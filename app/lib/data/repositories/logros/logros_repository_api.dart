import '../../../domain/models/logro.dart';
import '../../../utils/result.dart';
import '../../services/api/cliente_api.dart';
import 'logros_repository.dart';

class LogrosRepositoryApi implements LogrosRepository {
  LogrosRepositoryApi(this._api);

  final ClienteApi _api;

  @override
  Future<Result<List<Logro>>> listar() =>
      _api.get('/logros', (d) => [for (final l in d as List<dynamic>) Logro.fromJson(l as Map<String, dynamic>)]);
}
