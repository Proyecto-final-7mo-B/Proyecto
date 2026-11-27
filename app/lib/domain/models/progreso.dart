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
  const MejorRacha({required this.categoria, required this.rachaMaxima, this.categoriaClave = ''});

  factory MejorRacha.fromJson(Map<String, dynamic> json) => _$MejorRachaFromJson(json);

  final String categoria;

  /// Clave estable de la categoría (v1.6), para su color.
  @JsonKey(defaultValue: '')
  final String categoriaClave;
  final int rachaMaxima;

  Map<String, dynamic> toJson() => _$MejorRachaToJson(this);
}

/// Minutos de actividad aeróbica de la semana ISO contra la recomendación de la OMS (contrato v1.6, §6.7). Suma los
/// check-ins cumplidos de `aerobico_moderado` y `vigoroso`; 1 min vigoroso = 2 moderados.
@JsonSerializable()
class ActividadSemanal {
  const ActividadSemanal({
    required this.semana,
    required this.minutosModerados,
    required this.minutosVigorosos,
    required this.equivalenteModerado,
    required this.recomendadoDesde,
    required this.recomendadoHasta,
    required this.cita,
  });

  factory ActividadSemanal.fromJson(Map<String, dynamic> json) => _$ActividadSemanalFromJson(json);

  /// `2026-W48`.
  final String semana;
  final double minutosModerados;
  final double minutosVigorosos;
  final double equivalenteModerado;
  final double recomendadoDesde;
  final double recomendadoHasta;
  final String cita;

  /// Lo que falta para el mínimo recomendado (0 si ya se alcanzó).
  double get faltante => (recomendadoDesde - equivalenteModerado).clamp(0, recomendadoDesde).toDouble();

  bool get cumplida => equivalenteModerado >= recomendadoDesde;

  Map<String, dynamic> toJson() => _$ActividadSemanalToJson(this);
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
    this.actividadSemanal,
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

  /// `null` si el usuario no tiene hábitos aeróbicos.
  final ActividadSemanal? actividadSemanal;

  Map<String, dynamic> toJson() => _$ProgresoToJson(this);
}
