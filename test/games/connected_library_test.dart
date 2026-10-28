import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/games/game_models.dart';

void main() {
  final steam = GameHost(id: '123', name: 'PC', address: '192.168.1.2', protocol: GameProtocol.steam);
  final other = GameHost(id: '456', name: 'Deck', address: '192.168.1.3', protocol: GameProtocol.steam);
  final sunshine = GameHost(id: 'sun', name: 'Sunshine', address: '192.168.1.2', protocol: GameProtocol.gameStream);
  final portal = SteamCatalogGame(appId: 620, name: 'Portal 2');
  final shortcut = StreamGame(hostKey: steam.key, id: '620', name: 'Portal');

  test('catalog and multiple hosts project one identity, without claiming availability', () {
    final library = GameLibrary(hosts: [steam, other], games: [shortcut], steamCatalog: [portal]);
    final entry = library.entries.single;
    expect(entry.key, 'steam:620');
    expect(entry.name, 'Portal 2');
    expect(entry.routes, hasLength(2));
    expect(entry.routes.first.savedShortcut, isTrue);
    expect(entry.routes.last.savedShortcut, isFalse);
    expect(entry.preferredRoute(library), isNull);
  });

  test('matching names and numeric GameStream IDs never imply Steam identity', () {
    final library = GameLibrary(
      hosts: [steam, sunshine],
      games: [
        shortcut,
        StreamGame(hostKey: sunshine.key, id: '620', name: 'Portal 2'),
      ],
    );
    expect(library.entries, hasLength(2));
    expect(library.entries.where((e) => e.steamAppId == null), hasLength(1));
  });

  test('an explicit Steam identity merges a GameStream route while preserving its launch ID', () {
    final library = GameLibrary(
      hosts: [steam, sunshine],
      games: [
        shortcut,
        StreamGame(hostKey: sunshine.key, id: '7', name: 'Portal', steamAppId: 620),
      ],
    );
    expect(library.entries, hasLength(1));
    final route = library.entries.single.routes.last;
    expect(route.host.protocol, GameProtocol.gameStream);
    expect(route.game.id, '7');
  });

  test('64-bit non-Steam shortcuts retain their exact local identity', () {
    final game = StreamGame(hostKey: steam.key, id: '18446744073709551615', name: 'Local game');
    final library = GameLibrary(hosts: [steam], games: [game]);
    expect(library.entries.single.key, game.key);
    expect(library.entries.single.steamAppId, isNull);
    expect(GameLibrary.fromJson(library.toJson()).games.single.id, game.id);
  });

  test('old route favorites and recents project to canonical identities without duplication', () {
    final another = StreamGame(hostKey: other.key, id: '620', name: 'Portal');
    final library = GameLibrary.fromJson({
      'version': 1,
      'hosts': [steam.toJson(), other.toJson()],
      'games': [shortcut.toJson(), another.toJson()],
      'favorites': [shortcut.key, another.key],
      'recent': [another.key, shortcut.key],
    });
    expect(library.favoriteKeys, {'steam:620'});
    expect(library.recentKeys, ['steam:620']);
    expect(library.favorites, {shortcut.key, another.key}); // Downgrade data retained.
  });

  test('catalog-only favorite survives reload and is removed when the account is absent', () {
    final data = GameLibrary(
      steamAccountId: '76561198000000000',
      steamCatalog: [portal],
      favorites: {'steam:620'},
    ).toJson();
    expect(GameLibrary.fromJson(data).favoriteKeys, {'steam:620'});
    data.remove('steamAccountId');
    expect(GameLibrary.fromJson(data).favoriteKeys, isEmpty);
  });

  test('route preferences must point to a route for that exact game', () {
    final library = GameLibrary(
      hosts: [steam, other],
      games: [shortcut],
      preferredRoutes: {'steam:620': '${other.key}/620'},
    );
    final restored = GameLibrary.fromJson(library.toJson());
    expect(restored.entries.single.preferredRoute(restored)?.host.key, other.key);
    final bad = library.toJson()..['preferredRoutes'] = {'steam:620': '${other.key}/999'};
    expect(GameLibrary.fromJson(bad).preferredRoutes, isEmpty);
  });

  test('Steam Library remains a computer action, not a game identity', () {
    final library = GameLibrary(
      hosts: [steam],
      games: [StreamGame(hostKey: steam.key, id: '0', name: 'Library')],
    );
    expect(library.entries, isEmpty);
    expect(library.games, hasLength(1));
  });

  test('source IDs and untrusted shortcut control characters are rejected', () {
    expect(() => StreamGame(hostKey: sunshine.key, id: '7', name: 'x', steamAppId: 0), throwsFormatException);
    expect(() => StreamGame(hostKey: sunshine.key, id: '7\n8', name: 'x'), throwsFormatException);
  });
}
