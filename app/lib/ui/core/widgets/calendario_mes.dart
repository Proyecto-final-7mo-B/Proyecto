import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../utils/fechas.dart';
import '../tema/colores.dart';
import '../tema/medidas.dart';

/// Calendario de un mes (semana L–D) con la intensidad de cumplimiento de cada día (escala 0–4 de
/// [KaizenColores.intensidad]). Se usa en Hoy (escritorio) y en el detalle de un hábito.
class CalendarioMes extends StatelessWidget {
  const CalendarioMes({
    required this.anio,
    required this.mes,
    this.niveles = const {},
    this.hoy,
    this.onDia,
    this.altoCelda = 36,
    this.mostrarTitulo = true,
    super.key,
  });

  final int anio;

  /// 1–12.
  final int mes;

  /// Día del mes → nivel 0–4. Los días que no están valen 0.
  final Map<int, int> niveles;

  /// Si cae en este mes, ese día lleva un contorno.
  final DateTime? hoy;

  final ValueChanged<DateTime>? onDia;
  final double altoCelda;
  final bool mostrarTitulo;

  int nivelDe(int dia) => (niveles[dia] ?? 0).clamp(0, 4);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final desfase = Fechas.desfaseLunes(anio, mes);
    final totalDias = Fechas.diasDelMes(anio, mes);
    final semanas = ((desfase + totalDias) / 7).ceil();
    final diaHoy = hoy != null && hoy!.year == anio && hoy!.month == mes ? hoy!.day : null;

    Widget celda(int indice) {
      final dia = indice - desfase + 1;
      if (dia < 1 || dia > totalDias) {
        return SizedBox(height: altoCelda);
      }
      final nivel = nivelDe(dia);
      final contenido = Container(
        height: altoCelda,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: KaizenColores.deIntensidad(nivel),
          borderRadius: KaizenMedidas.bordeCelda,
          border: dia == diaHoy ? Border.all(color: KaizenColores.naranjaRacha, width: 2) : null,
        ),
        child: Text(
          '$dia',
          style: texto.labelMedium!.copyWith(
            fontWeight: FontWeight.w700,
            color: KaizenColores.textoSobreIntensidad(nivel),
          ),
        ),
      );
      return Semantics(
        label: '${Fechas.diaYMes(dia, mes)}: ${t.nivelDeCuatro(nivel)}',
        button: onDia != null,
        selected: dia == diaHoy,
        child: ExcludeSemantics(
          child: onDia == null
              ? contenido
              : InkWell(
                  borderRadius: KaizenMedidas.bordeCelda,
                  onTap: () => onDia!(DateTime(anio, mes, dia)),
                  child: contenido,
                ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (mostrarTitulo) ...[
          Text(Fechas.nombreMes(mes), style: texto.titleMedium),
          const SizedBox(height: KaizenMedidas.e8),
        ],
        Row(
          children: [
            for (final inicial in Fechas.inicialesSemana)
              Expanded(
                child: Center(
                  child: Text(inicial, style: texto.labelSmall!.copyWith(color: KaizenColores.textoSecundario)),
                ),
              ),
          ],
        ),
        for (var s = 0; s < semanas; s++)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                for (var d = 0; d < 7; d++) ...[if (d > 0) const SizedBox(width: 6), Expanded(child: celda(s * 7 + d))],
              ],
            ),
          ),
      ],
    );
  }
}
