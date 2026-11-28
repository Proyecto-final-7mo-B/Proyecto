import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/capsulas/capsulas_repository.dart';
import '../../../data/repositories/escalera/escalera_repository.dart';
import '../../../data/repositories/habitos/habitos_repository.dart';
import '../../../data/repositories/logros/logros_repository.dart';
import '../../../data/repositories/progreso/progreso_repository.dart';
import '../../../data/repositories/registros/registros_repository.dart';
import '../../../data/services/logros/novedades_logros.dart';
import '../../../domain/models/escalera.dart';
import '../../../domain/models/habito.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../routing/estado_sesion.dart';
import '../../../routing/rutas.dart';
import '../../../utils/fechas.dart';
import '../../../utils/reloj.dart';
import '../../core/adaptativo/breakpoints.dart';
import '../../core/adaptativo/plataforma.dart';
import '../../core/adaptativo/recarga_al_volver.dart';
import '../../core/formatos.dart';
import '../../core/mensajes.dart';
import '../../core/tema/colores.dart';
import '../../core/tema/iconos.dart';
import '../../core/tema/medidas.dart';
import '../../core/widgets/celebracion_hito.dart';
import '../../core/widgets/encabezado_pantalla.dart';
import '../../core/widgets/estados.dart';
import '../../core/widgets/fila_habito.dart';
import '../../core/widgets/tarjeta_kaizen.dart';
import '../../logros/widgets/tarjeta_ultimo_logro.dart';
import '../view_models/hoy_viewmodel.dart';
import '../../core/apariencia_habito.dart';
import 'panel_hoy.dart';
import 'tarjetas_hoy.dart';

/// `/hoy` (bosquejo 02). En el teléfono, una columna con la tarjeta compacta "Próximo hito", "Tu mes" (calendario y
/// %) y el Consejo saludable al final; con 900 px o más de
/// contenido, dos columnas: a la izquierda los hábitos y, en el espacio que quedaba vacío, la meta semanal OMS, el
/// próximo hito y la semana por hábito; a la derecha el calendario del mes, el micro-paso, la señal y, en web, el consejo
/// saludable del día (en escritorio va en el riel).
///
/// Lo pendiente va arriba por prioridad y lo hecho baja, con una animación corta, a "Hechos hoy" (doc. 07).
class PantallaHoy extends StatefulWidget {
  const PantallaHoy({super.key});

  /// Ancho del contenido desde el que se usan dos columnas.
  static const double anchoDosColumnas = 900;

  @override
  State<PantallaHoy> createState() => _PantallaHoyState();
}

class _PantallaHoyState extends State<PantallaHoy> with RecargaAlVolver {
  @override
  String get rutaPropia => Rutas.hoy;

  @override
  Future<void> recargarAlVolver() => _vm.cargar.ejecutar();

  late final HoyViewModel _vm;

  /// El hábito que se acaba de marcar o desmarcar: su fila entra con la animación de cambio de sección.
  String? _recienMovido;

  @override
  void initState() {
    super.initState();
    _vm = HoyViewModel(
      habitos: context.read<HabitosRepository>(),
      registros: context.read<RegistrosRepository>(),
      progreso: context.read<ProgresoRepository>(),
      escalera: context.read<EscaleraRepository>(),
      capsulas: context.read<CapsulasRepository>(),
      logros: context.read<LogrosRepository>(),
      novedadesLogros: context.read<NovedadesLogros>(),
      reloj: context.read<Reloj>(),
    );
    _vm.addListener(_avisarLogrosNuevos);
    _vm.cargar.ejecutar();
  }

  @override
  void dispose() {
    _vm.removeListener(_avisarLogrosNuevos);
    _vm.dispose();
    super.dispose();
  }

  /// Insignia nueva (Paso 11): un aviso breve con "Ver" (la celebración del hito, si la hay, va aparte).
  void _avisarLogrosNuevos() {
    final nuevos = _vm.tomarLogrosNuevos();
    if (nuevos.isEmpty || !mounted) {
      return;
    }
    final t = AppLocalizations.of(context);
    _logroVisible = true;
    final aviso = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    aviso
        .showSnackBar(
          SnackBar(
            key: const ValueKey('aviso-logro-nuevo'),
            // Con botón, un SnackBar se queda hasta que lo toquen; este se va solo (y deja pasar a los demás).
            persist: false,
            content: Row(
              children: [
                const Icon(KaizenIconos.logros, color: KaizenColores.verdeProgresoSobreMarino),
                const SizedBox(width: KaizenMedidas.e12),
                Expanded(
                  child: Text(nuevos.length == 1 ? t.logroNuevo(nuevos.single.nombre) : t.logrosNuevos(nuevos.length)),
                ),
              ],
            ),
            action: SnackBarAction(label: t.logroVer, onPressed: () => context.push(Rutas.logros)),
          ),
        )
        .closed
        .whenComplete(() => _logroVisible = false);
  }

  /// Mientras se ve el aviso de una insignia nueva, los demás avisos esperan su turno (no lo tapan).
  bool _logroVisible = false;

  /// La tarjeta "Último logro" (o "Tu próxima insignia"); `null` si no hay logros.
  Widget? _tarjetaLogro() => switch (_vm.ultimoLogro ?? _vm.proximoLogro) {
    final l? => TarjetaUltimoLogro(logro: l, onTap: () => context.push(Rutas.logros)),
    null => null,
  };

  void _avisar(String texto) {
    final aviso = ScaffoldMessenger.of(context);
    if (!_logroVisible) {
      aviso.hideCurrentSnackBar();
    }
    aviso.showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _alternar(Habito h) async {
    setState(() => _recienMovido = h.id);
    final error = await _vm.alternar(h);
    if (!mounted) {
      return;
    }
    if (error != null) {
      final t = AppLocalizations.of(context);
      _avisar(t.checkinNoGuardado(h.nombre, mensajeDeError(error, t)));
    } else if (_vm.tomarCelebracion() case final c?) {
      await mostrarCelebracion(context, hito: c.hito, habito: c.habito);
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
          if (_vm.habitoDelHito case final h?) ...[
            const SizedBox(height: KaizenMedidas.e8),
            TarjetaProximoHito(habito: h, compacta: true, onTap: () => context.push(Rutas.habito(h.id))),
          ],
          if (_tarjetaLogro() case final logro?) ...[const SizedBox(height: KaizenMedidas.e8), logro],
          // El avance del mes, como en escritorio (revisión de Jael, 27-nov).
          const SizedBox(height: KaizenMedidas.e8),
          _tuMes(),
          if (s != null) ...[
            const SizedBox(height: KaizenMedidas.e8),
            TarjetaSugerencia(sugerencia: s, unidad: _unidadDe(s), onTap: () => _opcionesSugerencia(s)),
          ],
          const SizedBox(height: KaizenMedidas.e8),
          TarjetaSenal(onTap: () => context.go(Rutas.laboratorio)),
          const SizedBox(height: KaizenMedidas.e8),
          TarjetaConsejo(indice: _vm.consejoDelDia),
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
                        const SizedBox(height: KaizenMedidas.e12),
                        ..._panel(context),
                      ],
                    ),
                  ),
                  const SizedBox(width: KaizenMedidas.e20),
                  SizedBox(
                    width: 360,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _tuMes(),
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
                        // En escritorio el consejo va en el riel; en web (sin riel), aquí.
                        if (esWeb) ...[
                          const SizedBox(height: KaizenMedidas.e12),
                          TarjetaConsejo(indice: _vm.consejoDelDia),
                        ],
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

  /// "Tu mes": el calendario con la intensidad de cada día, su % y los escudos del protector. En el teléfono va
  /// después del próximo hito; en escritorio, arriba a la derecha.
  Widget _tuMes() => TarjetaMes(
    anio: _vm.hoy.year,
    mes: _vm.hoy.month,
    hoy: _vm.hoy,
    niveles: _vm.nivelesMes,
    protegidos: _vm.protegidosMes,
    porcentaje: _vm.cumplimientoMes,
  );

  /// Widgets del espacio vacío de escritorio y web (doc. 05).
  List<Widget> _panel(BuildContext context) {
    final actividad = _vm.actividadSemanal;
    final h = _vm.habitoDelHito;
    final hito = h == null ? null : TarjetaProximoHito(habito: h, onTap: () => context.push(Rutas.habito(h.id)));
    return [
      if (actividad != null && hito != null)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: TarjetaMetaOms(actividad: actividad)),
              const SizedBox(width: KaizenMedidas.e12),
              Expanded(child: hito),
            ],
          ),
        )
      else if (actividad != null)
        TarjetaMetaOms(actividad: actividad)
      else
        ?hito,
      if (_tarjetaLogro() case final logro?) ...[const SizedBox(height: KaizenMedidas.e12), logro],
      if (_vm.semanaPorHabito case final filas when filas.isNotEmpty) ...[
        const SizedBox(height: KaizenMedidas.e12),
        TarjetaSemanaHabitos(filas: filas),
      ],
    ];
  }

  List<Widget> _filas(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    if (_vm.paraHoy.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: KaizenMedidas.e16),
          child: Text(t.nadaProgramadoHoy, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ];
    }
    final hechos = _vm.hechos;
    return [
      for (final h in _vm.pendientes) _fila(h, t),
      if (hechos.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(KaizenMedidas.e4, KaizenMedidas.e8, 0, KaizenMedidas.e8),
          child: Semantics(
            header: true,
            child: Row(
              children: [
                const Icon(KaizenIconos.cumplido, size: 18, color: KaizenColores.verdeProgreso),
                const SizedBox(width: KaizenMedidas.e8),
                Text(t.hechosHoy, style: texto.titleSmall),
                const SizedBox(width: KaizenMedidas.e8),
                Text(t.hechosHoyConteo(hechos.length), style: texto.bodySmall),
              ],
            ),
          ),
        ),
        for (final h in hechos) _fila(h, t),
      ],
    ];
  }

  Widget _fila(Habito h, AppLocalizations t) {
    final cumplido = h.hoy?.cumplido ?? false;
    return Padding(
      // La clave cambia al cambiar de sección: la fila "entra" de nuevo con la animación.
      key: ValueKey('${h.id}-$cumplido'),
      padding: const EdgeInsets.only(bottom: KaizenMedidas.e8),
      child: EntradaDeSeccion(
        animar: h.id == _recienMovido,
        child: FilaHabito(
          key: ValueKey(h.id),
          icono: h.icono,
          colorIcono: h.color,
          nombre: h.nombre,
          subtitulo: subtituloHabito(h, t),
          racha: h.racha.actual,
          cumplido: cumplido,
          conCapsula: _vm.tieneCapsula(h.id),
          protegida: h.racha.protegidaEstaSemana,
          prioridadAlta: h.prioridad == Prioridad.alta,
          onCheck: () => _alternar(h),
          onTap: () => context.push(Rutas.habito(h.id)),
        ),
      ),
    );
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

/// La fila que cambia de sección entra deslizándose y apareciendo (350 ms). Sin animación si el sistema pide reducir
/// movimiento.
class EntradaDeSeccion extends StatelessWidget {
  const EntradaDeSeccion({required this.animar, required this.child, super.key});

  final bool animar;
  final Widget child;

  static const Duration duracion = Duration(milliseconds: 350);

  @override
  Widget build(BuildContext context) {
    if (!animar || MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duracion,
      curve: Curves.easeOutCubic,
      builder: (context, v, hijo) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * -24), child: hijo),
      ),
      child: child,
    );
  }
}
