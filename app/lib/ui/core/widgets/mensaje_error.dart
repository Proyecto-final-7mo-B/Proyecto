import 'package:flutter/material.dart';

import '../tema/colores.dart';
import '../tema/iconos.dart';
import '../tema/medidas.dart';

/// Mensaje de error dentro de un formulario (p. ej., "Correo o contraseña incorrectos."). Se anuncia a los lectores
/// de pantalla en cuanto aparece.
class MensajeError extends StatelessWidget {
  const MensajeError(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: KaizenMedidas.e16, vertical: KaizenMedidas.e12),
        decoration: const BoxDecoration(color: KaizenColores.errorFondo, borderRadius: KaizenMedidas.bordeControl),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(KaizenIconos.error, size: 18, color: KaizenColores.error),
            const SizedBox(width: KaizenMedidas.e8),
            Expanded(
              child: Text(
                texto,
                style: Theme.of(context).textTheme.labelMedium!
                    .copyWith(color: KaizenColores.error, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
