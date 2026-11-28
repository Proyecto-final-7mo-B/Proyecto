import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/data/fake/datos_demo.dart';
import 'package:kaizen/data/repositories/escalera/escalera_repository_fake.dart';
import 'package:kaizen/data/repositories/habitos/habitos_repository_fake.dart';
import 'package:kaizen/data/repositories/registros/registros_repository_con_avisos.dart';
import 'package:kaizen/data/repositories/registros/registros_repository_fake.dart';
import 'package:kaizen/data/services/avisos/gestor_avisos.dart';
import 'package:kaizen/data/services/avisos/notificador.dart';
import 'package:kaizen/data/services/base_local/almacen_local.dart';
import 'package:kaizen/data/services/base_local/base_local.dart';
import 'package:kaizen/data/services/recordatorios/servicio_recordatorios_adaptativo.dart';
import 'package:kaizen/domain/models/avisos.dart';
import 'package:kaizen/domain/models/frecuencia.dart';
import 'package:kaizen/domain/models/registro.dart';
import 'package:kaizen/utils/fechas.dart';

void main() {
  late DateTime ahora;
  late DatosDemo datos;
  late BaseLocal base;
  late AlmacenLocal almacen;
  late NotificadorEnMemoria notificador;
  late GestorAvisos gestor;

  String idDe(String nombre) => datos.habitosDe('u-demo').firstWhere((h) => h.nombre == nombre).id;

  List<AvisoProgramado> deTipo(TipoAviso t) => [
    for (final a in notificador.programados)
      if (a.tipo == t) a,
  ];

  setUp(() {
    ahora = DateTime(2026, 11, 27, 10);
    datos = DatosDemo(reloj: () => ahora)..usuarioActual = 'u-demo';
    base = BaseLocal.enMemoria();
    almacen = AlmacenLocal(base);
    notificador = NotificadorEnMemoria();
    gestor = GestorAvisos(
      habitos: HabitosRepositoryFake(datos),
      escalera: EscaleraRepositoryFake(datos),
      almacen: almacen,
      notificador: notificador,
      reloj: () => ahora,
    );
  });

  tearDown(() async {
    await pumpEventQueue();
    await gestor.replanificar();
    gestor.dispose();
    await base.close();
  });

  test('sin preferencias guardadas usa las del doc. 06; se guardan en el dispositivo', () async {
    expect((await gestor.preferencias()).toJson(), const PreferenciasAvisos().toJson());
    final p = const PreferenciasAvisos().copyWith(
      personales: [const AvisoPersonal(id: 'a', hora: (hora: 22, minuto: 20), dias: 127, texto: 'Mochila')],
    );
    await gestor.guardarPreferencias(p);
    expect((await gestor.preferencias()).personales.single.texto, 'Mochila');
    expect(deTipo(TipoAviso.personal), hasLength(7));
    expect(gestor.plan, notificador.programados);
  });

  test(
    'recordatorio de un hábito: llega hoy si sigue pendiente; el check-in lo quita y queda en el historial',
    () async {
      final leer = idDe('Leer');
      final registros = RegistrosRepositoryConAvisos(interno: RegistrosRepositoryFake(datos), gestor: gestor);
      final servicio = ServicioRecordatoriosAdaptativo(gestor: gestor, almacen: almacen);
      expect(servicio.disponible, isTrue);
      expect(
        await servicio.programar(
          habitoId: leer,
          titulo: '',
          cuerpo: '',
          hora: (hora: 21, minuto: 0),
          frecuencia: const Diaria(),
        ),
        isTrue,
      );
      expect(await servicio.hora(leer), (hora: 21, minuto: 0));
      bool hayHoy() => deTipo(TipoAviso.recordatorio).any((a) => a.habitoId == leer && a.cuando.day == 27);
      expect(hayHoy(), isTrue);

      final r = await registros.registrar(
        NuevoRegistro(
          id: datos.nuevoId(),
          habitoId: leer,
          fecha: Fechas.soloFecha(ahora),
          cumplido: true,
          origen: OrigenRegistro.rapido,
        ),
      );
      expect(r.valorONulo, isNotNull);
      await gestor.replanificar();
      expect(hayHoy(), isFalse);
      expect(deTipo(TipoAviso.recordatorio).where((a) => a.habitoId == leer), isNotEmpty, reason: 'mañana sí');
      expect((await gestor.historial()).where((e) => e.esCheckin && e.habitoId == leer), hasLength(1));
      expect((await registros.registrarLote(const [])).valorONulo, isNotNull);

      await servicio.cancelar(leer);
      expect(deTipo(TipoAviso.recordatorio).where((a) => a.habitoId == leer), isEmpty);
    },
  );

  test('cada sugerencia de la Escalera se avisa una sola vez', () async {
    await gestor.replanificar();
    final primero = deTipo(TipoAviso.microPaso);
    expect(primero, isNotEmpty);
    // Se vuelve a planear antes de que llegue: se conserva a su hora.
    await gestor.replanificar();
    expect([for (final a in deTipo(TipoAviso.microPaso)) a.cuando], [for (final a in primero) a.cuando]);
    // Ya llegó: no se vuelve a programar.
    ahora = ahora.add(const Duration(hours: 1));
    await gestor.replanificar();
    expect(deTipo(TipoAviso.microPaso), isEmpty);
  });

  test('sin permiso, el recordatorio no se guarda', () async {
    notificador.permisoConcedido = false;
    final servicio = ServicioRecordatoriosAdaptativo(gestor: gestor, almacen: almacen);
    expect(
      await servicio.programar(
        habitoId: 'h1',
        titulo: '',
        cuerpo: '',
        hora: (hora: 9, minuto: 0),
        frecuencia: const Diaria(),
      ),
      isFalse,
    );
    expect(await almacen.recordatorio('h1'), isNull);
  });

  test('el historial guarda solo 30 días y lo que ya pasó', () async {
    await almacen.guardarJson(GestorAvisos.claveHistorial, [
      EventoAviso.checkin(cuando: ahora.subtract(const Duration(days: 40)), habitoId: 'viejo').toJson(),
      EventoAviso.checkin(cuando: ahora.subtract(const Duration(days: 2)), habitoId: 'reciente').toJson(),
      EventoAviso(cuando: ahora.add(const Duration(hours: 3)), tipo: TipoAviso.resumenSemanal, plantilla: 5).toJson(),
    ]);
    await gestor.replanificar();
    final h = await gestor.historial();
    expect(h.where((e) => e.habitoId == 'viejo'), isEmpty);
    expect(h.where((e) => e.habitoId == 'reciente'), hasLength(1));
    expect(
      h.where((e) => e.tipo == TipoAviso.resumenSemanal && e.plantilla == 5),
      isEmpty,
      reason: 'era del plan viejo',
    );
  });

  test('varias replanificaciones al mismo tiempo terminan con el plan más nuevo', () async {
    var avisos = 0;
    gestor.addListener(() => avisos++);
    await Future.wait([gestor.replanificar(), gestor.replanificar(), gestor.replanificar()]);
    await pumpEventQueue();
    expect(avisos, inInclusiveRange(1, 2));
    // Cerrar sesión con un plan armándose: al final no queda nada y no se vuelve a planear hasta activar.
    unawaited(gestor.replanificar());
    await gestor.cancelarTodo();
    expect(notificador.programados, isEmpty);
    expect(gestor.plan, isEmpty);
    await gestor.replanificar();
    expect(notificador.programados, isEmpty);
    gestor.activar();
    await gestor.replanificar();
    expect(notificador.programados, isNotEmpty);
  });

  test('"Mis avisos": días como texto', () {
    expect(diasDeMascara(127), 'Todos los días');
    expect(diasDeMascara(31), 'Lunes a viernes');
    expect(diasDeMascara(96), 'Fin de semana');
    expect(diasDeMascara(1 | 4 | 16), 'Lun · Mié · Vie');
  });
}
