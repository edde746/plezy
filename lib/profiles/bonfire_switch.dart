import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;

import '../connection/connection.dart';
import '../i18n/strings.g.dart';
import '../utils/app_logger.dart';
import '../utils/media_server_http_client.dart';
import '../utils/media_server_timeouts.dart';
import 'bonfire_service.dart';
import 'profile_connection.dart';
import 'profile_connection_registry.dart';

/// Outcome of a Bonfire `POST /plugins/profiles/switch` attempt. [authRejected]
/// means the server answered HTTP 401 to the CALLER's token — per the plugin's
/// own contract every target-side failure arrives as a 400 with a reason, so a
/// 401 always means the parent connection's token expired or was revoked.
enum BonfireSwitchStatus { success, cancelled, failed, authRejected }

class BonfireSwitchResult {
  final BonfireSwitchStatus status;
  final String? userToken;

  /// Plugin-supplied reason for a failure (the 400 body carries it), for the
  /// UI to surface verbatim.
  final String? message;

  const BonfireSwitchResult._(this.status, this.userToken, this.message);

  bool get succeeded => status == BonfireSwitchStatus.success;
}

/// Callback that prompts the user for a Bonfire profile PIN during a single
/// `/plugins/profiles/switch` round-trip. Returns the PIN string, or `null`
/// if the user cancelled.
typedef BonfireSwitchPinPrompt = Future<String?> Function({String? errorMessage});

/// Switch into [profileId] under the household authenticated by
/// [parentConnection]'s token, looping on the plugin's "incorrect PIN" 400.
/// Returns the freshly minted scoped profile session token.
///
/// Pass [requiresPin] = true when the profile's live `/list` entry says so
/// (the plugin already folds in LAN bypass); otherwise the call is attempted
/// without a PIN first and the loop only kicks in if the server 400s with a
/// PIN-shaped reason anyway.
///
/// Mirrors [switchPlexHomeUserWithPin]: used by [ActiveProfileBinder] (minting
/// a missing profile token on activation) and by the activation pre-verify.
Future<BonfireSwitchResult> switchBonfireUserWithPin({
  required JellyfinConnection parentConnection,
  required String profileId,
  required bool requiresPin,
  required BonfireSwitchPinPrompt promptForPin,
  String? logLabel,
  @visibleForTesting http.Client? testClient,
}) async {
  final authHeader = await bonfireMasterAuthHeader(parentConnection);
  final client = MediaServerHttpClient(
    baseUrl: parentConnection.baseUrl,
    defaultHeaders: {
      'Authorization': authHeader,
      'X-Emby-Token': parentConnection.accessToken,
      'Content-Type': 'application/json',
    },
    client: testClient,
  );
  String? pin;
  String? error;
  try {
    while (true) {
      if (requiresPin) {
        pin = await promptForPin(errorMessage: error);
        if (pin == null) return const BonfireSwitchResult._(BonfireSwitchStatus.cancelled, null, null);
      }
      final response = await client.post(
        '/plugins/profiles/switch',
        body: <String, Object?>{'profileId': profileId, if (pin != null && pin.isNotEmpty) 'pin': pin},
        timeout: MediaServerTimeouts.jellyfinProbe,
      );
      switch (response.statusCode) {
        case 200:
          final data = response.data;
          // Jellyfin 12 serializes PascalCase (`ActiveProfileToken`); older
          // shapes and the docs show camelCase. Accept either.
          final token = data is Map
              ? (data['activeProfileToken'] ?? data['ActiveProfileToken'])?.toString()
              : null;
          if (token == null || token.isEmpty) {
            appLogger.e('switchBonfireUserWithPin: 200 without activeProfileToken${logLabel == null ? '' : ' for $logLabel'}');
            return const BonfireSwitchResult._(BonfireSwitchStatus.failed, null, null);
          }
          return BonfireSwitchResult._(BonfireSwitchStatus.success, token, null);
        case 400:
          final reason = _failureReason(response.data);
          // The body carries the reason. Only a PIN-shaped 400 is retryable;
          // device restrictions / unprotected masters are final.
          if (pin == null || _looksLikePinFailure(reason)) {
            error = t.profiles.incorrectPinTryAgain;
            pin = null;
            // Force the next iteration to prompt even when the caller didn't
            // expect a PIN — the plugin disagrees about whether one is needed.
            requiresPin = true;
            continue;
          }
          return BonfireSwitchResult._(BonfireSwitchStatus.failed, null, reason);
        case 401:
          // About the caller's own token, never the target (plugin contract).
          return const BonfireSwitchResult._(BonfireSwitchStatus.authRejected, null, null);
        case 429:
          return const BonfireSwitchResult._(
            BonfireSwitchStatus.failed,
            null,
            'Too many attempts — try again in a few minutes.',
          );
        default:
          appLogger.w(
            'switchBonfireUserWithPin got ${response.statusCode}${logLabel == null ? '' : ' for $logLabel'}',
          );
          return BonfireSwitchResult._(BonfireSwitchStatus.failed, null, _failureReason(response.data));
      }
    }
  } catch (e, st) {
    appLogger.e(
      'switchBonfireUserWithPin failed${logLabel == null ? '' : ' for $logLabel'}',
      error: e,
      stackTrace: st,
    );
    return const BonfireSwitchResult._(BonfireSwitchStatus.failed, null, null);
  } finally {
    client.close();
  }
}

/// One-shot UI-side mint of a Bonfire profile token: run
/// [switchBonfireUserWithPin] against [parentConnection], optionally persist
/// the minted token as the ([persistProfileId], connection) [ProfileConnection]
/// row, and dispose the client. Activation pre-verify uses this so the binder
/// then binds with the token the user just authenticated as.
Future<BonfireSwitchResult> mintBonfireProfileToken({
  required JellyfinConnection parentConnection,
  required String profileId,
  required bool requiresPin,
  required BonfireSwitchPinPrompt promptForPin,
  ProfileConnectionRegistry? persistTo,
  String? persistProfileId,
  String? logLabel,
}) async {
  assert((persistTo == null) == (persistProfileId == null), 'persistTo and persistProfileId go together');
  final result = await switchBonfireUserWithPin(
    parentConnection: parentConnection,
    profileId: profileId,
    requiresPin: requiresPin,
    promptForPin: promptForPin,
    logLabel: logLabel,
  );
  if (result.succeeded && persistTo != null && persistProfileId != null) {
    await persistTo.upsert(
      ProfileConnection(
        profileId: persistProfileId,
        connectionId: parentConnection.id,
        userToken: result.userToken,
        userIdentifier: profileId,
        tokenAcquiredAt: DateTime.now(),
      ),
    );
  }
  return result;
}

String _failureReason(Object? data) {
  if (data is Map) {
    for (final key in ['message', 'error', 'detail', 'Description']) {
      final value = data[key];
      if (value != null && value.toString().isNotEmpty) return value.toString();
    }
    return data.toString();
  }
  if (data == null) return '';
  final text = data.toString();
  return text.length > 240 ? '${text.substring(0, 240)}…' : text;
}

bool _looksLikePinFailure(String reason) => reason.toLowerCase().contains('pin');
