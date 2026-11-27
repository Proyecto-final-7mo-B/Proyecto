import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../utils/reloj.dart';
import '../../hoy/consejos.dart';
import '../tema/colores.dart';
import '../tema/iconos.dart';
import '../tema/medidas.dart';

/// "Consejo saludable" del día en el riel extendido de escritorio (decisión del 27-nov): siempre a la vista, sin ocupar
/// el contenido. Solo el consejo: sin cita y sin enlace (las fuentes están en la sección "Acerca de"). Cambia cada día
/// (14 consejos, `ConsejosEvidencia.delDia`).
class ConsejoRiel extends StatelessWidget {
  const ConsejoRiel({super.key});

  /// La fecha sale del [Reloj] de la app (fijo en las pruebas); si no hay, la del sistema.
  static DateTime _hoy(BuildContext context) {
    try {
      return context.read<Reloj>()();
    } on ProviderNotFoundException {
      return DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final c = ConsejosEvidencia.de(t, ConsejosEvidencia.delDia(_hoy(context)));
    return Semantics(
      container: true,
      label: '${t.consejoTitulo}. ${c.texto}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, KaizenMedidas.e8, 14, 0),
          child: DecoratedBox(
            decoration: const BoxDecoration(color: KaizenColores.marino800, borderRadius: KaizenMedidas.bordeControl),
            child: Padding(
              padding: const EdgeInsets.all(KaizenMedidas.e12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(KaizenIconos.consejo, size: 18, color: KaizenColores.tealSobreMarino),
                      const SizedBox(width: KaizenMedidas.e8),
                      Flexible(
                        child: Text(
                          t.consejoTitulo,
                          style: texto.labelLarge!.copyWith(color: KaizenColores.superficie, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: KaizenMedidas.e8),
                  Text(c.texto, style: texto.bodySmall!.copyWith(color: KaizenColores.textoSobreMarino)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
