import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/domain/models/admin.dart';
import 'package:kaizen/domain/models/capsula.dart';
import 'package:kaizen/domain/models/categoria.dart';
import 'package:kaizen/domain/models/conversores.dart';
import 'package:kaizen/domain/models/escalera.dart';
import 'package:kaizen/domain/models/frecuencia.dart';
import 'package:kaizen/domain/models/habito.dart';
import 'package:kaizen/domain/models/laboratorio.dart';
import 'package:kaizen/domain/models/problema.dart';
import 'package:kaizen/domain/models/progreso.dart';
import 'package:kaizen/domain/models/registro.dart';
import 'package:kaizen/domain/models/sesion.dart';
import 'package:kaizen/domain/models/usuario.dart';

/// Ida y vuelta con los JSON de ejemplo del contrato v1.4: lo que manda la API se lee completo y, al volver a
/// JSON, sale igual (mismos nombres en snake_case, fechas y nulos).
Map<String, dynamic> json(String texto) => jsonDecode(texto) as Map<String, dynamic>;

void idaYVuelta(Map<String, dynamic> original, Map<String, dynamic> Function(Map<String, dynamic>) convertir) {
  expect(jsonDecode(jsonEncode(convertir(original))), original);
}

void main() {
  group('§5 objetos que se repiten', () {
    const habitoJson = '''
      {"id": "1c9e", "nombre": "Leer", "unidad": "páginas", "meta": 15, "nivel": 3,
       "categoria": {"id": "5b1e", "nombre": "Lectura"},
       "frecuencia": {"tipo": "dias_semana", "dias_semana": 31, "veces_semana": null},
       "escalera_activa": true, "activo": true, "fecha_creacion": "2026-09-01T14:00:00Z",
       "racha": {"actual": 5, "maxima": 12, "ultima_fecha": "2026-11-22"},
       "hoy": {"fecha": "2026-11-23", "programado": true,
               "registro": {"id": "r1", "cumplido": true, "valor": 18}}}''';

    test('Habito', () {
      final h = Habito.fromJson(json(habitoJson));
      expect(h.meta, 15.0);
      expect(h.frecuencia, const DiasSemana(31));
      expect(h.fechaCreacion, DateTime.utc(2026, 9, 1, 14));
      expect(h.racha.ultimaFecha, DateTime.utc(2026, 11, 22));
      expect(h.hoy!.cumplido, isTrue);
      expect(h.hoy!.registro!.valor, 18.0);
      final vuelta = jsonDecode(jsonEncode(h.toJson())) as Map<String, dynamic>;
      expect(vuelta['fecha_creacion'], '2026-09-01T14:00:00Z');
      expect(vuelta['racha'], {'actual': 5, 'maxima': 12, 'ultima_fecha': '2026-11-22'});
      expect(vuelta['frecuencia'], {'tipo': 'dias_semana', 'dias_semana': 31, 'veces_semana': null});
      expect(vuelta['categoria'], {'id': '5b1e', 'nombre': 'Lectura', 'activa': true});
    });

    test('Habito sin check-in hoy y copyWith', () {
      final m = json(habitoJson)..['hoy'] = {'fecha': '2026-11-23', 'programado': false, 'registro': null};
      final h = Habito.fromJson(m);
      expect(h.hoy!.registro, isNull);
      expect(h.hoy!.cumplido, isFalse);
      final c = h.copyWith(nombre: 'Leer más', racha: const Racha(actual: 6, maxima: 12));
      expect(c.nombre, 'Leer más');
      expect(c.racha.actual, 6);
      expect(c.id, h.id);
      expect(c.frecuencia, h.frecuencia);
    });

    test('Registro', () {
      idaYVuelta(
        json('''{"id": "r1", "habito_id": "h1", "fecha": "2026-11-23", "cumplido": true, "valor": 18.0,
                 "origen": "manual", "registrado_en": "2026-11-23T14:05:00Z"}'''),
        (m) => Registro.fromJson(m).toJson(),
      );
    });

    test('Sugerencia de la Escalera', () {
      final s = Sugerencia.fromJson(
        json('''{"id": "s1", "habito_id": "h1", "habito_nombre": "Leer", "tipo": "subir",
                 "meta_actual": 15, "meta_propuesta": 16.5, "cumplimiento_14d": 92.86,
                 "estado": "pendiente", "creada_en": "2026-11-23T03:00:00Z", "resuelta_en": null}'''),
      );
      expect(s.tipo, TipoSugerencia.subir);
      expect(s.cumplimiento14d, 92.86);
      expect(s.toJson()['cumplimiento_14d'], 92.86);
      expect(s.toJson()['resuelta_en'], isNull);
    });

    test('Capsula (sin el mensaje)', () {
      idaYVuelta(
        json('''{"id": "c1", "habito_id": "h1", "habito_nombre": "Tomar agua", "racha_objetivo": 21,
                 "progreso": 9, "se_puede_abrir": false, "estado": "sellada", "tiene_foto": true,
                 "creada_en": "2026-11-01T10:00:00Z", "abierta_en": null}'''),
        (m) => Capsula.fromJson(m).toJson(),
      );
    });

    test('Tokens: lee todo y no muestra los tokens en toString', () {
      final t = Tokens.fromJson(
        json('''{"token_acceso": "eyJ.acceso", "token_renovacion": "eyJ.renovacion", "tipo": "Bearer",
                 "expira_en": 900,
                 "usuario": {"id": "u1", "nombre": "Daniela", "rol": "usuario", "region": "MX-NORTE"}}'''),
      );
      expect(t.usuario.rol, RolUsuario.usuario);
      expect(t.expiraEn, 900);
      expect(t.toString(), isNot(contains('eyJ')));
      expect(t.toJson()['token_renovacion'], 'eyJ.renovacion');
    });
  });

  group('§6 cuerpos y respuestas', () {
    test('SolicitudRegistro: estado null fuera de México; toString sin la contraseña', () {
      const s = SolicitudRegistro(
        nombre: 'Daniela',
        email: 'dani@correo.com',
        contrasena: 'secreta-larga-123',
        pais: 'CO',
        estado: null,
        aceptaAviso: true,
        consienteSenales: false,
      );
      expect(s.toJson(), {
        'nombre': 'Daniela',
        'email': 'dani@correo.com',
        'contrasena': 'secreta-larga-123',
        'pais': 'CO',
        'estado': null,
        'acepta_aviso': true,
        'consiente_senales': false,
      });
      expect(s.toString(), isNot(contains('secreta')));
      expect(SolicitudRegistro.fromJson(s.toJson()).pais, 'CO');
    });

    test('NuevoHabito y CambiosHabito (PATCH solo con lo que cambia, nunca meta ni frecuencia)', () {
      const n = NuevoHabito(nombre: 'Leer', categoriaId: 'c1', frecuencia: NPorSemana(3), meta: 10, unidad: 'min');
      expect(n.toJson(), {
        'nombre': 'Leer',
        'categoria_id': 'c1',
        'frecuencia': {'tipo': 'n_por_semana', 'dias_semana': null, 'veces_semana': 3},
        'meta': 10.0,
        'unidad': 'min',
        'escalera_activa': true,
      });
      expect(NuevoHabito.fromJson(n.toJson()).frecuencia, const NPorSemana(3));
      expect(const CambiosHabito(activo: false).toJson(), {'activo': false});
      expect(const CambiosHabito(nombre: 'X', escaleraActiva: false).toJson(), {
        'nombre': 'X',
        'escalera_activa': false,
      });
      expect(const CambiosHabito().vacio, isTrue);
    });

    test('NuevoRegistro, ResultadoCheckin y lote', () {
      final r = NuevoRegistro(
        id: 'uuid',
        habitoId: 'h1',
        fecha: DateTime.utc(2026, 11, 23),
        cumplido: true,
        valor: 18,
        origen: OrigenRegistro.offline,
      );
      expect(r.toJson(), {
        'id': 'uuid',
        'habito_id': 'h1',
        'fecha': '2026-11-23',
        'cumplido': true,
        'valor': 18.0,
        'origen': 'offline',
      });
      expect(NuevoRegistro.fromJson(r.toJson()).fecha, DateTime.utc(2026, 11, 23));
      expect(ResultadoCheckin.fromJson({'id': 'uuid', 'racha_actual': 6}).rachaActual, 6);
      final lote = ResultadoLote.fromJson(
        json('''{"resultados": [{"id": "a", "estado": "aceptado", "racha_actual": 6},
                {"id": "b", "estado": "rechazado",
                 "error": {"type": "https://kaizen.app/errores/habito-archivado", "status": 409,
                           "title": "El hábito está archivado"}}]}'''),
      );
      expect(lote.resultados.first.aceptado, isTrue);
      expect(lote.resultados.last.aceptado, isFalse);
      expect(lote.resultados.last.error!.tipo, 'habito-archivado');
      expect(lote.toJson()['resultados'], hasLength(2));
    });

    test('Escalera de un hábito', () {
      final e = EscaleraHabito.fromJson(
        json('''{"habito_id": "h1", "escalera_activa": true, "nivel_actual": 3, "meta_actual": 10, "unidad": "min",
           "niveles": [{"nivel": 1, "meta": 7, "desde": "2026-10-03", "hasta": "2026-10-18"},
                       {"nivel": 2, "meta": 8.5, "desde": "2026-10-18", "hasta": "2026-11-02"},
                       {"nivel": 3, "meta": 10, "desde": "2026-11-02", "hasta": null}],
           "sugerencia_pendiente": {"id": "s1", "tipo": "subir", "meta_propuesta": 11, "cumplimiento_14d": 92.0},
           "historial": [{"fecha": "2026-11-02", "tipo": "subir", "de": 8.5, "a": 10, "estado": "aceptada"}]}'''),
      );
      expect(e.niveles.last.hasta, isNull);
      expect(e.sugerenciaPendiente!.metaPropuesta, 11.0);
      expect(e.historial.single.estado, EstadoSugerencia.aceptada);
      expect(e.toJson()['niveles'], hasLength(3));
      expect(
        RespuestaSugerencia.fromJson({'estado': 'rechazada', 'nivel': null, 'meta_nueva': null}).metaNueva,
        isNull,
      );
    });

    test('Progreso', () {
      final p = Progreso.fromJson(
        json('''{"periodo": "semana", "desde": "2026-11-17", "hasta": "2026-11-23",
           "cumplimiento": 82.0, "variacion": 6.0, "habitos_activos": 5,
           "por_dia": [{"fecha": "2026-11-17", "programados": 5, "cumplidos": 3, "cumplimiento": 60.0}],
           "por_habito": [{"habito_id": "h1", "nombre": "Leer", "cumplimiento": 85.71}],
           "mejores_rachas": [{"categoria": "Lectura", "racha_maxima": 34}],
           "crecimiento_metas": 18.0}'''),
      );
      expect(p.periodo, Periodo.semana);
      expect(p.porDia.single.cumplidos, 3);
      expect(p.mejoresRachas.single.rachaMaxima, 34);
      expect(p.toJson()['crecimiento_metas'], 18.0);
    });

    test('Perspectivas v1.4 (categoria + habitos) y tipos desconocidos', () {
      final p = Perspectivas.fromJson(
        json('''{"semana": "2026-W47", "datos_suficientes": true, "generado_en": "2026-11-24T09:03:00Z",
           "perspectivas": [{"tipo": "asociacion", "categoria": "Ejercicio", "variable": "energia", "delta": 0.8,
                             "dias_con": 9, "dias_sin": 8,
                             "habitos": [{"id": "1c9e", "nombre": "Caminar"}],
                             "texto": "Los días que cumples…"},
                            {"tipo": "franja_horaria", "franja": "noche", "texto": "…"},
                            {"tipo": "algo_nuevo", "texto": "…"}]}'''),
      );
      expect(p.perspectivas[0].habitos.single.nombre, 'Caminar');
      expect(p.perspectivas[1].tipo, TipoPerspectiva.franjaHoraria);
      expect(p.perspectivas[1].habitos, isEmpty);
      expect(p.perspectivas[2].tipo, TipoPerspectiva.desconocido);
      // Los campos que no aplican no se mandan.
      expect(p.perspectivas[1].toJson().containsKey('delta'), isFalse);
      expect(Senal.fromJson({'fecha': '2026-11-23', 'animo': 4, 'energia': 3}).toJson()['fecha'], '2026-11-23');
    });

    test('Cápsula abierta y nueva (toString sin el mensaje)', () {
      expect(
        CapsulaAbierta.fromJson({'id': 'c1', 'mensaje': 'hola', 'abierta_en': '2026-11-23T10:00:00Z'}).mensaje,
        'hola',
      );
      const n = NuevaCapsula(habitoId: 'h1', mensaje: 'secreto', rachaObjetivo: 21, tieneFoto: true);
      expect(n.toJson(), {'habito_id': 'h1', 'mensaje': 'secreto', 'racha_objetivo': 21, 'tiene_foto': true});
      expect(n.toString(), isNot(contains('secreto')));
      expect(NuevaCapsula.fromJson(n.toJson()).rachaObjetivo, 21);
    });

    test('Cuenta y consentimiento', () {
      final c = Cuenta.fromJson(
        json('''{"id": "u1", "nombre": "Daniela", "email": "d@x.com", "pais": "MX", "region": "MX-NORTE",
                 "rol": "admin", "fecha_registro": "2026-01-01T00:00:00Z", "consentimiento_senales": true,
                 "consentimiento_senales_en": "2026-02-01T00:00:00Z"}'''),
      );
      expect(c.rol, RolUsuario.admin);
      expect(c.toJson()['consentimiento_senales_en'], '2026-02-01T00:00:00Z');
      expect(ResultadoConsentimiento.fromJson({'senales': false, 'senales_borradas': 42}).senalesBorradas, 42);
      expect(UsuarioToken.fromJson(c.toJson()..['region'] = 'MX-NORTE').toJson()['rol'], 'admin');
    });

    test('Admin: página de usuarios, métricas, categoría e indicador', () {
      final pagina = Pagina.fromJson(
        json('''{"elementos": [{"id": "u1", "region": "LATAM", "pais": "CO", "rol": "usuario",
                 "fecha_registro": "2026-01-01T00:00:00Z", "nombre_mascara": "L****", "email_mascara": "l***@x.com",
                 "bloqueado": false, "consiente_senales": true, "suspendido": true,
                 "suspendido_en": "2026-11-20T00:00:00Z", "suspension_motivo": "Spam"}],
                 "pagina": 2, "por_pagina": 20, "total": 41}'''),
        UsuarioAdmin.fromJson,
      );
      expect(pagina.paginas, 3);
      expect(pagina.elementos.single.suspensionMotivo, 'Spam');
      expect(pagina.elementos.single.toJson()['email_mascara'], 'l***@x.com');
      expect(const Pagina<int>(elementos: [], pagina: 1, porPagina: 20, total: 0).paginas, 1);

      final m = MetricasAdmin.fromJson(
        json('''{"resumen": {"usuarios_activos": 1204, "variacion": 8.0, "cumplimiento_global": 76.0,
                 "categorias_activas": 8},
                 "por_region": [{"region": "LATAM", "categoria": "Salud", "usuarios": 10, "habitos": 30,
                                 "racha_promedio": 6.5}]}'''),
      );
      expect(m.resumen.usuariosActivos, 1204);
      expect(m.toJson()['por_region'], hasLength(1));
      expect(Categoria.fromJson({'id': 'c', 'nombre': 'Música', 'activa': false}).activa, isFalse);
      expect(Categoria.fromJson({'id': 'c', 'nombre': 'Música'}).activa, isTrue);

      final i = Indicador.fromJson(
        json('''{"codigo": "I2", "titulo": "Rachas", "grafica": "boxplot", "origen": "ETL", "datos_sinteticos": true,
                 "periodo": {"desde": "2026-08-26", "hasta": "2026-11-23"},
                 "series": [{"etiqueta": "Ejercicio", "min": 0, "q1": 2, "mediana": 6, "q3": 14, "max": 61, "n": 412}],
                 "generado_en": "2026-11-24T09:04:40Z"}'''),
      );
      expect(i.series.single['mediana'], 6);
      expect(i.periodo.hasta, DateTime.utc(2026, 11, 23));
      expect(i.toJson()['periodo'], {'desde': '2026-08-26', 'hasta': '2026-11-23'});
    });

    test('FiltroUsuarios: solo los filtros puestos; correo normalizado', () {
      expect(const FiltroUsuarios().aParametros(), {'pagina': '1', 'por_pagina': '20'});
      expect(
        const FiltroUsuarios(
          region: 'LATAM',
          rol: RolUsuario.admin,
          suspendido: true,
          email: ' Dani@Correo.com ',
          pagina: 2,
        ).aParametros(),
        {
          'region': 'LATAM',
          'rol': 'admin',
          'suspendido': 'true',
          'email': 'dani@correo.com',
          'pagina': '2',
          'por_pagina': '20',
        },
      );
    });
  });

  group('Problema (problem+json)', () {
    test('lee tipo, errores por campo y campos extra', () {
      final p = Problema.fromJson(
        json('''{"type": "https://kaizen.app/errores/capsula-sellada", "title": "Sellada", "status": 409,
                 "detail": "Racha 9 de 21", "id_peticion": "7f3c", "racha": 9, "objetivo": 21,
                 "errores": [{"campo": "mensaje", "detalle": "Máximo 4096 bytes"}]}'''),
      );
      expect(p.tipo, 'capsula-sellada');
      expect(p.entero('racha'), 9);
      expect(p.entero('objetivo'), 21);
      expect(p.errores.single.campo, 'mensaje');
      expect(p.toJson()['racha'], 9);
      expect(p.toJson()['errores'], [
        {'campo': 'mensaje', 'detalle': 'Máximo 4096 bytes'},
      ]);
    });

    test('tolera un cuerpo incompleto', () {
      final p = Problema.fromJson({});
      expect(p.tipo, 'about:blank');
      expect(p.status, 0);
      expect(p.toJson().containsKey('errores'), isFalse);
    });
  });

  group('Conversores de fechas', () {
    test('fecha YYYY-MM-DD a medianoche UTC y de vuelta', () {
      expect(const FechaConverter().fromJson('2026-02-09'), DateTime.utc(2026, 2, 9));
      expect(const FechaConverter().toJson(DateTime.utc(2026, 2, 9)), '2026-02-09');
      expect(() => const FechaConverter().fromJson('09/02/2026'), throwsFormatException);
      expect(const FechaNulaConverter().fromJson(null), isNull);
      expect(const FechaNulaConverter().toJson(null), isNull);
    });

    test('instante ISO en UTC con Z', () {
      expect(const InstanteConverter().fromJson('2026-11-23T18:04:05Z'), DateTime.utc(2026, 11, 23, 18, 4, 5));
      expect(const InstanteConverter().toJson(DateTime.utc(2026, 11, 23, 18, 4, 5, 123)), '2026-11-23T18:04:05Z');
      expect(const InstanteNuloConverter().fromJson(null), isNull);
      expect(const InstanteNuloConverter().toJson(null), isNull);
    });
  });
}
