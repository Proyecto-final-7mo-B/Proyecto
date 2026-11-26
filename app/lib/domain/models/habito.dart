import 'package:json_annotation/json_annotation.dart';

import 'categoria.dart';
import 'conversores.dart';
import 'frecuencia.dart';

part 'habito.g.dart';

/// Racha vigente (de `v_racha_vigente`).
@JsonSerializable()
class Racha {
  const Racha({required this.actual, required this.maxima, this.ultimaFecha});

  factory Racha.fromJson(Map<String, dynamic> json) => _$RachaFromJson(json);

  final int actual;
  final int maxima;
  @FechaNulaConverter()
  final DateTime? ultimaFecha;

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
    required this.frecuencia,
    required this.escaleraActiva,
    required this.activo,
    required this.fechaCreacion,
    required this.racha,
    this.hoy,
  });

  factory Habito.fromJson(Map<String, dynamic> json) => _$HabitoFromJson(json);

  final String id;
  final String nombre;
  final String unidad;

  /// Meta vigente. Solo se fija al crear; después cambia aceptando una sugerencia de la Escalera.
  final double meta;
  final int nivel;
  final Categoria categoria;
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

/// Cuerpo de `POST /habitos`.
@JsonSerializable()
class NuevoHabito {
  const NuevoHabito({
    required this.nombre,
    required this.categoriaId,
    required this.frecuencia,
    required this.meta,
    required this.unidad,
    this.escaleraActiva = true,
  });

  factory NuevoHabito.fromJson(Map<String, dynamic> json) => _$NuevoHabitoFromJson(json);

  final String nombre;
  final String categoriaId;
  final Frecuencia frecuencia;
  final double meta;
  final String unidad;
  final bool escaleraActiva;

  Map<String, dynamic> toJson() => _$NuevoHabitoToJson(this);
}

/// Cuerpo de `PATCH /habitos/{id}`: solo los campos que cambian. **No** acepta `meta` ni `frecuencia`.
class CambiosHabito {
  const CambiosHabito({this.nombre, this.categoriaId, this.unidad, this.escaleraActiva, this.activo});

  final String? nombre;
  final String? categoriaId;
  final String? unidad;
  final bool? escaleraActiva;

  /// `false` = archivar.
  final bool? activo;

  bool get vacio => toJson().isEmpty;

  /// Solo incluye lo que no es `null` (la API rechaza campos de más con 422).
  Map<String, dynamic> toJson() => {
    if (nombre != null) 'nombre': nombre,
    if (categoriaId != null) 'categoria_id': categoriaId,
    if (unidad != null) 'unidad': unidad,
    if (escaleraActiva != null) 'escalera_activa': escaleraActiva,
    if (activo != null) 'activo': activo,
  };
}
