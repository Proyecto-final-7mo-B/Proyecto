import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/ui/core/tema/iconos.dart';
import 'package:kaizen/ui/core/widgets/calendario_mes.dart';
import 'package:kaizen/ui/core/widgets/contador_meta.dart';
import 'package:kaizen/ui/core/widgets/fila_habito.dart';
import 'package:kaizen/ui/core/widgets/mapa_calor.dart';
import 'package:kaizen/ui/dev/galeria_componentes.dart';

import '../../helpers/envolver.dart';

/// La galería tiene un indicador de carga que gira sin parar: `pumpAndSettle` nunca terminaría.
const espera = Duration(milliseconds: 500);

void main() {
  Future<void> abrir(WidgetTester tester, Size tamano) =>
      montar(tester, const GaleriaComponentes(), tamano: tamano, centrado: false);

  Future<void> bajarHasta(WidgetTester tester, Finder objetivo) async {
    await tester.scrollUntilVisible(objetivo, 300, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(objetivo.first);
    await tester.pump(espera);
  }

  for (final (nombre, tamano) in const [('móvil', Size(390, 844)), ('escritorio', Size(1280, 800))]) {
    testWidgets('en $nombre muestra todas las secciones sin desbordes', (tester) async {
      await abrir(tester, tamano);
      for (final seccion in [
        'Paleta',
        'Botones',
        'Tarjetas',
        'Fila de hábito (toca el círculo)',
        'Calendario del mes',
        'Mapa de calor (I5)',
        'Controles de formulario',
        'Avisos',
        'Estados',
        'Diálogo',
      ]) {
        await bajarHasta(tester, find.text(seccion));
        expect(find.text(seccion), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('los componentes de la galería responden', (tester) async {
    await abrir(tester, const Size(390, 844));

    await bajarHasta(tester, find.text('Leer'));
    expect(find.byIcon(KaizenIconos.cumplido), findsNWidgets(2));
    await tester.tap(find.descendant(of: find.widgetWithText(FilaHabito, 'Leer'), matching: find.byType(BotonCheck)));
    await tester.pump(espera);
    expect(find.byIcon(KaizenIconos.cumplido), findsNWidgets(3));

    await bajarHasta(tester, find.byType(CalendarioMes));
    await tester.tap(find.text('15'));
    await bajarHasta(tester, find.byType(MapaCalor));

    await bajarHasta(tester, find.text('L-V'));
    await tester.tap(find.text('L-V'));
    await bajarHasta(tester, find.text('Salud'));
    await tester.tap(find.text('Salud'));
    await bajarHasta(tester, find.text('S').last);
    await tester.tap(find.text('S').last);
    await bajarHasta(tester, find.byType(ContadorMeta));
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('6 min'), findsOneWidget);
    await bajarHasta(tester, find.byType(SwitchListTile));
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);

    await bajarHasta(tester, find.text('Abrir diálogo de confirmación'));
    await tester.tap(find.text('Abrir diálogo de confirmación'));
    await tester.pump(espera);
    expect(find.text('¿Archivar “Leer”?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pump(espera);
    expect(tester.takeException(), isNull);
  });
}
