import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/ui/core/tema/iconos.dart';

void main() {
  test('cada categoría del catálogo inicial tiene su propio ícono', () {
    const catalogo = ['Aprendizaje', 'Ejercicio', 'Finanzas', 'Hidratación', 'Lectura', 'Meditación', 'Salud', 'Sueño'];
    final iconos = catalogo.map(KaizenIconos.deCategoria).toList();
    expect(iconos, isNot(contains(KaizenIconos.categoriaGenerica)));
    expect(iconos.toSet(), hasLength(catalogo.length), reason: 'no se repiten');
  });

  test('ignora mayúsculas, acentos y espacios', () {
    expect(KaizenIconos.deCategoria('  HIDRATACIÓN '), Icons.water_drop_outlined);
    expect(KaizenIconos.deCategoria('sueno'), Icons.bedtime_outlined);
    expect(KaizenIconos.deCategoria('Meditacion'), Icons.self_improvement);
  });

  test('una categoría nueva (creada por el admin) recibe el ícono genérico', () {
    expect(KaizenIconos.deCategoria('Jardinería'), KaizenIconos.categoriaGenerica);
    expect(KaizenIconos.deCategoria(''), KaizenIconos.categoriaGenerica);
  });

  test('normalizar', () {
    expect(KaizenIconos.normalizar('Ñandú Áéíóú'), 'nandu aeiou');
  });
}
