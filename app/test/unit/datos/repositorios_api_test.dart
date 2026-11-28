import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/data/repositories/admin/admin_repository_api.dart';
import 'package:kaizen/data/repositories/auth/auth_repository_api.dart';
import 'package:kaizen/data/repositories/capsulas/capsulas_repository_api.dart';
import 'package:kaizen/data/repositories/categorias/categorias_repository_api.dart';
import 'package:kaizen/data/repositories/cuenta/cuenta_repository_api.dart';
import 'package:kaizen/data/repositories/escalera/escalera_repository_api.dart';
import 'package:kaizen/data/repositories/habitos/habitos_repository_api.dart';
import 'package:kaizen/data/repositories/laboratorio/laboratorio_repository_api.dart';
import 'package:kaizen/data/repositories/logros/logros_repository_api.dart';
import 'package:kaizen/data/repositories/progreso/progreso_repository_api.dart';
import 'package:kaizen/data/repositories/registros/registros_repository_api.dart';
import 'package:kaizen/data/repositories/senales/senales_repository_api.dart';
import 'package:kaizen/data/services/almacen_seguro.dart';
import 'package:kaizen/data/services/api/cliente_api.dart';
import 'package:kaizen/data/services/api/interceptor_zona_horaria.dart';
import 'package:kaizen/data/services/gestor_tokens.dart';
import 'package:kaizen/domain/models/admin.dart';
import 'package:kaizen/domain/models/capsula.dart';
import 'package:kaizen/domain/models/evidencia.dart';
import 'package:kaizen/domain/models/frecuencia.dart';
import 'package:kaizen/domain/models/habito.dart';
import 'package:kaizen/domain/models/laboratorio.dart';
import 'package:kaizen/domain/models/progreso.dart';
import 'package:kaizen/domain/models/registro.dart';
import 'package:kaizen/domain/models/sesion.dart';
import 'package:kaizen/domain/models/usuario.dart';

import '../../helpers/adaptador_falso.dart';

/// Cada repositorio `_api` llama a la ruta del contrato, con sus parámetros y su cuerpo, y lee la respuesta.
void main() {
  late AdaptadorFalso red;
  late ClienteApi api;
  final hoy = DateTime.utc(2026, 11, 23);

  const habito = {
    'id': 'h 1',
    'nombre': 'Leer',
    'unidad': 'min',
    'meta': 10,
    'nivel': 3,
    'categoria': {'id': 'c1', 'clave': 'educacion', 'nombre': 'Educación', 'color': '#2563EB', 'icono': 'school'},
    'subcategoria': {'id': 's1', 'clave': 'lectura', 'nombre': 'Lectura', 'icono': 'menu_book', 'sentido': 'aumentar'},
    'prioridad': 2,
    'intencion': null,
    'frecuencia': {'tipo': 'diaria', 'dias_semana': null, 'veces_semana': null},
    'escalera_activa': true,
    'activo': true,
    'fecha_creacion': '2026-09-01T14:00:00Z',
    'racha': {'actual': 5, 'maxima': 12, 'ultima_fecha': '2026-11-22'},
    'hoy': null,
  };
  const tokens = {
    'token_acceso': 'a',
    'token_renovacion': 'r',
    'tipo': 'Bearer',
    'expira_en': 900,
    'usuario': {'id': 'u1', 'nombre': 'Daniela', 'rol': 'usuario', 'region': 'MX-NORTE'},
  };
  const capsula = {
    'id': 'c1',
    'habito_id': 'h1',
    'habito_nombre': 'Agua',
    'racha_objetivo': 21,
    'progreso': 9,
    'se_puede_abrir': false,
    'estado': 'sellada',
    'tiene_foto': false,
    'creada_en': '2026-11-01T10:00:00Z',
    'abierta_en': null,
  };

  void responde(Object? cuerpo, [int status = 200]) => red.responder = (_) => RespuestaFalsa(status, cuerpo);
  RequestOptions ultima() => red.peticiones.last;

  setUp(() {
    red = AdaptadorFalso((_) => const RespuestaFalsa(204));
    api = ClienteApi(
      baseUrl: 'https://api.prueba/api/v1',
      tokens: GestorTokens(AlmacenEnMemoria()),
      zonaHoraria: ProveedorZonaHoraria(respaldo: 'UTC', leerDelSistema: () async => 'UTC'),
      adaptador: red,
      esperar: (_) async {},
    );
  });

  test('auth: login (correo normalizado), registro, renovar, salir, recuperar, restablecer', () async {
    final auth = AuthRepositoryApi(api);
    responde(tokens);
    final r = await auth.entrar(email: '  Dani@Correo.COM ', contrasena: 'x');
    expect(r.valorONulo!.usuario.nombre, 'Daniela');
    expect(red.rutas.last, 'POST /auth/login');
    expect(ultima().data, {'email': 'dani@correo.com', 'contrasena': 'x'});

    await auth.registrar(
      const SolicitudRegistro(
        nombre: 'D',
        email: 'd@x.com',
        contrasena: 'p',
        pais: 'MX',
        estado: 'JAL',
        aceptaAviso: true,
        consienteSenales: false,
      ),
    );
    expect(red.rutas.last, 'POST /auth/registro');
    expect((ultima().data as Map)['estado'], 'JAL');

    await auth.renovar('r');
    expect(red.rutas.last, 'POST /auth/renovar');

    responde(null, 204);
    expect((await auth.salir('r')).esExito, isTrue);
    expect(ultima().data, {'token_renovacion': 'r'});
    responde({'detalle': 'Si el correo está registrado, te enviamos un enlace.'}, 202);
    expect((await auth.recuperar(' D@X.com')).esExito, isTrue);
    expect(ultima().data, {'email': 'd@x.com'});
    responde(null, 204);
    await auth.restablecer(token: 't', nueva: 'n');
    expect(red.rutas.last, 'POST /auth/restablecer');
    expect(ultima().data, {'token': 't', 'nueva': 'n'});
  });

  test('categorías', () async {
    responde([
      {
        'id': 'c1',
        'clave': 'educacion',
        'nombre': 'Educación',
        'color': '#2563EB',
        'icono': 'school',
        'subcategorias': [
          {
            'id': 's1',
            'clave': 'idiomas',
            'nombre': 'Idiomas',
            'icono': 'translate',
            'sentido': 'aumentar',
            'unidades': [
              {'unidad': 'min', 'factor_a_base': 1, 'paso': 5, 'minimo': 1, 'maximo': 1440},
            ],
            'referencia': null,
          },
        ],
      },
    ]);
    final r = await CategoriasRepositoryApi(api).listar();
    expect(r.valorONulo!.single.nombre, 'Educación');
    expect(r.valorONulo!.single.subcategorias.single.unidades.single.paso, 5);
    expect(red.rutas.single, 'GET /categorias');
  });

  test('hábitos: ?fecha= local, id codificado, PATCH sin meta ni frecuencia, registros y escalera', () async {
    final repo = HabitosRepositoryApi(api);
    responde([habito]);
    expect((await repo.listar(fecha: hoy)).valorONulo, hasLength(1));
    expect(ultima().queryParameters, {'fecha': '2026-11-23', 'archivados': 'false'});

    responde(habito);
    await repo.obtener('h 1', fecha: hoy);
    expect(ultima().path, '/habitos/h%201');
    await repo.crear(
      const NuevoHabito(nombre: 'Leer', subcategoriaId: 's1', frecuencia: Diaria(), meta: 10, unidad: 'min'),
    );
    expect(red.rutas.last, 'POST /habitos');
    expect((ultima().data as Map)['subcategoria_id'], 's1');
    await repo.actualizar('h 1', const CambiosHabito(activo: false));
    expect(red.rutas.last, 'PATCH /habitos/h%201');
    expect(ultima().data, {'activo': false});

    responde([
      {
        'id': 'r1',
        'habito_id': 'h1',
        'fecha': '2026-11-23',
        'cumplido': true,
        'valor': null,
        'origen': 'manual',
        'registrado_en': null,
      },
    ]);
    final regs = await repo.registros('h1', desde: hoy.subtract(const Duration(days: 30)), hasta: hoy);
    expect(regs.valorONulo!.single.cumplido, isTrue);
    expect(ultima().path, '/habitos/h1/registros');
    expect(ultima().queryParameters, {'desde': '2026-10-24', 'hasta': '2026-11-23'});

    responde({
      'habito_id': 'h1',
      'escalera_activa': false,
      'nivel_actual': 1,
      'meta_actual': 5,
      'unidad': 'min',
      'niveles': <Object>[],
      'sugerencia_pendiente': null,
      'historial': <Object>[],
    });
    expect((await repo.escalera('h1')).valorONulo!.escaleraActiva, isFalse);
    expect(ultima().path, '/habitos/h1/escalera');
  });

  test('hábitos (v1.7): recomendados, crear desde una recomendación y días protegidos', () async {
    final repo = HabitosRepositoryApi(api);
    responde([
      {
        'id': 'r1',
        'clave': 'caminar_rapido',
        'nombre': 'Caminar a paso rápido',
        'categoria': {'id': 'c1', 'clave': 'ejercicio', 'nombre': 'Ejercicio', 'color': '#D9480F', 'icono': 'fitness_center'},
        'subcategoria': {
          'id': 's1',
          'clave': 'aerobico_moderado',
          'nombre': 'Aeróbico moderado',
          'icono': 'directions_walk',
          'sentido': 'aumentar',
        },
        'unidad': 'min',
        'meta': 30,
        'frecuencia': {'tipo': 'dias_semana', 'dias_semana': 31, 'veces_semana': null},
        'momento': 'Después de comer',
        'porque': 'La OMS recomienda de 150 a 300 minutos…',
        'fuentes': 'F11',
        'zona': 'optimo',
        'optimo_desde': 30,
        'optimo_hasta': 60,
      },
    ]);
    final recs = (await repo.recomendados()).valorONulo!;
    expect(red.rutas.last, 'GET /habitos/recomendados');
    expect(recs.single.frecuencia, const DiasSemana(31));
    expect(recs.single.zona, ZonaEvidencia.optimo);
    expect((recs.single.optimoDesde, recs.single.optimoHasta), (30.0, 60.0));

    responde({...habito, 'recomendacion_id': 'r1'});
    final creado = (await repo.crearRecomendado('r1', prioridad: Prioridad.alta)).valorONulo!;
    expect(red.rutas.last, 'POST /habitos');
    expect(ultima().data, {'recomendacion_id': 'r1', 'prioridad': 1}, reason: 'la base copia lo demás');
    expect(creado.recomendacionId, 'r1');

    responde({
      'fechas': ['2026-11-16', '2026-11-23'],
    });
    final dias = (await repo.diasProtegidos('h 1', desde: hoy.subtract(const Duration(days: 30)), hasta: hoy)).valorONulo!;
    expect(ultima().path, '/habitos/h%201/protegidos');
    expect(ultima().queryParameters, {'desde': '2026-10-24', 'hasta': '2026-11-23'});
    expect(dias, {DateTime.utc(2026, 11, 16), DateTime.utc(2026, 11, 23)});
  });

  test('fuentes (v1.7)', () async {
    responde([
      {
        'clave': 'F01',
        'tema': 'formacion',
        'referencia': 'Lally et al. (2010)…',
        'enlace': '10.1002/ejsp.674',
        'dato': '18 a 254 días',
        'verificada': 'Sí',
        'confianza': 'Media',
      },
    ]);
    final f = (await CategoriasRepositoryApi(api).fuentes()).valorONulo!;
    expect(red.rutas.last, 'GET /fuentes');
    expect(f.single.clave, 'F01');
  });

  test('logros (§6.13)', () async {
    responde([
      {
        'clave': 'racha_7',
        'nombre': 'Primera semana',
        'descripcion': 'Llega a 7 días seguidos en un hábito',
        'icono': 'local_fire_department',
        'tipo': 'racha',
        'objetivo': 7,
        'progreso': 7,
        'obtenido': true,
        'obtenido_en': '2026-11-20T12:00:00Z',
        'habito': {'id': 'h1', 'nombre': 'Leer'},
        'porque': 'El día 7 es el primer hito con datos de retención',
        'fuentes': 'F47',
      },
    ]);
    final l = (await LogrosRepositoryApi(api).listar()).valorONulo!;
    expect(red.rutas.last, 'GET /logros');
    expect((l.single.clave, l.single.obtenido, l.single.habitoNombre), ('racha_7', true, 'Leer'));
  });

  test('registros: check-in y lote de la cola', () async {
    final repo = RegistrosRepositoryApi(api);
    final r = NuevoRegistro(id: 'x', habitoId: 'h1', fecha: hoy, cumplido: true, origen: OrigenRegistro.offline);
    responde({'id': 'x', 'racha_actual': 6});
    expect((await repo.registrar(r)).valorONulo!.rachaActual, 6);
    expect((ultima().data as Map)['origen'], 'offline');
    responde({
      'resultados': [
        {'id': 'x', 'estado': 'aceptado', 'racha_actual': 6, 'error': null},
      ],
    });
    final lote = await repo.registrarLote([r, r]);
    expect(lote.valorONulo!.resultados.single.aceptado, isTrue);
    expect(red.rutas.last, 'POST /registros/lote');
    expect((ultima().data as Map)['registros'], hasLength(2));
  });

  test('escalera: sugerencias y respuesta ("Mantener" = aceptar false)', () async {
    final repo = EscaleraRepositoryApi(api);
    responde(const <Object>[]);
    await repo.sugerencias();
    expect(red.rutas.last, 'GET /escalera/sugerencias');
    responde({'estado': 'rechazada', 'nivel': null, 'meta_nueva': null});
    await repo.responder('s1', aceptar: false);
    expect(red.rutas.last, 'POST /escalera/sugerencias/s1/respuesta');
    expect(ultima().data, {'aceptar': false});
  });

  test('progreso, señales y laboratorio', () async {
    responde({
      'periodo': 'mes',
      'desde': '2026-11-01',
      'hasta': '2026-11-30',
      'cumplimiento': 80.0,
      'variacion': null,
      'habitos_activos': 5,
      'por_dia': <Object>[],
      'por_habito': <Object>[],
      'mejores_rachas': <Object>[],
      'crecimiento_metas': 0.0,
    });
    await ProgresoRepositoryApi(api).obtener(Periodo.mes, fecha: hoy);
    expect(ultima().queryParameters, {'periodo': 'mes', 'fecha': '2026-11-23'});

    final senales = SenalesRepositoryApi(api);
    responde({'fecha': '2026-11-23', 'animo': 4, 'energia': 3});
    await senales.guardar(Senal(fecha: hoy, animo: 4, energia: 3));
    expect(ultima().data, {'fecha': '2026-11-23', 'animo': 4, 'energia': 3});
    responde(const <Object>[]);
    await senales.listar(desde: hoy, hasta: hoy);
    expect(ultima().queryParameters, {'desde': '2026-11-23', 'hasta': '2026-11-23'});

    responde({'semana': '2026-W47', 'datos_suficientes': false, 'generado_en': null, 'perspectivas': <Object>[]});
    final lab = LaboratorioRepositoryApi(api);
    await lab.perspectivas();
    expect(ultima().queryParameters, isEmpty);
    await lab.perspectivas(semana: '2026-W47');
    expect(ultima().queryParameters, {'semana': '2026-W47'});
  });

  test('cápsulas: crear, listar con filtro y abrir', () async {
    final repo = CapsulasRepositoryApi(api);
    responde(capsula, 201);
    await repo.crear(const NuevaCapsula(habitoId: 'h1', mensaje: 'm', rachaObjetivo: 21, tieneFoto: false));
    expect(red.rutas.last, 'POST /capsulas');
    responde([capsula]);
    await repo.listar(estado: EstadoCapsula.sellada);
    expect(ultima().queryParameters, {'estado': 'sellada'});
    await repo.listar();
    expect(ultima().queryParameters, isEmpty);
    responde({'id': 'c1', 'mensaje': 'hola', 'abierta_en': '2026-11-23T10:00:00Z'});
    expect((await repo.abrir('c1')).valorONulo!.mensaje, 'hola');
    expect(red.rutas.last, 'POST /capsulas/c1/abrir');
  });

  test('cuenta (ARCO)', () async {
    final repo = CuentaRepositoryApi(api);
    const cuenta = {
      'id': 'u1',
      'nombre': 'Daniela',
      'email': 'd@x.com',
      'pais': 'MX',
      'region': 'MX-NORTE',
      'rol': 'usuario',
      'fecha_registro': '2026-01-01T00:00:00Z',
      'consentimiento_senales': false,
      'consentimiento_senales_en': null,
    };
    responde(cuenta);
    await repo.obtener();
    expect(red.rutas.last, 'GET /cuenta');
    await repo.cambiarNombre('Dani');
    expect(red.rutas.last, 'PATCH /cuenta');
    expect(ultima().data, {'nombre': 'Dani'});
    responde(null, 204);
    await repo.cambiarContrasena(actual: 'a', nueva: 'b');
    expect(red.rutas.last, 'PUT /cuenta/contrasena');
    responde({'senales': false, 'senales_borradas': 3});
    expect((await repo.cambiarConsentimiento(senales: false)).valorONulo!.senalesBorradas, 3);
    expect(red.rutas.last, 'PUT /cuenta/consentimientos');
    responde({'cuenta': cuenta});
    expect((await repo.exportarDatos()).valorONulo!.containsKey('cuenta'), isTrue);
    responde(null, 204);
    await repo.eliminar(contrasena: 'p');
    expect(red.rutas.last, 'DELETE /cuenta');
    expect(ultima().data, {'contrasena': 'p'});
  });

  test('admin: usuarios con filtros, suspensión, métricas, categorías e indicador', () async {
    final repo = AdminRepositoryApi(api);
    responde({'elementos': <Object>[], 'pagina': 1, 'por_pagina': 20, 'total': 0});
    await repo.usuarios(const FiltroUsuarios(rol: RolUsuario.admin));
    expect(ultima().queryParameters, {'rol': 'admin', 'pagina': '1', 'por_pagina': '20'});

    const usuario = {
      'id': 'u1',
      'region': 'LATAM',
      'pais': 'CO',
      'rol': 'usuario',
      'fecha_registro': '2026-01-01T00:00:00Z',
      'nombre_mascara': 'L***',
      'email_mascara': 'l***@x.com',
      'bloqueado': false,
      'consiente_senales': false,
      'suspendido': true,
      'suspendido_en': null,
      'suspension_motivo': 'Spam',
    };
    responde(usuario);
    await repo.cambiarSuspension('u1', suspendido: true, motivo: 'Spam');
    expect(ultima().data, {'suspendido': true, 'motivo': 'Spam'});
    await repo.cambiarSuspension('u1', suspendido: false);
    expect(ultima().data, {'suspendido': false}, reason: 'reactivar no lleva motivo');

    responde({
      'resumen': {'usuarios_activos': 1, 'variacion': null, 'cumplimiento_global': 1.0, 'categorias_activas': 8},
      'por_region': <Object>[],
    });
    await repo.metricas();
    expect(red.rutas.last, 'GET /admin/metricas');

    responde([
      {'id': 'c1', 'nombre': 'Música', 'activa': false},
    ]);
    expect((await repo.categorias()).valorONulo!.single.activa, isFalse);
    responde({'id': 'c1', 'nombre': 'Música', 'activa': true}, 201);
    await repo.crearCategoria('  Música ');
    expect(ultima().data, {'nombre': 'Música'});
    await repo.actualizarCategoria('c1', activa: false);
    expect(ultima().data, {'activa': false});
    expect(red.rutas.last, 'PATCH /admin/categorias/c1');

    responde({
      'codigo': 'I3',
      'titulo': 't',
      'grafica': 'barras',
      'origen': 'o',
      'datos_sinteticos': true,
      'periodo': {'desde': '2026-11-01', 'hasta': '2026-11-23'},
      'series': [
        {'etiqueta': 'LATAM', 'valor': 118},
      ],
      'generado_en': '2026-11-24T09:04:40Z',
    });
    expect((await repo.indicador('I3')).valorONulo!.series.single['valor'], 118);
    expect(red.rutas.last, 'GET /admin/indicadores/I3');
  });
}
