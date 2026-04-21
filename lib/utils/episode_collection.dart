import '../models/plex_metadata.dart';
import '../services/plex_client.dart';
import '../utils/app_logger.dart';
import '../utils/content_utils.dart';

/// Walk the children of a show and collect every episode into [out].
///
/// - Per-season fetch failures are logged and skipped (one bad season doesn't
///   discard progress from the others).
/// - A failure to fetch the show's own children is logged and leaves [out]
///   empty.
/// - [unwatchedOnly] skips episodes that are watched and have no active
///   progress.
Future<void> collectEpisodesForShow(
  PlexClient client,
  String showRatingKey, {
  required bool unwatchedOnly,
  required List<PlexMetadata> out,
}) async {
  final List<PlexMetadata> seasons;
  try {
    seasons = await client.getChildren(showRatingKey);
  } catch (e) {
    appLogger.w('Episode collection: show $showRatingKey getChildren failed, skipping', error: e);
    return;
  }
  for (final season in seasons) {
    if (season.type != ContentTypes.season) continue;
    try {
      await collectEpisodesForSeason(client, season.ratingKey, unwatchedOnly: unwatchedOnly, out: out);
    } catch (e) {
      appLogger.w('Episode collection: season ${season.ratingKey} fetch failed, skipping', error: e);
    }
  }
}

/// Fetch the episodes of a season and append the ones passing [unwatchedOnly]
/// to [out]. Throws if the underlying `getChildren` fails — callers that want
/// per-season resilience should wrap in try/catch (see [collectEpisodesForShow]).
Future<void> collectEpisodesForSeason(
  PlexClient client,
  String seasonRatingKey, {
  required bool unwatchedOnly,
  required List<PlexMetadata> out,
}) async {
  final episodes = await client.getChildren(seasonRatingKey);
  for (final ep in episodes) {
    if (ep.type != ContentTypes.episode) continue;
    if (unwatchedOnly && ep.isWatched && !ep.hasActiveProgress) continue;
    out.add(ep);
  }
}
