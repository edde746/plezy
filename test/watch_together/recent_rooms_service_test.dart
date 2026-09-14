import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/watch_together/models/watch_session.dart';
import 'package:plezy/watch_together/services/recent_rooms_service.dart';
import 'package:plezy/watch_together/services/watch_together_relay_endpoint.dart';

import '../test_helpers/prefs.dart';

void main() {
  late SettingsService settings;
  final endpointA = WatchTogetherRelayEndpoint.resolve('https://relay-a.example.test/base/');
  final endpointB = WatchTogetherRelayEndpoint.resolve('http://relay-b.example.test:8080');

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    settings = await SettingsService.getInstance();
  });

  test('rooms are isolated by profile', () async {
    await RecentRoomsService.addOrUpdateRoom(
      'ROOM1',
      profileId: 'profile-a',
      endpoint: endpointA,
      name: 'Profile A room',
      controlMode: ControlMode.hostOnly,
    );

    expect(RecentRoomsService.getRecentRooms(profileId: 'profile-b', endpoint: endpointA), isEmpty);

    await RecentRoomsService.addOrUpdateRoom(
      'ROOM1',
      profileId: 'profile-b',
      endpoint: endpointA,
      name: 'Profile B room',
      controlMode: ControlMode.anyone,
    );

    final profileA = RecentRoomsService.getRecentRooms(profileId: 'profile-a', endpoint: endpointA);
    final profileB = RecentRoomsService.getRecentRooms(profileId: 'profile-b', endpoint: endpointA);
    expect(profileA.single.name, 'Profile A room');
    expect(profileA.single.controlMode, ControlMode.hostOnly);
    expect(profileB.single.name, 'Profile B room');
    expect(profileB.single.controlMode, ControlMode.anyone);
  });

  test('same code is independently mutable on different relay bases', () async {
    await RecentRoomsService.addOrUpdateRoom(
      'SAME1',
      profileId: 'profile-a',
      endpoint: endpointA,
      name: 'Relay A',
      controlMode: ControlMode.hostOnly,
    );
    await RecentRoomsService.addOrUpdateRoom(
      'SAME1',
      profileId: 'profile-a',
      endpoint: endpointB,
      name: 'Relay B',
      controlMode: ControlMode.anyone,
    );

    await RecentRoomsService.renameRoom('SAME1', 'Renamed A', profileId: 'profile-a', endpoint: endpointA);
    expect(RecentRoomsService.getRecentRooms(profileId: 'profile-a', endpoint: endpointA).single.name, 'Renamed A');
    expect(RecentRoomsService.getRecentRooms(profileId: 'profile-a', endpoint: endpointB).single.name, 'Relay B');

    await RecentRoomsService.removeRoom('SAME1', profileId: 'profile-a', endpoint: endpointA);
    expect(RecentRoomsService.getRecentRooms(profileId: 'profile-a', endpoint: endpointA), isEmpty);
    expect(RecentRoomsService.getRecentRooms(profileId: 'profile-a', endpoint: endpointB).single.code, 'SAME1');
  });

  test('profile history remains bounded across relay scopes and deduplicates tuples', () async {
    for (var index = 0; index < 21; index++) {
      await RecentRoomsService.addOrUpdateRoom(
        'R${index.toString().padLeft(4, '0')}',
        profileId: 'profile-a',
        endpoint: index.isEven ? endpointA : endpointB,
      );
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }

    final raw = settings.read(SettingsService.recentRoomsForProfile('profile-a'));
    final rows = jsonDecode(raw!) as List<dynamic>;
    expect(rows, hasLength(20));
    expect(rows.map((row) => (row as Map<String, dynamic>)['code']), isNot(contains('R0000')));

    await RecentRoomsService.addOrUpdateRoom('R0020', profileId: 'profile-a', endpoint: endpointA, name: 'Updated');
    final updatedRows = jsonDecode(settings.read(SettingsService.recentRoomsForProfile('profile-a'))!) as List<dynamic>;
    expect(updatedRows, hasLength(20));
    expect(
      updatedRows.where(
        (row) =>
            (row as Map<String, dynamic>)['code'] == 'R0020' &&
            row['relayScope'] == RecentRoomsService.relayScopeFor(endpointA),
      ),
      hasLength(1),
    );
  });

  test('startup drops unattributable legacy history', () async {
    SettingsService.resetForTesting();
    resetSharedPreferencesForTest(
      initialAsync: {
        'watch_together_recent_rooms': jsonEncode([
          {'code': 'OLD01', 'lastUsed': 1},
        ]),
      },
    );

    final initialized = await SettingsService.getInstance();
    expect(initialized.prefs.containsKey('watch_together_recent_rooms'), isFalse);
    expect(RecentRoomsService.getRecentRooms(profileId: 'profile-a', endpoint: endpointA), isEmpty);
  });
}
