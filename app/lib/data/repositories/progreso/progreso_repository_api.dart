import '../../../domain/models/progreso.dart';
import '../../../utils/fechas.dart';
import '../../../utils/result.dart';
import '../../services/api/cliente_api.dart';
import 'progreso_repository.dart';

class ProgresoRepositoryApi implements ProgresoRepository {
  ProgresoRepositoryApi(this._api);

  final ClienteApi _api;

  @override
  Future<Result<Progreso>> obtener(Periodo periodo, {required DateTime fecha}) => _api.get(
    '/progreso',
    (d) => Progreso.fromJson(d as Map<String, dynamic>),
    parametros: {'periodo': periodo.name, 'fecha': Fechas.iso(fecha)},
  );
}
