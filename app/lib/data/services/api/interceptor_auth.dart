import 'package:dio/dio.dart';

import '../gestor_tokens.dart';

/// Pone `Authorization: Bearer <token de acceso>` y, ante un 401, renueva **una sola vez** y repite la petición
/// (contrato §2.1). Si la renovación falla, deja pasar el 401: el gestor ya avisó que la sesión expiró.
class InterceptorAuth extends Interceptor {
  InterceptorAuth(this._tokens, this._dio);

  /// Marca de una petición que ya se repitió tras renovar (para no entrar en un ciclo).
  static const String marcaReintento = 'kaizen.reintento_auth';

  final GestorTokens _tokens;
  final Dio _dio;

  /// `/auth/*` no lleva token, salvo `/auth/salir`, que lo exige.
  static bool llevaToken(String ruta) => !ruta.startsWith('/auth/') || ruta == '/auth/salir';

  /// `/auth/*` nunca se renueva y repite: un 401 ahí significa credenciales o token de renovación inválidos.
  static bool puedeRenovar(String ruta) => !ruta.startsWith('/auth/');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokens.tokenAcceso;
    if (token != null && llevaToken(options.path)) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final opciones = err.requestOptions;
    final es401 = err.response?.statusCode == 401;
    if (!es401 || !puedeRenovar(opciones.path) || opciones.extra[marcaReintento] == true) {
      handler.next(err);
      return;
    }
    if (!await _tokens.renovar()) {
      handler.next(err);
      return;
    }
    opciones.extra[marcaReintento] = true;
    opciones.headers['Authorization'] = 'Bearer ${_tokens.tokenAcceso}';
    try {
      handler.resolve(await _dio.fetch<dynamic>(opciones));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
