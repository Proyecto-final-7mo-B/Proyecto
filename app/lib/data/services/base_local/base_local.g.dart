// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'base_local.dart';

// ignore_for_file: type=lint
class $HabitosTable extends Habitos with TableInfo<$HabitosTable, FilaHabito> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _datosMeta = const VerificationMeta('datos');
  @override
  late final GeneratedColumn<String> datos = GeneratedColumn<String>(
    'datos',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<bool> activo = GeneratedColumn<bool>(
    'activo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("activo" IN (0, 1))',
    ),
  );
  static const VerificationMeta _guardadoEnMeta = const VerificationMeta(
    'guardadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> guardadoEn = GeneratedColumn<DateTime>(
    'guardado_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, datos, activo, guardadoEn];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habitos';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilaHabito> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('datos')) {
      context.handle(
        _datosMeta,
        datos.isAcceptableOrUnknown(data['datos']!, _datosMeta),
      );
    } else if (isInserting) {
      context.missing(_datosMeta);
    }
    if (data.containsKey('activo')) {
      context.handle(
        _activoMeta,
        activo.isAcceptableOrUnknown(data['activo']!, _activoMeta),
      );
    } else if (isInserting) {
      context.missing(_activoMeta);
    }
    if (data.containsKey('guardado_en')) {
      context.handle(
        _guardadoEnMeta,
        guardadoEn.isAcceptableOrUnknown(data['guardado_en']!, _guardadoEnMeta),
      );
    } else if (isInserting) {
      context.missing(_guardadoEnMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FilaHabito map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilaHabito(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      datos: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}datos'],
      )!,
      activo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activo'],
      )!,
      guardadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}guardado_en'],
      )!,
    );
  }

  @override
  $HabitosTable createAlias(String alias) {
    return $HabitosTable(attachedDatabase, alias);
  }
}

class FilaHabito extends DataClass implements Insertable<FilaHabito> {
  final String id;
  final String datos;
  final bool activo;
  final DateTime guardadoEn;
  const FilaHabito({
    required this.id,
    required this.datos,
    required this.activo,
    required this.guardadoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['datos'] = Variable<String>(datos);
    map['activo'] = Variable<bool>(activo);
    map['guardado_en'] = Variable<DateTime>(guardadoEn);
    return map;
  }

  HabitosCompanion toCompanion(bool nullToAbsent) {
    return HabitosCompanion(
      id: Value(id),
      datos: Value(datos),
      activo: Value(activo),
      guardadoEn: Value(guardadoEn),
    );
  }

  factory FilaHabito.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilaHabito(
      id: serializer.fromJson<String>(json['id']),
      datos: serializer.fromJson<String>(json['datos']),
      activo: serializer.fromJson<bool>(json['activo']),
      guardadoEn: serializer.fromJson<DateTime>(json['guardadoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'datos': serializer.toJson<String>(datos),
      'activo': serializer.toJson<bool>(activo),
      'guardadoEn': serializer.toJson<DateTime>(guardadoEn),
    };
  }

  FilaHabito copyWith({
    String? id,
    String? datos,
    bool? activo,
    DateTime? guardadoEn,
  }) => FilaHabito(
    id: id ?? this.id,
    datos: datos ?? this.datos,
    activo: activo ?? this.activo,
    guardadoEn: guardadoEn ?? this.guardadoEn,
  );
  FilaHabito copyWithCompanion(HabitosCompanion data) {
    return FilaHabito(
      id: data.id.present ? data.id.value : this.id,
      datos: data.datos.present ? data.datos.value : this.datos,
      activo: data.activo.present ? data.activo.value : this.activo,
      guardadoEn: data.guardadoEn.present
          ? data.guardadoEn.value
          : this.guardadoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilaHabito(')
          ..write('id: $id, ')
          ..write('datos: $datos, ')
          ..write('activo: $activo, ')
          ..write('guardadoEn: $guardadoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, datos, activo, guardadoEn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilaHabito &&
          other.id == this.id &&
          other.datos == this.datos &&
          other.activo == this.activo &&
          other.guardadoEn == this.guardadoEn);
}

class HabitosCompanion extends UpdateCompanion<FilaHabito> {
  final Value<String> id;
  final Value<String> datos;
  final Value<bool> activo;
  final Value<DateTime> guardadoEn;
  final Value<int> rowid;
  const HabitosCompanion({
    this.id = const Value.absent(),
    this.datos = const Value.absent(),
    this.activo = const Value.absent(),
    this.guardadoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitosCompanion.insert({
    required String id,
    required String datos,
    required bool activo,
    required DateTime guardadoEn,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       datos = Value(datos),
       activo = Value(activo),
       guardadoEn = Value(guardadoEn);
  static Insertable<FilaHabito> custom({
    Expression<String>? id,
    Expression<String>? datos,
    Expression<bool>? activo,
    Expression<DateTime>? guardadoEn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (datos != null) 'datos': datos,
      if (activo != null) 'activo': activo,
      if (guardadoEn != null) 'guardado_en': guardadoEn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitosCompanion copyWith({
    Value<String>? id,
    Value<String>? datos,
    Value<bool>? activo,
    Value<DateTime>? guardadoEn,
    Value<int>? rowid,
  }) {
    return HabitosCompanion(
      id: id ?? this.id,
      datos: datos ?? this.datos,
      activo: activo ?? this.activo,
      guardadoEn: guardadoEn ?? this.guardadoEn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (datos.present) {
      map['datos'] = Variable<String>(datos.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    if (guardadoEn.present) {
      map['guardado_en'] = Variable<DateTime>(guardadoEn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitosCompanion(')
          ..write('id: $id, ')
          ..write('datos: $datos, ')
          ..write('activo: $activo, ')
          ..write('guardadoEn: $guardadoEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriasTable extends Categorias
    with TableInfo<$CategoriasTable, FilaCategoria> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activaMeta = const VerificationMeta('activa');
  @override
  late final GeneratedColumn<bool> activa = GeneratedColumn<bool>(
    'activa',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("activa" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _datosMeta = const VerificationMeta('datos');
  @override
  late final GeneratedColumn<String> datos = GeneratedColumn<String>(
    'datos',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ordenMeta = const VerificationMeta('orden');
  @override
  late final GeneratedColumn<int> orden = GeneratedColumn<int>(
    'orden',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, nombre, activa, datos, orden];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categorias';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilaCategoria> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('activa')) {
      context.handle(
        _activaMeta,
        activa.isAcceptableOrUnknown(data['activa']!, _activaMeta),
      );
    }
    if (data.containsKey('datos')) {
      context.handle(
        _datosMeta,
        datos.isAcceptableOrUnknown(data['datos']!, _datosMeta),
      );
    } else if (isInserting) {
      context.missing(_datosMeta);
    }
    if (data.containsKey('orden')) {
      context.handle(
        _ordenMeta,
        orden.isAcceptableOrUnknown(data['orden']!, _ordenMeta),
      );
    } else if (isInserting) {
      context.missing(_ordenMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FilaCategoria map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilaCategoria(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      activa: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activa'],
      )!,
      datos: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}datos'],
      )!,
      orden: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}orden'],
      )!,
    );
  }

  @override
  $CategoriasTable createAlias(String alias) {
    return $CategoriasTable(attachedDatabase, alias);
  }
}

class FilaCategoria extends DataClass implements Insertable<FilaCategoria> {
  final String id;
  final String nombre;
  final bool activa;

  /// El JSON de la categoría completa, como lo manda la API.
  final String datos;

  /// Posición en el catálogo (el orden de la API: Ejercicio, Salud, Educación, Bienestar, Finanzas).
  final int orden;
  const FilaCategoria({
    required this.id,
    required this.nombre,
    required this.activa,
    required this.datos,
    required this.orden,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nombre'] = Variable<String>(nombre);
    map['activa'] = Variable<bool>(activa);
    map['datos'] = Variable<String>(datos);
    map['orden'] = Variable<int>(orden);
    return map;
  }

  CategoriasCompanion toCompanion(bool nullToAbsent) {
    return CategoriasCompanion(
      id: Value(id),
      nombre: Value(nombre),
      activa: Value(activa),
      datos: Value(datos),
      orden: Value(orden),
    );
  }

  factory FilaCategoria.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilaCategoria(
      id: serializer.fromJson<String>(json['id']),
      nombre: serializer.fromJson<String>(json['nombre']),
      activa: serializer.fromJson<bool>(json['activa']),
      datos: serializer.fromJson<String>(json['datos']),
      orden: serializer.fromJson<int>(json['orden']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nombre': serializer.toJson<String>(nombre),
      'activa': serializer.toJson<bool>(activa),
      'datos': serializer.toJson<String>(datos),
      'orden': serializer.toJson<int>(orden),
    };
  }

  FilaCategoria copyWith({
    String? id,
    String? nombre,
    bool? activa,
    String? datos,
    int? orden,
  }) => FilaCategoria(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    activa: activa ?? this.activa,
    datos: datos ?? this.datos,
    orden: orden ?? this.orden,
  );
  FilaCategoria copyWithCompanion(CategoriasCompanion data) {
    return FilaCategoria(
      id: data.id.present ? data.id.value : this.id,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      activa: data.activa.present ? data.activa.value : this.activa,
      datos: data.datos.present ? data.datos.value : this.datos,
      orden: data.orden.present ? data.orden.value : this.orden,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilaCategoria(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('activa: $activa, ')
          ..write('datos: $datos, ')
          ..write('orden: $orden')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nombre, activa, datos, orden);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilaCategoria &&
          other.id == this.id &&
          other.nombre == this.nombre &&
          other.activa == this.activa &&
          other.datos == this.datos &&
          other.orden == this.orden);
}

class CategoriasCompanion extends UpdateCompanion<FilaCategoria> {
  final Value<String> id;
  final Value<String> nombre;
  final Value<bool> activa;
  final Value<String> datos;
  final Value<int> orden;
  final Value<int> rowid;
  const CategoriasCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
    this.activa = const Value.absent(),
    this.datos = const Value.absent(),
    this.orden = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriasCompanion.insert({
    required String id,
    required String nombre,
    this.activa = const Value.absent(),
    required String datos,
    required int orden,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nombre = Value(nombre),
       datos = Value(datos),
       orden = Value(orden);
  static Insertable<FilaCategoria> custom({
    Expression<String>? id,
    Expression<String>? nombre,
    Expression<bool>? activa,
    Expression<String>? datos,
    Expression<int>? orden,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
      if (activa != null) 'activa': activa,
      if (datos != null) 'datos': datos,
      if (orden != null) 'orden': orden,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriasCompanion copyWith({
    Value<String>? id,
    Value<String>? nombre,
    Value<bool>? activa,
    Value<String>? datos,
    Value<int>? orden,
    Value<int>? rowid,
  }) {
    return CategoriasCompanion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      activa: activa ?? this.activa,
      datos: datos ?? this.datos,
      orden: orden ?? this.orden,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (activa.present) {
      map['activa'] = Variable<bool>(activa.value);
    }
    if (datos.present) {
      map['datos'] = Variable<String>(datos.value);
    }
    if (orden.present) {
      map['orden'] = Variable<int>(orden.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriasCompanion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('activa: $activa, ')
          ..write('datos: $datos, ')
          ..write('orden: $orden, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RegistrosTable extends Registros
    with TableInfo<$RegistrosTable, FilaRegistro> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RegistrosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _habitoIdMeta = const VerificationMeta(
    'habitoId',
  );
  @override
  late final GeneratedColumn<String> habitoId = GeneratedColumn<String>(
    'habito_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<String> fecha = GeneratedColumn<String>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cumplidoMeta = const VerificationMeta(
    'cumplido',
  );
  @override
  late final GeneratedColumn<bool> cumplido = GeneratedColumn<bool>(
    'cumplido',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("cumplido" IN (0, 1))',
    ),
  );
  static const VerificationMeta _valorMeta = const VerificationMeta('valor');
  @override
  late final GeneratedColumn<double> valor = GeneratedColumn<double>(
    'valor',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _origenMeta = const VerificationMeta('origen');
  @override
  late final GeneratedColumn<String> origen = GeneratedColumn<String>(
    'origen',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _registradoEnMeta = const VerificationMeta(
    'registradoEn',
  );
  @override
  late final GeneratedColumn<DateTime> registradoEn = GeneratedColumn<DateTime>(
    'registrado_en',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    habitoId,
    fecha,
    cumplido,
    valor,
    origen,
    registradoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'registros';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilaRegistro> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('habito_id')) {
      context.handle(
        _habitoIdMeta,
        habitoId.isAcceptableOrUnknown(data['habito_id']!, _habitoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_habitoIdMeta);
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    if (data.containsKey('cumplido')) {
      context.handle(
        _cumplidoMeta,
        cumplido.isAcceptableOrUnknown(data['cumplido']!, _cumplidoMeta),
      );
    } else if (isInserting) {
      context.missing(_cumplidoMeta);
    }
    if (data.containsKey('valor')) {
      context.handle(
        _valorMeta,
        valor.isAcceptableOrUnknown(data['valor']!, _valorMeta),
      );
    }
    if (data.containsKey('origen')) {
      context.handle(
        _origenMeta,
        origen.isAcceptableOrUnknown(data['origen']!, _origenMeta),
      );
    } else if (isInserting) {
      context.missing(_origenMeta);
    }
    if (data.containsKey('registrado_en')) {
      context.handle(
        _registradoEnMeta,
        registradoEn.isAcceptableOrUnknown(
          data['registrado_en']!,
          _registradoEnMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {habitoId, fecha},
  ];
  @override
  FilaRegistro map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilaRegistro(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      habitoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}habito_id'],
      )!,
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fecha'],
      )!,
      cumplido: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}cumplido'],
      )!,
      valor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}valor'],
      ),
      origen: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origen'],
      )!,
      registradoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}registrado_en'],
      ),
    );
  }

  @override
  $RegistrosTable createAlias(String alias) {
    return $RegistrosTable(attachedDatabase, alias);
  }
}

class FilaRegistro extends DataClass implements Insertable<FilaRegistro> {
  final String id;
  final String habitoId;
  final String fecha;
  final bool cumplido;
  final double? valor;
  final String origen;
  final DateTime? registradoEn;
  const FilaRegistro({
    required this.id,
    required this.habitoId,
    required this.fecha,
    required this.cumplido,
    this.valor,
    required this.origen,
    this.registradoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['habito_id'] = Variable<String>(habitoId);
    map['fecha'] = Variable<String>(fecha);
    map['cumplido'] = Variable<bool>(cumplido);
    if (!nullToAbsent || valor != null) {
      map['valor'] = Variable<double>(valor);
    }
    map['origen'] = Variable<String>(origen);
    if (!nullToAbsent || registradoEn != null) {
      map['registrado_en'] = Variable<DateTime>(registradoEn);
    }
    return map;
  }

  RegistrosCompanion toCompanion(bool nullToAbsent) {
    return RegistrosCompanion(
      id: Value(id),
      habitoId: Value(habitoId),
      fecha: Value(fecha),
      cumplido: Value(cumplido),
      valor: valor == null && nullToAbsent
          ? const Value.absent()
          : Value(valor),
      origen: Value(origen),
      registradoEn: registradoEn == null && nullToAbsent
          ? const Value.absent()
          : Value(registradoEn),
    );
  }

  factory FilaRegistro.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilaRegistro(
      id: serializer.fromJson<String>(json['id']),
      habitoId: serializer.fromJson<String>(json['habitoId']),
      fecha: serializer.fromJson<String>(json['fecha']),
      cumplido: serializer.fromJson<bool>(json['cumplido']),
      valor: serializer.fromJson<double?>(json['valor']),
      origen: serializer.fromJson<String>(json['origen']),
      registradoEn: serializer.fromJson<DateTime?>(json['registradoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'habitoId': serializer.toJson<String>(habitoId),
      'fecha': serializer.toJson<String>(fecha),
      'cumplido': serializer.toJson<bool>(cumplido),
      'valor': serializer.toJson<double?>(valor),
      'origen': serializer.toJson<String>(origen),
      'registradoEn': serializer.toJson<DateTime?>(registradoEn),
    };
  }

  FilaRegistro copyWith({
    String? id,
    String? habitoId,
    String? fecha,
    bool? cumplido,
    Value<double?> valor = const Value.absent(),
    String? origen,
    Value<DateTime?> registradoEn = const Value.absent(),
  }) => FilaRegistro(
    id: id ?? this.id,
    habitoId: habitoId ?? this.habitoId,
    fecha: fecha ?? this.fecha,
    cumplido: cumplido ?? this.cumplido,
    valor: valor.present ? valor.value : this.valor,
    origen: origen ?? this.origen,
    registradoEn: registradoEn.present ? registradoEn.value : this.registradoEn,
  );
  FilaRegistro copyWithCompanion(RegistrosCompanion data) {
    return FilaRegistro(
      id: data.id.present ? data.id.value : this.id,
      habitoId: data.habitoId.present ? data.habitoId.value : this.habitoId,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      cumplido: data.cumplido.present ? data.cumplido.value : this.cumplido,
      valor: data.valor.present ? data.valor.value : this.valor,
      origen: data.origen.present ? data.origen.value : this.origen,
      registradoEn: data.registradoEn.present
          ? data.registradoEn.value
          : this.registradoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilaRegistro(')
          ..write('id: $id, ')
          ..write('habitoId: $habitoId, ')
          ..write('fecha: $fecha, ')
          ..write('cumplido: $cumplido, ')
          ..write('valor: $valor, ')
          ..write('origen: $origen, ')
          ..write('registradoEn: $registradoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, habitoId, fecha, cumplido, valor, origen, registradoEn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilaRegistro &&
          other.id == this.id &&
          other.habitoId == this.habitoId &&
          other.fecha == this.fecha &&
          other.cumplido == this.cumplido &&
          other.valor == this.valor &&
          other.origen == this.origen &&
          other.registradoEn == this.registradoEn);
}

class RegistrosCompanion extends UpdateCompanion<FilaRegistro> {
  final Value<String> id;
  final Value<String> habitoId;
  final Value<String> fecha;
  final Value<bool> cumplido;
  final Value<double?> valor;
  final Value<String> origen;
  final Value<DateTime?> registradoEn;
  final Value<int> rowid;
  const RegistrosCompanion({
    this.id = const Value.absent(),
    this.habitoId = const Value.absent(),
    this.fecha = const Value.absent(),
    this.cumplido = const Value.absent(),
    this.valor = const Value.absent(),
    this.origen = const Value.absent(),
    this.registradoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RegistrosCompanion.insert({
    required String id,
    required String habitoId,
    required String fecha,
    required bool cumplido,
    this.valor = const Value.absent(),
    required String origen,
    this.registradoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       habitoId = Value(habitoId),
       fecha = Value(fecha),
       cumplido = Value(cumplido),
       origen = Value(origen);
  static Insertable<FilaRegistro> custom({
    Expression<String>? id,
    Expression<String>? habitoId,
    Expression<String>? fecha,
    Expression<bool>? cumplido,
    Expression<double>? valor,
    Expression<String>? origen,
    Expression<DateTime>? registradoEn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (habitoId != null) 'habito_id': habitoId,
      if (fecha != null) 'fecha': fecha,
      if (cumplido != null) 'cumplido': cumplido,
      if (valor != null) 'valor': valor,
      if (origen != null) 'origen': origen,
      if (registradoEn != null) 'registrado_en': registradoEn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RegistrosCompanion copyWith({
    Value<String>? id,
    Value<String>? habitoId,
    Value<String>? fecha,
    Value<bool>? cumplido,
    Value<double?>? valor,
    Value<String>? origen,
    Value<DateTime?>? registradoEn,
    Value<int>? rowid,
  }) {
    return RegistrosCompanion(
      id: id ?? this.id,
      habitoId: habitoId ?? this.habitoId,
      fecha: fecha ?? this.fecha,
      cumplido: cumplido ?? this.cumplido,
      valor: valor ?? this.valor,
      origen: origen ?? this.origen,
      registradoEn: registradoEn ?? this.registradoEn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (habitoId.present) {
      map['habito_id'] = Variable<String>(habitoId.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<String>(fecha.value);
    }
    if (cumplido.present) {
      map['cumplido'] = Variable<bool>(cumplido.value);
    }
    if (valor.present) {
      map['valor'] = Variable<double>(valor.value);
    }
    if (origen.present) {
      map['origen'] = Variable<String>(origen.value);
    }
    if (registradoEn.present) {
      map['registrado_en'] = Variable<DateTime>(registradoEn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RegistrosCompanion(')
          ..write('id: $id, ')
          ..write('habitoId: $habitoId, ')
          ..write('fecha: $fecha, ')
          ..write('cumplido: $cumplido, ')
          ..write('valor: $valor, ')
          ..write('origen: $origen, ')
          ..write('registradoEn: $registradoEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ColaPendientesTable extends ColaPendientes
    with TableInfo<$ColaPendientesTable, FilaPendiente> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ColaPendientesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('registro'),
  );
  static const VerificationMeta _habitoIdMeta = const VerificationMeta(
    'habitoId',
  );
  @override
  late final GeneratedColumn<String> habitoId = GeneratedColumn<String>(
    'habito_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<String> fecha = GeneratedColumn<String>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cumplidoMeta = const VerificationMeta(
    'cumplido',
  );
  @override
  late final GeneratedColumn<bool> cumplido = GeneratedColumn<bool>(
    'cumplido',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("cumplido" IN (0, 1))',
    ),
  );
  static const VerificationMeta _valorMeta = const VerificationMeta('valor');
  @override
  late final GeneratedColumn<double> valor = GeneratedColumn<double>(
    'valor',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _creadoEnMeta = const VerificationMeta(
    'creadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> creadoEn = GeneratedColumn<DateTime>(
    'creado_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intentosMeta = const VerificationMeta(
    'intentos',
  );
  @override
  late final GeneratedColumn<int> intentos = GeneratedColumn<int>(
    'intentos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ultimoErrorMeta = const VerificationMeta(
    'ultimoError',
  );
  @override
  late final GeneratedColumn<String> ultimoError = GeneratedColumn<String>(
    'ultimo_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rechazadoMeta = const VerificationMeta(
    'rechazado',
  );
  @override
  late final GeneratedColumn<bool> rechazado = GeneratedColumn<bool>(
    'rechazado',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("rechazado" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tipo,
    habitoId,
    fecha,
    cumplido,
    valor,
    creadoEn,
    intentos,
    ultimoError,
    rechazado,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cola_pendientes';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilaPendiente> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    }
    if (data.containsKey('habito_id')) {
      context.handle(
        _habitoIdMeta,
        habitoId.isAcceptableOrUnknown(data['habito_id']!, _habitoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_habitoIdMeta);
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    if (data.containsKey('cumplido')) {
      context.handle(
        _cumplidoMeta,
        cumplido.isAcceptableOrUnknown(data['cumplido']!, _cumplidoMeta),
      );
    } else if (isInserting) {
      context.missing(_cumplidoMeta);
    }
    if (data.containsKey('valor')) {
      context.handle(
        _valorMeta,
        valor.isAcceptableOrUnknown(data['valor']!, _valorMeta),
      );
    }
    if (data.containsKey('creado_en')) {
      context.handle(
        _creadoEnMeta,
        creadoEn.isAcceptableOrUnknown(data['creado_en']!, _creadoEnMeta),
      );
    } else if (isInserting) {
      context.missing(_creadoEnMeta);
    }
    if (data.containsKey('intentos')) {
      context.handle(
        _intentosMeta,
        intentos.isAcceptableOrUnknown(data['intentos']!, _intentosMeta),
      );
    }
    if (data.containsKey('ultimo_error')) {
      context.handle(
        _ultimoErrorMeta,
        ultimoError.isAcceptableOrUnknown(
          data['ultimo_error']!,
          _ultimoErrorMeta,
        ),
      );
    }
    if (data.containsKey('rechazado')) {
      context.handle(
        _rechazadoMeta,
        rechazado.isAcceptableOrUnknown(data['rechazado']!, _rechazadoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {tipo, habitoId, fecha},
  ];
  @override
  FilaPendiente map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilaPendiente(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      habitoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}habito_id'],
      )!,
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fecha'],
      )!,
      cumplido: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}cumplido'],
      )!,
      valor: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}valor'],
      ),
      creadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}creado_en'],
      )!,
      intentos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}intentos'],
      )!,
      ultimoError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ultimo_error'],
      ),
      rechazado: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}rechazado'],
      )!,
    );
  }

  @override
  $ColaPendientesTable createAlias(String alias) {
    return $ColaPendientesTable(attachedDatabase, alias);
  }
}

class FilaPendiente extends DataClass implements Insertable<FilaPendiente> {
  final String id;
  final String tipo;
  final String habitoId;
  final String fecha;
  final bool cumplido;
  final double? valor;
  final DateTime creadoEn;
  final int intentos;
  final String? ultimoError;
  final bool rechazado;
  const FilaPendiente({
    required this.id,
    required this.tipo,
    required this.habitoId,
    required this.fecha,
    required this.cumplido,
    this.valor,
    required this.creadoEn,
    required this.intentos,
    this.ultimoError,
    required this.rechazado,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['tipo'] = Variable<String>(tipo);
    map['habito_id'] = Variable<String>(habitoId);
    map['fecha'] = Variable<String>(fecha);
    map['cumplido'] = Variable<bool>(cumplido);
    if (!nullToAbsent || valor != null) {
      map['valor'] = Variable<double>(valor);
    }
    map['creado_en'] = Variable<DateTime>(creadoEn);
    map['intentos'] = Variable<int>(intentos);
    if (!nullToAbsent || ultimoError != null) {
      map['ultimo_error'] = Variable<String>(ultimoError);
    }
    map['rechazado'] = Variable<bool>(rechazado);
    return map;
  }

  ColaPendientesCompanion toCompanion(bool nullToAbsent) {
    return ColaPendientesCompanion(
      id: Value(id),
      tipo: Value(tipo),
      habitoId: Value(habitoId),
      fecha: Value(fecha),
      cumplido: Value(cumplido),
      valor: valor == null && nullToAbsent
          ? const Value.absent()
          : Value(valor),
      creadoEn: Value(creadoEn),
      intentos: Value(intentos),
      ultimoError: ultimoError == null && nullToAbsent
          ? const Value.absent()
          : Value(ultimoError),
      rechazado: Value(rechazado),
    );
  }

  factory FilaPendiente.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilaPendiente(
      id: serializer.fromJson<String>(json['id']),
      tipo: serializer.fromJson<String>(json['tipo']),
      habitoId: serializer.fromJson<String>(json['habitoId']),
      fecha: serializer.fromJson<String>(json['fecha']),
      cumplido: serializer.fromJson<bool>(json['cumplido']),
      valor: serializer.fromJson<double?>(json['valor']),
      creadoEn: serializer.fromJson<DateTime>(json['creadoEn']),
      intentos: serializer.fromJson<int>(json['intentos']),
      ultimoError: serializer.fromJson<String?>(json['ultimoError']),
      rechazado: serializer.fromJson<bool>(json['rechazado']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tipo': serializer.toJson<String>(tipo),
      'habitoId': serializer.toJson<String>(habitoId),
      'fecha': serializer.toJson<String>(fecha),
      'cumplido': serializer.toJson<bool>(cumplido),
      'valor': serializer.toJson<double?>(valor),
      'creadoEn': serializer.toJson<DateTime>(creadoEn),
      'intentos': serializer.toJson<int>(intentos),
      'ultimoError': serializer.toJson<String?>(ultimoError),
      'rechazado': serializer.toJson<bool>(rechazado),
    };
  }

  FilaPendiente copyWith({
    String? id,
    String? tipo,
    String? habitoId,
    String? fecha,
    bool? cumplido,
    Value<double?> valor = const Value.absent(),
    DateTime? creadoEn,
    int? intentos,
    Value<String?> ultimoError = const Value.absent(),
    bool? rechazado,
  }) => FilaPendiente(
    id: id ?? this.id,
    tipo: tipo ?? this.tipo,
    habitoId: habitoId ?? this.habitoId,
    fecha: fecha ?? this.fecha,
    cumplido: cumplido ?? this.cumplido,
    valor: valor.present ? valor.value : this.valor,
    creadoEn: creadoEn ?? this.creadoEn,
    intentos: intentos ?? this.intentos,
    ultimoError: ultimoError.present ? ultimoError.value : this.ultimoError,
    rechazado: rechazado ?? this.rechazado,
  );
  FilaPendiente copyWithCompanion(ColaPendientesCompanion data) {
    return FilaPendiente(
      id: data.id.present ? data.id.value : this.id,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      habitoId: data.habitoId.present ? data.habitoId.value : this.habitoId,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      cumplido: data.cumplido.present ? data.cumplido.value : this.cumplido,
      valor: data.valor.present ? data.valor.value : this.valor,
      creadoEn: data.creadoEn.present ? data.creadoEn.value : this.creadoEn,
      intentos: data.intentos.present ? data.intentos.value : this.intentos,
      ultimoError: data.ultimoError.present
          ? data.ultimoError.value
          : this.ultimoError,
      rechazado: data.rechazado.present ? data.rechazado.value : this.rechazado,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilaPendiente(')
          ..write('id: $id, ')
          ..write('tipo: $tipo, ')
          ..write('habitoId: $habitoId, ')
          ..write('fecha: $fecha, ')
          ..write('cumplido: $cumplido, ')
          ..write('valor: $valor, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('intentos: $intentos, ')
          ..write('ultimoError: $ultimoError, ')
          ..write('rechazado: $rechazado')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    tipo,
    habitoId,
    fecha,
    cumplido,
    valor,
    creadoEn,
    intentos,
    ultimoError,
    rechazado,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilaPendiente &&
          other.id == this.id &&
          other.tipo == this.tipo &&
          other.habitoId == this.habitoId &&
          other.fecha == this.fecha &&
          other.cumplido == this.cumplido &&
          other.valor == this.valor &&
          other.creadoEn == this.creadoEn &&
          other.intentos == this.intentos &&
          other.ultimoError == this.ultimoError &&
          other.rechazado == this.rechazado);
}

class ColaPendientesCompanion extends UpdateCompanion<FilaPendiente> {
  final Value<String> id;
  final Value<String> tipo;
  final Value<String> habitoId;
  final Value<String> fecha;
  final Value<bool> cumplido;
  final Value<double?> valor;
  final Value<DateTime> creadoEn;
  final Value<int> intentos;
  final Value<String?> ultimoError;
  final Value<bool> rechazado;
  final Value<int> rowid;
  const ColaPendientesCompanion({
    this.id = const Value.absent(),
    this.tipo = const Value.absent(),
    this.habitoId = const Value.absent(),
    this.fecha = const Value.absent(),
    this.cumplido = const Value.absent(),
    this.valor = const Value.absent(),
    this.creadoEn = const Value.absent(),
    this.intentos = const Value.absent(),
    this.ultimoError = const Value.absent(),
    this.rechazado = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ColaPendientesCompanion.insert({
    required String id,
    this.tipo = const Value.absent(),
    required String habitoId,
    required String fecha,
    required bool cumplido,
    this.valor = const Value.absent(),
    required DateTime creadoEn,
    this.intentos = const Value.absent(),
    this.ultimoError = const Value.absent(),
    this.rechazado = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       habitoId = Value(habitoId),
       fecha = Value(fecha),
       cumplido = Value(cumplido),
       creadoEn = Value(creadoEn);
  static Insertable<FilaPendiente> custom({
    Expression<String>? id,
    Expression<String>? tipo,
    Expression<String>? habitoId,
    Expression<String>? fecha,
    Expression<bool>? cumplido,
    Expression<double>? valor,
    Expression<DateTime>? creadoEn,
    Expression<int>? intentos,
    Expression<String>? ultimoError,
    Expression<bool>? rechazado,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tipo != null) 'tipo': tipo,
      if (habitoId != null) 'habito_id': habitoId,
      if (fecha != null) 'fecha': fecha,
      if (cumplido != null) 'cumplido': cumplido,
      if (valor != null) 'valor': valor,
      if (creadoEn != null) 'creado_en': creadoEn,
      if (intentos != null) 'intentos': intentos,
      if (ultimoError != null) 'ultimo_error': ultimoError,
      if (rechazado != null) 'rechazado': rechazado,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ColaPendientesCompanion copyWith({
    Value<String>? id,
    Value<String>? tipo,
    Value<String>? habitoId,
    Value<String>? fecha,
    Value<bool>? cumplido,
    Value<double?>? valor,
    Value<DateTime>? creadoEn,
    Value<int>? intentos,
    Value<String?>? ultimoError,
    Value<bool>? rechazado,
    Value<int>? rowid,
  }) {
    return ColaPendientesCompanion(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      habitoId: habitoId ?? this.habitoId,
      fecha: fecha ?? this.fecha,
      cumplido: cumplido ?? this.cumplido,
      valor: valor ?? this.valor,
      creadoEn: creadoEn ?? this.creadoEn,
      intentos: intentos ?? this.intentos,
      ultimoError: ultimoError ?? this.ultimoError,
      rechazado: rechazado ?? this.rechazado,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (habitoId.present) {
      map['habito_id'] = Variable<String>(habitoId.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<String>(fecha.value);
    }
    if (cumplido.present) {
      map['cumplido'] = Variable<bool>(cumplido.value);
    }
    if (valor.present) {
      map['valor'] = Variable<double>(valor.value);
    }
    if (creadoEn.present) {
      map['creado_en'] = Variable<DateTime>(creadoEn.value);
    }
    if (intentos.present) {
      map['intentos'] = Variable<int>(intentos.value);
    }
    if (ultimoError.present) {
      map['ultimo_error'] = Variable<String>(ultimoError.value);
    }
    if (rechazado.present) {
      map['rechazado'] = Variable<bool>(rechazado.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ColaPendientesCompanion(')
          ..write('id: $id, ')
          ..write('tipo: $tipo, ')
          ..write('habitoId: $habitoId, ')
          ..write('fecha: $fecha, ')
          ..write('cumplido: $cumplido, ')
          ..write('valor: $valor, ')
          ..write('creadoEn: $creadoEn, ')
          ..write('intentos: $intentos, ')
          ..write('ultimoError: $ultimoError, ')
          ..write('rechazado: $rechazado, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SenalesTable extends Senales with TableInfo<$SenalesTable, FilaSenal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SenalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<String> fecha = GeneratedColumn<String>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _animoMeta = const VerificationMeta('animo');
  @override
  late final GeneratedColumn<int> animo = GeneratedColumn<int>(
    'animo',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _energiaMeta = const VerificationMeta(
    'energia',
  );
  @override
  late final GeneratedColumn<int> energia = GeneratedColumn<int>(
    'energia',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [fecha, animo, energia];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'senales';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilaSenal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    if (data.containsKey('animo')) {
      context.handle(
        _animoMeta,
        animo.isAcceptableOrUnknown(data['animo']!, _animoMeta),
      );
    } else if (isInserting) {
      context.missing(_animoMeta);
    }
    if (data.containsKey('energia')) {
      context.handle(
        _energiaMeta,
        energia.isAcceptableOrUnknown(data['energia']!, _energiaMeta),
      );
    } else if (isInserting) {
      context.missing(_energiaMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {fecha};
  @override
  FilaSenal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilaSenal(
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fecha'],
      )!,
      animo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}animo'],
      )!,
      energia: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}energia'],
      )!,
    );
  }

  @override
  $SenalesTable createAlias(String alias) {
    return $SenalesTable(attachedDatabase, alias);
  }
}

class FilaSenal extends DataClass implements Insertable<FilaSenal> {
  final String fecha;
  final int animo;
  final int energia;
  const FilaSenal({
    required this.fecha,
    required this.animo,
    required this.energia,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['fecha'] = Variable<String>(fecha);
    map['animo'] = Variable<int>(animo);
    map['energia'] = Variable<int>(energia);
    return map;
  }

  SenalesCompanion toCompanion(bool nullToAbsent) {
    return SenalesCompanion(
      fecha: Value(fecha),
      animo: Value(animo),
      energia: Value(energia),
    );
  }

  factory FilaSenal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilaSenal(
      fecha: serializer.fromJson<String>(json['fecha']),
      animo: serializer.fromJson<int>(json['animo']),
      energia: serializer.fromJson<int>(json['energia']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fecha': serializer.toJson<String>(fecha),
      'animo': serializer.toJson<int>(animo),
      'energia': serializer.toJson<int>(energia),
    };
  }

  FilaSenal copyWith({String? fecha, int? animo, int? energia}) => FilaSenal(
    fecha: fecha ?? this.fecha,
    animo: animo ?? this.animo,
    energia: energia ?? this.energia,
  );
  FilaSenal copyWithCompanion(SenalesCompanion data) {
    return FilaSenal(
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      animo: data.animo.present ? data.animo.value : this.animo,
      energia: data.energia.present ? data.energia.value : this.energia,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilaSenal(')
          ..write('fecha: $fecha, ')
          ..write('animo: $animo, ')
          ..write('energia: $energia')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(fecha, animo, energia);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilaSenal &&
          other.fecha == this.fecha &&
          other.animo == this.animo &&
          other.energia == this.energia);
}

class SenalesCompanion extends UpdateCompanion<FilaSenal> {
  final Value<String> fecha;
  final Value<int> animo;
  final Value<int> energia;
  final Value<int> rowid;
  const SenalesCompanion({
    this.fecha = const Value.absent(),
    this.animo = const Value.absent(),
    this.energia = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SenalesCompanion.insert({
    required String fecha,
    required int animo,
    required int energia,
    this.rowid = const Value.absent(),
  }) : fecha = Value(fecha),
       animo = Value(animo),
       energia = Value(energia);
  static Insertable<FilaSenal> custom({
    Expression<String>? fecha,
    Expression<int>? animo,
    Expression<int>? energia,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fecha != null) 'fecha': fecha,
      if (animo != null) 'animo': animo,
      if (energia != null) 'energia': energia,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SenalesCompanion copyWith({
    Value<String>? fecha,
    Value<int>? animo,
    Value<int>? energia,
    Value<int>? rowid,
  }) {
    return SenalesCompanion(
      fecha: fecha ?? this.fecha,
      animo: animo ?? this.animo,
      energia: energia ?? this.energia,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fecha.present) {
      map['fecha'] = Variable<String>(fecha.value);
    }
    if (animo.present) {
      map['animo'] = Variable<int>(animo.value);
    }
    if (energia.present) {
      map['energia'] = Variable<int>(energia.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SenalesCompanion(')
          ..write('fecha: $fecha, ')
          ..write('animo: $animo, ')
          ..write('energia: $energia, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SugerenciasTable extends Sugerencias
    with TableInfo<$SugerenciasTable, FilaSugerencia> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SugerenciasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _datosMeta = const VerificationMeta('datos');
  @override
  late final GeneratedColumn<String> datos = GeneratedColumn<String>(
    'datos',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, datos];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sugerencias';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilaSugerencia> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('datos')) {
      context.handle(
        _datosMeta,
        datos.isAcceptableOrUnknown(data['datos']!, _datosMeta),
      );
    } else if (isInserting) {
      context.missing(_datosMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FilaSugerencia map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilaSugerencia(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      datos: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}datos'],
      )!,
    );
  }

  @override
  $SugerenciasTable createAlias(String alias) {
    return $SugerenciasTable(attachedDatabase, alias);
  }
}

class FilaSugerencia extends DataClass implements Insertable<FilaSugerencia> {
  final String id;
  final String datos;
  const FilaSugerencia({required this.id, required this.datos});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['datos'] = Variable<String>(datos);
    return map;
  }

  SugerenciasCompanion toCompanion(bool nullToAbsent) {
    return SugerenciasCompanion(id: Value(id), datos: Value(datos));
  }

  factory FilaSugerencia.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilaSugerencia(
      id: serializer.fromJson<String>(json['id']),
      datos: serializer.fromJson<String>(json['datos']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'datos': serializer.toJson<String>(datos),
    };
  }

  FilaSugerencia copyWith({String? id, String? datos}) =>
      FilaSugerencia(id: id ?? this.id, datos: datos ?? this.datos);
  FilaSugerencia copyWithCompanion(SugerenciasCompanion data) {
    return FilaSugerencia(
      id: data.id.present ? data.id.value : this.id,
      datos: data.datos.present ? data.datos.value : this.datos,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilaSugerencia(')
          ..write('id: $id, ')
          ..write('datos: $datos')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, datos);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilaSugerencia &&
          other.id == this.id &&
          other.datos == this.datos);
}

class SugerenciasCompanion extends UpdateCompanion<FilaSugerencia> {
  final Value<String> id;
  final Value<String> datos;
  final Value<int> rowid;
  const SugerenciasCompanion({
    this.id = const Value.absent(),
    this.datos = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SugerenciasCompanion.insert({
    required String id,
    required String datos,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       datos = Value(datos);
  static Insertable<FilaSugerencia> custom({
    Expression<String>? id,
    Expression<String>? datos,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (datos != null) 'datos': datos,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SugerenciasCompanion copyWith({
    Value<String>? id,
    Value<String>? datos,
    Value<int>? rowid,
  }) {
    return SugerenciasCompanion(
      id: id ?? this.id,
      datos: datos ?? this.datos,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (datos.present) {
      map['datos'] = Variable<String>(datos.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SugerenciasCompanion(')
          ..write('id: $id, ')
          ..write('datos: $datos, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CapsulasTable extends Capsulas
    with TableInfo<$CapsulasTable, FilaCapsula> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CapsulasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _habitoIdMeta = const VerificationMeta(
    'habitoId',
  );
  @override
  late final GeneratedColumn<String> habitoId = GeneratedColumn<String>(
    'habito_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rachaObjetivoMeta = const VerificationMeta(
    'rachaObjetivo',
  );
  @override
  late final GeneratedColumn<int> rachaObjetivo = GeneratedColumn<int>(
    'racha_objetivo',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _estadoMeta = const VerificationMeta('estado');
  @override
  late final GeneratedColumn<String> estado = GeneratedColumn<String>(
    'estado',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _creadaEnMeta = const VerificationMeta(
    'creadaEn',
  );
  @override
  late final GeneratedColumn<DateTime> creadaEn = GeneratedColumn<DateTime>(
    'creada_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rutaFotoMeta = const VerificationMeta(
    'rutaFoto',
  );
  @override
  late final GeneratedColumn<String> rutaFoto = GeneratedColumn<String>(
    'ruta_foto',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    habitoId,
    rachaObjetivo,
    estado,
    creadaEn,
    rutaFoto,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'capsulas';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilaCapsula> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('habito_id')) {
      context.handle(
        _habitoIdMeta,
        habitoId.isAcceptableOrUnknown(data['habito_id']!, _habitoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_habitoIdMeta);
    }
    if (data.containsKey('racha_objetivo')) {
      context.handle(
        _rachaObjetivoMeta,
        rachaObjetivo.isAcceptableOrUnknown(
          data['racha_objetivo']!,
          _rachaObjetivoMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rachaObjetivoMeta);
    }
    if (data.containsKey('estado')) {
      context.handle(
        _estadoMeta,
        estado.isAcceptableOrUnknown(data['estado']!, _estadoMeta),
      );
    } else if (isInserting) {
      context.missing(_estadoMeta);
    }
    if (data.containsKey('creada_en')) {
      context.handle(
        _creadaEnMeta,
        creadaEn.isAcceptableOrUnknown(data['creada_en']!, _creadaEnMeta),
      );
    } else if (isInserting) {
      context.missing(_creadaEnMeta);
    }
    if (data.containsKey('ruta_foto')) {
      context.handle(
        _rutaFotoMeta,
        rutaFoto.isAcceptableOrUnknown(data['ruta_foto']!, _rutaFotoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  FilaCapsula map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilaCapsula(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      habitoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}habito_id'],
      )!,
      rachaObjetivo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}racha_objetivo'],
      )!,
      estado: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estado'],
      )!,
      creadaEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}creada_en'],
      )!,
      rutaFoto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ruta_foto'],
      ),
    );
  }

  @override
  $CapsulasTable createAlias(String alias) {
    return $CapsulasTable(attachedDatabase, alias);
  }
}

class FilaCapsula extends DataClass implements Insertable<FilaCapsula> {
  final String id;
  final String habitoId;
  final int rachaObjetivo;
  final String estado;
  final DateTime creadaEn;
  final String? rutaFoto;
  const FilaCapsula({
    required this.id,
    required this.habitoId,
    required this.rachaObjetivo,
    required this.estado,
    required this.creadaEn,
    this.rutaFoto,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['habito_id'] = Variable<String>(habitoId);
    map['racha_objetivo'] = Variable<int>(rachaObjetivo);
    map['estado'] = Variable<String>(estado);
    map['creada_en'] = Variable<DateTime>(creadaEn);
    if (!nullToAbsent || rutaFoto != null) {
      map['ruta_foto'] = Variable<String>(rutaFoto);
    }
    return map;
  }

  CapsulasCompanion toCompanion(bool nullToAbsent) {
    return CapsulasCompanion(
      id: Value(id),
      habitoId: Value(habitoId),
      rachaObjetivo: Value(rachaObjetivo),
      estado: Value(estado),
      creadaEn: Value(creadaEn),
      rutaFoto: rutaFoto == null && nullToAbsent
          ? const Value.absent()
          : Value(rutaFoto),
    );
  }

  factory FilaCapsula.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilaCapsula(
      id: serializer.fromJson<String>(json['id']),
      habitoId: serializer.fromJson<String>(json['habitoId']),
      rachaObjetivo: serializer.fromJson<int>(json['rachaObjetivo']),
      estado: serializer.fromJson<String>(json['estado']),
      creadaEn: serializer.fromJson<DateTime>(json['creadaEn']),
      rutaFoto: serializer.fromJson<String?>(json['rutaFoto']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'habitoId': serializer.toJson<String>(habitoId),
      'rachaObjetivo': serializer.toJson<int>(rachaObjetivo),
      'estado': serializer.toJson<String>(estado),
      'creadaEn': serializer.toJson<DateTime>(creadaEn),
      'rutaFoto': serializer.toJson<String?>(rutaFoto),
    };
  }

  FilaCapsula copyWith({
    String? id,
    String? habitoId,
    int? rachaObjetivo,
    String? estado,
    DateTime? creadaEn,
    Value<String?> rutaFoto = const Value.absent(),
  }) => FilaCapsula(
    id: id ?? this.id,
    habitoId: habitoId ?? this.habitoId,
    rachaObjetivo: rachaObjetivo ?? this.rachaObjetivo,
    estado: estado ?? this.estado,
    creadaEn: creadaEn ?? this.creadaEn,
    rutaFoto: rutaFoto.present ? rutaFoto.value : this.rutaFoto,
  );
  FilaCapsula copyWithCompanion(CapsulasCompanion data) {
    return FilaCapsula(
      id: data.id.present ? data.id.value : this.id,
      habitoId: data.habitoId.present ? data.habitoId.value : this.habitoId,
      rachaObjetivo: data.rachaObjetivo.present
          ? data.rachaObjetivo.value
          : this.rachaObjetivo,
      estado: data.estado.present ? data.estado.value : this.estado,
      creadaEn: data.creadaEn.present ? data.creadaEn.value : this.creadaEn,
      rutaFoto: data.rutaFoto.present ? data.rutaFoto.value : this.rutaFoto,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilaCapsula(')
          ..write('id: $id, ')
          ..write('habitoId: $habitoId, ')
          ..write('rachaObjetivo: $rachaObjetivo, ')
          ..write('estado: $estado, ')
          ..write('creadaEn: $creadaEn, ')
          ..write('rutaFoto: $rutaFoto')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, habitoId, rachaObjetivo, estado, creadaEn, rutaFoto);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilaCapsula &&
          other.id == this.id &&
          other.habitoId == this.habitoId &&
          other.rachaObjetivo == this.rachaObjetivo &&
          other.estado == this.estado &&
          other.creadaEn == this.creadaEn &&
          other.rutaFoto == this.rutaFoto);
}

class CapsulasCompanion extends UpdateCompanion<FilaCapsula> {
  final Value<String> id;
  final Value<String> habitoId;
  final Value<int> rachaObjetivo;
  final Value<String> estado;
  final Value<DateTime> creadaEn;
  final Value<String?> rutaFoto;
  final Value<int> rowid;
  const CapsulasCompanion({
    this.id = const Value.absent(),
    this.habitoId = const Value.absent(),
    this.rachaObjetivo = const Value.absent(),
    this.estado = const Value.absent(),
    this.creadaEn = const Value.absent(),
    this.rutaFoto = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CapsulasCompanion.insert({
    required String id,
    required String habitoId,
    required int rachaObjetivo,
    required String estado,
    required DateTime creadaEn,
    this.rutaFoto = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       habitoId = Value(habitoId),
       rachaObjetivo = Value(rachaObjetivo),
       estado = Value(estado),
       creadaEn = Value(creadaEn);
  static Insertable<FilaCapsula> custom({
    Expression<String>? id,
    Expression<String>? habitoId,
    Expression<int>? rachaObjetivo,
    Expression<String>? estado,
    Expression<DateTime>? creadaEn,
    Expression<String>? rutaFoto,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (habitoId != null) 'habito_id': habitoId,
      if (rachaObjetivo != null) 'racha_objetivo': rachaObjetivo,
      if (estado != null) 'estado': estado,
      if (creadaEn != null) 'creada_en': creadaEn,
      if (rutaFoto != null) 'ruta_foto': rutaFoto,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CapsulasCompanion copyWith({
    Value<String>? id,
    Value<String>? habitoId,
    Value<int>? rachaObjetivo,
    Value<String>? estado,
    Value<DateTime>? creadaEn,
    Value<String?>? rutaFoto,
    Value<int>? rowid,
  }) {
    return CapsulasCompanion(
      id: id ?? this.id,
      habitoId: habitoId ?? this.habitoId,
      rachaObjetivo: rachaObjetivo ?? this.rachaObjetivo,
      estado: estado ?? this.estado,
      creadaEn: creadaEn ?? this.creadaEn,
      rutaFoto: rutaFoto ?? this.rutaFoto,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (habitoId.present) {
      map['habito_id'] = Variable<String>(habitoId.value);
    }
    if (rachaObjetivo.present) {
      map['racha_objetivo'] = Variable<int>(rachaObjetivo.value);
    }
    if (estado.present) {
      map['estado'] = Variable<String>(estado.value);
    }
    if (creadaEn.present) {
      map['creada_en'] = Variable<DateTime>(creadaEn.value);
    }
    if (rutaFoto.present) {
      map['ruta_foto'] = Variable<String>(rutaFoto.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CapsulasCompanion(')
          ..write('id: $id, ')
          ..write('habitoId: $habitoId, ')
          ..write('rachaObjetivo: $rachaObjetivo, ')
          ..write('estado: $estado, ')
          ..write('creadaEn: $creadaEn, ')
          ..write('rutaFoto: $rutaFoto, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecordatoriosTable extends Recordatorios
    with TableInfo<$RecordatoriosTable, FilaRecordatorio> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecordatoriosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _habitoIdMeta = const VerificationMeta(
    'habitoId',
  );
  @override
  late final GeneratedColumn<String> habitoId = GeneratedColumn<String>(
    'habito_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _horaMeta = const VerificationMeta('hora');
  @override
  late final GeneratedColumn<int> hora = GeneratedColumn<int>(
    'hora',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minutoMeta = const VerificationMeta('minuto');
  @override
  late final GeneratedColumn<int> minuto = GeneratedColumn<int>(
    'minuto',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [habitoId, hora, minuto];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recordatorios';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilaRecordatorio> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('habito_id')) {
      context.handle(
        _habitoIdMeta,
        habitoId.isAcceptableOrUnknown(data['habito_id']!, _habitoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_habitoIdMeta);
    }
    if (data.containsKey('hora')) {
      context.handle(
        _horaMeta,
        hora.isAcceptableOrUnknown(data['hora']!, _horaMeta),
      );
    } else if (isInserting) {
      context.missing(_horaMeta);
    }
    if (data.containsKey('minuto')) {
      context.handle(
        _minutoMeta,
        minuto.isAcceptableOrUnknown(data['minuto']!, _minutoMeta),
      );
    } else if (isInserting) {
      context.missing(_minutoMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {habitoId};
  @override
  FilaRecordatorio map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilaRecordatorio(
      habitoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}habito_id'],
      )!,
      hora: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hora'],
      )!,
      minuto: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minuto'],
      )!,
    );
  }

  @override
  $RecordatoriosTable createAlias(String alias) {
    return $RecordatoriosTable(attachedDatabase, alias);
  }
}

class FilaRecordatorio extends DataClass
    implements Insertable<FilaRecordatorio> {
  final String habitoId;
  final int hora;
  final int minuto;
  const FilaRecordatorio({
    required this.habitoId,
    required this.hora,
    required this.minuto,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['habito_id'] = Variable<String>(habitoId);
    map['hora'] = Variable<int>(hora);
    map['minuto'] = Variable<int>(minuto);
    return map;
  }

  RecordatoriosCompanion toCompanion(bool nullToAbsent) {
    return RecordatoriosCompanion(
      habitoId: Value(habitoId),
      hora: Value(hora),
      minuto: Value(minuto),
    );
  }

  factory FilaRecordatorio.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilaRecordatorio(
      habitoId: serializer.fromJson<String>(json['habitoId']),
      hora: serializer.fromJson<int>(json['hora']),
      minuto: serializer.fromJson<int>(json['minuto']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'habitoId': serializer.toJson<String>(habitoId),
      'hora': serializer.toJson<int>(hora),
      'minuto': serializer.toJson<int>(minuto),
    };
  }

  FilaRecordatorio copyWith({String? habitoId, int? hora, int? minuto}) =>
      FilaRecordatorio(
        habitoId: habitoId ?? this.habitoId,
        hora: hora ?? this.hora,
        minuto: minuto ?? this.minuto,
      );
  FilaRecordatorio copyWithCompanion(RecordatoriosCompanion data) {
    return FilaRecordatorio(
      habitoId: data.habitoId.present ? data.habitoId.value : this.habitoId,
      hora: data.hora.present ? data.hora.value : this.hora,
      minuto: data.minuto.present ? data.minuto.value : this.minuto,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilaRecordatorio(')
          ..write('habitoId: $habitoId, ')
          ..write('hora: $hora, ')
          ..write('minuto: $minuto')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(habitoId, hora, minuto);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilaRecordatorio &&
          other.habitoId == this.habitoId &&
          other.hora == this.hora &&
          other.minuto == this.minuto);
}

class RecordatoriosCompanion extends UpdateCompanion<FilaRecordatorio> {
  final Value<String> habitoId;
  final Value<int> hora;
  final Value<int> minuto;
  final Value<int> rowid;
  const RecordatoriosCompanion({
    this.habitoId = const Value.absent(),
    this.hora = const Value.absent(),
    this.minuto = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecordatoriosCompanion.insert({
    required String habitoId,
    required int hora,
    required int minuto,
    this.rowid = const Value.absent(),
  }) : habitoId = Value(habitoId),
       hora = Value(hora),
       minuto = Value(minuto);
  static Insertable<FilaRecordatorio> custom({
    Expression<String>? habitoId,
    Expression<int>? hora,
    Expression<int>? minuto,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (habitoId != null) 'habito_id': habitoId,
      if (hora != null) 'hora': hora,
      if (minuto != null) 'minuto': minuto,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecordatoriosCompanion copyWith({
    Value<String>? habitoId,
    Value<int>? hora,
    Value<int>? minuto,
    Value<int>? rowid,
  }) {
    return RecordatoriosCompanion(
      habitoId: habitoId ?? this.habitoId,
      hora: hora ?? this.hora,
      minuto: minuto ?? this.minuto,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (habitoId.present) {
      map['habito_id'] = Variable<String>(habitoId.value);
    }
    if (hora.present) {
      map['hora'] = Variable<int>(hora.value);
    }
    if (minuto.present) {
      map['minuto'] = Variable<int>(minuto.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecordatoriosCompanion(')
          ..write('habitoId: $habitoId, ')
          ..write('hora: $hora, ')
          ..write('minuto: $minuto, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MarcasTable extends Marcas with TableInfo<$MarcasTable, FilaMarca> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MarcasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _claveMeta = const VerificationMeta('clave');
  @override
  late final GeneratedColumn<String> clave = GeneratedColumn<String>(
    'clave',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valorMeta = const VerificationMeta('valor');
  @override
  late final GeneratedColumn<String> valor = GeneratedColumn<String>(
    'valor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [clave, valor];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'marcas';
  @override
  VerificationContext validateIntegrity(
    Insertable<FilaMarca> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('clave')) {
      context.handle(
        _claveMeta,
        clave.isAcceptableOrUnknown(data['clave']!, _claveMeta),
      );
    } else if (isInserting) {
      context.missing(_claveMeta);
    }
    if (data.containsKey('valor')) {
      context.handle(
        _valorMeta,
        valor.isAcceptableOrUnknown(data['valor']!, _valorMeta),
      );
    } else if (isInserting) {
      context.missing(_valorMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clave};
  @override
  FilaMarca map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FilaMarca(
      clave: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clave'],
      )!,
      valor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valor'],
      )!,
    );
  }

  @override
  $MarcasTable createAlias(String alias) {
    return $MarcasTable(attachedDatabase, alias);
  }
}

class FilaMarca extends DataClass implements Insertable<FilaMarca> {
  final String clave;
  final String valor;
  const FilaMarca({required this.clave, required this.valor});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['clave'] = Variable<String>(clave);
    map['valor'] = Variable<String>(valor);
    return map;
  }

  MarcasCompanion toCompanion(bool nullToAbsent) {
    return MarcasCompanion(clave: Value(clave), valor: Value(valor));
  }

  factory FilaMarca.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FilaMarca(
      clave: serializer.fromJson<String>(json['clave']),
      valor: serializer.fromJson<String>(json['valor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clave': serializer.toJson<String>(clave),
      'valor': serializer.toJson<String>(valor),
    };
  }

  FilaMarca copyWith({String? clave, String? valor}) =>
      FilaMarca(clave: clave ?? this.clave, valor: valor ?? this.valor);
  FilaMarca copyWithCompanion(MarcasCompanion data) {
    return FilaMarca(
      clave: data.clave.present ? data.clave.value : this.clave,
      valor: data.valor.present ? data.valor.value : this.valor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FilaMarca(')
          ..write('clave: $clave, ')
          ..write('valor: $valor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(clave, valor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FilaMarca &&
          other.clave == this.clave &&
          other.valor == this.valor);
}

class MarcasCompanion extends UpdateCompanion<FilaMarca> {
  final Value<String> clave;
  final Value<String> valor;
  final Value<int> rowid;
  const MarcasCompanion({
    this.clave = const Value.absent(),
    this.valor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MarcasCompanion.insert({
    required String clave,
    required String valor,
    this.rowid = const Value.absent(),
  }) : clave = Value(clave),
       valor = Value(valor);
  static Insertable<FilaMarca> custom({
    Expression<String>? clave,
    Expression<String>? valor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clave != null) 'clave': clave,
      if (valor != null) 'valor': valor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MarcasCompanion copyWith({
    Value<String>? clave,
    Value<String>? valor,
    Value<int>? rowid,
  }) {
    return MarcasCompanion(
      clave: clave ?? this.clave,
      valor: valor ?? this.valor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clave.present) {
      map['clave'] = Variable<String>(clave.value);
    }
    if (valor.present) {
      map['valor'] = Variable<String>(valor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MarcasCompanion(')
          ..write('clave: $clave, ')
          ..write('valor: $valor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$BaseLocal extends GeneratedDatabase {
  _$BaseLocal(QueryExecutor e) : super(e);
  $BaseLocalManager get managers => $BaseLocalManager(this);
  late final $HabitosTable habitos = $HabitosTable(this);
  late final $CategoriasTable categorias = $CategoriasTable(this);
  late final $RegistrosTable registros = $RegistrosTable(this);
  late final $ColaPendientesTable colaPendientes = $ColaPendientesTable(this);
  late final $SenalesTable senales = $SenalesTable(this);
  late final $SugerenciasTable sugerencias = $SugerenciasTable(this);
  late final $CapsulasTable capsulas = $CapsulasTable(this);
  late final $RecordatoriosTable recordatorios = $RecordatoriosTable(this);
  late final $MarcasTable marcas = $MarcasTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    habitos,
    categorias,
    registros,
    colaPendientes,
    senales,
    sugerencias,
    capsulas,
    recordatorios,
    marcas,
  ];
}

typedef $$HabitosTableCreateCompanionBuilder = HabitosCompanion Function({
  required String id,
  required String datos,
  required bool activo,
  required DateTime guardadoEn,
  Value<int> rowid,
});
typedef $$HabitosTableUpdateCompanionBuilder = HabitosCompanion Function({
  Value<String> id,
  Value<String> datos,
  Value<bool> activo,
  Value<DateTime> guardadoEn,
  Value<int> rowid,
});

class $$HabitosTableFilterComposer
    extends Composer<_$BaseLocal, $HabitosTable> {
  $$HabitosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get datos => $composableBuilder(
    column: $table.datos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get guardadoEn => $composableBuilder(
    column: $table.guardadoEn,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HabitosTableOrderingComposer
    extends Composer<_$BaseLocal, $HabitosTable> {
  $$HabitosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get datos => $composableBuilder(
    column: $table.datos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get guardadoEn => $composableBuilder(
    column: $table.guardadoEn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HabitosTableAnnotationComposer
    extends Composer<_$BaseLocal, $HabitosTable> {
  $$HabitosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get datos =>
      $composableBuilder(column: $table.datos, builder: (column) => column);

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);

  GeneratedColumn<DateTime> get guardadoEn => $composableBuilder(
    column: $table.guardadoEn,
    builder: (column) => column,
  );
}

class $$HabitosTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $HabitosTable,
          FilaHabito,
          $$HabitosTableFilterComposer,
          $$HabitosTableOrderingComposer,
          $$HabitosTableAnnotationComposer,
          $$HabitosTableCreateCompanionBuilder,
          $$HabitosTableUpdateCompanionBuilder,
          (FilaHabito, BaseReferences<_$BaseLocal, $HabitosTable, FilaHabito>),
          FilaHabito,
          PrefetchHooks Function()
        > {
  $$HabitosTableTableManager(_$BaseLocal db, $HabitosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> datos = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<DateTime> guardadoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitosCompanion(
                id: id,
                datos: datos,
                activo: activo,
                guardadoEn: guardadoEn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String datos,
                required bool activo,
                required DateTime guardadoEn,
                Value<int> rowid = const Value.absent(),
              }) => HabitosCompanion.insert(
                id: id,
                datos: datos,
                activo: activo,
                guardadoEn: guardadoEn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HabitosTable, FilaHabito>(table),
                  BaseReferences<_$BaseLocal, $HabitosTable, FilaHabito>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HabitosTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $HabitosTable,
      FilaHabito,
      $$HabitosTableFilterComposer,
      $$HabitosTableOrderingComposer,
      $$HabitosTableAnnotationComposer,
      $$HabitosTableCreateCompanionBuilder,
      $$HabitosTableUpdateCompanionBuilder,
      (FilaHabito, BaseReferences<_$BaseLocal, $HabitosTable, FilaHabito>),
      FilaHabito,
      PrefetchHooks Function()
    >;
typedef $$CategoriasTableCreateCompanionBuilder = CategoriasCompanion Function({
  required String id,
  required String nombre,
  Value<bool> activa,
  required String datos,
  required int orden,
  Value<int> rowid,
});
typedef $$CategoriasTableUpdateCompanionBuilder = CategoriasCompanion Function({
  Value<String> id,
  Value<String> nombre,
  Value<bool> activa,
  Value<String> datos,
  Value<int> orden,
  Value<int> rowid,
});

class $$CategoriasTableFilterComposer
    extends Composer<_$BaseLocal, $CategoriasTable> {
  $$CategoriasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activa => $composableBuilder(
    column: $table.activa,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get datos => $composableBuilder(
    column: $table.datos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orden => $composableBuilder(
    column: $table.orden,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriasTableOrderingComposer
    extends Composer<_$BaseLocal, $CategoriasTable> {
  $$CategoriasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activa => $composableBuilder(
    column: $table.activa,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get datos => $composableBuilder(
    column: $table.datos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orden => $composableBuilder(
    column: $table.orden,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriasTableAnnotationComposer
    extends Composer<_$BaseLocal, $CategoriasTable> {
  $$CategoriasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<bool> get activa =>
      $composableBuilder(column: $table.activa, builder: (column) => column);

  GeneratedColumn<String> get datos =>
      $composableBuilder(column: $table.datos, builder: (column) => column);

  GeneratedColumn<int> get orden =>
      $composableBuilder(column: $table.orden, builder: (column) => column);
}

class $$CategoriasTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $CategoriasTable,
          FilaCategoria,
          $$CategoriasTableFilterComposer,
          $$CategoriasTableOrderingComposer,
          $$CategoriasTableAnnotationComposer,
          $$CategoriasTableCreateCompanionBuilder,
          $$CategoriasTableUpdateCompanionBuilder,
          (
            FilaCategoria,
            BaseReferences<_$BaseLocal, $CategoriasTable, FilaCategoria>,
          ),
          FilaCategoria,
          PrefetchHooks Function()
        > {
  $$CategoriasTableTableManager(_$BaseLocal db, $CategoriasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<bool> activa = const Value.absent(),
                Value<String> datos = const Value.absent(),
                Value<int> orden = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriasCompanion(
                id: id,
                nombre: nombre,
                activa: activa,
                datos: datos,
                orden: orden,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nombre,
                Value<bool> activa = const Value.absent(),
                required String datos,
                required int orden,
                Value<int> rowid = const Value.absent(),
              }) => CategoriasCompanion.insert(
                id: id,
                nombre: nombre,
                activa: activa,
                datos: datos,
                orden: orden,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriasTable, FilaCategoria>(table),
                  BaseReferences<_$BaseLocal, $CategoriasTable, FilaCategoria>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriasTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $CategoriasTable,
      FilaCategoria,
      $$CategoriasTableFilterComposer,
      $$CategoriasTableOrderingComposer,
      $$CategoriasTableAnnotationComposer,
      $$CategoriasTableCreateCompanionBuilder,
      $$CategoriasTableUpdateCompanionBuilder,
      (
        FilaCategoria,
        BaseReferences<_$BaseLocal, $CategoriasTable, FilaCategoria>,
      ),
      FilaCategoria,
      PrefetchHooks Function()
    >;
typedef $$RegistrosTableCreateCompanionBuilder = RegistrosCompanion Function({
  required String id,
  required String habitoId,
  required String fecha,
  required bool cumplido,
  Value<double?> valor,
  required String origen,
  Value<DateTime?> registradoEn,
  Value<int> rowid,
});
typedef $$RegistrosTableUpdateCompanionBuilder = RegistrosCompanion Function({
  Value<String> id,
  Value<String> habitoId,
  Value<String> fecha,
  Value<bool> cumplido,
  Value<double?> valor,
  Value<String> origen,
  Value<DateTime?> registradoEn,
  Value<int> rowid,
});

class $$RegistrosTableFilterComposer
    extends Composer<_$BaseLocal, $RegistrosTable> {
  $$RegistrosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get habitoId => $composableBuilder(
    column: $table.habitoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get cumplido => $composableBuilder(
    column: $table.cumplido,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origen => $composableBuilder(
    column: $table.origen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get registradoEn => $composableBuilder(
    column: $table.registradoEn,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RegistrosTableOrderingComposer
    extends Composer<_$BaseLocal, $RegistrosTable> {
  $$RegistrosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get habitoId => $composableBuilder(
    column: $table.habitoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get cumplido => $composableBuilder(
    column: $table.cumplido,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origen => $composableBuilder(
    column: $table.origen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get registradoEn => $composableBuilder(
    column: $table.registradoEn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RegistrosTableAnnotationComposer
    extends Composer<_$BaseLocal, $RegistrosTable> {
  $$RegistrosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get habitoId =>
      $composableBuilder(column: $table.habitoId, builder: (column) => column);

  GeneratedColumn<String> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumn<bool> get cumplido =>
      $composableBuilder(column: $table.cumplido, builder: (column) => column);

  GeneratedColumn<double> get valor =>
      $composableBuilder(column: $table.valor, builder: (column) => column);

  GeneratedColumn<String> get origen =>
      $composableBuilder(column: $table.origen, builder: (column) => column);

  GeneratedColumn<DateTime> get registradoEn => $composableBuilder(
    column: $table.registradoEn,
    builder: (column) => column,
  );
}

class $$RegistrosTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $RegistrosTable,
          FilaRegistro,
          $$RegistrosTableFilterComposer,
          $$RegistrosTableOrderingComposer,
          $$RegistrosTableAnnotationComposer,
          $$RegistrosTableCreateCompanionBuilder,
          $$RegistrosTableUpdateCompanionBuilder,
          (
            FilaRegistro,
            BaseReferences<_$BaseLocal, $RegistrosTable, FilaRegistro>,
          ),
          FilaRegistro,
          PrefetchHooks Function()
        > {
  $$RegistrosTableTableManager(_$BaseLocal db, $RegistrosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RegistrosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RegistrosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RegistrosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> habitoId = const Value.absent(),
                Value<String> fecha = const Value.absent(),
                Value<bool> cumplido = const Value.absent(),
                Value<double?> valor = const Value.absent(),
                Value<String> origen = const Value.absent(),
                Value<DateTime?> registradoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RegistrosCompanion(
                id: id,
                habitoId: habitoId,
                fecha: fecha,
                cumplido: cumplido,
                valor: valor,
                origen: origen,
                registradoEn: registradoEn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String habitoId,
                required String fecha,
                required bool cumplido,
                Value<double?> valor = const Value.absent(),
                required String origen,
                Value<DateTime?> registradoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RegistrosCompanion.insert(
                id: id,
                habitoId: habitoId,
                fecha: fecha,
                cumplido: cumplido,
                valor: valor,
                origen: origen,
                registradoEn: registradoEn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RegistrosTable, FilaRegistro>(table),
                  BaseReferences<_$BaseLocal, $RegistrosTable, FilaRegistro>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RegistrosTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $RegistrosTable,
      FilaRegistro,
      $$RegistrosTableFilterComposer,
      $$RegistrosTableOrderingComposer,
      $$RegistrosTableAnnotationComposer,
      $$RegistrosTableCreateCompanionBuilder,
      $$RegistrosTableUpdateCompanionBuilder,
      (
        FilaRegistro,
        BaseReferences<_$BaseLocal, $RegistrosTable, FilaRegistro>,
      ),
      FilaRegistro,
      PrefetchHooks Function()
    >;
typedef $$ColaPendientesTableCreateCompanionBuilder =
    ColaPendientesCompanion Function({
      required String id,
      Value<String> tipo,
      required String habitoId,
      required String fecha,
      required bool cumplido,
      Value<double?> valor,
      required DateTime creadoEn,
      Value<int> intentos,
      Value<String?> ultimoError,
      Value<bool> rechazado,
      Value<int> rowid,
    });
typedef $$ColaPendientesTableUpdateCompanionBuilder =
    ColaPendientesCompanion Function({
      Value<String> id,
      Value<String> tipo,
      Value<String> habitoId,
      Value<String> fecha,
      Value<bool> cumplido,
      Value<double?> valor,
      Value<DateTime> creadoEn,
      Value<int> intentos,
      Value<String?> ultimoError,
      Value<bool> rechazado,
      Value<int> rowid,
    });

class $$ColaPendientesTableFilterComposer
    extends Composer<_$BaseLocal, $ColaPendientesTable> {
  $$ColaPendientesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get habitoId => $composableBuilder(
    column: $table.habitoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get cumplido => $composableBuilder(
    column: $table.cumplido,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intentos => $composableBuilder(
    column: $table.intentos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ultimoError => $composableBuilder(
    column: $table.ultimoError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get rechazado => $composableBuilder(
    column: $table.rechazado,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ColaPendientesTableOrderingComposer
    extends Composer<_$BaseLocal, $ColaPendientesTable> {
  $$ColaPendientesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get habitoId => $composableBuilder(
    column: $table.habitoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get cumplido => $composableBuilder(
    column: $table.cumplido,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intentos => $composableBuilder(
    column: $table.intentos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ultimoError => $composableBuilder(
    column: $table.ultimoError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get rechazado => $composableBuilder(
    column: $table.rechazado,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ColaPendientesTableAnnotationComposer
    extends Composer<_$BaseLocal, $ColaPendientesTable> {
  $$ColaPendientesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get habitoId =>
      $composableBuilder(column: $table.habitoId, builder: (column) => column);

  GeneratedColumn<String> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumn<bool> get cumplido =>
      $composableBuilder(column: $table.cumplido, builder: (column) => column);

  GeneratedColumn<double> get valor =>
      $composableBuilder(column: $table.valor, builder: (column) => column);

  GeneratedColumn<DateTime> get creadoEn =>
      $composableBuilder(column: $table.creadoEn, builder: (column) => column);

  GeneratedColumn<int> get intentos =>
      $composableBuilder(column: $table.intentos, builder: (column) => column);

  GeneratedColumn<String> get ultimoError => $composableBuilder(
    column: $table.ultimoError,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get rechazado =>
      $composableBuilder(column: $table.rechazado, builder: (column) => column);
}

class $$ColaPendientesTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $ColaPendientesTable,
          FilaPendiente,
          $$ColaPendientesTableFilterComposer,
          $$ColaPendientesTableOrderingComposer,
          $$ColaPendientesTableAnnotationComposer,
          $$ColaPendientesTableCreateCompanionBuilder,
          $$ColaPendientesTableUpdateCompanionBuilder,
          (
            FilaPendiente,
            BaseReferences<_$BaseLocal, $ColaPendientesTable, FilaPendiente>,
          ),
          FilaPendiente,
          PrefetchHooks Function()
        > {
  $$ColaPendientesTableTableManager(_$BaseLocal db, $ColaPendientesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ColaPendientesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ColaPendientesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ColaPendientesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<String> habitoId = const Value.absent(),
                Value<String> fecha = const Value.absent(),
                Value<bool> cumplido = const Value.absent(),
                Value<double?> valor = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
                Value<int> intentos = const Value.absent(),
                Value<String?> ultimoError = const Value.absent(),
                Value<bool> rechazado = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ColaPendientesCompanion(
                id: id,
                tipo: tipo,
                habitoId: habitoId,
                fecha: fecha,
                cumplido: cumplido,
                valor: valor,
                creadoEn: creadoEn,
                intentos: intentos,
                ultimoError: ultimoError,
                rechazado: rechazado,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> tipo = const Value.absent(),
                required String habitoId,
                required String fecha,
                required bool cumplido,
                Value<double?> valor = const Value.absent(),
                required DateTime creadoEn,
                Value<int> intentos = const Value.absent(),
                Value<String?> ultimoError = const Value.absent(),
                Value<bool> rechazado = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ColaPendientesCompanion.insert(
                id: id,
                tipo: tipo,
                habitoId: habitoId,
                fecha: fecha,
                cumplido: cumplido,
                valor: valor,
                creadoEn: creadoEn,
                intentos: intentos,
                ultimoError: ultimoError,
                rechazado: rechazado,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ColaPendientesTable, FilaPendiente>(table),
                  BaseReferences<
                    _$BaseLocal,
                    $ColaPendientesTable,
                    FilaPendiente
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ColaPendientesTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $ColaPendientesTable,
      FilaPendiente,
      $$ColaPendientesTableFilterComposer,
      $$ColaPendientesTableOrderingComposer,
      $$ColaPendientesTableAnnotationComposer,
      $$ColaPendientesTableCreateCompanionBuilder,
      $$ColaPendientesTableUpdateCompanionBuilder,
      (
        FilaPendiente,
        BaseReferences<_$BaseLocal, $ColaPendientesTable, FilaPendiente>,
      ),
      FilaPendiente,
      PrefetchHooks Function()
    >;
typedef $$SenalesTableCreateCompanionBuilder = SenalesCompanion Function({
  required String fecha,
  required int animo,
  required int energia,
  Value<int> rowid,
});
typedef $$SenalesTableUpdateCompanionBuilder = SenalesCompanion Function({
  Value<String> fecha,
  Value<int> animo,
  Value<int> energia,
  Value<int> rowid,
});

class $$SenalesTableFilterComposer
    extends Composer<_$BaseLocal, $SenalesTable> {
  $$SenalesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get animo => $composableBuilder(
    column: $table.animo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get energia => $composableBuilder(
    column: $table.energia,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SenalesTableOrderingComposer
    extends Composer<_$BaseLocal, $SenalesTable> {
  $$SenalesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get animo => $composableBuilder(
    column: $table.animo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get energia => $composableBuilder(
    column: $table.energia,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SenalesTableAnnotationComposer
    extends Composer<_$BaseLocal, $SenalesTable> {
  $$SenalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumn<int> get animo =>
      $composableBuilder(column: $table.animo, builder: (column) => column);

  GeneratedColumn<int> get energia =>
      $composableBuilder(column: $table.energia, builder: (column) => column);
}

class $$SenalesTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $SenalesTable,
          FilaSenal,
          $$SenalesTableFilterComposer,
          $$SenalesTableOrderingComposer,
          $$SenalesTableAnnotationComposer,
          $$SenalesTableCreateCompanionBuilder,
          $$SenalesTableUpdateCompanionBuilder,
          (FilaSenal, BaseReferences<_$BaseLocal, $SenalesTable, FilaSenal>),
          FilaSenal,
          PrefetchHooks Function()
        > {
  $$SenalesTableTableManager(_$BaseLocal db, $SenalesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SenalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SenalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SenalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> fecha = const Value.absent(),
                Value<int> animo = const Value.absent(),
                Value<int> energia = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SenalesCompanion(
                fecha: fecha,
                animo: animo,
                energia: energia,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String fecha,
                required int animo,
                required int energia,
                Value<int> rowid = const Value.absent(),
              }) => SenalesCompanion.insert(
                fecha: fecha,
                animo: animo,
                energia: energia,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SenalesTable, FilaSenal>(table),
                  BaseReferences<_$BaseLocal, $SenalesTable, FilaSenal>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SenalesTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $SenalesTable,
      FilaSenal,
      $$SenalesTableFilterComposer,
      $$SenalesTableOrderingComposer,
      $$SenalesTableAnnotationComposer,
      $$SenalesTableCreateCompanionBuilder,
      $$SenalesTableUpdateCompanionBuilder,
      (FilaSenal, BaseReferences<_$BaseLocal, $SenalesTable, FilaSenal>),
      FilaSenal,
      PrefetchHooks Function()
    >;
typedef $$SugerenciasTableCreateCompanionBuilder =
    SugerenciasCompanion Function({
      required String id,
      required String datos,
      Value<int> rowid,
    });
typedef $$SugerenciasTableUpdateCompanionBuilder =
    SugerenciasCompanion Function({
      Value<String> id,
      Value<String> datos,
      Value<int> rowid,
    });

class $$SugerenciasTableFilterComposer
    extends Composer<_$BaseLocal, $SugerenciasTable> {
  $$SugerenciasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get datos => $composableBuilder(
    column: $table.datos,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SugerenciasTableOrderingComposer
    extends Composer<_$BaseLocal, $SugerenciasTable> {
  $$SugerenciasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get datos => $composableBuilder(
    column: $table.datos,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SugerenciasTableAnnotationComposer
    extends Composer<_$BaseLocal, $SugerenciasTable> {
  $$SugerenciasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get datos =>
      $composableBuilder(column: $table.datos, builder: (column) => column);
}

class $$SugerenciasTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $SugerenciasTable,
          FilaSugerencia,
          $$SugerenciasTableFilterComposer,
          $$SugerenciasTableOrderingComposer,
          $$SugerenciasTableAnnotationComposer,
          $$SugerenciasTableCreateCompanionBuilder,
          $$SugerenciasTableUpdateCompanionBuilder,
          (
            FilaSugerencia,
            BaseReferences<_$BaseLocal, $SugerenciasTable, FilaSugerencia>,
          ),
          FilaSugerencia,
          PrefetchHooks Function()
        > {
  $$SugerenciasTableTableManager(_$BaseLocal db, $SugerenciasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SugerenciasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SugerenciasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SugerenciasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> datos = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SugerenciasCompanion(id: id, datos: datos, rowid: rowid),
          createCompanionCallback: ({
            required String id,
            required String datos,
            Value<int> rowid = const Value.absent(),
          }) => SugerenciasCompanion.insert(id: id, datos: datos, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SugerenciasTable, FilaSugerencia>(table),
                  BaseReferences<
                    _$BaseLocal,
                    $SugerenciasTable,
                    FilaSugerencia
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SugerenciasTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $SugerenciasTable,
      FilaSugerencia,
      $$SugerenciasTableFilterComposer,
      $$SugerenciasTableOrderingComposer,
      $$SugerenciasTableAnnotationComposer,
      $$SugerenciasTableCreateCompanionBuilder,
      $$SugerenciasTableUpdateCompanionBuilder,
      (
        FilaSugerencia,
        BaseReferences<_$BaseLocal, $SugerenciasTable, FilaSugerencia>,
      ),
      FilaSugerencia,
      PrefetchHooks Function()
    >;
typedef $$CapsulasTableCreateCompanionBuilder = CapsulasCompanion Function({
  required String id,
  required String habitoId,
  required int rachaObjetivo,
  required String estado,
  required DateTime creadaEn,
  Value<String?> rutaFoto,
  Value<int> rowid,
});
typedef $$CapsulasTableUpdateCompanionBuilder = CapsulasCompanion Function({
  Value<String> id,
  Value<String> habitoId,
  Value<int> rachaObjetivo,
  Value<String> estado,
  Value<DateTime> creadaEn,
  Value<String?> rutaFoto,
  Value<int> rowid,
});

class $$CapsulasTableFilterComposer
    extends Composer<_$BaseLocal, $CapsulasTable> {
  $$CapsulasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get habitoId => $composableBuilder(
    column: $table.habitoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rachaObjetivo => $composableBuilder(
    column: $table.rachaObjetivo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creadaEn => $composableBuilder(
    column: $table.creadaEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rutaFoto => $composableBuilder(
    column: $table.rutaFoto,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CapsulasTableOrderingComposer
    extends Composer<_$BaseLocal, $CapsulasTable> {
  $$CapsulasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get habitoId => $composableBuilder(
    column: $table.habitoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rachaObjetivo => $composableBuilder(
    column: $table.rachaObjetivo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creadaEn => $composableBuilder(
    column: $table.creadaEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rutaFoto => $composableBuilder(
    column: $table.rutaFoto,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CapsulasTableAnnotationComposer
    extends Composer<_$BaseLocal, $CapsulasTable> {
  $$CapsulasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get habitoId =>
      $composableBuilder(column: $table.habitoId, builder: (column) => column);

  GeneratedColumn<int> get rachaObjetivo => $composableBuilder(
    column: $table.rachaObjetivo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get estado =>
      $composableBuilder(column: $table.estado, builder: (column) => column);

  GeneratedColumn<DateTime> get creadaEn =>
      $composableBuilder(column: $table.creadaEn, builder: (column) => column);

  GeneratedColumn<String> get rutaFoto =>
      $composableBuilder(column: $table.rutaFoto, builder: (column) => column);
}

class $$CapsulasTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $CapsulasTable,
          FilaCapsula,
          $$CapsulasTableFilterComposer,
          $$CapsulasTableOrderingComposer,
          $$CapsulasTableAnnotationComposer,
          $$CapsulasTableCreateCompanionBuilder,
          $$CapsulasTableUpdateCompanionBuilder,
          (
            FilaCapsula,
            BaseReferences<_$BaseLocal, $CapsulasTable, FilaCapsula>,
          ),
          FilaCapsula,
          PrefetchHooks Function()
        > {
  $$CapsulasTableTableManager(_$BaseLocal db, $CapsulasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CapsulasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CapsulasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CapsulasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> habitoId = const Value.absent(),
                Value<int> rachaObjetivo = const Value.absent(),
                Value<String> estado = const Value.absent(),
                Value<DateTime> creadaEn = const Value.absent(),
                Value<String?> rutaFoto = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CapsulasCompanion(
                id: id,
                habitoId: habitoId,
                rachaObjetivo: rachaObjetivo,
                estado: estado,
                creadaEn: creadaEn,
                rutaFoto: rutaFoto,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String habitoId,
                required int rachaObjetivo,
                required String estado,
                required DateTime creadaEn,
                Value<String?> rutaFoto = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CapsulasCompanion.insert(
                id: id,
                habitoId: habitoId,
                rachaObjetivo: rachaObjetivo,
                estado: estado,
                creadaEn: creadaEn,
                rutaFoto: rutaFoto,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CapsulasTable, FilaCapsula>(table),
                  BaseReferences<_$BaseLocal, $CapsulasTable, FilaCapsula>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CapsulasTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $CapsulasTable,
      FilaCapsula,
      $$CapsulasTableFilterComposer,
      $$CapsulasTableOrderingComposer,
      $$CapsulasTableAnnotationComposer,
      $$CapsulasTableCreateCompanionBuilder,
      $$CapsulasTableUpdateCompanionBuilder,
      (FilaCapsula, BaseReferences<_$BaseLocal, $CapsulasTable, FilaCapsula>),
      FilaCapsula,
      PrefetchHooks Function()
    >;
typedef $$RecordatoriosTableCreateCompanionBuilder =
    RecordatoriosCompanion Function({
      required String habitoId,
      required int hora,
      required int minuto,
      Value<int> rowid,
    });
typedef $$RecordatoriosTableUpdateCompanionBuilder =
    RecordatoriosCompanion Function({
      Value<String> habitoId,
      Value<int> hora,
      Value<int> minuto,
      Value<int> rowid,
    });

class $$RecordatoriosTableFilterComposer
    extends Composer<_$BaseLocal, $RecordatoriosTable> {
  $$RecordatoriosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get habitoId => $composableBuilder(
    column: $table.habitoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hora => $composableBuilder(
    column: $table.hora,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minuto => $composableBuilder(
    column: $table.minuto,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecordatoriosTableOrderingComposer
    extends Composer<_$BaseLocal, $RecordatoriosTable> {
  $$RecordatoriosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get habitoId => $composableBuilder(
    column: $table.habitoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hora => $composableBuilder(
    column: $table.hora,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minuto => $composableBuilder(
    column: $table.minuto,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecordatoriosTableAnnotationComposer
    extends Composer<_$BaseLocal, $RecordatoriosTable> {
  $$RecordatoriosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get habitoId =>
      $composableBuilder(column: $table.habitoId, builder: (column) => column);

  GeneratedColumn<int> get hora =>
      $composableBuilder(column: $table.hora, builder: (column) => column);

  GeneratedColumn<int> get minuto =>
      $composableBuilder(column: $table.minuto, builder: (column) => column);
}

class $$RecordatoriosTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $RecordatoriosTable,
          FilaRecordatorio,
          $$RecordatoriosTableFilterComposer,
          $$RecordatoriosTableOrderingComposer,
          $$RecordatoriosTableAnnotationComposer,
          $$RecordatoriosTableCreateCompanionBuilder,
          $$RecordatoriosTableUpdateCompanionBuilder,
          (
            FilaRecordatorio,
            BaseReferences<_$BaseLocal, $RecordatoriosTable, FilaRecordatorio>,
          ),
          FilaRecordatorio,
          PrefetchHooks Function()
        > {
  $$RecordatoriosTableTableManager(_$BaseLocal db, $RecordatoriosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecordatoriosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecordatoriosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecordatoriosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> habitoId = const Value.absent(),
                Value<int> hora = const Value.absent(),
                Value<int> minuto = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecordatoriosCompanion(
                habitoId: habitoId,
                hora: hora,
                minuto: minuto,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String habitoId,
                required int hora,
                required int minuto,
                Value<int> rowid = const Value.absent(),
              }) => RecordatoriosCompanion.insert(
                habitoId: habitoId,
                hora: hora,
                minuto: minuto,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecordatoriosTable, FilaRecordatorio>(table),
                  BaseReferences<
                    _$BaseLocal,
                    $RecordatoriosTable,
                    FilaRecordatorio
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecordatoriosTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $RecordatoriosTable,
      FilaRecordatorio,
      $$RecordatoriosTableFilterComposer,
      $$RecordatoriosTableOrderingComposer,
      $$RecordatoriosTableAnnotationComposer,
      $$RecordatoriosTableCreateCompanionBuilder,
      $$RecordatoriosTableUpdateCompanionBuilder,
      (
        FilaRecordatorio,
        BaseReferences<_$BaseLocal, $RecordatoriosTable, FilaRecordatorio>,
      ),
      FilaRecordatorio,
      PrefetchHooks Function()
    >;
typedef $$MarcasTableCreateCompanionBuilder = MarcasCompanion Function({
  required String clave,
  required String valor,
  Value<int> rowid,
});
typedef $$MarcasTableUpdateCompanionBuilder = MarcasCompanion Function({
  Value<String> clave,
  Value<String> valor,
  Value<int> rowid,
});

class $$MarcasTableFilterComposer extends Composer<_$BaseLocal, $MarcasTable> {
  $$MarcasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clave => $composableBuilder(
    column: $table.clave,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MarcasTableOrderingComposer
    extends Composer<_$BaseLocal, $MarcasTable> {
  $$MarcasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clave => $composableBuilder(
    column: $table.clave,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MarcasTableAnnotationComposer
    extends Composer<_$BaseLocal, $MarcasTable> {
  $$MarcasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clave =>
      $composableBuilder(column: $table.clave, builder: (column) => column);

  GeneratedColumn<String> get valor =>
      $composableBuilder(column: $table.valor, builder: (column) => column);
}

class $$MarcasTableTableManager
    extends
        RootTableManager<
          _$BaseLocal,
          $MarcasTable,
          FilaMarca,
          $$MarcasTableFilterComposer,
          $$MarcasTableOrderingComposer,
          $$MarcasTableAnnotationComposer,
          $$MarcasTableCreateCompanionBuilder,
          $$MarcasTableUpdateCompanionBuilder,
          (FilaMarca, BaseReferences<_$BaseLocal, $MarcasTable, FilaMarca>),
          FilaMarca,
          PrefetchHooks Function()
        > {
  $$MarcasTableTableManager(_$BaseLocal db, $MarcasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MarcasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MarcasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MarcasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> clave = const Value.absent(),
            Value<String> valor = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => MarcasCompanion(clave: clave, valor: valor, rowid: rowid),
          createCompanionCallback:
              ({
                required String clave,
                required String valor,
                Value<int> rowid = const Value.absent(),
              }) => MarcasCompanion.insert(
                clave: clave,
                valor: valor,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MarcasTable, FilaMarca>(table),
                  BaseReferences<_$BaseLocal, $MarcasTable, FilaMarca>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MarcasTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseLocal,
      $MarcasTable,
      FilaMarca,
      $$MarcasTableFilterComposer,
      $$MarcasTableOrderingComposer,
      $$MarcasTableAnnotationComposer,
      $$MarcasTableCreateCompanionBuilder,
      $$MarcasTableUpdateCompanionBuilder,
      (FilaMarca, BaseReferences<_$BaseLocal, $MarcasTable, FilaMarca>),
      FilaMarca,
      PrefetchHooks Function()
    >;

class $BaseLocalManager {
  final _$BaseLocal _db;
  $BaseLocalManager(this._db);
  $$HabitosTableTableManager get habitos =>
      $$HabitosTableTableManager(_db, _db.habitos);
  $$CategoriasTableTableManager get categorias =>
      $$CategoriasTableTableManager(_db, _db.categorias);
  $$RegistrosTableTableManager get registros =>
      $$RegistrosTableTableManager(_db, _db.registros);
  $$ColaPendientesTableTableManager get colaPendientes =>
      $$ColaPendientesTableTableManager(_db, _db.colaPendientes);
  $$SenalesTableTableManager get senales =>
      $$SenalesTableTableManager(_db, _db.senales);
  $$SugerenciasTableTableManager get sugerencias =>
      $$SugerenciasTableTableManager(_db, _db.sugerencias);
  $$CapsulasTableTableManager get capsulas =>
      $$CapsulasTableTableManager(_db, _db.capsulas);
  $$RecordatoriosTableTableManager get recordatorios =>
      $$RecordatoriosTableTableManager(_db, _db.recordatorios);
  $$MarcasTableTableManager get marcas =>
      $$MarcasTableTableManager(_db, _db.marcas);
}
