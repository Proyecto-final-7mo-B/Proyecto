import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/capsula.dart';
import '../../domain/models/categoria.dart';
import '../../domain/models/escalera.dart';
import '../../domain/models/frecuencia.dart';
import '../../domain/models/habito.dart';
import '../../domain/models/laboratorio.dart';
import '../../domain/models/problema.dart';
import '../../domain/models/registro.dart';
import '../../domain/models/usuario.dart';
import '../../utils/evidencia.dart';
import '../../utils/fechas.dart';
import '../../utils/paises_estados.dart';
import '../../utils/result.dart';
import '../services/api/errores_api.dart';
import 'catalogo_demo.dart';

/// "Servidor" en memoria para desarrollar y probar sin backend (`KAIZEN_FUENTE=fake`).
///
/// Usa las **mismas personas** que el poblador del entorno local (`demo@`, `admin@`, `latam@`, `nuevo@` y
/// `suspendido@kaizen.test`, contraseña [contrasenaDemo]) y aplica las mismas reglas que la base: rachas por días
/// programados, Escalera, cápsulas, consentimiento de señales, cuenta suspendida y bloqueo tras 10 intentos.
/// Los errores salen con los mismos `type` del contrato, para que la interfaz se pruebe igual que contra la API.
class DatosDemo {
  DatosDemo({DateTime Function()? reloj, this.latencia = Duration.zero, this.catalogo, int semilla = 7})
    : _reloj = reloj ?? DateTime.now,
      _azar = Random(semilla) {
    _sembrar();
  }

  static const String contrasenaDemo = 'KaizenDemo2026!';
  static const Uuid _uuid = Uuid();

  final DateTime Function() _reloj;
  final Random _azar;

  /// Espera simulada de cada operación (en la app, ~300 ms; en las pruebas, cero).
  Duration latencia;

  /// Con `false`, el Laboratorio y los indicadores responden 503 `analitica-no-disponible` (HomeLab apagado).
  bool analiticaDisponible = true;

  /// Para validar país y estado en el registro (igual que `fn_region`).
  CatalogoRegiones? catalogo;

  ErrorApp? _errorSiguiente;

  /// La próxima operación falla con [error] (para probar estados de error).
  void fallarSiguiente(ErrorApp error) => _errorSiguiente = error;

  /// El reloj de este servidor en memoria (la app lo usa como "ahora" en modo *fake*).
  DateTime Function() get reloj => _reloj;

  DateTime get ahora => _reloj().toUtc();
  DateTime get hoy => Fechas.soloFecha(_reloj());

  // ───────────────────────────── Estado ─────────────────────────────

  final Map<String, UsuarioDemo> usuarios = {};
  final List<Categoria> categorias = [];
  final Map<String, HabitoDemo> habitos = {};
  final Map<String, Map<DateTime, Registro>> registros = {};
  final Map<String, List<Nivel>> niveles = {};
  final Map<String, Sugerencia> sugerencias = {};
  final Map<String, CapsulaDemo> capsulas = {};
  final Map<String, Map<DateTime, Senal>> senales = {};

  /// Quién tiene la sesión (los *fakes* no revisan el token de acceso en cada llamada).
  String? usuarioActual;

  /// Token de renovación vigente → usuario. Los rotados se recuerdan para detectar reutilización.
  final Map<String, String> renovacionesVigentes = {};
  final Map<String, String> renovacionesRotadas = {};
  int _secuenciaTokens = 0;

  /// Token de recuperación → (usuario, vence).
  final Map<String, (String, DateTime)> recuperaciones = {};

  /// El último enlace de recuperación generado (en modo *fake* se imprime en la consola para poder probarlo).
  String? ultimoTokenRecuperacion;

  // ───────────────────────────── Ayudantes ─────────────────────────────

  /// Ejecuta una operación con la latencia y el error simulados. Las reglas lanzan [ErrorApp] y aquí se vuelven
  /// un `Fallo`, igual que hace el cliente de la API.
  Future<Result<T>> ejecutar<T>(T Function() operacion) async {
    if (latencia > Duration.zero) {
      await Future<void>.delayed(latencia);
    }
    final error = _errorSiguiente;
    _errorSiguiente = null;
    if (error != null) {
      return Result.fallo(error);
    }
    try {
      return Result.exito(operacion());
    } on ErrorApp catch (e) {
      return Result.fallo(e);
    }
  }

  /// Error con el mismo problem+json que mandaría la API.
  static ErrorApp error(
    TipoError tipo,
    int status,
    String titulo, {
    String? detalle,
    Map<String, dynamic> extras = const {},
    List<ErrorDeCampo> errores = const [],
    Duration? reintentarEn,
  }) {
    return ErrorApp.desdeProblema(
      Problema(
        type: 'https://kaizen.app/errores/${tipo.sufijo}',
        title: titulo,
        status: status,
        detail: detalle,
        errores: errores,
        extras: extras,
      ),
      reintentarEn: reintentarEn,
    );
  }

  /// 422 `validacion` con errores por campo.
  static ErrorApp validacion(Map<String, String> campos) => error(
    TipoError.validacion,
    422,
    'Datos inválidos',
    errores: [for (final e in campos.entries) ErrorDeCampo(campo: e.key, detalle: e.value)],
  );

  static ErrorApp noEncontrado() => error(TipoError.noEncontrado, 404, 'No encontrado');

  String nuevoId() => _uuid.v4();

  /// El usuario con la sesión abierta, o 401 si no hay.
  UsuarioDemo usuarioDeSesion() {
    final id = usuarioActual;
    final usuario = id == null ? null : usuarios[id];
    if (usuario == null) {
      throw error(TipoError.tokenInvalido, 401, 'Sesión no válida');
    }
    return usuario;
  }

  UsuarioDemo? usuarioPorCorreo(String correo) {
    final c = correo.trim().toLowerCase();
    return usuarios.values.where((u) => u.email == c).firstOrNull;
  }

  /// Hábito del usuario de la sesión; 404 si no existe o es de otro (anti-IDOR, como la API).
  HabitoDemo habitoPropio(String id) {
    final h = habitos[id];
    if (h == null || h.usuarioId != usuarioDeSesion().id) {
      throw noEncontrado();
    }
    return h;
  }

  Iterable<HabitoDemo> habitosDe(String usuarioId) => habitos.values.where((h) => h.usuarioId == usuarioId);

  Categoria categoria(String id) => categorias.firstWhere((c) => c.id == id);

  /// Subcategoría del catálogo completo (con unidades y referencia).
  Subcategoria subcategoria(String id) => categorias.subcategoria(id)!;

  /// Subcategoría por clave (`aerobico_moderado`), como la usan los datos de demo y las pruebas.
  Subcategoria subcategoriaPorClave(String clave) =>
      categorias.todasLasSubcategorias.firstWhere((s) => s.clave == clave);

  /// Emite un par de tokens (de mentira, pero con la misma rotación que la API).
  (String, String) emitirTokens(String usuarioId) {
    _secuenciaTokens++;
    final acceso = 'fake.acceso.$usuarioId.$_secuenciaTokens';
    final renovacion = 'fake.renovacion.$usuarioId.$_secuenciaTokens';
    renovacionesVigentes[renovacion] = usuarioId;
    usuarioActual = usuarioId;
    return (acceso, renovacion);
  }

  /// Revoca todas las sesiones de un usuario.
  void revocarSesiones(String usuarioId) {
    renovacionesVigentes.removeWhere((_, u) => u == usuarioId);
    if (usuarioActual == usuarioId) {
      usuarioActual = null;
    }
  }

  // ───────────────────────────── Rachas ─────────────────────────────

  /// Racha actual, máxima y último día cumplido, con las reglas de la base: solo cuentan los días programados;
  /// hoy todavía no rompe la racha si aún no hay check-in. Los "N por semana" cuentan semanas cumplidas.
  /// **Protector** (igual que `fn_rachas` desde el 27-nov): el primer día programado fallado de cada semana ISO no
  /// rompe la racha (ese día no suma); el segundo de la misma semana sí.
  Racha racha(HabitoDemo h, {DateTime? desde}) {
    final hasta = hoy;
    final inicio = desde ?? Fechas.soloFecha(h.fechaCreacion);
    final regs = registros[h.id] ?? const {};
    DateTime? ultima;
    DateTime? protegido;
    var actual = 0;
    var maxima = 0;
    if (h.frecuencia case NPorSemana(:final veces)) {
      for (var lunes = Fechas.inicioSemana(inicio); !lunes.isAfter(hasta); lunes = lunes.add(const Duration(days: 7))) {
        final cumplidos = [
          for (var i = 0; i < 7; i++)
            if (regs[lunes.add(Duration(days: i))]?.cumplido ?? false) lunes.add(Duration(days: i)),
        ];
        if (cumplidos.isNotEmpty) {
          ultima = cumplidos.last;
        }
        final semanaActual = !hasta.isAfter(lunes.add(const Duration(days: 6)));
        if (cumplidos.length >= veces) {
          actual++;
          maxima = max(maxima, actual);
        } else if (!semanaActual) {
          actual = 0;
        }
      }
    } else {
      DateTime? semanaProtegida;
      for (var d = inicio; !d.isAfter(hasta); d = d.add(const Duration(days: 1))) {
        if (!h.frecuencia.programadoEn(d)) {
          continue;
        }
        if (regs[d]?.cumplido ?? false) {
          actual++;
          maxima = max(maxima, actual);
          ultima = d;
        } else if (d == hasta) {
          // hoy todavía no cuenta como fallo
        } else if (actual > 0 && semanaProtegida != Fechas.inicioSemana(d)) {
          semanaProtegida = Fechas.inicioSemana(d);
          protegido = d;
        } else {
          actual = 0;
        }
      }
    }
    return Racha(
      actual: actual,
      maxima: desde == null ? max(maxima, h.maximaHistorica) : maxima,
      ultimaFecha: ultima,
      protegidaEstaSemana: protegido != null && !protegido.isBefore(Fechas.inicioSemana(hasta)),
    );
  }

  Habito aHabito(HabitoDemo h, DateTime fecha) {
    final reg = registros[h.id]?[fecha];
    final sub = subcategoria(h.subcategoriaId);
    return Habito(
      id: h.id,
      nombre: h.nombre,
      unidad: h.unidad,
      meta: h.meta,
      nivel: h.nivel,
      categoria: categoria(h.categoriaId).resumen,
      subcategoria: sub.resumen,
      prioridad: h.prioridad,
      intencion: h.intencion,
      evaluacion: EvaluadorEvidencia.evaluar(sub, h.unidad, h.meta, h.frecuencia),
      frecuencia: h.frecuencia,
      escaleraActiva: h.escaleraActiva,
      activo: h.activo,
      fechaCreacion: h.fechaCreacion,
      racha: racha(h),
      hoy: HoyHabito(
        fecha: fecha,
        programado: h.frecuencia.programadoEn(fecha),
        registro: reg == null ? null : RegistroDeHoy(id: reg.id, cumplido: reg.cumplido, valor: reg.valor),
      ),
    );
  }

  Capsula aCapsula(CapsulaDemo c) {
    final h = habitos[c.habitoId]!;
    final progreso = racha(h, desde: Fechas.soloFecha(c.creadaEn)).maxima;
    return Capsula(
      id: c.id,
      habitoId: c.habitoId,
      habitoNombre: h.nombre,
      rachaObjetivo: c.rachaObjetivo,
      progreso: progreso,
      sePuedeAbrir: c.estado == EstadoCapsula.abierta || progreso >= c.rachaObjetivo,
      estado: c.estado,
      tieneFoto: c.tieneFoto,
      creadaEn: c.creadaEn,
      abiertaEn: c.abiertaEn,
    );
  }

  // ───────────────────────────── Datos iniciales ─────────────────────────────

  void _sembrar() {
    // El catálogo es el mismo del clúster (mismos ids, unidades y referencias científicas).
    categorias.addAll([
      for (final c in jsonDecode(catalogoDemoJson) as List<dynamic>) Categoria.fromJson(c as Map<String, dynamic>),
    ]);

    final hace = ahora.subtract(const Duration(days: 120));
    UsuarioDemo cuenta(
      String id,
      String email,
      String nombre,
      String pais,
      String? estado,
      String region, {
      RolUsuario rol = RolUsuario.usuario,
      bool consiente = false,
      bool suspendido = false,
      int diasAntiguedad = 120,
    }) {
      final u = UsuarioDemo(
        id: id,
        email: email,
        nombre: nombre,
        contrasena: contrasenaDemo,
        pais: pais,
        region: region,
        rol: rol,
        fechaRegistro: ahora.subtract(Duration(days: diasAntiguedad)),
        consentimientoSenales: consiente,
        consentimientoSenalesEn: consiente ? hace : null,
        suspendido: suspendido,
        suspensionMotivo: suspendido ? 'Publica spam' : null,
      );
      usuarios[id] = u;
      return u;
    }

    final demo = cuenta('u-demo', 'demo@kaizen.test', 'Daniela Demo', 'MX', 'JAL', 'MX-NORTE', consiente: true);
    cuenta('u-admin', 'admin@kaizen.test', 'Admin Kaizen', 'MX', 'CMX', 'MX-CENTRO-SUR', rol: RolUsuario.admin);
    final latam = cuenta('u-latam', 'latam@kaizen.test', 'Lucía Latam', 'CO', null, 'LATAM', consiente: true);
    cuenta('u-nuevo', 'nuevo@kaizen.test', 'Nico Nuevo', 'MX', 'PUE', 'MX-CENTRO-SUR', diasAntiguedad: 0);
    cuenta('u-suspendido', 'suspendido@kaizen.test', 'Sergio Suspendido', 'MX', 'NLE', 'MX-NORTE', suspendido: true);

    // Los hábitos de Daniela son los de los bosquejos de Hoy, con su subcategoría, prioridad e intención.
    final agua = _habito(
      demo.id,
      'Tomar agua',
      'L',
      2,
      'hidratacion',
      const Diaria(),
      racha: 21,
      hoyCumplido: true,
      intencion: 'Después de lavarme los dientes',
    );
    final ejercicio = _habito(
      demo.id,
      'Ejercicio',
      'min',
      30,
      'aerobico_moderado',
      const Diaria(),
      racha: 8,
      hoyCumplido: true,
      metas: const [25, 30],
      prioridad: Prioridad.alta,
      intencion: 'Después de desayunar',
    );
    final leer = _habito(
      demo.id,
      'Leer',
      'min',
      10,
      'lectura',
      const Diaria(),
      racha: 34,
      metas: const [7, 8.5, 10],
      intencion: 'Antes de dormir',
    );
    _habito(
      demo.id,
      'Estudiar inglés',
      'min',
      20,
      'idiomas',
      const DiasSemana(DiasSemana.lunesAViernes),
      racha: 5,
      escalera: false,
      prioridad: Prioridad.baja,
    );
    final dormir = _habito(demo.id, 'Dormir 7 h', 'h', 7, 'sueno', const Diaria(), racha: 2);
    _sugerencia(leer, TipoSugerencia.subir, 11, 92.86, cita: subcategoriaPorClave('lectura').referencia?.cita);
    _capsula(agua, 7, 'Si estás leyendo esto, sí pudiste. Recuerda por qué empezaste: tener más energía.', 21);
    _capsula(ejercicio, 66, 'Sesenta y seis días después, ¿cómo se siente tu cuerpo?', 8);
    _capsula(dormir, 7, 'Una semana durmiendo bien. Sigue así.', 2);

    _habito('u-admin', 'Meditar', 'min', 10, 'meditacion', const Diaria(), racha: 4);
    _habito('u-admin', 'Caminar', 'min', 30, 'aerobico_moderado', const Diaria(), racha: 3);
    // Meta excesiva (Ericsson: ≈4 h/día de práctica como máximo): la Escalera propone bajar a 240.
    final apuntes = _habito('u-admin', 'Repasar apuntes', 'min', 300, 'estudio', const Diaria(), racha: 3);
    _sugerencia(
      apuntes,
      TipoSugerencia.bajar,
      240,
      null,
      motivo: MotivoSugerencia.excedeMaximo,
      cita: subcategoriaPorClave('estudio').referencia?.cita,
    );

    final leerLatam = _habito(latam.id, 'Leer', 'páginas', 15, 'lectura', const Diaria(), racha: 6);
    _habito(latam.id, 'Tomar agua', 'vasos', 8, 'hidratacion', const Diaria(), racha: 12);
    _habito(latam.id, 'Ahorrar', 'pesos', 50, 'ahorro', const NPorSemana(3), racha: 0);
    _sugerencia(leerLatam, TipoSugerencia.subir, 17, 92.86, cita: subcategoriaPorClave('lectura').referencia?.cita);
    _capsula(leerLatam, 30, 'Lucía del futuro: ¿ya terminaste el libro?', 6);

    _habito('u-suspendido', 'Correr', 'km', 3, 'aerobico_moderado', const Diaria(), racha: 1);

    for (final u in [demo, latam]) {
      final dias = senales.putIfAbsent(u.id, () => {});
      for (var i = 1; i <= 30; i++) {
        final d = hoy.subtract(Duration(days: i));
        dias[d] = Senal(fecha: d, animo: 2 + _azar.nextInt(4), energia: 2 + _azar.nextInt(4));
      }
    }

    // Usuarios sintéticos para el panel de administración (paginación y filtros).
    const regiones = ['MX-NORTE', 'MX-CENTRO-SUR', 'LATAM'];
    const paises = ['MX', 'MX', 'AR'];
    for (var i = 1; i <= 45; i++) {
      final n = i.toString().padLeft(3, '0');
      cuenta(
        'u-$n',
        'usuario$n@kaizen.test',
        'Usuario $n',
        paises[i % 3],
        paises[i % 3] == 'MX' ? 'AGU' : null,
        regiones[i % 3],
        consiente: i.isEven,
        diasAntiguedad: 10 + i,
      );
    }
  }

  HabitoDemo _habito(
    String usuarioId,
    String nombre,
    String unidad,
    double meta,
    String subcategoriaClave,
    Frecuencia frecuencia, {
    required int racha,
    bool hoyCumplido = false,
    bool escalera = true,
    List<double>? metas,
    double constancia = 0.7,
    int prioridad = Prioridad.media,
    String? intencion,
  }) {
    final creado = ahora.subtract(const Duration(days: 120));
    final sub = subcategoriaPorClave(subcategoriaClave);
    final h = HabitoDemo(
      id: nuevoId(),
      usuarioId: usuarioId,
      nombre: nombre,
      unidad: unidad,
      meta: meta,
      nivel: metas?.length ?? 1,
      subcategoriaId: sub.id,
      categoriaId: categorias.categoriaDe(sub.id)!.id,
      prioridad: prioridad,
      intencion: intencion,
      frecuencia: frecuencia,
      escaleraActiva: escalera,
      activo: true,
      fechaCreacion: creado,
    );
    habitos[h.id] = h;

    // Niveles alcanzados: repartidos en los 120 días.
    final todas = metas ?? [meta];
    final tramo = 120 ~/ todas.length;
    niveles[h.id] = [
      for (var i = 0; i < todas.length; i++)
        Nivel(
          nivel: i + 1,
          meta: todas[i],
          desde: Fechas.soloFecha(creado).add(Duration(days: i * tramo)),
          hasta: i == todas.length - 1 ? null : Fechas.soloFecha(creado).add(Duration(days: (i + 1) * tramo)),
        ),
    ];

    // Historial: los últimos [racha] días programados cumplidos; antes, fallos hasta que dos caen en la misma semana
    // (así el protector no alarga la racha y la racha queda exactamente en [racha]); antes de eso, al azar.
    final regs = registros.putIfAbsent(h.id, () => {});
    final inicio = Fechas.soloFecha(creado);
    var pendientes = racha;
    var corte = false;
    DateTime? semanaDelFallo;
    for (
      var d = hoyCumplido ? hoy : hoy.subtract(const Duration(days: 1));
      !d.isBefore(inicio);
      d = d.subtract(const Duration(days: 1))
    ) {
      final programado = frecuencia is NPorSemana || frecuencia.programadoEn(d);
      if (!programado) {
        continue;
      }
      bool cumplido;
      if (frecuencia is NPorSemana) {
        cumplido = _azar.nextDouble() < 0.35;
      } else if (pendientes > 0) {
        cumplido = true;
        pendientes--;
      } else if (!corte) {
        cumplido = false;
        final semana = Fechas.inicioSemana(d);
        corte = semana == semanaDelFallo;
        semanaDelFallo = semana;
      } else {
        cumplido = _azar.nextDouble() < constancia;
      }
      if (cumplido || _azar.nextBool()) {
        regs[d] = Registro(
          id: nuevoId(),
          habitoId: h.id,
          fecha: d,
          cumplido: cumplido,
          valor: cumplido ? meta : null,
          origen: _azar.nextInt(4) == 0 ? OrigenRegistro.rapido : OrigenRegistro.manual,
          registradoEn: d.add(Duration(hours: 13 + _azar.nextInt(10))),
        );
      }
    }
    return h;
  }

  void _sugerencia(
    HabitoDemo h,
    TipoSugerencia tipo,
    double propuesta,
    double? cumplimiento, {
    MotivoSugerencia? motivo,
    String? cita,
  }) {
    final s = Sugerencia(
      id: nuevoId(),
      habitoId: h.id,
      habitoNombre: h.nombre,
      tipo: tipo,
      metaActual: h.meta,
      metaPropuesta: propuesta,
      cumplimiento14d: cumplimiento,
      motivo:
          motivo ??
          (tipo == TipoSugerencia.subir ? MotivoSugerencia.cumplimientoAlto : MotivoSugerencia.cumplimientoBajo),
      cita: cita,
      estado: EstadoSugerencia.pendiente,
      creadaEn: hoy.add(const Duration(hours: 8)),
    );
    sugerencias[s.id] = s;
  }

  void _capsula(HabitoDemo h, int objetivo, String mensaje, int diasAtras) {
    final c = CapsulaDemo(
      id: nuevoId(),
      usuarioId: h.usuarioId,
      habitoId: h.id,
      rachaObjetivo: objetivo,
      mensaje: mensaje,
      tieneFoto: false,
      creadaEn: hoy.subtract(Duration(days: diasAtras)),
    );
    capsulas[c.id] = c;
  }

  /// Como `sp_admin_actualizar_subcategoria(..., activa => false)`: deja de ofrecerse y de aceptarse en hábitos nuevos.
  @visibleForTesting
  void desactivarSubcategoria(String id) {
    for (final c in categorias) {
      final i = c.subcategorias.indexWhere((s) => s.id == id);
      if (i >= 0) {
        c.subcategorias[i] = c.subcategorias[i].copyWith(activa: false);
      }
    }
  }

  @visibleForTesting
  int get totalRegistros => registros.values.fold(0, (s, m) => s + m.length);
}

/// Usuario del servidor en memoria (con su contraseña en claro: solo existe en modo *fake*).
class UsuarioDemo {
  UsuarioDemo({
    required this.id,
    required this.email,
    required this.nombre,
    required this.contrasena,
    required this.pais,
    required this.region,
    required this.rol,
    required this.fechaRegistro,
    required this.consentimientoSenales,
    this.consentimientoSenalesEn,
    this.suspendido = false,
    this.suspensionMotivo,
  });

  final String id;
  final String email;
  String nombre;
  String contrasena;
  final String pais;
  final String region;
  final RolUsuario rol;
  final DateTime fechaRegistro;
  bool consentimientoSenales;
  DateTime? consentimientoSenalesEn;
  bool suspendido;
  DateTime? suspendidoEn;
  String? suspensionMotivo;
  int intentosFallidos = 0;
  DateTime? bloqueadoHasta;

  UsuarioToken aToken() => UsuarioToken(id: id, nombre: nombre, rol: rol, region: region);

  Cuenta aCuenta() => Cuenta(
    id: id,
    nombre: nombre,
    email: email,
    pais: pais,
    region: region,
    rol: rol,
    fechaRegistro: fechaRegistro,
    consentimientoSenales: consentimientoSenales,
    consentimientoSenalesEn: consentimientoSenalesEn,
  );
}

class HabitoDemo {
  HabitoDemo({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    required this.unidad,
    required this.meta,
    required this.nivel,
    required this.subcategoriaId,
    required this.categoriaId,
    required this.frecuencia,
    required this.escaleraActiva,
    required this.activo,
    required this.fechaCreacion,
    this.prioridad = Prioridad.media,
    this.intencion,
  });

  final String id;
  final String usuarioId;
  String nombre;
  String unidad;
  double meta;
  int nivel;
  String subcategoriaId;

  /// La categoría de su subcategoría (la base la fija con un trigger).
  String categoriaId;
  int prioridad;
  String? intencion;
  final Frecuencia frecuencia;
  bool escaleraActiva;
  bool activo;
  final DateTime fechaCreacion;
  int maximaHistorica = 0;
}

class CapsulaDemo {
  CapsulaDemo({
    required this.id,
    required this.usuarioId,
    required this.habitoId,
    required this.rachaObjetivo,
    required this.mensaje,
    required this.tieneFoto,
    required this.creadaEn,
  });

  final String id;
  final String usuarioId;
  final String habitoId;
  final int rachaObjetivo;

  /// En la API va cifrado con AES-256-GCM; aquí basta en memoria.
  final String mensaje;
  final bool tieneFoto;
  final DateTime creadaEn;
  EstadoCapsula estado = EstadoCapsula.sellada;
  DateTime? abiertaEn;
}
