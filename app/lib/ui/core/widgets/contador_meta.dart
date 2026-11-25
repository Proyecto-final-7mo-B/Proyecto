import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../tema/colores.dart';
import '../tema/medidas.dart';

/// Contador "−  5 min  +" de la meta inicial de un hábito. Respeta [minimo] y [maximo] (la base exige meta > 0).
class ContadorMeta extends StatelessWidget {
  const ContadorMeta({
    required this.valor,
    required this.unidad,
    required this.onCambio,
    this.minimo = 1,
    this.maximo = 9999,
    this.paso = 1,
    super.key,
  });

  final num valor;
  final String unidad;

  /// `null` = deshabilitado.
  final ValueChanged<num>? onCambio;
  final num minimo;
  final num maximo;
  final num paso;

  /// "5", "8.5" (sin ".0").
  static String formatoNumero(num v) {
    if (v == v.roundToDouble()) {
      return v.round().toString();
    }
    return v.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
  }

  bool get puedeBajar => onCambio != null && valor - paso >= minimo;
  bool get puedeSubir => onCambio != null && valor + paso <= maximo;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = unidad.isEmpty ? formatoNumero(valor) : '${formatoNumero(valor)} $unidad';
    return Row(
      children: [
        _BotonCuadrado(
          icono: Icons.remove,
          etiqueta: t.disminuir,
          onTap: puedeBajar ? () => onCambio!(valor - paso) : null,
        ),
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Text(texto, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
          ),
        ),
        _BotonCuadrado(
          icono: Icons.add,
          etiqueta: t.aumentar,
          onTap: puedeSubir ? () => onCambio!(valor + paso) : null,
        ),
      ],
    );
  }
}

class _BotonCuadrado extends StatelessWidget {
  const _BotonCuadrado({required this.icono, required this.etiqueta, required this.onTap});

  final IconData icono;
  final String etiqueta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final habilitado = onTap != null;
    return Semantics(
      button: true,
      enabled: habilitado,
      label: etiqueta,
      child: Material(
        color: KaizenColores.superficie,
        shape: const RoundedRectangleBorder(
          borderRadius: KaizenMedidas.bordeControl,
          side: BorderSide(color: KaizenColores.bordeCampo),
        ),
        child: InkWell(
          borderRadius: KaizenMedidas.bordeControl,
          onTap: onTap,
          child: SizedBox.square(
            dimension: 48,
            child: Icon(icono, color: habilitado ? KaizenColores.texto : KaizenColores.bordeControl),
          ),
        ),
      ),
    );
  }
}
