import '../../../domain/models/logro.dart';
import '../../../utils/result.dart';
import '../../services/base_local/almacen_local.dart';
import '../cache.dart';
import 'logros_repository.dart';

/// Logros con copia local (tabla `marcas`, JSON): sin conexión se ven los últimos que se leyeron.
class LogrosRepositoryLocal implements LogrosRepository {
  LogrosRepositoryLocal({required this.remoto, required this.almacen, this.reportar});

  static const String clave = 'logros';

  final LogrosRepository remoto;
  final AlmacenLocal almacen;
  final ReportarRed? reportar;

  @override
  Future<Result<List<Logro>>> listar() => leerConCache<List<Logro>>(
    remoto: remoto.listar,
    guardar: (lista) => almacen.guardarJson(clave, [for (final l in lista) l.toJson()]),
    local: () async {
      final json = await almacen.leerJson(clave);
      return json == null ? null : [for (final l in json as List<dynamic>) Logro.fromJson(l as Map<String, dynamic>)];
    },
    reportar: reportar,
  );
}
