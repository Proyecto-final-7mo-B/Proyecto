import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../routing/estado_sesion.dart';
import '../../../routing/rutas.dart';
import '../tema/colores.dart';
import '../tema/medidas.dart';
import '../widgets/avatar_usuario.dart';
import '../widgets/icono_escalera.dart';
import '../widgets/logo_kaizen.dart';
import 'destinos.dart';
import 'plataforma.dart';

/// Riel lateral `marino900` (bosquejos de escritorio). [extendido] (≥ 1200 px) muestra los nombres al lado de los
/// íconos y al usuario abajo; si no (600–1199 px), es un riel angosto con los nombres debajo.
class ShellEscritorio extends StatelessWidget {
  const ShellEscritorio({required this.ubicacion, required this.child, required this.extendido, super.key});

  final String ubicacion;
  final Widget child;
  final bool extendido;

  static const double anchoExtendido = 232;
  static const double anchoAngosto = 88;

  @override
  Widget build(BuildContext context) {
    final sesion = context.watch<EstadoSesion>();
    final destinos = destinosDe(
      t: AppLocalizations.of(context),
      plataforma: PlataformaApp.de(context),
      esAdmin: sesion.esAdmin,
      compacto: false,
    );
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RielLateral(
            destinos: destinos,
            seleccionado: indiceSeleccionado(destinos, ubicacion),
            extendido: extendido,
            usuario: sesion.usuario,
            onElegir: (ruta) => context.go(ruta),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class RielLateral extends StatelessWidget {
  const RielLateral({
    required this.destinos,
    required this.seleccionado,
    required this.extendido,
    required this.usuario,
    required this.onElegir,
    super.key,
  });

  final List<Destino> destinos;
  final int? seleccionado;
  final bool extendido;
  final UsuarioSesion? usuario;
  final ValueChanged<String> onElegir;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Container(
      width: extendido ? ShellEscritorio.anchoExtendido : ShellEscritorio.anchoAngosto,
      color: KaizenColores.marino900,
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: extendido ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(extendido ? 20 : 0, 20, extendido ? 20 : 0, 24),
              child: Align(
                alignment: extendido ? Alignment.centerLeft : Alignment.center,
                child: InkWell(
                  onTap: () => onElegir(Rutas.hoy),
                  child: LogoKaizen(sobreOscuro: true, conNombre: extendido),
                ),
              ),
            ),
            Expanded(
              child: Semantics(
                container: true,
                explicitChildNodes: true,
                label: t.menuPrincipal,
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: extendido ? 14 : 8),
                  children: [
                    for (var i = 0; i < destinos.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: KaizenMedidas.e4),
                        child: _ItemRiel(
                          destino: destinos[i],
                          elegido: i == seleccionado,
                          extendido: extendido,
                          onTap: () => onElegir(destinos[i].ruta),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (usuario != null)
              _PieUsuario(usuario: usuario!, extendido: extendido, onTap: () => onElegir(Rutas.perfil)),
          ],
        ),
      ),
    );
  }
}

class _ItemRiel extends StatelessWidget {
  const _ItemRiel({required this.destino, required this.elegido, required this.extendido, required this.onTap});

  final Destino destino;
  final bool elegido;
  final bool extendido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = elegido ? KaizenColores.superficie : KaizenColores.azul100;
    final texto = Theme.of(context).textTheme;
    final icono = destino.icono == null
        ? IconoEscalera(tamano: 22, color: color)
        : Icon(destino.icono, size: 22, color: color);
    final contenido = extendido
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                icono,
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    destino.etiqueta,
                    overflow: TextOverflow.ellipsis,
                    style: texto.bodyLarge!.copyWith(
                      color: color,
                      fontWeight: elegido ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              children: [
                icono,
                const SizedBox(height: KaizenMedidas.e4),
                Text(
                  destino.etiqueta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: texto.labelSmall!.copyWith(
                    color: color,
                    fontSize: 11,
                    fontWeight: elegido ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
    return Semantics(
      button: true,
      selected: elegido,
      label: destino.etiqueta,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: elegido ? KaizenColores.azul600 : Colors.transparent,
          borderRadius: KaizenMedidas.bordeControl,
          child: InkWell(borderRadius: KaizenMedidas.bordeControl, onTap: onTap, child: contenido),
        ),
      ),
    );
  }
}

class _PieUsuario extends StatelessWidget {
  const _PieUsuario({required this.usuario, required this.extendido, required this.onTap});

  final UsuarioSesion usuario;
  final bool extendido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final avatar = AvatarUsuario(inicial: usuario.inicial, sobreOscuro: true);
    return Semantics(
      button: true,
      label: t.abrirPerfil(usuario.nombre),
      onTap: onTap,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: extendido ? 24 : 0, vertical: 20),
            child: extendido
                ? Row(
                    children: [
                      avatar,
                      const SizedBox(width: KaizenMedidas.e12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              usuario.nombre,
                              overflow: TextOverflow.ellipsis,
                              style: texto.titleSmall!.copyWith(color: KaizenColores.superficie),
                            ),
                            if (usuario.nombreRegion != null)
                              Text(
                                t.regionDe(usuario.nombreRegion!),
                                maxLines: 2,
                                style: texto.bodySmall!.copyWith(color: KaizenColores.azul200),
                              ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Center(child: avatar),
          ),
        ),
      ),
    );
  }
}
