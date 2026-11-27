import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/routing/rutas.dart';
import 'package:kaizen/ui/acerca/widgets/pantalla_acerca.dart';
import 'package:kaizen/ui/core/adaptativo/consejo_riel.dart';
import 'package:kaizen/ui/core/adaptativo/plataforma.dart';
import 'package:kaizen/ui/core/tema/colores.dart';
import 'package:kaizen/ui/core/widgets/calendario_mes.dart';

import '../../helpers/app.dart';
import '../../helpers/envolver.dart';

Future<void> verHasta(WidgetTester tester, Finder f) async {
  final lista = find.descendant(of: find.byType(PantallaAcerca), matching: find.byType(Scrollable));
  await tester.scrollUntilVisible(f, 300, scrollable: lista.first);
  await tester.pumpAndSettle();
}

void main() {
  group('Acerca de Kaizen', () {
    testWidgets('portada con el porqué y sus cifras, cómo funciona, rangos por categoría y fuentes', (tester) async {
      await montarApp(tester, ubicacion: Rutas.acerca);
      expect(find.text('Acerca de Kaizen'), findsWidgets);
      expect(find.text('Mejora continua, con ciencia'), findsOneWidget);
      expect(find.textContaining('Casi todas las apps de hábitos premian hacer más'), findsOneWidget);
      expect(find.text('66'), findsOneWidget);
      expect(find.text('días: la mediana para formar un hábito'), findsOneWidget);
      await verHasta(tester, find.text('Cómo funciona'));
      await verHasta(tester, find.text('La Escalera: micro-pasos'));
      await verHasta(tester, find.text('Rangos recomendados'));
      await verHasta(tester, find.text('Aeróbico moderado'));
      expect(find.text('Recomendado: 150–300 min a la semana · Máximo: 600 min'), findsOneWidget);
      await verHasta(tester, find.text('Fuentes'));
      await verHasta(tester, find.text('53 fuentes'));
    });

    testWidgets('las fuentes se filtran por tema y se abren para ver qué tomamos de cada una', (tester) async {
      await montarApp(tester, plataforma: Plataforma.escritorio, tamano: const Size(1440, 900), ubicacion: Rutas.acerca);
      final chip = find.text('Color y accesibilidad');
      await verHasta(tester, chip);
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
      expect(find.text('6 fuentes'), findsOneWidget);
      await verHasta(tester, find.text('F45'));
      expect(find.textContaining('Web Content Accessibility Guidelines'), findsOneWidget);
      await tester.tap(find.textContaining('Web Content Accessibility Guidelines'));
      await tester.pumpAndSettle();
      expect(find.textContaining('el color nunca es la única señal'), findsOneWidget, reason: 'lo que usamos de ella');
      expect(find.text('https://www.w3.org/TR/WCAG22/'), findsOneWidget);
      expect(find.text('Evidencia sólida'), findsWidgets, reason: 'la confianza, con su pastilla');
    });

    testWidgets('es una sección del riel en escritorio; ya no está en Perfil', (tester) async {
      await montarApp(tester, plataforma: Plataforma.escritorio, tamano: const Size(1440, 900));
      await tester.tap(find.text('Acerca de'));
      await tester.pumpAndSettle();
      expect(find.byType(PantallaAcerca), findsOneWidget);
      await montarApp(tester, ubicacion: Rutas.perfil);
      expect(find.text('Acerca de Kaizen'), findsNothing);
    });

    testWidgets('en el teléfono se abre desde el detalle del hábito ("¿En qué nos basamos?")', (tester) async {
      final deps = dependenciasPrueba();
      final leer = deps.datosDemo!.habitosDe('u-demo').firstWhere((h) => h.nombre == 'Leer');
      await montarApp(tester, ubicacion: Rutas.habito(leer.id), dependencias: deps);
      final enlace = find.text('¿En qué nos basamos?');
      await tester.ensureVisible(enlace);
      await tester.pumpAndSettle();
      await tester.tap(enlace);
      await tester.pumpAndSettle();
      expect(find.byType(PantallaAcerca), findsOneWidget);
    });

    testWidgets('el consejo del riel es solo el consejo: tocarlo no abre nada', (tester) async {
      await montarApp(tester, plataforma: Plataforma.escritorio, tamano: const Size(1440, 900));
      expect(find.byType(ConsejoRiel), findsOneWidget);
      expect(find.text('Consejo saludable'), findsOneWidget);
      await tester.tap(find.byType(ConsejoRiel));
      await tester.pumpAndSettle();
      expect(find.byType(PantallaAcerca), findsNothing);
    });
  });

  group('escudo del calendario', () {
    testWidgets('los días protegidos llevan un escudo y se leen en pantalla', (tester) async {
      final semantica = tester.ensureSemantics();
      await montar(
        tester,
        const SizedBox(
          width: 360,
          child: CalendarioMes(anio: 2026, mes: 11, niveles: {5: 4, 6: 0}, protegidos: {5, 6}),
        ),
      );
      expect(find.byKey(const ValueKey('escudo-5')), findsOneWidget);
      expect(find.byKey(const ValueKey('escudo-6')), findsOneWidget);
      expect(find.byKey(const ValueKey('escudo-7')), findsNothing);
      expect(
        tester.widget<Icon>(find.byKey(const ValueKey('escudo-5'))).color,
        KaizenColores.superficie,
        reason: 'blanco sobre los niveles oscuros',
      );
      expect(tester.widget<Icon>(find.byKey(const ValueKey('escudo-6'))).color, KaizenColores.azul600);
      expect(find.bySemanticsLabel(RegExp(r'^6 de noviembre: .*, racha protegida ese día$')), findsOneWidget);
      semantica.dispose();
    });
  });
}
