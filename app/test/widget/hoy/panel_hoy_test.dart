import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/l10n/gen/app_localizations.dart';
import 'package:kaizen/domain/models/categoria.dart';
import 'package:kaizen/domain/models/frecuencia.dart';
import 'package:kaizen/domain/models/habito.dart';
import 'package:kaizen/domain/models/progreso.dart';
import 'package:kaizen/ui/core/tema/colores.dart';
import 'package:kaizen/ui/core/widgets/barra_progreso.dart';
import 'package:kaizen/ui/core/widgets/celebracion_hito.dart';
import 'package:kaizen/ui/core/widgets/fila_habito.dart';
import 'package:kaizen/ui/core/widgets/indicador_racha.dart';
import 'package:kaizen/ui/hoy/widgets/panel_hoy.dart';

import '../../helpers/envolver.dart';

ActividadSemanal actividad(double moderados, [double vigorosos = 0]) => ActividadSemanal(
  semana: '2026-W48',
  minutosModerados: moderados,
  minutosVigorosos: vigorosos,
  equivalenteModerado: moderados + 2 * vigorosos,
  recomendadoDesde: 150,
  recomendadoHasta: 300,
  cita: 'OMS 2020: 150–300 min/semana',
);

Habito habito(int racha) => Habito(
  id: 'h1',
  nombre: 'Leer',
  unidad: 'min',
  meta: 10,
  nivel: 3,
  categoria: const Categoria(id: 'c', nombre: 'Educación', clave: 'educacion', color: '#2563EB', icono: 'school'),
  subcategoria: const Subcategoria(id: 's', clave: 'lectura', nombre: 'Lectura', icono: 'menu_book'),
  frecuencia: const Diaria(),
  escaleraActiva: true,
  activo: true,
  fechaCreacion: DateTime.utc(2026, 9),
  racha: Racha(actual: racha, maxima: racha),
);

/// Todos los colores que pinta el árbol: íconos, textos, cajas y `Material`.
Iterable<Color> coloresPintados(WidgetTester tester) sync* {
  for (final e in find.byWidgetPredicate((_) => true).evaluate()) {
    final w = e.widget;
    switch (w) {
      case Icon(:final color?):
        yield color;
      case Text(:final style?) when style.color != null:
        yield style.color!;
      case Container(:final BoxDecoration decoration) when decoration.color != null:
        yield decoration.color!;
      case DecoratedBox(:final BoxDecoration decoration) when decoration.color != null:
        yield decoration.color!;
      case ColoredBox(:final color):
        yield color;
      case Material(:final color?):
        yield color;
    }
  }
}

void main() {
  group('TarjetaMetaOms', () {
    testWidgets('debajo de 150: cuánto falta, en gris', (tester) async {
      await montar(tester, SizedBox(width: 360, child: TarjetaMetaOms(actividad: actividad(95))));
      expect(find.text('95 de 150 min'), findsOneWidget);
      expect(find.text('Te faltan 55 min para lo mínimo recomendado'), findsOneWidget);
      expect(find.textContaining('OMS 2020'), findsNothing, reason: 'sin fuente fuera del detalle del hábito');
      expect(find.textContaining('vigorosos'), findsNothing);
    });

    testWidgets('150–300: dentro de lo recomendado, en verde; los vigorosos cuentan doble', (tester) async {
      await montar(tester, SizedBox(width: 360, child: TarjetaMetaOms(actividad: actividad(110, 20))));
      expect(find.text('150 de 150 min'), findsOneWidget);
      final estado = tester.widget<Text>(find.text('Dentro de lo recomendado esta semana'));
      expect(estado.style!.color, KaizenColores.verdeProgreso);
      expect(find.text('Incluye 20 min vigorosos (cuentan doble)'), findsOneWidget);
    });

    testWidgets('más de 300: beneficio extra pequeño y la barra se estira', (tester) async {
      await montar(tester, SizedBox(width: 360, child: TarjetaMetaOms(actividad: actividad(420))));
      expect(find.text('Arriba de 300 min el beneficio extra es pequeño'), findsOneWidget);
      final pintor = PintorFranjaOms(actividad: actividad(420), alto: 10);
      expect(pintor.escala, 420);
      expect(pintor.fraccion(420), 1);
      expect(PintorFranjaOms(actividad: actividad(0), alto: 10).escala, 360, reason: '1.2 × 300');
    });

    testWidgets('se lee como un solo bloque', (tester) async {
      final manejador = tester.ensureSemantics();
      await montar(tester, SizedBox(width: 360, child: TarjetaMetaOms(actividad: actividad(95))));
      expect(
        find.bySemanticsLabel('Meta semanal OMS. 95 de 150 min. Te faltan 55 min para lo mínimo recomendado'),
        findsOneWidget,
      );
      manejador.dispose();
    });
  });

  group('TarjetaProximoHito', () {
    testWidgets('días que faltan, la barra hacia el hito y un mensaje de ánimo (sin la automatización)', (
      tester,
    ) async {
      await montar(tester, SizedBox(width: 360, child: TarjetaProximoHito(habito: habito(34))));
      expect(find.text('Te faltan 32 días para 66'), findsOneWidget);
      expect(find.text('Vas muy bien: sigue a tu ritmo, un día a la vez.'), findsOneWidget);
      expect(find.textContaining('automatización'), findsNothing);
      expect(find.byType(BarraProgreso), findsOneWidget);
      expect(tester.widget<BarraProgreso>(find.byType(BarraProgreso)).valor, closeTo(34 / 66, 1e-9));
    });

    test('el ánimo según qué tan cerca va', () {
      final t = lookupAppLocalizations(const Locale('es'));
      expect(TarjetaProximoHito.animo(0, 7, t), t.animoEmpezar);
      expect(TarjetaProximoHito.animo(6, 7, t), t.animoManana);
      expect(TarjetaProximoHito.animo(63, 66, t), t.animoYaCasi);
      expect(TarjetaProximoHito.animo(10, 66, t), t.animoInicio);
      expect(TarjetaProximoHito.animo(34, 66, t), t.animoMitad);
      expect(TarjetaProximoHito.animo(50, 66, t), t.animoFinal);
    });

    testWidgets('singular a un día del hito; pasado el 100 apunta a la siguiente centena', (tester) async {
      await montar(tester, SizedBox(width: 360, child: TarjetaProximoHito(habito: habito(6), compacta: true)));
      expect(find.text('Te falta 1 día para 7'), findsOneWidget);
      await montar(tester, SizedBox(width: 360, child: TarjetaProximoHito(habito: habito(130), compacta: true)));
      expect(find.text('Te faltan 70 días para 200'), findsOneWidget);
    });

    testWidgets('tocarla avisa', (tester) async {
      var toques = 0;
      await montar(
        tester,
        SizedBox(
          width: 360,
          child: TarjetaProximoHito(habito: habito(3), compacta: true, onTap: () => toques++),
        ),
      );
      await tester.tap(find.byType(TarjetaProximoHito));
      expect(toques, 1);
    });
  });

  group('TarjetaConsejo y TarjetaSemanaHabitos', () {
    testWidgets('"Consejo saludable", solo el consejo: sin cita y sin enlace', (tester) async {
      await montar(tester, const SizedBox(width: 360, child: TarjetaConsejo(indice: 4)));
      expect(find.text('Consejo saludable'), findsOneWidget);
      expect(
        find.text('Repartir el estudio en varias sesiones rinde más que estudiar todo de corrido.'),
        findsOneWidget,
      );
      expect(find.text('Cepeda et al. 2006'), findsNothing);
      expect(find.byType(InkWell), findsNothing, reason: 'no se puede tocar');
    });

    testWidgets('la semana por hábito: ícono, nombre, barra y % de cada uno, con su lectura de pantalla', (
      tester,
    ) async {
      final manejador = tester.ensureSemantics();
      await montar(
        tester,
        SizedBox(
          width: 520,
          child: TarjetaSemanaHabitos(
            filas: [(habito: habito(3), cumplimiento: 66.67), (habito: habito(9), cumplimiento: 100)],
          ),
        ),
      );
      expect(find.text('Esta semana, por hábito'), findsOneWidget);
      expect(find.text('67 %'), findsOneWidget);
      expect(find.text('100 %'), findsOneWidget);
      expect(find.byType(BarraProgreso), findsNWidgets(2));
      expect(find.bySemanticsLabel('Leer: 67 % esta semana'), findsOneWidget);
      manejador.dispose();
    });
  });

  group('celebración', () {
    testWidgets('cada hito tiene su texto; el 66 dice "mediana científica"', (tester) async {
      await montar(tester, const CelebracionHito(hito: 66, habito: 'Leer'));
      await tester.pumpAndSettle();
      expect(find.text('¡66 días seguidos!'), findsOneWidget);
      expect(find.textContaining('suele tomar formar un hábito'), findsOneWidget);
      expect(find.textContaining('Lally'), findsNothing);
      for (final (hito, fragmento) in [(7, 'Primera semana'), (30, 'Un mes'), (100, 'Cien días'), (200, 'Sigue así')]) {
        await montar(tester, CelebracionHito(hito: hito, habito: 'Leer'));
        await tester.pumpAndSettle();
        expect(find.textContaining(fragmento), findsOneWidget, reason: '$hito');
      }
    });

    testWidgets('la animación dura menos de 1.5 s y no se anima si el sistema pide reducir movimiento', (tester) async {
      expect(CelebracionHito.duracion, lessThan(const Duration(milliseconds: 1500)));
      await montar(tester, const CelebracionHito(hito: 7, habito: 'Leer'));
      final animado = tester.widget<TweenAnimationBuilder<double>>(find.byKey(const ValueKey('animacion-hito')));
      expect(animado.duration, CelebracionHito.duracion);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: envolver(const CelebracionHito(hito: 7, habito: 'Leer')),
        ),
      );
      final quieto = tester.widget<TweenAnimationBuilder<double>>(find.byKey(const ValueKey('animacion-hito')));
      expect(quieto.duration, Duration.zero);
    });
  });

  testWidgets('ningún widget de progreso o de racha usa el rojo de error (doc. 04, F40)', (tester) async {
    await montar(
      tester,
      SingleChildScrollView(
        child: SizedBox(
          width: 520,
          child: Column(
            children: [
              for (final dias in [0, 3, 8, 34, 70, 120]) IndicadorRacha(dias: dias, conCapsula: true, protegida: true),
              const BarraProgreso(valor: 0.4),
              const BarraProgreso(valor: 0.4, sobreOscuro: true),
              const FilaHabito(
                icono: Icons.water_drop_outlined,
                nombre: 'Tomar agua',
                subtitulo: '2 L',
                racha: 0,
                cumplido: true,
                prioridadAlta: true,
              ),
              TarjetaMetaOms(actividad: actividad(95)),
              TarjetaProximoHito(habito: habito(0)),
              TarjetaSemanaHabitos(filas: [(habito: habito(3), cumplimiento: 40)]),
              const TarjetaConsejo(indice: 0),
              const CelebracionHito(hito: 7, habito: 'Leer'),
            ],
          ),
        ),
      ),
      tamano: const Size(520, 3000),
    );
    await tester.pumpAndSettle();
    final colores = coloresPintados(tester).toList();
    expect(colores, isNotEmpty);
    expect(colores, isNot(contains(KaizenColores.error)));
    expect(colores, isNot(contains(KaizenColores.errorFondo)));
  });
}
