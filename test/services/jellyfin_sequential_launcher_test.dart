import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_playlist.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/services/jellyfin_sequential_launcher.dart';
import 'package:plezy/services/media_list_playback_launcher.dart';

/// Recording fake that satisfies [JellyfinClient] via `implements` +
/// `noSuchMethod`. The launcher only needs the
/// [MediaServerClient.fetchPlayableDescendants] /
/// [MediaServerClient.fetchClientSideEpisodeQueue] surface, but we
/// `implements JellyfinClient` so existing tests stay backend-tagged.
class _RecordingJellyfinClient implements JellyfinClient {
  final List<MediaItem> playableDescendantsResponse;
  final List<MediaItem> seriesEpisodesResponse;
  final List<MediaItem> playlistItemsResponse;
  final List<String> fetchPlayableDescendantsCalls = [];
  final List<String> fetchSeriesEpisodesCalls = [];
  final List<({String id, int offset, int limit})> fetchPlaylistItemsCalls = [];

  _RecordingJellyfinClient({
    this.playableDescendantsResponse = const [],
    this.seriesEpisodesResponse = const [],
    this.playlistItemsResponse = const [],
  });

  @override
  Future<List<MediaItem>> fetchPlayableDescendants(String parentId) async {
    fetchPlayableDescendantsCalls.add(parentId);
    return playableDescendantsResponse;
  }

  @override
  Future<List<MediaItem>?> fetchClientSideEpisodeQueue(String seriesId) async {
    fetchSeriesEpisodesCalls.add(seriesId);
    return seriesEpisodesResponse;
  }

  @override
  Future<List<MediaItem>> fetchPlaylistItems(String id, {int offset = 0, int limit = 100}) async {
    fetchPlaylistItemsCalls.add((id: id, offset: offset, limit: limit));
    if (offset >= playlistItemsResponse.length) return const [];
    final end = (offset + limit).clamp(0, playlistItemsResponse.length);
    return playlistItemsResponse.sublist(offset, end);
  }

  @override
  MediaBackend get backend => MediaBackend.jellyfin;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MediaItem _ep(String id, {String? serverId = 'srv-jf'}) => MediaItem(
  id: id,
  backend: MediaBackend.jellyfin,
  kind: MediaKind.episode,
  title: 'Episode $id',
  serverId: serverId,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<BuildContext> pumpContext(WidgetTester tester) async {
    late BuildContext capturedContext;
    // Wrap in MaterialApp + Scaffold so ScaffoldMessenger is available
    // for the error-path snackbars the launcher emits.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    return capturedContext;
  }

  group('JellyfinSequentialLauncher', () {
    testWidgets('input guard rejects strings (neither MediaItem nor MediaPlaylist)', (tester) async {
      final ctx = await pumpContext(tester);
      final launcher = JellyfinSequentialLauncher(context: ctx);

      final result = await launcher.launchFromCollectionOrPlaylist(item: 'not-an-item', shuffle: false);

      expect(result, isA<PlayQueueError>());
      final error = (result as PlayQueueError).error;
      expect(error.toString(), contains('collection or playlist'));
    });

    testWidgets('input guard rejects items without serverId', (tester) async {
      final ctx = await pumpContext(tester);
      final launcher = JellyfinSequentialLauncher(context: ctx);

      final orphan = MediaItem(
        id: 'col-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.collection,
        // no serverId
      );

      final result = await launcher.launchFromCollectionOrPlaylist(item: orphan, shuffle: false);

      expect(result, isA<PlayQueueError>());
      expect((result as PlayQueueError).error.toString(), contains('serverId'));
    });

    testWidgets('collection path expands to playable items in order', (tester) async {
      final ctx = await pumpContext(tester);
      final fetched = [_ep('e1'), _ep('e2'), _ep('e3')];
      final fakeClient = _RecordingJellyfinClient(playableDescendantsResponse: fetched);
      final playback = PlaybackStateProvider();
      final navigated = <MediaItem>[];

      final launcher = JellyfinSequentialLauncher(
        context: ctx,
        clientForTesting: fakeClient,
        playbackStateForTesting: playback,
        navigateForTesting: (m) async => navigated.add(m),
      );

      final collection = MediaItem(
        id: 'col-99',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.collection,
        serverId: 'srv-jf',
      );

      final result = await launcher.launchFromCollectionOrPlaylist(
        item: collection,
        shuffle: false,
        showLoadingIndicator: false,
      );

      expect(result, isA<PlayQueueSuccess>());
      expect(fakeClient.fetchPlayableDescendantsCalls, ['col-99']);
      // Queue is seeded in original order, current is items[0].
      expect(playback.loadedItems.map((m) => m.id).toList(), ['e1', 'e2', 'e3']);
      expect(playback.isQueueActive, isTrue);
      expect(playback.isShuffleActive, isFalse);
      // First item is what the player navigates to.
      expect(navigated.single.id, 'e1');
    });

    testWidgets('playlist path uses /Playlists/{id}/Items endpoint', (tester) async {
      final ctx = await pumpContext(tester);
      final fetched = [_ep('a'), _ep('b')];
      final fakeClient = _RecordingJellyfinClient(playlistItemsResponse: fetched);
      final playback = PlaybackStateProvider();

      final launcher = JellyfinSequentialLauncher(
        context: ctx,
        clientForTesting: fakeClient,
        playbackStateForTesting: playback,
        navigateForTesting: (_) async {},
      );

      final playlist = const MediaPlaylist(
        id: 'pl-7',
        backend: MediaBackend.jellyfin,
        title: 'Mix',
        playlistType: 'video',
        serverId: 'srv-jf',
      );

      final result = await launcher.launchFromCollectionOrPlaylist(
        item: playlist,
        shuffle: false,
        showLoadingIndicator: false,
      );

      expect(result, isA<PlayQueueSuccess>());
      // Playlist-defined order via the dedicated endpoint — no recursive
      // descendant expansion (which doesn't preserve playlist order).
      expect(fakeClient.fetchPlayableDescendantsCalls, isEmpty);
      expect(fakeClient.fetchPlaylistItemsCalls.map((c) => c.id).toList(), ['pl-7']);
      expect(fakeClient.fetchPlaylistItemsCalls.first.offset, 0);
      expect(playback.loadedItems.map((m) => m.id).toList(), ['a', 'b']);
    });

    testWidgets('playlist path pages through every item', (tester) async {
      final ctx = await pumpContext(tester);
      // 150 items across 2 pages of 100 — the loop must keep paging until
      // the server returns a short page.
      final fetched = List.generate(150, (i) => _ep('p$i'));
      final fakeClient = _RecordingJellyfinClient(playlistItemsResponse: fetched);
      final playback = PlaybackStateProvider();

      final launcher = JellyfinSequentialLauncher(
        context: ctx,
        clientForTesting: fakeClient,
        playbackStateForTesting: playback,
        navigateForTesting: (_) async {},
      );

      final playlist = const MediaPlaylist(
        id: 'pl-big',
        backend: MediaBackend.jellyfin,
        title: 'Big',
        playlistType: 'video',
        serverId: 'srv-jf',
      );

      final result = await launcher.launchFromCollectionOrPlaylist(
        item: playlist,
        shuffle: false,
        showLoadingIndicator: false,
      );

      expect(result, isA<PlayQueueSuccess>());
      expect(playback.loadedItems.length, 150);
      expect(fakeClient.fetchPlaylistItemsCalls, hasLength(2));
      expect(fakeClient.fetchPlaylistItemsCalls[0].offset, 0);
      expect(fakeClient.fetchPlaylistItemsCalls[1].offset, 100);
    });

    testWidgets('collection containing a Series entry only seeds playable descendants', (tester) async {
      // Anchor: the recursive expansion is what skips the unplayable Series
      // container. If a future change reverts to fetchChildren the test
      // fails because a Series row would leak into the queue.
      final ctx = await pumpContext(tester);
      final movie = MediaItem(id: 'movie-1', backend: MediaBackend.jellyfin, kind: MediaKind.movie, serverId: 'srv-jf');
      final ep1 = _ep('series-A-ep1');
      final ep2 = _ep('series-A-ep2');
      final fakeClient = _RecordingJellyfinClient(playableDescendantsResponse: [movie, ep1, ep2]);
      final playback = PlaybackStateProvider();
      final navigated = <MediaItem>[];

      final launcher = JellyfinSequentialLauncher(
        context: ctx,
        clientForTesting: fakeClient,
        playbackStateForTesting: playback,
        navigateForTesting: (m) async => navigated.add(m),
      );

      final collection = MediaItem(
        id: 'col-mixed',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.collection,
        serverId: 'srv-jf',
      );

      final result = await launcher.launchFromCollectionOrPlaylist(
        item: collection,
        shuffle: false,
        showLoadingIndicator: false,
      );

      expect(result, isA<PlayQueueSuccess>());
      expect(playback.loadedItems.map((m) => m.id).toList(), ['movie-1', 'series-A-ep1', 'series-A-ep2']);
      // No Series rows leaked into the queue.
      expect(playback.loadedItems.any((m) => m.kind == MediaKind.show), isFalse);
      expect(navigated.single.id, 'movie-1');
    });

    testWidgets('shuffle=true reorders the queue (seed-stable assertion)', (tester) async {
      final ctx = await pumpContext(tester);
      // Use enough items that a coincidence-preserved order is statistically
      // unlikely (1 / 50! ~ 0).
      final originalIds = List.generate(50, (i) => 'e$i');
      final fetched = originalIds.map(_ep).toList();
      final fakeClient = _RecordingJellyfinClient(playableDescendantsResponse: fetched);
      final playback = PlaybackStateProvider();

      final launcher = JellyfinSequentialLauncher(
        context: ctx,
        clientForTesting: fakeClient,
        playbackStateForTesting: playback,
        navigateForTesting: (_) async {},
      );

      final collection = MediaItem(
        id: 'col-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.collection,
        serverId: 'srv-jf',
      );

      final result = await launcher.launchFromCollectionOrPlaylist(
        item: collection,
        shuffle: true,
        showLoadingIndicator: false,
      );

      expect(result, isA<PlayQueueSuccess>());
      // Same set of ids, just reordered.
      final shuffledIds = playback.loadedItems.map((m) => m.id).toList();
      expect(shuffledIds.toSet(), originalIds.toSet());
      expect(shuffledIds.length, originalIds.length);
      expect(playback.isShuffleActive, isTrue);
      // The shuffle should not preserve the original order.
      expect(shuffledIds, isNot(equals(originalIds)));
    });

    testWidgets('startItem positions playback at the matching index', (tester) async {
      final ctx = await pumpContext(tester);
      final fetched = [_ep('a'), _ep('b'), _ep('c'), _ep('d')];
      final fakeClient = _RecordingJellyfinClient(playableDescendantsResponse: fetched);
      final playback = PlaybackStateProvider();
      final navigated = <MediaItem>[];

      final launcher = JellyfinSequentialLauncher(
        context: ctx,
        clientForTesting: fakeClient,
        playbackStateForTesting: playback,
        navigateForTesting: (m) async => navigated.add(m),
      );

      final collection = MediaItem(
        id: 'col-start',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.collection,
        serverId: 'srv-jf',
      );

      final result = await launcher.launchFromCollectionOrPlaylist(
        item: collection,
        shuffle: false,
        startItem: fetched[2], // 'c'
        showLoadingIndicator: false,
      );

      expect(result, isA<PlayQueueSuccess>());
      // Queue keeps original order; player navigates to the chosen item.
      expect(playback.loadedItems.map((m) => m.id).toList(), ['a', 'b', 'c', 'd']);
      expect(navigated.single.id, 'c');
    });

    testWidgets('startItem with no match falls back to head of queue', (tester) async {
      final ctx = await pumpContext(tester);
      final fetched = [_ep('a'), _ep('b')];
      final fakeClient = _RecordingJellyfinClient(playableDescendantsResponse: fetched);
      final playback = PlaybackStateProvider();
      final navigated = <MediaItem>[];

      final launcher = JellyfinSequentialLauncher(
        context: ctx,
        clientForTesting: fakeClient,
        playbackStateForTesting: playback,
        navigateForTesting: (m) async => navigated.add(m),
      );

      final collection = MediaItem(
        id: 'col',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.collection,
        serverId: 'srv-jf',
      );

      final result = await launcher.launchFromCollectionOrPlaylist(
        item: collection,
        shuffle: false,
        startItem: _ep('not-in-list'),
        showLoadingIndicator: false,
      );

      expect(result, isA<PlayQueueSuccess>());
      expect(navigated.single.id, 'a');
    });

    testWidgets('launchShuffledShow rejects non-show/season kinds', (tester) async {
      final ctx = await pumpContext(tester);
      final launcher = JellyfinSequentialLauncher(context: ctx);

      final movie = MediaItem(id: 'm1', backend: MediaBackend.jellyfin, kind: MediaKind.movie, serverId: 'srv-jf');

      final result = await launcher.launchShuffledShow(metadata: movie, showLoadingIndicator: false);

      expect(result, isA<PlayQueueError>());
      expect((result as PlayQueueError).error.toString(), contains('shows and seasons'));
    });

    testWidgets('launchShuffledShow rejects season missing parentId', (tester) async {
      final ctx = await pumpContext(tester);
      final launcher = JellyfinSequentialLauncher(context: ctx);

      final season = MediaItem(id: 's1', backend: MediaBackend.jellyfin, kind: MediaKind.season, serverId: 'srv-jf');

      final result = await launcher.launchShuffledShow(metadata: season, showLoadingIndicator: false);

      expect(result, isA<PlayQueueError>());
      expect((result as PlayQueueError).error.toString(), contains('parentId'));
    });

    testWidgets('launchShuffledShow rejects items missing serverId', (tester) async {
      final ctx = await pumpContext(tester);
      final launcher = JellyfinSequentialLauncher(context: ctx);

      final orphan = MediaItem(id: 'show-orphan', backend: MediaBackend.jellyfin, kind: MediaKind.show);

      final result = await launcher.launchShuffledShow(metadata: orphan, showLoadingIndicator: false);

      expect(result, isA<PlayQueueError>());
      expect((result as PlayQueueError).error.toString(), contains('serverId'));
    });

    testWidgets('launchShuffledShow on a show fetches series episodes and shuffles', (tester) async {
      final ctx = await pumpContext(tester);
      // 50 episodes makes a coincident-original ordering effectively impossible.
      final originalIds = List.generate(50, (i) => 'ep$i');
      final fetched = originalIds.map(_ep).toList();
      final fakeClient = _RecordingJellyfinClient(seriesEpisodesResponse: fetched);
      final playback = PlaybackStateProvider();
      final navigated = <MediaItem>[];

      final launcher = JellyfinSequentialLauncher(
        context: ctx,
        clientForTesting: fakeClient,
        playbackStateForTesting: playback,
        navigateForTesting: (m) async => navigated.add(m),
      );

      final show = MediaItem(
        id: 'show-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.show,
        serverId: 'srv-jf',
        serverName: 'My Jellyfin',
      );

      final result = await launcher.launchShuffledShow(metadata: show, showLoadingIndicator: false);

      expect(result, isA<PlayQueueSuccess>());
      expect(fakeClient.fetchSeriesEpisodesCalls, ['show-1']);
      // Same set of episode ids, just reordered.
      final shuffledIds = playback.loadedItems.map((m) => m.id).toList();
      expect(shuffledIds.toSet(), originalIds.toSet());
      expect(shuffledIds.length, originalIds.length);
      expect(shuffledIds, isNot(equals(originalIds)));
      expect(playback.isShuffleActive, isTrue);
      expect(navigated.single.id, shuffledIds.first);
      // Server identity is propagated onto the queue items.
      expect(playback.loadedItems.first.serverId, 'srv-jf');
      expect(playback.loadedItems.first.serverName, 'My Jellyfin');
    });

    testWidgets('launchShuffledShow on a season uses parentId as series anchor', (tester) async {
      final ctx = await pumpContext(tester);
      final fakeClient = _RecordingJellyfinClient(seriesEpisodesResponse: [_ep('a'), _ep('b')]);
      final playback = PlaybackStateProvider();

      final launcher = JellyfinSequentialLauncher(
        context: ctx,
        clientForTesting: fakeClient,
        playbackStateForTesting: playback,
        navigateForTesting: (_) async {},
      );

      final season = MediaItem(
        id: 'season-2',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.season,
        serverId: 'srv-jf',
        parentId: 'show-7',
      );

      final result = await launcher.launchShuffledShow(metadata: season, showLoadingIndicator: false);

      expect(result, isA<PlayQueueSuccess>());
      expect(fakeClient.fetchSeriesEpisodesCalls, ['show-7']);
    });

    testWidgets('launchShuffledShow returns PlayQueueEmpty when series has no episodes', (tester) async {
      final ctx = await pumpContext(tester);
      final fakeClient = _RecordingJellyfinClient(seriesEpisodesResponse: const []);
      final playback = PlaybackStateProvider();
      var didNavigate = false;

      final launcher = JellyfinSequentialLauncher(
        context: ctx,
        clientForTesting: fakeClient,
        playbackStateForTesting: playback,
        navigateForTesting: (_) async {
          didNavigate = true;
        },
      );

      final show = MediaItem(
        id: 'show-empty',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.show,
        serverId: 'srv-jf',
      );

      final result = await launcher.launchShuffledShow(metadata: show, showLoadingIndicator: false);

      expect(result, isA<PlayQueueEmpty>());
      expect(playback.isQueueActive, isFalse);
      expect(didNavigate, isFalse);
    });

    testWidgets('empty fetch returns PlayQueueEmpty without seeding queue', (tester) async {
      final ctx = await pumpContext(tester);
      final fakeClient = _RecordingJellyfinClient(playableDescendantsResponse: const []);
      final playback = PlaybackStateProvider();
      var didNavigate = false;

      final launcher = JellyfinSequentialLauncher(
        context: ctx,
        clientForTesting: fakeClient,
        playbackStateForTesting: playback,
        navigateForTesting: (_) async {
          didNavigate = true;
        },
      );

      final collection = MediaItem(
        id: 'col-empty',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.collection,
        serverId: 'srv-jf',
      );

      final result = await launcher.launchFromCollectionOrPlaylist(
        item: collection,
        shuffle: false,
        showLoadingIndicator: false,
      );

      expect(result, isA<PlayQueueEmpty>());
      expect(playback.isQueueActive, isFalse);
      expect(didNavigate, isFalse);
    });
  });
}
