import '../../../domain/models/avisos.dart';

/// Lo que pone los avisos en el sistema del dispositivo. El plan lo arma `GestorAvisos`; el notificador solo
/// reemplaza lo programado por el plan nuevo.
abstract interface class Notificador {
  /// `false` = esta plataforma no tiene notificaciones del sistema (escritorio y web): el plan se arma igual, pero no
  /// se programa nada.
  bool get disponible;

  /// Pide permiso de notificaciones; `false` si el usuario lo negó.
  Future<bool> pedirPermiso();

  /// `true` si el sistema deja programar a la hora exacta (Android 12+ lo pide aparte: "Alarmas y recordatorios").
  /// Sin eso, Android puede retrasar los avisos unos minutos.
  Future<bool> horaExacta();

  /// Abre el ajuste del sistema para permitir la hora exacta; `true` si quedó permitido.
  Future<bool> pedirHoraExacta();

  /// Quita todo lo que Kaizen tenía programado y pone [avisos].
  Future<void> reemplazar(List<AvisoProgramado> avisos);
}

/// Para pruebas, escritorio y web.
class NotificadorEnMemoria implements Notificador {
  NotificadorEnMemoria({this.disponible = true, this.permisoConcedido = true, this.exactaPermitida = true});

  @override
  final bool disponible;

  /// Simula que el usuario niega el permiso.
  bool permisoConcedido;

  /// Simula el permiso de hora exacta de Android.
  bool exactaPermitida;

  /// Lo programado ahora mismo.
  List<AvisoProgramado> programados = const [];

  /// Cuántas veces se reemplazó el plan.
  int reemplazos = 0;

  @override
  Future<bool> pedirPermiso() async => disponible && permisoConcedido;

  @override
  Future<bool> horaExacta() async => disponible && exactaPermitida;

  @override
  Future<bool> pedirHoraExacta() async => disponible && (exactaPermitida = true);

  @override
  Future<void> reemplazar(List<AvisoProgramado> avisos) async {
    if (!disponible) {
      return;
    }
    reemplazos++;
    programados = List.unmodifiable(avisos);
  }
}
