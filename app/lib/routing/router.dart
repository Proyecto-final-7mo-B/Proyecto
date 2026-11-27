import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../config/entorno.dart';
import '../l10n/gen/app_localizations.dart';
import '../ui/auth/widgets/pantalla_entrar.dart';
import '../ui/auth/widgets/pantalla_restablecer.dart';
import '../ui/core/adaptativo/plataforma.dart';
import '../ui/core/adaptativo/shell_adaptativo.dart';
import '../ui/dev/galeria_componentes.dart';
import '../ui/habitos/widgets/pantalla_detalle_habito.dart';
import '../ui/habitos/widgets/pantalla_formulario_habito.dart';
import '../ui/habitos/widgets/pantalla_habitos.dart';
import '../ui/hoy/widgets/pantalla_hoy.dart';
import '../ui/provisional/pantallas_provisionales.dart';
import 'estado_sesion.dart';
import 'guardas.dart';
import 'rutas.dart';

/// Router de la app. Las pantallas con sesión van dentro del *shell* adaptativo (barra inferior, riel o barra
/// superior); el login, restablecer y la galería van solas. Cuando cambia la sesión se vuelven a evaluar las guardas.
GoRouter crearRouter({
  required EstadoSesion sesion,
  required Plataforma plataforma,
  required Entorno entorno,
  required bool herramientasDev,
  String ubicacionInicial = Rutas.hoy,
}) {
  /// Página sin animación: cambiar de sección no debe "deslizar" toda la pantalla.
  GoRouterPageBuilder provisional(
    String Function(AppLocalizations t) titulo,
    int paso, {
    String? Function(GoRouterState estado)? detalle,
    List<Widget> Function()? acciones,
  }) {
    return (context, estado) => NoTransitionPage<void>(
      key: estado.pageKey,
      child: PantallaProvisional(
        titulo: titulo(AppLocalizations.of(context)),
        paso: paso,
        detalle: detalle?.call(estado),
        acciones: acciones?.call() ?? const [],
      ),
    );
  }

  return GoRouter(
    initialLocation: ubicacionInicial,
    refreshListenable: sesion,
    redirect: (context, estado) =>
        redirigir(ubicacion: estado.uri, sesion: sesion, plataforma: plataforma, herramientasDev: herramientasDev),
    errorBuilder: (context, estado) => const PantallaNoEncontrada(),
    routes: [
      GoRoute(
        path: Rutas.login,
        builder: (context, estado) =>
            PantallaEntrar(cuentasDePrueba: entorno.usaFakes && herramientasDev, herramientasDev: herramientasDev),
      ),
      GoRoute(
        path: Rutas.restablecer,
        builder: (context, estado) => PantallaRestablecer(token: estado.uri.queryParameters['token']),
      ),
      GoRoute(path: Rutas.componentes, builder: (context, estado) => const GaleriaComponentes()),
      ShellRoute(
        builder: (context, estado, hijo) => ShellAdaptativo(ubicacion: estado.uri.path, child: hijo),
        routes: [
          GoRoute(
            path: Rutas.hoy,
            pageBuilder: (context, estado) => NoTransitionPage<void>(key: estado.pageKey, child: const PantallaHoy()),
          ),
          GoRoute(
            path: Rutas.habitos,
            pageBuilder: (context, estado) =>
                NoTransitionPage<void>(key: estado.pageKey, child: const PantallaHabitos()),
            routes: [
              GoRoute(
                path: 'nuevo',
                pageBuilder: (context, estado) =>
                    NoTransitionPage<void>(key: estado.pageKey, child: const PantallaFormularioHabito()),
              ),
              GoRoute(
                path: ':id',
                pageBuilder: (context, estado) => NoTransitionPage<void>(
                  key: estado.pageKey,
                  child: PantallaDetalleHabito(habitoId: estado.pathParameters['id']!),
                ),
                routes: [
                  GoRoute(
                    path: 'editar',
                    pageBuilder: (context, estado) => NoTransitionPage<void>(
                      key: estado.pageKey,
                      child: PantallaFormularioHabito(habitoId: estado.pathParameters['id']),
                    ),
                  ),
                  GoRoute(
                    path: 'escalera',
                    pageBuilder: provisional((t) => t.tituloEscaleraHabito, 9, detalle: (e) => e.pathParameters['id']),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: Rutas.progreso,
            pageBuilder: provisional((t) => t.tituloProgreso, 12),
            routes: [GoRoute(path: 'semana', pageBuilder: provisional((t) => t.tituloMiSemana, 12))],
          ),
          GoRoute(path: Rutas.escalera, pageBuilder: provisional((t) => t.tituloEscalera, 9)),
          GoRoute(path: Rutas.laboratorio, pageBuilder: provisional((t) => t.tituloLaboratorio, 10)),
          GoRoute(
            path: Rutas.capsulas,
            pageBuilder: provisional((t) => t.tituloCapsulas, 11),
            routes: [
              GoRoute(
                path: 'nueva',
                pageBuilder: provisional(
                  (t) => t.tituloNuevaCapsula,
                  11,
                  detalle: (e) => e.uri.queryParameters['habito'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: Rutas.perfil,
            pageBuilder: provisional((t) => t.tituloPerfil, 13, acciones: () => const [BotonCerrarSesion()]),
            routes: [GoRoute(path: 'privacidad', pageBuilder: provisional((t) => t.tituloPrivacidad, 13))],
          ),
          GoRoute(
            path: Rutas.admin,
            pageBuilder: provisional((t) => t.tituloAdmin, 14),
            routes: [GoRoute(path: 'indicadores', pageBuilder: provisional((t) => t.tituloIndicadores, 14))],
          ),
        ],
      ),
    ],
  );
}
