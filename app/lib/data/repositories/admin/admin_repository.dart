import '../../../domain/models/admin.dart';
import '../../../domain/models/categoria.dart';
import '../../../utils/result.dart';

/// Panel de administración (solo rol admin, escritorio y web). La API y la base vuelven a verificar el rol.
abstract interface class AdminRepository {
  /// `GET /admin/usuarios` (paginado, datos enmascarados).
  Future<Result<Pagina<UsuarioAdmin>>> usuarios(FiltroUsuarios filtro);

  /// `PATCH /admin/usuarios/{id}`: suspender exige motivo de 3–200 caracteres.
  Future<Result<UsuarioAdmin>> cambiarSuspension(String id, {required bool suspendido, String? motivo});

  /// `GET /admin/metricas`.
  Future<Result<MetricasAdmin>> metricas();

  /// `GET /admin/categorias` (incluye las inactivas).
  Future<Result<List<Categoria>>> categorias();

  /// `POST /admin/categorias`.
  Future<Result<Categoria>> crearCategoria(String nombre);

  /// `PATCH /admin/categorias/{id}`.
  Future<Result<Categoria>> actualizarCategoria(String id, {String? nombre, bool? activa});

  /// `GET /admin/indicadores/{I1…I6}`.
  Future<Result<Indicador>> indicador(String codigo);
}
