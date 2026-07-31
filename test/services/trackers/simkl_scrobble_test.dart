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
import 'package:plezy/services/trackers/anilist/anilist_tracker.dart';
import 'package:plezy/services/trackers/mal/mal_tracker.dart';
import 'package:plezy/services/trackers/simkl/simkl_tracker.dart';
import 'package:plezy/services/trackers/tracker_coordinator.dart';
import 'package:plezy/services/trackers/tracker_session.dart';
import 'package:plezy/utils/external_ids.dart';
import '../../test_helpers/media_items.dart';

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

/// Records every Simkl write and can hold one in flight, which is how the queue
/// ordering is driven without leaning on wall-clock timing.
class _SimklRecorder {
  final List<_Call> calls = [];
  Completer<void>? gate;
  int status = 200;

  http.Client get client => MockClient((request) async {
    final body = request.body.isEmpty
        ? <String, dynamic>{}
        : (json.decode(request.body) as Map).cast<String, dynamic>();
    calls.add(_Call(request.url.path, body));
    final pending = gate;
    if (pending != null) await pending.future;
    return http.Response('{}', status);
  });

  List<String> get paths => calls.map((c) => c.path).toList();

  _Call callFor(String path) => calls.firstWhere((c) => c.path == path, orElse: () => fail('no $path in $paths'));
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

MediaItem _movie() => testMediaItem(
  id: 'movie-1',
  backend: MediaBackend.plex,
  kind: MediaKind.movie,
  title: 'Movie 1',
  serverId: ServerId('server-1'),
  libraryId: 'lib-1',
);

TrackerSession _session() =>
    TrackerSession(accessToken: 'token', createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000);

_FakeMediaServerClient _client({double watchedThreshold = 0.9}) => _FakeMediaServerClient(
  externalIdsByItem: {'show-1': const ExternalIds(tvdb: 12345), 'movie-1': const ExternalIds(tmdb: 603)},
  watchedThreshold: watchedThreshold,
);

void main() {
  final coordinator = TrackerCoordinator.instance;
  final simkl = SimklTracker.instance;
  final mal = MalTracker.instance;
  final anilist = AnilistTracker.instance;

  late _SimklRecorder recorder;
  late DateTime now;

  setUp(() async {
    recorder = _SimklRecorder();
    now = DateTime(2026, 7, 30, 12);
    coordinator.debugUseScrobbleClock(() => now);
    await mal.setEnabled(false);
    await anilist.setEnabled(false);
    await simkl.setEnabled(true);
    simkl.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: recorder.client);
  });

  tearDown(() async {
    if (recorder.gate?.isCompleted == false) recorder.gate!.complete();
    coordinator.cancelInFlight();
    coordinator.debugUseResolverDependencies();
    coordinator.debugUseScrobbleClock(null);
    simkl.rebindSession(null, onSessionInvalidated: () {});
    await simkl.setEnabled(false);
  });

  /// Move the fake clock past the debounce and same-state throttle windows.
  void settleThrottles() => now = now.add(const Duration(seconds: 30));

  group('Simkl real-time playback', () {
    test('reports the resume position when playback starts', () async {
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

    test('pause saves progress and resume reopens the session', () async {
      await coordinator.startPlayback(_episode(durationMs: 100000), _client());
      await pumpEventQueue();
      coordinator.updatePosition(const Duration(milliseconds: 40000));

      settleThrottles();
      await coordinator.pausePlayback();
      settleThrottles();
      await coordinator.resumePlayback();
      await pumpEventQueue();

      expect(recorder.paths, ['/scrobble/start', '/scrobble/pause', '/scrobble/start']);
      expect(recorder.calls[1].body['progress'], 40.0);
      expect(recorder.calls[2].body['progress'], 40.0);
    });

    // Issue #1719: stopping before the item finished recorded nothing at all.
    test('stopping unfinished playback saves the true position, without a history write', () async {
      await coordinator.startPlayback(_episode(durationMs: 2526934), _client());
      await pumpEventQueue();
      coordinator.updatePosition(const Duration(milliseconds: 1292667));

      settleThrottles();
      await coordinator.stopPlayback();

      expect(recorder.paths, ['/scrobble/start', '/scrobble/stop']);
      expect(recorder.callFor('/scrobble/stop').body['progress'], closeTo(51.16, 0.01));
    });

    test('stopping a finished item reports completion and leaves watched to Simkl', () async {
      await coordinator.startPlayback(_episode(durationMs: 100000), _client());
      await pumpEventQueue();
      coordinator.updatePosition(const Duration(milliseconds: 95000));

      settleThrottles();
      await coordinator.stopPlayback();

      expect(recorder.callFor('/scrobble/stop').body['progress'], 95.0);
      // 95% is past Simkl's own 80% rule, so that stop is the single watched
      // write — never a second one through history.
      expect(recorder.paths, isNot(contains('/sync/history')));
    });

    test('records the watch explicitly when a low server threshold beats Simkl own rule', () async {
      // Plex offers 25/50/75%; at 75% a truthful stop sits below Simkl's 80%
      // rule, so the stop alone would only file resumable progress.
      await coordinator.startPlayback(_episode(durationMs: 100000), _client(watchedThreshold: 0.75));
      await pumpEventQueue();
      coordinator.updatePosition(const Duration(milliseconds: 76000));

      settleThrottles();
      await coordinator.stopPlayback();
      await pumpEventQueue();

      expect(recorder.paths, ['/scrobble/start', '/scrobble/stop', '/sync/history']);
      // Progress is never inflated to force the watched state: it doubles as the
      // user's resume position.
      expect(recorder.callFor('/scrobble/stop').body['progress'], 76.0);
    });

    test('an account rebind during the terminal report cancels the watched fallback', () async {
      await coordinator.startPlayback(_episode(durationMs: 100000), _client(watchedThreshold: 0.75));
      await pumpEventQueue();
      coordinator.updatePosition(const Duration(milliseconds: 76000));

      recorder.gate = Completer<void>();
      settleThrottles();
      final stopped = coordinator.stopPlayback();
      await pumpEventQueue();

      // The account is replaced while the stop is still on the wire — a
      // disconnect/reconnect or profile switch, neither of which the queued
      // fallback may follow.
      final replacement = _SimklRecorder();
      simkl.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: replacement.client);
      recorder.gate!.complete();
      await stopped;
      await pumpEventQueue();

      // The stop reached the account it belonged to; the history fallback lands
      // on neither account rather than on the wrong one.
      expect(recorder.paths, ['/scrobble/start', '/scrobble/stop']);
      expect(replacement.paths, isEmpty);
    });

    test('an account rebind drops a still-queued lifecycle report', () async {
      await coordinator.startPlayback(_episode(durationMs: 100000), _client());
      await pumpEventQueue();
      coordinator.updatePosition(const Duration(milliseconds: 40000));

      // The pause goes on the wire and blocks there; the stop only queues.
      recorder.gate = Completer<void>();
      settleThrottles();
      final paused = coordinator.pausePlayback();
      await pumpEventQueue();
      final stopped = coordinator.stopPlayback();
      await pumpEventQueue();

      // Disconnect/reconnect replaces the client the queued stop would have
      // used. Reading it at execution time would post this item to whichever
      // account is bound by then.
      final replacement = _SimklRecorder();
      simkl.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: replacement.client);
      recorder.gate!.complete();
      await paused;
      await stopped;
      await pumpEventQueue();

      // The pause was already bound when it went out, so it belongs to the
      // original account. The queued stop is dropped, not redirected.
      expect(recorder.paths, ['/scrobble/start', '/scrobble/pause']);
      expect(replacement.paths, isEmpty);
    });

    test('an account rebind before the terminal report keeps it off the new account', () async {
      await coordinator.startPlayback(_episode(durationMs: 100000), _client());
      await pumpEventQueue();
      coordinator.updatePosition(const Duration(milliseconds: 40000));

      // Nothing is queued or in flight this time: the account is simply replaced
      // between the start and the stop, so a target resolved at stop time would
      // look perfectly valid — and would post this item to the wrong account.
      final replacement = _SimklRecorder();
      simkl.rebindSession(_session(), onSessionInvalidated: () {}, httpClient: replacement.client);

      settleThrottles();
      await coordinator.pausePlayback();
      settleThrottles();
      await coordinator.stopPlayback();
      await pumpEventQueue();

      expect(recorder.paths, ['/scrobble/start']);
      expect(replacement.paths, isEmpty);
    });

    test('movies use the movie object with no episode', () async {
      await coordinator.startPlayback(_movie(), _client());
      await pumpEventQueue();

      expect(recorder.calls.single.body, {
        'progress': 0.0,
        'movie': {
          'ids': {'tmdb': 603},
        },
      });
    });

    test('a queued stop survives the next item starting behind a gated request', () async {
      await coordinator.startPlayback(_episode(durationMs: 100000), _client());
      await pumpEventQueue();
      coordinator.updatePosition(const Duration(milliseconds: 30000));

      // Hold a request so the swap's stop and the new item's start both queue.
      recorder.gate = Completer<void>();
      settleThrottles();
      final paused = coordinator.pausePlayback();
      await pumpEventQueue();

      final stopped = coordinator.stopPlayback();
      settleThrottles();
      final started = coordinator.startPlayback(_movie(), _client());

      recorder.gate!.complete();
      await paused;
      await stopped;
      await started;
      await pumpEventQueue();

      expect(recorder.paths, ['/scrobble/start', '/scrobble/pause', '/scrobble/stop', '/scrobble/start']);
      expect(recorder.calls[2].body['show'], {
        'ids': {'tvdb': 12345},
      });
      expect(recorder.calls[3].body['movie'], {
        'ids': {'tmdb': 603},
      });
    });

    test('a repeated state inside the debounce window is sent once', () async {
      await coordinator.startPlayback(_episode(durationMs: 100000), _client());
      await pumpEventQueue();
      coordinator.updatePosition(const Duration(milliseconds: 40000));

      settleThrottles();
      await coordinator.pausePlayback();
      // Same state, same instant — the player emits several of these per seek.
      await coordinator.pausePlayback();
      await pumpEventQueue();

      expect(recorder.paths, ['/scrobble/start', '/scrobble/pause']);
    });

    test('seeking alone reports nothing', () async {
      await coordinator.startPlayback(_episode(durationMs: 100000), _client());
      await pumpEventQueue();

      coordinator.updatePosition(const Duration(milliseconds: 10000));
      coordinator.updatePosition(const Duration(milliseconds: 60000));
      coordinator.updatePosition(const Duration(milliseconds: 20000));
      await pumpEventQueue();

      expect(recorder.paths, ['/scrobble/start']);
    });

    // Observed live: quitting seconds after an autoplayed episode opened a
    // session left Simkl showing the item as playing until its runtime elapsed,
    // because the terminal report was under a progress floor.
    test('a session opened at zero progress is still closed on stop', () async {
      await coordinator.startPlayback(_episode(durationMs: 100000), _client());
      await pumpEventQueue();
      expect(recorder.callFor('/scrobble/start').body['progress'], 0.0);

      settleThrottles();
      await coordinator.stopPlayback();

      expect(recorder.paths, ['/scrobble/start', '/scrobble/stop']);
      expect(recorder.callFor('/scrobble/stop').body['progress'], 0.0);
    });

    test('a stop with no session behind it is not sent', () async {
      // No ids resolve for this item, so playback never opened a session.
      await coordinator.startPlayback(
        _episode(durationMs: 100000),
        _FakeMediaServerClient(externalIdsByItem: const {}),
      );
      coordinator.updatePosition(const Duration(milliseconds: 40000));
      await coordinator.stopPlayback();
      await pumpEventQueue();

      expect(recorder.calls, isEmpty);
    });

    test('a disabled tracker reports nothing', () async {
      await simkl.setEnabled(false);

      await coordinator.startPlayback(_episode(durationMs: 100000), _client());
      coordinator.updatePosition(const Duration(milliseconds: 40000));
      await coordinator.stopPlayback();
      await pumpEventQueue();

      expect(recorder.calls, isEmpty);
    });

    test('a failing report never escapes to the caller', () async {
      recorder.status = 500;

      await coordinator.startPlayback(_episode(durationMs: 100000), _client());
      await pumpEventQueue();
      coordinator.updatePosition(const Duration(milliseconds: 40000));
      settleThrottles();
      await coordinator.stopPlayback();

      expect(recorder.paths, ['/scrobble/start', '/scrobble/stop']);
    });
  });
}
