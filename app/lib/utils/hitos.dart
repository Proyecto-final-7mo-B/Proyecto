/// Nivel visual de una racha (doc. 05 de la investigación): el símbolo cambia para que el avance **se note**.
///
/// | Días | Nivel |
/// |---|---|
/// | 0 | [sinRacha]: contorno gris, sin mensaje de falla (F09) |
/// | 1–6 | [chispa]: ámbar |
/// | 7–29 | [llama]: la llama naranja de siempre |
/// | 30–65 | [llamaConAro]: naranja profundo con aro |
/// | 66–99 | [formado]: "hábito formado", dorado (66 = mediana de Lally 2010, F01) |
/// | ≥ 100 | [emblema]: dorado y marino |
enum NivelRacha {
  sinRacha(0),
  chispa(1),
  llama(7),
  llamaConAro(30),
  formado(66),
  emblema(100);

  const NivelRacha(this.desde);

  /// Primer día de la racha con este nivel.
  final int desde;

  static NivelRacha deDias(int dias) => values.lastWhere((n) => dias >= n.desde, orElse: () => sinRacha);
}

/// Hitos de racha que se celebran (doc. 05): 7 (primer dato de retención), 30 (un mes), 66 (mediana científica) y 100.
/// Después de 100, cada centena.
abstract final class Hitos {
  static const List<int> celebrados = [7, 30, 66, 100];

  /// Días de la mediana científica para formar un hábito (Lally 2010, F01; Singh 2024, F02).
  static const int habitoFormado = 66;

  /// El siguiente hito por alcanzar con [dias] de racha.
  static int siguiente(int dias) {
    for (final h in celebrados) {
      if (dias < h) {
        return h;
      }
    }
    return (dias ~/ 100 + 1) * 100;
  }

  /// El hito que se acaba de cruzar al pasar de [antes] a [despues] días, o `null`. Solo cuenta subir.
  static int? cruzado(int antes, int despues) {
    if (despues <= antes) {
      return null;
    }
    final esHito = celebrados.contains(despues) || (despues > 100 && despues % 100 == 0);
    return esHito ? despues : null;
  }
}
