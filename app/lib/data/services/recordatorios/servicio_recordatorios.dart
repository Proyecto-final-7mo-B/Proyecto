import '../../../domain/models/frecuencia.dart';

/// Hora del día de un recordatorio (24 h).
typedef HoraRecordatorio = ({int hora, int minuto});

/// "07:30".
String formatoHora(HoraRecordatorio h) => '${h.hora.toString().padLeft(2, '0')}:${h.minuto.toString().padLeft(2, '0')}';

/// "07:30" → (hora: 7, minuto: 30); `null` si no es una hora válida.
HoraRecordatorio? leerHora(String? texto) {
  final partes = (texto ?? '').split(':');
  if (partes.length != 2) {
    return null;
  }
  final h = int.tryParse(partes[0]);
  final m = int.tryParse(partes[1]);
  if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
    return null;
  }
  return (hora: h, minuto: m);
}

/// Recordatorios de los hábitos: notificaciones **locales** del teléfono (no pasan por la API ni por la base).
///
/// - En Android e iOS: `ServicioRecordatoriosLocal`, con `flutter_local_notifications`.
/// - En escritorio, web y pruebas: `ServicioRecordatoriosEnMemoria` (en escritorio y web, `disponible` es `false` y la
///   app no muestra el campo).
abstract interface class ServicioRecordatorios {
  /// `false` = esta plataforma no tiene recordatorios.
  bool get disponible;

  /// Hora del recordatorio de [habitoId], o `null` si no tiene.
  Future<HoraRecordatorio?> hora(String habitoId);

  /// Programa (o reprograma) el recordatorio. Pide permiso de notificaciones si hace falta; devuelve `false` si el
  /// usuario lo negó (el hábito se guarda igual, sin recordatorio).
  ///
  /// - Diario y "N por semana": todos los días a esa hora.
  /// - Días de la semana: solo esos días.
  Future<bool> programar({
    required String habitoId,
    required String titulo,
    required String cuerpo,
    required HoraRecordatorio hora,
    required Frecuencia frecuencia,
  });

  Future<void> cancelar(String habitoId);
}

/// Para pruebas, escritorio y web.
class ServicioRecordatoriosEnMemoria implements ServicioRecordatorios {
  ServicioRecordatoriosEnMemoria({this.disponible = true, this.permisoConcedido = true});

  @override
  final bool disponible;

  /// Simula que el usuario niega el permiso de notificaciones.
  bool permisoConcedido;

  /// Lo programado: hábito → (hora, frecuencia, texto).
  final Map<String, ({HoraRecordatorio hora, Frecuencia frecuencia, String titulo, String cuerpo})> programados = {};

  @override
  Future<HoraRecordatorio?> hora(String habitoId) async => programados[habitoId]?.hora;

  @override
  Future<bool> programar({
    required String habitoId,
    required String titulo,
    required String cuerpo,
    required HoraRecordatorio hora,
    required Frecuencia frecuencia,
  }) async {
    if (!disponible || !permisoConcedido) {
      return false;
    }
    programados[habitoId] = (hora: hora, frecuencia: frecuencia, titulo: titulo, cuerpo: cuerpo);
    return true;
  }

  @override
  Future<void> cancelar(String habitoId) async => programados.remove(habitoId);
}
