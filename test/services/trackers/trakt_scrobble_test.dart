import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/media/ids.dart';
import 'package:plezy/media/media_backend.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/media/media_server_client.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/trackers/anilist/anilist_tracker.dart';
import 'package:plezy/services/trackers/mal/mal_tracker.dart';
import 'package:plezy/services/trackers/simkl/simkl_tracker.dart';
import 'package:plezy/services/trackers/tracker_coordinator.dart';
import 'package:plezy/services/trackers/tracker_session.dart';
import 'package:plezy/services/trackers/trakt/trakt_tracker.dart';
import 'package:plezy/utils/external_ids.dart';

import '../../test_helpers/media_items.dart';
import '../../test_helpers/prefs.dart';

class _FakeMediaServerClient implements MediaServerClient {
  @override
  final ServerId serverId;
  @override
  String? get serverName => null;

  final Map<String, ExternalIds> externalIdsByItem;

  @override
  final double watchedThreshold;

  _FakeMediaServerClient({required this.externalIdsByItem, this.watchedThreshold = 0.9})
    : serverId = ServerId('server-1');

  @override
  MediaBackend get backend => MediaBackend.plex;

  @override
  Future<ExternalIds> fetchExternalIds(String itemId) async => externalIdsByItem[itemId] ?? const ExternalIds();

  @override
  Future<List<MediaItem>> fetchPlayableDescendants(String parentId) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Call {
  final String path;
  final Map<String, dynamic> body;

  _Call(this.path, this.body);

  @override
  String toString() => '$path ${json.encode(body)}';
}

class _TraktRecorder {
  final List<_Call> calls = [];
  final Map<String, int> statuses = {};
  Completer<void>? gate;

  http.Client get client => MockClient((request) async {
    final body = request.body.isEmpty
        ? <String, dynamic>{}
        : (json.decode(request.body) as Map).cast<String, dynamic>();
    calls.add(_Call(request.url.path, body));
    final pending = gate;
    if (pending != null) await pending.future;
    return http.Response('{}', statuses[request.url.path] ?? 200);
  });

  List<String> get paths => calls.map((call) => call.path).toList();

  List<_Call> callsFor(String path) => calls.where((call) => call.path == path).toList();

  _Call callFor(String path) => calls.firstWhere((call) => call.path == path, orElse: () => fail('no $path in $paths'));
}

MediaItem _episode({int? viewOffsetMs, int? durationMs}) => testMediaItem(
  id: 'episode-1-3',
  backend: MediaBackend.plex,
  kind: MediaKind.episode,
  title: 'Episode 3',
  serverId: ServerId('server-1'),
  libraryId: 'lib-1',
  parentIndex: 1,
  index: 3,
  grandparentId: 'show-1',
  viewOffsetMs: viewOffsetMs,
  durationMs: durationMs,
);

TrackerSession _session([String token = 'token']) =>
    TrackerSession(accessToken: token, createdAt: DateTime(2026, 7, 30).millisecondsSinceEpoch ~/ 1000);

_FakeMediaServerClient _client({double watchedThreshold = 0.9}) => _FakeMediaServerClient(
  externalIdsByItem: {'show-1': const ExternalIds(tvdb: 12345)},
  watchedThreshold: watchedThreshold,
);

void main() {
  final coordinator = TrackerCoordinator.instance;
  final trakt = TraktTracker.instance;
  final simkl = SimklTracker.instance;
  final mal = MalTracker.instance;
  final anilist = AnilistTracker.instance;

  late _TraktRecorder recorder;
  late DateTime now;

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();

    recorder = _TraktRecorder();
    now = DateTime(2026, 7, 30, 12);
    coordinator.debugUseScrobbleClock(() => now);

    simkl.rebindSession(null, onSessionInvalidated: () {});
    mal.rebindSession(null, onSessionInvalidated: () {});
    anilist.rebindSession(null, onSessionInvalidated: () {});
    trakt.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: recorder.client);

    await simkl.setEnabled(false);
    await mal.setEnabled(false);
    await anilist.setEnabled(false);
    await trakt.setEnabled(true);
    await trakt.setWatchedSyncEnabled(true);
  });

  tearDown(() async {
    if (recorder.gate?.isCompleted == false) recorder.gate!.complete();
    coordinator.cancelInFlight();
    coordinator.debugUseResolverDependencies();
    coordinator.debugUseScrobbleClock(null);

    trakt.rebindSession(null, onSessionInvalidated: () {});
    simkl.rebindSession(null, onSessionInvalidated: () {});
    mal.rebindSession(null, onSessionInvalidated: () {});
    anilist.rebindSession(null, onSessionInvalidated: () {});

    await trakt.setEnabled(false);
    await trakt.setWatchedSyncEnabled(false);
    await simkl.setEnabled(false);
    await mal.setEnabled(false);
    await anilist.setEnabled(false);
    SettingsService.resetForTesting();
  });

  void moveWithoutSeeking(Duration target) {
    for (var milliseconds = 5000; milliseconds < target.inMilliseconds; milliseconds += 5000) {
      coordinator.updatePosition(Duration(milliseconds: milliseconds));
    }
    coordinator.updatePosition(target);
  }

  Future<void> startAtZero({_FakeMediaServerClient? client}) async {
    await coordinator.startPlayback(_episode(durationMs: 100000), client ?? _client());
    await pumpEventQueue();
  }

  group('Trakt real-time playback', () {
    test('start posts the resume offset and episode identity', () async {
      await coordinator.startPlayback(
        _episode(viewOffsetMs: const Duration(minutes: 10).inMilliseconds, durationMs: 2000000),
        _client(),
      );
      await pumpEventQueue();

      expect(recorder.paths, ['/scrobble/start']);
      expect(recorder.calls.single.body, {
        'progress': 30.0,
        'show': {
          'ids': {'tvdb': 12345},
        },
        'episode': {'season': 1, 'number': 3},
      });
    });

    test('pause checkpoints progress and resume starts again', () async {
      await startAtZero();
      moveWithoutSeeking(const Duration(seconds: 40));

      await coordinator.pausePlayback();
      await coordinator.resumePlayback();
      await pumpEventQueue();

      expect(recorder.paths, ['/scrobble/start', '/scrobble/pause', '/scrobble/start']);
      expect(recorder.calls[1].body['progress'], 40.0);
      expect(recorder.calls[2].body['progress'], 40.0);
    });

    test('same-state start obeys the thirty-second resend throttle', () async {
      await startAtZero();

      now = now.add(const Duration(seconds: 5));
      await coordinator.resumePlayback();
      await pumpEventQueue();
      expect(recorder.paths, ['/scrobble/start']);

      now = now.add(const Duration(seconds: 25));
      await coordinator.resumePlayback();
      await pumpEventQueue();
      expect(recorder.paths, ['/scrobble/start', '/scrobble/start']);
    });

    test('seek checkpoints are throttled and ignored while paused', () async {
      await startAtZero();
      coordinator.updatePosition(const Duration(seconds: 4));
      coordinator.updatePosition(const Duration(seconds: 40));
      await pumpEventQueue();

      expect(recorder.paths, ['/scrobble/start', '/scrobble/pause', '/scrobble/start']);
      expect(recorder.calls[1].body['progress'], 40.0);
      expect(recorder.calls[2].body['progress'], 40.0);

      coordinator.updatePosition(const Duration(seconds: 70));
      await pumpEventQueue();
      expect(recorder.paths, ['/scrobble/start', '/scrobble/pause', '/scrobble/start']);

      now = now.add(const Duration(seconds: 5));
      coordinator.updatePosition(const Duration(seconds: 20));
      await pumpEventQueue();
      expect(recorder.paths, [
        '/scrobble/start',
        '/scrobble/pause',
        '/scrobble/start',
        '/scrobble/pause',
        '/scrobble/start',
      ]);
      expect(recorder.calls[3].body['progress'], 20.0);
      expect(recorder.calls[4].body['progress'], 20.0);

      await coordinator.pausePlayback();
      final callsBeforePausedJump = recorder.calls.length;
      coordinator.updatePosition(const Duration(seconds: 80));
      await pumpEventQueue();
      expect(recorder.calls, hasLength(callsBeforePausedJump));
    });

    test('stop reports measured progress without inflating it to watched', () async {
      await startAtZero();
      moveWithoutSeeking(const Duration(seconds: 60));

      await coordinator.stopPlayback();

      expect(recorder.paths, ['/scrobble/start', '/scrobble/stop']);
      expect(recorder.callFor('/scrobble/stop').body['progress'], 60.0);
    });

    test('a low server watched threshold falls back to Trakt history', () async {
      await startAtZero(client: _client(watchedThreshold: 0.5));
      moveWithoutSeeking(const Duration(seconds: 60));
      await pumpEventQueue();

      await coordinator.stopPlayback();
      await pumpEventQueue();

      expect(recorder.paths, ['/scrobble/start', '/scrobble/stop', '/sync/history']);
      expect(recorder.callFor('/scrobble/stop').body['progress'], 60.0);
      expect(recorder.callFor('/sync/history').body, {
        'shows': [
          {
            'ids': {'tvdb': 12345},
            'seasons': [
              {
                'number': 1,
                'episodes': [
                  {'number': 3},
                ],
              },
            ],
          },
        ],
      });
    });

    test('an unconfirmed completed stop falls back to Trakt history', () async {
      recorder.statuses['/scrobble/stop'] = 500;
      await startAtZero(client: _client(watchedThreshold: 0.8));
      moveWithoutSeeking(const Duration(seconds: 85));
      await pumpEventQueue();

      await coordinator.stopPlayback();
      await pumpEventQueue();

      expect(recorder.paths, ['/scrobble/start', '/scrobble/stop', '/sync/history']);
      expect(recorder.callFor('/scrobble/stop').body['progress'], 85.0);
      expect(recorder.callsFor('/sync/history'), hasLength(1));
    });

    Future<void> crossThresholdThenStopBelowTraktRule() async {
      await startAtZero();
      moveWithoutSeeking(const Duration(seconds: 95));
      await pumpEventQueue();
      coordinator.updateDuration(const Duration(seconds: 200));
      await coordinator.stopPlayback();
      await pumpEventQueue();
    }

    test('scrobble and watched sync together record one watch', () async {
      await crossThresholdThenStopBelowTraktRule();

      expect(recorder.paths, ['/scrobble/start', '/scrobble/stop', '/sync/history']);
      expect(recorder.callFor('/scrobble/stop').body['progress'], 47.5);
      expect(recorder.callsFor('/sync/history'), hasLength(1));
    });

    test('watched sync works with real-time scrobbling disabled', () async {
      await trakt.setEnabled(false);

      await crossThresholdThenStopBelowTraktRule();

      expect(recorder.paths.where((path) => path.startsWith('/scrobble/')), isEmpty);
      expect(recorder.paths, ['/sync/history']);
    });

    test('real-time scrobbling never writes history when watched sync is disabled', () async {
      await trakt.setWatchedSyncEnabled(false);

      await crossThresholdThenStopBelowTraktRule();

      expect(recorder.paths, ['/scrobble/start', '/scrobble/stop']);
      expect(recorder.callFor('/scrobble/stop').body['progress'], 47.5);
      expect(recorder.callsFor('/sync/history'), isEmpty);
    });

    test('disabling both Trakt toggles suppresses every request', () async {
      await trakt.setEnabled(false);
      await trakt.setWatchedSyncEnabled(false);

      await crossThresholdThenStopBelowTraktRule();

      expect(recorder.calls, isEmpty);
    });

    test('an account rebind before stop keeps the terminal report off the new account', () async {
      await startAtZero();
      moveWithoutSeeking(const Duration(seconds: 40));

      final replacement = _TraktRecorder();
      trakt.rebindSession(_session('replacement-token'), onSessionInvalidated: () {}, httpClient: replacement.client);
      await coordinator.stopPlayback();
      await pumpEventQueue();

      expect(recorder.paths, ['/scrobble/start']);
      expect(replacement.calls, isEmpty);
    });
  });
}
