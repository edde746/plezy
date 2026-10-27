import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/games/game_artwork.dart';
import 'package:plezy/games/game_models.dart';

void main() {
  final host = GameHost(id: 'pc', name: 'PC', address: '192.168.1.2', protocol: GameProtocol.gameStream);
  StreamGame game(int id) => StreamGame(hostKey: host.key, id: '$id', name: 'Game $id');

  test('cover requests are deduplicated, bounded and discarded on profile retirement', () async {
    final requests = <Completer<Uint8List?>>[];
    final loader = GameArtworkLoader(
      fetch: (_, _) {
        final completer = Completer<Uint8List?>();
        requests.add(completer);
        return completer.future;
      },
    );
    final first = loader.load(host, game(1));
    expect(identical(first, loader.load(host, game(1))), isTrue);
    final futures = [first, for (var i = 2; i <= 64; i++) loader.load(host, game(i))];
    expect(requests.length, 2);
    expect(await loader.load(host, game(65)), isNull);
    loader.dispose();
    for (final pending in requests) {
      pending.complete(Uint8List.fromList([1, 2, 3]));
    }
    expect(await Future.wait(futures), everyElement(isNull));
    expect(requests.length, 2);
  });

  test('a failed or oversized cover does not fail the library', () async {
    final large = GameArtworkLoader(fetch: (_, _) async => Uint8List(512 * 1024 + 1));
    final broken = GameArtworkLoader(fetch: (_, _) async => throw StateError('offline'));
    expect(await large.load(host, game(1)), isNull);
    expect(await broken.load(host, game(1)), isNull);
    large.dispose();
    broken.dispose();
  });
}
