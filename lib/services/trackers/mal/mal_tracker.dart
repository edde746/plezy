import 'package:http/http.dart' as http;

import '../../../models/trackers/anime_ids.dart';
import '../../../utils/app_logger.dart';
import '../../settings_service.dart';
import '../anime_list_tracker_base.dart';
import '../tracker.dart';
import '../tracker_constants.dart';
import '../tracker_exceptions.dart';
import '../tracker_session.dart';
import 'mal_client.dart';

/// MyAnimeList scrobble tracker. Marks `num_watched_episodes` on the user's
/// list entry once playback crosses the watched threshold.
///
/// MAL is anime-only: no-op when [TrackerContext.anime] is null.
///
/// For anime episodes, MAL receives watched progress in the mapped anime entry
/// when Fribb can define that scope, otherwise local episode progress.
class MalTracker extends TrackerBase with ClientBackedTracker<MalClient>, AnimeListTrackerBase<MalClient> {
  static MalTracker? _instance;
  static MalTracker get instance => _instance ??= MalTracker._();
  MalTracker._();

  @override
  String get name => 'mal';

  @override
  TrackerService get service => TrackerService.mal;

  @override
  bool readEnabledSetting(SettingsService settings) => settings.read(SettingsService.enableMalScrobble);

  @override
  String get logLabel => 'MAL';

  @override
  String get idLogName => 'mal';

  @override
  String get ratingUnavailableName => 'MAL';

  void rebindSession(
    TrackerSession? session, {
    required void Function() onSessionInvalidated,
    void Function(TrackerSession)? onSessionUpdated,
    http.Client? httpClient,
  }) {
    rebindTrackerClient(
      session,
      onBeforeBind: clearAnimeListTrackerCache,
      createClient: (session) => MalClient(
        session,
        onSessionInvalidated: onSessionInvalidated,
        onSessionUpdated: onSessionUpdated,
        httpClient: httpClient,
      ),
    );
  }

  @override
  int? animeId(AnimeIds? anime) => anime?.mal;

  @override
  Future<int?> loadAnimeEpisodeCount(MalClient client, int malId) => client.getAnimeEpisodeCount(malId);

  @override
  Future<void> saveAnimeProgress(
    MalClient client, {
    required int animeId,
    required int progress,
    required bool completed,
  }) async {
    final fields = {'status': completed ? 'completed' : 'watching', 'num_watched_episodes': '$progress'};
    await client.updateMyListStatus(animeId, fields);
    appLogger.d('MAL: updated list status (mal=$animeId, fields=$fields)');
  }

  @override
  Future<void> deleteAnimeEntry(MalClient client, int malId) async {
    try {
      await client.deleteMyListStatus(malId);
      appLogger.d('MAL: deleted list status (mal=$malId)');
    } on TrackerApiException catch (e) {
      if (e.statusCode == 404) return;
      rethrow;
    }
  }

  @override
  Future<void> setAnimeRating(MalClient client, int malId, int score) async {
    await client.updateMyListStatus(malId, {'score': '$score'});
    appLogger.d(score == 0 ? 'MAL: cleared score (mal=$malId)' : 'MAL: updated score (mal=$malId, score=$score)');
  }

  @override
  Future<int?> loadAnimeRating(MalClient client, int malId) => client.getMyListScore(malId);
}
