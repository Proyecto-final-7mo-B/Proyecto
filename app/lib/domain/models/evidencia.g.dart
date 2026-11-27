// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evidencia.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Evaluacion _$EvaluacionFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Evaluacion',
  json,
  ($checkedConvert) {
    final val = Evaluacion(
      zona: $checkedConvert(
        'zona',
        (v) => $enumDecode(_$ZonaEvidenciaEnumMap, v),
      ),
      sentido: $checkedConvert(
        'sentido',
        (v) => $enumDecode(_$SentidoHabitoEnumMap, v),
      ),
      paso: $checkedConvert('paso', (v) => (v as num).toDouble()),
      volumen: $checkedConvert('volumen', (v) => (v as num?)?.toDouble()),
      unidadBase: $checkedConvert('unidad_base', (v) => v as String?),
      periodo: $checkedConvert(
        'periodo',
        (v) => $enumDecodeNullable(_$PeriodoReferenciaEnumMap, v),
      ),
      optimoDesde: $checkedConvert(
        'optimo_desde',
        (v) => (v as num?)?.toDouble(),
      ),
      optimoHasta: $checkedConvert(
        'optimo_hasta',
        (v) => (v as num?)?.toDouble(),
      ),
      maximo: $checkedConvert('maximo', (v) => (v as num?)?.toDouble()),
      metaSugerida: $checkedConvert(
        'meta_sugerida',
        (v) => (v as num?)?.toDouble(),
      ),
      piso: $checkedConvert('piso', (v) => (v as num?)?.toDouble()),
      cita: $checkedConvert('cita', (v) => v as String?),
      fuentes: $checkedConvert('fuentes', (v) => v as String?),
      url: $checkedConvert('url', (v) => v as String?),
      confianza: $checkedConvert(
        'confianza',
        (v) => $enumDecodeNullable(_$ConfianzaEnumMap, v),
      ),
      nota: $checkedConvert('nota', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'unidadBase': 'unidad_base',
    'optimoDesde': 'optimo_desde',
    'optimoHasta': 'optimo_hasta',
    'metaSugerida': 'meta_sugerida',
  },
);

Map<String, dynamic> _$EvaluacionToJson(Evaluacion instance) =>
    <String, dynamic>{
      'zona': _$ZonaEvidenciaEnumMap[instance.zona]!,
      'sentido': _$SentidoHabitoEnumMap[instance.sentido]!,
      'volumen': instance.volumen,
      'unidad_base': instance.unidadBase,
      'periodo': _$PeriodoReferenciaEnumMap[instance.periodo],
      'optimo_desde': instance.optimoDesde,
      'optimo_hasta': instance.optimoHasta,
      'maximo': instance.maximo,
      'meta_sugerida': instance.metaSugerida,
      'paso': instance.paso,
      'piso': instance.piso,
      'cita': instance.cita,
      'fuentes': instance.fuentes,
      'url': instance.url,
      'confianza': _$ConfianzaEnumMap[instance.confianza],
      'nota': instance.nota,
    };

const _$ZonaEvidenciaEnumMap = {
  ZonaEvidencia.bajo: 'bajo',
  ZonaEvidencia.optimo: 'optimo',
  ZonaEvidencia.alto: 'alto',
  ZonaEvidencia.excesivo: 'excesivo',
  ZonaEvidencia.sinReferencia: 'sin_referencia',
};

const _$SentidoHabitoEnumMap = {
  SentidoHabito.aumentar: 'aumentar',
  SentidoHabito.reducir: 'reducir',
};

const _$PeriodoReferenciaEnumMap = {
  PeriodoReferencia.dia: 'dia',
  PeriodoReferencia.semana: 'semana',
};

const _$ConfianzaEnumMap = {
  Confianza.alta: 'alta',
  Confianza.media: 'media',
  Confianza.baja: 'baja',
};
