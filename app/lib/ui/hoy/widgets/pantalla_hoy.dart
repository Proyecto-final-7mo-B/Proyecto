import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/capsulas/capsulas_repository.dart';
import '../../../data/repositories/escalera/escalera_repository.dart';
import '../../../data/repositories/habitos/habitos_repository.dart';
import '../../../data/repositories/progreso/progreso_repository.dart';
import '../../../data/repositories/registros/registros_repository.dart';
import '../../../domain/models/escalera.dart';
import '../../../domain/models/habito.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../routing/estado_sesion.dart';
import '../../../routing/rutas.dart';
import '../../../utils/fechas.dart';
import '../../../utils/reloj.dart';
import '../../core/adaptativo/breakpoints.dart';
import '../../core/adaptativo/plataforma.dart';
import '../../core/formatos.dart';
import '../../core/mensajes.dart';
import '../../core/tema/colores.dart';
import '../../core/tema/iconos.dart';
import '../../core/tema/medidas.dart';
import '../../core/widgets/calendario_mes.dart';
import '../../core/widgets/encabezado_pantalla.dart';
import '../../core/widgets/estados.dart';
import '../../core/widgets/fila_habito.dart';
import '../../core/widgets/tarjeta_kaizen.dart';
import '../view_models/hoy_viewmodel.dart';
import 'tarjetas_hoy.dart';

/// `/hoy` (bosquejo 02). En el teléfono, una columna; con 900 px o más de contenido, dos columnas con el calendario
/// del mes y el micro-paso a la derecha.
class PantallaHoy extends StatefulWidget {
  const PantallaHoy({super.key});

  /// Ancho del contenido desde el que se usan dos columnas.
  static const double anchoDosColumnas = 900;

  @override
  State<PantallaHoy> createState() => _PantallaHoyState();
}

class _PantallaHoyState extends State<PantallaHoy> {
  late final HoyViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = HoyViewModel(
      habitos: context.read<HabitosRepository>(),
      registros: context.read<RegistrosRepository>(),
      progreso: context.read<ProgresoRepository>(),
      escalera: context.read<EscaleraRepository>(),
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

  void _avisar(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _alternar(Habito h) async {
    final error = await _vm.alternar(h);
    if (error != null && mounted) {
      final t = AppLocalizations.of(context);
      _avisar(t.checkinNoGuardado(h.nombre, mensajeDeError(error, t)));
    }
  }

  Future<void> _responder(bool aceptar) async {
    final s = _vm.sugerencia;
    final unidad = _unidadDe(s);
    await _vm.responder.ejecutar(aceptar);
    if (!mounted) {
      return;
    }
    final t = AppLocalizations.of(context);
    final r = _vm.responder.resultado;
    final respuesta = r?.valorONulo;
    if (respuesta != null) {
      _avisar(
        respuesta.nivel != null && respuesta.metaNueva != null
            ? t.metaAceptada(respuesta.nivel!, numero(respuesta.metaNueva!), unidad)
            : t.metaMantenida,
      );
    } else if (r?.errorONulo case final error?) {
      _avisar(mensajeDeError(error, t));
    }
  }

  /// La unidad viene del hábito (la sugerencia no la trae).
  String _unidadDe(Sugerencia? s) =>
      _vm.habitos.where((h) => h.id == s?.habitoId).map((h) => h.unidad).firstOrNull ?? '';

  Future<void> _opcionesSugerencia(Sugerencia s) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (contexto) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(KaizenMedidas.e20, 0, KaizenMedidas.e20, KaizenMedidas.e20),
        child: TarjetaMicroPaso(
          sugerencia: s,
          unidad: _unidadDe(s),
          ocupado: false,
          onResponder: (aceptar) {
            Navigator.of(contexto).pop();
            _responder(aceptar);
          },
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_vm, _vm.cargar, _vm.responder]),
      builder: (context, _) {
        if (!_vm.cargado) {
          if (_vm.cargar.error case final error?) {
            return EstadoError(
              mensaje: mensajeDeError(error, AppLocalizations.of(context)),
              onReintentar: _vm.cargar.ejecutar,
            );
          }
          return const EstadoCargando();
        }
        return LayoutBuilder(
          builder: (context, limites) => RefreshIndicator(
            onRefresh: _vm.cargar.ejecutar,
            child: limites.maxWidth >= PantallaHoy.anchoDosColumnas ? _dosColumnas(context) : _unaColumna(context),
          ),
        );
      },
    );
  }

  // ───────────────────────── Teléfono ─────────────────────────

  Widget _unaColumna(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final nombre = context.watch<EstadoSesion>().usuario?.nombre ?? '';
    final s = _vm.sugerencia;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(KaizenMedidas.e20, KaizenMedidas.e24, KaizenMedidas.e20, KaizenMedidas.e32),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Fechas.larga(_vm.hoy), style: texto.bodyMedium!.copyWith(color: KaizenColores.textoSecundario)),
                  const SizedBox(height: 2),
                  Semantics(header: true, child: Text(saludo(_vm.ahora, nombre, t), style: texto.headlineMedium)),
                ],
              ),
            ),
            const SizedBox(width: KaizenMedidas.e12),
            IconButton.filled(
              tooltip: t.nuevoHabito,
              onPressed: () => context.push(Rutas.nuevoHabito),
              // El tema pinta los IconButton con el color del texto; este va relleno, con el "+" blanco.
              style: IconButton.styleFrom(
                backgroundColor: KaizenColores.marino800,
                foregroundColor: KaizenColores.superficie,
                minimumSize: const Size(52, 52),
                shape: const RoundedRectangleBorder(borderRadius: KaizenMedidas.bordeControl),
              ),
              icon: const Icon(KaizenIconos.agregar),
            ),
          ],
        ),
        const SizedBox(height: KaizenMedidas.e20),
        if (_vm.habitos.isEmpty)
          _vacio(context)
        else ...[
          TarjetaProgresoDia(cumplidos: _vm.cumplidosHoy, total: _vm.totalHoy, semana: _vm.nivelesSemana),
          const SizedBox(height: KaizenMedidas.e24),
          Semantics(header: true, child: Text(t.paraHoy, style: texto.titleMedium)),
          const SizedBox(height: KaizenMedidas.e12),
          ..._filas(context),
          if (s != null) ...[
            const SizedBox(height: KaizenMedidas.e8),
            TarjetaSugerencia(sugerencia: s, unidad: _unidadDe(s), onTap: () => _opcionesSugerencia(s)),
          ],
          const SizedBox(height: KaizenMedidas.e8),
          TarjetaSenal(onTap: () => context.go(Rutas.laboratorio)),
        ],
      ],
    );
  }

  // ───────────────────────── Escritorio y web ─────────────────────────

  Widget _dosColumnas(BuildContext context) {
    final t = AppLocalizations.of(context);
    final esWeb = PlataformaApp.de(context) == Plataforma.web;
    final s = _vm.sugerencia;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: anchoMaximoContenido),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(KaizenMedidas.e32, 28, KaizenMedidas.e32, KaizenMedidas.e32),
          children: [
            EncabezadoPantalla(
              titulo: t.tituloHoy,
              subtitulo: Fechas.larga(_vm.hoy),
              acciones: [
                // En web, "Nuevo hábito" ya está en la barra superior.
                if (!esWeb)
                  FilledButton.icon(
                    onPressed: () => context.push(Rutas.nuevoHabito),
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 46)),
                    icon: const Icon(KaizenIconos.agregar),
                    label: Text(t.nuevoHabito),
                  ),
              ],
            ),
            const SizedBox(height: KaizenMedidas.e24),
            if (_vm.habitos.isEmpty)
              _vacio(context)
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TarjetaProgresoDia(cumplidos: _vm.cumplidosHoy, total: _vm.totalHoy),
                        const SizedBox(height: KaizenMedidas.e12),
                        ..._filas(context),
                      ],
                    ),
                  ),
                  const SizedBox(width: KaizenMedidas.e20),
                  SizedBox(
                    width: 360,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TarjetaKaizen(
                          relleno: const EdgeInsets.all(KaizenMedidas.e20),
                          child: CalendarioMes(
                            anio: _vm.hoy.year,
                            mes: _vm.hoy.month,
                            hoy: _vm.hoy,
                            niveles: _vm.nivelesMes,
                          ),
                        ),
                        if (s != null) ...[
                          const SizedBox(height: KaizenMedidas.e12),
                          TarjetaMicroPaso(
                            sugerencia: s,
                            unidad: _unidadDe(s),
                            ocupado: _vm.responder.ejecutando,
                            onResponder: _responder,
                          ),
                        ],
                        const SizedBox(height: KaizenMedidas.e12),
                        TarjetaSenal(conDetalle: false, onTap: () => context.go(Rutas.laboratorio)),
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

  // ───────────────────────── Comunes ─────────────────────────

  List<Widget> _filas(BuildContext context) {
    final t = AppLocalizations.of(context);
    final lista = _vm.paraHoy;
    if (lista.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: KaizenMedidas.e16),
          child: Text(t.nadaProgramadoHoy, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ];
    }
    return [
      for (final h in lista)
        Padding(
          padding: const EdgeInsets.only(bottom: KaizenMedidas.e8),
          child: FilaHabito(
            key: ValueKey(h.id),
            icono: KaizenIconos.deCategoria(h.categoria.nombre),
            nombre: h.nombre,
            subtitulo: subtituloHabito(h, t),
            racha: h.racha.actual,
            cumplido: h.hoy?.cumplido ?? false,
            conCapsula: _vm.tieneCapsula(h.id),
            onCheck: () => _alternar(h),
            onTap: () => context.push(Rutas.habito(h.id)),
          ),
        ),
    ];
  }

  Widget _vacio(BuildContext context) {
    final t = AppLocalizations.of(context);
    return TarjetaKaizen(
      child: EstadoVacio(
        titulo: t.sinHabitosHoyTitulo,
        mensaje: t.sinHabitosHoyTexto,
        accion: FilledButton(onPressed: () => context.push(Rutas.nuevoHabito), child: Text(t.crearPrimerHabito)),
      ),
    );
  }
}
