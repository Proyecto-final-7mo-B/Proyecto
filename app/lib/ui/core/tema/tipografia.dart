import 'package:flutter/material.dart';

import 'colores.dart';

/// Tipografía: **Plus Jakarta Sans** (licencia OFL) incluida como asset en `assets/fuentes/plus_jakarta_sans/`, así que
/// funciona sin internet. Pesos incluidos: 400, 500, 600, 700 y 800.
abstract final class KaizenTipografia {
  static const String familia = 'PlusJakartaSans';

  /// Escala medida en los bosquejos.
  ///
  /// | Estilo | Tamaño | Uso |
  /// |---|---|---|
  /// | displayLarge | 44 / 800 | Marca "Kaizen" en el login |
  /// | displayMedium | 32 / 800 | Número grande ("2 de 5", "1,204") |
  /// | headlineLarge | 28 / 800 | Título de pantalla ("Hoy", "Panel de administración") |
  /// | headlineSmall | 20 / 800 | Cifra de tarjeta ("10 → 12 min") |
  /// | titleLarge | 18 / 700 | Mensaje destacado |
  /// | titleMedium | 16 / 700 | Título de tarjeta y de hábito ("Tomar agua") |
  /// | titleSmall | 14 / 700 | Etiqueta de campo ("Nombre", "Frecuencia") |
  /// | bodyLarge | 16 / 400 | Texto de campos |
  /// | bodyMedium | 14 / 400 | Cuerpo |
  /// | bodySmall | 13 / 400 | Subtítulos en gris ("2 L · diario") |
  /// | labelLarge | 15 / 700 | Botones |
  /// | labelMedium | 13 / 600 | Chips y segmentado |
  /// | labelSmall | 12 / 600 | Días "L M M J V S D" |
  static TextTheme textTheme() {
    const base = TextTheme(
      displayLarge: TextStyle(fontSize: 44, height: 1.1, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      displayMedium: TextStyle(fontSize: 32, height: 1.15, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      displaySmall: TextStyle(fontSize: 30, height: 1.15, fontWeight: FontWeight.w800, letterSpacing: -0.4),
      headlineLarge: TextStyle(fontSize: 28, height: 1.2, fontWeight: FontWeight.w800, letterSpacing: -0.3),
      headlineMedium: TextStyle(fontSize: 24, height: 1.25, fontWeight: FontWeight.w800, letterSpacing: -0.2),
      headlineSmall: TextStyle(fontSize: 20, height: 1.3, fontWeight: FontWeight.w800),
      titleLarge: TextStyle(fontSize: 18, height: 1.35, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(fontSize: 16, height: 1.35, fontWeight: FontWeight.w700),
      titleSmall: TextStyle(fontSize: 14, height: 1.4, fontWeight: FontWeight.w700),
      bodyLarge: TextStyle(fontSize: 16, height: 1.45, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(fontSize: 14, height: 1.45, fontWeight: FontWeight.w400),
      bodySmall: TextStyle(fontSize: 13, height: 1.4, fontWeight: FontWeight.w400),
      labelLarge: TextStyle(fontSize: 15, height: 1.3, fontWeight: FontWeight.w700),
      labelMedium: TextStyle(fontSize: 13, height: 1.3, fontWeight: FontWeight.w600),
      labelSmall: TextStyle(fontSize: 12, height: 1.3, fontWeight: FontWeight.w600, letterSpacing: 0.2),
    );
    final conColor = base.apply(fontFamily: familia, bodyColor: KaizenColores.texto, displayColor: KaizenColores.texto);
    // Los subtítulos van en gris, como en los bosquejos.
    return conColor.copyWith(bodySmall: conColor.bodySmall!.copyWith(color: KaizenColores.textoSecundario));
  }
}
