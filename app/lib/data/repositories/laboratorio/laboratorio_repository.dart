import '../../../domain/models/laboratorio.dart';
import '../../../utils/result.dart';

abstract interface class LaboratorioRepository {
  /// `GET /laboratorio/perspectivas?semana=`. Sin [semana], la última completa. 503 si la analítica no está.
  Future<Result<Perspectivas>> perspectivas({String? semana});
}
