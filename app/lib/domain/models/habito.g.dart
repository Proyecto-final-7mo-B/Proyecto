// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habito.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Racha _$RachaFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Racha',
  json,
  ($checkedConvert) {
    final val = Racha(
      actual: $checkedConvert('actual', (v) => (v as num).toInt()),
      maxima: $checkedConvert('maxima', (v) => (v as num).toInt()),
      ultimaFecha: $checkedConvert(
        'ultima_fecha',
        (v) => const FechaNulaConverter().fromJson(v as String?),
      ),
      protegidaEstaSemana: $checkedConvert(
        'protegida_esta_semana',
        (v) => v as bool? ?? false,
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'ultimaFecha': 'ultima_fecha',
    'protegidaEstaSemana': 'protegida_esta_semana',
  },
);

Map<String, dynamic> _$RachaToJson(Racha instance) => <String, dynamic>{
  'actual': instance.actual,
  'maxima': instance.maxima,
  'ultima_fecha': const FechaNulaConverter().toJson(instance.ultimaFecha),
  'protegida_esta_semana': instance.protegidaEstaSemana,
};

RegistroDeHoy _$RegistroDeHoyFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RegistroDeHoy', json, ($checkedConvert) {
      final val = RegistroDeHoy(
        id: $checkedConvert('id', (v) => v as String),
        cumplido: $checkedConvert('cumplido', (v) => v as bool),
        valor: $checkedConvert('valor', (v) => (v as num?)?.toDouble()),
      );
      return val;
    });

Map<String, dynamic> _$RegistroDeHoyToJson(RegistroDeHoy instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cumplido': instance.cumplido,
      'valor': instance.valor,
    };

HoyHabito _$HoyHabitoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('HoyHabito', json, ($checkedConvert) {
      final val = HoyHabito(
        fecha: $checkedConvert(
          'fecha',
          (v) => const FechaConverter().fromJson(v as String),
        ),
        programado: $checkedConvert('programado', (v) => v as bool),
        registro: $checkedConvert(
          'registro',
          (v) => v == null
              ? null
              : RegistroDeHoy.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$HoyHabitoToJson(HoyHabito instance) => <String, dynamic>{
  'fecha': const FechaConverter().toJson(instance.fecha),
  'programado': instance.programado,
  'registro': instance.registro?.toJson(),
};

Habito _$HabitoFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Habito',
  json,
  ($checkedConvert) {
    final val = Habito(
      id: $checkedConvert('id', (v) => v as String),
      nombre: $checkedConvert('nombre', (v) => v as String),
      unidad: $checkedConvert('unidad', (v) => v as String),
      meta: $checkedConvert('meta', (v) => (v as num).toDouble()),
      nivel: $checkedConvert('nivel', (v) => (v as num).toInt()),
      categoria: $checkedConvert(
        'categoria',
        (v) => Categoria.fromJson(v as Map<String, dynamic>),
      ),
      subcategoria: $checkedConvert(
        'subcategoria',
        (v) => Subcategoria.fromJson(v as Map<String, dynamic>),
      ),
      frecuencia: $checkedConvert(
        'frecuencia',
        (v) => Frecuencia.fromJson(v as Map<String, dynamic>),
      ),
      escaleraActiva: $checkedConvert('escalera_activa', (v) => v as bool),
      activo: $checkedConvert('activo', (v) => v as bool),
      fechaCreacion: $checkedConvert(
        'fecha_creacion',
        (v) => const InstanteConverter().fromJson(v as String),
      ),
      racha: $checkedConvert(
        'racha',
        (v) => Racha.fromJson(v as Map<String, dynamic>),
      ),
      prioridad: $checkedConvert('prioridad', (v) => (v as num?)?.toInt() ?? 2),
      intencion: $checkedConvert('intencion', (v) => v as String?),
      evaluacion: $checkedConvert(
        'evaluacion',
        (v) =>
            v == null ? null : Evaluacion.fromJson(v as Map<String, dynamic>),
      ),
      hoy: $checkedConvert(
        'hoy',
        (v) => v == null ? null : HoyHabito.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'escaleraActiva': 'escalera_activa',
    'fechaCreacion': 'fecha_creacion',
  },
);

Map<String, dynamic> _$HabitoToJson(Habito instance) => <String, dynamic>{
  'id': instance.id,
  'nombre': instance.nombre,
  'unidad': instance.unidad,
  'meta': instance.meta,
  'nivel': instance.nivel,
  'categoria': instance.categoria.toJson(),
  'subcategoria': instance.subcategoria.toJson(),
  'prioridad': instance.prioridad,
  'intencion': instance.intencion,
  'evaluacion': instance.evaluacion?.toJson(),
  'frecuencia': instance.frecuencia.toJson(),
  'escalera_activa': instance.escaleraActiva,
  'activo': instance.activo,
  'fecha_creacion': const InstanteConverter().toJson(instance.fechaCreacion),
  'racha': instance.racha.toJson(),
  'hoy': instance.hoy?.toJson(),
};

NuevoHabito _$NuevoHabitoFromJson(Map<String, dynamic> json) => $checkedCreate(
  'NuevoHabito',
  json,
  ($checkedConvert) {
    final val = NuevoHabito(
      nombre: $checkedConvert('nombre', (v) => v as String),
      subcategoriaId: $checkedConvert('subcategoria_id', (v) => v as String),
      frecuencia: $checkedConvert(
        'frecuencia',
        (v) => Frecuencia.fromJson(v as Map<String, dynamic>),
      ),
      meta: $checkedConvert('meta', (v) => (v as num).toDouble()),
      unidad: $checkedConvert('unidad', (v) => v as String),
      escaleraActiva: $checkedConvert(
        'escalera_activa',
        (v) => v as bool? ?? true,
      ),
      prioridad: $checkedConvert(
        'prioridad',
        (v) => (v as num?)?.toInt() ?? Prioridad.media,
      ),
      intencion: $checkedConvert('intencion', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {
    'subcategoriaId': 'subcategoria_id',
    'escaleraActiva': 'escalera_activa',
  },
);

Map<String, dynamic> _$NuevoHabitoToJson(NuevoHabito instance) =>
    <String, dynamic>{
      'nombre': instance.nombre,
      'subcategoria_id': instance.subcategoriaId,
      'frecuencia': instance.frecuencia.toJson(),
      'meta': instance.meta,
      'unidad': instance.unidad,
      'escalera_activa': instance.escaleraActiva,
      'prioridad': instance.prioridad,
      'intencion': instance.intencion,
    };
