// Fuente de web/drift_worker.js (el "worker" que abre la base local en web).
// Regenerar al cambiar la versión de drift:
//   dart compile js -O4 tool/drift_worker.dart -o web/drift_worker.js
import 'package:drift/wasm.dart';

void main() => WasmDatabase.workerMainForOpen();
