import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/app.dart';
import 'package:kaizen/config/dependencias.dart';
import 'package:kaizen/config/entorno.dart';
import 'package:kaizen/data/fake/datos_demo.dart';
import 'package:kaizen/ui/core/widgets/campo_validado.dart';
import 'package:kaizen/ui/core/widgets/logo_kaizen.dart';
import 'package:kaizen/routing/estado_sesion.dart';
import 'package:kaizen/routing/rutas.dart';
import 'package:kaizen/ui/core/adaptativo/plataforma.dart';

const UsuarioSesion usuarioPrueba = UsuarioSesion(nombre: 'Jael', rol: RolUsuario.usuario, region: 'MX-NORTE');
const UsuarioSesion adminPrueba = UsuarioSesion(nombre: 'Sofía', rol: RolUsuario.admin, region: 'MX-CENTRO-SUR');

/// "Ahora" en las pruebas de la app completa: miércoles 25-nov-2026, 9:30 (las imágenes golden no cambian con el día).
final DateTime ahoraPrueba = DateTime(2026, 11, 25, 9, 30);

/// Dependencias *fake* con el reloj fijo de [ahoraPrueba].
Dependencias dependenciasPrueba() => Dependencias.fake(datos: DatosDemo(reloj: () => ahoraPrueba));

final Entorno entornoPrueba = Entorno.desdeValores(
  fuente: 'fake',
  apiBaseUrl: apiProduccion,
  zonaHorariaDefecto: 'UTC',
);

/// Monta la app completa (router, *shell*, sesión) en una pantalla de [tamano].
Future<EstadoSesion> montarApp(
  WidgetTester tester, {
  Plataforma plataforma = Plataforma.movil,
  UsuarioSesion? usuario = usuarioPrueba,
  String ubicacion = Rutas.hoy,
  Size tamano = const Size(390, 844),
  bool dev = true,
  Dependencias? dependencias,
  String? cuentaDemo,
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final sesion = EstadoSesion(usuario);
  addTearDown(sesion.dispose);
  final deps = dependencias ?? dependenciasPrueba();
  if (usuario != null) {
    // Que el "servidor" en memoria también tenga la sesión abierta (Daniela, el admin u otra [cuentaDemo]).
    deps.datosDemo!.usuarioActual = cuentaDemo ?? (usuario.esAdmin ? 'u-admin' : 'u-demo');
  }
  await tester.pumpWidget(
    KaizenApp(
      key: UniqueKey(), // cada montaje empieza con su propio router
      entorno: entornoPrueba,
      plataforma: plataforma,
      sesion: sesion,
      ubicacionInicial: ubicacion,
      mostrarHerramientasDev: dev,
      dependencias: deps,
    ),
  );
  await tester.pumpAndSettle();
  // El logo es una imagen: se decodifica fuera del reloj de la prueba. Precargarlo hace que las goldens siempre lo
  // muestren.
  final contexto = tester.element(find.byType(MaterialApp));
  await tester.runAsync(() => precacheImage(const AssetImage(LogoKaizen.rutaImagen), contexto));
  await tester.pumpAndSettle();
  return sesion;
}

/// En la pantalla de entrada, escribe correo y contraseña y toca "Iniciar sesión".
Future<void> entrarCon(
  WidgetTester tester, {
  String correo = 'demo@kaizen.test',
  String contrasena = DatosDemo.contrasenaDemo,
}) async {
  final campos = find.descendant(of: find.byType(CampoValidado), matching: find.byType(TextField));
  await tester.enterText(campos.at(0), correo);
  await tester.enterText(campos.at(1), contrasena);
  await tester.ensureVisible(find.text('Iniciar sesión'));
  await tester.tap(find.text('Iniciar sesión'));
  await tester.pumpAndSettle();
}
