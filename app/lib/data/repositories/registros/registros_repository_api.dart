import '../../../domain/models/registro.dart';
import '../../../utils/result.dart';
import '../../services/api/cliente_api.dart';
import 'registros_repository.dart';

class RegistrosRepositoryApi implements RegistrosRepository {
  RegistrosRepositoryApi(this._api);

  static const int maximoPorLote = 100;

  final ClienteApi _api;

  @override
  Future<Result<ResultadoCheckin>> registrar(NuevoRegistro registro) =>
      _api.post('/registros', (d) => ResultadoCheckin.fromJson(d as Map<String, dynamic>), datos: registro.toJson());

  @override
  Future<Result<ResultadoLote>> registrarLote(List<NuevoRegistro> registros) {
    assert(registros.length <= maximoPorLote, 'Máximo $maximoPorLote por lote');
    return _api.post(
      '/registros/lote',
      (d) => ResultadoLote.fromJson(d as Map<String, dynamic>),
      datos: {
        'registros': [for (final r in registros) r.toJson()],
      },
    );
  }
}
