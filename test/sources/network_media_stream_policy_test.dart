import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/sources/network_media_stream_server.dart';

void main() {
  group('NetworkMediaStreamPolicy.safeAssetName', () {
    test('allows only the token-scoped HLS playlist and generated segments', () {
      expect(NetworkMediaStreamPolicy.safeAssetName(['private-token', 'index.m3u8'], 'private-token'), 'index.m3u8');
      expect(
        NetworkMediaStreamPolicy.safeAssetName(['private-token', 'segment00042.ts'], 'private-token'),
        'segment00042.ts',
      );
      expect(NetworkMediaStreamPolicy.safeAssetName(['other-token', 'index.m3u8'], 'private-token'), isNull);
      expect(NetworkMediaStreamPolicy.safeAssetName(['private-token', 'segment00042.mp4'], 'private-token'), isNull);
      expect(NetworkMediaStreamPolicy.safeAssetName(['private-token', 'index.m3u8', 'extra'], 'private-token'), isNull);
      expect(NetworkMediaStreamPolicy.safeAssetName(['private-token', '..'], 'private-token'), isNull);
      expect(NetworkMediaStreamPolicy.safeAssetName(['private-token', '%2e%2e'], 'private-token'), isNull);
      expect(NetworkMediaStreamPolicy.safeAssetName(['index.m3u8'], 'private-token'), isNull);
    });
  });

  group('NetworkMediaStreamPolicy.allowsHostAndPeer', () {
    const addresses = ['192.168.1.20'];

    test('requires the exact advertised host and a private IPv4 peer', () {
      expect(
        NetworkMediaStreamPolicy.allowsHostAndPeer(
          hostHeader: '192.168.1.20:4455',
          advertisedAddresses: addresses,
          port: 4455,
          peer: InternetAddress('192.168.1.21'),
        ),
        isTrue,
      );
      expect(
        NetworkMediaStreamPolicy.allowsHostAndPeer(
          hostHeader: 'attacker.example:4455',
          advertisedAddresses: addresses,
          port: 4455,
          peer: InternetAddress('192.168.1.21'),
        ),
        isFalse,
      );
      expect(
        NetworkMediaStreamPolicy.allowsHostAndPeer(
          hostHeader: '192.168.1.20:4455',
          advertisedAddresses: addresses,
          port: 4455,
          peer: InternetAddress('8.8.8.8'),
        ),
        isFalse,
      );
      expect(
        NetworkMediaStreamPolicy.allowsHostAndPeer(
          hostHeader: null,
          advertisedAddresses: addresses,
          port: 4455,
          peer: InternetAddress('192.168.1.21'),
        ),
        isFalse,
      );
    });

    test('accepts RFC1918, loopback and link-local IPv4 only', () {
      for (final address in ['10.1.2.3', '127.0.0.1', '192.168.2.2', '172.16.0.1', '172.31.255.254', '169.254.4.2']) {
        expect(NetworkMediaStreamPolicy.isPrivateIPv4(InternetAddress(address)), isTrue, reason: address);
      }
      for (final address in ['8.8.8.8', '172.15.255.255', '172.32.0.1', '192.167.1.1', '2001:db8::1']) {
        expect(NetworkMediaStreamPolicy.isPrivateIPv4(InternetAddress(address)), isFalse, reason: address);
      }
    });
  });
}
