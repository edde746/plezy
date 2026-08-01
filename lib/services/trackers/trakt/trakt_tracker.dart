import 'package:http/http.dart' as http;

import '../../../media/media_kind.dart';
import '../../../models/trackers/tracker_context.dart';
import '../../../models/trakt/trakt_ids.dart';
import '../../../models/trakt/trakt_scrobble_request.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/json_utils.dart';
import '../../settings_service.dart';
import '../tracker.dart';
import '../tracker_constants.dart';
import '../tracker_id_resolver.dart';
import '../tracker_rating_match.dart';
import '../tracker_session.dart';
import '../tracker_write_queue.dart';
import 'trakt_client.dart';

/// Trakt tracker.
///
/// In-player playback is reported in real time through `POST /scrobble/start`,
/// `/pause` and `/stop`; Trakt's own rule then decides watched state — a `stop`
/// at or above 80% progress records a play, below that it stores a resumable
/// position. `POST /sync/history` covers the marks that never pass through the
/// player: manual, container, offline replay, external players, and watch state
/// Plezy observes changing on the server.
///
/// Unlike the other services Trakt splits its user settings in two: the
/// scrobble toggle gates real-time reports ([canReportPlayback]) and a separate
/// watched-sync toggle gates history writes ([canWriteWatched]).
class TraktTracker extends TrackerBase
    with ClientBackedTracker<TraktClient>
    implements TrackerRatingSource, RealtimeScrobbleTracker, EpisodeHistoryTracker {
  static TraktTracker? _instance;
  static TraktTracker get instance => _instance ??= TraktTracker._();
  TraktTracker._();

  @override
  String get name => 'trakt';

  @override
  TrackerService get service => TrackerService.trakt;

  @override
  bool get needsFribb => false;

  /// Trakt counts a `/scrobble/stop` as a watch from this progress upwards.
  static const double _scrobbleWatchedPercent = 80.0;

  /// The bound client is replaced on every session rebind, so its identity is
  /// the account identity.
  @override
  Object? get scrobbleBinding => client;

  @override
  bool get canReportPlayback => isEnabledWithSession;

  bool _watchedSyncEnabled = false;

  @override
  bool get canWriteWatched => _watchedSyncEnabled && hasActiveClient;

  @override
  ScrobblePolicy get scrobblePolicy => const ScrobblePolicy(
    // Trakt allows one scrobble per item per 15 minutes and 409s the rest, so a
    // re-sent `start` waits out this window instead of collecting conflicts.
    resendThrottle: Duration(seconds: 30),
    // A slider drag emits many position updates; only one checkpoint per window
    // reaches Trakt.
    seekThrottle: Duration(seconds: 5),
  );

  @override
  Future<void> initialize() async {
    await super.initialize();
    final settings = await SettingsService.getInstance();
    _watchedSyncEnabled = settings.read(SettingsService.enableTraktWatchedSync);
  }

  /// Paired with the watched-sync settings toggle, mirroring [setEnabled] for
  /// the scrobble toggle.
  Future<void> setWatchedSyncEnabled(bool enabled) async {
    _watchedSyncEnabled = enabled;
  }

  void rebindSession(
    TrackerSession? session, {
    required void Function() onSessionInvalidated,
    void Function(TrackerSession session)? onSessionUpdated,
    http.Client? httpClient,
  }) {
    rebindTrackerClient(
      session,
      createClient: (session) => TraktClient(
        session,
        onSessionInvalidated: onSessionInvalidated,
        onSessionUpdated: onSessionUpdated,
        httpClient: httpClient,
      ),
    );
  }

  /// Trakt matches on the media server's own external ids and nothing else — the
  /// anime mappings other trackers use never reach its requests.
  @override
  String? historyRowIdentity(TrackerContext ctx) => trackerExternalRowIdentity(ctx.external);

  /// Push a rotated token pair into the live client instead of rebuilding it —
  /// a second client would race the next refresh.
  void updateSession(TrackerSession session) => client?.updateSession(session);

  @override
  Future<void> markWatched(TrackerContext ctx, {DateTime? watchedAt}) async {
    final client = this.client;
    if (client == null || !canWriteWatched) return;
    final body = _requestFor(ctx);
    if (body == null) return;

    await client.addToHistory(body, watchedAt: watchedAt?.toUtc().toIso8601String());
    appLogger.d('Trakt: marked watched (${ctx.ratingKey}, isMovie=${ctx.isMovie})');
  }

  @override
  Future<void> markUnwatched(TrackerContext ctx) async {
    final client = this.client;
    if (client == null || !canWriteWatched) return;
    final body = _requestFor(ctx);
    if (body == null) return;

    await client.removeFromHistory(body);
    appLogger.d('Trakt: marked unwatched (${ctx.ratingKey}, isMovie=${ctx.isMovie})');
  }

  @override
  Future<void> scrobble(TrackerContext ctx, TrackerScrobbleState state, double progressPercent) async {
    final client = this.client;
    if (client == null) return;
    final body = _requestFor(ctx)?.copyWith(progress: progressPercent);
    if (body == null) return;

    switch (state) {
      case TrackerScrobbleState.start:
        await client.scrobbleStart(body);
      case TrackerScrobbleState.pause:
        await client.scrobblePause(body);
      case TrackerScrobbleState.seek:
        // Trakt has no seek event. Official clients checkpoint with pause+start
        // at the new position; without it "resume on another device" stays stuck
        // on the pre-seek position until the next pause or stop.
        await client.scrobblePause(body);
        await client.scrobbleStart(body);
      case TrackerScrobbleState.stop:
        await client.scrobbleStop(body);
    }
    appLogger.d('Trakt: scrobble ${state.name} @ ${progressPercent.toStringAsFixed(1)}%');
  }

  @override
  Future<void> reconcileWatchedAfterStop(TrackerContext ctx, double progressPercent) async {
    // At or above Trakt's own rule the stop already recorded the play; a history
    // write would record a second one.
    if (progressPercent >= _scrobbleWatchedPercent) return;
    appLogger.d('Trakt: stop below ${_scrobbleWatchedPercent.toStringAsFixed(0)}% — recording watch explicitly');
    await markWatched(ctx);
  }

  /// Trakt matches an episode through the show's ids plus the aired
  /// season/episode index — that shape works even when the episode itself is not
  /// in its catalog yet. Null when the item carries no usable ids.
  TraktScrobbleRequest? _requestFor(TrackerContext ctx) {
    final ids = TraktIds.fromExternal(ctx.external);
    if (!ids.hasAny) return null;
    if (ctx.isMovie) return TraktScrobbleRequest.movie(ids: ids);

    final season = ctx.season;
    final number = ctx.episodeNumber;
    if (season == null || number == null) return null;
    return TraktScrobbleRequest.episode(showIds: ids, season: season, number: number);
  }

  @override
  Future<int?> getRating(TrackerRatingContext ctx) async {
    final client = this.client;
    if (client == null) throw const TrackerRatingUnavailableException('Trakt');
    final localIds = TraktIds.fromExternal(ctx.ids.external).toJson();
    if (localIds.isEmpty) throw const TrackerRatingUnavailableException('Trakt');

    final entries = await client.getRatings(_ratingType(ctx));
    for (final entry in entries) {
      if (entry is! Map) continue;
      if (!_ratingEntryMatches(ctx, entry.cast<String, dynamic>(), localIds)) continue;
      final rating = flexibleInt(entry['rating']);
      return rating != null && rating > 0 ? rating.clamp(1, 10).toInt() : null;
    }
    return null;
  }

  @override
  Future<void> rate(TrackerRatingContext ctx, int score) async {
    final client = this.client;
    if (client == null) throw const TrackerRatingUnavailableException('Trakt');
    await client.addRatings(_ratingBody(ctx, rating: score.clamp(1, 10).toInt()));
  }

  @override
  Future<void> clearRating(TrackerRatingContext ctx) async {
    final client = this.client;
    if (client == null) throw const TrackerRatingUnavailableException('Trakt');
    await client.removeRatings(_ratingBody(ctx));
  }

  String _ratingType(TrackerRatingContext ctx) => switch (ctx.kind) {
    MediaKind.movie => 'movies',
    MediaKind.show => 'shows',
    MediaKind.season => 'seasons',
    MediaKind.episode => 'episodes',
    _ => throw const TrackerRatingUnavailableException('Trakt'),
  };

  bool _ratingEntryMatches(TrackerRatingContext ctx, Map<String, dynamic> entry, Map<String, dynamic> localIds) {
    final show = entry['show'];
    final movie = entry['movie'];
    return switch (ctx.kind) {
      MediaKind.movie => trackerIdsMatch(trackerNestedIds(movie), localIds),
      MediaKind.show => trackerIdsMatch(trackerNestedIds(show), localIds),
      MediaKind.season =>
        trackerIdsMatch(trackerNestedIds(show), localIds) && _numberMatches(entry['season'], ctx.season),
      MediaKind.episode =>
        trackerIdsMatch(trackerNestedIds(show), localIds) &&
            _numberMatches(entry['episode'], ctx.episodeNumber) &&
            _seasonMatches(entry['episode'], ctx.season),
      _ => false,
    };
  }

  bool _numberMatches(Object? value, int? expected) {
    if (expected == null || value is! Map) return false;
    return flexibleInt(value['number']) == expected;
  }

  bool _seasonMatches(Object? value, int? expected) {
    if (expected == null || value is! Map) return false;
    return flexibleInt(value['season']) == expected;
  }

  Map<String, dynamic> _ratingBody(TrackerRatingContext ctx, {int? rating}) {
    final ids = TraktIds.fromExternal(ctx.ids.external).toJson();
    final item = {'ids': ids, 'rating': ?rating};

    return switch (ctx.kind) {
      MediaKind.movie => {
        'movies': [item],
      },
      MediaKind.show => {
        'shows': [item],
      },
      MediaKind.season => {
        'shows': [
          {
            'ids': ids,
            'seasons': [
              {'number': ctx.season, 'rating': ?rating},
            ],
          },
        ],
      },
      MediaKind.episode => {
        'shows': [
          {
            'ids': ids,
            'seasons': [
              {
                'number': ctx.season,
                'episodes': [
                  {'number': ctx.episodeNumber, 'rating': ?rating},
                ],
              },
            ],
          },
        ],
      },
      _ => throw const TrackerRatingUnavailableException('Trakt'),
    };
  }
}
