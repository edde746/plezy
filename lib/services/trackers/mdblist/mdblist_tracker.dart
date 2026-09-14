import 'package:http/http.dart' as http;

import '../../../models/trackers/tracker_context.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/external_ids.dart';
import '../../../utils/json_utils.dart';
import '../tracker.dart';
import '../tracker_constants.dart';
import '../tracker_id_resolver.dart';
import '../tracker_rating_match.dart';
import '../tracker_session.dart';
import '../tracker_write_queue.dart';
import 'mdblist_client.dart';

/// MDBList tracker.
///
/// In-player playback is reported in real time through `POST /scrobble/start`,
/// `/pause` and `/stop`; MDBList's own rule then decides watched state — a
/// `stop` at or above 80% progress files the item under `/sync/watched` and
/// deletes the session. `POST /sync/watched` covers the marks that never pass
/// through the player: manual, container, offline replay and external players.
///
/// Matching is by IMDb and TMDb id only. MDBList's id block accepts
/// `imdb`/`tmdb`/`trakt`/`kitsu`/`mdblist` but **not** `tvdb`, so an item that
/// a media server only identifies by TVDB id cannot be written and is skipped
/// rather than mismatched onto the wrong title.
class MdblistTracker extends TrackerBase
    with ClientBackedTracker<MdblistClient>
    implements TrackerRatingSource, RealtimeScrobbleTracker, EpisodeHistoryTracker {
  static MdblistTracker? _instance;
  static MdblistTracker get instance => _instance ??= MdblistTracker._();
  MdblistTracker._();

  @override
  String get name => 'mdblist';

  @override
  TrackerService get service => TrackerService.mdblist;

  /// MDBList carries no anime mapping of its own and takes plain external ids.
  @override
  bool get needsFribb => false;

  /// MDBList counts a `/scrobble/stop` as a watch from this progress upwards.
  static const double _scrobbleWatchedPercent = 80.0;

  @override
  bool get canReportPlayback => isEnabledWithSession;

  @override
  ScrobblePolicy get scrobblePolicy => const ScrobblePolicy(
    // MDBList documents no per-item scrobble cooldown, so this mirrors the
    // conservative Trakt window rather than re-sending `start` freely.
    resendThrottle: Duration(seconds: 30),
    // A slider drag emits many position updates; only one checkpoint per
    // window reaches MDBList.
    seekThrottle: Duration(seconds: 5),
  );

  void rebindSession(
    TrackerSession? session, {
    required void Function() onSessionInvalidated,
    void Function(TrackerSession session)? onSessionUpdated,
    http.Client? httpClient,
  }) {
    rebindTrackerClient(
      session,
      createClient: (session) => MdblistClient(
        session,
        onSessionInvalidated: onSessionInvalidated,
        onSessionUpdated: onSessionUpdated,
        httpClient: httpClient,
      ),
    );
  }

  /// MDBList matches on the media server's own external ids and nothing else.
  @override
  String? historyRowIdentity(TrackerContext ctx) => trackerExternalRowIdentity(ctx.external);

  @override
  Future<void> markWatched(TrackerContext ctx, {DateTime? watchedAt}) async {
    final client = this.client;
    if (client == null || !canWriteWatched) return;
    final body = _watchedBody(ctx, watchedAt: watchedAt);
    if (body == null) return;

    await client.addToWatched(body);
    appLogger.d('MDBList: marked watched (${ctx.ratingKey}, isMovie=${ctx.isMovie})');
  }

  @override
  Future<void> markUnwatched(TrackerContext ctx) async {
    final client = this.client;
    if (client == null || !canWriteWatched) return;
    final body = _watchedBody(ctx);
    if (body == null) return;

    await client.removeFromWatched(body);
    appLogger.d('MDBList: marked unwatched (${ctx.ratingKey}, isMovie=${ctx.isMovie})');
  }

  @override
  Future<void> scrobble(TrackerContext ctx, TrackerScrobbleState state, double progressPercent) async {
    final client = this.client;
    if (client == null) return;
    final body = _scrobbleBody(ctx, progressPercent);
    if (body == null) return;

    final action = switch (state) {
      TrackerScrobbleState.start => 'start',
      TrackerScrobbleState.pause => 'pause',
      // MDBList has no seek event, but `start` is documented as upserting the
      // session's progress, so one re-start checkpoints the new position
      // without the pause+start pair Trakt needs.
      TrackerScrobbleState.seek => 'start',
      TrackerScrobbleState.stop => 'stop',
    };
    await client.scrobble(action, body);
    appLogger.d('MDBList: scrobble ${state.name} @ ${progressPercent.toStringAsFixed(1)}%');
  }

  @override
  Future<void> reconcileWatchedAfterStop(TrackerContext ctx, double progressPercent) async {
    // At or above MDBList's own rule the stop already recorded the watch; a
    // `/sync/watched` write would record a second one.
    if (progressPercent >= _scrobbleWatchedPercent) return;
    appLogger.d('MDBList: stop below ${_scrobbleWatchedPercent.toStringAsFixed(0)}% — recording watch explicitly');
    await markWatched(ctx);
  }

  /// `/sync/watched` and its `/remove` sibling share one shape; the remove
  /// variant simply carries no timestamps.
  Map<String, dynamic>? _watchedBody(TrackerContext ctx, {DateTime? watchedAt}) {
    final ids = _ids(ctx.external);
    if (ids.isEmpty) return null;
    final stamp = watchedAt?.toUtc().toIso8601String();

    if (ctx.isMovie) {
      return {
        'movies': [
          {'ids': ids, 'watched_at': ?stamp},
        ],
      };
    }

    final season = ctx.season;
    final number = ctx.episodeNumber;
    if (season == null || number == null) return null;
    return {
      'shows': [
        {
          'ids': ids,
          'seasons': [
            {
              'number': season,
              'episodes': [
                {'number': number, 'watched_at': ?stamp},
              ],
            },
          ],
        },
      ],
    };
  }

  /// Scrobble nests the episode inside the show as `show.season.episode`,
  /// unlike the sibling `episode` object Trakt and Simkl accept.
  Map<String, dynamic>? _scrobbleBody(TrackerContext ctx, double progressPercent) {
    final ids = _ids(ctx.external);
    if (ids.isEmpty) return null;
    // MDBList rejects a progress outside 0-100; clamp rather than let a
    // rounding overshoot fail the whole report.
    final progress = double.parse(progressPercent.clamp(0, 100).toStringAsFixed(2));

    if (ctx.isMovie) {
      return {
        'movie': {'ids': ids},
        'progress': progress,
      };
    }

    final season = ctx.season;
    final number = ctx.episodeNumber;
    if (season == null || number == null) return null;
    return {
      'show': {
        'ids': ids,
        'season': {
          'number': season,
          'episode': {'number': number},
        },
      },
      'progress': progress,
    };
  }

  /// Resolve the active client plus a non-empty id block, or refuse. Without
  /// the id check a TVDB-only item would post `"ids": {}`, which MDBList would
  /// accept as a write against nothing.
  (MdblistClient, Map<String, Object>) _ratingTarget(TrackerRatingContext ctx) {
    final activeClient = client;
    if (activeClient == null) throw const TrackerRatingUnavailableException('MDBList');
    final ids = _ids(ctx.ids.external);
    if (ids.isEmpty) throw const TrackerRatingUnavailableException('MDBList');
    return (activeClient, ids);
  }

  @override
  Future<int?> getRating(TrackerRatingContext ctx) async {
    final (client, localIds) = _ratingTarget(ctx);

    final entries = await client.getRatings(trackerRatingType(ctx, 'MDBList'));
    for (final entry in entries) {
      if (entry is! Map) continue;
      final map = entry.cast<String, dynamic>();
      if (!trackerRatingEntryMatches(ctx, map, localIds)) continue;
      final rating = flexibleInt(map['rating']);
      return rating != null && rating > 0 ? rating.clamp(1, 10).toInt() : null;
    }
    return null;
  }

  @override
  Future<void> rate(TrackerRatingContext ctx, int score) async {
    final (client, ids) = _ratingTarget(ctx);
    await client.addRatings(trackerRatingBody(ctx, ids, 'MDBList', rating: score.clamp(1, 10).toInt()));
    appLogger.d('MDBList: updated score (${ctx.kind.name}, score=$score)');
  }

  @override
  Future<void> clearRating(TrackerRatingContext ctx) async {
    final (client, ids) = _ratingTarget(ctx);
    await client.removeRatings(trackerRatingBody(ctx, ids, 'MDBList'));
    appLogger.d('MDBList: cleared score (${ctx.kind.name})');
  }

  /// MDBList's id block. TVDB is deliberately absent — the API does not accept
  /// it, so a TVDB-only item yields an empty map and every write no-ops.
  Map<String, Object> _ids(ExternalIds external) => {'imdb': ?external.imdb, 'tmdb': ?external.tmdb};
}
