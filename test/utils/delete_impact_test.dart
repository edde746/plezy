import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_part.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/media_version.dart';
import 'package:plezy/models/plex/plex_config.dart';
import 'package:plezy/services/plex_api_cache.dart';
import 'package:plezy/services/plex_client.dart';
import 'package:plezy/utils/delete_impact.dart';

import '../test_helpers/backend_client_fixtures.dart';
import '../test_helpers/media_items.dart';

/// Plex is the backend that actually produces multi-episode files, and #1781
/// was reported against it. These drive the real [PlexClient] and Plex mappers
/// over a [MockClient], so the wire shape Plezy depends on — `Media` → `Part` →
/// `file` on both `/library/metadata/{id}` and `/library/metadata/{id}/children`
/// — is asserted rather than assumed.
///
/// Plain `test`, not `testWidgets`: the Plex metadata cache is a real Drift
/// database, and its I/O never completes under the widget tester's fake clock.
/// Awaiting the resolver directly keeps this deterministic with no clock
/// pumping and no wall-clock waiting.
void main() {
  const sharedFile = '/tv/Breaking Bad/Season 01/S01E02-E03.mkv';

  /// Episode `Metadata` entry. [file]/[files] land on nested `Part` entries,
  /// which is the attribute the shared-file signal reads.
  ///
  /// [partWithoutPath] emits a `Media` whose `Part` carries no `file` — what a
  /// Plex restricted user receives. Passing none of the three omits `Media`
  /// entirely, the thin-row shape.
  Map<String, Object?> episodeMetadata({
    required String id,
    required int index,
    String? file,
    List<String>? files,
    bool partWithoutPath = false,
  }) => {
    'ratingKey': id,
    'key': '/library/metadata/$id',
    'type': 'episode',
    'title': 'Episode $index',
    'index': index,
    'parentIndex': 1,
    'parentRatingKey': 'season-1',
    'grandparentRatingKey': 'show-1',
    'grandparentTitle': 'Breaking Bad',
    if (file != null || files != null || partWithoutPath)
      'Media': [
        {
          'id': 'media-$id',
          'container': 'mkv',
          'Part': [
            if (partWithoutPath)
              {'id': 'part-$id', 'key': '/library/parts/$id/file.mkv', 'size': 1024}
            else
              for (final path in files ?? <String>[file!])
                {'id': 'part-$id-${path.hashCode}', 'key': '/library/parts/$id/file.mkv', 'file': path, 'size': 1024},
          ],
        },
      ],
  };

  http.Response container(List<Map<String, Object?>> metadata) => http.Response(
    jsonEncode({
      'MediaContainer': {'size': metadata.length, 'totalSize': metadata.length, 'Metadata': metadata},
    }),
    200,
    headers: const {'content-type': 'application/json'},
  );

  /// A real PlexClient over [handler], with the metadata cache backed by an
  /// in-memory database. Recorded request paths let a test prove which
  /// endpoints the resolver actually consulted.
  ({PlexClient client, List<String> paths, List<String> deleted}) plexClient(
    Future<http.Response> Function(String path) handler,
  ) {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    PlexApiCache.initialize(db);
    final paths = <String>[];
    final deleted = <String>[];
    final client = testPlexClient(
      config: PlexConfig(
        baseUrl: 'https://plex.example.com',
        token: 'token',
        clientIdentifier: 'client-id',
        product: 'Plezy',
        version: '1',
      ),
      serverId: ServerId('plex-1'),
      httpClient: MockClient((request) async {
        paths.add(request.url.path);
        if (request.method == 'DELETE') {
          deleted.add(request.url.path.split('/').last);
          return http.Response('', 200);
        }
        return handler(request.url.path);
      }),
    );
    addTearDown(() async {
      client.close();
      await db.close();
    });
    return (client: client, paths: paths, deleted: deleted);
  }

  /// The reported shape: an episode row Plezy holds with no media at all.
  final thinEpisode = testMediaItem(
    id: 'ep-2',
    backend: MediaBackend.plex,
    kind: MediaKind.episode,
    title: 'Cat in the Bag',
    parentId: 'season-1',
    parentIndex: 1,
    index: 2,
    grandparentId: 'show-1',
    grandparentTitle: 'Breaking Bad',
    serverId: 'plex-1',
  );

  test('a thin row recovers scope from detail and finds the episode sharing its file', () async {
    final plex = plexClient(
      (path) async => switch (path) {
        '/library/metadata/ep-2' => container([episodeMetadata(id: 'ep-2', index: 2, file: sharedFile)]),
        '/library/metadata/season-1/children' => container([
          episodeMetadata(id: 'ep-1', index: 1, file: '/tv/Breaking Bad/Season 01/S01E01.mkv'),
          episodeMetadata(id: 'ep-2', index: 2, file: sharedFile),
          episodeMetadata(id: 'ep-3', index: 3, file: sharedFile),
        ]),
        _ => http.Response('not found', 404),
      },
    );

    final impact = await resolveDeleteImpact(item: thinEpisode, client: plex.client);

    expect(impact.scope, DeleteImpactScope.broad);
    expect(impact.files, {sharedFile});
    expect(impact.sharedWith.map((item) => item.id), ['ep-3']);
    // The inline row carried nothing, so both endpoints had to be consulted.
    expect(plex.paths, contains('/library/metadata/ep-2'));
    expect(plex.paths, contains('/library/metadata/season-1/children'));
  });

  test('deletes only the resolved episode rating key', () async {
    final plex = plexClient(
      (path) async => switch (path) {
        '/library/metadata/ep-2' => container([episodeMetadata(id: 'ep-2', index: 2, file: sharedFile)]),
        '/library/metadata/season-1/children' => container([
          episodeMetadata(id: 'ep-2', index: 2, file: sharedFile),
          episodeMetadata(id: 'ep-3', index: 3, file: sharedFile),
        ]),
        _ => http.Response('not found', 404),
      },
    );

    expect(await plex.client.deleteMediaItem(thinEpisode), isTrue);

    expect(plex.deleted, ['ep-2'], reason: 'a shared file must not widen the DELETE to its siblings');
    expect(plex.paths, contains('/library/metadata/ep-2'));
  });

  test('an episode alone in its file resolves as exclusive', () async {
    const ownFile = '/tv/Breaking Bad/Season 01/S01E02.mkv';
    final plex = plexClient(
      (path) async => switch (path) {
        '/library/metadata/ep-2' => container([episodeMetadata(id: 'ep-2', index: 2, file: ownFile)]),
        '/library/metadata/season-1/children' => container([
          episodeMetadata(id: 'ep-2', index: 2, file: ownFile),
          episodeMetadata(id: 'ep-3', index: 3, file: '/tv/Breaking Bad/Season 01/S01E03.mkv'),
        ]),
        _ => http.Response('not found', 404),
      },
    );

    final impact = await resolveDeleteImpact(item: thinEpisode, client: plex.client);

    expect(impact.scope, DeleteImpactScope.exclusive);
    expect(impact.sharedWith, isEmpty);
  });

  test('a multi-part episode counts every file it will destroy', () async {
    const parts = ['/tv/bb/S01E02-cd1.mkv', '/tv/bb/S01E02-cd2.mkv'];
    final plex = plexClient(
      (path) async => switch (path) {
        '/library/metadata/ep-2' => container([episodeMetadata(id: 'ep-2', index: 2, files: parts)]),
        '/library/metadata/season-1/children' => container([episodeMetadata(id: 'ep-2', index: 2, files: parts)]),
        _ => http.Response('not found', 404),
      },
    );

    final impact = await resolveDeleteImpact(item: thinEpisode, client: plex.client);

    expect(impact.scope, DeleteImpactScope.broad);
    expect(impact.files, parts.toSet());
    expect(impact.sharedWith, isEmpty);
  });

  test('a Part carrying no path is unverified, not a single known file', () async {
    // A restricted user gets Media and Part but never `file`. Skipping such a
    // part instead of invalidating the answer would report one path-less part
    // as an exclusive single-file delete.
    final plex = plexClient(
      (path) async => switch (path) {
        '/library/metadata/ep-2' => container([episodeMetadata(id: 'ep-2', index: 2, partWithoutPath: true)]),
        '/library/metadata/season-1/children' => container([
          episodeMetadata(id: 'ep-2', index: 2, partWithoutPath: true),
        ]),
        _ => http.Response('not found', 404),
      },
    );

    final impact = await resolveDeleteImpact(item: thinEpisode, client: plex.client);

    expect(impact.scope, DeleteImpactScope.unverified);
    expect(impact.reason, DeleteImpactUnverifiedReason.noFileInfo);
    expect(impact.files, isEmpty);
  });

  test('a payload with no media at all is unverified', () async {
    final plex = plexClient(
      (path) async => switch (path) {
        '/library/metadata/ep-2' => container([episodeMetadata(id: 'ep-2', index: 2)]),
        '/library/metadata/season-1/children' => container([episodeMetadata(id: 'ep-2', index: 2)]),
        _ => http.Response('not found', 404),
      },
    );

    final impact = await resolveDeleteImpact(item: thinEpisode, client: plex.client);

    expect(impact.scope, DeleteImpactScope.unverified);
    expect(impact.reason, DeleteImpactUnverifiedReason.noFileInfo);
  });

  test('a sibling whose path stays unknown blocks an exclusive verdict', () async {
    // Neither the browse row nor the detail refetch names ep-3's file, so it
    // could be backed by this very file. Assuming it is distinct would hide a
    // shared-file delete behind a confident confirmation.
    final plex = plexClient(
      (path) async => switch (path) {
        '/library/metadata/ep-2' => container([episodeMetadata(id: 'ep-2', index: 2, file: sharedFile)]),
        '/library/metadata/season-1/children' => container([
          episodeMetadata(id: 'ep-2', index: 2, file: sharedFile),
          episodeMetadata(id: 'ep-3', index: 3, partWithoutPath: true),
        ]),
        '/library/metadata/ep-3' => container([episodeMetadata(id: 'ep-3', index: 3, partWithoutPath: true)]),
        _ => http.Response('not found', 404),
      },
    );

    final impact = await resolveDeleteImpact(item: thinEpisode, client: plex.client);

    expect(impact.scope, DeleteImpactScope.unverified);
    expect(impact.reason, DeleteImpactUnverifiedReason.noFileInfo);
    expect(plex.paths, contains('/library/metadata/ep-3'));
  });

  test('a sibling row without a path is resolved before ruling out a shared file', () async {
    final plex = plexClient(
      (path) async => switch (path) {
        '/library/metadata/ep-2' => container([episodeMetadata(id: 'ep-2', index: 2, file: sharedFile)]),
        // The browse row omits ep-3's path; trusting it would report the delete
        // as exclusive while the server destroys ep-3 with the same file.
        '/library/metadata/season-1/children' => container([
          episodeMetadata(id: 'ep-2', index: 2, file: sharedFile),
          episodeMetadata(id: 'ep-3', index: 3),
        ]),
        '/library/metadata/ep-3' => container([episodeMetadata(id: 'ep-3', index: 3, file: sharedFile)]),
        _ => http.Response('not found', 404),
      },
    );

    final impact = await resolveDeleteImpact(item: thinEpisode, client: plex.client);

    expect(impact.scope, DeleteImpactScope.broad);
    expect(impact.sharedWith.map((item) => item.id), ['ep-3']);
    expect(plex.paths, contains('/library/metadata/ep-3'));
  });

  // Direct contract of the predicate every verdict above rests on. Neither
  // mapper can currently produce a version with zero parts, so this is the
  // only place that shape is pinned.
  group('completePartFiles', () {
    test('rejects an empty version list', () {
      expect(completePartFiles(const []), isNull);
    });

    test('rejects a version with no parts rather than reporting zero files', () {
      expect(completePartFiles(const [MediaVersion(id: 'v-1')]), isNull);
    });

    test('rejects a version where any single part lacks a path', () {
      expect(
        completePartFiles(const [
          MediaVersion(
            id: 'v-1',
            parts: [
              MediaPart(id: 'p-1', file: '/tv/a.mkv'),
              MediaPart(id: 'p-2'),
            ],
          ),
        ]),
        isNull,
        reason: 'one unknown path makes the whole file list untrustworthy',
      );
    });

    test('collapses duplicate paths across versions into one file', () {
      expect(
        completePartFiles(const [
          MediaVersion(
            id: 'v-1',
            parts: [MediaPart(id: 'p-1', file: '/tv/a.mkv')],
          ),
          MediaVersion(
            id: 'v-2',
            parts: [MediaPart(id: 'p-2', file: '/tv/a.mkv')],
          ),
        ]),
        {'/tv/a.mkv'},
      );
    });

    test('returns every distinct path of a multi-part version', () {
      expect(
        completePartFiles(const [
          MediaVersion(
            id: 'v-1',
            parts: [
              MediaPart(id: 'p-1', file: '/tv/cd1.mkv'),
              MediaPart(id: 'p-2', file: '/tv/cd2.mkv'),
            ],
          ),
        ]),
        {'/tv/cd1.mkv', '/tv/cd2.mkv'},
      );
    });
  });

  test('a failed sibling lookup is a transient probe failure', () async {
    final plex = plexClient(
      (path) async => switch (path) {
        '/library/metadata/ep-2' => container([episodeMetadata(id: 'ep-2', index: 2, file: sharedFile)]),
        _ => http.Response('boom', 500),
      },
    );

    final impact = await resolveDeleteImpact(item: thinEpisode, client: plex.client);

    expect(impact.scope, DeleteImpactScope.unverified);
    expect(impact.reason, DeleteImpactUnverifiedReason.probeFailed);
  });

  group('bounded probing', () {
    /// A season whose rows all arrive without paths — the shape that would fan
    /// out one detail request per episode.
    List<Map<String, Object?>> pathlessSeason(int count) => [
      episodeMetadata(id: 'ep-2', index: 2, file: sharedFile),
      for (var index = 3; index < 3 + count; index++)
        episodeMetadata(id: 'ep-$index', index: index, partWithoutPath: true),
    ];

    int detailFetches(List<String> paths) =>
        paths.where((path) => path.startsWith('/library/metadata/ep-') && !path.endsWith('/children')).length;

    test('stops at the first sibling it cannot resolve instead of fanning out', () async {
      final plex = plexClient(
        (path) async => switch (path) {
          '/library/metadata/ep-2' => container([episodeMetadata(id: 'ep-2', index: 2, file: sharedFile)]),
          '/library/metadata/season-1/children' => container(pathlessSeason(60)),
          // Every sibling detail refuses; only the first may ever be asked.
          _ => http.Response('boom', 500),
        },
      );

      final impact = await resolveDeleteImpact(item: thinEpisode, client: plex.client);

      expect(impact.scope, DeleteImpactScope.unverified);
      expect(impact.reason, DeleteImpactUnverifiedReason.probeFailed);
      expect(
        detailFetches(plex.paths),
        2,
        reason: 'the target plus exactly one sibling — not one request per path-less episode',
      );
    });

    test('asks nothing extra of a season whose rows already carry paths', () async {
      final plex = plexClient(
        (path) async => switch (path) {
          '/library/metadata/ep-2' => container([episodeMetadata(id: 'ep-2', index: 2, file: sharedFile)]),
          '/library/metadata/season-1/children' => container([
            episodeMetadata(id: 'ep-2', index: 2, file: sharedFile),
            for (var index = 3; index < 40; index++)
              episodeMetadata(id: 'ep-$index', index: index, file: '/tv/bb/S01E$index.mkv'),
          ]),
          _ => http.Response('should not be fetched', 500),
        },
      );

      final impact = await resolveDeleteImpact(item: thinEpisode, client: plex.client);

      expect(impact.scope, DeleteImpactScope.exclusive);
      expect(detailFetches(plex.paths), 1, reason: 'only the thin target itself needs a detail request');
    });
  });
  // The Plex cases above cannot express a deadline: their cache is a real
  // database, so they need a real clock. Cancellation is backend-neutral, so it
  // is pinned here against a narrow fake under `fakeAsync` — deterministic,
  // and no wall-clock waiting.
  group('cancellation on timeout', () {
    const timeout = Duration(seconds: 10);

    MediaItem pathlessEpisode(String id, int index) => testMediaItem(
      id: id,
      kind: MediaKind.episode,
      title: 'Episode $index',
      parentId: 'season-1',
      parentIndex: 1,
      index: index,
      grandparentId: 'show-1',
      serverId: 'srv-1',
      mediaVersions: const [
        MediaVersion(
          id: 'v',
          parts: [MediaPart(id: 'p')],
        ),
      ],
    );

    test('no further sibling is fetched once the deadline has returned', () {
      final target = testMediaItem(
        id: 'ep-2',
        kind: MediaKind.episode,
        title: 'Cat in the Bag',
        parentId: 'season-1',
        parentIndex: 1,
        index: 2,
        grandparentId: 'show-1',
        serverId: 'srv-1',
        mediaVersions: const [
          MediaVersion(
            id: 'v-2',
            parts: [MediaPart(id: 'p-2', file: '/tv/bb/S01E02.mkv')],
          ),
        ],
      );
      // Every sibling row lacks a path, so each one costs a detail lookup.
      final client = _GatedClient(
        children: [target, for (var index = 3; index < 30; index++) pathlessEpisode('ep-$index', index)],
      );

      DeleteImpact? impact;
      fakeAsync((async) {
        resolveDeleteImpact(item: target, client: client, timeout: timeout).then((value) => impact = value);

        // Let the children lookup land and the first sibling fetch begin.
        async.flushMicrotasks();
        expect(client.itemFetches, 1, reason: 'one sibling in flight');
        expect(impact, isNull);

        async.elapse(timeout + const Duration(seconds: 1));
        expect(impact?.scope, DeleteImpactScope.unverified);
        expect(impact?.reason, DeleteImpactUnverifiedReason.probeFailed);
        expect(client.itemFetches, 1, reason: 'the deadline must not have started another');

        // The abandoned request finally answers. The loop resumes here — and
        // must stop instead of walking the remaining 26 siblings.
        client.releaseFetch();
        async.flushMicrotasks();
        async.elapse(const Duration(minutes: 1));

        expect(
          client.itemFetches,
          1,
          reason: 'a completed in-flight fetch must not restart the walk after the probe gave up',
        );
      });
    });

    test('an uninterrupted probe still visits every sibling', () {
      final target = testMediaItem(
        id: 'ep-2',
        kind: MediaKind.episode,
        parentId: 'season-1',
        index: 2,
        grandparentId: 'show-1',
        serverId: 'srv-1',
        mediaVersions: const [
          MediaVersion(
            id: 'v-2',
            parts: [MediaPart(id: 'p-2', file: '/tv/bb/S01E02.mkv')],
          ),
        ],
      );
      final client = _GatedClient(children: [target, pathlessEpisode('ep-3', 3), pathlessEpisode('ep-4', 4)])
        ..autoRelease = true
        ..detailFile = '/tv/bb/S01E02.mkv';

      DeleteImpact? impact;
      fakeAsync((async) {
        resolveDeleteImpact(item: target, client: client, timeout: timeout).then((value) => impact = value);
        async.flushMicrotasks();

        expect(client.itemFetches, 2, reason: 'both path-less siblings resolved');
        expect(impact?.scope, DeleteImpactScope.broad);
        expect(impact?.sharedWith.map((item) => item.id), ['ep-3', 'ep-4']);
      });
    });

    test('the season is never listed when the deadline expires on the item itself', () {
      // The target's own row carries no path, so its lookup is the first thing
      // outstanding. Resuming past it would ask the server for the children of
      // a season nobody is waiting on any more.
      final target = pathlessEpisode('ep-2', 2);
      final client = _GatedClient(children: [target, pathlessEpisode('ep-3', 3)]);

      DeleteImpact? impact;
      fakeAsync((async) {
        resolveDeleteImpact(item: target, client: client, timeout: timeout).then((value) => impact = value);
        async.flushMicrotasks();
        expect(client.itemFetches, 1);
        expect(client.childrenFetches, 0);

        async.elapse(timeout + const Duration(seconds: 1));
        expect(impact?.reason, DeleteImpactUnverifiedReason.probeFailed);

        client.releaseFetch();
        async.flushMicrotasks();
        async.elapse(const Duration(minutes: 1));

        expect(client.childrenFetches, 0, reason: 'an abandoned probe must not go on to list the season');
        expect(client.itemFetches, 1);
      });
    });
  });
}

/// Neutral client whose item lookups can be held open, so a test can place the
/// probe deadline in the middle of one.
class _GatedClient implements MediaServerClient {
  _GatedClient({required this.children});

  final List<MediaItem> children;

  /// Answer item lookups immediately instead of gating them.
  bool autoRelease = false;

  /// Path reported by a released lookup.
  String detailFile = '/tv/bb/other.mkv';

  int itemFetches = 0;
  int childrenFetches = 0;
  final List<Completer<MediaItem?>> _pending = [];

  void releaseFetch() {
    for (final completer in _pending) {
      if (!completer.isCompleted) completer.complete(_detail());
    }
    _pending.clear();
  }

  MediaItem _detail() => testMediaItem(
    id: 'resolved',
    kind: MediaKind.episode,
    serverId: 'srv-1',
    mediaVersions: [
      MediaVersion(
        id: 'v',
        parts: [MediaPart(id: 'p', file: detailFile)],
      ),
    ],
  );

  @override
  Future<List<MediaItem>> fetchChildren(String parentId) async {
    childrenFetches++;
    return children;
  }

  @override
  Future<MediaItem?> fetchItem(String id) {
    itemFetches++;
    if (autoRelease) return Future.value(_detail());
    final completer = Completer<MediaItem?>();
    _pending.add(completer);
    return completer.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
