import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdatos;
import 'package:timezone/timezone.dart' as tz;

import '../../../domain/models/frecuencia.dart';
import 'servicio_recordatorios.dart';

/// Recordatorios con notificaciones locales (Android e iOS).
///
/// - **No se guarda nada aparte:** el propio sistema conserva las notificaciones programadas (y el *plugin* las
///   reprograma al reiniciar el teléfono). La hora de cada hábito se lee de su `payload`. Además, `ServicioRecordatoriosConCopia`
///   la copia en la tabla local `recordatorios`.
/// - Cada hábito usa 8 ids: `base + 0` para "todos los días" y `base + 1…7` para lunes…domingo.
/// - Horario **inexacto** (`inexactAllowWhileIdle`): Android puede retrasarlo unos minutos, pero no exige el permiso
///   de alarmas exactas.
class ServicioRecordatoriosLocal implements ServicioRecordatorios {
  ServicioRecordatoriosLocal({
    FlutterLocalNotificationsPlugin? plugin,
    Future<String> Function()? zonaDelSistema,
    Future<bool> Function()? pedirPermiso,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _zonaDelSistema = zonaDelSistema ?? _leerZona,
       _pedirPermisoInyectado = pedirPermiso;

  final FlutterLocalNotificationsPlugin _plugin;
  final Future<String> Function() _zonaDelSistema;
  final Future<bool> Function()? _pedirPermisoInyectado;
  Future<void>? _inicio;

  static const String canal = 'recordatorios';

  static Future<String> _leerZona() async => (await FlutterTimezone.getLocalTimezone()).identifier;

  @override
  bool get disponible => true;

  /// Primer id de [habitoId]: un *hash* estable (FNV-1a de 32 bits) recortado para que `base + 7` quepa en un int de
  /// 32 bits con signo, como piden Android e iOS.
  @visibleForTesting
  static int idBase(String habitoId) {
    var h = 0x811c9dc5;
    for (final c in utf8.encode(habitoId)) {
      h = ((h ^ c) * 0x01000193) & 0xffffffff;
    }
    return (h & 0x0fffffff) * 8;
  }

  Future<void> _iniciar() => _inicio ??= () async {
    tzdatos.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(await _zonaDelSistema()));
    } on Object {
      tz.setLocalLocation(tz.getLocation('America/Mexico_City'));
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }();

  Future<bool> _pedirPermiso() async {
    final inyectado = _pedirPermisoInyectado;
    if (inyectado != null) {
      return inyectado();
    }
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  @override
  Future<HoraRecordatorio?> hora(String habitoId) async {
    await _iniciar();
    for (final p in await _plugin.pendingNotificationRequests()) {
      final datos = _leerPayload(p.payload);
      if (datos?['habito'] == habitoId) {
        return leerHora(datos?['hora'] as String?);
      }
    }
    return null;
  }

  static Map<String, dynamic>? _leerPayload(String? payload) {
    if (payload == null) {
      return null;
    }
    try {
      return jsonDecode(payload) as Map<String, dynamic>;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<bool> programar({
    required String habitoId,
    required String titulo,
    required String cuerpo,
    required HoraRecordatorio hora,
    required Frecuencia frecuencia,
  }) async {
    await _iniciar();
    if (!await _pedirPermiso()) {
      return false;
    }
    await cancelar(habitoId);
    final base = idBase(habitoId);
    final payload = jsonEncode({'habito': habitoId, 'hora': formatoHora(hora)});
    const detalles = NotificationDetails(
      android: AndroidNotificationDetails(
        canal,
        'Recordatorios',
        channelDescription: 'Recordatorios de tus hábitos',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );
    final ahora = tz.TZDateTime.now(tz.local);
    switch (frecuencia) {
      case DiasSemana(:final dias):
        for (final dia in dias) {
          await _plugin.zonedSchedule(
            id: base + dia,
            title: titulo,
            body: cuerpo,
            scheduledDate: siguiente(ahora, hora, diaSemana: dia),
            notificationDetails: detalles,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            payload: payload,
          );
        }
      case Diaria() || NPorSemana():
        await _plugin.zonedSchedule(
          id: base,
          title: titulo,
          body: cuerpo,
          scheduledDate: siguiente(ahora, hora),
          notificationDetails: detalles,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: payload,
        );
    }
    return true;
  }

  /// La próxima vez que toca [hora] después de [ahora] (y, si se da, en el día [diaSemana]: 1 = lunes … 7 = domingo).
  @visibleForTesting
  static tz.TZDateTime siguiente(tz.TZDateTime ahora, HoraRecordatorio hora, {int? diaSemana}) {
    var t = tz.TZDateTime(ahora.location, ahora.year, ahora.month, ahora.day, hora.hora, hora.minuto);
    while (!t.isAfter(ahora) || (diaSemana != null && t.weekday != diaSemana)) {
      t = tz.TZDateTime(t.location, t.year, t.month, t.day + 1, hora.hora, hora.minuto);
    }
    return t;
  }

  @override
  Future<void> cancelar(String habitoId) async {
    await _iniciar();
    final base = idBase(habitoId);
    for (var i = 0; i <= 7; i++) {
      await _plugin.cancel(id: base + i);
    }
  }
}
