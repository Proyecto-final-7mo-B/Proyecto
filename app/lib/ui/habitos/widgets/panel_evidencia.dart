import 'dart:math';

import 'package:flutter/material.dart';

import '../../../domain/models/categoria.dart';
import '../../../domain/models/evidencia.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../core/formatos.dart';
import '../../core/tema/colores.dart';
import '../../core/tema/medidas.dart';

/// "Lo que dice la evidencia" para una meta: la zona (con ícono y texto, no solo color), la barra del rango
/// recomendado con la meta marcada, qué hacer y la fuente. Las reglas y las citas están en
/// `Evidencias_generales/12_investigacion_cientifica/` (doc. 02 y 03).
class PanelEvidencia extends StatelessWidget {
  const PanelEvidencia({
    required this.evaluacion,
    required this.meta,
    required this.unidad,
    this.unidadComparable,
    this.onUsarSugerida,
    super.key,
  });

  final Evaluacion evaluacion;
  final double meta;
  final String unidad;

  /// Sin referencia por la unidad (km): la unidad que sí se compara, para sugerirla.
  final String? unidadComparable;

  /// "Usar X" (solo al crear y si la meta pasa del máximo). `null` = sin botón.
  final VoidCallback? onUsarSugerida;

  static IconData iconoDe(ZonaEvidencia z) => switch (z) {
    ZonaEvidencia.bajo => Icons.trending_up,
    ZonaEvidencia.optimo => Icons.verified_outlined,
    ZonaEvidencia.alto => Icons.info_outline,
    ZonaEvidencia.excesivo => Icons.warning_amber_outlined,
    ZonaEvidencia.sinReferencia => Icons.help_outline,
  };

  static Color colorDe(ZonaEvidencia z) => switch (z) {
    ZonaEvidencia.bajo => KaizenColores.azul600,
    ZonaEvidencia.optimo => KaizenColores.verdeProgreso,
    ZonaEvidencia.alto => KaizenColores.azul600,
    ZonaEvidencia.excesivo => KaizenColores.avisoTexto,
    ZonaEvidencia.sinReferencia => KaizenColores.textoSecundario,
  };

  static String nombreDe(ZonaEvidencia z, AppLocalizations t) => switch (z) {
    ZonaEvidencia.bajo => t.zonaBajo,
    ZonaEvidencia.optimo => t.zonaOptimo,
    ZonaEvidencia.alto => t.zonaAlto,
    ZonaEvidencia.excesivo => t.zonaExcesivo,
    ZonaEvidencia.sinReferencia => t.evidenciaTitulo,
  };

  /// Un rango por sesión sale con decimales (150 ÷ 7 = 21.43 min). Para leerlo: enteros si la unidad avanza de 1 en
  /// 1 o más (min, pasos, vasos); si no (h, L), hasta 2 decimales.
  static String paraMostrar(double x, double paso) => numero(paso >= 1 ? x.roundToDouble() : x);

  /// Qué significa la zona para esta meta (texto corto para el usuario).
  static String mensajeDe(Evaluacion e, String unidad, AppLocalizations t, {String? unidadComparable}) {
    final sugerida = e.metaSugerida;
    String conUnidad(double x) => '${paraMostrar(x, e.paso)} $unidad';
    return switch (e.zona) {
      ZonaEvidencia.bajo => t.evidenciaBajo(conUnidad(sugerida ?? e.optimoDesde ?? 0)),
      ZonaEvidencia.optimo => t.evidenciaOptimo,
      ZonaEvidencia.alto when e.sentido == SentidoHabito.reducir => t.evidenciaReducirAlto(conUnidad(sugerida ?? 0)),
      ZonaEvidencia.alto => t.evidenciaAlto,
      ZonaEvidencia.excesivo => t.evidenciaExcesivo(conUnidad(e.maximo ?? 0)),
      ZonaEvidencia.sinReferencia =>
        unidadComparable == null ? t.zonaSinReferencia : t.unidadSinConversion(unidadComparable),
    };
  }

  static String? rangoDe(Evaluacion e, String unidad, AppLocalizations t) {
    final desde = e.optimoDesde;
    final hasta = e.optimoHasta;
    if (desde == null || hasta == null) {
      return null;
    }
    return e.sentido == SentidoHabito.reducir || desde == 0
        ? t.evidenciaHasta(paraMostrar(hasta, e.paso), unidad)
        : t.evidenciaRango(paraMostrar(desde, e.paso), paraMostrar(hasta, e.paso), unidad);
  }

  static String confianzaDe(Confianza c, AppLocalizations t) => switch (c) {
    Confianza.alta => t.confianzaAlta,
    Confianza.media => t.confianzaMedia,
    Confianza.baja => t.confianzaBaja,
  };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final e = evaluacion;
    final color = colorDe(e.zona);
    final rango = rangoDe(e, unidad, t);
    final sugerida = e.metaSugerida;
    final mostrarUsar = onUsarSugerida != null && e.zona == ZonaEvidencia.excesivo && sugerida != null;
    return Semantics(
      container: true,
      label: t.evidenciaTitulo,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: e.zona == ZonaEvidencia.excesivo ? KaizenColores.avisoFondo : KaizenColores.fondo,
          borderRadius: KaizenMedidas.bordeControl,
          border: Border.all(color: KaizenColores.bordeCampo),
        ),
        child: Padding(
          padding: const EdgeInsets.all(KaizenMedidas.e12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(iconoDe(e.zona), size: 20, color: color),
                  const SizedBox(width: KaizenMedidas.e8),
                  Expanded(
                    child: Text(
                      e.tieneReferencia ? nombreDe(e.zona, t) : t.evidenciaTitulo,
                      style: texto.titleSmall!.copyWith(color: KaizenColores.texto),
                    ),
                  ),
                ],
              ),
              if (e.tieneReferencia) ...[
                const SizedBox(height: KaizenMedidas.e12),
                ExcludeSemantics(
                  child: BarraRangoEvidencia(evaluacion: e, meta: meta),
                ),
                if (rango != null) ...[
                  const SizedBox(height: KaizenMedidas.e8),
                  Text('$rango · ${t.evidenciaPorSesion}', style: texto.bodySmall),
                ],
              ],
              const SizedBox(height: KaizenMedidas.e8),
              Text(mensajeDe(e, unidad, t, unidadComparable: unidadComparable), style: texto.bodyMedium),
              if (mostrarUsar) ...[
                const SizedBox(height: KaizenMedidas.e8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: onUsarSugerida,
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(t.evidenciaUsar('${numero(sugerida)} $unidad')),
                  ),
                ),
              ],
              if (e.cita case final cita?) ...[
                const SizedBox(height: KaizenMedidas.e8),
                Text(
                  [t.evidenciaFuente(cita), if (e.confianza case final c?) confianzaDe(c, t)].join(' · '),
                  style: texto.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Ámbar de la zona excesiva: se distingue del fondo del aviso; el rojo queda solo para errores (doc. 04).
const Color _ambarExceso = Color(0xFFE0A526);

/// Barra del rango: zona baja, óptima (verde), alta y excesiva, con la meta marcada. Las zonas se distinguen también
/// por el patrón de la marca y por el texto del panel, no solo por el color.
class BarraRangoEvidencia extends StatelessWidget {
  const BarraRangoEvidencia({required this.evaluacion, required this.meta, super.key});

  final Evaluacion evaluacion;
  final double meta;

  @override
  Widget build(BuildContext context) {
    final e = evaluacion;
    final desde = e.sentido == SentidoHabito.reducir ? 0.0 : (e.optimoDesde ?? 0);
    final hasta = e.optimoHasta ?? desde;
    final maximo = e.maximo;
    final escala = max(max(maximo ?? hasta * 1.5, hasta * 1.2), meta * 1.1);
    double fraccion(double x) => escala <= 0 ? 0 : (x / escala).clamp(0, 1).toDouble();
    return SizedBox(
      height: 22,
      child: LayoutBuilder(
        builder: (context, limites) {
          final ancho = limites.maxWidth;
          Widget tramo(double a, double b, Color color) => Positioned(
            left: ancho * fraccion(a),
            width: max(0, ancho * (fraccion(b) - fraccion(a))),
            top: 6,
            height: 10,
            child: ColoredBox(color: color),
          );
          return Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned.fill(
                top: 6,
                bottom: 6,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: KaizenColores.azul50,
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                  ),
                ),
              ),
              if (desde > 0) tramo(0, desde, KaizenColores.azul200),
              tramo(desde, hasta, KaizenColores.verdeProgreso),
              tramo(hasta, maximo ?? escala, KaizenColores.azul400),
              if (maximo != null) tramo(maximo, escala, _ambarExceso),
              Positioned(
                left: (ancho * fraccion(meta) - 2).clamp(0, max(0, ancho - 4)),
                top: 0,
                width: 4,
                height: 22,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: KaizenColores.marino900,
                    borderRadius: BorderRadius.all(Radius.circular(2)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
