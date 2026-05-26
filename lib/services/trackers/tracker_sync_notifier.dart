import 'package:flutter/foundation.dart';
import 'tracker_watch_state_provider.dart';
import 'watch_state_overlay.dart';

/// Generic tracker sync hub. Screens subscribe here for any tracker
/// sync/state-change notification without coupling to a specific tracker.
///
/// A tracker account provider (e.g. [TraktAccountProvider]) drives this by
/// calling [activateAuthority] on connect and [deactivateAuthority] on
/// disconnect. Adding a new tracker requires no screen-level changes.
class TrackerSyncNotifier extends ChangeNotifier {
  static final TrackerSyncNotifier instance = TrackerSyncNotifier._();
  TrackerSyncNotifier._();

  VoidCallback? _triggerPostPlaybackSync;
  Future<void> Function()? _forceSyncWatchState;
  Future<void> Function()? _syncIfStale;

  /// Register [provider] as the active watch-state authority and bind the
  /// tracker's sync-action callbacks. Call this from the tracker account
  /// provider when the user connects or re-enables watch-state authority.
  ///
  /// Activation flow: TrackerAccountProvider → TrackerSyncNotifier.activateAuthority
  /// → WatchStateOverlay.setActiveProvider → TrackerWatchStateProvider (see CLAUDE.md §Activation flow).
  ///
  /// Internally wires [WatchStateOverlay] so no tracker need import it directly.
  void activateAuthority(
    TrackerWatchStateProvider provider, {
    required VoidCallback triggerPostPlaybackSync,
    required Future<void> Function() forceSyncWatchState,
    required Future<void> Function() syncIfStale,
  }) {
    // Provider must be registered first so any listener that fires during
    // this synchronous call sees a valid overlay. The callback assignments
    // below are safe because Dart is single-threaded — no listener can run
    // between setActiveProvider and the end of this method.
    WatchStateOverlay.instance.setActiveProvider(provider);
    _triggerPostPlaybackSync = triggerPostPlaybackSync;
    _forceSyncWatchState = forceSyncWatchState;
    _syncIfStale = syncIfStale;
  }

  /// Clear the active watch-state authority and all action callbacks. Call this
  /// from the tracker account provider on disconnect or when the user disables
  /// watch-state authority.
  void deactivateAuthority() {
    WatchStateOverlay.instance.setActiveProvider(null);
    _triggerPostPlaybackSync = null;
    _forceSyncWatchState = null;
    _syncIfStale = null;
  }

  /// Called by the active tracker account provider after each sync or state
  /// change. Notifies all screen-level listeners.
  void notifySync() => notifyListeners();

  /// Fire-and-forget sync triggered 2 s after playback ends.
  void triggerPostPlaybackSync() => _triggerPostPlaybackSync?.call();

  /// Full re-sync, ignoring activity timestamps. Awaitable.
  Future<void> forceSyncWatchState() => _forceSyncWatchState?.call() ?? Future.value();

  /// Sync only when remote data has changed since last sync. Awaitable.
  Future<void> syncIfStale() => _syncIfStale?.call() ?? Future.value();
}
