import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/ui/core/tema/colores.dart';
import 'package:kaizen/ui/core/widgets/campo_validado.dart';
import 'package:kaizen/ui/core/widgets/chips_seleccion.dart';
import 'package:kaizen/ui/core/widgets/contador_meta.dart';
import 'package:kaizen/ui/core/widgets/selector_segmentado.dart';

import '../../helpers/envolver.dart';

void main() {
  group('SelectorSegmentado', () {
    const opciones = [
      (valor: 'd', etiqueta: 'Diario'),
      (valor: 'lv', etiqueta: 'L-V'),
      (valor: 'n', etiqueta: 'N por sem.'),
    ];

    testWidgets('marca la opción elegida y cambia al tocar otra', (tester) async {
      String? elegido;
      await montar(
        tester,
        SelectorSegmentado<String>(opciones: opciones, seleccionado: 'd', onCambio: (v) => elegido = v),
      );
      expect(tester.widget<Text>(find.text('Diario')).style!.fontWeight, FontWeight.w700);
      expect(tester.widget<Text>(find.text('L-V')).style!.color, KaizenColores.textoSecundario);
      await tester.tap(find.text('L-V'));
      expect(elegido, 'lv');
      elegido = null;
      await tester.tap(find.text('Diario'));
      expect(elegido, isNull, reason: 'tocar la elegida no avisa');
    });

    testWidgets('deshabilitado no responde y se anuncia como grupo de botones', (tester) async {
      final manejador = tester.ensureSemantics();
      await montar(tester, const SelectorSegmentado<String>(opciones: opciones, seleccionado: 'd', onCambio: null));
      await tester.tap(find.text('L-V'));
      expect(
        tester.getSemantics(find.text('Diario')),
        matchesSemantics(
          label: 'Diario',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          hasEnabledState: true,
          isInMutuallyExclusiveGroup: true,
        ),
      );
      manejador.dispose();
    });
  });

  group('ChipsSeleccion', () {
    const categorias = [
      (valor: 1, etiqueta: 'Aprendizaje'),
      (valor: 2, etiqueta: 'Salud'),
      (valor: 3, etiqueta: 'Sueño'),
    ];

    testWidgets('el elegido va en marino800 con texto blanco', (tester) async {
      await montar(tester, ChipsSeleccion<int>(opciones: categorias, seleccionados: const {1}, onCambio: (_) {}));
      final elegido = tester.widget<Material>(
        find.ancestor(of: find.text('Aprendizaje'), matching: find.byType(Material)).first,
      );
      final otro = tester.widget<Material>(
        find.ancestor(of: find.text('Salud'), matching: find.byType(Material)).first,
      );
      expect(elegido.color, KaizenColores.marino800);
      expect(otro.color, KaizenColores.superficie);
      expect(tester.widget<Text>(find.text('Aprendizaje')).style!.color, KaizenColores.superficie);
    });

    testWidgets('una sola opción: tocar otra la reemplaza; tocar la misma no avisa', (tester) async {
      final cambios = <Set<int>>[];
      await montar(tester, ChipsSeleccion<int>(opciones: categorias, seleccionados: const {1}, onCambio: cambios.add));
      await tester.tap(find.text('Sueño'));
      await tester.tap(find.text('Aprendizaje'));
      expect(cambios, [
        {3},
      ]);
    });

    testWidgets('varias opciones (días de la semana)', (tester) async {
      Set<int>? ultimo;
      await montar(
        tester,
        ChipsSeleccion<int>(
          opciones: categorias,
          seleccionados: const {1},
          multiple: true,
          onCambio: (v) => ultimo = v,
        ),
      );
      await tester.tap(find.text('Salud'));
      expect(ultimo, {1, 2});
    });

    testWidgets('deshabilitado no responde', (tester) async {
      await montar(tester, const ChipsSeleccion<int>(opciones: categorias, seleccionados: {1}, onCambio: null));
      await tester.tap(find.text('Salud'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('en un teléfono angosto los chips bajan de renglón sin desbordar', (tester) async {
      await montar(
        tester,
        ChipsSeleccion<int>(
          opciones: [for (var i = 0; i < 8; i++) (valor: i, etiqueta: 'Categoría $i')],
          seleccionados: const {0},
          onCambio: (_) {},
        ),
        tamano: const Size(320, 640),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('ContadorMeta', () {
    testWidgets('muestra valor y unidad; + y − cambian por el paso', (tester) async {
      final valores = <num>[];
      await montar(tester, ContadorMeta(valor: 5, unidad: 'min', onCambio: valores.add));
      expect(find.text('5 min'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add));
      await tester.tap(find.byIcon(Icons.remove));
      expect(valores, [6, 4]);
    });

    testWidgets('no baja del mínimo ni sube del máximo', (tester) async {
      final valores = <num>[];
      await montar(tester, ContadorMeta(valor: 1, unidad: 'vaso', maximo: 1, onCambio: valores.add));
      await tester.tap(find.byIcon(Icons.remove));
      await tester.tap(find.byIcon(Icons.add));
      expect(valores, isEmpty);
      expect(tester.widget<Icon>(find.byIcon(Icons.remove)).color, KaizenColores.bordeControl);
    });

    testWidgets('sin unidad muestra solo el número; los botones se leen', (tester) async {
      final manejador = tester.ensureSemantics();
      await montar(tester, ContadorMeta(valor: 8.5, unidad: '', onCambio: (_) {}));
      expect(find.text('8.5'), findsOneWidget);
      expect(find.bySemanticsLabel('Aumentar'), findsOneWidget);
      expect(find.bySemanticsLabel('Disminuir'), findsOneWidget);
      manejador.dispose();
    });
  });

  group('CampoValidado', () {
    testWidgets('etiqueta arriba, ayuda en azul y el texto escrito llega', (tester) async {
      final control = TextEditingController();
      addTearDown(control.dispose);
      String? escrito;
      await montar(
        tester,
        CampoValidado(etiqueta: 'Nombre', controller: control, ayuda: 'Empieza pequeño', onCambio: (v) => escrito = v),
      );
      expect(find.text('Nombre'), findsOneWidget);
      expect(find.text('Empieza pequeño'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'Leer');
      expect(control.text, 'Leer');
      expect(escrito, 'Leer');
    });

    testWidgets('valida y muestra el error en rojo', (tester) async {
      final formulario = GlobalKey<FormState>();
      await montar(
        tester,
        Form(
          key: formulario,
          child: CampoValidado(etiqueta: 'Nombre', validador: (v) => (v ?? '').isEmpty ? 'Escribe un nombre' : null),
        ),
      );
      expect(formulario.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Escribe un nombre'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'Leer');
      expect(formulario.currentState!.validate(), isTrue);
    });

    testWidgets('contraseña oculta que se puede mostrar', (tester) async {
      await montar(tester, const CampoValidado(etiqueta: 'Contraseña', contrasena: true));
      TextField campo() => tester.widget<TextField>(find.byType(TextField));
      expect(campo().obscureText, isTrue);
      expect(campo().enableSuggestions, isFalse);
      await tester.tap(find.byTooltip('Mostrar contraseña'));
      await tester.pump();
      expect(campo().obscureText, isFalse);
      expect(find.byTooltip('Ocultar contraseña'), findsOneWidget);
    });

    testWidgets('el lector de pantalla lee la etiqueta en el campo', (tester) async {
      final manejador = tester.ensureSemantics();
      await montar(tester, const CampoValidado(etiqueta: 'Correo', sufijo: Icon(Icons.mail_outline)));
      expect(find.bySemanticsLabel(RegExp('Correo')), findsWidgets);
      expect(find.byIcon(Icons.mail_outline), findsOneWidget);
      manejador.dispose();
    });
  });
}
