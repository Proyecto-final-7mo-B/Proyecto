import '../../../domain/models/escalera.dart';
import '../../../domain/models/habito.dart';
import '../../../domain/models/recomendacion.dart';
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

  /// `GET /habitos/recomendados` (v1.7): los hábitos saludables listos para crear.
  Future<Result<List<HabitoRecomendado>>> recomendados();

  /// `POST /habitos` con `recomendacion_id` (v1.7): la base copia nombre, meta, frecuencia e intención; el usuario
  /// solo elige la [prioridad].
  Future<Result<Habito>> crearRecomendado(String recomendacionId, {int prioridad = Prioridad.media});

  /// `GET /habitos/{id}/protegidos?desde=&hasta=` (v1.7): los días que perdonó el protector de racha.
  Future<Result<Set<DateTime>>> diasProtegidos(String id, {required DateTime desde, required DateTime hasta});
}
