import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';

/// Collect every episode of a show into [out] using the backend's one-shot
/// recursive-leaves call ([MediaServerClient.fetchPlayableDescendants] —
/// Plex's `/library/metadata/{id}/allLeaves`, Jellyfin's
/// `/Items?Recursive=true&IncludeItemTypes=Movie,Episode`). Avoids walking
/// show → seasons → episodes client-side, so large series come back in one
/// trip and aren't capped by any per-page Limit.
///
/// A failure of the underlying call propagates to the caller — both
/// [DownloadProvider.queueDownload] and the sync rule executor wrap their
/// invocations so the user-facing error surfaces / the rule run is rolled
/// back.
Future<void> collectEpisodesForShow(
  MediaServerClient client,
  String showRatingKey, {
  required bool unwatchedOnly,
  required List<MediaItem> out,
}) {
  return _collectPlayable(client, showRatingKey, unwatchedOnly: unwatchedOnly, out: out);
}

/// Collect every episode of a single season into [out] via the same
/// one-shot endpoint. On a season the leaves *are* the episodes, so the
/// shape matches the show case.
Future<void> collectEpisodesForSeason(
  MediaServerClient client,
  String seasonRatingKey, {
  required bool unwatchedOnly,
  required List<MediaItem> out,
}) {
  return _collectPlayable(client, seasonRatingKey, unwatchedOnly: unwatchedOnly, out: out);
}

Future<void> _collectPlayable(
  MediaServerClient client,
  String parentId, {
  required bool unwatchedOnly,
  required List<MediaItem> out,
}) async {
  final leaves = await client.fetchPlayableDescendants(parentId);
  for (final ep in leaves) {
    if (ep.kind != MediaKind.episode) continue;
    if (unwatchedOnly && ep.isWatched && !ep.hasActiveProgress) continue;
    out.add(ep);
  }
}
