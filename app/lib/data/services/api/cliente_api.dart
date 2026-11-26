import 'dart:math';

import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../../domain/models/sesion.dart';
import '../../../utils/result.dart';
import '../gestor_tokens.dart';
import 'errores_api.dart';
import 'interceptor_auth.dart';
import 'interceptor_reintentos.dart';
import 'interceptor_zona_horaria.dart';

/// Cliente HTTP de la API (`dio`) con sus interceptores, en este orden: zona horaria → autenticación → reintentos.
///
/// Los repositorios `_api` lo usan y reciben un [Result]: los errores de red y los problem+json se convierten en
/// [ErrorApp] aquí, así que ninguna excepción de `dio` sale de la capa de datos.
class ClienteApi {
  ClienteApi({
    required String baseUrl,
    required this.tokens,
    required ProveedorZonaHoraria zonaHoraria,
    HttpClientAdapter? adaptador,
    Future<void> Function(Duration)? esperar,
    Random? azar,
  }) : dio = Dio(_opciones(baseUrl)),
       _dioRenovar = Dio(_opciones(baseUrl)) {
    if (adaptador != null) {
      dio.httpClientAdapter = adaptador;
      _dioRenovar.httpClientAdapter = adaptador;
    }
    dio.interceptors.addAll([
      InterceptorZonaHoraria(zonaHoraria),
      InterceptorAuth(tokens, dio),
      InterceptorReintentos(dio, esperar: esperar, azar: azar),
    ]);
    // La renovación va por un cliente sin el interceptor de autenticación (si no, un 401 ahí volvería a renovar).
    _dioRenovar.interceptors.add(InterceptorZonaHoraria(zonaHoraria));
    tokens.renovador = renovar;
  }

  final Dio dio;
  final Dio _dioRenovar;
  final GestorTokens tokens;

  static BaseOptions _opciones(String baseUrl) => BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    contentType: Headers.jsonContentType,
    responseType: ResponseType.json,
    headers: {'Accept': 'application/json, application/problem+json'},
  );

  /// `POST /auth/renovar`.
  Future<Result<Tokens>> renovar(String tokenRenovacion) => _enviar(
    () => _dioRenovar.post<dynamic>('/auth/renovar', data: {'token_renovacion': tokenRenovacion}),
    (d) => Tokens.fromJson(d as Map<String, dynamic>),
  );

  Future<Result<T>> get<T>(String ruta, T Function(dynamic datos) convertir, {Map<String, dynamic>? parametros}) =>
      _enviar(() => dio.get<dynamic>(ruta, queryParameters: parametros), convertir);

  Future<Result<T>> post<T>(String ruta, T Function(dynamic datos) convertir, {Object? datos}) =>
      _enviar(() => dio.post<dynamic>(ruta, data: datos), convertir);

  Future<Result<T>> patch<T>(String ruta, T Function(dynamic datos) convertir, {Object? datos}) =>
      _enviar(() => dio.patch<dynamic>(ruta, data: datos), convertir);

  Future<Result<T>> put<T>(String ruta, T Function(dynamic datos) convertir, {Object? datos}) =>
      _enviar(() => dio.put<dynamic>(ruta, data: datos), convertir);

  Future<Result<T>> delete<T>(String ruta, T Function(dynamic datos) convertir, {Object? datos}) =>
      _enviar(() => dio.delete<dynamic>(ruta, data: datos), convertir);

  /// Para respuestas sin cuerpo (204).
  static void sinCuerpo(dynamic _) {}

  Future<Result<T>> _enviar<T>(Future<Response<dynamic>> Function() peticion, T Function(dynamic) convertir) async {
    try {
      final respuesta = await peticion();
      return Result.exito(convertir(respuesta.data));
    } on DioException catch (e) {
      return Result.fallo(ErrorApp.desdeDio(e));
    } on CheckedFromJsonException {
      // La respuesta no tiene la forma del contrato.
      return const Result.fallo(ErrorApp(TipoError.desconocido));
    } on FormatException {
      return const Result.fallo(ErrorApp(TipoError.desconocido));
    } on TypeError {
      // La respuesta no tiene la forma del contrato.
      return const Result.fallo(ErrorApp(TipoError.desconocido));
    }
  }
}
