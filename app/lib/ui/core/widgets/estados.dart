import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../tema/colores.dart';
import '../tema/iconos.dart';
import '../tema/medidas.dart';

/// Los tres estados que toda pantalla con datos debe poder mostrar: cargando, vacío y error.

class EstadoCargando extends StatelessWidget {
  const EstadoCargando({this.mensaje, super.key});

  final String? mensaje;

  @override
  Widget build(BuildContext context) {
    final texto = mensaje ?? AppLocalizations.of(context).cargando;
    return Center(
      child: Semantics(
        liveRegion: true,
        label: texto,
        child: ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox.square(dimension: 32, child: CircularProgressIndicator(strokeWidth: 3)),
              const SizedBox(height: KaizenMedidas.e16),
              Text(texto, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class EstadoVacio extends StatelessWidget {
  const EstadoVacio({required this.titulo, this.mensaje, this.icono = KaizenIconos.vacio, this.accion, super.key});

  final String titulo;
  final String? mensaje;
  final IconData icono;

  /// Botón opcional ("Crear mi primer hábito").
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    return _Plantilla(
      icono: icono,
      colorIcono: KaizenColores.azul600,
      fondoIcono: KaizenColores.azul100,
      titulo: titulo,
      mensaje: mensaje,
      accion: accion,
    );
  }
}

class EstadoError extends StatelessWidget {
  const EstadoError({this.mensaje, this.onReintentar, super.key});

  /// Por omisión, el mensaje genérico.
  final String? mensaje;
  final VoidCallback? onReintentar;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return _Plantilla(
      icono: KaizenIconos.error,
      colorIcono: KaizenColores.error,
      fondoIcono: KaizenColores.errorFondo,
      titulo: mensaje ?? t.errorGenerico,
      liveRegion: true,
      accion: onReintentar == null
          ? null
          : OutlinedButton.icon(onPressed: onReintentar, icon: const Icon(Icons.refresh), label: Text(t.reintentar)),
    );
  }
}

class _Plantilla extends StatelessWidget {
  const _Plantilla({
    required this.icono,
    required this.colorIcono,
    required this.fondoIcono,
    required this.titulo,
    this.mensaje,
    this.accion,
    this.liveRegion = false,
  });

  final IconData icono;
  final Color colorIcono;
  final Color fondoIcono;
  final String titulo;
  final String? mensaje;
  final Widget? accion;
  final bool liveRegion;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KaizenMedidas.e24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: fondoIcono, borderRadius: KaizenMedidas.bordeTarjeta),
                child: Icon(icono, color: colorIcono, size: 28),
              ),
            ),
            const SizedBox(height: KaizenMedidas.e16),
            Semantics(
              liveRegion: liveRegion,
              child: Text(titulo, style: texto.titleMedium, textAlign: TextAlign.center),
            ),
            if (mensaje != null) ...[
              const SizedBox(height: KaizenMedidas.e8),
              Text(mensaje!, style: texto.bodySmall, textAlign: TextAlign.center),
            ],
            if (accion != null) ...[const SizedBox(height: KaizenMedidas.e20), accion!],
          ],
        ),
      ),
    );
  }
}
