import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../config/constantes.dart';
import '../../utils/result.dart';
import '../repositories/registros/registros_repository.dart';
import '../services/api/errores_api.dart';
import '../services/base_local/almacen_local.dart';
import 'monitor_conexion.dart';

/// Un check-in de la cola que el servidor rechazó (p. ej., el hábito se archivó en otro dispositivo).
typedef Rechazo = ({String id, String motivo});

/// Envía la cola sin conexión con `POST /registros/lote` (hasta 100 por lote):
/// - al abrir la app y al iniciar sesión;
/// - cuando vuelve la red (`connectivity_plus`);
/// - al regresar la app al frente;
/// - cada [reintento] mientras queden pendientes (por si el servidor estaba caído aunque hubiera red).
///
/// Por cada elemento: `aceptado` → sale de la cola y la copia del hábito toma la racha real; `rechazado` → se
/// marca con su motivo y no se reintenta (contrato §6.5). Si el envío falla por red, todo se queda para después.
class Sincronizador extends ChangeNotifier {
  Sincronizador({
    required AlmacenLocal almacen,
    required RegistrosRepository remoto,
    required MonitorConexion monitor,
    this.reintento = const Duration(minutes: 1),
  }) : _almacenCola = almacen,
       _remotoLote = remoto,
       _monitorRed = monitor;

  final AlmacenLocal _almacenCola;
  final RegistrosRepository _remotoLote;
  final MonitorConexion _monitorRed;

  /// Solo se envía con una sesión abierta (la app lo conecta con `EstadoSesion`).
  bool Function() haySesion = _sinSesion;

  static bool _sinSesion() => false;

  /// `null` = sin reintento periódico (pruebas).
  final Duration? reintento;

  final _rechazos = StreamController<List<Rechazo>>.broadcast();
  final List<StreamSubscription<Object?>> _subs = [];
  Timer? _temporizador;
  Future<int>? _enCurso;
  bool _iniciado = false;

  bool _enLinea = true;
  int _pendientes = 0;
  int _rechazados = 0;

  /// Hay red y el último intento llegó al servidor.
  bool get enLinea => _enLinea;
  int get pendientes => _pendientes;
  int get rechazados => _rechazados;
  bool get sincronizando => _enCurso != null;

  /// El aviso de "sin conexión" se muestra si no hay red o si quedaron cosas sin enviar.
  bool get mostrarAviso => !_enLinea || (_pendientes > 0 && !sincronizando);

  /// Rechazos de cada envío, para avisarle al usuario una vez.
  Stream<List<Rechazo>> get rechazos => _rechazos.stream;

  static const Set<TipoError> erroresDeRed = {
    TipoError.sinConexion,
    TipoError.tiempoAgotado,
    TipoError.servicioNoDisponible,
    TipoError.primarioNoDisponible,
  };

  static bool esDeRed(ErrorApp e) => erroresDeRed.contains(e.tipo);

  Future<void> iniciar() async {
    if (_iniciado) {
      return;
    }
    _iniciado = true;
    await _monitorRed.iniciar();
    _enLinea = _monitorRed.hayRed;
    _subs
      ..add(
        _monitorRed.cambios.listen((hayRed) {
          _enLinea = hayRed;
          notifyListeners();
          if (hayRed) {
            sincronizar();
          }
        }),
      )
      ..add(
        _almacenCola.observarCola().listen((c) {
          _pendientes = c.pendientes;
          _rechazados = c.rechazados;
          _programarReintento();
          notifyListeners();
        }),
      );
    notifyListeners();
    await sincronizar();
  }

  /// Una petición falló por red: se muestra el aviso hasta que algo vuelva a llegar al servidor.
  void marcarSinConexion() {
    if (_enLinea) {
      _enLinea = false;
      notifyListeners();
    }
  }

  void marcarEnLinea() {
    if (!_enLinea && _monitorRed.hayRed) {
      _enLinea = true;
      notifyListeners();
    }
  }

  void _programarReintento() {
    final cada = reintento;
    if (cada == null || _pendientes == 0) {
      _temporizador?.cancel();
      _temporizador = null;
      return;
    }
    _temporizador ??= Timer.periodic(cada, (_) => sincronizar());
  }

  /// Envía todo lo pendiente; devuelve cuántos aceptó el servidor. Si ya se está enviando, espera ese envío.
  Future<int> sincronizar() => _enCurso ??= _enviar().whenComplete(() {
    _enCurso = null;
    notifyListeners();
  });

  Future<int> _enviar() async {
    if (!haySesion() || !_monitorRed.hayRed) {
      return 0;
    }
    notifyListeners();
    var aceptados = 0;
    final rechazos = <Rechazo>[];
    while (true) {
      final lote = await _almacenCola.pendientes(limite: Limites.loteMaxRegistros);
      if (lote.isEmpty) {
        break;
      }
      final r = await _remotoLote.registrarLote(lote);
      if (r case Fallo(:final error)) {
        await _almacenCola.anotarIntento(lote.map((x) => x.id), error.tipo.name);
        if (esDeRed(error)) {
          marcarSinConexion();
        }
        break;
      }
      marcarEnLinea();
      final porId = {for (final x in lote) x.id: x};
      for (final e in r.valorONulo!.resultados) {
        final enviado = porId[e.id];
        if (enviado == null) {
          continue;
        }
        if (e.aceptado) {
          aceptados++;
          await _almacenCola.desencolar(e.id);
          await _almacenCola.confirmarCheckin(enviado, e.rachaActual ?? 0);
        } else {
          final motivo = e.error?.tipo ?? 'rechazado';
          await _almacenCola.marcarRechazado(e.id, motivo);
          rechazos.add((id: e.id, motivo: motivo));
        }
      }
      if (lote.length < Limites.loteMaxRegistros) {
        break;
      }
    }
    if (rechazos.isNotEmpty) {
      _rechazos.add(rechazos);
    }
    return aceptados;
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    _rechazos.close();
    super.dispose();
  }
}
