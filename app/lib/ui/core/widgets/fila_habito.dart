import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../tema/colores.dart';
import '../tema/iconos.dart';
import '../tema/medidas.dart';
import 'indicador_racha.dart';

/// Fila de un hábito en "Para hoy": ícono de su categoría, nombre, subtítulo ("2 L · diario"), racha y el círculo del
/// check-in de un toque.
class FilaHabito extends StatelessWidget {
  const FilaHabito({
    required this.icono,
    required this.nombre,
    required this.subtitulo,
    required this.racha,
    required this.cumplido,
    this.conCapsula = false,
    this.onCheck,
    this.onTap,
    super.key,
  });

  final IconData icono;
  final String nombre;
  final String subtitulo;
  final int racha;
  final bool cumplido;
  final bool conCapsula;

  /// Toque en el círculo; `null` = sin check-in (p. ej., hábito no programado hoy).
  final VoidCallback? onCheck;

  /// Toque en el resto de la fila (abre el detalle).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Material(
      color: KaizenColores.superficie,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: KaizenMedidas.bordeTarjeta,
        side: BorderSide(color: KaizenColores.borde),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            KaizenMedidas.e12,
            KaizenMedidas.e12,
            KaizenMedidas.e12,
            KaizenMedidas.e12,
          ),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: KaizenMedidas.ladoIconoHabito,
                  height: KaizenMedidas.ladoIconoHabito,
                  decoration: const BoxDecoration(
                    color: KaizenColores.azul100,
                    borderRadius: KaizenMedidas.bordeControl,
                  ),
                  child: Icon(icono, color: KaizenColores.texto, size: 22),
                ),
              ),
              const SizedBox(width: KaizenMedidas.e16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombre, style: texto.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(subtitulo, style: texto.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: KaizenMedidas.e8),
              IndicadorRacha(dias: racha, conCapsula: conCapsula),
              const SizedBox(width: KaizenMedidas.e20),
              BotonCheck(cumplido: cumplido, nombreHabito: nombre, onTap: onCheck),
            ],
          ),
        ),
      ),
    );
  }
}

/// Círculo del check-in: relleno `marino800` con palomita si está cumplido; vacío con borde si no.
class BotonCheck extends StatelessWidget {
  const BotonCheck({required this.cumplido, required this.nombreHabito, this.onTap, super.key});

  final bool cumplido;
  final String nombreHabito;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Semantics(
      container: true,
      button: true,
      checked: cumplido,
      enabled: onTap != null,
      label: cumplido ? t.habitoCumplido(nombreHabito) : t.marcarCumplido(nombreHabito),
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: cumplido ? KaizenColores.marino800 : KaizenColores.superficie,
          shape: CircleBorder(
            side: cumplido ? BorderSide.none : const BorderSide(color: KaizenColores.bordeControl, width: 1.5),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox.square(
              dimension: KaizenMedidas.ladoCheck,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: cumplido
                    ? const Icon(KaizenIconos.cumplido, key: ValueKey(true), color: KaizenColores.superficie)
                    : const SizedBox.shrink(key: ValueKey(false)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
