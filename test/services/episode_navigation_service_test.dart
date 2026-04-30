import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/play_queue.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/services/data_aggregation_service.dart';
import 'package:plezy/services/episode_navigation_service.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:provider/provider.dart';

// NOTE on coverage scope:
// `EpisodeNavigationService` has two methods:
//
//   1. `loadAdjacentEpisodes` — pure-ish: reads PlaybackStateProvider, asks for
//      next/prev episode, wraps the result. The interesting branch is the
//      "no queue active" short-circuit, which we exercise without any client
//      or network because PlaybackStateProvider can be constructed bare.
//
//   2. `navigateToEpisode` — performs full navigation through
//      [navigateToVideoPlayer], which depends on a Navigator, a
//      DownloadProvider, a MultiServerProvider, and the [SettingsService]
//      singleton. Skipped: not unit-testable without recreating the entire
//      app shell.
//
// We also cover the [AdjacentEpisodes] data class invariants since that's
// the public surface callers depend on.

MediaItem _meta(String id, {String? title}) =>
    MediaItem(id: id, backend: MediaBackend.plex, kind: MediaKind.episode, title: title ?? 'Episode $id');

MediaItem _jfEpisode(String id, {required String seriesId, String serverId = 'srv-jf'}) => MediaItem(
  id: id,
  backend: MediaBackend.jellyfin,
  kind: MediaKind.episode,
  title: 'Episode $id',
  serverId: serverId,
  grandparentId: seriesId,
);

/// MultiServerManager subclass that returns a pre-supplied client without
/// going through the production add-connection flow. The base class doesn't
/// expose a way to inject clients into its private `_clients` map, so we
/// override the lookup directly.
class _StubManager extends MultiServerManager {
  _StubManager(this._client);
  final MediaServerClient? _client;
  @override
  MediaServerClient? getClient(String _) => _client;
}

/// Recording client whose `fetchClientSideEpisodeQueue` is observable —
/// callers can assert it was (or wasn't) hit.
class _RecordingClient implements MediaServerClient {
  _RecordingClient({required this.seriesEpisodes});
  final List<MediaItem> seriesEpisodes;
  final List<String> seriesQueueCalls = [];

  @override
  Future<List<MediaItem>?> fetchClientSideEpisodeQueue(String seriesId) async {
    seriesQueueCalls.add(seriesId);
    return seriesEpisodes;
  }

  @override
  MediaBackend get backend => MediaBackend.jellyfin;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ProbeWidget extends StatefulWidget {
  const _ProbeWidget({required this.metadata, required this.onResult});

  final MediaItem metadata;
  final void Function(AdjacentEpisodes) onResult;

  @override
  State<_ProbeWidget> createState() => _ProbeWidgetState();
}

class _ProbeWidgetState extends State<_ProbeWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final svc = EpisodeNavigationService();
      final result = await svc.loadAdjacentEpisodes(context: context, metadata: widget.metadata);
      widget.onResult(result);
    });
  }

  @override
  Widget build(BuildContext context) =>
      const Directionality(textDirection: TextDirection.ltr, child: SizedBox.shrink());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ===========================================================
  // AdjacentEpisodes data class
  // ===========================================================

  group('AdjacentEpisodes', () {
    test('default constructor reports no neighbours', () {
      final ae = AdjacentEpisodes();
      expect(ae.next, isNull);
      expect(ae.previous, isNull);
      expect(ae.hasNext, isFalse);
      expect(ae.hasPrevious, isFalse);
    });

    test('next/previous flags reflect non-null fields', () {
      final ae = AdjacentEpisodes(next: _meta('n'), previous: _meta('p'));
      expect(ae.hasNext, isTrue);
      expect(ae.hasPrevious, isTrue);
      expect(ae.next!.id, 'n');
      expect(ae.previous!.id, 'p');
    });

    test('only-next variant', () {
      final ae = AdjacentEpisodes(next: _meta('n'));
      expect(ae.hasNext, isTrue);
      expect(ae.hasPrevious, isFalse);
    });

    test('only-previous variant', () {
      final ae = AdjacentEpisodes(previous: _meta('p'));
      expect(ae.hasNext, isFalse);
      expect(ae.hasPrevious, isTrue);
    });
  });

  // ===========================================================
  // loadAdjacentEpisodes: short-circuit without an active queue
  // ===========================================================

  group('loadAdjacentEpisodes', () {
    testWidgets('returns empty AdjacentEpisodes when no play queue is active', (tester) async {
      // Bare provider — no setPlaybackFromPlayQueue() call → isQueueActive = false.
      final playback = PlaybackStateProvider();
      addTearDown(playback.dispose);

      AdjacentEpisodes? result;
      await tester.pumpWidget(
        ChangeNotifierProvider<PlaybackStateProvider>.value(
          value: playback,
          child: _ProbeWidget(metadata: _meta('42'), onResult: (r) => result = r),
        ),
      );
      // Drain the post-frame callback and the awaited service call.
      await tester.pump();
      await tester.pump();

      expect(result, isNotNull);
      expect(result!.hasNext, isFalse);
      expect(result!.hasPrevious, isFalse);
    });

    testWidgets('catches downstream exceptions and returns empty AdjacentEpisodes', (tester) async {
      // PlaybackStateProvider not provided → context.read throws. The service
      // wraps the entire body in try/catch and returns AdjacentEpisodes() so
      // the UI never crashes when the queue subsystem is unavailable.
      AdjacentEpisodes? result;
      await tester.pumpWidget(_ProbeWidget(metadata: _meta('42'), onResult: (r) => result = r));
      await tester.pump();
      await tester.pump();

      expect(result, isNotNull);
      expect(result!.hasNext, isFalse);
      expect(result!.hasPrevious, isFalse);
    });

    testWidgets('preserves an active playlist/collection queue against series rebuild', (tester) async {
      // Reproduces the bug where playing an episode from a Jellyfin playlist
      // had next/prev walking the show's episodes instead of the playlist —
      // [_ensureLocalEpisodeQueue] used to overwrite the launcher-set queue
      // unconditionally. The guard now bails out when contextKey is set to
      // anything other than the seriesId.
      final ep1 = _jfEpisode('ep1', seriesId: 'series-A');
      final ep2 = _jfEpisode('ep2', seriesId: 'series-B');
      final ep3 = _jfEpisode('ep3', seriesId: 'series-A');

      final playback = PlaybackStateProvider();
      addTearDown(playback.dispose);
      playback.setPlaybackFromLocalQueue(
        LocalPlayQueue(
          id: 'jellyfin:playlist-X',
          items: [ep1, ep2, ep3],
          currentIndex: 1,
          backendId: MediaBackend.jellyfin.id,
        ),
        contextKey: 'playlist-X',
      );

      // Stub client returns fake series episodes that *include* ep2 — without
      // the guard, the service would replace the playlist queue with this
      // list and prev/next would point at sibling-X / sibling-Y.
      final client = _RecordingClient(
        seriesEpisodes: [
          _jfEpisode('sibling-X', seriesId: 'series-B'),
          ep2,
          _jfEpisode('sibling-Y', seriesId: 'series-B'),
        ],
      );
      final manager = _StubManager(client);
      final aggregation = DataAggregationService(manager);
      final serverProvider = MultiServerProvider(manager, aggregation);
      addTearDown(serverProvider.dispose);

      AdjacentEpisodes? result;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<PlaybackStateProvider>.value(value: playback),
            ChangeNotifierProvider<MultiServerProvider>.value(value: serverProvider),
          ],
          child: _ProbeWidget(metadata: ep2, onResult: (r) => result = r),
        ),
      );
      await tester.pump();
      await tester.pump();

      // Guard short-circuits before the wire fetch.
      expect(client.seriesQueueCalls, isEmpty);
      // Queue items unchanged — still the playlist's three episodes.
      expect(playback.loadedItems.map((e) => e.id), ['ep1', 'ep2', 'ep3']);
      // Prev/next walk the playlist, not the series.
      expect(result, isNotNull);
      expect(result!.next?.id, 'ep3');
      expect(result!.previous?.id, 'ep1');
    });
  });
}
