import 'dart:async';

import '../../../domain/models/registro.dart';
import '../../../utils/result.dart';
import '../../services/avisos/gestor_avisos.dart';
import 'registros_repository.dart';

/// Cada check-in que se guarda (con red o en la cola sin conexión) le avisa a [gestor]: cuenta como respuesta al
/// recordatorio y quita los avisos de hoy de ese hábito. Desmarcar también vuelve a planear (el recordatorio regresa).
class RegistrosRepositoryConAvisos implements RegistrosRepository {
  RegistrosRepositoryConAvisos({required this.interno, required this.gestor});

  final RegistrosRepository interno;
  final GestorAvisos gestor;

  @override
  Future<Result<ResultadoCheckin>> registrar(NuevoRegistro registro) async {
    final r = await interno.registrar(registro);
    if (r is Exito) {
      unawaited(registro.cumplido ? gestor.registrarCheckin(registro.habitoId) : gestor.replanificar());
    }
    return r;
  }

  /// El lote es de días atrasados (la cola sin conexión): no cambia lo que falta hoy.
  @override
  Future<Result<ResultadoLote>> registrarLote(List<NuevoRegistro> registros) => interno.registrarLote(registros);
}
