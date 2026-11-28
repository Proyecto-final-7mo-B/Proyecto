import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kaizen/app.dart';
import 'package:kaizen/config/dependencias.dart';
import 'package:kaizen/config/entorno.dart';
import 'package:kaizen/data/fake/datos_demo.dart';
import 'package:kaizen/ui/core/widgets/campo_validado.dart';
import 'package:kaizen/ui/hoy/widgets/pantalla_hoy.dart';
import 'package:kaizen/ui/logros/widgets/pantalla_logros.dart';
import 'package:kaizen/ui/logros/widgets/tarjeta_ultimo_logro.dart';

/// Flujo del Paso 11 en la app real: entrar → "Último logro" en Hoy → aceptar una subida de la Escalera →
/// "Insignia nueva: Primer micro-paso" → "Ver" abre Logros con 7 de 10 → su detalle.
/// `flutter test integration_test/logros_test.dart -d linux`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> tocar(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets('último logro, insignia nueva al aceptar un micro-paso y la sección Logros', (tester) async {
    final datos = DatosDemo(reloj: () => DateTime(2026, 11, 25, 9, 30));
    await tester.pumpWidget(
      KaizenApp(
        key: UniqueKey(),
        entorno: Entorno.desdeValores(fuente: 'fake', apiBaseUrl: apiProduccion, zonaHorariaDefecto: 'UTC'),
        dependencias: Dependencias.fake(datos: datos),
        mostrarHerramientasDev: false,
      ),
    );
    await tester.pumpAndSettle();

    // 1. Entrar como Daniela: Hoy muestra su último logro.
    final campos = find.descendant(of: find.byType(CampoValidado), matching: find.byType(TextField));
    await tester.enterText(campos.at(0), 'demo@kaizen.test');
    await tester.enterText(campos.at(1), DatosDemo.contrasenaDemo);
    await tocar(tester, find.text('Iniciar sesión'));
    for (var i = 0; i < 50 && find.byType(TarjetaUltimoLogro).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(PantallaHoy), findsOneWidget);
    final tarjeta = find.byType(TarjetaUltimoLogro);
    await tester.ensureVisible(tarjeta);
    expect(find.descendant(of: tarjeta, matching: find.text('Ritmo ideal')), findsOneWidget);

    // 2. Aceptar la subida de "Leer" (en escritorio, en la tarjeta "Micro-paso sugerido"): insignia nueva.
    await tocar(tester, find.text('Aceptar'));
    expect(find.text('Insignia nueva: Primer micro-paso'), findsOneWidget);

    // 3. "Ver" abre Logros: ahora 7 de 10, y el nuevo es el último.
    await tester.tap(find.text('Ver'));
    await tester.pumpAndSettle();
    expect(find.byType(PantallaLogros), findsOneWidget);
    expect(find.text('7 de 10 insignias'), findsOneWidget);

    // 4. Su detalle.
    await tocar(tester, find.byKey(const ValueKey('logro-primer_micro_paso')));
    expect(find.text('Cómo se obtiene'), findsOneWidget);
    expect(find.text('Con Leer'), findsOneWidget);
    await tocar(tester, find.text('Cerrar'));
  });
}
