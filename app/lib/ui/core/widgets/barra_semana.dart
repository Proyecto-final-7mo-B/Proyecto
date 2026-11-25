import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../utils/fechas.dart';
import '../tema/colores.dart';
import '../tema/medidas.dart';

/// Siete cuadros de lunes a domingo con la intensidad de cumplimiento de cada día (0–4) y la inicial debajo.
///
/// `null` = día sin dato todavía (futuro o sin hábitos programados): se ve en blanco.
class BarraSemana extends StatelessWidget {
  const BarraSemana({required this.niveles, this.sobreOscuro = false, this.altoCelda = 32, super.key});

  /// Exactamente 7 valores, de lunes a domingo.
  final List<int?> niveles;
  final bool sobreOscuro;
  final double altoCelda;

  /// Sobre la tarjeta `marino800` la escala va de blanco a `azul600`, para que se vea contra el fondo oscuro.
  static const List<Color> escalaSobreOscuro = [
    KaizenColores.superficie,
    KaizenColores.azul100,
    KaizenColores.azul200,
    KaizenColores.azul400,
    KaizenColores.azul600,
  ];

  Color colorDe(int? nivel) {
    if (nivel == null) {
      return KaizenColores.superficie;
    }
    final n = nivel.clamp(0, 4);
    return sobreOscuro ? escalaSobreOscuro[n] : KaizenColores.deIntensidad(n);
  }

  @override
  Widget build(BuildContext context) {
    assert(niveles.length == 7, 'La semana tiene 7 días (lunes a domingo)');
    final t = AppLocalizations.of(context);
    final estiloInicial = Theme.of(context).textTheme.labelSmall!
        .copyWith(color: sobreOscuro ? KaizenColores.azul200 : KaizenColores.textoSecundario);
    return Row(
      children: [
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: KaizenMedidas.e8),
          Expanded(
            child: Semantics(
              label:
                  '${Fechas.diasSemana[i]}: ${niveles[i] == null ? t.sinDatos : t.nivelDeCuatro(niveles[i]!.clamp(0, 4))}',
              child: ExcludeSemantics(
                child: Column(
                  children: [
                    Container(
                      height: altoCelda,
                      decoration: BoxDecoration(
                        color: colorDe(niveles[i]),
                        borderRadius: KaizenMedidas.bordeCelda,
                        border: !sobreOscuro && niveles[i] == null ? Border.all(color: KaizenColores.borde) : null,
                      ),
                    ),
                    const SizedBox(height: KaizenMedidas.e8),
                    Text(Fechas.inicialesSemana[i], style: estiloInicial),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
