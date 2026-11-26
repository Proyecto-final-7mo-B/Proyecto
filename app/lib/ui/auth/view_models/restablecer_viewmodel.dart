import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

/// `/restablecer?token=…`: nueva contraseña con el enlace del correo (15 min, un solo uso).
class RestablecerViewModel extends ChangeNotifier {
  RestablecerViewModel(this._auth, this.token) {
    guardar = Command1<void, String>(_guardar);
  }

  final AuthRepository _auth;
  final String? token;
  late final Command1<void, String> guardar;

  /// Sin token, el enlace no sirve: se ofrece pedir otro.
  bool get tieneToken => token != null && token!.isNotEmpty;

  Future<Result<void>> _guardar(String nueva) => _auth.restablecer(token: token!, nueva: nueva);

  @override
  void dispose() {
    guardar.dispose();
    super.dispose();
  }
}
