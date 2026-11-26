/// Nombres de fechas en español de México y cálculo de la semana L–D (lunes = 1, como `fn_dia_programado`).
///
abstract final class Fechas {
  static const List<String> meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', //
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  /// Iniciales de lunes a domingo, como en los bosquejos.
  static const List<String> inicialesSemana = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  static const List<String> diasSemana = ['lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo'];

  /// "Octubre" para el mes 10.
  static String nombreMes(int mes) {
    RangeError.checkValueInInterval(mes, 1, 12, 'mes');
    return meses[mes - 1];
  }

  /// Días que tiene un mes (considera años bisiestos).
  static int diasDelMes(int anio, int mes) => DateTime.utc(anio, mes + 1, 0).day;

  /// Cuántas celdas vacías van antes del día 1 en una cuadrícula que empieza en lunes (0 = empieza en lunes).
  static int desfaseLunes(int anio, int mes) => DateTime.utc(anio, mes).weekday - 1;

  /// "8 de octubre".
  static String diaYMes(int dia, int mes) => '$dia de ${nombreMes(mes).toLowerCase()}';

  /// Solo el día (sin hora) de un instante local, como `DateTime` UTC a medianoche: así se guardan las `fecha` del
  /// contrato. Usar con la hora **local** del dispositivo: "hoy" es el día del usuario, no el de UTC.
  static DateTime soloFecha(DateTime momento) => DateTime.utc(momento.year, momento.month, momento.day);

  /// Hoy, en la zona del dispositivo.
  static DateTime hoy([DateTime Function()? reloj]) => soloFecha((reloj ?? DateTime.now)());

  /// `2026-11-23`.
  static String iso(DateTime fecha) =>
      '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-'
      '${fecha.day.toString().padLeft(2, '0')}';

  /// "Domingo 8 de noviembre", como en el encabezado de Hoy.
  static String larga(DateTime fecha) {
    final dia = diasSemana[fecha.weekday - 1];
    return '${dia[0].toUpperCase()}${dia.substring(1)} ${diaYMes(fecha.day, fecha.month)}';
  }

  /// Lunes de la semana de [fecha] (la semana va de lunes a domingo).
  static DateTime inicioSemana(DateTime fecha) => soloFecha(fecha).subtract(Duration(days: fecha.weekday - 1));

  /// Semana ISO 8601 (`2026-W47`), como la pide `GET /laboratorio/perspectivas`.
  static String semanaIso(DateTime fecha) {
    final dia = soloFecha(fecha);
    final jueves = dia.add(Duration(days: 4 - dia.weekday));
    final anio = jueves.year;
    final semana = 1 + jueves.difference(DateTime.utc(anio)).inDays ~/ 7;
    return '$anio-W${semana.toString().padLeft(2, '0')}';
  }
}
