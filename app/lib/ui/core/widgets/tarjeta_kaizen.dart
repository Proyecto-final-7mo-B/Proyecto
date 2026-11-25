import 'package:flutter/material.dart';

import '../tema/colores.dart';
import '../tema/medidas.dart';

/// Estilos de tarjeta que aparecen en los bosquejos.
enum EstiloTarjeta {
  /// Blanca con borde (lista de hábitos, calendario, KPIs).
  normal,

  /// `marino800` con texto blanco ("2 de 5", cápsula abierta).
  destacada,

  /// `azul100` sin borde (sugerencia de la Escalera, micro-paso).
  suave,
}

/// Contenedor base de todas las tarjetas: radio 16, borde de 1 px y toque opcional.
class TarjetaKaizen extends StatelessWidget {
  const TarjetaKaizen({
    required this.child,
    this.estilo = EstiloTarjeta.normal,
    this.relleno = KaizenMedidas.rellenoTarjeta,
    this.onTap,
    this.etiquetaSemantica,
    super.key,
  });

  final Widget child;
  final EstiloTarjeta estilo;
  final EdgeInsetsGeometry relleno;
  final VoidCallback? onTap;

  /// Texto para lectores de pantalla cuando la tarjeta completa es un botón.
  final String? etiquetaSemantica;

  Color get colorFondo => switch (estilo) {
    EstiloTarjeta.normal => KaizenColores.superficie,
    EstiloTarjeta.destacada => KaizenColores.marino800,
    EstiloTarjeta.suave => KaizenColores.azul100,
  };

  @override
  Widget build(BuildContext context) {
    final oscura = estilo == EstiloTarjeta.destacada;
    Widget contenido = Padding(padding: relleno, child: child);
    if (oscura) {
      contenido = DefaultTextStyle.merge(
        style: const TextStyle(color: KaizenColores.superficie),
        child: IconTheme.merge(
          data: const IconThemeData(color: KaizenColores.superficie),
          child: contenido,
        ),
      );
    }
    if (onTap != null) {
      contenido = InkWell(onTap: onTap, child: contenido);
    }
    final tarjeta = Material(
      color: colorFondo,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: KaizenMedidas.bordeTarjeta,
        side: estilo == EstiloTarjeta.normal ? const BorderSide(color: KaizenColores.borde) : BorderSide.none,
      ),
      child: contenido,
    );
    if (onTap == null && etiquetaSemantica == null) {
      return tarjeta;
    }
    return Semantics(button: onTap != null, label: etiquetaSemantica, container: true, child: tarjeta);
  }
}
