import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/entorno.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../routing/estado_sesion.dart';
import '../../routing/rutas.dart';
import '../core/adaptativo/breakpoints.dart';
import '../core/tema/medidas.dart';
import '../core/widgets/encabezado_pantalla.dart';
import '../core/widgets/estados.dart';
import '../core/widgets/logo_kaizen.dart';
import '../core/widgets/tarjeta_kaizen.dart';

/// Pantallas provisionales del Paso 3: cada ruta existe y muestra su título y en qué paso llega su contenido.
/// Cada paso siguiente reemplaza la suya (Hoy en el 6, Hábitos en el 7…). Esta carpeta desaparece en el Paso 14.
class PantallaProvisional extends StatelessWidget {
  const PantallaProvisional({
    required this.titulo,
    required this.paso,
    this.detalle,
    this.acciones = const [],
    super.key,
  });

  final String titulo;
  final int paso;

  /// Dato de la ruta, p. ej., el id del hábito.
  final String? detalle;
  final List<Widget> acciones;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final compacto = TamanoPantalla.de(context) == TamanoPantalla.compacto;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: anchoMaximoContenido),
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: compacto ? 20 : 32, vertical: 28),
          children: [
            EncabezadoPantalla(titulo: titulo, subtitulo: detalle),
            const SizedBox(height: KaizenMedidas.e24),
            TarjetaKaizen(
              child: EstadoVacio(
                icono: Icons.construction_outlined,
                titulo: t.llegaEnPaso(paso),
                accion: acciones.isEmpty ? null : Wrap(spacing: 12, runSpacing: 12, children: acciones),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Entrar (provisional hasta el Paso 5). En depuración permite entrar como usuario o admin de prueba para revisar
/// la navegación.
class PantallaEntrarProvisional extends StatelessWidget {
  const PantallaEntrarProvisional({required this.entorno, required this.herramientasDev, super.key});

  final Entorno entorno;
  final bool herramientasDev;

  /// Mismas personas que el poblador del entorno local (`demo@kaizen.test`, `admin@kaizen.test`).
  static const UsuarioSesion usuarioDemo = UsuarioSesion(
    nombre: 'Daniela',
    rol: RolUsuario.usuario,
    region: 'MX-NORTE',
  );
  static const UsuarioSesion adminDemo = UsuarioSesion(nombre: 'Admin', rol: RolUsuario.admin, region: 'MX-CENTRO-SUR');

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final sesion = context.read<EstadoSesion>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(KaizenMedidas.e24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  const LogoKaizen(lado: 64),
                  const SizedBox(height: KaizenMedidas.e16),
                  Text(t.appTitulo, style: texto.displayLarge),
                  const SizedBox(height: KaizenMedidas.e8),
                  Text(t.appLema, style: texto.bodyLarge),
                  const SizedBox(height: KaizenMedidas.e24),
                  TarjetaKaizen(
                    relleno: const EdgeInsets.all(KaizenMedidas.e24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(header: true, child: Text(t.tituloEntrar, style: texto.headlineSmall)),
                        const SizedBox(height: KaizenMedidas.e8),
                        Text(t.llegaEnPaso(5), style: texto.bodySmall),
                        if (herramientasDev) ...[
                          const SizedBox(height: KaizenMedidas.e20),
                          FilledButton(onPressed: () => sesion.iniciar(usuarioDemo), child: Text(t.entrarDemo)),
                          const SizedBox(height: KaizenMedidas.e12),
                          OutlinedButton(onPressed: () => sesion.iniciar(adminDemo), child: Text(t.entrarAdminDemo)),
                          const SizedBox(height: KaizenMedidas.e8),
                          TextButton(onPressed: () => context.push(Rutas.componentes), child: Text(t.verComponentes)),
                        ],
                      ],
                    ),
                  ),
                  if (herramientasDev) ...[
                    const SizedBox(height: KaizenMedidas.e16),
                    Text(t.fuenteDeDatos(entorno.fuente.name), style: texto.bodySmall),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `/restablecer?token=…` (provisional hasta el Paso 5). Nunca muestra el token.
class PantallaRestablecerProvisional extends StatelessWidget {
  const PantallaRestablecerProvisional({required this.token, super.key});

  final String? token;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final valido = token != null && token!.isNotEmpty;
    return Scaffold(
      body: SafeArea(
        child: PantallaProvisional(
          titulo: t.tituloRestablecer,
          paso: 5,
          detalle: valido ? t.enlaceRecibido : t.enlaceInvalido,
          acciones: [OutlinedButton(onPressed: () => context.go(Rutas.login), child: Text(t.tituloEntrar))],
        ),
      ),
    );
  }
}

/// Ruta que no existe.
class PantallaNoEncontrada extends StatelessWidget {
  const PantallaNoEncontrada({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      body: EstadoVacio(
        icono: Icons.explore_off_outlined,
        titulo: t.paginaNoEncontrada,
        accion: FilledButton(onPressed: () => context.go(Rutas.hoy), child: Text(t.irAHoy)),
      ),
    );
  }
}

/// Botón "Cerrar sesión" del perfil provisional (el perfil real llega en el Paso 13).
class BotonCerrarSesion extends StatelessWidget {
  const BotonCerrarSesion({super.key});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        context.read<EstadoSesion>().cerrar();
        context.go(Rutas.login);
      },
      icon: const Icon(Icons.logout),
      label: Text(AppLocalizations.of(context).cerrarSesion),
    );
  }
}
