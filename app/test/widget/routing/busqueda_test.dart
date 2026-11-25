import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/ui/core/adaptativo/busqueda.dart';
import 'package:kaizen/ui/core/adaptativo/plataforma.dart';

import '../../helpers/app.dart';

const escritorio = Size(1280, 800);

Future<void> ctrlK(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Ctrl+K abre la búsqueda en escritorio; Enter va al primer resultado', (tester) async {
    await montarApp(tester, plataforma: Plataforma.escritorio, tamano: escritorio);
    await ctrlK(tester);
    expect(find.byType(PaletaBusqueda), findsOneWidget);
    await tester.enterText(find.descendant(of: find.byType(PaletaBusqueda), matching: find.byType(TextField)), 'lab');
    await tester.pump();
    expect(find.descendant(of: find.byType(PaletaBusqueda), matching: find.byType(ListTile)), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.byType(PaletaBusqueda), findsNothing);
    expect(find.text('Esta pantalla llega en el paso 10 del plan.'), findsOneWidget);
  });

  testWidgets('⌘K también abre (Mac) y Ctrl+K con la paleta abierta no abre otra', (tester) async {
    await montarApp(tester, plataforma: Plataforma.web, tamano: const Size(1440, 900));
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pumpAndSettle();
    expect(find.byType(PaletaBusqueda), findsOneWidget);
    await ctrlK(tester);
    expect(find.byType(PaletaBusqueda), findsOneWidget);
  });

  testWidgets('sin resultados, Enter no hace nada; Esc cierra', (tester) async {
    await montarApp(tester, plataforma: Plataforma.escritorio, tamano: escritorio);
    await ctrlK(tester);
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.text('Sin resultados'), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.byType(PaletaBusqueda), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(PaletaBusqueda), findsNothing);
  });

  testWidgets('tocar un resultado navega; un usuario normal no encuentra el panel', (tester) async {
    await montarApp(tester, plataforma: Plataforma.escritorio, tamano: escritorio);
    await ctrlK(tester);
    expect(find.text('Admin'), findsNothing);
    expect(find.text('Dashboard de indicadores'), findsNothing);
    await tester.enterText(find.byType(TextField), 'semana');
    await tester.pump();
    await tester.tap(find.text('Mi semana'));
    await tester.pumpAndSettle();
    expect(find.text('Mi semana'), findsOneWidget);
  });

  testWidgets('un admin encuentra los indicadores', (tester) async {
    await montarApp(tester, plataforma: Plataforma.escritorio, tamano: escritorio, usuario: adminPrueba);
    await ctrlK(tester);
    await tester.enterText(find.byType(TextField), 'indic');
    await tester.pump();
    await tester.tap(find.text('Dashboard de indicadores'));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard de indicadores'), findsOneWidget);
  });

  testWidgets('el campo "Buscar · Ctrl K" solo aparece en escritorio amplio y abre la paleta', (tester) async {
    await montarApp(tester, plataforma: Plataforma.escritorio, tamano: escritorio);
    expect(find.byType(CampoBuscar), findsOneWidget);
    await tester.tap(find.byType(CampoBuscar));
    await tester.pumpAndSettle();
    expect(find.byType(PaletaBusqueda), findsOneWidget);

    await montarApp(tester, plataforma: Plataforma.escritorio, tamano: const Size(900, 700));
    expect(find.byType(CampoBuscar), findsNothing);
    await montarApp(tester, plataforma: Plataforma.web, tamano: const Size(1440, 900));
    expect(find.byType(CampoBuscar), findsNothing, reason: 'los bosquejos web no lo tienen');
  });

  testWidgets('en móvil Ctrl+K no hace nada', (tester) async {
    await montarApp(tester);
    await ctrlK(tester);
    expect(find.byType(PaletaBusqueda), findsNothing);
  });
}
