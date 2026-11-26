import '../../../domain/models/capsula.dart';
import '../../../utils/result.dart';
import '../../services/api/cliente_api.dart';
import 'capsulas_repository.dart';

class CapsulasRepositoryApi implements CapsulasRepository {
  CapsulasRepositoryApi(this._api);

  final ClienteApi _api;

  static Capsula _capsula(dynamic d) => Capsula.fromJson(d as Map<String, dynamic>);

  @override
  Future<Result<Capsula>> crear(NuevaCapsula nueva) => _api.post('/capsulas', _capsula, datos: nueva.toJson());

  @override
  Future<Result<List<Capsula>>> listar({EstadoCapsula? estado}) => _api.get(
    '/capsulas',
    (d) => [for (final c in d as List<dynamic>) _capsula(c)],
    parametros: {'estado': ?estado?.name},
  );

  @override
  Future<Result<CapsulaAbierta>> abrir(String id) => _api.post(
    '/capsulas/${Uri.encodeComponent(id)}/abrir',
    (d) => CapsulaAbierta.fromJson(d as Map<String, dynamic>),
  );
}
