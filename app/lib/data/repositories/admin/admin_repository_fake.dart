import 'dart:math';

import '../../../domain/models/admin.dart';
import '../../../domain/models/categoria.dart';
import '../../../domain/models/usuario.dart';
import '../../../utils/fechas.dart';
import '../../../utils/result.dart';
import '../../../utils/validadores.dart';
import '../../fake/datos_demo.dart';
import '../../services/api/errores_api.dart';
import 'admin_repository.dart';

class AdminRepositoryFake implements AdminRepository {
  AdminRepositoryFake(this._datos);

  final DatosDemo _datos;

  UsuarioDemo _admin() {
    final u = _datos.usuarioDeSesion();
    if (u.rol != RolUsuario.admin) {
      throw DatosDemo.error(TipoError.rolInsuficiente, 403, 'Se requiere rol de administrador');
    }
    return u;
  }

  /// "Daniela Demo" → "D***** D***"; "demo@kaizen.test" → "d***@kaizen.test".
  static String enmascararNombre(String nombre) =>
      nombre.split(' ').map((p) => p.isEmpty ? p : '${p[0]}${'*' * (p.length - 1)}').join(' ');
  static String enmascararCorreo(String correo) {
    final i = correo.indexOf('@');
    return i <= 0 ? '***' : '${correo[0]}***${correo.substring(i)}';
  }

  UsuarioAdmin _vista(UsuarioDemo u) => UsuarioAdmin(
    id: u.id,
    region: u.region,
    pais: u.pais,
    rol: u.rol,
    fechaRegistro: u.fechaRegistro,
    nombreMascara: enmascararNombre(u.nombre),
    emailMascara: enmascararCorreo(u.email),
    bloqueado: u.bloqueadoHasta?.isAfter(_datos.ahora) ?? false,
    consienteSenales: u.consentimientoSenales,
    suspendido: u.suspendido,
    suspendidoEn: u.suspendidoEn,
    suspensionMotivo: u.suspensionMotivo,
  );

  @override
  Future<Result<Pagina<UsuarioAdmin>>> usuarios(FiltroUsuarios f) => _datos.ejecutar(() {
    _admin();
    final correo = f.email?.trim().toLowerCase();
    final todos =
        _datos.usuarios.values
            .where(
              (u) =>
                  (f.region == null || u.region == f.region) &&
                  (f.rol == null || u.rol == f.rol) &&
                  (f.suspendido == null || u.suspendido == f.suspendido) &&
                  (correo == null || correo.isEmpty || u.email == correo), // solo búsqueda exacta
            )
            .toList()
          ..sort((a, b) => a.fechaRegistro.compareTo(b.fechaRegistro));
    final porPagina = f.porPagina.clamp(1, 100);
    final inicio = (f.pagina - 1) * porPagina;
    return Pagina(
      elementos: [for (final u in todos.skip(inicio).take(porPagina)) _vista(u)],
      pagina: f.pagina,
      porPagina: porPagina,
      total: todos.length,
    );
  });

  @override
  Future<Result<UsuarioAdmin>> cambiarSuspension(String id, {required bool suspendido, String? motivo}) =>
      _datos.ejecutar(() {
        final admin = _admin();
        final u = _datos.usuarios[id];
        if (u == null) {
          throw DatosDemo.noEncontrado();
        }
        if (u.id == admin.id || u.rol == RolUsuario.admin) {
          throw DatosDemo.error(TipoError.rolInsuficiente, 403, 'No se puede suspender a un administrador');
        }
        if (suspendido && Validadores.motivoSuspension(motivo) != null) {
          throw DatosDemo.validacion({'motivo': 'De 3 a 200 caracteres'});
        }
        u
          ..suspendido = suspendido
          ..suspendidoEn = suspendido ? _datos.ahora : null
          ..suspensionMotivo = suspendido ? motivo!.trim() : null;
        if (suspendido) {
          _datos.revocarSesiones(u.id);
        }
        return _vista(u);
      });

  @override
  Future<Result<MetricasAdmin>> metricas() => _datos.ejecutar(() {
    _admin();
    final activos = _datos.usuarios.values.where((u) => !u.suspendido).length;
    final regiones = {for (final u in _datos.usuarios.values) u.region};
    return MetricasAdmin(
      resumen: ResumenMetricas(
        usuariosActivos: activos,
        variacion: 8,
        cumplimientoGlobal: 76,
        categoriasActivas: _datos.categorias.where((c) => c.activa).length,
      ),
      porRegion: [
        for (final r in regiones)
          MetricaRegion(
            region: r,
            categoria: 'Ejercicio',
            usuarios: _datos.usuarios.values.where((u) => u.region == r).length,
            habitos: _datos.habitos.values.where((h) => _datos.usuarios[h.usuarioId]?.region == r).length,
            rachaPromedio: 6.5,
          ),
      ],
    );
  });

  @override
  Future<Result<List<Categoria>>> categorias() => _datos.ejecutar(() {
    _admin();
    return List.of(_datos.categorias)..sort((a, b) => a.nombre.compareTo(b.nombre));
  });

  void _nombreUnico(String nombre, {String? exceptoId}) {
    if (Validadores.nombreCategoria(nombre) != null) {
      throw DatosDemo.validacion({'nombre': 'De 2 a 40 caracteres'});
    }
    final n = nombre.trim().toLowerCase();
    if (_datos.categorias.any((c) => c.id != exceptoId && c.nombre.toLowerCase() == n)) {
      throw DatosDemo.error(TipoError.nombreDuplicado, 409, 'Ya existe una categoría con ese nombre');
    }
  }

  @override
  Future<Result<Categoria>> crearCategoria(String nombre) => _datos.ejecutar(() {
    _admin();
    _nombreUnico(nombre);
    final c = Categoria(id: 'cat-${_datos.nuevoId()}', nombre: nombre.trim());
    _datos.categorias.add(c);
    return c;
  });

  @override
  Future<Result<Categoria>> actualizarCategoria(String id, {String? nombre, bool? activa}) => _datos.ejecutar(() {
    _admin();
    final i = _datos.categorias.indexWhere((c) => c.id == id);
    if (i < 0) {
      throw DatosDemo.noEncontrado();
    }
    if (nombre != null) {
      _nombreUnico(nombre, exceptoId: id);
    }
    final c = _datos.categorias[i].copyWith(nombre: nombre?.trim(), activa: activa);
    _datos.categorias[i] = c;
    return c;
  });

  @override
  Future<Result<Indicador>> indicador(String codigo) => _datos.ejecutar(() {
    _admin();
    if (!_datos.analiticaDisponible) {
      throw DatosDemo.error(TipoError.analiticaNoDisponible, 503, 'La analítica no está disponible');
    }
    final serie = _series[codigo];
    if (serie == null) {
      throw DatosDemo.noEncontrado();
    }
    return Indicador(
      codigo: codigo,
      titulo: serie.$1,
      grafica: serie.$2,
      origen: serie.$3,
      datosSinteticos: true,
      periodo: PeriodoIndicador(desde: _datos.hoy.subtract(const Duration(days: 89)), hasta: _datos.hoy),
      series: serie.$4(_datos.hoy),
      generadoEn: _datos.hoy.add(const Duration(hours: 9, minutes: 4)),
    );
  });

  /// Indicadores I1–I6 con la forma de la sección 6 del documento de MongoDB.
  static final Map<String, (String, String, String, List<Map<String, dynamic>> Function(DateTime))> _series = {
    'I1': (
      'Cumplimiento diario y semanal',
      'lineas',
      'resumen_diario vía ETL',
      (hoy) => [
        for (var i = 89; i >= 0; i--)
          {
            'etiqueta': Fechas.iso(hoy.subtract(Duration(days: i))),
            'valor': 60 + 15 * sin(i / 9),
            'semanal': 64 + 8 * sin(i / 14),
          },
      ],
    ),
    'I2': (
      'Distribución de rachas por categoría',
      'boxplot',
      'PostgreSQL (racha, habito, categoria) vía ETL',
      (_) => [
        {'etiqueta': 'Salud', 'min': 0, 'q1': 4, 'mediana': 9, 'q3': 16, 'max': 61, 'n': 412},
        {'etiqueta': 'Aprendizaje', 'min': 0, 'q1': 3, 'mediana': 7, 'q3': 12, 'max': 44, 'n': 380},
        {'etiqueta': 'Ejercicio', 'min': 0, 'q1': 2, 'mediana': 6, 'q3': 11, 'max': 39, 'n': 455},
        {'etiqueta': 'Sueño', 'min': 0, 'q1': 2, 'mediana': 4, 'q3': 8, 'max': 30, 'n': 298},
      ],
    ),
    'I3': (
      'Usuarios activos por región',
      'barras',
      'metricas_globales',
      (_) => [
        {'etiqueta': 'MX-CENTRO-SUR', 'valor': 655},
        {'etiqueta': 'MX-NORTE', 'valor': 331},
        {'etiqueta': 'LATAM', 'valor': 118},
      ],
    ),
    'I4': (
      'Efecto de la Escalera',
      'barras_agrupadas',
      'PostgreSQL (sugerencia_ajuste, nivel_habito, registro) vía ETL',
      (_) => [
        {'etiqueta': 'Salud', 'antes': 62.0, 'despues': 78.5, 'n': 120},
        {'etiqueta': 'Aprendizaje', 'antes': 48.0, 'despues': 69.0, 'n': 96},
        {'etiqueta': 'Ejercicio', 'antes': 66.0, 'despues': 81.0, 'n': 140},
      ],
    ),
    'I5': (
      'Hábito y energía',
      'mapa_calor',
      'resumen_diario',
      (_) => [
        {'etiqueta': 'Ejercicio', 'variable': 'energia', 'valor': 0.8, 'n': 310},
        {'etiqueta': 'Hidratación', 'variable': 'energia', 'valor': 0.3, 'n': 280},
        {'etiqueta': 'Lectura', 'variable': 'animo', 'valor': 0.1, 'n': 190},
        {'etiqueta': 'Sueño', 'variable': 'energia', 'valor': 0.8, 'n': 260},
      ],
    ),
    'I6': (
      'Retención con cápsula',
      'barras_agrupadas',
      'resumen_diario',
      (_) => [
        {'etiqueta': '30 días', 'con_capsula': 74.0, 'sin_capsula': 51.3},
        {'etiqueta': '60 días', 'con_capsula': 63.0, 'sin_capsula': 40.0},
        {'etiqueta': '90 días', 'con_capsula': 55.0, 'sin_capsula': 31.0},
      ],
    ),
  };
}
