import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../core/formatos.dart';
import '../../core/tema/colores.dart';
import '../../core/tema/iconos.dart';
import '../../core/tema/medidas.dart';
import '../../core/widgets/fila_habito.dart';
import '../../core/widgets/tarjeta_kaizen.dart';

/// Escritorio: "Así se verá" (la fila como saldrá en Hoy) y "Tu escalera inicial" (bosquejo escritorio 03).
class VistaPreviaHabito extends StatelessWidget {
  const VistaPreviaHabito({
    required this.nombre,
    required this.icono,
    required this.subtitulo,
    required this.niveles,
    required this.unidad,
    required this.conCapsula,
    required this.conEscalera,
    this.colorIcono,
    super.key,
  });

  final String nombre;

  /// Ícono de la subcategoría elegida (`null` = todavía no se elige).
  final IconData? icono;

  /// Color de la categoría elegida.
  final Color? colorIcono;
  final String subtitulo;

  /// La meta de cada nivel: el primero es el actual y los demás son proyección.
  final List<double> niveles;
  final String unidad;
  final bool conCapsula;
  final bool conEscalera;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    return TarjetaKaizen(
      relleno: const EdgeInsets.all(KaizenMedidas.e20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.asiSeVera, style: texto.titleMedium),
          const SizedBox(height: KaizenMedidas.e12),
          ExcludeSemantics(
            child: FilaHabito(
              icono: icono ?? KaizenIconos.categoriaGenerica,
              colorIcono: colorIcono,
              nombre: nombre.trim().isEmpty ? t.pistaNombreHabito : nombre.trim(),
              subtitulo: subtitulo,
              racha: 0,
              cumplido: false,
              conCapsula: conCapsula,
            ),
          ),
          if (conEscalera) ...[
            const SizedBox(height: KaizenMedidas.e24),
            Text(t.tuEscaleraInicial, style: texto.titleSmall),
            const SizedBox(height: KaizenMedidas.e16),
            EscaleraInicial(niveles: niveles, unidad: unidad),
            const SizedBox(height: KaizenMedidas.e12),
            Text(t.proyeccionEscalera, style: texto.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// Barras que suben: el nivel 1 (actual, "Aquí vas") y los proyectados en tono claro.
class EscaleraInicial extends StatelessWidget {
  const EscaleraInicial({required this.niveles, required this.unidad, this.alto = 210, super.key});

  final List<double> niveles;
  final String unidad;
  final double alto;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final n = niveles.length;
    return Semantics(
      label: [for (var i = 0; i < n; i++) '${t.nivelN(i + 1)}: ${numero(niveles[i])} $unidad'].join('. '),
      child: ExcludeSemantics(
        child: SizedBox(
          height: alto,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < n; i++) ...[
                if (i > 0) const SizedBox(width: KaizenMedidas.e8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (i == 0)
                        Container(
                          margin: const EdgeInsets.only(bottom: KaizenMedidas.e8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: const BoxDecoration(
                            color: KaizenColores.naranjaRacha,
                            borderRadius: KaizenMedidas.bordePildora,
                          ),
                          child: FittedBox(
                            child: Text(t.aquiVas, style: texto.labelSmall!.copyWith(color: KaizenColores.superficie)),
                          ),
                        ),
                      Container(
                        height: (alto - 40) * (0.35 + 0.65 * i / (n - 1 == 0 ? 1 : n - 1)),
                        width: double.infinity,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: i == 0 ? KaizenColores.marino800 : KaizenColores.azul100,
                          borderRadius: KaizenMedidas.bordeCelda,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.topLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.nivelN(i + 1),
                                style: texto.labelMedium!.copyWith(
                                  color: i == 0 ? KaizenColores.superficie : KaizenColores.texto,
                                ),
                              ),
                              Text(
                                '${numero(niveles[i])} $unidad',
                                style: texto.labelSmall!.copyWith(
                                  color: i == 0 ? KaizenColores.textoSobreMarino : KaizenColores.textoSecundario,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
