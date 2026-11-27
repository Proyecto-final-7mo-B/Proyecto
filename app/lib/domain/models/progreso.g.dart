// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progreso.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProgresoDia _$ProgresoDiaFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ProgresoDia', json, ($checkedConvert) {
      final val = ProgresoDia(
        fecha: $checkedConvert(
          'fecha',
          (v) => const FechaConverter().fromJson(v as String),
        ),
        programados: $checkedConvert('programados', (v) => (v as num).toInt()),
        cumplidos: $checkedConvert('cumplidos', (v) => (v as num).toInt()),
        cumplimiento: $checkedConvert(
          'cumplimiento',
          (v) => (v as num).toDouble(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ProgresoDiaToJson(ProgresoDia instance) =>
    <String, dynamic>{
      'fecha': const FechaConverter().toJson(instance.fecha),
      'programados': instance.programados,
      'cumplidos': instance.cumplidos,
      'cumplimiento': instance.cumplimiento,
    };

ProgresoHabito _$ProgresoHabitoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ProgresoHabito', json, ($checkedConvert) {
      final val = ProgresoHabito(
        habitoId: $checkedConvert('habito_id', (v) => v as String),
        nombre: $checkedConvert('nombre', (v) => v as String),
        cumplimiento: $checkedConvert(
          'cumplimiento',
          (v) => (v as num).toDouble(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'habitoId': 'habito_id'});

Map<String, dynamic> _$ProgresoHabitoToJson(ProgresoHabito instance) =>
    <String, dynamic>{
      'habito_id': instance.habitoId,
      'nombre': instance.nombre,
      'cumplimiento': instance.cumplimiento,
    };

MejorRacha _$MejorRachaFromJson(Map<String, dynamic> json) => $checkedCreate(
  'MejorRacha',
  json,
  ($checkedConvert) {
    final val = MejorRacha(
      categoria: $checkedConvert('categoria', (v) => v as String),
      rachaMaxima: $checkedConvert('racha_maxima', (v) => (v as num).toInt()),
      categoriaClave: $checkedConvert(
        'categoria_clave',
        (v) => v as String? ?? '',
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'rachaMaxima': 'racha_maxima',
    'categoriaClave': 'categoria_clave',
  },
);

Map<String, dynamic> _$MejorRachaToJson(MejorRacha instance) =>
    <String, dynamic>{
      'categoria': instance.categoria,
      'categoria_clave': instance.categoriaClave,
      'racha_maxima': instance.rachaMaxima,
    };

ActividadSemanal _$ActividadSemanalFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ActividadSemanal',
      json,
      ($checkedConvert) {
        final val = ActividadSemanal(
          semana: $checkedConvert('semana', (v) => v as String),
          minutosModerados: $checkedConvert(
            'minutos_moderados',
            (v) => (v as num).toDouble(),
          ),
          minutosVigorosos: $checkedConvert(
            'minutos_vigorosos',
            (v) => (v as num).toDouble(),
          ),
          equivalenteModerado: $checkedConvert(
            'equivalente_moderado',
            (v) => (v as num).toDouble(),
          ),
          recomendadoDesde: $checkedConvert(
            'recomendado_desde',
            (v) => (v as num).toDouble(),
          ),
          recomendadoHasta: $checkedConvert(
            'recomendado_hasta',
            (v) => (v as num).toDouble(),
          ),
          cita: $checkedConvert('cita', (v) => v as String),
        );
        return val;
      },
      fieldKeyMap: const {
        'minutosModerados': 'minutos_moderados',
        'minutosVigorosos': 'minutos_vigorosos',
        'equivalenteModerado': 'equivalente_moderado',
        'recomendadoDesde': 'recomendado_desde',
        'recomendadoHasta': 'recomendado_hasta',
      },
    );

Map<String, dynamic> _$ActividadSemanalToJson(ActividadSemanal instance) =>
    <String, dynamic>{
      'semana': instance.semana,
      'minutos_moderados': instance.minutosModerados,
      'minutos_vigorosos': instance.minutosVigorosos,
      'equivalente_moderado': instance.equivalenteModerado,
      'recomendado_desde': instance.recomendadoDesde,
      'recomendado_hasta': instance.recomendadoHasta,
      'cita': instance.cita,
    };

Progreso _$ProgresoFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Progreso',
  json,
  ($checkedConvert) {
    final val = Progreso(
      periodo: $checkedConvert(
        'periodo',
        (v) => $enumDecode(_$PeriodoEnumMap, v),
      ),
      desde: $checkedConvert(
        'desde',
        (v) => const FechaConverter().fromJson(v as String),
      ),
      hasta: $checkedConvert(
        'hasta',
        (v) => const FechaConverter().fromJson(v as String),
      ),
      cumplimiento: $checkedConvert(
        'cumplimiento',
        (v) => (v as num).toDouble(),
      ),
      habitosActivos: $checkedConvert(
        'habitos_activos',
        (v) => (v as num).toInt(),
      ),
      porDia: $checkedConvert(
        'por_dia',
        (v) => (v as List<dynamic>)
            .map((e) => ProgresoDia.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      porHabito: $checkedConvert(
        'por_habito',
        (v) => (v as List<dynamic>)
            .map((e) => ProgresoHabito.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      mejoresRachas: $checkedConvert(
        'mejores_rachas',
        (v) => (v as List<dynamic>)
            .map((e) => MejorRacha.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      crecimientoMetas: $checkedConvert(
        'crecimiento_metas',
        (v) => (v as num).toDouble(),
      ),
      variacion: $checkedConvert('variacion', (v) => (v as num?)?.toDouble()),
      actividadSemanal: $checkedConvert(
        'actividad_semanal',
        (v) => v == null
            ? null
            : ActividadSemanal.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'habitosActivos': 'habitos_activos',
    'porDia': 'por_dia',
    'porHabito': 'por_habito',
    'mejoresRachas': 'mejores_rachas',
    'crecimientoMetas': 'crecimiento_metas',
    'actividadSemanal': 'actividad_semanal',
  },
);

Map<String, dynamic> _$ProgresoToJson(Progreso instance) => <String, dynamic>{
  'periodo': _$PeriodoEnumMap[instance.periodo]!,
  'desde': const FechaConverter().toJson(instance.desde),
  'hasta': const FechaConverter().toJson(instance.hasta),
  'cumplimiento': instance.cumplimiento,
  'variacion': instance.variacion,
  'habitos_activos': instance.habitosActivos,
  'por_dia': instance.porDia.map((e) => e.toJson()).toList(),
  'por_habito': instance.porHabito.map((e) => e.toJson()).toList(),
  'mejores_rachas': instance.mejoresRachas.map((e) => e.toJson()).toList(),
  'crecimiento_metas': instance.crecimientoMetas,
  'actividad_semanal': instance.actividadSemanal?.toJson(),
};

const _$PeriodoEnumMap = {
  Periodo.semana: 'semana',
  Periodo.mes: 'mes',
  Periodo.anio: 'anio',
};
