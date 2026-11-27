import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../config/constantes.dart';
import '../../../data/repositories/categorias/categorias_repository.dart';
import '../../../data/repositories/habitos/habitos_repository.dart';
import '../../../data/services/recordatorios/servicio_recordatorios.dart';
import '../../../data/services/api/errores_api.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../routing/rutas.dart';
import '../../../utils/reloj.dart';
import '../../../domain/models/habito.dart';
import '../../../utils/validadores.dart';
import '../../core/adaptativo/breakpoints.dart';
import '../../core/apariencia_habito.dart';
import '../../core/formatos.dart';
import '../../core/mensajes.dart';
import '../../core/tema/colores.dart';
import '../../core/tema/iconos.dart';
import '../../core/tema/medidas.dart';
import '../../core/widgets/boton_volver.dart';
import '../../core/widgets/campo_validado.dart';
import '../../core/widgets/chips_seleccion.dart';
import '../../core/widgets/contador_meta.dart';
import '../../core/widgets/dialogo_confirmacion.dart';
import '../../core/widgets/encabezado_pantalla.dart';
import '../../core/widgets/estados.dart';
import '../../core/widgets/icono_escalera.dart';
import '../../core/widgets/mensaje_error.dart';
import '../../core/widgets/selector_segmentado.dart';
import '../../core/widgets/tarjeta_kaizen.dart';
import '../view_models/formulario_habito_viewmodel.dart';
import 'chips_con_icono.dart';
import 'panel_evidencia.dart';
import 'vista_previa_habito.dart';

/// `/habitos/nuevo` y `/habitos/:id/editar` (bosquejo 03, con el respaldo científico del 27-nov). En el teléfono,
/// una columna con "Guardar hábito" fijo abajo; con 900 px o más, el formulario a la izquierda y la vista previa a la
/// derecha. Junto a la meta, "Lo que dice la evidencia" (`PanelEvidencia`).
class PantallaFormularioHabito extends StatefulWidget {
  const PantallaFormularioHabito({this.habitoId, super.key});

  /// `null` = nuevo hábito.
  final String? habitoId;

  static const double anchoDosColumnas = 900;

  @override
  State<PantallaFormularioHabito> createState() => _PantallaFormularioHabitoState();
}

class _PantallaFormularioHabitoState extends State<PantallaFormularioHabito> {
  late final FormularioHabitoViewModel _vm;
  final _formulario = GlobalKey<FormState>();
  final _scroll = ScrollController();
  final _nombre = TextEditingController();
  final _intencion = TextEditingController();
  bool _textosPuestos = false;

  @override
  void initState() {
    super.initState();
    _vm = FormularioHabitoViewModel(
      habitos: context.read<HabitosRepository>(),
      categorias: context.read<CategoriasRepository>(),
      recordatorios: context.read<ServicioRecordatorios>(),
      reloj: context.read<Reloj>(),
      habitoId: widget.habitoId,
    );
    _vm.cargar.ejecutar();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final t = AppLocalizations.of(context);
    _vm.textos = (titulo: t.appTitulo, cuerpo: t.recordatorioCuerpo);
  }

  @override
  void dispose() {
    _vm.dispose();
    _nombre.dispose();
    _scroll.dispose();
    _intencion.dispose();
    super.dispose();
  }

  /// Al editar, los campos de texto se llenan una vez con el hábito cargado.
  void _ponerTextos() {
    if (!_textosPuestos && _vm.cargado) {
      _textosPuestos = true;
      _nombre.text = _vm.nombre;
      _intencion.text = _vm.intencion;
    }
  }

  void _avisar(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  void _salir() => context.canPop() ? context.pop(true) : context.go(Rutas.habitos);

  Future<void> _guardar() async {
    final textosValidos = _formulario.currentState?.validate() ?? false;
    await _vm.guardar.ejecutar();
    if (!mounted) {
      return;
    }
    final validacionLocal = _vm.guardar.error?.tipo == TipoError.validacion && _vm.guardar.error?.status == null;
    if (!textosValidos || validacionLocal) {
      // Los errores pueden quedar arriba (nombre, categoría): se regresa al inicio para que se vean.
      if (_scroll.hasClients) {
        await _scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
      return;
    }
    final t = AppLocalizations.of(context);
    final r = _vm.guardar.resultado;
    final guardado = r?.valorONulo;
    if (guardado == null) {
      final error = r?.errorONulo;
      // La validación local (sin respuesta del servidor) y los 422 con errores por campo ya se ven junto a cada campo.
      final yaVisible = error?.tipo == TipoError.validacion && (error?.status == null || error!.errores.isNotEmpty);
      if (error != null && !yaVisible) {
        _avisar(mensajeDeError(error, t));
      }
      return;
    }
    if (guardado.recordatorioNegado) {
      _avisar(t.recordatorioSinPermiso);
    } else {
      _avisar(_vm.editando ? t.cambiosGuardados : t.habitoCreado(guardado.habito.nombre));
    }
    final capsula = guardado.capsula;
    if (capsula != null) {
      context.pushReplacement(Rutas.nuevaCapsulaDe(guardado.habito.id, objetivo: capsula));
    } else if (context.canPop()) {
      context.pop(true);
    } else {
      context.go(Rutas.habito(guardado.habito.id));
    }
  }

  Future<void> _archivar() async {
    final t = AppLocalizations.of(context);
    final h = _vm.original;
    if (h == null) {
      return;
    }
    final si = await DialogoConfirmacion.mostrar(
      context,
      titulo: t.archivarTitulo(h.nombre),
      mensaje: t.archivarMensaje,
      textoConfirmar: t.archivar,
      peligroso: true,
    );
    if (!si || !mounted) {
      return;
    }
    await _vm.archivar.ejecutar();
    if (!mounted) {
      return;
    }
    if (_vm.archivar.error case final error?) {
      _avisar(mensajeDeError(error, t));
      return;
    }
    _avisar(t.habitoArchivadoAviso(h.nombre));
    _salir();
  }

  Future<void> _elegirHora() async {
    final actual = _vm.recordatorio ?? (hora: 7, minuto: 30);
    final elegida = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: actual.hora, minute: actual.minuto),
      builder: (context, hijo) =>
          MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: hijo!),
    );
    if (elegida != null) {
      _vm.recordatorio = (hora: elegida.hour, minuto: elegida.minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([_vm, _vm.cargar, _vm.guardar, _vm.archivar]),
      builder: (context, _) {
        if (!_vm.cargado) {
          if (_vm.cargar.error case final error?) {
            return EstadoError(mensaje: mensajeDeError(error, t), onReintentar: _vm.cargar.ejecutar);
          }
          return const EstadoCargando();
        }
        _ponerTextos();
        return LayoutBuilder(
          builder: (context, limites) => Form(
            key: _formulario,
            child: limites.maxWidth >= PantallaFormularioHabito.anchoDosColumnas
                ? _dosColumnas(context)
                : _unaColumna(context),
          ),
        );
      },
    );
  }

  String get _titulo {
    final t = AppLocalizations.of(context);
    return _vm.editando ? t.tituloEditarHabito : t.tituloNuevoHabito;
  }

  // ───────────────────────── Teléfono ─────────────────────────

  Widget _unaColumna(BuildContext context) {
    return Column(
      children: [
        Expanded(
          // No es una lista perezosa: así todos los campos existen siempre y el formulario los valida todos.
          child: SingleChildScrollView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(
              KaizenMedidas.e20,
              KaizenMedidas.e24,
              KaizenMedidas.e20,
              KaizenMedidas.e24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EncabezadoInterno(
                  titulo: _titulo,
                  respaldo: _vm.editando ? Rutas.habito(_vm.habitoId!) : Rutas.habitos,
                ),
                const SizedBox(height: KaizenMedidas.e20),
                _campoNombre(context),
                const SizedBox(height: KaizenMedidas.e16),
                _campoCategoria(context),
                const SizedBox(height: KaizenMedidas.e16),
                _campoFrecuencia(context),
                const SizedBox(height: KaizenMedidas.e16),
                _campoMeta(context),
                const SizedBox(height: KaizenMedidas.e16),
                _campoPrioridad(context),
                const SizedBox(height: KaizenMedidas.e16),
                _campoIntencion(context),
                const SizedBox(height: KaizenMedidas.e16),
                _campoEscalera(context),
                if (!_vm.editando) ...[const SizedBox(height: KaizenMedidas.e16), _campoCapsula(context)],
                if (_vm.recordatoriosDisponibles) ...[
                  const SizedBox(height: KaizenMedidas.e16),
                  _campoRecordatorio(context),
                ],
                if (_vm.editando) ...[const SizedBox(height: KaizenMedidas.e24), _botonArchivar(context)],
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: const BoxDecoration(
            color: KaizenColores.superficie,
            border: Border(top: BorderSide(color: KaizenColores.borde)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              KaizenMedidas.e20,
              KaizenMedidas.e12,
              KaizenMedidas.e20,
              KaizenMedidas.e12,
            ),
            child: SizedBox(width: double.infinity, child: _botonGuardar(context)),
          ),
        ),
      ],
    );
  }

  // ───────────────────────── Escritorio y web ─────────────────────────

  Widget _dosColumnas(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: anchoMaximoContenido),
        child: SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(KaizenMedidas.e32, 28, KaizenMedidas.e32, KaizenMedidas.e32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EncabezadoPantalla(
                titulo: _titulo,
                subtitulo: _vm.editando ? _vm.original?.nombre : t.subtituloNuevoHabito,
              ),
              const SizedBox(height: KaizenMedidas.e20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _campoNombre(context),
                        const SizedBox(height: KaizenMedidas.e16),
                        _campoCategoria(context),
                        const SizedBox(height: KaizenMedidas.e16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _campoFrecuencia(context)),
                            const SizedBox(width: KaizenMedidas.e16),
                            Expanded(child: _campoMeta(context)),
                          ],
                        ),
                        const SizedBox(height: KaizenMedidas.e16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _campoPrioridad(context)),
                            const SizedBox(width: KaizenMedidas.e16),
                            Expanded(
                              child: _vm.recordatoriosDisponibles
                                  ? _campoRecordatorio(context)
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                        const SizedBox(height: KaizenMedidas.e16),
                        _campoIntencion(context),
                        if (!_vm.editando) ...[const SizedBox(height: KaizenMedidas.e16), _campoCapsula(context)],
                        const SizedBox(height: KaizenMedidas.e16),
                        _campoEscalera(context),
                        const SizedBox(height: KaizenMedidas.e20),
                        Wrap(
                          spacing: KaizenMedidas.e12,
                          runSpacing: KaizenMedidas.e12,
                          children: [
                            _botonGuardar(context),
                            OutlinedButton(
                              onPressed: _salir,
                              style: OutlinedButton.styleFrom(minimumSize: const Size(120, KaizenMedidas.altoBoton)),
                              child: Text(t.cancelar),
                            ),
                            if (_vm.editando) _botonArchivar(context),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: KaizenMedidas.e24),
                  SizedBox(
                    width: 380,
                    child: VistaPreviaHabito(
                      nombre: _nombre.text,
                      icono: _vm.subcategoria == null ? null : iconoDeSubcategoria(_vm.subcategoria!),
                      colorIcono: _vm.categoria == null ? null : colorDeCategoria(_vm.categoria!),
                      subtitulo: _subtituloPrevio(t),
                      niveles: _vm.editando ? [_vm.meta] : _vm.escaleraInicial,
                      unidad: _vm.unidad,
                      conCapsula: _vm.capsula != null,
                      conEscalera: _vm.escaleraActiva && !_vm.editando,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtituloPrevio(AppLocalizations t) {
    final meta = '${numero(_vm.meta)} ${_vm.unidad}';
    return _vm.editando && (_vm.original?.nivel ?? 1) > 1
        ? '$meta · ${t.nivelN(_vm.original!.nivel)}'
        : '$meta · ${textoFrecuencia(_vm.frecuencia, t)}';
  }

  // ───────────────────────── Campos ─────────────────────────

  Widget _etiqueta(BuildContext context, String texto) => Padding(
    padding: const EdgeInsets.only(bottom: KaizenMedidas.e8),
    child: Text(texto, style: Theme.of(context).textTheme.labelLarge),
  );

  Widget _campoNombre(BuildContext context) {
    final t = AppLocalizations.of(context);
    return CampoValidado(
      etiqueta: t.campoNombreHabito,
      controller: _nombre,
      pista: t.pistaNombreHabito,
      ayuda: _vm.editando ? null : t.ayudaNombreHabito,
      accionTeclado: TextInputAction.done,
      validador: validadorDe(Validadores.nombreHabito, t),
      errorServidor: _vm.guardar.error?.errorDe('nombre'),
      onCambio: (v) {
        _vm.nombre = v;
        _vm.textoCambiado();
      },
    );
  }

  /// Categoría (con su color e ícono) y, debajo, sus subcategorías.
  Widget _campoCategoria(BuildContext context) {
    final t = AppLocalizations.of(context);
    final categoria = _vm.categoria;
    final color = categoria == null ? KaizenColores.marino800 : colorDeCategoria(categoria);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _etiqueta(context, t.campoCategoria),
        ChipsConIcono<String>(
          opciones: [
            for (final c in _vm.opcionesCategoria)
              (valor: c.id, etiqueta: c.nombre, icono: KaizenIconos.porNombre(c.icono), color: colorDeCategoria(c)),
          ],
          seleccionado: _vm.categoriaId,
          onCambio: (id) => _vm.categoriaId = id,
        ),
        if (categoria != null) ...[
          const SizedBox(height: KaizenMedidas.e16),
          _etiqueta(context, t.campoSubcategoria),
          ChipsConIcono<String>(
            opciones: [
              for (final s in _vm.opcionesSubcategoria)
                (valor: s.id, etiqueta: s.nombre, icono: iconoDeSubcategoria(s, categoria: categoria), color: color),
            ],
            seleccionado: _vm.subcategoriaId,
            onCambio: (id) => _vm.subcategoriaId = id,
          ),
        ],
        if (_vm.intentoGuardar && _vm.faltaSubcategoria) ...[
          const SizedBox(height: KaizenMedidas.e8),
          MensajeError(categoria == null ? t.validacionRequerido : t.validacionSubcategoria),
        ],
      ],
    );
  }

  Widget _campoFrecuencia(BuildContext context) {
    final t = AppLocalizations.of(context);
    if (_vm.editando) {
      return _soloLectura(context, t.campoFrecuencia, textoFrecuencia(_vm.frecuencia, t));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _etiqueta(context, t.campoFrecuencia),
        SelectorSegmentado<TipoFrecuencia>(
          opciones: [
            (valor: TipoFrecuencia.diaria, etiqueta: t.opcionDiario),
            (valor: TipoFrecuencia.dias, etiqueta: t.opcionDias),
            (valor: TipoFrecuencia.veces, etiqueta: t.opcionVeces),
          ],
          seleccionado: _vm.tipo,
          onCambio: (v) => _vm.tipo = v,
        ),
        if (_vm.tipo == TipoFrecuencia.dias) ...[
          const SizedBox(height: KaizenMedidas.e12),
          Semantics(
            label: t.queDias,
            child: ChipsSeleccion<int>(
              opciones: [
                for (var d = 1; d <= 7; d++) (valor: d, etiqueta: const ['L', 'Ma', 'Mi', 'J', 'V', 'S', 'D'][d - 1]),
              ],
              seleccionados: {
                for (var d = 1; d <= 7; d++)
                  if (_vm.mascara & (1 << (d - 1)) != 0) d,
              },
              multiple: true,
              permitirVacio: true,
              onCambio: (nuevos) {
                final actuales = {
                  for (var d = 1; d <= 7; d++)
                    if (_vm.mascara & (1 << (d - 1)) != 0) d,
                };
                for (final d in nuevos.difference(actuales).union(actuales.difference(nuevos))) {
                  _vm.alternarDia(d);
                }
              },
            ),
          ),
          if (_vm.intentoGuardar && _vm.faltanDias) ...[
            const SizedBox(height: KaizenMedidas.e8),
            MensajeError(t.validacionDias),
          ],
        ],
        if (_vm.tipo == TipoFrecuencia.veces) ...[
          const SizedBox(height: KaizenMedidas.e12),
          Text(t.vecesPorSemana, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: KaizenMedidas.e4),
          ContadorMeta(
            valor: _vm.veces,
            unidad: t.vecesUnidad(_vm.veces),
            minimo: Limites.vecesSemanaMin,
            maximo: Limites.vecesSemanaMax,
            onCambio: (v) => _vm.veces = v.toInt(),
          ),
        ],
      ],
    );
  }

  /// Unidad (solo las permitidas de la subcategoría), meta (al paso de la unidad) y lo que dice la evidencia.
  Widget _campoMeta(BuildContext context) {
    final t = AppLocalizations.of(context);
    final evaluacion = _vm.evaluacion;
    final panel = evaluacion == null
        ? null
        : PanelEvidencia(
            evaluacion: evaluacion,
            meta: _vm.meta,
            unidad: _vm.unidad,
            unidadComparable: _vm.unidadComparable,
            onUsarSugerida: _vm.editando ? null : _vm.usarSugerida,
          );
    if (_vm.editando) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _soloLectura(context, t.campoMetaActual, '${numero(_vm.meta)} ${_vm.unidad}'),
          const SizedBox(height: KaizenMedidas.e8),
          Text('${t.metaNoEditable} ${t.unidadNoEditable}', style: Theme.of(context).textTheme.bodySmall),
          if (panel != null) ...[const SizedBox(height: KaizenMedidas.e12), panel],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_vm.unidades.length > 1) ...[
          _etiqueta(context, t.campoUnidad),
          ChipsSeleccion<String>(
            opciones: [for (final u in _vm.unidades) (valor: u.unidad, etiqueta: u.unidad)],
            seleccionados: {if (_vm.unidad.isNotEmpty) _vm.unidad},
            onCambio: (s) => _vm.unidad = s.first,
          ),
          const SizedBox(height: KaizenMedidas.e12),
        ],
        _etiqueta(context, t.campoMeta),
        ContadorMeta(
          valor: _vm.meta,
          unidad: _vm.unidad,
          minimo: _vm.metaMinima,
          maximo: _vm.metaMaxima,
          paso: _vm.pasoMeta,
          onCambio: _vm.faltaSubcategoria ? null : (v) => _vm.meta = (v * 100).round() / 100,
        ),
        if (panel != null) ...[const SizedBox(height: KaizenMedidas.e12), panel],
      ],
    );
  }

  Widget _campoPrioridad(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _etiqueta(context, t.campoPrioridad),
        SelectorSegmentado<int>(
          opciones: [
            (valor: Prioridad.alta, etiqueta: t.prioridadAlta),
            (valor: Prioridad.media, etiqueta: t.prioridadMedia),
            (valor: Prioridad.baja, etiqueta: t.prioridadBaja),
          ],
          seleccionado: _vm.prioridad,
          onCambio: (p) => _vm.prioridad = p,
        ),
      ],
    );
  }

  /// "Después de ___": la señal del contexto (intención de implementación, doc. 01). Opcional.
  Widget _campoIntencion(BuildContext context) {
    final t = AppLocalizations.of(context);
    return CampoValidado(
      etiqueta: t.campoIntencion,
      controller: _intencion,
      pista: t.pistaIntencion,
      ayuda: t.ayudaIntencion,
      accionTeclado: TextInputAction.done,
      validador: validadorDe(Validadores.intencion, t),
      errorServidor: _vm.guardar.error?.errorDe('intencion'),
      onCambio: (v) {
        _vm.intencion = v;
        _vm.textoCambiado();
      },
    );
  }

  Widget _campoEscalera(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    return TarjetaKaizen(
      relleno: const EdgeInsets.symmetric(horizontal: KaizenMedidas.e16, vertical: KaizenMedidas.e8),
      child: MergeSemantics(
        child: Row(
          children: [
            const IconoEscalera(tamano: 22, color: KaizenColores.texto),
            const SizedBox(width: KaizenMedidas.e16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.escaleraKaizen, style: texto.titleSmall),
                  Text(t.escaleraKaizenDetalle, style: texto.bodySmall),
                ],
              ),
            ),
            Switch(value: _vm.escaleraActiva, onChanged: (v) => _vm.escaleraActiva = v),
          ],
        ),
      ),
    );
  }

  Widget _campoCapsula(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _etiqueta(context, t.campoCapsula),
        ChipsSeleccion<int>(
          opciones: [
            (valor: 0, etiqueta: t.sinCapsula),
            for (final d in Limites.rachasObjetivo) (valor: d, etiqueta: t.nDias(d)),
          ],
          seleccionados: {_vm.capsula ?? 0},
          onCambio: (s) => _vm.capsula = (s.firstOrNull ?? 0) == 0 ? null : s.first,
        ),
      ],
    );
  }

  Widget _campoRecordatorio(BuildContext context) {
    final t = AppLocalizations.of(context);
    final texto = Theme.of(context).textTheme;
    final hora = _vm.recordatorio;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _etiqueta(context, t.campoRecordatorio),
        Material(
          color: KaizenColores.superficie,
          shape: const RoundedRectangleBorder(
            borderRadius: KaizenMedidas.bordeControl,
            side: BorderSide(color: KaizenColores.borde),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _elegirHora,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: KaizenMedidas.altoBoton),
              child: Padding(
                padding: const EdgeInsets.only(left: KaizenMedidas.e16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        hora == null ? t.sinRecordatorio : formatoHora(hora),
                        style: texto.bodyLarge!.copyWith(
                          color: hora == null ? KaizenColores.textoSecundario : KaizenColores.texto,
                        ),
                      ),
                    ),
                    if (hora != null)
                      IconButton(
                        tooltip: t.quitarRecordatorio,
                        onPressed: () => _vm.recordatorio = null,
                        icon: const Icon(Icons.close),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.all(KaizenMedidas.e12),
                        child: Icon(KaizenIconos.reloj, color: KaizenColores.textoSecundario),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _soloLectura(BuildContext context, String etiqueta, String valor) {
    final texto = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _etiqueta(context, etiqueta),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: KaizenMedidas.altoBoton),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: KaizenMedidas.e16),
          decoration: const BoxDecoration(color: KaizenColores.azul100, borderRadius: KaizenMedidas.bordeControl),
          child: Row(
            children: [
              Expanded(child: Text(valor, style: texto.bodyLarge)),
              const Icon(KaizenIconos.candado, size: 18, color: KaizenColores.textoSecundario),
            ],
          ),
        ),
      ],
    );
  }

  Widget _botonGuardar(BuildContext context) {
    final t = AppLocalizations.of(context);
    final ocupado = _vm.guardar.ejecutando || _vm.archivar.ejecutando;
    return FilledButton(
      onPressed: ocupado ? null : _guardar,
      style: FilledButton.styleFrom(minimumSize: const Size(180, KaizenMedidas.altoBoton)),
      child: ocupado
          ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : Text(_vm.editando ? t.guardarCambios : t.guardarHabito),
    );
  }

  Widget _botonArchivar(BuildContext context) {
    final t = AppLocalizations.of(context);
    return OutlinedButton.icon(
      onPressed: _vm.archivar.ejecutando ? null : _archivar,
      style: OutlinedButton.styleFrom(
        foregroundColor: KaizenColores.error,
        minimumSize: const Size(0, KaizenMedidas.altoBoton),
      ),
      icon: const Icon(KaizenIconos.archivar),
      label: Text(t.archivarHabito),
    );
  }
}
