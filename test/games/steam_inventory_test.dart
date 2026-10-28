import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:plezy/games/game_models.dart';
import 'package:plezy/games/steam_inventory_exchange.dart';
import 'package:plezy/games/steam_local_inventory.dart';

void main() {
  test('KeyValues handles comments and Windows escapes, rejects unsafe structures', () {
    expect(parseSteamKeyValues(r'"path" "D:\\SteamLibrary" // comment')['path'], r'D:\SteamLibrary');
    for (final input in ['"a" {', '}', '"a" "1" "a" "2"', '"#include" "secret"', '"a" "unterminated']) {
      expect(() => parseSteamKeyValues(input), throwsFormatException, reason: input);
    }
    expect(() => parseSteamKeyValues('${'"a" {' * 20}${'}' * 20}'), throwsFormatException);
  });

  test('all library volumes contribute manifests; missing volumes make the scan partial', () async {
    final temp = await Directory.systemTemp.createTemp('plezy-steam-inventory-');
    addTearDown(() => temp.delete(recursive: true));
    final first = Directory(p.join(temp.path, 'Steam', 'steamapps'))..createSync(recursive: true);
    final second = Directory(p.join(temp.path, 'External', 'steamapps'))..createSync(recursive: true);
    File(p.join(first.path, 'libraryfolders.vdf')).writeAsStringSync(
      '"libraryfolders" { "0" { "path" "${first.parent.path}" } "1" { "path" "${second.parent.path}" } }',
    );
    File(
      p.join(first.path, 'appmanifest_620.acf'),
    ).writeAsStringSync('"AppState" { "appid" "620" "name" "Portal 2" "StateFlags" "4" }');
    File(
      p.join(second.path, 'appmanifest_400.acf'),
    ).writeAsStringSync('"AppState" { "appid" "400" "name" "Portal" "StateFlags" "2" }');
    var scan = await SteamLocalInventory().scan(root: first.parent.path);
    expect(scan.complete, isTrue);
    expect(scan.games.map((g) => g.appId), unorderedEquals([400, 620]));
    expect(scan.games.singleWhere((g) => g.appId == 620).installed, isTrue);
    expect(scan.games.singleWhere((g) => g.appId == 400).installed, isFalse);
    await second.delete(recursive: true);
    scan = await SteamLocalInventory().scan(root: first.parent.path);
    expect(scan.complete, isFalse);
    expect(scan.games, hasLength(1));
  });

  test('identity mismatch is ignored and cancellation cannot publish a snapshot', () async {
    final root = await Directory.systemTemp.createTemp('plezy-steam-inventory-');
    addTearDown(() => root.delete(recursive: true));
    final apps = Directory(p.join(root.path, 'steamapps'))..createSync();
    File(
      p.join(apps.path, 'appmanifest_620.acf'),
    ).writeAsStringSync('"AppState" { "appid" "999" "name" "Wrong" "StateFlags" "4" }');
    final scan = await SteamLocalInventory().scan(root: root.path);
    expect(scan.games, isEmpty);
    expect(scan.complete, isFalse);
    await expectLater(
      SteamLocalInventory().scan(root: root.path, isCurrent: () => false),
      throwsA(isA<SteamInventoryCancelled>()),
    );
  });

  test('encrypted-channel extension pages a complete snapshot and never includes paths', () async {
    late SteamInventoryExchange host, client;
    final sent = <Map<String, dynamic>>[];
    host = SteamInventoryExchange(
      isHost: true,
      canShare: () => true,
      readInventory: (_) async => SteamInventoryScan(
        complete: true,
        games: List.generate(121, (i) => SteamInstalledGame(appId: i + 1, name: 'Game $i', installed: true)),
      ),
      send: (message) {
        sent.add(message);
        client.receive(message);
      },
    );
    client = SteamInventoryExchange(
      isHost: false,
      canShare: () => false,
      readInventory: (_) => throw StateError('remote must not read local data'),
      send: host.receive,
    );
    addTearDown(host.close);
    addTearDown(client.close);
    final result = await client.request();
    expect(result.complete, isTrue);
    expect(result.games, hasLength(121));
    expect(sent, hasLength(3));
    expect(sent.expand((p) => p.keys), isNot(contains('path')));
  });

  test('sharing is opt-in and disabling it sends no game metadata', () async {
    late SteamInventoryExchange host, client;
    var reads = 0;
    host = SteamInventoryExchange(
      isHost: true,
      canShare: () => false,
      readInventory: (_) async {
        reads++;
        return const SteamInventoryScan(games: [], complete: true);
      },
      send: (message) => client.receive(message),
    );
    client = SteamInventoryExchange(
      isHost: false,
      canShare: () => false,
      readInventory: (_) => throw StateError('no'),
      send: host.receive,
    );
    addTearDown(host.close);
    addTearDown(client.close);
    await expectLater(client.request(), throwsA(isA<SteamInventoryUnavailable>()));
    expect(reads, 0);
  });

  test('out-of-order and unsolicited pages cannot become installed inventory', () async {
    Map<String, dynamic>? request;
    final client = SteamInventoryExchange(
      isHost: false,
      canShare: () => false,
      readInventory: (_) => throw StateError('no'),
      send: (message) => request = message,
    );
    addTearDown(client.close);
    final result = client.request();
    final assertion = expectLater(result, throwsA(isA<SteamInventoryUnavailable>()));
    client.receive({
      'version': 1,
      'op': 'page',
      'request': request!['request'],
      'offset': 10,
      'total': 1,
      'last': true,
      'complete': true,
      'games': [
        {'appId': 620, 'name': 'Portal', 'installed': true},
      ],
    });
    await assertion;
  });

  test('three computers contribute one card and retain distinct installation states', () {
    final hosts = [
      for (final name in ['Steambox', 'Desktop', 'BC250'])
        GameHost(id: name, name: name, address: '$name.local', protocol: GameProtocol.steam),
    ];
    final library = GameLibrary.fromJson(
      GameLibrary(
        hosts: hosts,
        inventories: [
          for (var i = 0; i < hosts.length; i++)
            SteamHostInventory(
              hostKey: hosts[i].key,
              peerId: 'peer$i',
              observedAt: DateTime(2026, 10, 28),
              complete: true,
              games: [
                SteamInstalledGame(appId: 620, name: 'Portal 2', installed: i != 2),
                SteamInstalledGame(appId: 100 + i, name: 'Unique $i', installed: true),
              ],
            ),
        ],
      ).toJson(),
    );
    expect(library.entries, hasLength(4));
    final portal = library.entries.singleWhere((e) => e.steamAppId == 620);
    expect(portal.routes.where((r) => r.installation == GameInstallation.installed), hasLength(2));
    expect(portal.routes.last.installation, GameInstallation.incomplete);
  });
}
