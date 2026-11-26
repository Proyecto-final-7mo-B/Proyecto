import '../../../domain/models/escalera.dart';
import '../../../utils/result.dart';
import '../../services/api/cliente_api.dart';
import 'escalera_repository.dart';

class EscaleraRepositoryApi implements EscaleraRepository {
  EscaleraRepositoryApi(this._api);

  final ClienteApi _api;

  @override
  Future<Result<List<Sugerencia>>> sugerencias() => _api.get(
    '/escalera/sugerencias',
    (d) => [for (final s in d as List<dynamic>) Sugerencia.fromJson(s as Map<String, dynamic>)],
  );

  @override
  Future<Result<RespuestaSugerencia>> responder(String id, {required bool aceptar}) => _api.post(
    '/escalera/sugerencias/${Uri.encodeComponent(id)}/respuesta',
    (d) => RespuestaSugerencia.fromJson(d as Map<String, dynamic>),
    datos: {'aceptar': aceptar},
  );
}
