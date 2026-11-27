import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kaizen/app.dart';
import 'package:kaizen/config/dependencias.dart';
import 'package:kaizen/config/entorno.dart';
import 'package:kaizen/data/fake/datos_demo.dart';
import 'package:kaizen/ui/core/widgets/campo_validado.dart';
import 'package:kaizen/ui/core/widgets/contador_meta.dart';
import 'package:kaizen/ui/core/widgets/fila_habito.dart';
import 'package:kaizen/ui/habitos/widgets/pantalla_detalle_habito.dart';
import 'package:kaizen/ui/habitos/widgets/pantalla_formulario_habito.dart';
import 'package:kaizen/ui/hoy/widgets/pantalla_hoy.dart';

/// Flujo del Paso 7 en la app real: entrar → crear un hábito desde Hoy con una meta excesiva y corregirla con
/// "Usar 1.25 h" ("2 de 6") → archivarlo desde su detalle ("2 de 5" otra vez) → crear otro con cápsula de 30 días →
/// se abre la pantalla de la cápsula.
/// `flutter test integration_test/habitos_test.dart -d linux`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Finder campo(String etiqueta) =>
      find.descendant(of: find.widgetWithText(CampoValidado, etiqueta), matching: find.byType(TextField));

  Future<void> tocar(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets('crear, archivar y crear con cápsula', (tester) async {
    // Miércoles: Daniela tiene 5 hábitos programados y 2 cumplidos.
    final deps = Dependencias.fake(datos: DatosDemo(reloj: () => DateTime(2026, 11, 25, 9, 30)));
    await tester.pumpWidget(
      KaizenApp(
        entorno: Entorno.desdeValores(fuente: 'fake', apiBaseUrl: apiProduccion, zonaHorariaDefecto: 'UTC'),
        dependencias: deps,
        mostrarHerramientasDev: false,
      ),
    );
    await tester.pumpAndSettle();

    // 1. Entrar como Daniela.
    final campos = find.descendant(of: find.byType(CampoValidado), matching: find.byType(TextField));
    await tester.enterText(campos.at(0), 'demo@kaizen.test');
    await tester.enterText(campos.at(1), DatosDemo.contrasenaDemo);
    await tocar(tester, find.text('Iniciar sesión'));
    expect(find.text('2 de 5'), findsOneWidget);

    // 2. Crear "Caminar" desde Hoy con 2 h diarias: la evidencia avisa y "Usar 1.25 h" la corrige. Al volver, Hoy
    //    ya lo cuenta.
    await tocar(tester, find.widgetWithText(FilledButton, 'Nuevo hábito'));
    // "Nuevo hábito" abre las recomendaciones (27-nov); el formulario es "Hábito personalizado".
    await tocar(tester, find.text('Hábito personalizado'));
    expect(find.byType(PantallaFormularioHabito), findsOneWidget);
    await tester.enterText(campo('Nombre'), 'Caminar');
    await tocar(tester, find.text('Ejercicio'));
    await tocar(tester, find.text('Aeróbico moderado'));
    await tocar(tester, find.text('h'));
    for (var i = 0; i < 6; i++) {
      await tocar(tester, find.descendant(of: find.byType(ContadorMeta), matching: find.byIcon(Icons.add)));
    }
    expect(find.text('Más de lo recomendado'), findsOneWidget);
    await tocar(tester, find.text('Usar 1.25 h'));
    await tocar(tester, find.text('Guardar hábito'));
    expect(find.byType(PantallaHoy), findsOneWidget);
    expect(find.text('2 de 6'), findsOneWidget);

    // 3. Abrirlo, editarlo y archivarlo: Hoy deja de contarlo.
    // "Caminar" también está en "Esta semana, por hábito": se toca su fila.
    await tocar(tester, find.widgetWithText(FilaHabito, 'Caminar'));
    expect(find.byType(PantallaDetalleHabito), findsOneWidget);
    await tocar(tester, find.text('Editar'));
    // El aviso de "hábito creado" puede tapar el botón de abajo en ventanas bajas: se quita antes de tocar.
    tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger).first).clearSnackBars();
    await tester.pumpAndSettle();
    await tocar(tester, find.text('Archivar hábito'));
    await tocar(tester, find.text('Archivar'));
    expect(find.text('Este hábito está archivado: no aparece en Hoy.'), findsOneWidget);
    await tocar(tester, find.text('Hoy').first);
    expect(find.text('2 de 5'), findsOneWidget);
    expect(find.text('Caminar'), findsNothing);

    expect(deps.datosDemo!.habitosDe('u-demo').firstWhere((h) => h.nombre == 'Caminar').meta, 1.25);

    // 4. Crear "Meditar" con cápsula de 30 días: se abre la pantalla de la cápsula de ese hábito.
    //    Hoy conserva su desplazamiento: se regresa arriba, donde está "Nuevo hábito".
    final hoy = find.descendant(of: find.byType(PantallaHoy), matching: find.byType(Scrollable)).first;
    tester.state<ScrollableState>(hoy).position.jumpTo(0);
    await tester.pumpAndSettle();
    await tocar(tester, find.widgetWithText(FilledButton, 'Nuevo hábito'));
    await tocar(tester, find.text('Hábito personalizado'));
    await tester.enterText(campo('Nombre'), 'Meditar');
    await tocar(tester, find.text('Bienestar'));
    await tocar(tester, find.text('Meditación'));
    await tocar(tester, find.text('30 días'));
    await tocar(tester, find.text('Guardar hábito'));
    final meditar = deps.datosDemo!.habitosDe('u-demo').firstWhere((h) => h.nombre == 'Meditar');
    expect(find.text('Nueva cápsula'), findsWidgets);
    expect(find.text(meditar.id), findsOneWidget);
  });
}
