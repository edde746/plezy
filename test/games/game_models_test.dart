import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/games/game_discovery.dart';
import 'package:plezy/games/game_models.dart';

GameHost host({String id = 'pc', String address = '192.168.1.10', int port = 47989}) =>
    GameHost(id: id, name: 'Gaming PC', address: address, port: port, protocol: GameProtocol.gameStream);

void main() {
  test('addresses reject URLs, option injection and broadcast targets', () {
    for (final value in [
      'https://pc',
      'user@pc',
      'pc/?token=secret',
      '-help',
      'pc;shutdown',
      'pc\nlocal',
      '0.0.0.0',
      '224.0.0.1',
      '255.255.255.255',
    ]) {
      expect(() => host(address: value), throwsFormatException, reason: value);
    }
    for (final value in ['192.168.1.10', 'gaming-pc.local', '2001:db8::1']) {
      expect(host(address: value).address, value);
    }
  });
  test('Sunshine QR preserves custom ports and IPv6 without carrying secrets', () {
    final uri = host(address: '2001:db8::1', port: 48000).sunshinePairingPage;
    expect(uri.toString(), 'https://[2001:db8::1]:48001/pin');
    expect(uri.userInfo, isEmpty);
    expect(uri.query, isEmpty);
    expect(() => host(port: 65535), throwsFormatException);
  });
  test('corrupt collections and unknown schemas recover to an empty library', () {
    expect(GameLibrary.fromJson({'version': 99}).hosts, isEmpty);
    final value = GameLibrary.fromJson({'version': 1, 'hosts': 5, 'games': 'bad', 'recent': {}, 'favorites': false});
    expect(value.hosts, isEmpty);
    expect(value.games, isEmpty);
  });
  test('bad entries and orphan shortcuts do not discard valid entries', () {
    final pc = host();
    final game = StreamGame(hostKey: pc.key, id: '1', name: 'Desktop', hdr: true);
    final value = GameLibrary.fromJson({
      'version': 1,
      'hosts': [
        pc.toJson(),
        null,
        {'id': 'bad'},
      ],
      'games': [
        game.toJson(),
        {'hostKey': 'missing', 'id': '2', 'name': 'Lost'},
      ],
      'recent': [game.key, game.key, 'orphan'],
      'favorites': [game.key, 'orphan'],
    });
    expect(value.hosts, hasLength(1));
    expect(value.games.single.hdr, isTrue);
    expect(value.recent, [game.key]);
    expect(value.favorites, {game.key});
  });
  test('delimiter characters cannot alias different games or hosts', () {
    final a = StreamGame(
      hostKey: host(id: 'pc/x').key,
      id: '1',
      name: 'A',
    );
    final b = StreamGame(
      hostKey: host(id: 'pc').key,
      id: 'x/1',
      name: 'B',
    );
    expect(a.key, isNot(b.key));
  });
  test('public serverinfo identifies a host but contains no pairing credential', () {
    final identified = parseGameStreamInfo(
      host(),
      '<root status_code="200"><uniqueid>01234567-89ab-cdef-0123-456789abcdef</uniqueid><hostname>Studio</hostname></root>',
    );
    expect(identified.name, 'Studio');
    expect(identified.id, '01234567-89ab-cdef-0123-456789abcdef');
    expect(identified.toJson().keys, isNot(contains('paired')));
    for (final body in [
      '<root status_code="401"/>',
      '<!DOCTYPE root><root status_code="200"/>',
      '<root status_code="200"><uniqueid>oops</uniqueid></root>',
    ]) {
      expect(() => parseGameStreamInfo(host(), body), throwsFormatException);
    }
  });
  test('Wake-on-LAN packet repeats only the requested MAC sixteen times', () {
    final value = wakePacket('00:11:22:33:44:55');
    expect(value.length, 102);
    expect(value.take(6), List.filled(6, 255));
    for (var n = 0; n < 16; n++) {
      expect(value.sublist(6 + n * 6, 12 + n * 6), [0, 17, 34, 51, 68, 85]);
    }
    expect(() => wakePacket('00:11'), throwsFormatException);
  });
}
