import 'package:flutter/material.dart';

import '../../../domain/models/escalera.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../core/formatos.dart';
import '../../core/tema/colores.dart';
import '../../core/tema/iconos.dart';
import '../../core/tema/medidas.dart';
import '../../core/widgets/barra_progreso.dart';
import '../../core/widgets/barra_semana.dart';
import '../../core/widgets/icono_escalera.dart';
import '../../core/widgets/tarjeta_kaizen.dart';

/// Tarjeta "2 de 5 · hábitos de hoy" con su barra y, en el teléfono, la semana L–D.
class TarjetaProgresoDia extends StatelessWidget {
  const TarjetaProgresoDia({required this.cumplidos, required this.total, this.semana, super.key});

  final int cumplidos;
  final int total;

  /// Intensidad de lunes a domingo; `null` = sin la fila de la semana (escritorio).
  final List<int?>? semana;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: t.resumenHoySemantica(cumplidos, total),
      child: ExcludeSemantics(
        child: TarjetaKaizen(
          estilo: EstiloTarjeta.destacada,
          relleno: const EdgeInsets.all(KaizenMedidas.e20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(t.nDeM(cumplidos, total), style: texto.displayMedium!.copyWith(color: KaizenColores.superficie)),
                  const SizedBox(width: KaizenMedidas.e16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        t.habitosDeHoy,
                        textAlign: semana == null ? TextAlign.start : TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: texto.bodyMedium!.copyWith(color: KaizenColores.textoSobreMarino),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KaizenMedidas.e16),
              BarraProgreso(valor: total == 0 ? 0 : cumplidos / total, sobreOscuro: true),
              if (semana != null) ...[
                const SizedBox(height: KaizenMedidas.e16),
                BarraSemana(niveles: semana!, sobreOscuro: true),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Pregunta de la sugerencia: "Leer: ¿subir de 10 a 11 min?".
String preguntaSugerencia(Sugerencia s, String unidad, AppLocalizations t) => s.tipo == TipoSugerencia.subir
    ? t.sugerenciaSubir(s.habitoNombre, numero(s.metaActual), numero(s.metaPropuesta), unidad)
    : t.sugerenciaBajar(s.habitoNombre, numero(s.metaActual), numero(s.metaPropuesta), unidad);

/// "93 % en 14 días".
/// "Cumpliste 93 % en 14 días" o, si la meta pasa del máximo recomendado (v1.6, sin porcentaje), el aviso de exceso.
String detalleSugerencia(Sugerencia s, AppLocalizations t) {
  final pct = s.cumplimiento14d;
  return pct == null ? t.sugerenciaExceso : t.sugerenciaDetalle(pct.round().toString());
}

/// Teléfono: la sugerencia como un renglón que abre las opciones (bosquejo móvil 02).
class TarjetaSugerencia extends StatelessWidget {
  const TarjetaSugerencia({required this.sugerencia, required this.unidad, required this.onTap, super.key});

  final Sugerencia sugerencia;
  final String unidad;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    return TarjetaKaizen(
      estilo: EstiloTarjeta.suave,
      onTap: onTap,
      child: Row(
        children: [
          const IconoEscalera(tamano: 24, color: KaizenColores.texto),
          const SizedBox(width: KaizenMedidas.e16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(preguntaSugerencia(sugerencia, unidad, t), style: texto.titleSmall),
                const SizedBox(height: 2),
                Text(detalleSugerencia(sugerencia, t), style: texto.bodySmall),
              ],
            ),
          ),
          const Icon(KaizenIconos.siguiente),
        ],
      ),
    );
  }
}

/// Escritorio: "Micro-paso sugerido" con Aceptar y Mantener a la vista (bosquejo escritorio 02).
class TarjetaMicroPaso extends StatelessWidget {
  const TarjetaMicroPaso({
    required this.sugerencia,
    required this.unidad,
    required this.ocupado,
    required this.onResponder,
    super.key,
  });

  final Sugerencia sugerencia;
  final String unidad;
  final bool ocupado;
  final ValueChanged<bool> onResponder;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    return TarjetaKaizen(
      estilo: EstiloTarjeta.suave,
      relleno: const EdgeInsets.all(KaizenMedidas.e20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconoEscalera(tamano: 22, color: KaizenColores.texto),
              const SizedBox(width: KaizenMedidas.e12),
              Flexible(child: Text(t.microPasoSugerido, style: texto.titleMedium)),
            ],
          ),
          const SizedBox(height: KaizenMedidas.e12),
          Text('${sugerencia.habitoNombre} · ${detalleSugerencia(sugerencia, t)}', style: texto.bodySmall),
          const SizedBox(height: KaizenMedidas.e4),
          Text(
            '${numero(sugerencia.metaActual)} → ${numero(sugerencia.metaPropuesta)} $unidad',
            style: texto.headlineSmall,
          ),
          const SizedBox(height: KaizenMedidas.e16),
          BotonesSugerencia(ocupado: ocupado, onResponder: onResponder),
        ],
      ),
    );
  }
}

/// "Aceptar" y "Mantener" (Mantener = rechazar: la meta no cambia).
class BotonesSugerencia extends StatelessWidget {
  const BotonesSugerencia({required this.ocupado, required this.onResponder, super.key});

  final bool ocupado;
  final ValueChanged<bool> onResponder;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    const alto = Size(0, 44);
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: ocupado ? null : () => onResponder(true),
            style: FilledButton.styleFrom(minimumSize: alto),
            child: Text(t.aceptar),
          ),
        ),
        const SizedBox(width: KaizenMedidas.e8),
        Expanded(
          child: OutlinedButton(
            onPressed: ocupado ? null : () => onResponder(false),
            style: OutlinedButton.styleFrom(minimumSize: alto),
            child: Text(t.mantener),
          ),
        ),
      ],
    );
  }
}

/// "¿Cómo te sientes hoy?": lleva al Laboratorio para registrar ánimo y energía.
class TarjetaSenal extends StatelessWidget {
  const TarjetaSenal({required this.onTap, this.conDetalle = true, super.key});

  final VoidCallback onTap;
  final bool conDetalle;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    return TarjetaKaizen(
      onTap: onTap,
      child: Row(
        children: [
          const Icon(KaizenIconos.laboratorio),
          const SizedBox(width: KaizenMedidas.e16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.comoTeSientes, style: texto.titleSmall),
                if (conDetalle) ...[const SizedBox(height: 2), Text(t.comoTeSientesDetalle, style: texto.bodySmall)],
              ],
            ),
          ),
          const Icon(KaizenIconos.siguiente),
        ],
      ),
    );
  }
}
