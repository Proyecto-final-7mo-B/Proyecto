import '../../../domain/models/categoria.dart';
import '../../../domain/models/recomendacion.dart';
import '../../../utils/result.dart';

abstract interface class CategoriasRepository {
  /// `GET /categorias` (v1.6): el árbol de categorías activas, en su orden, con sus subcategorías, unidades
  /// permitidas y referencia científica.
  Future<Result<List<Categoria>>> listar();

  /// `GET /fuentes` (v1.7): las fuentes de la investigación, para "Acerca de Kaizen".
  Future<Result<List<FuenteCientifica>>> fuentes();
}
