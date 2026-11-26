import '../../../domain/models/escalera.dart';
import '../../../domain/models/habito.dart';
import '../../../domain/models/registro.dart';
import '../../../utils/result.dart';

abstract interface class HabitosRepository {
  /// `GET /habitos?fecha=&archivados=`. [fecha] es el día local, para calcular `hoy`.
  Future<Result<List<Habito>>> listar({required DateTime fecha, bool archivados = false});

  /// `GET /habitos/{id}?fecha=`.
  Future<Result<Habito>> obtener(String id, {required DateTime fecha});

  /// `POST /habitos`.
  Future<Result<Habito>> crear(NuevoHabito nuevo);

  /// `PATCH /habitos/{id}`. Archivar = `CambiosHabito(activo: false)`.
  Future<Result<Habito>> actualizar(String id, CambiosHabito cambios);

  /// `GET /habitos/{id}/registros?desde=&hasta=` (máximo 366 días).
  Future<Result<List<Registro>>> registros(String id, {required DateTime desde, required DateTime hasta});

  /// `GET /habitos/{id}/escalera`.
  Future<Result<EscaleraHabito>> escalera(String id);
}
