import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdatos;
import 'package:timezone/timezone.dart' as tz;

import '../../../domain/models/avisos.dart';
import 'notificador.dart';

/// Notificaciones locales en Android e iOS (`flutter_local_notifications`).
///
/// - Cada plan **reemplaza** al anterior: se cancela todo lo de Kaizen y se programan avisos de una sola vez para los
///   próximos 7 días. La app vuelve a planear al abrirse, al volver al frente, con cada check-in y al cambiar las
///   preferencias, así que lo programado siempre refleja lo que falta hoy.
/// - Lo que el usuario programó a una hora (sus avisos y los recordatorios) va a la **hora exacta** si Android lo
///   permite ("Alarmas y recordatorios"; en Android 14 hay que activarlo). Si no, y para los automáticos, horario
///   **inexacto**: Android puede retrasarlo unos minutos. El *plugin* reprograma los avisos si el teléfono se reinicia.
/// - Un canal por tipo, para que el usuario también pueda apagarlos desde los ajustes del sistema.
class NotificadorLocal implements Notificador {
  NotificadorLocal({
    FlutterLocalNotificationsPlugin? plugin,
    Future<String> Function()? zonaDelSistema,
    Future<bool> Function()? pedirPermiso,
    Future<bool> Function()? horaExacta,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _zonaDelSistema = zonaDelSistema ?? _leerZona,
       _pedirPermisoInyectado = pedirPermiso,
       _horaExactaInyectada = horaExacta;

  final FlutterLocalNotificationsPlugin _plugin;
  final Future<String> Function() _zonaDelSistema;
  final Future<bool> Function()? _pedirPermisoInyectado;
  final Future<bool> Function()? _horaExactaInyectada;
  Future<void>? _inicio;

  static Future<String> _leerZona() async => (await FlutterTimezone.getLocalTimezone()).identifier;

  @override
  bool get disponible => true;

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

  @override
  Future<bool> pedirPermiso() async {
    await _iniciar();
    final inyectado = _pedirPermisoInyectado;
    if (inyectado != null) {
      return inyectado();
    }
    final android = _android;
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  @override
  Future<bool> horaExacta() async {
    await _iniciar();
    final inyectada = _horaExactaInyectada;
    if (inyectada != null) {
      return inyectada();
    }
    final android = _android;
    // iOS no distingue: lo programado llega a su hora.
    return android == null || (await android.canScheduleExactNotifications() ?? false);
  }

  @override
  Future<bool> pedirHoraExacta() async {
    await _iniciar();
    final android = _android;
    if (android != null && _horaExactaInyectada == null) {
      await android.requestExactAlarmsPermission();
    }
    return horaExacta();
  }

  /// Modo de Android: exacto para lo que el usuario puso a una hora (si se puede), inexacto para lo demás.
  @visibleForTesting
  static AndroidScheduleMode modo(TipoAviso tipo, {required bool exacta}) =>
      exacta && !tipo.automatico ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle;

  /// Canal de Android de cada tipo (id y nombre visible en los ajustes del sistema).
  @visibleForTesting
  static (String, String) canal(TipoAviso tipo) => switch (tipo) {
    TipoAviso.recordatorio => ('recordatorios', 'Recordatorios de tus hábitos'),
    TipoAviso.personal => ('mis_avisos', 'Mis avisos'),
    TipoAviso.rachaEnRiesgo => ('racha', 'Racha en riesgo'),
    TipoAviso.microPaso => ('escalera', 'Micro-pasos de la Escalera'),
    TipoAviso.resumenSemanal => ('resumen', 'Resumen semanal'),
  };

  /// La hora local de [a] en la zona del dispositivo.
  @visibleForTesting
  static tz.TZDateTime enZona(DateTime cuando) =>
      tz.TZDateTime(tz.local, cuando.year, cuando.month, cuando.day, cuando.hour, cuando.minute);

  @override
  Future<void> reemplazar(List<AvisoProgramado> avisos) async {
    await _iniciar();
    await _plugin.cancelAll();
    final exacta = avisos.isNotEmpty && await horaExacta();
    for (final a in avisos) {
      final (id, nombre) = canal(a.tipo);
      await _plugin.zonedSchedule(
        id: a.id,
        title: a.titulo,
        body: a.cuerpo,
        scheduledDate: enZona(a.cuando),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            id,
            nombre,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: modo(a.tipo, exacta: exacta),
        payload: jsonEncode({'tipo': a.tipo.name, 'habito': ?a.habitoId}),
      );
    }
  }
}
