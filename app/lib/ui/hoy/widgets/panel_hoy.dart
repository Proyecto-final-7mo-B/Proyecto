import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/models/habito.dart';
import '../../../domain/models/progreso.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../utils/hitos.dart';
import '../../core/apariencia_racha.dart';
import '../../core/formatos.dart';
import '../../core/tema/colores.dart';
import '../../core/tema/iconos.dart';
import '../../core/tema/medidas.dart';
import '../../core/apariencia_habito.dart';
import '../../core/widgets/barra_progreso.dart';
import '../../core/widgets/indicador_racha.dart';
import '../../core/widgets/tarjeta_kaizen.dart';
import '../consejos.dart';

/// Encabezado común de los widgets del panel: ícono y título.
class _Titulo extends StatelessWidget {
  const _Titulo({required this.icono, required this.texto, this.color = KaizenColores.texto});

  final IconData icono;
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icono, size: 20, color: color),
      const SizedBox(width: KaizenMedidas.e8),
      Flexible(child: Text(texto, style: Theme.of(context).textTheme.titleSmall)),
    ],
  );
}

/// **Meta semanal OMS** (doc. 05): minutos de actividad aeróbica de la semana contra la franja de 150–300 de la OMS
/// (F11), con la zona marcada en la barra. Más allá de 300 el beneficio extra es pequeño (Lee 2022, F12). Muestra solo
/// lo recomendado y la medición, sin la fuente (decisión del 27-nov; las fuentes están en "Acerca de Kaizen").
class TarjetaMetaOms extends StatelessWidget {
  const TarjetaMetaOms({required this.actividad, super.key});

  final ActividadSemanal actividad;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final a = actividad;
    final estado = a.equivalenteModerado > a.recomendadoHasta
        ? t.metaOmsArriba
        : a.cumplida
        ? t.metaOmsCumplida
        : t.metaOmsFalta(numero(a.faltante));
    final valor = t.metaOmsValor(numero(a.equivalenteModerado), numero(a.recomendadoDesde));
    return Semantics(
      container: true,
      label: '${t.metaOmsTitulo}. $valor. $estado',
      child: ExcludeSemantics(
        child: TarjetaKaizen(
          relleno: const EdgeInsets.all(KaizenMedidas.e20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Titulo(icono: KaizenIconos.actividad, texto: t.metaOmsTitulo),
              const SizedBox(height: KaizenMedidas.e12),
              Text(valor, style: texto.headlineSmall),
              const SizedBox(height: KaizenMedidas.e12),
              BarraFranjaOms(actividad: a),
              const SizedBox(height: KaizenMedidas.e8),
              Text(
                estado,
                style: texto.bodySmall!.copyWith(
                  color: a.cumplida ? KaizenColores.verdeProgreso : KaizenColores.textoSecundario,
                  fontWeight: a.cumplida ? FontWeight.w700 : null,
                ),
              ),
              if (a.minutosVigorosos > 0) ...[
                const SizedBox(height: 2),
                Text(t.metaOmsDetalle(numero(a.minutosVigorosos)), style: texto.bodySmall),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Barra de la semana: la franja recomendada (150–300) va sombreada en verde claro, con una marca en cada extremo, y el
/// avance va en verde. La escala llega a 1.2 × 300 o al valor, lo que sea mayor, para que la franja siempre se vea.
/// Se pinta con `CustomPaint` (sin `LayoutBuilder`) para poder ir dentro de un `IntrinsicHeight`.
class BarraFranjaOms extends StatelessWidget {
  const BarraFranjaOms({required this.actividad, this.alto = 10, super.key});

  final ActividadSemanal actividad;
  final double alto;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: alto + 4,
    width: double.infinity,
    child: CustomPaint(
      painter: PintorFranjaOms(actividad: actividad, alto: alto),
    ),
  );
}

class PintorFranjaOms extends CustomPainter {
  PintorFranjaOms({required this.actividad, required this.alto});

  final ActividadSemanal actividad;
  final double alto;

  double get escala => math.max(actividad.recomendadoHasta * 1.2, actividad.equivalenteModerado);

  /// Fracción 0–1 del ancho para [valor].
  double fraccion(double valor) => (valor / escala).clamp(0, 1).toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    final a = actividad;
    final arriba = (size.height - alto) / 2;
    final radio = Radius.circular(alto / 2);
    double x(double v) => size.width * fraccion(v);
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, arriba, size.width, alto), radio),
        Paint()..color = KaizenColores.azul50,
      )
      ..drawRect(
        Rect.fromLTRB(x(a.recomendadoDesde), arriba, x(a.recomendadoHasta), arriba + alto),
        Paint()..color = KaizenColores.verdeProgresoFondo,
      );
    if (a.equivalenteModerado > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, arriba, x(a.equivalenteModerado), alto), radio),
        Paint()..color = KaizenColores.verdeProgreso,
      );
    }
    final marca = Paint()
      ..color = KaizenColores.textoSecundario
      ..strokeWidth = 2;
    for (final v in [a.recomendadoDesde, a.recomendadoHasta]) {
      canvas.drawLine(Offset(x(v), 0), Offset(x(v), size.height), marca);
    }
  }

  @override
  bool shouldRepaint(PintorFranjaOms old) => old.actividad != actividad || old.alto != alto;
}

/// **Próximo hito** (doc. 05): el hábito con la racha más larga, los días que le faltan para su siguiente hito, una
/// barra hacia él y un mensaje de ánimo según qué tan cerca va (sin culpa, F09). En el teléfono va [compacta].
class TarjetaProximoHito extends StatelessWidget {
  const TarjetaProximoHito({required this.habito, this.compacta = false, this.onTap, super.key});

  final Habito habito;
  final bool compacta;
  final VoidCallback? onTap;

  /// El mensaje de ánimo: más cerca del hito, más directo.
  static String animo(int dias, int hito, AppLocalizations t) {
    final faltan = hito - dias;
    if (dias == 0) {
      return t.animoEmpezar;
    }
    if (faltan == 1) {
      return t.animoManana;
    }
    if (faltan <= 3) {
      return t.animoYaCasi;
    }
    final avance = dias / hito;
    if (avance < 1 / 3) {
      return t.animoInicio;
    }
    return avance < 2 / 3 ? t.animoMitad : t.animoFinal;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final dias = habito.racha.actual;
    final hito = Hitos.siguiente(dias);
    final faltan = t.proximoHitoFaltan(hito - dias, hito);
    final nivel = NivelRacha.deDias(dias);
    final mensaje = animo(dias, hito, t);
    return Semantics(
      container: true,
      button: onTap != null,
      label: '${t.proximoHitoTitulo}. ${t.proximoHitoSemantica(habito.nombre, dias, faltan)} $mensaje',
      child: ExcludeSemantics(
        child: TarjetaKaizen(
          onTap: onTap,
          relleno: EdgeInsets.all(compacta ? KaizenMedidas.e16 : KaizenMedidas.e20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Titulo(icono: KaizenIconos.hito, texto: t.proximoHitoTitulo, color: nivel.color),
              const SizedBox(height: KaizenMedidas.e12),
              Row(
                children: [
                  Expanded(
                    child: Text(habito.nombre, style: texto.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  IndicadorRacha(dias: dias, tamano: 18),
                ],
              ),
              const SizedBox(height: KaizenMedidas.e4),
              Text(faltan, style: texto.bodySmall),
              const SizedBox(height: KaizenMedidas.e8),
              BarraProgreso(valor: dias / hito, etiquetaSemantica: t.proximoHitoTitulo),
              const SizedBox(height: KaizenMedidas.e12),
              Text(
                mensaje,
                key: const ValueKey('animo-hito'),
                style: texto.bodyMedium!.copyWith(color: KaizenColores.texto, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// **Consejo saludable** (doc. 05): uno al día. Sin la cita (decisión del 27-nov: las fuentes viven en el detalle del
/// hábito y en "Acerca de Kaizen"); solo el consejo, sin enlace. Cambia cada día. En escritorio va en el riel
/// ([ConsejoRiel]); esta tarjeta es la de web.
class TarjetaConsejo extends StatelessWidget {
  const TarjetaConsejo({required this.indice, super.key});

  final int indice;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final c = ConsejosEvidencia.de(t, indice);
    return Semantics(
      container: true,
      label: '${t.consejoTitulo}. ${c.texto}',
      child: ExcludeSemantics(
        child: TarjetaKaizen(
          relleno: const EdgeInsets.all(KaizenMedidas.e20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Titulo(icono: KaizenIconos.consejo, texto: t.consejoTitulo, color: KaizenColores.tealBienestar),
              const SizedBox(height: KaizenMedidas.e12),
              Text(c.texto, style: texto.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

/// **Esta semana, por hábito**: el % de cada hábito de lunes a hoy, con su ícono y su color, en el orden de Hoy. Ver
/// el avance de cada uno impulsa a completar lo que falta (gradiente de meta, F10). Reemplaza al mapa de 12 semanas,
/// que repetía lo del calendario (revisión de Jael, 27-nov).
class TarjetaSemanaHabitos extends StatelessWidget {
  const TarjetaSemanaHabitos({required this.filas, super.key});

  final List<({Habito habito, double cumplimiento})> filas;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    return TarjetaKaizen(
      relleno: const EdgeInsets.all(KaizenMedidas.e20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            header: true,
            child: _Titulo(icono: KaizenIconos.cumplimiento, texto: t.semanaPorHabitoTitulo),
          ),
          const SizedBox(height: KaizenMedidas.e4),
          Text(t.semanaPorHabitoDetalle, style: texto.bodySmall),
          for (final f in filas)
            Padding(
              padding: const EdgeInsets.only(top: KaizenMedidas.e12),
              child: Semantics(
                label: t.semanaPorHabitoSemantica(f.habito.nombre, f.cumplimiento.round()),
                child: ExcludeSemantics(
                  child: Row(
                    children: [
                      Icon(f.habito.icono, size: 20, color: f.habito.color),
                      const SizedBox(width: KaizenMedidas.e8),
                      SizedBox(
                        width: 130,
                        child: Text(
                          f.habito.nombre,
                          style: texto.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: KaizenMedidas.e8),
                      Expanded(child: BarraProgreso(valor: f.cumplimiento / 100)),
                      const SizedBox(width: KaizenMedidas.e8),
                      SizedBox(
                        width: 44,
                        child: Text(
                          t.porcentaje(f.cumplimiento.round()),
                          textAlign: TextAlign.end,
                          style: texto.labelLarge!.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
