import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/config/dependencias.dart';
import 'package:kaizen/data/fake/datos_demo.dart';
import 'package:kaizen/data/sync/monitor_conexion.dart';
import 'package:kaizen/domain/models/registro.dart';
import 'package:kaizen/ui/core/adaptativo/plataforma.dart';
import 'package:kaizen/ui/core/widgets/banner_sin_conexion.dart';
import 'package:kaizen/ui/core/widgets/fila_habito.dart';

import '../../helpers/app.dart';

Finder check(String nombre) =>
    find.descendant(of: find.widgetWithText(FilaHabito, nombre), matching: find.byType(BotonCheck));

void main() {
  late MonitorConexionManual red;
  late Dependencias deps;

  setUp(() {
    red = MonitorConexionManual();
    deps = Dependencias.fake(
      datos: DatosDemo(reloj: () => ahoraPrueba),
      monitor: red,
    );
  });

  testWidgets('sin red: aviso arriba, el check-in se queda; al volver la red se envía y el aviso se va', (
    tester,
  ) async {
    await montarApp(tester, dependencias: deps);
    expect(find.byType(BannerSinConexion), findsNothing);

    red.hayRed = false;
    await tester.pumpAndSettle();
    expect(find.byType(BannerSinConexion), findsOneWidget);
    expect(find.textContaining('tus cambios se guardan en este dispositivo'), findsOneWidget);

    await tester.tap(check('Leer'));
    await tester.pumpAndSettle();
    expect(find.text('3 de 5'), findsOneWidget, reason: 'sin red el check-in no se regresa');
    expect(find.textContaining('No se guardó'), findsNothing);
    expect(find.textContaining('1 registro por enviar'), findsOneWidget);

    final datos = deps.datosDemo!;
    final leer = datos.habitosDe('u-demo').firstWhere((h) => h.nombre == 'Leer').id;
    expect(datos.registros[leer]?[DateTime.utc(2026, 11, 25)], isNull);

    red.hayRed = true;
    await tester.pumpAndSettle();
    expect(find.byType(BannerSinConexion), findsNothing);
    expect(datos.registros[leer]![DateTime.utc(2026, 11, 25)]!.origen, OrigenRegistro.offline);
    expect(find.text('3 de 5'), findsOneWidget);
  });

  testWidgets('en escritorio el aviso también va arriba del riel', (tester) async {
    await montarApp(tester, dependencias: deps, plataforma: Plataforma.escritorio, tamano: const Size(1280, 800));
    red.hayRed = false;
    await tester.pumpAndSettle();
    expect(find.byType(BannerSinConexion), findsOneWidget);
    expect(tester.getTopLeft(find.byType(BannerSinConexion)).dy, 0);
  });

  testWidgets('si el servidor rechaza un check-in de la cola, se avisa una vez', (tester) async {
    await montarApp(tester, dependencias: deps);
    red.hayRed = false;
    await tester.pumpAndSettle();
    await tester.tap(check('Leer'));
    await tester.pumpAndSettle();
    final datos = deps.datosDemo!;
    datos.habitos[datos.habitosDe('u-demo').firstWhere((h) => h.nombre == 'Leer').id]!.activo = false;
    red.hayRed = true;
    await tester.pumpAndSettle();
    expect(find.text('Un check-in hecho sin conexión no se guardó: El hábito está archivado.'), findsOneWidget);
  });
}
