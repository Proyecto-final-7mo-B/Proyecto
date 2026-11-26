import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../utils/command.dart';

/// "¿Olvidaste tu contraseña?": siempre muestra el mismo mensaje, exista o no la cuenta (no delata correos).
/// Solo los errores de red o de límite de tasa se muestran como error.
class RecuperarViewModel extends ChangeNotifier {
  RecuperarViewModel(AuthRepository auth) {
    enviar = Command1<void, String>(auth.recuperar);
  }

  late final Command1<void, String> enviar;

  @override
  void dispose() {
    enviar.dispose();
    super.dispose();
  }
}
