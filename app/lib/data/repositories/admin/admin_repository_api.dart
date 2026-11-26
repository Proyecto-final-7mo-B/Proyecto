import '../../../domain/models/admin.dart';
import '../../../domain/models/categoria.dart';
import '../../../utils/result.dart';
import '../../services/api/cliente_api.dart';
import 'admin_repository.dart';

class AdminRepositoryApi implements AdminRepository {
  AdminRepositoryApi(this._api);

  final ClienteApi _api;

  static Categoria _categoria(dynamic d) => Categoria.fromJson(d as Map<String, dynamic>);
  static UsuarioAdmin _usuario(dynamic d) => UsuarioAdmin.fromJson(d as Map<String, dynamic>);

  @override
  Future<Result<Pagina<UsuarioAdmin>>> usuarios(FiltroUsuarios filtro) => _api.get(
    '/admin/usuarios',
    (d) => Pagina.fromJson(d as Map<String, dynamic>, UsuarioAdmin.fromJson),
    parametros: filtro.aParametros(),
  );

  @override
  Future<Result<UsuarioAdmin>> cambiarSuspension(String id, {required bool suspendido, String? motivo}) => _api.patch(
    '/admin/usuarios/${Uri.encodeComponent(id)}',
    _usuario,
    datos: {'suspendido': suspendido, if (suspendido) 'motivo': motivo},
  );

  @override
  Future<Result<MetricasAdmin>> metricas() =>
      _api.get('/admin/metricas', (d) => MetricasAdmin.fromJson(d as Map<String, dynamic>));

  @override
  Future<Result<List<Categoria>>> categorias() =>
      _api.get('/admin/categorias', (d) => [for (final c in d as List<dynamic>) _categoria(c)]);

  @override
  Future<Result<Categoria>> crearCategoria(String nombre) =>
      _api.post('/admin/categorias', _categoria, datos: {'nombre': nombre.trim()});

  @override
  Future<Result<Categoria>> actualizarCategoria(String id, {String? nombre, bool? activa}) => _api.patch(
    '/admin/categorias/${Uri.encodeComponent(id)}',
    _categoria,
    datos: {'nombre': ?nombre?.trim(), 'activa': ?activa},
  );

  @override
  Future<Result<Indicador>> indicador(String codigo) => _api.get(
    '/admin/indicadores/${Uri.encodeComponent(codigo)}',
    (d) => Indicador.fromJson(d as Map<String, dynamic>),
  );
}
