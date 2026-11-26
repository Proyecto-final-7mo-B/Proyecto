// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categoria.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Categoria _$CategoriaFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Categoria', json, ($checkedConvert) {
      final val = Categoria(
        id: $checkedConvert('id', (v) => v as String),
        nombre: $checkedConvert('nombre', (v) => v as String),
        activa: $checkedConvert('activa', (v) => v as bool? ?? true),
      );
      return val;
    });

Map<String, dynamic> _$CategoriaToJson(Categoria instance) => <String, dynamic>{
  'id': instance.id,
  'nombre': instance.nombre,
  'activa': instance.activa,
};
