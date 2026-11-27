import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/sync/sincronizador.dart';
import '../widgets/banner_sin_conexion.dart';

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
/// En escritorio y web, Ctrl+K (⌘K) abre la búsqueda. Sin conexión, arriba va el aviso con lo que falta enviar.
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
    final conAviso = _ConAvisoSinConexion(child: shell);
    return plataforma.tieneTeclado ? AtajoBusqueda(child: conAviso) : conAviso;
  }
}

/// Arriba de todo, "Sin conexión · N registros por enviar" mientras no haya red o quede algo en la cola (Paso 8).
class _ConAvisoSinConexion extends StatelessWidget {
  const _ConAvisoSinConexion({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<Sincronizador?>();
    if (sync == null || !sync.mostrarAviso) {
      return child;
    }
    return Column(
      children: [
        SafeArea(bottom: false, child: BannerSinConexion(pendientes: sync.pendientes)),
        Expanded(
          child: MediaQuery.removePadding(context: context, removeTop: true, child: child),
        ),
      ],
    );
  }
}
