import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../domain/models/registro.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../utils/fechas.dart';
import '../../../utils/hitos.dart';
import '../../core/apariencia_racha.dart';
import '../../core/formatos.dart';
import '../../core/tema/colores.dart';
import '../../core/tema/iconos.dart';
import '../../core/tema/medidas.dart';
import '../../core/widgets/barra_progreso.dart';
import '../../core/widgets/calendario_mes.dart';
import '../../core/widgets/tarjeta_kaizen.dart';

/// Teléfono: racha grande con el símbolo de su nivel (en blanco sobre marino; doc. 05) y la mejor racha a la derecha
/// (bosquejo móvil 04).
class TarjetaRacha extends StatelessWidget {
  const TarjetaRacha({required this.actual, required this.maxima, super.key});

  final int actual;
  final int maxima;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    const blanco = KaizenColores.superficie;
    return Semantics(
      container: true,
      label: t.rachaSemantica(actual, maxima),
      child: ExcludeSemantics(
        child: TarjetaKaizen(
          estilo: EstiloTarjeta.destacada,
          relleno: const EdgeInsets.symmetric(horizontal: KaizenMedidas.e24, vertical: KaizenMedidas.e24),
          child: Row(
            children: [
              // Con letra grande el número se encoge en vez de desbordarse.
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      Icon(NivelRacha.deDias(actual).icono, color: blanco, size: 36),
                      const SizedBox(width: KaizenMedidas.e12),
                      Text('$actual', style: texto.displayMedium!.copyWith(color: blanco)),
                      const SizedBox(width: KaizenMedidas.e8),
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          t.diasDeRacha,
                          style: texto.titleMedium!.copyWith(color: KaizenColores.textoSobreMarino),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: KaizenMedidas.e16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(t.mejorRacha, style: texto.bodySmall!.copyWith(color: KaizenColores.textoSobreMarino)),
                  const SizedBox(height: 4),
                  Text(t.nDias(maxima), style: texto.titleLarge!.copyWith(color: blanco)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Calendario del mes con su % y flechas para ver meses anteriores (hasta un año).
class TarjetaCalendarioHabito extends StatelessWidget {
  const TarjetaCalendarioHabito({
    required this.mes,
    required this.hoy,
    required this.niveles,
    required this.porcentaje,
    required this.onAnterior,
    required this.onSiguiente,
    this.protegidos = const {},
    super.key,
  });

  final DateTime mes;
  final DateTime hoy;
  final Map<int, int> niveles;

  /// Días con escudo (el protector de racha perdonó la falla).
  final Set<int> protegidos;
  final double? porcentaje;

  /// `null` = no hay más meses hacia ese lado.
  final VoidCallback? onAnterior;
  final VoidCallback? onSiguiente;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final nombreMes = Fechas.nombreMes(mes.month);
    final titulo = mes.year == hoy.year ? nombreMes : '$nombreMes ${mes.year}';
    return TarjetaKaizen(
      relleno: const EdgeInsets.fromLTRB(KaizenMedidas.e16, KaizenMedidas.e8, KaizenMedidas.e16, KaizenMedidas.e16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(tooltip: t.mesAnterior, onPressed: onAnterior, icon: const Icon(KaizenIconos.atras)),
              Expanded(child: Text(titulo, style: texto.titleMedium)),
              if (porcentaje != null)
                Semantics(
                  label: t.cumplimientoMes(porcentaje!.round(), nombreMes),
                  child: ExcludeSemantics(
                    child: Text(
                      t.porcentaje(porcentaje!.round()),
                      style: texto.titleLarge!.copyWith(color: KaizenColores.azul600),
                    ),
                  ),
                ),
              IconButton(tooltip: t.mesSiguiente, onPressed: onSiguiente, icon: const Icon(KaizenIconos.siguiente)),
            ],
          ),
          const SizedBox(height: KaizenMedidas.e4),
          CalendarioMes(
            anio: mes.year,
            mes: mes.month,
            hoy: hoy,
            niveles: niveles,
            protegidos: protegidos,
            mostrarTitulo: false,
          ),
        ],
      ),
    );
  }
}

/// Los check-ins más recientes: "7 nov · Cumplido · 10 min".
class TarjetaHistorial extends StatelessWidget {
  const TarjetaHistorial({required this.registros, required this.unidad, super.key});

  final List<Registro> registros;
  final String unidad;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    return TarjetaKaizen(
      relleno: const EdgeInsets.all(KaizenMedidas.e20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(t.historial, style: texto.titleMedium)),
          const SizedBox(height: KaizenMedidas.e12),
          if (registros.isEmpty)
            Text(t.sinRegistros, style: texto.bodyMedium)
          else
            for (final r in registros)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: MergeSemantics(
                  child: Row(
                    children: [
                      _CirculoCheck(cumplido: r.cumplido),
                      const SizedBox(width: KaizenMedidas.e12),
                      Expanded(
                        child: Text(
                          r.cumplido
                              ? t.historialCumplido(Fechas.corta(r.fecha))
                              : t.historialNoCumplido(Fechas.corta(r.fecha)),
                          style: texto.titleSmall,
                        ),
                      ),
                      if (r.cumplido && r.valor != null) Text('${numero(r.valor!)} $unidad', style: texto.bodySmall),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

/// Círculo de 28 px del historial: marino con ✓ si se cumplió; solo el borde si no.
class _CirculoCheck extends StatelessWidget {
  const _CirculoCheck({required this.cumplido});

  final bool cumplido;

  @override
  Widget build(BuildContext context) => Container(
    width: 28,
    height: 28,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: cumplido ? KaizenColores.verdeProgreso : KaizenColores.superficie,
      border: Border.all(color: cumplido ? KaizenColores.verdeProgreso : KaizenColores.borde, width: 2),
    ),
    child: cumplido ? const Icon(KaizenIconos.cumplido, size: 16, color: KaizenColores.superficie) : null,
  );
}

/// Escritorio: tendencia del cumplimiento por semana (fl_chart, dibujada en la app con los check-ins que ya trae el
/// detalle). Eje Y: % de días cumplidos (0–100); eje X: la semana, por su lunes. Cada semana lleva su punto y, al
/// tocarlo, su valor. La línea punteada del 85 % es el umbral con el que la Escalera propone subir (doc. 02).
class TarjetaTendencia extends StatelessWidget {
  const TarjetaTendencia({required this.valores, this.lunes = const [], super.key});

  /// % de cada semana, de la más antigua a la actual.
  final List<double> valores;

  /// El lunes de cada semana de [valores] (mismo orden). Vacío = sin fechas en el eje X.
  final List<DateTime> lunes;

  /// Cumplimiento con el que la Escalera propone subir (doc. 02).
  static const double umbralSubir = 85;

  String _semana(int i) => i < lunes.length ? Fechas.corta(lunes[i]) : '${i + 1}';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final etiqueta = texto.labelSmall!.copyWith(color: KaizenColores.textoSecundario);
    final puntos = [for (var i = 0; i < valores.length; i++) FlSpot(i.toDouble(), valores[i])];
    // Con muchas semanas, una etiqueta sí y otra no en el eje X.
    final cada = valores.length > 7 ? 2 : 1;
    return TarjetaKaizen(
      relleno: const EdgeInsets.all(KaizenMedidas.e20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.tendencia, style: texto.titleMedium),
          Text(t.tendenciaDetalle, style: texto.bodySmall),
          const SizedBox(height: KaizenMedidas.e16),
          Semantics(
            label: t.tendenciaSemantica(
              valores.length,
              [for (var i = 0; i < valores.length; i++) '${_semana(i)}: ${valores[i].round()} %'].join(', '),
            ),
            child: ExcludeSemantics(
              child: SizedBox(
                height: 230,
                child: valores.length < 2
                    ? Center(child: Text(t.sinDatos, style: texto.bodyMedium))
                    : LineChart(
                        duration: Duration.zero,
                        LineChartData(
                          minX: 0,
                          maxX: (valores.length - 1).toDouble(),
                          minY: 0,
                          maxY: 100,
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(),
                            rightTitles: const AxisTitles(),
                            leftTitles: AxisTitles(
                              axisNameWidget: Text(t.tendenciaEjeY, style: etiqueta),
                              axisNameSize: 18,
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                interval: 25,
                                getTitlesWidget: (v, _) => Text('${v.round()} %', style: etiqueta),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              axisNameWidget: Text(t.tendenciaEjeX, style: etiqueta),
                              axisNameSize: 18,
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 24,
                                interval: 1,
                                getTitlesWidget: (v, _) {
                                  final i = v.round();
                                  final ultimo = valores.length - 1;
                                  if (v != i || (i % cada != ultimo % cada)) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(_semana(i), style: etiqueta),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: const Border(
                              left: BorderSide(color: KaizenColores.bordeControl),
                              bottom: BorderSide(color: KaizenColores.bordeControl),
                            ),
                          ),
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (_) => KaizenColores.marino800,
                              getTooltipItems: (tocados) => [
                                for (final p in tocados)
                                  LineTooltipItem(
                                    t.tendenciaPunto(_semana(p.x.round()), p.y.round()),
                                    texto.labelMedium!.copyWith(color: KaizenColores.superficie),
                                  ),
                              ],
                            ),
                          ),
                          gridData: FlGridData(
                            drawVerticalLine: false,
                            horizontalInterval: 25,
                            getDrawingHorizontalLine: (_) => const FlLine(color: KaizenColores.borde, strokeWidth: 1),
                          ),
                          extraLinesData: ExtraLinesData(
                            horizontalLines: [
                              HorizontalLine(
                                y: umbralSubir,
                                color: KaizenColores.verdeProgreso,
                                strokeWidth: 1.5,
                                dashArray: [6, 4],
                                label: HorizontalLineLabel(
                                  show: true,
                                  alignment: Alignment.topRight,
                                  style: texto.labelSmall!.copyWith(
                                    color: KaizenColores.verdeProgreso,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  labelResolver: (_) => t.tendenciaUmbral,
                                ),
                              ),
                            ],
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: puntos,
                              color: KaizenColores.azul600,
                              barWidth: 2.5,
                              dotData: FlDotData(
                                getDotPainter: (punto, _, _, _) => FlDotCirclePainter(
                                  color: punto.x == puntos.last.x ? KaizenColores.marino800 : KaizenColores.azul600,
                                  radius: punto.x == puntos.last.x ? 5 : 3.5,
                                  strokeWidth: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: KaizenMedidas.e12),
          Text(t.tendenciaLeyenda, style: texto.bodySmall),
        ],
      ),
    );
  }
}

/// Escritorio: "Nivel 3 de 5 · 10 min", su barra y el siguiente micro-paso.
class TarjetaNivel extends StatelessWidget {
  const TarjetaNivel({
    required this.nivel,
    required this.total,
    required this.meta,
    required this.unidad,
    required this.siguiente,
    required this.escaleraActiva,
    required this.onVerEscalera,
    super.key,
  });

  final int nivel;
  final int total;
  final double meta;
  final String unidad;
  final double? siguiente;
  final bool escaleraActiva;
  final VoidCallback onVerEscalera;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    return TarjetaKaizen(
      relleno: const EdgeInsets.all(KaizenMedidas.e20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(t.nivelActual, style: texto.titleMedium)),
              TextButton(onPressed: onVerEscalera, child: Text(t.verEscalera)),
            ],
          ),
          const SizedBox(height: KaizenMedidas.e4),
          Text(t.nivelDeTotal(nivel, total, numero(meta), unidad), style: texto.headlineSmall),
          const SizedBox(height: KaizenMedidas.e16),
          BarraProgreso(valor: nivel / total, alto: 10),
          const SizedBox(height: KaizenMedidas.e12),
          Text(
            !escaleraActiva
                ? t.escaleraApagada
                : siguiente != null
                ? t.siguienteMicroPaso(numero(siguiente!), unidad)
                : t.evidenciaOptimo,
            style: texto.bodyMedium!.copyWith(color: KaizenColores.textoSecundario),
          ),
        ],
      ),
    );
  }
}
