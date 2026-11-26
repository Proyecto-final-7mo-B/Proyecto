import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../data/repositories/capsulas/capsulas_repository.dart';
import '../../../data/repositories/escalera/escalera_repository.dart';
import '../../../data/repositories/habitos/habitos_repository.dart';
import '../../../data/repositories/progreso/progreso_repository.dart';
import '../../../data/repositories/registros/registros_repository.dart';
import '../../../data/services/api/errores_api.dart';
import '../../../domain/models/capsula.dart';
import '../../../domain/models/escalera.dart';
import '../../../domain/models/frecuencia.dart';
import '../../../domain/models/habito.dart';
import '../../../domain/models/progreso.dart';
import '../../../domain/models/registro.dart';
import '../../../utils/command.dart';
import '../../../utils/fechas.dart';
import '../../../utils/intensidad.dart';
import '../../../utils/reloj.dart';
import '../../../utils/result.dart';

/// Pantalla Hoy (bosquejo 02): los hábitos de hoy con su check-in de un toque, "N de M", la semana L–D, el calendario
/// del mes (escritorio), la sugerencia de la Escalera y las cápsulas selladas (reloj de arena en la fila).
///
/// Solo los hábitos son indispensables: si falla la semana, el mes, la sugerencia o las cápsulas, la pantalla se
/// muestra igual sin esa parte.
class HoyViewModel extends ChangeNotifier {
  HoyViewModel({
    required HabitosRepository habitos,
    required RegistrosRepository registros,
    required ProgresoRepository progreso,
    required EscaleraRepository escalera,
    required CapsulasRepository capsulas,
    Reloj reloj = relojDelSistema,
    Uuid uuid = const Uuid(),
  }) : _habitosRepo = habitos,
       _repoRegistros = registros,
       _repoProgreso = progreso,
       _repoEscalera = escalera,
       _repoCapsulas = capsulas,
       _relojHoy = reloj,
       _generadorId = uuid {
    cargar = Command0<void>(_cargar);
    responder = Command1<RespuestaSugerencia, bool>(_responder);
  }

  final HabitosRepository _habitosRepo;
  final RegistrosRepository _repoRegistros;
  final ProgresoRepository _repoProgreso;
  final EscaleraRepository _repoEscalera;
  final CapsulasRepository _repoCapsulas;
  final Reloj _relojHoy;
  final Uuid _generadorId;

  late final Command0<void> cargar;

  /// Responde la sugerencia mostrada: `true` = Aceptar, `false` = Mantener.
  late final Command1<RespuestaSugerencia, bool> responder;

  List<Habito> _habitos = const [];
  Progreso? _semana;
  Progreso? _mes;
  Sugerencia? _sugerencia;
  Set<String> _conCapsula = const {};
  final Set<String> _enviando = {};
  bool _cargado = false;

  DateTime get ahora => _relojHoy();

  /// El día del usuario (no el de UTC).
  DateTime get hoy => Fechas.soloFecha(_relojHoy());

  bool get cargado => _cargado;
  List<Habito> get habitos => _habitos;
  Sugerencia? get sugerencia => _sugerencia;

  /// Lo que se lista en "Para hoy": los programados hoy y los de "N por semana" (se cumplen cualquier día).
  List<Habito> get paraHoy => [
    for (final h in _habitos)
      if (h.hoy?.programado ?? false) h,
    for (final h in _habitos)
      if (h.frecuencia is NPorSemana) h,
  ];

  /// "N de M": solo cuentan los programados hoy.
  int get totalHoy => _habitos.where((h) => h.hoy?.programado ?? false).length;
  int get cumplidosHoy => _habitos.where((h) => (h.hoy?.programado ?? false) && (h.hoy?.cumplido ?? false)).length;
  double get avanceHoy => totalHoy == 0 ? 0 : cumplidosHoy / totalHoy;

  bool tieneCapsula(String habitoId) => _conCapsula.contains(habitoId);
  bool enviando(String habitoId) => _enviando.contains(habitoId);

  /// Intensidad de lunes a domingo; los días que aún no llegan van en `null`.
  List<int?> get nivelesSemana {
    final lunes = Fechas.inicioSemana(hoy);
    final porDia = {for (final d in _semana?.porDia ?? const <ProgresoDia>[]) d.fecha: d};
    return [
      for (var i = 0; i < 7; i++)
        switch (lunes.add(Duration(days: i))) {
          final dia when dia.isAfter(hoy) => null,
          final dia => nivelDeCumplimiento(porDia[dia]?.cumplimiento ?? 0),
        },
    ];
  }

  /// Día del mes → intensidad, para el calendario de escritorio.
  Map<int, int> get nivelesMes => {
    for (final d in _mes?.porDia ?? const <ProgresoDia>[])
      if (d.fecha.month == hoy.month && !d.fecha.isAfter(hoy)) d.fecha.day: nivelDeCumplimiento(d.cumplimiento),
  };

  Future<Result<void>> _cargar() async {
    final dia = hoy;
    final resultados = await Future.wait<Result<Object?>>([
      _habitosRepo.listar(fecha: dia),
      _repoProgreso.obtener(Periodo.semana, fecha: dia),
      _repoProgreso.obtener(Periodo.mes, fecha: dia),
      _repoEscalera.sugerencias(),
      _repoCapsulas.listar(estado: EstadoCapsula.sellada),
    ]);
    switch (resultados[0]) {
      case Fallo(:final error):
        return Result.fallo(error);
      case Exito(:final valor):
        _habitos = valor! as List<Habito>;
    }
    _semana = resultados[1].valorONulo as Progreso?;
    _mes = resultados[2].valorONulo as Progreso?;
    final sugerencias = resultados[3].valorONulo as List<Sugerencia>?;
    _sugerencia = sugerencias?.where((s) => s.estado == EstadoSugerencia.pendiente).firstOrNull;
    final capsulas = resultados[4].valorONulo as List<Capsula>?;
    _conCapsula = {for (final c in capsulas ?? const <Capsula>[]) c.habitoId};
    _cargado = true;
    notifyListeners();
    return const Result.exito(null);
  }

  /// Check-in de un toque: marca o desmarca el hábito **hoy**.
  ///
  /// La pantalla cambia al instante (racha incluida) y, si el servidor falla, vuelve a como estaba y devuelve el
  /// error para avisarlo. Reusa el `id` del check-in de hoy si ya existe: reenviarlo no duplica (idempotente).
  Future<ErrorApp?> alternar(Habito habito) async {
    if (_enviando.contains(habito.id)) {
      return null;
    }
    final anterior = habito;
    final cumplido = !(habito.hoy?.cumplido ?? false);
    final id = habito.hoy?.registro?.id ?? _generadorId.v4();
    final estimada = max(0, habito.racha.actual + (cumplido ? 1 : -1));
    _reemplazar(
      habito.copyWith(
        racha: Racha(
          actual: estimada,
          maxima: max(habito.racha.maxima, estimada),
          ultimaFecha: habito.racha.ultimaFecha,
        ),
        hoy: HoyHabito(
          fecha: hoy,
          programado: habito.hoy?.programado ?? false,
          registro: RegistroDeHoy(id: id, cumplido: cumplido, valor: cumplido ? habito.meta : null),
        ),
      ),
    );
    _enviando.add(habito.id);
    notifyListeners();

    final resultado = await _repoRegistros.registrar(
      NuevoRegistro(
        id: id,
        habitoId: habito.id,
        fecha: hoy,
        cumplido: cumplido,
        valor: cumplido ? habito.meta : null,
        origen: OrigenRegistro.rapido,
      ),
    );
    _enviando.remove(habito.id);
    switch (resultado) {
      case Exito(:final valor):
        final actual = _habitos.firstWhere((h) => h.id == habito.id);
        _reemplazar(
          actual.copyWith(
            racha: Racha(
              actual: valor.rachaActual,
              maxima: max(actual.racha.maxima, valor.rachaActual),
              ultimaFecha: cumplido ? hoy : actual.racha.ultimaFecha,
            ),
          ),
        );
        notifyListeners();
        await _refrescarProgreso();
        return null;
      case Fallo(:final error):
        _reemplazar(anterior);
        notifyListeners();
        return error;
    }
  }

  Future<Result<RespuestaSugerencia>> _responder(bool aceptar) async {
    final s = _sugerencia;
    if (s == null) {
      return const Result.fallo(ErrorApp(TipoError.noEncontrado));
    }
    final r = await _repoEscalera.responder(s.id, aceptar: aceptar);
    if (r is Exito || r.errorONulo?.tipo == TipoError.sugerenciaResuelta) {
      // Resuelta (o ya lo estaba): se quita y se recarga para ver la nueva meta y nivel.
      _sugerencia = null;
      notifyListeners();
      await _cargar();
    }
    return r;
  }

  /// La semana y el mes cambian con cada check-in; se recargan sin bloquear la pantalla.
  Future<void> _refrescarProgreso() async {
    final dia = hoy;
    final semana = await _repoProgreso.obtener(Periodo.semana, fecha: dia);
    final mes = await _repoProgreso.obtener(Periodo.mes, fecha: dia);
    _semana = semana.valorONulo ?? _semana;
    _mes = mes.valorONulo ?? _mes;
    notifyListeners();
  }

  void _reemplazar(Habito nuevo) {
    _habitos = [for (final h in _habitos) h.id == nuevo.id ? nuevo : h];
  }

  @override
  void dispose() {
    cargar.dispose();
    responder.dispose();
    super.dispose();
  }
}
