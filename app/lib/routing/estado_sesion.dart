import 'package:flutter/foundation.dart';

import '../domain/models/usuario.dart';
import '../utils/paises_estados.dart' as utils;

export '../domain/models/usuario.dart' show RolUsuario;

/// Datos mínimos de quien tiene la sesión abierta, para la navegación y el riel lateral.
@immutable
class UsuarioSesion {
  const UsuarioSesion({required this.nombre, required this.rol, this.region});

  /// A partir del usuario que viene con los tokens.
  factory UsuarioSesion.desdeToken(UsuarioToken u) => UsuarioSesion(nombre: u.nombre, rol: u.rol, region: u.region);

  final String nombre;
  final RolUsuario rol;

  /// Código de la API: `MX-NORTE`, `MX-CENTRO-SUR` o `LATAM` (lo calcula la base con `fn_region`).
  final String? region;

  /// "MX Norte", "MX Centro-Sur" o "LATAM", como en los bosquejos.
  String? get nombreRegion => region == null ? null : utils.nombreRegion(region!);

  bool get esAdmin => rol == RolUsuario.admin;

  /// Inicial para el avatar ("J" de "Jael").
  String get inicial => nombre.trim().isEmpty ? '?' : String.fromCharCode(nombre.trim().runes.first).toUpperCase();
}

/// Estado de la sesión que escucha el router: cuando cambia, vuelve a evaluar las guardas.
///
/// En el Paso 3 solo guarda quién entró. En el Paso 5 lo actualiza el ViewModel de login con lo que devuelve
/// `POST /auth/login` (los tokens viven en el almacén seguro, nunca aquí).
class EstadoSesion extends ChangeNotifier {
  /// Con [_usuario] se empieza con la sesión abierta (pruebas).
  EstadoSesion([this._usuario]);

  UsuarioSesion? _usuario;

  UsuarioSesion? get usuario => _usuario;
  bool get iniciada => _usuario != null;
  bool get esAdmin => _usuario?.esAdmin ?? false;

  void iniciar(UsuarioSesion usuario) {
    _usuario = usuario;
    notifyListeners();
  }

  void cerrar() {
    if (_usuario == null) {
      return;
    }
    _usuario = null;
    notifyListeners();
  }
}
