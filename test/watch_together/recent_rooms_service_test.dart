import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/watch_together/services/recent_rooms_service.dart';
import 'package:plezy/watch_together/services/watch_party_relays.dart';

import '../test_helpers/prefs.dart';

const _alphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';

/// The [index]th of a run of distinct valid room codes.
String _code(int index) => 'K7MQ${_alphabet[index ~/ _alphabet.length]}${_alphabet[index % _alphabet.length]}';

void main() {
  late SettingsService settings;
  final public = relayScopeOf(null);
  final custom = relayScopeOf('https://relay.example.test');

  Future<void> seed(String profileId, List<Map<String, Object?>> rows) =>
      settings.write(SettingsService.recentRoomsForProfile(profileId), jsonEncode(rows));

  List<Map<String, dynamic>> stored(String profileId) => [
    for (final row in jsonDecode(settings.read(SettingsService.recentRoomsForProfile(profileId))!) as List<dynamic>)
      row as Map<String, dynamic>,
  ];

  List<String> codes(String profileId, String relayScope) => [
    for (final room in RecentRoomsService.getRecentRooms(profileId: profileId, relayScope: relayScope)) room.code,
  ];

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    settings = await SettingsService.getInstance();
  });

  test('rooms are kept per profile and per relay scope', () async {
    await RecentRoomsService.addOrUpdateRoom('K7MQ2X', profileId: 'profile-a', relayScope: public);

    expect(codes('profile-a', public), ['K7MQ2X']);
    expect(codes('profile-b', public), isEmpty);
    expect(codes('profile-a', custom), isEmpty);
  });

  test('the same code on two relays is renamed and removed independently', () async {
    await RecentRoomsService.addOrUpdateRoom('K7MQ2X', profileId: 'profile-a', relayScope: public);
    await RecentRoomsService.addOrUpdateRoom('K7MQ2X', profileId: 'profile-a', relayScope: custom);

    await RecentRoomsService.renameRoom('K7MQ2X', 'Movie night', profileId: 'profile-a', relayScope: public);
    expect(RecentRoomsService.getRecentRooms(profileId: 'profile-a', relayScope: public).single.name, 'Movie night');
    expect(RecentRoomsService.getRecentRooms(profileId: 'profile-a', relayScope: custom).single.name, isNull);

    await RecentRoomsService.removeRoom('K7MQ2X', profileId: 'profile-a', relayScope: custom);
    expect(codes('profile-a', custom), isEmpty);
    expect(codes('profile-a', public), ['K7MQ2X']);
  });

  test('renaming to null clears the name; renaming an unknown room changes nothing', () async {
    await RecentRoomsService.addOrUpdateRoom('K7MQ2X', profileId: 'profile-a', relayScope: public);
    await RecentRoomsService.renameRoom('K7MQ2X', 'Movie night', profileId: 'profile-a', relayScope: public);
    await RecentRoomsService.renameRoom('K7MQ2X', null, profileId: 'profile-a', relayScope: public);
    expect(RecentRoomsService.getRecentRooms(profileId: 'profile-a', relayScope: public).single.name, isNull);
    expect(stored('profile-a').single.containsKey('name'), isFalse);

    final before = settings.read(SettingsService.recentRoomsForProfile('profile-a'));
    await RecentRoomsService.renameRoom('ABCDEF', 'Nope', profileId: 'profile-a', relayScope: public);
    expect(settings.read(SettingsService.recentRoomsForProfile('profile-a')), before);
  });

  test('joining a known room again moves it first and keeps its name', () async {
    await seed('profile-a', [
      {'code': 'K7MQ2X', 'relayScope': public, 'name': 'Old friends', 'lastUsed': 1},
      {'code': 'ABCDEF', 'relayScope': public, 'lastUsed': 2},
    ]);
    expect(codes('profile-a', public), ['ABCDEF', 'K7MQ2X']);

    await RecentRoomsService.addOrUpdateRoom('K7MQ2X', profileId: 'profile-a', relayScope: public);

    final rooms = RecentRoomsService.getRecentRooms(profileId: 'profile-a', relayScope: public);
    expect(rooms.map((room) => room.code), ['K7MQ2X', 'ABCDEF']);
    expect(rooms.first.name, 'Old friends');
    expect(stored('profile-a'), hasLength(2));
  });

  test('keeps the 20 most recent rooms across relay scopes', () async {
    await seed('profile-a', [
      for (var i = 0; i < 20; i++) {'code': _code(i), 'relayScope': i.isEven ? public : custom, 'lastUsed': i + 1},
    ]);

    await RecentRoomsService.addOrUpdateRoom(_code(20), profileId: 'profile-a', relayScope: custom);

    final rows = stored('profile-a');
    expect(rows, hasLength(20));
    expect(rows.map((row) => row['code']), isNot(contains(_code(0))), reason: 'the oldest room goes');
    expect(rows.first['code'], _code(20));
    expect(codes('profile-a', custom).first, _code(20));
  });

  test('codes of the former relay (5 symbols) and unnormalized codes are not shown', () async {
    await seed('profile-a', [
      {'code': 'ROOM1', 'relayScope': public, 'name': 'Former relay', 'lastUsed': 3, 'controlMode': 0},
      {'code': 'AB2CD', 'relayScope': public, 'lastUsed': 2},
      {'code': 'k7m-q2x', 'relayScope': public, 'lastUsed': 4},
      {'code': 'K7MQ2X', 'relayScope': public, 'lastUsed': 1},
    ]);

    expect(codes('profile-a', public), ['K7MQ2X']);

    await RecentRoomsService.addOrUpdateRoom('ABCDEF', profileId: 'profile-a', relayScope: public);
    expect(stored('profile-a').map((row) => row['code']), ['ABCDEF', 'K7MQ2X']);
  });

  test('unreadable history reads as empty and gives way to the next room', () async {
    await settings.write(SettingsService.recentRoomsForProfile('profile-a'), '{not json');
    expect(codes('profile-a', public), isEmpty);

    await RecentRoomsService.addOrUpdateRoom('K7MQ2X', profileId: 'profile-a', relayScope: public);
    expect(codes('profile-a', public), ['K7MQ2X']);
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
    expect(codes('profile-a', public), isEmpty);
  });
}
