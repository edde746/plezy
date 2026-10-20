import '../utils/app_logger.dart';
import '../utils/external_ids.dart';
import '../utils/media_server_http_client.dart';
import 'media_item.dart';
import 'media_kind.dart';
import 'media_server_client.dart';

/// A movie or an episode to find in the user's libraries by catalogue
/// identity, as another app describes it. An episode is found through its
/// show (by the show's IDs, else its title) and its season and episode numbers.
class TitleQuery {
  const TitleQuery.movie({required this.title, this.year, this.ids = const ExternalIds(), this.plexGuid})
    : kind = MediaKind.movie,
      showTitle = null,
      showYear = null,
      showIds = const ExternalIds(),
      showPlexGuid = null,
      season = null,
      episode = null;

  const TitleQuery.episode({
    required String this.showTitle,
    this.showYear,
    this.showIds = const ExternalIds(),
    this.showPlexGuid,
    required int this.season,
    required int this.episode,
    this.ids = const ExternalIds(),
    this.title = '',
  }) : kind = MediaKind.episode,
       year = null,
       plexGuid = null;

  final MediaKind kind;

  /// The movie's title, or the episode's own (unused for lookups).
  final String title;
  final int? year;

  /// The movie's IDs, or the episode's own.
  final ExternalIds ids;
  final String? plexGuid;
  final String? showTitle;
  final int? showYear;
  final ExternalIds showIds;
  final String? showPlexGuid;
  final int? season;
  final int? episode;
}

/// The most title-search hits checked against the query's IDs when no item
/// matched by ID.
const int _titleFallbackLimit = 5;

extension TitleCopiesLookup on MediaServerClient {
  /// Every copy of [query] on this server, each with its versions.
  ///
  /// Movies and shows come from [findByExternalIds]. Only when that finds
  /// nothing does a title search run: same folded title, a year at most one
  /// apart, and no catalogue ID that contradicts the query's. An episode is
  /// then the show's episode with the query's season and episode numbers,
  /// dropped when its own IDs contradict the query's. Failures throw, so the
  /// caller can tell "not on this server" from "couldn't ask".
  Future<List<MediaItem>> findTitleCopies(TitleQuery query, {AbortController? abort}) async {
    final List<MediaItem> found;
    if (query.kind == MediaKind.movie) {
      found = await _titleItems(
        kind: MediaKind.movie,
        title: query.title,
        year: query.year,
        ids: query.ids,
        plexGuid: query.plexGuid,
        abort: abort,
      );
    } else {
      final shows = await _titleItems(
        kind: MediaKind.show,
        title: query.showTitle ?? '',
        year: query.showYear,
        ids: query.showIds,
        plexGuid: query.showPlexGuid,
        abort: abort,
      );
      final episodes = <MediaItem>[];
      for (final show in shows) {
        abort?.throwIfAborted();
        episodes.addAll(await _episodesOf(show, season: query.season!, episode: query.episode!, abort: abort));
      }
      found = query.ids.hasAny ? await _withoutContradictions(episodes, query.ids, abort: abort) : episodes;
    }
    return _withVersions(found, abort: abort);
  }

  Future<List<MediaItem>> _titleItems({
    required MediaKind kind,
    required String title,
    required int? year,
    required ExternalIds ids,
    required String? plexGuid,
    AbortController? abort,
  }) async {
    final titles = [if (title.trim().isNotEmpty) title.trim()];
    if (ids.hasAny || plexGuid != null) {
      final byId = await findByExternalIds(ids, kind: kind, titles: titles, year: year, plexGuid: plexGuid);
      abort?.throwIfAborted();
      if (byId != null && byId.isNotEmpty) return byId;
    }
    if (titles.isEmpty) return const [];
    final hits = await searchItems(titles.single, limit: 50, abort: abort);
    abort?.throwIfAborted();
    final folded = foldTitle(titles.single);
    final sameTitle = [
      for (final hit in hits)
        if (hit.kind == kind && foldTitle(hit.title ?? '') == folded && _yearsAgree(year, hit.year)) hit,
    ];
    if (!ids.hasAny) return sameTitle;
    return _withoutContradictions(sameTitle.take(_titleFallbackLimit).toList(), ids, abort: abort);
  }

  /// [items] minus those whose catalogue IDs name another title than [ids].
  /// An item whose IDs can't be read stays: nothing contradicts it.
  Future<List<MediaItem>> _withoutContradictions(
    List<MediaItem> items,
    ExternalIds ids, {
    AbortController? abort,
  }) async {
    final kept = <MediaItem>[];
    for (final item in items) {
      abort?.throwIfAborted();
      ExternalIds own;
      try {
        own = await fetchExternalIds(item.id);
      } catch (error, stackTrace) {
        if (abort?.isAborted ?? false) rethrow;
        appLogger.w('Could not read external IDs of ${item.id}', error: error, stackTrace: stackTrace);
        own = const ExternalIds();
      }
      if (!contradicts(own, ids)) kept.add(item);
    }
    return kept;
  }

  /// The episodes of [show] numbered [season]x[episode]. A Plex show whose
  /// seasons are hidden lists its episodes directly.
  Future<List<MediaItem>> _episodesOf(
    MediaItem show, {
    required int season,
    required int episode,
    AbortController? abort,
  }) async {
    bool isTarget(MediaItem item) =>
        item.kind == MediaKind.episode && item.index == episode && (item.parentIndex ?? season) == season;
    final children = await fetchChildren(show.id);
    abort?.throwIfAborted();
    final matches = [
      for (final child in children)
        if (isTarget(child)) child,
    ];
    for (final seasonItem in children) {
      if (seasonItem.kind != MediaKind.season || seasonItem.index != season) continue;
      final episodes = await _seasonEpisodes(show, seasonItem);
      abort?.throwIfAborted();
      matches.addAll(episodes.where(isTarget));
    }
    return matches;
  }

  Future<List<MediaItem>> _seasonEpisodes(MediaItem show, MediaItem season) async {
    final Object client = this;
    if (client is! SeasonEpisodePagingClient) return fetchChildren(season.id);
    const pageSize = 200;
    final items = <MediaItem>[];
    while (true) {
      final page = await client.fetchSeasonEpisodesPage(show.id, season.id, start: items.length, size: pageSize);
      items.addAll(page.items);
      if (page.items.length < pageSize || items.length >= page.totalCount) return items;
    }
  }

  /// [items] with their versions: rows that came without them are fetched.
  Future<List<MediaItem>> _withVersions(List<MediaItem> items, {AbortController? abort}) async {
    final result = <MediaItem>[];
    for (final item in items) {
      if (item.mediaVersions?.isNotEmpty ?? false) {
        result.add(item);
        continue;
      }
      abort?.throwIfAborted();
      try {
        result.add(await fetchItem(item.id) ?? item);
      } catch (error, stackTrace) {
        // The row itself still names the copy; its length may be on the row.
        appLogger.w('Could not read versions of ${item.id}', error: error, stackTrace: stackTrace);
        result.add(item);
      }
    }
    return result;
  }
}

bool _yearsAgree(int? wanted, int? found) => wanted == null || found == null || (wanted - found).abs() <= 1;

/// [title] lower-cased with everything but letters and digits removed, so
/// punctuation, articles' spacing and case don't tell two titles apart.
String foldTitle(String title) => title.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), '');

/// Whether some catalogue holds different IDs in [a] and [b] (SDK.md §9.3):
/// then they name different titles whatever else they share.
bool contradicts(ExternalIds a, ExternalIds b) =>
    (a.imdb != null && b.imdb != null && a.imdb != b.imdb) ||
    (a.tmdb != null && b.tmdb != null && a.tmdb != b.tmdb) ||
    (a.tvdb != null && b.tvdb != null && a.tvdb != b.tvdb) ||
    (a.anidb != null && b.anidb != null && a.anidb != b.anidb);
