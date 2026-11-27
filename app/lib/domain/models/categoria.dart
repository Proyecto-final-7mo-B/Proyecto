import 'package:json_annotation/json_annotation.dart';

part 'categoria.g.dart';

/// `aumentar`: la meta es algo que se quiere hacer más (minutos, vasos…). `reducir`: la meta es un **límite**
/// (azúcar, alcohol, tabaco, pantallas) que la Escalera baja poco a poco.
@JsonEnum()
enum SentidoHabito { aumentar, reducir }

@JsonEnum()
enum PeriodoReferencia { dia, semana }

@JsonEnum()
enum Confianza { alta, media, baja }

/// Una unidad en la que se puede medir una subcategoría (`unidad_subcategoria`).
@JsonSerializable()
class UnidadPermitida {
  const UnidadPermitida({
    required this.unidad,
    required this.paso,
    required this.minimo,
    required this.maximo,
    this.factorABase,
  });

  factory UnidadPermitida.fromJson(Map<String, dynamic> json) => _$UnidadPermitidaFromJson(json);

  final String unidad;

  /// Multiplica la meta para llevarla a la unidad de la referencia (vasos → L = 0.25). `null`: esta unidad se
  /// registra pero no se compara con la referencia (km, repeticiones).
  final double? factorABase;

  /// Redondeo de la Escalera y del contador de meta en esta unidad.
  final double paso;

  /// Límites de captura de la meta (la base los hace cumplir con KZ011).
  final double minimo;
  final double maximo;

  bool get convertible => factorABase != null;

  Map<String, dynamic> toJson() => _$UnidadPermitidaToJson(this);
}

/// Rango que recomienda la evidencia para una subcategoría (`referencia_cientifica`). Los valores están en la
/// [unidadBase] y por [periodo]; para un hábito concreto se usa `EvaluadorEvidencia`.
@JsonSerializable()
class ReferenciaCientifica {
  const ReferenciaCientifica({
    required this.periodo,
    required this.unidadBase,
    required this.optimoDesde,
    required this.optimoHasta,
    required this.cita,
    required this.fuentes,
    required this.url,
    required this.confianza,
    this.maximo,
    this.pisoBajada,
    this.nota,
  });

  factory ReferenciaCientifica.fromJson(Map<String, dynamic> json) => _$ReferenciaCientificaFromJson(json);

  final PeriodoReferencia periodo;
  final String unidadBase;
  final double optimoDesde;
  final double optimoHasta;

  /// `null`: sin tope (hacer más no hace daño; arriba del óptimo solo "no hace falta más").
  final double? maximo;

  /// La Escalera no baja de aquí por bajo cumplimiento (sueño 7 h, agua 1.5 L).
  final double? pisoBajada;
  final String cita;

  /// Claves `F##` de `fuentes.md`.
  final String fuentes;
  final String url;
  final Confianza confianza;
  final String? nota;

  Map<String, dynamic> toJson() => _$ReferenciaCientificaToJson(this);
}

/// Tipo concreto de hábito dentro de una categoría (Aeróbico moderado, Hidratación, Lectura…).
///
/// Dentro de un `Habito` solo llegan `id`, `clave`, `nombre`, `icono` y `sentido`; las [unidades] y la
/// [referencia] vienen en `GET /categorias`.
@JsonSerializable()
class Subcategoria {
  const Subcategoria({
    required this.id,
    required this.clave,
    required this.nombre,
    required this.icono,
    this.sentido = SentidoHabito.aumentar,
    this.activa = true,
    this.unidades = const [],
    this.referencia,
  });

  factory Subcategoria.fromJson(Map<String, dynamic> json) => _$SubcategoriaFromJson(json);

  final String id;
  final String clave;
  final String nombre;

  /// Nombre del símbolo de Material (`directions_walk`): la app lo convierte con `KaizenIconos.porNombre`.
  final String icono;
  @JsonKey(defaultValue: SentidoHabito.aumentar)
  final SentidoHabito sentido;
  @JsonKey(defaultValue: true)
  final bool activa;
  @JsonKey(defaultValue: <UnidadPermitida>[])
  final List<UnidadPermitida> unidades;
  final ReferenciaCientifica? referencia;

  UnidadPermitida? unidad(String nombre) => unidades.where((u) => u.unidad == nombre).firstOrNull;

  Subcategoria copyWith({bool? activa}) => Subcategoria(
    id: id,
    clave: clave,
    nombre: nombre,
    icono: icono,
    sentido: sentido,
    activa: activa ?? this.activa,
    unidades: unidades,
    referencia: referencia,
  );

  /// La versión corta que viaja dentro de un hábito.
  Subcategoria get resumen => Subcategoria(id: id, clave: clave, nombre: nombre, icono: icono, sentido: sentido);

  Map<String, dynamic> toJson() => _$SubcategoriaToJson(this);

  @override
  bool operator ==(Object other) =>
      other is Subcategoria && other.id == id && other.clave == clave && other.nombre == nombre;

  @override
  int get hashCode => Object.hash(id, clave, nombre);
}

/// Categoría (Ejercicio, Salud, Educación, Bienestar, Finanzas) con su color e ícono y, en `GET /categorias`, sus
/// subcategorías. `activa` solo la manda `GET /admin/categorias`.
@JsonSerializable()
class Categoria {
  const Categoria({
    required this.id,
    required this.nombre,
    this.clave = '',
    this.color = '#1B2A5E',
    this.icono = 'category',
    this.activa = true,
    this.subcategorias = const [],
  });

  factory Categoria.fromJson(Map<String, dynamic> json) => _$CategoriaFromJson(json);

  final String id;

  /// Clave estable (`ejercicio`): para lógica y colores; el nombre puede cambiar.
  @JsonKey(defaultValue: '')
  final String clave;
  final String nombre;

  /// Hex `#RRGGBB` elegido por la evidencia de color (doc. 04).
  @JsonKey(defaultValue: '#1B2A5E')
  final String color;
  @JsonKey(defaultValue: 'category')
  final String icono;
  @JsonKey(defaultValue: true)
  final bool activa;
  @JsonKey(defaultValue: <Subcategoria>[])
  final List<Subcategoria> subcategorias;

  /// La versión corta que viaja dentro de un hábito.
  Categoria get resumen => Categoria(id: id, clave: clave, nombre: nombre, color: color, icono: icono);

  Categoria copyWith({String? nombre, bool? activa}) => Categoria(
    id: id,
    clave: clave,
    nombre: nombre ?? this.nombre,
    color: color,
    icono: icono,
    activa: activa ?? this.activa,
    subcategorias: subcategorias,
  );

  Map<String, dynamic> toJson() => _$CategoriaToJson(this);

  @override
  bool operator ==(Object other) =>
      other is Categoria && other.id == id && other.nombre == nombre && other.activa == activa;

  @override
  int get hashCode => Object.hash(id, nombre, activa);
}

/// Ayudas sobre el árbol del catálogo.
extension CatalogoCategorias on List<Categoria> {
  Iterable<Subcategoria> get todasLasSubcategorias => expand((c) => c.subcategorias);

  Subcategoria? subcategoria(String id) => todasLasSubcategorias.where((s) => s.id == id).firstOrNull;

  Categoria? categoriaDe(String subcategoriaId) =>
      where((c) => c.subcategorias.any((s) => s.id == subcategoriaId)).firstOrNull;
}
