import 'package:json_annotation/json_annotation.dart';

import 'categoria.dart';
import 'conversores.dart';
import 'evidencia.dart';
import 'frecuencia.dart';

part 'habito.g.dart';

/// Racha vigente (de `v_racha_vigente`). Desde la v1.6 tiene **protector**: un día programado fallado por semana no
/// la rompe (doc. 01 de la investigación).
@JsonSerializable()
class Racha {
  const Racha({required this.actual, required this.maxima, this.ultimaFecha, this.protegidaEstaSemana = false});

  factory Racha.fromJson(Map<String, dynamic> json) => _$RachaFromJson(json);

  final int actual;
  final int maxima;
  @FechaNulaConverter()
  final DateTime? ultimaFecha;

  /// El protector ya se usó esta semana: un fallo más la rompe.
  @JsonKey(defaultValue: false)
  final bool protegidaEstaSemana;

  Map<String, dynamic> toJson() => _$RachaToJson(this);
}

/// Check-in de hoy dentro de un hábito (`hoy.registro`).
@JsonSerializable()
class RegistroDeHoy {
  const RegistroDeHoy({required this.id, required this.cumplido, this.valor});

  factory RegistroDeHoy.fromJson(Map<String, dynamic> json) => _$RegistroDeHoyFromJson(json);

  final String id;
  final bool cumplido;
  final double? valor;

  Map<String, dynamic> toJson() => _$RegistroDeHoyToJson(this);
}

/// Estado del hábito en la fecha que pidió la app (`?fecha=`).
@JsonSerializable()
class HoyHabito {
  const HoyHabito({required this.fecha, required this.programado, this.registro});

  factory HoyHabito.fromJson(Map<String, dynamic> json) => _$HoyHabitoFromJson(json);

  @FechaConverter()
  final DateTime fecha;
  final bool programado;

  /// `null` si aún no hay check-in ese día.
  final RegistroDeHoy? registro;

  bool get cumplido => registro?.cumplido ?? false;

  Map<String, dynamic> toJson() => _$HoyHabitoToJson(this);
}

/// Hábito, como lo devuelve la API.
@JsonSerializable()
class Habito {
  const Habito({
    required this.id,
    required this.nombre,
    required this.unidad,
    required this.meta,
    required this.nivel,
    required this.categoria,
    required this.subcategoria,
    required this.frecuencia,
    required this.escaleraActiva,
    required this.activo,
    required this.fechaCreacion,
    required this.racha,
    this.prioridad = Prioridad.media,
    this.intencion,
    this.evaluacion,
    this.hoy,
  });

  factory Habito.fromJson(Map<String, dynamic> json) => _$HabitoFromJson(json);

  final String id;
  final String nombre;
  final String unidad;

  /// Meta vigente. Solo se fija al crear; después cambia aceptando una sugerencia de la Escalera.
  final double meta;
  final int nivel;

  /// Versión corta: id, clave, nombre, color e ícono.
  final Categoria categoria;

  /// Versión corta: id, clave, nombre, ícono y sentido.
  final Subcategoria subcategoria;

  /// 1 alta, 2 media, 3 baja. Hoy ordena los pendientes por prioridad y después por nombre (doc. 07).
  @JsonKey(defaultValue: Prioridad.media)
  final int prioridad;

  /// Señal del contexto: "Después de desayunar" (intención de implementación, doc. 01).
  final String? intencion;

  /// Zona según la evidencia (`v_habito_evidencia`). `null` si la API no la mandó.
  final Evaluacion? evaluacion;
  final Frecuencia frecuencia;
  final bool escaleraActiva;
  final bool activo;
  @InstanteConverter()
  final DateTime fechaCreacion;
  final Racha racha;
  final HoyHabito? hoy;

  Habito copyWith({
    String? nombre,
    String? unidad,
    double? meta,
    int? nivel,
    Categoria? categoria,
    Subcategoria? subcategoria,
    int? prioridad,
    String? Function()? intencion,
    Evaluacion? Function()? evaluacion,
    bool? escaleraActiva,
    bool? activo,
    Racha? racha,
    HoyHabito? hoy,
  }) {
    return Habito(
      id: id,
      nombre: nombre ?? this.nombre,
      unidad: unidad ?? this.unidad,
      meta: meta ?? this.meta,
      nivel: nivel ?? this.nivel,
      categoria: categoria ?? this.categoria,
      subcategoria: subcategoria ?? this.subcategoria,
      prioridad: prioridad ?? this.prioridad,
      intencion: intencion == null ? this.intencion : intencion(),
      evaluacion: evaluacion == null ? this.evaluacion : evaluacion(),
      frecuencia: frecuencia,
      escaleraActiva: escaleraActiva ?? this.escaleraActiva,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion,
      racha: racha ?? this.racha,
      hoy: hoy ?? this.hoy,
    );
  }

  Map<String, dynamic> toJson() => _$HabitoToJson(this);
}

/// Prioridades de un hábito (`habito.prioridad`).
abstract final class Prioridad {
  static const int alta = 1;
  static const int media = 2;
  static const int baja = 3;
  static const List<int> todas = [alta, media, baja];
}

/// Cuerpo de `POST /habitos` (v1.6: con subcategoría; la categoría la fija la base).
@JsonSerializable()
class NuevoHabito {
  const NuevoHabito({
    required this.nombre,
    required this.subcategoriaId,
    required this.frecuencia,
    required this.meta,
    required this.unidad,
    this.escaleraActiva = true,
    this.prioridad = Prioridad.media,
    this.intencion,
  });

  factory NuevoHabito.fromJson(Map<String, dynamic> json) => _$NuevoHabitoFromJson(json);

  final String nombre;
  final String subcategoriaId;
  final Frecuencia frecuencia;
  final double meta;

  /// Una de las unidades permitidas de la subcategoría (si no, 422 `unidad-no-permitida`).
  final String unidad;
  final bool escaleraActiva;
  final int prioridad;
  final String? intencion;

  Map<String, dynamic> toJson() => _$NuevoHabitoToJson(this);
}

/// Cuerpo de `PATCH /habitos/{id}`: solo los campos que cambian. **No** acepta `meta`, `frecuencia` ni
/// `categoria_id` (la categoría sigue a la subcategoría).
class CambiosHabito {
  const CambiosHabito({
    this.nombre,
    this.subcategoriaId,
    this.unidad,
    this.prioridad,
    this.intencion,
    this.quitarIntencion = false,
    this.escaleraActiva,
    this.activo,
  });

  final String? nombre;
  final String? subcategoriaId;
  final String? unidad;
  final int? prioridad;
  final String? intencion;

  /// Manda `"intencion": null` para borrarla.
  final bool quitarIntencion;
  final bool? escaleraActiva;

  /// `false` = archivar.
  final bool? activo;

  bool get vacio => toJson().isEmpty;

  /// Solo incluye lo que no es `null` (la API rechaza campos de más con 422).
  Map<String, dynamic> toJson() => {
    if (nombre != null) 'nombre': nombre,
    if (subcategoriaId != null) 'subcategoria_id': subcategoriaId,
    if (unidad != null) 'unidad': unidad,
    if (prioridad != null) 'prioridad': prioridad,
    if (intencion != null) 'intencion': intencion else if (quitarIntencion) 'intencion': null,
    if (escaleraActiva != null) 'escalera_activa': escaleraActiva,
    if (activo != null) 'activo': activo,
  };
}
