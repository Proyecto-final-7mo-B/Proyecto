import 'package:drift/drift.dart';
import 'package:drift/native.dart';

/// SQLite en memoria (se pierde al cerrar la app).
QueryExecutor ejecutorEnMemoria() => NativeDatabase.memory();
