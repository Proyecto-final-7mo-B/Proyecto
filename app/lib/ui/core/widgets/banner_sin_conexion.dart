import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../tema/colores.dart';
import '../tema/iconos.dart';
import '../tema/medidas.dart';

/// Franja que avisa que no hay red y cuántos check-ins esperan en la cola (Paso 8). Se anuncia a lectores de pantalla.
class BannerSinConexion extends StatelessWidget {
  const BannerSinConexion({this.pendientes = 0, super.key});

  final int pendientes;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        color: KaizenColores.avisoFondo,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: KaizenMedidas.e16, vertical: KaizenMedidas.e8 + 2),
          child: Row(
            children: [
              const Icon(KaizenIconos.sinConexion, size: 18, color: KaizenColores.avisoTexto),
              const SizedBox(width: KaizenMedidas.e8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: t.sinConexion,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(text: ' · ${t.registrosPorEnviar(pendientes)}'),
                    ],
                  ),
                  style: texto.labelMedium!.copyWith(color: KaizenColores.avisoTexto),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
