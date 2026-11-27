import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../utils/hitos.dart';
import '../apariencia_racha.dart';
import '../tema/colores.dart';
import '../tema/iconos.dart';

/// Símbolo y número de días de racha. El símbolo **cambia por nivel** (doc. 05): gris sin racha, chispa ámbar de 1 a 6,
/// llama naranja de 7 a 29, llama con aro de 30 a 65, dorado desde 66 ("hábito formado") y emblema desde 100.
///
/// - [conCapsula]: el reloj de arena va antes (como "Ejercicio" en el bosquejo de Hoy).
/// - [protegida]: el escudo del protector de racha (ya se perdonó la falla de esta semana).
class IndicadorRacha extends StatelessWidget {
  const IndicadorRacha({
    required this.dias,
    this.conCapsula = false,
    this.protegida = false,
    this.tamano = 16,
    super.key,
  });

  final int dias;
  final bool conCapsula;
  final bool protegida;
  final double tamano;

  NivelRacha get nivel => NivelRacha.deDias(dias);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final n = nivel;
    final lado = tamano * n.escala;
    final estilo = Theme.of(context).textTheme.labelLarge!
        .copyWith(color: n.color, fontSize: tamano * 0.9, fontWeight: FontWeight.w800);
    final partes = [
      t.rachaDias(dias),
      ?n.nombre(t),
      if (protegida) t.rachaProtegida,
      if (conCapsula) t.conCapsulaSellada,
    ];
    final simbolo = Icon(n.icono, size: lado, color: n.color);
    final aro = n.colorAro;
    return Semantics(
      label: partes.join(', '),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (conCapsula) ...[
              Icon(KaizenIconos.capsulaSellada, size: tamano, color: KaizenColores.naranjaRacha),
              SizedBox(width: tamano * 0.4),
            ],
            if (protegida) ...[
              Icon(KaizenIconos.protector, size: tamano * 0.9, color: KaizenColores.azul600),
              SizedBox(width: tamano * 0.25),
            ],
            if (aro == null)
              simbolo
            else
              Container(
                key: const ValueKey('aro-racha'),
                padding: EdgeInsets.all(tamano * 0.12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: aro, width: tamano * 0.1),
                ),
                child: Icon(n.icono, size: lado * 0.8, color: n.color),
              ),
            SizedBox(width: tamano * 0.2),
            Text('$dias', style: estilo),
          ],
        ),
      ),
    );
  }
}
