import 'package:flutter/material.dart';

import '../tema/colores.dart';
import '../tema/medidas.dart';
import 'icono_escalera.dart';

/// Logo: escalera en un cuadro redondeado, opcionalmente con el nombre "Kaizen".
///
/// - Sobre fondo oscuro (riel, panel del login): cuadro blanco con escalera `marino800`.
/// - Sobre fondo claro: cuadro `marino800` con escalera blanca.
class LogoKaizen extends StatelessWidget {
  const LogoKaizen({this.lado = 36, this.sobreOscuro = false, this.conNombre = false, super.key});

  final double lado;
  final bool sobreOscuro;
  final bool conNombre;

  @override
  Widget build(BuildContext context) {
    final fondo = sobreOscuro ? KaizenColores.superficie : KaizenColores.marino800;
    final trazo = sobreOscuro ? KaizenColores.marino800 : KaizenColores.superficie;
    final cuadro = Container(
      width: lado,
      height: lado,
      decoration: BoxDecoration(color: fondo, borderRadius: BorderRadius.circular(lado * 0.28)),
      padding: EdgeInsets.all(lado * 0.2),
      child: IconoEscalera(color: trazo),
    );
    if (!conNombre) {
      return Semantics(
        label: 'Kaizen',
        image: true,
        child: ExcludeSemantics(child: cuadro),
      );
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
