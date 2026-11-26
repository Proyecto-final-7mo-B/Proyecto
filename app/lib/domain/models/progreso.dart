import 'package:json_annotation/json_annotation.dart';

import 'conversores.dart';

part 'progreso.g.dart';

@JsonEnum()
enum Periodo { semana, mes, anio }

@JsonSerializable()
class ProgresoDia {
  const ProgresoDia({
    required this.fecha,
    required this.programados,
    required this.cumplidos,
    required this.cumplimiento,
  });

  factory ProgresoDia.fromJson(Map<String, dynamic> json) => _$ProgresoDiaFromJson(json);

  @FechaConverter()
  final DateTime fecha;
  final int programados;
  final int cumplidos;
  final double cumplimiento;

  Map<String, dynamic> toJson() => _$ProgresoDiaToJson(this);
}

@JsonSerializable()
class ProgresoHabito {
  const ProgresoHabito({required this.habitoId, required this.nombre, required this.cumplimiento});

  factory ProgresoHabito.fromJson(Map<String, dynamic> json) => _$ProgresoHabitoFromJson(json);

  final String habitoId;
  final String nombre;
  final double cumplimiento;

  Map<String, dynamic> toJson() => _$ProgresoHabitoToJson(this);
}

@JsonSerializable()
class MejorRacha {
  const MejorRacha({required this.categoria, required this.rachaMaxima});

  factory MejorRacha.fromJson(Map<String, dynamic> json) => _$MejorRachaFromJson(json);

  final String categoria;
  final int rachaMaxima;

  Map<String, dynamic> toJson() => _$MejorRachaToJson(this);
}

/// `GET /progreso?periodo=&fecha=`. La semana va de lunes a domingo.
@JsonSerializable()
class Progreso {
  const Progreso({
    required this.periodo,
    required this.desde,
    required this.hasta,
    required this.cumplimiento,
    required this.habitosActivos,
    required this.porDia,
    required this.porHabito,
    required this.mejoresRachas,
    required this.crecimientoMetas,
    this.variacion,
  });

  factory Progreso.fromJson(Map<String, dynamic> json) => _$ProgresoFromJson(json);

  final Periodo periodo;
  @FechaConverter()
  final DateTime desde;
  @FechaConverter()
  final DateTime hasta;
  final double cumplimiento;

  /// Contra el periodo anterior, en puntos porcentuales.
  final double? variacion;
  final int habitosActivos;
  final List<ProgresoDia> porDia;
  final List<ProgresoHabito> porHabito;
  final List<MejorRacha> mejoresRachas;
  final double crecimientoMetas;

  Map<String, dynamic> toJson() => _$ProgresoToJson(this);
}
