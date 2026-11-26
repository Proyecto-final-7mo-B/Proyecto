import 'package:flutter/foundation.dart';

import '../../../data/services/servicio_sesion.dart';
import '../../../domain/models/usuario.dart';
import '../../../utils/command.dart';

/// Credenciales del formulario de entrar.
typedef Credenciales = ({String email, String contrasena});

/// Pestaña "Entrar". Al terminar con éxito, la sesión queda abierta y el router lleva a `/hoy` (o a donde iba).
class EntrarViewModel extends ChangeNotifier {
  EntrarViewModel(this._sesion) {
    entrar = Command1<UsuarioToken, Credenciales>((c) => _sesion.entrar(email: c.email, contrasena: c.contrasena));
  }

  final ServicioSesion _sesion;
  late final Command1<UsuarioToken, Credenciales> entrar;

  @override
  void dispose() {
    entrar.dispose();
    super.dispose();
  }
}
