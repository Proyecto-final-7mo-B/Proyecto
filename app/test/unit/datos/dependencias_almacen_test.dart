import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/config/dependencias.dart';
import 'package:kaizen/config/entorno.dart';
import 'package:kaizen/data/repositories/auth/auth_repository.dart';
import 'package:kaizen/data/repositories/auth/auth_repository_api.dart';
import 'package:kaizen/data/repositories/auth/auth_repository_fake.dart';
import 'package:kaizen/data/repositories/habitos/habitos_repository_api.dart';
import 'package:kaizen/data/services/almacen_seguro.dart';
import 'package:kaizen/domain/models/categoria.dart';
import 'package:kaizen/utils/paises_estados.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Entorno entorno(String fuente) =>
      Entorno.desdeValores(fuente: fuente, apiBaseUrl: 'http://localhost:8000/api/v1', zonaHorariaDefecto: 'UTC');

  test('KAIZEN_FUENTE=fake → repositorios fake con 300 ms de red simulada', () {
    final d = Dependencias.desdeEntorno(entorno('fake'));
    expect(d.auth, isA<AuthRepositoryFake>());
    expect(d.datosDemo, isNotNull);
    expect(d.datosDemo!.latencia, const Duration(milliseconds: 300));
    expect(d.tokens.renovador, isNotNull, reason: 'el gestor renueva contra el fake');
  });

  test('KAIZEN_FUENTE=api → repositorios contra la API; sin datos demo', () {
    final d = Dependencias.desdeEntorno(entorno('api'));
    expect(d.auth, isA<AuthRepositoryApi>());
    expect(d.habitos, isA<HabitosRepositoryApi>());
    expect(d.datosDemo, isNull);
    expect(d.tokens.renovador, isNotNull, reason: 'el cliente configura /auth/renovar');
  });

  testWidgets('proveedores: cada interfaz se puede pedir con context.read', (tester) async {
    const catalogo = CatalogoRegiones(paises: [], estadosMx: []);
    final d = Dependencias.fake(catalogo: catalogo);
    expect(d.proveedores(), hasLength(15));
    late AuthRepository auth;
    late CatalogoRegiones leido;
    await tester.pumpWidget(
      MultiProvider(
        providers: d.proveedores(),
        child: Builder(
          builder: (context) {
            auth = context.read<AuthRepository>();
            leido = context.read<CatalogoRegiones>();
            return const SizedBox();
          },
        ),
      ),
    );
    expect(auth, same(d.auth));
    expect(leido, same(catalogo));
    expect(Dependencias.fake().proveedores(), hasLength(15), reason: 'el catálogo se registra aunque sea nulo');
  });

  test('almacén nativo (flutter_secure_storage simulado) y almacén en memoria', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final nativo = AlmacenSeguroNativo();
    await nativo.escribir('k', 'v');
    expect(await nativo.leer('k'), 'v');
    await nativo.borrar('k');
    expect(await nativo.leer('k'), isNull);
    expect(crearAlmacenSeguro(), isA<AlmacenSeguroNativo>(), reason: 'las pruebas no son web');
  });

  test('Categoria: igualdad por valor y copyWith', () {
    const c = Categoria(id: '1', nombre: 'Salud');
    expect(c, const Categoria(id: '1', nombre: 'Salud'));
    expect(c.hashCode, const Categoria(id: '1', nombre: 'Salud').hashCode);
    expect(c.copyWith(activa: false), isNot(c));
    expect(c.copyWith(nombre: 'Bienestar').nombre, 'Bienestar');
  });
}
