import '../../media/episode_collection.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_server_client.dart';

/// Resolves a companion-remote `playMedia` request's [ratingKey] into an
/// exact, playable [MediaItem] the host can hand to `navigateToVideoPlayer`.
///
/// Movies and episodes resolve to themselves, refetched so resume state is
/// current. Shows resolve to their on-deck episode, falling back to the first
/// episode of the default playback season when the backend has none. Seasons
/// resolve at the show level, so a season behaves like the show's own Play
/// button. Returns `null` when the item can't be found or isn't a supported
/// kind.
Future<MediaItem?> resolveCompanionRemotePlaybackTarget(MediaServerClient client, String ratingKey) async {
  final withOnDeck = await client.fetchItemWithOnDeck(ratingKey);
  final fetched = withOnDeck.item;
  if (fetched == null) return null;

  switch (fetched.kind) {
    case MediaKind.movie:
    case MediaKind.episode:
      return fetched;
    case MediaKind.show:
      return withOnDeck.onDeckEpisode ?? await _firstEpisodeOfDefaultSeason(client, fetched);
    case MediaKind.season:
      final seriesId = fetched.grandparentId ?? fetched.parentId;
      if (seriesId == null) return null;
      return resolveCompanionRemotePlaybackTarget(client, seriesId);
    default:
      return null;
  }
}

Future<MediaItem?> _firstEpisodeOfDefaultSeason(MediaServerClient client, MediaItem show) async {
  final season = defaultPlaybackSeason(await client.fetchChildren(show.id));
  if (season == null) return null;
  return fetchFirstEpisodeForSeason(client, season.id, seriesId: show.id);
}
