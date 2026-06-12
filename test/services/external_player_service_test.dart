import 'package:drift/native.dart';
import 'package:plezy/media/ids.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/database/app_database.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/media/playback_report_metadata.dart';
import 'package:plezy/models/external_player_models.dart';
import 'package:plezy/services/external_player_service.dart';
import 'package:plezy/services/jellyfin_api_cache.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/offline_watch_sync_service.dart';

class _RecordingClient implements MediaServerClient {
  _RecordingClient({this.backend = MediaBackend.plex});

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
  double get watchedThreshold => 0.9;

  // Mirror the real clients: Jellyfin marks played from the stopped report, so
  // the external-player completion path emits only the local watch event
  // (#1287); Plex needs the explicit markWatched.
  @override
  bool get marksWatchedOnPlaybackStopped => backend == MediaBackend.jellyfin;

  @override
  Future<void> reportPlaybackStarted({
    required String itemId,
    required Duration position,
    Duration? duration,
    String? playSessionId,
    String? playMethod,
    String? mediaSourceId,
    int? audioStreamIndex,
    int? subtitleStreamIndex,
  }) async {
    started.add((positionMs: position.inMilliseconds, durationMs: duration?.inMilliseconds));
    if (failStart) throw StateError('start failed');
  }

  @override
  Future<void> reportPlaybackStopped({
    required String itemId,
    required Duration position,
    Duration? duration,
    String? playSessionId,
    String? mediaSourceId,
    PlaybackReportMetadata report = const PlaybackReportMetadata.live(),
  }) async {
    stopped.add((positionMs: position.inMilliseconds, durationMs: duration?.inMilliseconds));
    if (failStop) throw StateError('stop failed');
  }

  @override
  Future<void> markWatched(MediaItem item) async {
    watched.add(item.id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MediaItem _item({int? durationMs}) {
  return MediaItem(
    id: 'item-1',
    backend: MediaBackend.plex,
    kind: MediaKind.movie,
    serverId: 'srv',
    durationMs: durationMs,
  );
}

void main() {
  test('MX Player Android package candidates include free and Pro variants', () {
    final mxPlayer = KnownPlayers.findById('mx_player');

    expect(mxPlayer, isNotNull);
    expect(KnownPlayers.androidPackageCandidates(mxPlayer!), [
      'com.mxtech.videoplayer.ad',
      'com.mxtech.videoplayer.pro',
    ]);
  });

  test('Android external progress preserves null duration and still stops after start failure', () async {
    final client = _RecordingClient()..failStart = true;

    await ExternalPlayerService.reportAndroidExternalProgressForTesting(
      positionMs: 5000,
      durationMs: null,
      metadata: _item(),
      client: client,
    );

    expect(client.started, [(positionMs: 5000, durationMs: null)]);
    expect(client.stopped, [(positionMs: 5000, durationMs: null)]);
  });

  test('Android external progress queues unknown-duration resume when no client is available', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    JellyfinApiCache.initialize(db);
    final manager = MultiServerManager();
    final service = OfflineWatchSyncService(database: db, serverManager: manager);
    addTearDown(() async {
      service.dispose();
      manager.dispose();
      await db.close();
    });

    await ExternalPlayerService.reportAndroidExternalProgressForTesting(
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

  test('Android external progress ignores missing position without explicit completion', () async {
    final client = _RecordingClient();

    await ExternalPlayerService.reportAndroidExternalProgressForTesting(
      positionMs: null,
      durationMs: 100000,
      playbackCompleted: false,
      metadata: _item(durationMs: 100000),
      client: client,
    );

    expect(client.started, isEmpty);
    expect(client.stopped, isEmpty);
  });

  test('Android external progress reports full duration for explicit completion', () async {
    final client = _RecordingClient();

    await ExternalPlayerService.reportAndroidExternalProgressForTesting(
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

  test('Android external completion on Jellyfin marks watched via the stop report, not markWatched (#1287)', () async {
    final client = _RecordingClient(backend: MediaBackend.jellyfin);

    await ExternalPlayerService.reportAndroidExternalProgressForTesting(
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
}
