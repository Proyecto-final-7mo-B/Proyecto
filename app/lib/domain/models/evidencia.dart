import 'package:json_annotation/json_annotation.dart';

import 'categoria.dart';

part 'evidencia.g.dart';

/// Dónde cae una meta respecto a lo que recomienda la evidencia (doc. 02 y 03 de la investigación).
@JsonEnum(fieldRename: FieldRename.snake)
enum ZonaEvidencia {
  /// Por debajo del óptimo: la Escalera puede subir.
  bajo,

  /// Dentro del óptimo: "ritmo ideal", ya no se recomienda subir.
  optimo,

  /// Arriba del óptimo sin pasar del máximo: no hace falta más, pero tampoco se pide bajar.
  alto,

  /// Arriba del máximo: se recomienda bajar.
  excesivo,

  /// Subcategoría sin rango científico o unidad sin conversión (km): la meta la define el usuario.
  sinReferencia,
}

/// Evaluación de una meta (`fn_evaluar_meta` / `v_habito_evidencia`; contrato v1.6, §5).
///
/// Los rangos vienen en la **unidad del hábito y por sesión** (por día programado): para "30 min diarios" el óptimo
/// de la OMS (150–300 min/semana) llega como 21.43–42.86.
@JsonSerializable()
class Evaluacion {
  const Evaluacion({
    required this.zona,
    required this.sentido,
    required this.paso,
    this.volumen,
    this.unidadBase,
    this.periodo,
    this.optimoDesde,
    this.optimoHasta,
    this.maximo,
    this.metaSugerida,
    this.piso,
    this.cita,
    this.fuentes,
    this.url,
    this.confianza,
    this.nota,
  });

  factory Evaluacion.fromJson(Map<String, dynamic> json) => _$EvaluacionFromJson(json);

  final ZonaEvidencia zona;
  final SentidoHabito sentido;

  /// Meta × factor (× sesiones por semana si la referencia es semanal), en la unidad base.
  final double? volumen;
  final String? unidadBase;
  final PeriodoReferencia? periodo;
  final double? optimoDesde;
  final double? optimoHasta;
  final double? maximo;

  /// Bajo: "hacia X". Excesivo: "Usar X". Reducir y alto: el límite recomendado.
  final double? metaSugerida;
  final double paso;
  final double? piso;
  final String? cita;
  final String? fuentes;
  final String? url;
  final Confianza? confianza;
  final String? nota;

  bool get tieneReferencia => zona != ZonaEvidencia.sinReferencia;

  Map<String, dynamic> toJson() => _$EvaluacionToJson(this);
}
