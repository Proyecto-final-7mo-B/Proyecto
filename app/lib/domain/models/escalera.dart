import 'package:json_annotation/json_annotation.dart';

import 'conversores.dart';

part 'escalera.g.dart';

@JsonEnum()
enum TipoSugerencia { subir, bajar }

@JsonEnum()
enum EstadoSugerencia { pendiente, aceptada, rechazada, expirada }

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
    required this.cumplimiento14d,
    required this.estado,
    required this.creadaEn,
    this.resueltaEn,
  });

  factory Sugerencia.fromJson(Map<String, dynamic> json) => _$SugerenciaFromJson(json);

  final String id;
  final String habitoId;
  final String habitoNombre;
  final TipoSugerencia tipo;
  final double metaActual;
  final double metaPropuesta;

  /// Porcentaje 0–100 de los últimos 14 días.
  @JsonKey(name: 'cumplimiento_14d')
  final double cumplimiento14d;
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
    required this.cumplimiento14d,
  });

  factory SugerenciaPendiente.fromJson(Map<String, dynamic> json) => _$SugerenciaPendienteFromJson(json);

  final String id;
  final TipoSugerencia tipo;
  final double metaPropuesta;
  @JsonKey(name: 'cumplimiento_14d')
  final double cumplimiento14d;

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
