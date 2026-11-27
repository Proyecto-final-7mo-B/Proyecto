import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/domain/models/habito.dart';
import 'package:kaizen/routing/rutas.dart';
import 'package:kaizen/ui/acerca/widgets/pantalla_acerca.dart';
import 'package:kaizen/ui/core/adaptativo/plataforma.dart';
import 'package:kaizen/ui/habitos/widgets/pantalla_formulario_habito.dart';
import 'package:kaizen/ui/habitos/widgets/pantalla_habitos.dart';
import 'package:kaizen/ui/habitos/widgets/pantalla_recomendados.dart';

import '../../helpers/app.dart';

const Size escritorio = Size(1440, 900);

/// Toca [f]; si aún no se construyó, primero desplaza la pantalla de recomendados (o la hoja de detalle).
Future<void> tocar(WidgetTester tester, Finder f) async {
  if (f.evaluate().isEmpty) {
    final lista = find.descendant(of: find.byType(PantallaRecomendados), matching: find.byType(Scrollable));
    await tester.scrollUntilVisible(f, 200, scrollable: lista.first);
  }
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  group('teléfono', () {
    testWidgets(
      'recomendaciones por categoría y subcategoría, sin fuentes; "Hábito personalizado" abre el formulario',
      (tester) async {
        await montarApp(tester, ubicacion: Rutas.nuevoHabito);
        expect(find.byType(PantallaRecomendados), findsOneWidget);
        expect(find.text('Nuevo hábito'), findsWidgets);
        expect(find.textContaining('Tú solo decides la prioridad'), findsOneWidget);
        expect(find.text('Aeróbico moderado'), findsOneWidget, reason: 'empieza en Ejercicio');
        expect(find.text('Caminar a paso rápido'), findsOneWidget);
        expect(find.text('30 min · L-V'), findsOneWidget);
        expect(find.text('Después de comer'), findsOneWidget);
        expect(find.textContaining('OMS 2020'), findsNothing);
        expect(find.textContaining('F11'), findsNothing);

        await tocar(tester, find.text('Hábito personalizado'));
        expect(find.byType(PantallaFormularioHabito), findsOneWidget);
      },
    );

    testWidgets('cambiar de categoría cambia las subcategorías', (tester) async {
      await montarApp(tester, ubicacion: Rutas.nuevoHabito);
      await tocar(tester, find.text('Salud'));
      expect(find.text('Hidratación'), findsOneWidget);
      expect(find.text('Caminar a paso rápido'), findsNothing);
    });

    testWidgets('elegir una: el detalle dice cuándo y por qué; con prioridad y cápsula abre la cápsula', (
      tester,
    ) async {
      final deps = dependenciasPrueba();
      await montarApp(tester, ubicacion: Rutas.habitos, dependencias: deps);
      await tester.tap(find.byTooltip('Nuevo hábito'));
      await tester.pumpAndSettle();
      await tocar(tester, find.text('Bienestar'));
      await tocar(tester, find.text('Meditar 10 minutos'));
      expect(find.byType(DetalleRecomendacion), findsOneWidget);
      expect(find.text('10 min · diario'), findsWidgets);
      expect(find.text('Dentro de lo recomendado: 10–20 min cada vez'), findsOneWidget);
      expect(find.text('Cuándo'), findsOneWidget);
      expect(find.text('Al despertar'), findsWidgets);
      expect(find.text('Por qué'), findsOneWidget);
      expect(find.textContaining('Strohmaier'), findsNothing);
      await tester.tap(find.text('Alta'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('30 días'));
      await tester.tap(find.text('30 días'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Crear hábito'));
      await tester.tap(find.text('Crear hábito'));
      await tester.pumpAndSettle();
      final h = deps.datosDemo!.habitosDe('u-demo').firstWhere((h) => h.nombre == 'Meditar 10 minutos');
      expect((h.prioridad, h.intencion, h.meta), (Prioridad.alta, 'Al despertar', 10.0));
      expect(find.text('Nueva cápsula'), findsWidgets);
      expect(find.text(h.id), findsOneWidget, reason: 'la cápsula de ese hábito');
    });

    testWidgets('sin cápsula regresa a la lista y aparece; sin rango lo dice', (tester) async {
      await montarApp(tester, ubicacion: Rutas.habitos);
      await tester.tap(find.byTooltip('Nuevo hábito'));
      await tester.pumpAndSettle();
      await tocar(tester, find.text('Finanzas'));
      await tocar(tester, find.text('Anotar tus gastos del día'));
      expect(find.textContaining('No hay un rango científico'), findsOneWidget);
      await tester.ensureVisible(find.text('Crear hábito'));
      await tester.tap(find.text('Crear hábito'));
      await tester.pumpAndSettle();
      expect(find.byType(PantallaHabitos), findsOneWidget);
      expect(find.text('Listo: Anotar tus gastos del día ya está en tu lista.'), findsOneWidget);
    });

    testWidgets('dejar de fumar: la Escalera ayuda a bajar poco a poco', (tester) async {
      await montarApp(tester, ubicacion: Rutas.nuevoHabito);
      await tocar(tester, find.text('Salud'));
      await tocar(tester, find.text('Bajar a 5 cigarros al día'));
      expect(find.textContaining('la Escalera te ayudará a bajar'), findsOneWidget);
    });

    testWidgets('si la recomendación ya no está, el error sale en el detalle y no se cierra', (tester) async {
      final deps = dependenciasPrueba();
      await montarApp(tester, ubicacion: Rutas.nuevoHabito, dependencias: deps);
      final r = deps.datosDemo!.recomendados.firstWhere((x) => x.clave == 'caminar_rapido');
      deps.datosDemo!.recomendadosInactivos.add(r.id);
      await tocar(tester, find.text('Caminar a paso rápido'));
      await tester.ensureVisible(find.text('Crear hábito'));
      await tester.tap(find.text('Crear hábito'));
      await tester.pumpAndSettle();
      expect(find.text('Esta recomendación ya no está disponible. Elige otra.'), findsOneWidget);
      expect(find.byType(DetalleRecomendacion), findsOneWidget);
    });

    testWidgets('"¿En qué nos basamos?" abre Acerca de Kaizen', (tester) async {
      await montarApp(tester, ubicacion: Rutas.nuevoHabito);
      await tocar(tester, find.text('¿En qué nos basamos?'));
      expect(find.byType(PantallaAcerca), findsOneWidget);
    });
  });

  group('escritorio', () {
    testWidgets('dos columnas, "Hábito personalizado" arriba y el detalle en un diálogo', (tester) async {
      await montarApp(tester, plataforma: Plataforma.escritorio, tamano: escritorio, ubicacion: Rutas.nuevoHabito);
      expect(find.widgetWithText(OutlinedButton, 'Hábito personalizado'), findsOneWidget);
      final a = tester.getTopLeft(find.text('Caminar a paso rápido'));
      final b = tester.getTopLeft(find.text('Andar en bicicleta'));
      expect(a.dy, b.dy, reason: 'dos tarjetas en la misma fila');
      await tocar(tester, find.text('Caminar a paso rápido'));
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(DetalleRecomendacion), findsOneWidget);
    });
  });
}
