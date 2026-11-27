import 'package:flutter/material.dart';

import '../../core/tema/colores.dart';
import '../../core/tema/medidas.dart';

/// Una opción con ícono y el color de su categoría.
typedef OpcionConIcono<T> = ({T valor, String etiqueta, IconData icono, Color color});

/// Chips en píldora con ícono, para elegir categoría y subcategoría. El color de la categoría marca el ícono y, al
/// elegir, el borde y el fondo (al 12 %); el texto siempre va en `texto` (contraste ≥ 14:1, doc. 04). El color nunca
/// es la única señal: el elegido también lleva borde grueso y la palomita (WCAG 1.4.1).
class ChipsConIcono<T> extends StatelessWidget {
  const ChipsConIcono({required this.opciones, required this.seleccionado, required this.onCambio, super.key});

  final List<OpcionConIcono<T>> opciones;
  final T? seleccionado;

  /// `null` = deshabilitado.
  final ValueChanged<T>? onCambio;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w700);
    return Wrap(
      spacing: KaizenMedidas.e8,
      runSpacing: KaizenMedidas.e8,
      children: [
        for (final o in opciones)
          _ChipConIcono(
            opcion: o,
            elegido: o.valor == seleccionado,
            estilo: estilo,
            onTap: onCambio == null ? null : () => onCambio!(o.valor),
          ),
      ],
    );
  }
}

class _ChipConIcono<T> extends StatelessWidget {
  const _ChipConIcono({required this.opcion, required this.elegido, required this.estilo, required this.onTap});

  final OpcionConIcono<T> opcion;
  final bool elegido;
  final TextStyle estilo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = opcion.color;
    return Semantics(
      button: true,
      selected: elegido,
      enabled: onTap != null,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: elegido ? KaizenColores.fondoDe(color) : KaizenColores.superficie,
        shape: StadiumBorder(
          side: BorderSide(color: elegido ? color : KaizenColores.bordeCampo, width: elegido ? 2 : 1),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(KaizenMedidas.e12, 10, KaizenMedidas.e16, 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(child: Icon(elegido ? Icons.check : opcion.icono, size: 18, color: color)),
                const SizedBox(width: KaizenMedidas.e8),
                Text(opcion.etiqueta, style: estilo.copyWith(color: KaizenColores.texto)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
