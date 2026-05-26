import '../trakt/trakt_scrobble_service.dart';
import 'anilist/anilist_tracker.dart';
import 'mal/mal_tracker.dart';
import 'simkl/simkl_tracker.dart';
import 'tracker_constants.dart';
import 'tracker_id_resolver.dart' show TrackerRatingContext;

/// Generic rating dispatcher. UI widgets call into this service instead of
/// importing concrete tracker classes, so adding (or replacing) a tracker
/// requires no widget-level changes.
///
/// This file is the only allowlisted import of concrete tracker classes from
/// outside their own subfolder — see CLAUDE.md's "Tracker import hygiene"
/// section.
class TrackerRatingService {
  static final TrackerRatingService instance = TrackerRatingService._();
  TrackerRatingService._();

  Future<int?> getRating(TrackerService service, TrackerRatingContext ctx) {
    switch (service) {
      case TrackerService.trakt:
        return TraktScrobbleService.instance.getRating(ctx);
      case TrackerService.mal:
        return MalTracker.instance.getRating(ctx);
      case TrackerService.anilist:
        return AnilistTracker.instance.getRating(ctx);
      case TrackerService.simkl:
        return SimklTracker.instance.getRating(ctx);
    }
  }

  Future<void> rate(TrackerService service, TrackerRatingContext ctx, int score) {
    switch (service) {
      case TrackerService.trakt:
        return TraktScrobbleService.instance.rate(ctx, score);
      case TrackerService.mal:
        return MalTracker.instance.rate(ctx, score);
      case TrackerService.anilist:
        return AnilistTracker.instance.rate(ctx, score);
      case TrackerService.simkl:
        return SimklTracker.instance.rate(ctx, score);
    }
  }

  Future<void> clearRating(TrackerService service, TrackerRatingContext ctx) {
    switch (service) {
      case TrackerService.trakt:
        return TraktScrobbleService.instance.clearRating(ctx);
      case TrackerService.mal:
        return MalTracker.instance.clearRating(ctx);
      case TrackerService.anilist:
        return AnilistTracker.instance.clearRating(ctx);
      case TrackerService.simkl:
        return SimklTracker.instance.clearRating(ctx);
    }
  }
}
