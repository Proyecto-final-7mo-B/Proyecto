import 'package:flutter/material.dart';

import '../tema/colores.dart';
import '../tema/medidas.dart';

/// Una opción de un selector: el valor que devuelve y el texto que se ve.
typedef Opcion<T> = ({T valor, String etiqueta});

/// Selector de una sola opción en una barra `azul100` con la opción elegida en blanco ("Diario | L-V | N por sem.",
/// "Semana | Mes | Año").
class SelectorSegmentado<T> extends StatelessWidget {
  const SelectorSegmentado({required this.opciones, required this.seleccionado, required this.onCambio, super.key});

  final List<Opcion<T>> opciones;
  final T seleccionado;

  /// `null` = deshabilitado.
  final ValueChanged<T>? onCambio;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(KaizenMedidas.e4),
      decoration: const BoxDecoration(color: KaizenColores.azul100, borderRadius: KaizenMedidas.bordeControl),
      child: Row(
        children: [
          for (final opcion in opciones)
            Expanded(
              child: _Segmento(
                etiqueta: opcion.etiqueta,
                elegido: opcion.valor == seleccionado,
                estilo: texto.labelMedium!,
                onTap: onCambio == null || opcion.valor == seleccionado ? null : () => onCambio!(opcion.valor),
                habilitado: onCambio != null,
              ),
            ),
        ],
      ),
    );
  }
}

class _Segmento extends StatelessWidget {
  const _Segmento({
    required this.etiqueta,
    required this.elegido,
    required this.estilo,
    required this.onTap,
    required this.habilitado,
  });

  final String etiqueta;
  final bool elegido;
  final TextStyle estilo;
  final VoidCallback? onTap;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    const radio = BorderRadius.all(Radius.circular(KaizenMedidas.radioControl - 2));
    return Semantics(
      button: true,
      selected: elegido,
      enabled: habilitado,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: elegido ? KaizenColores.superficie : Colors.transparent,
        borderRadius: radio,
        child: InkWell(
          borderRadius: radio,
          onTap: onTap,
          child: Container(
            height: 40,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: KaizenMedidas.e8),
            child: Text(
              etiqueta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: estilo.copyWith(
                fontWeight: elegido ? FontWeight.w700 : FontWeight.w500,
                color: elegido ? KaizenColores.texto : KaizenColores.textoSecundario,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
