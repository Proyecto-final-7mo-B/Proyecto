import '../../data/services/api/errores_api.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../utils/validadores.dart';

/// Texto en español para cada error de validación (los validadores no dependen de la interfaz).
String mensajeValidacion(ErrorValidacion error, AppLocalizations t) => switch (error) {
  ErrorValidacion.requerido => t.validacionRequerido,
  ErrorValidacion.muyLargo => t.validacionMuyLargo,
  ErrorValidacion.muyCorto => t.validacionMuyCorto,
  ErrorValidacion.correoInvalido => t.validacionCorreo,
  ErrorValidacion.contrasenaCorta => t.validacionContrasenaCorta,
  ErrorValidacion.contrasenaLarga => t.validacionContrasenaLarga,
  ErrorValidacion.contrasenaIgualAlCorreo => t.validacionContrasenaCorreo,
  ErrorValidacion.contrasenasDistintas => t.validacionContrasenasDistintas,
  ErrorValidacion.numeroInvalido => t.validacionNumero,
  ErrorValidacion.debeSerMayorACero => t.validacionMayorACero,
  ErrorValidacion.noNegativo => t.validacionNoNegativo,
  ErrorValidacion.maximoDosDecimales => t.validacionDosDecimales,
  ErrorValidacion.fueraDeRango => t.validacionFueraDeRango,
  ErrorValidacion.mensajeMuyLargo => t.validacionMensajeLargo,
  ErrorValidacion.rangoFechasInvalido => t.validacionRangoFechas,
};

/// Convierte un validador de `utils/validadores.dart` en uno para `TextFormField`.
String? Function(String?) validadorDe(ErrorValidacion? Function(String?) validar, AppLocalizations t) =>
    (valor) => switch (validar(valor)) {
      null => null,
      final e => mensajeValidacion(e, t),
    };

/// Texto para el usuario de cada error de la API (contrato §3, columna "Qué hace la app").
String mensajeDeError(ErrorApp error, AppLocalizations t) => switch (error.tipo) {
  TipoError.validacion => t.errorValidacion,
  TipoError.regionInvalida => t.errorRegionInvalida,
  TipoError.fechaFueraDeRango => t.errorFechaFueraDeRango,
  TipoError.categoriaInactiva => t.errorCategoriaInactiva,
  TipoError.enlaceInvalido => t.errorEnlaceInvalido,
  TipoError.credencialesInvalidas => t.errorCredenciales,
  TipoError.tokenInvalido => t.errorTokenInvalido,
  TipoError.tokenReutilizado => t.errorTokenReutilizado,
  TipoError.consentimientoRequerido => t.errorConsentimiento,
  TipoError.rolInsuficiente => t.errorRolInsuficiente,
  TipoError.cuentaSuspendida => t.errorCuentaSuspendida,
  TipoError.noEncontrado => t.errorNoEncontrado,
  TipoError.registroRechazado => t.errorRegistroRechazado,
  TipoError.capsulaSellada => error.problema?.detail ?? t.errorCapsulaSellada,
  TipoError.sugerenciaResuelta => t.errorSugerenciaResuelta,
  TipoError.operacionNoPermitida => error.problema?.detail ?? t.errorOperacionNoPermitida,
  TipoError.habitoArchivado => t.errorHabitoArchivado,
  TipoError.nombreDuplicado => t.errorNombreDuplicado,
  TipoError.cuentaBloqueada => t.errorCuentaBloqueada(_minutos(error.reintentarEn)),
  TipoError.demasiadasPeticiones => t.errorDemasiadasPeticiones,
  TipoError.primarioNoDisponible => t.errorPrimarioNoDisponible,
  TipoError.analiticaNoDisponible => t.errorAnaliticaNoDisponible,
  TipoError.servicioNoDisponible => t.errorServicioNoDisponible,
  TipoError.errorInterno => switch (error.problema?.idPeticion) {
    final String id => t.errorInternoConId(id),
    null => t.errorGenerico,
  },
  TipoError.sinConexion => t.errorSinConexion,
  TipoError.tiempoAgotado => t.errorTiempoAgotado,
  TipoError.desconocido => t.errorGenerico,
};

/// Minutos que faltan (redondeando hacia arriba; mínimo 1). Sin `Retry-After`, los 15 del bloqueo.
int _minutos(Duration? espera) {
  if (espera == null) {
    return 15;
  }
  final minutos = (espera.inSeconds / 60).ceil();
  return minutos < 1 ? 1 : minutos;
}
