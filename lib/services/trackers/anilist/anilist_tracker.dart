import '../../../models/trackers/tracker_context.dart';
import '../../../utils/app_logger.dart';
import '../../settings_service.dart';
import '../tracker.dart';
import 'anilist_client.dart';
import 'anilist_session.dart';

/// AniList scrobble tracker. Saves `SaveMediaListEntry(progress, status)`
/// once playback crosses the watched threshold.
///
/// AniList is anime-only: no-op when [TrackerContext.anime] is null.
class AnilistTracker extends TrackerBase {
  static AnilistTracker? _instance;
  static AnilistTracker get instance => _instance ??= AnilistTracker._();
  AnilistTracker._();

  @override
  String get name => 'anilist';

  @override
  bool get needsFribb => true;

  AnilistClient? _client;

  @override
  bool get hasActiveClient => _client != null;

  @override
  bool readEnabledSetting(SettingsService settings) => settings.getEnableAnilistScrobble();

  void rebindSession(AnilistSession? session, {required void Function() onSessionInvalidated}) {
    _client?.dispose();
    _client = session == null ? null : AnilistClient(session, onSessionInvalidated: onSessionInvalidated);
  }

  @override
  Future<void> markWatched(TrackerContext ctx) async {
    final client = _client;
    final anilistId = ctx.anime?.anilist;
    if (client == null || anilistId == null) return;

    // AniList auto-promotes CURRENT → COMPLETED when progress == total, so we
    // only need to send CURRENT for episodes. Movies are always a single-unit
    // completion.
    final progress = ctx.isMovie ? 1 : (ctx.episodeNumber ?? 0);
    final status = ctx.isMovie ? 'COMPLETED' : 'CURRENT';

    await client.saveMediaListEntry(mediaId: anilistId, progress: progress, status: status);
    appLogger.d('AniList: saved entry (anilist=$anilistId, progress=$progress, status=$status)');
  }
}
