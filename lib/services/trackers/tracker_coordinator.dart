import 'dart:async';

import '../../models/plex_metadata.dart';
import '../../models/trackers/tracker_context.dart';
import '../../utils/app_logger.dart';
import '../plex_client.dart';
import 'anilist/anilist_tracker.dart';
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

  TrackerContext? _ctx;
  Duration _duration = Duration.zero;
  Duration _lastPosition = Duration.zero;
  bool _thresholdCrossed = false;

  Future<void> initialize() async {
    await Future.wait(_trackers.map((t) => t.initialize()));
  }

  Future<void> startPlayback(PlexMetadata metadata, PlexClient plexClient, {bool isLive = false}) async {
    if (isLive) return;
    final mediaType = metadata.mediaType;
    if (mediaType != PlexMediaType.movie && mediaType != PlexMediaType.episode) return;
    if (!_trackers.any((t) => t.canScrobble)) return;

    _resolver ??= TrackerIdResolver(plexClient, needsFribb: _anyTrackerNeedsFribb);
    final ctx = await _buildContext(metadata);
    if (ctx == null) {
      appLogger.d('Trackers: no external IDs for ${metadata.ratingKey}');
      _reset();
      return;
    }
    _reset();
    _ctx = ctx;
  }

  bool _anyTrackerNeedsFribb() => _trackers.any((t) => t.canScrobble && t.needsFribb);

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
  }

  /// Drop the resolver's ID cache without touching in-flight playback state.
  /// Called after a tracker is connected/disconnected so cached lookups
  /// re-evaluate the `needsFribb` predicate.
  void invalidateResolverCache() => _resolver?.clearCache();

  void _reset() {
    _ctx = null;
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

  Future<TrackerContext?> _buildContext(PlexMetadata metadata) async {
    final resolver = _resolver;
    if (resolver == null) return null;

    final libraryKey = metadata.librarySectionGlobalKey;

    if (metadata.mediaType == PlexMediaType.movie) {
      final ids = await resolver.resolveForMovie(metadata.ratingKey);
      if (ids == null) return null;
      return TrackerContext.movie(
        external: ids.external,
        anime: ids.anime,
        ratingKey: metadata.ratingKey,
        libraryGlobalKey: libraryKey,
      );
    }

    final season = metadata.parentIndex;
    final number = metadata.index;
    if (season == null || number == null) return null;

    final ids = await resolver.resolveShowForEpisode(metadata);
    if (ids == null) return null;
    return TrackerContext.episode(
      external: ids.external,
      anime: ids.anime,
      ratingKey: metadata.ratingKey,
      libraryGlobalKey: libraryKey,
      season: season,
      episodeNumber: number,
    );
  }
}
