import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../routing/estado_sesion.dart';
import '../tema/colores.dart';
import '../tema/medidas.dart';
import '../widgets/icono_escalera.dart';
import 'destinos.dart';
import 'plataforma.dart';

/// Pantallas compactas (< 600 px): contenido arriba y barra inferior con 5 destinos (bosquejos móviles).
class ShellMovil extends StatelessWidget {
  const ShellMovil({required this.ubicacion, required this.child, super.key});

  final String ubicacion;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final destinos = destinosDe(
      t: AppLocalizations.of(context),
      plataforma: PlataformaApp.de(context),
      esAdmin: context.watch<EstadoSesion>().esAdmin,
      compacto: true,
    );
    return Scaffold(
      body: SafeArea(bottom: false, child: child),
      bottomNavigationBar: BarraInferior(
        destinos: destinos,
        seleccionado: indiceSeleccionado(destinos, ubicacion),
        onElegir: (d) => context.go(d.ruta),
      ),
    );
  }
}

class BarraInferior extends StatelessWidget {
  const BarraInferior({required this.destinos, required this.seleccionado, required this.onElegir, super.key});

  final List<Destino> destinos;
  final int? seleccionado;
  final ValueChanged<Destino> onElegir;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: AppLocalizations.of(context).menuPrincipal,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: KaizenColores.superficie,
          border: Border(top: BorderSide(color: KaizenColores.borde)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 72,
            child: Row(
              children: [
                for (var i = 0; i < destinos.length; i++)
                  Expanded(
                    child: _ItemInferior(
                      destino: destinos[i],
                      elegido: i == seleccionado,
                      onTap: () => onElegir(destinos[i]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemInferior extends StatelessWidget {
  const _ItemInferior({required this.destino, required this.elegido, required this.onTap});

  final Destino destino;
  final bool elegido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.labelSmall!
        .copyWith(color: KaizenColores.texto, fontWeight: elegido ? FontWeight.w800 : FontWeight.w500);
    return Semantics(
      button: true,
      selected: elegido,
      label: destino.etiqueta,
      onTap: onTap,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 56,
                height: 32,
                decoration: BoxDecoration(
                  color: elegido ? KaizenColores.azul100 : Colors.transparent,
                  borderRadius: KaizenMedidas.bordePildora,
                ),
                child: Center(
                  child: destino.icono == null
                      ? const IconoEscalera(tamano: 22, color: KaizenColores.texto)
                      : Icon(destino.icono, size: 22, color: KaizenColores.texto),
                ),
              ),
              const SizedBox(height: KaizenMedidas.e4),
              Text(destino.etiqueta, style: estilo, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
