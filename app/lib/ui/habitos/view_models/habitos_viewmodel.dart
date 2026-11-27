import 'package:flutter/foundation.dart';

import '../../../data/repositories/capsulas/capsulas_repository.dart';
import '../../../data/repositories/habitos/habitos_repository.dart';
import '../../../domain/models/capsula.dart';
import '../../../domain/models/habito.dart';
import '../../../utils/command.dart';
import '../../../utils/fechas.dart';
import '../../../utils/reloj.dart';
import '../../../utils/result.dart';

/// `/habitos`: los activos y los archivados (una sola llamada con `archivados=true`), ordenados por nombre.
class HabitosViewModel extends ChangeNotifier {
  HabitosViewModel({
    required HabitosRepository habitos,
    required CapsulasRepository capsulas,
    Reloj reloj = relojDelSistema,
  }) : _repoHabitos = habitos,
       _repoCapsulas = capsulas,
       _relojLista = reloj {
    cargar = Command0<void>(_cargar);
  }

  final HabitosRepository _repoHabitos;
  final CapsulasRepository _repoCapsulas;
  final Reloj _relojLista;

  late final Command0<void> cargar;

  List<Habito> _todos = const [];
  Set<String> _conCapsula = const {};
  bool _verArchivados = false;
  bool _cargado = false;

  bool get cargado => _cargado;
  bool get verArchivados => _verArchivados;

  List<Habito> get activos => _todos.where((h) => h.activo).toList();
  List<Habito> get archivados => _todos.where((h) => !h.activo).toList();

  /// Lo que muestra la pestaña elegida.
  List<Habito> get visibles => _verArchivados ? archivados : activos;

  bool tieneCapsula(String habitoId) => _conCapsula.contains(habitoId);

  set verArchivados(bool valor) {
    if (valor != _verArchivados) {
      _verArchivados = valor;
      notifyListeners();
    }
  }

  Future<Result<void>> _cargar() async {
    final resultados = await Future.wait<Result<Object?>>([
      _repoHabitos.listar(fecha: Fechas.soloFecha(_relojLista()), archivados: true),
      _repoCapsulas.listar(estado: EstadoCapsula.sellada),
    ]);
    switch (resultados[0]) {
      case Fallo(:final error):
        return Result.fallo(error);
      case Exito(:final valor):
        // Por prioridad y después por nombre, igual que la API (doc. 07 de la investigación).
        _todos = List.of(valor! as List<Habito>)
          ..sort((a, b) {
            final p = a.prioridad.compareTo(b.prioridad);
            return p != 0 ? p : a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
          });
    }
    final capsulas = resultados[1].valorONulo as List<Capsula>?;
    _conCapsula = {for (final c in capsulas ?? const <Capsula>[]) c.habitoId};
    _cargado = true;
    notifyListeners();
    return const Result.exito(null);
  }

  @override
  void dispose() {
    cargar.dispose();
    super.dispose();
  }
}
