import 'package:flutter/foundation.dart';

import '../data/services/api/errores_api.dart';
import 'result.dart';

/// Una acción de la interfaz (entrar, guardar, marcar un hábito) con su estado: ejecutando, completado o con error.
/// La pantalla escucha el comando para mostrar un indicador de carga, deshabilitar el botón o el mensaje de error.
///
/// Mientras se ejecuta, una segunda llamada se ignora (evita doble envío al tocar dos veces).
abstract class Command<T> extends ChangeNotifier {
  bool _ejecutando = false;
  Result<T>? _resultado;

  bool get ejecutando => _ejecutando;
  Result<T>? get resultado => _resultado;
  bool get completado => _resultado is Exito<T>;
  bool get conError => _resultado is Fallo<T>;
  ErrorApp? get error => _resultado?.errorONulo;

  /// Olvida el último resultado (p. ej., al cerrar el mensaje de error).
  void limpiar() {
    if (_resultado == null) {
      return;
    }
    _resultado = null;
    notifyListeners();
  }

  Future<void> _ejecutar(Future<Result<T>> Function() accion) async {
    if (_ejecutando) {
      return;
    }
    _ejecutando = true;
    _resultado = null;
    notifyListeners();
    try {
      _resultado = await accion();
    } finally {
      _ejecutando = false;
      notifyListeners();
    }
  }
}

/// Comando sin argumentos.
class Command0<T> extends Command<T> {
  Command0(this._accion);

  final Future<Result<T>> Function() _accion;

  Future<void> ejecutar() => _ejecutar(_accion);
}

/// Comando con un argumento.
class Command1<T, A> extends Command<T> {
  Command1(this._accion);

  final Future<Result<T>> Function(A argumento) _accion;

  Future<void> ejecutar(A argumento) => _ejecutar(() => _accion(argumento));
}
