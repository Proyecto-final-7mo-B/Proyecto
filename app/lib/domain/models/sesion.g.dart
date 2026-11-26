// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sesion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Tokens _$TokensFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Tokens',
  json,
  ($checkedConvert) {
    final val = Tokens(
      tokenAcceso: $checkedConvert('token_acceso', (v) => v as String),
      tokenRenovacion: $checkedConvert('token_renovacion', (v) => v as String),
      tipo: $checkedConvert('tipo', (v) => v as String),
      expiraEn: $checkedConvert('expira_en', (v) => (v as num).toInt()),
      usuario: $checkedConvert(
        'usuario',
        (v) => UsuarioToken.fromJson(v as Map<String, dynamic>),
      ),
    );
    return val;
  },
  fieldKeyMap: const {
    'tokenAcceso': 'token_acceso',
    'tokenRenovacion': 'token_renovacion',
    'expiraEn': 'expira_en',
  },
);

Map<String, dynamic> _$TokensToJson(Tokens instance) => <String, dynamic>{
  'token_acceso': instance.tokenAcceso,
  'token_renovacion': instance.tokenRenovacion,
  'tipo': instance.tipo,
  'expira_en': instance.expiraEn,
  'usuario': instance.usuario.toJson(),
};

SolicitudRegistro _$SolicitudRegistroFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'SolicitudRegistro',
      json,
      ($checkedConvert) {
        final val = SolicitudRegistro(
          nombre: $checkedConvert('nombre', (v) => v as String),
          email: $checkedConvert('email', (v) => v as String),
          contrasena: $checkedConvert('contrasena', (v) => v as String),
          pais: $checkedConvert('pais', (v) => v as String),
          estado: $checkedConvert('estado', (v) => v as String?),
          aceptaAviso: $checkedConvert('acepta_aviso', (v) => v as bool),
          consienteSenales: $checkedConvert(
            'consiente_senales',
            (v) => v as bool,
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'aceptaAviso': 'acepta_aviso',
        'consienteSenales': 'consiente_senales',
      },
    );

Map<String, dynamic> _$SolicitudRegistroToJson(SolicitudRegistro instance) =>
    <String, dynamic>{
      'nombre': instance.nombre,
      'email': instance.email,
      'contrasena': instance.contrasena,
      'pais': instance.pais,
      'estado': instance.estado,
      'acepta_aviso': instance.aceptaAviso,
      'consiente_senales': instance.consienteSenales,
    };
