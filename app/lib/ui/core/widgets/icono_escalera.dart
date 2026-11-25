import 'package:flutter/material.dart';

/// Ícono de la Escalera Kaizen: una escalera de tres peldaños dibujada con línea, como en los bosquejos.
/// Material no trae este trazo, por eso se dibuja.
class IconoEscalera extends StatelessWidget {
  const IconoEscalera({this.tamano, this.color, super.key});

  /// Por omisión, el tamaño del `IconTheme`.
  final double? tamano;

  /// Por omisión, el color del `IconTheme`.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tema = IconTheme.of(context);
    final lado = tamano ?? tema.size ?? 24;
    return SizedBox.square(
      dimension: lado,
      child: CustomPaint(painter: PintorEscalera(color ?? tema.color ?? Colors.black)),
    );
  }
}

/// Dibuja la escalera dentro de un cuadrado. Público para reutilizarlo en el logo.
class PintorEscalera extends CustomPainter {
  const PintorEscalera(this.color);

  final Color color;

  /// Puntos de la línea en proporción al lado (0–1).
  static const List<Offset> puntos = [
    Offset(0.16, 0.84),
    Offset(0.16, 0.64),
    Offset(0.39, 0.64),
    Offset(0.39, 0.44),
    Offset(0.62, 0.44),
    Offset(0.62, 0.24),
    Offset(0.84, 0.24),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final lado = size.shortestSide;
    final pincel = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = lado * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final camino = Path()..moveTo(puntos.first.dx * lado, puntos.first.dy * lado);
    for (final p in puntos.skip(1)) {
      camino.lineTo(p.dx * lado, p.dy * lado);
    }
    canvas.drawPath(camino, pincel);
  }

  @override
  bool shouldRepaint(PintorEscalera oldDelegate) => oldDelegate.color != color;
}
