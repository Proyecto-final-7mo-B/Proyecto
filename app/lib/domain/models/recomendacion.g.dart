// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recomendacion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HabitoRecomendado _$HabitoRecomendadoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'HabitoRecomendado',
      json,
      ($checkedConvert) {
        final val = HabitoRecomendado(
          id: $checkedConvert('id', (v) => v as String),
          clave: $checkedConvert('clave', (v) => v as String),
          nombre: $checkedConvert('nombre', (v) => v as String),
          categoria: $checkedConvert(
            'categoria',
            (v) => Categoria.fromJson(v as Map<String, dynamic>),
          ),
          subcategoria: $checkedConvert(
            'subcategoria',
            (v) => Subcategoria.fromJson(v as Map<String, dynamic>),
          ),
          unidad: $checkedConvert('unidad', (v) => v as String),
          meta: $checkedConvert('meta', (v) => (v as num).toDouble()),
          frecuencia: $checkedConvert(
            'frecuencia',
            (v) => Frecuencia.fromJson(v as Map<String, dynamic>),
          ),
          momento: $checkedConvert('momento', (v) => v as String),
          porque: $checkedConvert('porque', (v) => v as String),
          fuentes: $checkedConvert('fuentes', (v) => v as String),
          zona: $checkedConvert(
            'zona',
            (v) =>
                $enumDecodeNullable(
                  _$ZonaEvidenciaEnumMap,
                  v,
                  unknownValue: ZonaEvidencia.sinReferencia,
                ) ??
                ZonaEvidencia.sinReferencia,
          ),
          optimoDesde: $checkedConvert(
            'optimo_desde',
            (v) => (v as num?)?.toDouble(),
          ),
          optimoHasta: $checkedConvert(
            'optimo_hasta',
            (v) => (v as num?)?.toDouble(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'optimoDesde': 'optimo_desde',
        'optimoHasta': 'optimo_hasta',
      },
    );

Map<String, dynamic> _$HabitoRecomendadoToJson(HabitoRecomendado instance) =>
    <String, dynamic>{
      'id': instance.id,
      'clave': instance.clave,
      'nombre': instance.nombre,
      'categoria': instance.categoria.toJson(),
      'subcategoria': instance.subcategoria.toJson(),
      'unidad': instance.unidad,
      'meta': instance.meta,
      'frecuencia': instance.frecuencia.toJson(),
      'momento': instance.momento,
      'porque': instance.porque,
      'fuentes': instance.fuentes,
      'zona': _$ZonaEvidenciaEnumMap[instance.zona]!,
      'optimo_desde': instance.optimoDesde,
      'optimo_hasta': instance.optimoHasta,
    };

const _$ZonaEvidenciaEnumMap = {
  ZonaEvidencia.bajo: 'bajo',
  ZonaEvidencia.optimo: 'optimo',
  ZonaEvidencia.alto: 'alto',
  ZonaEvidencia.excesivo: 'excesivo',
  ZonaEvidencia.sinReferencia: 'sin_referencia',
};

FuenteCientifica _$FuenteCientificaFromJson(Map<String, dynamic> json) =>
    $checkedCreate('FuenteCientifica', json, ($checkedConvert) {
      final val = FuenteCientifica(
        clave: $checkedConvert('clave', (v) => v as String),
        tema: $checkedConvert('tema', (v) => v as String),
        referencia: $checkedConvert('referencia', (v) => v as String),
        enlace: $checkedConvert('enlace', (v) => v as String),
        dato: $checkedConvert('dato', (v) => v as String),
        verificada: $checkedConvert('verificada', (v) => v as String),
        confianza: $checkedConvert('confianza', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$FuenteCientificaToJson(FuenteCientifica instance) =>
    <String, dynamic>{
      'clave': instance.clave,
      'tema': instance.tema,
      'referencia': instance.referencia,
      'enlace': instance.enlace,
      'dato': instance.dato,
      'verificada': instance.verificada,
      'confianza': instance.confianza,
    };
