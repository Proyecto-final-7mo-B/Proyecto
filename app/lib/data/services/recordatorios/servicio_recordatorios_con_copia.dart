import '../../../domain/models/frecuencia.dart';
import '../base_local/almacen_local.dart';
import 'servicio_recordatorios.dart';

/// Copia la hora de cada recordatorio en la tabla local `recordatorios` (diseño §7.5). Si el sistema no la reporta
/// (p. ej., el *plugin* aún no inicia), se lee de la copia.
class ServicioRecordatoriosConCopia implements ServicioRecordatorios {
  ServicioRecordatoriosConCopia(this.interno, this.almacen);

  final ServicioRecordatorios interno;
  final AlmacenLocal almacen;

  @override
  bool get disponible => interno.disponible;

  @override
  Future<HoraRecordatorio?> hora(String habitoId) async =>
      await interno.hora(habitoId) ?? await almacen.recordatorio(habitoId);

  @override
  Future<bool> programar({
    required String habitoId,
    required String titulo,
    required String cuerpo,
    required HoraRecordatorio hora,
    required Frecuencia frecuencia,
  }) async {
    final ok = await interno.programar(
      habitoId: habitoId,
      titulo: titulo,
      cuerpo: cuerpo,
      hora: hora,
      frecuencia: frecuencia,
    );
    if (ok) {
      await almacen.guardarRecordatorio(habitoId, hora.hora, hora.minuto);
    }
    return ok;
  }

  @override
  Future<void> cancelar(String habitoId) async {
    await interno.cancelar(habitoId);
    await almacen.quitarRecordatorio(habitoId);
  }
}
