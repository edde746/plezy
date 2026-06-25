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

/// A season number of 0 (or missing) denotes the Specials folder. Season
/// selection treats it as a last resort for "what to watch next" — see
/// [defaultPlaybackSeasonIndex] and [firstUnwatchedSeasonIndex], which open on
/// the first regular season. Episode ordering ([compareEpisodesByWatchOrder])
/// instead places Specials by air date, only falling back to Specials-last when
/// an episode has no air date.
bool isSpecialSeasonNumber(int? seasonNumber) => (seasonNumber ?? 0) == 0;

/// Prefer the first regular season over specials, falling back to the first
/// season row when a show only has specials or lacks season indexes.
int defaultPlaybackSeasonIndex(List<MediaItem> seasons) {
  if (seasons.isEmpty) return 0;
  final regularSeasonIndex = seasons.indexWhere(
    (season) => season.kind == MediaKind.season && !isSpecialSeasonNumber(season.index),
  );
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
    if (!isSpecialSeasonNumber(season.index)) return i; // first regular season with unwatched
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
    if (!episode.isUnwatchedOrInProgress) continue;
    return episode;
  }
  return null;
}

/// Orders episodes into the **aired watch order** — the sequence they're meant
/// to be played in: primarily by air date ([MediaItem.originallyAvailableAt]),
/// so a Special that aired between two regular episodes is played between them,
/// the way Plex's own play queue and clients do (#1416). This is the single
/// shared definition of episode order, used by the offline next/prev queue, the
/// Jellyfin online queue, the offline OnDeck list, and the count-capped
/// "download / sync next N" selection — keeping streaming, offline, and
/// download order consistent across both backends.
///
/// Episodes without a usable air date sort *after* dated ones, falling back to
/// season → episode order with Specials last. So undated Specials never wedge
/// into the middle of the aired run, and a "next N" cut still leads with regular
/// episodes — preserving the #1414 guarantee that the whole Specials folder is
/// never front-loaded. The trailing id comparison keeps ties deterministic
/// (Dart's [List.sort] is not stable) so the "next N" cut is stable across runs.
int compareEpisodesByWatchOrder(MediaItem a, MediaItem b) {
  final aDate = _airDateKey(a);
  final bDate = _airDateKey(b);
  if (aDate != null && bDate != null) {
    final byDate = aDate.compareTo(bDate);
    if (byDate != 0) return byDate;
  } else if (aDate == null && bDate != null) {
    return 1; // undated episodes sort after dated ones
  } else if (aDate != null && bDate == null) {
    return -1;
  }
  // Same air date, or both undated: regular seasons before Specials, then by
  // season number, episode number, and id.
  final aSpecial = isSpecialSeasonNumber(a.parentIndex);
  final bSpecial = isSpecialSeasonNumber(b.parentIndex);
  if (aSpecial != bSpecial) return aSpecial ? 1 : -1;
  final season = (a.parentIndex ?? 0).compareTo(b.parentIndex ?? 0);
  if (season != 0) return season;
  final episode = (a.index ?? 0).compareTo(b.index ?? 0);
  if (episode != 0) return episode;
  return a.id.compareTo(b.id);
}

/// Air date used to order episodes in [compareEpisodesByWatchOrder], or null
/// when absent. Both backends normalize [MediaItem.originallyAvailableAt] to
/// `YYYY-MM-DD` (Plex natively, Jellyfin from `PremiereDate`), so a plain
/// lexicographic comparison is chronological.
String? _airDateKey(MediaItem episode) {
  final date = episode.originallyAvailableAt;
  return (date == null || date.isEmpty) ? null : date;
}

/// In-place sort by [compareEpisodesByWatchOrder]. See that function for the
/// ordering rationale.
void sortEpisodesByWatchOrder(List<MediaItem> episodes) => episodes.sort(compareEpisodesByWatchOrder);

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
  // Collect into a local list and order it before handing back: the backend
  // returns episodes in raw container order (Plex /grandchildren puts S00
  // first). Sorting into aired watch order means order-capped callers ("next N
  // unwatched" download, sync-rule deficit) slice the next episodes in the order
  // they're meant to be watched — Specials interleaved by air date, never the
  // whole Specials folder front-loaded (#1414). Sort the per-call slice, not the
  // shared `out` accumulator, so multi-container callers don't interleave across
  // shows.
  final collected = <MediaItem>[];
  for (final ep in leaves) {
    if (ep.kind != MediaKind.episode) continue;
    if (unwatchedOnly && !ep.isUnwatchedOrInProgress) continue;
    collected.add(_withFallbackLibrary(ep, fallback));
  }
  sortEpisodesByWatchOrder(collected);
  out.addAll(collected);
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
