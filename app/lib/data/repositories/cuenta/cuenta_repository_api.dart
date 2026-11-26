import '../../../domain/models/usuario.dart';
import '../../../utils/result.dart';
import '../../services/api/cliente_api.dart';
import 'cuenta_repository.dart';

class CuentaRepositoryApi implements CuentaRepository {
  CuentaRepositoryApi(this._api);

  final ClienteApi _api;

  static Cuenta _cuenta(dynamic d) => Cuenta.fromJson(d as Map<String, dynamic>);

  @override
  Future<Result<Cuenta>> obtener() => _api.get('/cuenta', _cuenta);

  @override
  Future<Result<Cuenta>> cambiarNombre(String nombre) => _api.patch('/cuenta', _cuenta, datos: {'nombre': nombre});

  @override
  Future<Result<void>> cambiarContrasena({required String actual, required String nueva}) =>
      _api.put('/cuenta/contrasena', ClienteApi.sinCuerpo, datos: {'actual': actual, 'nueva': nueva});

  @override
  Future<Result<ResultadoConsentimiento>> cambiarConsentimiento({required bool senales}) => _api.put(
    '/cuenta/consentimientos',
    (d) => ResultadoConsentimiento.fromJson(d as Map<String, dynamic>),
    datos: {'senales': senales},
  );

  @override
  Future<Result<Map<String, dynamic>>> exportarDatos() => _api.get('/cuenta/datos', (d) => d as Map<String, dynamic>);

  @override
  Future<Result<void>> eliminar({required String contrasena}) =>
      _api.delete('/cuenta', ClienteApi.sinCuerpo, datos: {'contrasena': contrasena});
}
