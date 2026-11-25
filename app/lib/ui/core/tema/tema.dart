import 'package:flutter/material.dart';

import 'colores.dart';
import 'medidas.dart';
import 'tipografia.dart';

/// Tema de Kaizen: Material 3, **solo claro**.
///
/// El `ColorScheme` se arma a mano con los tokens de [KaizenColores] (no con `fromSeed`), para que los colores sean
/// exactamente los de los bosquejos.
abstract final class KaizenTema {
  static const ColorScheme esquema = ColorScheme(
    brightness: Brightness.light,
    primary: KaizenColores.marino800,
    onPrimary: KaizenColores.superficie,
    primaryContainer: KaizenColores.azul100,
    onPrimaryContainer: KaizenColores.marino900,
    secondary: KaizenColores.azul600,
    onSecondary: KaizenColores.superficie,
    secondaryContainer: KaizenColores.azul100,
    onSecondaryContainer: KaizenColores.marino800,
    tertiary: KaizenColores.naranjaRacha,
    onTertiary: KaizenColores.superficie,
    tertiaryContainer: KaizenColores.avisoFondo,
    onTertiaryContainer: KaizenColores.avisoTexto,
    error: KaizenColores.error,
    onError: KaizenColores.superficie,
    surface: KaizenColores.superficie,
    onSurface: KaizenColores.texto,
    onSurfaceVariant: KaizenColores.textoSecundario,
    surfaceContainerLowest: KaizenColores.superficie,
    surfaceContainerLow: KaizenColores.fondo,
    surfaceContainer: KaizenColores.azul50,
    surfaceContainerHigh: KaizenColores.azul100,
    surfaceContainerHighest: KaizenColores.azul100,
    outline: KaizenColores.bordeControl,
    outlineVariant: KaizenColores.borde,
    inverseSurface: KaizenColores.marino900,
    onInverseSurface: KaizenColores.superficie,
    inversePrimary: KaizenColores.azul200,
    shadow: Color(0x14121A3A),
    scrim: Color(0x66121A3A),
    surfaceTint: Colors.transparent,
  );

  static ThemeData claro() {
    final texto = KaizenTipografia.textTheme();
    const bordeCampo = OutlineInputBorder(
      borderRadius: KaizenMedidas.bordeControl,
      borderSide: BorderSide(color: KaizenColores.bordeCampo),
    );
    const formaControl = RoundedRectangleBorder(borderRadius: KaizenMedidas.bordeControl);
    const tamanoBoton = Size(64, KaizenMedidas.altoBoton);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: esquema,
      fontFamily: KaizenTipografia.familia,
      textTheme: texto,
      scaffoldBackgroundColor: KaizenColores.fondo,
      canvasColor: KaizenColores.fondo,
      dividerColor: KaizenColores.borde,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      iconTheme: const IconThemeData(color: KaizenColores.texto, size: 22),
      appBarTheme: AppBarTheme(
        backgroundColor: KaizenColores.fondo,
        foregroundColor: KaizenColores.texto,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: texto.titleLarge,
      ),
      cardTheme: const CardThemeData(
        color: KaizenColores.superficie,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: KaizenMedidas.bordeTarjeta,
          side: BorderSide(color: KaizenColores.borde),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: KaizenColores.marino800,
          foregroundColor: KaizenColores.superficie,
          disabledBackgroundColor: KaizenColores.azul100,
          disabledForegroundColor: KaizenColores.textoSecundario,
          minimumSize: tamanoBoton,
          padding: const EdgeInsets.symmetric(horizontal: KaizenMedidas.e24),
          shape: formaControl,
          textStyle: texto.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: KaizenColores.superficie,
          foregroundColor: KaizenColores.texto,
          minimumSize: tamanoBoton,
          padding: const EdgeInsets.symmetric(horizontal: KaizenMedidas.e24),
          side: const BorderSide(color: KaizenColores.bordeCampo),
          shape: formaControl,
          textStyle: texto.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KaizenColores.azul600,
          shape: formaControl,
          textStyle: texto.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: KaizenColores.texto)),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: KaizenColores.marino800,
        foregroundColor: KaizenColores.superficie,
        elevation: 0,
        shape: formaControl,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: KaizenColores.superficie,
        contentPadding: const EdgeInsets.symmetric(horizontal: KaizenMedidas.e16, vertical: KaizenMedidas.e16),
        hintStyle: texto.bodyLarge!.copyWith(color: KaizenColores.textoSecundario),
        helperStyle: texto.bodySmall!.copyWith(color: KaizenColores.azul600, fontWeight: FontWeight.w600),
        errorStyle: texto.bodySmall!.copyWith(color: KaizenColores.error, fontWeight: FontWeight.w600),
        helperMaxLines: 3,
        errorMaxLines: 3,
        border: bordeCampo,
        enabledBorder: bordeCampo,
        disabledBorder: bordeCampo,
        focusedBorder: bordeCampo.copyWith(borderSide: const BorderSide(color: KaizenColores.marino800, width: 1.5)),
        errorBorder: bordeCampo.copyWith(borderSide: const BorderSide(color: KaizenColores.error)),
        focusedErrorBorder: bordeCampo.copyWith(borderSide: const BorderSide(color: KaizenColores.error, width: 1.5)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: KaizenColores.superficie,
        selectedColor: KaizenColores.marino800,
        disabledColor: KaizenColores.azul50,
        side: const BorderSide(color: KaizenColores.bordeCampo),
        shape: const StadiumBorder(),
        labelStyle: texto.labelMedium,
        secondaryLabelStyle: texto.labelMedium!.copyWith(color: KaizenColores.superficie),
        checkmarkColor: KaizenColores.superficie,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: KaizenMedidas.e12, vertical: KaizenMedidas.e8),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.selected) ? KaizenColores.superficie : KaizenColores.bordeControl,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.selected) ? KaizenColores.marino800 : KaizenColores.azul50,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.selected) ? KaizenColores.marino800 : KaizenColores.bordeControl,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.selected) ? KaizenColores.marino800 : KaizenColores.superficie,
        ),
        checkColor: const WidgetStatePropertyAll(KaizenColores.superficie),
        side: const BorderSide(color: KaizenColores.bordeControl, width: 1.5),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: KaizenColores.marino800,
        linearTrackColor: KaizenColores.azul50,
        circularTrackColor: KaizenColores.azul50,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: KaizenColores.superficie,
        surfaceTintColor: Colors.transparent,
        indicatorColor: KaizenColores.azul100,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (estados) => texto.labelSmall!.copyWith(
            color: KaizenColores.texto,
            fontWeight: estados.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        iconTheme: const WidgetStatePropertyAll(IconThemeData(color: KaizenColores.texto)),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: KaizenColores.marino900,
        indicatorColor: KaizenColores.azul600,
        indicatorShape: formaControl,
        selectedIconTheme: const IconThemeData(color: KaizenColores.superficie),
        unselectedIconTheme: const IconThemeData(color: KaizenColores.azul200),
        selectedLabelTextStyle: texto.titleSmall!.copyWith(color: KaizenColores.superficie),
        unselectedLabelTextStyle: texto.bodyMedium!.copyWith(color: KaizenColores.azul200),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: KaizenColores.superficie,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: KaizenMedidas.bordeTarjeta),
        titleTextStyle: texto.titleLarge,
        contentTextStyle: texto.bodyMedium,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: KaizenColores.superficie,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(KaizenMedidas.radioTarjeta)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: KaizenColores.marino900,
        contentTextStyle: texto.bodyMedium!.copyWith(color: KaizenColores.superficie),
        actionTextColor: KaizenColores.azul200,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: KaizenMedidas.bordeControl),
      ),
      dividerTheme: const DividerThemeData(color: KaizenColores.borde, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: KaizenColores.texto,
        textColor: KaizenColores.texto,
        titleTextStyle: texto.titleMedium,
        subtitleTextStyle: texto.bodySmall,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: const BoxDecoration(color: KaizenColores.marino900, borderRadius: KaizenMedidas.bordeCelda),
        textStyle: texto.bodySmall!.copyWith(color: KaizenColores.superficie),
      ),
    );
  }
}
