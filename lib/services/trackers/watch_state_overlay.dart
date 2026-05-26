import '../../media/media_item.dart';
import '../../utils/app_logger.dart';
import '../plex_client.dart';
import 'tracker_stub_resolver.dart';
import 'tracker_watch_state_provider.dart';

/// Central synchronous overlay point: the UI calls [apply] / [applyAll] to
/// get the authoritative version of a [MediaItem]. All data is pre-loaded in
/// memory by [TrackerWatchStateProvider.syncWatchState], so these methods
/// never block.
///
/// **Load-bearing invariant — do not weaken without re-reading pr.md
/// "What is not affected":** when an authority is active and the tracker has
/// no record for an item, [apply] zeroes the watch-state fields rather than
/// passing through Plex's own counts. The entire "tracker as source of truth"
/// guarantee depends on this. A future refactor that decides "fall back to
/// Plex when tracker has no record" would silently re-introduce a watch-state
/// leak this overlay was built to prevent.
///
/// Usage:
/// ```dart
/// final overlay = WatchStateOverlay.instance;
/// final enriched = overlay.apply(rawItem);
/// ```
class WatchStateOverlay {
  static final WatchStateOverlay instance = WatchStateOverlay._();
  WatchStateOverlay._();

  TrackerWatchStateProvider? _activeProvider;

  /// Register the active watch-state authority. Pass [null] to disable.
  void setActiveProvider(TrackerWatchStateProvider? provider) {
    appLogger.d('WatchStateOverlay: activating provider ${provider?.runtimeType}');
    _activeProvider = provider;
  }

  /// Whether any tracker is currently acting as watch state authority.
  bool get hasActiveAuthority {
    final p = _activeProvider;
    return p != null && p.isTrackerStateAuthorityEnabled;
  }

  /// The display name of the active tracker authority (e.g. 'Trakt'), or null.
  String? get activeTrackerName => hasActiveAuthority ? _activeProvider!.trackerName : null;

  /// Completes when the active provider's initial cache load is finished.
  Future<void> get cacheReady async {
    if (_activeProvider != null) {
      await _activeProvider!.cacheReady;
    }
  }

  MediaItem _applyOverride(MediaItem item, WatchStateOverride override) => item.copyWith(
    viewCount: override.viewCount ?? item.viewCount,
    viewOffsetMs: override.viewOffset ?? item.viewOffsetMs,
    viewedLeafCount: override.viewedLeafCount ?? item.viewedLeafCount,
    leafCount: override.leafCount ?? item.leafCount,
    lastViewedAt: override.lastViewedAt ?? item.lastViewedAt,
  );

  /// Apply the active authority's data to a single [MediaItem].
  ///
  /// Returns a new [MediaItem] with overridden watch-state fields, or the
  /// original item if no override exists or no authority is active.
  MediaItem apply(MediaItem item) {
    if (!hasActiveAuthority) {
      appLogger.t('WatchStateOverlay: no active authority for ${item.title}');
      return item;
    }
    final override = _activeProvider!.getOverrideFor(item);
    if (override == null) {
      // Tracker is authority but has no record for this item — treat as unwatched.
      // Never let Plex's own watch state leak through when a tracker is active.
      appLogger.t('WatchStateOverlay: no tracker record for ${item.title} (${item.id}) — zeroing watch state');
      return item.copyWith(viewCount: 0, viewOffsetMs: 0, viewedLeafCount: 0, lastViewedAt: null);
    }

    final enriched = _applyOverride(item, override);
    appLogger.t(
      'WatchStateOverlay: Enriched ${item.title} (${item.id}) with ${_activeProvider!.trackerName} data: '
      'offset=${enriched.viewOffsetMs}, count=${enriched.viewCount}, '
      'leaf=${enriched.viewedLeafCount}/${enriched.leafCount}',
    );
    return enriched;
  }

  /// Apply to an entire list. Safe to call on large lists (synchronous, O(n)).
  List<MediaItem> applyAll(List<MediaItem> items) {
    appLogger.t('WatchStateOverlay.applyAll: items=${items.length}, authority=$hasActiveAuthority');
    if (!hasActiveAuthority) return items;
    appLogger.t('WatchStateOverlay: processing batch of ${items.length} items');
    return items.map(apply).toList();
  }

  /// Apply overlay AND filter to only items the tracker has any watch record for.
  /// Single-pass — calls [getOverrideFor] once per item. Use for library-level
  /// Continue Watching hubs when the tracker is authority; prevents Plex-only
  /// in-progress items from leaking through.
  List<MediaItem> applyAllContinueWatching(List<MediaItem> items) {
    if (!hasActiveAuthority) return applyAll(items);
    final result = <MediaItem>[];
    for (final item in items) {
      final override = _activeProvider!.getOverrideFor(item);
      if (override == null) continue;
      result.add(_applyOverride(item, override));
    }
    return result;
  }

  /// Returns true if the active tracker has in-progress playback for [item]
  /// (i.e. an override exists with viewOffset > 0). Used to filter movies
  /// in authority mode — only include movies Trakt actually knows about.
  bool hasTrackerProgress(MediaItem item) {
    if (!hasActiveAuthority) return false;
    final override = _activeProvider!.getOverrideFor(item);
    return override != null && (override.viewOffset ?? 0) > 0;
  }

  /// Returns true if the active tracker has ANY watch record for [item]
  /// (viewed, in-progress, or timestamped). Used to filter "Recently Watched"
  /// hub items — only show items Trakt knows the user has seen.
  bool hasTrackerRecord(MediaItem item) {
    if (!hasActiveAuthority) return false;
    return _activeProvider!.getOverrideFor(item) != null;
  }

  /// The "Continue Watching" items from the active tracker's playback data.
  /// Empty list when no authority is active.
  List<ContinueWatchingItem> getContinueWatchingItems() {
    if (!hasActiveAuthority) return const [];
    return _activeProvider!.getContinueWatchingItems();
  }

  /// Items in the active tracker's primary curated list (e.g. Trakt watchlist),
  /// resolved against [clients] (keyed by serverId). Empty when no authority
  /// is active or the active tracker has no list concept. Consumed by the
  /// Playlists tab when authority is on — Plex playlists are hidden in that
  /// mode and these items render in their place.
  Future<List<MediaItem>> getAuthorityListItems(
    Map<String, PlexClient> clients,
  ) {
    if (!hasActiveAuthority) return Future.value(const []);
    return _activeProvider!.getAuthorityListItems(clients);
  }

  /// Returns the up-next (season, episode) position for a show.
  /// Null when no authority is active or the tracker doesn't support this.
  ({int season, int episode, int? tvdb, int? tmdb})? getUpNextPosition(String mediaId) {
    if (!hasActiveAuthority) return null;
    return _activeProvider!.getUpNextPosition(mediaId);
  }

  /// Lazily fetch detailed show progress if not already cached.
  /// Returns true if new data arrived that warrants a UI refresh.
  Future<bool> fetchShowProgressIfNeeded(MediaItem show) {
    if (!hasActiveAuthority) return Future.value(false);
    return _activeProvider!.fetchShowProgressIfNeeded(show);
  }

  /// Queue a tracker scrobble for offline playback. No-op when no authority is active.
  Future<void> queueOfflineScrobble(MediaItem item, {required double progressPercent}) {
    if (!hasActiveAuthority) return Future.value();
    return _activeProvider!.queueOfflineScrobble(item, progressPercent: progressPercent);
  }

  /// Drain queued offline scrobbles. Call when the network returns.
  Future<void> flushOfflineQueue() {
    if (!hasActiveAuthority) return Future.value();
    return _activeProvider!.flushOfflineQueue();
  }

  /// Optimistically evict [item] from the active tracker's playback cache
  /// so Continue Watching updates immediately, without waiting for the
  /// tracker API push to finish. A background sync confirms the final state.
  void evictFromPlayback(MediaItem item) => _activeProvider?.evictFromPlayback(item);

  /// Drop all in-memory and persisted cache for the active tracker authority.
  /// No-op when no authority is active.
  Future<void> invalidateCache() => _activeProvider?.invalidateCache() ?? Future.value();

  /// Returns the active tracker's stub resolver, or null when the active
  /// tracker does not support stub resolution (or no authority is active).
  TrackerStubResolver? get stubResolver {
    final p = _activeProvider;
    if (p == null || !p.isTrackerStateAuthorityEnabled) return null;
    return p.asStubResolver;
  }
}
