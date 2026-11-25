import 'package:flutter/material.dart';

import '../tema/colores.dart';

/// Barra de progreso redondeada (0–1).
///
/// - Sobre la tarjeta destacada ("2 de 5"): barra blanca sobre pista `marino700`.
/// - Sobre fondo claro: `marino800` sobre `azul50`, o el color que se pida (p. ej., `naranjaRacha` en las cápsulas).
class BarraProgreso extends StatelessWidget {
  const BarraProgreso({
    required this.valor,
    this.sobreOscuro = false,
    this.color,
    this.alto = 8,
    this.etiquetaSemantica,
    super.key,
  });

  final double valor;
  final bool sobreOscuro;
  final Color? color;
  final double alto;
  final String? etiquetaSemantica;

  double get valorRecortado => valor.isNaN ? 0 : valor.clamp(0, 1).toDouble();

  Color get colorBarra => color ?? (sobreOscuro ? KaizenColores.superficie : KaizenColores.marino800);

  Color get colorPista => sobreOscuro ? KaizenColores.marino700 : KaizenColores.azul50;

  @override
  Widget build(BuildContext context) {
    final radio = BorderRadius.circular(alto / 2);
    return Semantics(
      label: etiquetaSemantica,
      value: '${(valorRecortado * 100).round()} %',
      child: Container(
        height: alto,
        decoration: BoxDecoration(color: colorPista, borderRadius: radio),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: valorRecortado,
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(color: colorBarra, borderRadius: radio),
          ),
        ),
      ),
    );
  }
}
