import 'package:flutter/foundation.dart';

import '../../../config/constantes.dart';
import '../../../data/repositories/categorias/categorias_repository.dart';
import '../../../data/repositories/habitos/habitos_repository.dart';
import '../../../data/services/api/errores_api.dart';
import '../../../data/services/recordatorios/servicio_recordatorios.dart';
import '../../../domain/models/categoria.dart';
import '../../../domain/models/evidencia.dart';
import '../../../domain/models/frecuencia.dart';
import '../../../domain/models/habito.dart';
import '../../../utils/command.dart';
import '../../../utils/evidencia.dart';
import '../../../utils/fechas.dart';
import '../../../utils/reloj.dart';
import '../../../utils/result.dart';
import '../../../utils/validadores.dart';
import 'estadisticas_habito.dart';

/// Tipo de frecuencia que se elige en el formulario.
enum TipoFrecuencia { diaria, dias, veces }

/// Lo que pasó al guardar, para que la pantalla decida a dónde ir y qué avisar.
typedef Guardado = ({Habito habito, int? capsula, bool recordatorioNegado});

/// Textos de la notificación (vienen de la pantalla, que tiene las traducciones).
typedef TextosRecordatorio = ({String titulo, String Function(String habito) cuerpo});

/// Crear (`/habitos/nuevo`) y editar (`/habitos/:id/editar`) un hábito (bosquejo 03), con respaldo científico
/// (contrato v1.6; investigación en `Evidencias_generales/12_investigacion_cientifica/`).
///
/// - **Crear:** nombre, categoría → subcategoría, unidad (solo las permitidas), meta (arranca en lo recomendado y se
///   evalúa en vivo contra la evidencia, con "Usar X" si se pasa del máximo), frecuencia, prioridad, intención
///   "Después de ___", Escalera, cápsula 7/30/66 y recordatorio (solo en el teléfono).
/// - **Editar:** meta, frecuencia y unidad de solo lectura (la meta cambia con la Escalera; cambiar la unidad sin
///   cambiar la meta le quitaría sentido). La subcategoría solo puede cambiar a una que acepte la misma unidad. Se
///   manda solo lo que cambió. También se archiva.
class FormularioHabitoViewModel extends ChangeNotifier {
  FormularioHabitoViewModel({
    required HabitosRepository habitos,
    required CategoriasRepository categorias,
    required ServicioRecordatorios recordatorios,
    this.textos = (titulo: 'Kaizen', cuerpo: _cuerpoPorOmision),
    this.habitoId,
    Reloj reloj = relojDelSistema,
  }) : _repoHabitos = habitos,
       _repoCategorias = categorias,
       _servicioRecordatorios = recordatorios,
       _relojFormulario = reloj {
    cargar = Command0<void>(_cargar);
    guardar = Command0<Guardado>(_guardar);
    archivar = Command0<Habito>(_archivar);
  }

  final HabitosRepository _repoHabitos;
  final CategoriasRepository _repoCategorias;
  final ServicioRecordatorios _servicioRecordatorios;
  final Reloj _relojFormulario;

  /// Textos de la notificación; la pantalla pone los traducidos.
  TextosRecordatorio textos;

  static String _cuerpoPorOmision(String habito) => habito;

  /// `null` = crear; si no, el hábito que se edita.
  final String? habitoId;

  late final Command0<void> cargar;
  late final Command0<Guardado> guardar;
  late final Command0<Habito> archivar;

  static const double metaSinSubcategoria = 5;
  static const int vecesInicial = 3;

  bool get editando => habitoId != null;

  List<Categoria> _categorias = const [];
  Habito? _original;
  HoraRecordatorio? _recordatorioOriginal;
  bool _cargado = false;

  String nombre = '';
  String intencion = '';
  String? _categoriaId;
  String? _subcategoriaId;
  String _unidad = '';
  TipoFrecuencia _tipo = TipoFrecuencia.diaria;
  int _mascara = DiasSemana.lunesAViernes;
  int _veces = vecesInicial;
  double _meta = metaSinSubcategoria;
  int _prioridad = Prioridad.media;
  bool _escalera = true;
  int? _capsula;
  HoraRecordatorio? _recordatorio;
  bool _intentoGuardar = false;

  bool get cargado => _cargado;
  List<Categoria> get categorias => _categorias;
  Habito? get original => _original;
  String? get categoriaId => _categoriaId;
  String? get subcategoriaId => _subcategoriaId;
  String get unidad => _unidad;
  TipoFrecuencia get tipo => _tipo;
  int get mascara => _mascara;
  int get veces => _veces;
  double get meta => _meta;
  int get prioridad => _prioridad;
  bool get escaleraActiva => _escalera;
  int? get capsula => _capsula;
  HoraRecordatorio? get recordatorio => _recordatorio;
  bool get recordatoriosDisponibles => _servicioRecordatorios.disponible;

  /// Ya se intentó guardar: desde ahí se muestran los errores que no son de un campo de texto.
  bool get intentoGuardar => _intentoGuardar;

  Categoria? get categoria => _categorias.where((c) => c.id == _categoriaId).firstOrNull ?? _original?.categoria;

  /// La subcategoría elegida, con su catálogo completo (unidades y referencia).
  Subcategoria? get subcategoria => _subcategoriaId == null ? null : _categorias.subcategoria(_subcategoriaId!);

  /// Subcategorías que se pueden elegir: las de la categoría elegida; al editar, solo las que aceptan la unidad.
  List<Subcategoria> get opcionesSubcategoria {
    final lista = categoria?.subcategorias ?? const <Subcategoria>[];
    return editando
        ? [
            for (final s in lista)
              if (s.unidad(_unidad) != null) s,
          ]
        : lista;
  }

  /// Al editar, solo las categorías que tienen alguna subcategoría con la misma unidad.
  List<Categoria> get opcionesCategoria => editando
      ? [
          for (final c in _categorias)
            if (c.subcategorias.any((s) => s.unidad(_unidad) != null)) c,
        ]
      : _categorias;

  List<UnidadPermitida> get unidades => subcategoria?.unidades ?? const [];
  UnidadPermitida? get unidadPermitida => subcategoria?.unidad(_unidad);

  /// Paso, mínimo y máximo del contador de meta (de la unidad; sin subcategoría, los de antes).
  double get pasoMeta => unidadPermitida?.paso ?? 1;
  double get metaMinima => unidadPermitida?.minimo ?? 0.5;
  double get metaMaxima => unidadPermitida?.maximo ?? 9999;

  Frecuencia get frecuencia => switch (_tipo) {
    TipoFrecuencia.diaria => const Diaria(),
    TipoFrecuencia.dias => DiasSemana(_mascara == 0 ? DiasSemana.lunesAViernes : _mascara),
    TipoFrecuencia.veces => NPorSemana(_veces),
  };

  /// Dónde cae la meta según la evidencia, calculado igual que la base (`fn_evaluar_meta`): sirve sin red.
  Evaluacion? get evaluacion {
    final sub = subcategoria;
    return sub == null || _unidad.isEmpty ? null : EvaluadorEvidencia.evaluar(sub, _unidad, _meta, frecuencia);
  }

  /// Si la unidad no se compara con la referencia (km), la unidad que sí se compara, para sugerirla.
  String? get unidadComparable {
    final sub = subcategoria;
    if (sub?.referencia == null || (unidadPermitida?.convertible ?? true)) {
      return null;
    }
    return sub!.unidades.where((u) => u.convertible).firstOrNull?.unidad;
  }

  /// Falta elegir días en "Días".
  bool get faltanDias => _tipo == TipoFrecuencia.dias && _mascara == 0;
  bool get faltaSubcategoria => _subcategoriaId == null;

  /// Compatibilidad con la pantalla y las pruebas anteriores: sin subcategoría tampoco hay categoría completa.
  bool get faltaCategoria => faltaSubcategoria;

  /// La escalera de la vista previa: la meta inicial y los niveles proyectados como la Escalera v2 (al paso de la
  /// unidad, sin pasar del óptimo; si la meta ya está en el óptimo o arriba, no hay más niveles).
  List<double> get escaleraInicial {
    final e = evaluacion;
    if (e == null) {
      return [_meta, ...EstadisticasHabito.proyeccion(_meta, cuantos: 4)];
    }
    final subeSegunEvidencia = e.zona == ZonaEvidencia.bajo || e.zona == ZonaEvidencia.sinReferencia;
    if (e.sentido == SentidoHabito.reducir || !subeSegunEvidencia) {
      return [_meta];
    }
    return [
      _meta,
      ...EstadisticasHabito.proyeccionConEvidencia(
        _meta,
        paso: e.paso,
        techo: e.zona == ZonaEvidencia.bajo ? e.optimoHasta : null,
      ),
    ];
  }

  // ───────────────────────── Cambios ─────────────────────────

  /// Elegir categoría. Si la subcategoría elegida no es de ella, se quita.
  set categoriaId(String? id) => _cambiar(() {
    _categoriaId = id;
    if (subcategoria != null && !(categoria?.subcategorias.any((s) => s.id == _subcategoriaId) ?? false)) {
      _subcategoriaId = null;
    }
  });

  /// Elegir subcategoría: al crear, la unidad pasa a la primera permitida y la meta a la recomendada.
  set subcategoriaId(String? id) => _cambiar(() {
    _subcategoriaId = id;
    final sub = subcategoria;
    if (sub == null) {
      return;
    }
    _categoriaId = _categorias.categoriaDe(sub.id)?.id ?? _categoriaId;
    if (!editando) {
      _ponerUnidad(sub.unidades.firstOrNull?.unidad ?? '');
    }
  });

  /// Cambiar de unidad (solo al crear): la meta vuelve a la recomendada en esa unidad.
  set unidad(String u) => _cambiar(() => _ponerUnidad(u));

  void _ponerUnidad(String u) {
    _unidad = u;
    final sub = subcategoria;
    final permitida = sub?.unidad(u);
    if (sub != null && permitida != null) {
      _meta = EvaluadorEvidencia.metaInicial(sub, permitida, frecuencia);
    }
  }

  set tipo(TipoFrecuencia t) => _cambiar(() => _tipo = t);
  set veces(int v) => _cambiar(() => _veces = v.clamp(Limites.vecesSemanaMin, Limites.vecesSemanaMax));
  set meta(double m) => _cambiar(() => _meta = m);
  set prioridad(int p) => _cambiar(() => _prioridad = p);
  set escaleraActiva(bool v) => _cambiar(() => _escalera = v);
  set capsula(int? dias) => _cambiar(() => _capsula = dias);
  set recordatorio(HoraRecordatorio? h) => _cambiar(() => _recordatorio = h);

  /// "Usar X": pone la meta que sugiere la evidencia (el máximo si se pasa; el inicio del óptimo si está bajo).
  void usarSugerida() {
    final sugerida = evaluacion?.metaSugerida;
    if (sugerida != null && !editando) {
      meta = sugerida;
    }
  }

  /// Activa o apaga un día (1 = lunes … 7 = domingo).
  void alternarDia(int dia) => _cambiar(() => _mascara ^= 1 << (dia - 1));

  /// Avisa a la vista previa cuando cambian el nombre o la intención.
  void textoCambiado() => notifyListeners();

  void _cambiar(VoidCallback cambio) {
    cambio();
    notifyListeners();
  }

  // ───────────────────────── Carga ─────────────────────────

  Future<Result<void>> _cargar() async {
    final cats = await _repoCategorias.listar();
    if (cats case Fallo(:final error)) {
      return Result.fallo(error);
    }
    _categorias = cats.valorONulo!;
    final id = habitoId;
    if (id != null) {
      final r = await _repoHabitos.obtener(id, fecha: Fechas.soloFecha(_relojFormulario()));
      switch (r) {
        case Fallo(:final error):
          return Result.fallo(error);
        case Exito(valor: final h):
          _original = h;
          nombre = h.nombre;
          intencion = h.intencion ?? '';
          _unidad = h.unidad;
          _categoriaId = h.categoria.id;
          _subcategoriaId = h.subcategoria.id;
          _meta = h.meta;
          _prioridad = h.prioridad;
          _escalera = h.escaleraActiva;
          switch (h.frecuencia) {
            case Diaria():
              _tipo = TipoFrecuencia.diaria;
            case DiasSemana(:final mascara):
              _tipo = TipoFrecuencia.dias;
              _mascara = mascara;
            case NPorSemana(:final veces):
              _tipo = TipoFrecuencia.veces;
              _veces = veces;
          }
      }
      if (_servicioRecordatorios.disponible) {
        _recordatorioOriginal = await _servicioRecordatorios.hora(id);
        _recordatorio = _recordatorioOriginal;
      }
    }
    _cargado = true;
    notifyListeners();
    return const Result.exito(null);
  }

  // ───────────────────────── Guardar ─────────────────────────

  /// Lo que se mandaría en `PATCH`: solo los campos que cambiaron (nunca meta, frecuencia, unidad ni categoría).
  CambiosHabito get cambios {
    final o = _original!;
    final n = nombre.trim();
    final i = intencion.trim();
    final intencionAntes = o.intencion ?? '';
    return CambiosHabito(
      nombre: n != o.nombre ? n : null,
      subcategoriaId: _subcategoriaId != o.subcategoria.id ? _subcategoriaId : null,
      prioridad: _prioridad != o.prioridad ? _prioridad : null,
      intencion: i != intencionAntes && i.isNotEmpty ? i : null,
      quitarIntencion: i.isEmpty && intencionAntes.isNotEmpty,
      escaleraActiva: _escalera != o.escaleraActiva ? _escalera : null,
    );
  }

  static bool _vacio(CambiosHabito c) => c.toJson().isEmpty;

  bool get _valido =>
      Validadores.nombreHabito(nombre) == null &&
      Validadores.intencion(intencion) == null &&
      !faltaSubcategoria &&
      unidadPermitida != null &&
      !faltanDias &&
      (editando || (Validadores.meta(_meta.toString()) == null && _meta >= metaMinima && _meta <= metaMaxima));

  Future<Result<Guardado>> _guardar() async {
    _intentoGuardar = true;
    notifyListeners();
    if (!_valido) {
      return const Result.fallo(ErrorApp(TipoError.validacion));
    }
    final Result<Habito> r;
    if (editando) {
      final c = cambios;
      r = _vacio(c) ? Result.exito(_original!) : await _repoHabitos.actualizar(habitoId!, c);
    } else {
      final i = intencion.trim();
      r = await _repoHabitos.crear(
        NuevoHabito(
          nombre: nombre.trim(),
          subcategoriaId: _subcategoriaId!,
          frecuencia: frecuencia,
          meta: _meta,
          unidad: _unidad,
          escaleraActiva: _escalera,
          prioridad: _prioridad,
          intencion: i.isEmpty ? null : i,
        ),
      );
    }
    switch (r) {
      case Fallo(:final error):
        if (const {
          TipoError.categoriaInactiva,
          TipoError.subcategoriaInactiva,
          TipoError.unidadNoPermitida,
        }.contains(error.tipo)) {
          await _recargarCategorias();
        }
        return Result.fallo(error);
      case Exito(valor: final h):
        final negado = !await _actualizarRecordatorio(h);
        _original = editando ? h : null;
        return Result.exito((habito: h, capsula: editando ? null : _capsula, recordatorioNegado: negado));
    }
  }

  /// Programa, reprograma (cambió la hora, el nombre o la intención) o quita el recordatorio. `false` si el permiso
  /// se negó. El aviso lleva la intención: la señal del contexto es lo que forma el hábito (doc. 06).
  Future<bool> _actualizarRecordatorio(Habito h) async {
    if (!_servicioRecordatorios.disponible) {
      return true;
    }
    final hora = _recordatorio;
    if (hora == null) {
      if (_recordatorioOriginal != null) {
        await _servicioRecordatorios.cancelar(h.id);
      }
      return true;
    }
    final igual = _recordatorioOriginal == hora && _original?.nombre == h.nombre && _original?.intencion == h.intencion;
    if (igual) {
      return true;
    }
    final intencionHabito = h.intencion;
    return _servicioRecordatorios.programar(
      habitoId: h.id,
      titulo: textos.titulo,
      cuerpo: intencionHabito == null ? textos.cuerpo(h.nombre) : '$intencionHabito: ${h.nombre}',
      hora: hora,
      frecuencia: h.frecuencia,
    );
  }

  /// La categoría o subcategoría elegida se desactivó mientras tanto (422): se recarga el catálogo y, si ya no
  /// está, se quita la elección.
  Future<void> _recargarCategorias() async {
    final cats = await _repoCategorias.listar();
    if (cats.valorONulo case final lista?) {
      _categorias = lista;
      if (!lista.any((c) => c.id == _categoriaId)) {
        _categoriaId = null;
      }
      if (lista.subcategoria(_subcategoriaId ?? '') == null) {
        _subcategoriaId = null;
      }
      notifyListeners();
    }
  }

  // ───────────────────────── Archivar ─────────────────────────

  /// `PATCH {"activo": false}` y se apaga el recordatorio. El historial se conserva.
  Future<Result<Habito>> _archivar() async {
    final id = habitoId;
    if (id == null) {
      return const Result.fallo(ErrorApp(TipoError.noEncontrado));
    }
    final r = await _repoHabitos.actualizar(id, const CambiosHabito(activo: false));
    if (r.esExito && _servicioRecordatorios.disponible) {
      await _servicioRecordatorios.cancelar(id);
    }
    return r;
  }

  @override
  void dispose() {
    cargar.dispose();
    guardar.dispose();
    archivar.dispose();
    super.dispose();
  }
}
