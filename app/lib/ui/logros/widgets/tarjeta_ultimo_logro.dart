import 'package:flutter/material.dart';

import '../../../domain/models/logro.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../utils/fechas.dart';
import '../../core/tema/colores.dart';
import '../../core/tema/iconos.dart';
import '../../core/tema/medidas.dart';
import '../../core/widgets/barra_progreso.dart';
import '../../core/widgets/tarjeta_kaizen.dart';
import 'insignia_logro.dart';

/// **Último logro** (doc. 05, widget de Hoy): la insignia más reciente; si aún no hay ninguna, **"Tu próxima
/// insignia"** con su avance (gradiente de meta, F10). Tocarla abre `/logros`. En el teléfono es la entrada a Logros
/// (la barra inferior se queda con 5 destinos).
class TarjetaUltimoLogro extends StatelessWidget {
  const TarjetaUltimoLogro({required this.logro, required this.onTap, super.key});

  /// El último obtenido o, si no hay, el próximo por obtener.
  final Logro logro;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final l = logro;
    final titulo = l.obtenido ? t.ultimoLogroTitulo : t.proximoLogroTitulo;
    final detalle = l.obtenido
        ? [
            if (l.obtenidoEn != null) t.logroObtenidoEl(Fechas.corta(l.obtenidoEn!.toLocal())),
            if (l.habitoNombre != null) t.logroConHabito(l.habitoNombre!),
          ].join(' · ')
        : (l.muestraProgreso ? t.logroProgresoDias(l.progreso, l.objetivo) : l.descripcion);
    return Semantics(
      container: true,
      button: true,
      label: '$titulo. ${l.nombre}. $detalle',
      child: ExcludeSemantics(
        child: TarjetaKaizen(
          key: const ValueKey('tarjeta-ultimo-logro'),
          onTap: onTap,
          relleno: const EdgeInsets.all(KaizenMedidas.e16),
          child: Row(
            children: [
              InsigniaLogro(logro: l, tamano: 48),
              const SizedBox(width: KaizenMedidas.e16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(KaizenIconos.logros, size: 16, color: KaizenColores.textoSecundario),
                        const SizedBox(width: KaizenMedidas.e4),
                        Flexible(
                          child: Text(titulo, style: texto.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: KaizenMedidas.e4),
                    Text(l.nombre, style: texto.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(detalle, style: texto.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (!l.obtenido && l.muestraProgreso) ...[
                      const SizedBox(height: KaizenMedidas.e8),
                      BarraProgreso(valor: l.avance, alto: 6),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: KaizenMedidas.e8),
              const Icon(KaizenIconos.siguiente, color: KaizenColores.textoSecundario),
            ],
          ),
        ),
      ),
    );
  }
}
