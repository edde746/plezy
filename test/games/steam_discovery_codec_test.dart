import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/games/steam_discovery_codec.dart';

void main() {
  Uint8List status({List<int> extra = const [], int services = 2}) {
    final name = utf8.encode('Living room');
    // Exact wire bytes: client_id=42, message_type=1; hostname=4, services=6.
    return SteamDiscoveryCodec.frame([8, 42, 16, 1], [34, name.length, ...name, 48, services, ...extra]);
  }

  test('legacy status without optional fields is discovered', () {
    final peer = SteamDiscoveryCodec.decode(status())!;
    expect(peer.id, '42');
    expect(peer.name, 'Living room');
    expect(peer.connectPort, 27036);
  });
  test('current/future unknown fields preserve discovery without claiming a codec', () {
    // Unknown length-delimited field 99 and locked/busy fields 13/14.
    final peer = SteamDiscoveryCodec.decode(status(extra: [0x9a, 6, 3, 1, 2, 3, 104, 1, 112, 1]))!;
    expect(peer.screenLocked, isTrue);
    expect(peer.busy, isTrue);
    expect(peer.id, '42');
  });
  test('non-streaming services and our own discovery query are ignored', () {
    expect(SteamDiscoveryCodec.decode(status(services: 1)), isNull);
    expect(SteamDiscoveryCodec.decode(SteamDiscoveryCodec.query(25)), isNull);
    expect(() => SteamDiscoveryCodec.query(-1), throwsFormatException);
  });
  test('truncation and mismatched frame lengths never produce a peer', () {
    final value = status();
    for (var n = 0; n < value.length; n++) {
      expect(SteamDiscoveryCodec.decode(Uint8List.sublistView(value, 0, n)), isNull, reason: '$n');
    }
    expect(SteamDiscoveryCodec.decode(Uint8List.fromList([...value, 0])), isNull);
    value[8] = 255;
    expect(SteamDiscoveryCodec.decode(value), isNull);
  });
  test('overflowing varints and malicious length fields are bounded', () {
    for (final body in [
      [48, ...List.filled(11, 255)],
      [34, 255, 255, 255, 255, 127],
      [0],
      [34, 1, 255],
    ]) {
      expect(SteamDiscoveryCodec.decode(SteamDiscoveryCodec.frame([8, 42, 16, 1], body)), isNull);
    }
  });
  test('seeded malformed datagrams never escape the decoder', () {
    final random = Random(4319);
    for (var i = 0; i < 3000; i++) {
      final bytes = Uint8List.fromList(List.generate(random.nextInt(2048), (_) => random.nextInt(256)));
      if (i.isEven && bytes.length > 16) bytes.setAll(0, SteamDiscoveryCodec.signature);
      expect(() => SteamDiscoveryCodec.decode(bytes), returnsNormally);
    }
  });
}
