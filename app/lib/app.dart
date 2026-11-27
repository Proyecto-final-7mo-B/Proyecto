import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'dart:async';

import 'config/dependencias.dart';
import 'config/entorno.dart';
import 'data/services/api/errores_api.dart';
import 'data/services/servicio_sesion.dart';
import 'data/sync/sincronizador.dart';
import 'l10n/gen/app_localizations.dart';
import 'routing/estado_sesion.dart';
import 'routing/router.dart';
import 'routing/rutas.dart';
import 'ui/core/adaptativo/plataforma.dart';
import 'ui/core/mensajes.dart';
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
    this.servicioSesion,
    super.key,
  });

  final Entorno entorno;

  /// Repositorios y servicios de datos. Por omisión, según `KAIZEN_FUENTE` (las pruebas pasan unos *fake*).
  final Dependencias? dependencias;

  /// Entrar, salir y restaurar la sesión. `main` lo crea antes de `runApp` para restaurar la sesión al abrir.
  final ServicioSesion? servicioSesion;

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
  late final ServicioSesion _servicio = widget.servicioSesion ?? _dependencias.crearServicioSesion(_sesion);
  late final Plataforma _plataforma = widget.plataforma ?? Plataforma.actual();
  late final GoRouter _router = crearRouter(
    sesion: _sesion,
    plataforma: _plataforma,
    entorno: widget.entorno,
    herramientasDev: widget.mostrarHerramientasDev,
    ubicacionInicial: widget.ubicacionInicial,
  );

  final _mensajes = GlobalKey<ScaffoldMessengerState>();
  late final AppLifecycleListener _ciclo;
  StreamSubscription<List<Rechazo>>? _rechazos;

  Sincronizador get _sync => _dependencias.sincronizador;

  @override
  void initState() {
    super.initState();
    // La cola sin conexión se envía al abrir, al iniciar sesión, al volver la red y al regresar la app al frente.
    _sync.haySesion = () => _sesion.usuario != null;
    _sesion.addListener(_alCambiarSesion);
    _ciclo = AppLifecycleListener(onResume: _sync.sincronizar);
    _rechazos = _sync.rechazos.listen(_avisarRechazos);
    _sync.iniciar();
  }

  void _alCambiarSesion() {
    if (_sesion.usuario != null) {
      _sync.sincronizar();
    }
  }

  /// Check-ins de la cola que el servidor no aceptó (p. ej., el hábito se archivó en otro dispositivo).
  void _avisarRechazos(List<Rechazo> rechazos) {
    final contexto = _mensajes.currentContext;
    if (contexto == null) {
      return;
    }
    final t = AppLocalizations.of(contexto);
    final motivo = mensajeDeError(ErrorApp(TipoError.desdeSufijo(rechazos.first.motivo)), t);
    _mensajes.currentState?.showSnackBar(SnackBar(content: Text(t.checkinsRechazados(rechazos.length, motivo))));
  }

  @override
  void dispose() {
    _sesion.removeListener(_alCambiarSesion);
    _ciclo.dispose();
    _rechazos?.cancel();
    _router.dispose();
    if (widget.servicioSesion == null) {
      _servicio.cerrar();
    }
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
          Provider<ServicioSesion>.value(value: _servicio),
        ],
        child: MaterialApp.router(
          routerConfig: _router,
          scaffoldMessengerKey: _mensajes,
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
