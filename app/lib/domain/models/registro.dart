import 'package:json_annotation/json_annotation.dart';

import 'conversores.dart';
import 'problema.dart';

part 'registro.g.dart';

/// De dónde salió un check-in. La cola sin conexión manda `offline`.
@JsonEnum()
enum OrigenRegistro { manual, rapido, offline }

/// Check-in, como lo devuelve `GET /habitos/{id}/registros`.
@JsonSerializable()
class Registro {
  const Registro({
    required this.id,
    required this.habitoId,
    required this.fecha,
    required this.cumplido,
    required this.origen,
    this.valor,
    this.registradoEn,
  });

  factory Registro.fromJson(Map<String, dynamic> json) => _$RegistroFromJson(json);

  final String id;
  final String habitoId;

  /// Día **local** del check-in.
  @FechaConverter()
  final DateTime fecha;
  final bool cumplido;
  final double? valor;
  final OrigenRegistro origen;
  @InstanteNuloConverter()
  final DateTime? registradoEn;

  Map<String, dynamic> toJson() => _$RegistroToJson(this);
}

/// Cuerpo de `POST /registros` y de cada elemento de `POST /registros/lote`.
/// El `id` (UUID v4) lo genera la app **antes** de guardarlo: reenviar el mismo `id` no duplica.
@JsonSerializable()
class NuevoRegistro {
  const NuevoRegistro({
    required this.id,
    required this.habitoId,
    required this.fecha,
    required this.cumplido,
    required this.origen,
    this.valor,
  });

  factory NuevoRegistro.fromJson(Map<String, dynamic> json) => _$NuevoRegistroFromJson(json);

  final String id;
  final String habitoId;
  @FechaConverter()
  final DateTime fecha;
  final bool cumplido;
  final double? valor;
  final OrigenRegistro origen;

  Map<String, dynamic> toJson() => _$NuevoRegistroToJson(this);
}

/// Respuesta de `POST /registros`.
@JsonSerializable()
class ResultadoCheckin {
  const ResultadoCheckin({required this.id, required this.rachaActual});

  factory ResultadoCheckin.fromJson(Map<String, dynamic> json) => _$ResultadoCheckinFromJson(json);

  final String id;
  final int rachaActual;

  Map<String, dynamic> toJson() => _$ResultadoCheckinToJson(this);
}

@JsonEnum()
enum EstadoElementoLote { aceptado, rechazado }

/// Resultado de un elemento de `POST /registros/lote`.
@JsonSerializable()
class ElementoLote {
  const ElementoLote({required this.id, required this.estado, this.rachaActual, this.error});

  factory ElementoLote.fromJson(Map<String, dynamic> json) => _$ElementoLoteFromJson(json);

  final String id;
  final EstadoElementoLote estado;
  final int? rachaActual;
  @JsonKey(fromJson: _problemaDesdeJson, toJson: _problemaAJson)
  final Problema? error;

  bool get aceptado => estado == EstadoElementoLote.aceptado;

  Map<String, dynamic> toJson() => _$ElementoLoteToJson(this);
}

Problema? _problemaDesdeJson(Map<String, dynamic>? json) => json == null ? null : Problema.fromJson(json);
Map<String, dynamic>? _problemaAJson(Problema? p) => p?.toJson();

/// Respuesta de `POST /registros/lote`.
@JsonSerializable()
class ResultadoLote {
  const ResultadoLote({required this.resultados});

  factory ResultadoLote.fromJson(Map<String, dynamic> json) => _$ResultadoLoteFromJson(json);

  final List<ElementoLote> resultados;

  Map<String, dynamic> toJson() => _$ResultadoLoteToJson(this);
}
