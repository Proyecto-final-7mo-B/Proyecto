import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/config/dependencias.dart';
import 'package:kaizen/data/fake/datos_demo.dart';
import 'package:kaizen/routing/rutas.dart';
import 'package:kaizen/ui/auth/widgets/dialogo_recuperar.dart';
import 'package:kaizen/ui/auth/widgets/pantalla_entrar.dart';
import 'package:kaizen/ui/core/widgets/campo_validado.dart';

import '../../helpers/app.dart';

void main() {
  late DatosDemo datos;
  late Dependencias deps;

  setUp(() {
    datos = DatosDemo();
    deps = Dependencias.fake(datos: datos);
  });

  Future<void> abrir(WidgetTester tester, String? token) => montarApp(
    tester,
    usuario: null,
    dependencias: deps,
    ubicacion: token == null ? Rutas.restablecer : '${Rutas.restablecer}?token=$token',
  );

  Finder campo(int i) => find.descendant(of: find.byType(CampoValidado), matching: find.byType(TextField)).at(i);

  Future<void> tocar(WidgetTester tester, String texto) async {
    await tester.ensureVisible(find.text(texto).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(texto).last);
    await tester.pumpAndSettle();
  }

  Future<String> pedirToken() async {
    await deps.auth.recuperar('demo@kaizen.test');
    return datos.ultimoTokenRecuperacion!;
  }

  testWidgets('sin token: enlace inválido, se puede pedir otro o ir a entrar', (tester) async {
    await abrir(tester, null);
    expect(find.text('El enlace no es válido o ya venció.'), findsOneWidget);
    await tocar(tester, 'Pedir otro enlace');
    expect(find.byType(DialogoRecuperar), findsOneWidget);
    await tocar(tester, 'Cancelar');
    await tocar(tester, 'Ir a entrar');
    expect(find.byType(PantallaEntrar), findsOneWidget);
  });

  testWidgets('con token: valida longitud y confirmación; el token nunca se muestra', (tester) async {
    final token = await pedirToken();
    await abrir(tester, token);
    expect(find.textContaining(token), findsNothing);
    await tester.enterText(campo(0), 'corta');
    await tester.enterText(campo(1), 'otra');
    await tocar(tester, 'Guardar contraseña');
    expect(find.text('Usa al menos 18 caracteres.'), findsOneWidget);
    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
  });

  testWidgets('éxito: cambia la contraseña, cierra sesiones y deja entrar con la nueva', (tester) async {
    final token = await pedirToken();
    await abrir(tester, token);
    await tester.enterText(campo(0), 'mi-nueva-contrasena');
    await tester.enterText(campo(1), 'mi-nueva-contrasena');
    await tocar(tester, 'Guardar contraseña');
    expect(find.text('Listo. Tu contraseña cambió y se cerraron todas tus sesiones.'), findsOneWidget);
    await tocar(tester, 'Ir a entrar');
    await entrarCon(tester, contrasena: 'mi-nueva-contrasena');
    expect(find.byType(PantallaEntrar), findsNothing);
  });

  testWidgets('enlace usado o vencido: lo dice y ofrece pedir otro', (tester) async {
    final token = await pedirToken();
    await deps.auth.restablecer(token: token, nueva: 'ya-se-uso-este-enlace');
    await abrir(tester, token);
    await tester.enterText(campo(0), 'mi-nueva-contrasena');
    await tester.enterText(campo(1), 'mi-nueva-contrasena');
    await tocar(tester, 'Guardar contraseña');
    expect(find.text('El enlace no es válido o ya venció.'), findsOneWidget);
    expect(find.text('Pedir otro enlace'), findsOneWidget);
  });

  testWidgets('error del servidor en la contraseña se muestra junto al campo', (tester) async {
    final token = await pedirToken();
    await abrir(tester, token);
    datos.fallarSiguiente(DatosDemo.validacion({'nueva': 'Está en la lista de contraseñas comunes'}));
    await tester.enterText(campo(0), 'contrasena1234567890');
    await tester.enterText(campo(1), 'contrasena1234567890');
    await tocar(tester, 'Guardar contraseña');
    expect(find.text('Está en la lista de contraseñas comunes'), findsOneWidget);
  });
}
