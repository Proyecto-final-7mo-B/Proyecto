import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../tema/colores.dart';

/// Diálogo para confirmar una acción (archivar un hábito, retirar el consentimiento, suspender una cuenta).
/// Si [peligroso], el botón de confirmar va en rojo.
class DialogoConfirmacion extends StatelessWidget {
  const DialogoConfirmacion({
    required this.titulo,
    required this.mensaje,
    this.textoConfirmar,
    this.peligroso = false,
    super.key,
  });

  final String titulo;
  final String mensaje;
  final String? textoConfirmar;
  final bool peligroso;

  /// Muestra el diálogo y devuelve `true` solo si la persona confirma (cerrar o cancelar = `false`).
  static Future<bool> mostrar(
    BuildContext context, {
    required String titulo,
    required String mensaje,
    String? textoConfirmar,
    bool peligroso = false,
  }) async {
    final respuesta = await showDialog<bool>(
      context: context,
      builder: (_) =>
          DialogoConfirmacion(titulo: titulo, mensaje: mensaje, textoConfirmar: textoConfirmar, peligroso: peligroso),
    );
    return respuesta ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: OutlinedButton.styleFrom(minimumSize: const Size(96, 44)),
          child: Text(t.cancelar),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            minimumSize: const Size(96, 44),
            backgroundColor: peligroso ? KaizenColores.error : null,
          ),
          child: Text(textoConfirmar ?? t.confirmar),
        ),
      ],
    );
  }
}
