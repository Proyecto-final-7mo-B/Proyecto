import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaizen/l10n/gen/app_localizations.dart';
import 'package:kaizen/ui/core/tema/tema.dart';

/// Envuelve un widget con el tema de Kaizen, los textos en es-MX y un `Scaffold`, como en la app.
Widget envolver(Widget hijo, {bool centrado = true}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: KaizenTema.claro(),
    locale: const Locale('es', 'MX'),
    supportedLocales: const [Locale('es', 'MX'), Locale('es')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(
      body: centrado
          ? Center(
              child: Padding(padding: const EdgeInsets.all(16), child: hijo),
            )
          : hijo,
    ),
  );
}

/// Monta [hijo] en una pantalla de [tamano] (por omisión, un teléfono de 390 × 844 como los bosquejos móviles).
Future<void> montar(
  WidgetTester tester,
  Widget hijo, {
  Size tamano = const Size(390, 844),
  bool centrado = true,
}) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(envolver(hijo, centrado: centrado));
  await tester.pump();
}
