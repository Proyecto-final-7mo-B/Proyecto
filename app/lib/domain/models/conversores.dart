import 'package:json_annotation/json_annotation.dart';

/// `fecha` del contrato: `YYYY-MM-DD` (fecha local del usuario, sin hora). Se guarda como `DateTime` UTC a medianoche
/// para que comparar y sumar días no dependa de la zona del dispositivo.
class FechaConverter implements JsonConverter<DateTime, String> {
  const FechaConverter();

  static DateTime desdeTexto(String texto) {
    final partes = texto.split('-');
    if (partes.length != 3) {
      throw FormatException('Fecha inválida (se espera YYYY-MM-DD)', texto);
    }
    return DateTime.utc(int.parse(partes[0]), int.parse(partes[1]), int.parse(partes[2]));
  }

  static String aTexto(DateTime fecha) =>
      '${fecha.year.toString().padLeft(4, '0')}-${fecha.month.toString().padLeft(2, '0')}-'
      '${fecha.day.toString().padLeft(2, '0')}';

  @override
  DateTime fromJson(String json) => desdeTexto(json);

  @override
  String toJson(DateTime object) => aTexto(object);
}

/// Igual que [FechaConverter], pero acepta `null`.
class FechaNulaConverter implements JsonConverter<DateTime?, String?> {
  const FechaNulaConverter();

  @override
  DateTime? fromJson(String? json) => json == null ? null : FechaConverter.desdeTexto(json);

  @override
  String? toJson(DateTime? object) => object == null ? null : FechaConverter.aTexto(object);
}

/// Instante del contrato: ISO 8601 en UTC con `Z` (`2026-11-23T18:04:05Z`).
class InstanteConverter implements JsonConverter<DateTime, String> {
  const InstanteConverter();

  @override
  DateTime fromJson(String json) => DateTime.parse(json).toUtc();

  @override
  String toJson(DateTime object) => '${object.toUtc().toIso8601String().split('.').first}Z';
}

/// Igual que [InstanteConverter], pero acepta `null`.
class InstanteNuloConverter implements JsonConverter<DateTime?, String?> {
  const InstanteNuloConverter();

  @override
  DateTime? fromJson(String? json) => json == null ? null : const InstanteConverter().fromJson(json);

  @override
  String? toJson(DateTime? object) => object == null ? null : const InstanteConverter().toJson(object);
}
