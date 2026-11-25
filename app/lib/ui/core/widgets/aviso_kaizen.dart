import 'package:flutter/material.dart';

import '../tema/colores.dart';
import '../tema/medidas.dart';

/// Aviso en ámbar ("La foto solo se agrega desde Android, con cámara o galería.").
class AvisoKaizen extends StatelessWidget {
  const AvisoKaizen({required this.texto, this.icono, super.key});

  final String texto;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.labelMedium!
        .copyWith(color: KaizenColores.avisoTexto, fontWeight: FontWeight.w700);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: KaizenMedidas.e16, vertical: KaizenMedidas.e12),
      decoration: const BoxDecoration(color: KaizenColores.avisoFondo, borderRadius: KaizenMedidas.bordeControl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 18, color: KaizenColores.avisoTexto),
            const SizedBox(width: KaizenMedidas.e8),
          ],
          Expanded(child: Text(texto, style: estilo)),
        ],
      ),
    );
  }
}
