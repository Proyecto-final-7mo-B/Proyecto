import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// ¿Hay red? Avisa cada vez que cambia. Solo dice si el dispositivo tiene una interfaz de red (wifi, datos, cable):
/// que el servidor conteste es otra cosa, y eso lo descubre cada petición.
abstract interface class MonitorConexion {
  bool get hayRed;
  Stream<bool> get cambios;
  Future<void> iniciar();
  Future<void> cerrar();
}

/// Con `connectivity_plus` (las 6 plataformas).
class MonitorConexionPlus implements MonitorConexion {
  MonitorConexionPlus({Connectivity? connectivity}) : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  final _cambios = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _hayRed = true;

  @override
  bool get hayRed => _hayRed;

  @override
  Stream<bool> get cambios => _cambios.stream;

  static bool _conRed(List<ConnectivityResult> r) => r.any((x) => x != ConnectivityResult.none);

  @override
  Future<void> iniciar() async {
    if (_sub != null) {
      return;
    }
    try {
      _hayRed = _conRed(await _connectivity.checkConnectivity());
    } on Object {
      _hayRed = true; // Si el sistema no lo dice, se asume que sí y lo decide la petición.
    }
    _sub = _connectivity.onConnectivityChanged.listen((r) {
      final nuevo = _conRed(r);
      if (nuevo != _hayRed) {
        _hayRed = nuevo;
        _cambios.add(nuevo);
      }
    });
  }

  @override
  Future<void> cerrar() async {
    await _sub?.cancel();
    await _cambios.close();
  }
}

/// Para pruebas y para simular "modo avión" en la galería de desarrollo.
class MonitorConexionManual implements MonitorConexion {
  MonitorConexionManual({bool hayRed = true}) : _red = hayRed;

  final _cambios = StreamController<bool>.broadcast(sync: true);
  bool _red;

  @override
  bool get hayRed => _red;

  set hayRed(bool valor) {
    if (valor != _red) {
      _red = valor;
      _cambios.add(valor);
    }
  }

  @override
  Stream<bool> get cambios => _cambios.stream;

  @override
  Future<void> iniciar() async {}

  @override
  Future<void> cerrar() => _cambios.close();
}
