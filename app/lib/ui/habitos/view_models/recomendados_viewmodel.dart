import 'package:flutter/foundation.dart';

import '../../../data/repositories/habitos/habitos_repository.dart';
import '../../../domain/models/categoria.dart';
import '../../../domain/models/habito.dart';
import '../../../domain/models/recomendacion.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

/// Hábitos recomendados de una subcategoría.
typedef GrupoRecomendados = ({Subcategoria subcategoria, List<HabitoRecomendado> recomendados});

/// Pantalla "Nuevo hábito" (decisión del 27-nov): 100 hábitos saludables (20 por categoría) con nombre, meta,
/// frecuencia y momento ya definidos por la evidencia. El usuario elige uno y solo decide la prioridad y la cápsula;
/// para todo lo demás está "Hábito personalizado" (el formulario del Paso 7).
class RecomendadosViewModel extends ChangeNotifier {
  RecomendadosViewModel({required HabitosRepository habitos}) : _repo = habitos {
    cargar = Command0<void>(_cargar);
    crear = Command0<Habito>(_crear);
  }

  final HabitosRepository _repo;

  late final Command0<void> cargar;

  /// Crea el hábito elegido con la prioridad elegida (la cápsula se sella después, en su pantalla).
  late final Command0<Habito> crear;

  List<HabitoRecomendado> _todos = const [];
  String? _categoria;
  HabitoRecomendado? _elegido;
  int _prioridad = Prioridad.media;
  int? _capsula;
  bool _cargado = false;

  bool get cargado => _cargado;
  List<HabitoRecomendado> get todos => _todos;

  /// Las categorías en el orden del catálogo (el de la lista).
  List<Categoria> get categorias {
    final vistas = <String>{};
    return [
      for (final r in _todos)
        if (vistas.add(r.categoria.clave)) r.categoria,
    ];
  }

  /// Clave de la categoría que se ve (la primera al cargar).
  String? get categoria => _categoria;
  set categoria(String? clave) {
    if (clave == _categoria) {
      return;
    }
    _categoria = clave;
    notifyListeners();
  }

  /// Las recomendaciones de la categoría elegida, agrupadas por subcategoría (en su orden).
  List<GrupoRecomendados> get grupos {
    final porSub = <String, GrupoRecomendados>{};
    for (final r in _todos.where((r) => r.categoria.clave == _categoria)) {
      porSub.putIfAbsent(r.subcategoria.id, () => (subcategoria: r.subcategoria, recomendados: <HabitoRecomendado>[]));
      porSub[r.subcategoria.id]!.recomendados.add(r);
    }
    return porSub.values.toList();
  }

  HabitoRecomendado? get elegido => _elegido;

  /// Elegir una recomendación reinicia la prioridad (media) y la cápsula (ninguna).
  void elegir(HabitoRecomendado? r) {
    _elegido = r;
    _prioridad = Prioridad.media;
    _capsula = null;
    crear.limpiar();
    notifyListeners();
  }

  int get prioridad => _prioridad;
  set prioridad(int p) {
    _prioridad = p;
    notifyListeners();
  }

  /// Racha objetivo de la cápsula (7, 30 o 66); `null` = sin cápsula.
  int? get capsula => _capsula;
  set capsula(int? c) {
    _capsula = c;
    notifyListeners();
  }

  Future<Result<void>> _cargar() async {
    final r = await _repo.recomendados();
    switch (r) {
      case Fallo(:final error):
        return Result.fallo(error);
      case Exito(:final valor):
        _todos = valor;
        if (_categoria == null || !_todos.any((x) => x.categoria.clave == _categoria)) {
          _categoria = _todos.firstOrNull?.categoria.clave;
        }
        _cargado = true;
        notifyListeners();
        return const Result.exito(null);
    }
  }

  Future<Result<Habito>> _crear() {
    final r = _elegido;
    if (r == null) {
      throw StateError('No hay recomendación elegida');
    }
    return _repo.crearRecomendado(r.id, prioridad: _prioridad);
  }

  @override
  void dispose() {
    cargar.dispose();
    crear.dispose();
    super.dispose();
  }
}
