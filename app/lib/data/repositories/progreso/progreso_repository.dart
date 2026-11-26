import '../../../domain/models/progreso.dart';
import '../../../utils/result.dart';

abstract interface class ProgresoRepository {
  /// `GET /progreso?periodo=&fecha=`.
  Future<Result<Progreso>> obtener(Periodo periodo, {required DateTime fecha});
}
