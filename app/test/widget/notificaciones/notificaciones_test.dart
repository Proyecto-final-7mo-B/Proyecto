import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/config/dependencias.dart';
import 'package:kaizen/data/fake/datos_demo.dart';
import 'package:kaizen/data/services/avisos/notificador.dart';
import 'package:kaizen/domain/models/avisos.dart';
import 'package:kaizen/routing/rutas.dart';
import 'package:kaizen/ui/core/adaptativo/busqueda.dart';
import 'package:kaizen/ui/core/adaptativo/plataforma.dart';
import 'package:kaizen/ui/notificaciones/widgets/pantalla_notificaciones.dart';

import '../../helpers/app.dart';

Future<void> ver(WidgetTester tester, Finder f, {bool arriba = false}) async {
  final lista = find.descendant(of: find.byType(PantallaNotificaciones), matching: find.byType(Scrollable));
  await tester.scrollUntilVisible(f, arriba ? -200 : 200, scrollable: lista.first);
  await tester.pumpAndSettle();
}

Future<void> tocar(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

/// La próxima hora que "elige" el usuario.
Hora? _siguienteHora;

/// La próxima vez que se abra el reloj, el usuario elige [hora]:[minuto].
void elegir(int hora, int minuto) => _siguienteHora = (hora: hora, minuto: minuto);

/// El interruptor de la fila con [titulo].
Finder interruptor(String titulo) => find.descendant(
  of: find.ancestor(of: find.text(titulo), matching: find.byType(Row)).first,
  matching: find.byType(Switch),
);

Dependencias _deps({Notificador? notificador}) => Dependencias.fake(
  datos: DatosDemo(reloj: () => ahoraPrueba),
  notificador: notificador,
);

void main() {
  setUp(() {
    _siguienteHora = null;
    PantallaNotificaciones.selectorHora = (_, inicial) async {
      final h = _siguienteHora;
      _siguienteHora = null;
      return h;
    };
  });
  tearDown(() => PantallaNotificaciones.selectorHora = elegirHoraDelSistema);

  group('Notificaciones', () {
    testWidgets('la hora se elige con el reloj del sistema (cancelar no cambia nada)', (tester) async {
      PantallaNotificaciones.selectorHora = elegirHoraDelSistema;
      await montarApp(tester, ubicacion: Rutas.notificaciones);
      await tocar(tester, find.text('Agregar aviso'));
      await tocar(tester, find.byKey(const ValueKey('hora-aviso')));
      expect(find.byType(TimePickerDialog), findsOneWidget);
      await tester.tap(find.descendant(of: find.byType(TimePickerDialog), matching: find.text('Cancelar')));
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(DialogoAviso), matching: find.text('09:00')), findsOneWidget);
    });

    testWidgets('se abre desde Perfil y muestra cada sección', (tester) async {
      await montarApp(tester, ubicacion: Rutas.perfil);
      await tocar(tester, find.text('Notificaciones'));
      expect(find.byType(PantallaNotificaciones), findsOneWidget);
      expect(find.text('Tus avisos viven en este dispositivo'), findsOneWidget);
      expect(find.text('Mis avisos'), findsOneWidget);
      expect(find.text('Aún no tienes avisos propios.'), findsOneWidget);
      await ver(tester, find.text('Recordatorios de tus hábitos'));
      await ver(tester, find.text('Leer'));
      await ver(tester, find.text('Avisos automáticos'));
      await ver(tester, find.text('Racha en riesgo'));
      expect(find.text('20:00'), findsOneWidget);
      await ver(tester, find.text('Resumen semanal'));
      expect(find.text('18:00'), findsOneWidget);
      await ver(tester, find.text('Horas de silencio'));
      expect(find.text('Desde 22:00'), findsOneWidget);
      expect(find.text('Hasta 08:00'), findsOneWidget);
      await ver(tester, find.text('Próximos avisos'));
      expect(find.textContaining(RegExp(r'^(Hoy|Mañana) \d\d:\d\d$')), findsWidgets);
      await ver(tester, find.text('Cómo funcionan'));
      expect(find.textContaining('66 días'), findsOneWidget);
      expect(find.textContaining('F0'), findsNothing, reason: 'sin fuentes fuera del detalle del hábito');
    });

    testWidgets('"Mis avisos": programar uno a las 22:20 de lunes a viernes, editarlo y quitarlo', (tester) async {
      final deps = _deps();
      await montarApp(tester, ubicacion: Rutas.notificaciones, dependencias: deps);
      await tocar(tester, find.text('Agregar aviso'));
      expect(find.text('09:00'), findsOneWidget, reason: 'hora inicial');
      elegir(22, 20);
      await tocar(tester, find.byKey(const ValueKey('hora-aviso')));
      expect(find.text('22:20'), findsOneWidget);
      // Quita sábado y domingo.
      final dialogo = find.byType(DialogoAviso);
      await tocar(tester, find.descendant(of: dialogo, matching: find.text('Sáb')));
      await tocar(tester, find.descendant(of: dialogo, matching: find.text('Dom')));
      await tester.pumpAndSettle();
      await tester.enterText(find.descendant(of: dialogo, matching: find.byType(TextField)), 'Prepara la mochila');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('Prepara la mochila'), findsWidgets);
      final prefs = await deps.avisos.preferencias();
      expect(prefs.personales.single.hora, (hora: 22, minuto: 20));
      expect(prefs.personales.single.dias, 31);
      expect(deps.avisos.plan.where((a) => a.tipo == TipoAviso.personal), hasLength(5), reason: 'L–V, 7 días');

      // Editar: tocar la fila abre el diálogo con lo guardado.
      await tocar(tester, find.descendant(of: find.byType(ListTile), matching: find.text('Prepara la mochila')).first);
      expect(find.text('Editar aviso'), findsOneWidget);
      expect(find.text('22:20'), findsWidgets);
      await tester.enterText(find.descendant(of: find.byType(DialogoAviso), matching: find.byType(TextField)), 'Agua');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect((await deps.avisos.preferencias()).personales.single.texto, 'Agua');

      // Apagar y quitar.
      final fila = find.byKey(ValueKey('aviso-${prefs.personales.single.id}'));
      await tester.tap(find.descendant(of: fila, matching: find.byType(Switch)));
      await tester.pumpAndSettle();
      expect(deps.avisos.plan.where((a) => a.tipo == TipoAviso.personal), isEmpty);
      await tester.tap(find.descendant(of: fila, matching: find.byIcon(Icons.delete_outline)));
      await tester.pumpAndSettle();
      expect(find.text('Aún no tienes avisos propios.'), findsOneWidget);
    });

    testWidgets('siempre queda al menos un día; Cancelar no agrega nada', (tester) async {
      final deps = _deps();
      await montarApp(tester, ubicacion: Rutas.notificaciones, dependencias: deps);
      await tocar(tester, find.text('Agregar aviso'));
      final dialogo = find.byType(DialogoAviso);
      for (final d in ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom']) {
        await tocar(tester, find.descendant(of: dialogo, matching: find.text(d)));
      }
      await tester.pumpAndSettle();
      final guardar = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Guardar'));
      expect(guardar.onPressed, isNotNull, reason: 'el último día no se puede quitar');
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect((await deps.avisos.preferencias()).personales, isEmpty);
    });

    testWidgets('recordatorio de un hábito con la hora que quieras; la racha en riesgo a otra hora', (tester) async {
      final deps = _deps();
      await montarApp(tester, ubicacion: Rutas.notificaciones, dependencias: deps);
      final leer = deps.datosDemo!.habitosDe('u-demo').firstWhere((h) => h.nombre == 'Leer');
      final fila = find.byKey(ValueKey('recordatorio-${leer.id}'));
      await ver(tester, fila);
      elegir(21, 35);
      await tocar(tester, fila);
      expect(find.descendant(of: fila, matching: find.text('21:35')), findsOneWidget);
      expect(await deps.almacenLocal.recordatorio(leer.id), (hora: 21, minuto: 35));
      await tocar(tester, find.descendant(of: fila, matching: find.byIcon(Icons.alarm_off)));
      expect(await deps.almacenLocal.recordatorio(leer.id), isNull);

      await ver(tester, find.text('20:00'));
      elegir(19, 30);
      await tocar(tester, find.text('20:00'));
      expect((await deps.avisos.preferencias()).horaRachaEnRiesgo, (hora: 19, minuto: 30));
      expect(find.text('19:30'), findsOneWidget);
    });

    testWidgets('interruptores y silencio se guardan', (tester) async {
      final deps = _deps();
      await montarApp(tester, ubicacion: Rutas.notificaciones, dependencias: deps);
      await ver(tester, find.text('Nuevo micro-paso'));
      await tocar(tester, interruptor('Nuevo micro-paso'));
      expect((await deps.avisos.preferencias()).microPaso, isFalse);
      await ver(tester, find.text('Resumen semanal'));
      await tocar(tester, interruptor('Resumen semanal'));
      expect((await deps.avisos.preferencias()).resumenSemanal, isFalse);
      expect(find.text('18:00'), findsNothing, reason: 'apagado, sin hora');
      await tocar(tester, interruptor('Racha en riesgo'));
      expect((await deps.avisos.preferencias()).rachaEnRiesgo, isFalse);
      await ver(tester, find.text('Recordatorios de tus hábitos'), arriba: true);
      await tocar(tester, interruptor('Recordatorios de tus hábitos'));
      expect((await deps.avisos.preferencias()).recordatorios, isFalse);
      await ver(tester, find.text('Desde 22:00'));
      elegir(23, 0);
      await tocar(tester, find.text('Desde 22:00'));
      expect(find.text('Desde 23:00'), findsOneWidget);
      elegir(7, 15);
      await tocar(tester, find.text('Hasta 08:00'));
      expect((await deps.avisos.preferencias()).silencioHasta, (hora: 7, minuto: 15));
    });

    testWidgets('resumen semanal: otro día', (tester) async {
      final deps = _deps();
      await montarApp(tester, ubicacion: Rutas.notificaciones, dependencias: deps);
      await ver(tester, find.text('Domingo'));
      await tocar(tester, find.text('Domingo'));
      await tester.tap(find.text('Sábado').last);
      await tester.pumpAndSettle();
      expect((await deps.avisos.preferencias()).diaResumen, DateTime.saturday);
    });

    testWidgets('en escritorio y web lo dice: los avisos llegan en el teléfono', (tester) async {
      await montarApp(
        tester,
        ubicacion: Rutas.notificaciones,
        dependencias: _deps(notificador: NotificadorEnMemoria(disponible: false)),
      );
      expect(find.textContaining('En la computadora y en la web no hay notificaciones del sistema'), findsOneWidget);
    });

    testWidgets('sin hora exacta lo explica y ofrece permitirla', (tester) async {
      final n = NotificadorEnMemoria(exactaPermitida: false);
      await montarApp(
        tester,
        ubicacion: Rutas.notificaciones,
        dependencias: _deps(notificador: n),
      );
      expect(find.textContaining('lleguen al minuto'), findsOneWidget);
      expect(find.text('Mis avisos'), findsOneWidget);
      await tocar(tester, find.text('Permitir hora exacta'));
      expect(n.exactaPermitida, isTrue);
      expect(find.byKey(const ValueKey('hora-exacta')), findsNothing);
    });

    testWidgets('sin permiso lo explica', (tester) async {
      final deps = _deps(notificador: NotificadorEnMemoria(permisoConcedido: false));
      await montarApp(tester, ubicacion: Rutas.notificaciones, dependencias: deps);
      await tocar(tester, find.text('Agregar aviso'));
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();
      expect(find.byType(DialogoAviso), findsNothing);
      expect(await deps.avisos.preferencias(), isA<PreferenciasAvisos>());
      await ver(tester, find.textContaining('Sin permiso de notificaciones'), arriba: true);
      expect(find.textContaining('Sin permiso de notificaciones'), findsOneWidget);
    });

    testWidgets('Ctrl K la encuentra en escritorio', (tester) async {
      await montarApp(tester, plataforma: Plataforma.escritorio, tamano: const Size(1280, 800));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(of: find.byType(PaletaBusqueda), matching: find.byType(TextField)),
        'notif',
      );
      await tester.pump();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.byType(PantallaNotificaciones), findsOneWidget);
    });
  });
}
