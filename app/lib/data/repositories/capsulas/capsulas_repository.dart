import '../../../domain/models/capsula.dart';
import '../../../utils/result.dart';

abstract interface class CapsulasRepository {
  /// `POST /capsulas`. La foto nunca se sube: solo `tiene_foto`.
  Future<Result<Capsula>> crear(NuevaCapsula nueva);

  /// `GET /capsulas?estado=`. Nunca trae el mensaje.
  Future<Result<List<Capsula>>> listar({EstadoCapsula? estado});

  /// `POST /capsulas/{id}/abrir`. 409 `capsula-sellada` si la racha no alcanza el objetivo.
  Future<Result<CapsulaAbierta>> abrir(String id);
}
