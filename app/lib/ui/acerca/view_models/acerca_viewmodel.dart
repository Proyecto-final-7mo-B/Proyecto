import 'package:flutter/foundation.dart';

import '../../../data/repositories/categorias/categorias_repository.dart';
import '../../../domain/models/categoria.dart';
import '../../../domain/models/recomendacion.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

/// "Acerca de Kaizen" (decisión del 27-nov): los textos fijos están en la pantalla; aquí se cargan los rangos del
/// catálogo (`GET /categorias`) y las fuentes (`GET /fuentes`). Si fallan, la pantalla muestra igual los textos.
class AcercaViewModel extends ChangeNotifier {
  AcercaViewModel({required CategoriasRepository categorias}) : _repo = categorias {
    cargar = Command0<void>(_cargar);
  }

  final CategoriasRepository _repo;

  late final Command0<void> cargar;

  List<Categoria> _categorias = const [];
  List<FuenteCientifica> _fuentes = const [];

  List<Categoria> get categorias => _categorias;
  List<FuenteCientifica> get fuentes => _fuentes;

  String? _tema;

  /// Tema del filtro de fuentes; `null` = todas.
  String? get tema => _tema;
  set tema(String? t) {
    _tema = t;
    notifyListeners();
  }

  List<FuenteCientifica> get fuentesFiltradas => [
    for (final f in _fuentes)
      if (_tema == null || f.tema == _tema) f,
  ];

  /// Cuántas subcategorías tienen rango científico.
  int get totalRangos => _categorias.expand((c) => c.subcategorias).where((s) => s.referencia != null).length;

  /// El nivel de confianza de una fuente a partir de su texto ("Media (96 participantes…)", "Baja–media"): la primera
  /// palabra. "Baja–media" cuenta como media.
  static Confianza nivelDe(String texto) {
    final t = texto.toLowerCase();
    if (t.startsWith('alta')) {
      return Confianza.alta;
    }
    if (t.startsWith('media') || t.startsWith('baja–media') || t.startsWith('baja-media')) {
      return Confianza.media;
    }
    return Confianza.baja;
  }

  /// Las fuentes agrupadas por tema, en el orden de [temas].
  Map<String, List<FuenteCientifica>> get fuentesPorTema => {
    for (final tema in temas)
      if (_fuentes.any((f) => f.tema == tema)) tema: [for (final f in _fuentes) if (f.tema == tema) f],
  };

  /// El orden de los temas en `fuentes.md`.
  static const List<String> temas = [
    'formacion',
    'actividad',
    'salud',
    'educacion',
    'bienestar',
    'color',
    'notificaciones',
  ];

  Future<Result<void>> _cargar() async {
    final (cats, fuentes) = (await _repo.listar(), await _repo.fuentes());
    _categorias = cats.valorONulo ?? _categorias;
    _fuentes = fuentes.valorONulo ?? _fuentes;
    notifyListeners();
    return switch ((cats, fuentes)) {
      (Fallo(:final error), _) || (_, Fallo(:final error)) => Result.fallo(error),
      _ => const Result.exito(null),
    };
  }

  @override
  void dispose() {
    cargar.dispose();
    super.dispose();
  }
}
