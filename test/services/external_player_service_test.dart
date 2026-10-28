import 'package:drift/native.dart';
import 'package:plezy/media/ids.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_part.dart';
import 'package:plezy/media/media_part_timeline.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/services/external_player_service.dart';
import 'package:plezy/services/deep_links/deep_link.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/offline_watch_sync_service.dart';
import 'package:plezy/utils/active_client_scope.dart';
import 'package:plezy/utils/watch_state_notifier.dart';
import '../test_helpers/media_items.dart';
import '../test_helpers/playback_report_fakes.dart';

class _RecordingClient with PlaybackReportRecorder implements MediaServerClient, ScopedMediaServerClient {
  _RecordingClient({this.backend = MediaBackend.plex, String? scopedServerId})
    : scopedServerId =
          scopedServerId ??
          (backend == MediaBackend.plex
              ? buildPlexProfileScopeId(serverId: ServerId('srv'), profileId: 'profile-a')
              : 'srv/user-a');

  bool failStart = false;
  bool failStop = false;
  final started = <({int positionMs, int? durationMs})>[];
  final stopped = <({int positionMs, int? durationMs})>[];
  final watched = <String>[];

  @override
  ServerId get serverId => ServerId('srv');

  @override
  final MediaBackend backend;
  @override
  final String scopedServerId;

  @override
  double get watchedThreshold => 0.9;

  // Mirror the real clients: Jellyfin marks played from the stopped report, so
  // the external-player completion path emits only the local watch event
  // (#1287); Plex needs the explicit markWatched.
  @override
  bool get marksWatchedOnPlaybackStopped => backend == MediaBackend.jellyfin;

  @override
  Future<void> onPlaybackReport(PlaybackReportCall call) async {
    final entry = (positionMs: call.position.inMilliseconds, durationMs: call.duration?.inMilliseconds);
    switch (call.kind) {
      case PlaybackReportKind.started:
        started.add(entry);
        if (failStart) throw StateError('start failed');
      case PlaybackReportKind.progress:
        throw UnimplementedError();
      case PlaybackReportKind.stopped:
        stopped.add(entry);
        if (failStop) throw StateError('stop failed');
    }
  }

  @override
  Future<void> markWatched(MediaItem item) async {
    watched.add(item.id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MediaItem _item({int? durationMs}) {
  return testMediaItem(
    id: 'item-1',
    backend: MediaBackend.plex,
    kind: MediaKind.movie,
    serverId: 'srv',
    durationMs: durationMs,
  );
}

void main() {
  test('External progress preserves null duration and still stops after start failure', () async {
    final client = _RecordingClient()..failStart = true;

    await ExternalPlayerService.reportExternalProgressForTesting(
      positionMs: 5000,
      durationMs: null,
      metadata: _item(),
      client: client,
    );

    expect(client.started, [(positionMs: 5000, durationMs: null)]);
    expect(client.stopped, [(positionMs: 5000, durationMs: null)]);
  });

  test('External progress queues unknown-duration resume when no client is available', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    JellyfinApiCache.initialize(db);
    final manager = MultiServerManager();
    final service = OfflineWatchSyncService(database: db, serverManager: manager);
    addTearDown(() async {
      service.dispose();
      manager.dispose();
      await db.close();
    });

    await ExternalPlayerService.reportExternalProgressForTesting(
      positionMs: 5000,
      durationMs: null,
      metadata: _item(),
      client: null,
      offlineWatchService: service,
    );

    final action = await db.getLatestWatchAction('srv:item-1');
    expect(action, isNotNull);
    expect(action!.viewOffset, 5000);
    expect(action.duration, isNull);
    expect(action.shouldMarkWatched, isFalse);
  });

  test('External progress emits the exact client cache scope', () async {
    final scope = buildPlexProfileScopeId(serverId: ServerId('srv'), profileId: 'profile-a');
    final client = _RecordingClient(scopedServerId: scope);
    final events = <WatchStateEvent>[];
    final subscription = WatchStateNotifier().stream
        .where((event) => event.affectsItem('item-1'))
        .where((event) => event.changeType == WatchStateChangeType.progressUpdate)
        .listen(events.add);
    addTearDown(subscription.cancel);

    await ExternalPlayerService.reportExternalProgressForTesting(
      positionMs: 5000,
      durationMs: 100000,
      metadata: _item(durationMs: 100000),
      client: client,
    );
    await Future<void>.delayed(Duration.zero);

    expect(events, hasLength(1));
    expect(events.single.cacheServerId, scope);
  });

  test('External progress ignores missing position without explicit completion', () async {
    final client = _RecordingClient();

    await ExternalPlayerService.reportExternalProgressForTesting(
      positionMs: null,
      durationMs: 100000,
      playbackCompleted: false,
      metadata: _item(durationMs: 100000),
      client: client,
    );

    expect(client.started, isEmpty);
    expect(client.stopped, isEmpty);
  });

  test('External progress reports full duration for explicit completion', () async {
    final client = _RecordingClient();

    await ExternalPlayerService.reportExternalProgressForTesting(
      positionMs: null,
      durationMs: 100000,
      playbackCompleted: true,
      metadata: _item(durationMs: 100000),
      client: client,
    );

    expect(client.started, [(positionMs: 100000, durationMs: 100000)]);
    expect(client.stopped, [(positionMs: 100000, durationMs: 100000)]);
    expect(client.watched, ['item-1']);
  });

  test('External completion on Jellyfin marks watched via the stop report, not markWatched (#1287)', () async {
    final client = _RecordingClient(backend: MediaBackend.jellyfin);

    await ExternalPlayerService.reportExternalProgressForTesting(
      positionMs: null,
      durationMs: 100000,
      playbackCompleted: true,
      metadata: _item(durationMs: 100000),
      client: client,
    );

    // The stopped report at full duration marks it played server-side…
    expect(client.stopped, [(positionMs: 100000, durationMs: 100000)]);
    // …so the explicit markWatched is skipped — issuing it would double-scrobble
    // through the Jellyfin Trakt plugin.
    expect(client.watched, isEmpty);
  });

  group('a stacked item (50 + 40 minute files)', () {
    const fileOneMs = 3000000;
    const itemMs = 5400000;
    MediaPartTimeline timeline({required int currentIndex}) => MediaPartTimeline.fromParts(const [
      MediaPart(id: '11', durationMs: fileOneMs),
      MediaPart(id: '12', durationMs: 2400000),
    ], currentIndex: currentIndex)!;

    test('playing out the first file leaves the item at the second, not watched', () async {
      final client = _RecordingClient();

      await ExternalPlayerService.reportExternalProgressForTesting(
        positionMs: null,
        durationMs: fileOneMs,
        playbackCompleted: true,
        metadata: _item(durationMs: itemMs),
        client: client,
        partTimeline: timeline(currentIndex: 0),
      );

      expect(client.stopped, [(positionMs: fileOneMs, durationMs: itemMs)]);
      expect(client.watched, isEmpty);
    });

    test('the second file reports on the item clock and finishing it finishes the item', () async {
      final client = _RecordingClient();

      await ExternalPlayerService.reportExternalProgressForTesting(
        positionMs: 600000,
        durationMs: 2400000,
        metadata: _item(durationMs: itemMs),
        client: client,
        partTimeline: timeline(currentIndex: 1),
      );
      expect(client.stopped.last, (positionMs: fileOneMs + 600000, durationMs: itemMs));
      expect(client.watched, isEmpty);

      await ExternalPlayerService.reportExternalProgressForTesting(
        positionMs: null,
        durationMs: 2400000,
        playbackCompleted: true,
        metadata: _item(durationMs: itemMs),
        client: client,
        partTimeline: timeline(currentIndex: 1),
      );
      expect(client.stopped.last, (positionMs: itemMs, durationMs: itemMs));
      expect(client.watched, ['item-1']);
    });
  });

  group('x-callback-url return links', () {
    Uri link(String result, String session, [String query = '']) =>
        Uri.parse('plezy://external-player/$result/$session${query.isEmpty ? '' : '?$query'}');

    test('cancel reports the position the player stopped at, in seconds', () async {
      final client = _RecordingClient();
      final session = ExternalPlayerService.beginCallbackSessionForTesting(
        metadata: _item(durationMs: 6000000),
        client: client,
      );

      final handled = await ExternalPlayerService.handleCallbackUrl(
        link('cancel', session, 'url=http%3A%2F%2Fsrv%2Fv.mkv&position=1234.5&duration=6000'),
      );

      expect(handled, isTrue);
      expect(client.stopped, [(positionMs: 1234500, durationMs: 6000000)]);
      expect(client.watched, isEmpty);
    });

    test('a reported duration matching the runtime in milliseconds switches units', () async {
      final client = _RecordingClient();
      final session = ExternalPlayerService.beginCallbackSessionForTesting(
        metadata: _item(durationMs: 6000000),
        client: client,
      );

      await ExternalPlayerService.handleCallbackUrl(link('cancel', session, 'position=30000&duration=6000000'));

      expect(client.stopped, [(positionMs: 30000, durationMs: 6000000)]);
    });

    test('success marks the item watched', () async {
      final client = _RecordingClient();
      final session = ExternalPlayerService.beginCallbackSessionForTesting(
        metadata: _item(durationMs: 100000),
        client: client,
      );

      await ExternalPlayerService.handleCallbackUrl(link('success', session, 'url=x'));

      expect(client.stopped, [(positionMs: 100000, durationMs: 100000)]);
      expect(client.watched, ['item-1']);
    });

    test('Infuse success mid-video saves the position without marking watched', () async {
      final client = _RecordingClient();
      final session = ExternalPlayerService.beginCallbackSessionForTesting(
        metadata: _item(durationMs: 1420016),
        client: client,
      );

      // Infuse sends lastPlayedUrl and position (seconds), never a duration.
      await ExternalPlayerService.handleCallbackUrl(
        link('success', session, 'lastPlayedUrl=http%3A%2F%2Fsrv%2Fv.mkv&position=600'),
      );

      expect(client.stopped, [(positionMs: 600000, durationMs: 1420016)]);
      expect(client.watched, isEmpty);
    });

    test('Infuse success past the watched threshold marks watched', () async {
      final client = _RecordingClient();
      final session = ExternalPlayerService.beginCallbackSessionForTesting(
        metadata: _item(durationMs: 1420016),
        client: client,
      );

      await ExternalPlayerService.handleCallbackUrl(
        link('success', session, 'lastPlayedUrl=http%3A%2F%2Fsrv%2Fv.mkv&position=1400'),
      );

      expect(client.stopped, [(positionMs: 1400000, durationMs: 1420016)]);
      expect(client.watched, ['item-1']);
    });

    test('Infuse error reports nothing', () async {
      final client = _RecordingClient();
      final session = ExternalPlayerService.beginCallbackSessionForTesting(
        metadata: _item(durationMs: 1420016),
        client: client,
      );

      await ExternalPlayerService.handleCallbackUrl(
        link('error', session, 'errorCode=1&errorMessage=Playback%20failed&failedUrl=http%3A%2F%2Fsrv%2Fv.mkv'),
      );

      expect(client.started, isEmpty);
      expect(client.stopped, isEmpty);
    });

    test('error reports nothing', () async {
      final client = _RecordingClient();
      final session = ExternalPlayerService.beginCallbackSessionForTesting(
        metadata: _item(durationMs: 100000),
        client: client,
      );

      await ExternalPlayerService.handleCallbackUrl(link('error', session, 'position=50'));

      expect(client.started, isEmpty);
      expect(client.stopped, isEmpty);
    });

    test('VLC success means stopped somewhere unknown: nothing is reported or marked watched', () async {
      final client = _RecordingClient();
      final session = ExternalPlayerService.beginCallbackSessionForTesting(
        metadata: _item(durationMs: 1420016),
        client: client,
        playerId: 'vlc',
      );

      // VLC appends nothing to its return links.
      expect(await ExternalPlayerService.handleCallbackUrl(link('success', session)), isTrue);

      expect(client.started, isEmpty);
      expect(client.stopped, isEmpty);
      expect(client.watched, isEmpty);
    });

    test('VLC error reports nothing', () async {
      final client = _RecordingClient();
      final session = ExternalPlayerService.beginCallbackSessionForTesting(
        metadata: _item(durationMs: 1420016),
        client: client,
        playerId: 'vlc',
      );

      await ExternalPlayerService.handleCallbackUrl(link('error', session));

      expect(client.started, isEmpty);
      expect(client.stopped, isEmpty);
    });

    test('Outplayer success without a position still means it played to the end', () async {
      final client = _RecordingClient();
      final session = ExternalPlayerService.beginCallbackSessionForTesting(
        metadata: _item(durationMs: 1420016),
        client: client,
        playerId: 'outplayer',
      );

      await ExternalPlayerService.handleCallbackUrl(link('success', session));

      expect(client.stopped, [(positionMs: 1420016, durationMs: 1420016)]);
      expect(client.watched, ['item-1']);
    });

    test('a link from a replaced launch is ignored, and each link is used once', () async {
      final client = _RecordingClient();
      final stale = ExternalPlayerService.beginCallbackSessionForTesting(metadata: _item(), client: client);
      await Future<void>.delayed(const Duration(milliseconds: 1));
      final current = ExternalPlayerService.beginCallbackSessionForTesting(metadata: _item(), client: client);

      expect(await ExternalPlayerService.handleCallbackUrl(link('cancel', stale, 'position=10')), isFalse);
      expect(await ExternalPlayerService.handleCallbackUrl(link('cancel', current, 'position=10')), isTrue);
      expect(await ExternalPlayerService.handleCallbackUrl(link('cancel', current, 'position=20')), isFalse);
      expect(client.stopped, [(positionMs: 10000, durationMs: null)]);
    });

    test('accepts the return link the deep-link layer parsed, in the shape Outplayer opens', () async {
      final client = _RecordingClient();
      final session = ExternalPlayerService.beginCallbackSessionForTesting(
        metadata: _item(durationMs: 1420016),
        client: client,
      );

      // The exact shape Outplayer opened: the stream URL appended unencoded.
      final url =
          '${ExternalPlayerService.returnLinks(session).cancel}'
          '?url=https://srv.plex.direct:32400/library/parts/1/2/file.mkv?X-Plex-Token=t'
          '&position=283.283&duration=1420.016';
      final returnLink = DeepLink.tryParse(url) as ExternalPlayerReturnLink;

      expect(await ExternalPlayerService.handleCallbackUrl(returnLink.uri), isTrue);
      expect(client.stopped, [(positionMs: 283283, durationMs: 1420016)]);
    });

    test('return links are built from the deep-link grammar', () {
      final links = ExternalPlayerService.returnLinks('s1');

      for (final (uri, result) in [(links.success, 'success'), (links.cancel, 'cancel'), (links.error, 'error')]) {
        expect(DeepLink.tryParse(uri.toString()), isA<ExternalPlayerReturnLink>());
        expect(uri.pathSegments, [result, 's1']);
      }
    });

    test('other plezy links are not callbacks', () async {
      expect(await ExternalPlayerService.handleCallbackUrl(Uri.parse('plezy://live?channel=4.1')), isFalse);
    });

    test('a return link without a session is not a callback', () async {
      ExternalPlayerService.beginCallbackSessionForTesting(metadata: _item(), client: _RecordingClient());

      expect(await ExternalPlayerService.handleCallbackUrl(Uri.parse('plezy://external-player/cancel')), isFalse);
    });
  });

  group('player file name', () {
    const plexUrl = 'https://srv.plex.direct:32400/library/parts/28182/1791123620/file.mkv?X-Plex-Token=t';

    test('movies use Title (Year) with the stream extension', () {
      final item = testMediaItem(kind: MediaKind.movie, title: 'Inception', year: 2010);
      expect(ExternalPlayerService.playerFilename(item, plexUrl), 'Inception (2010).mkv');
    });

    test('episodes use Show - S01E02 - Title', () {
      final item = testMediaItem(
        kind: MediaKind.episode,
        title: 'The Dundies',
        grandparentTitle: 'The Office',
        parentIndex: 2,
        index: 1,
      );
      expect(ExternalPlayerService.playerFilename(item, plexUrl), 'The Office - S02E01 - The Dundies.mkv');
    });

    test('specials keep season 0 and an untitled episode drops the title', () {
      final item = testMediaItem(kind: MediaKind.episode, grandparentTitle: 'Doctor Who', parentIndex: 0, index: 12);
      expect(ExternalPlayerService.playerFilename(item, plexUrl), 'Doctor Who - S00E12.mkv');
    });

    test('characters file names cannot hold are replaced', () {
      final item = testMediaItem(kind: MediaKind.movie, title: 'Mission: Impossible / Fallout', year: 2018);
      expect(ExternalPlayerService.playerFilename(item, plexUrl), 'Mission Impossible Fallout (2018).mkv');
    });

    test('Jellyfin stream URLs give their container as the extension', () {
      final item = testMediaItem(backend: MediaBackend.jellyfin, kind: MediaKind.movie, title: 'Dune', year: 2021);
      expect(
        ExternalPlayerService.playerFilename(item, 'https://jf.example/Videos/abc/stream.mp4?Static=true&api_key=k'),
        'Dune (2021).mp4',
      );
    });

    test('an episode without season or episode numbers gets no name', () {
      final item = testMediaItem(kind: MediaKind.episode, title: 'Pilot', grandparentTitle: 'Show', index: 1);
      expect(ExternalPlayerService.playerFilename(item, plexUrl), isNull);
    });

    test('other kinds get no name', () {
      final item = testMediaItem(kind: MediaKind.clip, title: 'Trailer');
      expect(ExternalPlayerService.playerFilename(item, plexUrl), isNull);
    });
  });
}
