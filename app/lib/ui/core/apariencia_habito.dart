import 'package:flutter/widgets.dart';

import '../../domain/models/categoria.dart';
import '../../domain/models/habito.dart';
import 'tema/colores.dart';
import 'tema/iconos.dart';

/// Ícono y color de un hábito, de su subcategoría y su categoría (catálogo v1.6; colores en el doc. 04).
/// El color nunca va solo: siempre acompaña al ícono y al nombre (WCAG 1.4.1).
extension AparienciaHabito on Habito {
  IconData get icono => iconoDeSubcategoria(subcategoria, categoria: categoria);
  Color get color => KaizenColores.deHex(categoria.color);
}

/// Ícono de una subcategoría; si el nombre no se conoce, el de su categoría.
IconData iconoDeSubcategoria(Subcategoria s, {Categoria? categoria}) {
  final icono = KaizenIconos.porNombre(s.icono);
  if (icono != KaizenIconos.categoriaGenerica || categoria == null) {
    return icono;
  }
  return KaizenIconos.porNombre(categoria.icono);
}

Color colorDeCategoria(Categoria c) => KaizenColores.deHex(c.color);
