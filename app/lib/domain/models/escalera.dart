import 'package:json_annotation/json_annotation.dart';

import 'conversores.dart';

part 'escalera.g.dart';

@JsonEnum()
enum TipoSugerencia { subir, bajar }

@JsonEnum()
enum EstadoSugerencia { pendiente, aceptada, rechazada, expirada }

/// Por qué la Escalera v2 propone el cambio (contrato v1.6; reglas en el doc. 02 de la investigación).
@JsonEnum(fieldRename: FieldRename.snake)
enum MotivoSugerencia {
  /// Regla anterior al 27-nov (solo por cumplimiento).
  cumplimiento,

  /// ≥ 85 % en 14 días.
  cumplimientoAlto,

  /// < 50 % en 14 días.
  cumplimientoBajo,

  /// La meta pasa del máximo que recomienda la evidencia.
  excedeMaximo,
}

/// Sugerencia de la Escalera (`GET /escalera/sugerencias`).
@JsonSerializable()
class Sugerencia {
  const Sugerencia({
    required this.id,
    required this.habitoId,
    required this.habitoNombre,
    required this.tipo,
    required this.metaActual,
    required this.metaPropuesta,
    required this.estado,
    required this.creadaEn,
    this.cumplimiento14d,
    this.motivo = MotivoSugerencia.cumplimiento,
    this.cita,
    this.resueltaEn,
  });

  factory Sugerencia.fromJson(Map<String, dynamic> json) => _$SugerenciaFromJson(json);

  final String id;
  final String habitoId;
  final String habitoNombre;
  final TipoSugerencia tipo;
  final double metaActual;
  final double metaPropuesta;

  /// Porcentaje 0–100 de los últimos 14 días. `null` cuando el motivo es [MotivoSugerencia.excedeMaximo].
  @JsonKey(name: 'cumplimiento_14d')
  final double? cumplimiento14d;
  @JsonKey(defaultValue: MotivoSugerencia.cumplimiento, unknownEnumValue: MotivoSugerencia.cumplimiento)
  final MotivoSugerencia motivo;

  /// Cita corta de la referencia científica (`null` en subcategorías sin rango).
  final String? cita;
  final EstadoSugerencia estado;
  @InstanteConverter()
  final DateTime creadaEn;
  @InstanteNuloConverter()
  final DateTime? resueltaEn;

  Map<String, dynamic> toJson() => _$SugerenciaToJson(this);
}

/// Respuesta de `POST /escalera/sugerencias/{id}/respuesta`. Si se rechaza, `nivel` y `metaNueva` son `null`.
@JsonSerializable()
class RespuestaSugerencia {
  const RespuestaSugerencia({required this.estado, this.nivel, this.metaNueva});

  factory RespuestaSugerencia.fromJson(Map<String, dynamic> json) => _$RespuestaSugerenciaFromJson(json);

  final EstadoSugerencia estado;
  final int? nivel;
  final double? metaNueva;

  Map<String, dynamic> toJson() => _$RespuestaSugerenciaToJson(this);
}

/// Un nivel alcanzado de la Escalera. `hasta = null` es el nivel vigente.
@JsonSerializable()
class Nivel {
  const Nivel({required this.nivel, required this.meta, required this.desde, this.hasta});

  factory Nivel.fromJson(Map<String, dynamic> json) => _$NivelFromJson(json);

  final int nivel;
  final double meta;
  @FechaConverter()
  final DateTime desde;
  @FechaNulaConverter()
  final DateTime? hasta;

  Map<String, dynamic> toJson() => _$NivelToJson(this);
}

/// Sugerencia pendiente dentro de la Escalera de un hábito.
@JsonSerializable()
class SugerenciaPendiente {
  const SugerenciaPendiente({
    required this.id,
    required this.tipo,
    required this.metaPropuesta,
    this.cumplimiento14d,
    this.motivo = MotivoSugerencia.cumplimiento,
  });

  factory SugerenciaPendiente.fromJson(Map<String, dynamic> json) => _$SugerenciaPendienteFromJson(json);

  final String id;
  final TipoSugerencia tipo;
  final double metaPropuesta;
  @JsonKey(name: 'cumplimiento_14d')
  final double? cumplimiento14d;
  @JsonKey(defaultValue: MotivoSugerencia.cumplimiento, unknownEnumValue: MotivoSugerencia.cumplimiento)
  final MotivoSugerencia motivo;

  Map<String, dynamic> toJson() => _$SugerenciaPendienteToJson(this);
}

/// Un cambio pasado de la Escalera.
@JsonSerializable()
class CambioEscalera {
  const CambioEscalera({
    required this.fecha,
    required this.tipo,
    required this.de,
    required this.a,
    required this.estado,
  });

  factory CambioEscalera.fromJson(Map<String, dynamic> json) => _$CambioEscaleraFromJson(json);

  @FechaConverter()
  final DateTime fecha;
  final TipoSugerencia tipo;
  final double de;
  final double a;
  final EstadoSugerencia estado;

  Map<String, dynamic> toJson() => _$CambioEscaleraToJson(this);
}

/// `GET /habitos/{id}/escalera`. Los niveles futuros no existen en la base: la app los proyecta (+10 % cada uno).
@JsonSerializable()
class EscaleraHabito {
  const EscaleraHabito({
    required this.habitoId,
    required this.escaleraActiva,
    required this.nivelActual,
    required this.metaActual,
    required this.unidad,
    required this.niveles,
    required this.historial,
    this.sugerenciaPendiente,
  });

  factory EscaleraHabito.fromJson(Map<String, dynamic> json) => _$EscaleraHabitoFromJson(json);

  final String habitoId;
  final bool escaleraActiva;
  final int nivelActual;
  final double metaActual;
  final String unidad;
  final List<Nivel> niveles;
  final SugerenciaPendiente? sugerenciaPendiente;
  final List<CambioEscalera> historial;

  Map<String, dynamic> toJson() => _$EscaleraHabitoToJson(this);
}
