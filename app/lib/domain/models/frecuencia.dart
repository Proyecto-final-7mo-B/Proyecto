/// Frecuencia de un hábito, como en el contrato:
/// `{"tipo": "diaria" | "dias_semana" | "n_por_semana", "dias_semana": <máscara> | null, "veces_semana": <1-7> | null}`.
sealed class Frecuencia {
  const Frecuencia();

  factory Frecuencia.fromJson(Map<String, dynamic> json) {
    final tipo = json['tipo'] as String?;
    return switch (tipo) {
      'diaria' => const Diaria(),
      'dias_semana' => DiasSemana((json['dias_semana'] as num).toInt()),
      'n_por_semana' => NPorSemana((json['veces_semana'] as num).toInt()),
      _ => throw FormatException('Tipo de frecuencia desconocido', tipo),
    };
  }

  /// Valor de `frecuencia_tipo` en la base.
  String get tipo;

  Map<String, dynamic> toJson();

  /// `true` si el hábito toca ese día. Igual que `fn_dia_programado` en la base: los hábitos "N por semana" no
  /// tienen días fijos, así que ningún día está "programado" (se cumplen cualquier día de la semana).
  bool programadoEn(DateTime fecha);

  /// Bit del día en la máscara: lunes = 1, martes = 2, … domingo = 64.
  static int bitDe(DateTime fecha) => 1 << (fecha.weekday - 1);
}

final class Diaria extends Frecuencia {
  const Diaria();

  @override
  String get tipo => 'diaria';

  @override
  Map<String, dynamic> toJson() => {'tipo': tipo, 'dias_semana': null, 'veces_semana': null};

  @override
  bool programadoEn(DateTime fecha) => true;

  @override
  bool operator ==(Object other) => other is Diaria;

  @override
  int get hashCode => tipo.hashCode;
}

final class DiasSemana extends Frecuencia {
  const DiasSemana(this.mascara) : assert(mascara >= 1 && mascara <= 127, 'Máscara 1–127');

  /// Lunes a viernes.
  static const int lunesAViernes = 31;

  /// Lunes = 1, martes = 2, miércoles = 4, jueves = 8, viernes = 16, sábado = 32, domingo = 64.
  final int mascara;

  /// Días marcados (1 = lunes … 7 = domingo).
  List<int> get dias => [
    for (var d = 1; d <= 7; d++)
      if (mascara & (1 << (d - 1)) != 0) d,
  ];

  /// Máscara a partir de los días (1 = lunes … 7 = domingo).
  static int mascaraDe(Iterable<int> dias) => dias.fold(0, (m, d) => m | (1 << (d - 1)));

  @override
  String get tipo => 'dias_semana';

  @override
  Map<String, dynamic> toJson() => {'tipo': tipo, 'dias_semana': mascara, 'veces_semana': null};

  @override
  bool programadoEn(DateTime fecha) => mascara & Frecuencia.bitDe(fecha) != 0;

  @override
  bool operator ==(Object other) => other is DiasSemana && other.mascara == mascara;

  @override
  int get hashCode => Object.hash(tipo, mascara);
}

final class NPorSemana extends Frecuencia {
  const NPorSemana(this.veces) : assert(veces >= 1 && veces <= 7, 'Veces 1–7');

  final int veces;

  @override
  String get tipo => 'n_por_semana';

  @override
  Map<String, dynamic> toJson() => {'tipo': tipo, 'dias_semana': null, 'veces_semana': veces};

  @override
  bool programadoEn(DateTime fecha) => false;

  @override
  bool operator ==(Object other) => other is NPorSemana && other.veces == veces;

  @override
  int get hashCode => Object.hash(tipo, veces);
}
