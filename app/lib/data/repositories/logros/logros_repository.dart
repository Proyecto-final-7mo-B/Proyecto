import '../../../domain/models/logro.dart';
import '../../../utils/result.dart';

abstract interface class LogrosRepository {
  /// `GET /logros` (contrato §6.13): los 10 logros del catálogo en su orden, obtenidos o no, con su progreso.
  Future<Result<List<Logro>>> listar();
}
