@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/ui/core/adaptativo/plataforma.dart';

import '../helpers/app.dart';

/// Pantalla Hoy con los datos de Daniela ("2 de 5", sugerencia de Leer, cápsulas), para compararla con el bosquejo 02.
/// Regenerar (solo si el cambio es intencional): `flutter test --update-goldens --tags golden`.
void main() {
  for (final (nombre, plataforma, tamano) in const [
    ('hoy_movil', Plataforma.movil, Size(390, 844)),
    ('hoy_escritorio', Plataforma.escritorio, Size(1440, 900)),
    ('hoy_web', Plataforma.web, Size(1440, 900)),
  ]) {
    testWidgets(nombre, (tester) async {
      await montarApp(tester, plataforma: plataforma, tamano: tamano);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$nombre.png'));
    });
  }
}
