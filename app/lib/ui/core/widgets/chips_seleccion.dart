import 'package:flutter/material.dart';

import '../tema/colores.dart';
import '../tema/medidas.dart';
import 'selector_segmentado.dart';

/// Chips en píldora para elegir una opción (categoría, cápsula 7/21/66) o varias (días de la semana).
/// El elegido va en `marino800` con texto blanco.
class ChipsSeleccion<T> extends StatelessWidget {
  const ChipsSeleccion({
    required this.opciones,
    required this.seleccionados,
    required this.onCambio,
    this.multiple = false,
    this.permitirVacio = false,
    super.key,
  });

  final List<Opcion<T>> opciones;
  final Set<T> seleccionados;

  /// `null` = deshabilitado.
  final ValueChanged<Set<T>>? onCambio;

  /// `true`: se pueden elegir varias opciones.
  final bool multiple;

  /// `true`: se puede quitar la última opción elegida y quedar sin ninguna.
  final bool permitirVacio;

  /// Conjunto que resulta de tocar [valor] con el estado actual.
  Set<T> alTocar(T valor) {
    final elegido = seleccionados.contains(valor);
    if (!multiple) {
      if (elegido) {
        return permitirVacio ? <T>{} : seleccionados;
      }
      return {valor};
    }
    if (elegido) {
      final nuevo = {...seleccionados}..remove(valor);
      return nuevo.isEmpty && !permitirVacio ? seleccionados : nuevo;
    }
    return {...seleccionados, valor};
  }

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w700);
    return Wrap(
      spacing: KaizenMedidas.e8,
      runSpacing: KaizenMedidas.e8,
      children: [
        for (final opcion in opciones)
          _Chip(
            etiqueta: opcion.etiqueta,
            elegido: seleccionados.contains(opcion.valor),
            estilo: estilo,
            multiple: multiple,
            onTap: onCambio == null
                ? null
                : () {
                    final nuevo = alTocar(opcion.valor);
                    if (!_iguales(nuevo, seleccionados)) {
                      onCambio!(nuevo);
                    }
                  },
          ),
      ],
    );
  }

  static bool _iguales<E>(Set<E> a, Set<E> b) => a.length == b.length && a.containsAll(b);
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.etiqueta,
    required this.elegido,
    required this.estilo,
    required this.multiple,
    required this.onTap,
  });

  final String etiqueta;
  final bool elegido;
  final TextStyle estilo;
  final bool multiple;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: elegido,
      enabled: onTap != null,
      inMutuallyExclusiveGroup: !multiple,
      child: Material(
        color: elegido ? KaizenColores.marino800 : KaizenColores.superficie,
        shape: StadiumBorder(side: BorderSide(color: elegido ? KaizenColores.marino800 : KaizenColores.bordeCampo)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: KaizenMedidas.e16, vertical: KaizenMedidas.e12),
            child: Text(
              etiqueta,
              style: estilo.copyWith(color: elegido ? KaizenColores.superficie : KaizenColores.texto),
            ),
          ),
        ),
      ),
    );
  }
}
