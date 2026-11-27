import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/habitos/habitos_repository.dart';
import '../../../domain/models/habito.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../routing/rutas.dart';
import '../../../utils/reloj.dart';
import '../../core/adaptativo/breakpoints.dart';
import '../../core/adaptativo/recarga_al_volver.dart';
import '../../core/formatos.dart';
import '../../core/mensajes.dart';
import '../../core/tema/colores.dart';
import '../../core/tema/iconos.dart';
import '../../core/tema/medidas.dart';
import '../../core/widgets/boton_volver.dart';
import '../../core/widgets/encabezado_pantalla.dart';
import '../../core/widgets/estados.dart';
import '../../core/widgets/tarjeta_kaizen.dart';
import '../../core/widgets/tarjeta_kpi.dart';
import '../view_models/detalle_habito_viewmodel.dart';
import 'tarjeta_evidencia_habito.dart';
import 'tarjetas_detalle.dart';

/// `/habitos/:id` (bosquejo 04). Teléfono: racha, calendario e historial. Con 900 px o más: KPIs, tendencia y nivel a
/// la izquierda; calendario e historial a la derecha.
class PantallaDetalleHabito extends StatefulWidget {
  const PantallaDetalleHabito({required this.habitoId, super.key});

  final String habitoId;

  static const double anchoDosColumnas = 900;

  @override
  State<PantallaDetalleHabito> createState() => _PantallaDetalleHabitoState();
}

class _PantallaDetalleHabitoState extends State<PantallaDetalleHabito> with RecargaAlVolver {
  @override
  String get rutaPropia => Rutas.habito(widget.habitoId);

  @override
  Future<void> recargarAlVolver() => _vm.cargar.ejecutar();

  late final DetalleHabitoViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = DetalleHabitoViewModel(
      habitos: context.read<HabitosRepository>(),
      habitoId: widget.habitoId,
      reloj: context.read<Reloj>(),
    );
    _vm.cargar.ejecutar();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  // Al volver de editar, RecargaAlVolver vuelve a cargar el hábito.
  void _editar() => context.push(Rutas.editarHabito(widget.habitoId));

  Future<void> _reactivar() async {
    final t = AppLocalizations.of(context);
    await _vm.reactivar.ejecutar();
    if (!mounted) {
      return;
    }
    final r = _vm.reactivar.resultado;
    final mensaje = switch (r?.errorONulo) {
      final error? => mensajeDeError(error, t),
      null => t.habitoReactivado(_vm.habito!.nombre),
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  /// "Aprendizaje · 10 min · diario · Nivel 3".
  String _subtitulo(Habito h, AppLocalizations t) => [
    h.subcategoria.nombre,
    '${numero(h.meta)} ${h.unidad}',
    textoFrecuencia(h.frecuencia, t),
    if (h.nivel > 1) t.nivelN(h.nivel),
  ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([_vm, _vm.cargar, _vm.reactivar]),
      builder: (context, _) {
        final h = _vm.habito;
        if (h == null) {
          if (_vm.cargar.error case final error?) {
            return EstadoError(mensaje: mensajeDeError(error, t), onReintentar: _vm.cargar.ejecutar);
          }
          return const EstadoCargando();
        }
        return LayoutBuilder(
          builder: (context, limites) => RefreshIndicator(
            onRefresh: _vm.cargar.ejecutar,
            child: limites.maxWidth >= PantallaDetalleHabito.anchoDosColumnas
                ? _dosColumnas(context, h)
                : _unaColumna(context, h),
          ),
        );
      },
    );
  }

  Widget _unaColumna(BuildContext context, Habito h) {
    final t = AppLocalizations.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(KaizenMedidas.e20, KaizenMedidas.e24, KaizenMedidas.e20, KaizenMedidas.e32),
      children: [
        EncabezadoInterno(
          titulo: h.nombre,
          subtitulo: _subtitulo(h, t),
          respaldo: Rutas.habitos,
          acciones: [IconButton(tooltip: t.editar, onPressed: _editar, icon: const Icon(KaizenIconos.editar))],
        ),
        const SizedBox(height: KaizenMedidas.e20),
        if (!h.activo) ...[_avisoArchivado(context), const SizedBox(height: KaizenMedidas.e12)],
        TarjetaRacha(actual: h.racha.actual, maxima: h.racha.maxima),
        const SizedBox(height: KaizenMedidas.e12),
        TarjetaEvidenciaHabito(habito: h),
        const SizedBox(height: KaizenMedidas.e12),
        _calendario(),
        const SizedBox(height: KaizenMedidas.e12),
        TarjetaHistorial(registros: _vm.historial, unidad: h.unidad),
      ],
    );
  }

  Widget _dosColumnas(BuildContext context, Habito h) {
    final t = AppLocalizations.of(context);
    final c30 = _vm.cumplimiento30;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: anchoMaximoContenido),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(KaizenMedidas.e32, 28, KaizenMedidas.e32, KaizenMedidas.e32),
          children: [
            EncabezadoPantalla(
              titulo: h.nombre,
              subtitulo: _subtitulo(h, t),
              acciones: [
                OutlinedButton.icon(
                  onPressed: _editar,
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 46)),
                  icon: const Icon(KaizenIconos.editar),
                  label: Text(t.editar),
                ),
              ],
            ),
            const SizedBox(height: KaizenMedidas.e20),
            if (!h.activo) ...[_avisoArchivado(context), const SizedBox(height: KaizenMedidas.e16)],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: TarjetaKpi(valor: '${h.racha.actual}', etiqueta: t.rachaActual),
                            ),
                            const SizedBox(width: KaizenMedidas.e12),
                            Expanded(
                              child: TarjetaKpi(valor: '${h.racha.maxima}', etiqueta: t.rachaMaxima),
                            ),
                            const SizedBox(width: KaizenMedidas.e12),
                            Expanded(
                              child: TarjetaKpi(
                                valor: c30 == null ? '—' : t.porcentaje(c30.round()),
                                etiqueta: t.cumplimiento30,
                                variacion: _vm.variacion30,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: KaizenMedidas.e12),
                      TarjetaTendencia(valores: _vm.tendencia),
                      const SizedBox(height: KaizenMedidas.e12),
                      TarjetaNivel(
                        nivel: _vm.escalera?.nivelActual ?? h.nivel,
                        total: _vm.totalNiveles,
                        meta: h.meta,
                        unidad: h.unidad,
                        siguiente: _vm.siguienteMeta,
                        escaleraActiva: h.escaleraActiva,
                        onVerEscalera: () => context.push(Rutas.escaleraHabito(h.id)),
                      ),
                      const SizedBox(height: KaizenMedidas.e12),
                      TarjetaEvidenciaHabito(habito: h),
                    ],
                  ),
                ),
                const SizedBox(width: KaizenMedidas.e20),
                SizedBox(
                  width: 360,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _calendario(),
                      const SizedBox(height: KaizenMedidas.e12),
                      TarjetaHistorial(registros: _vm.historial, unidad: h.unidad),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _calendario() => TarjetaCalendarioHabito(
    mes: _vm.mes,
    hoy: _vm.hoy,
    niveles: _vm.nivelesMes,
    porcentaje: _vm.cumplimientoMes,
    onAnterior: _vm.puedeRetroceder ? _vm.mesAnterior : null,
    onSiguiente: _vm.puedeAvanzar ? _vm.mesSiguiente : null,
  );

  Widget _avisoArchivado(BuildContext context) {
    final t = AppLocalizations.of(context);
    return TarjetaKaizen(
      estilo: EstiloTarjeta.suave,
      child: Row(
        children: [
          const Icon(KaizenIconos.archivar, color: KaizenColores.texto),
          const SizedBox(width: KaizenMedidas.e12),
          Expanded(child: Text(t.estaArchivado, style: Theme.of(context).textTheme.bodyMedium)),
          const SizedBox(width: KaizenMedidas.e8),
          FilledButton.icon(
            onPressed: _vm.reactivar.ejecutando ? null : _reactivar,
            icon: const Icon(KaizenIconos.reactivar),
            label: Text(t.reactivar),
          ),
        ],
      ),
    );
  }
}
