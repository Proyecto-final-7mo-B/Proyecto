import 'package:flutter/foundation.dart';

import '../../../domain/models/sesion.dart';
import '../../../domain/models/usuario.dart';
import '../../../utils/result.dart';
import '../../../utils/validadores.dart';
import '../../fake/datos_demo.dart';
import '../../services/api/errores_api.dart';
import 'auth_repository.dart';

class AuthRepositoryFake implements AuthRepository {
  AuthRepositoryFake(this._datos);

  final DatosDemo _datos;

  static const int intentosAntesDeBloquear = 10;
  static const Duration bloqueo = Duration(minutes: 15);

  Tokens _tokens(UsuarioDemo u) {
    final (acceso, renovacion) = _datos.emitirTokens(u.id);
    return Tokens(tokenAcceso: acceso, tokenRenovacion: renovacion, tipo: 'Bearer', expiraEn: 900, usuario: u.aToken());
  }

  @override
  Future<Result<Tokens>> entrar({required String email, required String contrasena}) => _datos.ejecutar(() {
    final u = _datos.usuarioPorCorreo(email);
    final bloqueadoHasta = u?.bloqueadoHasta;
    if (u != null && bloqueadoHasta != null && bloqueadoHasta.isAfter(_datos.ahora)) {
      throw DatosDemo.error(
        TipoError.cuentaBloqueada,
        429,
        'Cuenta bloqueada temporalmente',
        reintentarEn: bloqueadoHasta.difference(_datos.ahora),
      );
    }
    if (u == null || u.contrasena != contrasena) {
      if (u != null && ++u.intentosFallidos >= intentosAntesDeBloquear) {
        u
          ..bloqueadoHasta = _datos.ahora.add(bloqueo)
          ..intentosFallidos = 0;
      }
      // El mismo error exista o no la cuenta.
      throw DatosDemo.error(TipoError.credencialesInvalidas, 401, 'Correo o contraseña incorrectos');
    }
    if (u.suspendido) {
      throw DatosDemo.error(TipoError.cuentaSuspendida, 403, 'Cuenta suspendida');
    }
    u
      ..intentosFallidos = 0
      ..bloqueadoHasta = null;
    return _tokens(u);
  });

  @override
  Future<Result<Tokens>> registrar(SolicitudRegistro s) => _datos.ejecutar(() {
    final campos = <String, String>{};
    if (Validadores.nombreUsuario(s.nombre) != null) campos['nombre'] = '1 a 80 caracteres';
    if (Validadores.correo(s.email) != null) campos['email'] = 'Correo no válido';
    final errorContrasena = Validadores.contrasena(s.contrasena, correo: s.email);
    if (errorContrasena != null) campos['contrasena'] = 'De 12 a 128 caracteres y distinta del correo';
    if (!s.aceptaAviso) campos['acepta_aviso'] = 'Debes aceptar el aviso de privacidad';
    if (campos.isNotEmpty) {
      throw DatosDemo.validacion(campos);
    }
    final catalogo = _datos.catalogo;
    final region = catalogo != null
        ? catalogo.regionDe(s.pais, s.estado)
        : (s.pais == 'MX' ? (s.estado == null ? null : 'MX-NORTE') : (s.estado == null ? 'LATAM' : null));
    if (region == null) {
      throw DatosDemo.error(TipoError.regionInvalida, 422, 'País o estado fuera del servicio');
    }
    if (_datos.usuarioPorCorreo(s.email) != null) {
      // Texto genérico a propósito: no revela que el correo ya existe.
      throw DatosDemo.error(TipoError.registroRechazado, 409, 'No fue posible completar el registro');
    }
    final u = UsuarioDemo(
      id: _datos.nuevoId(),
      email: Validadores.normalizarCorreo(s.email),
      nombre: s.nombre.trim(),
      contrasena: s.contrasena,
      pais: s.pais,
      region: region,
      rol: RolUsuario.usuario,
      fechaRegistro: _datos.ahora,
      consentimientoSenales: s.consienteSenales,
      consentimientoSenalesEn: s.consienteSenales ? _datos.ahora : null,
    );
    _datos.usuarios[u.id] = u;
    return _tokens(u);
  });

  @override
  Future<Result<Tokens>> renovar(String tokenRenovacion) => _datos.ejecutar(() {
    final rotado = _datos.renovacionesRotadas[tokenRenovacion];
    if (rotado != null) {
      // Alguien presentó un token ya usado: se revoca toda la familia.
      _datos.revocarSesiones(rotado);
      throw DatosDemo.error(TipoError.tokenReutilizado, 401, 'Token reutilizado');
    }
    final id = _datos.renovacionesVigentes.remove(tokenRenovacion);
    final u = id == null ? null : _datos.usuarios[id];
    if (u == null) {
      throw DatosDemo.error(TipoError.tokenInvalido, 401, 'Token inválido');
    }
    _datos.renovacionesRotadas[tokenRenovacion] = u.id;
    if (u.suspendido) {
      throw DatosDemo.error(TipoError.cuentaSuspendida, 403, 'Cuenta suspendida');
    }
    return _tokens(u);
  });

  @override
  Future<Result<void>> salir(String tokenRenovacion) => _datos.ejecutar(() {
    _datos.renovacionesVigentes.remove(tokenRenovacion);
    _datos.usuarioActual = null;
  });

  @override
  Future<Result<void>> recuperar(String email) => _datos.ejecutar(() {
    final u = _datos.usuarioPorCorreo(email);
    if (u == null) {
      return; // misma respuesta exista o no
    }
    final token = 'demo-${_datos.nuevoId()}';
    _datos.recuperaciones[token] = (u.id, _datos.ahora.add(const Duration(minutes: 15)));
    _datos.ultimoTokenRecuperacion = token;
    debugPrint('[Kaizen · fake] Enlace para restablecer la contraseña: /restablecer?token=$token');
  });

  @override
  Future<Result<void>> restablecer({required String token, required String nueva}) => _datos.ejecutar(() {
    final datos = _datos.recuperaciones[token];
    if (datos == null || datos.$2.isBefore(_datos.ahora)) {
      throw DatosDemo.error(TipoError.enlaceInvalido, 400, 'El enlace no es válido o ya venció');
    }
    final u = _datos.usuarios[datos.$1]!;
    if (Validadores.contrasena(nueva, correo: u.email) != null) {
      throw DatosDemo.validacion({'nueva': 'De 12 a 128 caracteres y distinta del correo'});
    }
    _datos.recuperaciones.remove(token); // un solo uso
    u
      ..contrasena = nueva
      ..intentosFallidos = 0
      ..bloqueadoHasta = null;
    _datos.revocarSesiones(u.id);
  });
}
