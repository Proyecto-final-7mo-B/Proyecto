import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../routing/estado_sesion.dart';
import '../../../routing/rutas.dart';
import '../tema/colores.dart';
import '../tema/iconos.dart';
import '../tema/medidas.dart';
import '../widgets/avatar_usuario.dart';
import '../widgets/logo_kaizen.dart';
import 'breakpoints.dart';
import 'destinos.dart';
import 'plataforma.dart';

/// Web en pantallas amplias (≥ 1200 px): barra superior blanca con la marca, las secciones en píldoras, el botón
/// "Nuevo hábito" y el avatar (bosquejos web).
class ShellWeb extends StatelessWidget {
  const ShellWeb({required this.ubicacion, required this.child, super.key});

  final String ubicacion;
  final Widget child;

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
      body: Column(
        children: [
          BarraSuperior(
            destinos: destinos,
            seleccionado: indiceSeleccionado(destinos, ubicacion),
            usuario: sesion.usuario,
            onElegir: (ruta) => context.go(ruta),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class BarraSuperior extends StatelessWidget {
  const BarraSuperior({
    required this.destinos,
    required this.seleccionado,
    required this.usuario,
    required this.onElegir,
    super.key,
  });

  final List<Destino> destinos;
  final int? seleccionado;
  final UsuarioSesion? usuario;
  final ValueChanged<String> onElegir;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: KaizenColores.superficie,
        border: Border(bottom: BorderSide(color: KaizenColores.borde)),
      ),
      child: SizedBox(
        height: 68,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: anchoMaximoContenido),
            child: Padding(
              // Mismo margen que el contenido de las pantallas (32 px), para que la marca y el título queden alineados.
              padding: const EdgeInsets.symmetric(horizontal: KaizenMedidas.e32),
              child: Row(
                children: [
                  InkWell(onTap: () => onElegir(Rutas.hoy), child: const LogoKaizen(conNombre: true)),
                  const SizedBox(width: KaizenMedidas.e32),
                  Expanded(
                    child: Semantics(
                      container: true,
                      explicitChildNodes: true,
                      label: t.menuPrincipal,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (var i = 0; i < destinos.length; i++)
                              _PildoraDestino(
                                destino: destinos[i],
                                elegido: i == seleccionado,
                                onTap: () => onElegir(destinos[i].ruta),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: KaizenMedidas.e16),
                  FilledButton.icon(
                    onPressed: () => onElegir(Rutas.nuevoHabito),
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                    icon: const Icon(KaizenIconos.agregar),
                    label: Text(t.nuevoHabito),
                  ),
                  if (usuario != null) ...[
                    const SizedBox(width: KaizenMedidas.e24),
                    AvatarUsuario(
                      inicial: usuario!.inicial,
                      etiquetaSemantica: t.abrirPerfil(usuario!.nombre),
                      onTap: () => onElegir(Rutas.perfil),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PildoraDestino extends StatelessWidget {
  const _PildoraDestino({required this.destino, required this.elegido, required this.onTap});

  final Destino destino;
  final bool elegido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.bodyMedium!.copyWith(
      color: elegido ? KaizenColores.texto : KaizenColores.textoSecundario,
      fontWeight: elegido ? FontWeight.w700 : FontWeight.w500,
    );
    return Semantics(
      button: true,
      selected: elegido,
      label: destino.etiqueta,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(right: KaizenMedidas.e4),
          child: Material(
            color: elegido ? KaizenColores.azul100 : Colors.transparent,
            shape: const StadiumBorder(),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text(destino.etiqueta, style: estilo),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
