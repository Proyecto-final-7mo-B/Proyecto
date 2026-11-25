import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/routing/estado_sesion.dart';
import 'package:kaizen/routing/rutas.dart';

void main() {
  group('Rutas', () {
    test('rutas de un hábito, con el id codificado', () {
      expect(Rutas.habito('abc'), '/habitos/abc');
      expect(Rutas.editarHabito('abc'), '/habitos/abc/editar');
      expect(Rutas.escaleraHabito('abc'), '/habitos/abc/escalera');
      expect(Rutas.habito('a/b c'), '/habitos/a%2Fb%20c');
    });

    test('nueva cápsula de un hábito y login con destino', () {
      expect(Rutas.nuevaCapsulaDe('h1'), '/capsulas/nueva?habito=h1');
      expect(Rutas.loginDesde('/hoy'), '/login?desde=%2Fhoy');
    });

    test('dentroDe distingue prefijos reales', () {
      expect(Rutas.dentroDe('/habitos', '/habitos'), isTrue);
      expect(Rutas.dentroDe('/habitos/1/editar', '/habitos'), isTrue);
      expect(Rutas.dentroDe('/habitosx', '/habitos'), isFalse);
      expect(Rutas.dentroDe('/hoy', '/habitos'), isFalse);
    });

    test('solo login y restablecer son públicas', () {
      expect(Rutas.publicas, {Rutas.login, Rutas.restablecer});
    });
  });

  group('EstadoSesion', () {
    test('empieza cerrada; iniciar y cerrar avisan al router', () {
      final sesion = EstadoSesion();
      var avisos = 0;
      sesion.addListener(() => avisos++);
      expect(sesion.iniciada, isFalse);
      expect(sesion.esAdmin, isFalse);

      sesion.iniciar(const UsuarioSesion(nombre: 'Admin', rol: RolUsuario.admin));
      expect(sesion.iniciada, isTrue);
      expect(sesion.esAdmin, isTrue);
      expect(sesion.usuario!.nombre, 'Admin');

      sesion.cerrar();
      expect(sesion.iniciada, isFalse);
      expect(avisos, 2);

      sesion.cerrar();
      expect(avisos, 2, reason: 'cerrar dos veces no avisa de nuevo');
      sesion.dispose();
    });

    test('inicial del avatar y nombre de la región', () {
      const u = UsuarioSesion(nombre: ' ángel ', rol: RolUsuario.usuario, region: 'MX-NORTE');
      expect(u.inicial, 'Á');
      expect(u.nombreRegion, 'MX Norte');
      expect(const UsuarioSesion(nombre: '', rol: RolUsuario.usuario).inicial, '?');
      expect(
        const UsuarioSesion(nombre: 'x', rol: RolUsuario.usuario, region: 'MX-CENTRO-SUR').nombreRegion,
        'MX Centro-Sur',
      );
      expect(const UsuarioSesion(nombre: 'x', rol: RolUsuario.usuario, region: 'LATAM').nombreRegion, 'LATAM');
      expect(const UsuarioSesion(nombre: 'x', rol: RolUsuario.usuario, region: 'OTRA').nombreRegion, 'OTRA');
      expect(const UsuarioSesion(nombre: 'x', rol: RolUsuario.usuario).nombreRegion, isNull);
    });
  });
}
