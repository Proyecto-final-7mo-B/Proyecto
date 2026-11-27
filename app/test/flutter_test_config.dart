import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

/// Configuración de todas las pruebas:
/// - un toque que no llega a su widget (fuera de pantalla o tapado) es un error, no solo una advertencia;
/// - cada prueba usa su propia base local en memoria: varias instancias de `BaseLocal` son intencionales.
Future<void> testExecutable(FutureOr<void> Function() pruebas) async {
  WidgetController.hitTestWarningShouldBeFatal = true;
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  await pruebas();
}
