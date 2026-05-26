import 'package:flutter/material.dart';
import '../media/media_item.dart';
import '../services/trackers/tracker_sync_notifier.dart';
import '../services/trackers/watch_state_overlay.dart';

/// Mixin for screens that need to react to tracker authority sync events
/// (e.g. Trakt re-sync after playback).
///
/// Handles [TrackerSyncNotifier] subscription lifecycle automatically.
/// Override [onTrackerSyncChanged] to respond to sync notifications.
/// Use [hasTrackerAuthority], [applyOverlay], and [applyOverlayAll] to
/// re-apply the active tracker's watch state without importing [WatchStateOverlay].
mixin TrackerSyncAware<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    TrackerSyncNotifier.instance.addListener(_handleTrackerSync);
  }

  @override
  void dispose() {
    TrackerSyncNotifier.instance.removeListener(_handleTrackerSync);
    super.dispose();
  }

  void _handleTrackerSync() {
    if (!mounted) return;
    onTrackerSyncChanged();
  }

  /// Whether a tracker authority is currently active.
  bool get hasTrackerAuthority => WatchStateOverlay.instance.hasActiveAuthority;

  /// Re-applies the active tracker overlay to a single item.
  MediaItem applyOverlay(MediaItem item) => WatchStateOverlay.instance.apply(item);

  /// Re-applies the active tracker overlay to a list of items.
  List<MediaItem> applyOverlayAll(List<MediaItem> items) =>
      WatchStateOverlay.instance.applyAll(items);

  /// Called when the tracker authority notifies a sync or state change.
  /// The widget is guaranteed to be mounted at the point this is called.
  /// If the implementation awaits any async operation, check [mounted]
  /// again before calling [setState] — the widget may have been disposed
  /// while the future was in flight.
  void onTrackerSyncChanged();
}
