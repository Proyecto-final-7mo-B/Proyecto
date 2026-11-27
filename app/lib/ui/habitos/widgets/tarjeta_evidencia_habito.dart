import 'package:flutter/material.dart';

import '../../../domain/models/frecuencia.dart';
import '../../../domain/models/habito.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../core/tema/colores.dart';
import '../../core/tema/medidas.dart';
import '../../core/widgets/tarjeta_kaizen.dart';
import 'panel_evidencia.dart';

/// Días para la mediana de formación de un hábito (Lally 2010; Singh 2024; doc. 01 de la investigación).
const int diasHabitoFormado = 66;

/// Detalle del hábito: dónde está la meta según la evidencia, cuánto falta para los 66 días (o "Hábito formado"),
/// el protector de racha de la semana y la intención "Después de ___".
class TarjetaEvidenciaHabito extends StatelessWidget {
  const TarjetaEvidenciaHabito({required this.habito, super.key});

  final Habito habito;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final h = habito;
    final evaluacion = h.evaluacion;
    final formado = h.racha.maxima >= diasHabitoFormado;
    final intencion = h.intencion;
    return TarjetaKaizen(
      relleno: const EdgeInsets.all(KaizenMedidas.e20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.evidenciaTitulo, style: texto.titleMedium),
          if (evaluacion != null) ...[
            const SizedBox(height: KaizenMedidas.e12),
            PanelEvidencia(evaluacion: evaluacion, meta: h.meta, unidad: h.unidad),
          ],
          const SizedBox(height: KaizenMedidas.e12),
          _Renglon(
            icono: formado ? Icons.workspace_premium_outlined : Icons.flag_outlined,
            color: formado ? KaizenColores.verdeProgreso : KaizenColores.azul600,
            titulo: formado ? t.habitoFormado : null,
            texto: formado
                ? t.habitoFormadoDetalle(h.racha.maxima)
                : t.habitoHacia66(diasHabitoFormado - h.racha.actual),
          ),
          if (h.frecuencia is! NPorSemana) ...[
            const SizedBox(height: KaizenMedidas.e8),
            _Renglon(
              icono: Icons.shield_outlined,
              color: h.racha.protegidaEstaSemana ? KaizenColores.avisoTexto : KaizenColores.verdeProgreso,
              texto: h.racha.protegidaEstaSemana ? t.protectorUsado : t.protectorDisponible,
            ),
          ],
          if (intencion != null) ...[
            const SizedBox(height: KaizenMedidas.e8),
            _Renglon(icono: Icons.route_outlined, color: KaizenColores.azul600, texto: t.intencionDe(intencion)),
          ],
        ],
      ),
    );
  }
}

class _Renglon extends StatelessWidget {
  const _Renglon({required this.icono, required this.color, required this.texto, this.titulo});

  final IconData icono;
  final Color color;
  final String? titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final estilos = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 20, color: color),
          const SizedBox(width: KaizenMedidas.e8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (titulo != null) Text(titulo!, style: estilos.titleSmall),
                Text(texto, style: estilos.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
