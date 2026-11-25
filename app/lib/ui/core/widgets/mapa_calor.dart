import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../tema/colores.dart';
import '../tema/medidas.dart';

/// Mapa de calor con etiquetas de filas y columnas (indicador I5 "Hábito y energía" del panel de admin).
///
/// Cada valor se pasa a la escala 0–4 de [KaizenColores.intensidad] entre [minimo] y [maximo]; `null` se ve como
/// "—" en el color más claro.
class MapaCalor extends StatelessWidget {
  const MapaCalor({
    required this.filas,
    required this.columnas,
    required this.valores,
    this.minimo = -1,
    this.maximo = 1,
    this.formato = formatoConSigno,
    this.altoCelda = 40,
    this.anchoEtiquetas = 88,
    super.key,
  });

  final List<String> filas;
  final List<String> columnas;

  /// `valores[fila][columna]`.
  final List<List<double?>> valores;
  final double minimo;
  final double maximo;
  final String Function(double) formato;
  final double altoCelda;
  final double anchoEtiquetas;

  /// "+0.8", "−0.3", "0.0".
  static String formatoConSigno(double v) {
    final texto = v.abs().toStringAsFixed(1);
    if (v > 0) {
      return '+$texto';
    }
    return v < 0 ? '−$texto' : texto;
  }

  /// Nivel 0–4 de un valor dentro del rango.
  int nivelDe(double valor) {
    if (maximo <= minimo) {
      return 0;
    }
    final proporcion = ((valor - minimo) / (maximo - minimo)).clamp(0.0, 1.0);
    return (proporcion * 4).round();
  }

  @override
  Widget build(BuildContext context) {
    assert(valores.length == filas.length, 'Una lista de valores por fila');
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;

    Widget celda(int f, int c) {
      final valor = c < valores[f].length ? valores[f][c] : null;
      final nivel = valor == null ? 0 : nivelDe(valor);
      final etiqueta = valor == null ? '—' : formato(valor);
      return Semantics(
        label: '${filas[f]}, ${columnas[c]}: ${valor == null ? t.sinDatos : etiqueta}',
        child: ExcludeSemantics(
          child: Container(
            height: altoCelda,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: KaizenColores.deIntensidad(nivel), borderRadius: KaizenMedidas.bordeCelda),
            child: Text(
              etiqueta,
              style: texto.labelMedium!.copyWith(
                fontWeight: FontWeight.w800,
                color: KaizenColores.textoSobreIntensidad(nivel),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            SizedBox(width: anchoEtiquetas),
            for (final col in columnas)
              Expanded(
                child: Center(
                  child: Text(col, style: texto.labelSmall!.copyWith(color: KaizenColores.textoSecundario)),
                ),
              ),
          ],
        ),
        for (var f = 0; f < filas.length; f++)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                SizedBox(
                  width: anchoEtiquetas,
                  child: Text(filas[f], style: texto.labelMedium!.copyWith(fontWeight: FontWeight.w700)),
                ),
                for (var c = 0; c < columnas.length; c++) ...[
                  if (c > 0) const SizedBox(width: 6),
                  Expanded(child: celda(f, c)),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
