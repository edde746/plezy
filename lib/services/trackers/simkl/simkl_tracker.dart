import 'package:http/http.dart' as http;

import '../../../models/trackers/anime_ids.dart';
import '../../../models/trackers/tracker_context.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/external_ids.dart';
import '../../../utils/json_utils.dart';
import '../../settings_service.dart';
import '../tracker.dart';
import '../tracker_constants.dart';
import '../tracker_id_resolver.dart';
import '../tracker_rating_match.dart';
import '../tracker_session.dart';
import 'simkl_client.dart';

/// Simkl scrobble tracker. Fires `POST /sync/history` once playback crosses
/// the watched threshold (Simkl has no real-time `/scrobble/*` endpoints).
///
/// General-purpose: accepts any Plex external ID (tvdb/imdb/tmdb) directly,
/// so it fires for non-anime TV and movies too. Prefers Fribb's simkl_id
/// when present for stricter anime match, otherwise falls back to whatever
/// Plex exposes.
class SimklTracker extends TrackerBase with ClientBackedTracker<SimklClient> implements TrackerRatingSource {
  static SimklTracker? _instance;
  static SimklTracker get instance => _instance ??= SimklTracker._();
  SimklTracker._();

  @override
  String get name => 'simkl';

  @override
  TrackerService get service => TrackerService.simkl;

  @override
  bool get needsFribb => false;

  @override
  bool readEnabledSetting(SettingsService settings) => settings.read(SettingsService.enableSimklScrobble);

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

  @override
  Future<void> markWatched(TrackerContext ctx) async {
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
