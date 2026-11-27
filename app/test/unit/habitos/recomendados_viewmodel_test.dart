import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/config/dependencias.dart';
import 'package:kaizen/data/fake/datos_demo.dart';
import 'package:kaizen/data/services/api/errores_api.dart';
import 'package:kaizen/domain/models/frecuencia.dart';
import 'package:kaizen/domain/models/habito.dart';
import 'package:kaizen/ui/acerca/view_models/acerca_viewmodel.dart';
import 'package:kaizen/ui/habitos/view_models/recomendados_viewmodel.dart';

/// Miércoles 25-nov-2026, 9:30.
final DateTime _ahora = DateTime(2026, 11, 25, 9, 30);

void main() {
  late DatosDemo datos;
  late Dependencias d;
  late RecomendadosViewModel vm;

  setUp(() async {
    datos = DatosDemo(reloj: () => _ahora)..usuarioActual = 'u-demo';
    d = Dependencias.fake(datos: datos);
    vm = RecomendadosViewModel(habitos: d.habitos);
    await vm.cargar.ejecutar();
  });

  tearDown(() => vm.dispose());

  group('Nuevo hábito: recomendaciones', () {
    test('carga las 100 y empieza en la primera categoría (Ejercicio)', () {
      expect(vm.cargado, isTrue);
      expect(vm.todos, hasLength(100));
      expect(vm.categorias.map((c) => c.clave), ['ejercicio', 'salud', 'educacion', 'bienestar', 'finanzas']);
      expect(vm.categoria, 'ejercicio');
    });

    test('agrupa por subcategoría en el orden del catálogo; 20 por categoría', () {
      expect(vm.grupos.map((g) => g.subcategoria.clave), [
        'aerobico_moderado',
        'vigoroso',
        'fuerza',
        'pasos',
        'estiramiento',
        'pausas_activas',
      ]);
      expect(vm.grupos.map((g) => g.recomendados.length), [4, 3, 4, 3, 3, 3]);
      for (final c in vm.categorias) {
        vm.categoria = c.clave;
        expect(vm.grupos.expand((g) => g.recomendados), hasLength(20), reason: c.clave);
      }
      vm.categoria = 'finanzas';
      expect(vm.grupos.map((g) => (g.subcategoria.clave, g.recomendados.length)), [
        ('ahorro', 10),
        ('control_gastos', 10),
      ]);
    });

    test('elegir reinicia la prioridad (media) y la cápsula (ninguna)', () {
      final r = vm.grupos.first.recomendados.first;
      vm
        ..elegir(r)
        ..prioridad = Prioridad.alta
        ..capsula = 30;
      vm.elegir(vm.grupos.last.recomendados.first);
      expect((vm.prioridad, vm.capsula), (Prioridad.media, null));
    });

    test('crear: la base copia todo; el usuario solo puso la prioridad', () async {
      final r = vm.todos.firstWhere((x) => x.clave == 'caminar_rapido');
      vm
        ..elegir(r)
        ..prioridad = Prioridad.alta
        ..capsula = 66;
      await vm.crear.ejecutar();
      final h = vm.crear.resultado!.valorONulo!;
      expect(
        (h.nombre, h.meta, h.unidad, h.frecuencia, h.intencion, h.prioridad),
        ('Caminar a paso rápido', 30.0, 'min', const DiasSemana(31), 'Después de comer', Prioridad.alta),
      );
      expect(h.recomendacionId, r.id);
      expect(vm.capsula, 66, reason: 'la cápsula se sella después, en su pantalla');
    });

    test('si la recomendación ya no está disponible, el error queda en el comando', () async {
      final r = vm.todos.first;
      datos.recomendadosInactivos.add(r.id);
      vm.elegir(r);
      await vm.crear.ejecutar();
      expect(vm.crear.error!.tipo, TipoError.recomendacionNoDisponible);
      vm.elegir(r);
      expect(vm.crear.error, isNull, reason: 'elegir de nuevo limpia el error');
    });

    test('si no carga, el error queda en el comando y no hay categorías', () async {
      final otro = RecomendadosViewModel(habitos: d.habitos);
      // Un error que no es de red (con uno de red, la copia local respondería).
      datos.fallarSiguiente(const ErrorApp(TipoError.desconocido));
      await otro.cargar.ejecutar();
      expect(otro.cargado, isFalse);
      expect(otro.cargar.error!.tipo, TipoError.desconocido);
      expect(otro.categorias, isEmpty);
      otro.dispose();
    });
  });

  group('Acerca de Kaizen', () {
    test('carga el catálogo y las fuentes agrupadas por tema, en el orden del documento', () async {
      final acerca = AcercaViewModel(categorias: d.categorias);
      await acerca.cargar.ejecutar();
      expect(acerca.categorias, hasLength(5));
      expect(acerca.fuentes, hasLength(53));
      expect(acerca.fuentesPorTema.keys, AcercaViewModel.temas);
      expect(acerca.fuentesPorTema['formacion']!.first.clave, 'F01');
      expect(acerca.fuentesPorTema.values.expand((l) => l), hasLength(53));
      acerca.dispose();
    });

    test('si falla, se queda lo que ya tenía y el error en el comando', () async {
      final acerca = AcercaViewModel(categorias: d.categorias);
      datos.fallarSiguiente(const ErrorApp(TipoError.sinConexion));
      await acerca.cargar.ejecutar();
      expect(acerca.cargar.error, isNotNull);
      expect(acerca.fuentes, hasLength(53), reason: 'las fuentes sí llegaron (solo falló el catálogo)');
      acerca.dispose();
    });
  });
}
