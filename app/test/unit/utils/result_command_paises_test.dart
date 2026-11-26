import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/data/services/api/errores_api.dart';
import 'package:kaizen/utils/command.dart';
import 'package:kaizen/utils/fechas.dart';
import 'package:kaizen/utils/paises_estados.dart';
import 'package:kaizen/utils/result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Result', () {
    test('éxito y fallo sin excepciones', () {
      const ok = Result<int>.exito(3);
      const malo = Result<int>.fallo(ErrorApp(TipoError.noEncontrado));
      expect(ok.esExito, isTrue);
      expect(ok.valorONulo, 3);
      expect(ok.errorONulo, isNull);
      expect(malo.esExito, isFalse);
      expect(malo.valorONulo, isNull);
      expect(malo.errorONulo!.tipo, TipoError.noEncontrado);
      expect(ok.mapear((v) => v * 2).valorONulo, 6);
      expect(malo.mapear((v) => v * 2).errorONulo!.tipo, TipoError.noEncontrado);
      expect(ok.toString(), 'Exito(3)');
      expect(malo.toString(), 'Fallo(noEncontrado)');
    });
  });

  group('Command', () {
    test('marca ejecutando, guarda el resultado y avisa', () async {
      final completer = Completer<Result<String>>();
      final c = Command0<String>(() => completer.future);
      final avisos = <bool>[];
      c.addListener(() => avisos.add(c.ejecutando));
      final f = c.ejecutar();
      expect(c.ejecutando, isTrue);
      completer.complete(const Result.exito('listo'));
      await f;
      expect(c.ejecutando, isFalse);
      expect(c.completado, isTrue);
      expect(c.resultado!.valorONulo, 'listo');
      expect(avisos, [true, false]);
    });

    test('ignora una segunda llamada mientras se ejecuta (doble toque)', () async {
      var llamadas = 0;
      final completer = Completer<Result<int>>();
      final c = Command1<int, int>((n) {
        llamadas++;
        return completer.future;
      });
      final f1 = c.ejecutar(1);
      final f2 = c.ejecutar(2);
      completer.complete(const Result.exito(1));
      await Future.wait([f1, f2]);
      expect(llamadas, 1);
    });

    test('error y limpiar', () async {
      final c = Command0<void>(() async => const Result.fallo(ErrorApp(TipoError.sinConexion)));
      await c.ejecutar();
      expect(c.conError, isTrue);
      expect(c.error!.tipo, TipoError.sinConexion);
      c.limpiar();
      expect(c.resultado, isNull);
      c.limpiar(); // sin resultado no avisa ni truena
    });
  });

  group('Catálogo de países y estados (asset real)', () {
    late CatalogoRegiones catalogo;
    setUpAll(() async => catalogo = await CatalogoRegiones.cargar());

    test('20 países y 32 estados, como fn_region', () {
      expect(catalogo.paises, hasLength(20));
      expect(catalogo.estadosMx, hasLength(32));
      expect(catalogo.pais('MX')!.requiereEstado, isTrue);
      expect(catalogo.pais('CO')!.requiereEstado, isFalse);
      expect(catalogo.pais('US'), isNull);
    });

    test('región que asignaría la base', () {
      expect(catalogo.regionDe('MX', 'AGU'), 'MX-NORTE');
      expect(catalogo.regionDe('MX', 'JAL'), 'MX-NORTE');
      expect(catalogo.regionDe('MX', 'CMX'), 'MX-CENTRO-SUR');
      expect(catalogo.regionDe('MX', null), isNull, reason: 'México exige estado');
      expect(catalogo.regionDe('MX', 'XXX'), isNull);
      expect(catalogo.regionDe('CO', null), 'LATAM');
      expect(catalogo.regionDe('CO', 'JAL'), isNull, reason: 'fuera de México el estado va en null');
      expect(catalogo.regionDe('US', null), isNull);
    });
  });

  group('Fechas (Paso 4)', () {
    test('formato largo, ISO y solo fecha', () {
      expect(Fechas.larga(DateTime.utc(2026, 11, 8)), 'Domingo 8 de noviembre');
      expect(Fechas.larga(DateTime.utc(2026, 11, 23)), 'Lunes 23 de noviembre');
      expect(Fechas.iso(DateTime.utc(2026, 2, 9)), '2026-02-09');
      expect(Fechas.soloFecha(DateTime(2026, 11, 23, 23, 59)), DateTime.utc(2026, 11, 23));
      expect(Fechas.hoy(() => DateTime(2026, 11, 23, 22)), DateTime.utc(2026, 11, 23));
    });

    test('inicio de semana (lunes) y semana ISO', () {
      expect(Fechas.inicioSemana(DateTime.utc(2026, 11, 29)), DateTime.utc(2026, 11, 23));
      expect(Fechas.inicioSemana(DateTime.utc(2026, 11, 23)), DateTime.utc(2026, 11, 23));
      expect(Fechas.semanaIso(DateTime.utc(2026, 11, 23)), '2026-W48');
      expect(Fechas.semanaIso(DateTime.utc(2026, 11, 17)), '2026-W47');
      expect(Fechas.semanaIso(DateTime.utc(2027, 1, 1)), '2026-W53');
      expect(Fechas.semanaIso(DateTime.utc(2026, 1, 1)), '2026-W01');
    });
  });
}
