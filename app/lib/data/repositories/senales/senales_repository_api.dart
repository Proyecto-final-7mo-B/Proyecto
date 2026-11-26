import '../../../domain/models/laboratorio.dart';
import '../../../utils/fechas.dart';
import '../../../utils/result.dart';
import '../../services/api/cliente_api.dart';
import 'senales_repository.dart';

class SenalesRepositoryApi implements SenalesRepository {
  SenalesRepositoryApi(this._api);

  final ClienteApi _api;

  @override
  Future<Result<Senal>> guardar(Senal senal) =>
      _api.post('/senales', (d) => Senal.fromJson(d as Map<String, dynamic>), datos: senal.toJson());

  @override
  Future<Result<List<Senal>>> listar({required DateTime desde, required DateTime hasta}) => _api.get(
    '/senales',
    (d) => [for (final s in d as List<dynamic>) Senal.fromJson(s as Map<String, dynamic>)],
    parametros: {'desde': Fechas.iso(desde), 'hasta': Fechas.iso(hasta)},
  );
}
