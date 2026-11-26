import '../../../domain/models/registro.dart';
import '../../../utils/result.dart';

/// Check-ins. Los dos métodos son idempotentes: reenviar el mismo `id` no duplica.
abstract interface class RegistrosRepository {
  /// `POST /registros`.
  Future<Result<ResultadoCheckin>> registrar(NuevoRegistro registro);

  /// `POST /registros/lote` (hasta 100, para la cola sin conexión).
  Future<Result<ResultadoLote>> registrarLote(List<NuevoRegistro> registros);
}
