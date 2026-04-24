import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/trackers/device_code.dart';
import '../services/trakt/trakt_account_store.dart';
import '../services/trakt/trakt_auth_service.dart';
import '../services/trakt/trakt_client.dart';
import '../services/trakt/trakt_scrobble_service.dart';
import '../services/trakt/trakt_session.dart';
import '../services/trakt/trakt_sync_service.dart';
import '../utils/app_logger.dart';

/// Owns the active Trakt session for the currently-selected Plex profile.
///
/// Single rebind seam: `onActiveProfileChanged` loads the new profile's
/// session and pushes it to both `TraktScrobbleService` and `TraktSyncService`.
class TraktAccountProvider extends ChangeNotifier {
  final TraktAuthService _auth = TraktAuthService();
  final _store = traktAccountStore;

  TraktSession? _session;
  String _activeUserUuid = '';
  bool _isConnecting = false;
  bool _cancelRequested = false;

  TraktSession? get session => _session;
  bool get isConnected => _session != null;
  String? get username => _session?.username;
  bool get isConnecting => _isConnecting;

  /// Cancel an in-flight `connect()` (e.g. user dismissed the device-code
  /// dialog). The poll loop checks this flag between iterations.
  void cancelConnect() {
    _cancelRequested = true;
  }

  /// Called whenever the active Plex profile changes (or on initial load).
  Future<void> onActiveProfileChanged(String? newUserUuid) async {
    _activeUserUuid = newUserUuid ?? '';
    final loaded = await _store.load(_activeUserUuid);
    _setSessionAndRebind(loaded);
  }

  /// Run the device-code OAuth flow.
  ///
  /// [onCodeReady] is invoked once with the user code + verification URL so
  /// the UI can render the dialog.
  Future<bool> connect({required void Function(DeviceCode code) onCodeReady}) async {
    if (_isConnecting) return false;
    _isConnecting = true;
    _cancelRequested = false;
    notifyListeners();

    try {
      final code = await _auth.createDeviceCode();
      onCodeReady(code);

      await for (final event in _auth.pollDeviceCode(code, shouldCancel: () => _cancelRequested)) {
        if (event is DevicePollSuccess) {
          await _completeConnect(event.tokenResponse);
          return true;
        }
        if (event is DevicePollDenied || event is DevicePollExpired) {
          return false;
        }
      }
      return false;
    } catch (e) {
      appLogger.w('Trakt connect failed', error: e);
      return false;
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> _completeConnect(Map<String, dynamic> tokenResponse) async {
    final raw = TraktSession.fromTokenResponse(tokenResponse);
    // Best-effort fetch of the username for display.
    TraktSession enriched = raw;
    try {
      final tmpClient = TraktClient(raw, onSessionInvalidated: () {});
      final user = await tmpClient.getUserSettings();
      enriched = raw.copyWith(username: user.username);
      tmpClient.dispose();
    } catch (e) {
      appLogger.d('Trakt: getUserSettings failed (non-fatal)', error: e);
    }

    await _store.save(_activeUserUuid, enriched);
    _setSessionAndRebind(enriched);
  }

  /// Revoke the access token and clear local state.
  Future<void> disconnect() async {
    final session = _session;
    if (session != null) {
      final client = TraktClient(session, onSessionInvalidated: () {});
      await client.revoke();
      client.dispose();
    }
    await _store.clear(_activeUserUuid);
    _setSessionAndRebind(null);
  }

  void _setSessionAndRebind(TraktSession? session) {
    _session = session;
    TraktScrobbleService.instance.rebindToProfile(session, onSessionInvalidated: _handleSessionInvalidated);
    TraktSyncService.instance.rebindToProfile(
      _activeUserUuid,
      session,
      onSessionInvalidated: _handleSessionInvalidated,
    );
    notifyListeners();
  }

  /// Called by [TraktClient] when refresh fails permanently. Clears local state
  /// so the UI shows "not connected" and the user can re-link.
  void _handleSessionInvalidated() {
    _store.clear(_activeUserUuid);
    _setSessionAndRebind(null);
  }

  @override
  void dispose() {
    _auth.dispose();
    super.dispose();
  }
}
