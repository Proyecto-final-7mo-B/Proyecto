import 'package:dio/dio.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

/// Agrega `X-Zona-Horaria` (zona IANA del dispositivo) a **todas** las peticiones (contrato §1.1): así la base calcula
/// "hoy" en la hora del usuario y no en UTC.
class InterceptorZonaHoraria extends Interceptor {
  InterceptorZonaHoraria(this._zona);

  static const String cabecera = 'X-Zona-Horaria';

  final ProveedorZonaHoraria _zona;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    options.headers[cabecera] = await _zona.obtener();
    handler.next(options);
  }
}

/// Lee la zona del dispositivo una vez y la recuerda. Si el sistema no la reporta, usa la de respaldo
/// (`KAIZEN_ZONA_DEFECTO`, por omisión `America/Mexico_City`).
class ProveedorZonaHoraria {
  ProveedorZonaHoraria({required this.respaldo, Future<String> Function()? leerDelSistema})
    : _leer = leerDelSistema ?? _leerConPlugin;

  final String respaldo;
  final Future<String> Function() _leer;
  String? _zona;

  static Future<String> _leerConPlugin() async => (await FlutterTimezone.getLocalTimezone()).identifier;

  Future<String> obtener() async {
    final conocida = _zona;
    if (conocida != null) {
      return conocida;
    }
    String zona;
    try {
      zona = (await _leer()).trim();
    } on Object {
      zona = '';
    }
    // Una zona IANA tiene la forma Región/Ciudad (o "UTC"). Lo demás se cambia por la de respaldo.
    final valida = zona == 'UTC' || RegExp(r'^[A-Za-z_]+(/[A-Za-z0-9_+\-]+)+$').hasMatch(zona);
    return _zona = valida ? zona : respaldo;
  }
}
