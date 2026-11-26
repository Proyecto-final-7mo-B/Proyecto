import '../../../domain/models/laboratorio.dart';
import '../../../utils/result.dart';

abstract interface class SenalesRepository {
  /// `POST /senales`: si ya hay una ese día, se reemplaza. Exige el consentimiento de señales.
  Future<Result<Senal>> guardar(Senal senal);

  /// `GET /senales?desde=&hasta=`.
  Future<Result<List<Senal>>> listar({required DateTime desde, required DateTime hasta});
}
