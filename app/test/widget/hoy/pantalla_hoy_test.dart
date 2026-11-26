import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/data/services/api/errores_api.dart';
import 'package:kaizen/routing/rutas.dart';
import 'package:kaizen/ui/core/adaptativo/plataforma.dart';
import 'package:kaizen/ui/core/widgets/barra_semana.dart';
import 'package:kaizen/ui/core/widgets/calendario_mes.dart';
import 'package:kaizen/ui/core/widgets/fila_habito.dart';
import 'package:kaizen/ui/core/widgets/indicador_racha.dart';
import 'package:kaizen/ui/hoy/widgets/pantalla_hoy.dart';
import 'package:kaizen/ui/hoy/widgets/tarjetas_hoy.dart';

import '../../helpers/app.dart';

const Size escritorio = Size(1280, 800);
const Size web = Size(1440, 900);

Finder fila(String nombre) => find.widgetWithText(FilaHabito, nombre);
Finder check(String nombre) => find.descendant(of: fila(nombre), matching: find.byType(BotonCheck));
Finder racha(String nombre) => find.descendant(of: fila(nombre), matching: find.byType(IndicadorRacha));

/// Toca [f]; si aún no se construyó (la lista es perezosa), primero desplaza la pantalla Hoy hasta encontrarlo.
Future<void> tocar(WidgetTester tester, Finder f) async {
  if (f.evaluate().isEmpty) {
    final lista = find.descendant(of: find.byType(PantallaHoy), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(f, 200, scrollable: lista);
  }
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  group('teléfono', () {
    testWidgets('saludo, fecha, "2 de 5", semana, Para hoy, sugerencia y señal', (tester) async {
      await montarApp(tester);
      expect(find.byType(PantallaHoy), findsOneWidget);
      expect(find.text('Miércoles 25 de noviembre'), findsOneWidget);
      expect(find.text('Buenos días, Jael'), findsOneWidget);
      expect(find.text('2 de 5'), findsOneWidget);
      expect(find.byType(BarraSemana), findsOneWidget);
      expect(find.text('Para hoy'), findsOneWidget);
      expect(find.byType(FilaHabito), findsNWidgets(5));
      expect(find.text('2 L · diario'), findsOneWidget);
      expect(find.text('20 min · L-V'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byType(TarjetaSenal),
        200,
        scrollable: find.descendant(of: find.byType(PantallaHoy), matching: find.byType(Scrollable)).first,
      );
      expect(find.text('Leer: ¿subir de 10 a 11 min?'), findsOneWidget);
      expect(find.text('93 % en 14 días'), findsOneWidget);
      expect(find.text('¿Cómo te sientes hoy?'), findsOneWidget);
      expect(find.byType(CalendarioMes), findsNothing, reason: 'el calendario es de escritorio');
    });

    testWidgets('el resumen se lee completo con el lector de pantalla', (tester) async {
      final semantica = tester.ensureSemantics();
      await montarApp(tester);
      expect(find.bySemanticsLabel('Hoy: 2 de 5 hábitos cumplidos'), findsOneWidget);
      semantica.dispose();
    });

    testWidgets('check-in de un toque: "3 de 5" y la racha sube', (tester) async {
      await montarApp(tester);
      final antes = int.parse(tester.widget<IndicadorRacha>(racha('Leer')).dias.toString());
      await tocar(tester, check('Leer'));
      expect(find.text('3 de 5'), findsOneWidget);
      expect(tester.widget<FilaHabito>(fila('Leer')).cumplido, isTrue);
      expect(tester.widget<IndicadorRacha>(racha('Leer')).dias, antes + 1);
    });

    testWidgets('si el check-in falla, se avisa y vuelve a como estaba', (tester) async {
      final deps = dependenciasPrueba();
      await montarApp(tester, dependencias: deps);
      deps.datosDemo!.fallarSiguiente(const ErrorApp(TipoError.sinConexion));
      await tocar(tester, check('Leer'));
      expect(find.textContaining('No se guardó el check-in de Leer'), findsOneWidget);
      expect(find.text('2 de 5'), findsOneWidget);
      expect(tester.widget<FilaHabito>(fila('Leer')).cumplido, isFalse);
    });

    testWidgets('la sugerencia abre Aceptar/Mantener; aceptar sube la meta', (tester) async {
      await montarApp(tester);
      await tocar(tester, find.byType(TarjetaSugerencia));
      expect(find.text('Micro-paso sugerido'), findsOneWidget);
      expect(find.text('10 → 11 min'), findsOneWidget);
      await tocar(tester, find.text('Aceptar'));
      expect(find.textContaining('tu nueva meta es 11 min'), findsOneWidget);
      expect(find.byType(TarjetaSugerencia), findsNothing);
      expect(find.textContaining('11 min · Nivel'), findsOneWidget);
    });

    testWidgets('el botón + abre Nuevo hábito y la fila abre el detalle', (tester) async {
      await montarApp(tester);
      await tocar(tester, find.byTooltip('Nuevo hábito'));
      expect(find.text('Nuevo hábito'), findsWidgets);
      expect(find.byType(PantallaHoy), findsNothing);
    });

    testWidgets('tocar un hábito abre su detalle', (tester) async {
      await montarApp(tester);
      await tocar(tester, find.text('Ejercicio'));
      expect(find.text('Detalle del hábito'), findsOneWidget);
    });

    testWidgets('"¿Cómo te sientes hoy?" lleva al Laboratorio', (tester) async {
      await montarApp(tester);
      await tocar(tester, find.byType(TarjetaSenal));
      expect(find.byType(PantallaHoy), findsNothing);
      expect(find.text('Laboratorio'), findsWidgets);
    });

    testWidgets('sin hábitos: estado vacío que invita a crear el primero', (tester) async {
      await montarApp(tester, cuentaDemo: 'u-nuevo');
      expect(find.text('Aún no tienes hábitos'), findsOneWidget);
      expect(find.byType(FilaHabito), findsNothing);
      await tocar(tester, find.text('Crear mi primer hábito'));
      expect(find.byType(PantallaHoy), findsNothing);
    });

    testWidgets('si no carga, muestra el error y Reintentar', (tester) async {
      final deps = dependenciasPrueba();
      deps.datosDemo!.fallarSiguiente(const ErrorApp(TipoError.sinConexion));
      await montarApp(tester, dependencias: deps);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.byType(FilaHabito), findsNothing);
      await tocar(tester, find.text('Reintentar'));
      expect(find.text('2 de 5'), findsOneWidget);
    });
  });

  group('escritorio y web', () {
    testWidgets('dos columnas: calendario del mes y micro-paso con Aceptar/Mantener', (tester) async {
      await montarApp(tester, plataforma: Plataforma.escritorio, tamano: escritorio);
      expect(find.text('Hoy'), findsWidgets);
      expect(find.text('Miércoles 25 de noviembre'), findsOneWidget);
      expect(find.text('2 de 5'), findsOneWidget);
      expect(find.byType(CalendarioMes), findsOneWidget);
      expect(find.byType(BarraSemana), findsNothing, reason: 'en escritorio la semana la cubre el calendario');
      expect(find.byType(TarjetaMicroPaso), findsOneWidget);
      expect(find.byType(TarjetaSugerencia), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Nuevo hábito'), findsOneWidget);
    });

    testWidgets('Mantener deja la meta y quita el micro-paso', (tester) async {
      await montarApp(tester, plataforma: Plataforma.escritorio, tamano: escritorio);
      await tocar(tester, find.text('Mantener'));
      expect(find.text('Mantienes tu meta actual.'), findsOneWidget);
      expect(find.byType(TarjetaMicroPaso), findsNothing);
      expect(find.text('10 min · Nivel 3'), findsOneWidget);
    });

    testWidgets('el check-in también funciona en escritorio', (tester) async {
      await montarApp(tester, plataforma: Plataforma.escritorio, tamano: escritorio);
      await tocar(tester, check('Dormir 7 h'));
      expect(find.text('3 de 5'), findsOneWidget);
    });

    testWidgets('en web, "Nuevo hábito" solo está en la barra superior', (tester) async {
      await montarApp(tester, plataforma: Plataforma.web, tamano: web);
      expect(find.byType(CalendarioMes), findsOneWidget);
      expect(find.text('Nuevo hábito'), findsOneWidget);
    });

    testWidgets('con el riel angosto (900 px) se usa una columna', (tester) async {
      await montarApp(tester, plataforma: Plataforma.escritorio, tamano: const Size(900, 800));
      expect(find.byType(BarraSemana), findsOneWidget);
      expect(find.byType(CalendarioMes), findsNothing);
    });
  });

  testWidgets('la ruta /hoy es la pantalla real', (tester) async {
    await montarApp(tester, ubicacion: Rutas.hoy);
    expect(find.byType(PantallaHoy), findsOneWidget);
    expect(find.textContaining('paso 6'), findsNothing);
  });
}
