/// Conditional export for process info (memory usage).
///
/// On native platforms, uses dart:io ProcessInfo.
/// On web, returns 0 (not available).
export 'process_info_helper_native.dart'
    if (dart.library.js_interop) 'process_info_helper_web.dart';
