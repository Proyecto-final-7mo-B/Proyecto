import 'package:flutter/material.dart';

import '../../../domain/models/logro.dart';
import '../../../utils/hitos.dart';
import '../../core/apariencia_racha.dart';
import '../../core/tema/colores.dart';
import '../../core/tema/iconos.dart';

/// Color de una insignia (doc. 04): las de racha llevan el color de su nivel (llama naranja, aro, dorado a los 66);
/// las demás, el verde de progreso. Las que faltan, gris con candado. Nunca el rojo de error.
Color colorDeLogro(Logro l) {
  if (!l.obtenido) {
    return KaizenColores.rachaSinRacha;
  }
  if (l.tipo == TipoLogro.racha) {
    return NivelRacha.values.lastWhere((n) => n.desde <= l.objetivo).color;
  }
  return KaizenColores.verdeProgreso;
}

/// El círculo de la insignia: el ícono del logro (color si se obtuvo; gris y con candado si no).
class InsigniaLogro extends StatelessWidget {
  const InsigniaLogro({required this.logro, this.tamano = 56, super.key});

  final Logro logro;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final color = colorDeLogro(logro);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: tamano,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: tamano,
              height: tamano,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: logro.obtenido ? color.withValues(alpha: 0.12) : KaizenColores.fondo,
                border: Border.all(color: logro.obtenido ? color : KaizenColores.bordeControl, width: 2),
              ),
              child: Icon(KaizenIconos.porNombre(logro.icono), color: color, size: tamano * 0.5),
            ),
            if (!logro.obtenido)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: KaizenColores.superficie, shape: BoxShape.circle),
                  child: Icon(KaizenIconos.candado, size: tamano * 0.26, color: KaizenColores.textoSecundario),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
