import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../tema/colores.dart';
import '../tema/iconos.dart';
import '../tema/medidas.dart';

/// Botón "‹" cuadrado de los bosquejos (Nuevo hábito, Detalle). Regresa a la pantalla anterior o, si se llegó por
/// un enlace directo y no hay a dónde regresar, a [respaldo].
class BotonVolver extends StatelessWidget {
  const BotonVolver({required this.respaldo, super.key});

  final String respaldo;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppLocalizations.of(context).volver,
      onPressed: () => context.canPop() ? context.pop() : context.go(respaldo),
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        backgroundColor: KaizenColores.superficie,
        side: const BorderSide(color: KaizenColores.borde),
        shape: const RoundedRectangleBorder(borderRadius: KaizenMedidas.bordeControl),
      ),
      icon: const Icon(KaizenIconos.atras),
    );
  }
}

/// Encabezado de las pantallas internas en el teléfono: "‹ Título" con un subtítulo opcional y acciones a la derecha.
class EncabezadoInterno extends StatelessWidget {
  const EncabezadoInterno({
    required this.titulo,
    required this.respaldo,
    this.subtitulo,
    this.acciones = const [],
    super.key,
  });

  final String titulo;
  final String? subtitulo;
  final String respaldo;
  final List<Widget> acciones;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Row(
      children: [
        BotonVolver(respaldo: respaldo),
        const SizedBox(width: KaizenMedidas.e12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(titulo, style: texto.headlineSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              if (subtitulo != null)
                Text(
                  subtitulo!,
                  style: texto.bodySmall!.copyWith(color: KaizenColores.textoSecundario),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        ...acciones,
      ],
    );
  }
}
