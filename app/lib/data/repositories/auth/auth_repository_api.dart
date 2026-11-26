import '../../../domain/models/sesion.dart';
import '../../../utils/result.dart';
import '../../../utils/validadores.dart';
import '../../services/api/cliente_api.dart';
import 'auth_repository.dart';

class AuthRepositoryApi implements AuthRepository {
  AuthRepositoryApi(this._api);

  final ClienteApi _api;

  static Tokens _tokens(dynamic d) => Tokens.fromJson(d as Map<String, dynamic>);

  @override
  Future<Result<Tokens>> entrar({required String email, required String contrasena}) => _api.post(
    '/auth/login',
    _tokens,
    datos: {'email': Validadores.normalizarCorreo(email), 'contrasena': contrasena},
  );

  @override
  Future<Result<Tokens>> registrar(SolicitudRegistro solicitud) =>
      _api.post('/auth/registro', _tokens, datos: solicitud.toJson());

  @override
  Future<Result<Tokens>> renovar(String tokenRenovacion) => _api.renovar(tokenRenovacion);

  @override
  Future<Result<void>> salir(String tokenRenovacion) =>
      _api.post('/auth/salir', ClienteApi.sinCuerpo, datos: {'token_renovacion': tokenRenovacion});

  @override
  Future<Result<void>> recuperar(String email) =>
      _api.post('/auth/recuperar', ClienteApi.sinCuerpo, datos: {'email': Validadores.normalizarCorreo(email)});

  @override
  Future<Result<void>> restablecer({required String token, required String nueva}) =>
      _api.post('/auth/restablecer', ClienteApi.sinCuerpo, datos: {'token': token, 'nueva': nueva});
}
