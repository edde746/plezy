import 'dart:io';

import 'package:url_launcher/url_launcher.dart';

import 'app_logger.dart';

/// Opens [uri] in the system's external handler, with a Linux fallback.
///
/// On Linux, `url_launcher` opens URLs through GLib, which execs the
/// `gio-launch-desktop` helper. That helper is absent on some desktops (seen
/// on Fedora/KDE that don't pull in the GTK stack), so `launchUrl` throws
/// `Failed to execute child process "gio-launch-desktop"`. For the Plex PIN
/// sign-in that surfaced as an unrecoverable "Plex PIN auth failed" error
/// (#1477). When the primary launch fails on Linux, fall back to `xdg-open`,
/// which is desktop-agnostic and shipped by xdg-utils.
///
/// Returns `true` when either the primary launcher or the fallback reports the
/// URL was handled. On non-Linux platforms a thrown primary launch is
/// rethrown, matching `launchUrl`'s own contract; on Linux the throw is
/// swallowed in favour of the fallback.
///
/// The [launcher], [fallback] and [isLinuxOverride] parameters exist as
/// injection seams for tests; production callers pass a [uri] and, optionally,
/// a [mode].
Future<bool> launchExternalUrl(
  Uri uri, {
  LaunchMode mode = LaunchMode.externalApplication,
  UrlLauncher launcher = _launchViaUrlLauncher,
  FallbackLauncher fallback = _launchViaXdgOpen,
  bool? isLinuxOverride,
}) async {
  final isLinux = isLinuxOverride ?? Platform.isLinux;
  try {
    if (await launcher(uri, mode: mode)) return true;
    // launchUrl returned false rather than throwing (no handler); on Linux the
    // gio path may simply have declined, so still try xdg-open below.
  } catch (e, st) {
    appLogger.w('launchUrl failed for $uri', error: e, stackTrace: st);
    if (!isLinux) rethrow;
  }
  if (isLinux) return fallback(uri.toString());
  return false;
}

typedef UrlLauncher = Future<bool> Function(Uri uri, {LaunchMode mode});
typedef FallbackLauncher = Future<bool> Function(String url);

Future<bool> _launchViaUrlLauncher(Uri uri, {LaunchMode mode = LaunchMode.externalApplication}) {
  return launchUrl(uri, mode: mode);
}

Future<bool> _launchViaXdgOpen(String url) async {
  try {
    final result = await Process.start('xdg-open', [url], mode: ProcessStartMode.detached);
    appLogger.d('Launched xdg-open for $url with PID: ${result.pid}');
    return true;
  } catch (e) {
    appLogger.w('xdg-open fallback failed for $url', error: e);
    return false;
  }
}
