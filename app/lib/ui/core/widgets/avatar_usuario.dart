import 'package:flutter/material.dart';

import '../tema/colores.dart';

/// Círculo con la inicial del usuario (barra superior web, riel lateral). Si tiene [onTap], abre el perfil.
class AvatarUsuario extends StatelessWidget {
  const AvatarUsuario({
    required this.inicial,
    this.lado = 36,
    this.sobreOscuro = false,
    this.onTap,
    this.etiquetaSemantica,
    super.key,
  });

  final String inicial;
  final double lado;

  /// En el riel oscuro el círculo va en `azul600`; sobre fondo claro, en `marino800`.
  final bool sobreOscuro;
  final VoidCallback? onTap;
  final String? etiquetaSemantica;

  @override
  Widget build(BuildContext context) {
    final circulo = Material(
      color: sobreOscuro ? KaizenColores.azul600 : KaizenColores.marino800,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox.square(
          dimension: lado,
          child: Center(
            child: Text(
              inicial,
              style: Theme.of(context).textTheme.labelLarge!
                  .copyWith(color: KaizenColores.superficie, fontSize: lado * 0.4, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      button: onTap != null,
      label: etiquetaSemantica,
      child: ExcludeSemantics(child: circulo),
    );
  }
}
