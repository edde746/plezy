import 'package:flutter/material.dart';
import 'package:plezy/media/ids.dart';
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
import '../test_helpers/media_items.dart';

MediaItem _meta(String id, {String? title}) =>
    testMediaItem(id: id, backend: MediaBackend.plex, kind: MediaKind.episode, title: title ?? 'Episode $id');

MediaItem _jfEpisode(String id, {required String seriesId, ServerId? serverId}) => testMediaItem(
  id: id,
  backend: MediaBackend.jellyfin,
  kind: MediaKind.episode,
  title: 'Episode $id',
  serverId: serverId ?? ServerId('srv-jf'),
  grandparentId: seriesId,
);

MediaItem _plexEpisode(String id, {required String seriesId, int? viewCount}) => testMediaItem(
  id: id,
  backend: MediaBackend.plex,
  kind: MediaKind.episode,
  title: 'Episode $id',
  serverId: 'srv-plex',
  grandparentId: seriesId,
  viewCount: viewCount,
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
  _RecordingClient({required this.seriesEpisodes, this.clientBackend = MediaBackend.jellyfin, this.fetchError});
  final List<MediaItem> seriesEpisodes;
  final MediaBackend clientBackend;
  final Object? fetchError;
  final List<String> seriesQueueCalls = [];

  @override
  Future<List<MediaItem>?> fetchClientSideEpisodeQueue(String seriesId) async {
    seriesQueueCalls.add(seriesId);
    final error = fetchError;
    if (error != null) throw error;
    return seriesEpisodes;
  }

  @override
  MediaBackend get backend => clientBackend;

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

  group('loadAdjacentEpisodes', () {
    testWidgets('returns unavailable when no play queue is active for non-series media', (tester) async {
      final playback = PlaybackStateProvider();
      addTearDown(playback.dispose);
      final manager = _StubManager(null);
      final serverProvider = MultiServerProvider(manager, DataAggregationService(manager));
      addTearDown(serverProvider.dispose);

      AdjacentEpisodes? result;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<PlaybackStateProvider>.value(value: playback),
            ChangeNotifierProvider<MultiServerProvider>.value(value: serverProvider),
          ],
          child: _ProbeWidget(metadata: _meta('42'), onResult: (r) => result = r),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(result, isNotNull);
      expect(result!.nextStatus, QueueNavigationStatus.unavailable);
      expect(result!.hasNext, isFalse);
      expect(result!.hasPrevious, isFalse);
      expect(playback.isQueueActive, isFalse);
    });

    testWidgets('catches downstream exceptions and reports failed adjacency', (tester) async {
      // Required providers are absent, so context.read throws. The service
      // converts the exception into an explicit failed result.
      AdjacentEpisodes? result;
      await tester.pumpWidget(_ProbeWidget(metadata: _meta('42'), onResult: (r) => result = r));
      await tester.pump();
      await tester.pump();

      expect(result, isNotNull);
      expect(result!.hasNext, isFalse);
      expect(result!.hasPrevious, isFalse);
      expect(result!.nextStatus, QueueNavigationStatus.failed);
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

    testWidgets('builds a Plex local fallback queue with watched episodes', (tester) async {
      final ep1 = _plexEpisode('ep1', seriesId: 'series-P', viewCount: 1);
      final ep2 = _plexEpisode('ep2', seriesId: 'series-P', viewCount: 1);
      final ep3 = _plexEpisode('ep3', seriesId: 'series-P', viewCount: 1);
      final playback = PlaybackStateProvider();
      addTearDown(playback.dispose);
      final client = _RecordingClient(seriesEpisodes: [ep1, ep2, ep3], clientBackend: MediaBackend.plex);
      final manager = _StubManager(client);
      final serverProvider = MultiServerProvider(manager, DataAggregationService(manager));
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

      expect(client.seriesQueueCalls, ['series-P']);
      expect(playback.loadedItems.map((item) => item.id), ['ep1', 'ep2', 'ep3']);
      expect(result!.nextStatus, QueueNavigationStatus.found);
      expect(result!.next?.id, 'ep3');
      expect(result!.previous?.id, 'ep1');
    });

    testWidgets('distinguishes a fallback fetch failure from the end of a series', (tester) async {
      final current = _plexEpisode('ep2', seriesId: 'series-P');
      final playback = PlaybackStateProvider();
      addTearDown(playback.dispose);
      final client = _RecordingClient(
        seriesEpisodes: const [],
        clientBackend: MediaBackend.plex,
        fetchError: StateError('network unavailable'),
      );
      final manager = _StubManager(client);
      final serverProvider = MultiServerProvider(manager, DataAggregationService(manager));
      addTearDown(serverProvider.dispose);

      AdjacentEpisodes? result;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<PlaybackStateProvider>.value(value: playback),
            ChangeNotifierProvider<MultiServerProvider>.value(value: serverProvider),
          ],
          child: _ProbeWidget(metadata: current, onResult: (r) => result = r),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(result!.nextStatus, QueueNavigationStatus.failed);
      expect(result!.isEndConfirmed, isFalse);
      expect(playback.isQueueActive, isFalse);
    });

    testWidgets('confirms the end only after loading a queue containing the current episode', (tester) async {
      final ep1 = _plexEpisode('ep1', seriesId: 'series-P', viewCount: 1);
      final ep2 = _plexEpisode('ep2', seriesId: 'series-P', viewCount: 1);
      final playback = PlaybackStateProvider();
      addTearDown(playback.dispose);
      final client = _RecordingClient(seriesEpisodes: [ep1, ep2], clientBackend: MediaBackend.plex);
      final manager = _StubManager(client);
      final serverProvider = MultiServerProvider(manager, DataAggregationService(manager));
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

      expect(result!.nextStatus, QueueNavigationStatus.boundary);
      expect(result!.isEndConfirmed, isTrue);
      expect(result!.next, isNull);
    });
  });

  // ===========================================================
  // loadAdjacentEpisodes: shuffled same-series queue (#1466)
  // ===========================================================

  group('loadAdjacentEpisodes with a shuffled same-series queue', () {
    // Mirrors JellyfinSequentialLauncher.launchShuffledShow: the full series
    // episode list, locally shuffled, published with contextKey == seriesId.
    // The regression under test: _ensureLocalEpisodeQueue used to rebuild a
    // sequential series queue whenever contextKey == seriesId, so shuffle
    // held for exactly one episode (#1466).
    final ep1 = _jfEpisode('ep1', seriesId: 'series-A');
    final ep2 = _jfEpisode('ep2', seriesId: 'series-A');
    final ep3 = _jfEpisode('ep3', seriesId: 'series-A');
    final ep4 = _jfEpisode('ep4', seriesId: 'series-A');
    final ep5 = _jfEpisode('ep5', seriesId: 'series-A');
    final shuffledOrder = [ep3, ep1, ep5, ep2, ep4];
    const shuffledIds = ['ep3', 'ep1', 'ep5', 'ep2', 'ep4'];

    // Stub server answers with the sequential list, so an (unwanted) queue
    // rebuild is observable both via seriesQueueCalls and via reordered
    // loadedItems.
    (PlaybackStateProvider, _RecordingClient, MultiServerProvider) buildShuffledSession() {
      final playback = PlaybackStateProvider();
      addTearDown(playback.dispose);
      playback.setPlaybackFromLocalQueue(
        LocalPlayQueue(
          id: 'jellyfin:series-A',
          items: shuffledOrder,
          currentIndex: 0,
          shuffled: true,
          backendId: MediaBackend.jellyfin.id,
        ),
        contextKey: 'series-A',
      );
      final client = _RecordingClient(seriesEpisodes: [ep1, ep2, ep3, ep4, ep5]);
      final manager = _StubManager(client);
      final serverProvider = MultiServerProvider(manager, DataAggregationService(manager));
      addTearDown(serverProvider.dispose);
      return (playback, client, serverProvider);
    }

    Future<AdjacentEpisodes?> probe(
      WidgetTester tester,
      PlaybackStateProvider playback,
      MultiServerProvider serverProvider,
      MediaItem metadata,
    ) async {
      AdjacentEpisodes? result;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<PlaybackStateProvider>.value(value: playback),
            ChangeNotifierProvider<MultiServerProvider>.value(value: serverProvider),
          ],
          child: _ProbeWidget(metadata: metadata, onResult: (r) => result = r),
        ),
      );
      await tester.pump();
      await tester.pump();
      return result;
    }

    testWidgets('preserves the shuffled order instead of rebuilding sequentially', (tester) async {
      final (playback, client, serverProvider) = buildShuffledSession();

      final result = await probe(tester, playback, serverProvider, ep3);

      expect(client.seriesQueueCalls, isEmpty);
      expect(playback.loadedItems.map((e) => e.id), shuffledIds);
      expect(playback.isShuffleActive, isTrue);
      expect(playback.shuffleContextKey, 'series-A');
      expect(result!.next?.id, 'ep1');
      expect(result.previous, isNull);
    });

    testWidgets('continues the shuffled order after advancing to the next episode', (tester) async {
      final (playback, client, serverProvider) = buildShuffledSession();
      // What _reloadMediaInPlace does when the player swaps to the next item.
      playback.setCurrentItem(ep1);

      final result = await probe(tester, playback, serverProvider, ep1);

      expect(client.seriesQueueCalls, isEmpty);
      expect(playback.isShuffleActive, isTrue);
      expect(result!.next?.id, 'ep5');
      expect(result.previous?.id, 'ep3');
    });

    testWidgets('same-episode clone from a source switch does not clobber the queue', (tester) async {
      final (playback, client, serverProvider) = buildShuffledSession();

      // _switchPlaybackSource reloads with a copyWith clone of the playing
      // item; MediaItem compares by identity, so queue membership misses and
      // only the cursor-globalKey gate keeps the queue alive.
      final result = await probe(tester, playback, serverProvider, ep3.copyWith(viewOffsetMs: 42));

      expect(client.seriesQueueCalls, isEmpty);
      expect(playback.loadedItems.map((e) => e.id), shuffledIds);
      expect(playback.isShuffleActive, isTrue);
      expect(result!.next?.id, 'ep1');
    });

    testWidgets('still builds a sequential series queue when no queue is active', (tester) async {
      // Direct episode tap with no launcher: the preserve gates must not get
      // in the way of the normal series-queue build.
      final playback = PlaybackStateProvider();
      addTearDown(playback.dispose);
      final client = _RecordingClient(seriesEpisodes: [ep1, ep2, ep3, ep4, ep5]);
      final manager = _StubManager(client);
      final serverProvider = MultiServerProvider(manager, DataAggregationService(manager));
      addTearDown(serverProvider.dispose);

      final result = await probe(tester, playback, serverProvider, ep3);

      expect(client.seriesQueueCalls, ['series-A']);
      expect(playback.loadedItems.map((e) => e.id), ['ep1', 'ep2', 'ep3', 'ep4', 'ep5']);
      expect(playback.isShuffleActive, isFalse);
      expect(result!.next?.id, 'ep4');
      expect(result.previous?.id, 'ep2');
    });
  });
}
