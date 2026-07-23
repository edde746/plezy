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
}
