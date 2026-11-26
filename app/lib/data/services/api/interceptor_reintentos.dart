import 'dart:math';

import 'package:dio/dio.dart';

/// Reintenta **solo lecturas y check-ins** (son idempotentes) ante un 502/503/504 o un error de red: 3 veces, a los
/// 0.2, 0.4 y 0.8 s, con ± 20 % de azar para que no reintenten todos los clientes al mismo tiempo (contrato §3 y §8).
///
/// Nunca reintenta registro, login, restablecer ni operaciones de admin. Tampoco `analitica-no-disponible`, que no se
/// arregla reintentando (el HomeLab está apagado): la pantalla muestra lo último guardado.
class InterceptorReintentos extends Interceptor {
  InterceptorReintentos(this._dio, {Future<void> Function(Duration)? esperar, Random? azar})
    : _esperar = esperar ?? Future<void>.delayed,
      _azar = azar ?? Random();

  static const String marcaIntento = 'kaizen.intento';
  static const List<Duration> esperas = [
    Duration(milliseconds: 200),
    Duration(milliseconds: 400),
    Duration(milliseconds: 800),
  ];

  final Dio _dio;
  final Future<void> Function(Duration) _esperar;
  final Random _azar;

  /// Lecturas (`GET`) y check-ins (`POST /registros` y `/registros/lote`, idempotentes por su `id`).
  static bool esIdempotente(RequestOptions o) =>
      o.method.toUpperCase() == 'GET' ||
      (o.method.toUpperCase() == 'POST' && (o.path == '/registros' || o.path == '/registros/lote'));

  static bool esReintentable(DioException e) {
    final respuesta = e.response;
    if (respuesta == null) {
      return const {
        DioExceptionType.connectionError,
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.unknown,
      }.contains(e.type);
    }
    final datos = respuesta.data;
    final tipo = datos is Map<String, dynamic> ? '${datos['type']}' : '';
    return const {502, 503, 504}.contains(respuesta.statusCode) && !tipo.endsWith('/analitica-no-disponible');
  }

  /// Espera del intento [n] (0, 1, 2) con ± 20 % de azar.
  Duration esperaDe(int n) {
    final base = esperas[n].inMicroseconds;
    return Duration(microseconds: (base * (0.8 + 0.4 * _azar.nextDouble())).round());
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final opciones = err.requestOptions;
    final intento = (opciones.extra[marcaIntento] as int?) ?? 0;
    if (!esIdempotente(opciones) || !esReintentable(err) || intento >= esperas.length) {
      handler.next(err);
      return;
    }
    await _esperar(esperaDe(intento));
    opciones.extra[marcaIntento] = intento + 1;
    try {
      handler.resolve(await _dio.fetch<dynamic>(opciones));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
