import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/ui/core/tema/colores.dart';
import 'package:kaizen/ui/core/tema/iconos.dart';
import 'package:kaizen/ui/core/widgets/anillo_progreso.dart';
import 'package:kaizen/ui/core/widgets/barra_progreso.dart';
import 'package:kaizen/ui/core/widgets/barra_semana.dart';
import 'package:kaizen/ui/core/widgets/icono_escalera.dart';
import 'package:kaizen/ui/core/widgets/indicador_racha.dart';
import 'package:kaizen/ui/core/widgets/logo_kaizen.dart';

import '../../helpers/envolver.dart';

void main() {
  group('IndicadorRacha', () {
    testWidgets('llama y número en naranjaRacha', (tester) async {
      await montar(tester, const IndicadorRacha(dias: 34));
      final numero = tester.widget<Text>(find.text('34'));
      expect(numero.style!.color, KaizenColores.naranjaRacha);
      expect(tester.widget<Icon>(find.byIcon(KaizenIconos.racha)).color, KaizenColores.naranjaRacha);
      expect(find.byIcon(KaizenIconos.capsulaSellada), findsNothing);
    });

    testWidgets('se lee como "Racha de N días" (singular y con cápsula)', (tester) async {
      final manejador = tester.ensureSemantics();
      await montar(tester, const IndicadorRacha(dias: 1));
      expect(find.bySemanticsLabel('Racha de 1 día'), findsOneWidget);
      await montar(tester, const IndicadorRacha(dias: 8, conCapsula: true));
      expect(find.bySemanticsLabel('Racha de 8 días, con cápsula sellada'), findsOneWidget);
      manejador.dispose();
    });
  });

  group('AnilloProgreso y BarraProgreso', () {
    testWidgets('el anillo dibuja su hijo al centro y anuncia el porcentaje', (tester) async {
      final manejador = tester.ensureSemantics();
      await montar(tester, const AnilloProgreso(valor: 14 / 21, etiquetaSemantica: 'Cápsula', child: Text('14/21')));
      expect(find.text('14/21'), findsOneWidget);
      expect(tester.getSize(find.byType(AnilloProgreso)), const Size(56, 56));
      expect(tester.getSemantics(find.byType(AnilloProgreso)), isSemantics(label: 'Cápsula\n14/21', value: '67 %'));
      manejador.dispose();
    });

    testWidgets('el anillo en 0 y en 1 se dibuja sin errores', (tester) async {
      await montar(tester, const Row(children: [AnilloProgreso(valor: 0), AnilloProgreso(valor: 1)]));
      expect(tester.takeException(), isNull);
      const pintor = PintorAnillo(
        valor: 0.5,
        grosor: 6,
        color: KaizenColores.naranjaClaro,
        colorPista: KaizenColores.azul50,
      );
      expect(pintor.shouldRepaint(pintor), isFalse);
      expect(
        pintor.shouldRepaint(
          const PintorAnillo(
            valor: 0.6,
            grosor: 6,
            color: KaizenColores.naranjaClaro,
            colorPista: KaizenColores.azul50,
          ),
        ),
        isTrue,
      );
    });

    testWidgets('la barra llena la proporción del ancho', (tester) async {
      await montar(tester, const SizedBox(width: 200, child: BarraProgreso(valor: 0.4)));
      final relleno = tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox));
      expect(relleno.widthFactor, 0.4);
      expect(tester.getSize(find.byType(BarraProgreso)).width, 200);
    });
  });

  group('BarraSemana', () {
    testWidgets('7 cuadros con las iniciales L M M J V S D', (tester) async {
      await montar(tester, const SizedBox(width: 340, child: BarraSemana(niveles: [2, 1, 0, 0, 2, 1, null])));
      expect(find.text('L'), findsOneWidget);
      expect(find.text('M'), findsNWidgets(2));
      expect(find.text('D'), findsOneWidget);
      final cuadros = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => c.decoration is BoxDecoration)
          .map((c) => (c.decoration! as BoxDecoration).color)
          .toList();
      expect(cuadros, [
        KaizenColores.azul400,
        KaizenColores.azul200,
        KaizenColores.azul50,
        KaizenColores.azul50,
        KaizenColores.azul400,
        KaizenColores.azul200,
        KaizenColores.superficie,
      ]);
    });

    testWidgets('cada día se lee con su nombre y nivel', (tester) async {
      final manejador = tester.ensureSemantics();
      await montar(tester, const SizedBox(width: 340, child: BarraSemana(niveles: [4, 0, 0, 0, 0, 0, null])));
      expect(find.bySemanticsLabel('lunes: nivel 4 de 4'), findsOneWidget);
      expect(find.bySemanticsLabel('domingo: sin datos'), findsOneWidget);
      manejador.dispose();
    });
  });

  group('Logo e ícono de escalera', () {
    testWidgets('logo (ensō) con nombre y en sus dos variantes', (tester) async {
      await montar(tester, const Column(children: [LogoKaizen(conNombre: true), LogoKaizen(sobreOscuro: true)]));
      expect(find.text('Kaizen'), findsOneWidget);
      // El ensō (imagen) dentro de un cuadro blanco; con borde solo sobre fondo claro.
      final imagenes = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(imagenes, hasLength(2));
      expect(imagenes.every((i) => (i.image as AssetImage).assetName == LogoKaizen.rutaImagen), isTrue);
      final cuadros = tester
          .widgetList<Container>(find.ancestor(of: find.byType(Image), matching: find.byType(Container)))
          .map((c) => c.decoration! as BoxDecoration)
          .toList();
      expect(cuadros.every((d) => d.color == KaizenColores.superficie), isTrue);
      expect(cuadros.map((d) => d.border != null), [true, false]);
    });

    testWidgets('el logo solo se anuncia como imagen "Kaizen"', (tester) async {
      final manejador = tester.ensureSemantics();
      await montar(tester, const LogoKaizen());
      expect(tester.getSemantics(find.byType(LogoKaizen)), matchesSemantics(label: 'Kaizen', isImage: true));
      manejador.dispose();
    });

    testWidgets('la escalera toma el tamaño y color del IconTheme', (tester) async {
      await montar(
        tester,
        const IconTheme(
          data: IconThemeData(size: 30, color: KaizenColores.azul600),
          child: IconoEscalera(),
        ),
      );
      expect(tester.getSize(find.byType(IconoEscalera)), const Size(30, 30));
      final pintor = tester.widget<CustomPaint>(
        find.descendant(of: find.byType(IconoEscalera), matching: find.byType(CustomPaint)),
      );
      expect((pintor.painter! as PintorEscalera).color, KaizenColores.azul600);
      expect(const PintorEscalera(KaizenColores.azul600).shouldRepaint(const PintorEscalera(Colors.white)), isTrue);
    });
  });
}
