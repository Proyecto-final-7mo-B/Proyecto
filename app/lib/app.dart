import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'config/entorno.dart';
import 'l10n/gen/app_localizations.dart';
import 'ui/core/tema/medidas.dart';
import 'ui/core/tema/tema.dart';
import 'ui/core/widgets/logo_kaizen.dart';
import 'ui/dev/galeria_componentes.dart';

/// Raíz de la app. Desde el Paso 2 usa el tema de Kaizen; las rutas llegan en el Paso 3.
class KaizenApp extends StatelessWidget {
  const KaizenApp({required this.entorno, this.mostrarHerramientasDev = kDebugMode, super.key});

  final Entorno entorno;

  /// Muestra el acceso a la galería de componentes. Por omisión solo en depuración (nunca en release).
  final bool mostrarHerramientasDev;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitulo,
      debugShowCheckedModeBanner: false,
      theme: KaizenTema.claro(),
      themeMode: ThemeMode.light,
      locale: const Locale('es', 'MX'),
      supportedLocales: const [Locale('es', 'MX'), Locale('es')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: _PantallaInicialTemporal(entorno: entorno, mostrarHerramientasDev: mostrarHerramientasDev),
    );
  }
}

/// Pantalla provisional: confirma que la app arranca, con qué fuente de datos y (en depuración) abre la galería.
/// En el Paso 3 la reemplaza el router (`/login`, `/hoy` y `/dev/componentes`).
class _PantallaInicialTemporal extends StatelessWidget {
  const _PantallaInicialTemporal({required this.entorno, required this.mostrarHerramientasDev});

  final Entorno entorno;
  final bool mostrarHerramientasDev;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(KaizenMedidas.e24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const LogoKaizen(lado: 64),
              const SizedBox(height: KaizenMedidas.e16),
              Text(t.appTitulo, style: texto.displayLarge),
              const SizedBox(height: KaizenMedidas.e8),
              Text(t.appLema, style: texto.bodyLarge),
              const SizedBox(height: KaizenMedidas.e24),
              Text(t.fuenteDeDatos(entorno.fuente.name), style: texto.bodySmall),
              if (mostrarHerramientasDev) ...[
                const SizedBox(height: KaizenMedidas.e24),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const GaleriaComponentes())),
                  child: Text(t.verComponentes),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
