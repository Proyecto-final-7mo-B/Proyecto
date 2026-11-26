import '../../../domain/models/usuario.dart';
import '../../../utils/result.dart';

/// Cuenta y derechos ARCO.
abstract interface class CuentaRepository {
  /// `GET /cuenta`.
  Future<Result<Cuenta>> obtener();

  /// `PATCH /cuenta`.
  Future<Result<Cuenta>> cambiarNombre(String nombre);

  /// `PUT /cuenta/contrasena`: revoca las demás sesiones; la actual sigue abierta.
  Future<Result<void>> cambiarContrasena({required String actual, required String nueva});

  /// `PUT /cuenta/consentimientos`. Retirarlo borra las señales.
  Future<Result<ResultadoConsentimiento>> cambiarConsentimiento({required bool senales});

  /// `GET /cuenta/datos`: el JSON descargable con todos los datos.
  Future<Result<Map<String, dynamic>>> exportarDatos();

  /// `DELETE /cuenta`: borra todo en cascada.
  Future<Result<void>> eliminar({required String contrasena});
}
