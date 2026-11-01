import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_logger.dart';

const _tvosBuild = bool.fromEnvironment('TVOS_BUILD');

/// The tvOS Runner has no url_launcher implementation; it hands URLs to other
/// apps itself on this channel (external players and Android's `openVideo`
/// share it).
const _tvosHandoffChannel = MethodChannel('com.plezy/external_player');

bool? _debugTvosRunnerOverride;

/// Whether this is the tvOS Runner. There is no browser on tvOS, so a URL can
/// only reach another installed app: web pages cannot be opened at all.
///
/// Keyed to the build rather than to TV detection, which tests also use to put
/// Android TV focus behaviour on screen, where links still open.
bool get isTvosRunner => _debugTvosRunnerOverride ?? _tvosBuild;

// ignore: unused-code
/// Test hook: puts the tvOS Runner's URL handling on screen without a tvOS build.
@visibleForTesting
set debugTvosRunnerOverride(bool? value) => _debugTvosRunnerOverride = value;

/// Asks the tvOS Runner whether an installed app handles [uri]. Schemes missing
/// from LSApplicationQueriesSchemes always answer false.
Future<bool> tvosCanOpenUrl(Uri uri) async {
  return await _tvosHandoffChannel.invokeMethod<bool>('canOpenUrl', {'url': uri.toString()}) ?? false;
}

/// Hands [uri] to whichever tvOS app handles it; false when none did.
Future<bool> tvosOpenUrl(Uri uri) async {
  return await _tvosHandoffChannel.invokeMethod<bool>('openUrl', {'url': uri.toString()}) ?? false;
}

/// Opens [uri] outside Plezy: through the tvOS Runner's handoff channel there,
/// url_launcher elsewhere. Returns false rather than throwing when nothing
/// opened it, so callers can tell the user instead of ignoring the press
/// (#2877).
Future<bool> openExternalUrl(Uri uri) async {
  try {
    if (isTvosRunner) return await tvosOpenUrl(uri);
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (error, stackTrace) {
    appLogger.w('Could not open an external URL', error: error, stackTrace: stackTrace);
    return false;
  }
}
