import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/data/fake/datos_demo.dart';
import 'package:kaizen/data/repositories/escalera/escalera_repository_fake.dart';
import 'package:kaizen/data/repositories/habitos/habitos_repository_fake.dart';
import 'package:kaizen/data/services/avisos/gestor_avisos.dart';
import 'package:kaizen/data/services/avisos/notificador.dart';
import 'package:kaizen/data/services/base_local/almacen_local.dart';
import 'package:kaizen/data/services/base_local/base_local.dart';
import 'package:kaizen/data/services/recordatorios/servicio_recordatorios_adaptativo.dart';
import 'package:kaizen/domain/models/avisos.dart';
import 'package:kaizen/ui/notificaciones/view_models/notificaciones_viewmodel.dart';

void main() {
  late DateTime ahora;
  late DatosDemo datos;
  late BaseLocal base;
  late NotificadorEnMemoria notificador;
  late GestorAvisos gestor;
  late NotificacionesViewModel vm;

  setUp(() async {
    ahora = DateTime(2026, 11, 27, 10);
    datos = DatosDemo(reloj: () => ahora)..usuarioActual = 'u-demo';
    base = BaseLocal.enMemoria();
    final almacen = AlmacenLocal(base);
    notificador = NotificadorEnMemoria();
    final habitos = HabitosRepositoryFake(datos);
    gestor = GestorAvisos(
      habitos: habitos,
      escalera: EscaleraRepositoryFake(datos),
      almacen: almacen,
      notificador: notificador,
      reloj: () => ahora,
    );
    vm = NotificacionesViewModel(
      avisos: gestor,
      recordatorios: ServicioRecordatoriosAdaptativo(gestor: gestor, almacen: almacen),
      habitos: habitos,
      reloj: () => ahora,
    );
    await vm.cargar.ejecutar();
  });

  tearDown(() async {
    await gestor.replanificar();
    vm.dispose();
    gestor.dispose();
    await base.close();
  });

  test('carga las preferencias, los hábitos activos sin hora y el plan', () {
    expect(vm.cargado, isTrue);
    expect(vm.disponible, isTrue);
    expect(vm.preferencias.toJson(), const PreferenciasAvisos().toJson());
    expect(vm.habitos, isNotEmpty);
    expect(vm.habitos.every((x) => x.habito.activo && x.hora == null), isTrue);
    expect(vm.proximos(cuantos: 2).length, lessThanOrEqualTo(2));
    expect(vm.proximos(), gestor.plan.take(5).toList());
  });

  test('"Mis avisos": agregar a las 22:20, editar, apagar y quitar', () async {
    expect(await vm.agregarAviso(hora: (hora: 22, minuto: 20), dias: 0, texto: '  Prepara la mochila '), isTrue);
    final a = vm.preferencias.personales.single;
    expect((a.hora, a.dias, a.texto, a.activo), ((hora: 22, minuto: 20), 127, 'Prepara la mochila', true));
    expect(notificador.programados.where((x) => x.cuerpo == 'Prepara la mochila'), hasLength(7));

    await vm.editarAviso(a.copyWith(hora: (hora: 9, minuto: 35), dias: 1));
    final lunes = notificador.programados.where((x) => x.tipo == TipoAviso.personal).toList();
    expect(lunes.single.cuando, DateTime(2026, 11, 30, 9, 35));

    await vm.editarAviso(vm.preferencias.personales.single.copyWith(activo: false));
    expect(notificador.programados.where((x) => x.tipo == TipoAviso.personal), isEmpty);

    await vm.quitarAviso(a.id);
    expect(vm.preferencias.personales, isEmpty);
    expect((await gestor.preferencias()).personales, isEmpty, reason: 'se guardó en el dispositivo');
  });

  test('sin permiso no se agrega y lo avisa', () async {
    notificador.permisoConcedido = false;
    expect(await vm.agregarAviso(hora: (hora: 8, minuto: 0), dias: 127, texto: 'x'), isFalse);
    expect(vm.permisoNegado, isTrue);
    expect(vm.preferencias.personales, isEmpty);
    final h = vm.habitos.first.habito;
    expect(await vm.ponerRecordatorio(h, (hora: 21, minuto: 0)), isFalse);
    expect(vm.habitos.first.hora, isNull);
  });

  test('recordatorio de cada hábito: poner y quitar la hora', () async {
    final h = vm.habitos.first.habito;
    expect(await vm.ponerRecordatorio(h, (hora: 23, minuto: 30)), isTrue);
    expect(vm.permisoNegado, isFalse);
    expect(vm.habitos.first.hora, (hora: 23, minuto: 30));
    expect(notificador.programados.where((a) => a.tipo == TipoAviso.recordatorio && a.habitoId == h.id), isNotEmpty);
    await vm.quitarRecordatorio(h);
    expect(vm.habitos.first.hora, isNull);
    expect(notificador.programados.where((a) => a.habitoId == h.id && a.tipo == TipoAviso.recordatorio), isEmpty);
  });

  test('automáticos, horas y silencio se guardan y replanifican', () async {
    await vm.cambiarRecordatorios(false);
    await vm.cambiarRachaEnRiesgo(false);
    await vm.cambiarHoraRachaEnRiesgo((hora: 19, minuto: 0));
    await vm.cambiarMicroPaso(false);
    await vm.cambiarResumenSemanal(true);
    await vm.cambiarDiaResumen(DateTime.saturday);
    await vm.cambiarHoraResumen((hora: 17, minuto: 30));
    await vm.cambiarSilencioDesde((hora: 23, minuto: 0));
    await vm.cambiarSilencioHasta((hora: 7, minuto: 0));
    final p = await gestor.preferencias();
    expect(
      (
        p.recordatorios,
        p.rachaEnRiesgo,
        p.horaRachaEnRiesgo,
        p.microPaso,
        p.diaResumen,
        p.horaResumen,
        p.silencioDesde,
        p.silencioHasta,
      ),
      (
        false,
        false,
        (hora: 19, minuto: 0),
        false,
        DateTime.saturday,
        (hora: 17, minuto: 30),
        (hora: 23, minuto: 0),
        (hora: 7, minuto: 0),
      ),
    );
    expect(notificador.programados.single.tipo, TipoAviso.resumenSemanal);
    expect(notificador.programados.single.cuando, DateTime(2026, 11, 28, 17, 30));
  });

  test('hora exacta: si Android no la permite, se pide y se vuelve a planear', () async {
    notificador.exactaPermitida = false;
    await vm.cargar.ejecutar();
    expect(vm.horaExacta, isFalse);
    final antes = notificador.reemplazos;
    await vm.pedirHoraExacta();
    expect(vm.horaExacta, isTrue);
    expect(notificador.reemplazos, greaterThan(antes));
  });
}
