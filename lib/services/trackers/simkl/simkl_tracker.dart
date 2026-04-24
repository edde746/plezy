import '../../../models/trackers/tracker_context.dart';
import '../../../utils/app_logger.dart';
import '../../settings_service.dart';
import '../tracker.dart';
import '../tracker_constants.dart';
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
  bool readEnabledSetting(SettingsService settings) => settings.getEnableSimklScrobble();

  void rebindSession(SimklSession? session, {required void Function() onSessionInvalidated}) {
    _client?.dispose();
    _client = session != null ? SimklClient(session, onSessionInvalidated: onSessionInvalidated) : null;
  }

  @override
  Future<void> markWatched(TrackerContext ctx) async {
    final client = _client;
    if (client == null) return;

    final ids = _buildIds(ctx);
    if (ids.isEmpty) return;

    final body = ctx.isMovie
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

    await client.addToHistory(body);
    appLogger.d('Simkl: marked watched (ids=$ids, isMovie=${ctx.isMovie})');
  }

  /// Prefer Fribb's simkl_id for precision; otherwise send whatever Plex
  /// exposes. Simkl accepts tvdb/imdb/tmdb in both movie and show shapes.
  Map<String, Object> _buildIds(TrackerContext ctx) {
    final ids = <String, Object>{};
    final simklId = ctx.anime?.simkl;
    if (simklId != null) ids['simkl'] = simklId;
    final tvdb = ctx.external.tvdb;
    if (tvdb != null) ids['tvdb'] = tvdb;
    final tmdb = ctx.external.tmdb;
    if (tmdb != null) ids['tmdb'] = tmdb;
    final imdb = ctx.external.imdb;
    if (imdb != null) ids['imdb'] = imdb;
    return ids;
  }
}
