import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Configuración de las pruebas golden:
/// 1. Carga las fuentes reales (Plus Jakarta Sans y los íconos de Material). Sin esto, las pruebas dibujan cada letra
///    como un cuadro (fuente Ahem) y la imagen no sirve para comparar con los bosquejos.
/// 2. Tolera hasta un 0.5 % de píxeles distintos: el suavizado de las letras cambia un poco entre máquinas.
Future<void> testExecutable(FutureOr<void> Function() pruebas) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  await _cargarFuentes();
  final actual = goldenFileComparator;
  if (actual is LocalFileComparator) {
    goldenFileComparator = ComparadorTolerante(Uri.parse('${actual.basedir}golden_test.dart'), tolerancia: 0.005);
  }
  await pruebas();
}

Future<void> _cargarFuentes() async {
  final jakarta = FontLoader('PlusJakartaSans');
  for (final peso in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    jakarta.addFont(_leer('assets/fuentes/plus_jakarta_sans/PlusJakartaSans-$peso.ttf'));
  }
  await jakarta.load();

  final iconos = _rutaIconosMaterial();
  if (iconos != null) {
    await (FontLoader('MaterialIcons')..addFont(_leer(iconos))).load();
  }
}

Future<ByteData> _leer(String ruta) async => ByteData.sublistView(Uint8List.fromList(await File(ruta).readAsBytes()));

/// `MaterialIcons-Regular.otf` viene con el SDK de Flutter (bin/cache/artifacts/material_fonts).
String? _rutaIconosMaterial() {
  final raices = [
    Platform.environment['FLUTTER_ROOT'],
    // flutter_tester vive en <flutter>/bin/cache/artifacts/engine/<plataforma>/
    File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.parent.path,
  ];
  for (final raiz in raices.whereType<String>()) {
    final ruta = '$raiz/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
    if (File(ruta).existsSync()) {
      return ruta;
    }
  }
  return null;
}

/// Igual que el comparador normal, pero acepta diferencias menores a [tolerancia] (proporción de píxeles).
class ComparadorTolerante extends LocalFileComparator {
  ComparadorTolerante(super.testFile, {required this.tolerancia});

  final double tolerancia;

  @override
  Future<bool> compare(Uint8List imagen, Uri golden) async {
    final resultado = await GoldenFileComparator.compareLists(imagen, await getGoldenBytes(golden));
    if (resultado.passed || resultado.diffPercent <= tolerancia) {
      resultado.dispose();
      return true;
    }
    final error = await generateFailureOutput(resultado, golden, basedir);
    resultado.dispose();
    throw FlutterError(error);
  }
}
