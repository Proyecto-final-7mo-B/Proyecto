import 'dart:async';

import '../../domain/models/sesion.dart';
import '../../domain/models/usuario.dart';
import '../../routing/estado_sesion.dart';
import '../../utils/result.dart';
import '../repositories/auth/auth_repository.dart';
import 'gestor_tokens.dart';

/// Une el repositorio de autenticación, los tokens y el [EstadoSesion] que escucha el router:
///
/// - **entrar / registrar**: guarda los tokens y abre la sesión (el router lleva a `/hoy` o a donde iba).
/// - **salir**: avisa al servidor (si falla, igual borra los tokens) y cierra la sesión.
/// - **restaurar**: al abrir la app, si hay un token de renovación guardado, pide tokens nuevos. Sin red, abre la
///   sesión con el usuario guardado (la app funciona sin conexión); si el servidor rechaza el token, no la abre.
/// - Si una renovación falla por sesión inválida (p. ej., cuenta suspendida), cierra la sesión sola.
class ServicioSesion {
  ServicioSesion({required this.auth, required this.tokens, required this.estado}) {
    _expirada = tokens.sesionExpirada.listen((_) => estado.cerrar());
  }

  final AuthRepository auth;
  final GestorTokens tokens;
  final EstadoSesion estado;
  late final StreamSubscription<void> _expirada;

  /// Tiempo máximo para restaurar la sesión al abrir la app; después se abre con el usuario guardado.
  static const Duration limiteRestaurar = Duration(seconds: 4);

  Future<Result<UsuarioToken>> entrar({required String email, required String contrasena}) async =>
      _abrir(await auth.entrar(email: email, contrasena: contrasena));

  Future<Result<UsuarioToken>> registrar(SolicitudRegistro solicitud) async => _abrir(await auth.registrar(solicitud));

  Future<Result<UsuarioToken>> _abrir(Result<Tokens> resultado) async {
    switch (resultado) {
      case Exito(:final valor):
        await tokens.guardar(valor);
        estado.iniciar(UsuarioSesion.desdeToken(valor.usuario));
        return Result.exito(valor.usuario);
      case Fallo(:final error):
        return Result.fallo(error);
    }
  }

  /// Cierra la sesión. Los tokens se borran aunque el servidor no responda.
  Future<void> salir() async {
    final renovacion = await tokens.tokenRenovacion();
    if (renovacion != null) {
      await auth.salir(renovacion);
    }
    await tokens.borrar();
    estado.cerrar();
  }

  /// Al abrir la app. `true` si quedó una sesión abierta.
  Future<bool> restaurar() async {
    final guardado = await tokens.usuarioGuardado();
    if (guardado == null || await tokens.tokenRenovacion() == null) {
      return false;
    }
    final renovada = await tokens.renovar().timeout(limiteRestaurar, onTimeout: () => false);
    if (renovada) {
      estado.iniciar(UsuarioSesion.desdeToken(await tokens.usuarioGuardado() ?? guardado));
      return true;
    }
    // Si el servidor rechazó el token, el gestor ya lo borró: no hay sesión.
    if (await tokens.tokenRenovacion() == null) {
      return false;
    }
    // Sin red: se abre con el usuario guardado; las peticiones renovarán cuando vuelva la conexión.
    estado.iniciar(UsuarioSesion.desdeToken(guardado));
    return true;
  }

  Future<void> cerrar() => _expirada.cancel();
}
