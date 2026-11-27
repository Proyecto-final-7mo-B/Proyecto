import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../config/constantes.dart';
import '../../../data/repositories/habitos/habitos_repository.dart';
import '../../../domain/models/evidencia.dart';
import '../../../domain/models/habito.dart';
import '../../../domain/models/recomendacion.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../routing/rutas.dart';
import '../../core/adaptativo/breakpoints.dart';
import '../../core/apariencia_habito.dart';
import '../../core/formatos.dart';
import '../../core/mensajes.dart';
import '../../core/tema/colores.dart';
import '../../core/tema/iconos.dart';
import '../../core/tema/medidas.dart';
import '../../core/widgets/boton_volver.dart';
import '../../core/widgets/chips_seleccion.dart';
import '../../core/widgets/encabezado_pantalla.dart';
import '../../core/widgets/estados.dart';
import '../../core/widgets/selector_segmentado.dart';
import '../../core/widgets/tarjeta_kaizen.dart';
import '../view_models/recomendados_viewmodel.dart';
import 'chips_con_icono.dart';

/// `/habitos/nuevo` (decisión del 27-nov): hábitos saludables recomendados por categoría y subcategoría, con su meta,
/// frecuencia y momento ya definidos por la evidencia. Al elegir uno solo se decide la prioridad y la cápsula.
/// "Hábito personalizado" abre el formulario del Paso 7 (`/habitos/nuevo/personalizado`).
///
/// Aquí no se muestran fuentes: solo lo recomendado y la medición. Las fuentes están en "Acerca de Kaizen".
class PantallaRecomendados extends StatefulWidget {
  const PantallaRecomendados({super.key});

  /// Ancho del contenido desde el que las tarjetas van en dos columnas y el detalle abre como diálogo.
  static const double anchoDosColumnas = 900;

  @override
  State<PantallaRecomendados> createState() => _PantallaRecomendadosState();
}

class _PantallaRecomendadosState extends State<PantallaRecomendados> {
  late final RecomendadosViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = RecomendadosViewModel(habitos: context.read<HabitosRepository>());
    _vm.cargar.ejecutar();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  /// El formulario reemplaza a esta pantalla: al guardar, se regresa a donde se empezó.
  void _personalizado() => context.pushReplacement(Rutas.nuevoHabitoPersonalizado);

  Future<void> _abrir(HabitoRecomendado r, {required bool ancho}) async {
    _vm.elegir(r);
    final creado = ancho
        ? await showDialog<Habito>(
            context: context,
            builder: (_) => Dialog(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(KaizenMedidas.e24),
                  child: DetalleRecomendacion(vm: _vm),
                ),
              ),
            ),
          )
        : await showModalBottomSheet<Habito>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(KaizenMedidas.e20, 0, KaizenMedidas.e20, KaizenMedidas.e20),
                child: DetalleRecomendacion(vm: _vm),
              ),
            ),
          );
    if (creado == null || !mounted) {
      return;
    }
    final t = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(t.habitoCreado(creado.nombre))));
    final capsula = _vm.capsula;
    if (capsula != null) {
      context.pushReplacement(Rutas.nuevaCapsulaDe(creado.id, objetivo: capsula));
    } else if (context.canPop()) {
      context.pop(true);
    } else {
      context.go(Rutas.habito(creado.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([_vm, _vm.cargar]),
      builder: (context, _) {
        if (!_vm.cargado) {
          if (_vm.cargar.error case final error?) {
            return EstadoError(mensaje: mensajeDeError(error, t), onReintentar: _vm.cargar.ejecutar);
          }
          return const EstadoCargando();
        }
        return LayoutBuilder(
          builder: (context, limites) {
            final ancho = limites.maxWidth >= PantallaRecomendados.anchoDosColumnas;
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: anchoMaximoContenido),
                child: ListView(
                  padding: ancho
                      ? const EdgeInsets.fromLTRB(KaizenMedidas.e32, 28, KaizenMedidas.e32, KaizenMedidas.e32)
                      : const EdgeInsets.fromLTRB(
                          KaizenMedidas.e20,
                          KaizenMedidas.e24,
                          KaizenMedidas.e20,
                          KaizenMedidas.e32,
                        ),
                  children: [
                    if (ancho)
                      EncabezadoPantalla(
                        titulo: t.tituloNuevoHabito,
                        subtitulo: t.subtituloNuevoHabito,
                        acciones: [
                          OutlinedButton.icon(
                            onPressed: _personalizado,
                            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
                            icon: const Icon(KaizenIconos.editar),
                            label: Text(t.habitoPersonalizado),
                          ),
                        ],
                      )
                    else
                      EncabezadoInterno(titulo: t.tituloNuevoHabito, respaldo: Rutas.habitos),
                    const SizedBox(height: KaizenMedidas.e16),
                    Text(t.recomendadosIntro, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: KaizenMedidas.e8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => context.push(Rutas.acerca),
                        icon: const Icon(KaizenIconos.consejo, size: 18),
                        label: Text(t.enQueNosBasamos),
                      ),
                    ),
                    if (!ancho) ...[
                      const SizedBox(height: KaizenMedidas.e8),
                      _BotonPersonalizado(onTap: _personalizado),
                    ],
                    const SizedBox(height: KaizenMedidas.e20),
                    ChipsConIcono<String>(
                      opciones: [
                        for (final c in _vm.categorias)
                          (
                            valor: c.clave,
                            etiqueta: c.nombre,
                            icono: KaizenIconos.porNombre(c.icono),
                            color: colorDeCategoria(c),
                          ),
                      ],
                      seleccionado: _vm.categoria,
                      onCambio: (c) => _vm.categoria = c,
                    ),
                    const SizedBox(height: KaizenMedidas.e8),
                    if (_vm.grupos.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: KaizenMedidas.e24),
                        child: Text(t.recomendadosVacio),
                      ),
                    for (final g in _vm.grupos) ..._grupo(context, g, ancho: ancho),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _grupo(BuildContext context, GrupoRecomendados g, {required bool ancho}) {
    final texto = Theme.of(context).textTheme;
    final primero = g.recomendados.first;
    final color = colorDeCategoria(primero.categoria);
    final tarjetas = [
      for (final r in g.recomendados)
        TarjetaRecomendacion(recomendacion: r, onTap: () => _abrir(r, ancho: ancho)),
    ];
    return [
      const SizedBox(height: KaizenMedidas.e16),
      Semantics(
        header: true,
        child: Row(
          children: [
            Icon(iconoDeSubcategoria(g.subcategoria, categoria: primero.categoria), size: 20, color: color),
            const SizedBox(width: KaizenMedidas.e8),
            Text(g.subcategoria.nombre, style: texto.titleMedium),
          ],
        ),
      ),
      const SizedBox(height: KaizenMedidas.e8),
      if (ancho)
        LayoutBuilder(
          builder: (context, limites) {
            final lado = (limites.maxWidth - KaizenMedidas.e12) / 2;
            return Wrap(
              spacing: KaizenMedidas.e12,
              runSpacing: KaizenMedidas.e8,
              children: [for (final w in tarjetas) SizedBox(width: lado, child: w)],
            );
          },
        )
      else
        for (final w in tarjetas) Padding(padding: const EdgeInsets.only(bottom: KaizenMedidas.e8), child: w),
    ];
  }
}

class _BotonPersonalizado extends StatelessWidget {
  const _BotonPersonalizado({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    return TarjetaKaizen(
      estilo: EstiloTarjeta.suave,
      onTap: onTap,
      child: Row(
        children: [
          const Icon(KaizenIconos.editar, color: KaizenColores.texto),
          const SizedBox(width: KaizenMedidas.e16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.habitoPersonalizado, style: texto.titleSmall),
                Text(t.habitoPersonalizadoDetalle, style: texto.bodySmall),
              ],
            ),
          ),
          const Icon(KaizenIconos.siguiente),
        ],
      ),
    );
  }
}

/// "30 min · L-V".
String metaYFrecuencia(HabitoRecomendado r, AppLocalizations t) =>
    '${numero(r.meta)} ${r.unidad} · ${textoFrecuencia(r.frecuencia, t)}';

/// Una recomendación: ícono y color de su categoría, nombre, meta y frecuencia, y cuándo hacerlo.
class TarjetaRecomendacion extends StatelessWidget {
  const TarjetaRecomendacion({required this.recomendacion, required this.onTap, super.key});

  final HabitoRecomendado recomendacion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final r = recomendacion;
    final color = colorDeCategoria(r.categoria);
    final meta = metaYFrecuencia(r, t);
    return Semantics(
      button: true,
      label: t.recomendadoSemantica(r.nombre, meta, r.momento),
      child: ExcludeSemantics(
        child: TarjetaKaizen(
          onTap: onTap,
          relleno: const EdgeInsets.all(KaizenMedidas.e12),
          child: Row(
            children: [
              Container(
                width: KaizenMedidas.ladoIconoHabito,
                height: KaizenMedidas.ladoIconoHabito,
                decoration: BoxDecoration(color: KaizenColores.fondoDe(color), borderRadius: KaizenMedidas.bordeControl),
                child: Icon(iconoDeSubcategoria(r.subcategoria, categoria: r.categoria), color: color, size: 22),
              ),
              const SizedBox(width: KaizenMedidas.e12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.nombre, style: texto.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(meta, style: texto.bodySmall),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(KaizenIconos.reloj, size: 14, color: KaizenColores.textoSecundario),
                        const SizedBox(width: KaizenMedidas.e4),
                        Expanded(
                          child: Text(r.momento, style: texto.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(KaizenIconos.siguiente, color: KaizenColores.textoSecundario),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lo que dice la recomendación elegida y lo único que se elige: prioridad y cápsula. "Crear hábito" cierra el
/// diálogo (o la hoja) devolviendo el hábito creado.
class DetalleRecomendacion extends StatelessWidget {
  const DetalleRecomendacion({required this.vm, super.key});

  final RecomendadosViewModel vm;

  static String? rango(HabitoRecomendado r, AppLocalizations t) => switch (r.zona) {
    ZonaEvidencia.sinReferencia => t.recomendadoSinRango,
    ZonaEvidencia.alto || ZonaEvidencia.excesivo => t.recomendadoReducir,
    _ when r.optimoDesde != null && r.optimoHasta != null =>
      numero(r.optimoDesde!) == numero(r.optimoHasta!)
          ? t.recomendadoRangoExacto(numero(r.optimoDesde!), r.unidad)
          : t.recomendadoRango(numero(r.optimoDesde!), numero(r.optimoHasta!), r.unidad),
    _ => null,
  };

  Future<void> _crear(BuildContext context) async {
    await vm.crear.ejecutar();
    if (!context.mounted) {
      return;
    }
    if (vm.crear.resultado?.valorONulo case final h?) {
      Navigator.of(context).pop(h);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: Listenable.merge([vm, vm.crear]),
      builder: (context, _) {
        final r = vm.elegido;
        if (r == null) {
          return const SizedBox.shrink();
        }
        final color = colorDeCategoria(r.categoria);
        final textoRango = rango(r, t);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: KaizenColores.fondoDe(color), borderRadius: KaizenMedidas.bordeControl),
                  child: Icon(iconoDeSubcategoria(r.subcategoria, categoria: r.categoria), color: color),
                ),
                const SizedBox(width: KaizenMedidas.e12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(header: true, child: Text(r.nombre, style: texto.titleLarge)),
                      Text('${r.categoria.nombre} · ${r.subcategoria.nombre}', style: texto.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: KaizenMedidas.e16),
            Text(metaYFrecuencia(r, t), style: texto.titleMedium),
            if (textoRango != null) ...[
              const SizedBox(height: KaizenMedidas.e4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    r.zona == ZonaEvidencia.optimo ? Icons.verified_outlined : Icons.info_outline,
                    size: 18,
                    color: r.zona == ZonaEvidencia.optimo ? KaizenColores.verdeProgreso : KaizenColores.textoSecundario,
                  ),
                  const SizedBox(width: KaizenMedidas.e8),
                  Expanded(child: Text(textoRango, style: texto.bodySmall)),
                ],
              ),
            ],
            const SizedBox(height: KaizenMedidas.e16),
            Text(t.recomendadoCuando, style: texto.labelLarge),
            Text(r.momento, style: texto.bodyMedium),
            const SizedBox(height: KaizenMedidas.e12),
            Text(t.recomendadoPorQue, style: texto.labelLarge),
            Text(r.porque, style: texto.bodyMedium),
            const Divider(height: KaizenMedidas.e32),
            Text(t.recomendadoSoloEliges, style: texto.bodySmall),
            const SizedBox(height: KaizenMedidas.e12),
            Text(t.campoPrioridad, style: texto.labelLarge),
            const SizedBox(height: KaizenMedidas.e8),
            SelectorSegmentado<int>(
              opciones: [
                (valor: Prioridad.alta, etiqueta: t.prioridadAlta),
                (valor: Prioridad.media, etiqueta: t.prioridadMedia),
                (valor: Prioridad.baja, etiqueta: t.prioridadBaja),
              ],
              seleccionado: vm.prioridad,
              onCambio: (p) => vm.prioridad = p,
            ),
            const SizedBox(height: KaizenMedidas.e16),
            Text(t.campoCapsula, style: texto.labelLarge),
            const SizedBox(height: KaizenMedidas.e8),
            ChipsSeleccion<int>(
              opciones: [
                (valor: 0, etiqueta: t.sinCapsula),
                for (final d in Limites.rachasObjetivo) (valor: d, etiqueta: t.nDias(d)),
              ],
              seleccionados: {vm.capsula ?? 0},
              onCambio: (s) => vm.capsula = (s.firstOrNull ?? 0) == 0 ? null : s.first,
            ),
            if (vm.crear.error case final error?) ...[
              const SizedBox(height: KaizenMedidas.e12),
              Text(mensajeDeError(error, t), style: texto.bodySmall!.copyWith(color: KaizenColores.error)),
            ],
            const SizedBox(height: KaizenMedidas.e20),
            FilledButton(
              onPressed: vm.crear.ejecutando ? null : () => _crear(context),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
              child: Text(t.crearHabito),
            ),
          ],
        );
      },
    );
  }
}
