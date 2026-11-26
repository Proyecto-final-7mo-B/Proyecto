import 'package:json_annotation/json_annotation.dart';

import 'usuario.dart';

part 'sesion.g.dart';

/// Respuesta de `POST /auth/login`, `/auth/registro` y `/auth/renovar`.
///
/// El token de acceso vive solo en memoria; el de renovación, en el almacén seguro (en web, solo en memoria).
@JsonSerializable()
class Tokens {
  const Tokens({
    required this.tokenAcceso,
    required this.tokenRenovacion,
    required this.tipo,
    required this.expiraEn,
    required this.usuario,
  });

  factory Tokens.fromJson(Map<String, dynamic> json) => _$TokensFromJson(json);

  final String tokenAcceso;
  final String tokenRenovacion;

  /// Siempre `Bearer`.
  final String tipo;

  /// Segundos de vida del token de acceso (900 = 15 min).
  final int expiraEn;
  final UsuarioToken usuario;

  Map<String, dynamic> toJson() => _$TokensToJson(this);

  /// Sin los tokens, para mostrarlo en bitácoras de depuración sin filtrar secretos.
  @override
  String toString() => 'Tokens(usuario: ${usuario.id}, expiraEn: $expiraEn)';
}

/// Cuerpo de `POST /auth/registro`.
@JsonSerializable()
class SolicitudRegistro {
  const SolicitudRegistro({
    required this.nombre,
    required this.email,
    required this.contrasena,
    required this.pais,
    required this.estado,
    required this.aceptaAviso,
    required this.consienteSenales,
  });

  factory SolicitudRegistro.fromJson(Map<String, dynamic> json) => _$SolicitudRegistroFromJson(json);

  final String nombre;
  final String email;
  final String contrasena;
  final String pais;

  /// Código ISO 3166-2 del estado si `pais = MX`; `null` en otro caso.
  final String? estado;
  final bool aceptaAviso;
  final bool consienteSenales;

  Map<String, dynamic> toJson() => _$SolicitudRegistroToJson(this);

  @override
  String toString() => 'SolicitudRegistro(email: $email, pais: $pais, estado: $estado)';
}
