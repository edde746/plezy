import '../../media/media_item.dart';
import '../plex_client.dart';
import 'tracker_stub_resolver.dart';

/// Overlay DTO that mirrors watch-state fields so the UI layer needs
/// zero Trakt-specific code. Values here directly replace the corresponding
/// fields on [MediaItem] via `copyWith`.
class WatchStateOverride {
  /// Replaces [MediaItem.viewCount] — number of times watched.
  final int? viewCount;

  /// Replaces [MediaItem.viewOffsetMs] — resume position in milliseconds.
  /// Semantics: null = preserve the item's existing Plex offset (tracker has no
  /// opinion); 0 = explicit no-progress (tracker confirms unwatched or complete);
  /// positive = tracker's resume position.
  final int? viewOffset;

  /// Replaces [MediaItem.viewedLeafCount] — watched episodes in a show/season.
  final int? viewedLeafCount;

  /// Replaces [MediaItem.leafCount] — total episodes in a show/season.
  final int? leafCount;

  /// Replaces [MediaItem.lastViewedAt] — unix timestamp (seconds).
  final int? lastViewedAt;

  const WatchStateOverride({this.viewCount, this.viewOffset, this.viewedLeafCount, this.leafCount, this.lastViewedAt});
}

/// A lightweight item representing an in-progress piece of content from the
/// tracker's `/sync/playback` endpoint, used by the "Continue Watching" hub.
class ContinueWatchingItem {
  /// The media item enriched with tracker progress.
  final MediaItem metadata;

  /// Progress percentage (0–100) from the tracker.
  final double progress;

  /// The next episode after [metadata], pre-fetched from Plex during enrichment.
  /// Null for movies, if the show has no further episodes, or if enrichment
  /// has not yet run. Used to immediately populate Continue Watching after the
  /// user marks the current episode as watched.
  final MediaItem? nextEpisode;

  const ContinueWatchingItem({
    required this.metadata,
    required this.progress,
    this.nextEpisode,
  });
}

/// Optional capability a [Tracker] can implement to provide authoritative
/// watch state via pull-based sync rather than just push-based scrobbling.
///
/// Only one tracker may be active as watch-state authority at a time.
/// When active, its data replaces the server's native watch fields
/// before the UI renders them — no fields are added or removed.
abstract class TrackerWatchStateProvider {
  /// Human-readable name of the tracker (e.g. 'Trakt'). Shown in UI badges.
  String get trackerName;

  /// Whether the user has enabled this tracker as the watch state authority.
  bool get isTrackerStateAuthorityEnabled;

  /// Completes when the initial cache load is finished.
  Future<void> get cacheReady;

  /// Pull all watch data from the tracker. Called once on app boot (background)
  /// and on reconnect after going offline. Must NOT block the UI thread.
  Future<void> syncWatchState();

  /// Synchronous lookup for a single [MediaItem]. Returns [null] if
  /// no tracker data exists for this item — in which case the original
  /// server state is shown unchanged.
  WatchStateOverride? getOverrideFor(MediaItem item);

  /// In-progress items from the tracker's playback-progress endpoint.
  /// Sorted by most-recently-paused first.
  List<ContinueWatchingItem> getContinueWatchingItems();

  /// Drop all in-memory and persistent cached state. Called on account switch
  /// or when the user manually requests a cache clear.
  Future<void> invalidateCache();

  /// Returns the up-next (season, episode) position for a show by its media ID.
  /// Null when this tracker does not track positional watch state.
  ({int season, int episode, int? tvdb, int? tmdb})? getUpNextPosition(String mediaId) => null;

  /// Lazily fetch detailed show progress if not already cached.
  /// Returns true if new data arrived that warrants a UI refresh.
  Future<bool> fetchShowProgressIfNeeded(MediaItem show) async => false;

  /// Queue a tracker scrobble for offline playback. Called when the player
  /// crosses the watch threshold while offline. Implementors persist the action
  /// so [flushOfflineQueue] can drain it when the network returns.
  Future<void> queueOfflineScrobble(MediaItem item, {required double progressPercent}) async {}

  /// Drain any queued offline scrobbles to the tracker's API.
  /// Called when the app detects it is back online.
  Future<void> flushOfflineQueue() async {}

  /// Optimistically remove [item] from the local playback cache so it
  /// disappears from Continue Watching immediately, without waiting for the
  /// tracker's history push to complete. A background sync confirms the state.
  void evictFromPlayback(MediaItem item) {}

  /// Returns this provider as a [TrackerStubResolver] if it also implements
  /// that interface, or null otherwise. Override to return [this] when the
  /// tracker produces synthetic stub IDs for Continue Watching.
  TrackerStubResolver? get asStubResolver => null;

  /// Items in the tracker's primary curated list when acting as watch-state
  /// authority (e.g. Trakt's watchlist). Resolved against the user's Plex
  /// libraries via [clients] (keyed by serverId) — only items present in the
  /// user's Plex library are returned; unresolved entries are dropped.
  /// Returns empty for trackers that have no list concept. When non-empty
  /// the Playlists tab renders these items in place of Plex playlists.
  Future<List<MediaItem>> getAuthorityListItems(
    Map<String, PlexClient> clients,
  ) async => const [];
}
