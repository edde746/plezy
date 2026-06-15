import 'library_query.dart';
import 'media_item.dart';
import 'media_kind.dart';
import 'media_server_client.dart';

/// Collect every episode of a show into [out] using the backend's one-shot
/// recursive-leaves call ([MediaServerClient.fetchPlayableDescendants] —
/// Plex's `/library/metadata/{id}/allLeaves`, Jellyfin's
/// `/Items?Recursive=true&IncludeItemTypes=Movie,Episode`). Avoids walking
/// show → seasons → episodes client-side, so large series come back in one
/// trip and aren't capped by any per-page Limit.
///
/// A failure of the underlying call propagates to the caller — both
/// `DownloadProvider.queueDownload` and the sync rule executor wrap their
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

/// Fetch just the first episode of a season without walking the entire season.
/// Use this for representative lookups and immediate "play first" actions.
Future<MediaItem?> fetchFirstEpisodeForSeason(
  MediaServerClient client,
  String seasonRatingKey, {
  String? seriesId,
}) async {
  final seasonPagingClient = client is SeasonEpisodePagingClient ? client as SeasonEpisodePagingClient : null;
  final page = seriesId != null && seasonPagingClient != null
      ? await seasonPagingClient.fetchSeasonEpisodesPage(seriesId, seasonRatingKey, start: 0, size: 1)
      : await client.fetchChildrenPage(seasonRatingKey, start: 0, size: 1);
  for (final item in page.items) {
    if (item.kind == MediaKind.episode) return item;
  }
  return null;
}

/// Prefer the first regular season over specials, falling back to the first
/// season row when a show only has specials or lacks season indexes.
int defaultPlaybackSeasonIndex(List<MediaItem> seasons) {
  if (seasons.isEmpty) return 0;
  final regularSeasonIndex = seasons.indexWhere((season) => season.kind == MediaKind.season && (season.index ?? 0) > 0);
  if (regularSeasonIndex != -1) return regularSeasonIndex;
  final firstSeasonIndex = seasons.indexWhere((season) => season.kind == MediaKind.season);
  return firstSeasonIndex == -1 ? 0 : firstSeasonIndex;
}

MediaItem? defaultPlaybackSeason(List<MediaItem> seasons) {
  if (seasons.isEmpty) return null;
  final index = defaultPlaybackSeasonIndex(seasons);
  if (index < 0 || index >= seasons.length) return null;
  final season = seasons[index];
  return season.kind == MediaKind.season ? season : null;
}

/// Index of the first season that still has unwatched episodes, preferring
/// regular seasons over specials (mirrors [defaultPlaybackSeasonIndex]). Uses
/// leafCount/viewedLeafCount, so no episodes need to be fetched. Returns null
/// when every season is fully watched (or counts are unavailable).
int? firstUnwatchedSeasonIndex(List<MediaItem> seasons) {
  int? firstSpecial;
  for (var i = 0; i < seasons.length; i++) {
    final season = seasons[i];
    if (season.kind != MediaKind.season) continue;
    final leaf = season.leafCount;
    if (leaf == null || leaf <= 0) continue;
    if ((season.viewedLeafCount ?? 0) >= leaf) continue; // fully watched
    if ((season.index ?? 0) > 0) return i; // first regular season with unwatched
    firstSpecial ??= i; // specials only count as a last resort
  }
  return firstSpecial;
}

/// First episode that is unwatched or still in progress, in list order.
/// Same predicate as [_collectPlayable]'s `unwatchedOnly` filter, returned in
/// the order the episodes are displayed so the highlight matches the list.
MediaItem? firstUnwatchedEpisode(List<MediaItem> episodes) {
  for (final episode in episodes) {
    if (episode.kind != MediaKind.episode) continue;
    if (episode.isWatched && !episode.hasActiveProgress) continue;
    return episode;
  }
  return null;
}

/// Find the season index matching an explicit navigation target or on-deck
/// episode. With neither, fall back to the first season that still has
/// unwatched episodes (so a partially-watched show removed from Continue
/// Watching still opens on the right season), then [defaultPlaybackSeasonIndex].
int preferredSeasonIndex(
  List<MediaItem> seasons, {
  String? initialSeasonId,
  int? initialSeasonIndex,
  MediaItem? onDeckEpisode,
}) {
  if (seasons.isEmpty) return 0;
  if (initialSeasonId != null) {
    final idx = seasons.indexWhere((season) => season.kind == MediaKind.season && season.id == initialSeasonId);
    if (idx != -1) return idx;
  }

  if (initialSeasonIndex != null) {
    final idx = seasons.indexWhere((season) => season.kind == MediaKind.season && season.index == initialSeasonIndex);
    if (idx != -1) return idx;
  }

  if (onDeckEpisode != null) {
    final parentId = onDeckEpisode.parentId;
    if (parentId != null) {
      final idx = seasons.indexWhere((season) => season.kind == MediaKind.season && season.id == parentId);
      if (idx != -1) return idx;
    }

    final parentIndex = onDeckEpisode.parentIndex;
    if (parentIndex != null) {
      final idx = seasons.indexWhere((season) => season.kind == MediaKind.season && season.index == parentIndex);
      if (idx != -1) return idx;
    }
  }

  final unwatched = firstUnwatchedSeasonIndex(seasons);
  if (unwatched != null) return unwatched;

  return defaultPlaybackSeasonIndex(seasons);
}

/// Fetch a page of season episodes and normalize the episode identity fields
/// detail rows depend on. Local/session progress stays layered in UI.
Future<LibraryPage<MediaItem>> fetchSeasonEpisodePage(
  MediaServerClient client, {
  required MediaItem show,
  required MediaItem season,
  required int start,
  required int size,
}) async {
  final seasonPagingClient = client is SeasonEpisodePagingClient ? client as SeasonEpisodePagingClient : null;
  final page = seasonPagingClient != null
      ? await seasonPagingClient.fetchSeasonEpisodesPage(show.id, season.id, start: start, size: size)
      : await client.fetchChildrenPage(season.id, start: start, size: size);
  return LibraryPage<MediaItem>(
    items: normalizeSeasonEpisodes(page.items, show: show, season: season),
    totalCount: page.totalCount,
    offset: page.offset,
  );
}

List<MediaItem> normalizeSeasonEpisodes(
  List<MediaItem> episodes, {
  required MediaItem show,
  required MediaItem season,
}) {
  return episodes
      .where((episode) => episode.kind == MediaKind.episode)
      .map(
        (episode) => _withFallbackLibrary(
          episode.copyWith(
            serverId: show.serverId ?? episode.serverId,
            serverName: show.serverName ?? episode.serverName,
            grandparentId: show.id,
            grandparentTitle: show.title ?? episode.grandparentTitle,
            parentId: episode.parentId ?? season.id,
            parentIndex: episode.parentIndex ?? season.index,
          ),
          season.libraryId != null ? season : show,
        ),
      )
      .toList();
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
