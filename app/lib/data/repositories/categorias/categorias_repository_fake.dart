import '../../../domain/models/categoria.dart';
import '../../../utils/result.dart';
import '../../fake/datos_demo.dart';
import 'categorias_repository.dart';

class CategoriasRepositoryFake implements CategoriasRepository {
  CategoriasRepositoryFake(this._datos);

  final DatosDemo _datos;

  /// Como `GET /categorias` (v1.6): solo activas, en el orden del catálogo, con sus subcategorías activas.
  @override
  Future<Result<List<Categoria>>> listar() => _datos.ejecutar(() {
    _datos.usuarioDeSesion();
    return [
      for (final c in _datos.categorias)
        if (c.activa)
          Categoria(
            id: c.id,
            clave: c.clave,
            nombre: c.nombre,
            color: c.color,
            icono: c.icono,
            subcategorias: [
              for (final s in c.subcategorias)
                if (s.activa) s,
            ],
          ),
    ];
  });
}
