import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/utils/validadores.dart';

/// Los mismos límites que la base (contrato §4), con los bordes incluidos.
void main() {
  test('nombre de usuario 1–80', () {
    expect(Validadores.nombreUsuario(''), ErrorValidacion.requerido);
    expect(Validadores.nombreUsuario('   '), ErrorValidacion.requerido);
    expect(Validadores.nombreUsuario('A'), isNull);
    expect(Validadores.nombreUsuario('a' * 80), isNull);
    expect(Validadores.nombreUsuario('a' * 81), ErrorValidacion.muyLargo);
  });

  test('correo con formato x@y.z, normalizado', () {
    expect(Validadores.correo(null), ErrorValidacion.requerido);
    expect(Validadores.correo('dani@correo.com'), isNull);
    expect(Validadores.correo('  Dani@Correo.COM '), isNull);
    for (final malo in ['dani', 'dani@', '@correo.com', 'dani@correo', 'da ni@correo.com']) {
      expect(Validadores.correo(malo), ErrorValidacion.correoInvalido, reason: malo);
    }
    expect(Validadores.normalizarCorreo('  Dani@Correo.COM '), 'dani@correo.com');
  });

  test('contraseña 18–128 (acordado con backend), sin reglas de composición, distinta del correo', () {
    expect(Validadores.contrasena(''), ErrorValidacion.requerido);
    expect(Validadores.contrasena('a' * 17), ErrorValidacion.contrasenaCorta);
    expect(Validadores.contrasena('a' * 18), isNull);
    expect(Validadores.contrasena('a' * 128), isNull);
    expect(Validadores.contrasena('a' * 129), ErrorValidacion.contrasenaLarga);
    expect(
      Validadores.contrasena('Muy.Largo@Correo.com', correo: 'muy.largo@correo.com'),
      ErrorValidacion.contrasenaIgualAlCorreo,
    );
    expect(Validadores.contrasenaParaEntrar(''), ErrorValidacion.requerido);
    expect(Validadores.contrasenaParaEntrar('x'), isNull);
    expect(Validadores.confirmacion('abc', 'abc'), isNull);
    expect(Validadores.confirmacion('abd', 'abc'), ErrorValidacion.contrasenasDistintas);
  });

  test('hábito: nombre 1–60, unidad 1–20, categoría 2–40, motivo 3–200', () {
    expect(Validadores.nombreHabito('a' * 60), isNull);
    expect(Validadores.nombreHabito('a' * 61), ErrorValidacion.muyLargo);
    expect(Validadores.unidad('min'), isNull);
    expect(Validadores.unidad('a' * 21), ErrorValidacion.muyLargo);
    expect(Validadores.nombreCategoria('A'), ErrorValidacion.muyCorto);
    expect(Validadores.nombreCategoria('Arte'), isNull);
    expect(Validadores.motivoSuspension('ab'), ErrorValidacion.muyCorto);
    expect(Validadores.motivoSuspension('Spam'), isNull);
    expect(Validadores.motivoSuspension('a' * 201), ErrorValidacion.muyLargo);
  });

  test('meta > 0 con hasta 2 decimales (acepta coma decimal)', () {
    expect(Validadores.meta(''), ErrorValidacion.requerido);
    expect(Validadores.meta('abc'), ErrorValidacion.numeroInvalido);
    expect(Validadores.meta('0'), ErrorValidacion.debeSerMayorACero);
    expect(Validadores.meta('-1'), ErrorValidacion.debeSerMayorACero);
    expect(Validadores.meta('0.01'), isNull);
    expect(Validadores.meta('16.5'), isNull);
    expect(Validadores.meta('16,55'), isNull);
    expect(Validadores.meta('1.234'), ErrorValidacion.maximoDosDecimales);
  });

  test('valor de check-in opcional, ≥ 0', () {
    expect(Validadores.valorRegistro(''), isNull);
    expect(Validadores.valorRegistro('0'), isNull);
    expect(Validadores.valorRegistro('-0.5'), ErrorValidacion.noNegativo);
    expect(Validadores.valorRegistro('x'), ErrorValidacion.numeroInvalido);
    expect(Validadores.valorRegistro('2.555'), ErrorValidacion.maximoDosDecimales);
  });

  test('ánimo y energía 1–5; días 1–127; veces 1–7; objetivo 7/21/66', () {
    expect(Validadores.animoEnergia(null), ErrorValidacion.requerido);
    expect(Validadores.animoEnergia(0), ErrorValidacion.fueraDeRango);
    expect(Validadores.animoEnergia(1), isNull);
    expect(Validadores.animoEnergia(5), isNull);
    expect(Validadores.animoEnergia(6), ErrorValidacion.fueraDeRango);
    expect(Validadores.mascaraDias(0), ErrorValidacion.requerido);
    expect(Validadores.mascaraDias(1), isNull);
    expect(Validadores.mascaraDias(127), isNull);
    expect(Validadores.mascaraDias(128), ErrorValidacion.fueraDeRango);
    expect(Validadores.vecesSemana(null), ErrorValidacion.requerido);
    expect(Validadores.vecesSemana(7), isNull);
    expect(Validadores.vecesSemana(8), ErrorValidacion.fueraDeRango);
    expect(Validadores.rachaObjetivo(21), isNull);
    expect(Validadores.rachaObjetivo(30), ErrorValidacion.fueraDeRango);
  });

  test('mensaje de cápsula: 4096 BYTES en UTF-8 (un emoji ocupa 4)', () {
    expect(Validadores.bytesUtf8('😀'), 4);
    expect(Validadores.bytesUtf8('ñ'), 2);
    expect(Validadores.mensajeCapsula(' '), ErrorValidacion.requerido);
    expect(Validadores.mensajeCapsula('a' * 4096), isNull);
    expect(Validadores.mensajeCapsula('a' * 4097), ErrorValidacion.mensajeMuyLargo);
    expect(Validadores.mensajeCapsula('😀' * 1024), isNull);
    expect(Validadores.mensajeCapsula('${'😀' * 1024}a'), ErrorValidacion.mensajeMuyLargo);
  });

  test('rango de fechas: desde ≤ hasta y máximo 366 días', () {
    final d = DateTime.utc(2026, 1, 1);
    expect(Validadores.rangoFechas(d, d), isNull);
    expect(Validadores.rangoFechas(d, d.add(const Duration(days: 366))), isNull);
    expect(Validadores.rangoFechas(d, d.add(const Duration(days: 367))), ErrorValidacion.rangoFechasInvalido);
    expect(Validadores.rangoFechas(d, d.subtract(const Duration(days: 1))), ErrorValidacion.rangoFechasInvalido);
  });
}
