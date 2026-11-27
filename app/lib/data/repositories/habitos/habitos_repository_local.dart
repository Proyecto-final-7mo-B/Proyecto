import '../../../domain/models/escalera.dart';
import '../../../domain/models/habito.dart';
import '../../../domain/models/registro.dart';
import '../../../utils/fechas.dart';
import '../../../utils/result.dart';
import '../../services/base_local/almacen_local.dart';
import '../cache.dart';
import 'habitos_repository.dart';

/// Hábitos con copia local.
///
/// - **Lecturas** (lista, uno, check-ins): del servidor y se guardan; sin red, de la copia local.
/// - Siempre se aplican los check-ins que siguen en la cola (aún no los conoce el servidor): así lo marcado sin
///   conexión no "desaparece" al volver la red antes de sincronizar.
/// - **Crear, editar, archivar y la Escalera** necesitan al servidor: sin red devuelven el error.
class HabitosRepositoryLocal implements HabitosRepository {
  HabitosRepositoryLocal({required this.remoto, required this.almacen, this.reportar});

  final HabitosRepository remoto;
  final AlmacenLocal almacen;
  final ReportarRed? reportar;

  /// [h] con el check-in local de [fecha]: el pendiente (si hay) o, sin conexión, el guardado en la base local.
  Future<Habito> _conLocal(Habito h, DateTime fecha, {required bool usarGuardado}) async {
    final pendiente = await almacen.pendienteDe(h.id, fecha);
    if (pendiente != null) {
      return AlmacenLocal.conCheckinLocal(
        h,
        fecha: fecha,
        cumplido: pendiente.cumplido,
        id: pendiente.id,
        valor: pendiente.valor,
      );
    }
    if (usarGuardado) {
      final r = await almacen.registro(h.id, fecha);
      if (r != null) {
        return AlmacenLocal.conCheckinLocal(h, fecha: fecha, cumplido: r.cumplido, id: r.id, valor: r.valor);
      }
      if (h.hoy?.fecha != fecha) {
        // La copia es de otro día: "hoy" se calcula con la frecuencia y sin check-in.
        return h.copyWith(
          hoy: HoyHabito(fecha: fecha, programado: h.frecuencia.programadoEn(fecha)),
        );
      }
    }
    return h;
  }

  Future<List<Habito>> _todosConLocal(List<Habito> lista, DateTime fecha, {required bool usarGuardado}) async => [
    for (final h in lista) await _conLocal(h, fecha, usarGuardado: usarGuardado),
  ];

  @override
  Future<Result<List<Habito>>> listar({required DateTime fecha, bool archivados = false}) async {
    final r = await leerConCache<List<Habito>>(
      remoto: () => remoto.listar(fecha: fecha, archivados: archivados),
      guardar: (lista) => almacen.guardarHabitos(lista, incluyeArchivados: archivados),
      local: () async {
        if (!await almacen.hayHabitosGuardados()) {
          return null;
        }
        return _todosConLocal(await almacen.habitos(incluyeArchivados: archivados), fecha, usarGuardado: true);
      },
      reportar: reportar,
    );
    // Del servidor: se le aplican los pendientes. De la copia: ya vienen aplicados.
    return switch (r) {
      Exito(:final valor) => Result.exito(await _todosConLocal(valor, fecha, usarGuardado: false)),
      Fallo() => r,
    };
  }

  @override
  Future<Result<Habito>> obtener(String id, {required DateTime fecha}) async {
    var deCopia = false;
    final r = await leerConCache<Habito>(
      remoto: () => remoto.obtener(id, fecha: fecha),
      guardar: almacen.guardarHabito,
      local: () async {
        final h = await almacen.habito(id);
        deCopia = h != null;
        return h == null ? null : _conLocal(h, fecha, usarGuardado: true);
      },
      reportar: reportar,
    );
    return switch (r) {
      Exito(:final valor) when !deCopia => Result.exito(await _conLocal(valor, fecha, usarGuardado: false)),
      _ => r,
    };
  }

  @override
  Future<Result<List<Registro>>> registros(String id, {required DateTime desde, required DateTime hasta}) async {
    final r = await leerConCache<List<Registro>>(
      remoto: () => remoto.registros(id, desde: desde, hasta: hasta),
      guardar: almacen.guardarRegistros,
      // Sin red: lo guardado, que ya incluye lo marcado sin conexión.
      local: () => almacen.registros(id, desde: desde, hasta: hasta),
      reportar: reportar,
    );
    if (r case Exito(valor: final lista)) {
      // Lo del servidor más los pendientes, que reemplazan al check-in de su día.
      final porFecha = {for (final x in lista) Fechas.soloFecha(x.fecha): x};
      for (final x in await almacen.registros(id, desde: desde, hasta: hasta)) {
        if (await almacen.pendienteDe(id, x.fecha) != null) {
          porFecha[Fechas.soloFecha(x.fecha)] = x;
        }
      }
      return Result.exito(porFecha.values.toList()..sort((a, b) => a.fecha.compareTo(b.fecha)));
    }
    return r;
  }

  @override
  Future<Result<Habito>> crear(NuevoHabito nuevo) async {
    final r = await escribirEnServidor(() => remoto.crear(nuevo), reportar);
    if (r case Exito(:final valor)) {
      await almacen.guardarHabito(valor);
    }
    return r;
  }

  @override
  Future<Result<Habito>> actualizar(String id, CambiosHabito cambios) async {
    final r = await escribirEnServidor(() => remoto.actualizar(id, cambios), reportar);
    if (r case Exito(:final valor)) {
      await almacen.guardarHabito(valor);
    }
    return r;
  }

  @override
  Future<Result<EscaleraHabito>> escalera(String id) => escribirEnServidor(() => remoto.escalera(id), reportar);
}
