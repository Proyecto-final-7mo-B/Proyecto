import 'package:dio/dio.dart';

import '../../../domain/models/problema.dart';

/// Tipos de error del contrato (§3) más los de red. La pantalla decide el texto con `mensajeDeError` (ui/core).
enum TipoError {
  validacion,
  regionInvalida,
  fechaFueraDeRango,
  categoriaInactiva,
  subcategoriaInactiva,
  unidadNoPermitida,
  recomendacionNoDisponible,
  enlaceInvalido,
  credencialesInvalidas,
  tokenInvalido,
  tokenReutilizado,
  consentimientoRequerido,
  rolInsuficiente,
  cuentaSuspendida,
  noEncontrado,
  registroRechazado,
  capsulaSellada,
  sugerenciaResuelta,
  operacionNoPermitida,
  habitoArchivado,
  nombreDuplicado,
  cuentaBloqueada,
  demasiadasPeticiones,
  primarioNoDisponible,
  analiticaNoDisponible,
  servicioNoDisponible,
  errorInterno,

  /// Sin red o el servidor no contestó (no hubo respuesta HTTP).
  sinConexion,
  tiempoAgotado,
  desconocido;

  /// Sufijo del `type` de problem+json (`capsula-sellada`) → tipo.
  static TipoError desdeSufijo(String sufijo) => _porSufijo[sufijo] ?? TipoError.desconocido;

  /// Tipo → sufijo del `type` (`capsula-sellada`); `null` para los errores de red, que no vienen del servidor.
  String? get sufijo => _porSufijo.entries.where((e) => e.value == this).firstOrNull?.key;

  static const Map<String, TipoError> _porSufijo = {
    'validacion': validacion,
    'region-invalida': regionInvalida,
    'fecha-fuera-de-rango': fechaFueraDeRango,
    'categoria-inactiva': categoriaInactiva,
    'subcategoria-inactiva': subcategoriaInactiva,
    'unidad-no-permitida': unidadNoPermitida,
    'recomendacion-no-disponible': recomendacionNoDisponible,
    'enlace-invalido': enlaceInvalido,
    'credenciales-invalidas': credencialesInvalidas,
    'token-invalido': tokenInvalido,
    'token-reutilizado': tokenReutilizado,
    'consentimiento-requerido': consentimientoRequerido,
    'rol-insuficiente': rolInsuficiente,
    'cuenta-suspendida': cuentaSuspendida,
    'no-encontrado': noEncontrado,
    'registro-rechazado': registroRechazado,
    'capsula-sellada': capsulaSellada,
    'sugerencia-resuelta': sugerenciaResuelta,
    'operacion-no-permitida': operacionNoPermitida,
    'habito-archivado': habitoArchivado,
    'nombre-duplicado': nombreDuplicado,
    'cuenta-bloqueada': cuentaBloqueada,
    'demasiadas-peticiones': demasiadasPeticiones,
    'primario-no-disponible': primarioNoDisponible,
    'analitica-no-disponible': analiticaNoDisponible,
    'servicio-no-disponible': servicioNoDisponible,
    'error-interno': errorInterno,
  };
}

/// Error que cruza de la capa de datos a la de interfaz (dentro de un `Fallo`). Nunca lleva tokens ni contraseñas.
class ErrorApp implements Exception {
  const ErrorApp(this.tipo, {this.problema, this.status, this.reintentarEn});

  /// A partir del cuerpo problem+json.
  factory ErrorApp.desdeProblema(Problema problema, {Duration? reintentarEn}) => ErrorApp(
    TipoError.desdeSufijo(problema.tipo),
    problema: problema,
    status: problema.status,
    reintentarEn: reintentarEn,
  );

  /// A partir de un error de `dio` (con o sin respuesta del servidor).
  factory ErrorApp.desdeDio(DioException e) {
    if (e.error is ErrorApp) {
      return e.error! as ErrorApp;
    }
    final respuesta = e.response;
    if (respuesta == null) {
      return switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => const ErrorApp(TipoError.tiempoAgotado),
        DioExceptionType.connectionError || DioExceptionType.unknown => const ErrorApp(TipoError.sinConexion),
        _ => const ErrorApp(TipoError.desconocido),
      };
    }
    final reintentar = _retryAfter(respuesta.headers.value('retry-after'));
    final datos = respuesta.data;
    if (datos is Map<String, dynamic> && datos['type'] is String) {
      return ErrorApp.desdeProblema(Problema.fromJson(datos), reintentarEn: reintentar);
    }
    final status = respuesta.statusCode ?? 0;
    final tipo = switch (status) {
      401 => TipoError.tokenInvalido,
      403 => TipoError.rolInsuficiente,
      404 => TipoError.noEncontrado,
      429 => TipoError.demasiadasPeticiones,
      502 || 503 || 504 => TipoError.servicioNoDisponible,
      >= 500 => TipoError.errorInterno,
      _ => TipoError.desconocido,
    };
    return ErrorApp(tipo, status: status, reintentarEn: reintentar);
  }

  final TipoError tipo;
  final Problema? problema;
  final int? status;

  /// De la cabecera `Retry-After` (429 de bloqueo o de límite de tasa).
  final Duration? reintentarEn;

  /// Errores por campo de un 422.
  List<ErrorDeCampo> get errores => problema?.errores ?? const [];

  /// Detalle del servidor para un campo (p. ej., `contrasena`), o `null`.
  String? errorDe(String campo) => errores.where((e) => e.campo == campo).firstOrNull?.detalle;

  /// Errores en los que conviene usar lo guardado localmente o encolar (no son culpa del usuario).
  bool get esDeRed => const {
    TipoError.sinConexion,
    TipoError.tiempoAgotado,
    TipoError.servicioNoDisponible,
    TipoError.primarioNoDisponible,
  }.contains(tipo);

  /// La sesión ya no vale: hay que volver a entrar.
  bool get cierraSesion =>
      const {TipoError.tokenInvalido, TipoError.tokenReutilizado, TipoError.cuentaSuspendida}.contains(tipo);

  static Duration? _retryAfter(String? valor) {
    final segundos = int.tryParse(valor?.trim() ?? '');
    return segundos == null ? null : Duration(seconds: segundos);
  }

  @override
  String toString() => 'ErrorApp(${tipo.name}${status == null ? '' : ', $status'})';
}
