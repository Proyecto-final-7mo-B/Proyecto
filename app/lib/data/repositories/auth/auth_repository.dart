import '../../../domain/models/sesion.dart';
import '../../../utils/result.dart';

/// Autenticación (`/auth`). Los tokens que devuelve los guarda el servicio de sesión, no el repositorio.
abstract interface class AuthRepository {
  /// `POST /auth/login`.
  Future<Result<Tokens>> entrar({required String email, required String contrasena});

  /// `POST /auth/registro`: deja la sesión iniciada.
  Future<Result<Tokens>> registrar(SolicitudRegistro solicitud);

  /// `POST /auth/renovar`.
  Future<Result<Tokens>> renovar(String tokenRenovacion);

  /// `POST /auth/salir`: revoca esa sesión en el servidor.
  Future<Result<void>> salir(String tokenRenovacion);

  /// `POST /auth/recuperar`: siempre responde igual, exista o no la cuenta.
  Future<Result<void>> recuperar(String email);

  /// `POST /auth/restablecer`.
  Future<Result<void>> restablecer({required String token, required String nueva});
}
