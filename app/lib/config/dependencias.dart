import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/fake/datos_demo.dart';
import '../data/repositories/admin/admin_repository.dart';
import '../data/repositories/admin/admin_repository_api.dart';
import '../data/repositories/admin/admin_repository_fake.dart';
import '../data/repositories/auth/auth_repository.dart';
import '../data/repositories/auth/auth_repository_api.dart';
import '../data/repositories/auth/auth_repository_fake.dart';
import '../data/repositories/capsulas/capsulas_repository.dart';
import '../data/repositories/capsulas/capsulas_repository_api.dart';
import '../data/repositories/capsulas/capsulas_repository_fake.dart';
import '../data/repositories/categorias/categorias_repository.dart';
import '../data/repositories/categorias/categorias_repository_api.dart';
import '../data/repositories/categorias/categorias_repository_fake.dart';
import '../data/repositories/cuenta/cuenta_repository.dart';
import '../data/repositories/cuenta/cuenta_repository_api.dart';
import '../data/repositories/cuenta/cuenta_repository_fake.dart';
import '../data/repositories/escalera/escalera_repository.dart';
import '../data/repositories/escalera/escalera_repository_api.dart';
import '../data/repositories/escalera/escalera_repository_fake.dart';
import '../data/repositories/habitos/habitos_repository.dart';
import '../data/repositories/habitos/habitos_repository_api.dart';
import '../data/repositories/habitos/habitos_repository_fake.dart';
import '../data/repositories/laboratorio/laboratorio_repository.dart';
import '../data/repositories/laboratorio/laboratorio_repository_api.dart';
import '../data/repositories/laboratorio/laboratorio_repository_fake.dart';
import '../data/repositories/progreso/progreso_repository.dart';
import '../data/repositories/progreso/progreso_repository_api.dart';
import '../data/repositories/progreso/progreso_repository_fake.dart';
import '../data/repositories/registros/registros_repository.dart';
import '../data/repositories/registros/registros_repository_api.dart';
import '../data/repositories/registros/registros_repository_fake.dart';
import '../data/repositories/senales/senales_repository.dart';
import '../data/repositories/senales/senales_repository_api.dart';
import '../data/repositories/senales/senales_repository_fake.dart';
import '../data/services/almacen_seguro.dart';
import '../data/services/api/cliente_api.dart';
import '../data/services/api/interceptor_zona_horaria.dart';
import '../data/services/gestor_tokens.dart';
import '../utils/paises_estados.dart';
import '../utils/reloj.dart';
import '../data/services/recordatorios/servicio_recordatorios.dart';
import '../data/services/recordatorios/servicio_recordatorios_local.dart';
import '../data/services/recordatorios/servicio_recordatorios_con_copia.dart';
import '../data/services/base_local/almacen_local.dart';
import '../data/services/base_local/base_local.dart';
import '../data/repositories/categorias/categorias_repository_local.dart';
import '../data/repositories/habitos/habitos_repository_local.dart';
import '../data/repositories/registros/registros_repository_local.dart';
import '../data/sync/monitor_conexion.dart';
import '../data/sync/sincronizador.dart';
import '../data/services/servicio_sesion.dart';
import '../routing/estado_sesion.dart';
import 'entorno.dart';

/// Todo lo que la app necesita de la capa de datos, armado según `KAIZEN_FUENTE`:
/// repositorios *fake* (datos en memoria, sin red) o contra la API real.
///
/// Las pantallas nunca saben cuál se usa: piden la interfaz (`context.read<HabitosRepository>()`).
class Dependencias {
  Dependencias({
    required this.tokens,
    required this.auth,
    required this.categorias,
    required this.habitos,
    required this.registros,
    required this.escalera,
    required this.progreso,
    required this.senales,
    required this.laboratorio,
    required this.capsulas,
    required this.cuenta,
    required this.admin,
    required this.recordatorios,
    required this.base,
    required this.almacenLocal,
    required this.monitor,
    required this.sincronizador,
    this.catalogo,
    this.datosDemo,
    this.reloj = relojDelSistema,
  });

  /// Repositorios *fake* sobre [datos] (los mismos datos para todos, como un servidor), con la misma capa local que
  /// la API: base en memoria, cola sin conexión y sincronizador. Con [monitor] sin red, el "servidor" no contesta.
  factory Dependencias.fake({
    DatosDemo? datos,
    AlmacenSeguro? almacen,
    CatalogoRegiones? catalogo,
    Duration latencia = Duration.zero,
    ServicioRecordatorios? recordatorios,
    BaseLocal? base,
    MonitorConexion? monitor,
    Duration? reintento,
  }) {
    final d = datos ?? DatosDemo(latencia: latencia, catalogo: catalogo);
    d.catalogo ??= catalogo;
    final red = monitor ?? MonitorConexionManual();
    d.hayRed = () => red.hayRed;
    final auth = AuthRepositoryFake(d);
    final tokens = GestorTokens(almacen ?? AlmacenEnMemoria())..renovador = auth.renovar;
    return Dependencias._conCapaLocal(
      tokens: tokens,
      auth: auth,
      categorias: CategoriasRepositoryFake(d),
      habitos: HabitosRepositoryFake(d),
      registros: RegistrosRepositoryFake(d),
      escalera: EscaleraRepositoryFake(d),
      progreso: ProgresoRepositoryFake(d),
      senales: SenalesRepositoryFake(d),
      laboratorio: LaboratorioRepositoryFake(d),
      capsulas: CapsulasRepositoryFake(d),
      cuenta: CuentaRepositoryFake(d),
      admin: AdminRepositoryFake(d),
      recordatorios: recordatorios ?? ServicioRecordatoriosEnMemoria(),
      base: base ?? BaseLocal.enMemoria(),
      monitor: red,
      reintento: reintento,
      catalogo: catalogo,
      datosDemo: d,
      reloj: d.reloj,
    );
  }

  /// Repositorios contra la API de [entorno], con la base local en el dispositivo (`kaizen.sqlite`).
  factory Dependencias.api(
    Entorno entorno, {
    AlmacenSeguro? almacen,
    CatalogoRegiones? catalogo,
    ServicioRecordatorios? recordatorios,
    BaseLocal? base,
    MonitorConexion? monitor,
  }) {
    final tokens = GestorTokens(almacen ?? crearAlmacenSeguro());
    final api = ClienteApi(
      baseUrl: entorno.apiBaseUrl,
      tokens: tokens,
      zonaHoraria: ProveedorZonaHoraria(respaldo: entorno.zonaHorariaDefecto),
    );
    return Dependencias._conCapaLocal(
      tokens: tokens,
      auth: AuthRepositoryApi(api),
      categorias: CategoriasRepositoryApi(api),
      habitos: HabitosRepositoryApi(api),
      registros: RegistrosRepositoryApi(api),
      escalera: EscaleraRepositoryApi(api),
      progreso: ProgresoRepositoryApi(api),
      senales: SenalesRepositoryApi(api),
      laboratorio: LaboratorioRepositoryApi(api),
      capsulas: CapsulasRepositoryApi(api),
      cuenta: CuentaRepositoryApi(api),
      admin: AdminRepositoryApi(api),
      recordatorios: recordatorios ?? recordatoriosDeLaPlataforma(),
      base: base ?? BaseLocal.abrir(),
      monitor: monitor ?? MonitorConexionPlus(),
      reintento: const Duration(minutes: 1),
      catalogo: catalogo,
    );
  }

  /// Envuelve los repositorios remotos con la base local (Paso 8): categorías, hábitos y check-ins leen de la copia
  /// sin conexión, y el check-in se encola. Los demás se usan directo por ahora.
  factory Dependencias._conCapaLocal({
    required GestorTokens tokens,
    required AuthRepository auth,
    required CategoriasRepository categorias,
    required HabitosRepository habitos,
    required RegistrosRepository registros,
    required EscaleraRepository escalera,
    required ProgresoRepository progreso,
    required SenalesRepository senales,
    required LaboratorioRepository laboratorio,
    required CapsulasRepository capsulas,
    required CuentaRepository cuenta,
    required AdminRepository admin,
    required ServicioRecordatorios recordatorios,
    required BaseLocal base,
    required MonitorConexion monitor,
    required Duration? reintento,
    CatalogoRegiones? catalogo,
    DatosDemo? datosDemo,
    Reloj reloj = relojDelSistema,
  }) {
    final almacenLocal = AlmacenLocal(base);
    final sincronizador = Sincronizador(
      almacen: almacenLocal,
      remoto: registros,
      monitor: monitor,
      reintento: reintento,
    );
    void reportar(bool llego) => llego ? sincronizador.marcarEnLinea() : sincronizador.marcarSinConexion();
    return Dependencias(
      tokens: tokens,
      auth: auth,
      categorias: CategoriasRepositoryLocal(remoto: categorias, almacen: almacenLocal, reportar: reportar),
      habitos: HabitosRepositoryLocal(remoto: habitos, almacen: almacenLocal, reportar: reportar),
      registros: RegistrosRepositoryLocal(remoto: registros, almacen: almacenLocal, reportar: reportar),
      escalera: escalera,
      progreso: progreso,
      senales: senales,
      laboratorio: laboratorio,
      capsulas: capsulas,
      cuenta: cuenta,
      admin: admin,
      recordatorios: recordatorios.disponible
          ? ServicioRecordatoriosConCopia(recordatorios, almacenLocal)
          : recordatorios,
      base: base,
      almacenLocal: almacenLocal,
      monitor: monitor,
      sincronizador: sincronizador,
      catalogo: catalogo,
      datosDemo: datosDemo,
      reloj: reloj,
    );
  }

  /// Según `KAIZEN_FUENTE`. En modo *fake* simula ~300 ms de red para que se vean los estados de carga.
  ///
  /// [base] solo lo pasan las pruebas (la base real necesita la carpeta privada del dispositivo).
  factory Dependencias.desdeEntorno(Entorno entorno, {CatalogoRegiones? catalogo, BaseLocal? base}) => entorno.usaFakes
      ? Dependencias.fake(
          catalogo: catalogo,
          latencia: const Duration(milliseconds: 300),
          recordatorios: recordatoriosDeLaPlataforma(),
          // Base real en el dispositivo y red real: en el teléfono, el modo avión deja al "servidor" sin contestar.
          base: base ?? BaseLocal.abrir(),
          monitor: MonitorConexionPlus(),
          reintento: const Duration(minutes: 1),
        )
      : Dependencias.api(entorno, catalogo: catalogo, base: base);

  final GestorTokens tokens;
  final AuthRepository auth;
  final CategoriasRepository categorias;
  final HabitosRepository habitos;
  final RegistrosRepository registros;
  final EscaleraRepository escalera;
  final ProgresoRepository progreso;
  final SenalesRepository senales;
  final LaboratorioRepository laboratorio;
  final CapsulasRepository capsulas;
  final CuentaRepository cuenta;
  final AdminRepository admin;

  /// Recordatorios locales de los hábitos.
  final ServicioRecordatorios recordatorios;

  /// Notificaciones locales en Android e iOS; en escritorio y web no hay recordatorios.
  static ServicioRecordatorios recordatoriosDeLaPlataforma() =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)
      ? ServicioRecordatoriosLocal()
      : ServicioRecordatoriosEnMemoria(disponible: false);

  /// Base local (SQLite con drift).
  final BaseLocal base;

  /// Lo que se guarda y se lee de la base local.
  final AlmacenLocal almacenLocal;

  /// ¿Hay red? (`connectivity_plus` en la app; manual en las pruebas).
  final MonitorConexion monitor;

  /// Envía la cola sin conexión.
  final Sincronizador sincronizador;

  /// Países y estados (para el registro). Se carga una vez al arrancar.
  final CatalogoRegiones? catalogo;

  /// Solo en modo *fake*: el "servidor" en memoria (las pruebas lo usan para preparar casos).
  final DatosDemo? datosDemo;

  /// "Ahora" para toda la app. Con *fakes* es el mismo reloj del servidor en memoria (las pruebas lo fijan).
  final Reloj reloj;

  /// El servicio de sesión con la base local: al salir, primero envía la cola y después la borra.
  ServicioSesion crearServicioSesion(EstadoSesion estado) => ServicioSesion(
    auth: auth,
    tokens: tokens,
    estado: estado,
    enviarPendientes: () async {
      await sincronizador.sincronizar();
    },
    borrarDatosLocales: almacenLocal.borrarTodo,
  );

  List<SingleChildWidget> proveedores() => [
    Provider<GestorTokens>.value(value: tokens),
    Provider<AuthRepository>.value(value: auth),
    Provider<CategoriasRepository>.value(value: categorias),
    Provider<HabitosRepository>.value(value: habitos),
    Provider<RegistrosRepository>.value(value: registros),
    Provider<EscaleraRepository>.value(value: escalera),
    Provider<ProgresoRepository>.value(value: progreso),
    Provider<SenalesRepository>.value(value: senales),
    Provider<LaboratorioRepository>.value(value: laboratorio),
    Provider<CapsulasRepository>.value(value: capsulas),
    Provider<CuentaRepository>.value(value: cuenta),
    Provider<AdminRepository>.value(value: admin),
    Provider<CatalogoRegiones?>.value(value: catalogo),
    Provider<Reloj>.value(value: reloj),
    Provider<ServicioRecordatorios>.value(value: recordatorios),
    ChangeNotifierProvider<Sincronizador>.value(value: sincronizador),
  ];
}
