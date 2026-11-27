import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../utils/hitos.dart';
import '../apariencia_racha.dart';
import '../tema/colores.dart';
import '../tema/medidas.dart';

/// Celebración al cruzar un hito de racha (7, 30, 66, 100; doc. 05). La animación dura menos de 1.5 s: el refuerzo
/// breve ayuda, pero no es lo que forma el hábito (F48). Con "reducir movimiento" del sistema no se anima.
Future<void> mostrarCelebracion(BuildContext context, {required int hito, required String habito}) => showDialog<void>(
  context: context,
  builder: (_) => CelebracionHito(hito: hito, habito: habito),
);

class CelebracionHito extends StatelessWidget {
  const CelebracionHito({required this.hito, required this.habito, super.key});

  final int hito;
  final String habito;

  static const Duration duracion = Duration(milliseconds: 900);

  /// El texto con el dato científico de cada hito.
  static String mensaje(int hito, AppLocalizations t) => switch (hito) {
    7 => t.celebracion7,
    30 => t.celebracion30,
    Hitos.habitoFormado => t.celebracion66,
    100 => t.celebracion100,
    _ => t.celebracionMas,
  };

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final nivel = NivelRacha.deDias(hito);
    final sinMovimiento = MediaQuery.disableAnimationsOf(context);
    return AlertDialog(
      contentPadding: const EdgeInsets.fromLTRB(KaizenMedidas.e24, KaizenMedidas.e24, KaizenMedidas.e24, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            key: const ValueKey('animacion-hito'),
            tween: Tween(begin: sinMovimiento ? 1 : 0.4, end: 1),
            duration: sinMovimiento ? Duration.zero : duracion,
            curve: Curves.elasticOut,
            builder: (context, escala, hijo) => Transform.scale(scale: escala, child: hijo),
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: KaizenColores.fondoDe(nivel.color),
                border: nivel.colorAro == null ? null : Border.all(color: nivel.colorAro!, width: 4),
              ),
              child: Icon(nivel.icono, size: 56, color: nivel.color),
            ),
          ),
          const SizedBox(height: KaizenMedidas.e16),
          Semantics(
            header: true,
            liveRegion: true,
            child: Text(t.celebracionTitulo(hito), style: texto.headlineSmall, textAlign: TextAlign.center),
          ),
          const SizedBox(height: KaizenMedidas.e4),
          Text(habito, style: texto.titleMedium!.copyWith(color: nivel.color), textAlign: TextAlign.center),
          const SizedBox(height: KaizenMedidas.e12),
          Text(mensaje(hito, t), style: texto.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(t.celebracionSeguir)),
      ],
    );
  }
}
