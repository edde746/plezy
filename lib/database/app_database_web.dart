/// Web implementation of database connection using Drift's web support.
///
/// Uses IndexedDB (via sql.js WASM) for persistent storage on webOS/web.
library;

import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Opens a web-compatible database connection using IndexedDB.
QueryExecutor openWebConnection() {
  return LazyDatabase(() async {
    final result = await WasmDatabase.open(
      databaseName: 'plezy_db',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.dart.js'),
    );
    return result.resolvedExecutor;
  });
}
