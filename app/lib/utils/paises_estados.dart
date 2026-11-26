import 'dart:convert';

import 'package:flutter/services.dart';

/// Un país que acepta Kaizen.
class Pais {
  const Pais({required this.codigo, required this.nombre, required this.requiereEstado, this.region});

  final String codigo;
  final String nombre;

  /// Solo México pide estado (ISO 3166-2).
  final bool requiereEstado;

  /// Región fija del país (`LATAM`); `null` en México, donde la decide el estado.
  final String? region;
}

/// Un estado de México.
class EstadoMx {
  const EstadoMx({required this.codigo, required this.nombre, required this.region});

  final String codigo;
  final String nombre;
  final String region;
}

/// Países y estados de `assets/paises_estados.json`: la **misma lista que `fn_region()`** en la base. Cualquier otro
/// valor da `422 region-invalida` (KZ002).
class CatalogoRegiones {
  const CatalogoRegiones({required this.paises, required this.estadosMx});

  factory CatalogoRegiones.desdeJson(Map<String, dynamic> json) {
    return CatalogoRegiones(
      paises: [
        for (final p in json['paises'] as List<dynamic>)
          Pais(
            codigo: (p as Map<String, dynamic>)['codigo'] as String,
            nombre: p['nombre'] as String,
            requiereEstado: p['requiere_estado'] as bool,
            region: p['region'] as String?,
          ),
      ],
      estadosMx: [
        for (final e in json['estados_mx'] as List<dynamic>)
          EstadoMx(
            codigo: (e as Map<String, dynamic>)['codigo'] as String,
            nombre: e['nombre'] as String,
            region: e['region'] as String,
          ),
      ],
    );
  }

  static const String rutaAsset = 'assets/paises_estados.json';

  static Future<CatalogoRegiones> cargar([AssetBundle? bundle]) async {
    final texto = await (bundle ?? rootBundle).loadString(rutaAsset);
    return CatalogoRegiones.desdeJson(jsonDecode(texto) as Map<String, dynamic>);
  }

  final List<Pais> paises;
  final List<EstadoMx> estadosMx;

  Pais? pais(String codigo) => paises.where((p) => p.codigo == codigo).firstOrNull;

  /// Región que asignaría la base, o `null` si la combinación no es válida (igual que `fn_region`).
  String? regionDe(String pais, String? estado) {
    final p = this.pais(pais);
    if (p == null) {
      return null;
    }
    if (!p.requiereEstado) {
      return estado == null ? p.region : null;
    }
    return estadosMx.where((e) => e.codigo == estado).firstOrNull?.region;
  }
}
