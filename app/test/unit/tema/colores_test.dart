import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/ui/core/tema/colores.dart';

String hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// Contraste WCAG 2.1 entre dos colores.
double contraste(Color a, Color b) {
  double canal(double c) => c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  double luminancia(Color c) => 0.2126 * canal(c.r) + 0.7152 * canal(c.g) + 0.0722 * canal(c.b);
  final la = luminancia(a);
  final lb = luminancia(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group('paleta medida en los bosquejos', () {
    test('los tokens principales tienen los hex medidos con cuentagotas', () {
      expect(hex(KaizenColores.marino900), '#121A3A');
      expect(hex(KaizenColores.marino800), '#1B2A5E');
      expect(hex(KaizenColores.azul600), '#2F4A9A');
      expect(hex(KaizenColores.azul400), '#7F9BE0');
      expect(hex(KaizenColores.azul200), '#C3D1F0');
      expect(hex(KaizenColores.azul100), '#E4EAF8');
      expect(hex(KaizenColores.fondo), '#F7F8FB');
      expect(hex(KaizenColores.naranjaRacha), '#C2410C');
      expect(hex(KaizenColores.avisoFondo), '#FFF4DB');
    });

    test('todos los colores son opacos', () {
      for (final c in [...KaizenColores.intensidad, ...KaizenColores.series, KaizenColores.error]) {
        expect(c.a, 1.0, reason: hex(c));
      }
    });
  });

  group('escala de intensidad 0–4', () {
    test('va de claro a oscuro y tiene 5 niveles', () {
      expect(KaizenColores.intensidad, hasLength(5));
      expect(KaizenColores.intensidad.first, KaizenColores.azul50);
      expect(KaizenColores.intensidad.last, KaizenColores.marino800);
    });

    test('deIntensidad recorta valores fuera de rango', () {
      expect(KaizenColores.deIntensidad(-3), KaizenColores.azul50);
      expect(KaizenColores.deIntensidad(2), KaizenColores.azul400);
      expect(KaizenColores.deIntensidad(9), KaizenColores.marino800);
    });

    test('el texto sobre cada nivel se lee (contraste ≥ 4.5)', () {
      for (var n = 0; n <= 4; n++) {
        final fondo = KaizenColores.deIntensidad(n);
        final texto = KaizenColores.textoSobreIntensidad(n);
        expect(contraste(texto, fondo), greaterThanOrEqualTo(4.5), reason: 'nivel $n');
      }
    });
  });

  group('contraste de texto (WCAG AA ≥ 4.5)', () {
    final pares = <String, (Color, Color)>{
      'texto sobre fondo': (KaizenColores.texto, KaizenColores.fondo),
      'texto secundario sobre blanco': (KaizenColores.textoSecundario, KaizenColores.superficie),
      'texto secundario sobre fondo': (KaizenColores.textoSecundario, KaizenColores.fondo),
      'blanco sobre primario': (KaizenColores.superficie, KaizenColores.marino800),
      'texto sobre marino (secundario)': (KaizenColores.textoSobreMarino, KaizenColores.marino800),
      'racha sobre blanco': (KaizenColores.naranjaRacha, KaizenColores.superficie),
      'enlace sobre blanco': (KaizenColores.azul600, KaizenColores.superficie),
      'aviso': (KaizenColores.avisoTexto, KaizenColores.avisoFondo),
      'error sobre blanco': (KaizenColores.error, KaizenColores.superficie),
      'texto sobre sugerencia': (KaizenColores.texto, KaizenColores.azul100),
    };
    pares.forEach((nombre, par) {
      test(nombre, () => expect(contraste(par.$1, par.$2), greaterThanOrEqualTo(4.5)));
    });
  });
}
