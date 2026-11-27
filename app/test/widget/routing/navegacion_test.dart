import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/routing/rutas.dart';
import 'package:kaizen/ui/core/adaptativo/plataforma.dart';
import 'package:kaizen/ui/core/adaptativo/shell_escritorio.dart';
import 'package:kaizen/ui/core/adaptativo/shell_movil.dart';
import 'package:kaizen/ui/core/adaptativo/shell_web.dart';
import 'package:kaizen/ui/core/widgets/avatar_usuario.dart';
import 'package:kaizen/ui/dev/galeria_componentes.dart';
import 'package:kaizen/ui/habitos/widgets/pantalla_habitos.dart';
import 'package:kaizen/ui/hoy/widgets/pantalla_hoy.dart';
import 'package:kaizen/ui/auth/widgets/pantalla_entrar.dart';

import '../../helpers/app.dart';

const movil = Size(390, 844);
const mediano = Size(900, 700);
const escritorio = Size(1280, 800);
const web = Size(1440, 900);

void main() {
  group('guardas en la app', () {
    testWidgets('sin sesión abre la entrada; al entrar llega a Hoy', (tester) async {
      await montarApp(tester, usuario: null);
      expect(find.byType(PantallaEntrar), findsOneWidget);
      expect(find.byType(ShellMovil), findsNothing);

      await entrarCon(tester);
      expect(find.byType(ShellMovil), findsOneWidget);
      expect(find.byType(PantallaHoy), findsOneWidget);
    });

    testWidgets('un enlace profundo sin sesión vuelve a su destino después de entrar', (tester) async {
      final deps = dependenciasPrueba();
      final leer = deps.datosDemo!.habitosDe('u-demo').firstWhere((h) => h.nombre == 'Leer');
      await montarApp(tester, usuario: null, ubicacion: Rutas.editarHabito(leer.id), dependencias: deps);
      await entrarCon(tester);
      expect(find.text('Editar hábito'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Leer'), findsOneWidget);
    });

    testWidgets('un usuario normal que abre /admin termina en Hoy', (tester) async {
      await montarApp(tester, plataforma: Plataforma.escritorio, tamano: escritorio, ubicacion: Rutas.admin);
      expect(find.text('Panel de administración'), findsNothing);
      expect(find.byType(PantallaHoy), findsOneWidget);
    });

    testWidgets('si la sesión se cierra desde fuera, vuelve a la entrada', (tester) async {
      final sesion = await montarApp(tester);
      sesion.cerrar();
      await tester.pumpAndSettle();
      expect(find.byType(PantallaEntrar), findsOneWidget);
    });

    testWidgets('cerrar sesión desde el perfil', (tester) async {
      await montarApp(tester, ubicacion: Rutas.perfil);
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.byType(PantallaEntrar), findsOneWidget);
    });

    testWidgets('ruta inexistente muestra "No encontramos esa página" y regresa a Hoy', (tester) async {
      await montarApp(tester, ubicacion: '/no-existe');
      expect(find.text('No encontramos esa página'), findsOneWidget);
      await tester.tap(find.text('Ir a Hoy'));
      await tester.pumpAndSettle();
      expect(find.byType(ShellMovil), findsOneWidget);
    });

    testWidgets('restablecer se abre sin sesión y nunca muestra el token', (tester) async {
      await montarApp(tester, usuario: null, ubicacion: '/restablecer?token=secreto123');
      expect(find.text('Nueva contraseña'), findsOneWidget);
      expect(find.textContaining('secreto123'), findsNothing);
      await montarApp(tester, usuario: null, ubicacion: Rutas.restablecer);
      expect(find.text('El enlace no es válido o ya venció.'), findsOneWidget);
      await tester.tap(find.text('Ir a entrar'));
      await tester.pumpAndSettle();
      expect(find.byType(PantallaEntrar), findsOneWidget);
    });

    testWidgets('la galería de componentes solo existe en depuración', (tester) async {
      await montarApp(tester, usuario: null, ubicacion: Rutas.componentes);
      expect(find.byType(GaleriaComponentes), findsOneWidget);
      await montarApp(tester, usuario: null, ubicacion: Rutas.componentes, dev: false);
      expect(find.byType(GaleriaComponentes), findsNothing);
      expect(find.byType(PantallaEntrar), findsOneWidget);
      expect(find.text('Cuentas de prueba (solo en desarrollo)'), findsNothing, reason: 'en release no hay atajos');
    });

    testWidgets('desde la entrada se abre la galería y se puede regresar', (tester) async {
      await montarApp(tester, usuario: null);
      await tester.ensureVisible(find.text('Ver componentes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver componentes'));
      await tester.pumpAndSettle();
      expect(find.byType(GaleriaComponentes), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(PantallaEntrar), findsOneWidget);
    });

    testWidgets('cada ruta del plan abre su pantalla', (tester) async {
      final casos = {
        Rutas.habitos: 'Hábitos',
        Rutas.nuevoHabito: 'Nuevo hábito',
        Rutas.escaleraHabito('7'): 'Escalera del hábito',
        Rutas.progreso: 'Progreso',
        Rutas.miSemana: 'Mi semana',
        Rutas.escalera: 'Escalera Kaizen',
        Rutas.laboratorio: 'Laboratorio',
        Rutas.capsulas: 'Cápsula Kaizen',
        Rutas.nuevaCapsulaDe('9'): 'Nueva cápsula',
        Rutas.privacidad: 'Privacidad',
      };
      for (final MapEntry(key: ruta, value: titulo) in casos.entries) {
        await montarApp(tester, plataforma: Plataforma.escritorio, tamano: escritorio, ubicacion: ruta);
        expect(find.text(titulo), findsWidgets, reason: ruta);
      }
      await montarApp(
        tester,
        plataforma: Plataforma.web,
        tamano: web,
        usuario: adminPrueba,
        ubicacion: Rutas.indicadores,
      );
      expect(find.text('Dashboard de indicadores'), findsOneWidget);
    });
  });

  group('shell según ancho y plataforma', () {
    final casos = <(Plataforma, Size, Type, bool?)>[
      (Plataforma.movil, movil, ShellMovil, null),
      (Plataforma.escritorio, const Size(400, 800), ShellMovil, null),
      (Plataforma.web, const Size(400, 800), ShellMovil, null),
      (Plataforma.escritorio, mediano, ShellEscritorio, false),
      (Plataforma.web, mediano, ShellEscritorio, false),
      (Plataforma.movil, mediano, ShellEscritorio, false),
      (Plataforma.escritorio, escritorio, ShellEscritorio, true),
      (Plataforma.movil, escritorio, ShellEscritorio, true),
      (Plataforma.web, web, ShellWeb, null),
    ];
    for (final (plataforma, tamano, tipo, extendido) in casos) {
      testWidgets(
        '${plataforma.name} a ${tamano.width.toInt()} px → $tipo${extendido == null ? '' : ' (extendido: $extendido)'}',
        (tester) async {
          await montarApp(tester, plataforma: plataforma, tamano: tamano);
          expect(find.byType(tipo), findsOneWidget);
          if (extendido != null) {
            expect(tester.widget<ShellEscritorio>(find.byType(ShellEscritorio)).extendido, extendido);
          }
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('sin desbordes en 320 px ni en el límite de 600 px', (tester) async {
      await montarApp(tester, tamano: const Size(320, 640));
      expect(tester.takeException(), isNull);
      await montarApp(tester, plataforma: Plataforma.escritorio, tamano: const Size(600, 640), usuario: adminPrueba);
      expect(tester.takeException(), isNull);
    });
  });

  group('barra inferior (móvil)', () {
    testWidgets('5 destinos; tocar uno navega y queda elegido', (tester) async {
      final manejador = tester.ensureSemantics();
      await montarApp(tester);
      for (final e in ['Hoy', 'Hábitos', 'Progreso', 'Lab', 'Perfil']) {
        expect(find.descendant(of: find.byType(BarraInferior), matching: find.text(e)), findsOneWidget);
      }
      await tester.tap(find.text('Hábitos'));
      await tester.pumpAndSettle();
      expect(find.byType(PantallaHabitos), findsOneWidget);
      expect(
        tester.getSemantics(find.descendant(of: find.byType(BarraInferior), matching: find.text('Hábitos'))),
        isSemantics(label: 'Hábitos', isButton: true, isSelected: true),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      manejador.dispose();
    });

    testWidgets('un admin en móvil no ve el panel', (tester) async {
      await montarApp(tester, usuario: adminPrueba);
      expect(find.text('Admin'), findsNothing);
    });
  });

  group('riel lateral (escritorio)', () {
    testWidgets('extendido: marca, 6 secciones y usuario; Admin solo para admin', (tester) async {
      await montarApp(tester, plataforma: Plataforma.escritorio, tamano: escritorio);
      for (final e in ['Hoy', 'Hábitos', 'Progreso', 'Escalera', 'Laboratorio', 'Cápsulas']) {
        expect(
          find.descendant(of: find.byType(RielLateral), matching: find.text(e)),
          findsOneWidget,
          reason: e,
        );
      }
      expect(find.text('Admin'), findsNothing);
      expect(find.text('Jael'), findsOneWidget);
      expect(find.textContaining('Región'), findsNothing, reason: 'la región no se muestra');

      await montarApp(tester, plataforma: Plataforma.escritorio, tamano: escritorio, usuario: adminPrueba);
      await tester.tap(find.text('Admin'));
      await tester.pumpAndSettle();
      expect(find.text('Panel de administración'), findsOneWidget);
    });

    testWidgets('el usuario abre el perfil; el logo regresa a Hoy', (tester) async {
      await montarApp(tester, plataforma: Plataforma.escritorio, tamano: escritorio, ubicacion: Rutas.escalera);
      await tester.tap(find.text('Jael'));
      await tester.pumpAndSettle();
      expect(find.text('Perfil'), findsOneWidget);
      await tester.tap(find.text('Kaizen'));
      await tester.pumpAndSettle();
      expect(find.byType(PantallaHoy), findsOneWidget);
    });

    testWidgets('angosto: íconos con nombre corto y avatar', (tester) async {
      await montarApp(tester, plataforma: Plataforma.escritorio, tamano: mediano);
      expect(tester.getSize(find.byType(RielLateral)).width, ShellEscritorio.anchoAngosto);
      await tester.tap(find.text('Cápsulas'));
      await tester.pumpAndSettle();
      expect(find.text('Cápsula Kaizen'), findsOneWidget);
      expect(find.text('Región MX Norte'), findsNothing);
    });
  });

  group('barra superior (web)', () {
    testWidgets('pestañas, Nuevo hábito y avatar', (tester) async {
      await montarApp(tester, plataforma: Plataforma.web, tamano: web, usuario: adminPrueba);
      expect(find.descendant(of: find.byType(BarraSuperior), matching: find.text('Admin')), findsOneWidget);
      await tester.tap(find.text('Progreso'));
      await tester.pumpAndSettle();
      expect(find.text('Esta pantalla llega en el paso 12 del plan.'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Nuevo hábito'));
      await tester.pumpAndSettle();
      expect(find.text('Nuevo hábito'), findsNWidgets(2), reason: 'botón y título');
      await tester.tap(find.byType(AvatarUsuario));
      await tester.pumpAndSettle();
      expect(find.text('Cerrar sesión'), findsOneWidget);
    });
  });
}
