@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/routing/rutas.dart';
import 'package:kaizen/ui/core/adaptativo/plataforma.dart';
import 'package:kaizen/ui/core/widgets/contador_meta.dart';

import '../helpers/app.dart';

/// Módulo Hábitos con los datos de Daniela, para compararlo con los bosquejos 03 y 04 (con el respaldo científico
/// del 27-nov: subcategoría, unidad permitida, "Lo que dice la evidencia", prioridad e intención).
/// Regenerar (solo si el cambio es intencional): `flutter test --update-goldens --tags golden`.
void main() {
  const movil = Size(390, 844);
  const escritorio = Size(1440, 900);

  Future<void> tocar(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  /// Toca [veces] veces el + (o el − si [subir] es `false`) del contador de meta.
  Future<void> contador(WidgetTester tester, {required bool subir, required int veces}) async {
    final boton = find.descendant(
      of: find.byType(ContadorMeta),
      matching: find.byIcon(subir ? Icons.add : Icons.remove),
    );
    for (var i = 0; i < veces; i++) {
      await tocar(tester, boton);
    }
  }

  for (final (nombre, plataforma, tamano, ruta, Future<void> Function(WidgetTester)? llenar) in [
    ('habitos_lista_movil', Plataforma.movil, movil, (String _) => Rutas.habitos, null),
    (
      'habitos_nuevo_movil',
      Plataforma.movil,
      movil,
      (String _) => Rutas.nuevoHabito,
      (WidgetTester t) async {
        await t.enterText(find.byType(TextField).first, 'Caminar');
        await tocar(t, find.text('Ejercicio'));
        await tocar(t, find.text('Aeróbico moderado'));
        await t.scrollUntilVisible(
          find.text('Dentro de lo recomendado'),
          -300,
          scrollable: find.byType(Scrollable).first,
        );
      },
    ),
    (
      'habitos_nuevo_escritorio',
      Plataforma.escritorio,
      escritorio,
      (String _) => Rutas.nuevoHabito,
      (WidgetTester t) async {
        await t.enterText(find.byType(TextField).first, 'Leer novelas');
        await tocar(t, find.text('Educación'));
        await tocar(t, find.text('Lectura'));
        await contador(t, subir: false, veces: 2);
      },
    ),
    (
      'habitos_nuevo_excesivo_escritorio',
      Plataforma.escritorio,
      escritorio,
      (String _) => Rutas.nuevoHabito,
      (WidgetTester t) async {
        await t.enterText(find.byType(TextField).first, 'Bici');
        await tocar(t, find.text('Ejercicio'));
        await tocar(t, find.text('Aeróbico moderado'));
        await tocar(t, find.text('h'));
        await contador(t, subir: true, veces: 6);
        await t.scrollUntilVisible(find.text('Más de lo recomendado'), 300, scrollable: find.byType(Scrollable).first);
      },
    ),
    ('habitos_detalle_movil', Plataforma.movil, movil, Rutas.habito, null),
    ('habitos_detalle_escritorio', Plataforma.escritorio, escritorio, Rutas.habito, null),
    ('habitos_editar_movil', Plataforma.movil, movil, Rutas.editarHabito, null),
  ]) {
    testWidgets(nombre, (tester) async {
      final deps = dependenciasPrueba();
      final leer = deps.datosDemo!.habitosDe('u-demo').firstWhere((h) => h.nombre == 'Leer');
      await montarApp(tester, plataforma: plataforma, tamano: tamano, ubicacion: ruta(leer.id), dependencias: deps);
      if (llenar != null) {
        await llenar(tester);
      }
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$nombre.png'));
    });
  }
}
