@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/routing/rutas.dart';
import 'package:kaizen/ui/core/adaptativo/plataforma.dart';

import '../helpers/app.dart';

/// Imágenes de referencia de los cuatro marcos de navegación, para compararlos con los bosquejos.
/// Regenerar (solo si el cambio es intencional): `flutter test --update-goldens --tags golden`.
void main() {
  final casos = <(String, Plataforma, Size, String)>[
    ('shell_movil', Plataforma.movil, const Size(390, 844), Rutas.hoy),
    ('shell_mediano', Plataforma.escritorio, const Size(900, 700), Rutas.habitos),
    ('shell_escritorio', Plataforma.escritorio, const Size(1280, 800), Rutas.hoy),
    ('shell_web', Plataforma.web, const Size(1440, 900), Rutas.hoy),
  ];
  for (final (nombre, plataforma, tamano, ruta) in casos) {
    testWidgets(nombre, (tester) async {
      await montarApp(tester, plataforma: plataforma, tamano: tamano, ubicacion: ruta, usuario: adminPrueba);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$nombre.png'));
    });
  }

  testWidgets('entrada provisional', (tester) async {
    await montarApp(tester, usuario: null, tamano: const Size(390, 844));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/entrar_provisional.png'));
  });
}
