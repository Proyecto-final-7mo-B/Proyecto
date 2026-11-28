import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../../domain/models/avisos.dart';
import '../../../domain/models/escalera.dart';
import '../../../domain/models/habito.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/core/formatos.dart';
import '../../../utils/fechas.dart';
import '../../../utils/planificador_avisos.dart';
import '../../../utils/reloj.dart';
import '../../repositories/escalera/escalera_repository.dart';
import '../../repositories/habitos/habitos_repository.dart';
import '../base_local/almacen_local.dart';
import 'notificador.dart';

/// Arma y programa los avisos (Paso 10). Todo es **local**: las preferencias y el historial viven en la base del
/// dispositivo (tabla `marcas`, como JSON) y los avisos los programa el sistema operativo.
///
/// Se vuelve a planear al abrir la app y al volver al frente, con cada check-in (así el recordatorio de hoy se va),
/// al cambiar la hora de un recordatorio y al cambiar las preferencias.
class GestorAvisos extends ChangeNotifier {
  GestorAvisos({
    required HabitosRepository habitos,
    required EscaleraRepository escalera,
    required AlmacenLocal almacen,
    required this.notificador,
    Reloj reloj = relojDelSistema,
    AppLocalizations? textos,
  }) : _repoHabitos = habitos,
       _repoEscalera = escalera,
       _almacenAvisos = almacen,
       _relojAvisos = reloj,
       _planificador = PlanificadorAvisos(textos ?? lookupAppLocalizations(const Locale('es')));

  final HabitosRepository _repoHabitos;
  final EscaleraRepository _repoEscalera;
  final AlmacenLocal _almacenAvisos;
  final Notificador notificador;
  final Reloj _relojAvisos;
  final PlanificadorAvisos _planificador;

  static const String clavePreferencias = 'avisos_preferencias';
  static const String claveHistorial = 'avisos_historial';

  /// El historial se guarda 30 días (para la rotación de textos y los recordatorios ignorados).
  static const Duration memoria = Duration(days: 30);

  List<AvisoProgramado> _plan = const [];
  Future<void>? _enCurso;
  Completer<void>? _siguiente;
  bool _activo = true;

  /// Lo último que se programó (para "Próximos avisos").
  List<AvisoProgramado> get plan => _plan;

  Future<PreferenciasAvisos> preferencias() async {
    final json = await _almacenAvisos.leerJson(clavePreferencias);
    return json is Map<String, dynamic> ? PreferenciasAvisos.fromJson(json) : const PreferenciasAvisos();
  }

  Future<void> guardarPreferencias(PreferenciasAvisos p) async {
    await _almacenAvisos.guardarJson(clavePreferencias, p.toJson());
    await replanificar();
  }

  Future<List<EventoAviso>> historial() async {
    final json = await _almacenAvisos.leerJson(claveHistorial);
    return [
      if (json is List)
        for (final e in json) EventoAviso.fromJson(e as Map<String, dynamic>),
    ];
  }

  Future<void> _guardarHistorial(List<EventoAviso> eventos) async {
    final limite = _relojAvisos().subtract(memoria);
    await _almacenAvisos.guardarJson(claveHistorial, [
      for (final e in eventos)
        if (e.cuando.isAfter(limite)) e.toJson(),
    ]);
  }

  /// Un check-in cumplido: cuenta como respuesta al recordatorio (si fue en las 2 h siguientes) y quita lo que ya no
  /// hace falta (el recordatorio y la "racha en riesgo" de hoy).
  Future<void> registrarCheckin(String habitoId) async {
    final eventos = await historial();
    await _guardarHistorial([...eventos, EventoAviso.checkin(cuando: _relojAvisos(), habitoId: habitoId)]);
    await replanificar();
  }

  /// Pide permiso (al crear el primer aviso o recordatorio).
  Future<bool> pedirPermiso() => notificador.pedirPermiso();

  /// Si se puede programar a la hora exacta y, si no, pedirlo (vuelve a programar con el permiso nuevo).
  Future<bool> horaExacta() => notificador.horaExacta();

  Future<bool> pedirHoraExacta() async {
    final ok = await notificador.pedirHoraExacta();
    await replanificar();
    return ok;
  }

  /// Vuelve a armar el plan. Si ya se está armando uno, se arma otra vez al terminar y el `Future` devuelto termina
  /// con ese segundo plan (el que ya ve el cambio que lo pidió). Un fallo nunca sale de aquí: los avisos no deben
  /// tumbar la app.
  Future<void> replanificar() {
    if (_enCurso == null) {
      return _enCurso = _correr();
    }
    return (_siguiente ??= Completer<void>()).future;
  }

  Future<void> _correr() async {
    try {
      await _planear();
    } on Object catch (e) {
      debugPrint('Kaizen: no se pudieron programar los avisos ($e)');
    }
    final siguiente = _siguiente;
    _siguiente = null;
    if (siguiente == null) {
      _enCurso = null;
    } else {
      siguiente.complete(_enCurso = _correr());
    }
  }

  Future<void> _planear() async {
    if (!_activo) {
      return;
    }
    final ahora = _relojAvisos();
    final hoy = Fechas.soloFecha(ahora);
    final p = await preferencias();
    // Lo que ya pasó (avisos entregados y check-ins) se queda; lo futuro del plan anterior se reemplaza. Los
    // micro-pasos se guardan aunque no hayan llegado: así cada sugerencia se avisa una sola vez.
    final pasados = [
      for (final e in await historial())
        if (e.esCheckin || !e.cuando.isAfter(ahora) || e.tipo == TipoAviso.microPaso) e,
    ];
    final horas = await _almacenAvisos.recordatorios();
    final lista = (await _repoHabitos.listar(fecha: hoy)).valorONulo ?? const <Habito>[];
    final sugerencias = (await _repoEscalera.sugerencias()).valorONulo ?? const <Sugerencia>[];
    final plan = _planificador.planificar(
      ahora: ahora,
      preferencias: p,
      historial: pasados,
      habitos: [
        for (final h in lista)
          if (h.activo)
            (
              id: h.id,
              nombre: h.nombre,
              meta: '${numero(h.meta)} ${h.unidad}',
              intencion: h.intencion,
              frecuencia: h.frecuencia,
              racha: h.racha.actual,
              protegidaEstaSemana: h.racha.protegidaEstaSemana,
              hechoHoy: h.hoy?.cumplido ?? false,
              hora: switch (horas[h.id]) {
                final x? => (hora: x.hora, minuto: x.minuto),
                null => null,
              },
            ),
      ],
      sugerencias: [
        for (final s in sugerencias)
          if (s.estado == EstadoSugerencia.pendiente) (id: s.id, habitoNombre: s.habitoNombre),
      ],
    );
    await notificador.reemplazar(plan);
    await _guardarHistorial([
      ...pasados,
      for (final a in plan)
        if (a.tipo != TipoAviso.microPaso || !pasados.any((e) => e.sugerenciaId == a.sugerenciaId))
          EventoAviso.desdeAviso(a),
    ]);
    _plan = plan;
    notifyListeners();
  }

  /// Al cerrar sesión: nada programado (la base local también se borra). Espera lo que se esté planeando y no
  /// vuelve a planear hasta [activar] (al iniciar sesión).
  Future<void> cancelarTodo() async {
    _activo = false;
    while (_enCurso != null) {
      await _enCurso;
    }
    _plan = const [];
    await notificador.reemplazar(const []);
    notifyListeners();
  }

  /// Con sesión: se puede volver a planear.
  void activar() => _activo = true;
}

/// Los días de un aviso de "Mis avisos" en texto: "Todos los días", "Lunes a viernes", "Fin de semana" o
/// "Lun · Mié · Vie".
String diasDeMascara(int mascara) => switch (mascara) {
  127 => 'Todos los días',
  31 => 'Lunes a viernes',
  96 => 'Fin de semana',
  _ => [
    for (var b = 0; b < 7; b++)
      if (mascara & (1 << b) != 0) diasCortos[b],
  ].join(' · '),
};

/// Abreviaturas de los días (lunes primero).
const List<String> diasCortos = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
