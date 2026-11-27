import 'package:flutter/material.dart';

import '../tema/colores.dart';
import 'tarjeta_kaizen.dart';

/// Tarjeta de indicador (panel de admin y detalle del hábito): cifra grande, etiqueta y, opcionales, la variación
/// ("+8 %") arriba a la derecha (azul si sube, rojo si baja), un [icono] con su [color] (en un círculo de ese color al
/// 12 %) y una [nota] corta debajo ("Próximo hito: 66"). El color nunca va solo: siempre lleva ícono y texto.
class TarjetaKpi extends StatelessWidget {
  const TarjetaKpi({
    required this.valor,
    required this.etiqueta,
    this.variacion,
    this.icono,
    this.color,
    this.nota,
    super.key,
  });

  /// Texto ya formateado ("1,204", "76 %", "3 de 3").
  final String valor;
  final String etiqueta;

  /// Variación en puntos porcentuales; `null` = no se muestra.
  final double? variacion;

  final IconData? icono;

  /// Color del ícono y de la nota; `null` = marino.
  final Color? color;
  final String? nota;

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
      label: [
        '$etiqueta: $valor',
        if (variacion != null) formatoVariacion(variacion!),
        ?nota,
      ].join(', '),
      child: ExcludeSemantics(
        child: TarjetaKaizen(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icono != null) ...[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: KaizenColores.fondoDe(color ?? KaizenColores.marino800),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icono, size: 20, color: color ?? KaizenColores.marino800),
                    ),
                    const SizedBox(height: 4),
                  ] else
                    const SizedBox(height: 8),
                  Text(valor, style: texto.headlineLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(etiqueta, style: texto.bodyMedium!.copyWith(color: KaizenColores.textoSecundario)),
                  if (nota != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      nota!,
                      style: texto.labelMedium!.copyWith(
                        color: color ?? KaizenColores.textoSecundario,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
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
