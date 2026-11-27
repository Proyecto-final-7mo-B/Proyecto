import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/data/sync/monitor_conexion.dart';
import 'package:mocktail/mocktail.dart';

class _ConnectivityFalsa extends Mock implements Connectivity {}

void main() {
  late _ConnectivityFalsa connectivity;
  late StreamController<List<ConnectivityResult>> cambios;

  setUp(() {
    connectivity = _ConnectivityFalsa();
    cambios = StreamController<List<ConnectivityResult>>.broadcast();
    when(() => connectivity.onConnectivityChanged).thenAnswer((_) => cambios.stream);
  });

  test('connectivity_plus: estado inicial y cambios (solo cuando cambia de verdad)', () async {
    when(connectivity.checkConnectivity).thenAnswer((_) async => [ConnectivityResult.none]);
    final m = MonitorConexionPlus(connectivity: connectivity);
    await m.iniciar();
    await m.iniciar(); // una sola suscripción
    expect(m.hayRed, isFalse);
    final avisos = <bool>[];
    final sub = m.cambios.listen(avisos.add);
    cambios.add([ConnectivityResult.wifi]);
    cambios.add([ConnectivityResult.wifi, ConnectivityResult.mobile]);
    cambios.add([ConnectivityResult.none]);
    await pumpEventQueue();
    expect(avisos, [true, false]);
    expect(m.hayRed, isFalse);
    verify(() => connectivity.onConnectivityChanged).called(1);
    await sub.cancel();
    await m.cerrar();
  });

  test('si el sistema no reporta la red, se asume que sí (lo decide la petición)', () async {
    when(connectivity.checkConnectivity).thenThrow(Exception('sin plugin'));
    final m = MonitorConexionPlus(connectivity: connectivity);
    await m.iniciar();
    expect(m.hayRed, isTrue);
    await m.cerrar();
  });

  test('manual: avisa solo cuando cambia', () async {
    final m = MonitorConexionManual();
    final avisos = <bool>[];
    m.cambios.listen(avisos.add);
    m
      ..hayRed = true
      ..hayRed = false
      ..hayRed = false
      ..hayRed = true;
    await m.iniciar();
    expect(avisos, [false, true]);
    await m.cerrar();
  });
}
