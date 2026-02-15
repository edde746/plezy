/// Conditional export for dart:io types (File, Directory).
///
/// On native platforms, re-exports from dart:io.
/// On web, provides stub classes that compile but should never be
/// used at runtime (guarded by kIsWeb checks).
export 'io_helpers_native.dart' if (dart.library.js_interop) 'io_helpers_web.dart';
