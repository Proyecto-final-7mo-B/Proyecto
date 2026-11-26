import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kaizen/app.dart';
import 'package:kaizen/config/dependencias.dart';
import 'package:kaizen/config/entorno.dart';
import 'package:kaizen/data/fake/datos_demo.dart';
import 'package:kaizen/ui/core/widgets/campo_validado.dart';
import 'package:kaizen/ui/core/widgets/fila_habito.dart';
import 'package:kaizen/ui/core/widgets/indicador_racha.dart';
import 'package:kaizen/ui/hoy/widgets/pantalla_hoy.dart';

/// Flujo del Paso 6 en la app real: entrar → marcar un hábito → "3 de 5" y la racha sube → salir y volver a entrar
/// (el check-in quedó guardado) → desmarcarlo → la racha vuelve.
/// `flutter test integration_test/hoy_test.dart -d linux`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Finder fila(String nombre) => find.widgetWithText(FilaHabito, nombre);
  int racha(WidgetTester tester, String nombre) =>
      tester.widget<IndicadorRacha>(find.descendant(of: fila(nombre), matching: find.byType(IndicadorRacha))).dias;

  Future<void> tocar(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Future<void> montar(WidgetTester tester, Dependencias deps) async {
    await tester.pumpWidget(
      KaizenApp(
        key: UniqueKey(),
        entorno: Entorno.desdeValores(fuente: 'fake', apiBaseUrl: apiProduccion, zonaHorariaDefecto: 'UTC'),
        dependencias: deps,
        mostrarHerramientasDev: false,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> entrar(WidgetTester tester) async {
    final campos = find.descendant(of: find.byType(CampoValidado), matching: find.byType(TextField));
    await tester.enterText(campos.at(0), 'demo@kaizen.test');
    await tester.enterText(campos.at(1), DatosDemo.contrasenaDemo);
    await tocar(tester, find.text('Iniciar sesión'));
  }

  testWidgets('entrar, marcar un hábito y ver subir la racha', (tester) async {
    // Miércoles: Daniela tiene 5 hábitos programados y 2 cumplidos.
    final datos = DatosDemo(reloj: () => DateTime(2026, 11, 25, 9, 30));
    final deps = Dependencias.fake(datos: datos);
    await montar(tester, deps);

    // 1. Entrar como Daniela.
    await entrar(tester);
    expect(find.byType(PantallaHoy), findsOneWidget);
    expect(find.text('Miércoles 25 de noviembre'), findsOneWidget);
    expect(find.text('2 de 5'), findsOneWidget);

    // 2. Marcar "Leer": "3 de 5" y la racha sube en uno.
    final antes = racha(tester, 'Leer');
    await tocar(tester, find.descendant(of: fila('Leer'), matching: find.byType(BotonCheck)));
    expect(find.text('3 de 5'), findsOneWidget);
    expect(racha(tester, 'Leer'), antes + 1);

    // 3. El check-in quedó en el "servidor": abrir la app de nuevo (otra instalación, mismos datos) y entrar lo muestra.
    await montar(tester, Dependencias.fake(datos: datos));
    await entrar(tester);
    expect(find.text('3 de 5'), findsOneWidget);
    expect(tester.widget<FilaHabito>(fila('Leer')).cumplido, isTrue);
    expect(racha(tester, 'Leer'), antes + 1);

    // 4. Desmarcarlo: la racha vuelve a la de antes.
    await tocar(tester, find.descendant(of: fila('Leer'), matching: find.byType(BotonCheck)));
    expect(find.text('2 de 5'), findsOneWidget);
    expect(racha(tester, 'Leer'), antes);
  });
}
