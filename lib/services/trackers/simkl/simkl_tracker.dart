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
import 'simkl_client.dart';
import 'simkl_session.dart';

/// Simkl scrobble tracker. Fires `POST /sync/history` once playback crosses
/// the watched threshold (Simkl has no real-time `/scrobble/*` endpoints).
///
/// General-purpose: accepts any Plex external ID (tvdb/imdb/tmdb) directly,
/// so it fires for non-anime TV and movies too. Prefers Fribb's simkl_id
/// when present for stricter anime match, otherwise falls back to whatever
/// Plex exposes.
class SimklTracker extends TrackerBase {
  static SimklTracker? _instance;
  static SimklTracker get instance => _instance ??= SimklTracker._();
  SimklTracker._();

  @override
  String get name => 'simkl';

  @override
  TrackerService get service => TrackerService.simkl;

  @override
  bool get needsFribb => false;

  SimklClient? _client;

  @override
  bool get hasActiveClient => _client != null;

  @override
  bool readEnabledSetting(SettingsService settings) => settings.read(SettingsService.enableSimklScrobble);

  void rebindSession(SimklSession? session, {required void Function() onSessionInvalidated, http.Client? httpClient}) {
    _client?.dispose();
    _client = session != null
        ? SimklClient(session, onSessionInvalidated: onSessionInvalidated, httpClient: httpClient)
        : null;
  }

  @override
  Future<void> markWatched(TrackerContext ctx) async {
    final client = _client;
    if (client == null) return;

    final ids = _buildIds(external: ctx.external, anime: ctx.anime);
    if (ids.isEmpty) return;

    final body = _historyBody(ctx, ids);

    await client.addToHistory(body);
    appLogger.d('Simkl: marked watched (ids=$ids, isMovie=${ctx.isMovie})');
  }

  @override
  Future<void> markUnwatched(TrackerContext ctx) async {
    final client = _client;
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

  Future<int?> getRating(TrackerRatingContext ctx) async {
    final client = _client;
    if (client == null) throw const TrackerRatingUnavailableException('Simkl');
    final ids = _buildIds(external: ctx.ids.external, anime: ctx.ids.anime);
    if (ids.isEmpty) throw const TrackerRatingUnavailableException('Simkl');

    final types = ctx.isMovie ? const ['movies'] : const ['shows', 'anime'];
    for (final type in types) {
      final entries = await client.getRatings(type);
      for (final entry in entries) {
        if (entry is! Map) continue;
        final map = entry.cast<String, dynamic>();
        final media = map[ctx.isMovie ? 'movie' : 'show'];
        final remoteIds = _nestedIds(media) ?? _nestedIds(map);
        if (!_idsMatch(remoteIds, ids)) continue;
        final rating = flexibleInt(map['user_rating']) ?? flexibleInt(map['rating']);
        return rating != null && rating > 0 ? rating.clamp(1, 10).toInt() : null;
      }
    }
    return null;
  }

  Future<void> rate(TrackerRatingContext ctx, int score) async {
    final client = _client;
    if (client == null) throw const TrackerRatingUnavailableException('Simkl');
    final ids = _buildIds(external: ctx.ids.external, anime: ctx.ids.anime);
    if (ids.isEmpty) throw const TrackerRatingUnavailableException('Simkl');

    final clamped = score.clamp(1, 10).toInt();
    await client.addRatings(_ratingBody(ctx, ids, rating: clamped));
    appLogger.d('Simkl: updated score (ids=$ids, score=$clamped)');
  }

  Future<void> clearRating(TrackerRatingContext ctx) async {
    final client = _client;
    if (client == null) throw const TrackerRatingUnavailableException('Simkl');
    final ids = _buildIds(external: ctx.ids.external, anime: ctx.ids.anime);
    if (ids.isEmpty) throw const TrackerRatingUnavailableException('Simkl');

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

  Map<String, dynamic>? _nestedIds(Object? value) {
    if (value is! Map) return null;
    final ids = value['ids'];
    return ids is Map ? ids.cast<String, dynamic>() : null;
  }

  bool _idsMatch(Map<String, dynamic>? remoteIds, Map<String, Object> localIds) {
    if (remoteIds == null) return false;
    for (final entry in localIds.entries) {
      final remote = remoteIds[entry.key];
      if (remote == null) continue;
      if (entry.value is String && remote.toString() == entry.value) return true;
      final remoteInt = flexibleInt(remote);
      final localInt = flexibleInt(entry.value);
      if (remoteInt != null && localInt != null && remoteInt == localInt) return true;
    }
    return false;
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
