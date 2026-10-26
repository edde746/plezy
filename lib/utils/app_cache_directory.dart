import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'platform_detector.dart';

/// Returns an app-private cache location supported by the active platform.
///
/// LG's pinned webOS path-provider implementation exposes the temporary and
/// application-support directories, but not `getApplicationCacheDirectory`.
/// Its temporary directory is scoped by app ID and is suitable for disposable
/// artwork and shader caches.
Future<Directory> getPlezyAppCacheDirectory() =>
    PlatformDetector.isWebOSBuild() ? getTemporaryDirectory() : getApplicationCacheDirectory();
