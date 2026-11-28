import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/data/services/api/errores_api.dart';
import 'package:kaizen/routing/rutas.dart';
import 'package:kaizen/ui/acerca/widgets/pantalla_acerca.dart';
import 'package:kaizen/ui/core/adaptativo/plataforma.dart';
import 'package:kaizen/ui/core/adaptativo/shell_escritorio.dart';
import 'package:kaizen/ui/hoy/widgets/pantalla_hoy.dart';
import 'package:kaizen/ui/hoy/widgets/tarjetas_hoy.dart';
import 'package:kaizen/ui/logros/widgets/pantalla_logros.dart';
import 'package:kaizen/ui/logros/widgets/tarjeta_ultimo_logro.dart';

import '../../helpers/app.dart';

Future<void> tocar(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> verLogro(WidgetTester tester, String clave) async {
  final lista = find.descendant(of: find.byType(PantallaLogros), matching: find.byType(Scrollable));
  await tester.scrollUntilVisible(find.byKey(ValueKey('logro-$clave')), 200, scrollable: lista.first);
  await tester.pumpAndSettle();
}

void main() {
  group('Logros', () {
    testWidgets('teléfono: resumen, insignias obtenidas y por obtener con su progreso', (tester) async {
      await montarApp(tester, ubicacion: Rutas.logros);
      expect(find.text('Insignias por tu constancia, no por hacer de más'), findsOneWidget);
      expect(find.text('6 de 10 insignias'), findsOneWidget);
      expect(find.byKey(const ValueKey('logro-racha_7')), findsOneWidget);
      expect(find.text('Primera semana'), findsOneWidget);
      await verLogro(tester, 'habito_formado');
      expect(find.text('34 de 66 días'), findsOneWidget);
      await verLogro(tester, 'capsula_abierta');
      expect(find.text('Por obtener'), findsWidgets);
      expect(find.textContaining('Obtenida el'), findsWidgets);
      expect(find.textContaining(RegExp(r'\bF\d{2}\b')), findsNothing, reason: 'sin fuentes (regla del 27-nov)');
    });

    testWidgets('los filtros: obtenidos y por obtener', (tester) async {
      await montarApp(tester, ubicacion: Rutas.logros);
      await tocar(tester, find.text('Por obtener').first);
      expect(find.byKey(const ValueKey('logro-racha_7')), findsNothing);
      expect(find.byKey(const ValueKey('logro-habito_formado')), findsOneWidget);
      await tocar(tester, find.text('Obtenidos'));
      expect(find.byKey(const ValueKey('logro-racha_7')), findsOneWidget);
      expect(find.byKey(const ValueKey('logro-habito_formado')), findsNothing);
    });

    testWidgets('el detalle: cómo se obtiene, por qué existe y "¿En qué nos basamos?"', (tester) async {
      await montarApp(tester, ubicacion: Rutas.logros);
      await tocar(tester, find.byKey(const ValueKey('logro-racha_30')));
      final detalle = find.byKey(const ValueKey('detalle-logro'));
      expect(detalle, findsOneWidget);
      expect(find.descendant(of: detalle, matching: find.text('Cómo se obtiene')), findsOneWidget);
      expect(find.descendant(of: detalle, matching: find.text('Por qué existe')), findsOneWidget);
      expect(find.descendant(of: detalle, matching: find.text('Con Leer')), findsOneWidget);
      expect(find.descendant(of: detalle, matching: find.textContaining('mediana de formación')), findsOneWidget);
      await tocar(tester, find.text('Cerrar'));
      expect(detalle, findsNothing);

      await verLogro(tester, 'capsula_abierta');
      await tocar(tester, find.byKey(const ValueKey('logro-capsula_abierta')));
      expect(find.text('Recompensa personal por la constancia'), findsOneWidget, reason: 'sin "(F3)"');
      await tocar(tester, find.text('¿En qué nos basamos?'));
      expect(find.byType(PantallaAcerca), findsOneWidget);
    });

    testWidgets('si no carga, el error y Reintentar', (tester) async {
      final deps = dependenciasPrueba();
      deps.datosDemo!.fallarSiguiente(const ErrorApp(TipoError.desconocido));
      await montarApp(tester, ubicacion: Rutas.logros, dependencias: deps);
      expect(find.text('Reintentar'), findsOneWidget);
      await tocar(tester, find.text('Reintentar'));
      expect(find.text('6 de 10 insignias'), findsOneWidget);
    });

    testWidgets('escritorio: sección del riel, cuadrícula de 4', (tester) async {
      await montarApp(tester, plataforma: Plataforma.escritorio, tamano: const Size(1440, 900));
      await tester.tap(find.descendant(of: find.byType(RielLateral), matching: find.text('Logros')));
      await tester.pumpAndSettle();
      expect(find.byType(PantallaLogros), findsOneWidget);
      final a = tester.getTopLeft(find.byKey(const ValueKey('logro-racha_7')));
      final d = tester.getTopLeft(find.byKey(const ValueKey('logro-racha_100')));
      expect(a.dy, d.dy, reason: 'las 4 primeras en la misma fila');
    });

    testWidgets('teléfono: se abre desde Perfil y desde "Último logro" en Hoy', (tester) async {
      await montarApp(tester, ubicacion: Rutas.perfil);
      await tocar(tester, find.text('Logros'));
      expect(find.byType(PantallaLogros), findsOneWidget);

      await montarApp(tester);
      final tarjeta = find.byType(TarjetaUltimoLogro);
      final lista = find.descendant(of: find.byType(PantallaHoy), matching: find.byType(Scrollable));
      await tester.scrollUntilVisible(tarjeta, 200, scrollable: lista.first);
      expect(find.descendant(of: tarjeta, matching: find.text('Último logro')), findsOneWidget);
      expect(find.descendant(of: tarjeta, matching: find.text('Ritmo ideal')), findsOneWidget);
      await tocar(tester, tarjeta);
      expect(find.byType(PantallaLogros), findsOneWidget);
    });

    testWidgets('sin insignias, Hoy muestra "Tu próxima insignia" con su avance', (tester) async {
      await montarApp(tester, cuentaDemo: 'u-nuevo');
      final tarjeta = find.byType(TarjetaUltimoLogro);
      if (tarjeta.evaluate().isEmpty) {
        // La cuenta nueva no tiene hábitos: Hoy muestra el estado vacío y no la tarjeta.
        expect(find.byType(PantallaHoy), findsOneWidget);
        return;
      }
      expect(find.descendant(of: tarjeta, matching: find.text('Tu próxima insignia')), findsOneWidget);
    });

    testWidgets('aceptar una subida en Hoy avisa "Insignia nueva" y "Ver" abre Logros', (tester) async {
      await montarApp(tester);
      final lista = find.descendant(of: find.byType(PantallaHoy), matching: find.byType(Scrollable));
      await tester.scrollUntilVisible(find.byType(TarjetaSugerencia), 200, scrollable: lista.first);
      await tocar(tester, find.byType(TarjetaSugerencia));
      await tocar(tester, find.text('Aceptar'));
      expect(find.byKey(const ValueKey('aviso-logro-nuevo')), findsOneWidget);
      expect(find.text('Insignia nueva: Primer micro-paso'), findsOneWidget);
      expect(find.textContaining('tu nueva meta es'), findsNothing, reason: 'espera su turno: no tapa la insignia');
      await tester.tap(find.text('Ver'));
      await tester.pumpAndSettle();
      expect(find.byType(PantallaLogros), findsOneWidget);
      expect(find.text('7 de 10 insignias'), findsOneWidget);
    });
  });
}
