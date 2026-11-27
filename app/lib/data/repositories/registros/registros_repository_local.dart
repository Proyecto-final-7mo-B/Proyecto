import '../../../domain/models/registro.dart';
import '../../../utils/result.dart';
import '../../services/api/errores_api.dart';
import '../../services/base_local/almacen_local.dart';
import '../../sync/sincronizador.dart';
import '../cache.dart';
import 'registros_repository.dart';

/// Check-in que funciona sin conexión (diseño §7.5 y contrato §6.5):
///
/// 1. **Guarda el check-in y lo encola en una sola transacción** (o quedan los dos o ninguno).
/// 2. Intenta enviarlo al momento con `POST /registros`.
///    - Llegó: sale de la cola y se devuelve la racha real.
///    - Falló **por red**: se queda en la cola y se devuelve la racha **estimada** (el check-in no se pierde ni se
///      "regresa" en la pantalla). El [Sincronizador] lo manda después en un lote con `origen: offline`.
///    - El servidor lo **rechazó** (p. ej., hábito archivado): se quita de la cola, vuelve el check-in que había y se
///      devuelve el error.
///
/// El `id` lo generó la app, así que reenviarlo no duplica nada.
class RegistrosRepositoryLocal implements RegistrosRepository {
  RegistrosRepositoryLocal({required this.remoto, required this.almacen, this.reportar});

  final RegistrosRepository remoto;
  final AlmacenLocal almacen;
  final ReportarRed? reportar;

  @override
  Future<Result<ResultadoCheckin>> registrar(NuevoRegistro registro) async {
    final anterior = await almacen.guardarYEncolar(registro);
    final r = await remoto.registrar(registro);
    switch (r) {
      case Exito(:final valor):
        reportar?.call(true);
        await almacen.desencolar(registro.id);
        await almacen.confirmarCheckin(registro, valor.rachaActual);
        return r;
      case Fallo(:final error) when Sincronizador.esDeRed(error):
        reportar?.call(false);
        return Result.exito(ResultadoCheckin(id: registro.id, rachaActual: await _rachaEstimada(registro)));
      case Fallo():
        reportar?.call(true);
        await almacen.deshacer(registro, anterior);
        return r;
    }
  }

  /// La racha que tendría el hábito con este check-in, a partir de la última copia del servidor.
  Future<int> _rachaEstimada(NuevoRegistro r) async {
    final h = await almacen.habito(r.habitoId);
    if (h == null) {
      return 0;
    }
    return AlmacenLocal.conCheckinLocal(h, fecha: r.fecha, cumplido: r.cumplido, id: r.id, valor: r.valor).racha.actual;
  }

  /// El lote lo usa el [Sincronizador] directamente contra el servidor; aquí solo se pasa.
  @override
  Future<Result<ResultadoLote>> registrarLote(List<NuevoRegistro> registros) async {
    final r = await remoto.registrarLote(registros);
    reportar?.call(r is Exito || !Sincronizador.esDeRed(r.errorONulo ?? const ErrorApp(TipoError.desconocido)));
    return r;
  }
}
