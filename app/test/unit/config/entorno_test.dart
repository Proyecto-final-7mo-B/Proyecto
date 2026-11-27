import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/config/constantes.dart';
import 'package:kaizen/config/entorno.dart';

void main() {
  group('FuenteDatos.desde', () {
    test('"fake" usa los repositorios de prueba (sin importar mayúsculas ni espacios)', () {
      expect(FuenteDatos.desde('fake'), FuenteDatos.fake);
      expect(FuenteDatos.desde('  FAKE '), FuenteDatos.fake);
    });

    test('"api" y cualquier valor desconocido usan la API (nunca datos de prueba por error)', () {
      expect(FuenteDatos.desde('api'), FuenteDatos.api);
      expect(FuenteDatos.desde(''), FuenteDatos.api);
      expect(FuenteDatos.desde('produccion'), FuenteDatos.api);
    });
  });

  group('Entorno.desdeValores', () {
    test('quita las diagonales finales de la URL', () {
      final e = Entorno.desdeValores(
        fuente: 'api',
        apiBaseUrl: 'http://localhost:8000/api/v1//',
        zonaHorariaDefecto: 'UTC',
      );
      expect(e.apiBaseUrl, 'http://localhost:8000/api/v1');
    });

    test('una URL vacía vuelve a la de producción', () {
      final e = Entorno.desdeValores(fuente: 'api', apiBaseUrl: '  ', zonaHorariaDefecto: 'UTC');
      expect(e.apiBaseUrl, apiProduccion);
    });

    test('una zona vacía usa America/Mexico_City', () {
      final e = Entorno.desdeValores(fuente: 'fake', apiBaseUrl: apiProduccion, zonaHorariaDefecto: '');
      expect(e.zonaHorariaDefecto, 'America/Mexico_City');
      expect(e.usaFakes, isTrue);
    });
  });

  test('sin --dart-define la app usa la API de producción', () {
    // Las pruebas se corren sin --dart-define: esto comprueba los valores por omisión reales.
    final e = Entorno.actual();
    expect(e.fuente, FuenteDatos.api);
    expect(e.apiBaseUrl, apiProduccion);
  });

  test('los límites coinciden con el contrato v1.6', () {
    expect(Limites.contrasenaMin, 18);
    expect(Limites.mensajeCapsulaMaxBytes, 4096);
    expect(Limites.rachasObjetivo, [7, 30, 66], reason: '21 días es un mito; 66 es la mediana científica');
    expect(Limites.intencionMax, 120);
    expect(Limites.mascaraLunesAViernes, 1 + 2 + 4 + 8 + 16);
  });
}
