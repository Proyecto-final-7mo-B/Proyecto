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
    this.catalogo,
    this.datosDemo,
    this.reloj = relojDelSistema,
  });

  /// Repositorios *fake* sobre [datos] (los mismos datos para todos, como un servidor).
  factory Dependencias.fake({
    DatosDemo? datos,
    AlmacenSeguro? almacen,
    CatalogoRegiones? catalogo,
    Duration latencia = Duration.zero,
    ServicioRecordatorios? recordatorios,
  }) {
    final d = datos ?? DatosDemo(latencia: latencia, catalogo: catalogo);
    d.catalogo ??= catalogo;
    final auth = AuthRepositoryFake(d);
    final tokens = GestorTokens(almacen ?? AlmacenEnMemoria())..renovador = auth.renovar;
    return Dependencias(
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
      catalogo: catalogo,
      datosDemo: d,
      reloj: d.reloj,
    );
  }

  /// Repositorios contra la API de [entorno].
  factory Dependencias.api(
    Entorno entorno, {
    AlmacenSeguro? almacen,
    CatalogoRegiones? catalogo,
    ServicioRecordatorios? recordatorios,
  }) {
    final tokens = GestorTokens(almacen ?? crearAlmacenSeguro());
    final api = ClienteApi(
      baseUrl: entorno.apiBaseUrl,
      tokens: tokens,
      zonaHoraria: ProveedorZonaHoraria(respaldo: entorno.zonaHorariaDefecto),
    );
    return Dependencias(
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
      catalogo: catalogo,
    );
  }

  /// Según `KAIZEN_FUENTE`. En modo *fake* simula ~300 ms de red para que se vean los estados de carga.
  factory Dependencias.desdeEntorno(Entorno entorno, {CatalogoRegiones? catalogo}) => entorno.usaFakes
      ? Dependencias.fake(
          catalogo: catalogo,
          latencia: const Duration(milliseconds: 300),
          recordatorios: recordatoriosDeLaPlataforma(),
        )
      : Dependencias.api(entorno, catalogo: catalogo);

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

  /// Países y estados (para el registro). Se carga una vez al arrancar.
  final CatalogoRegiones? catalogo;

  /// Solo en modo *fake*: el "servidor" en memoria (las pruebas lo usan para preparar casos).
  final DatosDemo? datosDemo;

  /// "Ahora" para toda la app. Con *fakes* es el mismo reloj del servidor en memoria (las pruebas lo fijan).
  final Reloj reloj;

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
  ];
}
