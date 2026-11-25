import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../routing/estado_sesion.dart';
import '../../../routing/rutas.dart';
import '../tema/colores.dart';
import '../tema/iconos.dart';
import '../tema/medidas.dart';
import '../widgets/icono_escalera.dart';
import 'destinos.dart';
import 'plataforma.dart';

/// Búsqueda rápida (Ctrl+K en escritorio y web): por ahora busca secciones de la app. En el Paso 7 se agregan los
/// hábitos.
abstract final class Busqueda {
  /// Qué navegadores tienen la paleta abierta (por navegador, no global: cada app/ventana tiene el suyo).
  static final Expando<bool> _abiertaEn = Expando('paleta abierta');

  /// Lo que se puede buscar: todos los destinos de la plataforma, más Perfil, Privacidad, Mi semana y Nuevo hábito.
  static List<Destino> opciones(BuildContext context) {
    final t = AppLocalizations.of(context);
    final plataforma = PlataformaApp.de(context);
    final esAdmin = context.read<EstadoSesion>().esAdmin;
    final lista = [
      ...destinosDe(t: t, plataforma: plataforma, esAdmin: esAdmin, compacto: false),
      Destino(ruta: Rutas.nuevoHabito, etiqueta: t.nuevoHabito, icono: KaizenIconos.agregar),
      Destino(ruta: Rutas.miSemana, etiqueta: t.tituloMiSemana, icono: Icons.date_range_outlined),
      Destino(ruta: Rutas.perfil, etiqueta: t.navPerfil, icono: KaizenIconos.perfil),
      Destino(ruta: Rutas.privacidad, etiqueta: t.tituloPrivacidad, icono: Icons.privacy_tip_outlined),
      if (esAdmin && plataforma.permiteAdmin)
        Destino(ruta: Rutas.indicadores, etiqueta: t.tituloIndicadores, icono: Icons.insights_outlined),
    ];
    return lista;
  }

  /// Filtra por texto sin importar mayúsculas ni acentos ("hab" encuentra "Hábitos").
  static List<Destino> filtrar(List<Destino> opciones, String consulta) {
    final q = KaizenIconos.normalizar(consulta);
    if (q.isEmpty) {
      return opciones;
    }
    return [
      for (final o in opciones)
        if (KaizenIconos.normalizar(o.etiqueta).contains(q)) o,
    ];
  }

  /// Abre la paleta y navega a lo elegido. Si ya está abierta, no abre otra.
  static Future<void> abrir(BuildContext context) async {
    final navegador = Navigator.of(context, rootNavigator: true);
    if (_abiertaEn[navegador] ?? false) {
      return;
    }
    _abiertaEn[navegador] = true;
    try {
      final ruta = await showDialog<String>(
        context: context,
        builder: (_) => PaletaBusqueda(opciones: opciones(context)),
      );
      if (ruta != null && context.mounted) {
        context.go(ruta);
      }
    } finally {
      _abiertaEn[navegador] = false;
    }
  }
}

/// Envuelve el *shell* para que Ctrl+K (o ⌘K) abra la búsqueda.
class AtajoBusqueda extends StatelessWidget {
  const AtajoBusqueda({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    void abrir() => Busqueda.abrir(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): abrir,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): abrir,
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}

/// Diálogo con un campo y la lista de resultados. Enter elige el primero; Esc cierra.
class PaletaBusqueda extends StatefulWidget {
  const PaletaBusqueda({required this.opciones, super.key});

  final List<Destino> opciones;

  @override
  State<PaletaBusqueda> createState() => _PaletaBusquedaState();
}

class _PaletaBusquedaState extends State<PaletaBusqueda> {
  String _consulta = '';

  List<Destino> get _resultados => Busqueda.filtrar(widget.opciones, _consulta);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final resultados = _resultados;
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.fromLTRB(16, 96, 16, 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(KaizenMedidas.e12),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(prefixIcon: const Icon(KaizenIconos.buscar), hintText: t.buscarPista),
                onChanged: (v) => setState(() => _consulta = v),
                onSubmitted: (_) {
                  if (resultados.isNotEmpty) {
                    Navigator.of(context).pop(resultados.first.ruta);
                  }
                },
              ),
            ),
            const Divider(),
            if (resultados.isEmpty)
              Padding(
                padding: const EdgeInsets.all(KaizenMedidas.e24),
                child: Text(t.sinResultados, style: Theme.of(context).textTheme.bodySmall),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: KaizenMedidas.e8),
                  children: [
                    for (final d in resultados)
                      ListTile(
                        leading: d.icono == null ? const IconoEscalera() : Icon(d.icono),
                        title: Text(d.etiqueta),
                        subtitle: Text(d.ruta),
                        onTap: () => Navigator.of(context).pop(d.ruta),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Campo "Buscar · Ctrl K" del encabezado en escritorio (bosquejos de escritorio). Al tocarlo abre la paleta.
class CampoBuscar extends StatelessWidget {
  const CampoBuscar({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '${t.buscar} (${t.atajoBuscar})',
      child: ExcludeSemantics(
        child: Material(
          color: KaizenColores.superficie,
          shape: const RoundedRectangleBorder(
            borderRadius: KaizenMedidas.bordeControl,
            side: BorderSide(color: KaizenColores.bordeCampo),
          ),
          child: InkWell(
            borderRadius: KaizenMedidas.bordeControl,
            onTap: () => Busqueda.abrir(context),
            child: SizedBox(
              width: 250,
              height: 46,
              child: Row(
                children: [
                  const SizedBox(width: KaizenMedidas.e12),
                  const Icon(KaizenIconos.buscar, size: 20, color: KaizenColores.textoSecundario),
                  const SizedBox(width: KaizenMedidas.e8),
                  Expanded(
                    child: Text(t.buscar, style: texto.bodyMedium!.copyWith(color: KaizenColores.textoSecundario)),
                  ),
                  Text(t.atajoBuscar, style: texto.labelSmall!.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(width: KaizenMedidas.e16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
