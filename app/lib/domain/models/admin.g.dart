// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UsuarioAdmin _$UsuarioAdminFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'UsuarioAdmin',
  json,
  ($checkedConvert) {
    final val = UsuarioAdmin(
      id: $checkedConvert('id', (v) => v as String),
      region: $checkedConvert('region', (v) => v as String),
      pais: $checkedConvert('pais', (v) => v as String),
      rol: $checkedConvert('rol', (v) => $enumDecode(_$RolUsuarioEnumMap, v)),
      fechaRegistro: $checkedConvert(
        'fecha_registro',
        (v) => const InstanteConverter().fromJson(v as String),
      ),
      nombreMascara: $checkedConvert('nombre_mascara', (v) => v as String),
      emailMascara: $checkedConvert('email_mascara', (v) => v as String),
      bloqueado: $checkedConvert('bloqueado', (v) => v as bool),
      consienteSenales: $checkedConvert('consiente_senales', (v) => v as bool),
      suspendido: $checkedConvert('suspendido', (v) => v as bool),
      suspendidoEn: $checkedConvert(
        'suspendido_en',
        (v) => const InstanteNuloConverter().fromJson(v as String?),
      ),
      suspensionMotivo: $checkedConvert(
        'suspension_motivo',
        (v) => v as String?,
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'fechaRegistro': 'fecha_registro',
    'nombreMascara': 'nombre_mascara',
    'emailMascara': 'email_mascara',
    'consienteSenales': 'consiente_senales',
    'suspendidoEn': 'suspendido_en',
    'suspensionMotivo': 'suspension_motivo',
  },
);

Map<String, dynamic> _$UsuarioAdminToJson(
  UsuarioAdmin instance,
) => <String, dynamic>{
  'id': instance.id,
  'region': instance.region,
  'pais': instance.pais,
  'rol': _$RolUsuarioEnumMap[instance.rol]!,
  'fecha_registro': const InstanteConverter().toJson(instance.fechaRegistro),
  'nombre_mascara': instance.nombreMascara,
  'email_mascara': instance.emailMascara,
  'bloqueado': instance.bloqueado,
  'consiente_senales': instance.consienteSenales,
  'suspendido': instance.suspendido,
  'suspendido_en': const InstanteNuloConverter().toJson(instance.suspendidoEn),
  'suspension_motivo': instance.suspensionMotivo,
};

const _$RolUsuarioEnumMap = {
  RolUsuario.usuario: 'usuario',
  RolUsuario.admin: 'admin',
};

ResumenMetricas _$ResumenMetricasFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'ResumenMetricas',
      json,
      ($checkedConvert) {
        final val = ResumenMetricas(
          usuariosActivos: $checkedConvert(
            'usuarios_activos',
            (v) => (v as num).toInt(),
          ),
          cumplimientoGlobal: $checkedConvert(
            'cumplimiento_global',
            (v) => (v as num).toDouble(),
          ),
          categoriasActivas: $checkedConvert(
            'categorias_activas',
            (v) => (v as num).toInt(),
          ),
          variacion: $checkedConvert(
            'variacion',
            (v) => (v as num?)?.toDouble(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'usuariosActivos': 'usuarios_activos',
        'cumplimientoGlobal': 'cumplimiento_global',
        'categoriasActivas': 'categorias_activas',
      },
    );

Map<String, dynamic> _$ResumenMetricasToJson(ResumenMetricas instance) =>
    <String, dynamic>{
      'usuarios_activos': instance.usuariosActivos,
      'variacion': instance.variacion,
      'cumplimiento_global': instance.cumplimientoGlobal,
      'categorias_activas': instance.categoriasActivas,
    };

MetricaRegion _$MetricaRegionFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MetricaRegion', json, ($checkedConvert) {
      final val = MetricaRegion(
        region: $checkedConvert('region', (v) => v as String),
        categoria: $checkedConvert('categoria', (v) => v as String),
        usuarios: $checkedConvert('usuarios', (v) => (v as num).toInt()),
        habitos: $checkedConvert('habitos', (v) => (v as num).toInt()),
        rachaPromedio: $checkedConvert(
          'racha_promedio',
          (v) => (v as num).toDouble(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'rachaPromedio': 'racha_promedio'});

Map<String, dynamic> _$MetricaRegionToJson(MetricaRegion instance) =>
    <String, dynamic>{
      'region': instance.region,
      'categoria': instance.categoria,
      'usuarios': instance.usuarios,
      'habitos': instance.habitos,
      'racha_promedio': instance.rachaPromedio,
    };

MetricasAdmin _$MetricasAdminFromJson(Map<String, dynamic> json) =>
    $checkedCreate('MetricasAdmin', json, ($checkedConvert) {
      final val = MetricasAdmin(
        resumen: $checkedConvert(
          'resumen',
          (v) => ResumenMetricas.fromJson(v as Map<String, dynamic>),
        ),
        porRegion: $checkedConvert(
          'por_region',
          (v) => (v as List<dynamic>)
              .map((e) => MetricaRegion.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    }, fieldKeyMap: const {'porRegion': 'por_region'});

Map<String, dynamic> _$MetricasAdminToJson(MetricasAdmin instance) =>
    <String, dynamic>{
      'resumen': instance.resumen.toJson(),
      'por_region': instance.porRegion.map((e) => e.toJson()).toList(),
    };

PeriodoIndicador _$PeriodoIndicadorFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PeriodoIndicador', json, ($checkedConvert) {
      final val = PeriodoIndicador(
        desde: $checkedConvert(
          'desde',
          (v) => const FechaConverter().fromJson(v as String),
        ),
        hasta: $checkedConvert(
          'hasta',
          (v) => const FechaConverter().fromJson(v as String),
        ),
      );
      return val;
    });

Map<String, dynamic> _$PeriodoIndicadorToJson(PeriodoIndicador instance) =>
    <String, dynamic>{
      'desde': const FechaConverter().toJson(instance.desde),
      'hasta': const FechaConverter().toJson(instance.hasta),
    };

Indicador _$IndicadorFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Indicador',
  json,
  ($checkedConvert) {
    final val = Indicador(
      codigo: $checkedConvert('codigo', (v) => v as String),
      titulo: $checkedConvert('titulo', (v) => v as String),
      grafica: $checkedConvert('grafica', (v) => v as String),
      origen: $checkedConvert('origen', (v) => v as String),
      datosSinteticos: $checkedConvert('datos_sinteticos', (v) => v as bool),
      periodo: $checkedConvert(
        'periodo',
        (v) => PeriodoIndicador.fromJson(v as Map<String, dynamic>),
      ),
      series: $checkedConvert(
        'series',
        (v) =>
            (v as List<dynamic>).map((e) => e as Map<String, dynamic>).toList(),
      ),
      generadoEn: $checkedConvert(
        'generado_en',
        (v) => const InstanteConverter().fromJson(v as String),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'datosSinteticos': 'datos_sinteticos',
    'generadoEn': 'generado_en',
  },
);

Map<String, dynamic> _$IndicadorToJson(Indicador instance) => <String, dynamic>{
  'codigo': instance.codigo,
  'titulo': instance.titulo,
  'grafica': instance.grafica,
  'origen': instance.origen,
  'datos_sinteticos': instance.datosSinteticos,
  'periodo': instance.periodo.toJson(),
  'series': instance.series,
  'generado_en': const InstanteConverter().toJson(instance.generadoEn),
};
