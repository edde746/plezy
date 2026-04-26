import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:plezy/connection/connection.dart';
import 'package:plezy/models/livetv_channel.dart';
import 'package:plezy/services/jellyfin_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers/prefs.dart';

JellyfinConnection _conn({required String userId}) => JellyfinConnection(
  id: 'srv-shared/$userId',
  baseUrl: 'https://jf.example.com',
  serverName: 'Shared JF',
  serverMachineId: 'srv-shared',
  userId: userId,
  userName: 'user-$userId',
  accessToken: 'tok-$userId',
  deviceId: 'dev-$userId',
  createdAt: DateTime.fromMillisecondsSinceEpoch(0),
);

JellyfinClient _client(JellyfinConnection conn) => JellyfinClient.forTesting(
  connection: conn,
  // Favorites read path is local-only; an http stub that always 500s is
  // fine since fetchFavoriteChannels never hits it.
  httpClient: MockClient((_) async => throw StateError('no HTTP expected')),
);

String _favKey(JellyfinConnection conn) => 'jellyfin_fav_channels:${conn.id}';
String _legacyFavKey(JellyfinConnection conn) => 'jellyfin_fav_channels:${conn.serverMachineId}';

String _encodeFavorites(List<FavoriteChannel> favs) => jsonEncode(favs.map((f) => f.toJson()).toList());

FavoriteChannel _ch(String id, {String? title}) =>
    FavoriteChannel(id: id, title: title ?? id, source: 'server://srv-shared/jellyfin');

void main() {
  setUp(resetSharedPreferencesForTest);

  group('Jellyfin favorites isolation across users on the same server', () {
    test('two users on the same server have independent favorite lists', () async {
      final connA = _conn(userId: 'user-a');
      final connB = _conn(userId: 'user-b');

      // Pre-seed user A's favorites under the compound key, leave user B empty.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_favKey(connA), _encodeFavorites([_ch('chan-a1'), _ch('chan-a2')]));

      final aFavs = await _client(connA).liveTv.fetchFavoriteChannels();
      final bFavs = await _client(connB).liveTv.fetchFavoriteChannels();

      expect(aFavs.map((f) => f.id).toList(), ['chan-a1', 'chan-a2']);
      expect(bFavs, isEmpty, reason: 'user B must not see user A\'s favorites');
    });

    test('legacy bare-machineId key migrates into the first user\'s compound slot', () async {
      final connA = _conn(userId: 'user-a');

      // Pre-seed legacy entry only.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_legacyFavKey(connA), _encodeFavorites([_ch('legacy-1')]));

      final aFavs = await _client(connA).liveTv.fetchFavoriteChannels();
      expect(aFavs.map((f) => f.id).toList(), ['legacy-1']);

      // Migration: legacy key gone, compound key written.
      expect(prefs.getString(_legacyFavKey(connA)), isNull);
      expect(prefs.getString(_favKey(connA)), isNotNull);
    });
  });
}
