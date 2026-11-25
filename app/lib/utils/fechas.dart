/// Nombres de fechas en español de México y cálculo de la semana L–D (lunes = 1, como `fn_dia_programado`).
///
/// En el Paso 4 se agregan los formatos completos ("Domingo 8 de noviembre").
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
}
