import 'dart:async';
import 'dart:convert';

import '../../domain/models/sesion.dart';
import '../../domain/models/usuario.dart';
import '../../utils/result.dart';
import 'almacen_seguro.dart';

/// Guarda los tokens y coordina su renovación.
///
/// - El token de **acceso** vive solo en memoria.
/// - El de **renovación** y el usuario van al [AlmacenSeguro] (en web, también en memoria).
/// - [renovar] es de **un solo vuelo**: si dos peticiones reciben 401 a la vez, se hace una sola llamada a
///   `/auth/renovar` y ambas esperan el mismo resultado (contrato §2.1).
class GestorTokens {
  GestorTokens(this._almacen);

  static const String claveRenovacion = 'kaizen.token_renovacion';
  static const String claveUsuario = 'kaizen.usuario';

  final AlmacenSeguro _almacen;
  String? _acceso;
  Completer<bool>? _renovando;

  /// Llama a `POST /auth/renovar` (lo configura el cliente de la API; en modo *fake*, el repositorio *fake*).
  Future<Result<Tokens>> Function(String tokenRenovacion)? renovador;

  /// Se avisa cuando la sesión ya no se puede renovar (token inválido, reutilizado o cuenta suspendida).
  final StreamController<void> _expirada = StreamController<void>.broadcast();
  Stream<void> get sesionExpirada => _expirada.stream;

  String? get tokenAcceso => _acceso;

  Future<String?> tokenRenovacion() => _almacen.leer(claveRenovacion);

  Future<void> guardar(Tokens tokens) async {
    _acceso = tokens.tokenAcceso;
    await _almacen.escribir(claveRenovacion, tokens.tokenRenovacion);
    await _almacen.escribir(claveUsuario, jsonEncode(tokens.usuario.toJson()));
  }

  /// El usuario de la última sesión (para abrir la app sin red).
  Future<UsuarioToken?> usuarioGuardado() async {
    final texto = await _almacen.leer(claveUsuario);
    if (texto == null) {
      return null;
    }
    try {
      return UsuarioToken.fromJson(jsonDecode(texto) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  Future<void> borrar() async {
    _acceso = null;
    await _almacen.borrar(claveRenovacion);
    await _almacen.borrar(claveUsuario);
  }

  /// Pide tokens nuevos con el de renovación. `true` si se pudo.
  ///
  /// Si el servidor dice que la sesión ya no vale, borra todo y avisa en [sesionExpirada]. Si solo falló la red,
  /// conserva los tokens para intentarlo después.
  Future<bool> renovar() {
    final enCurso = _renovando;
    if (enCurso != null) {
      return enCurso.future;
    }
    final completer = Completer<bool>();
    _renovando = completer;
    unawaited(
      _renovarUnaVez().then(completer.complete, onError: (Object _) => completer.complete(false)).whenComplete(() {
        _renovando = null;
      }),
    );
    return completer.future;
  }

  Future<bool> _renovarUnaVez() async {
    final renovacion = await tokenRenovacion();
    final llamar = renovador;
    if (renovacion == null || llamar == null) {
      return false;
    }
    switch (await llamar(renovacion)) {
      case Exito(:final valor):
        await guardar(valor);
        return true;
      case Fallo(:final error):
        if (!error.esDeRed) {
          await borrar();
          _expirada.add(null);
        }
        return false;
    }
  }

  Future<void> cerrar() => _expirada.close();
}
