import 'dart:async';

import 'package:flutter/foundation.dart';

import '../mixins/disposable_change_notifier_mixin.dart';
import '../models/trackers/device_code.dart';
import '../services/trackers/tracker_connect_runner.dart';
import '../services/trackers/tracker_constants.dart';
import '../services/trakt/trakt_account_store.dart';
import '../services/trakt/trakt_auth_service.dart';
import '../services/trakt/trakt_client.dart';
import '../services/trakt/trakt_scrobble_service.dart';
import '../services/trakt/trakt_session.dart';
import '../services/trakt/trakt_sync_service.dart';
import '../services/trakt/trakt_watch_state_provider.dart';
import '../services/settings_service.dart';
import '../services/trackers/tracker_sync_notifier.dart';
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
    appLogger.d('TraktAccountProvider: active profile changed to $newUserUuid');
    _activeUserUuid = newUserUuid ?? '';
    final loaded = await _store.load(_activeUserUuid);
    appLogger.d(
      'TraktAccountProvider: loaded session for $_activeUserUuid: ${loaded != null ? "connected" : "disconnected"}',
    );
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
    final session = _session;
    if (session != null) {
      final client = TraktClient(session, onSessionInvalidated: () {});
      try {
        await client.revoke();
      } finally {
        client.dispose();
      }
    }
    await _store.clear(_activeUserUuid);
    _setSessionAndRebind(null);
  }

  void _setSessionAndRebind(TraktSession? session) {
    _session = session;
    // Scrobble service
    TraktScrobbleService.instance.rebindToProfile(session, onSessionInvalidated: _handleSessionInvalidated);
    // Sync service
    TraktSyncService.instance.rebindToProfile(
      _activeUserUuid,
      session,
      onSessionInvalidated: _handleSessionInvalidated,
    );
    // After each successful history-add, trigger a lightweight playback refresh
    // so the next episode appears in Continue Watching without waiting for the
    // next app-launch sync.
    TraktSyncService.instance.setOnHistoryAdded(
      session != null ? TraktWatchStateProvider.instance.schedulePlaybackRefresh : null,
    );
    // After offline reconnect progress push, refresh playback cache so Continue
    // Watching reflects the offline position without waiting for the next full sync.
    TraktSyncService.instance.setOnProgressPushed(
      session != null ? TraktWatchStateProvider.instance.schedulePlaybackRefresh : null,
    );
    // After scrobble stop, stamp the local playback cache with paused_at = now
    // so the 2-second post-playback sync always sees the correct episode as most
    // recently paused — even if Trakt's server hasn't processed the stop yet.
    TraktScrobbleService.instance.setOnPlaybackStopped(
      session != null ? TraktWatchStateProvider.instance.touchPlaybackEntryByIds : null,
    );
    // Bind the watch-state provider. The future resolves once the in-memory
    // caches reflect the new profile; authority activation chains off it so
    // the overlay is never re-activated while the prior profile's caches are
    // still in memory.
    final bindFuture = TraktWatchStateProvider.instance.bindSession(
      session,
      userUuid: _activeUserUuid,
      onSessionInvalidated: _handleSessionInvalidated,
    );
    // Whenever enrichment adds a new Plex show to the bridge map, notify
    // listeners so Continue Watching thumbnails update without waiting for the
    // next full sync cycle.
    TraktWatchStateProvider.instance.setOnBridgeMapUpdated(session != null ? safeNotifyListeners : null);
    // Register background ID fetcher so movies with missing Plex Guid arrays
    // can still be matched against Trakt after a one-shot async resolve.
    TraktWatchStateProvider.instance.setExternalIdsFetcher(
      session != null
          ? (plexKey, serverId) => TraktSyncService.instance.resolveMovieIds(plexKey, serverId)
          : null,
    );
    if (session != null) {
      // Connected: activation must wait for bindSession's in-memory reset
      // (profile switch) to complete; then load cached data and sync.
      // safeNotifyListeners() at the bottom of this method already notifies
      // session-state subscribers — the post-sync notification only fans out
      // to TrackerSyncAware screens so they re-apply the now-fresh overlay.
      unawaited(bindFuture
          .then((_) {
            _applyWatchStateAuthority();
            return TraktWatchStateProvider.instance.loadFromCache();
          })
          .then((_) => TraktWatchStateProvider.instance.syncWatchState())
          .then((_) => TrackerSyncNotifier.instance.notifySync())
          .catchError((Object e) {
            appLogger.w('TraktWatchState: bind/sync chain failed', error: e);
          }));
    } else {
      // Disconnected: deactivate immediately so the overlay stops serving
      // any data. bindSession's disk wipe runs in the background.
      unawaited(bindFuture.catchError((Object e) {
        appLogger.w('TraktWatchStateProvider: bindSession(null) failed', error: e);
      }));
      TrackerSyncNotifier.instance.deactivateAuthority();
      TrackerSyncNotifier.instance.notifySync();
    }
    safeNotifyListeners();
  }

  void setWatchStateAuthorityEnabled(bool enabled) {
    _setWatchStateAuthority(enabled);
    safeNotifyListeners();
  }

  void _applyWatchStateAuthority() {
    final enabled = SettingsService.instanceOrNull?.read(SettingsService.trackerStateAuthority) == TrackerService.trakt.name;
    _setWatchStateAuthority(enabled);
  }

  void _setWatchStateAuthority(bool enabled) {
    if (enabled && _session != null) {
      TrackerSyncNotifier.instance.activateAuthority(
        TraktWatchStateProvider.instance,
        triggerPostPlaybackSync: triggerPostPlaybackSync,
        forceSyncWatchState: forceSyncWatchState,
        syncIfStale: syncIfStale,
      );
    } else {
      TrackerSyncNotifier.instance.deactivateAuthority();
    }
  }

  /// Refresh the local Trakt watch state cache after playback ends so
  /// Continue Watching and library badges update without waiting for the
  /// next app launch. Fire-and-forget — never blocks the caller.
  void triggerPostPlaybackSync() {
    if (!isConnected) return;
    unawaited(
      TraktWatchStateProvider.instance
          // force=true bypasses the last_activities timestamp check — Trakt's
          // server may not have updated it within the 2-second delay window,
          // so we must always re-fetch /sync/playback after a watch session.
          .syncWatchState(force: true)
          .then((_) {
            TrackerSyncNotifier.instance.notifySync();
            safeNotifyListeners();
          })
          .catchError((Object e) {
            appLogger.d('Trakt: post-playback sync failed (non-critical)', error: e);
          }),
    );
  }

  /// Sync Trakt watch state if remote data has changed since last sync.
  /// Uses the last_activities check — cheap when nothing changed externally,
  /// full re-sync when the user made changes on another device or the website.
  Future<void> syncIfStale() async {
    if (!isConnected) return;
    try {
      await TraktWatchStateProvider.instance.syncWatchState(force: false);
    } catch (e) {
      appLogger.d('Trakt: stale-check sync failed (non-critical)', error: e);
    }
  }

  /// Manually trigger a full sync from Trakt, ignoring activity timestamps.
  Future<void> forceSyncWatchState() async {
    await TraktWatchStateProvider.instance.syncWatchState(force: true);
    notifyListeners();
    TrackerSyncNotifier.instance.notifySync();
  }

  /// Clear all cached Trakt watch state (in-memory and persistent).
  Future<void> invalidateWatchStateCache() async {
    await TraktWatchStateProvider.instance.invalidateCache();
    notifyListeners();
  }

  /// Called by [TraktClient] when refresh fails permanently. Clears local state
  /// so the UI shows "not connected" and the user can re-link.
  Future<void> _handleSessionInvalidated() async {
    await _store.clear(_activeUserUuid);
    _setSessionAndRebind(null);
  }

  @override
  void dispose() {
    _auth.dispose();
    super.dispose();
  }
}
