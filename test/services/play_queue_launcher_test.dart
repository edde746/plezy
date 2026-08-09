import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';

import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_playlist.dart';
import 'package:plezy/models/plex/play_queue_response.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/services/play_queue_launcher.dart';
import 'package:plezy/services/plex_client.dart';

import '../test_helpers/media_items.dart';

// Focused orchestration coverage lives here: the network response must be
// published to PlaybackStateProvider before navigation, and a navigation
// failure remains an owned PlayQueueError rather than a reported success.
// Jellyfin cancellation ownership is covered by
// jellyfin_sequential_launcher_test.dart.

class _StubPlexClient implements PlexClient {
  _StubPlexClient({this.response});

  final PlayQueueResponse? response;

  @override
  Future<PlayQueueResponse?> createPlayQueue({
    String? uri,
    int? playlistID,
    required String type,
    String? key,
    int shuffle = 0,
    int repeat = 0,
    int continuous = 0,
    String? librarySectionID,
    String? librarySectionTitle,
  }) async {
    return response;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<BuildContext> _pumpContext(WidgetTester tester) async {
  late BuildContext capturedContext;
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

PlayQueueResponse _queueWith(MediaItem item) {
  return PlayQueueResponse(
    playQueueID: 73,
    playQueueSelectedItemID: 41,
    playQueueShuffled: false,
    playQueueTotalCount: 1,
    playQueueVersion: 1,
    items: [item],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // PlayQueueResult sealed hierarchy
  // ============================================================

  group('PlayQueueResult', () {
    test('PlayQueueCancelled is a distinct re-exported result', () {
      const PlayQueueResult result = PlayQueueCancelled();
      expect(result, isA<PlayQueueCancelled>());
      expect(result, isNot(isA<PlayQueueError>()));
    });
  });

  // ============================================================
  // Pre-flight branches that don't touch the network
  // ============================================================

  group('launchShuffledShow pre-flight guard', () {
    testWidgets('returns PlayQueueError when metadata is not a show or season', (tester) async {
      // Build a launcher inside an active Element so its `context.mounted`
      // returns true. We don't need a Provider tree because the guard runs
      // before any context.read.
      late BuildContext capturedContext;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      );

      final launcher = PlexPlayQueueLauncher(context: capturedContext, client: _StubPlexClient());
      final result = await launcher.launchShuffledShow(
        // movie is not show / season.
        metadata: testMediaItem(id: 'rk1', backend: MediaBackend.plex, kind: MediaKind.movie),
        showLoadingIndicator: false,
      );

      expect(result, isA<PlayQueueError>());
      final error = (result as PlayQueueError).error;
      expect(error.toString(), contains('shows and seasons'));
    });
  });

  group('launchFromCollectionOrPlaylist input guard', () {
    testWidgets('returns PlayQueueError for non-collection/playlist input', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      );

      final launcher = PlexPlayQueueLauncher(context: capturedContext, client: _StubPlexClient());
      // Passing a String — neither a PlexMetadata nor a PlexPlaylist.
      final result = await launcher.launchFromCollectionOrPlaylist(item: 'not-a-real-item', shuffle: false);

      expect(result, isA<PlayQueueError>());
      final error = (result as PlayQueueError).error;
      expect(error.toString(), contains('collection or playlist'));
    });
  });

  group('queue application ownership', () {
    testWidgets('publishes the Plex queue before navigating to its selected item', (tester) async {
      final context = await _pumpContext(tester);
      final item = const MediaItem.plex(id: 'movie-1', kind: MediaKind.movie, title: 'Movie', playQueueItemId: 41);
      final playbackState = PlaybackStateProvider();
      final navigated = <MediaItem>[];
      final launcher = PlexPlayQueueLauncher(
        context: context,
        client: _StubPlexClient(response: _queueWith(item)),
        playbackStateForTesting: playbackState,
        navigateForTesting: (selected) async {
          expect(playbackState.isQueueActive, isTrue);
          expect(playbackState.playQueueId, 73);
          expect(playbackState.currentQueueItem, same(item));
          expect(playbackState.loadedItems.single, same(item));
          navigated.add(selected);
        },
      );
      const playlist = MediaPlaylist(id: '12', backend: MediaBackend.plex, title: 'Playlist', playlistType: 'video');

      final result = await launcher.launchFromCollectionOrPlaylist(
        item: playlist,
        shuffle: false,
        showLoadingIndicator: false,
      );

      expect(result, isA<PlayQueueSuccess>());
      expect(navigated, hasLength(1));
      expect(navigated.single, same(item));
    });

    testWidgets('navigation failure is returned as PlayQueueError, not success', (tester) async {
      final context = await _pumpContext(tester);
      final item = const MediaItem.plex(id: 'movie-1', kind: MediaKind.movie, playQueueItemId: 41);
      final failure = StateError('navigation failed');
      final playbackState = PlaybackStateProvider();
      final launcher = PlexPlayQueueLauncher(
        context: context,
        client: _StubPlexClient(response: _queueWith(item)),
        playbackStateForTesting: playbackState,
        navigateForTesting: (_) async => throw failure,
      );
      const playlist = MediaPlaylist(id: '12', backend: MediaBackend.plex, title: 'Playlist', playlistType: 'video');

      final result = await launcher.launchFromCollectionOrPlaylist(
        item: playlist,
        shuffle: false,
        showLoadingIndicator: false,
      );

      expect(result, isA<PlayQueueError>());
      expect((result as PlayQueueError).error, same(failure));
      expect(playbackState.isQueueActive, isTrue);
      expect(playbackState.currentQueueItem, same(item));
    });
  });
}
