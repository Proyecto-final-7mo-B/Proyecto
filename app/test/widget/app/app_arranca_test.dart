import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/app.dart';
import 'package:kaizen/config/entorno.dart';

void main() {
  testWidgets('prueba de humo: la app arranca en español y muestra la pantalla inicial', (tester) async {
    final entorno = Entorno.desdeValores(fuente: 'fake', apiBaseUrl: apiProduccion, zonaHorariaDefecto: 'UTC');
    await tester.pumpWidget(KaizenApp(entorno: entorno));
    await tester.pumpAndSettle();

    expect(find.text('Kaizen'), findsOneWidget);
    expect(find.text('Un paso pequeño cada día.'), findsOneWidget);
    expect(find.text('Fuente de datos: fake'), findsOneWidget);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('es', 'MX'));
  });
}
