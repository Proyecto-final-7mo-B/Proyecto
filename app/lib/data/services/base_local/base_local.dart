import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'memoria.dart';
import 'tablas.dart';

export 'tablas.dart';

part 'base_local.g.dart';

/// Base local de la app (SQLite con drift): la misma en las 6 plataformas; en web corre sobre WebAssembly
/// (`web/sqlite3.wasm` y `web/drift_worker.js`).
@DriftDatabase(
  tables: [Habitos, Categorias, Registros, ColaPendientes, Senales, Sugerencias, Capsulas, Recordatorios, Marcas],
)
class BaseLocal extends _$BaseLocal {
  BaseLocal(super.e);

  /// El archivo `kaizen.sqlite` en la carpeta privada de la app (en web, en el almacenamiento del navegador).
  factory BaseLocal.abrir() => BaseLocal(
    driftDatabase(
      name: 'kaizen',
      web: DriftWebOptions(sqlite3Wasm: Uri.parse('sqlite3.wasm'), driftWorker: Uri.parse('drift_worker.js')),
    ),
  );

  /// En memoria: pruebas y modo *fake* (en web, una base aparte del navegador).
  factory BaseLocal.enMemoria() => BaseLocal(ejecutorEnMemoria());

  /// Versión del esquema. Cada cambio de tablas la sube y agrega su paso en [migration].
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, de, a) async {
      // Aún no hay versiones anteriores. Ejemplo para la v2: if (de < 2) await m.createTable(nuevaTabla);
    },
  );

  /// Al cerrar sesión: no deben quedar datos de una cuenta para la siguiente (y en web así lo pide el diseño).
  Future<void> borrarTodo() => transaction(() async {
    for (final tabla in allTables) {
      await delete(tabla).go();
    }
  });
}
