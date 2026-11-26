import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/config/dependencias.dart';
import 'package:kaizen/data/fake/datos_demo.dart';
import 'package:kaizen/data/services/api/errores_api.dart';
import 'package:kaizen/routing/rutas.dart';
import 'package:kaizen/ui/auth/widgets/dialogo_recuperar.dart';
import 'package:kaizen/ui/auth/widgets/panel_marca.dart';
import 'package:kaizen/ui/auth/widgets/pantalla_entrar.dart';
import 'package:kaizen/ui/core/adaptativo/plataforma.dart';
import 'package:kaizen/ui/core/adaptativo/shell_escritorio.dart';
import 'package:kaizen/ui/core/adaptativo/shell_movil.dart';
import 'package:kaizen/ui/core/widgets/campo_validado.dart';
import 'package:kaizen/utils/paises_estados.dart';

import '../../helpers/app.dart';

void main() {
  late CatalogoRegiones catalogo;
  late DatosDemo datos;
  late Dependencias deps;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    catalogo = await CatalogoRegiones.cargar();
  });

  setUp(() {
    datos = DatosDemo(catalogo: catalogo);
    deps = Dependencias.fake(datos: datos, catalogo: catalogo);
  });

  Future<void> abrir(
    WidgetTester tester, {
    Size tamano = const Size(390, 844),
    String ubicacion = Rutas.hoy,
    bool dev = true,
  }) => montarApp(tester, usuario: null, tamano: tamano, ubicacion: ubicacion, dependencias: deps, dev: dev);

  Finder campo(int i) => find.descendant(of: find.byType(CampoValidado), matching: find.byType(TextField)).at(i);

  Future<void> tocar(WidgetTester tester, String texto) async {
    await tester.ensureVisible(find.text(texto).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(texto).last);
    await tester.pumpAndSettle();
  }

  group('diseño (bosquejo 01)', () {
    testWidgets('teléfono: encabezado de marca y hoja con las pestañas', (tester) async {
      await abrir(tester);
      expect(find.byType(PanelMarca), findsOneWidget);
      expect(tester.widget<PanelMarca>(find.byType(PanelMarca)).compacto, isTrue);
      expect(find.text('Te damos la bienvenida'), findsNothing);
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('Crear cuenta'), findsOneWidget);
      expect(find.textContaining('región'), findsNothing, reason: 'al usuario no se le muestra la región');
      expect(tester.takeException(), isNull);
    });

    testWidgets('escritorio y web: dos paneles y título de bienvenida', (tester) async {
      await abrir(tester, tamano: const Size(1440, 900));
      expect(tester.widget<PanelMarca>(find.byType(PanelMarca)).compacto, isFalse);
      expect(find.text('Te damos la bienvenida'), findsOneWidget);
      expect(tester.getCenter(find.byType(PanelMarca)).dx, lessThan(720));
    });

    testWidgets('sin desbordes a 320 px y accesible (toques y contraste)', (tester) async {
      await abrir(tester, tamano: const Size(320, 640));
      expect(tester.takeException(), isNull);
      final manejador = tester.ensureSemantics();
      await abrir(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      manejador.dispose();
    });
  });

  group('entrar', () {
    testWidgets('valida antes de llamar a la API', (tester) async {
      await abrir(tester);
      await tocar(tester, 'Iniciar sesión');
      expect(find.text('Este campo es obligatorio.'), findsNWidgets(2));
      await tester.enterText(campo(0), 'correo-malo');
      await tester.pump();
      expect(find.text('Escribe un correo válido.'), findsOneWidget);
      expect(datos.usuarioActual, isNull);
    });

    testWidgets('credenciales incorrectas: mismo mensaje exista o no la cuenta', (tester) async {
      await abrir(tester);
      await entrarCon(tester, contrasena: 'incorrecta');
      expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
      await entrarCon(tester, correo: 'nadie@kaizen.test', contrasena: 'incorrecta');
      expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
      expect(find.byType(PantallaEntrar), findsOneWidget);
    });

    testWidgets('cuenta suspendida y cuenta bloqueada (con minutos)', (tester) async {
      await abrir(tester);
      await entrarCon(tester, correo: 'suspendido@kaizen.test');
      expect(find.text('Tu cuenta está suspendida. Contacta al administrador.'), findsOneWidget);
      for (var i = 0; i < 10; i++) {
        await deps.auth.entrar(email: 'demo@kaizen.test', contrasena: 'mala');
      }
      await entrarCon(tester);
      expect(find.textContaining('Intenta de nuevo en 15 minutos'), findsOneWidget);
    });

    testWidgets('sin red: lo dice y no entra', (tester) async {
      await abrir(tester);
      datos.fallarSiguiente(const ErrorApp(TipoError.sinConexion));
      await entrarCon(tester);
      expect(find.text('Sin conexión a internet.'), findsOneWidget);
    });

    testWidgets('éxito: llega a Hoy (móvil) y al riel con su nombre (escritorio)', (tester) async {
      await abrir(tester);
      await entrarCon(tester);
      expect(find.byType(ShellMovil), findsOneWidget);
      await abrir(tester, tamano: const Size(1280, 800));
      await entrarCon(tester, correo: 'admin@kaizen.test');
      expect(find.byType(ShellEscritorio), findsOneWidget);
      expect(find.text('Admin Kaizen'), findsOneWidget);
      expect(find.textContaining('Región'), findsNothing);
    });

    testWidgets('los atajos de cuentas de prueba llenan correo y contraseña (solo fake + depuración)', (tester) async {
      await abrir(tester);
      await tocar(tester, 'Lucía (LATAM)');
      expect(tester.widget<TextField>(campo(0)).controller!.text, 'latam@kaizen.test');
      await tocar(tester, 'Iniciar sesión');
      expect(find.byType(ShellMovil), findsOneWidget);
      await abrir(tester, dev: false);
      expect(find.text('Lucía (LATAM)'), findsNothing);
    });
  });

  group('¿Olvidaste tu contraseña?', () {
    testWidgets('mismo mensaje exista o no la cuenta; usa el correo ya escrito', (tester) async {
      await abrir(tester);
      await tester.enterText(campo(0), 'nadie@x.com');
      await tocar(tester, '¿Olvidaste tu contraseña?');
      expect(find.byType(DialogoRecuperar), findsOneWidget);
      final enDialogo = find.descendant(of: find.byType(DialogoRecuperar), matching: find.byType(TextField));
      expect(tester.widget<TextField>(enDialogo).controller!.text, 'nadie@x.com');
      await tocar(tester, 'Enviar enlace');
      const mensaje = 'Si el correo está registrado, te enviamos un enlace. Revisa también tu carpeta de spam.';
      expect(find.text(mensaje), findsOneWidget);
      await tocar(tester, 'Cerrar');
      expect(find.byType(DialogoRecuperar), findsNothing);

      await tocar(tester, '¿Olvidaste tu contraseña?');
      await tester.enterText(
        find.descendant(of: find.byType(DialogoRecuperar), matching: find.byType(TextField)),
        'demo@kaizen.test',
      );
      await tocar(tester, 'Enviar enlace');
      expect(find.text(mensaje), findsOneWidget);
      expect(datos.ultimoTokenRecuperacion, isNotNull);
    });

    testWidgets('valida el correo y muestra errores de red; Cancelar cierra', (tester) async {
      await abrir(tester);
      await tocar(tester, '¿Olvidaste tu contraseña?');
      await tocar(tester, 'Enviar enlace');
      expect(find.text('Este campo es obligatorio.'), findsOneWidget);
      await tester.enterText(
        find.descendant(of: find.byType(DialogoRecuperar), matching: find.byType(TextField)),
        'a@b.co',
      );
      datos.fallarSiguiente(const ErrorApp(TipoError.demasiadasPeticiones));
      await tocar(tester, 'Enviar enlace');
      expect(find.text('Demasiados intentos. Espera un momento.'), findsOneWidget);
      await tocar(tester, 'Cancelar');
      expect(find.byType(DialogoRecuperar), findsNothing);
    });
  });

  group('crear cuenta', () {
    Future<void> llenar(
      WidgetTester tester, {
      String correo = 'ana@correo.com',
      String contrasena = 'una-contrasena-larga',
    }) async {
      await tester.enterText(campo(0), 'Ana');
      await tester.enterText(campo(1), correo);
      await tester.enterText(campo(2), contrasena);
    }

    /// Selector 0 = país, 1 = estado.
    Future<void> elegir(WidgetTester tester, int selector, String opcion) async {
      final lista = find.byType(DropdownButtonFormField<String>).at(selector);
      await tester.ensureVisible(lista);
      await tester.pumpAndSettle();
      await tester.tap(lista);
      await tester.pumpAndSettle();
      await tester.tap(find.text(opcion).last);
      await tester.pumpAndSettle();
    }

    testWidgets('el estado solo se pide con México; la región nunca se muestra', (tester) async {
      await abrir(tester);
      await tocar(tester, 'Crear cuenta');
      expect(find.text('Estado'), findsNothing);
      await elegir(tester, 0, 'México');
      expect(find.text('Estado'), findsOneWidget);
      await elegir(tester, 1, 'Campeche'); // la lista solo construye las opciones visibles
      expect(find.textContaining('región'), findsNothing);
      await elegir(tester, 0, 'Chile');
      expect(find.text('Estado'), findsNothing);
    });

    testWidgets('sin aviso de privacidad no se puede crear; contraseña corta rechazada', (tester) async {
      await abrir(tester);
      await tocar(tester, 'Crear cuenta');
      await llenar(tester, contrasena: 'corta');
      await elegir(tester, 0, 'Chile');
      await tocar(tester, 'Crear cuenta');
      expect(find.text('Debes aceptar el aviso de privacidad para crear tu cuenta.'), findsOneWidget);
      expect(find.text('Usa al menos 18 caracteres.'), findsOneWidget);
      expect(datos.usuarios.values.any((u) => u.email == 'ana@correo.com'), isFalse);
    });

    testWidgets('el aviso se puede leer en un diálogo', (tester) async {
      await abrir(tester);
      await tocar(tester, 'Crear cuenta');
      await tocar(tester, 'Ver aviso de privacidad');
      expect(find.textContaining('derechos ARCO'), findsOneWidget);
      await tocar(tester, 'Cerrar');
    });

    testWidgets('éxito: crea la cuenta (consentimiento opcional) y entra a Hoy', (tester) async {
      await abrir(tester);
      await tocar(tester, 'Crear cuenta');
      await llenar(tester);
      await elegir(tester, 0, 'México');
      await elegir(tester, 1, 'Jalisco');
      await tocar(tester, 'Acepto el aviso de privacidad');
      await tocar(tester, 'Crear cuenta');
      expect(find.byType(ShellMovil), findsOneWidget);
      final nueva = datos.usuarios.values.firstWhere((u) => u.email == 'ana@correo.com');
      expect(nueva.region, 'MX-NORTE');
      expect(nueva.consentimientoSenales, isFalse);
    });

    testWidgets('correo ya registrado: mensaje genérico; errores del servidor junto al campo', (tester) async {
      await abrir(tester);
      await tocar(tester, 'Crear cuenta');
      await llenar(tester, correo: 'demo@kaizen.test');
      await elegir(tester, 0, 'Chile');
      await tocar(tester, 'Acepto el aviso de privacidad');
      await tocar(tester, 'Quiero registrar mi ánimo y energía para el Laboratorio (opcional)');
      await tocar(tester, 'Crear cuenta');
      expect(find.text('No fue posible completar el registro.'), findsOneWidget);

      datos.fallarSiguiente(DatosDemo.validacion({'contrasena': 'Está en la lista de contraseñas comunes'}));
      await tester.enterText(campo(1), 'otra@correo.com');
      await tocar(tester, 'Crear cuenta');
      expect(find.text('Está en la lista de contraseñas comunes'), findsOneWidget);
      expect(find.text('Revisa los datos marcados.'), findsOneWidget);
    });
  });

  testWidgets('con sesión abierta, /login lleva a Hoy', (tester) async {
    await montarApp(tester, ubicacion: Rutas.login, plataforma: Plataforma.movil);
    expect(find.byType(PantallaEntrar), findsNothing);
    expect(find.byType(ShellMovil), findsOneWidget);
  });
}
