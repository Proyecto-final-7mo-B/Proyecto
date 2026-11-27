import 'package:drift/drift.dart';

/// Tablas de la base local (diseño §7.5). Es una **caché**: la verdad está en el servidor.
///
/// - No se guardan tokens ni el mensaje de las cápsulas.
/// - Las fechas de los check-ins van como texto `AAAA-MM-DD`: es la fecha **local** del usuario y no debe moverse con
///   la zona horaria.

/// Copia de `GET /habitos`: el JSON del contrato (racha, nivel y `hoy` del día en que se guardó).
@DataClassName('FilaHabito')
class Habitos extends Table {
  TextColumn get id => text()();
  TextColumn get datos => text()();
  BoolColumn get activo => boolean()();
  DateTimeColumn get guardadoEn => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Copia de `GET /categorias` (v1.6): cada categoría con su árbol (subcategorías, unidades permitidas y referencia
/// científica) en `datos`, para que la evaluación con evidencia funcione sin red.
@DataClassName('FilaCategoria')
class Categorias extends Table {
  TextColumn get id => text()();
  TextColumn get nombre => text()();
  BoolColumn get activa => boolean().withDefault(const Constant(true))();

  /// El JSON de la categoría completa, como lo manda la API.
  TextColumn get datos => text()();

  /// Posición en el catálogo (el orden de la API: Ejercicio, Salud, Educación, Bienestar, Finanzas).
  IntColumn get orden => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Check-ins (hasta 366 días por hábito). Un solo check-in por hábito y día, como en la base del servidor.
@DataClassName('FilaRegistro')
class Registros extends Table {
  TextColumn get id => text()();
  TextColumn get habitoId => text()();
  TextColumn get fecha => text()();
  BoolColumn get cumplido => boolean()();
  RealColumn get valor => real().nullable()();
  TextColumn get origen => text()();
  DateTimeColumn get registradoEn => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {habitoId, fecha},
  ];
}

/// Lo que falta enviar al servidor. Hoy solo check-ins (`tipo = 'registro'`); las señales se agregan en el Paso 10.
///
/// - `id`: el UUID que generó la app (el mismo del check-in): reenviarlo no duplica.
/// - `fecha`: la fecha **local original**; nunca se cambia por la del día en que se sincroniza.
/// - `rechazado`: el servidor lo rechazó (p. ej., hábito archivado); ya no se reintenta (contrato §6.5).
@DataClassName('FilaPendiente')
class ColaPendientes extends Table {
  TextColumn get id => text()();
  TextColumn get tipo => text().withDefault(const Constant('registro'))();
  TextColumn get habitoId => text()();
  TextColumn get fecha => text()();
  BoolColumn get cumplido => boolean()();
  RealColumn get valor => real().nullable()();
  DateTimeColumn get creadoEn => dateTime()();
  IntColumn get intentos => integer().withDefault(const Constant(0))();
  TextColumn get ultimoError => text().nullable()();
  BoolColumn get rechazado => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {tipo, habitoId, fecha},
  ];
}

/// Señales recientes de ánimo y energía (se usa desde el Paso 10).
@DataClassName('FilaSenal')
class Senales extends Table {
  TextColumn get fecha => text()();
  IntColumn get animo => integer()();
  IntColumn get energia => integer()();

  @override
  Set<Column> get primaryKey => {fecha};
}

/// Sugerencias recientes de la Escalera, como JSON del contrato (se usa desde el Paso 9).
@DataClassName('FilaSugerencia')
class Sugerencias extends Table {
  TextColumn get id => text()();
  TextColumn get datos => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cápsulas: solo metadatos y la ruta local de la foto. **Nunca el mensaje** (se usa desde el Paso 11).
@DataClassName('FilaCapsula')
class Capsulas extends Table {
  TextColumn get id => text()();
  TextColumn get habitoId => text()();
  IntColumn get rachaObjetivo => integer()();
  TextColumn get estado => text()();
  DateTimeColumn get creadaEn => dateTime()();
  TextColumn get rutaFoto => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Hora del recordatorio de cada hábito. Solo existe en el dispositivo.
@DataClassName('FilaRecordatorio')
class Recordatorios extends Table {
  TextColumn get habitoId => text()();
  IntColumn get hora => integer()();
  IntColumn get minuto => integer()();

  @override
  Set<Column> get primaryKey => {habitoId};
}

/// Marcas de la caché (`habitos_guardados` = ya se guardó la lista al menos una vez). Sin conexión, distingue "nunca
/// se cargó" (error) de "no hay hábitos" (lista vacía).
@DataClassName('FilaMarca')
class Marcas extends Table {
  TextColumn get clave => text()();
  TextColumn get valor => text()();

  @override
  Set<Column> get primaryKey => {clave};
}
