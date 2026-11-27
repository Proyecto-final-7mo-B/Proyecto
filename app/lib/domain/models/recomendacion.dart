import 'package:json_annotation/json_annotation.dart';

import 'categoria.dart';
import 'evidencia.dart';
import 'frecuencia.dart';

part 'recomendacion.g.dart';

/// Hábito saludable listo para crear (`GET /habitos/recomendados`, contrato v1.7). Nombre, meta, frecuencia y momento
/// ya vienen definidos con base en la evidencia; el usuario solo elige la prioridad y la cápsula.
@JsonSerializable()
class HabitoRecomendado {
  const HabitoRecomendado({
    required this.id,
    required this.clave,
    required this.nombre,
    required this.categoria,
    required this.subcategoria,
    required this.unidad,
    required this.meta,
    required this.frecuencia,
    required this.momento,
    required this.porque,
    required this.fuentes,
    this.zona = ZonaEvidencia.sinReferencia,
    this.optimoDesde,
    this.optimoHasta,
  });

  factory HabitoRecomendado.fromJson(Map<String, dynamic> json) => _$HabitoRecomendadoFromJson(json);

  final String id;
  final String clave;
  final String nombre;
  final Categoria categoria;
  final Subcategoria subcategoria;
  final String unidad;
  final double meta;
  final Frecuencia frecuencia;

  /// Cuándo hacerlo ("Después de comer"): se vuelve la intención del hábito.
  final String momento;

  /// Por qué, sin la cita (la fuente está en [fuentes] y en "Acerca de Kaizen").
  final String porque;

  /// Claves `F##` de `GET /fuentes`.
  final String fuentes;
  @JsonKey(unknownEnumValue: ZonaEvidencia.sinReferencia)
  final ZonaEvidencia zona;

  /// Rango óptimo por sesión, en [unidad]; `null` sin referencia.
  final double? optimoDesde;
  final double? optimoHasta;

  Map<String, dynamic> toJson() => _$HabitoRecomendadoToJson(this);
}

/// Una fuente de la investigación (`GET /fuentes`, v1.7), para "Acerca de Kaizen".
@JsonSerializable()
class FuenteCientifica {
  const FuenteCientifica({
    required this.clave,
    required this.tema,
    required this.referencia,
    required this.enlace,
    required this.dato,
    required this.verificada,
    required this.confianza,
  });

  factory FuenteCientifica.fromJson(Map<String, dynamic> json) => _$FuenteCientificaFromJson(json);

  /// `F01` … `F53`.
  final String clave;

  /// `formacion`, `actividad`, `salud`, `educacion`, `bienestar`, `color` o `notificaciones`.
  final String tema;
  final String referencia;

  /// DOI o URL (a veces dos, separados por "·").
  final String enlace;

  /// Lo que la app toma de esa fuente.
  final String dato;
  final String verificada;
  final String confianza;

  Map<String, dynamic> toJson() => _$FuenteCientificaToJson(this);
}
