import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../tema/colores.dart';
import '../tema/iconos.dart';

/// Llama y número de días de racha en `naranjaRacha`. Si el hábito tiene una cápsula sellada, va el reloj de arena
/// antes de la llama (como "Ejercicio" en el bosquejo de Hoy).
class IndicadorRacha extends StatelessWidget {
  const IndicadorRacha({required this.dias, this.conCapsula = false, this.tamano = 16, super.key});

  final int dias;
  final bool conCapsula;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final estilo = Theme.of(context).textTheme.labelLarge!
        .copyWith(color: KaizenColores.naranjaRacha, fontSize: tamano * 0.9, fontWeight: FontWeight.w800);
    final etiqueta = conCapsula ? '${t.rachaDias(dias)}, ${t.conCapsulaSellada}' : t.rachaDias(dias);
    return Semantics(
      label: etiqueta,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (conCapsula) ...[
              Icon(KaizenIconos.capsulaSellada, size: tamano, color: KaizenColores.naranjaRacha),
              SizedBox(width: tamano * 0.4),
            ],
            Icon(KaizenIconos.racha, size: tamano, color: KaizenColores.naranjaRacha),
            SizedBox(width: tamano * 0.2),
            Text('$dias', style: estilo),
          ],
        ),
      ),
    );
  }
}
