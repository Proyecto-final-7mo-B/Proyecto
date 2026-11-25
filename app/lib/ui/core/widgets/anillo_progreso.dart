import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tema/colores.dart';

/// Anillo de progreso (0–1) que empieza arriba y avanza en sentido horario. Por omisión en `naranjaClaro`, como el de
/// la cápsula. Puede llevar un widget al centro (p. ej., "14/21").
class AnilloProgreso extends StatelessWidget {
  const AnilloProgreso({
    required this.valor,
    this.lado = 56,
    this.grosor = 6,
    this.color = KaizenColores.naranjaClaro,
    this.colorPista = KaizenColores.azul50,
    this.etiquetaSemantica,
    this.child,
    super.key,
  });

  /// Progreso entre 0 y 1; fuera de rango se recorta.
  final double valor;
  final double lado;
  final double grosor;
  final Color color;
  final Color colorPista;
  final String? etiquetaSemantica;
  final Widget? child;

  double get valorRecortado => valor.isNaN ? 0 : valor.clamp(0, 1).toDouble();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: etiquetaSemantica,
      value: '${(valorRecortado * 100).round()} %',
      child: SizedBox.square(
        dimension: lado,
        child: CustomPaint(
          painter: PintorAnillo(valor: valorRecortado, grosor: grosor, color: color, colorPista: colorPista),
          child: child == null ? null : Center(child: child),
        ),
      ),
    );
  }
}

class PintorAnillo extends CustomPainter {
  const PintorAnillo({required this.valor, required this.grosor, required this.color, required this.colorPista});

  final double valor;
  final double grosor;
  final Color color;
  final Color colorPista;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(grosor / 2, grosor / 2, size.width - grosor, size.height - grosor);
    final pista = Paint()
      ..color = colorPista
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor;
    canvas.drawArc(rect, 0, math.pi * 2, false, pista);
    if (valor <= 0) {
      return;
    }
    final arco = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * valor, false, arco);
  }

  @override
  bool shouldRepaint(PintorAnillo oldDelegate) =>
      oldDelegate.valor != valor ||
      oldDelegate.grosor != grosor ||
      oldDelegate.color != color ||
      oldDelegate.colorPista != colorPista;
}
