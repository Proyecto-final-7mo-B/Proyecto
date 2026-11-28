import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/logros/logros_repository.dart';
import '../../../domain/models/logro.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../routing/rutas.dart';
import '../../../utils/fechas.dart';
import '../../core/mensajes.dart';
import '../../core/tema/colores.dart';
import '../../core/tema/medidas.dart';
import '../../core/widgets/barra_progreso.dart';
import '../../core/widgets/boton_volver.dart';
import '../../core/widgets/chips_seleccion.dart';
import '../../core/widgets/encabezado_pantalla.dart';
import '../../core/widgets/estados.dart';
import '../../core/widgets/tarjeta_kaizen.dart';
import '../view_models/logros_viewmodel.dart';
import 'insignia_logro.dart';

/// `/logros` (Paso 11, doc. 05): las insignias obtenidas y por obtener, con su progreso ("21 de 30 días") y la fecha
/// en que se obtuvieron. Tocar una abre su detalle: cómo se obtiene y por qué existe (sin fuentes: regla del 27-nov;
/// "¿En qué nos basamos?" lleva a Acerca de Kaizen).
class PantallaLogros extends StatefulWidget {
  const PantallaLogros({super.key});

  static const double anchoMaximo = 1100;
  static const double anchoEscritorio = 900;

  @override
  State<PantallaLogros> createState() => _PantallaLogrosState();
}

class _PantallaLogrosState extends State<PantallaLogros> {
  late final LogrosViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = LogrosViewModel(logros: context.read<LogrosRepository>());
    _vm.cargar.ejecutar();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, limites) {
        final ancho = limites.maxWidth >= PantallaLogros.anchoEscritorio;
        final columnas = limites.maxWidth >= 1200 ? 4 : (ancho ? 3 : 2);
        return ListenableBuilder(
          listenable: Listenable.merge([_vm, _vm.cargar]),
          builder: (context, _) {
            if (_vm.logros.isEmpty) {
              if (_vm.cargar.error case final error?) {
                return EstadoError(mensaje: mensajeDeError(error, t), onReintentar: _vm.cargar.ejecutar);
              }
              return const EstadoCargando();
            }
            final visibles = _vm.visibles;
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: PantallaLogros.anchoMaximo),
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: ancho
                          ? const EdgeInsets.fromLTRB(KaizenMedidas.e32, 28, KaizenMedidas.e32, 0)
                          : const EdgeInsets.fromLTRB(KaizenMedidas.e20, KaizenMedidas.e24, KaizenMedidas.e20, 0),
                      sliver: SliverList.list(
                        children: [
                          if (ancho)
                            EncabezadoPantalla(titulo: t.tituloLogros, subtitulo: t.subtituloLogros)
                          else
                            EncabezadoInterno(
                              titulo: t.tituloLogros,
                              subtitulo: t.subtituloLogros,
                              respaldo: Rutas.hoy,
                            ),
                          const SizedBox(height: KaizenMedidas.e20),
                          _Resumen(obtenidos: _vm.obtenidos, total: _vm.total),
                          const SizedBox(height: KaizenMedidas.e16),
                          ChipsSeleccion<FiltroLogros>(
                            opciones: [
                              (valor: FiltroLogros.todos, etiqueta: t.logrosFiltroTodos),
                              (valor: FiltroLogros.obtenidos, etiqueta: t.logrosFiltroObtenidos),
                              (valor: FiltroLogros.porObtener, etiqueta: t.logrosFiltroPorObtener),
                            ],
                            seleccionados: {_vm.filtro},
                            onCambio: (s) => _vm.elegirFiltro(s.first),
                          ),
                          const SizedBox(height: KaizenMedidas.e16),
                          if (visibles.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: KaizenMedidas.e24),
                              child: Text(
                                _vm.filtro == FiltroLogros.obtenidos ? t.logrosSinObtenidos : t.logrosTodosObtenidos,
                                style: Theme.of(context).textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: ancho ? KaizenMedidas.e32 : KaizenMedidas.e20),
                      sliver: SliverGrid.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columnas,
                          mainAxisSpacing: KaizenMedidas.e12,
                          crossAxisSpacing: KaizenMedidas.e12,
                          mainAxisExtent: 240,
                        ),
                        itemCount: visibles.length,
                        itemBuilder: (context, i) =>
                            TarjetaLogro(logro: visibles[i], onTap: () => mostrarDetalleLogro(context, visibles[i])),
                      ),
                    ),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        ancho ? KaizenMedidas.e32 : KaizenMedidas.e20,
                        KaizenMedidas.e20,
                        ancho ? KaizenMedidas.e32 : KaizenMedidas.e20,
                        KaizenMedidas.e32,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          t.logrosNota,
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.obtenidos, required this.total});

  final int obtenidos;
  final int total;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    return TarjetaKaizen(
      relleno: const EdgeInsets.all(KaizenMedidas.e20),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_outlined, color: KaizenColores.verdeProgreso, size: 32),
          const SizedBox(width: KaizenMedidas.e16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.logrosResumen(obtenidos, total), style: texto.titleMedium),
                const SizedBox(height: KaizenMedidas.e8),
                BarraProgreso(
                  valor: total == 0 ? 0 : obtenidos / total,
                  etiquetaSemantica: t.logrosResumen(obtenidos, total),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Una insignia en la cuadrícula: el círculo, el nombre y la fecha (o el progreso, o "Por obtener").
class TarjetaLogro extends StatelessWidget {
  const TarjetaLogro({required this.logro, required this.onTap, super.key});

  final Logro logro;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final estado = _estado(t, logro);
    return Semantics(
      button: true,
      label: '${logro.nombre}. $estado',
      excludeSemantics: true,
      child: TarjetaKaizen(
        key: ValueKey('logro-${logro.clave}'),
        relleno: EdgeInsets.zero,
        child: InkWell(
          borderRadius: KaizenMedidas.bordeTarjeta,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(KaizenMedidas.e16),
            child: Column(
              children: [
                InsigniaLogro(logro: logro),
                const SizedBox(height: KaizenMedidas.e12),
                Text(
                  logro.nombre,
                  style: texto.titleSmall!.copyWith(
                    color: logro.obtenido ? KaizenColores.texto : KaizenColores.textoSecundario,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: KaizenMedidas.e4),
                Text(
                  logro.descripcion,
                  style: texto.bodySmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                if (logro.muestraProgreso) ...[
                  BarraProgreso(valor: logro.avance, alto: 6),
                  const SizedBox(height: KaizenMedidas.e4),
                ],
                Text(
                  estado,
                  style: texto.labelMedium!.copyWith(
                    color: logro.obtenido ? KaizenColores.verdeProgreso : KaizenColores.textoSecundario,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _estado(AppLocalizations t, Logro l) {
  if (l.obtenido) {
    final en = l.obtenidoEn;
    return en == null ? t.logrosFiltroObtenidos : t.logroObtenidoEl(Fechas.corta(en.toLocal()));
  }
  if (l.muestraProgreso) {
    return t.logroProgresoDias(l.progreso, l.objetivo);
  }
  return t.logroPorObtener;
}

/// El detalle de un logro: cómo se obtiene, por qué existe, cuándo y con qué hábito se obtuvo.
Future<void> mostrarDetalleLogro(BuildContext context, Logro logro) => showDialog<void>(
  context: context,
  builder: (context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    return AlertDialog(
      key: const ValueKey('detalle-logro'),
      icon: Center(child: InsigniaLogro(logro: logro, tamano: 72)),
      title: Text(logro.nombre, textAlign: TextAlign.center),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                _estado(t, logro),
                style: texto.labelLarge!.copyWith(
                  color: logro.obtenido ? KaizenColores.verdeProgreso : KaizenColores.textoSecundario,
                ),
              ),
            ),
            if (logro.obtenido && logro.habitoNombre != null)
              Center(child: Text(t.logroConHabito(logro.habitoNombre!), style: texto.bodySmall)),
            if (logro.muestraProgreso) ...[
              const SizedBox(height: KaizenMedidas.e8),
              BarraProgreso(valor: logro.avance),
            ],
            const SizedBox(height: KaizenMedidas.e16),
            Text(t.logroComoSeObtiene, style: texto.titleSmall),
            const SizedBox(height: KaizenMedidas.e4),
            Text(logro.descripcion, style: texto.bodyMedium),
            const SizedBox(height: KaizenMedidas.e12),
            Text(t.logroPorQue, style: texto.titleSmall),
            const SizedBox(height: KaizenMedidas.e4),
            Text(logro.porqueParaMostrar, style: texto.bodyMedium),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.push(Rutas.acerca);
          },
          child: Text(t.enQueNosBasamos),
        ),
        FilledButton(onPressed: () => Navigator.of(context).pop(), child: Text(t.logroCerrar)),
      ],
    );
  },
);
