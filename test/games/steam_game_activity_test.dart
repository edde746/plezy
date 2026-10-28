import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plezy/games/steam_game_activity.dart';
import 'package:plezy/services/trackers/oauth_proxy_client.dart';

void main() {
  const id = '76561198000000000';
  test('activity uses a bearer header, no caller identity and explicit social opt-in', () async {
    final client = OAuthProxyClient(
      httpClient: MockClient((request) async {
        expect(request.url.query, isEmpty);
        expect(request.headers['Authorization'], 'Bearer scoped-token');
        expect(jsonDecode(request.body), {'appId': 620, 'includeFriends': false});
        return http.Response(
          jsonEncode({'appId': 620, 'steamId': id, 'achievementsAvailable': false, 'news': []}),
          200,
        );
      }),
    );
    addTearDown(client.dispose);
    final data = await client.steamGameActivity('scoped-token', appId: 620, steamId: id);
    expect(data.achievementsAvailable, isFalse);
    expect(data.friendsRequested, isFalse);
  });
  test('another game or identity cannot populate the detail view', () {
    expect(
      () => SteamGameActivity.fromJson({'appId': 621, 'steamId': id}, appId: 620, steamId: id),
      throwsFormatException,
    );
    expect(
      () => SteamGameActivity.fromJson({'appId': 620, 'steamId': '76561198000000001'}, appId: 620, steamId: id),
      throwsFormatException,
    );
  });
  test('hidden spoilers are discarded even if an older relay supplies them', () {
    final data = SteamGameActivity.fromJson(
      {
        'appId': 620,
        'steamId': id,
        'achievements': [
          {'hidden': true, 'unlocked': false, 'name': 'Spoiler', 'description': 'Secret'},
        ],
      },
      appId: 620,
      steamId: id,
    );
    expect(data.achievements.single.name, isEmpty);
    expect(data.achievements.single.description, isEmpty);
  });
  test('activity sizes and dates are bounded', () {
    expect(
      () => SteamGameActivity.fromJson(
        {'appId': 620, 'steamId': id, 'friends': List.filled(101, {})},
        appId: 620,
        steamId: id,
      ),
      throwsFormatException,
    );
    expect(
      () => SteamNewsItem.fromJson({'title': 'Update', 'feed': 'Steam', 'date': 9999999999999999}),
      throwsFormatException,
    );
  });
  test('Steam destinations cannot carry remote URLs or arbitrary app identifiers', () {
    for (final destination in SteamDestination.values) {
      final uri = steamDestination(620, destination);
      expect(uri.scheme, 'https');
      expect({'store.steampowered.com', 'steamcommunity.com'}, contains(uri.host));
      expect(uri.userInfo, isEmpty);
      expect(uri.query, isEmpty);
    }
    expect(() => steamDestination(0, SteamDestination.store), throwsFormatException);
    expect(() => steamDestination(0x100000000, SteamDestination.store), throwsFormatException);
  });
}
