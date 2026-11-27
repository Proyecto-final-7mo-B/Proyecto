import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kaizen/app.dart';
import 'package:kaizen/config/dependencias.dart';
import 'package:kaizen/config/entorno.dart';
import 'package:kaizen/data/fake/datos_demo.dart';
import 'package:kaizen/data/sync/monitor_conexion.dart';
import 'package:kaizen/domain/models/registro.dart';
import 'package:kaizen/ui/core/widgets/banner_sin_conexion.dart';
import 'package:kaizen/ui/core/widgets/campo_validado.dart';
import 'package:kaizen/ui/core/widgets/fila_habito.dart';
import 'package:kaizen/ui/core/widgets/indicador_racha.dart';

/// Criterio del Paso 8: "en modo avión, el check-in se guarda; al reconectar llega **una sola vez**".
/// Entrar → sin red → marcar Leer dos veces seguidas y una tercera (queda marcado) → reconectar → el servidor tiene
/// un solo check-in de hoy (`origen: offline`) y la racha coincide con la del servidor.
/// `flutter test integration_test/sin_conexion_test.dart -d linux`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Finder fila(String nombre) => find.widgetWithText(FilaHabito, nombre);

  Future<void> tocar(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets('sin conexión → check-in → reconectar → llega una vez', (tester) async {
    final red = MonitorConexionManual();
    final datos = DatosDemo(reloj: () => DateTime(2026, 11, 25, 9, 30));
    final deps = Dependencias.fake(datos: datos, monitor: red);
    await tester.pumpWidget(
      KaizenApp(
        entorno: Entorno.desdeValores(fuente: 'fake', apiBaseUrl: apiProduccion, zonaHorariaDefecto: 'UTC'),
        dependencias: deps,
        mostrarHerramientasDev: false,
      ),
    );
    await tester.pumpAndSettle();

    final campos = find.descendant(of: find.byType(CampoValidado), matching: find.byType(TextField));
    await tester.enterText(campos.at(0), 'demo@kaizen.test');
    await tester.enterText(campos.at(1), DatosDemo.contrasenaDemo);
    await tocar(tester, find.text('Iniciar sesión'));
    expect(find.text('2 de 5'), findsOneWidget);
    final leer = datos.habitosDe('u-demo').firstWhere((h) => h.nombre == 'Leer').id;
    final total = datos.totalRegistros;
    final racha = tester.widget<IndicadorRacha>(
      find.descendant(of: fila('Leer'), matching: find.byType(IndicadorRacha)),
    );

    // 1. Modo avión: aparece el aviso.
    red.hayRed = false;
    await tester.pumpAndSettle();
    expect(find.byType(BannerSinConexion), findsOneWidget);

    // 2. Marcar, desmarcar y volver a marcar sin red: queda marcado, con un solo pendiente.
    final checkLeer = find.descendant(of: fila('Leer'), matching: find.byType(BotonCheck));
    await tocar(tester, checkLeer);
    await tocar(tester, checkLeer);
    await tocar(tester, checkLeer);
    expect(find.text('3 de 5'), findsOneWidget);
    expect(find.textContaining('1 registro por enviar'), findsOneWidget);
    expect(datos.totalRegistros, total, reason: 'el servidor aún no sabe nada');

    // 3. Vuelve la red: se envía solo, el aviso se va y llega una sola vez.
    red.hayRed = true;
    await tester.pumpAndSettle();
    expect(find.byType(BannerSinConexion), findsNothing);
    expect(datos.totalRegistros, total + 1);
    final enviado = datos.registros[leer]![DateTime.utc(2026, 11, 25)]!;
    expect(enviado.cumplido, isTrue);
    expect(enviado.origen, OrigenRegistro.offline);

    // 4. La racha que se ve es la del servidor.
    final rachaServidor = datos.racha(datos.habitos[leer]!).actual;
    expect(rachaServidor, racha.dias + 1);
    final ahora = tester.widget<IndicadorRacha>(
      find.descendant(of: fila('Leer'), matching: find.byType(IndicadorRacha)),
    );
    expect(ahora.dias, rachaServidor);
  });
}
