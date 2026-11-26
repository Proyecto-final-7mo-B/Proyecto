// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'laboratorio.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Senal _$SenalFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Senal', json, ($checkedConvert) {
      final val = Senal(
        fecha: $checkedConvert(
          'fecha',
          (v) => const FechaConverter().fromJson(v as String),
        ),
        animo: $checkedConvert('animo', (v) => (v as num).toInt()),
        energia: $checkedConvert('energia', (v) => (v as num).toInt()),
      );
      return val;
    });

Map<String, dynamic> _$SenalToJson(Senal instance) => <String, dynamic>{
  'fecha': const FechaConverter().toJson(instance.fecha),
  'animo': instance.animo,
  'energia': instance.energia,
};

HabitoReferido _$HabitoReferidoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('HabitoReferido', json, ($checkedConvert) {
      final val = HabitoReferido(
        id: $checkedConvert('id', (v) => v as String),
        nombre: $checkedConvert('nombre', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$HabitoReferidoToJson(HabitoReferido instance) =>
    <String, dynamic>{'id': instance.id, 'nombre': instance.nombre};

Perspectiva _$PerspectivaFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Perspectiva',
  json,
  ($checkedConvert) {
    final val = Perspectiva(
      tipo: $checkedConvert(
        'tipo',
        (v) => $enumDecode(
          _$TipoPerspectivaEnumMap,
          v,
          unknownValue: TipoPerspectiva.desconocido,
        ),
      ),
      texto: $checkedConvert('texto', (v) => v as String),
      categoria: $checkedConvert('categoria', (v) => v as String?),
      habitos: $checkedConvert(
        'habitos',
        (v) =>
            (v as List<dynamic>?)
                ?.map((e) => HabitoReferido.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      ),
      variable: $checkedConvert('variable', (v) => v as String?),
      delta: $checkedConvert('delta', (v) => (v as num?)?.toDouble()),
      diasCon: $checkedConvert('dias_con', (v) => (v as num?)?.toInt()),
      diasSin: $checkedConvert('dias_sin', (v) => (v as num?)?.toInt()),
      franja: $checkedConvert('franja', (v) => v as String?),
      cumplimiento7d: $checkedConvert(
        'cumplimiento_7d',
        (v) => (v as num?)?.toDouble(),
      ),
      pendiente14d: $checkedConvert(
        'pendiente_14d',
        (v) => (v as num?)?.toDouble(),
      ),
      rachaObjetivo: $checkedConvert(
        'racha_objetivo',
        (v) => (v as num?)?.toInt(),
      ),
      diasRestantes: $checkedConvert(
        'dias_restantes',
        (v) => (v as num?)?.toInt(),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'diasCon': 'dias_con',
    'diasSin': 'dias_sin',
    'cumplimiento7d': 'cumplimiento_7d',
    'pendiente14d': 'pendiente_14d',
    'rachaObjetivo': 'racha_objetivo',
    'diasRestantes': 'dias_restantes',
  },
);

Map<String, dynamic> _$PerspectivaToJson(Perspectiva instance) =>
    <String, dynamic>{
      'tipo': _$TipoPerspectivaEnumMap[instance.tipo]!,
      'texto': instance.texto,
      'categoria': ?instance.categoria,
      'habitos': instance.habitos.map((e) => e.toJson()).toList(),
      'variable': ?instance.variable,
      'delta': ?instance.delta,
      'dias_con': ?instance.diasCon,
      'dias_sin': ?instance.diasSin,
      'franja': ?instance.franja,
      'cumplimiento_7d': ?instance.cumplimiento7d,
      'pendiente_14d': ?instance.pendiente14d,
      'racha_objetivo': ?instance.rachaObjetivo,
      'dias_restantes': ?instance.diasRestantes,
    };

const _$TipoPerspectivaEnumMap = {
  TipoPerspectiva.asociacion: 'asociacion',
  TipoPerspectiva.franjaHoraria: 'franja_horaria',
  TipoPerspectiva.riesgoAbandono: 'riesgo_abandono',
  TipoPerspectiva.capsulaCercana: 'capsula_cercana',
  TipoPerspectiva.desconocido: 'desconocido',
};

Perspectivas _$PerspectivasFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'Perspectivas',
      json,
      ($checkedConvert) {
        final val = Perspectivas(
          semana: $checkedConvert('semana', (v) => v as String),
          datosSuficientes: $checkedConvert(
            'datos_suficientes',
            (v) => v as bool,
          ),
          perspectivas: $checkedConvert(
            'perspectivas',
            (v) => (v as List<dynamic>)
                .map((e) => Perspectiva.fromJson(e as Map<String, dynamic>))
                .toList(),
          ),
          generadoEn: $checkedConvert(
            'generado_en',
            (v) => const InstanteNuloConverter().fromJson(v as String?),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'datosSuficientes': 'datos_suficientes',
        'generadoEn': 'generado_en',
      },
    );

Map<String, dynamic> _$PerspectivasToJson(Perspectivas instance) =>
    <String, dynamic>{
      'semana': instance.semana,
      'datos_suficientes': instance.datosSuficientes,
      'generado_en': const InstanteNuloConverter().toJson(instance.generadoEn),
      'perspectivas': instance.perspectivas.map((e) => e.toJson()).toList(),
    };
