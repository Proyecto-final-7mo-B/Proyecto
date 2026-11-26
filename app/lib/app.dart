import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'config/dependencias.dart';
import 'config/entorno.dart';
import 'l10n/gen/app_localizations.dart';
import 'routing/estado_sesion.dart';
import 'routing/router.dart';
import 'routing/rutas.dart';
import 'ui/core/adaptativo/plataforma.dart';
import 'ui/core/tema/tema.dart';

/// Raíz de la app: tema de Kaizen, textos es-MX, sesión y router con el *shell* adaptativo.
class KaizenApp extends StatefulWidget {
  const KaizenApp({
    required this.entorno,
    this.mostrarHerramientasDev = kDebugMode,
    this.plataforma,
    this.sesion,
    this.ubicacionInicial = Rutas.hoy,
    this.dependencias,
    super.key,
  });

  final Entorno entorno;

  /// Repositorios y servicios de datos. Por omisión, según `KAIZEN_FUENTE` (las pruebas pasan unos *fake*).
  final Dependencias? dependencias;

  /// Galería de componentes y entrada de prueba. Por omisión solo en depuración (nunca en *release*).
  final bool mostrarHerramientasDev;

  /// Por omisión, la real. Las pruebas la fijan para probar cada *shell*.
  final Plataforma? plataforma;

  /// Por omisión empieza sin sesión. Las pruebas pueden pasar una ya iniciada.
  final EstadoSesion? sesion;

  final String ubicacionInicial;

  @override
  State<KaizenApp> createState() => _KaizenAppState();
}

class _KaizenAppState extends State<KaizenApp> {
  late final Dependencias _dependencias = widget.dependencias ?? Dependencias.desdeEntorno(widget.entorno);
  late final EstadoSesion _sesion = widget.sesion ?? EstadoSesion();
  late final Plataforma _plataforma = widget.plataforma ?? Plataforma.actual();
  late final GoRouter _router = crearRouter(
    sesion: _sesion,
    plataforma: _plataforma,
    entorno: widget.entorno,
    herramientasDev: widget.mostrarHerramientasDev,
    ubicacionInicial: widget.ubicacionInicial,
  );

  @override
  void dispose() {
    _router.dispose();
    if (widget.sesion == null) {
      _sesion.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlataformaApp(
      plataforma: _plataforma,
      child: MultiProvider(
        providers: [
          ..._dependencias.proveedores(),
          ChangeNotifierProvider<EstadoSesion>.value(value: _sesion),
        ],
        child: MaterialApp.router(
          routerConfig: _router,
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
        ),
      ),
    );
  }
}
