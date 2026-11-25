import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/ui/core/tema/colores.dart';
import 'package:kaizen/ui/core/widgets/calendario_mes.dart';
import 'package:kaizen/ui/core/widgets/mapa_calor.dart';

import '../../helpers/envolver.dart';

Color? colorDeCelda(WidgetTester tester, String texto) {
  final contenedor = tester.widget<Container>(
    find.ancestor(of: find.text(texto), matching: find.byType(Container)).first,
  );
  return (contenedor.decoration! as BoxDecoration).color;
}

void main() {
  group('CalendarioMes', () {
    testWidgets('octubre de 2026: título, 31 días y empieza en jueves', (tester) async {
      await montar(tester, const SizedBox(width: 340, child: CalendarioMes(anio: 2026, mes: 10)));
      expect(find.text('Octubre'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('31'), findsOneWidget);
      expect(find.text('32'), findsNothing);
      // El 1 queda en la columna del jueves (4.ª): misma x que la "J" del encabezado.
      expect(tester.getCenter(find.text('1')).dx, closeTo(tester.getCenter(find.text('J')).dx, 0.5));
    });

    testWidgets('pinta la intensidad correcta de cada día (escala 0–4)', (tester) async {
      await montar(
        tester,
        const SizedBox(width: 340, child: CalendarioMes(anio: 2026, mes: 10, niveles: {1: 2, 2: 1, 9: 4, 13: 3})),
      );
      expect(colorDeCelda(tester, '1'), KaizenColores.azul400);
      expect(colorDeCelda(tester, '2'), KaizenColores.azul200);
      expect(colorDeCelda(tester, '9'), KaizenColores.marino800);
      expect(colorDeCelda(tester, '13'), KaizenColores.azul600);
      expect(colorDeCelda(tester, '22'), KaizenColores.azul50, reason: 'sin dato = nivel 0');
      expect(tester.widget<Text>(find.text('9')).style!.color, KaizenColores.superficie);
      expect(tester.widget<Text>(find.text('22')).style!.color, KaizenColores.texto);
    });

    testWidgets('marca hoy con contorno y avisa el día tocado', (tester) async {
      DateTime? tocado;
      await montar(
        tester,
        SizedBox(
          width: 340,
          child: CalendarioMes(anio: 2026, mes: 10, hoy: DateTime(2026, 10, 22), onDia: (d) => tocado = d),
        ),
      );
      final hoy = tester.widget<Container>(find.ancestor(of: find.text('22'), matching: find.byType(Container)).first);
      expect((hoy.decoration! as BoxDecoration).border, isNotNull);
      await tester.tap(find.text('15'));
      expect(tocado, DateTime(2026, 10, 15));
    });

    testWidgets('febrero bisiesto tiene 29 días y cada día se lee', (tester) async {
      final manejador = tester.ensureSemantics();
      await montar(tester, const SizedBox(width: 340, child: CalendarioMes(anio: 2028, mes: 2, niveles: {29: 3})));
      expect(find.text('29'), findsOneWidget);
      expect(find.text('30'), findsNothing);
      expect(find.bySemanticsLabel('29 de febrero: nivel 3 de 4'), findsOneWidget);
      manejador.dispose();
    });

    testWidgets('sin título cuando se pide', (tester) async {
      await montar(tester, const SizedBox(width: 340, child: CalendarioMes(anio: 2026, mes: 11, mostrarTitulo: false)));
      expect(find.text('Noviembre'), findsNothing);
    });
  });

  group('MapaCalor', () {
    const mapa = MapaCalor(
      filas: ['Ejercicio', 'Agua'],
      columnas: ['L-M', 'J-V', 'S-D'],
      valores: [
        [0.8, -0.6, 0.3],
        [0.1, null],
      ],
    );

    testWidgets('etiquetas de filas y columnas y valores con signo', (tester) async {
      await montar(tester, const SizedBox(width: 340, child: mapa));
      for (final t in ['Ejercicio', 'Agua', 'L-M', 'J-V', 'S-D', '+0.8', '−0.6', '+0.3', '+0.1']) {
        expect(find.text(t), findsOneWidget, reason: t);
      }
      expect(find.text('—'), findsNWidgets(2), reason: 'null y la columna que falta');
    });

    testWidgets('color según el valor y texto legible', (tester) async {
      await montar(tester, const SizedBox(width: 340, child: mapa));
      expect(colorDeCelda(tester, '+0.8'), KaizenColores.marino800);
      expect(colorDeCelda(tester, '−0.6'), KaizenColores.azul200, reason: '−0.6 en el rango −1…1 = nivel 1');
      expect(tester.widget<Text>(find.text('+0.8')).style!.color, KaizenColores.superficie);
    });

    testWidgets('cada celda se lee con su fila y columna', (tester) async {
      final manejador = tester.ensureSemantics();
      await montar(tester, const SizedBox(width: 340, child: mapa));
      expect(find.bySemanticsLabel('Ejercicio, L-M: +0.8'), findsOneWidget);
      expect(find.bySemanticsLabel('Agua, J-V: sin datos'), findsOneWidget);
      manejador.dispose();
    });
  });
}
