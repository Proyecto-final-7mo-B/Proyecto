@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/routing/rutas.dart';
import 'package:kaizen/ui/core/adaptativo/plataforma.dart';

import '../helpers/app.dart';

/// Logros (Paso 11) con los de Daniela: 6 de 10 insignias.
/// Regenerar (solo si el cambio es intencional): `flutter test --update-goldens --tags golden`.
void main() {
  for (final (nombre, plataforma, tamano, bool detalle) in [
    ('logros_movil', Plataforma.movil, const Size(390, 844), false),
    ('logros_escritorio', Plataforma.escritorio, const Size(1440, 900), false),
    ('logros_detalle_movil', Plataforma.movil, const Size(390, 844), true),
  ]) {
    testWidgets(nombre, (tester) async {
      await montarApp(tester, plataforma: plataforma, tamano: tamano, ubicacion: Rutas.logros);
      if (detalle) {
        await tester.tap(find.byKey(const ValueKey('logro-racha_30')));
        await tester.pumpAndSettle();
      }
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$nombre.png'));
    });
  }
}
