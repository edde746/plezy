import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app_logger.dart';

/// The running build's version, as the platform's package metadata reports
/// it. The only place the app reads it.
///
/// Either part is null when the platform can't report it. On Linux,
/// `package_info_plus` reads `data/flutter_assets/version.json` beside the
/// executable, which a distro package that splits the bundle across
/// `/usr/bin`, `/usr/lib` and `/usr/share` doesn't keep. On Windows the
/// version-resource read throws on a UNC launch or antivirus interception.
final class AppVersion {
  const AppVersion._({required this.version, required this.buildNumber});

  /// Stands in for a part the platform can't report wherever a value is
  /// required: a client identity on the wire, a diagnostics label.
  static const String unknown = 'unknown';

  /// The release version, such as `2.26.0`.
  final String? version;

  /// The build number, such as `160`.
  final String? buildNumber;

  /// [version] for an identity that requires one (`X-Plex-Version`, the
  /// MediaBrowser `Version`, Simkl's `app-version`, the Open Watch Party
  /// `client`), or [unknown]. Open Watch Party refuses a `client` with
  /// nothing after its `/`.
  String get versionOrUnknown => version ?? unknown;

  /// `version+buildNumber` for diagnostics; a part the platform can't report
  /// reads [unknown].
  String get label => '$versionOrUnknown+${buildNumber ?? unknown}';

  static AppVersion? _current;

  /// The running build's version, read once per process. Never throws.
  ///
  /// Concurrent first calls each read rather than share one future: a shared
  /// future completes in the zone of whichever caller started it, which a
  /// `fakeAsync` test may already have left.
  static Future<AppVersion> current() async => _current ??= await read();

  /// Reads the version from [load], uncached, logging when it is unknown.
  @visibleForTesting
  static Future<AppVersion> read([Future<PackageInfo> Function() load = PackageInfo.fromPlatform]) async {
    PackageInfo? info;
    Object? failure;
    StackTrace? failureStack;
    try {
      info = await load();
    } catch (error, stackTrace) {
      failure = error;
      failureStack = stackTrace;
    }
    final appVersion = AppVersion._(version: _reported(info?.version), buildNumber: _reported(info?.buildNumber));
    if (appVersion.version == null) {
      appLogger.w(
        'App version unavailable from package metadata; identifying as "$unknown"',
        error: failure,
        stackTrace: failureStack,
      );
    }
    return appVersion;
  }

  @visibleForTesting
  static void resetForTesting() => _current = null;

  static String? _reported(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
