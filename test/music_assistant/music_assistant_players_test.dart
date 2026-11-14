import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/music/music_playback_service.dart' show MusicRepeatMode;
import 'package:plezy/services/music_assistant/music_assistant_api.dart';
import 'package:plezy/services/music_assistant/music_assistant_players.dart';

import 'fake_ma_server.dart';

/// Fixtures copied from real 2.6.3 frames rather than invented, so a field
/// renamed upstream fails here instead of in front of a speaker.
Map<String, dynamic> _sonos({
  String id = 'RINCON_7828CA0DABA601400',
  bool available = true,
  String? activeSource = 'RINCON_7828CA0DABA601400',
  int volume = 2,
  String state = 'idle',
  List<String> groupChilds = const [],
  String? activeGroup,
}) => {
  'player_id': id,
  'name': 'Sonos',
  'display_name': '➡️ 🥙 Dining Room',
  'provider': 'sonos',
  'type': 'player',
  'available': available,
  'powered': true,
  'state': state,
  'active_source': activeSource,
  'active_group': activeGroup,
  'group_childs': groupChilds,
  'volume_level': volume,
  'volume_muted': false,
  'supported_features': ['seek', 'volume_set', 'next_previous', 'pause', 'enqueue'],
  'enabled': true,
};

Map<String, dynamic> _queue({
  String id = 'RINCON_7828CA0DABA601400',
  String state = 'playing',
  double elapsed = 12.5,
  double? updatedAt,
  int index = 0,
  int items = 3,
  String url = 'https://plex/library/parts/1/2/file.flac?X-Plex-Token=t',
  num duration = 146,
}) => {
  'queue_id': id,
  'state': state,
  'elapsed_time': elapsed,
  'elapsed_time_last_updated': updatedAt,
  'current_index': index,
  'items': items,
  'current_item': {
    'queue_item_id': 'abc',
    'name': ':zoviet*france: - The Grit in the Clouds',
    'duration': duration,
    'streamdetails': {'item_id': url, 'provider': 'builtin'},
    'media_item': {'item_id': url, 'provider': 'builtin'},
  },
};

/// A frame from 2.10.9, with the fields the rename touched. Measured in a live
/// group: the leader lists itself first, and a follower carries nothing but
/// `synced_to`.
Map<String, dynamic> _current({
  String id = 'RINCON_LEADER',
  List<String> groupMembers = const [],
  String? syncedTo,
  String? activeSource,
  String playbackState = 'idle',
  bool private = false,
  bool hideInUi = false,
}) => {
  'player_id': id,
  'name': 'Kitchen',
  'provider': 'sonos',
  'type': 'player',
  'available': true,
  'powered': true,
  'playback_state': playbackState,
  'group_members': groupMembers,
  'synced_to': syncedTo,
  'active_group': null,
  'active_source': activeSource ?? id,
  'volume_level': 12,
  'supported_features': ['seek', 'volume_set', 'next_previous'],
  'private': private,
  'hide_in_ui': hideInUi,
};

void main() {
  group('MaPlayer on 2.10.9', () {
    test('reads the current names, without leaning on the aliases', () {
      final player = MaPlayer.fromJson(_current(playbackState: 'playing', groupMembers: ['RINCON_LEADER', 'B']))!;

      expect(player.name, 'Kitchen');
      expect(player.state, MaPlayerState.playing);
      expect(player.isGroup, isTrue);
    });

    test('a leader, which lists itself, is a destination', () {
      final leader = MaPlayer.fromJson(_current(groupMembers: ['RINCON_LEADER', 'B']))!;

      expect(leader.isFollower, isFalse);
    });

    test('a follower is recognised by synced_to alone', () {
      final follower = MaPlayer.fromJson(_current(id: 'B', syncedTo: 'RINCON_LEADER', activeSource: 'RINCON_LEADER'))!;

      expect(follower.isFollower, isTrue);
      expect(follower.hasForeignSource, isFalse, reason: 'its source is its leader, not somebody else');
    });

    test('a private or hidden player reads as hidden', () {
      expect(MaPlayer.fromJson(_current(private: true))!.hidden, isTrue);
      expect(MaPlayer.fromJson(_current(hideInUi: true))!.hidden, isTrue);
      expect(MaPlayer.fromJson(_current())!.hidden, isFalse);
    });
  });

  group('sync groups on 2.10.9', () {
    Map<String, dynamic> group({String id = 'syncgroup_abc', List<String> members = const ['A', 'B']}) => {
      ..._current(id: id, groupMembers: members),
      'type': 'group',
      'provider': 'sync_group',
      'volume_level': null,
      'group_volume': 35,
      'supported_features': ['play_media', 'volume_set', 'set_members'],
    };

    Future<MusicAssistantPlayers> playersOn(FakeMaServer server) async {
      final api = MusicAssistantApi(channelFactory: server.open, autoReconnect: false);
      addTearDown(api.dispose);
      await api.connect(Uri.parse('http://127.0.0.1:8095'));
      return MusicAssistantPlayers(api);
    }

    test('a group reads the volume it actually has, not silence', () {
      // `volume_level` is null on a group. Read as 0, the slider opens at
      // nothing and the first read-back after any change snaps it there.
      expect(MaPlayer.fromJson(group())!.volumeLevel, 35);
    });

    test('is a group even before it has reported any members', () {
      final player = MaPlayer.fromJson(group(members: const []))!;

      expect(player.isGroup, isTrue);
      expect(player.supportsGrouping, isFalse, reason: 'a group cannot be a member of a group');
    });

    test('a room still naming a stopped group is not reported as busy', () {
      final room = MaPlayer.fromJson(_current(id: 'A', activeSource: 'syncgroup_abc'))!;

      expect(room.hasForeignSource, isFalse);
    });

    test('reuses a group holding exactly these rooms, in any order', () async {
      final server = FakeMaServer(
        responder: (command, args) => [
          group(members: const ['B', 'A']),
        ],
      );
      final players = await playersOn(server);

      final found = await players.syncGroup({'A', 'B'}, name: 'A + B');

      expect(found.playerId, 'syncgroup_abc');
      expect(server.commands, isNot(contains('players/create_group_player')));
    });

    test('a group holding more rooms is not these rooms', () async {
      final created = group(id: 'syncgroup_new');
      var made = false;
      final server = FakeMaServer(
        responder: (command, args) {
          if (command == 'players/create_group_player') {
            made = true;
            // The real reply: an accepted group that reports no members yet.
            return {...created, 'group_members': <String>[]};
          }
          return [
            group(members: const ['A', 'B', 'C']),
            if (made) created,
          ];
        },
      );
      final players = await playersOn(server);

      final found = await players.syncGroup({'A', 'B'}, name: 'Kitchen + Dining Room');

      expect(found.playerId, 'syncgroup_new');
      expect(server.argsFor('players/create_group_player'), {
        'provider': 'sync_group',
        'name': 'Kitchen + Dining Room',
        'members': ['A', 'B'],
        'dynamic': true,
      });
    });

    test('a room the server dropped fails loudly and leaves no half group behind', () async {
      var made = false;
      final server = FakeMaServer(
        responder: (command, args) {
          if (command == 'players/create_group_player') {
            made = true;
            return group(id: 'syncgroup_new', members: const []);
          }
          if (command == 'players/remove_group_player') return null;
          return [
            if (made) group(id: 'syncgroup_new', members: const ['A']),
          ];
        },
      );
      final players = await playersOn(server);

      await expectLater(
        players.syncGroup({'A', 'B'}, name: 'A + B'),
        throwsA(isA<MaGroupRefusedException>().having((e) => e.refused, 'refused', {'B'})),
      );
      expect(server.argsFor('players/remove_group_player'), {'player_id': 'syncgroup_new'});
    });
  });

  group('MaPlayer', () {
    test('prefers display_name, which is what the speaker is actually called', () {
      final player = MaPlayer.fromJson(_sonos())!;
      expect(player.name, '➡️ 🥙 Dining Room');
      expect(player.playerId, 'RINCON_7828CA0DABA601400');
      expect(player.provider, 'sonos');
      expect(player.volumeLevel, 2);
    });

    test('reads capabilities off supported_features rather than assuming them', () {
      final player = MaPlayer.fromJson(_sonos())!;
      expect(player.supportsVolume, isTrue);
      expect(player.supportsSeek, isTrue);
      expect(player.supportsNextPrevious, isTrue);
      expect(MaPlayer.fromJson({..._sonos(), 'supported_features': <String>[]})!.supportsVolume, isFalse);
    });

    test('a missing available field means available, not hidden', () {
      final raw = _sonos()..remove('available');
      expect(MaPlayer.fromJson(raw)!.available, isTrue);
    });

    test('its own id as active_source is Music Assistant driving it, not a foreign source', () {
      expect(MaPlayer.fromJson(_sonos())!.hasForeignSource, isFalse);
      expect(MaPlayer.fromJson(_sonos(activeSource: null))!.hasForeignSource, isFalse);
      expect(MaPlayer.fromJson(_sonos(activeSource: 'Spotify'))!.hasForeignSource, isTrue);
    });

    test('a group leader driving its own group is not foreign', () {
      final player = MaPlayer.fromJson(_sonos(activeSource: 'group-1', activeGroup: 'group-1'))!;
      expect(player.hasForeignSource, isFalse);
    });

    test('group_childs makes it a group', () {
      expect(MaPlayer.fromJson(_sonos())!.isGroup, isFalse);
      expect(MaPlayer.fromJson(_sonos(groupChilds: ['a', 'b']))!.isGroup, isTrue);
    });

    test('a frame without a player_id is dropped rather than half-decoded', () {
      expect(MaPlayer.fromJson({'name': 'x'}), isNull);
      expect(MaPlayer.fromJson('not a map'), isNull);
    });
  });

  group('MaQueueState', () {
    test('takes the sounding handle from streamdetails.item_id', () {
      final state = MaQueueState.fromJson(_queue())!;
      expect(state.currentItemId, 'https://plex/library/parts/1/2/file.flac?X-Plex-Token=t');
      expect(state.currentItemName, ':zoviet*france: - The Grit in the Clouds');
      expect(state.currentDuration, const Duration(seconds: 146));
      expect(state.itemCount, 3);
      expect(state.currentIndex, 0);
    });

    test('falls back to media_item.item_id when streamdetails is absent', () {
      final raw = _queue();
      (raw['current_item'] as Map).remove('streamdetails');
      expect(MaQueueState.fromJson(raw)!.currentItemId, contains('file.flac'));
    });

    test('a library track is recognised by its uri, which is what was sent', () {
      // Captured from the real server. `item_id` is the bare id, and the app
      // sends `uri` — so matching on `item_id` never recognised this app's own
      // queue. Every reading looked foreign, the session reported no current
      // track, and audio played to the speaker with no transport on screen.
      final raw = <String, dynamic>{
        'queue_id': 'RINCON_7828CA0DABA601400',
        'state': 'playing',
        'elapsed_time': 3.2,
        'current_index': 0,
        'items': 1,
        'current_item': {
          'queue_item_id': '1e2331ea8297477787c943d024773b85',
          'name': 'Atmosphere - @',
          'duration': 146,
          'media_item': {'item_id': '23461', 'uri': 'library://track/23461', 'provider': 'library'},
        },
      };

      expect(MaQueueState.fromJson(raw)!.currentItemId, 'library://track/23461');
    });

    test('a queued URL is recognised by the URL that was sent', () {
      // The Plex path queues plain URLs, and the server names them back under
      // `streamdetails.item_id`. Preferring `media_item.uri` — which a library
      // track needs — made every URL queue look like somebody else's: the
      // session reported no current track and the transport vanished while the
      // speaker played the track that had just been tapped. Captured from a
      // real session doing exactly that.
      const url = 'https://10-0-2-105.plex.direct:32400/library/parts/1/2/file.flac?X-Plex-Token=t';
      final raw = <String, dynamic>{
        'queue_id': 'RINCON_74CA6074EA9A01400',
        'state': 'playing',
        'elapsed_time': 2.0,
        'current_index': 0,
        'items': 12,
        'current_item': {
          'queue_item_id': 'aa11',
          'name': "Bad Wolves - I'll Be There",
          'duration': 210,
          'streamdetails': {'item_id': url, 'provider': 'builtin'},
          'media_item': {'item_id': 'something-of-its-own', 'uri': 'builtin://something-else'},
        },
      };

      expect(
        MaQueueState.fromJson(raw)!.currentItemIds,
        contains(url),
        reason: 'the URL that was sent has to be among the identifiers a reading offers',
      );
    });

    test('a duration of zero is no duration rather than a zero-length track', () {
      expect(MaQueueState.fromJson(_queue(duration: 0))!.currentDuration, isNull);
    });

    group('positionAt', () {
      test('advances a playing reading by wall clock, because ticks are ~1/s', () {
        final takenAt = DateTime.now().subtract(const Duration(seconds: 4));
        final state = MaQueueState.fromJson(
          _queue(elapsed: 10, updatedAt: takenAt.toUtc().millisecondsSinceEpoch / 1000),
        )!;
        expect(state.positionAt(DateTime.now()).inSeconds, 14);
      });

      test('does not advance a paused reading', () {
        final takenAt = DateTime.now().subtract(const Duration(seconds: 30));
        final state = MaQueueState.fromJson(
          _queue(state: 'paused', elapsed: 10, updatedAt: takenAt.toUtc().millisecondsSinceEpoch / 1000),
        )!;
        expect(state.positionAt(DateTime.now()).inSeconds, 10);
      });

      test('clamps to the track runtime — this number reaches the lock screen', () {
        final takenAt = DateTime.now().subtract(const Duration(seconds: 600));
        final state = MaQueueState.fromJson(
          _queue(elapsed: 140, duration: 146, updatedAt: takenAt.toUtc().millisecondsSinceEpoch / 1000),
        )!;
        expect(state.positionAt(DateTime.now()), const Duration(seconds: 146));
      });

      test('without a timestamp it reports the reading as given', () {
        final state = MaQueueState.fromJson(_queue(elapsed: 7))!;
        expect(state.positionAt(DateTime.now()), const Duration(seconds: 7));
      });
    });
  });

  group('MusicAssistantPlayers', () {
    late FakeMaServer server;
    late MusicAssistantApi api;
    late MusicAssistantPlayers players;

    setUp(() async {
      server = FakeMaServer();
      api = MusicAssistantApi(channelFactory: server.open, autoReconnect: false);
      await api.connect(Uri.parse('http://10.0.2.107:8095'));
      players = MusicAssistantPlayers(api);
    });

    tearDown(() async => api.dispose());

    test('players() lists everything, including the unavailable', () async {
      server.responder = (command, args) =>
          command == 'players/all' ? [_sonos(), _sonos(id: 'other', available: false, activeSource: 'airplay')] : null;
      final all = await players.players();
      expect(all, hasLength(2));
      expect(all.last.available, isFalse);
      expect(all.last.hasForeignSource, isTrue);
    });

    test('queueState picks its own queue out of the whole list', () async {
      server.responder = (command, args) =>
          command == 'player_queues/all' ? [_queue(id: 'someone-else'), _queue(elapsed: 42)] : null;
      final state = await players.queueState('RINCON_7828CA0DABA601400');
      expect(state!.elapsed, 42);
    });

    test('queueState is null rather than throwing when the server has no such queue', () async {
      server.responder = (command, args) => command == 'player_queues/all' ? <dynamic>[] : null;
      expect(await players.queueState('nope'), isNull);
    });

    test('a non-list answer is a protocol fault, not an empty library', () async {
      server.responder = (command, args) => command == 'players/all' ? {'unexpected': true} : null;
      await expectLater(players.players(), throwsA(isA<MaProtocolException>()));
    });

    test('playMedia sends the urls verbatim — the server fetches them itself', () async {
      server.responder = (_, _) => null;
      await players.playMedia('q', ['https://plex/a.flac?X-Plex-Token=t', 'https://plex/b.flac?X-Plex-Token=t']);
      expect(server.argsFor('player_queues/play_media'), {
        'queue_id': 'q',
        'media': ['https://plex/a.flac?X-Plex-Token=t', 'https://plex/b.flac?X-Plex-Token=t'],
        'option': 'replace',
      });
    });

    test('an empty media list sends nothing at all', () async {
      server.responder = (_, _) => null;
      await players.playMedia('q', const []);
      expect(server.commands, isNot(contains('player_queues/play_media')));
    });

    test('appending uses add, so the playing track is left alone', () async {
      server.responder = (_, _) => null;
      await players.playMedia('q', ['u'], option: MaEnqueueOption.add);
      expect(server.argsFor('player_queues/play_media')['option'], 'add');
    });

    test('replaceUpcoming leaves the sounding item and still sends an empty tail', () async {
      server.responder = (_, _) => null;
      await players.replaceUpcoming('q', const []);
      final args = server.argsFor('player_queues/play_media');
      expect(args['option'], 'replace_next');
      expect(args['media'], isEmpty);
    });

    test('transport commands carry only the queue id', () async {
      server.responder = (_, _) => null;
      await players.play('q');
      await players.pause('q');
      await players.next('q');
      await players.previous('q');
      await players.stop('q');
      expect(
        server.commands,
        containsAll(<String>[
          'player_queues/play',
          'player_queues/pause',
          'player_queues/next',
          'player_queues/previous',
          'player_queues/stop',
        ]),
      );
      expect(server.argsFor('player_queues/next'), {'queue_id': 'q'});
    });

    test('seek is sent in whole seconds, item-relative', () async {
      server.responder = (_, _) => null;
      await players.seek('q', const Duration(milliseconds: 90500));
      expect(server.argsFor('player_queues/seek'), {'queue_id': 'q', 'position': 90});
    });

    test('volume is clamped into 0-100 before it reaches a speaker', () async {
      server.responder = (_, _) => null;
      await players.setVolume('p', 250);
      expect(server.argsFor('players/cmd/volume_set')['volume_level'], 100);
      await players.setVolume('p', -5);
      expect(server.argsFor('players/cmd/volume_set')['volume_level'], 0);
    });

    test('volumeOf reads the level back off the player list', () async {
      server.responder = (command, args) => command == 'players/all' ? [_sonos(volume: 37)] : null;
      expect(await players.volumeOf('RINCON_7828CA0DABA601400'), 37);
      expect(await players.volumeOf('missing'), isNull);
    });

    test('repeat mode is pushed to the server, which is what decides what plays next', () async {
      server.responder = (_, _) => null;
      await players.setRepeatMode('q', MusicRepeatMode.one);
      expect(server.argsFor('player_queues/repeat'), {'queue_id': 'q', 'repeat_mode': 'one'});
    });

    group('queueUpdates', () {
      test('publishes queue_updated frames for its own queue only', () async {
        final readings = <MaQueueState>[];
        final subscription = players.queueUpdates('mine').listen(readings.add);
        server.pushEvent({'event': 'queue_updated', 'object_id': 'someone-else', 'data': _queue(id: 'someone-else')});
        server.pushEvent({'event': 'queue_updated', 'object_id': 'mine', 'data': _queue(id: 'mine', elapsed: 5)});
        await pumpEventQueue();
        expect(readings, hasLength(1));
        expect(readings.single.elapsed, 5);
        await subscription.cancel();
      });

      test('a time tick refreshes position while carrying the rest forward', () async {
        final readings = <MaQueueState>[];
        final subscription = players.queueUpdates('mine').listen(readings.add);
        server.pushEvent({
          'event': 'queue_updated',
          'object_id': 'mine',
          'data': _queue(id: 'mine', elapsed: 5, index: 2),
        });
        await pumpEventQueue();
        server.pushEvent({'event': 'queue_time_updated', 'object_id': 'mine', 'data': 11});
        await pumpEventQueue();
        expect(readings, hasLength(2));
        expect(readings.last.elapsed, 11);
        // The tick says nothing about these, so they must survive it.
        expect(readings.last.currentIndex, 2);
        expect(readings.last.currentItemId, contains('file.flac'));
        expect(readings.last.state, MaPlayerState.playing);
        await subscription.cancel();
      });

      test('a tick before any queue_updated is ignored rather than invented', () async {
        final readings = <MaQueueState>[];
        final subscription = players.queueUpdates('mine').listen(readings.add);
        server.pushEvent({'event': 'queue_time_updated', 'object_id': 'mine', 'data': 11});
        await pumpEventQueue();
        expect(readings, isEmpty);
        await subscription.cancel();
      });

      test('a tick wrapped in a map is accepted too', () async {
        final readings = <MaQueueState>[];
        final subscription = players.queueUpdates('mine').listen(readings.add);
        server.pushEvent({'event': 'queue_updated', 'object_id': 'mine', 'data': _queue(id: 'mine')});
        await pumpEventQueue();
        server.pushEvent({
          'event': 'queue_time_updated',
          'object_id': 'mine',
          'data': {'elapsed_time': 33},
        });
        await pumpEventQueue();
        expect(readings.last.elapsed, 33);
        await subscription.cancel();
      });
    });
  });
}
