import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kaizen/app.dart';
import 'package:kaizen/config/entorno.dart';
import 'package:kaizen/ui/core/adaptativo/busqueda.dart';
import 'package:kaizen/ui/hoy/widgets/pantalla_hoy.dart';

/// Flujo del Paso 3 en la app real (escritorio): entrar → secciones → Ctrl+K → perfil → salir.
/// `flutter test integration_test/navegacion_test.dart -d linux`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> buscarEIr(WidgetTester tester, String texto) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.byType(PaletaBusqueda), findsOneWidget);
    await tester.enterText(find.byType(TextField), texto);
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(PaletaBusqueda), matching: find.byType(ListTile)).first);
    await tester.pumpAndSettle();
    expect(find.byType(PaletaBusqueda), findsNothing);
  }

  testWidgets('entrar, navegar, buscar y salir', (tester) async {
    await tester.pumpWidget(
      KaizenApp(
        entorno: Entorno.desdeValores(fuente: 'fake', apiBaseUrl: apiProduccion, zonaHorariaDefecto: 'UTC'),
        mostrarHerramientasDev: true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Daniela'));
    await tester.pump();
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.byType(PantallaHoy), findsOneWidget);

    await tester.tap(find.text('Hábitos'));
    await tester.pumpAndSettle();
    expect(find.text('Esta pantalla llega en el paso 7 del plan.'), findsOneWidget);

    await buscarEIr(tester, 'progreso');
    expect(find.text('Esta pantalla llega en el paso 12 del plan.'), findsOneWidget);

    await buscarEIr(tester, 'perfil');
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
