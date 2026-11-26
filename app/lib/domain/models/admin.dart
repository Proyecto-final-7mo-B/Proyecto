import 'package:json_annotation/json_annotation.dart';

import 'conversores.dart';
import 'usuario.dart';

part 'admin.g.dart';

/// Página de resultados: `{"elementos": [...], "pagina": 1, "por_pagina": 20, "total": 134}`.
class Pagina<T> {
  const Pagina({required this.elementos, required this.pagina, required this.porPagina, required this.total});

  factory Pagina.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) convertir) => Pagina(
    elementos: [for (final e in json['elementos'] as List<dynamic>) convertir(e as Map<String, dynamic>)],
    pagina: (json['pagina'] as num).toInt(),
    porPagina: (json['por_pagina'] as num).toInt(),
    total: (json['total'] as num).toInt(),
  );

  final List<T> elementos;
  final int pagina;
  final int porPagina;
  final int total;

  int get paginas => total == 0 ? 1 : (total / porPagina).ceil();
}

/// Usuario visto por el admin (datos enmascarados, de `v_usuario_admin`).
@JsonSerializable()
class UsuarioAdmin {
  const UsuarioAdmin({
    required this.id,
    required this.region,
    required this.pais,
    required this.rol,
    required this.fechaRegistro,
    required this.nombreMascara,
    required this.emailMascara,
    required this.bloqueado,
    required this.consienteSenales,
    required this.suspendido,
    this.suspendidoEn,
    this.suspensionMotivo,
  });

  factory UsuarioAdmin.fromJson(Map<String, dynamic> json) => _$UsuarioAdminFromJson(json);

  final String id;
  final String region;
  final String pais;
  final RolUsuario rol;
  @InstanteConverter()
  final DateTime fechaRegistro;
  final String nombreMascara;
  final String emailMascara;
  final bool bloqueado;
  final bool consienteSenales;
  final bool suspendido;
  @InstanteNuloConverter()
  final DateTime? suspendidoEn;
  final String? suspensionMotivo;

  Map<String, dynamic> toJson() => _$UsuarioAdminToJson(this);
}

/// Filtros de `GET /admin/usuarios`.
class FiltroUsuarios {
  const FiltroUsuarios({this.region, this.rol, this.suspendido, this.email, this.pagina = 1, this.porPagina = 20});

  final String? region;
  final RolUsuario? rol;
  final bool? suspendido;

  /// Búsqueda **exacta** por correo (por HMAC en la base).
  final String? email;
  final int pagina;
  final int porPagina;

  Map<String, String> aParametros() => {
    'region': ?region,
    if (rol != null) 'rol': rol!.name,
    if (suspendido != null) 'suspendido': '$suspendido',
    if (email != null && email!.trim().isNotEmpty) 'email': email!.trim().toLowerCase(),
    'pagina': '$pagina',
    'por_pagina': '$porPagina',
  };
}

@JsonSerializable()
class ResumenMetricas {
  const ResumenMetricas({
    required this.usuariosActivos,
    required this.cumplimientoGlobal,
    required this.categoriasActivas,
    this.variacion,
  });

  factory ResumenMetricas.fromJson(Map<String, dynamic> json) => _$ResumenMetricasFromJson(json);

  final int usuariosActivos;
  final double? variacion;
  final double cumplimientoGlobal;
  final int categoriasActivas;

  Map<String, dynamic> toJson() => _$ResumenMetricasToJson(this);
}

@JsonSerializable()
class MetricaRegion {
  const MetricaRegion({
    required this.region,
    required this.categoria,
    required this.usuarios,
    required this.habitos,
    required this.rachaPromedio,
  });

  factory MetricaRegion.fromJson(Map<String, dynamic> json) => _$MetricaRegionFromJson(json);

  final String region;
  final String categoria;
  final int usuarios;
  final int habitos;
  final double rachaPromedio;

  Map<String, dynamic> toJson() => _$MetricaRegionToJson(this);
}

/// `GET /admin/metricas`. Todo grupo respeta k ≥ 5 usuarios.
@JsonSerializable()
class MetricasAdmin {
  const MetricasAdmin({required this.resumen, required this.porRegion});

  factory MetricasAdmin.fromJson(Map<String, dynamic> json) => _$MetricasAdminFromJson(json);

  final ResumenMetricas resumen;
  final List<MetricaRegion> porRegion;

  Map<String, dynamic> toJson() => _$MetricasAdminToJson(this);
}

@JsonSerializable()
class PeriodoIndicador {
  const PeriodoIndicador({required this.desde, required this.hasta});

  factory PeriodoIndicador.fromJson(Map<String, dynamic> json) => _$PeriodoIndicadorFromJson(json);

  @FechaConverter()
  final DateTime desde;
  @FechaConverter()
  final DateTime hasta;

  Map<String, dynamic> toJson() => _$PeriodoIndicadorToJson(this);
}

/// `GET /admin/indicadores/{I1…I6}`. La forma de cada elemento de `series` depende del indicador (documento de
/// MongoDB, sección 6); el panel (Paso 14) la interpreta.
@JsonSerializable()
class Indicador {
  const Indicador({
    required this.codigo,
    required this.titulo,
    required this.grafica,
    required this.origen,
    required this.datosSinteticos,
    required this.periodo,
    required this.series,
    required this.generadoEn,
  });

  factory Indicador.fromJson(Map<String, dynamic> json) => _$IndicadorFromJson(json);

  final String codigo;
  final String titulo;

  /// `lineas`, `boxplot`, `barras`, `barras_agrupadas` o `mapa_calor`.
  final String grafica;
  final String origen;
  final bool datosSinteticos;
  final PeriodoIndicador periodo;
  final List<Map<String, dynamic>> series;
  @InstanteConverter()
  final DateTime generadoEn;

  Map<String, dynamic> toJson() => _$IndicadorToJson(this);
}
