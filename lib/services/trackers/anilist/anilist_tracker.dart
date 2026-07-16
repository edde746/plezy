import 'package:http/http.dart' as http;

import '../../../models/trackers/anime_ids.dart';
import '../../../models/trackers/tracker_context.dart';
import '../../../utils/app_logger.dart';
import '../../settings_service.dart';
import '../anime_list_tracker_base.dart';
import '../tracker.dart';
import '../tracker_constants.dart';
import '../tracker_session.dart';
import 'anilist_client.dart';

/// AniList scrobble tracker. Saves `SaveMediaListEntry(progress, status)`
/// once playback crosses the watched threshold.
///
/// AniList is anime-only: no-op when [TrackerContext.anime] is null.
class AnilistTracker extends TrackerBase with ClientBackedTracker<AnilistClient>, AnimeListTrackerBase<AnilistClient> {
  static AnilistTracker? _instance;
  static AnilistTracker get instance => _instance ??= AnilistTracker._();
  AnilistTracker._();

  @override
  String get name => 'anilist';

  @override
  TrackerService get service => TrackerService.anilist;

  @override
  bool readEnabledSetting(SettingsService settings) => settings.read(SettingsService.enableAnilistScrobble);

  @override
  String get logLabel => 'AniList';

  @override
  String get idLogName => 'anilist';

  @override
  String get ratingUnavailableName => 'AniList';

  void rebindSession(
    TrackerSession? session, {
    required void Function() onSessionInvalidated,
    http.Client? httpClient,
  }) {
    rebindTrackerClient(
      session,
      onBeforeBind: clearAnimeListTrackerCache,
      createClient: (session) =>
          AnilistClient(session, onSessionInvalidated: onSessionInvalidated, httpClient: httpClient),
    );
  }

  @override
  int? animeId(AnimeIds? anime) => anime?.anilist;

  @override
  Future<int?> loadAnimeEpisodeCount(AnilistClient client, int anilistId) => client.getAnimeEpisodeCount(anilistId);

  @override
  Future<void> saveAnimeProgress(
    AnilistClient client, {
    required int animeId,
    required int progress,
    required bool completed,
  }) async {
    final status = completed ? 'COMPLETED' : 'CURRENT';
    await client.saveMediaListEntry(mediaId: animeId, progress: progress, status: status);
    appLogger.d('AniList: saved entry (anilist=$animeId, progress=$progress, status=$status)');
  }

  @override
  Future<void> deleteAnimeEntry(AnilistClient client, int anilistId) async {
    await client.deleteMediaListEntry(anilistId);
    appLogger.d('AniList: deleted entry (anilist=$anilistId)');
  }

  @override
  Future<void> setAnimeRating(AnilistClient client, int anilistId, int score) async {
    await client.setMediaListScore(mediaId: anilistId, score: score);
    appLogger.d(
      score == 0
          ? 'AniList: cleared score (anilist=$anilistId)'
          : 'AniList: updated score (anilist=$anilistId, score=$score)',
    );
  }

  @override
  Future<int?> loadAnimeRating(AnilistClient client, int anilistId) => client.getMediaListScore(anilistId);
}
