import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/data/services/almacen_seguro.dart';
import 'package:kaizen/data/services/api/cliente_api.dart';
import 'package:kaizen/data/services/api/errores_api.dart';
import 'package:kaizen/data/services/api/interceptor_auth.dart';
import 'package:kaizen/data/services/api/interceptor_reintentos.dart';
import 'package:kaizen/data/services/api/interceptor_zona_horaria.dart';
import 'package:kaizen/data/services/gestor_tokens.dart';
import 'package:kaizen/domain/models/sesion.dart';
import 'package:kaizen/domain/models/usuario.dart';

import '../../helpers/adaptador_falso.dart';

Map<String, dynamic> tokensJson(String sufijo) => {
  'token_acceso': 'acceso-$sufijo',
  'token_renovacion': 'renovacion-$sufijo',
  'tipo': 'Bearer',
  'expira_en': 900,
  'usuario': {'id': 'u1', 'nombre': 'Daniela', 'rol': 'usuario', 'region': 'MX-NORTE'},
};

void main() {
  late AdaptadorFalso red;
  late GestorTokens tokens;
  late List<Duration> esperas;

  ClienteApi cliente({String zona = 'America/Mexico_City'}) => ClienteApi(
    baseUrl: 'https://api.prueba/api/v1',
    tokens: tokens,
    zonaHoraria: ProveedorZonaHoraria(respaldo: 'America/Mexico_City', leerDelSistema: () async => zona),
    adaptador: red,
    esperar: (d) async => esperas.add(d),
    azar: Random(1),
  );

  setUp(() {
    red = AdaptadorFalso((_) => const RespuestaFalsa(200, {'ok': true}));
    tokens = GestorTokens(AlmacenEnMemoria());
    esperas = [];
  });

  group('cabeceras', () {
    test('X-Zona-Horaria en todas las peticiones (también /auth)', () async {
      final api = cliente(zona: 'America/Bogota');
      await api.get('/categorias', (d) => d);
      await api.post('/auth/login', (d) => d, datos: {'email': 'x'});
      expect(red.peticiones.map((p) => p.headers[InterceptorZonaHoraria.cabecera]), [
        'America/Bogota',
        'America/Bogota',
      ]);
    });

    test('una zona que no es IANA se cambia por la de respaldo; si el sistema falla también', () async {
      expect(await ProveedorZonaHoraria(respaldo: 'UTC', leerDelSistema: () async => 'GMT-6').obtener(), 'UTC');
      expect(
        await ProveedorZonaHoraria(respaldo: 'UTC', leerDelSistema: () async => throw Exception()).obtener(),
        'UTC',
      );
      expect(
        await ProveedorZonaHoraria(
          respaldo: 'UTC',
          leerDelSistema: () async => 'America/Argentina/Buenos_Aires',
        ).obtener(),
        'America/Argentina/Buenos_Aires',
      );
      var lecturas = 0;
      final p = ProveedorZonaHoraria(
        respaldo: 'UTC',
        leerDelSistema: () async {
          lecturas++;
          return 'UTC';
        },
      );
      await p.obtener();
      await p.obtener();
      expect(lecturas, 1, reason: 'se lee una sola vez');
    });

    test('Bearer en las rutas protegidas y en /auth/salir, nunca en el resto de /auth', () async {
      await tokens.guardar(Tokens.fromJson(tokensJson('1')));
      final api = cliente();
      await api.get('/habitos', (d) => d);
      await api.post('/auth/login', (d) => d);
      await api.post('/auth/salir', (d) => d);
      expect(red.peticiones[0].headers['Authorization'], 'Bearer acceso-1');
      expect(red.peticiones[1].headers.containsKey('Authorization'), isFalse);
      expect(red.peticiones[2].headers['Authorization'], 'Bearer acceso-1');
      expect(InterceptorAuth.llevaToken('/auth/renovar'), isFalse);
      expect(InterceptorAuth.puedeRenovar('/auth/salir'), isFalse);
    });
  });

  group('renovación ante 401', () {
    test('renueva una vez y repite la petición con el token nuevo', () async {
      await tokens.guardar(Tokens.fromJson(tokensJson('viejo')));
      red.responder = (p) {
        if (p.path == '/auth/renovar') {
          return RespuestaFalsa(200, tokensJson('nuevo'));
        }
        return p.headers['Authorization'] == 'Bearer acceso-nuevo'
            ? const RespuestaFalsa(200, [])
            : RespuestaFalsa.problema(401, 'token-invalido');
      };
      final r = await cliente().get('/habitos', (d) => d);
      expect(r.esExito, isTrue);
      expect(red.rutas, ['GET /habitos', 'POST /auth/renovar', 'GET /habitos']);
      expect(red.peticiones[1].data, {'token_renovacion': 'renovacion-viejo'});
      expect(red.peticiones[1].headers.containsKey('Authorization'), isFalse);
      expect(tokens.tokenAcceso, 'acceso-nuevo');
      expect(await tokens.tokenRenovacion(), 'renovacion-nuevo');
    });

    test('dos 401 a la vez → UNA sola renovación (candado)', () async {
      await tokens.guardar(Tokens.fromJson(tokensJson('viejo')));
      final liberar = Completer<void>();
      red.responder = (p) async {
        if (p.path == '/auth/renovar') {
          await liberar.future;
          return RespuestaFalsa(200, tokensJson('nuevo'));
        }
        return p.headers['Authorization'] == 'Bearer acceso-nuevo'
            ? const RespuestaFalsa(200, [])
            : RespuestaFalsa.problema(401, 'token-invalido');
      };
      final api = cliente();
      final a = api.get('/habitos', (d) => d);
      final b = api.get('/categorias', (d) => d);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      liberar.complete();
      final resultados = await Future.wait([a, b]);
      expect(resultados.every((r) => r.esExito), isTrue);
      expect(red.rutas.where((r) => r == 'POST /auth/renovar'), hasLength(1));
    });

    test('si la renovación es rechazada: borra los tokens, avisa y devuelve el 401', () async {
      await tokens.guardar(Tokens.fromJson(tokensJson('viejo')));
      var avisos = 0;
      final sub = tokens.sesionExpirada.listen((_) => avisos++);
      red.responder = (p) => p.path == '/auth/renovar'
          ? RespuestaFalsa.problema(401, 'token-reutilizado')
          : RespuestaFalsa.problema(401, 'token-invalido');
      final r = await cliente().get('/habitos', (d) => d);
      await Future<void>.delayed(Duration.zero);
      expect(r.errorONulo!.tipo, TipoError.tokenInvalido);
      expect(r.errorONulo!.cierraSesion, isTrue);
      expect(await tokens.tokenRenovacion(), isNull);
      expect(tokens.tokenAcceso, isNull);
      expect(avisos, 1);
      await sub.cancel();
    });

    test('si la renovación falla por red: conserva los tokens (se intentará después)', () async {
      await tokens.guardar(Tokens.fromJson(tokensJson('viejo')));
      red.responder = (p) =>
          p.path == '/auth/renovar' ? const RespuestaFalsa.sinRed() : RespuestaFalsa.problema(401, 'token-invalido');
      await cliente().get('/cuenta', (d) => d);
      expect(await tokens.tokenRenovacion(), 'renovacion-viejo');
    });

    test('no renueva en /auth/* ni dos veces la misma petición', () async {
      await tokens.guardar(Tokens.fromJson(tokensJson('viejo')));
      red.responder = (p) => p.path == '/auth/renovar'
          ? RespuestaFalsa(200, tokensJson('nuevo'))
          : RespuestaFalsa.problema(401, 'credenciales-invalidas');
      final login = await cliente().post('/auth/login', (d) => d);
      expect(login.errorONulo!.tipo, TipoError.credencialesInvalidas);
      expect(red.rutas, ['POST /auth/login']);
      red.peticiones.clear();
      await cliente().get('/habitos', (d) => d);
      expect(red.rutas, ['GET /habitos', 'POST /auth/renovar', 'GET /habitos'], reason: 'el segundo 401 no renueva');
    });

    test('sin token de renovación no llama a /auth/renovar', () async {
      red.responder = (_) => RespuestaFalsa.problema(401, 'token-invalido');
      await cliente().get('/habitos', (d) => d);
      expect(red.rutas, ['GET /habitos']);
    });
  });

  group('reintentos (solo lecturas y check-ins)', () {
    test('GET con 503 se reintenta 3 veces con 0.2/0.4/0.8 s ± 20 %', () async {
      red.responder = (_) => RespuestaFalsa.problema(503, 'primario-no-disponible');
      final r = await cliente().get('/habitos', (d) => d);
      expect(r.errorONulo!.tipo, TipoError.primarioNoDisponible);
      expect(red.peticiones, hasLength(4));
      expect(esperas, hasLength(3));
      for (final (i, base) in [200, 400, 800].indexed) {
        expect(esperas[i].inMilliseconds, inInclusiveRange(base * 0.8, base * 1.2));
      }
    });

    test('se recupera si el primario vuelve a la segunda', () async {
      var n = 0;
      red.responder = (_) =>
          ++n < 2 ? RespuestaFalsa.problema(503, 'primario-no-disponible') : const RespuestaFalsa(200, []);
      expect((await cliente().get('/habitos', (d) => d)).esExito, isTrue);
      expect(n, 2);
    });

    test('check-in sin red se reintenta (es idempotente por su id)', () async {
      red.responder = (_) => const RespuestaFalsa.sinRed();
      final r = await cliente().post('/registros', (d) => d, datos: {'id': 'x'});
      expect(r.errorONulo!.tipo, TipoError.sinConexion);
      expect(r.errorONulo!.esDeRed, isTrue);
      expect(red.peticiones, hasLength(4));
    });

    test('nunca reintenta login, registro, crear hábito ni admin', () async {
      red.responder = (_) => RespuestaFalsa.problema(503, 'servicio-no-disponible');
      final api = cliente();
      await api.post('/auth/login', (d) => d);
      await api.post('/auth/registro', (d) => d);
      await api.post('/habitos', (d) => d);
      await api.patch('/admin/usuarios/1', (d) => d);
      expect(red.peticiones, hasLength(4));
      expect(esperas, isEmpty);
    });

    test('no reintenta analitica-no-disponible ni errores 4xx', () async {
      red.responder = (_) => RespuestaFalsa.problema(503, 'analitica-no-disponible');
      final r = await cliente().get('/laboratorio/perspectivas', (d) => d);
      expect(r.errorONulo!.tipo, TipoError.analiticaNoDisponible);
      expect(red.peticiones, hasLength(1));
      red
        ..peticiones.clear()
        ..responder = (_) => RespuestaFalsa.problema(404, 'no-encontrado');
      await cliente().get('/habitos/x', (d) => d);
      expect(red.peticiones, hasLength(1));
    });

    test('esIdempotente', () {
      RequestOptions o(String m, String p) => RequestOptions(method: m, path: p);
      expect(InterceptorReintentos.esIdempotente(o('GET', '/x')), isTrue);
      expect(InterceptorReintentos.esIdempotente(o('POST', '/registros/lote')), isTrue);
      expect(InterceptorReintentos.esIdempotente(o('POST', '/senales')), isFalse);
      expect(InterceptorReintentos.esIdempotente(o('DELETE', '/cuenta')), isFalse);
    });
  });

  group('errores', () {
    test('problem+json → tipo, campos y Retry-After', () async {
      red.responder = (_) => RespuestaFalsa.problema(429, 'cuenta-bloqueada', cabeceras: {'Retry-After': '900'});
      final r = await cliente().post('/auth/login', (d) => d);
      expect(r.errorONulo!.tipo, TipoError.cuentaBloqueada);
      expect(r.errorONulo!.reintentarEn, const Duration(minutes: 15));
      expect(r.errorONulo!.status, 429);

      red.responder = (_) => RespuestaFalsa.problema(
        422,
        'validacion',
        extras: {
          'errores': [
            {'campo': 'contrasena', 'detalle': 'Muy corta'},
          ],
        },
      );
      final v = await cliente().post('/auth/registro', (d) => d);
      expect(v.errorONulo!.errorDe('contrasena'), 'Muy corta');
      expect(v.errorONulo!.errorDe('email'), isNull);
    });

    test('cada type del contrato tiene su TipoError', () {
      const sufijos = [
        'validacion', 'region-invalida', 'fecha-fuera-de-rango', 'categoria-inactiva', 'enlace-invalido', //
        'credenciales-invalidas', 'token-invalido', 'token-reutilizado', 'consentimiento-requerido',
        'rol-insuficiente', 'cuenta-suspendida', 'no-encontrado', 'registro-rechazado', 'capsula-sellada',
        'sugerencia-resuelta', 'operacion-no-permitida', 'habito-archivado', 'nombre-duplicado',
        'cuenta-bloqueada', 'demasiadas-peticiones', 'primario-no-disponible', 'analitica-no-disponible',
        'servicio-no-disponible', 'error-interno',
      ];
      for (final s in sufijos) {
        final tipo = TipoError.desdeSufijo(s);
        expect(tipo, isNot(TipoError.desconocido), reason: s);
        expect(tipo.sufijo, s);
      }
      expect(TipoError.desdeSufijo('otro'), TipoError.desconocido);
      expect(TipoError.sinConexion.sufijo, isNull);
    });

    test('sin cuerpo problem+json se decide por el código HTTP', () async {
      for (final (status, tipo) in [
        (401, TipoError.tokenInvalido),
        (403, TipoError.rolInsuficiente),
        (404, TipoError.noEncontrado),
        (429, TipoError.demasiadasPeticiones),
        (502, TipoError.servicioNoDisponible),
        (500, TipoError.errorInterno),
        (418, TipoError.desconocido),
      ]) {
        red.responder = (_) => RespuestaFalsa(status, 'texto');
        expect((await cliente().post('/x', (d) => d)).errorONulo!.tipo, tipo, reason: '$status');
      }
    });

    test('tiempos agotados y respuestas con otra forma', () {
      final o = RequestOptions(path: '/x');
      expect(
        ErrorApp.desdeDio(DioException.connectionTimeout(requestOptions: o, timeout: Duration.zero)).tipo,
        TipoError.tiempoAgotado,
      );
      expect(
        ErrorApp.desdeDio(DioException.receiveTimeout(requestOptions: o, timeout: Duration.zero)).tipo,
        TipoError.tiempoAgotado,
      );
      expect(
        ErrorApp.desdeDio(DioException.requestCancelled(requestOptions: o, reason: null)).tipo,
        TipoError.desconocido,
      );
      const interno = ErrorApp(TipoError.capsulaSellada);
      expect(ErrorApp.desdeDio(DioException(requestOptions: o, error: interno)), same(interno));
      expect(interno.toString(), 'ErrorApp(capsulaSellada)');
    });

    test('una respuesta que no es del contrato no truena: Fallo desconocido', () async {
      red.responder = (_) => const RespuestaFalsa(200, {'otra': 'forma'});
      final r = await cliente().get('/cuenta', (d) => Tokens.fromJson(d as Map<String, dynamic>));
      expect(r.errorONulo!.tipo, TipoError.desconocido);
      red.responder = (_) => const RespuestaFalsa(200, [1]);
      final t = await cliente().get('/x', (d) => (d as Map<String, dynamic>)['a'] as String);
      expect(t.errorONulo!.tipo, TipoError.desconocido);
      final f = await cliente().get('/x', (_) => throw const FormatException('x'));
      expect(f.errorONulo!.tipo, TipoError.desconocido);
    });
  });

  group('GestorTokens', () {
    test('guarda el de renovación y el usuario en el almacén; el de acceso solo en memoria', () async {
      final almacen = AlmacenEnMemoria();
      final g = GestorTokens(almacen);
      await g.guardar(Tokens.fromJson(tokensJson('1')));
      expect(await almacen.leer(GestorTokens.claveRenovacion), 'renovacion-1');
      expect(await almacen.leer('kaizen.token_acceso'), isNull);
      expect((await g.usuarioGuardado())!.rol, RolUsuario.usuario);
      await g.borrar();
      expect(await g.usuarioGuardado(), isNull);
      await almacen.escribir(GestorTokens.claveUsuario, 'no es json');
      expect(await g.usuarioGuardado(), isNull);
      await g.cerrar();
    });

    test('renovar sin renovador configurado devuelve false', () async {
      final g = GestorTokens(AlmacenEnMemoria());
      await g.guardar(Tokens.fromJson(tokensJson('1')));
      expect(await g.renovar(), isFalse);
    });
  });
}
