import '../../../domain/models/categoria.dart';
import '../../../utils/result.dart';
import '../../services/api/cliente_api.dart';
import 'categorias_repository.dart';

class CategoriasRepositoryApi implements CategoriasRepository {
  CategoriasRepositoryApi(this._api);

  final ClienteApi _api;

  @override
  Future<Result<List<Categoria>>> listar() => _api.get(
    '/categorias',
    (d) => [for (final c in d as List<dynamic>) Categoria.fromJson(c as Map<String, dynamic>)],
  );
}
