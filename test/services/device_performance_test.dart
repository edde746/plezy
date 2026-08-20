import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/device_performance.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    DevicePerformance.debugReset();
    addTearDown(DevicePerformance.debugReset);
  });

  test('concurrent callers wait for hardware detection', () async {
    final detection = Completer<void>();
    DevicePerformance.debugDetectionGate = detection.future;

    final first = DevicePerformance.getInstance(override: VisualEffectsSetting.reduced);
    var secondCompleted = false;
    final second = DevicePerformance.getInstance();
    unawaited(second.then((_) => secondCompleted = true));
    await Future<void>.delayed(Duration.zero);

    expect(secondCompleted, isFalse);
    detection.complete();

    final instances = await Future.wait([first, second]);
    expect(identical(instances.first, instances.last), isTrue);
    expect(DevicePerformance.isReduced, isTrue);
  });

  test('failed hardware detection can be retried', () async {
    DevicePerformance.debugDetectionGate = Future<void>.error(StateError('detection failed'));

    await expectLater(DevicePerformance.getInstance(), throwsStateError);

    DevicePerformance.debugDetectionGate = null;
    final recovered = await DevicePerformance.getInstance();
    expect(recovered, isNotNull);
  });

  group('displayBudgetFactor', () {
    void detectAt(double shortestSide) {
      DevicePerformance.debugDisplayShortestSideOverride = shortestSide;
      DevicePerformance.debugDetectDisplayBudget();
    }

    test('stays 1.0 until a latch runs', () {
      DevicePerformance.debugReset(autoReduced: false, override: VisualEffectsSetting.auto);
      expect(DevicePerformance.displayBudgetFactor(), 1.0);
    });

    test('scales with the display shortest side up to 2x', () {
      DevicePerformance.debugReset(autoReduced: false, override: VisualEffectsSetting.auto);

      detectAt(1080);
      expect(DevicePerformance.displayBudgetFactor(), 1.0);

      detectAt(1440);
      expect(DevicePerformance.displayBudgetFactor(), closeTo(1440 / 1080, 0.001));

      detectAt(2160);
      expect(DevicePerformance.displayBudgetFactor(), 2.0);

      // 8K stays at the 2x ceiling.
      detectAt(4320);
      expect(DevicePerformance.displayBudgetFactor(), 2.0);
    });

    test('sub-1080p displays never shrink the budget below 1.0', () {
      DevicePerformance.debugReset(autoReduced: false, override: VisualEffectsSetting.auto);
      detectAt(720);
      expect(DevicePerformance.displayBudgetFactor(), 1.0);
    });

    test('mid-RAM hardware holds a 4K budget at 1.5x', () {
      DevicePerformance.debugReset(autoReduced: false, override: VisualEffectsSetting.auto, totalMemBytes: 2400 << 20);
      detectAt(2160);
      expect(DevicePerformance.displayBudgetFactor(), 1.5);
    });

    test('high-RAM hardware keeps the full 4K budget', () {
      DevicePerformance.debugReset(autoReduced: false, override: VisualEffectsSetting.auto, totalMemBytes: 2870 << 20);
      detectAt(2160);
      expect(DevicePerformance.displayBudgetFactor(), 2.0);
    });

    test('reduced tier pins the budget to 1.0 even after a 4K latch', () {
      DevicePerformance.debugReset(autoReduced: true, override: VisualEffectsSetting.auto);
      detectAt(2160);
      expect(DevicePerformance.displayBudgetFactor(), 1.0);
    });
  });
}
