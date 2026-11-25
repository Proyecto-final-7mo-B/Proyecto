import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/ui/core/tema/colores.dart';
import 'package:kaizen/ui/core/tema/medidas.dart';
import 'package:kaizen/ui/core/tema/tema.dart';
import 'package:kaizen/ui/core/tema/tipografia.dart';

void main() {
  final tema = KaizenTema.claro();

  test('es Material 3 y solo claro', () {
    expect(tema.useMaterial3, isTrue);
    expect(tema.brightness, Brightness.light);
    expect(tema.colorScheme.brightness, Brightness.light);
  });

  test('el ColorScheme usa exactamente los tokens de la paleta', () {
    final c = tema.colorScheme;
    expect(c.primary, KaizenColores.marino800);
    expect(c.onPrimary, KaizenColores.superficie);
    expect(c.secondary, KaizenColores.azul600);
    expect(c.tertiary, KaizenColores.naranjaRacha);
    expect(c.error, KaizenColores.error);
    expect(c.surface, KaizenColores.superficie);
    expect(c.onSurface, KaizenColores.texto);
    expect(c.onSurfaceVariant, KaizenColores.textoSecundario);
    expect(c.outlineVariant, KaizenColores.borde);
    expect(tema.scaffoldBackgroundColor, KaizenColores.fondo);
  });

  test('toda la tipografía es Plus Jakarta Sans', () {
    final t = tema.textTheme;
    for (final estilo in [t.displayLarge, t.headlineLarge, t.titleMedium, t.bodyMedium, t.bodySmall, t.labelLarge]) {
      expect(estilo!.fontFamily, KaizenTipografia.familia);
    }
  });

  test('escala de textos de los bosquejos', () {
    final t = tema.textTheme;
    expect(t.displayLarge!.fontSize, 44); // marca
    expect(t.displayMedium!.fontSize, 32); // "2 de 5"
    expect(t.headlineLarge!.fontSize, 28); // título de pantalla
    expect(t.titleMedium!.fontSize, 16); // título de tarjeta
    expect(t.titleMedium!.fontWeight, FontWeight.w700);
    expect(t.bodyMedium!.fontSize, 14);
    expect(t.labelSmall!.fontSize, 12);
    expect(t.bodySmall!.color, KaizenColores.textoSecundario);
    expect(t.bodyMedium!.color, KaizenColores.texto);
  });

  test('botón principal de 52 px de alto y radio 12', () {
    final estilo = tema.filledButtonTheme.style!;
    expect(estilo.minimumSize!.resolve({})!.height, KaizenMedidas.altoBoton);
    expect(estilo.backgroundColor!.resolve({}), KaizenColores.marino800);
    expect(estilo.backgroundColor!.resolve({WidgetState.disabled}), KaizenColores.azul100);
    final forma = estilo.shape!.resolve({})! as RoundedRectangleBorder;
    expect(forma.borderRadius, KaizenMedidas.bordeControl);
  });

  test('tarjetas blancas, sin sombra, radio 16 y borde de 1 px', () {
    final tarjeta = tema.cardTheme;
    expect(tarjeta.color, KaizenColores.superficie);
    expect(tarjeta.elevation, 0);
    final forma = tarjeta.shape! as RoundedRectangleBorder;
    expect(forma.borderRadius, KaizenMedidas.bordeTarjeta);
    expect(forma.side.color, KaizenColores.borde);
  });

  test('campos blancos con borde claro que se oscurece al enfocar', () {
    final campos = tema.inputDecorationTheme;
    expect(campos.filled, isTrue);
    expect(campos.fillColor, KaizenColores.superficie);
    expect(campos.enabledBorder!.borderSide.color, KaizenColores.bordeCampo);
    expect(campos.focusedBorder!.borderSide.color, KaizenColores.marino800);
    expect(campos.errorBorder!.borderSide.color, KaizenColores.error);
  });

  test('interruptor y navegación con los colores de los bosquejos', () {
    expect(tema.switchTheme.trackColor!.resolve({WidgetState.selected}), KaizenColores.marino800);
    expect(tema.switchTheme.thumbColor!.resolve({WidgetState.selected}), KaizenColores.superficie);
    expect(tema.navigationBarTheme.indicatorColor, KaizenColores.azul100);
    expect(tema.navigationRailTheme.backgroundColor, KaizenColores.marino900);
    expect(tema.navigationRailTheme.indicatorColor, KaizenColores.azul600);
  });
}
