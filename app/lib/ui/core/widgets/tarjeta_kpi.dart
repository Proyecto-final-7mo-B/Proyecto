import 'package:flutter/material.dart';

import '../tema/colores.dart';
import 'tarjeta_kaizen.dart';

/// Tarjeta de indicador del panel de admin: cifra grande, etiqueta y, opcional, la variación ("+8 %") arriba a la
/// derecha (azul si sube, rojo si baja).
class TarjetaKpi extends StatelessWidget {
  const TarjetaKpi({required this.valor, required this.etiqueta, this.variacion, super.key});

  /// Texto ya formateado ("1,204", "76 %", "3 de 3").
  final String valor;
  final String etiqueta;

  /// Variación en puntos porcentuales; `null` = no se muestra.
  final double? variacion;

  /// "+8 %", "−2.5 %", "0 %".
  static String formatoVariacion(double v) {
    final abs = v.abs();
    final numero = abs == abs.roundToDouble() ? abs.toStringAsFixed(0) : abs.toStringAsFixed(1);
    if (v > 0) {
      return '+$numero %';
    }
    return v < 0 ? '−$numero %' : '$numero %';
  }

  static Color colorVariacion(double v) => v < 0 ? KaizenColores.error : KaizenColores.azul600;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: variacion == null ? '$etiqueta: $valor' : '$etiqueta: $valor, ${formatoVariacion(variacion!)}',
      child: ExcludeSemantics(
        child: TarjetaKaizen(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Text(valor, style: texto.headlineLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(etiqueta, style: texto.bodyMedium!.copyWith(color: KaizenColores.textoSecundario)),
                ],
              ),
              if (variacion != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Text(
                    formatoVariacion(variacion!),
                    style: texto.labelMedium!.copyWith(fontWeight: FontWeight.w800, color: colorVariacion(variacion!)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
