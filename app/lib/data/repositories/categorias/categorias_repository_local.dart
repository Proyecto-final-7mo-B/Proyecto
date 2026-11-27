import '../../../domain/models/categoria.dart';
import '../../../utils/result.dart';
import '../../services/base_local/almacen_local.dart';
import '../cache.dart';
import 'categorias_repository.dart';

/// Catálogo con copia local: sin conexión se sigue pudiendo ver (y elegir) la categoría.
class CategoriasRepositoryLocal implements CategoriasRepository {
  CategoriasRepositoryLocal({required this.remoto, required this.almacen, this.reportar});

  final CategoriasRepository remoto;
  final AlmacenLocal almacen;
  final ReportarRed? reportar;

  @override
  Future<Result<List<Categoria>>> listar() => leerConCache(
    remoto: remoto.listar,
    guardar: almacen.guardarCategorias,
    local: () async {
      final lista = await almacen.categorias();
      return lista.isEmpty ? null : lista;
    },
    reportar: reportar,
  );
}
