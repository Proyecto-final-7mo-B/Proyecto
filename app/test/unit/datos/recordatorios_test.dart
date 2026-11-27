import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/data/services/recordatorios/servicio_recordatorios.dart';
import 'package:kaizen/data/services/recordatorios/servicio_recordatorios_local.dart';
import 'package:kaizen/domain/models/frecuencia.dart';
import 'package:mocktail/mocktail.dart';
import 'package:timezone/data/latest_all.dart' as tzdatos;
import 'package:timezone/timezone.dart' as tz;

class _PluginFalso extends Mock implements FlutterLocalNotificationsPlugin {}

void main() {
  setUpAll(() {
    tzdatos.initializeTimeZones();
    registerFallbackValue(const InitializationSettings());
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
    registerFallbackValue(tz.TZDateTime.utc(2026));
  });

  group('hora', () {
    test('formato y lectura', () {
      expect(formatoHora((hora: 7, minuto: 5)), '07:05');
      expect(leerHora('21:30'), (hora: 21, minuto: 30));
      expect(leerHora('24:00'), isNull);
      expect(leerHora('7'), isNull);
      expect(leerHora(null), isNull);
      expect(leerHora('aa:bb'), isNull);
    });
  });

  group('en memoria', () {
    test('programa, lee y cancela; respeta el permiso y la disponibilidad', () async {
      final s = ServicioRecordatoriosEnMemoria();
      expect(
        await s.programar(
          habitoId: 'h1',
          titulo: 'K',
          cuerpo: 'x',
          hora: (hora: 7, minuto: 0),
          frecuencia: const Diaria(),
        ),
        isTrue,
      );
      expect(await s.hora('h1'), (hora: 7, minuto: 0));
      await s.cancelar('h1');
      expect(await s.hora('h1'), isNull);
      s.permisoConcedido = false;
      expect(
        await s.programar(
          habitoId: 'h1',
          titulo: 'K',
          cuerpo: 'x',
          hora: (hora: 7, minuto: 0),
          frecuencia: const Diaria(),
        ),
        isFalse,
      );
      final sinPlataforma = ServicioRecordatoriosEnMemoria(disponible: false);
      expect(sinPlataforma.disponible, isFalse);
      expect(
        await sinPlataforma.programar(
          habitoId: 'h1',
          titulo: 'K',
          cuerpo: 'x',
          hora: (hora: 7, minuto: 0),
          frecuencia: const Diaria(),
        ),
        isFalse,
      );
    });
  });

  group('notificaciones locales', () {
    late _PluginFalso plugin;
    late bool permiso;
    late ServicioRecordatoriosLocal servicio;
    final programadas = <Map<String, Object?>>[];

    setUp(() {
      plugin = _PluginFalso();
      permiso = true;
      programadas.clear();
      when(() => plugin.initialize(settings: any(named: 'settings'))).thenAnswer((_) async => true);
      when(() => plugin.cancel(id: any(named: 'id'))).thenAnswer((_) async {});
      when(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
          matchDateTimeComponents: any(named: 'matchDateTimeComponents'),
        ),
      ).thenAnswer((inv) async {
        programadas.add({for (final e in inv.namedArguments.entries) e.key.toString().split('"')[1]: e.value});
      });
      servicio = ServicioRecordatoriosLocal(
        plugin: plugin,
        zonaDelSistema: () async => 'America/Mexico_City',
        pedirPermiso: () async => permiso,
      );
    });

    test('el id base es estable, distinto por hábito y deja lugar a 8 ids', () {
      final a = ServicioRecordatoriosLocal.idBase('h-1');
      expect(ServicioRecordatoriosLocal.idBase('h-1'), a);
      expect(ServicioRecordatoriosLocal.idBase('h-2'), isNot(a));
      expect(a % 8, 0);
      expect(a + 7, lessThan(0x7fffffff));
      expect(a, greaterThanOrEqualTo(0));
    });

    test('la siguiente vez que toca: hoy si aún no pasa la hora, si no mañana; o el día pedido', () {
      final mx = tz.getLocation('America/Mexico_City');
      final miercoles = tz.TZDateTime(mx, 2026, 11, 25, 9, 30);
      expect(
        ServicioRecordatoriosLocal.siguiente(miercoles, (hora: 21, minuto: 0)),
        tz.TZDateTime(mx, 2026, 11, 25, 21),
      );
      expect(ServicioRecordatoriosLocal.siguiente(miercoles, (hora: 7, minuto: 0)), tz.TZDateTime(mx, 2026, 11, 26, 7));
      expect(
        ServicioRecordatoriosLocal.siguiente(miercoles, (hora: 7, minuto: 0), diaSemana: DateTime.monday),
        tz.TZDateTime(mx, 2026, 11, 30, 7),
      );
      expect(
        ServicioRecordatoriosLocal.siguiente(miercoles, (hora: 10, minuto: 0), diaSemana: DateTime.wednesday),
        tz.TZDateTime(mx, 2026, 11, 25, 10),
      );
    });

    test('diario: una notificación que se repite a la misma hora', () async {
      final ok = await servicio.programar(
        habitoId: 'h-1',
        titulo: 'Kaizen',
        cuerpo: 'Es hora de: Leer',
        hora: (hora: 7, minuto: 30),
        frecuencia: const Diaria(),
      );
      expect(ok, isTrue);
      final n = programadas.single;
      expect(n['id'], ServicioRecordatoriosLocal.idBase('h-1'));
      expect(n['title'], 'Kaizen');
      expect(n['body'], 'Es hora de: Leer');
      expect(n['matchDateTimeComponents'], DateTimeComponents.time);
      expect(n['androidScheduleMode'], AndroidScheduleMode.inexactAllowWhileIdle);
      expect(jsonDecode(n['payload']! as String), {'habito': 'h-1', 'hora': '07:30'});
      final fecha = n['scheduledDate']! as tz.TZDateTime;
      expect((fecha.hour, fecha.minute), (7, 30));
      // Antes de programar se cancelan los 8 ids del hábito (por si cambió la hora o los días).
      verify(() => plugin.cancel(id: any(named: 'id'))).called(8);
    });

    test('"N por semana" también es diario', () async {
      await servicio.programar(
        habitoId: 'h-1',
        titulo: 'Kaizen',
        cuerpo: 'x',
        hora: (hora: 8, minuto: 0),
        frecuencia: const NPorSemana(3),
      );
      expect(programadas.single['matchDateTimeComponents'], DateTimeComponents.time);
    });

    test('días de la semana: una por día, que se repite cada semana', () async {
      await servicio.programar(
        habitoId: 'h-1',
        titulo: 'Kaizen',
        cuerpo: 'x',
        hora: (hora: 18, minuto: 0),
        frecuencia: const DiasSemana(1 | 4 | 16), // L, Mi, V
      );
      final base = ServicioRecordatoriosLocal.idBase('h-1');
      expect(programadas.map((n) => n['id']), [base + 1, base + 3, base + 5]);
      expect(programadas.map((n) => (n['scheduledDate']! as tz.TZDateTime).weekday), [1, 3, 5]);
      expect(programadas.every((n) => n['matchDateTimeComponents'] == DateTimeComponents.dayOfWeekAndTime), isTrue);
    });

    test('sin permiso no programa nada', () async {
      permiso = false;
      final ok = await servicio.programar(
        habitoId: 'h-1',
        titulo: 'Kaizen',
        cuerpo: 'x',
        hora: (hora: 7, minuto: 0),
        frecuencia: const Diaria(),
      );
      expect(ok, isFalse);
      expect(programadas, isEmpty);
    });

    test('lee la hora del payload de las notificaciones pendientes', () async {
      when(plugin.pendingNotificationRequests).thenAnswer(
        (_) async => [
          const PendingNotificationRequest(1, 'a', 'b', 'no es json'),
          const PendingNotificationRequest(2, 'a', 'b', null),
          PendingNotificationRequest(3, 'a', 'b', jsonEncode({'habito': 'otro', 'hora': '06:00'})),
          PendingNotificationRequest(4, 'a', 'b', jsonEncode({'habito': 'h-1', 'hora': '21:15'})),
        ],
      );
      expect(await servicio.hora('h-1'), (hora: 21, minuto: 15));
      expect(await servicio.hora('h-9'), isNull);
    });

    test('se inicia una sola vez; con una zona inválida usa la de México', () async {
      final otro = ServicioRecordatoriosLocal(
        plugin: plugin,
        zonaDelSistema: () async => 'Zona/Inexistente',
        pedirPermiso: () async => true,
      );
      await otro.cancelar('h-1');
      await otro.cancelar('h-2');
      verify(() => plugin.initialize(settings: any(named: 'settings'))).called(1);
      expect(tz.local.name, 'America/Mexico_City');
      expect(otro.disponible, isTrue);
    });
  });
}
