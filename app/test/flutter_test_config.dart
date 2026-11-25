import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

/// Configuración de todas las pruebas: un toque que no llega a su widget (fuera de pantalla o tapado) es un error,
/// no solo una advertencia.
Future<void> testExecutable(FutureOr<void> Function() pruebas) async {
  WidgetController.hitTestWarningShouldBeFatal = true;
  await pruebas();
}
