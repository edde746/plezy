import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/discord_rpc_service.dart';

void main() {
  group('posterCacheExpiryFromResponse', () {
    final receivedAt = DateTime.utc(2026, 7, 12, 12);

    test('honors the relay-provided expiry', () {
      expect(
        posterCacheExpiryFromResponse({'expiresIn': 90}, receivedAt: receivedAt),
        receivedAt.add(const Duration(seconds: 90)),
      );
    });

    test('treats a non-positive relay expiry as immediately expired', () {
      expect(posterCacheExpiryFromResponse({'expiresIn': 0}, receivedAt: receivedAt), receivedAt);
    });

    test('retains the legacy fallback for older or invalid relays', () {
      final fallback = receivedAt.add(const Duration(hours: 3));

      expect(posterCacheExpiryFromResponse({'url': '/posters/a.png'}, receivedAt: receivedAt), fallback);
      expect(posterCacheExpiryFromResponse({'expiresIn': '90'}, receivedAt: receivedAt), fallback);
      expect(posterCacheExpiryFromResponse({'expiresIn': 1 << 62}, receivedAt: receivedAt), fallback);
    });
  });
}
