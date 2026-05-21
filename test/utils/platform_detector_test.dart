import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/utils/platform_detector.dart';

void main() {
  group('detectAndroidTvFromSystemFeatures', () {
    test('detects leanback devices', () {
      final detection = detectAndroidTvFromSystemFeatures([
        'android.software.leanback',
        'android.hardware.touchscreen',
      ]);

      expect(detection.isTv, isTrue);
      expect(detection.reasons, contains('leanback'));
      expect(detection.reasons, isNot(contains('no_touchscreen')));
    });

    test('detects Fire TV even when touchscreen is present', () {
      final detection = detectAndroidTvFromSystemFeatures(['amazon.hardware.fire_tv', 'android.hardware.touchscreen']);

      expect(detection.isTv, isTrue);
      expect(detection.reasons, contains('fire_tv'));
      expect(detection.reasons, isNot(contains('no_touchscreen')));
    });

    test('detects devices without real touchscreen capability', () {
      final detection = detectAndroidTvFromSystemFeatures(['android.hardware.faketouch']);

      expect(detection.isTv, isTrue);
      expect(detection.reasons, contains('no_touchscreen'));
    });

    test('detects television feature', () {
      final detection = detectAndroidTvFromSystemFeatures([
        'android.hardware.type.television',
        'android.hardware.touchscreen',
      ]);

      expect(detection.isTv, isTrue);
      expect(detection.reasons, contains('television_feature'));
    });

    test('does not classify touchscreen-only devices as TV', () {
      final detection = detectAndroidTvFromSystemFeatures(['android.hardware.touchscreen']);

      expect(detection.isTv, isFalse);
      expect(detection.reasons, isEmpty);
    });

    test('does not classify empty feature lists as no-touchscreen TVs', () {
      final detection = detectAndroidTvFromSystemFeatures(const []);

      expect(detection.isTv, isFalse);
      expect(detection.reasons, isEmpty);
    });
  });
}
