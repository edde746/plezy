import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/connectivity_link_type.dart';

void main() {
  // The single definition of "metered connection" behind the cellular playback
  // default, the download WiFi-only gate and the sync-rule cooldown.
  group('ConnectivityLinkType', () {
    test('cellular alone is the only metered case', () {
      expect(const [ConnectivityResult.mobile].isCellularOnly, isTrue);
      expect(const [ConnectivityResult.mobile].hasWifiOrEthernet, isFalse);
    });

    test('any WiFi or Ethernet link alongside cellular wins', () {
      for (final unmetered in const [ConnectivityResult.wifi, ConnectivityResult.ethernet]) {
        final results = [ConnectivityResult.mobile, unmetered];
        expect(results.isCellularOnly, isFalse, reason: '$unmetered should outrank cellular');
        expect(results.hasWifiOrEthernet, isTrue);
      }
    });

    test('an unknown snapshot is neither metered nor unmetered', () {
      // Load-bearing: the download WiFi-only gate relies on this instead of a
      // separate empty-list guard, and playback falls back to the general
      // default quality until the connection type is known.
      expect(const <ConnectivityResult>[].isCellularOnly, isFalse);
      expect(const <ConnectivityResult>[].hasWifiOrEthernet, isFalse);
      expect(const [ConnectivityResult.none].isCellularOnly, isFalse);
      expect(const [ConnectivityResult.other].isCellularOnly, isFalse);
    });

    test('a WiFi-only link is unmetered', () {
      expect(const [ConnectivityResult.wifi].hasWifiOrEthernet, isTrue);
      expect(const [ConnectivityResult.wifi].isCellularOnly, isFalse);
    });
  });
}
