import 'dart:math';

import '../media/media_item.dart';
import '../media/media_kind.dart';
import '../media/media_server_client.dart';

/// Airing-order comparator: season number, then episode number. Missing
/// indices sort first (treated as 0). Used to restore a randomly-picked subset
/// to a natural order before queueing.
int episodeAiringOrder(MediaItem a, MediaItem b) {
  final seasonCompare = (a.parentIndex ?? 0).compareTo(b.parentIndex ?? 0);
  if (seasonCompare != 0) return seasonCompare;
  return (a.index ?? 0).compareTo(b.index ?? 0);
}

/// Choose which of the collected [episodes] to queue.
///
/// By default returns [episodes] unchanged (the caller applies [maxCount] while
/// queueing, taking them in airing order). When [random] is set alongside a
/// [maxCount] smaller than the pool, picks [maxCount] episodes uniformly at
/// random and then restores airing order so the queue and offline library
/// still read naturally. Without a cap there is no subset to randomise.
///
/// [rng] is injectable so tests can pin the selection.
List<MediaItem> selectEpisodesForDownload(List<MediaItem> episodes, {int? maxCount, bool random = false, Random? rng}) {
  if (!random || maxCount == null || maxCount >= episodes.length) return episodes;
  final shuffled = [...episodes]..shuffle(rng);
  return shuffled.take(maxCount).toList()..sort(episodeAiringOrder);
}

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
  MediaItem? fallback,
}) {
  return _collectPlayable(client, showRatingKey, unwatchedOnly: unwatchedOnly, out: out, fallback: fallback);
}

/// Collect every episode of a single season into [out] via the same
/// one-shot endpoint. On a season the leaves *are* the episodes, so the
/// shape matches the show case.
Future<void> collectEpisodesForSeason(
  MediaServerClient client,
  String seasonRatingKey, {
  required bool unwatchedOnly,
  required List<MediaItem> out,
  MediaItem? fallback,
}) {
  return _collectPlayable(client, seasonRatingKey, unwatchedOnly: unwatchedOnly, out: out, fallback: fallback);
}

Future<void> _collectPlayable(
  MediaServerClient client,
  String parentId, {
  required bool unwatchedOnly,
  required List<MediaItem> out,
  MediaItem? fallback,
}) async {
  final leaves = await client.fetchPlayableDescendants(parentId);
  for (final ep in leaves) {
    if (ep.kind != MediaKind.episode) continue;
    if (unwatchedOnly && ep.isWatched && !ep.hasActiveProgress) continue;
    out.add(_withFallbackLibrary(ep, fallback));
  }
}

MediaItem _withFallbackLibrary(MediaItem item, MediaItem? fallback) {
  if (fallback == null) return item;
  final fallbackIsSeason = fallback.kind == MediaKind.season;
  final fallbackIsShow = fallback.kind == MediaKind.show;
  return item.copyWith(
    serverId: item.serverId ?? fallback.serverId,
    serverName: item.serverName ?? fallback.serverName,
    libraryId: item.libraryId ?? fallback.libraryId,
    libraryTitle: item.libraryTitle ?? fallback.libraryTitle,
    parentId: item.parentId ?? (fallbackIsSeason ? fallback.id : null),
    parentTitle: item.parentTitle ?? (fallbackIsSeason ? fallback.title : null),
    grandparentId: item.grandparentId ?? _fallbackGrandparentId(fallback, isShow: fallbackIsShow),
    grandparentTitle: item.grandparentTitle ?? _fallbackGrandparentTitle(fallback, isShow: fallbackIsShow),
  );
}

String? _fallbackGrandparentId(MediaItem fallback, {required bool isShow}) {
  if (isShow) return fallback.id;
  return fallback.grandparentId ?? fallback.parentId;
}

String? _fallbackGrandparentTitle(MediaItem fallback, {required bool isShow}) {
  if (isShow) return fallback.title;
  return fallback.grandparentTitle ?? fallback.parentTitle;
}
