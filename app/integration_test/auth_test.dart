import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kaizen/app.dart';
import 'package:kaizen/config/dependencias.dart';
import 'package:kaizen/config/entorno.dart';
import 'package:kaizen/data/services/almacen_seguro.dart';
import 'package:kaizen/data/services/gestor_tokens.dart';
import 'package:kaizen/ui/auth/widgets/pantalla_entrar.dart';
import 'package:kaizen/ui/core/adaptativo/busqueda.dart';
import 'package:kaizen/ui/core/widgets/campo_validado.dart';
import 'package:kaizen/utils/paises_estados.dart';

/// Flujo del Paso 5 en la app real: crear cuenta → Hoy → cerrar sesión (tokens borrados) → entrar de nuevo.
/// `flutter test integration_test/auth_test.dart -d linux`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Finder campo(int i) => find.descendant(of: find.byType(CampoValidado), matching: find.byType(TextField)).at(i);

  Future<void> tocar(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets('registrarse, salir y volver a entrar', (tester) async {
    final almacen = AlmacenEnMemoria();
    final catalogo = await CatalogoRegiones.cargar();
    final deps = Dependencias.fake(almacen: almacen, catalogo: catalogo);
    await tester.pumpWidget(
      KaizenApp(
        entorno: Entorno.desdeValores(fuente: 'fake', apiBaseUrl: apiProduccion, zonaHorariaDefecto: 'UTC'),
        dependencias: deps,
        mostrarHerramientasDev: false,
      ),
    );
    await tester.pumpAndSettle();

    // 1. Crear cuenta (Argentina: sin estado, región LATAM).
    await tocar(tester, find.text('Crear cuenta').first);
    await tester.enterText(campo(0), 'Valeria');
    await tester.enterText(campo(1), 'valeria@correo.com');
    await tester.enterText(campo(2), 'una frase larga y segura');
    await tocar(tester, find.byType(DropdownButtonFormField<String>).first);
    await tocar(tester, find.text('Argentina').last);
    await tocar(tester, find.text('Acepto el aviso de privacidad'));
    await tocar(tester, find.widgetWithText(FilledButton, 'Crear cuenta'));
    expect(find.byType(PantallaEntrar), findsNothing);
    expect(find.text('Esta pantalla llega en el paso 6 del plan.'), findsOneWidget);
    expect(await almacen.leer(GestorTokens.claveRenovacion), isNotNull);

    // 2. Cerrar sesión desde el perfil (Ctrl+K → perfil): se borran los tokens.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(of: find.byType(PaletaBusqueda), matching: find.byType(TextField)),
      'perfil',
    );
    await tester.pumpAndSettle();
    await tocar(tester, find.descendant(of: find.byType(PaletaBusqueda), matching: find.byType(ListTile)).first);
    await tocar(tester, find.text('Cerrar sesión'));
    expect(find.byType(PantallaEntrar), findsOneWidget);
    expect(await almacen.leer(GestorTokens.claveRenovacion), isNull);
    expect(deps.tokens.tokenAcceso, isNull);

    // 3. Entrar con la cuenta recién creada.
    await tester.enterText(campo(0), 'Valeria@Correo.com');
    await tester.enterText(campo(1), 'una frase larga y segura');
    await tocar(tester, find.text('Iniciar sesión'));
    expect(find.byType(PantallaEntrar), findsNothing);
    expect(await almacen.leer(GestorTokens.claveRenovacion), isNotNull);
  });
}
