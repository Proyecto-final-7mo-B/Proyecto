import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/config/dependencias.dart';
import 'package:kaizen/data/fake/datos_demo.dart';
import 'package:kaizen/data/repositories/registros/registros_repository.dart';
import 'package:kaizen/data/services/api/errores_api.dart';
import 'package:kaizen/data/services/recordatorios/servicio_recordatorios.dart';
import 'package:kaizen/data/sync/monitor_conexion.dart';
import 'package:kaizen/data/sync/sincronizador.dart';
import 'package:kaizen/domain/models/evidencia.dart';
import 'package:kaizen/domain/models/frecuencia.dart';
import 'package:kaizen/domain/models/habito.dart';
import 'package:kaizen/domain/models/registro.dart';
import 'package:kaizen/routing/estado_sesion.dart';
import 'package:kaizen/utils/result.dart';

/// Miércoles 25-nov-2026, 9:30.
final DateTime _ahora = DateTime(2026, 11, 25, 9, 30);
final DateTime _hoy = DateTime.utc(2026, 11, 25);

/// Cuenta los lotes que llegan al "servidor".
class _ContarLotes implements RegistrosRepository {
  _ContarLotes(this._real);

  final RegistrosRepository _real;
  final List<int> lotes = [];

  @override
  Future<Result<ResultadoCheckin>> registrar(NuevoRegistro r) => _real.registrar(r);

  @override
  Future<Result<ResultadoLote>> registrarLote(List<NuevoRegistro> r) {
    lotes.add(r.length);
    return _real.registrarLote(r);
  }
}

void main() {
  late DatosDemo datos;
  late MonitorConexionManual red;
  late Dependencias d;

  String idDe(String nombre) => datos.habitosDe('u-demo').firstWhere((h) => h.nombre == nombre).id;

  NuevoRegistro checkin(String habitoId, {DateTime? fecha, bool cumplido = true, String? id}) => NuevoRegistro(
    id: id ?? datos.nuevoId(),
    habitoId: habitoId,
    fecha: fecha ?? _hoy,
    cumplido: cumplido,
    origen: OrigenRegistro.rapido,
  );

  setUp(() {
    datos = DatosDemo(reloj: () => _ahora)..usuarioActual = 'u-demo';
    red = MonitorConexionManual();
    d = Dependencias.fake(datos: datos, monitor: red);
    d.sincronizador.haySesion = () => true;
  });

  group('lecturas con copia local', () {
    test('categorías: del servidor y, sin red, de la copia; sin copia, el error', () async {
      red.hayRed = false;
      expect((await d.categorias.listar()).errorONulo!.tipo, TipoError.sinConexion, reason: 'nunca se guardó');
      red.hayRed = true;
      expect((await d.categorias.listar()).valorONulo, hasLength(5));
      red.hayRed = false;
      final copia = (await d.categorias.listar()).valorONulo!;
      expect(copia.map((c) => c.clave), ['ejercicio', 'salud', 'educacion', 'bienestar', 'finanzas']);
      expect(copia.expand((c) => c.subcategorias), hasLength(22), reason: 'el árbol completo, para evaluar sin red');
    });

    test('hábitos sin red: la copia conserva el orden por prioridad, la intención y la evaluación', () async {
      await d.habitos.listar(fecha: _hoy);
      red.hayRed = false;
      final copia = (await d.habitos.listar(fecha: _hoy)).valorONulo!;
      expect(copia.map((h) => h.nombre), ['Ejercicio', 'Dormir 7 h', 'Leer', 'Tomar agua', 'Estudiar inglés']);
      final leer = copia.firstWhere((h) => h.nombre == 'Leer');
      expect(leer.intencion, 'Antes de dormir');
      expect(leer.evaluacion!.zona, ZonaEvidencia.bajo);
      expect(leer.subcategoria.clave, 'lectura');
      expect(leer.categoria.color, '#2563EB');
    });

    test('un error que no es de red no usa la copia', () async {
      await d.categorias.listar();
      datos.fallarSiguiente(const ErrorApp(TipoError.errorInterno));
      expect((await d.categorias.listar()).errorONulo!.tipo, TipoError.errorInterno);
    });

    test('hábitos sin red: la copia, con "hoy" recalculado para otro día', () async {
      await d.habitos.listar(fecha: _hoy);
      red.hayRed = false;
      final hoy = (await d.habitos.listar(fecha: _hoy)).valorONulo!;
      expect(hoy.where((h) => h.hoy!.cumplido).length, 2);
      final manana = (await d.habitos.listar(fecha: _hoy.add(const Duration(days: 1)))).valorONulo!;
      expect(manana.every((h) => !h.hoy!.cumplido), isTrue);
      expect(manana.every((h) => h.hoy!.fecha == _hoy.add(const Duration(days: 1))), isTrue);
      final leer = (await d.habitos.obtener(idDe('Leer'), fecha: _hoy)).valorONulo!;
      expect(leer.nombre, 'Leer');
      expect((await d.habitos.obtener('no-guardado', fecha: _hoy)).errorONulo!.tipo, TipoError.sinConexion);
    });

    test('crear, editar y la Escalera necesitan al servidor', () async {
      red.hayRed = false;
      final r = await d.habitos.crear(
        NuevoHabito(
          nombre: 'X',
          subcategoriaId: datos.subcategoriaPorClave('frutas_verduras').id,
          frecuencia: const Diaria(),
          meta: 1,
          unidad: 'porciones',
        ),
      );
      expect(r.errorONulo!.tipo, TipoError.sinConexion);
      expect((await d.habitos.escalera(idDe('Leer'))).errorONulo!.tipo, TipoError.sinConexion);
      expect(d.sincronizador.enLinea, isFalse);
    });

    test('crear y editar con red guardan la copia', () async {
      final h = (await d.habitos.crear(
        NuevoHabito(
          nombre: 'Correr',
          subcategoriaId: datos.subcategoriaPorClave('aerobico_moderado').id,
          frecuencia: const Diaria(),
          meta: 3,
          unidad: 'km',
        ),
      )).valorONulo!;
      await d.habitos.actualizar(h.id, const CambiosHabito(nombre: 'Trotar'));
      expect((await d.almacenLocal.habito(h.id))!.nombre, 'Trotar');
    });

    test('check-ins del detalle: con red, lo del servidor más lo pendiente; sin red, la copia', () async {
      final leer = idDe('Leer');
      await d.habitos.registros(leer, desde: _hoy.subtract(const Duration(days: 30)), hasta: _hoy);
      red.hayRed = false;
      await d.registros.registrar(checkin(leer));
      final sinRed = (await d.habitos.registros(leer, desde: _hoy, hasta: _hoy)).valorONulo!;
      expect(sinRed.single.cumplido, isTrue);
      red.hayRed = true;
      d.sincronizador.haySesion = () => false; // que no se envíe todavía
      final conRed = (await d.habitos.registros(
        leer,
        desde: _hoy.subtract(const Duration(days: 2)),
        hasta: _hoy,
      )).valorONulo!;
      expect(conRed.last.fecha, _hoy);
      expect(conRed.last.cumplido, isTrue, reason: 'el pendiente aparece aunque el servidor aún no lo tenga');
      expect(conRed.map((r) => r.fecha).toSet(), hasLength(conRed.length), reason: 'uno por día');
    });
  });

  group('check-in', () {
    test('con red: llega, no queda en la cola y la copia toma la racha real', () async {
      await d.habitos.listar(fecha: _hoy);
      final leer = idDe('Leer');
      final r = await d.registros.registrar(checkin(leer));
      expect(r.valorONulo!.rachaActual, 35);
      expect(await d.almacenLocal.pendientes(), isEmpty);
      expect((await d.almacenLocal.habito(leer))!.racha.actual, 35);
    });

    test('sin red: queda guardado y en la cola, con la racha estimada', () async {
      await d.habitos.listar(fecha: _hoy);
      red.hayRed = false;
      final r = await d.registros.registrar(checkin(idDe('Leer')));
      expect(r.esExito, isTrue);
      expect(r.valorONulo!.rachaActual, 35);
      expect(await d.almacenLocal.pendientes(), hasLength(1));
    });

    test('rechazado por el servidor: se quita de la cola y vuelve el check-in que había', () async {
      final agua = idDe('Tomar agua');
      final antes = await d.habitos.registros(agua, desde: _hoy, hasta: _hoy);
      final idAntes = antes.valorONulo!.single.id;
      datos.habitos[agua]!.activo = false;
      final r = await d.registros.registrar(checkin(agua, cumplido: false));
      expect(r.errorONulo!.tipo, TipoError.habitoArchivado);
      expect(await d.almacenLocal.pendientes(), isEmpty);
      expect((await d.almacenLocal.registro(agua, _hoy))!.id, idAntes);
    });
  });

  group('sincronizador', () {
    test('al volver la red envía la cola sola; el mismo check-in llega una vez', () async {
      await d.sincronizador.iniciar();
      await d.habitos.listar(fecha: _hoy); // la copia local de los hábitos
      final leer = idDe('Leer');
      final total = datos.totalRegistros;
      red.hayRed = false;
      final id = datos.nuevoId();
      await d.registros.registrar(checkin(leer, id: id));
      await d.registros.registrar(checkin(leer, id: id)); // el mismo check-in otra vez
      await pumpEventQueue();
      expect(d.sincronizador.pendientes, 1);
      expect(d.sincronizador.mostrarAviso, isTrue);

      red.hayRed = true; // el monitor avisa y el sincronizador envía
      await pumpEventQueue();
      await d.sincronizador.sincronizar();
      await pumpEventQueue();
      expect(datos.totalRegistros, total + 1);
      expect(datos.registros[leer]![_hoy]!.origen, OrigenRegistro.offline);
      expect(d.sincronizador.pendientes, 0);
      expect(d.sincronizador.mostrarAviso, isFalse);
      expect((await d.almacenLocal.habito(leer))!.racha.actual, 35);
      d.sincronizador.dispose();
    });

    test('lotes de máximo 100 y fechas atrasadas con su fecha original', () async {
      final lotes = _ContarLotes(d.registros);
      final sync = Sincronizador(almacen: d.almacenLocal, remoto: lotes, monitor: red, reintento: null)
        ..haySesion = () => true;
      final leer = idDe('Leer');
      for (var i = 0; i < 250; i++) {
        await d.almacenLocal.guardarYEncolar(
          checkin(
            leer,
            fecha: _hoy.subtract(Duration(days: i % 50)),
            id: 'x$i',
          ),
        );
      }
      // Uno por hábito y día: quedan 50 (los últimos de cada día).
      expect(await d.almacenLocal.pendientes(limite: 1000), hasLength(50));
      for (var i = 0; i < 120; i++) {
        await d.almacenLocal.guardarYEncolar(
          checkin(
            idDe('Ejercicio'),
            fecha: _hoy.subtract(Duration(days: i)),
            id: 'e$i',
          ),
        );
      }
      final aceptados = await sync.sincronizar();
      expect(lotes.lotes, [100, 70]);
      expect(await d.almacenLocal.pendientes(), isEmpty);
      // Los días antes de crear el hábito los rechaza el servidor (fecha fuera de rango).
      expect(aceptados, lessThanOrEqualTo(170));
      expect(datos.registros[leer]![_hoy.subtract(const Duration(days: 49))]!.origen, OrigenRegistro.offline);
      sync.dispose();
    });

    test('rechazados: se marcan con su motivo, se avisan una vez y no se reintentan', () async {
      final agua = idDe('Tomar agua');
      red.hayRed = false;
      await d.registros.registrar(checkin(agua, cumplido: false));
      datos.habitos[agua]!.activo = false;
      red.hayRed = true;
      final avisos = <List<Rechazo>>[];
      final sub = d.sincronizador.rechazos.listen(avisos.add);
      expect(await d.sincronizador.sincronizar(), 0);
      await pumpEventQueue();
      expect(avisos.single.single.motivo, 'habito-archivado');
      expect(await d.almacenLocal.pendientes(), isEmpty, reason: 'ya no se reintenta');
      expect(await d.almacenLocal.registro(agua, _hoy), isNull, reason: 'su check-in local se quita');
      expect(await d.sincronizador.sincronizar(), 0);
      expect(avisos, hasLength(1));
      await sub.cancel();
    });

    test('si el envío falla por red, todo se queda y se anota el intento', () async {
      red.hayRed = false;
      await d.registros.registrar(checkin(idDe('Leer')));
      red.hayRed = true;
      datos.fallarSiguiente(const ErrorApp(TipoError.servicioNoDisponible));
      expect(await d.sincronizador.sincronizar(), 0);
      expect(d.sincronizador.enLinea, isFalse);
      final f = await d.base.select(d.base.colaPendientes).getSingle();
      expect(f.intentos, 1);
      expect(f.ultimoError, 'servicioNoDisponible');
      expect(await d.sincronizador.sincronizar(), 1, reason: 'el siguiente intento sí llega');
      expect(d.sincronizador.enLinea, isTrue);
    });

    test('sin sesión o sin red no envía nada', () async {
      red.hayRed = false;
      await d.registros.registrar(checkin(idDe('Leer')));
      expect(await d.sincronizador.sincronizar(), 0);
      red.hayRed = true;
      d.sincronizador.haySesion = () => false;
      expect(await d.sincronizador.sincronizar(), 0);
      expect(await d.almacenLocal.pendientes(), hasLength(1));
    });

    test('dos llamadas al mismo tiempo hacen un solo envío', () async {
      final lotes = _ContarLotes(d.registros);
      final sync = Sincronizador(almacen: d.almacenLocal, remoto: lotes, monitor: red, reintento: null)
        ..haySesion = () => true;
      await d.almacenLocal.guardarYEncolar(checkin(idDe('Leer')));
      final f1 = sync.sincronizar();
      final f2 = sync.sincronizar();
      expect(sync.sincronizando, isTrue);
      expect(await f1, await f2);
      expect(lotes.lotes, [1]);
      sync.dispose();
    });

    test('reintenta solo cada cierto tiempo mientras haya pendientes', () async {
      final sync = Sincronizador(
        almacen: d.almacenLocal,
        remoto: d.registros,
        monitor: red,
        reintento: const Duration(milliseconds: 30),
      )..haySesion = () => true;
      await sync.iniciar();
      datos.fallarSiguiente(const ErrorApp(TipoError.servicioNoDisponible));
      await d.almacenLocal.guardarYEncolar(checkin(idDe('Leer')));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(await d.almacenLocal.pendientes(), isEmpty);
      expect(sync.pendientes, 0);
      sync.dispose();
    });
  });

  group('sesión y recordatorios', () {
    test('al salir se envía lo pendiente y se borra la base local', () async {
      final estado = EstadoSesion();
      final servicio = d.crearServicioSesion(estado);
      await servicio.entrar(email: 'demo@kaizen.test', contrasena: DatosDemo.contrasenaDemo);
      await d.habitos.listar(fecha: _hoy);
      red.hayRed = false;
      await d.registros.registrar(checkin(idDe('Leer')));
      red.hayRed = true;
      final total = datos.totalRegistros;
      await servicio.salir();
      expect(datos.totalRegistros, total + 1, reason: 'se envió antes de salir');
      expect(await d.almacenLocal.habitos(incluyeArchivados: true), isEmpty);
      expect(await d.almacenLocal.hayHabitosGuardados(), isFalse);
      expect(estado.usuario, isNull);
      await servicio.cerrar();
    });

    test('los recordatorios se copian a la tabla local', () async {
      final interno = ServicioRecordatoriosEnMemoria();
      final conCopia = Dependencias.fake(datos: datos, recordatorios: interno);
      final s = conCopia.recordatorios;
      await s.programar(
        habitoId: 'h1',
        titulo: 'K',
        cuerpo: 'x',
        hora: (hora: 7, minuto: 30),
        frecuencia: const Diaria(),
      );
      expect(await conCopia.almacenLocal.recordatorio('h1'), (hora: 7, minuto: 30));
      interno.programados.clear(); // p. ej., el sistema aún no los reporta
      expect(await s.hora('h1'), (hora: 7, minuto: 30));
      await s.cancelar('h1');
      expect(await conCopia.almacenLocal.recordatorio('h1'), isNull);
      interno.permisoConcedido = false;
      expect(
        await s.programar(
          habitoId: 'h1',
          titulo: 'K',
          cuerpo: 'x',
          hora: (hora: 8, minuto: 0),
          frecuencia: const Diaria(),
        ),
        isFalse,
      );
      expect(await conCopia.almacenLocal.recordatorio('h1'), isNull);
      final sinPlataforma = Dependencias.fake(recordatorios: ServicioRecordatoriosEnMemoria(disponible: false));
      expect(sinPlataforma.recordatorios.disponible, isFalse);
    });
  });
}
