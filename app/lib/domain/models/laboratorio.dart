import 'package:json_annotation/json_annotation.dart';

import 'conversores.dart';

part 'laboratorio.g.dart';

/// Señal diaria de ánimo y energía (1–5). Necesita el consentimiento de señales.
@JsonSerializable()
class Senal {
  const Senal({required this.fecha, required this.animo, required this.energia});

  factory Senal.fromJson(Map<String, dynamic> json) => _$SenalFromJson(json);

  @FechaConverter()
  final DateTime fecha;
  final int animo;
  final int energia;

  Map<String, dynamic> toJson() => _$SenalToJson(this);
}

@JsonEnum(fieldRename: FieldRename.snake)
enum TipoPerspectiva { asociacion, franjaHoraria, riesgoAbandono, capsulaCercana, desconocido }

@JsonSerializable()
class HabitoReferido {
  const HabitoReferido({required this.id, required this.nombre});

  factory HabitoReferido.fromJson(Map<String, dynamic> json) => _$HabitoReferidoFromJson(json);

  final String id;
  final String nombre;

  Map<String, dynamic> toJson() => _$HabitoReferidoToJson(this);
}

/// Una perspectiva del Laboratorio (contrato v1.4: trae `categoria` y `habitos`). Los campos que no aplican a un
/// tipo no vienen.
@JsonSerializable(includeIfNull: false)
class Perspectiva {
  const Perspectiva({
    required this.tipo,
    required this.texto,
    this.categoria,
    this.habitos = const [],
    this.variable,
    this.delta,
    this.diasCon,
    this.diasSin,
    this.franja,
    this.cumplimiento7d,
    this.pendiente14d,
    this.rachaObjetivo,
    this.diasRestantes,
  });

  factory Perspectiva.fromJson(Map<String, dynamic> json) => _$PerspectivaFromJson(json);

  @JsonKey(unknownEnumValue: TipoPerspectiva.desconocido)
  final TipoPerspectiva tipo;
  final String texto;
  final String? categoria;
  final List<HabitoReferido> habitos;

  /// `animo` o `energia` (tipo `asociacion`).
  final String? variable;
  final double? delta;
  final int? diasCon;
  final int? diasSin;

  /// `manana`, `tarde` o `noche` (tipo `franja_horaria`).
  final String? franja;
  @JsonKey(name: 'cumplimiento_7d')
  final double? cumplimiento7d;
  @JsonKey(name: 'pendiente_14d')
  final double? pendiente14d;
  final int? rachaObjetivo;
  final int? diasRestantes;

  Map<String, dynamic> toJson() => _$PerspectivaToJson(this);
}

/// `GET /laboratorio/perspectivas?semana=2026-W47`.
@JsonSerializable()
class Perspectivas {
  const Perspectivas({
    required this.semana,
    required this.datosSuficientes,
    required this.perspectivas,
    this.generadoEn,
  });

  factory Perspectivas.fromJson(Map<String, dynamic> json) => _$PerspectivasFromJson(json);

  /// Semana ISO (`2026-W47`).
  final String semana;

  /// `false` con menos de 14 días de datos (y entonces `perspectivas` viene vacía).
  final bool datosSuficientes;
  @InstanteNuloConverter()
  final DateTime? generadoEn;
  final List<Perspectiva> perspectivas;

  Map<String, dynamic> toJson() => _$PerspectivasToJson(this);
}
