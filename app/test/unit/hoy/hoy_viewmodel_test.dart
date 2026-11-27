import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/config/dependencias.dart';
import 'package:kaizen/data/fake/datos_demo.dart';
import 'package:kaizen/data/repositories/escalera/escalera_repository.dart';
import 'package:kaizen/data/repositories/progreso/progreso_repository.dart';
import 'package:kaizen/data/services/api/errores_api.dart';
import 'package:kaizen/data/sync/monitor_conexion.dart';
import 'package:kaizen/domain/models/escalera.dart';
import 'package:kaizen/domain/models/frecuencia.dart';
import 'package:kaizen/domain/models/habito.dart';
import 'package:kaizen/domain/models/progreso.dart';
import 'package:kaizen/domain/models/registro.dart';
import 'package:kaizen/ui/hoy/view_models/hoy_viewmodel.dart';
import 'package:kaizen/utils/fechas.dart';
import 'package:kaizen/utils/result.dart';
import 'package:mocktail/mocktail.dart';

class _EscaleraRota extends Mock implements EscaleraRepository {}

class _ProgresoRoto extends Mock implements ProgresoRepository {}

/// Miércoles 25-nov-2026, 9:30.
final DateTime _ahora = DateTime(2026, 11, 25, 9, 30);

void main() {
  late DatosDemo datos;
  late Dependencias d;
  late HoyViewModel vm;

  HoyViewModel crear({EscaleraRepository? escalera, ProgresoRepository? progreso}) => HoyViewModel(
    habitos: d.habitos,
    registros: d.registros,
    progreso: progreso ?? d.progreso,
    escalera: escalera ?? d.escalera,
    capsulas: d.capsulas,
    reloj: () => _ahora,
  );

  Habito habito(String nombre) => vm.habitos.firstWhere((h) => h.nombre == nombre);

  setUpAll(() {
    registerFallbackValue(Periodo.semana);
  });

  setUp(() async {
    datos = DatosDemo(reloj: () => _ahora)..usuarioActual = 'u-demo';
    d = Dependencias.fake(datos: datos);
    vm = crear();
    await vm.cargar.ejecutar();
  });

  tearDown(() => vm.dispose());

  group('carga', () {
    test('Daniela: "2 de 5" como en el bosquejo, con sugerencia y cápsulas', () {
      expect(vm.cargado, isTrue);
      expect(vm.hoy, DateTime.utc(2026, 11, 25));
      expect(vm.totalHoy, 5);
      expect(vm.cumplidosHoy, 2);
      expect(vm.avanceHoy, closeTo(0.4, 1e-9));
      // Como los manda la API (v1.6): por prioridad (Ejercicio alta, Estudiar inglés baja) y después por nombre.
      expect(vm.paraHoy.map((h) => h.nombre), ['Ejercicio', 'Dormir 7 h', 'Leer', 'Tomar agua', 'Estudiar inglés']);
      expect(vm.sugerencia!.habitoNombre, 'Leer');
      expect(vm.tieneCapsula(habito('Tomar agua').id), isTrue);
      expect(vm.tieneCapsula(habito('Leer').id), isFalse);
    });

    test('la semana va de lunes a domingo; los días que no llegan van en null', () {
      final semana = vm.nivelesSemana;
      expect(semana, hasLength(7));
      expect(semana.sublist(0, 3).every((n) => n != null && n >= 0 && n <= 4), isTrue, reason: 'L, Ma, Mi');
      expect(semana.sublist(3), everyElement(isNull), reason: 'J a D aún no llegan');
    });

    test('el mes trae del 1 a hoy, nunca días futuros', () {
      final mes = vm.nivelesMes;
      expect(mes.keys, isNotEmpty);
      expect(mes.keys.every((dia) => dia >= 1 && dia <= 25), isTrue);
      expect(mes.values.every((n) => n >= 0 && n <= 4), isTrue);
    });

    test('"N de M" cuenta solo los programados hoy; "N por semana" se lista pero no cuenta', () async {
      datos.usuarioActual = 'u-latam';
      final latam = crear();
      await latam.cargar.ejecutar();
      final ahorrar = latam.habitos.firstWhere((h) => h.nombre == 'Ahorrar');
      expect(ahorrar.frecuencia, isA<NPorSemana>());
      expect(latam.paraHoy, contains(ahorrar));
      expect(latam.totalHoy, 2, reason: 'Leer y Tomar agua; Ahorrar (3 por semana) no cuenta');
      latam.dispose();
    });

    test('un hábito de L-V no aparece en sábado', () async {
      DateTime reloj() => DateTime(2026, 11, 28, 10);
      final otro = Dependencias.fake(datos: DatosDemo(reloj: reloj)..usuarioActual = 'u-demo');
      final sabado = HoyViewModel(
        habitos: otro.habitos,
        registros: otro.registros,
        progreso: otro.progreso,
        escalera: otro.escalera,
        capsulas: otro.capsulas,
        reloj: reloj,
      );
      await sabado.cargar.ejecutar();
      expect(sabado.paraHoy.map((h) => h.nombre), isNot(contains('Estudiar inglés')));
      expect(sabado.totalHoy, 4);
      sabado.dispose();
    });

    test('si el servidor falla (no por red), la carga falla', () async {
      final otro = crear();
      datos.fallarSiguiente(const ErrorApp(TipoError.errorInterno));
      await otro.cargar.ejecutar();
      expect(otro.cargado, isFalse);
      expect(otro.cargar.error!.tipo, TipoError.errorInterno);
      otro.dispose();
    });

    test('sin conexión, carga la copia guardada (Paso 8)', () async {
      (d.monitor as MonitorConexionManual).hayRed = false;
      final otro = crear();
      await otro.cargar.ejecutar();
      expect(otro.cargado, isTrue);
      expect(otro.totalHoy, 5);
      expect(otro.cumplidosHoy, 2);
      expect(otro.sugerencia, isNull, reason: 'la Escalera necesita al servidor');
      otro.dispose();
    });

    test('sin conexión y sin copia guardada, la carga falla', () async {
      final nuevos = Dependencias.fake(
        datos: DatosDemo(reloj: () => _ahora)..usuarioActual = 'u-demo',
        monitor: MonitorConexionManual(hayRed: false),
      );
      final otro = HoyViewModel(
        habitos: nuevos.habitos,
        registros: nuevos.registros,
        progreso: nuevos.progreso,
        escalera: nuevos.escalera,
        capsulas: nuevos.capsulas,
        reloj: () => _ahora,
      );
      await otro.cargar.ejecutar();
      expect(otro.cargado, isFalse);
      expect(otro.cargar.error!.tipo, TipoError.sinConexion);
      otro.dispose();
    });

    test('si fallan la sugerencia o el progreso, la pantalla se muestra igual sin esa parte', () async {
      final escalera = _EscaleraRota();
      when(escalera.sugerencias).thenAnswer((_) async => const Result.fallo(ErrorApp(TipoError.servicioNoDisponible)));
      final progreso = _ProgresoRoto();
      when(() => progreso.obtener(any(), fecha: any(named: 'fecha')))
          .thenAnswer((_) async => const Result.fallo(ErrorApp(TipoError.sinConexion)));
      final otro = crear(escalera: escalera, progreso: progreso);
      await otro.cargar.ejecutar();
      expect(otro.cargado, isTrue);
      expect(otro.totalHoy, 5);
      expect(otro.sugerencia, isNull);
      expect(otro.nivelesMes, isEmpty);
      expect(otro.nivelesSemana.sublist(0, 3), everyElement(0));
      otro.dispose();
    });
  });

  group('check-in de un toque', () {
    test('marcar sube la racha al instante y queda guardado en el servidor', () async {
      final leer = habito('Leer');
      expect(leer.hoy!.cumplido, isFalse);
      final antes = leer.racha.actual;

      final f = vm.alternar(leer);
      // Optimista: antes de que conteste el servidor.
      expect(habito('Leer').hoy!.cumplido, isTrue);
      expect(habito('Leer').racha.actual, antes + 1);
      expect(vm.enviando(leer.id), isTrue);
      expect(vm.cumplidosHoy, 3);

      expect(await f, isNull);
      expect(vm.enviando(leer.id), isFalse);
      expect(habito('Leer').racha.actual, antes + 1, reason: 'la racha que confirma el servidor');
      expect(datos.registros[leer.id]![DateTime.utc(2026, 11, 25)]!.cumplido, isTrue);
    });

    test('desmarcar baja la racha y reusa el id del check-in de hoy', () async {
      final agua = habito('Tomar agua');
      final idHoy = agua.hoy!.registro!.id;
      final antes = agua.racha.actual;
      expect(await vm.alternar(agua), isNull);
      expect(habito('Tomar agua').hoy!.cumplido, isFalse);
      expect(habito('Tomar agua').racha.actual, antes - 1);
      expect(habito('Tomar agua').hoy!.registro!.id, idHoy);
      expect(datos.registros[agua.id]![DateTime.utc(2026, 11, 25)]!.id, idHoy);
    });

    test('si el servidor lo rechaza, vuelve a como estaba y devuelve el error', () async {
      final leer = habito('Leer');
      datos.fallarSiguiente(DatosDemo.error(TipoError.habitoArchivado, 409, 'El hábito está archivado'));
      final error = await vm.alternar(leer);
      expect(error!.tipo, TipoError.habitoArchivado);
      expect(habito('Leer'), leer);
      expect(vm.cumplidosHoy, 2);
      expect(datos.registros[leer.id]?[DateTime.utc(2026, 11, 25)], isNull);
    });

    test('marcar, desmarcar y volver a marcar deja un solo registro de hoy (idempotente)', () async {
      final leer = habito('Leer');
      final total = datos.totalRegistros;
      await vm.alternar(leer);
      final id = habito('Leer').hoy!.registro!.id;
      await vm.alternar(habito('Leer'));
      await vm.alternar(habito('Leer'));
      expect(datos.totalRegistros, total + 1);
      expect(datos.registros[leer.id]![DateTime.utc(2026, 11, 25)]!.id, id);
      expect(habito('Leer').hoy!.cumplido, isTrue);
    });

    test('un segundo toque mientras se envía se ignora', () async {
      final leer = habito('Leer');
      final f1 = vm.alternar(leer);
      final f2 = vm.alternar(habito('Leer'));
      await Future.wait([f1, f2]);
      expect(habito('Leer').hoy!.cumplido, isTrue, reason: 'el segundo toque no lo desmarcó');
    });

    test('el progreso de la semana se refresca después del check-in', () async {
      final antes = vm.nivelesSemana[2];
      for (final nombre in ['Leer', 'Estudiar inglés', 'Dormir 7 h']) {
        await vm.alternar(habito(nombre));
      }
      expect(vm.cumplidosHoy, 5);
      expect(vm.nivelesSemana[2], 4, reason: '100 % hoy (miércoles)');
      expect(vm.nivelesMes[25], 4);
      expect(antes, lessThan(4));
    });
  });

  group('sin conexión (Paso 8)', () {
    test('el check-in se queda marcado y en la cola; al volver la red se envía una sola vez', () async {
      final monitor = d.monitor as MonitorConexionManual;
      final leer = habito('Leer');
      final antes = leer.racha.actual;
      final total = datos.totalRegistros;
      monitor.hayRed = false;

      expect(await vm.alternar(leer), isNull, reason: 'sin red no es un error: queda guardado');
      expect(habito('Leer').hoy!.cumplido, isTrue);
      expect(habito('Leer').racha.actual, antes + 1, reason: 'racha estimada');
      expect(datos.totalRegistros, total, reason: 'el servidor aún no lo tiene');
      expect(await d.almacenLocal.pendientes(), hasLength(1));

      // La pantalla se recarga sin red: lo marcado sigue ahí.
      await vm.cargar.ejecutar();
      expect(habito('Leer').hoy!.cumplido, isTrue);
      expect(vm.cumplidosHoy, 3);

      d.sincronizador.haySesion = () => true;
      monitor.hayRed = true;
      expect(await d.sincronizador.sincronizar(), 1);
      expect(await d.almacenLocal.pendientes(), isEmpty);
      expect(datos.totalRegistros, total + 1);
      final enviado = datos.registros[leer.id]![DateTime.utc(2026, 11, 25)]!;
      expect(enviado.origen, OrigenRegistro.offline);
      expect(enviado.id, habito('Leer').hoy!.registro!.id);

      // Ya con red, la lista del servidor coincide con lo que se veía.
      await vm.cargar.ejecutar();
      expect(habito('Leer').racha.actual, antes + 1);
      expect(vm.cumplidosHoy, 3);
    });

    test('marcar y desmarcar sin red deja un solo pendiente (el último)', () async {
      (d.monitor as MonitorConexionManual).hayRed = false;
      await vm.alternar(habito('Leer'));
      await vm.alternar(habito('Leer'));
      final cola = await d.almacenLocal.pendientes();
      expect(cola, hasLength(1));
      expect(cola.single.cumplido, isFalse);
      expect(habito('Leer').hoy!.cumplido, isFalse);
    });
  });

  group('sugerencia de la Escalera', () {
    test('aceptar sube el nivel y la meta, y la sugerencia desaparece', () async {
      final leer = habito('Leer');
      await vm.responder.ejecutar(true);
      final r = vm.responder.resultado!.valorONulo!;
      expect(r.metaNueva, 11);
      expect(r.nivel, leer.nivel + 1);
      expect(vm.sugerencia, isNull);
      expect(habito('Leer').meta, 11);
      expect(habito('Leer').nivel, leer.nivel + 1);
    });

    test('mantener deja la meta igual y quita la sugerencia', () async {
      await vm.responder.ejecutar(false);
      expect(vm.responder.resultado!.esExito, isTrue);
      expect(vm.sugerencia, isNull);
      expect(habito('Leer').meta, 10);
    });

    test('si ya estaba resuelta (409), también se quita', () async {
      final s = vm.sugerencia!;
      datos.sugerencias[s.id] = Sugerencia(
        id: s.id,
        habitoId: s.habitoId,
        habitoNombre: s.habitoNombre,
        tipo: s.tipo,
        metaActual: s.metaActual,
        metaPropuesta: s.metaPropuesta,
        cumplimiento14d: s.cumplimiento14d,
        estado: EstadoSugerencia.aceptada,
        creadaEn: s.creadaEn,
      );
      await vm.responder.ejecutar(true);
      expect(vm.responder.error!.tipo, TipoError.sugerenciaResuelta);
      expect(vm.sugerencia, isNull);
    });

    test('con otro error la sugerencia se queda para reintentar', () async {
      datos.fallarSiguiente(const ErrorApp(TipoError.sinConexion));
      await vm.responder.ejecutar(true);
      expect(vm.responder.error!.tipo, TipoError.sinConexion);
      expect(vm.sugerencia, isNotNull);
    });

    test('sin sugerencia, responder no llama al servidor', () async {
      await vm.responder.ejecutar(false);
      await vm.responder.ejecutar(true);
      expect(vm.responder.error!.tipo, TipoError.noEncontrado);
    });
  });

  test('"hoy" es el día local aunque en UTC ya sea mañana', () async {
    final noche = HoyViewModel(
      habitos: d.habitos,
      registros: d.registros,
      progreso: d.progreso,
      escalera: d.escalera,
      capsulas: d.capsulas,
      reloj: () => DateTime(2026, 11, 25, 23, 50),
    );
    expect(noche.hoy, Fechas.soloFecha(DateTime(2026, 11, 25)));
    noche.dispose();
  });
}
