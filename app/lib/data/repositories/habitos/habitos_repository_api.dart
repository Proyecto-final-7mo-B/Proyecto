import '../../../domain/models/escalera.dart';
import '../../../domain/models/habito.dart';
import '../../../domain/models/registro.dart';
import '../../../utils/fechas.dart';
import '../../../utils/result.dart';
import '../../services/api/cliente_api.dart';
import 'habitos_repository.dart';

class HabitosRepositoryApi implements HabitosRepository {
  HabitosRepositoryApi(this._api);

  final ClienteApi _api;

  static Habito _habito(dynamic d) => Habito.fromJson(d as Map<String, dynamic>);
  static String _ruta(String id) => '/habitos/${Uri.encodeComponent(id)}';

  @override
  Future<Result<List<Habito>>> listar({required DateTime fecha, bool archivados = false}) => _api.get(
    '/habitos',
    (d) => [for (final h in d as List<dynamic>) _habito(h)],
    parametros: {'fecha': Fechas.iso(fecha), 'archivados': '$archivados'},
  );

  @override
  Future<Result<Habito>> obtener(String id, {required DateTime fecha}) =>
      _api.get(_ruta(id), _habito, parametros: {'fecha': Fechas.iso(fecha)});

  @override
  Future<Result<Habito>> crear(NuevoHabito nuevo) => _api.post('/habitos', _habito, datos: nuevo.toJson());

  @override
  Future<Result<Habito>> actualizar(String id, CambiosHabito cambios) =>
      _api.patch(_ruta(id), _habito, datos: cambios.toJson());

  @override
  Future<Result<List<Registro>>> registros(String id, {required DateTime desde, required DateTime hasta}) => _api.get(
    '${_ruta(id)}/registros',
    (d) => [for (final r in d as List<dynamic>) Registro.fromJson(r as Map<String, dynamic>)],
    parametros: {'desde': Fechas.iso(desde), 'hasta': Fechas.iso(hasta)},
  );

  @override
  Future<Result<EscaleraHabito>> escalera(String id) =>
      _api.get('${_ruta(id)}/escalera', (d) => EscaleraHabito.fromJson(d as Map<String, dynamic>));
}
