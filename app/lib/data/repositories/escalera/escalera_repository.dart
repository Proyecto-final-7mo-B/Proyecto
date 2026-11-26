import '../../../domain/models/escalera.dart';
import '../../../utils/result.dart';

abstract interface class EscaleraRepository {
  /// `GET /escalera/sugerencias`: las pendientes del usuario.
  Future<Result<List<Sugerencia>>> sugerencias();

  /// `POST /escalera/sugerencias/{id}/respuesta`. "Mantener" = `aceptar: false`.
  Future<Result<RespuestaSugerencia>> responder(String id, {required bool aceptar});
}
