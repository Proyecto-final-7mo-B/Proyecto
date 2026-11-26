import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/config/dependencias.dart';
import 'package:kaizen/data/fake/datos_demo.dart';
import 'package:kaizen/data/services/almacen_seguro.dart';
import 'package:kaizen/data/services/api/errores_api.dart';
import 'package:kaizen/data/services/gestor_tokens.dart';
import 'package:kaizen/data/services/servicio_sesion.dart';
import 'package:kaizen/domain/models/usuario.dart';
import 'package:kaizen/l10n/gen/app_localizations.dart';
import 'package:kaizen/domain/models/problema.dart';
import 'package:kaizen/routing/estado_sesion.dart';
import 'package:kaizen/ui/auth/view_models/entrar_viewmodel.dart';
import 'package:kaizen/ui/auth/view_models/recuperar_viewmodel.dart';
import 'package:kaizen/ui/auth/view_models/registro_viewmodel.dart';
import 'package:kaizen/ui/auth/view_models/restablecer_viewmodel.dart';
import 'package:kaizen/ui/core/mensajes.dart';
import 'package:kaizen/utils/paises_estados.dart';
import 'package:kaizen/utils/validadores.dart';
import 'package:flutter/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatosDemo datos;
  late AlmacenEnMemoria almacen;
  late Dependencias d;
  late EstadoSesion estado;
  late ServicioSesion servicio;
  late CatalogoRegiones catalogo;

  setUpAll(() async => catalogo = await CatalogoRegiones.cargar());

  setUp(() {
    datos = DatosDemo(catalogo: catalogo);
    almacen = AlmacenEnMemoria();
    d = Dependencias.fake(datos: datos, almacen: almacen, catalogo: catalogo);
    estado = EstadoSesion();
    servicio = ServicioSesion(auth: d.auth, tokens: d.tokens, estado: estado);
  });

  tearDown(() => servicio.cerrar());

  group('ServicioSesion', () {
    test('entrar: guarda los tokens y abre la sesión con nombre, rol y región', () async {
      final r = await servicio.entrar(email: 'admin@kaizen.test', contrasena: DatosDemo.contrasenaDemo);
      expect(r.esExito, isTrue);
      expect(estado.iniciada, isTrue);
      expect(estado.esAdmin, isTrue);
      expect(estado.usuario!.nombreRegion, 'MX Centro-Sur');
      expect(d.tokens.tokenAcceso, isNotNull);
      expect(await almacen.leer(GestorTokens.claveRenovacion), isNotNull);
    });

    test('entrar con error: no abre sesión ni guarda nada', () async {
      final r = await servicio.entrar(email: 'demo@kaizen.test', contrasena: 'mala');
      expect(r.errorONulo!.tipo, TipoError.credencialesInvalidas);
      expect(estado.iniciada, isFalse);
      expect(await almacen.leer(GestorTokens.claveRenovacion), isNull);
    });

    test('registrar deja la sesión abierta', () async {
      final vm = RegistroViewModel(servicio, catalogo)
        ..elegirPais('AR')
        ..cambiarAviso(acepta: true);
      final r = await servicio.registrar(
        vm.solicitud(nombre: 'Ana', email: 'ana@x.com', contrasena: 'una-contrasena-larga')!,
      );
      vm.dispose();
      expect(r.valorONulo!.region, 'LATAM');
      expect(estado.iniciada, isTrue);
    });

    test('salir: borra los tokens y cierra, aunque el servidor no responda', () async {
      await servicio.entrar(email: 'demo@kaizen.test', contrasena: DatosDemo.contrasenaDemo);
      datos.fallarSiguiente(const ErrorApp(TipoError.sinConexion));
      await servicio.salir();
      expect(estado.iniciada, isFalse);
      expect(await almacen.leer(GestorTokens.claveRenovacion), isNull);
      expect(d.tokens.tokenAcceso, isNull);
    });

    test('restaurar: sin nada guardado no abre sesión', () async {
      expect(await servicio.restaurar(), isFalse);
      expect(estado.iniciada, isFalse);
    });

    test('restaurar: con un token válido renueva y abre la sesión', () async {
      await servicio.entrar(email: 'demo@kaizen.test', contrasena: DatosDemo.contrasenaDemo);
      final anterior = await almacen.leer(GestorTokens.claveRenovacion);
      estado.cerrar(); // simula volver a abrir la app
      expect(await servicio.restaurar(), isTrue);
      expect(estado.usuario!.nombre, 'Daniela Demo');
      expect(await almacen.leer(GestorTokens.claveRenovacion), isNot(anterior), reason: 'se rotó');
    });

    test('restaurar: si el servidor rechaza el token, no abre sesión y borra lo guardado', () async {
      await servicio.entrar(email: 'demo@kaizen.test', contrasena: DatosDemo.contrasenaDemo);
      estado.cerrar();
      datos.renovacionesVigentes.clear(); // p. ej., se cambió la contraseña en otro equipo
      expect(await servicio.restaurar(), isFalse);
      expect(estado.iniciada, isFalse);
      expect(await almacen.leer(GestorTokens.claveRenovacion), isNull);
    });

    test('restaurar sin red: abre la sesión con el usuario guardado (modo sin conexión)', () async {
      await servicio.entrar(email: 'latam@kaizen.test', contrasena: DatosDemo.contrasenaDemo);
      estado.cerrar();
      datos.fallarSiguiente(const ErrorApp(TipoError.sinConexion));
      expect(await servicio.restaurar(), isTrue);
      expect(estado.usuario!.region, 'LATAM');
      expect(await almacen.leer(GestorTokens.claveRenovacion), isNotNull, reason: 'se conserva para después');
    });

    test('si una renovación dice "cuenta suspendida", la sesión se cierra sola', () async {
      await servicio.entrar(email: 'demo@kaizen.test', contrasena: DatosDemo.contrasenaDemo);
      datos.usuarios['u-demo']!.suspendido = true;
      expect(await d.tokens.renovar(), isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(estado.iniciada, isFalse);
    });
  });

  group('EntrarViewModel', () {
    test('éxito y cada error del login', () async {
      final vm = EntrarViewModel(servicio);
      await vm.entrar.ejecutar((email: 'nadie@x.com', contrasena: 'x'));
      expect(vm.entrar.error!.tipo, TipoError.credencialesInvalidas);
      await vm.entrar.ejecutar((email: 'suspendido@kaizen.test', contrasena: DatosDemo.contrasenaDemo));
      expect(vm.entrar.error!.tipo, TipoError.cuentaSuspendida);
      await vm.entrar.ejecutar((email: 'demo@kaizen.test', contrasena: DatosDemo.contrasenaDemo));
      expect(vm.entrar.completado, isTrue);
      expect(vm.entrar.resultado!.valorONulo!.nombre, 'Daniela Demo');
      vm.dispose();
    });
  });

  group('RegistroViewModel', () {
    test('México primero; el estado solo se pide en México; región calculada', () {
      final vm = RegistroViewModel(servicio, catalogo);
      expect(vm.paises.first.codigo, 'MX');
      expect(vm.paises.skip(1).map((p) => p.nombre).toList(), [...vm.paises.skip(1).map((p) => p.nombre)]..sort());
      expect(vm.estados.first.nombre, 'Aguascalientes');
      expect(vm.region, isNull);
      vm.elegirPais('MX');
      expect(vm.pideEstado, isTrue);
      expect(vm.region, isNull, reason: 'falta el estado');
      vm.elegirEstado('YUC');
      expect(vm.region, 'MX-CENTRO-SUR');
      vm.elegirPais('CL');
      expect(vm.pideEstado, isFalse);
      expect(vm.estado, isNull, reason: 'fuera de México se limpia el estado');
      expect(vm.region, 'LATAM');
      vm.dispose();
    });

    test('sin aviso no arma la solicitud y lo marca; el consentimiento es aparte y opcional', () {
      final vm = RegistroViewModel(servicio, catalogo)
        ..elegirPais('MX')
        ..elegirEstado('JAL');
      expect(vm.solicitud(nombre: 'Ana', email: 'a@x.com', contrasena: 'p' * 18), isNull);
      expect(vm.faltaAviso, isTrue);
      vm.cambiarAviso(acepta: true);
      expect(vm.faltaAviso, isFalse);
      final s = vm.solicitud(nombre: '  Ana ', email: ' A@X.com ', contrasena: 'p' * 18)!;
      expect(s.nombre, 'Ana');
      expect(s.email, 'a@x.com');
      expect(s.estado, 'JAL');
      expect(s.consienteSenales, isFalse);
      vm.cambiarConsentimiento(consiente: true);
      expect(vm.solicitud(nombre: 'Ana', email: 'a@x.com', contrasena: 'p' * 18)!.consienteSenales, isTrue);
      vm.dispose();
    });

    test('sin catálogo: México pide estado y no hay región calculada', () {
      final vm = RegistroViewModel(servicio, null)..elegirPais('MX');
      expect(vm.paises, isEmpty);
      expect(vm.pideEstado, isTrue);
      vm.dispose();
    });

    test('registrar: éxito y correo ya usado (mensaje genérico)', () async {
      final vm = RegistroViewModel(servicio, catalogo)
        ..elegirPais('MX')
        ..elegirEstado('AGU')
        ..cambiarAviso(acepta: true);
      await vm.registrar.ejecutar(vm.solicitud(nombre: 'Ana', email: 'demo@kaizen.test', contrasena: 'p' * 18)!);
      expect(vm.registrar.error!.tipo, TipoError.registroRechazado);
      await vm.registrar.ejecutar(vm.solicitud(nombre: 'Ana', email: 'ana@x.com', contrasena: 'p' * 18)!);
      expect(vm.registrar.completado, isTrue);
      expect(estado.usuario!.region, 'MX-NORTE');
      vm.dispose();
    });
  });

  group('Recuperar y restablecer', () {
    test('recuperar: mismo resultado exista o no la cuenta', () async {
      final vm = RecuperarViewModel(d.auth);
      await vm.enviar.ejecutar('nadie@x.com');
      expect(vm.enviar.completado, isTrue);
      await vm.enviar.ejecutar('demo@kaizen.test');
      expect(vm.enviar.completado, isTrue);
      vm.dispose();
    });

    test('restablecer: sin token no sirve; con token cambia la contraseña una sola vez', () async {
      expect(RestablecerViewModel(d.auth, null).tieneToken, isFalse);
      expect(RestablecerViewModel(d.auth, '').tieneToken, isFalse);
      await d.auth.recuperar('demo@kaizen.test');
      final vm = RestablecerViewModel(d.auth, datos.ultimoTokenRecuperacion);
      expect(vm.tieneToken, isTrue);
      await vm.guardar.ejecutar('nueva-contrasena-larga');
      expect(vm.guardar.completado, isTrue);
      await vm.guardar.ejecutar('nueva-contrasena-larga');
      expect(vm.guardar.error!.tipo, TipoError.enlaceInvalido);
      vm.dispose();
    });
  });

  group('Mensajes', () {
    final t = lookupAppLocalizations(const Locale('es'));

    test('cada TipoError y cada ErrorValidacion tiene texto', () {
      for (final tipo in TipoError.values) {
        expect(mensajeDeError(ErrorApp(tipo), t), isNotEmpty, reason: tipo.name);
      }
      for (final v in ErrorValidacion.values) {
        expect(mensajeValidacion(v, t), isNotEmpty, reason: v.name);
      }
      expect(mensajeDeError(const ErrorApp(TipoError.credencialesInvalidas), t), 'Correo o contraseña incorrectos.');
    });

    test('bloqueo con los minutos de Retry-After (redondeando hacia arriba)', () {
      String bloqueo(Duration? d) => mensajeDeError(ErrorApp(TipoError.cuentaBloqueada, reintentarEn: d), t);
      expect(bloqueo(const Duration(minutes: 15)), contains('15 minutos'));
      expect(bloqueo(const Duration(seconds: 61)), contains('2 minutos'));
      expect(bloqueo(const Duration(seconds: 5)), contains('1 minuto.'));
      expect(bloqueo(null), contains('15 minutos'));
    });

    test('500 con id de petición; cápsula sellada con el detalle del servidor', () {
      const interno = ErrorApp(
        TipoError.errorInterno,
        problema: Problema(type: 'x/error-interno', title: '', status: 500, idPeticion: '7f3c'),
      );
      expect(mensajeDeError(interno, t), 'Algo salió mal. Código: 7f3c');
      const sellada = ErrorApp(
        TipoError.capsulaSellada,
        problema: Problema(type: 'x/capsula-sellada', title: '', status: 409, detail: 'Racha 9 de 21'),
      );
      expect(mensajeDeError(sellada, t), 'Racha 9 de 21');
      expect(validadorDe(Validadores.correo, t)('malo'), 'Escribe un correo válido.');
      expect(validadorDe(Validadores.correo, t)('a@b.co'), isNull);
    });

    test('nombre de región y usuario desde el token', () {
      expect(nombreRegion('MX-NORTE'), 'MX Norte');
      expect(nombreRegion('OTRA'), 'OTRA');
      final u = UsuarioSesion.desdeToken(
        const UsuarioToken(id: '1', nombre: 'Lucía', rol: RolUsuario.usuario, region: 'LATAM'),
      );
      expect(u.nombreRegion, 'LATAM');
      expect(u.inicial, 'L');
    });
  });
}
