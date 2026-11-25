import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/routing/estado_sesion.dart';
import 'package:kaizen/routing/guardas.dart';
import 'package:kaizen/routing/rutas.dart';
import 'package:kaizen/ui/core/adaptativo/plataforma.dart';

void main() {
  final sinSesion = EstadoSesion();
  final usuario = EstadoSesion(const UsuarioSesion(nombre: 'Jael', rol: RolUsuario.usuario));
  final admin = EstadoSesion(const UsuarioSesion(nombre: 'Admin', rol: RolUsuario.admin));

  String? ir(
    String ubicacion, {
    EstadoSesion? sesion,
    Plataforma plataforma = Plataforma.escritorio,
    bool dev = false,
  }) => redirigir(
    ubicacion: Uri.parse(ubicacion),
    sesion: sesion ?? usuario,
    plataforma: plataforma,
    herramientasDev: dev,
  );

  group('sin sesión', () {
    test('cualquier pantalla lleva a /login recordando a dónde iba', () {
      expect(ir('/hoy', sesion: sinSesion), '/login?desde=%2Fhoy');
      expect(ir('/habitos/abc/editar', sesion: sinSesion), '/login?desde=%2Fhabitos%2Fabc%2Feditar');
      expect(ir('/capsulas/nueva?habito=1', sesion: sinSesion), '/login?desde=%2Fcapsulas%2Fnueva%3Fhabito%3D1');
      expect(ir('/admin', sesion: sinSesion), startsWith('/login'));
    });

    test('login y restablecer se abren sin sesión', () {
      expect(ir('/login', sesion: sinSesion), isNull);
      expect(ir('/login?desde=%2Fhoy', sesion: sinSesion), isNull);
      expect(ir('/restablecer?token=abc', sesion: sinSesion), isNull);
    });

    test('la raíz lleva a /hoy (y de ahí a /login)', () {
      expect(ir('/', sesion: sinSesion), Rutas.hoy);
      expect(ir('', sesion: sinSesion), Rutas.hoy);
    });
  });

  group('con sesión', () {
    test('las pantallas normales se abren', () {
      for (final r in ['/hoy', '/habitos', '/habitos/1', '/progreso/semana', '/escalera', '/perfil/privacidad']) {
        expect(ir(r), isNull, reason: r);
      }
    });

    test('/login lleva a /hoy o a donde iba', () {
      expect(ir('/login'), Rutas.hoy);
      expect(ir('/login?desde=%2Fhabitos%2F7'), '/habitos/7');
      expect(ir('/login?desde=%2Fcapsulas%2Fnueva%3Fhabito%3D1'), '/capsulas/nueva?habito=1');
    });

    test('restablecer también se abre con sesión', () => expect(ir('/restablecer?token=x'), isNull));
  });

  group('admin', () {
    test('un usuario normal no entra al panel', () {
      expect(ir('/admin'), Rutas.hoy);
      expect(ir('/admin/indicadores'), Rutas.hoy);
    });

    test('un admin entra en escritorio y web', () {
      expect(ir('/admin', sesion: admin), isNull);
      expect(ir('/admin/indicadores', sesion: admin, plataforma: Plataforma.web), isNull);
    });

    test('en Android/iOS no existe el panel, ni para un admin', () {
      expect(ir('/admin', sesion: admin, plataforma: Plataforma.movil), Rutas.hoy);
      expect(ir('/admin/indicadores', sesion: admin, plataforma: Plataforma.movil), Rutas.hoy);
    });

    test('/administracion no se confunde con /admin', () => expect(ir('/administracion'), isNull));
  });

  group('galería de componentes', () {
    test('solo en depuración, con o sin sesión', () {
      expect(ir('/dev/componentes', dev: true), isNull);
      expect(ir('/dev/componentes', sesion: sinSesion, dev: true), isNull);
      expect(ir('/dev/componentes'), Rutas.hoy);
      expect(ir('/dev/componentes', sesion: sinSesion), Rutas.login);
    });
  });

  group('destino seguro después de entrar (sin redirección abierta)', () {
    test('acepta rutas internas', () {
      expect(destinoSeguro('/habitos/1'), '/habitos/1');
      expect(destinoSeguro('/progreso?periodo=mes'), '/progreso?periodo=mes');
    });

    test('rechaza sitios externos, rutas raras y vacías', () {
      for (final malo in [
        null,
        '',
        'https://evil.example/hoy',
        '//evil.example/hoy',
        'evil.example',
        'javascript:alert(1)',
        r'/\evil.example',
        '/login',
        '/restablecer?token=x',
      ]) {
        expect(destinoSeguro(malo), isNull, reason: '$malo');
      }
    });

    test('con un desde malicioso, /login lleva a /hoy', () {
      expect(ir('/login?desde=https%3A%2F%2Fevil.example'), Rutas.hoy);
      expect(ir('/login?desde=%2F%2Fevil.example'), Rutas.hoy);
    });
  });
}
