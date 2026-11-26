import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../core/tema/colores.dart';
import '../../core/tema/medidas.dart';
import '../../core/widgets/logo_kaizen.dart';

/// Panel `marino800` con el logo, "Kaizen", el lema y la barra de 5 tonos (bosquejo 01). En pantallas amplias es la
/// mitad izquierda; en el teléfono, el encabezado.
class PanelMarca extends StatelessWidget {
  const PanelMarca({this.compacto = false, super.key});

  final bool compacto;

  /// Los 5 tonos de la barra: de oscuro a blanco, como los peldaños de la escalera.
  static const List<Color> tonos = [
    KaizenColores.marino700,
    KaizenColores.azul600,
    KaizenColores.azul400,
    KaizenColores.azul200,
    KaizenColores.superficie,
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final contenido = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          t.appTitulo,
          style: (compacto ? texto.displayMedium : texto.displayLarge)!.copyWith(
            color: KaizenColores.superficie,
            fontSize: compacto ? 40 : 64,
          ),
        ),
        const SizedBox(height: KaizenMedidas.e8),
        Text(
          t.appLema,
          style: (compacto ? texto.bodyLarge : texto.titleLarge)!.copyWith(
            color: KaizenColores.azul200,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: KaizenMedidas.e20),
        ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, color) in tonos.indexed) ...[
                if (i > 0) const SizedBox(width: KaizenMedidas.e8),
                Container(
                  width: compacto ? 32 : 50,
                  height: compacto ? 14 : 16,
                  decoration: BoxDecoration(color: color, borderRadius: KaizenMedidas.bordePildora),
                ),
              ],
            ],
          ),
        ),
      ],
    );
    return ColoredBox(
      color: KaizenColores.marino800,
      child: SafeArea(
        bottom: false,
        right: false,
        child: Padding(
          padding: compacto
              ? const EdgeInsets.fromLTRB(KaizenMedidas.e20, KaizenMedidas.e32, KaizenMedidas.e20, 56)
              : const EdgeInsets.fromLTRB(80, 70, KaizenMedidas.e32, 70),
          child: compacto
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LogoKaizen(lado: 56, sobreOscuro: true),
                    const SizedBox(height: KaizenMedidas.e24),
                    contenido,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LogoKaizen(lado: 64, sobreOscuro: true),
                    const Spacer(),
                    contenido,
                    const Spacer(flex: 2),
                  ],
                ),
        ),
      ),
    );
  }
}
