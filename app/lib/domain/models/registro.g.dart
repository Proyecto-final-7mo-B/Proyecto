// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'registro.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Registro _$RegistroFromJson(Map<String, dynamic> json) => $checkedCreate(
  'Registro',
  json,
  ($checkedConvert) {
    final val = Registro(
      id: $checkedConvert('id', (v) => v as String),
      habitoId: $checkedConvert('habito_id', (v) => v as String),
      fecha: $checkedConvert(
        'fecha',
        (v) => const FechaConverter().fromJson(v as String),
      ),
      cumplido: $checkedConvert('cumplido', (v) => v as bool),
      origen: $checkedConvert(
        'origen',
        (v) => $enumDecode(_$OrigenRegistroEnumMap, v),
      ),
      valor: $checkedConvert('valor', (v) => (v as num?)?.toDouble()),
      registradoEn: $checkedConvert(
        'registrado_en',
        (v) => const InstanteNuloConverter().fromJson(v as String?),
      ),
    );
    return val;
  },
  fieldKeyMap: const {'habitoId': 'habito_id', 'registradoEn': 'registrado_en'},
);

Map<String, dynamic> _$RegistroToJson(Registro instance) => <String, dynamic>{
  'id': instance.id,
  'habito_id': instance.habitoId,
  'fecha': const FechaConverter().toJson(instance.fecha),
  'cumplido': instance.cumplido,
  'valor': instance.valor,
  'origen': _$OrigenRegistroEnumMap[instance.origen]!,
  'registrado_en': const InstanteNuloConverter().toJson(instance.registradoEn),
};

const _$OrigenRegistroEnumMap = {
  OrigenRegistro.manual: 'manual',
  OrigenRegistro.rapido: 'rapido',
  OrigenRegistro.offline: 'offline',
};

NuevoRegistro _$NuevoRegistroFromJson(Map<String, dynamic> json) =>
    $checkedCreate('NuevoRegistro', json, ($checkedConvert) {
      final val = NuevoRegistro(
        id: $checkedConvert('id', (v) => v as String),
        habitoId: $checkedConvert('habito_id', (v) => v as String),
        fecha: $checkedConvert(
          'fecha',
          (v) => const FechaConverter().fromJson(v as String),
        ),
        cumplido: $checkedConvert('cumplido', (v) => v as bool),
        origen: $checkedConvert(
          'origen',
          (v) => $enumDecode(_$OrigenRegistroEnumMap, v),
        ),
        valor: $checkedConvert('valor', (v) => (v as num?)?.toDouble()),
      );
      return val;
    }, fieldKeyMap: const {'habitoId': 'habito_id'});

Map<String, dynamic> _$NuevoRegistroToJson(NuevoRegistro instance) =>
    <String, dynamic>{
      'id': instance.id,
      'habito_id': instance.habitoId,
      'fecha': const FechaConverter().toJson(instance.fecha),
      'cumplido': instance.cumplido,
      'valor': instance.valor,
      'origen': _$OrigenRegistroEnumMap[instance.origen]!,
    };

ResultadoCheckin _$ResultadoCheckinFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ResultadoCheckin', json, ($checkedConvert) {
      final val = ResultadoCheckin(
        id: $checkedConvert('id', (v) => v as String),
        rachaActual: $checkedConvert('racha_actual', (v) => (v as num).toInt()),
      );
      return val;
    }, fieldKeyMap: const {'rachaActual': 'racha_actual'});

Map<String, dynamic> _$ResultadoCheckinToJson(ResultadoCheckin instance) =>
    <String, dynamic>{'id': instance.id, 'racha_actual': instance.rachaActual};

ElementoLote _$ElementoLoteFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ElementoLote', json, ($checkedConvert) {
      final val = ElementoLote(
        id: $checkedConvert('id', (v) => v as String),
        estado: $checkedConvert(
          'estado',
          (v) => $enumDecode(_$EstadoElementoLoteEnumMap, v),
        ),
        rachaActual: $checkedConvert(
          'racha_actual',
          (v) => (v as num?)?.toInt(),
        ),
        error: $checkedConvert(
          'error',
          (v) => _problemaDesdeJson(v as Map<String, dynamic>?),
        ),
      );
      return val;
    }, fieldKeyMap: const {'rachaActual': 'racha_actual'});

Map<String, dynamic> _$ElementoLoteToJson(ElementoLote instance) =>
    <String, dynamic>{
      'id': instance.id,
      'estado': _$EstadoElementoLoteEnumMap[instance.estado]!,
      'racha_actual': instance.rachaActual,
      'error': _problemaAJson(instance.error),
    };

const _$EstadoElementoLoteEnumMap = {
  EstadoElementoLote.aceptado: 'aceptado',
  EstadoElementoLote.rechazado: 'rechazado',
};

ResultadoLote _$ResultadoLoteFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ResultadoLote', json, ($checkedConvert) {
      final val = ResultadoLote(
        resultados: $checkedConvert(
          'resultados',
          (v) => (v as List<dynamic>)
              .map((e) => ElementoLote.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$ResultadoLoteToJson(ResultadoLote instance) =>
    <String, dynamic>{
      'resultados': instance.resultados.map((e) => e.toJson()).toList(),
    };
