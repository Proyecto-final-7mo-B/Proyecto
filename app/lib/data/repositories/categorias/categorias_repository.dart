import '../../../domain/models/categoria.dart';
import '../../../utils/result.dart';

abstract interface class CategoriasRepository {
  /// `GET /categorias`: solo las activas, ordenadas por nombre.
  Future<Result<List<Categoria>>> listar();
}
