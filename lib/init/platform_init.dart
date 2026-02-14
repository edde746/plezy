/// Platform initialization with conditional imports.
///
/// Routes to native or web initialization based on the platform.
library;

export 'platform_init_native.dart'
    if (dart.library.js_interop) 'platform_init_web.dart';
