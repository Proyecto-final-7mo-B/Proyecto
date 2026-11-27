// El catálogo del modo fake (el mismo del clúster) se puede dibujar y respeta el contraste del doc. 04.
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/data/fake/catalogo_demo.dart';
import 'package:kaizen/domain/models/categoria.dart';
import 'package:kaizen/ui/core/tema/colores.dart';
import 'package:kaizen/ui/core/tema/iconos.dart';

double contraste(Color a, Color b) {
  double canal(double c) => c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4).toDouble();
  double luminancia(Color c) => 0.2126 * canal(c.r) + 0.7152 * canal(c.g) + 0.0722 * canal(c.b);
  final la = luminancia(a);
  final lb = luminancia(b);
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

void main() {
  final catalogo = [
    for (final c in jsonDecode(catalogoDemoJson) as List<dynamic>) Categoria.fromJson(c as Map<String, dynamic>),
  ];

  test('5 categorías y 22 subcategorías, cada una con unidades; 18 con referencia citada', () {
    expect(catalogo.map((c) => c.clave), ['ejercicio', 'salud', 'educacion', 'bienestar', 'finanzas']);
    final subs = catalogo.todasLasSubcategorias.toList();
    expect(subs, hasLength(22));
    expect(subs.where((s) => s.unidades.isEmpty), isEmpty);
    final conReferencia = subs.where((s) => s.referencia != null).toList();
    expect(conReferencia, hasLength(18));
    for (final s in conReferencia) {
      final r = s.referencia!;
      expect(r.fuentes, matches(RegExp(r'^F[0-9]{2}(, F[0-9]{2})*$')), reason: s.clave);
      expect(r.url, startsWith('https://'), reason: s.clave);
      expect(s.unidad(r.unidadBase)?.factorABase, 1, reason: '${s.clave}: la unidad base es una unidad con factor 1');
      expect(r.optimoHasta, greaterThanOrEqualTo(r.optimoDesde));
      if (r.maximo != null) {
        expect(r.maximo, greaterThanOrEqualTo(r.optimoHasta));
      }
    }
  });

  test('la app sabe dibujar cada ícono del catálogo', () {
    final nombres = {...catalogo.map((c) => c.icono), ...catalogo.todasLasSubcategorias.map((s) => s.icono)};
    expect(nombres.difference(KaizenIconos.nombresConocidos.toSet()), isEmpty);
  });

  test('colores de categoría: el ícono se ve sobre su fondo (≥ 3:1) y sobre el fondo de la app (doc. 04)', () {
    for (final c in catalogo) {
      final color = KaizenColores.deHex(c.color);
      expect(color, isNot(KaizenColores.marino800), reason: '${c.clave}: hex válido');
      expect(contraste(color, KaizenColores.fondoDe(color)), greaterThanOrEqualTo(3), reason: c.clave);
      expect(contraste(color, KaizenColores.fondo), greaterThanOrEqualTo(3), reason: c.clave);
      expect(contraste(KaizenColores.texto, KaizenColores.fondoDe(color)), greaterThanOrEqualTo(4.5), reason: c.clave);
    }
    expect(contraste(KaizenColores.verdeProgreso, KaizenColores.superficie), greaterThanOrEqualTo(4.5));
  });

  test('hex inválido: marino', () {
    expect(KaizenColores.deHex('rojo'), KaizenColores.marino800);
    expect(KaizenColores.deHex('#12'), KaizenColores.marino800);
  });

  test('por nombre de Material; desconocido → genérico; respaldo por nombre de categoría vieja', () {
    expect(KaizenIconos.porNombre('water_drop'), Icons.water_drop_outlined);
    expect(KaizenIconos.porNombre('no_existe'), KaizenIconos.categoriaGenerica);
    expect(KaizenIconos.deCategoria('Educación'), Icons.school_outlined);
  });
}
