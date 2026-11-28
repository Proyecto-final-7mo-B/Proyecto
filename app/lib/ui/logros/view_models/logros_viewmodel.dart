import 'package:flutter/foundation.dart';

import '../../../data/repositories/logros/logros_repository.dart';
import '../../../domain/models/logro.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

enum FiltroLogros { todos, obtenidos, porObtener }

/// `/logros` (Paso 11): las 10 insignias, obtenidas o no, con su progreso.
class LogrosViewModel extends ChangeNotifier {
  LogrosViewModel({required LogrosRepository logros}) : _repo = logros {
    cargar = Command0<void>(_cargar);
  }

  final LogrosRepository _repo;

  late final Command0<void> cargar;

  List<Logro> _logros = const [];
  FiltroLogros _filtro = FiltroLogros.todos;

  List<Logro> get logros => _logros;
  FiltroLogros get filtro => _filtro;
  int get obtenidos => _logros.where((l) => l.obtenido).length;
  int get total => _logros.length;

  /// Lo que se ve con el filtro elegido, en el orden del catálogo.
  List<Logro> get visibles => switch (_filtro) {
    FiltroLogros.todos => _logros,
    FiltroLogros.obtenidos => [
      for (final l in _logros)
        if (l.obtenido) l,
    ],
    FiltroLogros.porObtener => [
      for (final l in _logros)
        if (!l.obtenido) l,
    ],
  };

  void elegirFiltro(FiltroLogros f) {
    if (f != _filtro) {
      _filtro = f;
      notifyListeners();
    }
  }

  Future<Result<void>> _cargar() async {
    final r = await _repo.listar();
    switch (r) {
      case Exito(:final valor):
        _logros = valor;
        notifyListeners();
        return const Result.exito(null);
      case Fallo(:final error):
        return Result.fallo(error);
    }
  }

  @override
  void dispose() {
    cargar.dispose();
    super.dispose();
  }
}
