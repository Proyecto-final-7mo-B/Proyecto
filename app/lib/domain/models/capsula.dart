import 'package:json_annotation/json_annotation.dart';

import 'conversores.dart';

part 'capsula.g.dart';

@JsonEnum()
enum EstadoCapsula { sellada, abierta }

/// Cápsula **sin** el mensaje (la lista nunca lo trae).
@JsonSerializable()
class Capsula {
  const Capsula({
    required this.id,
    required this.habitoId,
    required this.habitoNombre,
    required this.rachaObjetivo,
    required this.progreso,
    required this.sePuedeAbrir,
    required this.estado,
    required this.tieneFoto,
    required this.creadaEn,
    this.abiertaEn,
  });

  factory Capsula.fromJson(Map<String, dynamic> json) => _$CapsulaFromJson(json);

  final String id;
  final String habitoId;
  final String habitoNombre;

  /// 7, 21 o 66.
  final int rachaObjetivo;

  /// Racha máxima desde que se selló.
  final int progreso;
  final bool sePuedeAbrir;
  final EstadoCapsula estado;

  /// La foto nunca se sube: vive en la carpeta privada del teléfono.
  final bool tieneFoto;
  @InstanteConverter()
  final DateTime creadaEn;
  @InstanteNuloConverter()
  final DateTime? abiertaEn;

  Map<String, dynamic> toJson() => _$CapsulaToJson(this);
}

/// Cuerpo de `POST /capsulas`.
@JsonSerializable()
class NuevaCapsula {
  const NuevaCapsula({
    required this.habitoId,
    required this.mensaje,
    required this.rachaObjetivo,
    required this.tieneFoto,
  });

  factory NuevaCapsula.fromJson(Map<String, dynamic> json) => _$NuevaCapsulaFromJson(json);

  final String habitoId;
  final String mensaje;
  final int rachaObjetivo;
  final bool tieneFoto;

  Map<String, dynamic> toJson() => _$NuevaCapsulaToJson(this);

  @override
  String toString() => 'NuevaCapsula(habitoId: $habitoId, rachaObjetivo: $rachaObjetivo)';
}

/// Respuesta de `POST /capsulas/{id}/abrir`.
@JsonSerializable()
class CapsulaAbierta {
  const CapsulaAbierta({required this.id, required this.mensaje, required this.abiertaEn});

  factory CapsulaAbierta.fromJson(Map<String, dynamic> json) => _$CapsulaAbiertaFromJson(json);

  final String id;
  final String mensaje;
  @InstanteConverter()
  final DateTime abiertaEn;

  Map<String, dynamic> toJson() => _$CapsulaAbiertaToJson(this);
}
