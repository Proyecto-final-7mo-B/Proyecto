import 'dart:math';

import '../../../domain/models/frecuencia.dart';
import '../../../domain/models/registro.dart';
import '../../../utils/evidencia.dart';
import '../../../utils/fechas.dart';
import '../../../utils/intensidad.dart';

/// Cálculos del detalle de un hábito a partir de sus check-ins (`GET /habitos/{id}/registros`). Son funciones puras:
/// se prueban sin pantalla ni repositorios.
abstract final class EstadisticasHabito {
  /// % de cumplimiento entre [desde] y [hasta] (inclusive), sin contar los días antes de [creado]:
  /// - diario y días de la semana: cumplidos ÷ días programados;
  /// - "N por semana": cumplidos ÷ (N × semanas del periodo), como máximo 100 %.
  ///
  /// `null` si en el periodo no había nada programado (p. ej., el hábito aún no existía).
  static double? cumplimiento({
    required Frecuencia frecuencia,
    required Map<DateTime, Registro> registros,
    required DateTime desde,
    required DateTime hasta,
    required DateTime creado,
  }) {
    final inicio = _max(Fechas.soloFecha(desde), Fechas.soloFecha(creado));
    final fin = Fechas.soloFecha(hasta);
    if (inicio.isAfter(fin)) {
      return null;
    }
    final dias = fin.difference(inicio).inDays + 1;
    var programados = 0;
    var cumplidos = 0;
    for (var i = 0; i < dias; i++) {
      final dia = inicio.add(Duration(days: i));
      final cumplido = registros[dia]?.cumplido ?? false;
      if (frecuencia is NPorSemana) {
        cumplidos += cumplido ? 1 : 0;
      } else if (frecuencia.programadoEn(dia)) {
        programados++;
        cumplidos += cumplido ? 1 : 0;
      }
    }
    if (frecuencia is NPorSemana) {
      final esperado = frecuencia.veces * dias / 7;
      return min(100, 100 * cumplidos / esperado);
    }
    return programados == 0 ? null : 100 * cumplidos / programados;
  }

  /// Intensidad 0–4 de cada día del mes para el calendario: un check-in cumplido con su meta (o sin valor) es 4; con
  /// un valor menor, la proporción de la meta; uno no cumplido, 0. Los días sin check-in no se colorean.
  static Map<int, int> nivelesMes({
    required Map<DateTime, Registro> registros,
    required int anio,
    required int mes,
    required double meta,
  }) => {
    for (final r in registros.values)
      if (r.fecha.year == anio && r.fecha.month == mes)
        r.fecha.day: switch (r) {
          Registro(cumplido: false) => 0,
          Registro(valor: final v?) when v < meta && meta > 0 => max(1, nivelDeCumplimiento(100 * v / meta)),
          _ => 4,
        },
  };

  /// % de cada una de las últimas [semanas] semanas (lunes a domingo), de la más antigua a la actual. La semana actual
  /// cuenta hasta [hoy]; las semanas antes de [creado] no aparecen.
  static List<double> tendencia({
    required Frecuencia frecuencia,
    required Map<DateTime, Registro> registros,
    required DateTime hoy,
    required DateTime creado,
    int semanas = 12,
  }) {
    final lunesActual = Fechas.inicioSemana(Fechas.soloFecha(hoy));
    return [
      for (var i = semanas - 1; i >= 0; i--)
        ?cumplimiento(
          frecuencia: frecuencia,
          registros: registros,
          desde: lunesActual.subtract(Duration(days: 7 * i)),
          hasta: _min(lunesActual.subtract(Duration(days: 7 * i - 6)), Fechas.soloFecha(hoy)),
          creado: creado,
        ),
    ];
  }

  /// [cuantos] niveles después de [meta], cada uno +10 % y redondeado a 2 decimales (contrato §6.4: los niveles
  /// futuros no existen en la base, son una proyección).
  static List<double> proyeccion(double meta, {int cuantos = 2}) {
    final lista = <double>[];
    var m = meta;
    for (var i = 0; i < cuantos; i++) {
      m = (m * 1.1 * 100).round() / 100;
      lista.add(m);
    }
    return lista;
  }

  /// Proyección como la Escalera v2 (doc. 02): cada nivel +10 % redondeado al [paso] (al menos un paso, como mucho
  /// +30 %), sin pasar de [techo] (el fin del óptimo de la evidencia). Se detiene al llegar al techo.
  static List<double> proyeccionConEvidencia(double meta, {required double paso, double? techo, int cuantos = 4}) {
    final lista = <double>[];
    var m = meta;
    final limite = techo == null ? null : EvaluadorEvidencia.redondearPaso(techo, paso, modo: Redondeo.abajo);
    for (var i = 0; i < cuantos; i++) {
      final diez = max(EvaluadorEvidencia.redondearPaso(m * 1.1, paso), _dos(m + paso));
      final treinta = max(EvaluadorEvidencia.redondearPaso(m * 1.3, paso, modo: Redondeo.abajo), _dos(m + paso));
      var siguiente = min(diez, treinta);
      if (limite != null) {
        siguiente = min(siguiente, limite);
      }
      if (siguiente <= m) {
        break;
      }
      lista.add(siguiente);
      m = siguiente;
    }
    return lista;
  }

  static double _dos(double x) => (x * 100).roundToDouble() / 100;

  static DateTime _max(DateTime a, DateTime b) => a.isAfter(b) ? a : b;
  static DateTime _min(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
}
