import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/services/multi_server_manager.dart';
import 'package:plezy/services/music/music_output.dart';
import 'package:plezy/services/music/music_output_controller.dart';
import 'package:plezy/services/music_assistant/music_assistant_api.dart';
import 'package:plezy/services/music_assistant_client.dart';
import 'package:plezy/services/settings_service.dart';

import '../../music_assistant/fake_ma_server.dart';
import '../../test_helpers/prefs.dart';

Map<String, dynamic> _sonos({
  required String id,
  String name = 'Room',
  bool available = true,
  String? activeSource,
  String? activeGroup,
}) => {
  'player_id': id,
  'display_name': name,
  'provider': 'sonos',
  'available': available,
  'powered': true,
  'state': 'idle',
  'active_source': activeSource ?? id,
  'active_group': activeGroup,
  'group_childs': <String>[],
  'volume_level': 2,
  'supported_features': ['volume_set', 'seek', 'next_previous'],
};

void main() {
  late FakeMaServer server;
  late MusicAssistantApi api;
  late MusicAssistantClient client;
  late MultiServerManager manager;

  /// The id `MusicAssistantClient` registers under, which is what
  /// [MusicOutput.id] is scoped by.
  late String serverId;

  Future<MusicOutputController> build() async {
    final controller = MusicOutputController(serverManager: manager, settingsLoader: SettingsService.getInstance);
    addTearDown(controller.dispose);
    await controller.start();
    return controller;
  }

  setUp(() async {
    resetSharedPreferencesForTest();
    server = FakeMaServer(
      responder: (command, args) => command == 'players/all'
          ? [_sonos(id: 'RINCON_KITCHEN', name: 'Kitchen'), _sonos(id: 'ma_plezy_this_device', name: 'Plezy (iPhone)')]
          : null,
    );
    api = MusicAssistantApi(channelFactory: server.open, autoReconnect: false);
    client = await MusicAssistantClient.create(
      MusicAssistantConnection(
        id: 'ma-1',
        displayName: 'Music Assistant',
        baseUrl: 'http://10.0.2.107:8095',
        serverId: 'fe2f5b6fd78e4608bb8b075a6c269fbf',
        createdAt: DateTime.now(),
      ),
      api: api,
    );
    serverId = client.serverId.value;
    manager = MultiServerManager()..debugRegisterClientForTesting(client);
  });

  tearDown(() async => api.dispose());

  test('offers neither a synced follower nor a player the server hides', () async {
    server.responder = (command, args) => command == 'players/all'
        ? [
            _sonos(id: 'RINCON_LEADER', name: 'Kitchen'),
            {
              ..._sonos(id: 'RINCON_FOLLOWER', name: 'Dining Room', activeSource: 'RINCON_LEADER'),
              'synced_to': 'RINCON_LEADER',
            },
            {..._sonos(id: 'web_player', name: 'Chrome'), 'private': true},
            {..._sonos(id: 'RINCON_BASEMENT', name: 'Basement'), 'hide_in_ui': true},
          ]
        : null;

    final controller = await build();

    expect(controller.outputs.where((output) => output.isRemote).map((output) => output.name), ['Kitchen']);
  });

  group('sync groups', () {
    Map<String, dynamic> room(String id, String name, {String? activeGroup, String? syncedTo, List<String>? members}) =>
        {
          ..._sonos(id: id, name: name, activeSource: activeGroup, activeGroup: activeGroup),
          'synced_to': syncedTo,
          'group_members': members ?? <String>[],
          'supported_features': ['volume_set', 'set_members'],
        };

    Map<String, dynamic> syncGroup(List<String> members) => {
      ..._sonos(id: 'syncgroup_abc', name: 'Kitchen + Den'),
      'type': 'group',
      'provider': 'sync_group',
      'group_members': members,
      'volume_level': null,
      'group_volume': 30,
    };

    test('a playing group replaces its rooms in the list, and they stay available to regroup', () async {
      server.responder = (command, args) => command == 'players/all'
          ? [
              room('A', 'Kitchen', activeGroup: 'syncgroup_abc', members: ['A', 'B']),
              room('B', 'Den', activeGroup: 'syncgroup_abc', syncedTo: 'A'),
              room('C', 'Attic'),
              syncGroup(['A', 'B']),
            ]
          : null;

      final controller = await build();

      expect(controller.outputs.where((output) => output.isRemote).map((output) => output.name), [
        'Attic',
        'Kitchen + Den',
      ]);
      expect(controller.groupableRooms.map((room) => room.name), ['Kitchen', 'Den', 'Attic']);
    });

    test('selectGroup moves the selection onto the group', () async {
      server.responder = (command, args) => command == 'players/all'
          ? [
              room('A', 'Kitchen'),
              room('B', 'Den'),
              syncGroup(['A', 'B']),
            ]
          : null;
      final controller = await build();

      await controller.selectGroup(controller.groupableRooms);

      expect(controller.selected.playerId, 'syncgroup_abc');
      expect(controller.selected.isGroup, isTrue);
    });

    test('a group that has never played takes its volume from its rooms, not its own 0', () async {
      server.responder = (command, args) => command == 'players/all'
          ? [
              {...room('A', 'Kitchen'), 'volume_level': 40},
              {...room('B', 'Den'), 'volume_level': 60},
              {
                ...syncGroup(['A', 'B']),
                'group_volume': 0,
              },
            ]
          : null;
      final controller = await build();

      await controller.selectGroup(controller.groupableRooms);

      expect(controller.selected.volume, 50);
    });

    test('a failed group leaves the selection where it was', () async {
      server.responder = (command, args) => switch (command) {
        'players/all' => [room('A', 'Kitchen'), room('B', 'Den')],
        'players/create_group_player' => const MaErrorReply(22, 'Insufficient permissions'),
        _ => null,
      };
      final controller = await build();
      final before = controller.selected;

      await expectLater(
        controller.selectGroup(controller.groupableRooms),
        throwsA(isA<MaRequestException>().having((e) => e.isPermissionDenied, 'isPermissionDenied', isTrue)),
      );
      expect(controller.selected, before);
    });
  });

  test('always offers this device, even with no servers at all', () async {
    final controller = MusicOutputController(
      serverManager: MultiServerManager(),
      settingsLoader: SettingsService.getInstance,
    );
    addTearDown(controller.dispose);
    await controller.start();
    expect(controller.outputs, [MusicOutput.thisDevice]);
    expect(controller.hasRemoteOutputs, isFalse);
    expect(controller.selected, MusicOutput.thisDevice);
  });

  test('lists the server\'s players alongside this device', () async {
    final controller = await build();
    expect(controller.hasRemoteOutputs, isTrue);
    expect(controller.outputs.first, MusicOutput.thisDevice);
    expect(controller.outputs.map((output) => output.name), containsAll(<String>['This device', 'Kitchen']));
  });

  test('hides our own builtin player, which is already "This device"', () async {
    final controller = await build();
    expect(
      controller.outputs.where((output) => output.playerId == 'ma_plezy_this_device'),
      isEmpty,
      reason: 'the phone would otherwise appear twice under two names',
    );
  });

  test('this app\'s own registrations never appear as destinations', () async {
    // The server remembers builtin players from earlier installs, whose ids no
    // longer match the current one. They can never be played to — they show as
    // permanently unavailable — so they were pure noise in the one menu that
    // has to be clear about where sound will come out. "This device" already
    // covers the phone in hand.
    server.responder = (command, args) => command == 'players/all'
        ? [
            _sonos(id: 'ma_plezy_4b9d44391ce6', name: 'Plezy (iPhone)'),
            _sonos(id: 'ma_plezy_stale_from_an_old_install', name: 'Plezy (iPhone)'),
            _sonos(id: 'RINCON_KITCHEN', name: 'Kitchen'),
          ]
        : null;
    final controller = await build();

    expect(controller.outputs.map((output) => output.name), isNot(contains('Plezy (iPhone)')));
    expect(controller.outputs.map((output) => output.name), contains('Kitchen'));
  });

  test('keeps a group leader — a stereo pair is still a destination', () async {
    // The leader reports the group's id as its active group, exactly as its
    // members do, and the old filter matched on that alone. A stereo pair or
    // any grouped room therefore vanished from the list, its owner looked like
    // a speaker that had gone away, and the selection fell back to the phone
    // mid-session. Children are what separate a leader from a follower.
    server.responder = (command, args) => command == 'players/all'
        ? [
            {
              ..._sonos(id: 'LEADER', name: 'Downstairs', activeGroup: 'group-1'),
              'group_childs': ['MEMBER'],
            },
            _sonos(id: 'MEMBER', name: 'Kitchen', activeGroup: 'group-1'),
          ]
        : null;
    final controller = await build();
    final names = controller.outputs.map((output) => output.name);
    expect(names, contains('Downstairs'), reason: 'the leader is a real destination');
    expect(names, isNot(contains('Kitchen')), reason: 'a follower is driven through it');
  });

  test('hides a grouped member, which is driven through its leader', () async {
    server.responder = (command, args) => command == 'players/all'
        ? [_sonos(id: 'LEADER', name: 'Downstairs'), _sonos(id: 'MEMBER', name: 'Kitchen', activeGroup: 'LEADER')]
        : null;
    final controller = await build();
    final names = controller.outputs.map((output) => output.name);
    expect(names, contains('Downstairs'));
    expect(names, isNot(contains('Kitchen')));
  });

  test('keeps an unavailable room in the list with its reason', () async {
    server.responder = (command, args) => command == 'players/all'
        ? [_sonos(id: 'RINCON_BUSY', name: 'Study', available: false, activeSource: 'airplay')]
        : null;
    final controller = await build();
    final busy = controller.outputs.firstWhere((output) => output.name == 'Study');
    expect(busy.available, isFalse);
    expect(busy.unavailableReason, 'In use by airplay');
    expect(controller.playableOutputs, isNot(contains(busy)));
  });

  group('choosing', () {
    test('stays on the phone when nothing was ever chosen, even with speakers available', () async {
      // Defaulting to a speaker sent audio to whichever room discovery
      // happened to return first, and made the session mirror that player's
      // queue — reporting `playing` for audio it never sent.
      final controller = await build();
      expect(controller.selected, MusicOutput.thisDevice);
    });

    test('does not persist that default', () async {
      await build();
      final settings = await SettingsService.getInstance();
      expect(settings.read(SettingsService.musicOutputId), isEmpty);
    });

    test('stays on the phone when there is no speaker at all', () async {
      server.responder = (command, args) => command == 'players/all' ? <dynamic>[] : null;
      final controller = await build();
      expect(controller.selected, MusicOutput.thisDevice);
    });

    test('remembers an explicit choice', () async {
      final controller = await build();
      await controller.select(MusicOutput.thisDevice);
      final settings = await SettingsService.getInstance();
      expect(settings.read(SettingsService.musicOutputId), MusicOutput.thisDeviceId);
    });

    test('a stored choice beats the default', () async {
      final settings = await SettingsService.getInstance();
      await settings.write(SettingsService.musicOutputId, MusicOutput.thisDeviceId);
      final controller = await build();
      expect(controller.selected, MusicOutput.thisDevice);
    });

    test('a stored speaker is restored once it appears', () async {
      final settings = await SettingsService.getInstance();
      await settings.write(SettingsService.musicOutputId, '$serverId|RINCON_KITCHEN');
      final controller = await build();
      expect(controller.selected.playerId, 'RINCON_KITCHEN');
    });

    test('a chosen speaker survives its server going quiet', () async {
      // A server that cannot be asked used to contribute nothing, so its rooms
      // vanished and the chosen one looked gone. The selection fell back to the
      // phone, which stops the remote engine mid-session: the audio carries on
      // in the room, because the server is the one playing it, while the app
      // loses the track — and with it the only transport the listener has.
      final controller = await build();
      await controller.select(controller.outputs.firstWhere((output) => output.playerId == 'RINCON_KITCHEN'));
      expect(controller.selected.playerId, 'RINCON_KITCHEN');

      server.responder = (command, args) => command == 'players/all' ? MaErrorReply(1, 'boom') : null;
      await controller.refresh();

      expect(
        controller.selected.playerId,
        'RINCON_KITCHEN',
        reason: 'a silent server must not move the listener back to the phone',
      );
      final kitchen = controller.outputs.firstWhere((output) => output.playerId == 'RINCON_KITCHEN');
      expect(kitchen.available, isFalse, reason: 'it is still the choice, but it cannot be played to right now');
      expect(kitchen.unavailableReason, isNotNull);

      // And it comes back by itself once the server answers again.
      server.responder = (command, args) => command == 'players/all'
          ? [_sonos(id: 'RINCON_KITCHEN', name: 'Kitchen'), _sonos(id: 'ma_plezy_this_device', name: 'Plezy (iPhone)')]
          : null;
      await controller.refresh();
      expect(controller.selected.playerId, 'RINCON_KITCHEN');
      expect(controller.outputs.firstWhere((o) => o.playerId == 'RINCON_KITCHEN').available, isTrue);
    });

    test('a speaker that goes away falls back to the phone, not to another room', () async {
      // Audio appearing in a room nobody chose is worse than audio appearing
      // on the device in the user's hand.
      server.responder = (command, args) => command == 'players/all'
          ? [_sonos(id: 'RINCON_KITCHEN', name: 'Kitchen'), _sonos(id: 'RINCON_STUDY', name: 'Study')]
          : null;
      final controller = await build();
      await controller.select(controller.outputs.firstWhere((output) => output.playerId == 'RINCON_KITCHEN'));
      expect(controller.selected.playerId, 'RINCON_KITCHEN');

      server.responder = (command, args) =>
          command == 'players/all' ? [_sonos(id: 'RINCON_STUDY', name: 'Study')] : null;
      await controller.refresh();
      expect(controller.selected, MusicOutput.thisDevice);
    });

    test('notifies listeners when the choice changes', () async {
      final controller = await build();
      var notifications = 0;
      controller.addListener(() => notifications++);
      await controller.select(MusicOutput.thisDevice);
      expect(notifications, greaterThan(0));
    });
  });

  test('a server that cannot be listed leaves the rest of the list usable', () async {
    server.responder = (command, args) => command == 'players/all' ? const MaErrorReply(1, 'boom') : null;
    final controller = await build();
    expect(controller.outputs, [MusicOutput.thisDevice]);
    expect(controller.hasRemoteOutputs, isFalse);
  });
}
