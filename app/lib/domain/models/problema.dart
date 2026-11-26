/// Error de la API en formato `application/problem+json` (RFC 9457), como lo define el contrato (§3).
class Problema {
  const Problema({
    required this.type,
    required this.title,
    required this.status,
    this.detail,
    this.idPeticion,
    this.errores = const [],
    this.extras = const {},
  });

  factory Problema.fromJson(Map<String, dynamic> json) {
    const conocidos = {'type', 'title', 'status', 'detail', 'id_peticion', 'errores'};
    return Problema(
      type: json['type'] as String? ?? 'about:blank',
      title: json['title'] as String? ?? '',
      status: (json['status'] as num?)?.toInt() ?? 0,
      detail: json['detail'] as String?,
      idPeticion: json['id_peticion'] as String?,
      errores: [
        for (final e in (json['errores'] as List<dynamic>? ?? const []))
          ErrorDeCampo.fromJson(e as Map<String, dynamic>),
      ],
      extras: {
        for (final entrada in json.entries)
          if (!conocidos.contains(entrada.key)) entrada.key: entrada.value,
      },
    );
  }

  /// URL completa, p. ej. `https://kaizen.app/errores/capsula-sellada`.
  final String type;
  final String title;
  final int status;
  final String? detail;

  /// Para buscar la petición en las bitácoras del servidor (en los 500).
  final String? idPeticion;

  /// Solo en los 422 de validación.
  final List<ErrorDeCampo> errores;

  /// Campos propios de algunos tipos (p. ej., `racha` y `objetivo` en `capsula-sellada`).
  final Map<String, dynamic> extras;

  /// Sufijo del `type`: `capsula-sellada`.
  String get tipo {
    final i = type.lastIndexOf('/');
    return i < 0 ? type : type.substring(i + 1);
  }

  int? entero(String campo) => (extras[campo] as num?)?.toInt();

  Map<String, dynamic> toJson() => {
    'type': type,
    'title': title,
    'status': status,
    if (detail != null) 'detail': detail,
    if (idPeticion != null) 'id_peticion': idPeticion,
    if (errores.isNotEmpty) 'errores': [for (final e in errores) e.toJson()],
    ...extras,
  };
}

/// Un error de validación junto a su campo (`{"campo": "mensaje", "detalle": "Máximo 4096 bytes"}`).
class ErrorDeCampo {
  const ErrorDeCampo({required this.campo, required this.detalle});

  factory ErrorDeCampo.fromJson(Map<String, dynamic> json) =>
      ErrorDeCampo(campo: json['campo'] as String? ?? '', detalle: json['detalle'] as String? ?? '');

  final String campo;
  final String detalle;

  Map<String, dynamic> toJson() => {'campo': campo, 'detalle': detalle};
}
