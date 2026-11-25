import 'package:flutter/material.dart';

import 'breakpoints.dart';
import 'busqueda.dart';
import 'plataforma.dart';
import 'shell_escritorio.dart';
import 'shell_movil.dart';
import 'shell_web.dart';

/// Elige el marco de navegación según el ancho y la plataforma:
///
/// | Ancho | Móvil | Escritorio | Web |
/// |---|---|---|---|
/// | < 600 | barra inferior | barra inferior | barra inferior |
/// | 600–1199 | riel angosto | riel angosto | riel angosto |
/// | ≥ 1200 | riel extendido | riel extendido | barra superior |
///
/// En escritorio y web, Ctrl+K (⌘K) abre la búsqueda.
class ShellAdaptativo extends StatelessWidget {
  const ShellAdaptativo({required this.ubicacion, required this.child, super.key});

  final String ubicacion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final plataforma = PlataformaApp.de(context);
    final shell = switch ((TamanoPantalla.de(context), plataforma)) {
      (TamanoPantalla.compacto, _) => ShellMovil(ubicacion: ubicacion, child: child),
      (TamanoPantalla.medio, _) => ShellEscritorio(ubicacion: ubicacion, extendido: false, child: child),
      (TamanoPantalla.amplio, Plataforma.web) => ShellWeb(ubicacion: ubicacion, child: child),
      (TamanoPantalla.amplio, _) => ShellEscritorio(ubicacion: ubicacion, extendido: true, child: child),
    };
    return plataforma.tieneTeclado ? AtajoBusqueda(child: shell) : shell;
  }
}
