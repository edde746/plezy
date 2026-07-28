import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/platform_detector.dart';

void main() {
  setUp(() {
    TvDetectionService.debugReset();
    addTearDown(TvDetectionService.debugReset);
  });

  test('concurrent callers wait for TV detection', () async {
    final detection = Completer<void>();
    TvDetectionService.debugDetectionGate = detection.future;

    final first = TvDetectionService.getInstance(forceTv: true);
    var secondCompleted = false;
    final second = TvDetectionService.getInstance();
    unawaited(second.then((_) => secondCompleted = true));
    await Future<void>.delayed(Duration.zero);

    expect(secondCompleted, isFalse);
    detection.complete();

    final instances = await Future.wait([first, second]);
    expect(identical(instances.first, instances.last), isTrue);
    expect(instances.first.isTV, isTrue);
  });

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
