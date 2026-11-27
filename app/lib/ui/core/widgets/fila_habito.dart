import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../tema/colores.dart';
import '../tema/iconos.dart';
import '../tema/medidas.dart';
import 'indicador_racha.dart';

/// Fila de un hábito en "Para hoy": ícono de su categoría, nombre, subtítulo ("2 L · diario"), racha por niveles y el
/// círculo del check-in de un toque. Con [prioridadAlta], una bandera y "Alta" antes del subtítulo (doc. 07).
class FilaHabito extends StatelessWidget {
  const FilaHabito({
    required this.icono,
    required this.nombre,
    required this.subtitulo,
    required this.racha,
    required this.cumplido,
    this.conCapsula = false,
    this.protegida = false,
    this.prioridadAlta = false,
    this.colorIcono,
    this.onCheck,
    this.onTap,
    super.key,
  });

  final IconData icono;

  /// Color de la categoría (doc. 04): el ícono va en ese color sobre el mismo color al 12 %. `null` = marino.
  final Color? colorIcono;
  final String nombre;
  final String subtitulo;
  final int racha;
  final bool cumplido;
  final bool conCapsula;

  /// El protector de racha ya se usó esta semana (escudo junto a la racha).
  final bool protegida;
  final bool prioridadAlta;

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
                  decoration: BoxDecoration(
                    color: colorIcono == null ? KaizenColores.azul100 : KaizenColores.fondoDe(colorIcono!),
                    borderRadius: KaizenMedidas.bordeControl,
                  ),
                  child: Icon(icono, color: colorIcono ?? KaizenColores.texto, size: 22),
                ),
              ),
              const SizedBox(width: KaizenMedidas.e16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombre, style: texto.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (prioridadAlta) ...[
                          Semantics(
                            label: AppLocalizations.of(context).prioridadAltaSemantica,
                            child: ExcludeSemantics(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(KaizenIconos.prioridadAlta, size: 14, color: KaizenColores.marino800),
                                  const SizedBox(width: 2),
                                  Text(
                                    AppLocalizations.of(context).prioridadAlta,
                                    style: texto.bodySmall!.copyWith(
                                      color: KaizenColores.marino800,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Text(' · ', style: texto.bodySmall),
                        ],
                        Flexible(
                          child: Text(subtitulo, style: texto.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: KaizenMedidas.e8),
              IndicadorRacha(dias: racha, conCapsula: conCapsula, protegida: protegida),
              const SizedBox(width: KaizenMedidas.e20),
              BotonCheck(cumplido: cumplido, nombreHabito: nombre, onTap: onCheck),
            ],
          ),
        ),
      ),
    );
  }
}

/// Círculo del check-in: relleno `verdeProgreso` con palomita si está cumplido (el verde es "hecho", doc. 04); vacío
/// con borde si no.
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
          color: cumplido ? KaizenColores.verdeProgreso : KaizenColores.superficie,
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
