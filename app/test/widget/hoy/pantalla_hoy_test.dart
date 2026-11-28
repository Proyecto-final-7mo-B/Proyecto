import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/data/fake/datos_demo.dart';
import 'package:kaizen/data/services/api/errores_api.dart';
import 'package:kaizen/routing/rutas.dart';
import 'package:kaizen/ui/core/adaptativo/consejo_riel.dart';
import 'package:kaizen/ui/core/adaptativo/plataforma.dart';
import 'package:kaizen/ui/core/adaptativo/shell_movil.dart';
import 'package:kaizen/ui/core/widgets/barra_semana.dart';
import 'package:kaizen/ui/core/widgets/calendario_mes.dart';
import 'package:kaizen/ui/core/widgets/celebracion_hito.dart';
import 'package:kaizen/ui/core/widgets/fila_habito.dart';
import 'package:kaizen/ui/core/widgets/indicador_racha.dart';
import 'package:kaizen/ui/habitos/widgets/pantalla_detalle_habito.dart';
import 'package:kaizen/ui/hoy/widgets/panel_hoy.dart';
import 'package:kaizen/ui/hoy/widgets/pantalla_hoy.dart';
import 'package:kaizen/ui/hoy/widgets/tarjetas_hoy.dart';

import '../../helpers/app.dart';

const Size escritorio = Size(1280, 800);
const Size web = Size(1440, 900);

Finder fila(String nombre) => find.widgetWithText(FilaHabito, nombre);
Finder check(String nombre) => find.descendant(of: fila(nombre), matching: find.byType(BotonCheck));
Finder racha(String nombre) => find.descendant(of: fila(nombre), matching: find.byType(IndicadorRacha));

/// Toca [f]; si aún no se construyó (la lista es perezosa), primero desplaza la pantalla Hoy hasta encontrarlo.
/// Regresa la lista de Hoy hasta arriba (la tarjeta "N de M" es lo primero y puede quedar fuera de lo construido).
Future<void> verArriba(WidgetTester tester) async {
  final lista = find.descendant(of: find.byType(PantallaHoy), matching: find.byType(Scrollable)).first;
  tester.state<ScrollableState>(lista).position.jumpTo(0);
  await tester.pumpAndSettle();
}

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
      expect(find.byType(CalendarioMes), findsOneWidget, reason: '"Tu mes" también en el teléfono');
    });

    testWidgets('teléfono: "Tu mes" con su % y escudos, y el Consejo saludable al final', (tester) async {
      await montarApp(tester);
      final lista = find.descendant(of: find.byType(PantallaHoy), matching: find.byType(Scrollable)).first;
      await tester.scrollUntilVisible(find.byType(TarjetaMes), 200, scrollable: lista);
      expect(find.text('Noviembre'), findsOneWidget);
      expect(find.descendant(of: find.byType(TarjetaMes), matching: find.textContaining(' %')), findsOneWidget);
      expect(find.byKey(const ValueKey('escudo-23')), findsOneWidget);
      await tester.scrollUntilVisible(find.byType(TarjetaConsejo), 200, scrollable: lista);
      expect(find.text('Consejo saludable'), findsOneWidget);
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
      await verArriba(tester);
      expect(find.text('3 de 5'), findsOneWidget);
      expect(tester.widget<FilaHabito>(fila('Leer')).cumplido, isTrue);
      expect(tester.widget<IndicadorRacha>(racha('Leer')).dias, antes + 1);
    });

    testWidgets('si el servidor rechaza el check-in, se avisa y vuelve a como estaba', (tester) async {
      final deps = dependenciasPrueba();
      await montarApp(tester, dependencias: deps);
      deps.datosDemo!.fallarSiguiente(DatosDemo.error(TipoError.habitoArchivado, 409, 'El hábito está archivado'));
      await tocar(tester, check('Leer'));
      expect(find.textContaining('No se guardó el check-in de Leer'), findsOneWidget);
      await verArriba(tester);
      expect(find.text('2 de 5'), findsOneWidget);
      expect(tester.widget<FilaHabito>(fila('Leer')).cumplido, isFalse);
    });

    testWidgets('la sugerencia abre Aceptar/Mantener; aceptar sube la meta', (tester) async {
      await montarApp(tester);
      await tocar(tester, find.byType(TarjetaSugerencia));
      expect(find.text('Micro-paso sugerido'), findsOneWidget);
      expect(find.text('10 → 11 min'), findsOneWidget);
      await tocar(tester, find.text('Aceptar'));
      // Primero el aviso de la insignia nueva ("Primer micro-paso", Paso 11); la nueva meta espera su turno.
      expect(find.text('Insignia nueva: Primer micro-paso'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.textContaining('tu nueva meta es 11 min'), findsOneWidget);
      expect(find.byType(TarjetaSugerencia), findsNothing);
      await verArriba(tester);
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
      expect(find.byType(PantallaDetalleHabito), findsOneWidget);
      expect(find.text('Ejercicio'), findsWidgets);
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

  testWidgets('al volver a Hoy por la barra después de archivar, "N de M" se actualiza', (tester) async {
    await montarApp(tester);
    expect(find.text('2 de 5'), findsOneWidget);
    // "Leer" también está en "Próximo hito" (es la racha más larga): se toca su fila.
    await tocar(tester, fila('Leer'));
    await tocar(tester, find.byTooltip('Editar'));
    await tocar(tester, find.text('Archivar hábito'));
    await tocar(tester, find.text('Archivar'));
    expect(find.byType(PantallaDetalleHabito), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(BarraInferior), matching: find.text('Hoy')));
    await tester.pumpAndSettle();
    await verArriba(tester);
    expect(find.text('2 de 4'), findsOneWidget);
    expect(fila('Leer'), findsNothing);
  });

  group('Paso 9 en el teléfono', () {
    testWidgets('pendientes arriba, "Hechos hoy" al final; marcar baja la fila con su animación', (tester) async {
      await montarApp(tester);
      double y(String nombre) => tester.getTopLeft(fila(nombre)).dy;
      expect(y('Dormir 7 h'), lessThan(y('Leer')));
      expect(y('Leer'), lessThan(y('Estudiar inglés')));
      expect(find.text('Hechos hoy'), findsOneWidget);
      expect(find.text('2 hechos'), findsOneWidget);
      expect(y('Estudiar inglés'), lessThan(tester.getTopLeft(find.text('Hechos hoy')).dy));
      expect(tester.getTopLeft(find.text('Hechos hoy')).dy, lessThan(y('Ejercicio')));
      // Prioridad alta: bandera en Ejercicio.
      expect(find.descendant(of: fila('Ejercicio'), matching: find.text('Alta')), findsOneWidget);

      await tester.tap(check('Leer'));
      await tester.pump();
      expect(find.byType(EntradaDeSeccion), findsWidgets);
      await tester.pumpAndSettle();
      expect(find.text('3 hechos'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Hechos hoy')).dy, lessThan(y('Leer')));
    });

    testWidgets('marcar "Estudiar inglés" (6 → 7) celebra el hito con el dato (sin la cita)', (tester) async {
      await montarApp(tester);
      await tocar(tester, check('Estudiar inglés'));
      expect(find.byType(CelebracionHito), findsOneWidget);
      expect(find.text('¡7 días seguidos!'), findsOneWidget);
      expect(find.textContaining('Primera semana completa'), findsOneWidget);
      expect(find.textContaining('Lally'), findsNothing);
      await tester.tap(find.text('Seguir'));
      await tester.pumpAndSettle();
      expect(find.byType(CelebracionHito), findsNothing);
      // Desmarcar (7 → 6) no celebra.
      await tocar(tester, check('Estudiar inglés'));
      expect(find.byType(CelebracionHito), findsNothing, reason: 'desmarcar no celebra');
    });

    testWidgets('la tarjeta compacta "Próximo hito" lleva al hábito de la racha más larga', (tester) async {
      await montarApp(tester);
      final tarjeta = find.byType(TarjetaProximoHito);
      await tester.scrollUntilVisible(
        tarjeta,
        200,
        scrollable: find.descendant(of: find.byType(PantallaHoy), matching: find.byType(Scrollable)).first,
      );
      expect(tester.widget<TarjetaProximoHito>(tarjeta).compacta, isTrue);
      expect(find.text('Te faltan 32 días para 66'), findsOneWidget);
      expect(find.byKey(const ValueKey('animo-hito')), findsOneWidget, reason: 'con su mensaje de ánimo');
      expect(find.byType(TarjetaMetaOms), findsNothing);
      expect(find.byType(TarjetaSemanaHabitos), findsNothing, reason: 'en el teléfono, solo la tarjeta del hito');
      await tocar(tester, tarjeta);
      expect(find.byType(PantallaDetalleHabito), findsOneWidget);
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

    testWidgets(
      'el espacio vacío lleva los widgets: meta OMS, próximo hito y la semana por hábito; el consejo, en el riel',
      (tester) async {
        await montarApp(tester, plataforma: Plataforma.escritorio, tamano: web);
        expect(find.byType(ConsejoRiel), findsOneWidget, reason: 'en escritorio el consejo va en el riel');
        expect(find.byType(TarjetaConsejo), findsNothing);
        final lista = find.descendant(of: find.byType(PantallaHoy), matching: find.byType(Scrollable)).first;
        await tester.scrollUntilVisible(find.byType(TarjetaSemanaHabitos), 200, scrollable: lista);
        expect(find.text('Meta semanal OMS'), findsOneWidget);
        expect(find.textContaining('OMS 2020'), findsNothing);
        expect(find.byKey(const ValueKey('animo-hito')), findsOneWidget);
        expect(find.textContaining('automatización'), findsNothing, reason: 'sin el mensaje de la automatización');
        expect(tester.widget<TarjetaProximoHito>(find.byType(TarjetaProximoHito)).compacta, isFalse);
        expect(find.text('Esta semana, por hábito'), findsOneWidget);
        expect(find.text('Tus últimas 12 semanas'), findsNothing);
        expect(find.text('Consejo saludable'), findsOneWidget);
        // Meta OMS y Próximo hito van lado a lado, a la misma altura.
        final oms = tester.getRect(find.byType(TarjetaMetaOms));
        final hito = tester.getRect(find.byType(TarjetaProximoHito));
        expect(oms.top, hito.top);
        expect(oms.height, hito.height);
        expect(oms.right, lessThan(hito.left));
      },
    );

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

    testWidgets('en web (sin riel) el consejo saludable va en la columna derecha; tocarlo no abre nada', (
      tester,
    ) async {
      await montarApp(tester, plataforma: Plataforma.web, tamano: web);
      expect(find.byType(ConsejoRiel), findsNothing);
      await tocar(tester, find.byType(TarjetaConsejo));
      expect(find.byType(PantallaHoy), findsOneWidget);
    });

    testWidgets('el calendario de Hoy lleva el escudo del día protegido', (tester) async {
      await montarApp(tester, plataforma: Plataforma.escritorio, tamano: web);
      expect(find.byKey(const ValueKey('escudo-23')), findsOneWidget);
    });

    testWidgets('con el riel angosto (900 px) se usa una columna', (tester) async {
      await montarApp(tester, plataforma: Plataforma.escritorio, tamano: const Size(900, 800));
      expect(find.byType(BarraSemana), findsOneWidget, reason: 'una columna, como el teléfono');
      expect(find.byType(TarjetaMicroPaso), findsNothing);
    });
  });

  testWidgets('la ruta /hoy es la pantalla real', (tester) async {
    await montarApp(tester, ubicacion: Rutas.hoy);
    expect(find.byType(PantallaHoy), findsOneWidget);
    expect(find.textContaining('paso 6'), findsNothing);
  });
}
