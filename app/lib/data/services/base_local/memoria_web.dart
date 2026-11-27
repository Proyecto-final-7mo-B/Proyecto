import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// En web no hay SQLite en memoria sin cargar antes el WebAssembly: se usa una base aparte para el modo *fake*.
QueryExecutor ejecutorEnMemoria() => driftDatabase(
  name: 'kaizen_demo',
  web: DriftWebOptions(sqlite3Wasm: Uri.parse('sqlite3.wasm'), driftWorker: Uri.parse('drift_worker.js')),
);
