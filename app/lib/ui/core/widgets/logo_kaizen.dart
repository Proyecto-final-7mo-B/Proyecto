import 'package:flutter/material.dart';

import '../tema/colores.dart';
import '../tema/medidas.dart';

/// Logo de Kaizen: un **ensō** (círculo zen de pincel) con piedras que suben como una escalera hasta una flor de
/// cerezo: la meta se alcanza paso a paso. Va en un cuadro blanco redondeado, opcionalmente con el nombre "Kaizen".
///
/// - Sobre fondo oscuro (riel, panel de la entrada): el cuadro blanco resalta solo.
/// - Sobre fondo claro: el cuadro lleva un borde suave para no perderse en el fondo.
///
/// La imagen es `assets/imagenes/logo_kaizen.png`; los íconos de cada plataforma salen del mismo dibujo
/// (`herramientas/generador_logo/`).
class LogoKaizen extends StatelessWidget {
  const LogoKaizen({this.lado = 36, this.sobreOscuro = false, this.conNombre = false, super.key});

  static const String rutaImagen = 'assets/imagenes/logo_kaizen.png';

  final double lado;
  final bool sobreOscuro;
  final bool conNombre;

  @override
  Widget build(BuildContext context) {
    final cuadro = Container(
      width: lado,
      height: lado,
      decoration: BoxDecoration(
        color: KaizenColores.superficie,
        borderRadius: BorderRadius.circular(lado * 0.225),
        border: sobreOscuro ? null : Border.all(color: KaizenColores.borde),
      ),
      padding: EdgeInsets.all(lado * 0.07),
      child: Image.asset(rutaImagen, filterQuality: FilterQuality.medium),
    );
    if (!conNombre) {
      return Semantics(label: 'Kaizen', image: true, child: ExcludeSemantics(child: cuadro));
    }
    final estilo = Theme.of(context).textTheme.titleLarge!.copyWith(
      fontSize: lado * 0.6,
      fontWeight: FontWeight.w800,
      color: sobreOscuro ? KaizenColores.superficie : KaizenColores.texto,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: cuadro),
        SizedBox(width: lado * 0.3 + KaizenMedidas.e4),
        Text('Kaizen', style: estilo),
      ],
    );
  }
}
