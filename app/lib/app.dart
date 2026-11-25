import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config/entorno.dart';
import 'l10n/gen/app_localizations.dart';

/// Raíz de la app. En el Paso 1 solo muestra una pantalla temporal; el tema llega en el Paso 2 y las rutas en el Paso 3.
class KaizenApp extends StatelessWidget {
  const KaizenApp({required this.entorno, super.key});

  final Entorno entorno;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitulo,
      debugShowCheckedModeBanner: false,
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX'), Locale('es')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _PantallaInicialTemporal(entorno: entorno),
    );
  }
}

/// Pantalla provisional del Paso 1: confirma que la app arranca y con qué fuente de datos.
class _PantallaInicialTemporal extends StatelessWidget {
  const _PantallaInicialTemporal({required this.entorno});

  final Entorno entorno;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.appTitulo, style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 8),
            Text(t.appLema),
            const SizedBox(height: 24),
            Text(t.proyectoBaseListo),
            Text(t.fuenteDeDatos(entorno.fuente.name)),
          ],
        ),
      ),
    );
  }
}
