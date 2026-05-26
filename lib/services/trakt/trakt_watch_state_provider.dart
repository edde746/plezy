// ─────────────────────────────────────────────────────────────────────────
// TraktWatchStateProvider — section map for a 2900+-line file.
//   _CacheKeys                                    21– 43
//   _TraktState / _TraktEpisodeState / _TraktCache
//                  / _ResolvedMovieEntry          44–166
//   _BoundedMap helper                           182–209
//   TraktWatchStateProvider singleton + state    211–356
//   bindSession / lifecycle (initialize, setEnabled,
//                            invalidateCache, _resetInMemoryState)
//                                                371–435 + 893–972
//   Watch-state API (overrides + sync)           Search "TrackerWatchStateProvider impl"
//   Offline / eviction                           Search "Optimistic eviction"
//   Cache persistence (loadFromCache /
//                      _persistToCache)          Search "Cache persistence (ApiCache table)"
//   Enrichment + stub resolution                 Search "Stub resolution"
// ─────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../services/plex_api_cache.dart';
import '../../services/settings_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/external_ids.dart';
import '../../utils/watch_state_notifier.dart';
import '../plex_client.dart';
import '../trackers/tracker_constants.dart';
import '../trackers/tracker_stub_resolver.dart';
import '../trackers/tracker_sync_notifier.dart';
import '../trackers/tracker_watch_state_provider.dart';
import 'trakt_client.dart';
import 'trakt_session.dart';
import 'trakt_sync_service.dart';

/// Persistence keys for the ApiCache table (prefixed with "trakt:" to avoid
/// collisions with Plex's serverId-prefixed cache keys).
class _CacheKeys {
  static const String watchedMovies = 'trakt:watched_movies';
  static const String watchedShows = 'trakt:watched_shows';
  static const String playback = 'trakt:playback';
  static const String lastActivities = 'trakt:last_activities';
  static const String watchlistShows = 'trakt:watchlist_shows';
  static const String watchlistMovies = 'trakt:watchlist_movies';
  static const String ratingsShows = 'trakt:ratings_shows';
  static const String ratingsMovies = 'trakt:ratings_movies';
  static const String bridgeMaps = 'trakt:bridge_maps';
  static const String enrichNotFound = 'trakt:enrich_not_found';
  static const String upNext = 'trakt:up_next';
  static const String externalIds = 'trakt:external_ids';
  static const String resolvedPositions = 'trakt:resolved_positions';
}

// TTL for empty external-ID markers (items with no Plex external IDs yet).
// After this duration the marker expires and a background re-fetch is allowed,
// in case the Plex metadata was refreshed in the interim.
const int _externalIdsEmptyTtlMs = 24 * 60 * 60 * 1000; // 24 h

/// Internal watch-state record for a movie or show.
class _TraktState {
  final int plays;
  final String? lastWatchedAt;
  final int traktId;

  const _TraktState({required this.plays, required this.lastWatchedAt, required this.traktId});
}

/// Per-episode state inside a show.
class _TraktEpisodeState {
  final int plays;
  final String? lastWatchedAt;

  const _TraktEpisodeState({required this.plays, required this.lastWatchedAt});
}

/// Fully resolved movie entry stored in the single-entry-point cache.
/// Populated on first successful [TraktWatchStateProvider.getOverrideFor] call;
/// subsequent calls return this directly without re-running the ID lookup chain.
class _ResolvedMovieEntry {
  final int traktId;
  final int plays;
  final double? playbackProgress; // 0–100, null = not in progress
  final String? lastWatchedAt;

  const _ResolvedMovieEntry({
    required this.traktId,
    required this.plays,
    this.playbackProgress,
    this.lastWatchedAt,
  });
}

/// Fully resolved show entry stored in the single-entry-point cache.
/// Stores only the Trakt show ID so the ID-lookup chain is skipped on
/// subsequent calls. Progress is always read live from `_cache.showProgress`
/// so deep-fetch updates (fetchShowProgressIfNeeded) are reflected immediately.
class _ResolvedShowEntry {
  final int traktId;
  const _ResolvedShowEntry({required this.traktId});
}

/// In-memory cache of Trakt watch data. Stores raw responses for future use
/// and builds lookup indices keyed by external IDs.
class _TraktCache {
  // ---- raw responses ----
  List<Map<String, dynamic>> watchedMoviesRaw = [];
  List<Map<String, dynamic>> watchedShowsRaw = [];
  List<Map<String, dynamic>> playbackRaw = [];
  Map<String, dynamic>? lastActivities;

  List<Map<String, dynamic>> upNextRaw = [];

  // ---- continue-watching stubs built from playbackRaw + upNextRaw ----
  List<ContinueWatchingItem> playbackStubs = [];

  // ---- lookup indices for movies ----
  final Map<String, _TraktState> byImdb = {};
  final Map<int, _TraktState> byTmdb = {};
  final Map<int, _TraktState> byTvdb = {};

  // ---- lookup indices for shows (show-level + episode-level) ----
  // traktShowId -> season#episode -> episode state
  final Map<int, Map<String, _TraktEpisodeState>> showEpisodes = {};

  // show-level: traktShowId -> watched episode count, total aired
  final Map<int, (int watched, int aired, String? lastWatchedAt)> showProgress = {};

  // show-level ID maps
  final Map<String, _TraktState> showByImdb = {};
  final Map<int, _TraktState> showByTmdb = {};
  final Map<int, _TraktState> showByTvdb = {};

  // playback (in-progress) — imdb/tmdb/tvdb + traktId keys for fast lookup
  // value: progress 0-100
  final Map<String, double> playbackByImdb = {};
  final Map<int, double> playbackByTmdb = {};
  final Map<int, double> playbackByTvdb = {};
  // traktMovieId → progress; used as safety-net when imdb/tmdb cross-match fails
  final Map<int, double> playbackByTraktId = {};
  // imdb/tmdb → traktMovieId for playback-only movies (not in watched list).
  // Used by feedExternalIds to populate the bridge map for in-progress movies.
  final Map<String, int> playbackTraktIdByImdb = {};
  final Map<int, int> playbackTraktIdByTmdb = {};
  // episode-level playback keyed as "traktShowId:s1e2"
  // value carries both the resume progress and when the pause was saved.
  final Map<String, ({double progress, String? pausedAt})> episodePlayback = {};

  // ---- single-entry-point resolved cache ----
  // Populated on first successful getOverrideFor; subsequent calls skip ID chain.
  // Cleared at the start of each index rebuild so stale entries don't survive sync.
  final Map<String, _ResolvedMovieEntry> resolvedMovies = {}; // plexRatingKey → entry
  final Map<String, _ResolvedShowEntry> resolvedShows = {};   // plexRatingKey → entry

  bool get isEmpty => watchedMoviesRaw.isEmpty && watchedShowsRaw.isEmpty && playbackRaw.isEmpty;

  void clear() {
    watchedMoviesRaw = [];
    watchedShowsRaw = [];
    playbackRaw = [];
    upNextRaw = [];
    playbackStubs = [];
    lastActivities = null;
    byImdb.clear();
    byTmdb.clear();
    byTvdb.clear();
    showEpisodes.clear();
    showProgress.clear();
    showByImdb.clear();
    showByTmdb.clear();
    showByTvdb.clear();
    playbackByImdb.clear();
    playbackByTmdb.clear();
    playbackByTvdb.clear();
    playbackByTraktId.clear();
    playbackTraktIdByImdb.clear();
    playbackTraktIdByTmdb.clear();
    episodePlayback.clear();
    resolvedMovies.clear();
    resolvedShows.clear();
  }
}

/// Trakt's implementation of [TrackerWatchStateProvider].
///
/// On [syncWatchState] (called once at boot):
///   1. Checks `last_activities` timestamps to decide if a refresh is needed.
///   2. Fetches `/sync/watched/movies`, `/sync/watched/shows`, `/sync/playback`.
///   3. Persists raw responses to the existing [ApiCache] table.
///   4. Builds in-memory lookup indices.
///
/// [getOverrideFor] is synchronous — it looks up from the pre-built indices.
/// Insertion-ordered map with a hard capacity ceiling. On insert past
/// capacity, evicts the oldest entry. Cheaper than full LRU and good enough
/// for the bridge maps — access patterns are dominated by recent activity,
/// so insertion-order eviction approximates LRU adequately.
class _BoundedMap<K, V> extends MapBase<K, V> {
  final int capacity;
  final LinkedHashMap<K, V> _store = LinkedHashMap<K, V>();

  _BoundedMap(this.capacity);

  @override
  V? operator [](Object? key) => _store[key];

  @override
  void operator []=(K key, V value) {
    _store[key] = value;
    if (_store.length > capacity) {
      _store.remove(_store.keys.first);
    }
  }

  @override
  void clear() => _store.clear();

  @override
  Iterable<K> get keys => _store.keys;

  @override
  V? remove(Object? key) => _store.remove(key);
}

class TraktWatchStateProvider implements TrackerWatchStateProvider, TrackerStubResolver {
  // ApiCache uses a dummy serverId prefix. We scope it by the active Plex
  // profile UUID so two profiles with different Trakt accounts on the same
  // device do not share cached watch history. Cold-start before bindSession
  // sets the unscoped 'trakt' value; first bindSession with a profile UUID
  // upgrades it to 'trakt:<uuid>' before any read or write. Pre-fix builds
  // wrote under the unscoped 'trakt:*' rows — these are intentionally left
  // in place (no migration); they are orphaned and will be cleaned by the
  // user's next manual cache reset.
  String _cacheServerId = 'trakt';
  String? _boundUserUuid;

  TraktClient? _client;
  final _TraktCache _cache = _TraktCache();
  bool _syncInProgress = false;
  bool _stubRebuildPending = false;

  // Forward bridge maps: Trakt ID → Plex metadata.
  // Lifecycle: populated lazily by getOverrideFor() and by enrichStubs();
  //            cleared on invalidateCache(); persisted via _persistBridgeMaps().
  // Capacity ceiling guards against unbounded growth on shared-device long-
  // uptime sessions where invalidateCache() may never fire. 10k entries per
  // map covers any realistic Trakt history with margin.
  final _BoundedMap<int, String> _traktShowIdToPlexKey = _BoundedMap(_bridgeMapCapacity);
  final _BoundedMap<int, String> _traktShowIdToThumb = _BoundedMap(_bridgeMapCapacity); // show poster
  final _BoundedMap<int, String> _traktShowIdToArt = _BoundedMap(_bridgeMapCapacity); // show background art (for hero)
  final _BoundedMap<int, String> _traktShowIdToServerId = _BoundedMap(_bridgeMapCapacity);
  // Movie forward maps (traktMovieId → Plex data).
  // Lifecycle: populated by enrichStubs() and lazily by _overrideForMovie();
  //            cleared on invalidateCache(); persisted via _persistBridgeMaps().
  // isMovieEnrichNotFound() / markMovieEnrichNotFound() guard against repeated
  // searches for movies the user doesn't have in their Plex library (24 h TTL).
  final _BoundedMap<int, String> _traktMovieIdToThumb = _BoundedMap(_bridgeMapCapacity);
  final _BoundedMap<int, String> _traktMovieIdToPlexKey = _BoundedMap(_bridgeMapCapacity);
  final _BoundedMap<int, String> _traktMovieIdToServerId = _BoundedMap(_bridgeMapCapacity);

  static const int _bridgeMapCapacity = 10000;

  // stub id → resolved Plex season/episode + episode thumb, populated when ID
  // matching succeeds. Used to show correct S/E and fallback thumb on cards.
  final Map<String, ({int season, int episode, String? thumb})> _resolvedEpisodePosition = {};

  // Trakt IDs that were fully searched and not found in any Plex library,
  // mapped to the epoch-second timestamp when they were marked. Entries expire
  // after 24 h so the item is re-attempted (the show may have been added to Plex).
  final Map<int, int> _enrichNotFoundShowTs = {};
  final Map<int, int> _enrichNotFoundMovieTs = {};

  static const _enrichNotFoundTtlSeconds = 86400; // 24 h

  int get _nowEpoch => DateTime.now().millisecondsSinceEpoch ~/ 1000;

  // Reverse bridge maps: Plex ratingKey → Trakt ID.
  // Lifecycle: populated by _overrideForEpisode/_overrideForMovie/_overrideForShow
  //            and by enrichStubs(); cleared on invalidateCache(); persisted via _persistBridgeMaps().
  // Lets _overrideForEpisode resolve the Trakt show ID via grandparentRatingKey.
  final _BoundedMap<String, int> _plexKeyToTraktShowId = _BoundedMap(_bridgeMapCapacity);

  // Fast lookup: Trakt show ID → _TraktState (plays, lastWatchedAt).
  // Built in _buildShowIndices() from /sync/watched/shows.
  final Map<int, _TraktState> _showByTraktId = {};

  // Fast lookup: Trakt movie ID → _TraktState. Built in _buildMovieIndices().
  final Map<int, _TraktState> _movieByTraktId = {};

  // Reverse bridge map for movies: Plex ratingKey → Trakt movie ID.
  // Populated on first successful _overrideForMovie match, same pattern as _plexKeyToTraktShowId.
  final _BoundedMap<String, int> _plexMovieKeyToTraktMovieId = _BoundedMap(_bridgeMapCapacity);

  // Watchlist raw items (Trakt JSON shape from /sync/watchlist/{type}).
  // Populated by _syncWatchlist during sync and by loadFromCache on cold boot.
  // Cleared in _resetInMemoryState; on-disk copy wiped in invalidateCache.
  // Used only for surfacing a single "Trakt Watchlist" entry to the
  // playlists tab when authority is on; items are resolved lazily to real
  // Plex MediaItems at detail-screen open time.
  List<Map<String, dynamic>> _watchlistShowsRaw = const [];
  List<Map<String, dynamic>> _watchlistMoviesRaw = const [];

  // Shows for which /shows/{id}/progress/watched has been fetched (lazy, once per session).
  final Set<int> _deepFetchedShows = {};

  // Shows confirmed not in Trakt this session (no IDs matched). Avoids re-running
  // the full _lookupShow chain on every getOverrideFor() call for the same show.
  // Cleared on every _buildShowIndices() (i.e. each sync cycle).
  final Set<String> _grandparentIdsNotFound = {};

  // Stale-pause decision cache. Incremented by _buildShowIndices() and
  // _buildPlaybackIndices() whenever the inputs to stale-pause detection change.
  // Allows _buildContinueWatchingStubs() calls that follow a no-input-change
  // event (e.g. resolveEpisodeDisplayPositions) to skip the detection loop.
  int _rawDataVersion = 0;
  int _stalePauseCacheVersion = -1;
  // showId → alreadyWatched: per-sync-cycle stale-pause decision cache for
  // _buildContinueWatchingStubs(). Cleared when _rawDataVersion changes.
  final Map<int, bool> _stalePauseCache = {};

  // Reverse map: '{traktShowId}:s{plexSeason}e{plexEp}' → 's{traktSeason}e{traktEp}'.
  // Built from _resolvedEpisodePosition so _overrideForEpisode can find Trakt
  // episode data for shows whose Plex S/E numbering differs from Trakt's (e.g. anime).
  // Cleared on invalidateCache(); rebuilt from _resolvedEpisodePosition on loadFromCache().
  final Map<String, String> _plexSeToTraktSeKey = {};

  // External IDs fed from the scrobble path for movies whose Plex metadata
  // doesn't include a Guid array (e.g. un-refreshed new-agent movies).
  // Keyed by Plex ratingKey; cleared on invalidateCache().
  final Map<String, ExternalIds> _fetchedExternalIds = {};

  // Tracks in-flight background ID fetches to avoid duplicate requests.
  final Set<String> _pendingIdFetches = {};

  // Optimistic-eviction guard. Keyed by Trakt ID.
  // • Movies: epKey is null — suppresses the movie stub until Trakt confirms removal.
  // • Shows: epKey is 's{season}e{episode}' of the evicted episode — only suppresses
  //   that specific episode stub. A stub for a different episode (e.g. the next ep after
  //   a successful history push) passes through immediately so it can be shown.
  // Pruned in _buildContinueWatchingStubs(); TTL prevents permanent suppression.
  // 5 minutes: the post-playback CW re-sync fires within ~2 s; this window
  // is intentionally wider to survive slow networks or a delayed foreground event.
  static const _pendingEvictionTtlSeconds = 300;
  final Map<int, ({String? epKey, int evictedAt})> _pendingEvictions = {};

  // Session-scoped cache for PlexClient.getAllLeaves() results, keyed by
  // Plex show ratingKey. Capped at 50 entries (FIFO eviction) so anime shows
  // with 400+ episodes don't blow up the heap. Cleared on invalidateCache().
  // Owned here so tracker lifecycle controls its lifetime, not PlexClient.
  final Map<String, List<MediaItem>> _allLeavesCache = {};
  static const _leavesCacheMaxEntries = 50;

  // Per-server GUID index built by _doEnrichStubs(). Cached for 5 min so
  // repeated enrichment runs within a sync window don't re-fetch every library
  // section on every server. Keyed by "show_{serverId}" / "movie_{serverId}".
  // Cleared on invalidateCache() and when the TTL expires.
  final Map<String, Map<String, MediaItem>> _guidIndexCache = {};
  int? _guidIndexBuiltAt;
  static const _guidIndexTtlSeconds = 300;

  // Timer that fires a lightweight playback+up_next refresh ~1.5 s after a
  // successful Trakt history-add. Debounced so bulk season marks coalesce.
  Timer? _postMarkRefreshTimer;

  // Stub ID → next episode MediaItem, populated by resolveEpisodeDisplayPositions().
  final Map<String, MediaItem> _nextEpisodeByStubId = {};

  // Immediately-shown next episodes after eviction, cleared when _refreshPlaybackAndUpNext fires.
  final List<ContinueWatchingItem> _pendingNextEpisodes = [];

  // Callback registered by TraktAccountProvider to resolve external IDs via
  // the Plex client without creating a circular import.
  Future<ExternalIds?> Function(String plexKey, String serverId)? _externalIdsFetcher;

  /// Called whenever a new entry is added to the bridge map (i.e. a show was
  /// matched in Plex for the first time). Registered by [TraktAccountProvider]
  /// so the UI can refresh Continue Watching thumbnails without waiting for the
  /// next full sync cycle.
  VoidCallback? _onBridgeMapUpdated;

  /// Register (or clear) the bridge-map-updated callback.
  void setOnBridgeMapUpdated(VoidCallback? callback) {
    _onBridgeMapUpdated = callback;
  }

  VoidCallback? _onCachesInvalidated;

  /// Register (or clear) the callback invoked at the end of [invalidateCache].
  /// Use this to clear related caches in other layers (e.g. PlexClient._allLeavesCache).
  void setOnCachesInvalidated(VoidCallback? callback) {
    _onCachesInvalidated = callback;
  }

  /// Completes when [loadFromCache] has finished (successfully or not).
  /// Consumers can await this before calling [getOverrideFor].
  Completer<void> _cacheReadyCompleter = Completer<void>();

  @override
  Future<void> get cacheReady => _cacheReadyCompleter.future;

  TraktWatchStateProvider._();

  static final TraktWatchStateProvider instance = TraktWatchStateProvider._();

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  /// Bind a live [TraktSession]. Called by [TraktAccountProvider] when the
  /// active profile's session changes.
  ///
  /// Contract: callers that want to (re)activate the overlay must await this
  /// future before doing so. The in-memory caches and `_client` reflect the
  /// new profile only after this completes; activating the overlay too early
  /// would cause it to serve the prior profile's data until the next
  /// syncWatchState() finishes. See [TraktAccountProvider._setSessionAndRebind]
  /// for the correct ordering.
  ///
  /// On full disconnect (`session == null`) the on-disk cache for the prior
  /// profile is wiped. On profile switch (both connected, identity changed),
  /// in-memory state is reset but the prior profile's persisted cache stays
  /// on disk so a future switch back is fast.
  Future<void> bindSession(
    TraktSession? session, {
    required String userUuid,
    required void Function() onSessionInvalidated,
  }) async {
    final newScope = session != null && userUuid.isNotEmpty ? 'trakt:$userUuid' : 'trakt';
    final identityChanged = newScope != _cacheServerId || userUuid != _boundUserUuid;
    _client?.dispose();
    _client = session != null ? TraktClient(session, onSessionInvalidated: onSessionInvalidated) : null;
    _cacheServerId = newScope;
    _boundUserUuid = userUuid;
    if (session == null) {
      await invalidateCache();
    } else if (identityChanged) {
      _resetInMemoryState();
    }
  }

  /// Load the "enabled" setting from SharedPreferences.
  Future<void> initialize() async {
    // No-op for now as we read directly from SettingsService,
    // but kept for future boots-up logic.
  }

  /// Toggle the authority on/off and persist the preference.
  Future<void> setEnabled(bool enabled) async {
    final settings = await SettingsService.getInstance();
    await settings.write(SettingsService.trackerStateAuthority, enabled ? TrackerService.trakt.name : 'none');
    if (!enabled) await invalidateCache();
  }

  @override
  String get trackerName => 'Trakt';

  @override
  TrackerStubResolver? get asStubResolver => this;

  @override
  Future<List<MediaItem>> getAuthorityListItems(
    Map<String, PlexClient> clients,
  ) async {
    if (!isTrackerStateAuthorityEnabled) return const [];
    if (_watchlistShowsRaw.isEmpty && _watchlistMoviesRaw.isEmpty) return const [];
    // Fire enrichment so unmatched watchlist items get a chance to resolve on
    // subsequent opens (no-op if already in flight; coalesced internally).
    unawaited(enrichStubs(null, clients));
    final out = <MediaItem>[];
    await _appendResolvedWatchlistItems(
      raws: _watchlistShowsRaw,
      idMap: _traktShowIdToPlexKey,
      serverMap: _traktShowIdToServerId,
      typeKey: 'show',
      clients: clients,
      out: out,
    );
    await _appendResolvedWatchlistItems(
      raws: _watchlistMoviesRaw,
      idMap: _traktMovieIdToPlexKey,
      serverMap: _traktMovieIdToServerId,
      typeKey: 'movie',
      clients: clients,
      out: out,
    );
    return out;
  }

  /// Walk a watchlist raw list, look up each entry's Plex ratingKey via the
  /// bridge map, and append the fetched [MediaItem]. Drops entries without a
  /// bridge-map hit (enrichment will pick them up on a subsequent open).
  Future<void> _appendResolvedWatchlistItems({
    required List<Map<String, dynamic>> raws,
    required _BoundedMap<int, String> idMap,
    required _BoundedMap<int, String> serverMap,
    required String typeKey,
    required Map<String, PlexClient> clients,
    required List<MediaItem> out,
  }) async {
    for (final entry in raws) {
      final inner = entry[typeKey];
      if (inner is! Map) continue;
      final ids = inner['ids'];
      if (ids is! Map) continue;
      final traktId = (ids['trakt'] as num?)?.toInt();
      if (traktId == null) continue;
      final plexKey = idMap[traktId];
      if (plexKey == null) continue;
      final serverId = serverMap[traktId];
      final client = serverId != null ? clients[serverId] : null;
      if (client == null) continue;
      try {
        final item = await client.fetchItem(plexKey);
        if (item != null) out.add(item);
      } catch (e) {
        appLogger.d('TraktWatchState: watchlist item fetch failed for $plexKey', error: e);
      }
    }
  }

  @override
  bool get isTrackerStateAuthorityEnabled {
    final settings = SettingsService.instanceOrNull;
    return settings?.read(SettingsService.trackerStateAuthority) == TrackerService.trakt.name && _client != null;
  }

  // -------------------------------------------------------------------------
  // TrackerWatchStateProvider impl
  // -------------------------------------------------------------------------

  @override
  Future<void> syncWatchState({bool force = false}) async {
    if (_syncInProgress) {
      appLogger.d('TraktWatchState: sync already in progress, skipping');
      return;
    }
    final client = _client;
    if (client == null) return;
    _syncInProgress = true;
    appLogger.d('TraktWatchState: checking for updates (force=$force)...');
    try {
      await _doSync(client, force: force);
    } catch (e, st) {
      appLogger.e('TraktWatchState: sync failed', error: e, stackTrace: st);
    } finally {
      _syncInProgress = false;
    }
  }

  @override
  WatchStateOverride? getOverrideFor(MediaItem item) {
    if (!isTrackerStateAuthorityEnabled) return null;

    final ids = _idsFromItem(item);
    final type = item.kind;
    WatchStateOverride? override;

    if (type == MediaKind.movie) override = _overrideForMovie(item, ids);
    if (type == MediaKind.episode) override = _overrideForEpisode(item, ids);
    if (type == MediaKind.show || type == MediaKind.season) override = _overrideForShow(item, ids);

    if (override != null) {
      appLogger.t(
        'TraktWatchState: found override for ${item.title} (${item.id}) '
        '[ids: $ids, plays: ${override.viewCount}, offset: ${override.viewOffset}]',
      );
    } else {
      appLogger.t('TraktWatchState: no Trakt record for ${item.title} (${item.id})');
    }
    return override;
  }

  /// Returns the Plex show ratingKey for a given Trakt show ID, if known.
  String? getPlexShowKey(int traktShowId) => _traktShowIdToPlexKey[traktShowId];

  /// Returns the cached Plex show thumb for a given Trakt show ID, if known.
  String? getPlexShowThumb(int traktShowId) => _traktShowIdToThumb[traktShowId];

  /// Returns the cached Plex show background art for a given Trakt show ID, if known.
  String? getPlexShowArt(int traktShowId) => _traktShowIdToArt[traktShowId];

  /// Returns the cached Plex serverId for a given Trakt show ID, if known.
  String? getPlexShowServerId(int traktShowId) => _traktShowIdToServerId[traktShowId];

  /// Returns the cached Plex movie thumbnail for a given Trakt movie ID, if known.
  String? getPlexMovieThumb(int traktMovieId) => _traktMovieIdToThumb[traktMovieId];

  /// Returns the cached Plex movie ratingKey for a given Trakt movie ID, if known.
  String? getPlexMovieKey(int traktMovieId) => _traktMovieIdToPlexKey[traktMovieId];

  /// Returns the cached Plex serverId for a given Trakt movie ID, if known.
  String? getPlexMovieServerId(int traktMovieId) => _traktMovieIdToServerId[traktMovieId];

  /// Records the resolved Plex season/episode for a stub after a successful ID
  /// match in [resolveTraktEpisodeStub]. Rebuilds Continue Watching stubs so
  /// the card shows the correct S/E number instead of Trakt's numbering.
  void recordResolvedEpisodePosition(String stubId, int season, int episode, {String? thumb}) {
    final prev = _resolvedEpisodePosition[stubId];
    if (prev?.season == season && prev?.episode == episode && prev?.thumb == thumb) return;
    _resolvedEpisodePosition[stubId] = (season: season, episode: episode, thumb: thumb);
    _updatePlexSeRemapping(stubId, season, episode);
  }

  /// Updates `_plexSeToTraktSeKey` with a Plex→Trakt S/E translation derived
  /// from [stubId]. Does nothing for stub IDs that don't encode a show+S/E pair.
  void _updatePlexSeRemapping(String stubId, int plexSeason, int plexEpisode) {
    final m = RegExp(r'trakt_(?:upnext|episode_pb)_(\d+)_s(\d+)e(\d+)').firstMatch(stubId);
    if (m == null) return;
    final showId = m.group(1)!;
    final traktSeason = m.group(2)!;
    final traktEp = m.group(3)!;
    _plexSeToTraktSeKey['$showId:s${plexSeason}e$plexEpisode'] = 's${traktSeason}e$traktEp';
  }

  /// Returns true if this Trakt show was searched and not found in Plex recently
  /// (within the 24 h TTL). Expired entries are treated as "not yet searched".
  bool isShowEnrichNotFound(int traktShowId) {
    final ts = _enrichNotFoundShowTs[traktShowId];
    return ts != null && (_nowEpoch - ts) < _enrichNotFoundTtlSeconds;
  }

  /// Returns true if this Trakt movie was searched and not found in Plex recently.
  bool isMovieEnrichNotFound(int traktMovieId) {
    final ts = _enrichNotFoundMovieTs[traktMovieId];
    return ts != null && (_nowEpoch - ts) < _enrichNotFoundTtlSeconds;
  }

  /// Marks a show as searched-but-not-found. Expires after 24 h so it is
  /// re-attempted in case the user adds the show to their Plex library later.
  /// Call [flushEnrichNotFound] after a batch of marks to persist to disk.
  void markShowEnrichNotFound(int traktShowId) {
    _enrichNotFoundShowTs[traktShowId] = _nowEpoch;
  }

  /// Marks a movie as searched-but-not-found (24 h TTL).
  /// Call [flushEnrichNotFound] after a batch of marks to persist to disk.
  void markMovieEnrichNotFound(int traktMovieId) {
    _enrichNotFoundMovieTs[traktMovieId] = _nowEpoch;
  }

  /// Persists the current not-found sets to disk. Call once after a batch of
  /// [markShowEnrichNotFound]/[markMovieEnrichNotFound] calls.
  Future<void> flushEnrichNotFound() => _persistEnrichNotFound();

  /// Returns the in-progress episode (season, episode) for a Plex show, if known.
  ///
  /// Priority: /sync/playback/episodes (genuinely paused) → up_next_nitro (next
  /// unstarted). A playback entry is skipped when its episode is already marked
  /// watched in /sync/watched/shows — that means the pause point is stale (e.g.
  /// watched to completion on another device without Plex scrobbling).
  @override
  ({int season, int episode, int? tvdb, int? tmdb})? getUpNextPosition(String plexShowRatingKey) {
    final traktId = _plexKeyToTraktShowId[plexShowRatingKey];
    if (traktId == null) {
      appLogger.d('TraktWatchState: getUpNextPosition — no traktId for plexKey=$plexShowRatingKey');
      return null;
    }

    // Fast path: the CW stub for this show already has the resolved Plex S/E position
    // (parentIndex/index are translated from Trakt's numbering in _buildContinueWatchingStubs).
    // Using it avoids returning a stale re-watch entry from episodePlayback — e.g. a show
    // where the user is mid-re-watch of S1E1 while the real up-next is S2E1.
    final cwItem = getContinueWatchingItems()
        .where((item) => item.metadata.grandparentId == plexShowRatingKey)
        .firstOrNull;
    if (cwItem != null) {
      final cwMeta = cwItem.metadata;
      final s = cwMeta.parentIndex ?? 0;
      final e = cwMeta.index ?? 0;
      if (s > 0 && e > 0) {
        final tvdb = cwMeta.raw?['episodeTvdb'] as int?;
        final tmdb = cwMeta.raw?['episodeTmdb'] as int?;
        appLogger.d(
          'TraktWatchState: getUpNextPosition — CW fast path traktId=$traktId: '
          's${s}e$e tvdb=$tvdb tmdb=$tmdb (stub=${cwMeta.id})',
        );
        return (season: s, episode: e, tvdb: tvdb, tmdb: tmdb);
      }
    }

    final showLastWatchedAt = DateTime.tryParse(_cache.showProgress[traktId]?.$3 ?? '');

    for (final key in _cache.episodePlayback.keys) {
      if (!key.startsWith('$traktId:')) continue;
      final m = RegExp(r':s(\d+)e(\d+)$').firstMatch(key);
      if (m == null) continue;
      final season = int.parse(m.group(1)!);
      final ep = int.parse(m.group(2)!);
      final epState = _cache.showEpisodes[traktId]?['s${season}e$ep'];
      final pausedAt = DateTime.tryParse(_cache.episodePlayback[key]?.pausedAt ?? '');

      // Show-level stale check: if any episode in the show was completed more
      // recently than this pause, the user has moved past it.
      if (pausedAt != null && showLastWatchedAt != null && showLastWatchedAt.isAfter(pausedAt)) {
        appLogger.d(
          'TraktWatchState: getUpNextPosition — stale pause at s${season}e$ep '
          'for traktId=$traktId (showLastWatched=$showLastWatchedAt, paused=$pausedAt) — falling back to up_next_nitro',
        );
        break;
      }

      // Episode-level stale check: this specific episode was completed after
      // its pause (plays > 0 and watched date is not older than the pause).
      if ((epState?.plays ?? 0) > 0) {
        final watchedAt = DateTime.tryParse(epState?.lastWatchedAt ?? '');
        if (pausedAt == null || watchedAt == null || !pausedAt.isAfter(watchedAt)) {
          appLogger.d(
            'TraktWatchState: getUpNextPosition — stale pause at s${season}e$ep '
            'for traktId=$traktId (plays=${epState?.plays}, watched=$watchedAt, paused=$pausedAt) — falling back to up_next_nitro',
          );
          break;
        }
      }

      // Look up episode IDs from playbackRaw for ID-based resolution.
      int? tvdb, tmdb;
      for (final item in _cache.playbackRaw) {
        final show = item['show'] as Map<String, dynamic>?;
        final episode = item['episode'] as Map<String, dynamic>?;
        if (show == null || episode == null) continue;
        final sid = ((show['ids'] as Map?)?['trakt'] as num?)?.toInt() ?? 0;
        final eSeason = (episode['season'] as num?)?.toInt() ?? 0;
        final eNumber = (episode['number'] as num?)?.toInt() ?? 0;
        if (sid == traktId && eSeason == season && eNumber == ep) {
          final ids = episode['ids'] as Map<String, dynamic>?;
          tvdb = (ids?['tvdb'] as num?)?.toInt();
          tmdb = (ids?['tmdb'] as num?)?.toInt();
          break;
        }
      }

      // Translate Trakt S/E → resolved Plex S/E so Strategy 1 in
      // _applyTrackerUpNextToOnDeck can match against _episodes (Plex numbering).
      final pbStub = 'trakt_episode_pb_${traktId}_s${season}e$ep';
      final unStub = 'trakt_upnext_${traktId}_s${season}e$ep';
      final res = _resolvedEpisodePosition[pbStub] ?? _resolvedEpisodePosition[unStub];
      final outSeason = res?.season ?? season;
      final outEp = res?.episode ?? ep;
      appLogger.d(
        'TraktWatchState: getUpNextPosition — traktId=$traktId '
        'playback=s${season}e$ep → plex=s${outSeason}e$outEp '
        '(resolved=${res != null}) tvdb=$tvdb tmdb=$tmdb',
      );
      return (season: outSeason, episode: outEp, tvdb: tvdb, tmdb: tmdb);
    }

    // Fall back to up_next_nitro for the next unstarted episode.
    for (final item in _cache.upNextRaw) {
      final showId =
          (item['show_id'] as num?)?.toInt() ??
          ((item['show'] as Map<String, dynamic>?)?['ids']?['trakt'] as num?)?.toInt() ??
          0;
      if (showId != traktId) continue;
      final nextEp = (item['progress'] as Map<String, dynamic>?)?['next_episode'] as Map<String, dynamic>?;
      if (nextEp == null) return null;
      final season = (nextEp['season'] as num?)?.toInt() ?? 0;
      final ep = (nextEp['number'] as num?)?.toInt() ?? 0;
      if (season <= 0 || ep <= 0) return null;
      final nextEpIds = nextEp['ids'] as Map<String, dynamic>?;
      final tvdb = (nextEpIds?['tvdb'] as num?)?.toInt();
      final tmdb = (nextEpIds?['tmdb'] as num?)?.toInt();
      // Translate Trakt S/E → resolved Plex S/E (same as episodePlayback path above).
      final unStub = 'trakt_upnext_${traktId}_s${season}e$ep';
      final pbStub = 'trakt_episode_pb_${traktId}_s${season}e$ep';
      final res = _resolvedEpisodePosition[unStub] ?? _resolvedEpisodePosition[pbStub];
      final outSeason = res?.season ?? season;
      final outEp = res?.episode ?? ep;
      appLogger.d(
        'TraktWatchState: getUpNextPosition — traktId=$traktId '
        'upnext=s${season}e$ep → plex=s${outSeason}e$outEp '
        '(resolved=${res != null}) tvdb=$tvdb tmdb=$tmdb',
      );
      return (season: outSeason, episode: outEp, tvdb: tvdb, tmdb: tmdb);
    }

    return null;
  }

  /// Update the Plex bridge map from an externally resolved show.
  /// Rebuilds stubs so thumbnails + navigation keys are injected immediately.
  void updateBridgeMap({
    required int traktShowId,
    required String plexKey,
    String? thumb,
    String? art,
    String? serverId,
  }) {
    final isNew = !_traktShowIdToPlexKey.containsKey(traktShowId);
    final artWasNull = !_traktShowIdToArt.containsKey(traktShowId);
    _traktShowIdToPlexKey[traktShowId] = plexKey;
    _plexKeyToTraktShowId[plexKey] = traktShowId;
    if (serverId != null) _traktShowIdToServerId[traktShowId] = serverId;
    if (thumb != null) _traktShowIdToThumb[traktShowId] = thumb;
    if (art != null) _traktShowIdToArt[traktShowId] = art;
    _enrichNotFoundShowTs.remove(traktShowId); // matched — clear any not-found mark
    unawaited(_persistBridgeMaps());
    if (isNew || (art != null && artWasNull)) {
      _scheduleBuildContinueWatchingStubs();
      _onBridgeMapUpdated?.call();
    }
  }

  /// Update the movie bridge map from an externally resolved Plex movie item.
  /// Rebuilds stubs so the thumbnail and navigation key are injected immediately.
  void updateMovieBridgeMap({required int traktMovieId, String? plexKey, String? thumb, String? serverId}) {
    final isNew = !_traktMovieIdToPlexKey.containsKey(traktMovieId);
    final hadThumb = _traktMovieIdToThumb.containsKey(traktMovieId);
    if (plexKey != null) _traktMovieIdToPlexKey[traktMovieId] = plexKey;
    if (thumb != null) _traktMovieIdToThumb[traktMovieId] = thumb;
    if (serverId != null) _traktMovieIdToServerId[traktMovieId] = serverId;
    _enrichNotFoundMovieTs.remove(traktMovieId); // matched — clear any not-found mark
    unawaited(_persistBridgeMaps());
    if (isNew || (!hadThumb && thumb != null)) {
      _scheduleBuildContinueWatchingStubs();
      _onBridgeMapUpdated?.call();
    }
  }

  // -------------------------------------------------------------------------
  // Offline scrobble
  // -------------------------------------------------------------------------

  /// Queue a tracker scrobble for offline playback. Emits a [WatchStateNotifier]
  /// watched event so [TraktSyncService] handles the push + retry-on-failure.
  @override
  Future<void> queueOfflineScrobble(MediaItem item, {required double progressPercent}) async {
    appLogger.d('TraktWatchState: queueOfflineScrobble for ${item.title} (${progressPercent.toStringAsFixed(1)}%)');
    WatchStateNotifier().notifyWatched(item: item, isNowWatched: true);
  }

  /// Drain the Trakt sync queue. Delegates to [TraktSyncService] which owns
  /// the queue and retry logic. After draining, re-syncs the in-memory cache
  /// so any deferred offline items that were just pushed to Trakt are reflected
  /// in the UI without waiting for the next scheduled sync.
  @override
  Future<void> flushOfflineQueue() async {
    await TraktSyncService.instance.flushQueue();
    await syncWatchState(force: true);
    TrackerSyncNotifier.instance.notifySync();
  }

  /// Lazily fetches `/shows/{id}/progress/watched` for the given show metadata.
  ///
  /// Called when the user opens a show's detail screen. Provides accurate
  /// per-episode `completed` booleans and `aired` counts (not available from
  /// the boot-time `/sync/watched/shows` call). Only runs once per show per session.
  /// Returns true if new data was fetched and the caller should re-apply overlays.
  @override
  Future<bool> fetchShowProgressIfNeeded(MediaItem show) async {
    if (!isTrackerStateAuthorityEnabled) return false;
    if (_client == null) return false;

    // Resolve traktId via bridge map or ID/title lookup.
    int? traktId = _plexKeyToTraktShowId[show.id];
    if (traktId == null) {
      final ids = _idsFromItem(show);
      final state = _lookupShow(ids);
      traktId = state?.traktId;
    }
    if (traktId == null || traktId == 0) return false;
    if (_deepFetchedShows.contains(traktId)) return false;
    _deepFetchedShows.add(traktId);

    try {
      final data = await _client!.getShowWatchedProgress(traktId);
      _applyShowWatchedProgress(traktId, data);
      return true;
    } catch (e) {
      _deepFetchedShows.remove(traktId); // allow retry on next open
      appLogger.d('TraktWatchState: deep progress fetch failed for traktId=$traktId', error: e);
      return false;
    }
  }

  void _applyShowWatchedProgress(int traktId, Map<String, dynamic> data) {
    final completed = (data['completed'] as num?)?.toInt() ?? 0;
    final aired = (data['aired'] as num?)?.toInt() ?? 0;
    final lastWatchedAt = data['last_watched_at'] as String?;

    // Update show-level progress with accurate aired count.
    _cache.showProgress[traktId] = (completed, aired, lastWatchedAt);

    // Update per-episode state from the richer response.
    final seasons = data['seasons'] as List?;
    if (seasons != null) {
      final epMap = _cache.showEpisodes[traktId] ?? {};
      for (final season in seasons) {
        final seasonNum = (season['number'] as num?)?.toInt() ?? 0;
        final episodes = season['episodes'] as List?;
        if (episodes == null) continue;
        for (final ep in episodes) {
          final epNum = (ep['number'] as num?)?.toInt() ?? 0;
          final isCompleted = ep['completed'] as bool? ?? false;
          final epWatchedAt = ep['last_watched_at'] as String?;
          final key = 's${seasonNum}e$epNum';
          // Use completion status from this richer endpoint to set plays=1 when
          // the episode is completed but /sync/watched/shows had plays=0 (e.g.
          // watched via Plex VIP scrobble which updates progress but not play count).
          final existing = epMap[key];
          final existingPlays = existing?.plays ?? 0;
          epMap[key] = _TraktEpisodeState(
            plays: isCompleted && existingPlays == 0 ? 1 : existingPlays,
            lastWatchedAt: epWatchedAt ?? existing?.lastWatchedAt,
          );
        }
      }
      _cache.showEpisodes[traktId] = epMap;
    }
  }

  Future<void> _persistEnrichNotFound() async {
    try {
      await PlexApiCache.instance.put(_cacheServerId, _CacheKeys.enrichNotFound, {
        'showTs': _enrichNotFoundShowTs.map((k, v) => MapEntry(k.toString(), v)),
        'movieTs': _enrichNotFoundMovieTs.map((k, v) => MapEntry(k.toString(), v)),
      });
    } catch (e) {
      appLogger.d('TraktWatchState: enrich-not-found persist failed (non-fatal)', error: e);
    }
  }

  Future<void> _persistBridgeMaps() async {
    try {
      final cache = PlexApiCache.instance;
      await cache.put(_cacheServerId, _CacheKeys.bridgeMaps, {
        'plexKey': _traktShowIdToPlexKey.map((k, v) => MapEntry(k.toString(), v)),
        'thumb': _traktShowIdToThumb.map((k, v) => MapEntry(k.toString(), v)),
        'art': _traktShowIdToArt.map((k, v) => MapEntry(k.toString(), v)),
        'serverId': _traktShowIdToServerId.map((k, v) => MapEntry(k.toString(), v)),
        'movieThumb': _traktMovieIdToThumb.map((k, v) => MapEntry(k.toString(), v)),
        'movieKey': _traktMovieIdToPlexKey.map((k, v) => MapEntry(k.toString(), v)),
        'movieServerId': _traktMovieIdToServerId.map((k, v) => MapEntry(k.toString(), v)),
      });
    } catch (e) {
      appLogger.d('TraktWatchState: bridge map persist failed (non-fatal)', error: e);
    }
  }

  @override
  List<ContinueWatchingItem> getContinueWatchingItems() {
    if (!isTrackerStateAuthorityEnabled) return const [];
    final expiryCutoff = _nowEpoch - _pendingEvictionTtlSeconds;
    final fromStubs = _cache.playbackStubs.where((stub) {
      final id = stub.metadata.id;
      if (id.startsWith('trakt_movie_pb_')) {
        final traktId = int.tryParse(id.substring('trakt_movie_pb_'.length));
        if (traktId == null) return false;
        if (!_traktMovieIdToPlexKey.containsKey(traktId)) return false;
        final record = _pendingEvictions[traktId];
        if (record != null && record.evictedAt > expiryCutoff) return false;
        return true;
      }
      if (id.startsWith('trakt_episode_pb_') || id.startsWith('trakt_upnext_')) {
        final m = RegExp(r'trakt_(?:episode_pb|upnext)_(\d+)_').firstMatch(id);
        final showId = m != null ? int.tryParse(m.group(1)!) : null;
        if (showId == null) return false;
        if (!_traktShowIdToPlexKey.containsKey(showId)) return false;
        final record = _pendingEvictions[showId];
        if (record != null && record.evictedAt > expiryCutoff) {
          // Only suppress the exact evicted episode — a different ep key means
          // Trakt already advanced to the next episode, so let it through.
          final m2 = RegExp(r'_s(\d+)e(\d+)$').firstMatch(id);
          final stubEpKey = m2 != null ? 's${m2.group(1)}e${m2.group(2)}' : null;
          if (record.epKey == stubEpKey) return false;
        }
        return true;
      }
      return false;
    }).toList();
    if (_pendingNextEpisodes.isEmpty) return fromStubs;
    return ([...fromStubs, ..._pendingNextEpisodes]
      ..sort((a, b) => (b.metadata.lastViewedAt ?? 0).compareTo(a.metadata.lastViewedAt ?? 0)));
  }

  /// All playback stubs, unfiltered — used by enrichment to find stubs that
  /// need Plex GUID matching regardless of current bridge-map state.
  List<ContinueWatchingItem> getAllPlaybackStubs() => List.unmodifiable(_cache.playbackStubs);

  /// Fire the bridge-map-updated callback to refresh any listening UI (e.g.
  /// after marking stubs as not-found so Continue Watching re-renders).
  void notifyBridgeMapChanged() => _onBridgeMapUpdated?.call();

  /// Feed external IDs resolved outside this provider (e.g. from the scrobble
  /// path) for a Plex item whose metadata doesn't include a Guid array.
  /// Also immediately populates the movie bridge map when a Trakt state match
  /// is found, so [getContinueWatchingItems] can surface the stub without
  /// waiting for a separate [getOverrideFor] call.
  void feedExternalIds(String plexKey, ExternalIds ids, {String? thumbPath, String? serverId}) {
    if (!ids.hasAny) return;
    _fetchedExternalIds[plexKey] = ids;

    // Immediately wire up the bridge map so getContinueWatchingItems() can
    // surface in-progress movie stubs without a separate getOverrideFor call.
    // Check both the watched-movies state (fully watched) and the playback
    // reverse maps (in-progress only, not yet fully watched).
    final state = _lookupMovie(ids);
    final traktId = state?.traktId
        ?? (ids.imdb != null ? _cache.playbackTraktIdByImdb[ids.imdb] : null)
        ?? (ids.tmdb != null ? _cache.playbackTraktIdByTmdb[ids.tmdb] : null);
    if (traktId != null) {
      _plexMovieKeyToTraktMovieId[plexKey] = traktId;
      if (!_traktMovieIdToPlexKey.containsKey(traktId)) {
        _traktMovieIdToPlexKey[traktId] = plexKey;
        if (thumbPath != null) _traktMovieIdToThumb[traktId] = thumbPath;
        if (serverId != null) _traktMovieIdToServerId[traktId] = serverId;
        _onBridgeMapUpdated?.call();
      }
    }
  }

  /// Register a callback used to fetch external IDs for movies whose Plex
  /// metadata endpoint doesn't return a Guid array.  Set to null to disable.
  void setExternalIdsFetcher(Future<ExternalIds?> Function(String plexKey, String serverId)? fetcher) {
    _externalIdsFetcher = fetcher;
  }

  void _triggerBackgroundIdFetch(MediaItem item) {
    final key = item.id;
    final serverId = item.serverId;
    if (serverId == null || serverId.isEmpty) return;
    // Skip if already fetched (regardless of whether a Trakt match was found).
    if (_fetchedExternalIds.containsKey(key)) return;
    if (_pendingIdFetches.contains(key)) return;
    final fetcher = _externalIdsFetcher;
    if (fetcher == null) return;
    _pendingIdFetches.add(key);
    unawaited(
      fetcher(key, serverId).then((ids) {
        _pendingIdFetches.remove(key);
        if (ids != null && ids.hasAny) {
          feedExternalIds(key, ids, thumbPath: item.thumbPath, serverId: serverId);
          TrackerSyncNotifier.instance.notifySync();
        } else {
          // Mark as resolved-but-empty so we don't re-fetch on next render.
          _fetchedExternalIds[key] = const ExternalIds();
        }
        // Save once when the last concurrent fetch drains the pending set,
        // so a single write captures the complete map instead of 23 racing writes.
        if (_pendingIdFetches.isEmpty) unawaited(_saveExternalIds());
      }).catchError((Object _) {
        _pendingIdFetches.remove(key);
        if (_pendingIdFetches.isEmpty) unawaited(_saveExternalIds());
      }),
    );
  }

  /// Clear every in-memory cache and lookup map. Does not touch the on-disk
  /// cache (see [invalidateCache] for that). Used by [bindSession] on profile
  /// switch so the new profile starts with empty memory but the prior
  /// profile's persisted cache stays on disk for a future switch-back.
  void _resetInMemoryState() {
    _cache.clear();
    if (_cacheReadyCompleter.isCompleted) {
      _cacheReadyCompleter = Completer<void>();
    }
    _traktShowIdToPlexKey.clear();
    _traktShowIdToThumb.clear();
    _traktShowIdToArt.clear();
    _traktShowIdToServerId.clear();
    _traktMovieIdToThumb.clear();
    _traktMovieIdToPlexKey.clear();
    _traktMovieIdToServerId.clear();
    _plexKeyToTraktShowId.clear();
    _showByTraktId.clear();
    _movieByTraktId.clear();
    _plexMovieKeyToTraktMovieId.clear();
    _deepFetchedShows.clear();
    _enrichNotFoundShowTs.clear();
    _enrichNotFoundMovieTs.clear();
    _fetchedExternalIds.clear();
    _pendingIdFetches.clear();
    _pendingEvictions.clear();
    _nextEpisodeByStubId.clear();
    _resolvedEpisodePosition.clear();
    _plexSeToTraktSeKey.clear();
    _pendingNextEpisodes.clear();
    _allLeavesCache.clear();
    _guidIndexCache.clear();
    _guidIndexBuiltAt = null;
    _watchlistShowsRaw = const [];
    _watchlistMoviesRaw = const [];
    _postMarkRefreshTimer?.cancel();
    _postMarkRefreshTimer = null;
    // Keep _onBridgeMapUpdated and _externalIdsFetcher — these callbacks should
    // persist through cache clears.
  }

  @override
  Future<void> invalidateCache() async {
    _resetInMemoryState();
    final cache = PlexApiCache.instance;
    await Future.wait([
      cache.delete(_cacheServerId, _CacheKeys.watchedMovies),
      cache.delete(_cacheServerId, _CacheKeys.watchedShows),
      cache.delete(_cacheServerId, _CacheKeys.playback),
      cache.delete(_cacheServerId, _CacheKeys.upNext),
      cache.delete(_cacheServerId, _CacheKeys.lastActivities),
      cache.delete(_cacheServerId, _CacheKeys.bridgeMaps),
      cache.delete(_cacheServerId, _CacheKeys.enrichNotFound),
      cache.delete(_cacheServerId, _CacheKeys.externalIds),
      cache.delete(_cacheServerId, _CacheKeys.resolvedPositions),
      cache.delete(_cacheServerId, _CacheKeys.watchlistShows),
      cache.delete(_cacheServerId, _CacheKeys.watchlistMovies),
    ]);
    appLogger.d('TraktWatchState: cache invalidated (memory and persistent)');
    _onCachesInvalidated?.call();
  }

  // -------------------------------------------------------------------------
  // Optimistic eviction
  // -------------------------------------------------------------------------

  /// Immediately removes [item] from the in-memory playback cache so
  /// Continue Watching updates without waiting for the Trakt history push.
  /// A background [syncWatchState] confirms the final state.
  @override
  void evictFromPlayback(MediaItem item) {
    final kind = item.kind;
    appLogger.d('TraktWatchState: evictFromPlayback called — kind=${kind.name} id=${item.id} title="${item.title}"');
    if (kind == MediaKind.movie) {
      final traktId = _plexMovieKeyToTraktMovieId[item.id];
      if (traktId == null) {
        appLogger.w('TraktWatchState: evict failed — movie key ${item.id} not in bridge map');
        return;
      }
      _pendingEvictions[traktId] = (epKey: null, evictedAt: _nowEpoch);
      final before = _cache.playbackRaw.length;
      _cache.playbackRaw = _cache.playbackRaw.where((e) {
        final id = ((e['movie'] as Map<String, dynamic>?)?['ids']?['trakt'] as num?)?.toInt();
        return id != traktId;
      }).toList();
      appLogger.d('TraktWatchState: evicted movie traktId=$traktId (playback $before→${_cache.playbackRaw.length})');
    } else {
      // Show, season, or episode: key off the show's Plex rating key.
      final showPlexKey = switch (kind) {
        MediaKind.episode => item.grandparentId ?? item.id,
        MediaKind.season => item.parentId ?? item.id,
        _ => item.id,
      };
      final traktShowId = _plexKeyToTraktShowId[showPlexKey];
      if (traktShowId == null) {
        appLogger.w('TraktWatchState: evict failed — show plexKey=$showPlexKey not in bridge map');
        return;
      }
      _pendingEvictions[traktShowId] = (epKey: 's${item.parentIndex ?? 0}e${item.index ?? 0}', evictedAt: _nowEpoch);

      // Capture pre-fetched next episode before evicting the stub from cache.
      ContinueWatchingItem? evictedStub;
      for (final stub in _cache.playbackStubs) {
        final m = RegExp(r'trakt_(?:episode_pb|upnext)_(\d+)_').firstMatch(stub.metadata.id);
        final sid = m != null ? int.tryParse(m.group(1)!) : null;
        if (sid == traktShowId) { evictedStub = stub; break; }
      }

      final beforePb = _cache.playbackRaw.length;
      final beforeUn = _cache.upNextRaw.length;
      _cache.playbackRaw = _cache.playbackRaw.where((e) {
        final id = ((e['show'] as Map<String, dynamic>?)?['ids']?['trakt'] as num?)?.toInt();
        return id != traktShowId;
      }).toList();
      _cache.upNextRaw = _cache.upNextRaw.where((e) {
        final id =
            (e['show_id'] as num?)?.toInt() ??
            ((e['show'] as Map<String, dynamic>?)?['ids']?['trakt'] as num?)?.toInt();
        return id != traktShowId;
      }).toList();
      appLogger.d(
        'TraktWatchState: evicted show traktId=$traktShowId '
        '(playback $beforePb→${_cache.playbackRaw.length}, upNext $beforeUn→${_cache.upNextRaw.length})',
      );

      final nextEp = evictedStub?.nextEpisode;
      if (nextEp != null) {
        final nextWithTimestamp = nextEp.copyWith(lastViewedAt: _nowEpoch);
        _pendingNextEpisodes.add(ContinueWatchingItem(metadata: nextWithTimestamp, progress: 0.0));
        appLogger.d(
          'TraktWatchState: pre-fetched next ep ready — '
          'S${nextEp.parentIndex}E${nextEp.index} "${nextEp.title}" (${nextEp.id})',
        );
      } else {
        appLogger.d('TraktWatchState: no pre-fetched next ep for show $traktShowId — waiting for Trakt refresh');
      }
    }
    _buildContinueWatchingStubs();
    appLogger.d('TraktWatchState: eviction complete — ${_cache.playbackStubs.length} stubs remain');
  }

  void touchPlaybackEntryByIds(int traktShowId, int season, int episode) {
    final nowStr = DateTime.now().toUtc().toIso8601String();
    bool updated = false;
    for (var i = 0; i < _cache.playbackRaw.length; i++) {
      final entry = _cache.playbackRaw[i];
      if (entry['type'] != 'episode') continue;
      final entryShowId = ((entry['show'] as Map<String, dynamic>?)?['ids']?['trakt'] as num?)?.toInt();
      if (entryShowId != traktShowId) continue;
      final ep = entry['episode'] as Map<String, dynamic>?;
      if ((ep?['season'] as num?)?.toInt() != season) continue;
      if ((ep?['number'] as num?)?.toInt() != episode) continue;
      _cache.playbackRaw[i] = {...entry, 'paused_at': nowStr};
      updated = true;
      appLogger.t('TraktWatchState: touched paused_at for s${season}e$episode traktShowId=$traktShowId');
      break;
    }
    if (updated) {
      _buildPlaybackIndices();
      _buildContinueWatchingStubs();
    }
  }

  // -------------------------------------------------------------------------
  // Playback + up_next lightweight refresh (used by both _doSync and post-mark)
  // -------------------------------------------------------------------------

  /// Fetch `/sync/playback` and `/sync/up_next_nitro`, update the in-memory cache,
  /// and rebuild stubs. Called by the `_doSync` playback-only path and by
  /// [schedulePlaybackRefresh] after a successful Trakt history push.
  Future<void> _refreshPlaybackAndUpNext(TraktClient client) async {
    _pendingNextEpisodes.clear(); // real Trakt data takes over from here
    List<dynamic> moviesRaw = [], episodesRaw = [], upNextItemsRaw = [];
    await Future.wait([
      client.getPlaybackMovies().then((v) => moviesRaw = v),
      client.getPlaybackEpisodes().then((v) => episodesRaw = v),
      client.getUpNextItems().then((v) => upNextItemsRaw = v),
    ]);
    _cache.playbackRaw = [...moviesRaw, ...episodesRaw].whereType<Map<String, dynamic>>().toList();
    _cache.upNextRaw = upNextItemsRaw.whereType<Map<String, dynamic>>().toList();
    _logPlaybackResponse(_cache.playbackRaw);
    _buildPlaybackIndices();
    _buildContinueWatchingStubs();
    _onBridgeMapUpdated?.call();
    unawaited(_persistToCache(null));
  }

  /// Schedule a debounced playback+up_next refresh ~1.5 s from now.
  /// Called after each successful Trakt history-add so the next episode appears
  /// in Continue Watching without waiting for the next app-launch sync.
  /// Debounced so bulk season marks coalesce into a single fetch.
  void schedulePlaybackRefresh() {
    _postMarkRefreshTimer?.cancel();
    _postMarkRefreshTimer = Timer(const Duration(milliseconds: 1500), () {
      final client = _client;
      if (client == null) return;
      unawaited(
        _refreshPlaybackAndUpNext(client)
            .then((_) => TrackerSyncNotifier.instance.notifySync())
            .catchError((Object e) {
          appLogger.d('TraktWatchState: post-mark refresh failed (non-fatal)', error: e);
        }),
      );
    });
  }

  // -------------------------------------------------------------------------
  // Sync logic
  // -------------------------------------------------------------------------

  Future<void> _doSync(TraktClient client, {bool force = false}) async {
    // 1. Fetch last_activities to determine whether data is stale.
    Map<String, dynamic>? newActivities;
    try {
      newActivities = await client.getLastActivities();
    } catch (e) {
      appLogger.d('TraktWatchState: getLastActivities failed', error: e);
    }

    final needsRefresh = force || _needsRefresh(newActivities);

    // Trakt unreachable (getLastActivities threw) — preserve existing cache rather
    // than risk overwriting good data with empty results from a failed full sync.
    // cacheReady is completed so UI can proceed with whatever is already loaded.
    if (newActivities == null && !_cache.isEmpty) {
      appLogger.w('TraktWatchState: Trakt unreachable — keeping cached watch data');
      if (!_cacheReadyCompleter.isCompleted) _cacheReadyCompleter.complete();
      return;
    }

    if (!needsRefresh && !_cache.isEmpty) {
      // Lightweight refresh: only re-fetches /sync/playback and /sync/up_next to
      // update in-progress items without re-fetching the full watched history.
      // Full rebuild (below) clears resolved-show/movie caches so getOverrideFor()
      // picks up renames and GUID changes — triggered when last_activities shows new
      // data or force=true (e.g. after a manual mark-watched or app foreground).
      appLogger.d('TraktWatchState: watched data up-to-date, refreshing playback only');
      try {
        await _refreshPlaybackAndUpNext(client);
      } catch (e) {
        appLogger.w('TraktWatchState: playback refresh failed (non-fatal)', error: e);
      }
      if (!_cacheReadyCompleter.isCompleted) _cacheReadyCompleter.complete();
      return;
    }

    appLogger.d('TraktWatchState: starting full sync (force=$force)');

    // 2. Fetch all raw data in parallel.
    List<dynamic> moviesRaw = [];
    List<dynamic> showsRaw = [];
    List<dynamic> playbackMoviesRaw = [];
    List<dynamic> playbackEpisodesRaw = [];
    List<dynamic> upNextItemsRaw = [];

    await Future.wait([
      client.getWatchedMovies().then((v) => moviesRaw = v).catchError((Object e) {
        appLogger.w('TraktWatchState: getWatchedMovies failed', error: e);
        return <dynamic>[];
      }),
      client.getWatchedShows().then((v) => showsRaw = v).catchError((Object e) {
        appLogger.w('TraktWatchState: getWatchedShows failed', error: e);
        return <dynamic>[];
      }),
      client.getPlaybackMovies().then((v) => playbackMoviesRaw = v).catchError((Object e) {
        appLogger.w('TraktWatchState: getPlaybackMovies failed', error: e);
        return <dynamic>[];
      }),
      client.getPlaybackEpisodes().then((v) => playbackEpisodesRaw = v).catchError((Object e) {
        appLogger.w('TraktWatchState: getPlaybackEpisodes failed', error: e);
        return <dynamic>[];
      }),
      client.getUpNextItems().then((v) => upNextItemsRaw = v).catchError((Object e) {
        appLogger.w('TraktWatchState: getUpNextItems failed', error: e);
        return <dynamic>[];
      }),
    ]);

    // 3. Cast and store raw responses.
    _cache.watchedMoviesRaw = moviesRaw.whereType<Map<String, dynamic>>().toList();
    _cache.watchedShowsRaw = showsRaw.whereType<Map<String, dynamic>>().toList();
    _cache.playbackRaw = [...playbackMoviesRaw, ...playbackEpisodesRaw].whereType<Map<String, dynamic>>().toList();
    _cache.upNextRaw = upNextItemsRaw.whereType<Map<String, dynamic>>().toList();
    if (newActivities != null) _cache.lastActivities = newActivities;

    // 4. Build lookup indices and continue-watching stubs.
    _buildMovieIndices();
    _buildShowIndices();
    _buildPlaybackIndices();
    _logPlaybackResponse(_cache.playbackRaw);
    _buildContinueWatchingStubs();

    // 5. Persist to ApiCache.
    await _persistToCache(newActivities);

    appLogger.d(
      'TraktWatchState: sync complete — '
      '${_cache.watchedMoviesRaw.length} movies, '
      '${_cache.watchedShowsRaw.length} shows, '
      '${_cache.playbackRaw.length} playback items, '
      '${_cache.upNextRaw.length} up-next items, '
      '${_cache.playbackStubs.length} continue-watching stubs',
    );

    // 6. Unblock consumers awaiting cacheReady.
    if (!_cacheReadyCompleter.isCompleted) _cacheReadyCompleter.complete();

    // 7. Non-blocking background fetches for watchlist and ratings.
    //    Watchlist also populates in-memory state so the playlists tab can
    //    surface it when authority is on (see _syncWatchlist).
    unawaited(_syncWatchlist(client));
    unawaited(_fetchAndCacheList(client.getRatings, _CacheKeys.ratingsShows));
    unawaited(_fetchAndCacheList(() => client.getRatings(type: 'movies'), _CacheKeys.ratingsMovies));
  }

  /// Generic helper: fetch a list endpoint and persist it to ApiCache.
  Future<void> _fetchAndCacheList(Future<List<dynamic>> Function() fetch, String cacheKey) async {
    try {
      final raw = await fetch();
      final typed = raw.whereType<Map<String, dynamic>>().toList();
      await _saveList(PlexApiCache.instance, cacheKey, typed);
    } catch (e) {
      appLogger.w('TraktWatchState: cache fetch failed for $cacheKey (non-fatal)', error: e);
    }
  }

  /// Fetch shows + movies watchlist, store in memory, and persist. Fires a
  /// sync notify if either list arrived so the playlists tab can rebuild.
  Future<void> _syncWatchlist(TraktClient client) async {
    var updated = false;
    try {
      final shows = (await client.getWatchlist()).whereType<Map<String, dynamic>>().toList();
      _watchlistShowsRaw = shows;
      await _saveList(PlexApiCache.instance, _CacheKeys.watchlistShows, shows);
      updated = true;
    } catch (e) {
      appLogger.w('TraktWatchState: watchlist (shows) sync failed (non-fatal)', error: e);
    }
    try {
      final movies = (await client.getWatchlist(type: 'movies')).whereType<Map<String, dynamic>>().toList();
      _watchlistMoviesRaw = movies;
      await _saveList(PlexApiCache.instance, _CacheKeys.watchlistMovies, movies);
      updated = true;
    } catch (e) {
      appLogger.w('TraktWatchState: watchlist (movies) sync failed (non-fatal)', error: e);
    }
    if (updated) TrackerSyncNotifier.instance.notifySync();
  }

  bool _needsRefresh(Map<String, dynamic>? newActivities) {
    if (newActivities == null) return true;
    final stored = _cache.lastActivities;
    if (stored == null) return true;

    // Compare the top-level 'all' timestamp.
    final storedAll = stored['all'] as String?;
    final newAll = newActivities['all'] as String?;
    if (storedAll == null || newAll == null) return true;
    return storedAll != newAll;
  }

  // Build-method call order: _buildMovieIndices → _buildShowIndices → _buildPlaybackIndices → _buildContinueWatchingStubs.
  // Each method in this chain depends on output from its predecessors; changing
  // the order or skipping a method will produce incorrect CW stubs.
  void _buildMovieIndices() {
    _cache.byImdb.clear();
    _cache.byTmdb.clear();
    _cache.byTvdb.clear();
    _cache.resolvedMovies.clear(); // invalidate resolved cache on every rebuild
    _movieByTraktId.clear();

    for (final item in _cache.watchedMoviesRaw) {
      final movie = item['movie'] as Map<String, dynamic>?;
      if (movie == null) continue;
      final ids = movie['ids'] as Map<String, dynamic>?;
      if (ids == null) continue;

      final traktId = (ids['trakt'] as num?)?.toInt() ?? 0;
      final plays = (item['plays'] as num?)?.toInt() ?? 0;
      final lastWatched = item['last_watched_at'] as String?;
      final state = _TraktState(plays: plays, lastWatchedAt: lastWatched, traktId: traktId);

      final imdb = ids['imdb'] as String?;
      final tmdb = (ids['tmdb'] as num?)?.toInt();
      if (imdb != null && imdb.isNotEmpty) _cache.byImdb[imdb] = state;
      if (tmdb != null) _cache.byTmdb[tmdb] = state;
      if (traktId > 0) _movieByTraktId[traktId] = state;
    }
  }

  // Called after _buildMovieIndices. Populates showEpisodes, showProgress, and
  // per-show ID lookup maps (_cache.showBy*). Must run before _buildPlaybackIndices.
  void _buildShowIndices() {
    // Two version increments per full sync (_buildShowIndices + _buildPlaybackIndices)
    // are intentional: each invalidates the stale-pause cache independently so that
    // partial refreshes (playback-only via _refreshPlaybackAndUpNext) also trigger
    // a cache miss. Do not consolidate into a single increment without updating
    // _refreshPlaybackAndUpNext to increment itself.
    _rawDataVersion++;
    _cache.showByImdb.clear();
    _cache.showByTmdb.clear();
    _cache.showByTvdb.clear();
    _cache.showEpisodes.clear();
    _cache.showProgress.clear();
    _cache.resolvedShows.clear(); // invalidate resolved cache on every rebuild
    _grandparentIdsNotFound.clear();

    for (final item in _cache.watchedShowsRaw) {
      final show = item['show'] as Map<String, dynamic>?;
      if (show == null) continue;
      final ids = show['ids'] as Map<String, dynamic>?;
      if (ids == null) continue;

      final traktId = (ids['trakt'] as num?)?.toInt() ?? 0;
      final plays = (item['plays'] as num?)?.toInt() ?? 0;
      final lastWatched = item['last_watched_at'] as String?;
      final state = _TraktState(plays: plays, lastWatchedAt: lastWatched, traktId: traktId);

      final imdb = ids['imdb'] as String?;
      final tmdb = (ids['tmdb'] as num?)?.toInt();
      final tvdb = (ids['tvdb'] as num?)?.toInt();
      if (imdb != null && imdb.isNotEmpty) _cache.showByImdb[imdb] = state;
      if (tmdb != null) _cache.showByTmdb[tmdb] = state;
      if (tvdb != null) _cache.showByTvdb[tvdb] = state;

      if (traktId > 0) _showByTraktId[traktId] = state;

      // Build per-episode map: "s{season}e{episode}" -> state.
      final seasons = item['seasons'] as List?;
      if (seasons != null && traktId > 0) {
        final epMap = <String, _TraktEpisodeState>{};
        int watchedCount = 0;
        for (final season in seasons) {
          final seasonNum = (season['number'] as num?)?.toInt() ?? 0;
          final episodes = season['episodes'] as List?;
          if (episodes == null) continue;
          for (final ep in episodes) {
            final epNum = (ep['number'] as num?)?.toInt() ?? 0;
            final epPlays = (ep['plays'] as num?)?.toInt() ?? 0;
            final epLastWatched = ep['last_watched_at'] as String?;
            final key = 's${seasonNum}e$epNum';
            epMap[key] = _TraktEpisodeState(plays: epPlays, lastWatchedAt: epLastWatched);
            if (epPlays > 0) watchedCount++;
          }
        }
        _cache.showEpisodes[traktId] = epMap;
        // Store (watched, 0, lastWatched) — aired count not available from
        // /sync/watched/shows; 0 is a sentinel meaning "use Plex's leafCount".
        _cache.showProgress[traktId] = (watchedCount, 0, lastWatched);
      }
    }
  }

  // Called after _buildShowIndices. Populates episodePlayback and playback reverse
  // indices from _cache.playbackRaw. Must run before _buildContinueWatchingStubs.
  void _buildPlaybackIndices() {
    _rawDataVersion++; // see _buildShowIndices for why both methods increment
    _cache.playbackByImdb.clear();
    _cache.playbackByTmdb.clear();
    _cache.playbackByTvdb.clear();
    _cache.playbackByTraktId.clear();
    _cache.episodePlayback.clear();

    for (final item in _cache.playbackRaw) {
      final progress = (item['progress'] as num?)?.toDouble() ?? 0.0;
      final itemType = item['type'] as String?;

      if (itemType == 'movie') {
        final movie = item['movie'] as Map<String, dynamic>?;
        final ids = movie?['ids'] as Map<String, dynamic>?;
        if (ids == null) continue;
        final imdb = ids['imdb'] as String?;
        final tmdb = (ids['tmdb'] as num?)?.toInt();
        final tvdb = (ids['tvdb'] as num?)?.toInt();
        final traktId = (ids['trakt'] as num?)?.toInt();
        if (imdb != null && imdb.isNotEmpty) _cache.playbackByImdb[imdb] = progress;
        if (tmdb != null) _cache.playbackByTmdb[tmdb] = progress;
        if (tvdb != null) _cache.playbackByTvdb[tvdb] = progress;
        // traktId-keyed fallback: used when imdb/tmdb cross-match fails
        if (traktId != null && traktId > 0) {
          _cache.playbackByTraktId[traktId] = progress;
          // Reverse maps for feedExternalIds bridge-map population.
          if (imdb != null && imdb.isNotEmpty) _cache.playbackTraktIdByImdb[imdb] = traktId;
          if (tmdb != null) _cache.playbackTraktIdByTmdb[tmdb] = traktId;
        }
      } else if (itemType == 'episode') {
        final show = item['show'] as Map<String, dynamic>?;
        final episode = item['episode'] as Map<String, dynamic>?;
        if (show == null || episode == null) continue;
        final showIds = show['ids'] as Map<String, dynamic>?;
        if (showIds == null) continue;
        final showTraktId = (showIds['trakt'] as num?)?.toInt() ?? 0;
        final season = (episode['season'] as num?)?.toInt() ?? 0;
        final number = (episode['number'] as num?)?.toInt() ?? 0;
        if (showTraktId > 0) {
          _cache.episodePlayback['$showTraktId:s${season}e$number'] = (
            progress: progress,
            pausedAt: item['paused_at'] as String?,
          );
        }
      }
    }
  }

  /// Schedules a [_buildContinueWatchingStubs] call via microtask.
  /// Multiple calls within the same synchronous block coalesce into one rebuild,
  /// preventing O(N) redundant iterations when enriching N shows/episodes at once.
  void _scheduleBuildContinueWatchingStubs() {
    if (_stubRebuildPending) return;
    _stubRebuildPending = true;
    scheduleMicrotask(() {
      _stubRebuildPending = false;
      _buildContinueWatchingStubs();
    });
  }

  void _buildContinueWatchingStubs() {
    final stubs = <ContinueWatchingItem>[];
    final seenMovieIds = <int>{};

    // 1. Movie stubs from /sync/playback/movies.
    for (final item in _cache.playbackRaw.where((i) => i['type'] == 'movie')) {
      final traktId = ((item['movie'] as Map<String, dynamic>?)?['ids']?['trakt'] as num?)?.toInt() ?? 0;
      if (traktId > 0 && seenMovieIds.add(traktId)) {
        final stub = _stubFromMoviePlayback(item);
        if (stub != null) stubs.add(stub);
      }
    }

    // 2. Build override map: showId → paused-episode stub from /sync/playback/episodes.
    //    These replace the up_next stub for shows actively mid-watch (correct ep + progress bar).
    //    When Trakt returns multiple episode entries for the same show (e.g. current ep +
    //    a previously-paused ep), prefer the one with the latest paused_at timestamp so a
    //    stale entry from a prior session never displaces the most-recently-paused episode.
    final Map<int, ({ContinueWatchingItem stub, String pausedAt})> pausedCandidates = {};
    for (final item in _cache.playbackRaw.where((i) => i['type'] == 'episode')) {
      final showId = ((item['show'] as Map<String, dynamic>?)?['ids']?['trakt'] as num?)?.toInt() ?? 0;
      if (showId <= 0) continue;
      final stub = _stubFromEpisodePlayback(item);
      if (stub == null) continue;
      final pausedAt = item['paused_at'] as String? ?? '';
      final existing = pausedCandidates[showId];
      if (existing == null || pausedAt.compareTo(existing.pausedAt) > 0) {
        pausedCandidates[showId] = (stub: stub, pausedAt: pausedAt);
      }
    }
    final pausedByShowId = pausedCandidates.map((k, v) => MapEntry(k, v.stub));

    // 3. Episode stubs: up_next_nitro as base (all shows), override with paused stub if available.
    //    Only override when the paused episode is NOT already completed in /sync/watched/shows —
    //    a completed episode with a lingering pause point is stale (watched on another device).
    final seenShowIds = <int>{};
    for (final item in _cache.upNextRaw) {
      final showId =
          (item['show_id'] as num?)?.toInt() ??
          ((item['show'] as Map<String, dynamic>?)?['ids']?['trakt'] as num?)?.toInt() ??
          0;
      if (showId == 0 || !seenShowIds.add(showId)) continue;

      ContinueWatchingItem? stub;
      final pausedStub = pausedByShowId[showId];
      if (pausedStub != null) {
        // Invalidate stale-pause cache when raw data changed since last build.
        if (_stalePauseCacheVersion != _rawDataVersion) {
          _stalePauseCache.clear();
          _stalePauseCacheVersion = _rawDataVersion;
        }

        final bool alreadyWatched;
        if (_stalePauseCache.containsKey(showId)) {
          alreadyWatched = _stalePauseCache[showId]!;
        } else {
          final season = pausedStub.metadata.parentIndex;
          final ep = pausedStub.metadata.index;
          _TraktEpisodeState? epState;
          if (season != null && ep != null) {
            epState = _cache.showEpisodes[showId]?['s${season}e$ep'];
          }
          final pbKey = season != null && ep != null ? '$showId:s${season}e$ep' : null;
          final pausedAt = DateTime.tryParse(_cache.episodePlayback[pbKey]?.pausedAt ?? '');
          final showLastWatchedAt = DateTime.tryParse(_cache.showProgress[showId]?.$3 ?? '');

          // Check 1 — show-level: any episode watched more recently than the pause.
          bool computed =
              pausedAt != null && showLastWatchedAt != null && showLastWatchedAt.isAfter(pausedAt);

          // Check 2 — episode-level: this specific episode was completed after its pause.
          if (!computed && (epState?.plays ?? 0) > 0) {
            final watchedAt = DateTime.tryParse(epState?.lastWatchedAt ?? '');
            computed = pausedAt == null || watchedAt == null || !pausedAt.isAfter(watchedAt);
          }

          // Check 3 — race condition: /sync/watched/shows may lag behind up_next_nitro
          // after a recent scrobble. If up_next_nitro's next episode is strictly ahead of
          // the paused episode, the pause is stale even if plays is still 0.
          if (!computed) {
            final nextEp = (item['progress'] as Map<String, dynamic>?)?['next_episode'] as Map<String, dynamic>?;
            final upNextSeason = (nextEp?['season'] as num?)?.toInt() ?? 0;
            final upNextEp = (nextEp?['number'] as num?)?.toInt() ?? 0;
            final pausedSeason = season ?? 0;
            final pausedEp = ep ?? 0;
            final upNextIsAhead =
                upNextSeason > pausedSeason || (upNextSeason == pausedSeason && upNextEp > pausedEp);
            if (upNextIsAhead) computed = true;
          }
          _stalePauseCache[showId] = computed;
          alreadyWatched = computed;
        }

        if (alreadyWatched) {
          stub = _stubFromUpNextItem(item);
        } else {
          // The /sync/playback endpoint doesn't include Trakt's Plex VIP integration IDs,
          // so the paused stub may lack the plex:// GUID. Inject it from the up_next_nitro
          // item which always carries the full show.ids.plex object.
          final upNextShowIds = (item['show'] as Map<String, dynamic>?)?['ids'] as Map<String, dynamic>?;
          final upNextPlexGuid = (upNextShowIds?['plex'] as Map<String, dynamic>?)?['guid'] as String?;
          stub = (upNextPlexGuid != null && upNextPlexGuid.isNotEmpty)
              ? _injectPlexGuid(pausedStub, upNextPlexGuid)
              : pausedStub;
        }
      } else {
        stub = _stubFromUpNextItem(item);
      }
      if (stub != null) stubs.add(stub);
    }

    // Edge case: show is in /sync/playback/episodes but NOT in up_next_nitro — still add it.
    for (final entry in pausedByShowId.entries) {
      if (!seenShowIds.contains(entry.key)) stubs.add(entry.value);
    }

    stubs.sort((a, b) => (b.metadata.lastViewedAt ?? 0).compareTo(a.metadata.lastViewedAt ?? 0));
    _cache.playbackStubs = stubs;

    // Prune _pendingEvictions after each rebuild.
    // Movies: guard cleared when the movie is gone from new stubs.
    // Shows: guard cleared when either (a) the show is gone, or (b) the new stub
    //   is for a different episode — meaning Trakt advanced to the next ep.
    //   This allows the next episode to appear immediately after a history push.
    if (_pendingEvictions.isNotEmpty) {
      final Map<int, String?> stubShowEpKeys = {}; // showId → stub ep key
      final Set<int> stubMovieIds = {};
      for (final stub in stubs) {
        final id = stub.metadata.id;
        if (id.startsWith('trakt_movie_pb_')) {
          final traktId = int.tryParse(id.substring('trakt_movie_pb_'.length));
          if (traktId != null) stubMovieIds.add(traktId);
        } else if (id.startsWith('trakt_episode_pb_') || id.startsWith('trakt_upnext_')) {
          final m = RegExp(r'trakt_(?:episode_pb|upnext)_(\d+)_s(\d+)e(\d+)').firstMatch(id);
          if (m != null) {
            final showId = int.tryParse(m.group(1)!);
            if (showId != null) stubShowEpKeys[showId] = 's${m.group(2)}e${m.group(3)}';
          }
        }
      }
      final expiryCutoff = _nowEpoch - _pendingEvictionTtlSeconds;
      _pendingEvictions.removeWhere((traktId, record) {
        if (record.evictedAt <= expiryCutoff) {
          appLogger.w('TraktWatchState: pendingEviction $traktId expired TTL without confirmation');
          return true;
        }
        if (record.epKey == null) {
          // Movie guard: clear when the movie is gone from new stubs.
          final confirmed = !stubMovieIds.contains(traktId);
          if (confirmed) appLogger.d('TraktWatchState: pendingEviction movie $traktId confirmed gone');
          return confirmed;
        } else {
          // Show guard: clear when show is gone OR new stub is a different episode.
          final newEpKey = stubShowEpKeys[traktId];
          final gone = newEpKey == null;
          final advanced = newEpKey != null && newEpKey != record.epKey;
          if (gone) appLogger.d('TraktWatchState: pendingEviction show $traktId confirmed gone');
          if (advanced) appLogger.d('TraktWatchState: pendingEviction show $traktId advanced to $newEpKey (was ${record.epKey})');
          return gone || advanced;
        }
      });
    }
  }

  ContinueWatchingItem _injectPlexGuid(ContinueWatchingItem stub, String plexGuid) {
    final plexUri = 'plex://show/$plexGuid';
    final existingRaw = stub.metadata.raw ?? {};
    final existingGuids = List<Map<String, dynamic>>.from(existingRaw['Guid'] as List? ?? []);
    if (existingGuids.any((g) => g['id'] == plexUri)) return stub;
    final newGuids = [{'id': plexUri}, ...existingGuids];
    return ContinueWatchingItem(
      metadata: stub.metadata.copyWith(raw: {...existingRaw, 'Guid': newGuids}),
      progress: stub.progress,
      nextEpisode: stub.nextEpisode,
    );
  }

  ContinueWatchingItem? _stubFromMoviePlayback(Map<String, dynamic> item) {
    final movie = item['movie'] as Map<String, dynamic>?;
    if (movie == null) return null;
    final ids = movie['ids'] as Map<String, dynamic>?;
    if (ids == null) return null;

    final traktId = (ids['trakt'] as num?)?.toInt() ?? 0;
    if (traktId == 0) return null;

    final progress = (item['progress'] as num?)?.toDouble() ?? 0.0;
    final pausedAt = item['paused_at'] as String?;

    final imdb = ids['imdb'] as String?;
    final tmdb = (ids['tmdb'] as num?)?.toInt();

    final externalGuids = <Map<String, String>>[
      if (imdb != null && imdb.isNotEmpty) {'id': 'imdb://$imdb'},
      if (tmdb != null) {'id': 'tmdb://$tmdb'},
    ];

    final plexKey = _traktMovieIdToPlexKey[traktId];
    final plexThumb = _traktMovieIdToThumb[traktId];
    final plexServerId = _traktMovieIdToServerId[traktId];

    final images = movie['images'] as Map<String, dynamic>?;
    final traktPoster = _extractTraktImage(images, 'poster');
    final traktFanart = _extractTraktImage(images, 'fanart');

    final runtimeMin = (movie['runtime'] as num?)?.toInt();
    final duration = runtimeMin != null ? runtimeMin * 60 * 1000 : null;
    final viewOffset = (duration != null && progress > 0) ? (progress / 100.0 * duration).toInt() : 1;

    final metadata = MediaItem.plex(
      id: 'trakt_movie_pb_$traktId',
      kind: MediaKind.movie,
      title: movie['title'] as String?,
      year: (movie['year'] as num?)?.toInt(),
      thumbPath: plexThumb ?? traktPoster,
      artPath: traktFanart,
      serverId: plexServerId,
      grandparentId: plexKey,
      viewOffsetMs: viewOffset,
      durationMs: duration,
      lastViewedAt: _isoToUnix(pausedAt),
      raw: externalGuids.isEmpty ? null : {'Guid': externalGuids},
    );

    return ContinueWatchingItem(metadata: metadata, progress: progress);
  }

  ContinueWatchingItem? _stubFromEpisodePlayback(Map<String, dynamic> item) {
    final show = item['show'] as Map<String, dynamic>?;
    final episode = item['episode'] as Map<String, dynamic>?;
    if (show == null || episode == null) return null;

    final showIds = show['ids'] as Map<String, dynamic>?;
    if (showIds == null) return null;

    final showTraktId = (showIds['trakt'] as num?)?.toInt() ?? 0;
    if (showTraktId == 0) return null;

    final season = (episode['season'] as num?)?.toInt() ?? 0;
    final epNumber = (episode['number'] as num?)?.toInt() ?? 0;
    final progress = (item['progress'] as num?)?.toDouble() ?? 0.0;
    final pausedAt = item['paused_at'] as String?;

    final plexGuid = (showIds['plex'] as Map<String, dynamic>?)?['guid'] as String?;
    final imdb = showIds['imdb'] as String?;
    final tmdb = (showIds['tmdb'] as num?)?.toInt();
    final tvdb = (showIds['tvdb'] as num?)?.toInt();
    final externalGuids = <Map<String, String>>[
      if (plexGuid != null && plexGuid.isNotEmpty) {'id': 'plex://show/$plexGuid'},
      if (imdb != null && imdb.isNotEmpty) {'id': 'imdb://$imdb'},
      if (tmdb != null) {'id': 'tmdb://$tmdb'},
      if (tvdb != null) {'id': 'tvdb://$tvdb'},
    ];

    final plexShowKey = _traktShowIdToPlexKey[showTraktId];
    final plexServerId = _traktShowIdToServerId[showTraktId];
    final plexThumb = _traktShowIdToThumb[showTraktId];
    final plexArt = _traktShowIdToArt[showTraktId];

    final showImages = show['images'] as Map<String, dynamic>?;
    final traktPoster = _extractTraktImage(showImages, 'poster');
    final traktFanart = _extractTraktImage(showImages, 'fanart');
    final epImages = episode['images'] as Map<String, dynamic>?;
    final traktEpThumb = _extractTraktImage(epImages, 'screenshot');

    final episodeIds = episode['ids'] as Map<String, dynamic>?;
    final episodeTvdb = (episodeIds?['tvdb'] as num?)?.toInt();
    final episodeTmdb = (episodeIds?['tmdb'] as num?)?.toInt();

    final runtimeMin = (episode['runtime'] as num?)?.toInt() ?? (show['runtime'] as num?)?.toInt();
    final duration = runtimeMin != null ? runtimeMin * 60 * 1000 : null;
    final viewOffset = (duration != null && progress > 0) ? (progress / 100.0 * duration).toInt() : 1;

    final stubId = 'trakt_episode_pb_${showTraktId}_s${season}e$epNumber';
    final resolved = _resolvedEpisodePosition[stubId];

    final metadata = MediaItem.plex(
      id: stubId,
      kind: MediaKind.episode,
      title: episode['title'] as String?,
      summary: episode['overview'] as String?,
      grandparentTitle: show['title'] as String?,
      grandparentId: plexShowKey,
      grandparentThumbPath: plexThumb ?? traktPoster,
      grandparentArtPath: plexArt ?? traktFanart,
      thumbPath: traktEpThumb ?? resolved?.thumb,
      serverId: plexServerId,
      year: (show['year'] as num?)?.toInt(),
      parentIndex: resolved?.season ?? season,
      index: resolved?.episode ?? epNumber,
      viewOffsetMs: viewOffset,
      durationMs: duration,
      lastViewedAt: _isoToUnix(pausedAt),
      raw: {
        if (externalGuids.isNotEmpty) 'Guid': externalGuids,
        'episodeTvdb': ?episodeTvdb,
        'episodeTmdb': ?episodeTmdb,
      },
    );

    return ContinueWatchingItem(metadata: metadata, progress: progress, nextEpisode: _nextEpisodeByStubId[stubId]);
  }

  ContinueWatchingItem? _stubFromUpNextItem(Map<String, dynamic> item) {
    final show = item['show'] as Map<String, dynamic>?;
    final progress = item['progress'] as Map<String, dynamic>?;
    if (show == null || progress == null) return null;

    final nextEp = progress['next_episode'] as Map<String, dynamic>?;
    if (nextEp == null) return null;

    final showIds = show['ids'] as Map<String, dynamic>?;
    if (showIds == null) return null;

    final showTraktId = (item['show_id'] as num?)?.toInt() ?? (showIds['trakt'] as num?)?.toInt() ?? 0;
    if (showTraktId == 0) return null;

    final season = (nextEp['season'] as num?)?.toInt() ?? 0;
    final epNumber = (nextEp['number'] as num?)?.toInt() ?? 0;
    final lastWatchedAt = progress['last_watched_at'] as String?;

    final plexGuid = (showIds['plex'] as Map<String, dynamic>?)?['guid'] as String?;
    final imdb = showIds['imdb'] as String?;
    final tmdb = (showIds['tmdb'] as num?)?.toInt();
    final tvdb = (showIds['tvdb'] as num?)?.toInt();
    final externalGuids = <Map<String, String>>[
      if (plexGuid != null && plexGuid.isNotEmpty) {'id': 'plex://show/$plexGuid'},
      if (imdb != null && imdb.isNotEmpty) {'id': 'imdb://$imdb'},
      if (tmdb != null) {'id': 'tmdb://$tmdb'},
      if (tvdb != null) {'id': 'tvdb://$tvdb'},
    ];

    final plexShowKey = _traktShowIdToPlexKey[showTraktId];
    final plexServerId = _traktShowIdToServerId[showTraktId];
    final plexThumb = _traktShowIdToThumb[showTraktId];
    final plexArt = _traktShowIdToArt[showTraktId];

    final showImages = show['images'] as Map<String, dynamic>?;
    final traktPoster = _extractTraktImage(showImages, 'poster');
    final traktFanart = _extractTraktImage(showImages, 'fanart');
    final epImages = nextEp['images'] as Map<String, dynamic>?;
    final traktEpThumb = _extractTraktImage(epImages, 'screenshot');

    final nextEpIds = nextEp['ids'] as Map<String, dynamic>?;
    final nextEpTvdb = (nextEpIds?['tvdb'] as num?)?.toInt();
    final nextEpTmdb = (nextEpIds?['tmdb'] as num?)?.toInt();

    final stubId = 'trakt_upnext_${showTraktId}_s${season}e$epNumber';
    final resolved = _resolvedEpisodePosition[stubId];

    final metadata = MediaItem.plex(
      id: stubId,
      kind: MediaKind.episode,
      title: nextEp['title'] as String?,
      summary: nextEp['overview'] as String?,
      grandparentTitle: show['title'] as String?,
      grandparentId: plexShowKey,
      grandparentThumbPath: plexThumb ?? traktPoster,
      grandparentArtPath: plexArt ?? traktFanart,
      thumbPath: traktEpThumb ?? resolved?.thumb,
      serverId: plexServerId,
      year: (show['year'] as num?)?.toInt(),
      parentIndex: resolved?.season ?? season,
      index: resolved?.episode ?? epNumber,
      lastViewedAt: _isoToUnix(lastWatchedAt),
      raw: {
        if (externalGuids.isNotEmpty) 'Guid': externalGuids,
        'episodeTvdb': ?nextEpTvdb,
        'episodeTmdb': ?nextEpTmdb,
      },
    );

    return ContinueWatchingItem(metadata: metadata, progress: 0.0, nextEpisode: _nextEpisodeByStubId[stubId]);
  }

  // -------------------------------------------------------------------------
  // Override builders
  // -------------------------------------------------------------------------

  WatchStateOverride? _overrideForMovie(MediaItem item, ExternalIds ids) {
    // 1. Resolved-cache fast path — populated on first successful match.
    final resolved = _cache.resolvedMovies[item.id];
    if (resolved != null) {
      final viewOffset = _progressToOffset(resolved.playbackProgress, item.durationMs) ?? 0;
      appLogger.t('[TraktOverride] movie=${item.title} — resolved cache hit (traktId=${resolved.traktId})');
      return WatchStateOverride(
        viewCount: resolved.plays,
        viewOffset: viewOffset,
        lastViewedAt: _isoToUnix(resolved.lastWatchedAt),
      );
    }

    // 2. Bridge-map fast path — traktId known from a prior session.
    final cachedTraktId = _plexMovieKeyToTraktMovieId[item.id];
    _TraktState? state;
    double? playback;
    if (cachedTraktId != null) {
      state = _movieByTraktId[cachedTraktId];
      playback = _cache.playbackByTraktId[cachedTraktId];
      appLogger.t('[TraktOverride] movie=${item.title} — bridge map hit (traktId=$cachedTraktId)');
    } else {
      // 3. Full external-ID lookup.
      state = _lookupMovie(ids);
      playback = _lookupMoviePlayback(ids);
      // 4. traktId-keyed playback fallback: when imdb/tmdb cross-match misses but
      //    state was found (giving us the traktId), look up playback by traktId.
      if (playback == null && state != null) {
        playback = _cache.playbackByTraktId[state.traktId];
      }
    }

    appLogger.t('[TraktOverride] movie=${item.title} state.plays=${state?.plays} playback=$playback ids=$ids');

    // 5. No title fallback — external IDs must match.
    if (state == null && playback == null) return null;

    final traktViewOffset = _progressToOffset(playback, item.durationMs);
    // Trakt is the sole authority: active playback → resume; in watched list → done (0); not in Trakt → null (early return above).
    final viewOffset = traktViewOffset ?? (state != null ? 0 : null);
    final lastViewed = _isoToUnix(state?.lastWatchedAt);

    // 6. Populate bridge map + resolved cache for subsequent calls.
    if (state != null) {
      _plexMovieKeyToTraktMovieId[item.id] = state.traktId;
      _cache.resolvedMovies[item.id] = _ResolvedMovieEntry(
        traktId: state.traktId,
        plays: state.plays,
        playbackProgress: playback,
        lastWatchedAt: state.lastWatchedAt,
      );
      // Also populate the reverse map so getContinueWatchingItems() shows this
      // movie without waiting for a full enrichment pass.
      final isNewBridgeEntry = !_traktMovieIdToPlexKey.containsKey(state.traktId);
      if (isNewBridgeEntry) {
        _traktMovieIdToPlexKey[state.traktId] = item.id;
        if (item.thumbPath != null) _traktMovieIdToThumb[state.traktId] = item.thumbPath!;
        if (item.serverId != null) _traktMovieIdToServerId[state.traktId] = item.serverId!;
        _onBridgeMapUpdated?.call();
      }
    } else if (playback != null) {
      // In-progress only (not yet in /sync/watched/movies).
      // Populate both bridge maps using the playback reverse-index so the
      // Continue Watching stub becomes visible without waiting for feedExternalIds.
      final traktId = (ids.imdb != null ? _cache.playbackTraktIdByImdb[ids.imdb] : null)
          ?? (ids.tmdb != null ? _cache.playbackTraktIdByTmdb[ids.tmdb] : null);
      if (traktId != null) {
        _plexMovieKeyToTraktMovieId[item.id] = traktId;
        if (!_traktMovieIdToPlexKey.containsKey(traktId)) {
          _traktMovieIdToPlexKey[traktId] = item.id;
          if (item.thumbPath != null) _traktMovieIdToThumb[traktId] = item.thumbPath!;
          if (item.serverId != null) _traktMovieIdToServerId[traktId] = item.serverId!;
          _onBridgeMapUpdated?.call();
        }
      }
    }

    return WatchStateOverride(
      viewCount: state?.plays ?? 0,
      viewOffset: viewOffset,
      lastViewedAt: lastViewed,
    );
  }

  WatchStateOverride? _overrideForEpisode(MediaItem item, ExternalIds episodeIds) {
    final season = item.parentIndex;
    final number = item.index;
    if (season == null || number == null) return null;

    // Fast-exit for shows already confirmed not in Trakt this sync cycle.
    // Skip the fast-exit when the bridge map now has an entry for this grandparentId —
    // the negative cache is stale (CW enrichment ran after the initial failed lookup).
    if (item.grandparentId != null && _grandparentIdsNotFound.contains(item.grandparentId)) {
      if (_plexKeyToTraktShowId.containsKey(item.grandparentId)) {
        _grandparentIdsNotFound.remove(item.grandparentId!);
        // Fall through: bridge map will resolve the traktId below.
      } else {
        appLogger.t(
          'TraktWatchState: _overrideForEpisode ${item.title} (${item.id}) — '
          'grandparentId=${item.grandparentId} in negative cache → null',
        );
        return null;
      }
    }

    // Identify the show via the episode's own IDs (Plex includes show-level
    // imdb/tmdb/tvdb on episodes via includeGuids=1).
    var showState = _lookupShow(episodeIds);

    // Bridge map fallback — works once the show has been matched via getOverrideFor(show)
    // or via CW enrichment. Also supports shows that are in /sync/playback but have no
    // entries yet in /sync/watched/shows (_showByTraktId may be null for such shows).
    int? bridgeMapTraktId;
    if (item.grandparentId != null) {
      bridgeMapTraktId = _plexKeyToTraktShowId[item.grandparentId];
    }
    if (showState == null && bridgeMapTraktId != null) {
      showState = _showByTraktId[bridgeMapTraktId];
    }

    // No title fallback — external IDs or bridge map must match.
    if (showState == null && bridgeMapTraktId == null) {
      if (item.grandparentId != null) _grandparentIdsNotFound.add(item.grandparentId!);
      appLogger.d(
        'TraktWatchState: show match failed for episode ${item.title} (IDs: $episodeIds, GP: ${item.grandparentId})',
      );
      return null;
    }

    // Use traktId from full show state when available; fall back to bridge map when the
    // show is in /sync/playback but not yet in /sync/watched/shows (showState == null).
    final traktShowId = showState?.traktId ?? bridgeMapTraktId!;

    // Register show → Plex data mapping using the show's ratingKey when available.
    final showPlexKey = item.grandparentId ?? item.id;
    final isNewEp = !_traktShowIdToPlexKey.containsKey(traktShowId);
    _traktShowIdToPlexKey[traktShowId] = showPlexKey;
    _plexKeyToTraktShowId[showPlexKey] = traktShowId;
    if (item.serverId != null) _traktShowIdToServerId[traktShowId] = item.serverId!;
    final epThumb = item.grandparentThumbPath ?? item.thumbPath;
    if (epThumb != null) _traktShowIdToThumb[traktShowId] = epThumb;
    final epArt = item.grandparentArtPath ?? item.artPath;
    if (epArt != null) _traktShowIdToArt[traktShowId] = epArt;
    if (isNewEp) _scheduleBuildContinueWatchingStubs();
    final epKey = 's${season}e$number';
    var epState = _cache.showEpisodes[traktShowId]?[epKey];
    var effectiveEpKey = epKey;
    // S/E remapping for shows whose Plex numbering differs from Trakt's (e.g. anime).
    // Falls back to the direct key when no remapping is available.
    if (epState == null) {
      final remappedKey = _plexSeToTraktSeKey['$traktShowId:$epKey'];
      if (remappedKey != null) {
        effectiveEpKey = remappedKey;
        epState = _cache.showEpisodes[traktShowId]?[remappedKey];
      }
    }

    // Playback progress for this specific episode.
    final pbKey = '$traktShowId:$effectiveEpKey';
    final playbackPct = _cache.episodePlayback[pbKey]?.progress;
    final viewOffset = _progressToOffset(playbackPct, item.durationMs);

    final plays = epState?.plays ?? 0;
    // Watched episodes (plays >= 1) are always shown with offset=0 — no progress bar.
    // Trakt may still hold a playback entry (e.g. the user re-started the episode);
    // we ignore it because showing a bar on a watched episode is confusing.
    // Unwatched episodes (plays=0): use Trakt's playback offset if present, otherwise
    // preserve Plex's own in-progress offset (null → caller keeps Plex value).
    final resolvedViewOffset = plays > 0 ? 0 : viewOffset;

    appLogger.t(
      'TraktWatchState: _overrideForEpisode ${item.title} (${item.id}) — '
      'traktShowId=$traktShowId epKey=$effectiveEpKey '
      'plays=$plays playbackPct=$playbackPct durationMs=${item.durationMs} '
      'viewOffset=$viewOffset resolvedViewOffset=$resolvedViewOffset',
    );

    // If Trakt has no per-episode record and no active playback, preserve Plex's
    // watched state (viewCount) entirely. Returning an override with viewCount=0
    // would clear Plex checkmarks for episodes watched locally but not scrobbled.
    if (epState == null && resolvedViewOffset == null) return null;

    return WatchStateOverride(
      // Only set viewCount when Trakt has positive play data; null preserves Plex's viewCount
      // for episodes that exist in the show but weren't scrobbled to Trakt.
      viewCount: plays > 0 ? plays : null,
      viewOffset: resolvedViewOffset,
      lastViewedAt: _isoToUnix(epState?.lastWatchedAt),
    );
  }

  WatchStateOverride? _overrideForShow(MediaItem item, ExternalIds ids) {
    // 1. Resolved-cache fast path — only stores traktId so progress is always
    //    read live from _cache.showProgress (safe against fetchShowProgressIfNeeded updates).
    final resolved = _cache.resolvedShows[item.id];
    if (resolved != null) {
      final progress = _cache.showProgress[resolved.traktId];
      final storedAired = progress?.$2 ?? 0;
      final leafCount = storedAired > 0 ? storedAired : item.leafCount;
      final lastViewed = _isoToUnix(_showByTraktId[resolved.traktId]?.lastWatchedAt);
      appLogger.t('[TraktOverride] show=${item.title} — resolved cache hit (traktId=${resolved.traktId})');
      return WatchStateOverride(
        viewedLeafCount: progress?.$1 ?? 0,
        leafCount: leafCount,
        lastViewedAt: lastViewed,
      );
    }

    // 2. Bridge map fast path.
    var showState = _showByTraktId[_plexKeyToTraktShowId[item.id]];

    // 3. External-ID lookup — no title fallback.
    showState ??= _lookupShow(ids);

    if (showState == null) return null;

    final isNewShow = !_traktShowIdToPlexKey.containsKey(showState.traktId);
    _traktShowIdToPlexKey[showState.traktId] = item.id;
    _plexKeyToTraktShowId[item.id] = showState.traktId;
    if (item.serverId != null) _traktShowIdToServerId[showState.traktId] = item.serverId!;
    if (item.thumbPath != null) _traktShowIdToThumb[showState.traktId] = item.thumbPath!;
    if (item.artPath != null) _traktShowIdToArt[showState.traktId] = item.artPath!;
    if (isNewShow) _scheduleBuildContinueWatchingStubs();

    final progress = _cache.showProgress[showState.traktId];
    final lastViewed = _isoToUnix(showState.lastWatchedAt);

    // Use Plex's leafCount when the stored aired count is 0 (sentinel —
    // /sync/watched/shows doesn't return total aired count).
    final storedAired = progress?.$2 ?? 0;
    final leafCount = storedAired > 0 ? storedAired : item.leafCount;

    // 4. Populate resolved cache — traktId only; progress is read live above.
    _cache.resolvedShows[item.id] = _ResolvedShowEntry(traktId: showState.traktId);

    return WatchStateOverride(viewedLeafCount: progress?.$1 ?? 0, leafCount: leafCount, lastViewedAt: lastViewed);
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  ExternalIds _idsFromItem(MediaItem item) {
    final guids = item.raw?['Guid'] as List?;
    if (guids != null && guids.isNotEmpty) {
      return ExternalIds.fromGuids(guids);
    }
    // Check IDs fed from the scrobble path (for movies whose Plex detail
    // endpoint doesn't return a Guid array even with includeGuids=1).
    final fed = _fetchedExternalIds[item.id];
    if (fed != null && fed.hasAny) return fed;
    // No IDs available synchronously — trigger a one-shot background fetch so
    // the overlay can match on the next render cycle.
    _triggerBackgroundIdFetch(item);
    return _idsFromGuid(item.guid);
  }

  /// Parse external IDs from a Plex guid string.
  /// Handles both modern (`imdb://tt123`) and legacy agent format
  /// (`com.plexapp.agents.imdb://tt123/0/0`).
  ExternalIds _idsFromGuid(String? guid) {
    if (guid == null || guid.isEmpty) return const ExternalIds();
    return ExternalIds.fromPrimaryGuid(guid);
  }

  _TraktState? _lookupMovie(ExternalIds ids) {
    if (ids.imdb != null) {
      final s = _cache.byImdb[ids.imdb];
      if (s != null) return s;
    }
    if (ids.tmdb != null) {
      final s = _cache.byTmdb[ids.tmdb];
      if (s != null) return s;
    }
    if (ids.tvdb != null) {
      final s = _cache.byTvdb[ids.tvdb];
      if (s != null) return s;
    }
    return null;
  }

  double? _lookupMoviePlayback(ExternalIds ids) {
    if (ids.imdb != null) {
      final p = _cache.playbackByImdb[ids.imdb];
      if (p != null) return p;
    }
    if (ids.tmdb != null) {
      final p = _cache.playbackByTmdb[ids.tmdb];
      if (p != null) return p;
    }
    if (ids.tvdb != null) {
      final p = _cache.playbackByTvdb[ids.tvdb];
      if (p != null) return p;
    }
    return null;
  }

  _TraktState? _lookupShow(ExternalIds ids) {
    if (ids.imdb != null) {
      final s = _cache.showByImdb[ids.imdb];
      if (s != null) return s;
    }
    if (ids.tmdb != null) {
      final s = _cache.showByTmdb[ids.tmdb];
      if (s != null) return s;
    }
    if (ids.tvdb != null) {
      final s = _cache.showByTvdb[ids.tvdb];
      if (s != null) return s;
    }
    return null;
  }

  /// Convert a Trakt `progress` (0-100) to a [MediaItem.viewOffset] in ms.
  int? _progressToOffset(double? progress, int? durationMs) {
    if (progress == null || durationMs == null || durationMs == 0) return null;
    if (progress <= 0) return null;
    return (progress / 100.0 * durationMs).toInt();
  }

  /// Convert an ISO-8601 timestamp to a unix timestamp in seconds.
  int? _isoToUnix(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    try {
      return DateTime.parse(iso).millisecondsSinceEpoch ~/ 1000;
    } catch (_) {
      return null;
    }
  }

  void _logPlaybackResponse(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      appLogger.d('TraktWatchState: /sync/playback returned 0 items');
      return;
    }
    appLogger.d('TraktWatchState: /sync/playback returned ${items.length} items');
    // for (var i = 0; i < items.length; i++) {
    //   appLogger.d('TraktWatchState: playback[$i] ${jsonEncode(items[i])}');
    // }
  }

  /// Extracts the first URL of [type] from a Trakt `images` object and prepends
  /// `https://` if the URL is not already absolute (Trakt omits the scheme).
  String? _extractTraktImage(Map<String, dynamic>? images, String type) {
    if (images == null) return null;
    final arr = images[type] as List<dynamic>?;
    if (arr == null || arr.isEmpty) return null;
    final url = arr.first as String?;
    if (url == null || url.isEmpty) return null;
    return url.startsWith('https://') ? url : 'https://$url';
  }

  // -------------------------------------------------------------------------
  // Cache persistence (ApiCache table)
  // -------------------------------------------------------------------------

  Future<void> _persistToCache(Map<String, dynamic>? lastActivities) async {
    final cache = PlexApiCache.instance;
    await Future.wait([
      _saveList(cache, _CacheKeys.watchedMovies, _cache.watchedMoviesRaw),
      _saveList(cache, _CacheKeys.watchedShows, _cache.watchedShowsRaw),
      _saveList(cache, _CacheKeys.playback, _cache.playbackRaw),
      _saveList(cache, _CacheKeys.upNext, _cache.upNextRaw),
      if (lastActivities != null) cache.put(_cacheServerId, _CacheKeys.lastActivities, lastActivities),
    ]);
  }

  Future<void> _saveList(PlexApiCache cache, String key, List<Map<String, dynamic>> items) {
    return cache.put(_cacheServerId, key, {'items': items});
  }

  Future<void> _saveExternalIds() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final items = {
      for (final e in _fetchedExternalIds.entries)
        e.key: {
          'imdb': e.value.imdb,
          'tmdb': e.value.tmdb,
          'tvdb': e.value.tvdb,
          if (!e.value.hasAny) 'ts': now,
        }
    };
    if (items.isNotEmpty) {
      await PlexApiCache.instance.put(_cacheServerId, _CacheKeys.externalIds, {'items': items});
    }
  }

  Future<void> _saveResolvedPositions() async {
    final items = {
      for (final e in _resolvedEpisodePosition.entries)
        e.key: {
          'season': e.value.season,
          'episode': e.value.episode,
          if (e.value.thumb != null) 'thumb': e.value.thumb,
        },
    };
    if (items.isNotEmpty) {
      await PlexApiCache.instance.put(_cacheServerId, _CacheKeys.resolvedPositions, {'items': items});
    }
  }

  /// Load data from ApiCache on startup (avoids a full API sync on cold boot
  /// if nothing changed since last run).
  Future<void> loadFromCache() async {
    try {
      final cache = PlexApiCache.instance;
      final lastAct = await cache.get(_cacheServerId, _CacheKeys.lastActivities);
      if (lastAct != null) _cache.lastActivities = lastAct;

      final movies = await cache.get(_cacheServerId, _CacheKeys.watchedMovies);
      if (movies != null) {
        _cache.watchedMoviesRaw = (movies['items'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
      }

      final shows = await cache.get(_cacheServerId, _CacheKeys.watchedShows);
      if (shows != null) {
        _cache.watchedShowsRaw = (shows['items'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
      }

      final pb = await cache.get(_cacheServerId, _CacheKeys.playback);
      if (pb != null) {
        _cache.playbackRaw = (pb['items'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
      }

      final un = await cache.get(_cacheServerId, _CacheKeys.upNext);
      if (un != null) {
        _cache.upNextRaw = (un['items'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
      }

      // Restore watchlist raw items so the "Trakt Watchlist" playlist shows
      // immediately on cold boot without waiting for a network sync.
      final wlShows = await cache.get(_cacheServerId, _CacheKeys.watchlistShows);
      if (wlShows != null) {
        _watchlistShowsRaw = (wlShows['items'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
      }
      final wlMovies = await cache.get(_cacheServerId, _CacheKeys.watchlistMovies);
      if (wlMovies != null) {
        _watchlistMoviesRaw = (wlMovies['items'] as List? ?? []).whereType<Map<String, dynamic>>().toList();
      }

      // Restore bridge maps so stubs have images immediately on second launch.
      final bridgeCached = await cache.get(_cacheServerId, _CacheKeys.bridgeMaps);
      if (bridgeCached != null) {
        final plexKeyMap = bridgeCached['plexKey'];
        final thumbMap = bridgeCached['thumb'];
        final artMap = bridgeCached['art'];
        final serverIdMap = bridgeCached['serverId'];
        final movieThumbMap = bridgeCached['movieThumb'];
        if (plexKeyMap is Map) {
          for (final e in plexKeyMap.entries) {
            final id = int.tryParse(e.key?.toString() ?? '');
            if (id != null && e.value is String) {
              _traktShowIdToPlexKey[id] = e.value as String;
              _plexKeyToTraktShowId[e.value as String] = id;
            }
          }
        }
        if (thumbMap is Map) {
          for (final e in thumbMap.entries) {
            final id = int.tryParse(e.key?.toString() ?? '');
            if (id != null && e.value is String) _traktShowIdToThumb[id] = e.value as String;
          }
        }
        if (artMap is Map) {
          for (final e in artMap.entries) {
            final id = int.tryParse(e.key?.toString() ?? '');
            if (id != null && e.value is String) _traktShowIdToArt[id] = e.value as String;
          }
        }
        if (serverIdMap is Map) {
          for (final e in serverIdMap.entries) {
            final id = int.tryParse(e.key?.toString() ?? '');
            if (id != null && e.value is String) _traktShowIdToServerId[id] = e.value as String;
          }
        }
        if (movieThumbMap is Map) {
          for (final e in movieThumbMap.entries) {
            final id = int.tryParse(e.key?.toString() ?? '');
            if (id != null && e.value is String) _traktMovieIdToThumb[id] = e.value as String;
          }
        }
        final movieKeyMap = bridgeCached['movieKey'];
        final movieServerIdMap = bridgeCached['movieServerId'];
        if (movieKeyMap is Map) {
          for (final e in movieKeyMap.entries) {
            final id = int.tryParse(e.key?.toString() ?? '');
            if (id != null && e.value is String) _traktMovieIdToPlexKey[id] = e.value as String;
          }
        }
        if (movieServerIdMap is Map) {
          for (final e in movieServerIdMap.entries) {
            final id = int.tryParse(e.key?.toString() ?? '');
            if (id != null && e.value is String) _traktMovieIdToServerId[id] = e.value as String;
          }
        }
      }

      // Restore external IDs resolved in prior sessions so background fetches
      // don't repeat for the same items on every cold start.
      final extIdsCached = await cache.get(_cacheServerId, _CacheKeys.externalIds);
      if (extIdsCached != null) {
        final items = extIdsCached['items'];
        if (items is Map) {
          final now = DateTime.now().millisecondsSinceEpoch;
          for (final e in items.entries) {
            if (e.key is! String) continue;
            final m = e.value;
            if (m is! Map) continue;
            final ids = ExternalIds(
              imdb: m['imdb'] as String?,
              tmdb: (m['tmdb'] as num?)?.toInt(),
              tvdb: (m['tvdb'] as num?)?.toInt(),
            );
            if (ids.hasAny) {
              // Successful resolution — restore without expiry.
              _fetchedExternalIds[e.key as String] = ids;
            } else {
              // Empty marker — only restore if within the 24 h TTL.
              final ts = (m['ts'] as num?)?.toInt();
              if (ts != null && now - ts < _externalIdsEmptyTtlMs) {
                _fetchedExternalIds[e.key as String] = const ExternalIds();
              }
            }
          }
        }
      }

      // DO NOT PERSIST _enrichNotFoundShowTs / _enrichNotFoundMovieTs to disk.
      // Prior incident: persisting them caused unmatched stubs to be permanently
      // filtered by getContinueWatchingItems() before _doEnrichTraktStubs could
      // re-try the GUID search, because the not-found marker survived across
      // sessions. These are session-local guards only — every app launch starts
      // with empty maps so all unmatched stubs are re-tried.

      // Restore resolved Plex S/E positions from prior sessions so CW stubs show
      // the correct episode numbers immediately on first render (without waiting for
      // resolveEpisodeDisplayPositions to re-fetch allLeaves from Plex).
      final resolvedPosCached = await cache.get(_cacheServerId, _CacheKeys.resolvedPositions);
      if (resolvedPosCached != null) {
        final posItems = resolvedPosCached['items'];
        if (posItems is Map) {
          for (final e in posItems.entries) {
            if (e.key is! String) continue;
            final m = e.value;
            if (m is! Map) continue;
            _resolvedEpisodePosition[e.key as String] = (
              season: (m['season'] as num?)?.toInt() ?? 0,
              episode: (m['episode'] as num?)?.toInt() ?? 0,
              thumb: m['thumb'] as String?,
            );
          }
        }
      }
      // Rebuild Plex→Trakt S/E remapping from the restored positions so
      // _overrideForEpisode can resolve anime episodes immediately on first load.
      for (final e in _resolvedEpisodePosition.entries) {
        _updatePlexSeRemapping(e.key, e.value.season, e.value.episode);
      }

      if (!_cache.isEmpty) {
        _buildMovieIndices();
        _buildShowIndices();
        _buildPlaybackIndices();
        _buildContinueWatchingStubs();
        appLogger.d(
          'TraktWatchState: loaded from cache — '
          '${_cache.watchedMoviesRaw.length} movies, '
          '${_cache.watchedShowsRaw.length} shows, '
          '${_cache.upNextRaw.length} up-next, '
          '${_cache.playbackStubs.length} continue-watching stubs',
        );
      }
    } catch (e) {
      appLogger.d('TraktWatchState: cache load failed (non-fatal)', error: e);
    } finally {
      if (!_cacheReadyCompleter.isCompleted) {
        _cacheReadyCompleter.complete();
      }
    }
  }

  // -------------------------------------------------------------------------
  // TrackerStubResolver impl
  // -------------------------------------------------------------------------

  Future<void>? _enrichingFuture;
  Future<void>? _resolvePositionsFuture;
  // Epoch-second of the last successful resolveEpisodeDisplayPositions run.
  // Guards against redundant HTTP calls when a screen re-enters the foreground
  // immediately after a sync already resolved positions.
  int? _resolvedPositionsAt;

  @override
  bool ownsStub(String stubId) =>
      stubId.startsWith('trakt_episode_pb_') ||
      stubId.startsWith('trakt_upnext_') ||
      stubId.startsWith('trakt_movie_pb_');

  @override
  Future<MediaItem> resolveEpisodeStub(MediaItem stub, PlexClient client) async {
    final RegExp pattern;
    if (stub.id.startsWith('trakt_episode_pb_')) {
      pattern = RegExp(r'trakt_episode_pb_(\d+)_s(\d+)e(\d+)');
    } else if (stub.id.startsWith('trakt_upnext_')) {
      pattern = RegExp(r'trakt_upnext_(\d+)_s(\d+)e(\d+)');
    } else {
      return stub;
    }

    final m = pattern.firstMatch(stub.id);
    if (m == null) return stub;

    final traktShowId = int.parse(m.group(1)!);
    final season = int.parse(m.group(2)!);
    final epNumber = int.parse(m.group(3)!);

    final showPlexKey = await _resolveShowKey(client, traktShowId, stub);
    if (showPlexKey == null) return stub;

    final label = stub.grandparentTitle ?? '';
    try {
      final episodeTvdb = stub.raw?['episodeTvdb'] as int?;
      final episodeTmdb = stub.raw?['episodeTmdb'] as int?;

      if (episodeTvdb != null || episodeTmdb != null) {
        final leaves = await client.getAllLeaves(showPlexKey);
        for (final ep in leaves) {
          final guids = (ep.raw?['Guid'] as List? ?? [])
              .map((g) => (g as Map?)?['id'] as String?)
              .whereType<String>();
          if (episodeTvdb != null && guids.contains('tvdb://$episodeTvdb')) {
            recordResolvedEpisodePosition(
                stub.id, ep.parentIndex ?? season, ep.index ?? epNumber, thumb: ep.thumbPath);
            return _overlayApply(ep);
          }
          if (episodeTmdb != null && guids.contains('tmdb://$episodeTmdb')) {
            recordResolvedEpisodePosition(
                stub.id, ep.parentIndex ?? season, ep.index ?? epNumber, thumb: ep.thumbPath);
            return _overlayApply(ep);
          }
        }
        appLogger.d('[EpisodeMatch] "$label" S${season}E$epNumber — ID lookup found no Guid match');
        return stub;
      }

      final seasons = await client.fetchChildren(showPlexKey);
      final matched = seasons.where((s) => s.index == season).toList();
      if (matched.isEmpty) return stub;
      final episodes = await client.fetchChildren(matched.first.id);
      final episode = episodes.where((e) => e.index == epNumber).toList();
      if (episode.isEmpty) return stub;
      return _overlayApply(episode.first);
    } catch (_) {
      return stub;
    }
  }

  @override
  Future<MediaItem?> resolveMovieStub(MediaItem stub, PlexClient client) async {
    if (!stub.id.startsWith('trakt_movie_pb_')) return stub;

    final m = RegExp(r'trakt_movie_pb_(\d+)').firstMatch(stub.id);
    if (m == null) return null;
    final traktMovieId = int.parse(m.group(1)!);

    var plexKey = stub.grandparentId ?? getPlexMovieKey(traktMovieId);

    if (plexKey == null) {
      final rawGuids = (stub.raw?['Guid'] as List? ?? [])
          .map((g) => (g as Map?)?['id'] as String?)
          .whereType<String>()
          .where((g) => g.startsWith('imdb://') || g.startsWith('tmdb://'))
          .toList();
      for (final guid in rawGuids) {
        try {
          final results = await client.searchSectionsByExternalIdUri(guid, 'movie');
          final hit = results.where((r) => r.kind == MediaKind.movie).firstOrNull;
          if (hit != null) {
            updateMovieBridgeMap(traktMovieId: traktMovieId, plexKey: hit.id, thumb: hit.thumbPath, serverId: hit.serverId);
            plexKey = hit.id;
            break;
          }
        } catch (e) {
          appLogger.w('[MovieNav] section GUID search failed for $guid', error: e);
        }
      }

      if (plexKey == null) {
        for (final guid in rawGuids) {
          try {
            final results = await client.searchByExternalIdUri(guid);
            final hit = results.where((r) => r.kind == MediaKind.movie).firstOrNull;
            if (hit != null) {
              updateMovieBridgeMap(traktMovieId: traktMovieId, plexKey: hit.id, thumb: hit.thumbPath, serverId: hit.serverId);
              plexKey = hit.id;
              break;
            }
          } catch (e) {
            appLogger.w('[MovieNav] global GUID search failed for $guid', error: e);
          }
        }
      }
    }

    if (plexKey == null) {
      appLogger.w('[MovieNav] resolveMovieStub: no Plex key found for traktMovieId=$traktMovieId');
      return null;
    }

    try {
      final result = await client.fetchItem(plexKey);
      if (result == null) return null;
      final guidList = stub.raw?['Guid'] as List?;
      final withGuids = (guidList?.isNotEmpty == true)
          ? result.copyWith(raw: {...?result.raw, 'Guid': guidList!})
          : result;
      return _overlayApply(withGuids);
    } catch (e) {
      appLogger.w('[MovieNav] fetchItem failed for plexKey=$plexKey', error: e);
      return null;
    }
  }

  @override
  Future<MediaItem?> resolveStubShowForNavigation(MediaItem stub, PlexClient client) async {
    final m = RegExp(r'trakt_(?:episode_pb|upnext)_(\d+)_').firstMatch(stub.id);
    if (m == null) return null;
    final traktShowId = int.parse(m.group(1)!);

    final showKey = await _resolveShowKey(client, traktShowId, stub);
    if (showKey == null) return null;

    return MediaItem.plex(
      id: showKey,
      kind: MediaKind.show,
      title: stub.grandparentTitle ?? stub.displayTitle,
      thumbPath: stub.grandparentThumbPath ?? getPlexShowThumb(traktShowId),
      serverId: stub.serverId ?? getPlexShowServerId(traktShowId),
      serverName: stub.serverName,
    );
  }

  @override
  Future<MediaItem?> resolveStubMovieForNavigation(MediaItem stub, PlexClient client) async {
    final m = RegExp(r'trakt_movie_pb_(\d+)').firstMatch(stub.id);
    if (m == null) return null;
    final traktMovieId = int.parse(m.group(1)!);

    var plexKey = stub.grandparentId ?? getPlexMovieKey(traktMovieId);

    if (plexKey == null) {
      final stubIds = ExternalIds.fromGuids(stub.raw?['Guid'] as List? ?? []);
      final movieTitle = stub.title;
      if (movieTitle != null && movieTitle.isNotEmpty && stubIds.hasAny) {
        try {
          final candidates = await client.searchItems(movieTitle, limit: 10);
          for (final c in candidates) {
            if (c.kind != MediaKind.movie) continue;
            final ids = await client.fetchExternalIds(c.id);
            if ((stubIds.imdb != null && stubIds.imdb == ids.imdb) ||
                (stubIds.tmdb != null && stubIds.tmdb == ids.tmdb)) {
              updateMovieBridgeMap(
                  traktMovieId: traktMovieId, plexKey: c.id, thumb: c.thumbPath, serverId: c.serverId);
              plexKey = c.id;
              break;
            }
          }
        } catch (_) {}
      }
    }

    if (plexKey == null) return null;

    final serverId = stub.serverId ?? getPlexMovieServerId(traktMovieId);
    return MediaItem.plex(
      id: plexKey,
      kind: MediaKind.movie,
      title: stub.title,
      thumbPath: stub.thumbPath ?? getPlexMovieThumb(traktMovieId),
      artPath: stub.artPath,
      year: stub.year,
      serverId: serverId,
      serverName: stub.serverName,
    );
  }

  @override
  Future<void> enrichStubs(String? preferredServerId, Map<String, PlexClient> clientMap) async {
    if (_enrichingFuture != null) {
      await _enrichingFuture;
      return;
    }
    final completer = Completer<void>();
    _enrichingFuture = completer.future;
    try {
      await _doEnrichStubs(preferredServerId, clientMap);
      completer.complete();
    } catch (e) {
      completer.completeError(e);
    } finally {
      _enrichingFuture = null;
    }
  }

  static const _resolvedPositionsTtlSeconds = 60;

  @override
  Future<void> resolveEpisodeDisplayPositions(
      Map<String, PlexClient> clients, String? fallbackServerId) async {
    // Coalesce concurrent callers onto the same in-flight operation.
    if (_resolvePositionsFuture != null) {
      await _resolvePositionsFuture;
      return;
    }
    // Skip if data is already fresh (e.g. screen re-enters foreground right
    // after a sync already resolved positions — no need to re-issue HTTP calls).
    final lastRan = _resolvedPositionsAt;
    if (lastRan != null && (_nowEpoch - lastRan) < _resolvedPositionsTtlSeconds) return;

    final completer = Completer<void>();
    _resolvePositionsFuture = completer.future;
    try {
      await _doResolveEpisodeDisplayPositions(clients, fallbackServerId);
      _resolvedPositionsAt = _nowEpoch;
      completer.complete();
    } catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    } finally {
      _resolvePositionsFuture = null;
    }
  }

  Future<List<MediaItem>> _getCachedLeaves(PlexClient client, String ratingKey) async {
    if (_allLeavesCache.containsKey(ratingKey)) return _allLeavesCache[ratingKey]!;
    final leaves = await client.getAllLeaves(ratingKey);
    if (_allLeavesCache.length >= _leavesCacheMaxEntries) {
      _allLeavesCache.remove(_allLeavesCache.keys.first); // FIFO eviction
    }
    _allLeavesCache[ratingKey] = leaves;
    return leaves;
  }

  Future<void> _doResolveEpisodeDisplayPositions(
      Map<String, PlexClient> clients, String? fallbackServerId) async {
    for (final item in getContinueWatchingItems()) {
      final meta = item.metadata;
      if (meta.grandparentId == null) continue;
      final episodeTvdb = meta.raw?['episodeTvdb'] as int?;
      final episodeTmdb = meta.raw?['episodeTmdb'] as int?;
      if (episodeTvdb == null && episodeTmdb == null) continue;
      final serverId = meta.serverId ?? fallbackServerId;
      final client = serverId != null ? clients[serverId] : null;
      if (client == null) continue;
      final cacheKey = meta.grandparentId!;
      final leaves = await _getCachedLeaves(client, cacheKey);
      final sorted = leaves.toList()
        ..sort((a, b) {
          final sc = (a.parentIndex ?? 0).compareTo(b.parentIndex ?? 0);
          return sc != 0 ? sc : (a.index ?? 0).compareTo(b.index ?? 0);
        });
      final matchIdx = sorted.indexWhere((ep) {
        final guids = (ep.raw?['Guid'] as List? ?? [])
            .map((g) => (g as Map?)?['id'] as String?)
            .whereType<String>();
        return (episodeTvdb != null && guids.contains('tvdb://$episodeTvdb')) ||
            (episodeTmdb != null && guids.contains('tmdb://$episodeTmdb'));
      });
      if (matchIdx < 0) continue;
      final ep = sorted[matchIdx];
      recordResolvedEpisodePosition(
          meta.id, ep.parentIndex ?? 0, ep.index ?? 0, thumb: ep.thumbPath);
      if (matchIdx + 1 < sorted.length) {
        final nextEp = sorted[matchIdx + 1];
        _nextEpisodeByStubId[meta.id] = nextEp;
        appLogger.d(
          'TraktWatchState: pre-fetched next ep for ${meta.title} → '
          'S${nextEp.parentIndex}E${nextEp.index} "${nextEp.title}" (${nextEp.id})',
        );
      }
      // Build full show S/E remapping for all episodes via sequential inference.
      // Covers the entire allLeaves list so _overrideForEpisode can resolve any
      // episode in the show, not just the current CW stub.
      final stubM =
          RegExp(r'trakt_(?:upnext|episode_pb)_(\d+)_s(\d+)e(\d+)').firstMatch(meta.id);
      if (stubM != null) {
        final traktShowIdInt = int.tryParse(stubM.group(1)!);
        final traktSeason = int.tryParse(stubM.group(2)!);
        final traktEpBase = int.tryParse(stubM.group(3)!);
        if (traktShowIdInt != null && traktSeason != null && traktEpBase != null) {
          for (int i = 0; matchIdx + i < sorted.length; i++) {
            final plexEp = sorted[matchIdx + i];
            final plexS = plexEp.parentIndex ?? 0;
            final plexE = plexEp.index ?? 0;
            final traktE = traktEpBase + i;
            if (plexS != traktSeason || plexE != traktE) {
              _plexSeToTraktSeKey['$traktShowIdInt:s${plexS}e$plexE'] = 's${traktSeason}e$traktE';
            }
          }
          for (int i = 1; matchIdx - i >= 0; i++) {
            final plexEp = sorted[matchIdx - i];
            final plexS = plexEp.parentIndex ?? 0;
            final plexE = plexEp.index ?? 0;
            final traktE = traktEpBase - i;
            if (traktE <= 0) break;
            if (plexS != traktSeason || plexE != traktE) {
              _plexSeToTraktSeKey['$traktShowIdInt:s${plexS}e$plexE'] = 's${traktSeason}e$traktE';
            }
          }
        }
      }
    }
    // Re-build stubs so the newly captured next-episode references are embedded.
    _buildContinueWatchingStubs();
    // Persist resolved positions so subsequent cold starts skip the allLeaves fetches.
    unawaited(_saveResolvedPositions());
  }

  // ---- private stub-resolution helpers (migrated from trakt_ui_helper.dart) ----

  /// Apply the active overlay to [item]. Thin wrapper so override methods don't
  /// import WatchStateOverlay directly.
  MediaItem _overlayApply(MediaItem item) {
    // Import-free apply: read override from self and apply manually.
    final override = getOverrideFor(item);
    if (override == null) return item.copyWith(viewCount: 0, viewOffsetMs: 0, viewedLeafCount: 0);
    return item.copyWith(
      viewCount: override.viewCount ?? item.viewCount,
      viewOffsetMs: override.viewOffset ?? item.viewOffsetMs,
      viewedLeafCount: override.viewedLeafCount ?? item.viewedLeafCount,
      leafCount: override.leafCount ?? item.leafCount,
      lastViewedAt: override.lastViewedAt ?? item.lastViewedAt,
    );
  }

  Future<String?> _resolveShowKey(PlexClient client, int traktShowId, MediaItem stub) async {
    final bridgeKey = getPlexShowKey(traktShowId);
    if (bridgeKey != null) return bridgeKey;

    final rawGuids = (stub.raw?['Guid'] as List? ?? [])
        .map((g) => (g as Map?)?['id'] as String?)
        .whereType<String>()
        .toList();
    if (rawGuids.isEmpty) return null;

    final label = stub.grandparentTitle ?? stub.displayTitle;
    final match = await _findByGuidSearch(client, rawGuids, MediaKind.show, label);
    appLogger.t('[ResolveShow] traktShowId=$traktShowId "$label" → ${match == null ? 'not found' : 'plexKey=${match.id}'}');

    if (match != null) {
      updateBridgeMap(
          traktShowId: traktShowId, plexKey: match.id, thumb: match.thumbPath, art: match.artPath, serverId: match.serverId);
      return match.id;
    }
    return null;
  }

  Future<void> _doEnrichStubs(String? preferredServerId, Map<String, PlexClient> clientMap) async {
    if (clientMap.isEmpty) return;

    // Prune expired not-found entries so they don't accumulate indefinitely.
    // Entries are cheap but there is no other eviction path — they are only
    // removed when the same ID is found (updateBridgeMap/updateMovieBridgeMap)
    // or on a full invalidateCache(). Pruning here keeps the maps bounded even
    // after years of failed enrichments for shows the user no longer has in Plex.
    final now = _nowEpoch;
    _enrichNotFoundShowTs.removeWhere((_, ts) => (now - ts) >= _enrichNotFoundTtlSeconds);
    _enrichNotFoundMovieTs.removeWhere((_, ts) => (now - ts) >= _enrichNotFoundTtlSeconds);

    final orderedClients = [
      if (preferredServerId != null && clientMap.containsKey(preferredServerId)) clientMap[preferredServerId]!,
      ...clientMap.entries.where((e) => e.key != preferredServerId).map((e) => e.value),
    ];

    final stubs = getAllPlaybackStubs();

    final needsWork = stubs.where((item) {
      final key = item.metadata.id;
      if (key.startsWith('trakt_episode_pb_') || key.startsWith('trakt_upnext_')) {
        final m = RegExp(r'trakt_(?:episode_pb|upnext)_(\d+)_').firstMatch(key);
        if (m == null) return false;
        final showId = int.tryParse(m.group(1)!) ?? 0;
        if (isShowEnrichNotFound(showId)) return false;
        return getPlexShowKey(showId) == null;
      }
      if (key.startsWith('trakt_movie_pb_')) {
        final m = RegExp(r'trakt_movie_pb_(\d+)').firstMatch(key);
        if (m == null) return false;
        final traktId = int.tryParse(m.group(1)!) ?? 0;
        if (isMovieEnrichNotFound(traktId)) return false;
        return getPlexMovieKey(traktId) == null;
      }
      return false;
    }).toList();

    if (needsWork.isEmpty) return;

    appLogger.d('TraktWatchState: enriching ${needsWork.length} stubs (parallel)');

    final hasShows = needsWork.any((i) =>
        i.metadata.id.startsWith('trakt_episode_pb_') || i.metadata.id.startsWith('trakt_upnext_'));
    final hasMovies = needsWork.any((i) => i.metadata.id.startsWith('trakt_movie_pb_'));
    final showGuidIndex = <String, MediaItem>{};
    final movieGuidIndex = <String, MediaItem>{};
    // Reuse a recently built GUID index (5-min TTL) to avoid full-library
    // fetches on every enrichment run within the same sync window.
    final indexStale = _guidIndexBuiltAt == null || (now - _guidIndexBuiltAt!) >= _guidIndexTtlSeconds;
    if (indexStale) {
      _guidIndexCache.clear();
      for (final client in orderedClients) {
        final sid = client.serverId;
        if (hasShows) {
          final idx = await client.buildGuidIndex('show');
          _guidIndexCache['show_$sid'] = idx;
          showGuidIndex.addAll(idx);
        }
        if (hasMovies) {
          final idx = await client.buildGuidIndex('movie');
          _guidIndexCache['movie_$sid'] = idx;
          movieGuidIndex.addAll(idx);
        }
      }
      _guidIndexBuiltAt = now;
    } else {
      for (final entry in _guidIndexCache.entries) {
        if (entry.key.startsWith('show_')) showGuidIndex.addAll(entry.value);
        if (entry.key.startsWith('movie_')) movieGuidIndex.addAll(entry.value);
      }
    }

    var anyNotFound = false;
    await Future.wait(
      needsWork.map((item) async {
        final meta = item.metadata;
        final key = meta.id;
        final rawGuids = (meta.raw?['Guid'] as List? ?? [])
            .map((g) => (g as Map?)?['id'] as String?)
            .whereType<String>()
            .toList();
        if (rawGuids.isEmpty) return;

        bool found = false;
        if (key.startsWith('trakt_episode_pb_') || key.startsWith('trakt_upnext_')) {
          final m = RegExp(r'trakt_(?:episode_pb|upnext)_(\d+)_').firstMatch(key)!;
          final traktShowId = int.parse(m.group(1)!);
          final showTitle = meta.grandparentTitle ?? '';
          found = await _enrichShowStub(
            traktShowId: traktShowId,
            showTitle: showTitle,
            rawGuids: rawGuids,
            orderedClients: orderedClients,
            guidIndex: showGuidIndex,
          );
        } else if (key.startsWith('trakt_movie_pb_')) {
          final m = RegExp(r'trakt_movie_pb_(\d+)').firstMatch(key)!;
          final traktMovieId = int.parse(m.group(1)!);
          final title = meta.title ?? '';
          found = await _enrichMovieStub(
            traktMovieId: traktMovieId,
            title: title,
            rawGuids: rawGuids,
            orderedClients: orderedClients,
            guidIndex: movieGuidIndex,
          );
        }
        if (!found) {
          anyNotFound = true;
          if (key.startsWith('trakt_episode_pb_') || key.startsWith('trakt_upnext_')) {
            final m = RegExp(r'trakt_(?:episode_pb|upnext)_(\d+)_').firstMatch(key);
            if (m != null) markShowEnrichNotFound(int.parse(m.group(1)!));
          } else if (key.startsWith('trakt_movie_pb_')) {
            final m = RegExp(r'trakt_movie_pb_(\d+)').firstMatch(key);
            if (m != null) markMovieEnrichNotFound(int.parse(m.group(1)!));
          }
        }
      }),
    );

    if (anyNotFound) await flushEnrichNotFound();
  }

  Future<bool> _enrichShowStub({
    required int traktShowId,
    required String showTitle,
    required List<String> rawGuids,
    required List<PlexClient> orderedClients,
    required Map<String, MediaItem> guidIndex,
  }) async {
    MediaItem? match;
    for (final client in orderedClients) {
      match = await _findByGuidSearch(client, rawGuids, MediaKind.show, showTitle, guidIndex);
      if (match != null) break;
    }
    if (match != null) {
      updateBridgeMap(
          traktShowId: traktShowId, plexKey: match.id, thumb: match.thumbPath, art: match.artPath, serverId: match.serverId);
      return true;
    }
    appLogger.d('[mapping] show "$showTitle" (traktId:$traktShowId) — not found');
    return false;
  }

  Future<bool> _enrichMovieStub({
    required int traktMovieId,
    required String title,
    required List<String> rawGuids,
    required List<PlexClient> orderedClients,
    required Map<String, MediaItem> guidIndex,
  }) async {
    MediaItem? match;
    for (final client in orderedClients) {
      match = await _findByGuidSearch(client, rawGuids, MediaKind.movie, title, guidIndex);
      if (match != null) break;
    }
    if (match != null) {
      updateMovieBridgeMap(
          traktMovieId: traktMovieId, plexKey: match.id, thumb: match.thumbPath, serverId: match.serverId);
      return true;
    }
    appLogger.d('[mapping] movie "$title" (traktId:$traktMovieId) — not found');
    return false;
  }

  static Future<MediaItem?> _findByGuidSearch(
    PlexClient client,
    List<String> rawGuids,
    MediaKind mediaKind,
    String label, [
    Map<String, MediaItem> guidIndex = const {},
  ]) async {
    final sectionType = mediaKind == MediaKind.movie ? 'movie' : 'show';
    final secondary = [
      ...rawGuids.where((g) => g.startsWith('imdb://')),
      ...rawGuids.where((g) => g.startsWith('tmdb://')),
      ...rawGuids.where((g) => g.startsWith('tvdb://')),
    ];

    final legacyEntries = <(String source, String legacy)>[
      for (final g in secondary.where((g) => g.startsWith('tvdb://'))) ...[
        (g, 'com.plexapp.agents.thetvdb://${g.substring(7)}'),
        (g, 'com.plexapp.agents.thetvdb://${g.substring(7)}/0/0'),
      ],
      if (mediaKind == MediaKind.movie) ...[
        for (final g in secondary.where((g) => g.startsWith('imdb://'))) ...[
          (g, 'com.plexapp.agents.imdb://${g.substring(7)}'),
          (g, 'com.plexapp.agents.imdb://${g.substring(7)}/0/0'),
        ],
        for (final g in secondary.where((g) => g.startsWith('tmdb://'))) ...[
          (g, 'com.plexapp.agents.themoviedb://${g.substring(7)}'),
          (g, 'com.plexapp.agents.themoviedb://${g.substring(7)}/0/0'),
        ],
      ],
    ];
    for (final (source, legacy) in legacyEntries) {
      try {
        final results = await client.searchSectionsByExternalIdUri(legacy, sectionType);
        final hit = results.where((r) => r.kind == mediaKind).firstOrNull;
        if (hit != null) {
          appLogger.d('[mapping] "$label" with id:"$source" using "Legacy GUID" → plex:${hit.id}');
          return hit;
        }
      } catch (e) {
        appLogger.d('[mapping] "$label" Legacy GUID error for $source', error: e);
      }
    }

    for (final guid in secondary) {
      final hit = guidIndex[guid];
      if (hit != null) {
        appLogger.d('[mapping] "$label" with id:"$guid" using "GUID index" → plex:${hit.id}');
        return hit;
      }
    }

    appLogger.d('[mapping] "$label" with ids:$secondary — all strategies failed');
    return null;
  }
}
