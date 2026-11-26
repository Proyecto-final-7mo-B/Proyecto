import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/config/dependencias.dart';
import 'package:kaizen/data/fake/datos_demo.dart';
import 'package:kaizen/data/repositories/admin/admin_repository_fake.dart';
import 'package:kaizen/data/services/api/errores_api.dart';
import 'package:kaizen/domain/models/admin.dart';
import 'package:kaizen/domain/models/capsula.dart';
import 'package:kaizen/domain/models/escalera.dart';
import 'package:kaizen/domain/models/frecuencia.dart';
import 'package:kaizen/domain/models/habito.dart';
import 'package:kaizen/domain/models/laboratorio.dart';
import 'package:kaizen/domain/models/progreso.dart';
import 'package:kaizen/domain/models/registro.dart';
import 'package:kaizen/domain/models/sesion.dart';
import 'package:kaizen/domain/models/usuario.dart';
import 'package:kaizen/utils/paises_estados.dart';
import 'package:kaizen/utils/result.dart';

/// Los repositorios *fake* cumplen las mismas reglas que la base y responden los mismos errores del contrato.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Lunes 23-nov-2026, 18:00 (hora del dispositivo).
  DateTime reloj() => DateTime(2026, 11, 23, 18);
  final hoy = DateTime.utc(2026, 11, 23);

  late DatosDemo datos;
  late Dependencias d;

  TipoError? tipo(Result<Object?> r) => r.errorONulo?.tipo;

  Future<void> entrar(String correo) async {
    final r = await d.auth.entrar(email: correo, contrasena: DatosDemo.contrasenaDemo);
    expect(r.esExito, isTrue, reason: '$correo: $r');
  }

  setUp(() {
    datos = DatosDemo(reloj: reloj);
    d = Dependencias.fake(datos: datos);
  });

  group('auth', () {
    test('las 5 cuentas del poblador; correo sin importar mayúsculas', () async {
      final r = await d.auth.entrar(email: ' DEMO@kaizen.test ', contrasena: DatosDemo.contrasenaDemo);
      expect(r.valorONulo!.usuario.nombre, 'Daniela Demo');
      expect(r.valorONulo!.usuario.region, 'MX-NORTE');
      expect(
        (await d.auth.entrar(email: 'admin@kaizen.test', contrasena: DatosDemo.contrasenaDemo)).valorONulo!.usuario.rol,
        RolUsuario.admin,
      );
      expect(
        (await d.auth.entrar(
          email: 'latam@kaizen.test',
          contrasena: DatosDemo.contrasenaDemo,
        )).valorONulo!.usuario.region,
        'LATAM',
      );
      expect((await d.auth.entrar(email: 'nuevo@kaizen.test', contrasena: DatosDemo.contrasenaDemo)).esExito, isTrue);
    });

    test('mismo error exista o no la cuenta; suspendido solo con contraseña correcta', () async {
      expect(tipo(await d.auth.entrar(email: 'nadie@x.com', contrasena: 'x')), TipoError.credencialesInvalidas);
      expect(tipo(await d.auth.entrar(email: 'demo@kaizen.test', contrasena: 'x')), TipoError.credencialesInvalidas);
      expect(
        tipo(await d.auth.entrar(email: 'suspendido@kaizen.test', contrasena: 'x')),
        TipoError.credencialesInvalidas,
      );
      expect(
        tipo(await d.auth.entrar(email: 'suspendido@kaizen.test', contrasena: DatosDemo.contrasenaDemo)),
        TipoError.cuentaSuspendida,
      );
    });

    test('10 fallos bloquean 15 min (429 con Retry-After)', () async {
      for (var i = 0; i < 10; i++) {
        await d.auth.entrar(email: 'demo@kaizen.test', contrasena: 'mala');
      }
      final r = await d.auth.entrar(email: 'demo@kaizen.test', contrasena: DatosDemo.contrasenaDemo);
      expect(tipo(r), TipoError.cuentaBloqueada);
      expect(r.errorONulo!.reintentarEn, const Duration(minutes: 15));
    });

    test('registro: valida, asigna región con el catálogo y deja la sesión iniciada', () async {
      datos.catalogo = await CatalogoRegiones.cargar();
      SolicitudRegistro s({
        String email = 'ana@correo.com',
        String pais = 'MX',
        String? estado = 'CMX',
        bool aviso = true,
      }) => SolicitudRegistro(
        nombre: 'Ana',
        email: email,
        contrasena: 'una-contrasena-larga',
        pais: pais,
        estado: estado,
        aceptaAviso: aviso,
        consienteSenales: true,
      );
      final r = await d.auth.registrar(s());
      expect(r.valorONulo!.usuario.region, 'MX-CENTRO-SUR');
      expect(datos.usuarioActual, r.valorONulo!.usuario.id);
      expect(
        (await d.auth.registrar(s(email: 'b@x.com', pais: 'AR', estado: null))).valorONulo!.usuario.region,
        'LATAM',
      );
      expect(tipo(await d.auth.registrar(s(email: 'c@x.com', estado: null))), TipoError.regionInvalida);
      expect(tipo(await d.auth.registrar(s(email: 'c@x.com', pais: 'US', estado: null))), TipoError.regionInvalida);
      expect(tipo(await d.auth.registrar(s(email: 'DEMO@kaizen.test'))), TipoError.registroRechazado);
      final sinAviso = await d.auth.registrar(s(email: 'e@x.com', aviso: false));
      expect(tipo(sinAviso), TipoError.validacion);
      expect(sinAviso.errorONulo!.errorDe('acepta_aviso'), isNotNull);
      final corta = await d.auth.registrar(
        const SolicitudRegistro(
          nombre: '',
          email: 'malo',
          contrasena: 'corta',
          pais: 'MX',
          estado: 'JAL',
          aceptaAviso: true,
          consienteSenales: false,
        ),
      );
      expect(corta.errorONulo!.errores.map((e) => e.campo), containsAll(['nombre', 'email', 'contrasena']));
    });

    test('registro sin catálogo: México exige estado, fuera de México va sin estado', () async {
      SolicitudRegistro s(String email, String pais, String? estado) => SolicitudRegistro(
        nombre: 'Ana',
        email: email,
        contrasena: 'una-contrasena-larga',
        pais: pais,
        estado: estado,
        aceptaAviso: true,
        consienteSenales: false,
      );
      expect((await d.auth.registrar(s('a@x.com', 'MX', 'JAL'))).esExito, isTrue);
      expect((await d.auth.registrar(s('b@x.com', 'CO', null))).esExito, isTrue);
      expect(tipo(await d.auth.registrar(s('c@x.com', 'MX', null))), TipoError.regionInvalida);
      expect(tipo(await d.auth.registrar(s('e@x.com', 'CO', 'JAL'))), TipoError.regionInvalida);
    });

    test('renovar rota el token; reutilizar uno rotado revoca la familia', () async {
      final t1 = (await d.auth.entrar(email: 'demo@kaizen.test', contrasena: DatosDemo.contrasenaDemo)).valorONulo!;
      final t2 = (await d.auth.renovar(t1.tokenRenovacion)).valorONulo!;
      expect(t2.tokenRenovacion, isNot(t1.tokenRenovacion));
      expect(tipo(await d.auth.renovar(t1.tokenRenovacion)), TipoError.tokenReutilizado);
      expect(tipo(await d.auth.renovar(t2.tokenRenovacion)), TipoError.tokenInvalido, reason: 'familia revocada');
      expect(tipo(await d.auth.renovar('inventado')), TipoError.tokenInvalido);
    });

    test('un usuario suspendido no puede renovar; salir cierra la sesión', () async {
      final t = (await d.auth.entrar(email: 'demo@kaizen.test', contrasena: DatosDemo.contrasenaDemo)).valorONulo!;
      await d.auth.salir(t.tokenRenovacion);
      expect(datos.usuarioActual, isNull);
      expect(tipo(await d.auth.renovar(t.tokenRenovacion)), TipoError.tokenInvalido);
      final t2 = (await d.auth.entrar(email: 'latam@kaizen.test', contrasena: DatosDemo.contrasenaDemo)).valorONulo!;
      datos.usuarios['u-latam']!.suspendido = true;
      expect(tipo(await d.auth.renovar(t2.tokenRenovacion)), TipoError.cuentaSuspendida);
    });

    test('recuperar responde igual siempre; restablecer es de un solo uso y valida la contraseña', () async {
      expect((await d.auth.recuperar('nadie@x.com')).esExito, isTrue);
      expect(datos.ultimoTokenRecuperacion, isNull);
      expect((await d.auth.recuperar('demo@kaizen.test')).esExito, isTrue);
      final token = datos.ultimoTokenRecuperacion!;
      expect(tipo(await d.auth.restablecer(token: token, nueva: 'corta')), TipoError.validacion);
      expect((await d.auth.restablecer(token: token, nueva: 'otra-contrasena-larga')).esExito, isTrue);
      expect(tipo(await d.auth.restablecer(token: token, nueva: 'otra-contrasena-larga')), TipoError.enlaceInvalido);
      expect((await d.auth.entrar(email: 'demo@kaizen.test', contrasena: 'otra-contrasena-larga')).esExito, isTrue);
      expect(
        tipo(await d.auth.restablecer(token: 'inventado', nueva: 'otra-contrasena-larga')),
        TipoError.enlaceInvalido,
      );
    });
  });

  group('hábitos y check-ins', () {
    test('sin sesión: 401', () async {
      expect(tipo(await d.habitos.listar(fecha: hoy)), TipoError.tokenInvalido);
      expect(tipo(await d.categorias.listar()), TipoError.tokenInvalido);
    });

    test('Daniela ve los 5 hábitos del bosquejo de Hoy con sus rachas', () async {
      await entrar('demo@kaizen.test');
      final lista = (await d.habitos.listar(fecha: hoy)).valorONulo!;
      final porNombre = {for (final h in lista) h.nombre: h};
      expect(porNombre.keys, containsAll(['Tomar agua', 'Ejercicio', 'Leer', 'Estudiar inglés', 'Dormir 7 h']));
      expect(porNombre['Tomar agua']!.racha.actual, 21);
      expect(porNombre['Tomar agua']!.hoy!.cumplido, isTrue);
      expect(porNombre['Ejercicio']!.racha.actual, 8);
      expect(porNombre['Leer']!.racha.actual, 34);
      expect(porNombre['Leer']!.hoy!.cumplido, isFalse);
      expect(porNombre['Leer']!.nivel, 3);
      expect(porNombre['Estudiar inglés']!.escaleraActiva, isFalse);
      expect(porNombre['Estudiar inglés']!.hoy!.programado, isTrue, reason: 'lunes es día de L–V');
      expect((await d.categorias.listar()).valorONulo, hasLength(8));
    });

    test('?fecha= fuera de hoy ±1 da 422', () async {
      await entrar('demo@kaizen.test');
      expect(tipo(await d.habitos.listar(fecha: hoy.subtract(const Duration(days: 3)))), TipoError.fechaFueraDeRango);
    });

    test('check-in: sube la racha, es idempotente y reemplaza el del mismo día', () async {
      await entrar('demo@kaizen.test');
      final leer = (await d.habitos.listar(fecha: hoy)).valorONulo!.firstWhere((h) => h.nombre == 'Leer');
      final r = NuevoRegistro(
        id: 'chk-1',
        habitoId: leer.id,
        fecha: hoy,
        cumplido: true,
        origen: OrigenRegistro.manual,
      );
      expect((await d.registros.registrar(r)).valorONulo!.rachaActual, 35);
      expect((await d.registros.registrar(r)).valorONulo!.rachaActual, 35, reason: 'mismo id no duplica');
      final otro = NuevoRegistro(
        id: 'chk-2',
        habitoId: leer.id,
        fecha: hoy,
        cumplido: false,
        origen: OrigenRegistro.manual,
      );
      expect((await d.registros.registrar(otro)).valorONulo!.rachaActual, 34, reason: 'gana el último del día');
      expect(datos.registros[leer.id]![hoy]!.id, 'chk-2');
    });

    test('check-in: hábito ajeno 404, fecha futura 422, archivado 409', () async {
      await entrar('latam@kaizen.test');
      final ajeno = datos.habitos.values.firstWhere((h) => h.usuarioId == 'u-demo');
      NuevoRegistro r(String id, DateTime f) =>
          NuevoRegistro(id: 'x', habitoId: id, fecha: f, cumplido: true, origen: OrigenRegistro.manual);
      expect(tipo(await d.registros.registrar(r(ajeno.id, hoy))), TipoError.noEncontrado);
      final propio = datos.habitos.values.firstWhere((h) => h.usuarioId == 'u-latam');
      expect(
        tipo(await d.registros.registrar(r(propio.id, hoy.add(const Duration(days: 2))))),
        TipoError.fechaFueraDeRango,
      );
      expect(
        (await d.registros.registrar(r(propio.id, hoy.add(const Duration(days: 1))))).esExito,
        isTrue,
        reason: 'hoy+1 sí',
      );
      expect(
        (await d.registros.registrar(r(propio.id, hoy.subtract(const Duration(days: 20))))).esExito,
        isTrue,
        reason: 'días atrasados de la cola',
      );
      await d.habitos.actualizar(propio.id, const CambiosHabito(activo: false));
      expect(tipo(await d.registros.registrar(r(propio.id, hoy))), TipoError.habitoArchivado);
    });

    test('lote: cada elemento aparte (aceptados y rechazados)', () async {
      await entrar('demo@kaizen.test');
      final h = datos.habitos.values.firstWhere((h) => h.usuarioId == 'u-demo');
      final lote = await d.registros.registrarLote([
        NuevoRegistro(id: 'a', habitoId: h.id, fecha: hoy, cumplido: true, origen: OrigenRegistro.offline),
        NuevoRegistro(id: 'b', habitoId: 'no-existe', fecha: hoy, cumplido: true, origen: OrigenRegistro.offline),
      ]);
      final res = lote.valorONulo!.resultados;
      expect(res[0].aceptado, isTrue);
      expect(res[1].aceptado, isFalse);
      expect(res[1].error!.tipo, 'no-encontrado');
      final grande = [
        for (var i = 0; i < 101; i++)
          NuevoRegistro(id: '$i', habitoId: h.id, fecha: hoy, cumplido: true, origen: OrigenRegistro.offline),
      ];
      expect(tipo(await d.registros.registrarLote(grande)), TipoError.validacion);
    });

    test('crear y editar: valida, categoría inactiva, archivar expira la sugerencia', () async {
      await entrar('demo@kaizen.test');
      const nuevo = NuevoHabito(
        nombre: 'Meditar',
        categoriaId: 'cat-meditacion',
        frecuencia: DiasSemana(96),
        meta: 5,
        unidad: 'min',
      );
      final h = (await d.habitos.crear(nuevo)).valorONulo!;
      expect(h.nivel, 1);
      expect(h.racha.actual, 0);
      expect(h.hoy!.programado, isFalse, reason: 'solo fines de semana');
      expect(
        tipo(
          await d.habitos.crear(
            const NuevoHabito(nombre: '', categoriaId: 'cat-meditacion', frecuencia: Diaria(), meta: 0, unidad: ''),
          ),
        ),
        TipoError.validacion,
      );
      datos.categorias[0] = datos.categorias[0].copyWith(activa: false);
      expect(
        tipo(
          await d.habitos.crear(
            NuevoHabito(
              nombre: 'X',
              categoriaId: datos.categorias[0].id,
              frecuencia: const Diaria(),
              meta: 1,
              unidad: 'u',
            ),
          ),
        ),
        TipoError.categoriaInactiva,
      );
      expect(
        tipo(await d.habitos.actualizar(h.id, CambiosHabito(categoriaId: datos.categorias[0].id))),
        TipoError.categoriaInactiva,
      );
      expect(tipo(await d.habitos.actualizar(h.id, CambiosHabito(nombre: 'x' * 61))), TipoError.validacion);
      expect(
        (await d.habitos.actualizar(
          h.id,
          const CambiosHabito(nombre: 'Meditar 5', unidad: 'minutos'),
        )).valorONulo!.unidad,
        'minutos',
      );

      final leer = datos.habitos.values.firstWhere((x) => x.usuarioId == 'u-demo' && x.nombre == 'Leer');
      expect((await d.escalera.sugerencias()).valorONulo, hasLength(1));
      final archivado = (await d.habitos.actualizar(leer.id, const CambiosHabito(activo: false))).valorONulo!;
      expect(archivado.activo, isFalse);
      expect((await d.escalera.sugerencias()).valorONulo, isEmpty, reason: 'la pendiente expiró');
      expect((await d.habitos.listar(fecha: hoy)).valorONulo!.any((x) => x.id == leer.id), isFalse);
      expect((await d.habitos.listar(fecha: hoy, archivados: true)).valorONulo!.any((x) => x.id == leer.id), isTrue);
    });

    test('registros por rango y escalera de un hábito', () async {
      await entrar('demo@kaizen.test');
      final leer = datos.habitos.values.firstWhere((x) => x.usuarioId == 'u-demo' && x.nombre == 'Leer');
      final regs = (await d.habitos.registros(
        leer.id,
        desde: hoy.subtract(const Duration(days: 30)),
        hasta: hoy,
      )).valorONulo!;
      expect(regs, isNotEmpty);
      expect(regs.first.fecha.isBefore(regs.last.fecha), isTrue, reason: 'ordenados por fecha');
      expect(
        tipo(await d.habitos.registros(leer.id, desde: hoy, hasta: hoy.add(const Duration(days: 400)))),
        TipoError.validacion,
      );
      final e = (await d.habitos.escalera(leer.id)).valorONulo!;
      expect(e.niveles.map((n) => n.meta), [7, 8.5, 10]);
      expect(e.niveles.last.hasta, isNull);
      expect(e.sugerenciaPendiente!.metaPropuesta, 11);
      expect(tipo(await d.habitos.obtener('no-existe', fecha: hoy)), TipoError.noEncontrado);
    });
  });

  group('escalera', () {
    test('aceptar sube nivel y meta; responder otra vez da 409', () async {
      await entrar('demo@kaizen.test');
      final s = (await d.escalera.sugerencias()).valorONulo!.single;
      final r = (await d.escalera.responder(s.id, aceptar: true)).valorONulo!;
      expect(r.estado, EstadoSugerencia.aceptada);
      expect(r.nivel, 4);
      expect(r.metaNueva, 11);
      expect(tipo(await d.escalera.responder(s.id, aceptar: false)), TipoError.sugerenciaResuelta);
      final e = (await d.habitos.escalera(s.habitoId)).valorONulo!;
      expect(e.nivelActual, 4);
      expect(e.niveles.last.meta, 11);
      expect(e.historial.single.estado, EstadoSugerencia.aceptada);
      expect(tipo(await d.escalera.responder('no-existe', aceptar: true)), TipoError.noEncontrado);
    });

    test('"Mantener" no cambia la meta', () async {
      await entrar('latam@kaizen.test');
      final s = (await d.escalera.sugerencias()).valorONulo!.single;
      final r = (await d.escalera.responder(s.id, aceptar: false)).valorONulo!;
      expect(r.estado, EstadoSugerencia.rechazada);
      expect(r.metaNueva, isNull);
      expect(datos.habitos[s.habitoId]!.meta, 15);
    });
  });

  group('cápsulas', () {
    test('la de 21 días de Daniela se abre; la de 66 responde "Racha X de 66"', () async {
      await entrar('demo@kaizen.test');
      final lista = (await d.capsulas.listar()).valorONulo!;
      final agua = lista.firstWhere((c) => c.rachaObjetivo == 21);
      final ejercicio = lista.firstWhere((c) => c.rachaObjetivo == 66);
      expect(agua.sePuedeAbrir, isTrue);
      expect(ejercicio.sePuedeAbrir, isFalse);
      final sellada = await d.capsulas.abrir(ejercicio.id);
      expect(tipo(sellada), TipoError.capsulaSellada);
      expect(sellada.errorONulo!.problema!.entero('racha'), 8);
      expect(sellada.errorONulo!.problema!.entero('objetivo'), 66);
      final abierta = (await d.capsulas.abrir(agua.id)).valorONulo!;
      expect(abierta.mensaje, contains('sí pudiste'));
      expect(
        (await d.capsulas.abrir(agua.id)).valorONulo!.mensaje,
        abierta.mensaje,
        reason: 'abrir otra vez devuelve el mensaje',
      );
      expect((await d.capsulas.listar(estado: EstadoCapsula.abierta)).valorONulo, hasLength(1));
      expect(tipo(await d.capsulas.abrir('no-existe')), TipoError.noEncontrado);
    });

    test('crear: 4096 bytes y objetivo 7/21/66; nunca guarda la foto, solo tiene_foto', () async {
      await entrar('demo@kaizen.test');
      final h = datos.habitos.values.firstWhere((x) => x.usuarioId == 'u-demo');
      final c = await d.capsulas.crear(
        NuevaCapsula(habitoId: h.id, mensaje: 'Hola', rachaObjetivo: 7, tieneFoto: true),
      );
      expect(c.valorONulo!.tieneFoto, isTrue);
      expect(c.valorONulo!.progreso, 0);
      expect(
        tipo(
          await d.capsulas.crear(
            NuevaCapsula(habitoId: h.id, mensaje: '😀' * 1025, rachaObjetivo: 7, tieneFoto: false),
          ),
        ),
        TipoError.validacion,
      );
      expect(
        tipo(await d.capsulas.crear(NuevaCapsula(habitoId: h.id, mensaje: 'x', rachaObjetivo: 30, tieneFoto: false))),
        TipoError.validacion,
      );
    });
  });

  group('progreso, señales y laboratorio', () {
    test('progreso por semana, mes y año (semana de lunes a domingo)', () async {
      await entrar('demo@kaizen.test');
      final s = (await d.progreso.obtener(Periodo.semana, fecha: hoy)).valorONulo!;
      expect(s.desde, DateTime.utc(2026, 11, 23));
      expect(s.hasta, DateTime.utc(2026, 11, 29));
      expect(s.habitosActivos, 5);
      expect(s.porDia.single.programados, 5);
      expect(s.porDia.single.cumplidos, 2, reason: 'Tomar agua y Ejercicio, como en el bosquejo "2 de 5"');
      expect(s.porDia.single.cumplimiento, 40);
      expect(s.mejoresRachas.first.categoria, 'Lectura');
      expect(s.crecimientoMetas, greaterThan(0));
      final m = (await d.progreso.obtener(Periodo.mes, fecha: hoy)).valorONulo!;
      expect(m.porDia, hasLength(23));
      expect((await d.progreso.obtener(Periodo.anio, fecha: hoy)).valorONulo!.hasta, DateTime.utc(2026, 12, 31));
    });

    test('señales exigen consentimiento (403) y se reemplazan el mismo día', () async {
      await entrar('nuevo@kaizen.test');
      expect(tipo(await d.senales.guardar(Senal(fecha: hoy, animo: 3, energia: 3))), TipoError.consentimientoRequerido);
      await entrar('demo@kaizen.test');
      await d.senales.guardar(Senal(fecha: hoy, animo: 3, energia: 3));
      await d.senales.guardar(Senal(fecha: hoy, animo: 5, energia: 4));
      final lista = (await d.senales.listar(desde: hoy, hasta: hoy)).valorONulo!;
      expect(lista.single.animo, 5);
      expect(tipo(await d.senales.guardar(Senal(fecha: hoy, animo: 6, energia: 4))), TipoError.validacion);
    });

    test('laboratorio: perspectivas, datos insuficientes y analítica caída (503)', () async {
      await entrar('demo@kaizen.test');
      final p = (await d.laboratorio.perspectivas()).valorONulo!;
      expect(p.datosSuficientes, isTrue);
      expect(p.perspectivas.first.categoria, 'Ejercicio');
      expect(p.perspectivas.first.habitos.single.nombre, 'Ejercicio');
      expect(p.semana, '2026-W47');
      datos.analiticaDisponible = false;
      expect(tipo(await d.laboratorio.perspectivas()), TipoError.analiticaNoDisponible);
      datos.analiticaDisponible = true;
      await entrar('nuevo@kaizen.test');
      final n = (await d.laboratorio.perspectivas(semana: '2026-W46')).valorONulo!;
      expect(n.datosSuficientes, isFalse);
      expect(n.perspectivas, isEmpty);
    });
  });

  group('cuenta (ARCO)', () {
    test('ver, cambiar nombre y contraseña', () async {
      await entrar('demo@kaizen.test');
      expect((await d.cuenta.obtener()).valorONulo!.email, 'demo@kaizen.test');
      expect((await d.cuenta.cambiarNombre('Dani')).valorONulo!.nombre, 'Dani');
      expect(tipo(await d.cuenta.cambiarNombre('')), TipoError.validacion);
      expect(
        tipo(await d.cuenta.cambiarContrasena(actual: 'mala', nueva: 'una-contrasena-nueva-larga')),
        TipoError.credencialesInvalidas,
      );
      expect(
        tipo(await d.cuenta.cambiarContrasena(actual: DatosDemo.contrasenaDemo, nueva: 'corta')),
        TipoError.validacion,
      );
      expect(
        (await d.cuenta.cambiarContrasena(
          actual: DatosDemo.contrasenaDemo,
          nueva: 'una-contrasena-nueva-larga',
        )).esExito,
        isTrue,
      );
    });

    test('retirar el consentimiento borra las señales; exportar no incluye mensajes sellados', () async {
      await entrar('demo@kaizen.test');
      final r = (await d.cuenta.cambiarConsentimiento(senales: false)).valorONulo!;
      expect(r.senalesBorradas, 30);
      expect((await d.cuenta.cambiarConsentimiento(senales: true)).valorONulo!.senales, isTrue);
      final datosExportados = (await d.cuenta.exportarDatos()).valorONulo!;
      expect(
        datosExportados.keys,
        containsAll(['cuenta', 'habitos', 'registros', 'niveles', 'sugerencias', 'senales', 'capsulas']),
      );
      expect((datosExportados['capsulas'] as List).every((c) => !(c as Map).containsKey('mensaje')), isTrue);
    });

    test('eliminar la cuenta exige la contraseña y borra todo', () async {
      await entrar('latam@kaizen.test');
      expect(tipo(await d.cuenta.eliminar(contrasena: 'mala')), TipoError.credencialesInvalidas);
      expect((await d.cuenta.eliminar(contrasena: DatosDemo.contrasenaDemo)).esExito, isTrue);
      expect(datos.usuarios.containsKey('u-latam'), isFalse);
      expect(datos.habitos.values.any((h) => h.usuarioId == 'u-latam'), isFalse);
      expect(
        tipo(await d.auth.entrar(email: 'latam@kaizen.test', contrasena: DatosDemo.contrasenaDemo)),
        TipoError.credencialesInvalidas,
      );
    });
  });

  group('admin', () {
    test('un usuario normal recibe 403', () async {
      await entrar('demo@kaizen.test');
      expect(tipo(await d.admin.metricas()), TipoError.rolInsuficiente);
      expect(tipo(await d.admin.usuarios(const FiltroUsuarios())), TipoError.rolInsuficiente);
    });

    test('usuarios enmascarados, paginados, con filtros y búsqueda exacta', () async {
      await entrar('admin@kaizen.test');
      final p1 = (await d.admin.usuarios(const FiltroUsuarios())).valorONulo!;
      expect(p1.total, 50);
      expect(p1.elementos, hasLength(20));
      expect(p1.paginas, 3);
      expect(p1.elementos.every((u) => u.emailMascara.contains('***')), isTrue);
      final latam = (await d.admin.usuarios(const FiltroUsuarios(region: 'LATAM'))).valorONulo!;
      expect(latam.elementos.every((u) => u.region == 'LATAM'), isTrue);
      expect((await d.admin.usuarios(const FiltroUsuarios(email: 'DEMO@kaizen.test'))).valorONulo!.total, 1);
      expect(
        (await d.admin.usuarios(const FiltroUsuarios(email: 'demo'))).valorONulo!.total,
        0,
        reason: 'sin búsqueda parcial',
      );
      expect((await d.admin.usuarios(const FiltroUsuarios(suspendido: true))).valorONulo!.total, 1);
      expect(AdminRepositoryFake.enmascararNombre('Daniela Demo'), 'D****** D***');
      expect(AdminRepositoryFake.enmascararCorreo('demo@kaizen.test'), 'd***@kaizen.test');
    });

    test('suspender: motivo 3–200, nunca a un admin; reactivar', () async {
      await entrar('admin@kaizen.test');
      expect(tipo(await d.admin.cambiarSuspension('u-demo', suspendido: true, motivo: 'no')), TipoError.validacion);
      expect(
        tipo(await d.admin.cambiarSuspension('u-admin', suspendido: true, motivo: 'Prueba')),
        TipoError.rolInsuficiente,
      );
      expect(
        tipo(await d.admin.cambiarSuspension('nadie', suspendido: true, motivo: 'Prueba')),
        TipoError.noEncontrado,
      );
      final s = (await d.admin.cambiarSuspension('u-demo', suspendido: true, motivo: 'Publica spam')).valorONulo!;
      expect(s.suspendido, isTrue);
      expect(s.suspensionMotivo, 'Publica spam');
      expect((await d.admin.cambiarSuspension('u-demo', suspendido: false)).valorONulo!.suspendido, isFalse);
    });

    test('categorías: crear, duplicado sin importar mayúsculas, desactivar', () async {
      await entrar('admin@kaizen.test');
      expect((await d.admin.categorias()).valorONulo, hasLength(8));
      final m = (await d.admin.crearCategoria('Música')).valorONulo!;
      expect(tipo(await d.admin.crearCategoria('música')), TipoError.nombreDuplicado);
      expect(tipo(await d.admin.crearCategoria('M')), TipoError.validacion);
      expect((await d.admin.actualizarCategoria(m.id, activa: false)).valorONulo!.activa, isFalse);
      expect(tipo(await d.admin.actualizarCategoria(m.id, nombre: 'Salud')), TipoError.nombreDuplicado);
      expect(tipo(await d.admin.actualizarCategoria('no', activa: true)), TipoError.noEncontrado);
      await entrar('demo@kaizen.test');
      expect(
        (await d.categorias.listar()).valorONulo!.any((c) => c.nombre == 'Música'),
        isFalse,
        reason: 'solo activas',
      );
    });

    test('métricas e indicadores I1–I6 con su forma; 404 y 503', () async {
      await entrar('admin@kaizen.test');
      expect((await d.admin.metricas()).valorONulo!.resumen.categoriasActivas, 8);
      for (final c in ['I1', 'I2', 'I3', 'I4', 'I5', 'I6']) {
        final i = (await d.admin.indicador(c)).valorONulo!;
        expect(i.datosSinteticos, isTrue);
        expect(i.series, isNotEmpty, reason: c);
      }
      expect(
        (await d.admin.indicador('I2')).valorONulo!.series.first.keys,
        containsAll(['min', 'q1', 'mediana', 'q3', 'max', 'n']),
      );
      expect(tipo(await d.admin.indicador('I9')), TipoError.noEncontrado);
      datos.analiticaDisponible = false;
      expect(tipo(await d.admin.indicador('I1')), TipoError.analiticaNoDisponible);
    });
  });

  test('fallarSiguiente simula un error una sola vez; la latencia se respeta', () async {
    await entrar('demo@kaizen.test');
    datos.fallarSiguiente(const ErrorApp(TipoError.primarioNoDisponible));
    expect(tipo(await d.categorias.listar()), TipoError.primarioNoDisponible);
    expect((await d.categorias.listar()).esExito, isTrue);
    datos.latencia = const Duration(milliseconds: 30);
    final reloj = Stopwatch()..start();
    await d.categorias.listar();
    expect(reloj.elapsedMilliseconds, greaterThanOrEqualTo(25));
    expect(datos.totalRegistros, greaterThan(300));
  });
}
