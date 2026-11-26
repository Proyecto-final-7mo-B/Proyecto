// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'escalera.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Sugerencia _$SugerenciaFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Sugerencia',
  json,
  ($checkedConvert) {
    final val = Sugerencia(
      id: $checkedConvert('id', (v) => v as String),
      habitoId: $checkedConvert('habito_id', (v) => v as String),
      habitoNombre: $checkedConvert('habito_nombre', (v) => v as String),
      tipo: $checkedConvert(
        'tipo',
        (v) => $enumDecode(_$TipoSugerenciaEnumMap, v),
      ),
      metaActual: $checkedConvert('meta_actual', (v) => (v as num).toDouble()),
      metaPropuesta: $checkedConvert(
        'meta_propuesta',
        (v) => (v as num).toDouble(),
      ),
      cumplimiento14d: $checkedConvert(
        'cumplimiento_14d',
        (v) => (v as num).toDouble(),
      ),
      estado: $checkedConvert(
        'estado',
        (v) => $enumDecode(_$EstadoSugerenciaEnumMap, v),
      ),
      creadaEn: $checkedConvert(
        'creada_en',
        (v) => const InstanteConverter().fromJson(v as String),
      ),
      resueltaEn: $checkedConvert(
        'resuelta_en',
        (v) => const InstanteNuloConverter().fromJson(v as String?),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'habitoId': 'habito_id',
    'habitoNombre': 'habito_nombre',
    'metaActual': 'meta_actual',
    'metaPropuesta': 'meta_propuesta',
    'cumplimiento14d': 'cumplimiento_14d',
    'creadaEn': 'creada_en',
    'resueltaEn': 'resuelta_en',
  },
);

Map<String, dynamic> _$SugerenciaToJson(Sugerencia instance) =>
    <String, dynamic>{
      'id': instance.id,
      'habito_id': instance.habitoId,
      'habito_nombre': instance.habitoNombre,
      'tipo': _$TipoSugerenciaEnumMap[instance.tipo]!,
      'meta_actual': instance.metaActual,
      'meta_propuesta': instance.metaPropuesta,
      'cumplimiento_14d': instance.cumplimiento14d,
      'estado': _$EstadoSugerenciaEnumMap[instance.estado]!,
      'creada_en': const InstanteConverter().toJson(instance.creadaEn),
      'resuelta_en': const InstanteNuloConverter().toJson(instance.resueltaEn),
    };

const _$TipoSugerenciaEnumMap = {
  TipoSugerencia.subir: 'subir',
  TipoSugerencia.bajar: 'bajar',
};

const _$EstadoSugerenciaEnumMap = {
  EstadoSugerencia.pendiente: 'pendiente',
  EstadoSugerencia.aceptada: 'aceptada',
  EstadoSugerencia.rechazada: 'rechazada',
  EstadoSugerencia.expirada: 'expirada',
};

RespuestaSugerencia _$RespuestaSugerenciaFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RespuestaSugerencia', json, ($checkedConvert) {
      final val = RespuestaSugerencia(
        estado: $checkedConvert(
          'estado',
          (v) => $enumDecode(_$EstadoSugerenciaEnumMap, v),
        ),
        nivel: $checkedConvert('nivel', (v) => (v as num?)?.toInt()),
        metaNueva: $checkedConvert(
          'meta_nueva',
          (v) => (v as num?)?.toDouble(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'metaNueva': 'meta_nueva'});

Map<String, dynamic> _$RespuestaSugerenciaToJson(
  RespuestaSugerencia instance,
) => <String, dynamic>{
  'estado': _$EstadoSugerenciaEnumMap[instance.estado]!,
  'nivel': instance.nivel,
  'meta_nueva': instance.metaNueva,
};

Nivel _$NivelFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Nivel', json, ($checkedConvert) {
      final val = Nivel(
        nivel: $checkedConvert('nivel', (v) => (v as num).toInt()),
        meta: $checkedConvert('meta', (v) => (v as num).toDouble()),
        desde: $checkedConvert(
          'desde',
          (v) => const FechaConverter().fromJson(v as String),
        ),
        hasta: $checkedConvert(
          'hasta',
          (v) => const FechaNulaConverter().fromJson(v as String?),
        ),
      );
      return val;
    });

Map<String, dynamic> _$NivelToJson(Nivel instance) => <String, dynamic>{
  'nivel': instance.nivel,
  'meta': instance.meta,
  'desde': const FechaConverter().toJson(instance.desde),
  'hasta': const FechaNulaConverter().toJson(instance.hasta),
};

SugerenciaPendiente _$SugerenciaPendienteFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SugerenciaPendiente',
      json,
      ($checkedConvert) {
        final val = SugerenciaPendiente(
          id: $checkedConvert('id', (v) => v as String),
          tipo: $checkedConvert(
            'tipo',
            (v) => $enumDecode(_$TipoSugerenciaEnumMap, v),
          ),
          metaPropuesta: $checkedConvert(
            'meta_propuesta',
            (v) => (v as num).toDouble(),
          ),
          cumplimiento14d: $checkedConvert(
            'cumplimiento_14d',
            (v) => (v as num).toDouble(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'metaPropuesta': 'meta_propuesta',
        'cumplimiento14d': 'cumplimiento_14d',
      },
    );

Map<String, dynamic> _$SugerenciaPendienteToJson(
  SugerenciaPendiente instance,
) => <String, dynamic>{
  'id': instance.id,
  'tipo': _$TipoSugerenciaEnumMap[instance.tipo]!,
  'meta_propuesta': instance.metaPropuesta,
  'cumplimiento_14d': instance.cumplimiento14d,
};

CambioEscalera _$CambioEscaleraFromJson(Map<String, dynamic> json) =>
    $checkedCreate('CambioEscalera', json, ($checkedConvert) {
      final val = CambioEscalera(
        fecha: $checkedConvert(
          'fecha',
          (v) => const FechaConverter().fromJson(v as String),
        ),
        tipo: $checkedConvert(
          'tipo',
          (v) => $enumDecode(_$TipoSugerenciaEnumMap, v),
        ),
        de: $checkedConvert('de', (v) => (v as num).toDouble()),
        a: $checkedConvert('a', (v) => (v as num).toDouble()),
        estado: $checkedConvert(
          'estado',
          (v) => $enumDecode(_$EstadoSugerenciaEnumMap, v),
        ),
      );
      return val;
    });

Map<String, dynamic> _$CambioEscaleraToJson(CambioEscalera instance) =>
    <String, dynamic>{
      'fecha': const FechaConverter().toJson(instance.fecha),
      'tipo': _$TipoSugerenciaEnumMap[instance.tipo]!,
      'de': instance.de,
      'a': instance.a,
      'estado': _$EstadoSugerenciaEnumMap[instance.estado]!,
    };

EscaleraHabito _$EscaleraHabitoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'EscaleraHabito',
  json,
  ($checkedConvert) {
    final val = EscaleraHabito(
      habitoId: $checkedConvert('habito_id', (v) => v as String),
      escaleraActiva: $checkedConvert('escalera_activa', (v) => v as bool),
      nivelActual: $checkedConvert('nivel_actual', (v) => (v as num).toInt()),
      metaActual: $checkedConvert('meta_actual', (v) => (v as num).toDouble()),
      unidad: $checkedConvert('unidad', (v) => v as String),
      niveles: $checkedConvert(
        'niveles',
        (v) => (v as List<dynamic>)
            .map((e) => Nivel.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      historial: $checkedConvert(
        'historial',
        (v) => (v as List<dynamic>)
            .map((e) => CambioEscalera.fromJson(e as Map<String, dynamic>))
            .toList(),
      ),
      sugerenciaPendiente: $checkedConvert(
        'sugerencia_pendiente',
        (v) => v == null
            ? null
            : SugerenciaPendiente.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'habitoId': 'habito_id',
    'escaleraActiva': 'escalera_activa',
    'nivelActual': 'nivel_actual',
    'metaActual': 'meta_actual',
    'sugerenciaPendiente': 'sugerencia_pendiente',
  },
);

Map<String, dynamic> _$EscaleraHabitoToJson(EscaleraHabito instance) =>
    <String, dynamic>{
      'habito_id': instance.habitoId,
      'escalera_activa': instance.escaleraActiva,
      'nivel_actual': instance.nivelActual,
      'meta_actual': instance.metaActual,
      'unidad': instance.unidad,
      'niveles': instance.niveles.map((e) => e.toJson()).toList(),
      'sugerencia_pendiente': instance.sugerenciaPendiente?.toJson(),
      'historial': instance.historial.map((e) => e.toJson()).toList(),
    };
