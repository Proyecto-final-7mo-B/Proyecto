// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'capsula.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Capsula _$CapsulaFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Capsula',
  json,
  ($checkedConvert) {
    final val = Capsula(
      id: $checkedConvert('id', (v) => v as String),
      habitoId: $checkedConvert('habito_id', (v) => v as String),
      habitoNombre: $checkedConvert('habito_nombre', (v) => v as String),
      rachaObjetivo: $checkedConvert(
        'racha_objetivo',
        (v) => (v as num).toInt(),
      ),
      progreso: $checkedConvert('progreso', (v) => (v as num).toInt()),
      sePuedeAbrir: $checkedConvert('se_puede_abrir', (v) => v as bool),
      estado: $checkedConvert(
        'estado',
        (v) => $enumDecode(_$EstadoCapsulaEnumMap, v),
      ),
      tieneFoto: $checkedConvert('tiene_foto', (v) => v as bool),
      creadaEn: $checkedConvert(
        'creada_en',
        (v) => const InstanteConverter().fromJson(v as String),
      ),
      abiertaEn: $checkedConvert(
        'abierta_en',
        (v) => const InstanteNuloConverter().fromJson(v as String?),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'habitoId': 'habito_id',
    'habitoNombre': 'habito_nombre',
    'rachaObjetivo': 'racha_objetivo',
    'sePuedeAbrir': 'se_puede_abrir',
    'tieneFoto': 'tiene_foto',
    'creadaEn': 'creada_en',
    'abiertaEn': 'abierta_en',
  },
);

Map<String, dynamic> _$CapsulaToJson(Capsula instance) => <String, dynamic>{
  'id': instance.id,
  'habito_id': instance.habitoId,
  'habito_nombre': instance.habitoNombre,
  'racha_objetivo': instance.rachaObjetivo,
  'progreso': instance.progreso,
  'se_puede_abrir': instance.sePuedeAbrir,
  'estado': _$EstadoCapsulaEnumMap[instance.estado]!,
  'tiene_foto': instance.tieneFoto,
  'creada_en': const InstanteConverter().toJson(instance.creadaEn),
  'abierta_en': const InstanteNuloConverter().toJson(instance.abiertaEn),
};

const _$EstadoCapsulaEnumMap = {
  EstadoCapsula.sellada: 'sellada',
  EstadoCapsula.abierta: 'abierta',
};

NuevaCapsula _$NuevaCapsulaFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'NuevaCapsula',
      json,
      ($checkedConvert) {
        final val = NuevaCapsula(
          habitoId: $checkedConvert('habito_id', (v) => v as String),
          mensaje: $checkedConvert('mensaje', (v) => v as String),
          rachaObjetivo: $checkedConvert(
            'racha_objetivo',
            (v) => (v as num).toInt(),
          ),
          tieneFoto: $checkedConvert('tiene_foto', (v) => v as bool),
        );
        return val;
      },
      fieldKeyMap: const {
        'habitoId': 'habito_id',
        'rachaObjetivo': 'racha_objetivo',
        'tieneFoto': 'tiene_foto',
      },
    );

Map<String, dynamic> _$NuevaCapsulaToJson(NuevaCapsula instance) =>
    <String, dynamic>{
      'habito_id': instance.habitoId,
      'mensaje': instance.mensaje,
      'racha_objetivo': instance.rachaObjetivo,
      'tiene_foto': instance.tieneFoto,
    };

CapsulaAbierta _$CapsulaAbiertaFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CapsulaAbierta', json, ($checkedConvert) {
      final val = CapsulaAbierta(
        id: $checkedConvert('id', (v) => v as String),
        mensaje: $checkedConvert('mensaje', (v) => v as String),
        abiertaEn: $checkedConvert(
          'abierta_en',
          (v) => const InstanteConverter().fromJson(v as String),
        ),
      );
      return val;
    }, fieldKeyMap: const {'abiertaEn': 'abierta_en'});

Map<String, dynamic> _$CapsulaAbiertaToJson(CapsulaAbierta instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mensaje': instance.mensaje,
      'abierta_en': const InstanteConverter().toJson(instance.abiertaEn),
    };
