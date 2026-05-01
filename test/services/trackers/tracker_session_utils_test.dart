import 'package:flutter_test/flutter_test.dart';
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
  });
}
