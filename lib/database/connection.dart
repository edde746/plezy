/// Database connection factory using conditional imports.
///
/// Selects the appropriate database backend:
/// - Native platforms: SQLite file via drift/native.dart
/// - Web platforms: IndexedDB via drift/wasm.dart
library;

import 'package:drift/drift.dart';

import 'connection_native.dart'
    if (dart.library.js_interop) 'connection_web.dart' as impl;

/// Opens a platform-appropriate database connection.
QueryExecutor openPlatformConnection() {
  return impl.openDatabaseConnection();
}
