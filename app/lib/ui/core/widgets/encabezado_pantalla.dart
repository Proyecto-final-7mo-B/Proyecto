import 'package:flutter/material.dart';

import '../adaptativo/breakpoints.dart';
import '../adaptativo/busqueda.dart';
import '../adaptativo/plataforma.dart';
import '../tema/medidas.dart';

/// Encabezado de cada pantalla: título grande ("Hoy"), subtítulo opcional ("Domingo 8 de noviembre") y acciones a la
/// derecha. En escritorio amplio agrega el campo "Buscar · Ctrl K", como en los bosquejos de escritorio.
class EncabezadoPantalla extends StatelessWidget {
  const EncabezadoPantalla({required this.titulo, this.subtitulo, this.acciones = const [], super.key});

  final String titulo;
  final String? subtitulo;
  final List<Widget> acciones;

  static bool muestraBuscar(Plataforma plataforma, TamanoPantalla tamano) =>
      plataforma == Plataforma.escritorio && tamano == TamanoPantalla.amplio;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final buscar = muestraBuscar(PlataformaApp.de(context), TamanoPantalla.de(context));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(header: true, child: Text(titulo, style: texto.headlineLarge)),
              if (subtitulo != null) ...[
                const SizedBox(height: 2),
                Text(subtitulo!, style: texto.bodyMedium!.copyWith(color: texto.bodySmall!.color)),
              ],
            ],
          ),
        ),
        if (buscar) ...[const SizedBox(width: KaizenMedidas.e16), const CampoBuscar()],
        for (final accion in acciones) ...[const SizedBox(width: KaizenMedidas.e12), accion],
      ],
    );
  }
}
