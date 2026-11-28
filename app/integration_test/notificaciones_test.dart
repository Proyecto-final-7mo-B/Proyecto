import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kaizen/app.dart';
import 'package:kaizen/config/dependencias.dart';
import 'package:kaizen/config/entorno.dart';
import 'package:kaizen/data/fake/datos_demo.dart';
import 'package:kaizen/data/services/avisos/notificador.dart';
import 'package:kaizen/domain/models/avisos.dart';
import 'package:kaizen/domain/models/frecuencia.dart';
import 'package:kaizen/routing/rutas.dart';
import 'package:kaizen/ui/core/widgets/campo_validado.dart';
import 'package:kaizen/ui/core/widgets/fila_habito.dart';
import 'package:kaizen/ui/hoy/widgets/pantalla_hoy.dart';
import 'package:kaizen/ui/notificaciones/widgets/pantalla_notificaciones.dart';

/// Flujo del Paso 10 en la app real: entrar (se planean los avisos) → recordatorio de "Leer" a las 21:00 → marcar
/// "Leer" quita el de hoy → programar un aviso propio a las 22:20 de lunes a viernes → salir no deja nada programado.
/// `flutter test integration_test/notificaciones_test.dart -d linux`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> tocar(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets('recordatorio, check-in, aviso propio y salir', (tester) async {
    // Miércoles 25-nov, 9:30.
    final datos = DatosDemo(reloj: () => DateTime(2026, 11, 25, 9, 30));
    final notificador = NotificadorEnMemoria();
    final deps = Dependencias.fake(datos: datos, notificador: notificador);
    await tester.pumpWidget(
      KaizenApp(
        key: UniqueKey(),
        entorno: Entorno.desdeValores(fuente: 'fake', apiBaseUrl: apiProduccion, zonaHorariaDefecto: 'UTC'),
        dependencias: deps,
        mostrarHerramientasDev: false,
      ),
    );
    await tester.pumpAndSettle();

    // 1. Entrar: se arma el plan (micro-pasos pendientes, racha en riesgo, resumen del domingo).
    final campos = find.descendant(of: find.byType(CampoValidado), matching: find.byType(TextField));
    await tester.enterText(campos.at(0), 'demo@kaizen.test');
    await tester.enterText(campos.at(1), DatosDemo.contrasenaDemo);
    await tocar(tester, find.text('Iniciar sesión'));
    expect(find.byType(PantallaHoy), findsOneWidget);
    await tester.pumpAndSettle();
    expect(notificador.reemplazos, greaterThan(0));
    expect(notificador.programados.where((a) => a.tipo == TipoAviso.resumenSemanal), hasLength(1));

    // 2. Recordatorio de "Leer" a las 21:00: llega hoy.
    final leer = datos.habitosDe('u-demo').firstWhere((h) => h.nombre == 'Leer');
    await deps.recordatorios.programar(
      habitoId: leer.id,
      titulo: 'Leer',
      cuerpo: '',
      hora: (hora: 21, minuto: 0),
      frecuencia: const Diaria(),
    );
    bool leerHoy() => notificador.programados.any(
      (a) => a.tipo == TipoAviso.recordatorio && a.habitoId == leer.id && a.cuando.day == 25,
    );
    expect(leerHoy(), isTrue);

    // 3. Marcar "Leer" en Hoy: el recordatorio de hoy se va (mañana sigue).
    await tocar(
      tester,
      find.descendant(of: find.widgetWithText(FilaHabito, 'Leer'), matching: find.byType(BotonCheck)),
    );
    await tester.pumpAndSettle();
    expect(leerHoy(), isFalse);
    expect(notificador.programados.where((a) => a.habitoId == leer.id && a.tipo == TipoAviso.recordatorio), isNotEmpty);

    // 4. Un aviso propio a las 22:20 de lunes a viernes.
    PantallaNotificaciones.selectorHora = (_, _) async => (hora: 22, minuto: 20);
    addTearDown(() => PantallaNotificaciones.selectorHora = elegirHoraDelSistema);
    GoRouter.of(tester.element(find.byType(PantallaHoy))).go(Rutas.notificaciones);
    await tester.pumpAndSettle();
    await tocar(tester, find.text('Agregar aviso'));
    await tocar(tester, find.byKey(const ValueKey('hora-aviso')));
    await tocar(tester, find.descendant(of: find.byType(DialogoAviso), matching: find.text('Sáb')));
    await tocar(tester, find.descendant(of: find.byType(DialogoAviso), matching: find.text('Dom')));
    await tester.enterText(
      find.descendant(of: find.byType(DialogoAviso), matching: find.byType(TextField)),
      'Prepara la mochila',
    );
    await tocar(tester, find.text('Guardar'));
    final propios = notificador.programados.where((a) => a.tipo == TipoAviso.personal).toList();
    // Mié 25, jue 26, vie 27, lun 30 y mar 1 (7 días desde hoy).
    expect([for (final a in propios) a.cuando.day], [25, 26, 27, 30, 1]);
    expect(propios.every((a) => a.cuando.hour == 22 && a.cuando.minute == 20), isTrue);
    expect(find.text('Prepara la mochila'), findsWidgets);

    // 5. Salir: no queda nada programado.
    GoRouter.of(tester.element(find.byType(PantallaNotificaciones))).go(Rutas.perfil);
    await tester.pumpAndSettle();
    await tocar(tester, find.text('Cerrar sesión'));
    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(notificador.programados, isEmpty);
  });
}
