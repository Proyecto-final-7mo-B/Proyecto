import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/app.dart';
import 'package:kaizen/ui/core/tema/colores.dart';
import 'package:kaizen/ui/core/tema/tipografia.dart';
import 'package:kaizen/ui/core/widgets/logo_kaizen.dart';

import '../../helpers/app.dart';

void main() {
  testWidgets('prueba de humo: la app arranca en español y, sin sesión, muestra la entrada', (tester) async {
    await tester.pumpWidget(KaizenApp(entorno: entornoPrueba));
    await tester.pumpAndSettle();

    expect(find.text('Kaizen'), findsOneWidget);
    expect(find.text('Un paso pequeño cada día.'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Fuente de datos: fake'), findsOneWidget);
    expect(find.byType(LogoKaizen), findsOneWidget);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('es', 'MX'));
  });

  testWidgets('usa el tema de Kaizen: claro, fondo y fuente de los bosquejos', (tester) async {
    await tester.pumpWidget(KaizenApp(entorno: entornoPrueba));
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
    expect(app.darkTheme, isNull, reason: 'solo tema claro');
    expect(app.theme!.scaffoldBackgroundColor, KaizenColores.fondo);
    expect(app.theme!.textTheme.bodyMedium!.fontFamily, KaizenTipografia.familia);
  });

  testWidgets('sin herramientas de depuración (release) no hay entrada de prueba ni galería', (tester) async {
    await tester.pumpWidget(KaizenApp(entorno: entornoPrueba, mostrarHerramientasDev: false));
    await tester.pumpAndSettle();
    expect(find.text('Entrar como usuario demo'), findsNothing);
    expect(find.text('Ver componentes'), findsNothing);
    expect(find.text('Fuente de datos: fake'), findsNothing);
  });

  testWidgets('al quitar la app se liberan el router y la sesión', (tester) async {
    await tester.pumpWidget(KaizenApp(entorno: entornoPrueba));
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
