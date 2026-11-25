import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/ui/core/tema/colores.dart';
import 'package:kaizen/ui/core/tema/iconos.dart';
import 'package:kaizen/ui/core/widgets/fila_habito.dart';
import 'package:kaizen/ui/core/widgets/indicador_racha.dart';

import '../../helpers/envolver.dart';

void main() {
  Widget fila({bool cumplido = false, VoidCallback? onCheck, VoidCallback? onTap, bool capsula = false}) => FilaHabito(
    icono: Icons.water_drop_outlined,
    nombre: 'Tomar agua',
    subtitulo: '2 L · diario',
    racha: 21,
    cumplido: cumplido,
    conCapsula: capsula,
    onCheck: onCheck,
    onTap: onTap,
  );

  testWidgets('muestra ícono, nombre, subtítulo y racha', (tester) async {
    await montar(tester, fila());
    expect(find.text('Tomar agua'), findsOneWidget);
    expect(find.text('2 L · diario'), findsOneWidget);
    expect(find.text('21'), findsOneWidget);
    expect(find.byIcon(Icons.water_drop_outlined), findsOneWidget);
    expect(find.byIcon(KaizenIconos.racha), findsOneWidget);
  });

  testWidgets('el círculo vacío no lleva palomita; el cumplido sí, sobre marino800', (tester) async {
    await montar(tester, fila());
    expect(find.byIcon(KaizenIconos.cumplido), findsNothing);

    await montar(tester, fila(cumplido: true));
    await tester.pumpAndSettle();
    expect(find.byIcon(KaizenIconos.cumplido), findsOneWidget);
    final material = tester.widget<Material>(
      find.ancestor(of: find.byIcon(KaizenIconos.cumplido), matching: find.byType(Material)).first,
    );
    expect(material.color, KaizenColores.marino800);
  });

  testWidgets('tocar el círculo hace el check-in; tocar la fila abre el detalle', (tester) async {
    var checks = 0;
    var detalles = 0;
    await montar(tester, fila(onCheck: () => checks++, onTap: () => detalles++));
    await tester.tap(find.byType(BotonCheck));
    await tester.tap(find.text('Tomar agua'));
    expect(checks, 1);
    expect(detalles, 1);
  });

  testWidgets('sin onCheck el círculo no responde', (tester) async {
    await montar(tester, fila());
    await tester.tap(find.byType(BotonCheck));
    expect(tester.takeException(), isNull);
  });

  testWidgets('con cápsula se ve el reloj de arena junto a la llama', (tester) async {
    await montar(tester, fila(capsula: true));
    expect(find.byIcon(KaizenIconos.capsulaSellada), findsOneWidget);
    expect(tester.widget<IndicadorRacha>(find.byType(IndicadorRacha)).conCapsula, isTrue);
  });

  testWidgets('lectores de pantalla: el check-in es un botón con estado', (tester) async {
    final manejador = tester.ensureSemantics();
    await montar(tester, fila(onCheck: () {}));
    expect(
      tester.getSemantics(find.byType(BotonCheck)),
      isSemantics(
        label: 'Marcar Tomar agua como cumplido',
        isButton: true,
        hasCheckedState: true,
        isChecked: false,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    await montar(tester, fila(cumplido: true, onCheck: () {}));
    expect(
      tester.getSemantics(find.byType(BotonCheck)),
      isSemantics(
        label: 'Tomar agua: cumplido hoy',
        isButton: true,
        hasCheckedState: true,
        isChecked: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
      ),
    );
    expect(find.bySemanticsLabel(RegExp('Racha de 21 días')), findsOneWidget);
    manejador.dispose();
  });

  testWidgets('el área de toque del check-in mide al menos 48 px (accesibilidad)', (tester) async {
    await montar(tester, fila(onCheck: () {}));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });

  testWidgets('un nombre largo no desborda en un teléfono angosto', (tester) async {
    await montar(
      tester,
      const FilaHabito(
        icono: Icons.translate,
        nombre: 'Estudiar inglés con la aplicación y el libro de ejercicios todos los días',
        subtitulo: '20 min · L-V',
        racha: 1234,
        cumplido: false,
      ),
      tamano: const Size(320, 640),
    );
    expect(tester.takeException(), isNull);
  });
}
