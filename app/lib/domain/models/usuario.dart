import 'package:json_annotation/json_annotation.dart';

import 'conversores.dart';

part 'usuario.g.dart';

/// Rol del usuario, igual que la columna `rol` de la tabla `usuario`.
@JsonEnum()
enum RolUsuario { usuario, admin }

/// Usuario que viene dentro de la respuesta de tokens (login, registro y renovar).
@JsonSerializable()
class UsuarioToken {
  const UsuarioToken({required this.id, required this.nombre, required this.rol, required this.region});

  factory UsuarioToken.fromJson(Map<String, dynamic> json) => _$UsuarioTokenFromJson(json);

  final String id;
  final String nombre;
  final RolUsuario rol;

  /// `MX-NORTE`, `MX-CENTRO-SUR` o `LATAM`.
  final String region;

  Map<String, dynamic> toJson() => _$UsuarioTokenToJson(this);
}

/// `GET /cuenta`.
@JsonSerializable()
class Cuenta {
  const Cuenta({
    required this.id,
    required this.nombre,
    required this.email,
    required this.pais,
    required this.region,
    required this.rol,
    required this.fechaRegistro,
    required this.consentimientoSenales,
    this.consentimientoSenalesEn,
  });

  factory Cuenta.fromJson(Map<String, dynamic> json) => _$CuentaFromJson(json);

  final String id;
  final String nombre;
  final String email;
  final String pais;
  final String region;
  final RolUsuario rol;
  @InstanteConverter()
  final DateTime fechaRegistro;
  final bool consentimientoSenales;
  @InstanteNuloConverter()
  final DateTime? consentimientoSenalesEn;

  Map<String, dynamic> toJson() => _$CuentaToJson(this);
}

/// Respuesta de `PUT /cuenta/consentimientos`.
@JsonSerializable()
class ResultadoConsentimiento {
  const ResultadoConsentimiento({required this.senales, required this.senalesBorradas});

  factory ResultadoConsentimiento.fromJson(Map<String, dynamic> json) => _$ResultadoConsentimientoFromJson(json);

  final bool senales;
  final int senalesBorradas;

  Map<String, dynamic> toJson() => _$ResultadoConsentimientoToJson(this);
}
