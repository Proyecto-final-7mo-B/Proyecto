import '../../../domain/models/categoria.dart';
import '../../../utils/result.dart';
import '../../fake/datos_demo.dart';
import 'categorias_repository.dart';

class CategoriasRepositoryFake implements CategoriasRepository {
  CategoriasRepositoryFake(this._datos);

  final DatosDemo _datos;

  @override
  Future<Result<List<Categoria>>> listar() => _datos.ejecutar(() {
    _datos.usuarioDeSesion();
    return [
      for (final c in _datos.categorias)
        if (c.activa) Categoria(id: c.id, nombre: c.nombre),
    ]..sort((a, b) => a.nombre.compareTo(b.nombre));
  });
}
