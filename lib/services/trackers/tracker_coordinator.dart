import 'dart:async';

import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_server_client.dart';
import '../../models/trackers/tracker_context.dart';
import '../../utils/app_logger.dart';
import '../../utils/episode_collection.dart';
import 'anime_episode_progress_resolver.dart';
import 'anime_lists_mapping_store.dart';
import 'anilist/anilist_tracker.dart';
import 'fribb_mapping_store.dart';
import 'mal/mal_tracker.dart';
import 'simkl/simkl_tracker.dart';
import 'tracker.dart';
import 'tracker_constants.dart';
import 'tracker_id_resolver.dart';

/// Fan-out for non-Trakt trackers (MAL, AniList, Simkl). Owns the per-playback
/// threshold state: each connected tracker is notified exactly once when
/// progress crosses the watched threshold, with a safety-net fire on stop if
/// the crossing was missed (e.g. user stopped between ticks).
class TrackerCoordinator {
  static TrackerCoordinator? _instance;
  static TrackerCoordinator get instance => _instance ??= TrackerCoordinator._();

  TrackerCoordinator._();

  late final List<Tracker> _trackers = [MalTracker.instance, AnilistTracker.instance, SimklTracker.instance];

  /// Resolver persists across episode swaps so back-to-back episodes of the
  /// same show reuse the cached IDs. Cleared only on profile switch.
  TrackerIdResolver? _resolver;
  String? _resolverClientKey;
  String? _activeLibraryGlobalKey;
  FribbMappingLookup? _debugFribbStore;
  AnimeListsMappingLookup? _debugAnimeListsStore;
  AnimeEpisodeProgressLookup? _debugAnimeProgress;

  TrackerContext? _ctx;
  Duration _duration = Duration.zero;
  Duration _lastPosition = Duration.zero;
  bool _thresholdCrossed = false;

  Future<void> initialize() async {
    await Future.wait(_trackers.map((t) => t.initialize()));
  }

  Future<void> startPlayback(MediaItem metadata, MediaServerClient client, {bool isLive = false}) async {
    if (isLive) return;
    final mediaType = metadata.kind;
    if (mediaType != MediaKind.movie && mediaType != MediaKind.episode) return;
    final libraryGlobalKey = metadata.libraryGlobalKey;
    if (!_hasActiveTrackerForLibrary(libraryGlobalKey)) {
      _reset();
      return;
    }

    _activeLibraryGlobalKey = libraryGlobalKey;
    final clientKey = client.cacheServerId;
    if (_resolver == null || _resolverClientKey != clientKey) {
      _resolver?.clearCache();
      _resolver = _newResolver(client, needsFribb: _anyTrackerNeedsFribb);
      _resolverClientKey = clientKey;
    }
    final ctx = await _buildContext(metadata, _resolver!);
    if (ctx == null) {
      appLogger.d('Trackers: no external IDs for ${metadata.id}');
      _reset();
      return;
    }
    _reset();
    _ctx = ctx;
  }

  bool _anyTrackerNeedsFribb() => _anyTrackerNeedsFribbForLibrary(_activeLibraryGlobalKey);

  bool _hasActiveTrackerForLibrary(String? libraryGlobalKey) =>
      _trackers.any((t) => t.canScrobble && t.shouldScrobbleForLibrary(libraryGlobalKey));

  bool _anyTrackerNeedsFribbForLibrary(String? libraryGlobalKey) =>
      _trackers.any((t) => t.canScrobble && t.needsFribb && t.shouldScrobbleForLibrary(libraryGlobalKey));

  void debugUseResolverDependencies({
    FribbMappingLookup? store,
    AnimeListsMappingLookup? animeLists,
    AnimeEpisodeProgressLookup? animeProgress,
  }) {
    _debugFribbStore = store;
    _debugAnimeListsStore = animeLists;
    _debugAnimeProgress = animeProgress;
    invalidateResolverCache();
  }

  TrackerIdResolver _newResolver(MediaServerClient client, {required bool Function() needsFribb}) => TrackerIdResolver(
    client,
    needsFribb: needsFribb,
    store: _debugFribbStore,
    animeLists: _debugAnimeListsStore,
    animeProgress: _debugAnimeProgress,
  );

  Future<void> markWatched(MediaItem item, MediaServerClient client) async {
    try {
      await _markWatched(item, client);
    } catch (e) {
      appLogger.d('Trackers: manual markWatched failed for ${item.id}', error: e);
    }
  }

  Future<void> markUnwatched(MediaItem item, MediaServerClient client) async {
    try {
      await _markUnwatched(item, client);
    } catch (e) {
      appLogger.d('Trackers: manual markUnwatched failed for ${item.id}', error: e);
    }
  }

  Future<void> _markWatched(MediaItem item, MediaServerClient client) async {
    final kind = item.kind;
    if (kind != MediaKind.movie && kind != MediaKind.episode && kind != MediaKind.season && kind != MediaKind.show) {
      return;
    }

    final libraryGlobalKey = item.libraryGlobalKey;
    if (!_hasActiveTrackerForLibrary(libraryGlobalKey)) return;

    final resolver = _newResolver(client, needsFribb: () => _anyTrackerNeedsFribbForLibrary(libraryGlobalKey));

    if (kind == MediaKind.movie || kind == MediaKind.episode) {
      await _markSingleWatched(item, resolver);
      return;
    }

    final episodes = <MediaItem>[];
    if (kind == MediaKind.show) {
      await collectEpisodesForShow(client, item.id, unwatchedOnly: false, out: episodes, fallback: item);
    } else {
      await collectEpisodesForSeason(client, item.id, unwatchedOnly: false, out: episodes, fallback: item);
    }
    appLogger.d('Trackers: manual ${kind.name} ${item.id} expanded to ${episodes.length} episodes');

    await _markContainerEpisodesWatched(episodes, resolver);
  }

  Future<void> _markUnwatched(MediaItem item, MediaServerClient client) async {
    final kind = item.kind;
    if (kind != MediaKind.movie && kind != MediaKind.episode && kind != MediaKind.season && kind != MediaKind.show) {
      return;
    }

    final libraryGlobalKey = item.libraryGlobalKey;
    if (!_hasActiveTrackerForLibrary(libraryGlobalKey)) return;

    final resolver = _newResolver(client, needsFribb: () => _anyTrackerNeedsFribbForLibrary(libraryGlobalKey));

    if (kind == MediaKind.movie || kind == MediaKind.episode) {
      await _markSingleUnwatched(item, resolver);
      return;
    }

    final episodes = <MediaItem>[];
    if (kind == MediaKind.show) {
      await collectEpisodesForShow(client, item.id, unwatchedOnly: false, out: episodes, fallback: item);
    } else {
      await collectEpisodesForSeason(client, item.id, unwatchedOnly: false, out: episodes, fallback: item);
    }
    appLogger.d('Trackers: manual ${kind.name} ${item.id} unwatched expanded to ${episodes.length} episodes');

    await _markContainerEpisodesUnwatched(episodes, resolver);
  }

  Future<void> _markContainerEpisodesWatched(List<MediaItem> episodes, TrackerIdResolver resolver) async {
    final animeGroups = <String, _ManualAnimeProgress>{};
    var resolved = 0;

    for (final episode in episodes) {
      final ctx = await _buildContext(episode, resolver, includeAnimeProgress: false);
      if (ctx == null) continue;
      resolved++;

      await _dispatchToTrackers([SimklTracker.instance], ctx);

      final key = _animeGroupKey(ctx);
      if (key == null) continue;
      (animeGroups[key] ??= _ManualAnimeProgress(ctx, fallbackToCount: true)).add(ctx);
    }

    appLogger.d('Trackers: manual container resolved $resolved/${episodes.length} episodes');

    for (final group in animeGroups.values) {
      final ctx = group.context;
      if (ctx != null) await _dispatchToTrackers([MalTracker.instance, AnilistTracker.instance], ctx);
    }
    appLogger.d('Trackers: manual container resolved ${animeGroups.length} anime entries');
  }

  Future<void> _markContainerEpisodesUnwatched(List<MediaItem> episodes, TrackerIdResolver resolver) async {
    final malEntries = <int, TrackerContext>{};
    final anilistEntries = <int, TrackerContext>{};
    var resolved = 0;

    for (final episode in episodes) {
      final ctx = await _buildContext(
        episode,
        resolver,
        includeAnimeProgress: false,
        fallbackToAnimeEpisodeNumber: false,
      );
      if (ctx == null) continue;
      resolved++;

      await _dispatchUnwatchedToTrackers([SimklTracker.instance], ctx);

      final anime = ctx.anime;
      if (anime == null) continue;
      final malId = anime.mal;
      if (malId != null && _isActive(MalTracker.instance, ctx.libraryGlobalKey)) {
        malEntries[malId] = ctx;
      }
      final anilistId = anime.anilist;
      if (anilistId != null && _isActive(AnilistTracker.instance, ctx.libraryGlobalKey)) {
        anilistEntries[anilistId] = ctx;
      }
    }

    appLogger.d('Trackers: manual container unwatched resolved $resolved/${episodes.length} episodes');

    await _removeAnimeEntriesFromLists(malEntries.values, anilistEntries.values);
    appLogger.d(
      'Trackers: manual container unwatched resolved ${malEntries.length} MAL and ${anilistEntries.length} AniList entries',
    );
  }

  Future<void> _removeAnimeEntriesFromLists(
    Iterable<TrackerContext> malEntries,
    Iterable<TrackerContext> anilistEntries,
  ) async {
    await Future.wait([
      ...malEntries.map((ctx) async {
        try {
          await MalTracker.instance.removeFromList(ctx);
        } catch (e) {
          appLogger.d('mal: removeFromList failed', error: e);
        }
      }),
      ...anilistEntries.map((ctx) async {
        try {
          await AnilistTracker.instance.removeFromList(ctx);
        } catch (e) {
          appLogger.d('anilist: removeFromList failed', error: e);
        }
      }),
    ]);
  }

  String? _animeGroupKey(TrackerContext ctx) {
    final anime = ctx.anime;
    if (anime == null) return null;
    final hasMal = anime.mal != null && _isActive(MalTracker.instance, ctx.libraryGlobalKey);
    final hasAnilist = anime.anilist != null && _isActive(AnilistTracker.instance, ctx.libraryGlobalKey);
    if (!hasMal && !hasAnilist) return null;
    return '${hasMal ? anime.mal : ''}:${hasAnilist ? anime.anilist : ''}';
  }

  Future<void> _markSingleWatched(MediaItem item, TrackerIdResolver resolver) async {
    final ctx = await _buildContext(item, resolver);
    if (ctx == null) {
      appLogger.d('Trackers: no external IDs for manually watched ${item.id}');
      return;
    }
    await _dispatchMarkWatched(ctx);
  }

  Future<void> _markSingleUnwatched(MediaItem item, TrackerIdResolver resolver) async {
    final ctx = await _buildContext(item, resolver, includeAnimeProgress: false, fallbackToAnimeEpisodeNumber: false);
    if (ctx == null) {
      appLogger.d('Trackers: no external IDs for manually unwatched ${item.id}');
      return;
    }
    if (ctx.isMovie) {
      await _dispatchMarkUnwatched(ctx);
    } else {
      await _dispatchUnwatchedToTrackers([SimklTracker.instance], ctx);
    }
  }

  Future<void> stopPlayback() async {
    final ctx = _ctx;
    if (ctx == null) {
      _reset();
      return;
    }
    // Safety net: fire if we passed the threshold but missed the tick.
    if (!_thresholdCrossed && _crossed(_duration, _lastPosition)) {
      await _dispatchMarkWatched(ctx);
    }
    _reset();
  }

  void updatePosition(Duration position) {
    _lastPosition = position;
    final ctx = _ctx;
    if (ctx == null || _thresholdCrossed) return;
    if (!_crossed(_duration, position)) return;
    _thresholdCrossed = true;
    unawaited(_dispatchMarkWatched(ctx));
  }

  void updateDuration(Duration duration) {
    if (duration == _duration) return;
    _duration = duration;
  }

  /// Called on Plex profile switch — drops in-flight state across all
  /// trackers and invalidates the resolver so a fresh Plex client is used.
  void cancelInFlight() {
    _reset();
    _resolver?.clearCache();
    _resolver = null;
    _resolverClientKey = null;
  }

  /// Drop the resolver's ID cache without touching in-flight playback state.
  /// Called after a tracker is connected/disconnected so cached lookups
  /// re-evaluate the `needsFribb` predicate.
  void invalidateResolverCache() => _resolver?.clearCache();

  void _reset() {
    _ctx = null;
    _activeLibraryGlobalKey = null;
    _duration = Duration.zero;
    _lastPosition = Duration.zero;
    _thresholdCrossed = false;
  }

  static bool _crossed(Duration duration, Duration position) {
    final dMs = duration.inMilliseconds;
    if (dMs == 0) return false;
    return position.inMilliseconds * 100 >= dMs * TrackerConstants.watchedThresholdPercent;
  }

  Future<void> _dispatchMarkWatched(TrackerContext ctx) async {
    final active = _trackers.where((t) => t.canScrobble && t.shouldScrobbleForLibrary(ctx.libraryGlobalKey));
    await _dispatchToTrackers(active, ctx);
  }

  Future<void> _dispatchMarkUnwatched(TrackerContext ctx) async {
    final active = _trackers.where((t) => t.canScrobble && t.shouldScrobbleForLibrary(ctx.libraryGlobalKey));
    await _dispatchUnwatchedToTrackers(active, ctx);
  }

  bool _isActive(Tracker tracker, String? libraryGlobalKey) =>
      tracker.canScrobble && tracker.shouldScrobbleForLibrary(libraryGlobalKey);

  Future<void> _dispatchToTrackers(Iterable<Tracker> trackers, TrackerContext ctx) async {
    final active = trackers.where((t) => _isActive(t, ctx.libraryGlobalKey));
    await Future.wait(
      active.map((t) async {
        try {
          await t.markWatched(ctx);
        } catch (e) {
          appLogger.d('${t.name}: markWatched failed', error: e);
        }
      }),
    );
  }

  Future<void> _dispatchUnwatchedToTrackers(Iterable<Tracker> trackers, TrackerContext ctx) async {
    final active = trackers.where((t) => _isActive(t, ctx.libraryGlobalKey));
    await Future.wait(
      active.map((t) async {
        try {
          await t.markUnwatched(ctx);
        } catch (e) {
          appLogger.d('${t.name}: markUnwatched failed', error: e);
        }
      }),
    );
  }

  Future<TrackerContext?> _buildContext(
    MediaItem metadata,
    TrackerIdResolver resolver, {
    bool includeAnimeProgress = true,
    bool includeCurrentEpisode = true,
    bool fallbackToAnimeEpisodeNumber = true,
  }) async {
    final libraryKey = metadata.libraryGlobalKey;

    if (metadata.kind == MediaKind.movie) {
      final ids = await resolver.resolveForMovie(metadata.id);
      if (ids == null) return null;
      return TrackerContext.movie(
        external: ids.external,
        anime: ids.anime,
        ratingKey: metadata.id,
        libraryGlobalKey: libraryKey,
      );
    }

    final season = metadata.parentIndex;
    final number = metadata.index;
    if (season == null || number == null) return null;

    final ids = await resolver.resolveShowForEpisode(
      metadata,
      includeAnimeProgress: includeAnimeProgress,
      includeCurrentEpisode: includeCurrentEpisode,
    );
    if (ids == null) return null;
    final animeProgress = includeAnimeProgress
        ? ids.animeProgress ?? (fallbackToAnimeEpisodeNumber ? ids.animeEpisodeNumber : null)
        : fallbackToAnimeEpisodeNumber
        ? ids.animeEpisodeNumber
        : null;
    return TrackerContext.episode(
      external: ids.external,
      anime: ids.anime,
      ratingKey: metadata.id,
      libraryGlobalKey: libraryKey,
      season: season,
      episodeNumber: number,
      animeProgress: animeProgress,
    );
  }
}

class _ManualAnimeProgress {
  final TrackerContext _base;
  final bool _fallbackToCount;
  int _count = 0;
  int? _maxMappedProgress;

  _ManualAnimeProgress(this._base, {required bool fallbackToCount}) : _fallbackToCount = fallbackToCount;

  void add(TrackerContext ctx) {
    _count++;
    final mapped = ctx.animeProgress;
    if (mapped != null && (_maxMappedProgress == null || mapped > _maxMappedProgress!)) {
      _maxMappedProgress = mapped;
    }
  }

  int? get progress => _maxMappedProgress ?? (_fallbackToCount ? _count : null);

  TrackerContext? get context {
    final progress = this.progress;
    if (progress == null) return null;
    return TrackerContext.episode(
      external: _base.external,
      anime: _base.anime,
      ratingKey: _base.ratingKey,
      libraryGlobalKey: _base.libraryGlobalKey,
      season: _base.season!,
      episodeNumber: progress,
      animeProgress: progress,
    );
  }
}
