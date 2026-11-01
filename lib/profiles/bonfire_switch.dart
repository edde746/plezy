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

/// Check a previously minted scoped session token for [profileUserId] is
/// still live before resuming it. Bonfire child tokens die when the master
/// session re-authenticates (e.g. a Quick Connect re-login), and binding a
/// dead token cold-starts the whole app offline until a manual reconnect.
/// Only an HTTP answer against the token itself counts as invalid: transport
/// failures keep the token so an offline cold start doesn't force a PIN
/// re-mint.
Future<bool> bonfireProfileTokenStillValid(
  JellyfinConnection parentConnection,
  String profileUserId,
  String profileToken, {
  @visibleForTesting http.Client? testClient,
}) async {
  final client = MediaServerHttpClient(
    baseUrl: parentConnection.baseUrl,
    defaultHeaders: {'Authorization': 'MediaBrowser Token="$profileToken"', 'X-Emby-Token': profileToken},
    client: testClient,
  );
  try {
    final response = await client.get('/Users/$profileUserId/Views', timeout: MediaServerTimeouts.jellyfinProbe);
    return response.statusCode == 200;
  } catch (e) {
    appLogger.w('bonfireProfileTokenStillValid: probe failed ($e) — keeping token');
    return true;
  } finally {
    client.close();
  }
}

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
  final labelSuffix = logLabel == null ? '' : ' for $logLabel';
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
          final token = data is Map ? (data['activeProfileToken'] ?? data['ActiveProfileToken'])?.toString() : null;
          if (token == null || token.isEmpty) {
            appLogger.e('switchBonfireUserWithPin: 200 without activeProfileToken$labelSuffix');
            return const BonfireSwitchResult._(BonfireSwitchStatus.failed, null, null);
          }
          return BonfireSwitchResult._(BonfireSwitchStatus.success, token, null);
        case 400:
          final reason = _failureReason(response.data);
          // The body carries the reason. Only a PIN-shaped 400 is retryable:
          // Bonfire answers "Invalid PIN"/"PIN required" here, and those get
          // a prompt (or a re-prompt when the entered PIN was wrong). Any
          // other 400 — profile not found, device restrictions — is final,
          // exactly like switchPlexHomeUserWithPin treats them.
          if (!_looksLikePinFailure(reason)) {
            return BonfireSwitchResult._(BonfireSwitchStatus.failed, null, reason);
          }
          error = pin != null ? t.profiles.incorrectPinTryAgain : reason;
          pin = null;
          // Force the next iteration to prompt even when the caller didn't
          // expect a PIN — the plugin disagrees about whether one is needed.
          requiresPin = true;
          continue;
        case 401:
          // About the caller's own token, never the target (plugin contract).
          return const BonfireSwitchResult._(BonfireSwitchStatus.authRejected, null, null);
        case 429:
          return BonfireSwitchResult._(BonfireSwitchStatus.failed, null, t.profiles.bonfireRateLimited);
        default:
          appLogger.w('switchBonfireUserWithPin got ${response.statusCode}$labelSuffix');
          return BonfireSwitchResult._(BonfireSwitchStatus.failed, null, _failureReason(response.data));
      }
    }
  } catch (e, st) {
    appLogger.e('switchBonfireUserWithPin failed$labelSuffix', error: e, stackTrace: st);
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
  @visibleForTesting http.Client? testClient,
}) async {
  assert((persistTo == null) == (persistProfileId == null), 'persistTo and persistProfileId go together');
  final result = await switchBonfireUserWithPin(
    parentConnection: parentConnection,
    profileId: profileId,
    requiresPin: requiresPin,
    promptForPin: promptForPin,
    logLabel: logLabel,
    testClient: testClient,
  );
  if (result.succeeded && persistTo != null && persistProfileId != null) {
    await persistTo.upsert(
      ProfileConnection(
        profileId: persistProfileId,
        // profile_connections.connectionId has an FK to the persisted
        // connections row — and fresh installs key Jellyfin rows by the
        // compound machineId/userId id, not the bare machine id. The Bonfire
        // PROFILE id carries the canonical machine id (stable across
        // re-binds); the join row must carry the connection's real row id or
        // every Bonfire join row throws FOREIGN KEY constraint failed.
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

/// Word-shaped match so unrelated wording that merely contains the
/// letters ("pinned", "spine") doesn't masquerade as a PIN problem.
bool _looksLikePinFailure(String reason) => RegExp(r'\bpin\b', caseSensitive: false).hasMatch(reason);
