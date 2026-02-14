/// Platform abstraction layer that works on both native and web.
///
/// On native platforms, delegates to `dart:io` Platform.
/// On web, provides webOS detection and sensible defaults.
///
/// Usage: Replace all `import 'dart:io' show Platform;` with
/// `import 'package:plezy/utils/platform_helper.dart';`
/// Then use `AppPlatform.isAndroid` etc. instead of `Platform.isAndroid`.
library;

export 'platform_helper_impl.dart';
