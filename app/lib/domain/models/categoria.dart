import 'package:json_annotation/json_annotation.dart';

part 'categoria.g.dart';

/// Categoría de hábitos. `GET /categorias` no trae `activa` (solo devuelve las activas); `GET /admin/categorias` sí.
@JsonSerializable()
class Categoria {
  const Categoria({required this.id, required this.nombre, this.activa = true});

  factory Categoria.fromJson(Map<String, dynamic> json) => _$CategoriaFromJson(json);

  final String id;
  final String nombre;
  @JsonKey(defaultValue: true)
  final bool activa;

  Categoria copyWith({String? nombre, bool? activa}) =>
      Categoria(id: id, nombre: nombre ?? this.nombre, activa: activa ?? this.activa);

  Map<String, dynamic> toJson() => _$CategoriaToJson(this);

  @override
  bool operator ==(Object other) =>
      other is Categoria && other.id == id && other.nombre == nombre && other.activa == activa;

  @override
  int get hashCode => Object.hash(id, nombre, activa);
}
