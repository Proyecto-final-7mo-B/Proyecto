import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/config/dependencias.dart';
import 'package:kaizen/data/fake/datos_demo.dart';
import 'package:kaizen/data/repositories/habitos/habitos_repository.dart';
import 'package:kaizen/data/services/api/errores_api.dart';
import 'package:kaizen/data/services/recordatorios/servicio_recordatorios.dart';
import 'package:kaizen/domain/models/escalera.dart';
import 'package:kaizen/domain/models/evidencia.dart';
import 'package:kaizen/domain/models/frecuencia.dart';
import 'package:kaizen/domain/models/habito.dart';
import 'package:kaizen/domain/models/registro.dart';
import 'package:kaizen/ui/habitos/view_models/detalle_habito_viewmodel.dart';
import 'package:kaizen/ui/habitos/view_models/formulario_habito_viewmodel.dart';
import 'package:kaizen/ui/habitos/view_models/habitos_viewmodel.dart';
import 'package:kaizen/utils/result.dart';

/// Miércoles 25-nov-2026, 9:30.
final DateTime _ahora = DateTime(2026, 11, 25, 9, 30);
final DateTime _hoy = DateTime.utc(2026, 11, 25);

/// Repositorio que cuenta las llamadas a `actualizar` y guarda los cambios que recibió.
class _HabitosEspia implements HabitosRepository {
  _HabitosEspia(this._real);

  final HabitosRepository _real;
  final List<CambiosHabito> actualizaciones = [];
  int creados = 0;
  bool fallarEscalera = false;

  @override
  Future<Result<List<Habito>>> listar({required DateTime fecha, bool archivados = false}) =>
      _real.listar(fecha: fecha, archivados: archivados);
  @override
  Future<Result<Habito>> obtener(String id, {required DateTime fecha}) => _real.obtener(id, fecha: fecha);
  @override
  Future<Result<Habito>> crear(NuevoHabito nuevo) {
    creados++;
    return _real.crear(nuevo);
  }

  @override
  Future<Result<Habito>> actualizar(String id, CambiosHabito cambios) {
    actualizaciones.add(cambios);
    return _real.actualizar(id, cambios);
  }

  @override
  Future<Result<List<Registro>>> registros(String id, {required DateTime desde, required DateTime hasta}) =>
      _real.registros(id, desde: desde, hasta: hasta);
  @override
  Future<Result<EscaleraHabito>> escalera(String id) async =>
      fallarEscalera ? const Result.fallo(ErrorApp(TipoError.servicioNoDisponible)) : _real.escalera(id);
}

void main() {
  late DatosDemo datos;
  late Dependencias d;
  late _HabitosEspia habitos;
  late ServicioRecordatoriosEnMemoria recordatorios;

  String idDe(String nombre, [String usuario = 'u-demo']) =>
      datos.habitosDe(usuario).firstWhere((h) => h.nombre == nombre).id;
  String sub(String clave) => datos.subcategoriaPorClave(clave).id;

  setUp(() {
    datos = DatosDemo(reloj: () => _ahora)..usuarioActual = 'u-demo';
    d = Dependencias.fake(datos: datos);
    habitos = _HabitosEspia(d.habitos);
    recordatorios = ServicioRecordatoriosEnMemoria();
  });

  FormularioHabitoViewModel formulario({String? id}) => FormularioHabitoViewModel(
    habitos: habitos,
    categorias: d.categorias,
    recordatorios: recordatorios,
    habitoId: id,
    reloj: () => _ahora,
    textos: (titulo: 'Kaizen', cuerpo: (h) => 'Es hora de: $h'),
  );

  group('lista', () {
    test('activos y archivados por separado, por prioridad y después por nombre', () async {
      datos.habitos[idDe('Dormir 7 h')]!.activo = false;
      final vm = HabitosViewModel(habitos: habitos, capsulas: d.capsulas, reloj: () => _ahora);
      await vm.cargar.ejecutar();
      // Ejercicio es de prioridad alta; Estudiar inglés, de baja.
      expect(vm.activos.map((h) => h.nombre), ['Ejercicio', 'Leer', 'Tomar agua', 'Estudiar inglés']);
      expect(vm.archivados.map((h) => h.nombre), ['Dormir 7 h']);
      expect(vm.visibles, vm.activos);
      vm.verArchivados = true;
      expect(vm.visibles.single.nombre, 'Dormir 7 h');
      expect(vm.tieneCapsula(idDe('Tomar agua')), isTrue);
      expect(vm.tieneCapsula(idDe('Leer')), isFalse);
      vm.dispose();
    });

    test('si falla, la carga falla', () async {
      final vm = HabitosViewModel(habitos: habitos, capsulas: d.capsulas, reloj: () => _ahora);
      datos.fallarSiguiente(const ErrorApp(TipoError.sinConexion));
      await vm.cargar.ejecutar();
      expect(vm.cargado, isFalse);
      expect(vm.cargar.error!.tipo, TipoError.sinConexion);
      vm.dispose();
    });
  });

  group('crear', () {
    late FormularioHabitoViewModel vm;
    setUp(() async {
      vm = formulario();
      await vm.cargar.ejecutar();
    });
    tearDown(() => vm.dispose());

    test('valores iniciales: catálogo de 5 categorías, diario, prioridad media, Escalera encendida, sin cápsula', () {
      expect(vm.categorias.map((c) => c.clave), ['ejercicio', 'salud', 'educacion', 'bienestar', 'finanzas']);
      expect(vm.subcategoria, isNull);
      expect(vm.evaluacion, isNull);
      expect(vm.tipo, TipoFrecuencia.diaria);
      expect(vm.meta, 5);
      expect(vm.unidad, '');
      expect(vm.prioridad, Prioridad.media);
      expect(vm.escaleraActiva, isTrue);
      expect(vm.capsula, isNull);
      expect(vm.recordatorio, isNull);
      expect(vm.escaleraInicial, [5, 5.5, 6.05, 6.66, 7.33]);
    });

    test('guarda con la frecuencia elegida, programa el recordatorio y devuelve la cápsula', () async {
      vm
        ..nombre = '  Leer en inglés '
        ..subcategoriaId = sub('lectura')
        ..unidad = 'páginas'
        ..tipo = TipoFrecuencia.dias
        ..alternarDia(5) // quita el viernes: L-J
        ..meta = 15
        ..prioridad = Prioridad.alta
        ..intencion = ' Antes de dormir '
        ..capsula = 30
        ..recordatorio = (hora: 7, minuto: 30);
      expect(vm.categoria!.clave, 'educacion', reason: 'la categoría sigue a la subcategoría');
      await vm.guardar.ejecutar();
      final g = vm.guardar.resultado!.valorONulo!;
      expect(g.habito.nombre, 'Leer en inglés');
      expect(g.habito.subcategoria.clave, 'lectura');
      expect(g.habito.frecuencia, const DiasSemana(15));
      expect(g.habito.meta, 15);
      expect(g.habito.unidad, 'páginas');
      expect(g.habito.nivel, 1);
      expect(g.habito.prioridad, Prioridad.alta);
      expect(g.habito.intencion, 'Antes de dormir');
      expect(g.capsula, 30);
      expect(g.recordatorioNegado, isFalse);
      final r = recordatorios.programados[g.habito.id]!;
      expect(r.hora, (hora: 7, minuto: 30));
      expect(r.frecuencia, const DiasSemana(15));
      expect(r.cuerpo, 'Antes de dormir: Leer en inglés', reason: 'el aviso lleva la señal "Después de ___"');
    });

    test('al elegir subcategoría: unidad permitida y meta en el inicio de lo recomendado', () {
      vm.subcategoriaId = sub('aerobico_moderado');
      expect(vm.unidades.map((u) => u.unidad), ['min', 'h', 'km']);
      expect((vm.unidad, vm.meta), ('min', 25), reason: '150 min/semana ÷ 7 = 21.4 → 25 (paso de 5)');
      expect(vm.pasoMeta, 5);
      expect(vm.evaluacion!.zona, ZonaEvidencia.optimo);
      vm.unidad = 'h';
      expect(vm.meta, 0.5, reason: '21.4 min = 0.36 h → 0.5 (paso de 0.25)');
      vm.subcategoriaId = sub('hidratacion');
      expect((vm.unidad, vm.meta), ('L', 1.5));
      vm.unidad = 'vasos';
      expect(vm.meta, 6, reason: '1.5 L ÷ 0.25 L por vaso');
      vm.subcategoriaId = sub('reducir_azucar');
      expect((vm.unidad, vm.meta), ('g', 25), reason: 'reducir: arranca en el límite recomendado');
      vm.subcategoriaId = sub('ahorro');
      expect((vm.unidad, vm.meta, vm.evaluacion!.zona), ('pesos', 10, ZonaEvidencia.sinReferencia));
    });

    test('evaluación en vivo: 2 h diarias de ejercicio es excesivo y "Usar X" pone el tope', () {
      vm
        ..subcategoriaId = sub('aerobico_moderado')
        ..meta = 120;
      expect(vm.evaluacion!.zona, ZonaEvidencia.excesivo);
      expect(vm.evaluacion!.metaSugerida, 85);
      expect(vm.escaleraInicial, [120], reason: 'no se proyecta subir más');
      vm.usarSugerida();
      expect(vm.meta, 85);
      expect(vm.evaluacion!.zona, ZonaEvidencia.alto, reason: '595 min/semana: dentro del máximo de 600');
      vm.tipo = TipoFrecuencia.veces;
      vm.veces = 3;
      expect(vm.evaluacion!.zona, ZonaEvidencia.optimo, reason: '85 × 3 = 255 min/semana');
    });

    test('escalera inicial como la Escalera v2: al paso de la unidad y sin pasar del óptimo', () {
      vm
        ..subcategoriaId = sub('lectura')
        ..meta = 10;
      expect(vm.evaluacion!.zona, ZonaEvidencia.bajo);
      expect(vm.escaleraInicial, [10, 15, 20, 25, 30]);
      vm.meta = 35;
      expect(vm.escaleraInicial, [35], reason: '245 min/semana ya está en el óptimo: ritmo ideal');
      vm
        ..subcategoriaId = sub('sueno')
        ..meta = 6.75;
      expect(vm.escaleraInicial, [6.75, 7.5, 8.25, 9], reason: 'se detiene en el fin del óptimo (9 h)');
      vm.subcategoriaId = sub('dejar_fumar');
      expect(vm.escaleraInicial, [vm.meta], reason: 'reducir: la meta es un límite, no se proyecta subir');
    });

    test('km no se compara con la OMS: sugiere minutos', () {
      vm
        ..subcategoriaId = sub('aerobico_moderado')
        ..unidad = 'km';
      expect(vm.evaluacion!.zona, ZonaEvidencia.sinReferencia);
      expect(vm.unidadComparable, 'min');
      vm.unidad = 'min';
      expect(vm.unidadComparable, isNull);
    });

    test('elegir otra categoría quita la subcategoría que no es suya', () {
      vm.subcategoriaId = sub('lectura');
      final ejercicio = vm.categorias.firstWhere((c) => c.clave == 'ejercicio');
      vm.categoriaId = ejercicio.id;
      expect(vm.subcategoriaId, isNull);
      expect(vm.opcionesSubcategoria.map((s) => s.clave), contains('pasos'));
      expect(vm.faltaSubcategoria, isTrue);
    });

    test('"N por semana" entre 1 y 7', () async {
      vm
        ..nombre = 'Ahorrar'
        ..subcategoriaId = sub('ahorro')
        ..tipo = TipoFrecuencia.veces
        ..veces = 9;
      expect(vm.veces, 7);
      vm.veces = 0;
      expect(vm.veces, 1);
      vm.veces = 3;
      await vm.guardar.ejecutar();
      expect(vm.guardar.resultado!.valorONulo!.habito.frecuencia, const NPorSemana(3));
    });

    test('sin nombre, sin subcategoría, sin días, con unidad no permitida o intención larga no llama a la API', () async {
      await vm.guardar.ejecutar();
      expect(vm.intentoGuardar, isTrue);
      expect(vm.faltaSubcategoria, isTrue);
      expect(vm.guardar.error!.tipo, TipoError.validacion);
      vm
        ..nombre = 'Leer'
        ..subcategoriaId = sub('lectura')
        ..tipo = TipoFrecuencia.dias;
      for (var dia = 1; dia <= 5; dia++) {
        vm.alternarDia(dia);
      }
      expect(vm.faltanDias, isTrue);
      await vm.guardar.ejecutar();
      vm
        ..unidad = 'km'
        ..alternarDia(1);
      expect(vm.unidadPermitida, isNull);
      await vm.guardar.ejecutar();
      vm
        ..unidad = 'min'
        ..intencion = 'x' * 121;
      await vm.guardar.ejecutar();
      expect(habitos.creados, 0);
    });

    test('subcategoría desactivada mientras tanto (422): recarga el catálogo y quita la elección', () async {
      vm
        ..nombre = 'Leer'
        ..subcategoriaId = sub('lectura');
      datos.desactivarSubcategoria(sub('lectura'));
      await vm.guardar.ejecutar();
      expect(vm.guardar.error!.tipo, TipoError.subcategoriaInactiva);
      expect(vm.subcategoriaId, isNull);
      expect(vm.opcionesSubcategoria.map((s) => s.clave), isNot(contains('lectura')));
    });

    test('permiso de notificaciones negado: el hábito se guarda igual, sin recordatorio', () async {
      recordatorios.permisoConcedido = false;
      vm
        ..nombre = 'Leer'
        ..subcategoriaId = sub('lectura')
        ..recordatorio = (hora: 21, minuto: 0);
      await vm.guardar.ejecutar();
      final g = vm.guardar.resultado!.valorONulo!;
      expect(g.recordatorioNegado, isTrue);
      expect(recordatorios.programados, isEmpty);
      expect(datos.habitos[g.habito.id], isNotNull);
    });

    test('sin recordatorios en la plataforma (escritorio/web) no programa nada', () async {
      recordatorios = ServicioRecordatoriosEnMemoria(disponible: false);
      final otro = formulario();
      await otro.cargar.ejecutar();
      expect(otro.recordatoriosDisponibles, isFalse);
      otro
        ..nombre = 'Leer'
        ..subcategoriaId = sub('lectura')
        ..recordatorio = (hora: 7, minuto: 0);
      await otro.guardar.ejecutar();
      expect(otro.guardar.resultado!.valorONulo!.recordatorioNegado, isFalse);
      expect(recordatorios.programados, isEmpty);
      otro.dispose();
    });

    test('errores del servidor por campo llegan al formulario', () async {
      vm
        ..nombre = 'Leer'
        ..subcategoriaId = sub('lectura');
      datos.fallarSiguiente(DatosDemo.validacion({'nombre': 'Ya tienes un hábito con ese nombre'}));
      await vm.guardar.ejecutar();
      expect(vm.guardar.error!.errorDe('nombre'), 'Ya tienes un hábito con ese nombre');
    });
  });

  group('editar', () {
    late FormularioHabitoViewModel vm;
    late String leer;
    setUp(() async {
      leer = idDe('Leer');
      await recordatorios.programar(
        habitoId: leer,
        titulo: 'Kaizen',
        cuerpo: 'Es hora de: Leer',
        hora: (hora: 21, minuto: 0),
        frecuencia: const Diaria(),
      );
      vm = formulario(id: leer);
      await vm.cargar.ejecutar();
    });
    tearDown(() => vm.dispose());

    test('carga el hábito y su recordatorio', () {
      expect(vm.editando, isTrue);
      expect(vm.nombre, 'Leer');
      expect(vm.subcategoriaId, sub('lectura'));
      expect(vm.categoria!.clave, 'educacion');
      expect(vm.unidad, 'min');
      expect(vm.intencion, 'Antes de dormir');
      expect(vm.prioridad, Prioridad.media);
      expect(vm.meta, 10);
      expect(vm.tipo, TipoFrecuencia.diaria);
      expect(vm.recordatorio, (hora: 21, minuto: 0));
    });

    test('solo manda lo que cambió y nunca meta ni frecuencia', () async {
      vm
        ..nombre = 'Leer novelas'
        ..escaleraActiva = false;
      await vm.guardar.ejecutar();
      final c = habitos.actualizaciones.single;
      expect(c.nombre, 'Leer novelas');
      expect(c.escaleraActiva, isFalse);
      expect(c.subcategoriaId, isNull);
      expect(c.unidad, isNull);
      expect(c.toJson().keys, unorderedEquals(['nombre', 'escalera_activa']));
      expect(vm.guardar.resultado!.valorONulo!.capsula, isNull, reason: 'al editar no se crea cápsula');
      // Cambió el nombre: el recordatorio se reprograma con el texto nuevo (y su intención).
      expect(recordatorios.programados[leer]!.cuerpo, 'Antes de dormir: Leer novelas');
    });

    test('la subcategoría solo cambia a una con la misma unidad; prioridad e intención se pueden quitar', () async {
      expect(vm.opcionesSubcategoria.map((s) => s.clave), ['lectura', 'estudio', 'idiomas']);
      expect(vm.opcionesCategoria.map((c) => c.clave), isNot(contains('finanzas')), reason: 'Finanzas no usa min');
      vm
        ..subcategoriaId = sub('idiomas')
        ..prioridad = Prioridad.baja
        ..intencion = '';
      expect(vm.unidad, 'min', reason: 'al editar la unidad no cambia');
      await vm.guardar.ejecutar();
      expect(habitos.actualizaciones.single.toJson(), {
        'subcategoria_id': sub('idiomas'),
        'prioridad': Prioridad.baja,
        'intencion': null,
      });
      expect(datos.habitos[leer]!.subcategoriaId, sub('idiomas'));
      expect(datos.habitos[leer]!.intencion, isNull);
    });

    test('al editar no hay "Usar X": la meta solo cambia con la Escalera', () {
      final antes = vm.meta;
      vm.usarSugerida();
      expect(vm.meta, antes);
    });

    test('sin cambios no llama a la API', () async {
      await vm.guardar.ejecutar();
      expect(vm.guardar.resultado!.esExito, isTrue);
      expect(habitos.actualizaciones, isEmpty);
    });

    test('quitar el recordatorio lo cancela', () async {
      vm.recordatorio = null;
      await vm.guardar.ejecutar();
      expect(recordatorios.programados, isNot(contains(leer)));
    });

    test('archivar: PATCH activo=false y se apaga el recordatorio', () async {
      await vm.archivar.ejecutar();
      expect(habitos.actualizaciones.single.toJson(), {'activo': false});
      expect(datos.habitos[leer]!.activo, isFalse);
      expect(recordatorios.programados, isNot(contains(leer)));
    });

    test('archivar sin hábito no hace nada', () async {
      final nuevo = formulario();
      await nuevo.archivar.ejecutar();
      expect(nuevo.archivar.error!.tipo, TipoError.noEncontrado);
      nuevo.dispose();
    });

    test('hábito que no existe: la carga falla', () async {
      final otro = formulario(id: 'no-existe');
      await otro.cargar.ejecutar();
      expect(otro.cargado, isFalse);
      expect(otro.cargar.error!.tipo, TipoError.noEncontrado);
      otro.dispose();
    });
  });

  group('detalle', () {
    DetalleHabitoViewModel detalle(String id) =>
        DetalleHabitoViewModel(habitos: habitos, habitoId: id, reloj: () => _ahora);

    test('carga racha, historial (más reciente primero, 7 renglones) y escalera', () async {
      final vm = detalle(idDe('Leer'));
      await vm.cargar.ejecutar();
      expect(vm.habito!.nombre, 'Leer');
      expect(vm.historial, hasLength(DetalleHabitoViewModel.renglonesHistorial));
      expect(vm.historial.first.fecha, DateTime.utc(2026, 11, 24));
      expect(vm.historial.map((r) => r.fecha).toList(), [for (var i = 24; i >= 18; i--) DateTime.utc(2026, 11, i)]);
      expect(vm.escalera!.nivelActual, 3);
      expect(vm.totalNiveles, 5);
      expect(vm.siguienteMeta, 11, reason: 'la sugerencia pendiente');
      vm.dispose();
    });

    test('hoy solo cuenta si ya tiene check-in', () async {
      final vm = detalle(idDe('Leer'));
      await vm.cargar.ejecutar();
      expect(vm.ultimoDiaContable, _hoy.subtract(const Duration(days: 1)));
      expect(vm.cumplimientoMes, 100, reason: 'Leer se cumplió del 1 al 24; hoy aún no cuenta');
      final agua = detalle(idDe('Tomar agua'));
      await agua.cargar.ejecutar();
      expect(agua.ultimoDiaContable, _hoy, reason: 'Tomar agua ya tiene check-in hoy');
      vm.dispose();
      agua.dispose();
    });

    test('cumplimiento de 30 días, su variación y la tendencia de 12 semanas', () async {
      final vm = detalle(idDe('Leer'));
      await vm.cargar.ejecutar();
      expect(vm.cumplimiento30, inInclusiveRange(0, 100));
      expect(vm.variacion30, isNotNull);
      expect(vm.variacion30, vm.variacion30!.roundToDouble());
      expect(vm.tendencia, hasLength(DetalleHabitoViewModel.semanasTendencia));
      vm.dispose();
    });

    test('meses: hacia atrás hasta que hay datos, nunca después del actual', () async {
      final vm = detalle(idDe('Leer'));
      await vm.cargar.ejecutar();
      expect(vm.mes, DateTime.utc(2026, 11));
      expect(vm.puedeAvanzar, isFalse);
      vm.mesSiguiente();
      expect(vm.mes, DateTime.utc(2026, 11));
      vm.mesAnterior();
      expect(vm.mes, DateTime.utc(2026, 10));
      expect(vm.nivelesMes, isNotEmpty);
      for (var i = 0; i < 20; i++) {
        vm.mesAnterior();
      }
      expect(vm.puedeRetroceder, isFalse);
      expect(vm.mes.isAfter(DateTime.utc(2025, 11)), isTrue, reason: 'máximo un año (y desde que se creó)');
      vm.mesSiguiente();
      expect(vm.puedeRetroceder, isTrue);
      vm.dispose();
    });

    test('un hábito recién creado no tiene variación ni tendencia larga', () async {
      final r = await habitos.crear(
        NuevoHabito(
          nombre: 'Nuevo',
          subcategoriaId: sub('frutas_verduras'),
          frecuencia: const Diaria(),
          meta: 1,
          unidad: 'porciones',
        ),
      );
      final vm = detalle(r.valorONulo!.id);
      await vm.cargar.ejecutar();
      expect(vm.historial, isEmpty);
      expect(vm.variacion30, isNull);
      expect(vm.cumplimiento30, isNull);
      expect(vm.cumplimientoMes, isNull);
      expect(vm.puedeRetroceder, isFalse);
      expect(vm.tendencia, isEmpty);
      vm.dispose();
    });

    test('en el óptimo de la evidencia no hay siguiente micro-paso ni niveles proyectados', () async {
      final vm = detalle(idDe('Ejercicio'));
      await vm.cargar.ejecutar();
      expect(vm.habito!.evaluacion!.zona, ZonaEvidencia.optimo);
      expect(vm.escalera!.escaleraActiva, isTrue);
      expect(vm.siguienteMeta, isNull, reason: 'ritmo ideal');
      expect(vm.totalNiveles, vm.escalera!.nivelActual);
      vm.dispose();
    });

    test('Escalera apagada: sin siguiente micro-paso', () async {
      final vm = detalle(idDe('Estudiar inglés'));
      await vm.cargar.ejecutar();
      expect(vm.escalera!.escaleraActiva, isFalse);
      expect(vm.siguienteMeta, isNull);
      vm.dispose();
    });

    test('si falla la Escalera, el detalle se muestra igual; si falla el hábito, no', () async {
      habitos.fallarEscalera = true;
      final vm = detalle(idDe('Ejercicio'));
      await vm.cargar.ejecutar();
      expect(vm.habito, isNotNull);
      expect(vm.escalera, isNull);
      expect(vm.siguienteMeta, isNull);
      expect(vm.totalNiveles, vm.habito!.nivel, reason: 'Ejercicio (30 min diarios) ya está en el óptimo');
      final roto = detalle('no-existe');
      await roto.cargar.ejecutar();
      expect(roto.habito, isNull);
      expect(roto.cargar.error!.tipo, TipoError.noEncontrado);
      vm.dispose();
      roto.dispose();
    });

    test('reactivar un archivado', () async {
      final id = idDe('Dormir 7 h');
      datos.habitos[id]!.activo = false;
      final vm = detalle(id);
      await vm.cargar.ejecutar();
      expect(vm.habito!.activo, isFalse);
      await vm.reactivar.ejecutar();
      expect(vm.habito!.activo, isTrue);
      expect(habitos.actualizaciones.single.toJson(), {'activo': true});
      vm.dispose();
    });
  });
}
