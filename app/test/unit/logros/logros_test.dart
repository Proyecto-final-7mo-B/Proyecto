import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/config/dependencias.dart';
import 'package:kaizen/data/fake/datos_demo.dart';
import 'package:kaizen/data/fake/logros_demo.dart';
import 'package:kaizen/data/repositories/capsulas/capsulas_repository_fake.dart';
import 'package:kaizen/data/repositories/escalera/escalera_repository_fake.dart';
import 'package:kaizen/data/repositories/habitos/habitos_repository_fake.dart';
import 'package:kaizen/data/repositories/logros/logros_repository_fake.dart';
import 'package:kaizen/data/repositories/registros/registros_repository_fake.dart';
import 'package:kaizen/data/services/api/errores_api.dart';
import 'package:kaizen/data/services/base_local/almacen_local.dart';
import 'package:kaizen/data/services/base_local/base_local.dart';
import 'package:kaizen/data/services/logros/novedades_logros.dart';
import 'package:kaizen/data/sync/monitor_conexion.dart';
import 'package:kaizen/domain/models/capsula.dart';
import 'package:kaizen/domain/models/escalera.dart';
import 'package:kaizen/domain/models/frecuencia.dart';
import 'package:kaizen/domain/models/habito.dart';
import 'package:kaizen/domain/models/logro.dart';
import 'package:kaizen/domain/models/registro.dart';
import 'package:kaizen/ui/logros/view_models/logros_viewmodel.dart';

/// Miércoles 25-nov-2026, 9:30.
final DateTime _ahora = DateTime(2026, 11, 25, 9, 30);

Logro _logro(
  String clave, {
  bool obtenido = false,
  DateTime? en,
  int progreso = 0,
  int objetivo = 1,
  String tipo = 'evento',
}) => Logro.fromJson({
  'clave': clave,
  'nombre': clave,
  'descripcion': 'd',
  'icono': 'verified',
  'tipo': tipo,
  'objetivo': objetivo,
  'progreso': progreso,
  'obtenido': obtenido,
  'obtenido_en': en?.toIso8601String(),
  'habito': null,
  'porque': 'p',
  'fuentes': null,
});

void main() {
  group('modelo', () {
    test('JSON del contrato §6.13, de ida y vuelta', () {
      const json = {
        'clave': 'habito_formado',
        'nombre': 'Hábito formado',
        'descripcion': 'Llega a 66 días seguidos: la mediana científica para formar un hábito',
        'icono': 'workspace_premium',
        'tipo': 'racha',
        'objetivo': 66,
        'progreso': 59,
        'obtenido': false,
        'obtenido_en': null,
        'habito': null,
        'porque': 'Mediana de los estudios que midieron la formación de hábitos (no 21 días)',
        'fuentes': 'F01, F02',
      };
      final l = Logro.fromJson(json);
      expect((l.tipo, l.objetivo, l.progreso, l.obtenido, l.fuentes), (TipoLogro.racha, 66, 59, false, 'F01, F02'));
      expect(l.avance, closeTo(59 / 66, 1e-9));
      expect(l.muestraProgreso, isTrue);
      expect(l.toJson(), json);

      final o = Logro.fromJson({
        ...json,
        'obtenido': true,
        'progreso': 66,
        'obtenido_en': '2026-11-20T12:00:00Z',
        'habito': {'id': 'h1', 'nombre': 'Leer'},
      });
      expect((o.habitoId, o.habitoNombre, o.obtenidoEn), ('h1', 'Leer', DateTime.utc(2026, 11, 20, 12)));
      expect((o.avance, o.muestraProgreso), (1.0, false));
      expect(Logro.fromJson(o.toJson()).toJson(), o.toJson());
    });

    test('tipos desconocidos son "evento"; "(F3)" no se muestra al usuario', () {
      expect(TipoLogro.deJson('semanal'), TipoLogro.semanal);
      expect(TipoLogro.deJson('otro'), TipoLogro.evento);
      final l = Logro.fromJson({..._logro('x').toJson(), 'porque': 'Recompensa personal por la constancia (F3)'});
      expect(l.porqueParaMostrar, 'Recompensa personal por la constancia');
      expect(_logro('y', objetivo: 0).avance, 0);
    });

    test('último obtenido y próximo por obtener', () {
      final a = _logro('a', obtenido: true, en: DateTime.utc(2026, 11, 1));
      final b = _logro('b', obtenido: true, en: DateTime.utc(2026, 11, 20));
      final c = _logro('c', tipo: 'racha', objetivo: 30, progreso: 21);
      final d = _logro('d', tipo: 'racha', objetivo: 66, progreso: 21);
      expect(ultimoObtenido([a, b, c])!.clave, 'b');
      expect(ultimoObtenido([c, d]), isNull);
      expect(proximoPorObtener([a, d, c])!.clave, 'c', reason: '21/30 va más avanzado que 21/66');
      expect(proximoPorObtener([a, b]), isNull);
      expect(ultimoObtenido([_logro('s', obtenido: true), a])!.clave, 'a', reason: 'sin fecha va al final');
    });
  });

  group('fake (las reglas de la base)', () {
    late DatosDemo datos;
    late LogrosRepositoryFake repo;

    setUp(() {
      datos = DatosDemo(reloj: () => _ahora)..usuarioActual = 'u-demo';
      repo = LogrosRepositoryFake(datos);
    });

    Future<Map<String, Logro>> logros() async => {for (final l in (await repo.listar()).valorONulo!) l.clave: l};
    String idDe(String nombre) => datos.habitosDe('u-demo').firstWhere((h) => h.nombre == nombre).id;

    test('el catálogo: 10 logros en el orden de la base', () async {
      final l = (await repo.listar()).valorONulo!;
      expect([for (final x in l) x.clave], [for (final x in logrosDemo) x.clave]);
      expect(l.first.clave, 'racha_7');
      expect(l.last.clave, 'plan_si_entonces');
    });

    test('Daniela: 6 de 10, con su hábito y su fecha', () async {
      final l = await logros();
      expect(
        [
          for (final x in l.values)
            if (x.obtenido) x.clave,
        ],
        ['racha_7', 'racha_30', 'ritmo_ideal', 'semana_oms', 'racha_salvada', 'plan_si_entonces'],
      );
      expect(l['racha_30']!.habitoNombre, 'Leer');
      expect(l['habito_formado']!.progreso, 34, reason: 'la mejor racha');
      expect(l['racha_100']!.progreso, 34);
      expect(l['capsula_abierta']!.progreso, 0);
      expect(l['racha_30']!.obtenidoEn!.isBefore(_ahora), isTrue);
      expect(ultimoObtenido(l.values)!.clave, 'ritmo_ideal');
    });

    test('se obtienen una sola vez: la fecha no cambia al volver a leer', () async {
      final antes = (await logros())['racha_7']!.obtenidoEn;
      expect((await logros())['racha_7']!.obtenidoEn, antes);
    });

    test('primer micro-paso al aceptar una subida; cápsula abierta al abrirla', () async {
      final escalera = EscaleraRepositoryFake(datos);
      final s = (await escalera.sugerencias()).valorONulo!.firstWhere(
        (s) => s.estado == EstadoSugerencia.pendiente && s.tipo == TipoSugerencia.subir,
      );
      await escalera.responder(s.id, aceptar: true);
      final l = await logros();
      expect(l['primer_micro_paso']!.obtenido, isTrue);
      expect(l['primer_micro_paso']!.habitoId, s.habitoId);

      final capsulas = CapsulasRepositoryFake(datos);
      final lista = (await capsulas.listar()).valorONulo!;
      final abrible = lista.firstWhere((c) => c.estado == EstadoCapsula.sellada && c.sePuedeAbrir);
      expect((await capsulas.abrir(abrible.id)).valorONulo, isNotNull);
      expect((await logros())['capsula_abierta']!.obtenido, isTrue);
    });

    test('plan si-entonces: solo con un hábito personalizado con intención', () async {
      datos.usuarioActual = 'u-admin';
      final habitos = HabitosRepositoryFake(datos);
      expect((await logros())['plan_si_entonces']!.obtenido, isFalse);
      final rec = datos.recomendados.firstWhere((r) => r.momento.isNotEmpty);
      await habitos.crearRecomendado(rec.id);
      expect((await logros())['plan_si_entonces']!.obtenido, isFalse, reason: 'la recomendación trae su momento');
      await habitos.crear(
        NuevoHabito(
          nombre: 'Leer de noche',
          subcategoriaId: datos.subcategoriaPorClave('lectura').id,
          frecuencia: const Diaria(),
          meta: 20,
          unidad: 'min',
          intencion: 'Después de cenar',
        ),
      );
      expect((await logros())['plan_si_entonces']!.obtenido, isTrue);
    });

    test('racha: al marcar el día que llega a 7 se obtiene "Primera semana" (y no antes)', () async {
      datos.usuarioActual = 'u-nuevo';
      expect(datos.habitosDe('u-nuevo'), isEmpty);
      final leer = datos.habitos.values.firstWhere((h) => h.nombre == 'Leer');
      final h = HabitoDemo(
        id: datos.nuevoId(),
        usuarioId: 'u-nuevo',
        nombre: 'Leer',
        unidad: leer.unidad,
        meta: leer.meta,
        nivel: 1,
        subcategoriaId: leer.subcategoriaId,
        categoriaId: leer.categoriaId,
        frecuencia: const Diaria(),
        escaleraActiva: true,
        activo: true,
        fechaCreacion: _ahora.subtract(const Duration(days: 10)).toUtc(),
      );
      datos.habitos[h.id] = h;
      final registros = RegistrosRepositoryFake(datos);
      Future<void> marcar(int diasAtras) => registros.registrar(
        NuevoRegistro(
          id: datos.nuevoId(),
          habitoId: h.id,
          fecha: datos.hoy.subtract(Duration(days: diasAtras)),
          cumplido: true,
          origen: OrigenRegistro.rapido,
        ),
      );
      for (var i = 6; i >= 1; i--) {
        await marcar(i);
      }
      final seis = await logros();
      expect((seis['racha_7']!.obtenido, seis['racha_7']!.progreso), (false, 6));
      await marcar(0);
      final siete = await logros();
      expect(siete['racha_7']!.obtenido, isTrue);
      expect(siete['racha_7']!.habitoId, h.id);
      expect(siete['racha_30']!.progreso, 7);
    });

    test('sin red: el error de red del fake', () async {
      datos.hayRed = () => false;
      expect((await repo.listar()).errorONulo!.tipo, TipoError.sinConexion);
      expect(idDe('Leer'), isNotEmpty);
    });
  });

  group('copia local y novedades', () {
    late DatosDemo datos;
    late MonitorConexionManual red;
    late Dependencias d;

    setUp(() {
      datos = DatosDemo(reloj: () => _ahora)..usuarioActual = 'u-demo';
      red = MonitorConexionManual();
      d = Dependencias.fake(datos: datos, monitor: red);
    });

    test('sin red se ven los últimos que se leyeron; sin copia, el error', () async {
      red.hayRed = false;
      expect((await d.logros.listar()).errorONulo!.tipo, TipoError.sinConexion);
      red.hayRed = true;
      final enLinea = (await d.logros.listar()).valorONulo!;
      red.hayRed = false;
      final copia = (await d.logros.listar()).valorONulo!;
      expect([for (final l in copia) l.toJson()], [for (final l in enLinea) l.toJson()]);
    });

    test('novedades: la primera vez solo anota; después, solo lo nuevo y una vez', () async {
      final n = NovedadesLogros(AlmacenLocal(BaseLocal.enMemoria()));
      final a = _logro('a', obtenido: true, en: DateTime.utc(2026, 11, 1));
      final b = _logro('b');
      expect(await n.revisar([a, b]), isEmpty, reason: 'instalación nueva: no avisa de golpe');
      final b2 = _logro('b', obtenido: true, en: DateTime.utc(2026, 11, 25));
      expect(
        [
          for (final l in await n.revisar([a, b2])) l.clave,
        ],
        ['b'],
      );
      expect(await n.revisar([a, b2]), isEmpty);
      await n.almacen.base.close();
    });
  });

  group('LogrosViewModel', () {
    test('carga, filtra y cuenta', () async {
      final datos = DatosDemo(reloj: () => _ahora)..usuarioActual = 'u-demo';
      final vm = LogrosViewModel(logros: LogrosRepositoryFake(datos));
      await vm.cargar.ejecutar();
      expect((vm.obtenidos, vm.total, vm.visibles.length), (6, 10, 10));
      var avisos = 0;
      vm.addListener(() => avisos++);
      vm.elegirFiltro(FiltroLogros.obtenidos);
      expect(vm.visibles.every((l) => l.obtenido), isTrue);
      expect(vm.visibles, hasLength(6));
      vm.elegirFiltro(FiltroLogros.porObtener);
      expect(vm.visibles.every((l) => !l.obtenido), isTrue);
      vm.elegirFiltro(FiltroLogros.porObtener);
      expect(avisos, 2, reason: 'el mismo filtro no vuelve a avisar');
      expect(vm.filtro, FiltroLogros.porObtener);
      vm.dispose();
    });

    test('si falla, devuelve el error', () async {
      final datos = DatosDemo(reloj: () => _ahora)..usuarioActual = 'u-demo';
      datos.fallarSiguiente(const ErrorApp(TipoError.desconocido));
      final vm = LogrosViewModel(logros: LogrosRepositoryFake(datos));
      await vm.cargar.ejecutar();
      expect(vm.cargar.error!.tipo, TipoError.desconocido);
      expect(vm.logros, isEmpty);
      vm.dispose();
    });
  });
}
