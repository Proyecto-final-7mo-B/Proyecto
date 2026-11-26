// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usuario.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UsuarioToken _$UsuarioTokenFromJson(Map<String, dynamic> json) =>
    $checkedCreate('UsuarioToken', json, ($checkedConvert) {
      final val = UsuarioToken(
        id: $checkedConvert('id', (v) => v as String),
        nombre: $checkedConvert('nombre', (v) => v as String),
        rol: $checkedConvert('rol', (v) => $enumDecode(_$RolUsuarioEnumMap, v)),
        region: $checkedConvert('region', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$UsuarioTokenToJson(UsuarioToken instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'rol': _$RolUsuarioEnumMap[instance.rol]!,
      'region': instance.region,
    };

const _$RolUsuarioEnumMap = {
  RolUsuario.usuario: 'usuario',
  RolUsuario.admin: 'admin',
};

Cuenta _$CuentaFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Cuenta',
  json,
  ($checkedConvert) {
    final val = Cuenta(
      id: $checkedConvert('id', (v) => v as String),
      nombre: $checkedConvert('nombre', (v) => v as String),
      email: $checkedConvert('email', (v) => v as String),
      pais: $checkedConvert('pais', (v) => v as String),
      region: $checkedConvert('region', (v) => v as String),
      rol: $checkedConvert('rol', (v) => $enumDecode(_$RolUsuarioEnumMap, v)),
      fechaRegistro: $checkedConvert(
        'fecha_registro',
        (v) => const InstanteConverter().fromJson(v as String),
      ),
      consentimientoSenales: $checkedConvert(
        'consentimiento_senales',
        (v) => v as bool,
      ),
      consentimientoSenalesEn: $checkedConvert(
        'consentimiento_senales_en',
        (v) => const InstanteNuloConverter().fromJson(v as String?),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'fechaRegistro': 'fecha_registro',
    'consentimientoSenales': 'consentimiento_senales',
    'consentimientoSenalesEn': 'consentimiento_senales_en',
  },
);

Map<String, dynamic> _$CuentaToJson(Cuenta instance) => <String, dynamic>{
  'id': instance.id,
  'nombre': instance.nombre,
  'email': instance.email,
  'pais': instance.pais,
  'region': instance.region,
  'rol': _$RolUsuarioEnumMap[instance.rol]!,
  'fecha_registro': const InstanteConverter().toJson(instance.fechaRegistro),
  'consentimiento_senales': instance.consentimientoSenales,
  'consentimiento_senales_en': const InstanteNuloConverter().toJson(
    instance.consentimientoSenalesEn,
  ),
};

ResultadoConsentimiento _$ResultadoConsentimientoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('ResultadoConsentimiento', json, ($checkedConvert) {
  final val = ResultadoConsentimiento(
    senales: $checkedConvert('senales', (v) => v as bool),
    senalesBorradas: $checkedConvert(
      'senales_borradas',
      (v) => (v as num).toInt(),
    ),
  );
  return val;
}, fieldKeyMap: const {'senalesBorradas': 'senales_borradas'});

Map<String, dynamic> _$ResultadoConsentimientoToJson(
  ResultadoConsentimiento instance,
) => <String, dynamic>{
  'senales': instance.senales,
  'senales_borradas': instance.senalesBorradas,
};
