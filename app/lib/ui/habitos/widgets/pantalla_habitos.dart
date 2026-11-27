import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/capsulas/capsulas_repository.dart';
import '../../../data/repositories/habitos/habitos_repository.dart';
import '../../../domain/models/habito.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../routing/rutas.dart';
import '../../../utils/reloj.dart';
import '../../core/adaptativo/breakpoints.dart';
import '../../core/adaptativo/plataforma.dart';
import '../../core/adaptativo/recarga_al_volver.dart';
import '../../core/formatos.dart';
import '../../core/mensajes.dart';
import '../../core/tema/colores.dart';
import '../../core/tema/iconos.dart';
import '../../core/tema/medidas.dart';
import '../../core/widgets/encabezado_pantalla.dart';
import '../../core/widgets/estados.dart';
import '../../core/widgets/indicador_racha.dart';
import '../../core/widgets/selector_segmentado.dart';
import '../../core/widgets/tarjeta_kaizen.dart';
import '../view_models/habitos_viewmodel.dart';
import '../../core/apariencia_habito.dart';

/// `/habitos`: activos y archivados. Tocar un hábito abre su detalle; "Nuevo hábito" abre el formulario.
class PantallaHabitos extends StatefulWidget {
  const PantallaHabitos({super.key});

  @override
  State<PantallaHabitos> createState() => _PantallaHabitosState();
}

class _PantallaHabitosState extends State<PantallaHabitos> with RecargaAlVolver {
  @override
  String get rutaPropia => Rutas.habitos;

  @override
  Future<void> recargarAlVolver() => _vm.cargar.ejecutar();

  late final HabitosViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = HabitosViewModel(
      habitos: context.read<HabitosRepository>(),
      capsulas: context.read<CapsulasRepository>(),
      reloj: context.read<Reloj>(),
    );
    _vm.cargar.ejecutar();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  void _abrir(String ruta) => context.push(ruta);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final compacto = TamanoPantalla.de(context) == TamanoPantalla.compacto;
    final esWeb = PlataformaApp.de(context) == Plataforma.web;
    return ListenableBuilder(
      listenable: Listenable.merge([_vm, _vm.cargar]),
      builder: (context, _) {
        if (!_vm.cargado) {
          if (_vm.cargar.error case final error?) {
            return EstadoError(mensaje: mensajeDeError(error, t), onReintentar: _vm.cargar.ejecutar);
          }
          return const EstadoCargando();
        }
        final lista = _vm.visibles;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: anchoMaximoContenido),
            child: RefreshIndicator(
              onRefresh: _vm.cargar.ejecutar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  compacto ? KaizenMedidas.e20 : KaizenMedidas.e32,
                  compacto ? KaizenMedidas.e24 : 28,
                  compacto ? KaizenMedidas.e20 : KaizenMedidas.e32,
                  KaizenMedidas.e32,
                ),
                children: [
                  EncabezadoPantalla(
                    titulo: t.tituloHabitos,
                    acciones: [
                      if (compacto)
                        IconButton.filled(
                          tooltip: t.nuevoHabito,
                          onPressed: () => _abrir(Rutas.nuevoHabito),
                          style: IconButton.styleFrom(
                            backgroundColor: KaizenColores.marino800,
                            foregroundColor: KaizenColores.superficie,
                            minimumSize: const Size(48, 48),
                            shape: const RoundedRectangleBorder(borderRadius: KaizenMedidas.bordeControl),
                          ),
                          icon: const Icon(KaizenIconos.agregar),
                        )
                      // En web, "Nuevo hábito" ya está en la barra superior.
                      else if (!esWeb)
                        FilledButton.icon(
                          onPressed: () => _abrir(Rutas.nuevoHabito),
                          style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                          icon: const Icon(KaizenIconos.agregar),
                          label: Text(t.nuevoHabito),
                        ),
                    ],
                  ),
                  const SizedBox(height: KaizenMedidas.e20),
                  SelectorSegmentado<bool>(
                    opciones: [
                      (valor: false, etiqueta: '${t.habitosActivos} (${_vm.activos.length})'),
                      (valor: true, etiqueta: '${t.habitosArchivados} (${_vm.archivados.length})'),
                    ],
                    seleccionado: _vm.verArchivados,
                    onCambio: (v) => _vm.verArchivados = v,
                  ),
                  const SizedBox(height: KaizenMedidas.e16),
                  if (lista.isEmpty)
                    TarjetaKaizen(
                      child: _vm.verArchivados
                          ? EstadoVacio(titulo: t.sinArchivados)
                          : EstadoVacio(
                              titulo: t.sinHabitosHoyTitulo,
                              mensaje: t.sinHabitosHoyTexto,
                              accion: FilledButton(
                                onPressed: () => _abrir(Rutas.nuevoHabito),
                                child: Text(t.crearPrimerHabito),
                              ),
                            ),
                    )
                  else
                    for (final h in lista)
                      Padding(
                        padding: const EdgeInsets.only(bottom: KaizenMedidas.e8),
                        child: FilaHabitoLista(
                          key: ValueKey(h.id),
                          habito: h,
                          conCapsula: _vm.tieneCapsula(h.id),
                          onTap: () => _abrir(Rutas.habito(h.id)),
                        ),
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Renglón de la lista: ícono de la categoría, nombre, "10 min · L-V", racha y "›". Los archivados van atenuados y
/// con la etiqueta "Archivado".
class FilaHabitoLista extends StatelessWidget {
  const FilaHabitoLista({required this.habito, required this.onTap, this.conCapsula = false, super.key});

  final Habito habito;
  final bool conCapsula;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final h = habito;
    return Opacity(
      opacity: h.activo ? 1 : 0.7,
      child: TarjetaKaizen(
        onTap: onTap,
        relleno: const EdgeInsets.symmetric(horizontal: KaizenMedidas.e12, vertical: KaizenMedidas.e12),
        child: Row(
          children: [
            Container(
              width: KaizenMedidas.ladoIconoHabito,
              height: KaizenMedidas.ladoIconoHabito,
              decoration: BoxDecoration(
                color: KaizenColores.fondoDe(h.color),
                borderRadius: KaizenMedidas.bordeControl,
              ),
              child: Icon(h.icono, color: h.color),
            ),
            const SizedBox(width: KaizenMedidas.e16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(h.nombre, style: texto.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    h.activo ? subtituloHabito(h, t) : '${subtituloHabito(h, t)} · ${t.etiquetaArchivado}',
                    style: texto.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: KaizenMedidas.e8),
            if (h.activo) IndicadorRacha(dias: h.racha.actual, conCapsula: conCapsula),
            const SizedBox(width: KaizenMedidas.e4),
            const Icon(KaizenIconos.siguiente, color: KaizenColores.textoSecundario),
          ],
        ),
      ),
    );
  }
}
