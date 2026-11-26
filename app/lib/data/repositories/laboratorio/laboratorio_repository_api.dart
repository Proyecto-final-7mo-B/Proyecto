import '../../../domain/models/laboratorio.dart';
import '../../../utils/result.dart';
import '../../services/api/cliente_api.dart';
import 'laboratorio_repository.dart';

class LaboratorioRepositoryApi implements LaboratorioRepository {
  LaboratorioRepositoryApi(this._api);

  final ClienteApi _api;

  @override
  Future<Result<Perspectivas>> perspectivas({String? semana}) => _api.get(
    '/laboratorio/perspectivas',
    (d) => Perspectivas.fromJson(d as Map<String, dynamic>),
    parametros: {'semana': ?semana},
  );
}
