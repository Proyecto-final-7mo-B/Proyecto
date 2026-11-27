import 'dart:math' as math;

import '../domain/models/categoria.dart';
import '../domain/models/evidencia.dart';
import '../domain/models/frecuencia.dart';

/// Espejo exacto de `fn_evaluar_meta` (db/cambios/2026-11-27_evidencia_cientifica.sql). La app lo usa para el aviso
/// del formulario (sin red también) y el modo *fake*; las pruebas repiten los casos de las pruebas SQL.
abstract final class EvaluadorEvidencia {
  static const double _eps = 1e-9;

  /// Veces por semana que toca el hábito (`fn_sesiones_semana`).
  static double sesionesSemana(Frecuencia f) => switch (f) {
    Diaria() => 7,
    DiasSemana(:final mascara) => [
      for (var b = 0; b < 7; b++) mascara & (1 << b),
    ].where((x) => x != 0).length.toDouble(),
    NPorSemana(:final veces) => veces.toDouble(),
  };

  /// `fn_redondear_paso`: al paso más cercano, hacia abajo o hacia arriba, con 2 decimales.
  static double redondearPaso(double valor, double paso, {Redondeo modo = Redondeo.cerca}) {
    final cociente = valor / paso;
    final pasos = switch (modo) {
      Redondeo.abajo => (cociente + _eps).floorToDouble(),
      Redondeo.arriba => (cociente - _eps).ceilToDouble(),
      Redondeo.cerca => cociente.roundToDouble(),
    };
    return _dos(pasos * paso);
  }

  static double _dos(double x) => (x * 100).roundToDouble() / 100;

  /// Evalúa [meta] en [unidad] para [subcategoria] (con su catálogo completo: unidades y referencia).
  static Evaluacion evaluar(Subcategoria subcategoria, String unidad, double meta, Frecuencia frecuencia) {
    final u = subcategoria.unidad(unidad);
    final r = subcategoria.referencia;
    final paso = u?.paso ?? 0.01;
    final factor = u?.factorABase;
    if (r == null || factor == null) {
      return Evaluacion(zona: ZonaEvidencia.sinReferencia, sentido: subcategoria.sentido, paso: paso);
    }
    final k = factor * (r.periodo == PeriodoReferencia.semana ? sesionesSemana(frecuencia) : 1);
    final volumen = meta * k;
    final maximo = r.maximo;
    final piso = r.pisoBajada;

    ZonaEvidencia zona;
    double? sugerida;
    if (subcategoria.sentido == SentidoHabito.aumentar && volumen < r.optimoDesde - _eps) {
      zona = ZonaEvidencia.bajo;
      sugerida = redondearPaso(r.optimoDesde / k, paso, modo: Redondeo.arriba);
    } else if (volumen <= r.optimoHasta + _eps) {
      zona = ZonaEvidencia.optimo;
    } else if (maximo == null || volumen <= maximo + _eps) {
      zona = ZonaEvidencia.alto;
      if (subcategoria.sentido == SentidoHabito.reducir) {
        sugerida = math.max(redondearPaso(r.optimoHasta / k, paso, modo: Redondeo.abajo), paso);
      }
    } else {
      zona = ZonaEvidencia.excesivo;
      sugerida = math.max(redondearPaso(maximo / k, paso, modo: Redondeo.abajo), paso);
    }
    return Evaluacion(
      zona: zona,
      sentido: subcategoria.sentido,
      paso: paso,
      volumen: _dos(volumen),
      unidadBase: r.unidadBase,
      periodo: r.periodo,
      optimoDesde: _dos(r.optimoDesde / k),
      optimoHasta: _dos(r.optimoHasta / k),
      maximo: maximo == null ? null : _dos(maximo / k),
      metaSugerida: sugerida,
      piso: piso == null ? null : redondearPaso(piso / k, paso, modo: Redondeo.arriba),
      cita: r.cita,
      fuentes: r.fuentes,
      url: r.url,
      confianza: r.confianza,
      nota: r.nota,
    );
  }

  /// Meta con la que arranca el formulario al elegir subcategoría y unidad: el inicio del óptimo (empezar por lo
  /// recomendado sin pasarse; doc. 02) o, en `reducir`, el límite recomendado. Sin referencia, el mínimo de la unidad.
  static double metaInicial(Subcategoria subcategoria, UnidadPermitida unidad, Frecuencia frecuencia) {
    final r = subcategoria.referencia;
    final factor = unidad.factorABase;
    double meta;
    if (r == null || factor == null) {
      meta = math.max(unidad.minimo, unidad.paso);
    } else {
      final k = factor * (r.periodo == PeriodoReferencia.semana ? sesionesSemana(frecuencia) : 1);
      meta = subcategoria.sentido == SentidoHabito.aumentar
          ? redondearPaso(r.optimoDesde / k, unidad.paso, modo: Redondeo.arriba)
          : math.max(redondearPaso(r.optimoHasta / k, unidad.paso, modo: Redondeo.abajo), unidad.paso);
    }
    return meta.clamp(unidad.minimo, unidad.maximo).toDouble();
  }
}

enum Redondeo { cerca, abajo, arriba }
