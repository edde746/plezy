import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/play_queue_launcher.dart';
import 'package:plezy/services/plex_client.dart';

// NOTE on coverage scope:
// `PlayQueueLauncher` is almost entirely network/UI glue:
//   - every public method calls into [PlexClient.createPlayQueue] or
//     [PlexClient.createShowPlayQueue] (network),
//   - then setups [PlaybackStateProvider] (Provider),
//   - then calls [navigateToVideoPlayer] (Navigator + DownloadProvider +
//     SettingsService singleton + Provider).
//
// Without re-implementing that entire dependency tree, the only meaningful
// unit-testable surface is:
//   - The `PlayQueueResult` sealed hierarchy (constructor + identity).
//   - `launchShuffledShow` short-circuits BEFORE any network call when the
//     metadata is not a show or season — that's a pure pre-flight branch.
//   - `launchFromCollectionOrPlaylist` short-circuits when the input is
//     neither a `PlexMetadata` nor a `PlexPlaylist`.
//
// Everything else (success/empty-queue/error paths) requires a full
// PlexClient fake + a Provider tree + a real Navigator. Skipped.

class _StubPlexClient implements PlexClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // PlayQueueResult sealed hierarchy
  // ============================================================

  group('PlayQueueResult', () {
    test('PlayQueueSuccess is a const, identity-comparable singleton', () {
      const a = PlayQueueSuccess();
      const b = PlayQueueSuccess();
      expect(identical(a, b), isTrue);
      expect(a, isA<PlayQueueResult>());
    });

    test('PlayQueueEmpty is a const, identity-comparable singleton', () {
      const a = PlayQueueEmpty();
      const b = PlayQueueEmpty();
      expect(identical(a, b), isTrue);
      expect(a, isA<PlayQueueResult>());
    });

    test('PlayQueueError carries the wrapped error', () {
      final error = StateError('boom');
      final result = PlayQueueError(error);
      expect(result.error, same(error));
      expect(result, isA<PlayQueueResult>());
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
        metadata: MediaItem(id: 'rk1', backend: MediaBackend.plex, kind: MediaKind.movie),
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

  // ============================================================
  // Constructor
  // ============================================================

  group('constructor', () {
    testWidgets('stores all wired arguments', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      );

      final client = _StubPlexClient();
      final launcher = PlexPlayQueueLauncher(
        context: capturedContext,
        client: client,
        serverId: 'srv-A',
        serverName: 'Plex',
      );

      expect(launcher.context, capturedContext);
      expect(identical(launcher.client, client), isTrue);
      expect(launcher.serverId, 'srv-A');
      expect(launcher.serverName, 'Plex');
    });
  });
}
