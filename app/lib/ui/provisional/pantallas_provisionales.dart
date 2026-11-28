import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../data/services/servicio_sesion.dart';
import '../../routing/rutas.dart';
import '../core/tema/iconos.dart';
import '../core/adaptativo/breakpoints.dart';
import '../core/tema/medidas.dart';
import '../core/widgets/encabezado_pantalla.dart';
import '../core/widgets/estados.dart';
import '../core/widgets/tarjeta_kaizen.dart';

/// Pantallas provisionales (desde el Paso 3): cada ruta existe y muestra su título y en qué paso llega su contenido.
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
/// "Logros" desde Perfil (Paso 11): en el teléfono la barra inferior se queda con 5 destinos (Material 3).
class BotonLogros extends StatelessWidget {
  const BotonLogros({super.key});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: () => context.push(Rutas.logros),
    icon: const Icon(KaizenIconos.logros),
    label: Text(AppLocalizations.of(context).logrosBoton),
  );
}

/// "Notificaciones" desde Perfil (Paso 10), hasta que llegue la pantalla de Cuenta.
class BotonNotificaciones extends StatelessWidget {
  const BotonNotificaciones({super.key});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: () => context.push(Rutas.notificaciones),
    icon: const Icon(Icons.notifications_none),
    label: Text(AppLocalizations.of(context).notificacionesBoton),
  );
}

class BotonCerrarSesion extends StatelessWidget {
  const BotonCerrarSesion({super.key});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        await context.read<ServicioSesion>().salir();
        if (context.mounted) {
          context.go(Rutas.login);
        }
      },
      icon: const Icon(Icons.logout),
      label: Text(AppLocalizations.of(context).cerrarSesion),
    );
  }
}
