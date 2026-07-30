import 'package:http/http.dart' as http;

import '../../../models/trackers/anime_ids.dart';
import '../../../models/trackers/tracker_context.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/external_ids.dart';
import '../../../utils/json_utils.dart';
import '../tracker.dart';
import '../tracker_constants.dart';
import '../tracker_id_resolver.dart';
import '../tracker_write_queue.dart';
import '../tracker_rating_match.dart';
import '../tracker_session.dart';
import 'simkl_client.dart';

/// Simkl tracker.
///
/// In-player playback is reported in real time through `POST /scrobble/start`,
/// `/pause` and `/stop` — Simkl's own rules then decide watched state: a `stop`
/// at >= 80% progress marks the item watched, below that it saves a resumable
/// playback so partially watched items survive (issue #1719). `POST
/// /sync/history` stays for the marks that never pass through the player:
/// manual, container, offline replay and external players.
///
/// General-purpose: accepts any Plex external ID (tvdb/imdb/tmdb) directly,
/// so it fires for non-anime TV and movies too. Prefers Fribb's simkl_id
/// when present for stricter anime match, otherwise falls back to whatever
/// Plex exposes.
class SimklTracker extends TrackerBase
    with ClientBackedTracker<SimklClient>
    implements TrackerRatingSource, RealtimeScrobbleTracker, EpisodeHistoryTracker {
  static SimklTracker? _instance;
  static SimklTracker get instance => _instance ??= SimklTracker._();
  SimklTracker._();

  @override
  String get name => 'simkl';

  @override
  TrackerService get service => TrackerService.simkl;

  @override
  bool get needsFribb => false;

  /// Simkl counts a `/scrobble/stop` as a watch from this progress upwards and
  /// files anything below it as resumable playback instead.
  static const double _scrobbleWatchedPercent = 80.0;

  /// The bound client is replaced on every session rebind, so its identity is
  /// the account identity.
  @override
  Object? get scrobbleBinding => client;

  @override
  bool get canReportPlayback => isEnabledWithSession;

  @override
  ScrobblePolicy get scrobblePolicy => const ScrobblePolicy(
    // Simkl serialises scrobble writes behind a 20-second per-user lock and
    // fails whatever queues up with a 400, so a re-sent `start` waits it out.
    resendThrottle: Duration(seconds: 20),
    // Simkl asks for nothing on a seek, so it receives no seek checkpoints.
    seekThrottle: null,
  );

  /// Prefers the server's external ids, which are always present when Simkl can
  /// write at all; its own id is a fallback, not part of the identity, because it
  /// only appears once an anime mapping has been downloaded.
  @override
  String? historyRowIdentity(TrackerContext ctx) {
    final external = trackerExternalRowIdentity(ctx.external);
    if (external != null) return external;
    final simklId = ctx.anime?.simkl;
    return simklId == null ? null : 'simkl=$simklId';
  }

  void rebindSession(
    TrackerSession? session, {
    required void Function() onSessionInvalidated,
    http.Client? httpClient,
  }) {
    rebindTrackerClient(
      session,
      createClient: (session) =>
          SimklClient(session, onSessionInvalidated: onSessionInvalidated, httpClient: httpClient),
    );
  }

  /// [watchedAt] is ignored: the history body Simkl accepts here carries no
  /// timestamp, so a replayed write records as "now".
  @override
  Future<void> markWatched(TrackerContext ctx, {DateTime? watchedAt}) async {
    final client = this.client;
    if (client == null) return;

    final ids = _buildIds(external: ctx.external, anime: ctx.anime);
    if (ids.isEmpty) return;

    final body = _historyBody(ctx, ids);

    await client.addToHistory(body);
    appLogger.d('Simkl: marked watched (ids=$ids, isMovie=${ctx.isMovie})');
  }

  @override
  Future<void> markUnwatched(TrackerContext ctx) async {
    final client = this.client;
    if (client == null) return;

    final ids = _buildIds(external: ctx.external, anime: ctx.anime);
    if (ids.isEmpty) return;

    await client.removeFromHistory(_historyBody(ctx, ids));
    appLogger.d('Simkl: marked unwatched (ids=$ids, isMovie=${ctx.isMovie})');
  }

  @override
  Future<void> scrobble(TrackerContext ctx, TrackerScrobbleState state, double progressPercent) async {
    final client = this.client;
    if (client == null) return;

    final ids = _buildIds(external: ctx.external, anime: ctx.anime);
    if (ids.isEmpty) return;

    final action = switch (state) {
      TrackerScrobbleState.start => 'start',
      TrackerScrobbleState.pause => 'pause',
      TrackerScrobbleState.stop => 'stop',
      TrackerScrobbleState.seek => null,
    };
    if (action == null) return;
    await client.scrobble(
      action,
      _scrobbleBody(ctx, ids, progressPercent),
      allowConflict: state == TrackerScrobbleState.stop,
    );
    appLogger.d('Simkl: scrobble $action @ ${progressPercent.toStringAsFixed(1)}% (ids=$ids)');
  }

  @override
  Future<void> reconcileWatchedAfterStop(TrackerContext ctx, double progressPercent) async {
    // At or above Simkl's own rule the stop already marked it watched; sending
    // history too would write the same watch twice.
    if (progressPercent >= _scrobbleWatchedPercent) return;
    appLogger.d('Simkl: stop below ${_scrobbleWatchedPercent.toStringAsFixed(0)}% — recording watch explicitly');
    await markWatched(ctx);
  }

  /// Scrobble takes a single `movie`/`show` object plus a sibling `episode`,
  /// unlike the plural history/ratings shapes. `show` also covers anime:
  /// Simkl routes by id and maps TVDB season/episode numbering to AniDB
  /// itself.
  Map<String, dynamic> _scrobbleBody(TrackerContext ctx, Map<String, Object> ids, double progressPercent) {
    // Simkl accepts at most two decimal places on `progress`.
    final progress = double.parse(progressPercent.toStringAsFixed(2));
    return ctx.isMovie
        ? {
            'progress': progress,
            'movie': {'ids': ids},
          }
        : {
            'progress': progress,
            'show': {'ids': ids},
            'episode': {'season': ctx.season, 'number': ctx.episodeNumber},
          };
  }

  Map<String, dynamic> _historyBody(TrackerContext ctx, Map<String, Object> ids) {
    return ctx.isMovie
        ? {
            'movies': [
              {'ids': ids},
            ],
          }
        : {
            'shows': [
              {
                'ids': ids,
                'seasons': [
                  {
                    'number': ctx.season,
                    'episodes': [
                      {'number': ctx.episodeNumber},
                    ],
                  },
                ],
              },
            ],
          };
  }

  /// Resolve the active client + matchable ids, or throw if rating is
  /// unavailable (no session, or no usable external/anime ids).
  (SimklClient, Map<String, Object>) _ratingTarget(TrackerRatingContext ctx) {
    final activeClient = client;
    if (activeClient == null) throw const TrackerRatingUnavailableException('Simkl');
    final ids = _buildIds(external: ctx.ids.external, anime: ctx.ids.anime);
    if (ids.isEmpty) throw const TrackerRatingUnavailableException('Simkl');
    return (activeClient, ids);
  }

  @override
  Future<int?> getRating(TrackerRatingContext ctx) async {
    final (client, ids) = _ratingTarget(ctx);
    final types = ctx.isMovie ? const ['movies'] : const ['shows', 'anime'];
    for (final type in types) {
      final entries = await client.getRatings(type);
      for (final entry in entries) {
        if (entry is! Map) continue;
        final map = entry.cast<String, dynamic>();
        final media = map[ctx.isMovie ? 'movie' : 'show'];
        final remoteIds = trackerNestedIds(media) ?? trackerNestedIds(map);
        if (!trackerIdsMatch(remoteIds, ids)) continue;
        final rating = flexibleInt(map['user_rating']) ?? flexibleInt(map['rating']);
        return rating != null && rating > 0 ? rating.clamp(1, 10).toInt() : null;
      }
    }
    return null;
  }

  @override
  Future<void> rate(TrackerRatingContext ctx, int score) async {
    final (client, ids) = _ratingTarget(ctx);
    final clamped = score.clamp(1, 10).toInt();
    await client.addRatings(_ratingBody(ctx, ids, rating: clamped));
    appLogger.d('Simkl: updated score (ids=$ids, score=$clamped)');
  }

  @override
  Future<void> clearRating(TrackerRatingContext ctx) async {
    final (client, ids) = _ratingTarget(ctx);
    await client.removeRatings(_ratingBody(ctx, ids));
    appLogger.d('Simkl: cleared score (ids=$ids)');
  }

  Map<String, dynamic> _ratingBody(TrackerRatingContext ctx, Map<String, Object> ids, {int? rating}) {
    final item = {'ids': ids, 'rating': ?rating};
    return ctx.isMovie
        ? {
            'movies': [item],
          }
        : {
            'shows': [item],
          };
  }

  /// Prefer Fribb's simkl_id for precision; otherwise send whatever Plex
  /// exposes. Simkl accepts tvdb/imdb/tmdb in both movie and show shapes.
  Map<String, Object> _buildIds({required ExternalIds external, required AnimeIds? anime}) {
    final ids = <String, Object>{};
    final simklId = anime?.simkl;
    if (simklId != null) ids['simkl'] = simklId;
    final tvdb = external.tvdb;
    if (tvdb != null) ids['tvdb'] = tvdb;
    final tmdb = external.tmdb;
    if (tmdb != null) ids['tmdb'] = tmdb;
    final imdb = external.imdb;
    if (imdb != null) ids['imdb'] = imdb;
    return ids;
  }
}
