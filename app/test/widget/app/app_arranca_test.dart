import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/app.dart';
import 'package:kaizen/config/entorno.dart';
import 'package:kaizen/ui/core/tema/colores.dart';
import 'package:kaizen/ui/core/tema/tipografia.dart';
import 'package:kaizen/ui/core/widgets/logo_kaizen.dart';
import 'package:kaizen/ui/dev/galeria_componentes.dart';

void main() {
  final entorno = Entorno.desdeValores(fuente: 'fake', apiBaseUrl: apiProduccion, zonaHorariaDefecto: 'UTC');

  testWidgets('prueba de humo: la app arranca en español y muestra la pantalla inicial', (tester) async {
    await tester.pumpWidget(KaizenApp(entorno: entorno));
    await tester.pumpAndSettle();

    expect(find.text('Kaizen'), findsOneWidget);
    expect(find.text('Un paso pequeño cada día.'), findsOneWidget);
    expect(find.text('Fuente de datos: fake'), findsOneWidget);
    expect(find.byType(LogoKaizen), findsOneWidget);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('es', 'MX'));
  });

  testWidgets('usa el tema de Kaizen: claro, fondo y fuente de los bosquejos', (tester) async {
    await tester.pumpWidget(KaizenApp(entorno: entorno));
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
    expect(app.darkTheme, isNull, reason: 'solo tema claro');
    expect(app.theme!.scaffoldBackgroundColor, KaizenColores.fondo);
    expect(app.theme!.textTheme.bodyMedium!.fontFamily, KaizenTipografia.familia);
  });

  testWidgets('en depuración abre la galería de componentes', (tester) async {
    await tester.pumpWidget(KaizenApp(entorno: entorno, mostrarHerramientasDev: true));
    await tester.tap(find.text('Ver componentes'));
    await tester.pumpAndSettle();
    expect(find.byType(GaleriaComponentes), findsOneWidget);
  });

  testWidgets('sin herramientas de depuración (release) no hay acceso a la galería', (tester) async {
    await tester.pumpWidget(KaizenApp(entorno: entorno, mostrarHerramientasDev: false));
    expect(find.text('Ver componentes'), findsNothing);
  });
}
