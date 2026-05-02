import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/trackers/anilist/anilist_session.dart';
import 'package:plezy/services/trackers/mal/mal_session.dart';
import 'package:plezy/services/trackers/simkl/simkl_session.dart';
import 'package:plezy/services/trackers/tracker_session_utils.dart';

void main() {
  group('tracker token expiry helpers', () {
    test('detects expired token', () {
      expect(isTrackerTokenExpired(100, nowSeconds: 100), isTrue);
      expect(isTrackerTokenExpired(101, nowSeconds: 100), isFalse);
    });

    test('detects refresh window', () {
      expect(trackerTokenNeedsRefresh(400, nowSeconds: 100), isTrue);
      expect(trackerTokenNeedsRefresh(401, nowSeconds: 100), isFalse);
      expect(trackerTokenNeedsRefresh(110, refreshWindowSeconds: 10, nowSeconds: 100), isTrue);
    });
  });

  group('tracker session json codec', () {
    test('round-trips through provided factory', () {
      final encoded = encodeTrackerSessionJson({'access_token': 'abc', 'created_at': 123});
      final decoded = decodeTrackerSessionJson(encoded, (json) => json);

      expect(decoded, {'access_token': 'abc', 'created_at': 123});
    });

    test('round-trips AniList sessions through shared encode mixin', () {
      const session = AnilistSession(accessToken: 'anilist-at', expiresAt: 2000, username: 'alice', createdAt: 1000);

      final decoded = AnilistSession.decode(session.encode());

      expect(decoded.accessToken, 'anilist-at');
      expect(decoded.expiresAt, 2000);
      expect(decoded.username, 'alice');
      expect(decoded.createdAt, 1000);
    });

    test('round-trips MAL sessions through shared encode mixin', () {
      const session = MalSession(
        accessToken: 'mal-at',
        refreshToken: 'mal-rt',
        expiresAt: 2000,
        username: 'bob',
        createdAt: 1000,
      );

      final decoded = MalSession.decode(session.encode());

      expect(decoded.accessToken, 'mal-at');
      expect(decoded.refreshToken, 'mal-rt');
      expect(decoded.expiresAt, 2000);
      expect(decoded.username, 'bob');
      expect(decoded.createdAt, 1000);
    });

    test('round-trips Simkl sessions through shared encode mixin', () {
      const session = SimklSession(accessToken: 'simkl-at', username: 'carol', createdAt: 1000);

      final decoded = SimklSession.decode(session.encode());

      expect(decoded.accessToken, 'simkl-at');
      expect(decoded.username, 'carol');
      expect(decoded.createdAt, 1000);
    });
  });
}
