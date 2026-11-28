import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../data/repositories/habitos/habitos_repository.dart';
import '../../../data/services/avisos/gestor_avisos.dart';
import '../../../data/services/recordatorios/servicio_recordatorios.dart';
import '../../../domain/models/avisos.dart';
import '../../../domain/models/habito.dart';
import '../../../utils/command.dart';
import '../../../utils/fechas.dart';
import '../../../utils/reloj.dart';
import '../../../utils/result.dart';

/// `/perfil/notificaciones` (Paso 10): todo lo que el usuario decide de sus avisos. Se guarda **en el dispositivo**
/// y cada cambio vuelve a planear lo programado.
class NotificacionesViewModel extends ChangeNotifier {
  NotificacionesViewModel({
    required GestorAvisos avisos,
    required ServicioRecordatorios recordatorios,
    required HabitosRepository habitos,
    Reloj reloj = relojDelSistema,
    Uuid uuid = const Uuid(),
  }) : _gestor = avisos,
       _servicio = recordatorios,
       _repoHabitos = habitos,
       _relojNotif = reloj,
       _generador = uuid {
    cargar = Command0<void>(_cargar);
    _gestor.addListener(notifyListeners);
  }

  final GestorAvisos _gestor;
  final ServicioRecordatorios _servicio;
  final HabitosRepository _repoHabitos;
  final Reloj _relojNotif;
  final Uuid _generador;

  late final Command0<void> cargar;

  PreferenciasAvisos _prefs = const PreferenciasAvisos();
  List<({Habito habito, HoraRecordatorio? hora})> _habitos = const [];
  bool _cargado = false;
  bool _permisoNegado = false;
  bool _exacta = true;

  bool get cargado => _cargado;
  PreferenciasAvisos get preferencias => _prefs;

  /// Los hábitos activos con la hora de su recordatorio (o `null`).
  List<({Habito habito, HoraRecordatorio? hora})> get habitos => _habitos;

  /// `false` en escritorio y web: ahí no hay notificaciones del sistema.
  bool get disponible => _gestor.notificador.disponible;

  /// `false` si Android no deja programar a la hora exacta (los avisos pueden llegar unos minutos tarde).
  bool get horaExacta => _exacta;

  /// El usuario negó el permiso la última vez que se pidió.
  bool get permisoNegado => _permisoNegado;

  /// Los próximos avisos programados (como mucho [cuantos]).
  List<AvisoProgramado> proximos({int cuantos = 5}) => _gestor.plan.take(cuantos).toList();

  Future<Result<void>> _cargar() async {
    _prefs = await _gestor.preferencias();
    _exacta = !disponible || await _gestor.horaExacta();
    final r = await _repoHabitos.listar(fecha: Fechas.soloFecha(_relojNotif()));
    final lista = (r.valorONulo ?? const <Habito>[]).where((h) => h.activo).toList();
    _habitos = [for (final h in lista) (habito: h, hora: await _servicio.hora(h.id))];
    await _gestor.replanificar();
    _cargado = true;
    notifyListeners();
    return const Result.exito(null);
  }

  Future<void> _guardar(PreferenciasAvisos p) async {
    _prefs = p;
    notifyListeners();
    await _gestor.guardarPreferencias(p);
  }

  /// Abre el ajuste de Android para la hora exacta.
  Future<void> pedirHoraExacta() async {
    _exacta = await _gestor.pedirHoraExacta();
    notifyListeners();
  }

  // ───────────────────────── Automáticos y silencio ─────────────────────────

  Future<void> cambiarRecordatorios(bool v) => _guardar(_prefs.copyWith(recordatorios: v));
  Future<void> cambiarRachaEnRiesgo(bool v) => _guardar(_prefs.copyWith(rachaEnRiesgo: v));
  Future<void> cambiarHoraRachaEnRiesgo(Hora h) => _guardar(_prefs.copyWith(horaRachaEnRiesgo: h));
  Future<void> cambiarMicroPaso(bool v) => _guardar(_prefs.copyWith(microPaso: v));
  Future<void> cambiarResumenSemanal(bool v) => _guardar(_prefs.copyWith(resumenSemanal: v));
  Future<void> cambiarDiaResumen(int dia) => _guardar(_prefs.copyWith(diaResumen: dia));
  Future<void> cambiarHoraResumen(Hora h) => _guardar(_prefs.copyWith(horaResumen: h));
  Future<void> cambiarSilencioDesde(Hora h) => _guardar(_prefs.copyWith(silencioDesde: h));
  Future<void> cambiarSilencioHasta(Hora h) => _guardar(_prefs.copyWith(silencioHasta: h));

  // ───────────────────────── Mis avisos ─────────────────────────

  /// Agrega un aviso a [hora] los [dias] (máscara L=1 … D=64) con [texto]. Pide permiso; `false` si lo negaron.
  Future<bool> agregarAviso({required Hora hora, required int dias, required String texto}) async {
    if (!await _gestor.pedirPermiso()) {
      _permisoNegado = true;
      notifyListeners();
      return false;
    }
    _permisoNegado = false;
    final nuevo = AvisoPersonal(id: _generador.v4(), hora: hora, dias: dias == 0 ? 127 : dias, texto: texto.trim());
    await _guardar(_prefs.copyWith(personales: [..._prefs.personales, nuevo]));
    return true;
  }

  Future<void> editarAviso(AvisoPersonal a) =>
      _guardar(_prefs.copyWith(personales: [for (final x in _prefs.personales) x.id == a.id ? a : x]));

  Future<void> quitarAviso(String id) => _guardar(
    _prefs.copyWith(
      personales: [
        for (final x in _prefs.personales)
          if (x.id != id) x,
      ],
    ),
  );

  // ───────────────────────── Recordatorio de cada hábito ─────────────────────────

  /// Pone (o cambia) la hora del recordatorio de [h]. `false` si el usuario negó el permiso.
  Future<bool> ponerRecordatorio(Habito h, HoraRecordatorio hora) async {
    final ok = await _servicio.programar(
      habitoId: h.id,
      titulo: h.nombre,
      cuerpo: h.nombre,
      hora: hora,
      frecuencia: h.frecuencia,
    );
    _permisoNegado = !ok;
    if (ok) {
      _habitos = [for (final x in _habitos) x.habito.id == h.id ? (habito: x.habito, hora: hora) : x];
    }
    notifyListeners();
    return ok;
  }

  Future<void> quitarRecordatorio(Habito h) async {
    await _servicio.cancelar(h.id);
    _habitos = [for (final x in _habitos) x.habito.id == h.id ? (habito: x.habito, hora: null) : x];
    notifyListeners();
  }

  @override
  void dispose() {
    _gestor.removeListener(notifyListeners);
    cargar.dispose();
    super.dispose();
  }
}
