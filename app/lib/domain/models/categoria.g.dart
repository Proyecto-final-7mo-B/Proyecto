// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categoria.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UnidadPermitida _$UnidadPermitidaFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UnidadPermitida', json, ($checkedConvert) {
      final val = UnidadPermitida(
        unidad: $checkedConvert('unidad', (v) => v as String),
        paso: $checkedConvert('paso', (v) => (v as num).toDouble()),
        minimo: $checkedConvert('minimo', (v) => (v as num).toDouble()),
        maximo: $checkedConvert('maximo', (v) => (v as num).toDouble()),
        factorABase: $checkedConvert(
          'factor_a_base',
          (v) => (v as num?)?.toDouble(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'factorABase': 'factor_a_base'});

Map<String, dynamic> _$UnidadPermitidaToJson(UnidadPermitida instance) =>
    <String, dynamic>{
      'unidad': instance.unidad,
      'factor_a_base': instance.factorABase,
      'paso': instance.paso,
      'minimo': instance.minimo,
      'maximo': instance.maximo,
    };

ReferenciaCientifica _$ReferenciaCientificaFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'ReferenciaCientifica',
  json,
  ($checkedConvert) {
    final val = ReferenciaCientifica(
      periodo: $checkedConvert(
        'periodo',
        (v) => $enumDecode(_$PeriodoReferenciaEnumMap, v),
      ),
      unidadBase: $checkedConvert('unidad_base', (v) => v as String),
      optimoDesde: $checkedConvert(
        'optimo_desde',
        (v) => (v as num).toDouble(),
      ),
      optimoHasta: $checkedConvert(
        'optimo_hasta',
        (v) => (v as num).toDouble(),
      ),
      cita: $checkedConvert('cita', (v) => v as String),
      fuentes: $checkedConvert('fuentes', (v) => v as String),
      url: $checkedConvert('url', (v) => v as String),
      confianza: $checkedConvert(
        'confianza',
        (v) => $enumDecode(_$ConfianzaEnumMap, v),
      ),
      maximo: $checkedConvert('maximo', (v) => (v as num?)?.toDouble()),
      pisoBajada: $checkedConvert(
        'piso_bajada',
        (v) => (v as num?)?.toDouble(),
      ),
      nota: $checkedConvert('nota', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'unidadBase': 'unidad_base',
    'optimoDesde': 'optimo_desde',
    'optimoHasta': 'optimo_hasta',
    'pisoBajada': 'piso_bajada',
  },
);

Map<String, dynamic> _$ReferenciaCientificaToJson(
  ReferenciaCientifica instance,
) => <String, dynamic>{
  'periodo': _$PeriodoReferenciaEnumMap[instance.periodo]!,
  'unidad_base': instance.unidadBase,
  'optimo_desde': instance.optimoDesde,
  'optimo_hasta': instance.optimoHasta,
  'maximo': instance.maximo,
  'piso_bajada': instance.pisoBajada,
  'cita': instance.cita,
  'fuentes': instance.fuentes,
  'url': instance.url,
  'confianza': _$ConfianzaEnumMap[instance.confianza]!,
  'nota': instance.nota,
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

Subcategoria _$SubcategoriaFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Subcategoria', json, ($checkedConvert) {
      final val = Subcategoria(
        id: $checkedConvert('id', (v) => v as String),
        clave: $checkedConvert('clave', (v) => v as String),
        nombre: $checkedConvert('nombre', (v) => v as String),
        icono: $checkedConvert('icono', (v) => v as String),
        sentido: $checkedConvert(
          'sentido',
          (v) =>
              $enumDecodeNullable(_$SentidoHabitoEnumMap, v) ??
              SentidoHabito.aumentar,
        ),
        activa: $checkedConvert('activa', (v) => v as bool? ?? true),
        unidades: $checkedConvert(
          'unidades',
          (v) =>
              (v as List<dynamic>?)
                  ?.map(
                    (e) => UnidadPermitida.fromJson(e as Map<String, dynamic>),
                  )
                  .toList() ??
              [],
        ),
        referencia: $checkedConvert(
          'referencia',
          (v) => v == null
              ? null
              : ReferenciaCientifica.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$SubcategoriaToJson(Subcategoria instance) =>
    <String, dynamic>{
      'id': instance.id,
      'clave': instance.clave,
      'nombre': instance.nombre,
      'icono': instance.icono,
      'sentido': _$SentidoHabitoEnumMap[instance.sentido]!,
      'activa': instance.activa,
      'unidades': instance.unidades.map((e) => e.toJson()).toList(),
      'referencia': instance.referencia?.toJson(),
    };

const _$SentidoHabitoEnumMap = {
  SentidoHabito.aumentar: 'aumentar',
  SentidoHabito.reducir: 'reducir',
};

Categoria _$CategoriaFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Categoria', json, ($checkedConvert) {
      final val = Categoria(
        id: $checkedConvert('id', (v) => v as String),
        nombre: $checkedConvert('nombre', (v) => v as String),
        clave: $checkedConvert('clave', (v) => v as String? ?? ''),
        color: $checkedConvert('color', (v) => v as String? ?? '#1B2A5E'),
        icono: $checkedConvert('icono', (v) => v as String? ?? 'category'),
        activa: $checkedConvert('activa', (v) => v as bool? ?? true),
        subcategorias: $checkedConvert(
          'subcategorias',
          (v) =>
              (v as List<dynamic>?)
                  ?.map((e) => Subcategoria.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [],
        ),
      );
      return val;
    });

Map<String, dynamic> _$CategoriaToJson(Categoria instance) => <String, dynamic>{
  'id': instance.id,
  'clave': instance.clave,
  'nombre': instance.nombre,
  'color': instance.color,
  'icono': instance.icono,
  'activa': instance.activa,
  'subcategorias': instance.subcategorias.map((e) => e.toJson()).toList(),
};
