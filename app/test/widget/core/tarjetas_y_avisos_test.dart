import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/ui/core/tema/colores.dart';
import 'package:kaizen/ui/core/tema/iconos.dart';
import 'package:kaizen/ui/core/widgets/aviso_kaizen.dart';
import 'package:kaizen/ui/core/widgets/banner_sin_conexion.dart';
import 'package:kaizen/ui/core/widgets/dialogo_confirmacion.dart';
import 'package:kaizen/ui/core/widgets/estados.dart';
import 'package:kaizen/ui/core/widgets/tarjeta_kaizen.dart';
import 'package:kaizen/ui/core/widgets/tarjeta_kpi.dart';

import '../../helpers/envolver.dart';

void main() {
  group('TarjetaKaizen', () {
    testWidgets('normal: blanca con borde; destacada: texto blanco', (tester) async {
      await montar(
        tester,
        const Column(
          children: [
            TarjetaKaizen(child: Text('normal')),
            TarjetaKaizen(estilo: EstiloTarjeta.destacada, child: Text('2 de 5')),
          ],
        ),
      );
      final normal = tester.widget<Material>(
        find.ancestor(of: find.text('normal'), matching: find.byType(Material)).first,
      );
      expect(normal.color, KaizenColores.superficie);
      expect((normal.shape! as RoundedRectangleBorder).side.color, KaizenColores.borde);
      final estilo = DefaultTextStyle.of(tester.element(find.text('2 de 5'))).style;
      expect(estilo.color, KaizenColores.superficie);
    });

    testWidgets('con onTap es un botón que responde', (tester) async {
      final manejador = tester.ensureSemantics();
      var toques = 0;
      await montar(
        tester,
        TarjetaKaizen(
          estilo: EstiloTarjeta.suave,
          onTap: () => toques++,
          etiquetaSemantica: 'Sugerencia',
          child: const Text('Leer: ¿subir de 10 a 12 min?'),
        ),
      );
      await tester.tap(find.byType(TarjetaKaizen));
      expect(toques, 1);
      expect(find.bySemanticsLabel(RegExp('Sugerencia')), findsOneWidget);
      manejador.dispose();
    });
  });

  group('TarjetaKpi', () {
    testWidgets('cifra, etiqueta y variación', (tester) async {
      await montar(tester, const TarjetaKpi(valor: '1,204', etiqueta: 'Usuarios activos', variacion: 8));
      expect(find.text('1,204'), findsOneWidget);
      expect(find.text('Usuarios activos'), findsOneWidget);
      expect(tester.widget<Text>(find.text('+8 %')).style!.color, KaizenColores.azul600);
    });

    testWidgets('sin variación no la muestra; se lee como una sola frase', (tester) async {
      final manejador = tester.ensureSemantics();
      await montar(tester, const TarjetaKpi(valor: '18', etiqueta: 'Categorías'));
      expect(find.textContaining('%'), findsNothing);
      expect(find.bySemanticsLabel('Categorías: 18'), findsOneWidget);
      await montar(tester, const TarjetaKpi(valor: '76 %', etiqueta: 'Cumplimiento', variacion: -3));
      expect(find.bySemanticsLabel('Cumplimiento: 76 %, −3 %'), findsOneWidget);
      manejador.dispose();
    });
  });

  group('Avisos', () {
    testWidgets('aviso ámbar con ícono opcional', (tester) async {
      await montar(
        tester,
        const AvisoKaizen(texto: 'La foto solo se agrega desde Android.', icono: Icons.info_outline),
      );
      expect(find.text('La foto solo se agrega desde Android.'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      final caja = tester.widget<Container>(find.byType(Container).first);
      expect((caja.decoration! as BoxDecoration).color, KaizenColores.avisoFondo);
    });

    testWidgets('banner sin conexión con plural de pendientes', (tester) async {
      await montar(tester, const BannerSinConexion(pendientes: 3));
      expect(find.textContaining('Sin conexión'), findsOneWidget);
      expect(find.textContaining('3 registros por enviar'), findsOneWidget);
      await montar(tester, const BannerSinConexion(pendientes: 1));
      expect(find.textContaining('1 registro por enviar'), findsOneWidget);
      await montar(tester, const BannerSinConexion());
      expect(find.textContaining('tus cambios se guardan en este dispositivo'), findsOneWidget);
      expect(find.byIcon(KaizenIconos.sinConexion), findsOneWidget);
    });
  });

  group('Estados', () {
    testWidgets('cargando con mensaje por omisión', (tester) async {
      await montar(tester, const EstadoCargando());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Cargando…'), findsOneWidget);
    });

    testWidgets('vacío con mensaje y acción', (tester) async {
      await montar(
        tester,
        EstadoVacio(
          titulo: 'Aún no tienes hábitos',
          mensaje: 'Empieza con uno pequeño.',
          accion: FilledButton(onPressed: () {}, child: const Text('Crear hábito')),
        ),
      );
      expect(find.text('Aún no tienes hábitos'), findsOneWidget);
      expect(find.text('Empieza con uno pequeño.'), findsOneWidget);
      expect(find.text('Crear hábito'), findsOneWidget);
    });

    testWidgets('error genérico con reintentar', (tester) async {
      var reintentos = 0;
      await montar(tester, EstadoError(onReintentar: () => reintentos++));
      expect(find.text('Algo salió mal. Intenta de nuevo.'), findsOneWidget);
      await tester.tap(find.text('Reintentar'));
      expect(reintentos, 1);
    });

    testWidgets('error con mensaje propio y sin botón', (tester) async {
      await montar(tester, const EstadoError(mensaje: 'La analítica no está disponible'));
      expect(find.text('La analítica no está disponible'), findsOneWidget);
      expect(find.text('Reintentar'), findsNothing);
    });
  });

  group('DialogoConfirmacion', () {
    Future<bool?> abrir(WidgetTester tester, {bool peligroso = false}) async {
      bool? resultado;
      await montar(
        tester,
        Builder(
          builder: (context) => FilledButton(
            onPressed: () async => resultado = await DialogoConfirmacion.mostrar(
              context,
              titulo: '¿Archivar “Leer”?',
              mensaje: 'Se conserva su historial.',
              textoConfirmar: 'Archivar',
              peligroso: peligroso,
            ),
            child: const Text('abrir'),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text('¿Archivar “Leer”?'), findsOneWidget);
      expect(find.text('Se conserva su historial.'), findsOneWidget);
      return resultado;
    }

    testWidgets('confirmar devuelve true', (tester) async {
      bool? resultado;
      await montar(
        tester,
        Builder(
          builder: (context) => FilledButton(
            onPressed: () async =>
                resultado = await DialogoConfirmacion.mostrar(context, titulo: 'Título', mensaje: 'Mensaje'),
            child: const Text('abrir'),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      expect(resultado, isTrue);
    });

    testWidgets('cancelar devuelve false', (tester) async {
      await abrir(tester);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('cerrar tocando fuera cuenta como no confirmar', (tester) async {
      bool? resultado;
      await montar(
        tester,
        Builder(
          builder: (context) => FilledButton(
            onPressed: () async => resultado = await DialogoConfirmacion.mostrar(context, titulo: 'T', mensaje: 'M'),
            child: const Text('abrir'),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(resultado, isFalse);
    });

    testWidgets('peligroso: el botón de confirmar va en rojo', (tester) async {
      await abrir(tester, peligroso: true);
      final boton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Archivar'));
      expect(boton.style!.backgroundColor!.resolve({}), KaizenColores.error);
    });
  });
}
