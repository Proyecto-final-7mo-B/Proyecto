import 'package:flutter/widgets.dart';

/// Formas y espacios de los bosquejos: tarjetas radio 16, campos y botones radio 12, chips en píldora.
abstract final class KaizenMedidas {
  static const double radioTarjeta = 16;
  static const double radioControl = 12;
  static const double radioCelda = 8;

  /// Alto del botón principal ("Guardar hábito", "Sellar cápsula").
  static const double altoBoton = 52;

  /// Lado del cuadro del ícono de hábito y del círculo del check-in.
  static const double ladoIconoHabito = 44;
  static const double ladoCheck = 48;

  static const double grosorBorde = 1;

  // Espacios (múltiplos de 4)
  static const double e4 = 4;
  static const double e8 = 8;
  static const double e12 = 12;
  static const double e16 = 16;
  static const double e20 = 20;
  static const double e24 = 24;
  static const double e32 = 32;

  static const BorderRadius bordeTarjeta = BorderRadius.all(Radius.circular(radioTarjeta));
  static const BorderRadius bordeControl = BorderRadius.all(Radius.circular(radioControl));
  static const BorderRadius bordeCelda = BorderRadius.all(Radius.circular(radioCelda));
  static const BorderRadius bordePildora = BorderRadius.all(Radius.circular(999));

  /// Margen de una tarjeta normal.
  static const EdgeInsets rellenoTarjeta = EdgeInsets.all(e16);
}
