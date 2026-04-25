import 'dart:async';

import 'package:flutter/foundation.dart';

import '../mixins/disposable_change_notifier_mixin.dart';
import '../models/trackers/device_code.dart';
import '../services/trackers/tracker_connect_runner.dart';
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
class TraktAccountProvider extends ChangeNotifier with DisposableChangeNotifierMixin {
  final TraktAuthService _auth = TraktAuthService();
  final _store = traktAccountStore;

  TraktSession? _session;
  String _activeUserUuid = '';
  bool _isConnecting = false;
  Completer<void>? _cancelCompleter;

  TraktSession? get session => _session;
  bool get isConnected => _session != null;
  String? get username => _session?.username;
  bool get isConnecting => _isConnecting;

  /// Cancel an in-flight `connect()` (e.g. user dismissed the device-code
  /// dialog). Completing the completer both wakes the blocking `Future.any`
  /// race and flips `isCompleted` for the next sync check.
  void cancelConnect() {
    final c = _cancelCompleter;
    if (c != null && !c.isCompleted) c.complete();
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
    if (_isConnecting || isConnected) return false;
    _isConnecting = true;
    _cancelCompleter = Completer<void>();
    notifyListeners();
    try {
      return await runConnectPipeline<TraktSession>(
        logLabel: 'Trakt',
        authorize: () => _auth.authorize(
          onCodeReady: onCodeReady,
          shouldCancel: () => _cancelCompleter?.isCompleted ?? false,
          onCancel: _cancelCompleter!.future,
        ),
        enrich: _enrichUsername,
        save: (s) => _store.save(_activeUserUuid, s),
        assign: _setSessionAndRebind,
      );
    } finally {
      final c = _cancelCompleter;
      if (c != null && !c.isCompleted) c.complete();
      _cancelCompleter = null;
      _isConnecting = false;
      safeNotifyListeners();
    }
  }

  Future<TraktSession> _enrichUsername(TraktSession raw) async {
    try {
      final tmp = TraktClient(raw, onSessionInvalidated: () {});
      final user = await tmp.getUserSettings();
      tmp.dispose();
      return raw.copyWith(username: user.username);
    } catch (e) {
      appLogger.d('Trakt: getUserSettings failed (non-fatal)', error: e);
      return raw;
    }
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
    safeNotifyListeners();
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
