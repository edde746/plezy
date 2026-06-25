import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/library_query.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/media_version.dart';
import 'package:plezy/utils/download_version_utils.dart';
import 'package:plezy/media/episode_collection.dart';

MediaItem _season(String id, {int index = 1, int? leafCount, int? viewedLeafCount}) => MediaItem(
  id: id,
  backend: MediaBackend.plex,
  kind: MediaKind.season,
  title: 'Season $index',
  index: index,
  leafCount: leafCount,
  viewedLeafCount: viewedLeafCount,
);

MediaItem _episode(
  String id, {
  List<MediaVersion>? versions,
  String? parentId,
  int? parentIndex,
  int? index,
  String? grandparentId,
  int? viewCount,
  int? viewOffsetMs,
  int? durationMs,
}) => MediaItem(
  id: id,
  backend: MediaBackend.plex,
  kind: MediaKind.episode,
  title: 'Episode',
  mediaVersions: versions,
  parentId: parentId,
  parentIndex: parentIndex,
  index: index,
  grandparentId: grandparentId,
  viewCount: viewCount,
  viewOffsetMs: viewOffsetMs,
  durationMs: durationMs,
);

MediaItem _clip(String id) => MediaItem(id: id, backend: MediaBackend.plex, kind: MediaKind.clip, title: 'Clip');

class _RecordingClient implements MediaServerClient {
  _RecordingClient({this.childrenByParent = const {}, this.childrenPageByParent = const {}, this.itemsById = const {}});

  final Map<String, List<MediaItem>> childrenByParent;
  final Map<String, List<MediaItem>> childrenPageByParent;
  final Map<String, MediaItem> itemsById;
  final childrenCalls = <String>[];
  final childrenPageCalls = <({String parentId, int? start, int? size})>[];

  @override
  Future<List<MediaItem>> fetchChildren(String parentId) async {
    childrenCalls.add(parentId);
    return childrenByParent[parentId] ?? const [];
  }

  @override
  Future<LibraryPage<MediaItem>> fetchChildrenPage(String parentId, {int? start, int? size, abort}) async {
    childrenPageCalls.add((parentId: parentId, start: start, size: size));
    final all = childrenPageByParent[parentId] ?? const <MediaItem>[];
    final offset = start ?? 0;
    final limit = size ?? all.length;
    final end = (offset + limit).clamp(0, all.length).toInt();
    final items = offset >= all.length ? const <MediaItem>[] : all.sublist(offset, end);
    return LibraryPage(items: items, totalCount: all.length, offset: offset);
  }

  @override
  Future<MediaItem?> fetchItem(String id) async => itemsById[id];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SeasonPagingRecordingClient extends _RecordingClient implements SeasonEpisodePagingClient {
  _SeasonPagingRecordingClient({this.seasonPageBySeason = const {}});

  final Map<({String seriesId, String seasonId}), List<MediaItem>> seasonPageBySeason;
  final seasonEpisodePageCalls = <({String seriesId, String seasonId, int? start, int? size})>[];

  @override
  Future<LibraryPage<MediaItem>> fetchSeasonEpisodesPage(
    String seriesId,
    String seasonId, {
    int? start,
    int? size,
    abort,
  }) async {
    seasonEpisodePageCalls.add((seriesId: seriesId, seasonId: seasonId, start: start, size: size));
    final all = seasonPageBySeason[(seriesId: seriesId, seasonId: seasonId)] ?? const <MediaItem>[];
    final offset = start ?? 0;
    final limit = size ?? all.length;
    final end = (offset + limit).clamp(0, all.length).toInt();
    final items = offset >= all.length ? const <MediaItem>[] : all.sublist(offset, end);
    return LibraryPage(items: items, totalCount: all.length, offset: offset);
  }
}

void main() {
  test('defaultPlaybackSeason skips specials when a regular season exists', () {
    final special = _season('specials', index: 0);
    final season1 = _season('season-1');
    final episodeRow = _episode('episode-row', parentIndex: 99);

    expect(defaultPlaybackSeason([special, season1]), same(season1));
    expect(defaultPlaybackSeasonIndex([special, season1]), 1);
    expect(preferredSeasonIndex([episodeRow, special, season1], initialSeasonIndex: 99), 2);
  });

  test('preferredSeasonIndex honors explicit and on-deck season choices', () {
    final special = _season('specials', index: 0);
    final season1 = _season('season-1');
    final season2 = _season('season-2', index: 2);

    expect(preferredSeasonIndex([special, season1, season2], initialSeasonId: season2.id, initialSeasonIndex: 1), 2);
    expect(preferredSeasonIndex([special, season1, season2], initialSeasonIndex: 2), 2);
    expect(
      preferredSeasonIndex([special, season1, season2], onDeckEpisode: _episode('episode-2', parentId: season2.id)),
      2,
    );
    expect(preferredSeasonIndex([special, season1, season2], onDeckEpisode: _episode('episode-1', parentIndex: 1)), 1);
  });

  test('firstUnwatchedSeasonIndex prefers the first regular season with unwatched episodes', () {
    final special = _season('specials', index: 0, leafCount: 3, viewedLeafCount: 0);
    final season1 = _season('season-1', index: 1, leafCount: 5, viewedLeafCount: 5); // fully watched
    final season2 = _season('season-2', index: 2, leafCount: 5, viewedLeafCount: 2); // partially watched
    final season3 = _season('season-3', index: 3, leafCount: 5, viewedLeafCount: 0);

    expect(firstUnwatchedSeasonIndex([special, season1, season2, season3]), 2);
  });

  test('firstUnwatchedSeasonIndex falls back to specials only when no regular season qualifies', () {
    final special = _season('specials', index: 0, leafCount: 3, viewedLeafCount: 1);
    final season1 = _season('season-1', index: 1, leafCount: 4, viewedLeafCount: 4);

    expect(firstUnwatchedSeasonIndex([special, season1]), 0);
  });

  test('firstUnwatchedSeasonIndex returns null when fully watched or counts are missing', () {
    final season1 = _season('season-1', index: 1, leafCount: 4, viewedLeafCount: 4);
    final season2 = _season('season-2', index: 2, leafCount: 6, viewedLeafCount: 6);
    expect(firstUnwatchedSeasonIndex([season1, season2]), isNull);

    // No leaf counts at all → can't tell, so returns null and callers fall back.
    expect(firstUnwatchedSeasonIndex([_season('season-1'), _season('season-2', index: 2)]), isNull);
  });

  test('preferredSeasonIndex falls back to the first unwatched season without an on-deck episode', () {
    final special = _season('specials', index: 0, leafCount: 2, viewedLeafCount: 0);
    final season1 = _season('season-1', index: 1, leafCount: 5, viewedLeafCount: 5);
    final season2 = _season('season-2', index: 2, leafCount: 5, viewedLeafCount: 1);

    // No explicit target, no backend on-deck → first season with unwatched episodes.
    expect(preferredSeasonIndex([special, season1, season2]), 2);
  });

  test('preferredSeasonIndex keeps the default season for a fully-unwatched show', () {
    final special = _season('specials', index: 0, leafCount: 2, viewedLeafCount: 0);
    final season1 = _season('season-1', index: 1, leafCount: 5, viewedLeafCount: 0);
    final season2 = _season('season-2', index: 2, leafCount: 5, viewedLeafCount: 0);

    // Identical to defaultPlaybackSeasonIndex (first regular season).
    expect(preferredSeasonIndex([special, season1, season2]), 1);
    expect(preferredSeasonIndex([special, season1, season2]), defaultPlaybackSeasonIndex([special, season1, season2]));
  });

  test('firstUnwatchedEpisode skips watched but keeps in-progress episodes', () {
    final watched = _episode('e1', index: 1, viewCount: 1);
    final inProgress = _episode('e2', index: 2, viewCount: 1, viewOffsetMs: 500, durationMs: 1000);
    final unwatched = _episode('e3', index: 3);

    // In-progress is returned even though it is flagged watched.
    expect(firstUnwatchedEpisode([watched, inProgress, unwatched]), same(inProgress));
    // Otherwise the first fully-unwatched episode wins.
    expect(firstUnwatchedEpisode([watched, unwatched]), same(unwatched));
    // Non-episode rows are ignored.
    expect(firstUnwatchedEpisode([_season('season-1'), unwatched]), same(unwatched));
  });

  test('firstUnwatchedEpisode returns null when every episode is watched', () {
    expect(
      firstUnwatchedEpisode([_episode('e1', index: 1, viewCount: 1), _episode('e2', index: 2, viewCount: 2)]),
      isNull,
    );
  });

  test('sortEpisodesByWatchOrder puts regular seasons first and Specials last', () {
    final s0e1 = _episode('s0e1', parentIndex: 0, index: 1);
    final s0e2 = _episode('s0e2', parentIndex: 0, index: 2);
    final s1e1 = _episode('s1e1', parentIndex: 1, index: 1);
    final s1e2 = _episode('s1e2', parentIndex: 1, index: 2);
    final s2e1 = _episode('s2e1', parentIndex: 2, index: 1);

    // Raw /grandchildren order would lead with the Specials folder.
    final episodes = [s0e1, s0e2, s1e1, s1e2, s2e1];
    sortEpisodesByWatchOrder(episodes);

    // A "next 2 unwatched" cut now takes S01E01/S01E02, not the Specials.
    expect(episodes.map((e) => e.id), ['s1e1', 's1e2', 's2e1', 's0e1', 's0e2']);
  });

  test('compareEpisodesByWatchOrder breaks index ties on id for deterministic cuts', () {
    final a = _episode('a', parentIndex: 1, index: 1);
    final b = _episode('b', parentIndex: 1, index: 1);

    expect(compareEpisodesByWatchOrder(a, b), lessThan(0));
    expect(compareEpisodesByWatchOrder(b, a), greaterThan(0));
    expect(compareEpisodesByWatchOrder(a, a), 0);
  });

  test('isSpecialSeasonNumber treats season 0 and missing numbers as Specials', () {
    expect(isSpecialSeasonNumber(0), isTrue);
    expect(isSpecialSeasonNumber(null), isTrue);
    expect(isSpecialSeasonNumber(1), isFalse);
    expect(isSpecialSeasonNumber(2), isFalse);
  });

  test('isUnwatchedOrInProgress keeps unwatched and resumable episodes', () {
    // Unwatched.
    expect(_episode('a', viewCount: 0).isUnwatchedOrInProgress, isTrue);
    // Watched with no resume point — counts as done.
    expect(_episode('b', viewCount: 1).isUnwatchedOrInProgress, isFalse);
    // Watched but still resumable (re-watching) — counts as to-watch.
    expect(
      _episode('c', viewCount: 1, viewOffsetMs: 500, durationMs: 1000).isUnwatchedOrInProgress,
      isTrue,
    );
  });

  test('fetchFirstEpisodeForSeason requests only the first children page', () async {
    final episode = _episode('episode-1');
    final client = _RecordingClient(
      childrenPageByParent: {
        'season-1': [episode, _episode('episode-2')],
      },
    );

    final result = await fetchFirstEpisodeForSeason(client, 'season-1');

    expect(result, same(episode));
    expect(client.childrenCalls, isEmpty);
    expect(client.childrenPageCalls, [(parentId: 'season-1', start: 0, size: 1)]);
  });

  test('fetchFirstEpisodeForSeason uses season episode paging when available', () async {
    final episode = _episode('episode-1');
    final client = _SeasonPagingRecordingClient(
      seasonPageBySeason: {
        (seriesId: 'show-1', seasonId: 'season-1'): [episode, _episode('episode-2')],
      },
    );

    final result = await fetchFirstEpisodeForSeason(client, 'season-1', seriesId: 'show-1');

    expect(result, same(episode));
    expect(client.childrenPageCalls, isEmpty);
    expect(client.seasonEpisodePageCalls, [(seriesId: 'show-1', seasonId: 'season-1', start: 0, size: 1)]);
  });

  test('fetchSeasonEpisodePage normalizes show and season identity', () async {
    final show = MediaItem(
      id: 'show-1',
      backend: MediaBackend.plex,
      kind: MediaKind.show,
      title: 'Show',
      serverId: 'server-1',
      serverName: 'Server',
      libraryId: 'lib-1',
      libraryTitle: 'Library',
    );
    final season = _season('season-1').copyWith(index: 1, libraryId: show.libraryId, libraryTitle: show.libraryTitle);
    final row = _episode('episode-1');
    final client = _RecordingClient(
      childrenPageByParent: {
        season.id: [row],
      },
    );

    final page = await fetchSeasonEpisodePage(client, show: show, season: season, start: 0, size: 200);

    expect(client.childrenCalls, isEmpty);
    expect(client.childrenPageCalls, [(parentId: 'season-1', start: 0, size: 200)]);
    expect(page.totalCount, 1);
    expect(page.items.single.serverId, show.serverId);
    expect(page.items.single.serverName, show.serverName);
    expect(page.items.single.grandparentId, show.id);
    expect(page.items.single.grandparentTitle, show.title);
    expect(page.items.single.parentId, season.id);
    expect(page.items.single.parentIndex, season.index);
    expect(page.items.single.libraryId, show.libraryId);
  });

  test('fetchSeasonEpisodePage uses season episode paging when available', () async {
    final show = MediaItem(id: 'show-1', backend: MediaBackend.plex, kind: MediaKind.show, title: 'Show');
    final season = _season('season-1');
    final row = _episode('episode-1');
    final client = _SeasonPagingRecordingClient(
      seasonPageBySeason: {
        (seriesId: show.id, seasonId: season.id): [row],
      },
    );

    final page = await fetchSeasonEpisodePage(client, show: show, season: season, start: 0, size: 10);

    expect(client.childrenPageCalls, isEmpty);
    expect(client.seasonEpisodePageCalls, [(seriesId: show.id, seasonId: season.id, start: 0, size: 10)]);
    expect(page.items.single.id, row.id);
  });

  test('normalizeSeasonEpisodes ignores non-episode rows', () {
    final show = MediaItem(id: 'show-1', backend: MediaBackend.plex, kind: MediaKind.show, title: 'Show');
    final season = _season('season-1');

    final normalized = normalizeSeasonEpisodes([_clip('extra-1'), _episode('episode-1')], show: show, season: season);

    expect(normalized.map((item) => item.id), ['episode-1']);
  });

  test('fetchRepresentativeVersions uses paged lookup for season metadata', () async {
    final versions = [const MediaVersion(id: '1080', videoResolution: '1080')];
    final episodeRow = _episode('episode-1');
    final fullEpisode = _episode('episode-1', versions: versions);
    final client = _RecordingClient(
      childrenPageByParent: {
        'season-1': [episodeRow],
      },
      itemsById: {'episode-1': fullEpisode},
    );

    final result = await fetchRepresentativeVersions(client, _season('season-1'));

    expect(result, same(versions));
    expect(client.childrenCalls, isEmpty);
    expect(client.childrenPageCalls, [(parentId: 'season-1', start: 0, size: 1)]);
  });

  test('fetchRepresentativeVersions keeps full season lookup but pages selected season episodes', () async {
    final versions = [const MediaVersion(id: '1080', videoResolution: '1080')];
    final show = MediaItem(id: 'show-1', backend: MediaBackend.plex, kind: MediaKind.show, title: 'Show');
    final special = _season('specials', index: 0);
    final firstRegularSeason = _season('season-1');
    final episodeRow = _episode('episode-1');
    final fullEpisode = _episode('episode-1', versions: versions);
    final client = _RecordingClient(
      childrenByParent: {
        'show-1': [special, firstRegularSeason],
      },
      childrenPageByParent: {
        'season-1': [episodeRow],
      },
      itemsById: {'episode-1': fullEpisode},
    );

    final result = await fetchRepresentativeVersions(client, show);

    expect(result, same(versions));
    expect(client.childrenCalls, ['show-1']);
    expect(client.childrenPageCalls, [(parentId: 'season-1', start: 0, size: 1)]);
  });
}
