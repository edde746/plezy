import 'dart:async';

import 'package:flutter/foundation.dart';

import '../mixins/disposable_change_notifier_mixin.dart';
import '../models/trackers/device_code.dart';
import '../services/trackers/tracker_account_store.dart';
import '../services/trackers/tracker_connect_runner.dart';
import '../services/trackers/tracker_constants.dart';
import '../services/trackers/tracker_session.dart';
import '../services/trakt/trakt_auth_service.dart';
import '../services/trakt/trakt_client.dart';
import '../services/trakt/trakt_scrobble_service.dart';
import '../services/trakt/trakt_sync_service.dart';
import '../utils/app_logger.dart';

/// Owns the active Trakt session for the currently-selected Plex profile.
///
/// Single rebind seam: `onActiveProfileChanged` loads the new profile's
/// session and pushes it to both `TraktScrobbleService` and `TraktSyncService`.
class TraktAccountProvider extends ChangeNotifier with DisposableChangeNotifierMixin {
  final TraktAuthService _auth = TraktAuthService();
  final TrackerAccountStore _store = trackerAccountStore(TrackerService.trakt);

  TrackerSession? _session;
  String _activeUserUuid = '';
  int _bindingGeneration = 0;
  bool _isConnecting = false;
  Completer<void>? _cancelCompleter;

  TrackerSession? get session => _session;
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
    if (isDisposed) return;
    final userUuid = newUserUuid ?? '';
    final generation = ++_bindingGeneration;
    _activeUserUuid = userUuid;
    final loaded = await _store.load(userUuid);
    _setSessionAndRebind(userUuid, generation, loaded);
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
      return await runConnectPipeline<TrackerSession>(
        logLabel: 'Trakt',
        authorize: () => _auth.authorize(
          onCodeReady: onCodeReady,
          shouldCancel: () => _cancelCompleter?.isCompleted ?? false,
          onCancel: _cancelCompleter!.future,
        ),
        enrich: _enrichUsername,
        save: (s) => _store.save(_activeUserUuid, s),
        assign: _bindCurrentSession,
      );
    } finally {
      final c = _cancelCompleter;
      if (c != null && !c.isCompleted) c.complete();
      _cancelCompleter = null;
      _isConnecting = false;
      safeNotifyListeners();
    }
  }

  Future<TrackerSession> _enrichUsername(TrackerSession raw) async {
    TraktClient? tmp;
    try {
      tmp = TraktClient(raw, onSessionInvalidated: () {});
      final user = await tmp.getUserSettings();
      return raw.copyWith(username: user.username);
    } catch (e) {
      appLogger.d('Trakt: getUserSettings failed (non-fatal)', error: e);
      return raw;
    } finally {
      tmp?.dispose();
    }
  }

  /// Revoke the access token and clear local state.
  Future<void> disconnect() async {
    final userUuid = _activeUserUuid;
    final generation = ++_bindingGeneration;
    final session = _session;
    _setSessionAndRebind(userUuid, generation, null);
    if (session != null) {
      final client = TraktClient(session, onSessionInvalidated: () {});
      try {
        await client.revoke();
      } finally {
        client.dispose();
      }
    }
    await _store.clear(userUuid);
  }

  void _bindCurrentSession(TrackerSession? session) {
    _setSessionAndRebind(_activeUserUuid, ++_bindingGeneration, session);
  }

  void _setSessionAndRebind(String userUuid, int generation, TrackerSession? session) {
    if (!_isCurrentBinding(userUuid, generation)) return;
    _session = session;

    void handleInvalidated() => _handleSessionInvalidated(userUuid, generation);
    void handleUpdated(TrackerSession next) => _handleSessionUpdated(userUuid, generation, next);

    TraktScrobbleService.instance.rebindToProfile(
      session,
      onSessionInvalidated: handleInvalidated,
      onSessionUpdated: handleUpdated,
    );
    TraktSyncService.instance.rebindToProfile(
      userUuid,
      session,
      onSessionInvalidated: handleInvalidated,
      onSessionUpdated: handleUpdated,
    );
    safeNotifyListeners();
  }

  bool _isCurrentBinding(String userUuid, int generation) {
    return !isDisposed && userUuid == _activeUserUuid && generation == _bindingGeneration;
  }

  void _handleSessionUpdated(String userUuid, int generation, TrackerSession session) {
    if (!_isCurrentBinding(userUuid, generation)) return;
    _session = session;
    TraktScrobbleService.instance.updateSession(session);
    TraktSyncService.instance.updateSession(session);
    unawaited(_store.save(userUuid, session));
    safeNotifyListeners();
  }

  /// Called by [TraktClient] when refresh fails permanently. Clears local state
  /// so the UI shows "not connected" and the user can re-link.
  void _handleSessionInvalidated(String userUuid, int generation) {
    if (!_isCurrentBinding(userUuid, generation)) return;
    final nextGeneration = ++_bindingGeneration;
    unawaited(_store.clear(userUuid));
    _setSessionAndRebind(userUuid, nextGeneration, null);
  }

  @visibleForTesting
  int get debugBindingGenerationForTesting => _bindingGeneration;

  @visibleForTesting
  void debugHandleSessionUpdatedForTesting(String userUuid, int generation, TrackerSession session) {
    _handleSessionUpdated(userUuid, generation, session);
  }

  @visibleForTesting
  void debugHandleSessionInvalidatedForTesting(String userUuid, int generation) {
    _handleSessionInvalidated(userUuid, generation);
  }

  @override
  void dispose() {
    _auth.dispose();
    super.dispose();
  }
}
