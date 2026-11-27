import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/data/fake/catalogo_demo.dart';
import 'package:kaizen/domain/models/categoria.dart';
import 'package:kaizen/ui/core/tema/colores.dart';

import 'colores_test.dart' show contraste, hex;

/// Paso 9: cada token nuevo de la paleta (doc. 04 de la investigación) con su hex y su contraste WCAG 2.2:
/// 4.5:1 para texto y 3:1 para íconos y componentes (F45).
void main() {
  const blanco = KaizenColores.superficie;
  const fondo = KaizenColores.fondo;

  group('los hex son los del doc. 04', () {
    test('progreso, bienestar y racha por niveles', () {
      expect(hex(KaizenColores.verdeProgreso), '#047857');
      expect(hex(KaizenColores.verdeProgresoFondo), '#E1EFEB');
      expect(hex(KaizenColores.verdeProgresoSobreMarino), '#34D399');
      expect(hex(KaizenColores.tealBienestar), '#0F766E');
      expect(hex(KaizenColores.rachaSinRacha), '#6B7280');
      expect(hex(KaizenColores.rachaChispa), '#B45309');
      expect(hex(KaizenColores.naranjaRacha), '#C2410C');
      expect(hex(KaizenColores.rachaProfunda), '#9A3412');
      expect(hex(KaizenColores.rachaDorada), '#A16207');
      expect(hex(KaizenColores.error), '#B3261E');
    });
  });

  group('contraste (WCAG 2.2)', () {
    test('los tokens que llevan texto pasan 4.5:1 sobre blanco y sobre el fondo de la app', () {
      final texto = {
        'verdeProgreso': KaizenColores.verdeProgreso,
        'tealBienestar': KaizenColores.tealBienestar,
        'rachaSinRacha': KaizenColores.rachaSinRacha,
        'rachaChispa': KaizenColores.rachaChispa,
        'naranjaRacha': KaizenColores.naranjaRacha,
        'rachaProfunda': KaizenColores.rachaProfunda,
        'rachaDorada': KaizenColores.rachaDorada,
      };
      for (final MapEntry(:key, :value) in texto.entries) {
        expect(contraste(value, blanco), greaterThanOrEqualTo(4.5), reason: '$key sobre blanco');
        expect(contraste(value, fondo), greaterThanOrEqualTo(4.5), reason: '$key sobre el fondo');
      }
    });

    test('la palomita blanca sobre el check verde y el ícono verde sobre su fondo', () {
      expect(contraste(blanco, KaizenColores.verdeProgreso), greaterThanOrEqualTo(4.5));
      expect(contraste(KaizenColores.verdeProgreso, KaizenColores.verdeProgresoFondo), greaterThanOrEqualTo(3));
    });

    test('la barra verde sobre la tarjeta marino ("2 de 5") pasa 3:1 contra la tarjeta y contra su pista', () {
      expect(contraste(KaizenColores.verdeProgresoSobreMarino, KaizenColores.marino800), greaterThanOrEqualTo(3));
      expect(contraste(KaizenColores.verdeProgresoSobreMarino, KaizenColores.marino700), greaterThanOrEqualTo(3));
      // Por eso no se usa el verde oscuro ahí:
      expect(contraste(KaizenColores.verdeProgreso, KaizenColores.marino800), lessThan(3));
    });

    test('el ícono de cada categoría del catálogo pasa 3:1 sobre su fondo al 12 %', () {
      final lista = jsonDecode(catalogoDemoJson) as List<dynamic>;
      final categorias = [for (final c in lista) Categoria.fromJson(c as Map<String, dynamic>)];
      expect(categorias.map((c) => c.clave), containsAll(['ejercicio', 'salud', 'educacion', 'bienestar', 'finanzas']));
      for (final c in categorias) {
        final color = KaizenColores.deHex(c.color);
        expect(contraste(color, KaizenColores.fondoDe(color)), greaterThanOrEqualTo(3), reason: c.nombre);
        expect(contraste(color, blanco), greaterThanOrEqualTo(3), reason: '${c.nombre} sobre blanco');
      }
    });

    test('ningún token de progreso o de racha es el rojo de error (F40)', () {
      final progreso = [
        KaizenColores.verdeProgreso,
        KaizenColores.verdeProgresoSobreMarino,
        KaizenColores.rachaSinRacha,
        KaizenColores.rachaChispa,
        KaizenColores.naranjaRacha,
        KaizenColores.rachaProfunda,
        KaizenColores.rachaDorada,
        ...KaizenColores.intensidad,
      ];
      expect(progreso, isNot(contains(KaizenColores.error)));
    });
  });
}
