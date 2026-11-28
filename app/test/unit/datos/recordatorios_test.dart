import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/data/services/recordatorios/servicio_recordatorios.dart';
import 'package:kaizen/data/services/avisos/notificador.dart';
import 'package:kaizen/data/services/avisos/notificador_local.dart';
import 'package:kaizen/domain/models/avisos.dart';
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

  group('notificador local', () {
    late _PluginFalso plugin;
    late NotificadorLocal notificador;
    late bool exacta;
    final programadas = <Map<String, Object?>>[];

    setUp(() {
      plugin = _PluginFalso();
      programadas.clear();
      when(() => plugin.initialize(settings: any(named: 'settings'))).thenAnswer((_) async => true);
      when(plugin.cancelAll).thenAnswer((_) async {});
      when(
        () => plugin.zonedSchedule(
          id: any(named: 'id'),
          scheduledDate: any(named: 'scheduledDate'),
          notificationDetails: any(named: 'notificationDetails'),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          title: any(named: 'title'),
          body: any(named: 'body'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((inv) async {
        programadas.add({for (final e in inv.namedArguments.entries) e.key.toString().split('"')[1]: e.value});
      });
      exacta = true;
      notificador = NotificadorLocal(
        plugin: plugin,
        zonaDelSistema: () async => 'America/Mexico_City',
        pedirPermiso: () async => true,
        horaExacta: () async => exacta,
      );
    });

    test('reemplaza todo: cancela lo anterior y programa cada aviso una vez, en su canal', () async {
      await notificador.reemplazar([
        AvisoProgramado(
          id: 70000,
          cuando: DateTime(2026, 11, 27, 22, 20),
          tipo: TipoAviso.personal,
          titulo: 'Kaizen',
          cuerpo: 'Prepara la mochila',
        ),
        AvisoProgramado(
          id: 70001,
          cuando: DateTime(2026, 11, 28, 9, 35),
          tipo: TipoAviso.recordatorio,
          habitoId: 'h-1',
          titulo: 'Leer',
          cuerpo: 'Después de cenar: Leer.',
        ),
      ]);
      verify(plugin.cancelAll).called(1);
      expect(programadas, hasLength(2));
      final a = programadas.first;
      expect(a['id'], 70000);
      expect(a['body'], 'Prepara la mochila');
      final cuando = a['scheduledDate']! as tz.TZDateTime;
      expect((cuando.hour, cuando.minute, cuando.location.name), (22, 20, 'America/Mexico_City'));
      final android = (a['notificationDetails']! as NotificationDetails).android!;
      expect(android.channelId, 'mis_avisos');
      expect(a['androidScheduleMode'], AndroidScheduleMode.exactAllowWhileIdle, reason: 'lo programó el usuario');
      expect(jsonDecode(programadas[1]['payload']! as String), {'tipo': 'recordatorio', 'habito': 'h-1'});
      expect(NotificadorLocal.canal(TipoAviso.rachaEnRiesgo).$1, 'racha');
      expect(NotificadorLocal.canal(TipoAviso.microPaso).$1, 'escalera');
      expect(NotificadorLocal.canal(TipoAviso.resumenSemanal).$1, 'resumen');
      expect(NotificadorLocal.canal(TipoAviso.recordatorio).$1, 'recordatorios');
    });

    test('sin el permiso de hora exacta, todo inexacto; los automáticos siempre inexactos', () async {
      exacta = false;
      expect(await notificador.horaExacta(), isFalse);
      expect(await notificador.pedirHoraExacta(), isFalse);
      await notificador.reemplazar([
        AvisoProgramado(
          id: 1,
          cuando: DateTime(2026, 11, 28, 9, 35),
          tipo: TipoAviso.personal,
          titulo: 'K',
          cuerpo: 'x',
        ),
      ]);
      expect(programadas.single['androidScheduleMode'], AndroidScheduleMode.inexactAllowWhileIdle);
      expect(NotificadorLocal.modo(TipoAviso.rachaEnRiesgo, exacta: true), AndroidScheduleMode.inexactAllowWhileIdle);
      expect(NotificadorLocal.modo(TipoAviso.recordatorio, exacta: true), AndroidScheduleMode.exactAllowWhileIdle);
    });

    test('un plan vacío solo cancela', () async {
      await notificador.reemplazar(const []);
      verify(plugin.cancelAll).called(1);
      expect(programadas, isEmpty);
    });

    test('se inicia una sola vez; con una zona inválida usa la de México; pide permiso', () async {
      final otro = NotificadorLocal(
        plugin: plugin,
        zonaDelSistema: () async => 'Zona/Inexistente',
        pedirPermiso: () async => false,
      );
      expect(otro.disponible, isTrue);
      expect(await otro.pedirPermiso(), isFalse);
      await otro.reemplazar(const []);
      verify(() => plugin.initialize(settings: any(named: 'settings'))).called(1);
      expect(tz.local.name, 'America/Mexico_City');
    });
  });

  group('notificador en memoria', () {
    test('guarda el plan; sin plataforma no programa ni da permiso', () async {
      final n = NotificadorEnMemoria();
      expect(await n.pedirPermiso(), isTrue);
      n.permisoConcedido = false;
      expect(await n.pedirPermiso(), isFalse);
      await n.reemplazar([
        AvisoProgramado(id: 1, cuando: DateTime(2026), tipo: TipoAviso.personal, titulo: 'a', cuerpo: 'b'),
      ]);
      expect((n.programados.length, n.reemplazos), (1, 1));
      n.exactaPermitida = false;
      expect(await n.horaExacta(), isFalse);
      expect(await n.pedirHoraExacta(), isTrue);
      expect(await n.horaExacta(), isTrue);
      final sin = NotificadorEnMemoria(disponible: false);
      await sin.reemplazar([
        AvisoProgramado(id: 1, cuando: DateTime(2026), tipo: TipoAviso.personal, titulo: 'a', cuerpo: 'b'),
      ]);
      expect(sin.programados, isEmpty);
      expect(sin.reemplazos, 0);
      expect(await sin.pedirPermiso(), isFalse);
      expect((await sin.horaExacta(), await sin.pedirHoraExacta()), (false, false));
    });
  });
}
