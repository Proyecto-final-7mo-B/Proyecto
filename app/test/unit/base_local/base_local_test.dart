import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/data/services/base_local/almacen_local.dart';
import 'package:kaizen/data/services/base_local/base_local.dart';
import 'package:kaizen/domain/models/categoria.dart';
import 'package:kaizen/domain/models/frecuencia.dart';
import 'package:kaizen/domain/models/habito.dart';
import 'package:kaizen/domain/models/registro.dart';

final DateTime hoy = DateTime.utc(2026, 11, 25);
final DateTime ayer = DateTime.utc(2026, 11, 24);

Habito habito({int racha = 5, DateTime? ultima, HoyHabito? deHoy, bool activo = true, String id = 'h1'}) => Habito(
  id: id,
  nombre: 'Leer',
  categoria: const Categoria(id: 'cat-educacion', clave: 'educacion', nombre: 'Educación'),
  subcategoria: const Subcategoria(id: 'sub-lectura', clave: 'lectura', nombre: 'Lectura', icono: 'menu_book'),
  frecuencia: const Diaria(),
  meta: 10,
  unidad: 'min',
  nivel: 1,
  escaleraActiva: true,
  activo: activo,
  racha: Racha(actual: racha, maxima: 9, ultimaFecha: ultima),
  fechaCreacion: DateTime.utc(2026, 10),
  hoy: deHoy,
);

NuevoRegistro nuevo(String id, {DateTime? fecha, bool cumplido = true, String habitoId = 'h1'}) =>
    NuevoRegistro(id: id, habitoId: habitoId, fecha: fecha ?? hoy, cumplido: cumplido, origen: OrigenRegistro.rapido);

void main() {
  late BaseLocal base;
  late AlmacenLocal almacen;

  setUp(() {
    base = BaseLocal(NativeDatabase.memory());
    almacen = AlmacenLocal(base);
  });
  tearDown(() => base.close());

  group('esquema', () {
    test('las 9 tablas del diseño, versión 1', () async {
      final tablas = await base
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'")
          .map((f) => f.read<String>('name'))
          .get();
      expect(
        tablas,
        unorderedEquals([
          'habitos',
          'categorias',
          'registros',
          'cola_pendientes',
          'senales',
          'sugerencias',
          'capsulas',
          'recordatorios',
          'marcas',
        ]),
      );
      expect(base.schemaVersion, 1);
      final columnasCapsulas = await base
          .customSelect('PRAGMA table_info(capsulas)')
          .map((f) => f.read<String>('name'))
          .get();
      expect(columnasCapsulas, isNot(contains('mensaje')), reason: 'el mensaje de la cápsula nunca se guarda');
      expect(columnasCapsulas, contains('ruta_foto'));
    });

    test('al reabrir el archivo los datos siguen y no se vuelve a crear nada', () async {
      final archivo = File('${Directory.systemTemp.createTempSync('kaizen_').path}/kaizen.sqlite');
      final primera = BaseLocal(NativeDatabase(archivo));
      await AlmacenLocal(primera).guardarCategorias([const Categoria(id: 'c1', nombre: 'Salud')]);
      expect(await primera.customSelect('PRAGMA user_version').map((f) => f.read<int>('user_version')).getSingle(), 1);
      await primera.close();
      final segunda = BaseLocal(NativeDatabase(archivo));
      expect(await AlmacenLocal(segunda).categorias(), [const Categoria(id: 'c1', nombre: 'Salud')]);
      await segunda.close();
    });

    test('UNIQUE (habito_id, fecha): la base no acepta dos check-ins del mismo día', () async {
      Future<void> insertar(String id) => base
          .into(base.registros)
          .insert(
            RegistrosCompanion.insert(id: id, habitoId: 'h1', fecha: '2026-11-25', cumplido: true, origen: 'rapido'),
          );
      await insertar('a');
      expect(() => insertar('b'), throwsA(isA<SqliteException>()));
    });
  });

  group('check-ins', () {
    test('guardar uno nuevo del mismo día reemplaza al anterior (gana el último)', () async {
      await almacen.guardarRegistros([
        Registro(id: 'a', habitoId: 'h1', fecha: hoy, cumplido: true, origen: OrigenRegistro.rapido),
      ]);
      await almacen.guardarRegistros([
        Registro(id: 'b', habitoId: 'h1', fecha: hoy, cumplido: false, origen: OrigenRegistro.manual, valor: 3),
      ]);
      final r = await almacen.registro('h1', hoy);
      expect(r!.id, 'b');
      expect(r.cumplido, isFalse);
      expect(r.valor, 3);
      expect(await almacen.registros('h1', desde: ayer, hasta: hoy), hasLength(1));
    });

    test('rango por fechas y orden', () async {
      await almacen.guardarRegistros([
        for (var d = 20; d <= 25; d++)
          Registro(
            id: 'r$d',
            habitoId: 'h1',
            fecha: DateTime.utc(2026, 11, d),
            cumplido: true,
            origen: OrigenRegistro.rapido,
          ),
      ]);
      final lista = await almacen.registros('h1', desde: DateTime.utc(2026, 11, 22), hasta: ayer);
      expect(lista.map((r) => r.id), ['r22', 'r23', 'r24']);
      expect(lista.first.fecha, DateTime.utc(2026, 11, 22));
    });
  });

  group('cola sin conexión', () {
    test('guardar + encolar: quedan los dos y devuelve el check-in anterior', () async {
      await almacen.guardarRegistros([
        Registro(id: 'viejo', habitoId: 'h1', fecha: hoy, cumplido: false, origen: OrigenRegistro.rapido),
      ]);
      final anterior = await almacen.guardarYEncolar(nuevo('n1'));
      expect(anterior!.id, 'viejo');
      expect((await almacen.registro('h1', hoy))!.id, 'n1');
      final cola = await almacen.pendientes();
      expect(cola.single.id, 'n1');
      expect(cola.single.origen, OrigenRegistro.offline, reason: 'la cola siempre se manda como offline');
      expect(cola.single.fecha, hoy, reason: 'la fecha local original');
    });

    test('es atómico: si encolar falla, el check-in tampoco se guarda', () async {
      await base.customStatement(
        "CREATE TRIGGER falla BEFORE INSERT ON cola_pendientes BEGIN SELECT RAISE(ABORT, 'falla'); END;",
      );
      await expectLater(almacen.guardarYEncolar(nuevo('n1')), throwsA(isA<SqliteException>()));
      expect(await almacen.registro('h1', hoy), isNull);
      expect(await almacen.pendientes(), isEmpty);
    });

    test('el mismo check-in dos veces (o marcar y desmarcar) queda una sola vez', () async {
      await almacen.guardarYEncolar(nuevo('n1'));
      await almacen.guardarYEncolar(nuevo('n1', cumplido: false));
      await almacen.guardarYEncolar(nuevo('n2'));
      final cola = await almacen.pendientes();
      expect(cola, hasLength(1));
      expect(cola.single.id, 'n2');
      expect(await almacen.registros('h1', desde: hoy, hasta: hoy), hasLength(1));
    });

    test('deshacer: sale de la cola y vuelve el check-in que había (o ninguno)', () async {
      final anterior = Registro(
        id: 'viejo',
        habitoId: 'h1',
        fecha: hoy,
        cumplido: false,
        origen: OrigenRegistro.rapido,
      );
      await almacen.guardarRegistros([anterior]);
      final n = nuevo('n1');
      await almacen.deshacer(n, await almacen.guardarYEncolar(n));
      expect((await almacen.registro('h1', hoy))!.id, 'viejo');
      expect(await almacen.pendientes(), isEmpty);
      final otro = nuevo('n2', fecha: ayer);
      await almacen.deshacer(otro, await almacen.guardarYEncolar(otro));
      expect(await almacen.registro('h1', ayer), isNull);
    });

    test('pendientes: del más viejo al más nuevo, máximo el límite, sin los rechazados', () async {
      for (var i = 1; i <= 5; i++) {
        await almacen.guardarYEncolar(nuevo('n$i', fecha: DateTime.utc(2026, 11, i)));
      }
      expect((await almacen.pendientes(limite: 3)).map((p) => p.id), ['n1', 'n2', 'n3']);
      await almacen.marcarRechazado('n2', 'habito-archivado');
      expect((await almacen.pendientes()).map((p) => p.id), ['n1', 'n3', 'n4', 'n5']);
      expect(await almacen.registro('h1', DateTime.utc(2026, 11, 2)), isNull, reason: 'el rechazado se quita');
      expect(await almacen.pendienteDe('h1', DateTime.utc(2026, 11, 2)), isNull);
      expect((await almacen.pendienteDe('h1', DateTime.utc(2026, 11, 3)))!.id, 'n3');
    });

    test('anotar un intento suma uno y guarda el motivo', () async {
      await almacen.guardarYEncolar(nuevo('n1'));
      await almacen.anotarIntento(['n1'], 'sinConexion');
      await almacen.anotarIntento(['n1'], 'tiempoAgotado');
      final f = await base.select(base.colaPendientes).getSingle();
      expect(f.intentos, 2);
      expect(f.ultimoError, 'tiempoAgotado');
    });

    test('observar la cola: pendientes, rechazados y fallidos al momento', () async {
      final eventos = <({int pendientes, int rechazados, int fallidos})>[];
      final sub = almacen.observarCola().listen(eventos.add);
      await pumpEventQueue();
      await almacen.guardarYEncolar(nuevo('n1'));
      await almacen.guardarYEncolar(nuevo('n2', fecha: ayer));
      await pumpEventQueue();
      expect(eventos.last, (pendientes: 2, rechazados: 0, fallidos: 0), reason: 'encolado no es fallido');
      await almacen.anotarIntento(['n2'], 'sinConexion');
      await pumpEventQueue();
      expect(eventos.last, (pendientes: 2, rechazados: 0, fallidos: 1));
      await almacen.marcarRechazado('n1', 'habito-archivado');
      await pumpEventQueue();
      expect(eventos.first, (pendientes: 0, rechazados: 0, fallidos: 0));
      expect(eventos.last, (pendientes: 1, rechazados: 1, fallidos: 1));
      await sub.cancel();
    });
  });

  group('racha estimada sin conexión', () {
    test('marcar suma uno; desmarcar lo que el servidor ya contaba resta uno', () {
      final sinHoy = habito(racha: 5, ultima: ayer);
      final marcado = AlmacenLocal.conCheckinLocal(sinHoy, fecha: hoy, cumplido: true, id: 'x');
      expect(marcado.racha.actual, 6);
      expect(marcado.racha.ultimaFecha, hoy);
      expect(marcado.hoy!.cumplido, isTrue);
      expect(marcado.hoy!.programado, isTrue);

      final conHoy = habito(
        racha: 6,
        ultima: hoy,
        deHoy: HoyHabito(
          fecha: hoy,
          programado: true,
          registro: const RegistroDeHoy(id: 'x', cumplido: true),
        ),
      );
      expect(AlmacenLocal.conCheckinLocal(conHoy, fecha: hoy, cumplido: true, id: 'x').racha.actual, 6);
      final desmarcado = AlmacenLocal.conCheckinLocal(conHoy, fecha: hoy, cumplido: false, id: 'x');
      expect(desmarcado.racha.actual, 5);
      expect(desmarcado.racha.ultimaFecha, isNull);
      expect(AlmacenLocal.conCheckinLocal(habito(racha: 0), fecha: hoy, cumplido: false).racha.actual, 0);
    });

    test('confirmar el check-in: la copia toma la racha real y ya no se cuenta dos veces', () async {
      await almacen.guardarHabito(
        habito(
          racha: 5,
          ultima: ayer,
          deHoy: HoyHabito(fecha: hoy, programado: true),
        ),
      );
      await almacen.confirmarCheckin(nuevo('n1'), 6);
      final h = (await almacen.habito('h1'))!;
      expect(h.racha.actual, 6);
      expect(h.hoy!.cumplido, isTrue);
      expect(AlmacenLocal.conCheckinLocal(h, fecha: hoy, cumplido: true, id: 'n1').racha.actual, 6);
      await almacen.confirmarCheckin(nuevo('n9', habitoId: 'no-existe'), 1); // sin copia: no hace nada
    });
  });

  group('copia de hábitos, categorías y recordatorios', () {
    test('hábitos: la marca distingue "nunca se guardó" de "no hay hábitos"', () async {
      expect(await almacen.hayHabitosGuardados(), isFalse);
      await almacen.guardarHabitos(const [], incluyeArchivados: false);
      expect(await almacen.hayHabitosGuardados(), isTrue);
      expect(await almacen.habitos(), isEmpty);
    });

    test('guardar solo los activos conserva los archivados guardados antes', () async {
      await almacen.guardarHabitos([habito(id: 'a'), habito(id: 'b', activo: false)], incluyeArchivados: true);
      await almacen.guardarHabitos([habito(id: 'c')], incluyeArchivados: false);
      expect((await almacen.habitos()).map((h) => h.id), ['c']);
      expect((await almacen.habitos(incluyeArchivados: true)).map((h) => h.id), unorderedEquals(['b', 'c']));
      expect((await almacen.habito('c'))!.nombre, 'Leer');
      expect(await almacen.habito('zz'), isNull);
    });

    test('categorías en el orden de la API, con su árbol completo; recordatorios guardar, leer y quitar', () async {
      const sub = Subcategoria(
        id: 'm',
        clave: 'meditacion',
        nombre: 'Meditación',
        icono: 'self_improvement',
        unidades: [UnidadPermitida(unidad: 'min', factorABase: 1, paso: 1, minimo: 1, maximo: 600)],
        referencia: ReferenciaCientifica(
          periodo: PeriodoReferencia.dia,
          unidadBase: 'min',
          optimoDesde: 10,
          optimoHasta: 20,
          maximo: 45,
          cita: 'Strohmaier 2020',
          fuentes: 'F32',
          url: 'https://doi.org/10.1007/s12671-020-01319-4',
          confianza: Confianza.media,
        ),
      );
      await almacen.guardarCategorias([
        const Categoria(id: 'b', clave: 'bienestar', nombre: 'Bienestar', color: '#0F766E', subcategorias: [sub]),
        const Categoria(id: 'a', clave: 'ahorro', nombre: 'Ahorro', activa: false),
      ]);
      final copia = await almacen.categorias();
      expect(copia.map((c) => c.nombre), ['Bienestar', 'Ahorro'], reason: 'el orden de la API, no el alfabético');
      final meditacion = copia.first.subcategorias.single;
      expect(meditacion.unidades.single.paso, 1);
      expect(meditacion.referencia!.maximo, 45, reason: 'sin red se sigue evaluando contra la evidencia');
      expect(copia.first.color, '#0F766E');
      await almacen.guardarRecordatorio('h1', 7, 30);
      expect(await almacen.recordatorio('h1'), (hora: 7, minuto: 30));
      await almacen.quitarRecordatorio('h1');
      expect(await almacen.recordatorio('h1'), isNull);
    });

    test('al cerrar sesión no queda nada', () async {
      await almacen.guardarCategorias([const Categoria(id: 's', nombre: 'Sueño')]);
      await almacen.guardarHabitos([habito()], incluyeArchivados: true);
      await almacen.guardarYEncolar(nuevo('n1'));
      await almacen.guardarRecordatorio('h1', 7, 30);
      await almacen.borrarTodo();
      for (final tabla in base.allTables) {
        expect(await base.select(tabla).get(), isEmpty, reason: tabla.actualTableName);
      }
      expect(await almacen.hayHabitosGuardados(), isFalse);
    });
  });
}
