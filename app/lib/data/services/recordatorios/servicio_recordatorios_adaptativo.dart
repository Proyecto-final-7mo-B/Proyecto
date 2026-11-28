import '../../../domain/models/frecuencia.dart';
import '../avisos/gestor_avisos.dart';
import '../base_local/almacen_local.dart';
import 'servicio_recordatorios.dart';

/// Recordatorios de los hábitos desde el Paso 10: la hora se guarda en la tabla local `recordatorios` y el aviso lo
/// programa `GestorAvisos` (solo los días que toca y, hoy, solo si el hábito sigue pendiente). El título y el texto
/// que manda el formulario ya no se usan: el planificador arma los suyos (con la intención y rotando).
class ServicioRecordatoriosAdaptativo implements ServicioRecordatorios {
  ServicioRecordatoriosAdaptativo({required this.gestor, required this.almacen});

  final GestorAvisos gestor;
  final AlmacenLocal almacen;

  /// El campo de recordatorio se muestra si el dispositivo tiene notificaciones del sistema.
  @override
  bool get disponible => gestor.notificador.disponible;

  @override
  Future<HoraRecordatorio?> hora(String habitoId) => almacen.recordatorio(habitoId);

  @override
  Future<bool> programar({
    required String habitoId,
    required String titulo,
    required String cuerpo,
    required HoraRecordatorio hora,
    required Frecuencia frecuencia,
  }) async {
    if (!await gestor.pedirPermiso()) {
      return false;
    }
    await almacen.guardarRecordatorio(habitoId, hora.hora, hora.minuto);
    await gestor.replanificar();
    return true;
  }

  @override
  Future<void> cancelar(String habitoId) async {
    await almacen.quitarRecordatorio(habitoId);
    await gestor.replanificar();
  }
}
