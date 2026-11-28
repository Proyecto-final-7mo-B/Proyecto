/// Logros (Paso 11, contrato §6.13): insignias que otorga **la base** (triggers y la tarea semanal); la app solo las
/// lee con `GET /logros`. Cada una se obtiene una sola vez.
library;

/// Cómo se obtiene: al llegar a una racha, por un evento (aceptar una subida, abrir una cápsula…) o con la revisión
/// semanal (semana OMS, ritmo ideal).
enum TipoLogro {
  racha,
  evento,
  semanal;

  static TipoLogro deJson(Object? v) => switch (v) {
    'racha' => racha,
    'semanal' => semanal,
    _ => evento,
  };
}

class Logro {
  const Logro({
    required this.clave,
    required this.nombre,
    required this.descripcion,
    required this.icono,
    required this.tipo,
    required this.objetivo,
    required this.progreso,
    required this.obtenido,
    required this.porque,
    this.obtenidoEn,
    this.habitoId,
    this.habitoNombre,
    this.fuentes,
  });

  factory Logro.fromJson(Map<String, dynamic> j) {
    final habito = j['habito'] as Map<String, dynamic>?;
    return Logro(
      clave: j['clave'] as String,
      nombre: j['nombre'] as String,
      descripcion: j['descripcion'] as String,
      icono: j['icono'] as String,
      tipo: TipoLogro.deJson(j['tipo']),
      objetivo: (j['objetivo'] as num?)?.toInt() ?? 1,
      progreso: (j['progreso'] as num?)?.toInt() ?? 0,
      obtenido: j['obtenido'] as bool? ?? false,
      obtenidoEn: switch (j['obtenido_en']) {
        final String s => DateTime.parse(s),
        _ => null,
      },
      habitoId: habito?['id'] as String?,
      habitoNombre: habito?['nombre'] as String?,
      porque: j['porque'] as String? ?? '',
      fuentes: j['fuentes'] as String?,
    );
  }

  final String clave;
  final String nombre;
  final String descripcion;

  /// Nombre de Material Symbols (`KaizenIconos.porNombre`).
  final String icono;
  final TipoLogro tipo;

  /// Días de racha para los de tipo racha; 1 para los demás.
  final int objetivo;

  /// De 0 a [objetivo] (los de racha usan la mejor racha del usuario).
  final int progreso;
  final bool obtenido;
  final DateTime? obtenidoEn;

  /// El hábito con el que se obtuvo, si aplica.
  final String? habitoId;
  final String? habitoNombre;

  /// Por qué existe (doc. 05 de la investigación).
  final String porque;

  /// Claves `F##` de las fuentes. La app no las muestra fuera del detalle del hábito (regla del 27-nov).
  final String? fuentes;

  /// [porque] sin referencias entre paréntesis como "(F3)", para mostrarlo al usuario.
  String get porqueParaMostrar => porque.replaceAll(RegExp(r'\s*\(F\d{1,2}\)'), '').trim();

  /// De 0 a 1.
  double get avance => obtenido ? 1 : (objetivo <= 0 ? 0 : (progreso / objetivo).clamp(0, 1).toDouble());

  /// Los que tiene sentido mostrar como "21 de 30" (los de racha que aún no se obtienen).
  bool get muestraProgreso => !obtenido && tipo == TipoLogro.racha;

  Map<String, dynamic> toJson() => {
    'clave': clave,
    'nombre': nombre,
    'descripcion': descripcion,
    'icono': icono,
    'tipo': tipo.name,
    'objetivo': objetivo,
    'progreso': progreso,
    'obtenido': obtenido,
    'obtenido_en': obtenidoEn?.toUtc().toIso8601String(),
    'habito': habitoId == null ? null : {'id': habitoId, 'nombre': habitoNombre},
    'porque': porque,
    'fuentes': fuentes,
  };
}

/// El logro obtenido más reciente (para "Último logro"); `null` si no hay.
Logro? ultimoObtenido(Iterable<Logro> logros) {
  Logro? mejor;
  for (final l in logros) {
    if (!l.obtenido) {
      continue;
    }
    final en = l.obtenidoEn ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    final antes = mejor?.obtenidoEn ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    if (mejor == null || en.isAfter(antes)) {
      mejor = l;
    }
  }
  return mejor;
}

/// El que va más cerca de obtenerse (para "Tu próxima insignia" cuando aún no hay ninguno): el de mayor avance;
/// empates, el primero del catálogo.
Logro? proximoPorObtener(Iterable<Logro> logros) {
  Logro? mejor;
  for (final l in logros) {
    if (!l.obtenido && (mejor == null || l.avance > mejor.avance)) {
      mejor = l;
    }
  }
  return mejor;
}
