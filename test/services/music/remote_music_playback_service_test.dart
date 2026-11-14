import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/music/music_output.dart';
import 'package:plezy/services/music/music_playback_service.dart';
import 'package:plezy/services/music/remote_music_playback_service.dart';
import 'package:plezy/services/music/remote_track_url_resolver.dart';
import 'package:plezy/services/music_assistant/music_assistant_api.dart';
import 'package:plezy/services/music_assistant/music_assistant_players.dart';

import '../../music_assistant/fake_ma_server.dart';

const _queueId = 'RINCON_1';

/// Hands back a predictable URL per track, so a reading can be matched to the
/// track it came from without any network.
class _StubResolver implements RemoteTrackUrlResolver {
  final List<String> resolved = [];
  final Set<String> failFor = {};

  @override
  Future<RemoteTrackMedia> resolve(MediaItem track, {required String? targetServerId}) async {
    if (failFor.contains(track.id)) throw StateError('cannot resolve ${track.id}');
    resolved.add(track.id);
    return RemoteTrackMedia('https://plex/${track.id}.flac?X-Plex-Token=t');
  }
}

MediaItem _track(String id) =>
    MediaItem.plex(id: id, serverId: 'plex-1', kind: MediaKind.track, title: 'Track $id', durationMs: 200000);

Map<String, dynamic> _queueFrame({
  String state = 'playing',
  double elapsed = 5,
  int index = 0,
  String? handle,
  int items = 1,
}) => {
  'queue_id': _queueId,
  'state': state,
  'elapsed_time': elapsed,
  'current_index': index,
  'items': items,
  if (handle != null)
    'current_item': {
      'name': 'whatever the file says',
      'duration': 200,
      'streamdetails': {'item_id': handle},
    },
};

void main() {
  late FakeMaServer server;
  late MusicAssistantApi api;
  late MusicAssistantPlayers players;
  late _StubResolver resolver;
  late MultiServerManager serverManager;
  late RemoteMusicPlaybackService service;

  const output = MusicOutput(
    id: 'ma-1|$_queueId',
    name: '➡️ 🥙 Dining Room',
    available: true,
    serverId: 'ma-1',
    playerId: _queueId,
    volume: 2,
  );

  setUp(() async {
    server = FakeMaServer(responder: (_, _) => null);
    api = MusicAssistantApi(channelFactory: server.open, autoReconnect: false);
    await api.connect(Uri.parse('http://10.0.2.107:8095'));
    players = MusicAssistantPlayers(api);
    resolver = _StubResolver();
    serverManager = MultiServerManager();
    service = RemoteMusicPlaybackService(
      output: output,
      players: players,
      resolver: resolver,
      serverManager: serverManager,
      // Long enough that no test depends on the safety-net poll firing.
      pollInterval: const Duration(minutes: 5),
    );
  });

  tearDown(() async {
    service.dispose();
    await api.dispose();
  });

  void push(Map<String, dynamic> frame) =>
      server.pushEvent({'event': 'queue_updated', 'object_id': _queueId, 'data': frame});

  /// A `queue_time_updated` tick: a bare position, carrying every identity
  /// field forward from the last real reading.
  void pushTick(double seconds) =>
      server.pushEvent({'event': 'queue_time_updated', 'object_id': _queueId, 'data': seconds});

  group('a speaker this session never played to', () {
    test('is never stopped, because whatever it is doing is not ours', () async {
      // Selecting an output builds one of these, and switching away stops the
      // outgoing engine. Glancing at a room in the picker must not kill what
      // that room was already playing — measured doing exactly that to a Sonos
      // playing Spotify.
      await service.stop();
      expect(server.commands, isNot(contains('player_queues/stop')));
    });

    test('is not touched at all just by being selected', () async {
      await pumpEventQueue(times: 10);
      expect(
        server.commands.where((c) => c.startsWith('player_queues/') && c != 'player_queues/all'),
        isEmpty,
        reason: 'constructing the engine may only read',
      );
    });
  });

  group('status', () {
    test('is idle before any reading — nothing is known, so nothing is claimed', () {
      expect(service.status, MusicPlaybackStatus.idle);
      expect(service.currentTrack, isNull);
      expect(service.position, Duration.zero);
    });

    test('follows the server through playing and buffering', () async {
      push(_queueFrame(handle: 'x'));
      await pumpEventQueue();
      expect(service.status, MusicPlaybackStatus.playing);

      push(_queueFrame(state: 'buffering', handle: 'x'));
      await pumpEventQueue();
      expect(service.status, MusicPlaybackStatus.loading);
    });

    test('idle with an item is paused — the measured behaviour for a URL queue', () async {
      // Music Assistant reports `idle` rather than `paused` when a queue of
      // plain URLs is paused, keeping current_item and elapsed_time, and
      // `player_queues/play` resumes from there. Measured twice on a real
      // Sonos. Reporting this as idle would hide the mini player mid-track.
      await service.playFromList(
        tracks: [_track('a')],
        playContext: const MusicPlayContext(title: 'Album', kind: MusicPlayContextKind.album),
      );
      push(_queueFrame(state: 'idle', handle: 'https://plex/a.flac?X-Plex-Token=t'));
      await pumpEventQueue();
      expect(service.status, MusicPlaybackStatus.paused);
    });

    test('idle with no item at all is idle', () async {
      push(_queueFrame(state: 'idle'));
      await pumpEventQueue();
      expect(service.status, MusicPlaybackStatus.idle);
    });
  });

  group('playFromList', () {
    test('a reading from before the queue we just sent does not disown the session', () async {
      // Captured on the device: `Mini player hidden: track=null,
      // suppressedByRoute=false, dismissed=false, openSheets=0`. Not
      // suppression, not a sheet — the session simply had no current track.
      //
      // Between `play_media` returning and the server reporting the new item,
      // a reading still describes whatever was playing before. Treating that
      // as somebody else's queue discarded the session at the moment it
      // started, and `currentTrack` — which the mini player is gated on —
      // went null. Audio in the room, nothing on screen to stop it.
      await service.playFromList(
        tracks: [_track('a'), _track('b')],
        playContext: const MusicPlayContext(title: 'Album', kind: MusicPlayContextKind.album),
      );
      expect(service.currentTrack, isNotNull, reason: 'the queue we just sent is ours');

      push(_queueFrame(handle: 'something-that-was-playing-before'));
      await pumpEventQueue();

      expect(
        service.currentTrack,
        isNotNull,
        reason: 'a server that has not caught up yet is not a server playing someone else\'s queue',
      );

      // Once it does catch up, the session carries on as ours.
      push(_queueFrame(handle: 'https://plex/a.flac?X-Plex-Token=t'));
      await pumpEventQueue();
      expect(service.currentTrack, isNotNull);

      // And a queue somebody else really took over keeps reporting their
      // track, so it crosses the threshold on the very next reading.
      push(_queueFrame(handle: 'someone-else-entirely'));
      await pumpEventQueue();
      push(_queueFrame(handle: 'someone-else-entirely'));
      await pumpEventQueue();
      expect(
        service.currentTrack,
        isNull,
        reason: 'once our queue has been observed, a different one really is different',
      );
    });

    test('position ticks cannot disown a queue on their own', () async {
      // `queue_time_updated` carries the previous reading's identity forward,
      // about once a second. If ticks counted, one stale handle would reach the
      // disowning threshold by itself roughly a second after playback started
      // — which is the "appears then fades" the transport was reported with.
      await service.playFromList(
        tracks: [_track('a'), _track('b')],
        playContext: const MusicPlayContext(title: 'Album', kind: MusicPlayContextKind.album),
      );
      service.errors.listen((_) {});

      // One real reading naming something else, then ticks that merely repeat
      // it — which is what the wire actually looks like.
      push(_queueFrame(handle: 'whatever-was-playing-before'));
      await pumpEventQueue();
      for (var i = 0; i < 10; i++) {
        pushTick(5 + i.toDouble());
        await pumpEventQueue();
      }

      expect(service.currentTrack, isNotNull, reason: 'ten ticks are one observation repeated, not ten disagreements');
      expect(service.hasForeignQueue, isFalse);
    });

    test('the transport names the track that is playing, not the album\'s first', () async {
      // The server's queue starts at the track the listener chose, so a
      // position within what was sent is not a position in the local queue —
      // they differ by the start index. Conflating them named the album's
      // first track while its fifth played: audible music, wrong title, and
      // every existing test started at index 0 so none of them saw it.
      final album = [_track('a'), _track('b'), _track('c'), _track('d'), _track('e')];
      await service.playFromList(
        tracks: album,
        startTrack: album[4],
        playContext: const MusicPlayContext(title: 'Album', kind: MusicPlayContextKind.album),
      );
      expect(service.currentTrack?.id, album[4].id, reason: 'the tapped track is what plays');

      // The server reports the first handle it was sent — which *is* the fifth
      // track, because that is where the server queue starts.
      push(_queueFrame(handle: 'https://plex/e.flac?X-Plex-Token=t'));
      await pumpEventQueue();

      expect(service.currentTrack?.id, album[4].id, reason: 'still the track that is audible');
      expect(service.currentIndex, 4, reason: 'and at its place in the album, not the queue we sent');
    });

    test('a URL queue stays ours even when the server also names it differently', () async {
      // The end-to-end shape of the same regression: the server reports the
      // URL we sent under `streamdetails.item_id` *and* a uri of its own under
      // `media_item`. Matching only the latter disowned the queue while it
      // played the track that had just been tapped.
      await service.playFromList(
        tracks: [_track('a'), _track('b')],
        playContext: const MusicPlayContext(title: 'Album', kind: MusicPlayContextKind.album),
      );
      service.errors.listen((_) {});

      Map<String, dynamic> reading() => {
        'event': 'queue_updated',
        'object_id': _queueId,
        'data': {
          'queue_id': _queueId,
          'state': 'playing',
          'elapsed_time': 2.0,
          'current_index': 0,
          'items': 2,
          'current_item': {
            'name': 'a',
            'duration': 100,
            'streamdetails': {'item_id': 'https://plex/a.flac?X-Plex-Token=t'},
            'media_item': {'item_id': '999', 'uri': 'builtin://something-else'},
          },
        },
      };

      // Twice, because the server keeps reporting it — which is what pushed a
      // misread past the disowning threshold in the captured session.
      server.pushEvent(reading());
      await pumpEventQueue();
      server.pushEvent(reading());
      await pumpEventQueue();

      expect(service.hasForeignQueue, isFalse, reason: 'the server is playing exactly what was sent');
      expect(service.currentTrack?.id, 'a');
    });

    test('pause shows as paused at once, not when the speaker gets round to it', () async {
      // Status was read from the server's last reading alone, so pressing
      // pause changed nothing on screen until a round trip to the speaker came
      // back — a second or more, during which the button looks broken and
      // people press it again.
      await service.playFromList(
        tracks: [_track('a'), _track('b')],
        playContext: const MusicPlayContext(title: 'Album', kind: MusicPlayContextKind.album),
      );
      push(_queueFrame(handle: 'https://plex/a.flac?X-Plex-Token=t'));
      await pumpEventQueue();
      expect(service.status, MusicPlaybackStatus.playing);

      await service.pause();
      expect(service.status, MusicPlaybackStatus.paused, reason: 'the finger, not the round trip');

      // And the server's own reading takes over once it agrees.
      push(_queueFrame(state: 'paused', handle: 'https://plex/a.flac?X-Plex-Token=t'));
      await pumpEventQueue();
      expect(service.status, MusicPlaybackStatus.paused);

      // Someone pressing play in the room is still seen: the intent is not
      // held past the point the server answers it.
      push(_queueFrame(handle: 'https://plex/a.flac?X-Plex-Token=t'));
      await pumpEventQueue();
      expect(service.status, MusicPlaybackStatus.playing);
    });

    test('starts on one resolve so audio does not wait for the whole queue', () async {
      await service.playFromList(
        tracks: [_track('a'), _track('b'), _track('c')],
        playContext: const MusicPlayContext(title: 'Album', kind: MusicPlayContextKind.album),
      );
      final first = server.requests.firstWhere((r) => r['command'] == 'player_queues/play_media');
      final args = first['args'] as Map<String, dynamic>;
      expect(args['option'], 'replace');
      expect(args['media'], ['https://plex/a.flac?X-Plex-Token=t']);
      expect(args['queue_id'], _queueId);
    });

    test('appends the rest behind the playing track, in order', () async {
      await service.playFromList(
        tracks: [_track('a'), _track('b'), _track('c')],
        playContext: const MusicPlayContext(title: 'Album', kind: MusicPlayContextKind.album),
      );
      await pumpEventQueue(times: 40);
      final adds = server.requests
          .where((r) => r['command'] == 'player_queues/play_media')
          .where((r) => (r['args'] as Map)['option'] == 'add')
          .toList();
      expect(adds, hasLength(1));
      expect((adds.single['args'] as Map)['media'], [
        'https://plex/b.flac?X-Plex-Token=t',
        'https://plex/c.flac?X-Plex-Token=t',
      ]);
    });

    test('starting midway sends that track first, so server indices line up', () async {
      final tracks = [_track('a'), _track('b'), _track('c')];
      await service.playFromList(
        tracks: tracks,
        startTrack: tracks[1],
        playContext: const MusicPlayContext(title: 'Album', kind: MusicPlayContextKind.album),
      );
      final first = server.requests.firstWhere((r) => r['command'] == 'player_queues/play_media');
      expect((first['args'] as Map)['media'], ['https://plex/b.flac?X-Plex-Token=t']);
    });

    test('a track that cannot be resolved is reported rather than silently dropped', () async {
      resolver.failFor.add('b');
      final errors = <Object>[];
      service.errors.listen(errors.add);
      await service.playFromList(
        tracks: [_track('a'), _track('b'), _track('c')],
        playContext: const MusicPlayContext(title: 'Album', kind: MusicPlayContextKind.album),
      );
      await pumpEventQueue(times: 40);
      expect(errors, isNotEmpty);
      final adds = server.requests
          .where((r) => r['command'] == 'player_queues/play_media')
          .where((r) => (r['args'] as Map)['option'] == 'add');
      expect((adds.single['args'] as Map)['media'], ['https://plex/c.flac?X-Plex-Token=t']);
    });

    test('a failure to start surfaces and does not leave a phantom queue', () async {
      resolver.failFor.add('a');
      final errors = <Object>[];
      service.errors.listen(errors.add);
      await service.playFromList(
        tracks: [_track('a')],
        playContext: const MusicPlayContext(title: 'Album', kind: MusicPlayContextKind.album),
      );
      await pumpEventQueue();
      expect(errors, hasLength(1));
      expect(server.commands, isNot(contains('player_queues/play_media')));
    });
  });

  group('reading the server rather than modelling it', () {
    test('the sounding handle decides which track is current, not our cursor', () async {
      await service.playFromList(
        tracks: [_track('a'), _track('b'), _track('c')],
        playContext: const MusicPlayContext(title: 'Album', kind: MusicPlayContextKind.album),
      );
      await pumpEventQueue(times: 40);

      // The server says it is on the third thing we sent. Note the index it
      // reports is deliberately wrong here: the handle is what names what is
      // audible, and it must win.
      push(_queueFrame(handle: 'https://plex/c.flac?X-Plex-Token=t', index: 0, items: 3));
      await pumpEventQueue();
      expect(service.currentTrack?.id, 'c');
      expect(service.currentIndex, 2);
    });

    test('a track we never sent is a conflict, not a relabelling', () async {
      await service.playFromList(
        tracks: [_track('a')],
        playContext: const MusicPlayContext(title: 'Album', kind: MusicPlayContextKind.album),
      );
      final errors = <Object>[];
      service.errors.listen(errors.add);

      // Twice: one reading is the server not having caught up with the queue
      // we just sent, which on the device disowned the session at the moment
      // it started. A queue somebody else took over keeps reporting their
      // track, so it still crosses the threshold immediately.
      push(_queueFrame(handle: 'spotify://somebody-elses-track', items: 1));
      await pumpEventQueue();
      push(_queueFrame(handle: 'spotify://somebody-elses-track', items: 1));
      await pumpEventQueue();

      expect(service.hasForeignQueue, isTrue);
      // Critically: no track is claimed. Showing ours over their audio is the
      // wrong-audio bug this whole design is arranged to avoid.
      expect(service.currentTrack, isNull);
      expect(service.currentIndex, -1);
      expect(errors, isNotEmpty);
    });

    test('recovers when the server comes back to something we sent', () async {
      await service.playFromList(
        tracks: [_track('a')],
        playContext: const MusicPlayContext(title: 'Album', kind: MusicPlayContextKind.album),
      );
      service.errors.listen((_) {});
      // Twice — see the conflict test above.
      push(_queueFrame(handle: 'spotify://theirs'));
      await pumpEventQueue();
      push(_queueFrame(handle: 'spotify://theirs'));
      await pumpEventQueue();
      expect(service.hasForeignQueue, isTrue);

      push(_queueFrame(handle: 'https://plex/a.flac?X-Plex-Token=t'));
      await pumpEventQueue();
      expect(service.hasForeignQueue, isFalse);
      expect(service.currentTrack?.id, 'a');
    });

    test('duration comes from what the server read out of the file', () async {
      await service.playFromList(
        tracks: [_track('a')],
        playContext: const MusicPlayContext(title: 'Album', kind: MusicPlayContextKind.album),
      );
      push(_queueFrame(handle: 'https://plex/a.flac?X-Plex-Token=t'));
      await pumpEventQueue();
      expect(service.duration, const Duration(seconds: 200));
    });
  });

  group('transport', () {
    setUp(() async {
      await service.playFromList(
        tracks: [_track('a'), _track('b')],
        playContext: const MusicPlayContext(title: 'Album', kind: MusicPlayContextKind.album),
      );
      await pumpEventQueue(times: 40);
    });

    test('sends the queue commands rather than doing anything locally', () async {
      await service.play();
      await service.pause();
      await service.next();
      await service.previous();
      await service.seek(const Duration(seconds: 42));
      expect(
        server.commands,
        containsAll(<String>[
          'player_queues/play',
          'player_queues/pause',
          'player_queues/next',
          'player_queues/previous',
          'player_queues/seek',
        ]),
      );
      expect(server.argsFor('player_queues/seek')['position'], 42);
    });

    test('togglePlayPause reads the server state to decide', () async {
      push(_queueFrame(handle: 'https://plex/a.flac?X-Plex-Token=t'));
      await pumpEventQueue();
      await service.togglePlayPause();
      expect(server.commands, contains('player_queues/pause'));
    });

    test('jumpTo outside the queue is refused rather than sent', () async {
      await service.jumpTo(99);
      expect(server.commands, isNot(contains('player_queues/play_index')));
      await service.jumpTo(1);
      expect(server.argsFor('player_queues/play_index')['index'], 1);
    });

    test('stop clears the session so the mini player goes away', () async {
      await service.stop();
      expect(server.commands, contains('player_queues/stop'));
      expect(service.queue, isEmpty);
      expect(service.currentTrack, isNull);
      expect(service.playContext, isNull);
    });

    test('stop leaves a diverged queue alone — it is somebody else\'s now', () async {
      service.errors.listen((_) {});
      // Twice — see the conflict test above.
      push(_queueFrame(handle: 'spotify://theirs'));
      await pumpEventQueue();
      push(_queueFrame(handle: 'spotify://theirs'));
      await pumpEventQueue();
      expect(service.hasForeignQueue, isTrue);

      await service.stop();
      expect(server.commands, isNot(contains('player_queues/stop')));
      expect(service.queue, isEmpty, reason: 'the local session still ends');
    });

    test('a command that fails surfaces instead of being swallowed', () async {
      server.responder = (command, args) => command == 'player_queues/next' ? const MaErrorReply(1, 'nope') : null;
      final errors = <Object>[];
      service.errors.listen(errors.add);
      await service.next();
      await pumpEventQueue();
      expect(errors, hasLength(1));
    });
  });

  group('volume', () {
    test('reaches the speaker and is confirmed by reading it back', () async {
      server.responder = (command, args) => command == 'players/all'
          ? [
              {
                'player_id': _queueId,
                'display_name': 'Dining Room',
                'provider': 'sonos',
                'available': true,
                'state': 'playing',
                'volume_level': 7,
                'supported_features': ['volume_set'],
              },
            ]
          : null;
      await service.setVolume(7);
      expect(server.argsFor('players/cmd/volume_set'), {'player_id': _queueId, 'volume_level': 7});
      expect(service.volume, 7);
    });

    test('is clamped to the 0-100 the rest of the app uses', () async {
      await service.setVolume(500);
      expect(service.volume, 100);
    });
  });

  group('queue edits', () {
    test('re-publish the tail, because the server is what actually sounds', () async {
      await service.playFromList(
        tracks: [_track('a'), _track('b')],
        playContext: const MusicPlayContext(title: 'Album', kind: MusicPlayContextKind.album),
      );
      await pumpEventQueue(times: 40);
      service.addToEnd([_track('d')]);
      await pumpEventQueue(times: 40);
      final replaced = server.requests
          .where((r) => r['command'] == 'player_queues/play_media')
          .where((r) => (r['args'] as Map)['option'] == 'replace_next')
          .toList();
      expect(replaced, isNotEmpty);
      expect((replaced.last['args'] as Map)['media'], [
        'https://plex/b.flac?X-Plex-Token=t',
        'https://plex/d.flac?X-Plex-Token=t',
      ]);
    });

    test('repeat mode is pushed, since the server decides what plays next', () async {
      service.setRepeatMode(MusicRepeatMode.all);
      await pumpEventQueue();
      expect(service.repeatMode, MusicRepeatMode.all);
      expect(server.argsFor('player_queues/repeat')['repeat_mode'], 'all');
    });
  });
}
