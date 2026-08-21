import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plezy/exceptions/media_server_exceptions.dart';
import 'package:plezy/media/ids.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/library_query.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_playlist.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:plezy/services/jellyfin_sequential_launcher.dart';
import 'package:plezy/services/media_list_playback_launcher.dart';
import 'package:plezy/services/playlist_items_loader.dart';
import 'package:plezy/utils/media_server_http_client.dart';
import 'package:plezy/widgets/dialog_action_button.dart';
import 'package:plezy/i18n/strings.g.dart';

import '../test_helpers/paged_fakes.dart';
import '../test_helpers/media_items.dart';

/// Recording fake that satisfies [JellyfinClient] via `implements` +
/// `noSuchMethod`. The launcher only needs the
/// [MediaServerClient.fetchPlayableDescendants] /
/// [MediaServerClient.fetchClientSideEpisodeQueue] surface, but we
/// `implements JellyfinClient` so existing tests stay backend-tagged.
class _RecordingJellyfinClient implements JellyfinClient {
  final List<MediaItem> playableDescendantsResponse;
  final List<MediaItem> playableFolderDescendantsResponse;
  final List<MediaItem> seriesEpisodesResponse;
  final List<MediaItem> playlistItemsResponse;
  final Completer<void>? playableDescendantsGate;
  final Completer<void>? playableFolderDescendantsGate;
  final Completer<void>? seriesEpisodesGate;
  final Completer<void>? playlistPageGate;
  final List<AbortController?> playableDescendantAborts = [];
  final List<AbortController?> playableFolderAborts = [];
  final List<AbortController?> seriesEpisodeAborts = [];
  final List<AbortController?> playlistPageAborts = [];
  final List<String> fetchPlayableDescendantsCalls = [];
  final List<String> fetchPlayableFolderDescendantsCalls = [];
  final List<String> fetchSeriesEpisodesCalls = [];
  final List<({String id, int offset, int limit})> fetchPlaylistItemsCalls = [];

  _RecordingJellyfinClient({
    this.playableDescendantsResponse = const [],
    this.playableFolderDescendantsResponse = const [],
    this.seriesEpisodesResponse = const [],
    this.playlistItemsResponse = const [],
    this.playableDescendantsGate,
    this.playableFolderDescendantsGate,
    this.seriesEpisodesGate,
    this.playlistPageGate,
  });

  @override
  Future<List<MediaItem>> fetchPlayableDescendants(String parentId, {AbortController? abort}) async {
    fetchPlayableDescendantsCalls.add(parentId);
    playableDescendantAborts.add(abort);
    await _waitForGate(playableDescendantsGate, abort);
    return playableDescendantsResponse;
  }

  @override
  Future<List<MediaItem>> fetchPlayableFolderDescendants(String parentId, {AbortController? abort}) async {
    fetchPlayableFolderDescendantsCalls.add(parentId);
    playableFolderAborts.add(abort);
    await _waitForGate(playableFolderDescendantsGate, abort);
    return playableFolderDescendantsResponse;
  }

  @override
  Future<List<MediaItem>?> fetchClientSideEpisodeQueue(String seriesId, {AbortController? abort}) async {
    fetchSeriesEpisodesCalls.add(seriesId);
    seriesEpisodeAborts.add(abort);
    await _waitForGate(seriesEpisodesGate, abort);
    return seriesEpisodesResponse;
  }

  @override
  Future<List<MediaItem>> fetchPlaylistItems(String id, {int offset = 0, int limit = 100}) async {
    final page = await fetchPlaylistPage(id, start: offset, size: limit);
    return page.items;
  }

  @override
  Future<LibraryPage<MediaItem>> fetchPlaylistPage(String id, {int? start, int? size, AbortController? abort}) async {
    final offset = start ?? 0;
    final limit = size ?? fakeMediaPageSize;
    fetchPlaylistItemsCalls.add((id: id, offset: offset, limit: limit));
    playlistPageAborts.add(abort);
    await _waitForGate(playlistPageGate, abort);
    return fakeLibraryPage(playlistItemsResponse, start: start, size: size);
  }

  Future<void> _waitForGate(Completer<void>? gate, AbortController? abort) async {
    if (gate == null) return;
    if (abort == null) {
      await gate.future;
      return;
    }
    await Future.any<void>([gate.future, abort.trigger]);
    abort.throwIfAborted();
  }

  @override
  MediaBackend get backend => MediaBackend.jellyfin;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Playlist fetch that fails before the loading dialog's first frame,
/// exercising `executeWithLoading`'s early-failure path.
class _ThrowingJellyfinClient extends _RecordingJellyfinClient {
  @override
  Future<LibraryPage<MediaItem>> fetchPlaylistPage(String id, {int? start, int? size, AbortController? abort}) async {
    fetchPlaylistItemsCalls.add((id: id, offset: start ?? 0, limit: size ?? fakeMediaPageSize));
    throw Exception('connection refused');
  }
}

MediaItem _ep(String id, {ServerId? serverId}) => testMediaItem(
  id: id,
  backend: MediaBackend.jellyfin,
  kind: MediaKind.episode,
  title: 'Episode $id',
  serverId: serverId ?? ServerId('srv-jf'),
);

MediaItem _movie(String id, {ServerId? serverId}) => testMediaItem(
  id: id,
  backend: MediaBackend.jellyfin,
  kind: MediaKind.movie,
  title: 'Movie $id',
  serverId: serverId ?? ServerId('srv-jf'),
);

MediaItem _clip(String id, {ServerId? serverId}) => testMediaItem(
  id: id,
  backend: MediaBackend.jellyfin,
  kind: MediaKind.clip,
  title: 'Video $id',
  serverId: serverId ?? ServerId('srv-jf'),
);

MediaItem _track(String id, {ServerId? serverId}) => testMediaItem(
  id: id,
  backend: MediaBackend.jellyfin,
  kind: MediaKind.track,
  title: 'Track $id',
  serverId: serverId ?? ServerId('srv-jf'),
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

      final orphan = testMediaItem(
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
        navigateForTesting: (m) async {
          expect(playback.isQueueActive, isTrue);
          expect(playback.loadedItems, orderedEquals(fetched));
          expect(playback.currentQueueItem, same(fetched.first));
          navigated.add(m);
        },
      );

      final collection = testMediaItem(
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
      // Enough items to span 2 default playlist pages — the loop must keep paging until
      // the server returns a short page.
      final fetched = List.generate(playlistItemsPageSize + 50, (i) => _ep('p$i'));
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
      expect(playback.loadedItems.length, playlistItemsPageSize + 50);
      expect(fakeClient.fetchPlaylistItemsCalls, hasLength(2));
      expect(fakeClient.fetchPlaylistItemsCalls.first.offset, 0);
      expect(fakeClient.fetchPlaylistItemsCalls[1].offset, playlistItemsPageSize);
    });

    testWidgets('collection containing a Series entry only seeds playable descendants', (tester) async {
      // Anchor: the recursive expansion is what skips the unplayable Series
      // container. If a future change reverts to fetchChildren the test
      // fails because a Series row would leak into the queue.
      final ctx = await pumpContext(tester);
      final movie = testMediaItem(
        id: 'movie-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.movie,
        serverId: 'srv-jf',
      );
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

      final collection = testMediaItem(
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

      final collection = testMediaItem(
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

      final collection = testMediaItem(
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

      final collection = testMediaItem(
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

    testWidgets('folder path seeds a video-only local queue', (tester) async {
      final ctx = await pumpContext(tester);
      final fakeClient = _RecordingJellyfinClient(
        playableFolderDescendantsResponse: [_track('song'), _movie('movie', serverId: null), _clip('video')],
      );
      final playback = PlaybackStateProvider();
      final navigated = <MediaItem>[];

      final launcher = JellyfinSequentialLauncher(
        context: ctx,
        clientForTesting: fakeClient,
        playbackStateForTesting: playback,
        navigateForTesting: (m) async => navigated.add(m),
      );

      final folder = testMediaItem(
        id: 'folder-1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.unknown,
        title: 'Folder',
        serverId: 'srv-jf',
        serverName: 'Home Jellyfin',
        libraryId: 'lib-1',
        libraryTitle: 'Videos',
      );

      final result = await launcher.launchFromFolder(folder: folder, shuffle: false, showLoadingIndicator: false);

      expect(result, isA<PlayQueueSuccess>());
      expect(fakeClient.fetchPlayableFolderDescendantsCalls, ['folder-1']);
      expect(fakeClient.fetchPlayableDescendantsCalls, isEmpty);
      expect(playback.loadedItems.map((m) => m.id).toList(), ['movie', 'video']);
      expect(playback.loadedItems.any((m) => m.kind == MediaKind.track), isFalse);
      expect(playback.loadedItems.first.serverId, 'srv-jf');
      expect(playback.loadedItems.first.libraryId, 'lib-1');
      expect(playback.isQueueActive, isTrue);
      expect(playback.isShuffleActive, isFalse);
      expect(navigated.single.id, 'movie');
    });

    testWidgets('folder shuffle reorders the video queue', (tester) async {
      final ctx = await pumpContext(tester);
      final originalIds = List.generate(50, (i) => 'v$i');
      final fakeClient = _RecordingJellyfinClient(playableFolderDescendantsResponse: originalIds.map(_clip).toList());
      final playback = PlaybackStateProvider();

      final launcher = JellyfinSequentialLauncher(
        context: ctx,
        clientForTesting: fakeClient,
        playbackStateForTesting: playback,
        navigateForTesting: (_) async {},
      );

      final folder = testMediaItem(
        id: 'folder-shuffle',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.unknown,
        serverId: 'srv-jf',
      );

      final result = await launcher.launchFromFolder(folder: folder, shuffle: true, showLoadingIndicator: false);

      expect(result, isA<PlayQueueSuccess>());
      final shuffledIds = playback.loadedItems.map((m) => m.id).toList();
      expect(shuffledIds.toSet(), originalIds.toSet());
      expect(shuffledIds.length, originalIds.length);
      expect(shuffledIds, isNot(equals(originalIds)));
      expect(playback.isShuffleActive, isTrue);
    });

    testWidgets('music-only folder returns PlayQueueEmpty', (tester) async {
      final ctx = await pumpContext(tester);
      final fakeClient = _RecordingJellyfinClient(playableFolderDescendantsResponse: [_track('a'), _track('b')]);
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

      final folder = testMediaItem(
        id: 'music-folder',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.unknown,
        serverId: 'srv-jf',
      );

      final result = await launcher.launchFromFolder(folder: folder, shuffle: false, showLoadingIndicator: false);

      expect(result, isA<PlayQueueEmpty>());
      expect(playback.isQueueActive, isFalse);
      expect(didNavigate, isFalse);
    });

    testWidgets('launchShuffledShow rejects non-show/season kinds', (tester) async {
      final ctx = await pumpContext(tester);
      final launcher = JellyfinSequentialLauncher(context: ctx);

      final movie = testMediaItem(id: 'm1', backend: MediaBackend.jellyfin, kind: MediaKind.movie, serverId: 'srv-jf');

      final result = await launcher.launchShuffledShow(metadata: movie, showLoadingIndicator: false);

      expect(result, isA<PlayQueueError>());
      expect((result as PlayQueueError).error.toString(), contains('shows and seasons'));
    });

    testWidgets('launchShuffledShow rejects season missing parentId', (tester) async {
      final ctx = await pumpContext(tester);
      final launcher = JellyfinSequentialLauncher(context: ctx);

      final season = testMediaItem(
        id: 's1',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.season,
        serverId: 'srv-jf',
      );

      final result = await launcher.launchShuffledShow(metadata: season, showLoadingIndicator: false);

      expect(result, isA<PlayQueueError>());
      expect((result as PlayQueueError).error.toString(), contains('parentId'));
    });

    testWidgets('launchShuffledShow rejects items missing serverId', (tester) async {
      final ctx = await pumpContext(tester);
      final launcher = JellyfinSequentialLauncher(context: ctx);

      final orphan = testMediaItem(id: 'show-orphan', backend: MediaBackend.jellyfin, kind: MediaKind.show);

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

      final show = testMediaItem(
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

      final season = testMediaItem(
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

      final show = testMediaItem(
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

      final collection = testMediaItem(
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

    testWidgets('fetch starts before the loading dialog first frame renders', (tester) async {
      final ctx = await pumpContext(tester);
      final gate = Completer<void>();
      final fakeClient = _RecordingJellyfinClient(playlistItemsResponse: [_ep('a'), _ep('b')], playlistPageGate: gate);
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
      const playlist = MediaPlaylist(
        id: 'pl-early-fetch',
        backend: MediaBackend.jellyfin,
        title: 'Early fetch',
        playlistType: 'video',
        serverId: 'srv-jf',
      );

      final resultFuture = launcher.launchFromCollectionOrPlaylist(item: playlist, shuffle: false);

      // No frame has been pumped, so the dialog has not built yet — but the
      // network operation must already be in flight.
      expect(fakeClient.fetchPlaylistItemsCalls, hasLength(1));
      expect(find.byType(DialogActionButton), findsNothing);

      gate.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(await resultFuture, isA<PlayQueueSuccess>());
      expect(didNavigate, isTrue);
      expect(find.byType(DialogActionButton), findsNothing);
    });

    testWidgets('operation failure before the dialog first frame still dismisses the dialog', (tester) async {
      final ctx = await pumpContext(tester);
      final fakeClient = _ThrowingJellyfinClient();
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
      const playlist = MediaPlaylist(
        id: 'pl-early-error',
        backend: MediaBackend.jellyfin,
        title: 'Early error',
        playlistType: 'video',
        serverId: 'srv-jf',
      );

      final resultFuture = launcher.launchFromCollectionOrPlaylist(item: playlist, shuffle: false);
      // The failure lands before the dialog's first frame; it must not
      // surface as an unhandled error, and the dialog must still come down.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(await resultFuture, isA<PlayQueueError>());
      expect(didNavigate, isFalse);
      expect(playback.isQueueActive, isFalse);
      expect(find.byType(DialogActionButton), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('dialog Cancel aborts playlist launch idempotently without queue or snackbar', (tester) async {
      final ctx = await pumpContext(tester);
      final gate = Completer<void>();
      final fakeClient = _RecordingJellyfinClient(playlistItemsResponse: [_ep('a'), _ep('b')], playlistPageGate: gate);
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
      const playlist = MediaPlaylist(
        id: 'pl-cancel',
        backend: MediaBackend.jellyfin,
        title: 'Cancel me',
        playlistType: 'video',
        serverId: 'srv-jf',
      );

      final resultFuture = launcher.launchFromCollectionOrPlaylist(item: playlist, shuffle: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(fakeClient.fetchPlaylistItemsCalls, hasLength(1));
      expect(fakeClient.playlistPageAborts.single, isNotNull);
      expect(find.text(t.common.cancel), findsOneWidget);
      final cancelButton = tester.widget<DialogActionButton>(find.byType(DialogActionButton));
      cancelButton.onPressed!();
      cancelButton.onPressed!();
      await tester.pump();
      expect(await resultFuture, isA<PlayQueueCancelled>());
      expect(fakeClient.playlistPageAborts.single!.isAborted, isTrue);
      expect(fakeClient.fetchPlaylistItemsCalls, hasLength(1));
      expect(playback.isQueueActive, isFalse);
      expect(didNavigate, isFalse);
      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('disposing the initiating navigator aborts its active playlist launch', (tester) async {
      late BuildContext initiatingContext;
      late StateSetter replaceProfileSubtree;
      var showProfileSubtree = true;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              replaceProfileSubtree = setState;
              if (!showProfileSubtree) {
                return const Scaffold(body: Text('replacement profile', key: Key('replacement-profile')));
              }
              return Navigator(
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                    body: Builder(
                      builder: (context) {
                        initiatingContext = context;
                        return const Text('initiating profile');
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      final gate = Completer<void>();
      final fakeClient = _RecordingJellyfinClient(playlistItemsResponse: [_ep('a')], playlistPageGate: gate);
      final playback = PlaybackStateProvider();
      var didNavigate = false;
      final launcher = JellyfinSequentialLauncher(
        context: initiatingContext,
        clientForTesting: fakeClient,
        playbackStateForTesting: playback,
        navigateForTesting: (_) async {
          didNavigate = true;
        },
      );
      const playlist = MediaPlaylist(
        id: 'pl-teardown',
        backend: MediaBackend.jellyfin,
        title: 'Teardown',
        playlistType: 'video',
        serverId: 'srv-jf',
      );

      final resultFuture = launcher.launchFromCollectionOrPlaylist(item: playlist, shuffle: false);
      await tester.pump();
      expect(fakeClient.fetchPlaylistItemsCalls, hasLength(1));

      replaceProfileSubtree(() => showProfileSubtree = false);
      await tester.pump();

      expect(await resultFuture, isA<PlayQueueCancelled>());
      expect(fakeClient.playlistPageAborts.single!.isAborted, isTrue);
      expect(fakeClient.fetchPlaylistItemsCalls, hasLength(1));
      expect(playback.isQueueActive, isFalse);
      expect(didNavigate, isFalse);
      expect(find.byKey(const Key('replacement-profile')), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('collection cancellation suppresses mapping and publication', (tester) async {
      final ctx = await pumpContext(tester);
      final fakeClient = _RecordingJellyfinClient(
        playableDescendantsResponse: [_ep('a')],
        playableDescendantsGate: Completer<void>(),
      );
      final playback = PlaybackStateProvider();
      final launcher = JellyfinSequentialLauncher(
        context: ctx,
        clientForTesting: fakeClient,
        playbackStateForTesting: playback,
        navigateForTesting: (_) async {},
      );
      final collection = testMediaItem(
        id: 'col-cancel',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.collection,
        serverId: 'srv-jf',
      );

      final resultFuture = launcher.launchFromCollectionOrPlaylist(
        item: collection,
        shuffle: true,
        showLoadingIndicator: false,
      );
      await tester.pump();
      fakeClient.playableDescendantAborts.single!.abort();

      expect(await resultFuture, isA<PlayQueueCancelled>());
      expect(fakeClient.fetchPlayableDescendantsCalls, ['col-cancel']);
      expect(playback.isQueueActive, isFalse);
    });

    testWidgets('folder cancellation suppresses filtering and publication', (tester) async {
      final ctx = await pumpContext(tester);
      final fakeClient = _RecordingJellyfinClient(
        playableFolderDescendantsResponse: [_clip('a')],
        playableFolderDescendantsGate: Completer<void>(),
      );
      final playback = PlaybackStateProvider();
      final launcher = JellyfinSequentialLauncher(
        context: ctx,
        clientForTesting: fakeClient,
        playbackStateForTesting: playback,
        navigateForTesting: (_) async {},
      );
      final folder = testMediaItem(
        id: 'folder-cancel',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.unknown,
        serverId: 'srv-jf',
      );

      final resultFuture = launcher.launchFromFolder(folder: folder, shuffle: true, showLoadingIndicator: false);
      await tester.pump();
      fakeClient.playableFolderAborts.single!.abort();

      expect(await resultFuture, isA<PlayQueueCancelled>());
      expect(fakeClient.fetchPlayableFolderDescendantsCalls, ['folder-cancel']);
      expect(playback.isQueueActive, isFalse);
    });

    testWidgets('show cancellation suppresses shuffle and publication', (tester) async {
      final ctx = await pumpContext(tester);
      final fakeClient = _RecordingJellyfinClient(
        seriesEpisodesResponse: [_ep('a')],
        seriesEpisodesGate: Completer<void>(),
      );
      final playback = PlaybackStateProvider();
      final launcher = JellyfinSequentialLauncher(
        context: ctx,
        clientForTesting: fakeClient,
        playbackStateForTesting: playback,
        navigateForTesting: (_) async {},
      );
      final show = testMediaItem(
        id: 'show-cancel',
        backend: MediaBackend.jellyfin,
        kind: MediaKind.show,
        serverId: 'srv-jf',
      );

      final resultFuture = launcher.launchShuffledShow(metadata: show, showLoadingIndicator: false);
      await tester.pump();
      fakeClient.seriesEpisodeAborts.single!.abort();

      expect(await resultFuture, isA<PlayQueueCancelled>());
      expect(fakeClient.fetchSeriesEpisodesCalls, ['show-cancel']);
      expect(playback.isQueueActive, isFalse);
    });
  });

  group('fetchAllPlaylistItems cancellation', () {
    test('aborts after a page await without returning a partial list or requesting page two', () async {
      final abort = AbortController();
      final fakeClient = _RecordingJellyfinClient(
        playlistItemsResponse: List.generate(playlistItemsPageSize + 1, (i) => _ep('p$i')),
        playlistPageGate: Completer<void>(),
      );

      final resultFuture = fetchAllPlaylistItems(fakeClient, 'pl-abort', abort: abort);
      expect(fakeClient.fetchPlaylistItemsCalls.map((call) => call.offset), [0]);
      abort.abort();

      await expectLater(
        resultFuture,
        throwsA(isA<MediaServerHttpException>().having((e) => e.isCancellation, 'isCancellation', isTrue)),
      );
      expect(fakeClient.fetchPlaylistItemsCalls.map((call) => call.offset), [0]);
    });

    test('null controller preserves two-page complete-list success', () async {
      final items = List.generate(playlistItemsPageSize + 1, (i) => _ep('p$i'));
      final fakeClient = _RecordingJellyfinClient(playlistItemsResponse: items);

      final result = await fetchAllPlaylistItems(fakeClient, 'pl-success');

      expect(result.map((item) => item.id), items.map((item) => item.id));
      expect(fakeClient.fetchPlaylistItemsCalls.map((call) => call.offset), [0, playlistItemsPageSize]);
      expect(fakeClient.playlistPageAborts, [null, null]);
    });
  });
}
