import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Respuesta preparada para [AdaptadorFalso]. Con [sinRed] simula que no hubo conexión.
class RespuestaFalsa {
  const RespuestaFalsa(this.status, [this.cuerpo, this.cabeceras = const {}]) : sinRed = false;
  const RespuestaFalsa.sinRed() : status = 0, cuerpo = null, cabeceras = const {}, sinRed = true;

  /// problem+json del contrato.
  factory RespuestaFalsa.problema(
    int status,
    String sufijo, {
    Map<String, dynamic> extras = const {},
    Map<String, String> cabeceras = const {},
  }) => RespuestaFalsa(status, {
    'type': 'https://kaizen.app/errores/$sufijo',
    'title': sufijo,
    'status': status,
    ...extras,
  }, cabeceras);

  final int status;
  final Object? cuerpo;
  final Map<String, String> cabeceras;
  final bool sinRed;
}

/// Sustituye la red de `dio`: registra cada petición y responde lo que diga [responder].
class AdaptadorFalso implements HttpClientAdapter {
  AdaptadorFalso(this.responder);

  FutureOr<RespuestaFalsa> Function(RequestOptions peticion) responder;
  final List<RequestOptions> peticiones = [];

  List<String> get rutas => [for (final p in peticiones) '${p.method} ${p.path}'];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    peticiones.add(options);
    final r = await responder(options);
    if (r.sinRed) {
      throw DioException.connectionError(requestOptions: options, reason: 'sin red (prueba)');
    }
    final tipo = r.status >= 400 ? 'application/problem+json' : 'application/json';
    return ResponseBody.fromString(
      r.cuerpo == null ? '' : jsonEncode(r.cuerpo),
      r.status,
      headers: {
        Headers.contentTypeHeader: [tipo],
        for (final e in r.cabeceras.entries) e.key.toLowerCase(): [e.value],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
