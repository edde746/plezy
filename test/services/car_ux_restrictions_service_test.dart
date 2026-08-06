import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/car_ux_restrictions_service.dart';
import 'package:plezy/utils/platform_detector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<String> calls;

  void answerWith(Map<String, Object?>? state) {
    messenger.setMockMethodCallHandler(CarUxRestrictionsService.channel, (call) async {
      calls.add(call.method);
      if (call.method == 'getState') return state;
      return null;
    });
  }

  /// Delivers what the platform pushes on a restriction change.
  Future<void> pushChange(bool restricted) async {
    await messenger.handlePlatformMessage(
      CarUxRestrictionsService.channel.name,
      CarUxRestrictionsService.channel.codec.encodeMethodCall(
        MethodCall('onChanged', <String, Object?>{'supported': true, 'requiresDistractionOptimization': restricted}),
      ),
      (_) {},
    );
  }

  setUp(() {
    calls = [];
    TvDetectionService.debugReset();
    CarUxRestrictionsService.instance.debugReset();
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(CarUxRestrictionsService.channel, null);
    TvDetectionService.debugReset();
    CarUxRestrictionsService.instance.debugReset();
  });

  test('stays unknown off a car and never touches the platform', () async {
    answerWith({'supported': true, 'requiresDistractionOptimization': true});
    TvDetectionService.debugSetAutomotiveOverride(false);

    expect(CarUxRestrictionsService.instance.state, CarUxRestrictionState.unknown);
    await pumpEventQueue();
    expect(calls, isEmpty, reason: 'a phone must not query the car service');
  });

  test('reads the vehicle state on first use', () async {
    answerWith({'supported': true, 'requiresDistractionOptimization': false});
    TvDetectionService.debugSetAutomotiveOverride(true);

    expect(CarUxRestrictionsService.instance.state, CarUxRestrictionState.unknown, reason: 'async until answered');
    await pumpEventQueue();

    expect(calls, ['getState']);
    expect(CarUxRestrictionsService.instance.state, CarUxRestrictionState.unrestricted);
  });

  test('a car that cannot answer stays unknown, so callers keep lifecycle gating', () async {
    answerWith({'supported': false, 'requiresDistractionOptimization': false});
    TvDetectionService.debugSetAutomotiveOverride(true);

    CarUxRestrictionsService.instance.state;
    await pumpEventQueue();

    expect(CarUxRestrictionsService.instance.state, CarUxRestrictionState.unknown);
  });

  test('a wedged car service costs one budget, not one per caller', () async {
    // Never answers: the call stays in flight forever, which is what a car service that hangs
    // during startup looks like.
    messenger.setMockMethodCallHandler(CarUxRestrictionsService.channel, (call) async {
      calls.add(call.method);
      await Completer<void>().future;
      return null;
    });
    TvDetectionService.debugSetAutomotiveOverride(true);
    const budget = Duration(milliseconds: 300);

    final first = Stopwatch()..start();
    await CarUxRestrictionsService.instance.ensureResolved(timeout: budget);
    first.stop();

    final second = Stopwatch()..start();
    await CarUxRestrictionsService.instance.ensureResolved(timeout: budget);
    second.stop();

    // Wide margins on both sides of the real boundary: one budget spent (~300 ms) against the two
    // a per-attempt timeout would cost (~600 ms), and a second call that should not wait at all.
    expect(calls, ['getState'], reason: 're-awaiting an in-flight call is not a retry');
    expect(second.elapsed, lessThan(budget ~/ 2), reason: 'a call already known to be stuck is not waited on again');
    expect(first.elapsed, lessThan(budget + budget ~/ 2), reason: 'the timeout is the whole budget, not per attempt');
    expect(CarUxRestrictionsService.instance.state, CarUxRestrictionState.unknown);
  });

  test('a vehicle that answered without a verdict is asked again', () async {
    answerWith({'supported': false, 'requiresDistractionOptimization': false});
    TvDetectionService.debugSetAutomotiveOverride(true);

    await CarUxRestrictionsService.instance.ensureResolved(timeout: const Duration(milliseconds: 300));
    expect(calls, ['getState', 'getState'], reason: 'a car service that was not up yet can connect later');

    // And the retry is what lands the verdict once it can.
    answerWith({'supported': true, 'requiresDistractionOptimization': true});
    await CarUxRestrictionsService.instance.ensureResolved(timeout: const Duration(milliseconds: 300));
    expect(CarUxRestrictionsService.instance.state, CarUxRestrictionState.restricted);
  });

  test('a car service that dies drops the verdict instead of freezing it', () async {
    answerWith({'supported': true, 'requiresDistractionOptimization': false});
    TvDetectionService.debugSetAutomotiveOverride(true);
    await CarUxRestrictionsService.instance.ensureResolved(timeout: const Duration(milliseconds: 300));
    expect(CarUxRestrictionsService.instance.state, CarUxRestrictionState.unrestricted);

    // What MainActivity pushes when the car service goes away: nothing maintains
    // the verdict any more, so callers must go back to lifecycle gating rather
    // than keep reading "parked" forever.
    await messenger.handlePlatformMessage(
      CarUxRestrictionsService.channel.name,
      CarUxRestrictionsService.channel.codec.encodeMethodCall(
        const MethodCall('onChanged', <String, Object?>{'supported': false, 'requiresDistractionOptimization': true}),
      ),
      (_) {},
    );

    expect(CarUxRestrictionsService.instance.state, CarUxRestrictionState.unknown);
  });

  test('a car service that is still connecting is waited for, not read as absent', () async {
    // What the platform answers while `Car` connects: no verdict yet, but one is coming over a push.
    answerWith({'supported': false, 'pending': true, 'requiresDistractionOptimization': true});
    TvDetectionService.debugSetAutomotiveOverride(true);

    var resolved = false;
    final waiting = CarUxRestrictionsService.instance
        .ensureResolved(timeout: const Duration(seconds: 2))
        .then((_) => resolved = true);
    await pumpEventQueue();
    expect(resolved, isFalse, reason: 'the verdict is still on its way');

    answerWith({'supported': true, 'requiresDistractionOptimization': false});
    await pushChange(false);
    await waiting;

    expect(resolved, isTrue);
    expect(CarUxRestrictionsService.instance.state, CarUxRestrictionState.unrestricted);
  });

  test('a device with no car service is not waited for at all', () async {
    answerWith({'supported': false, 'pending': false, 'requiresDistractionOptimization': true});
    TvDetectionService.debugSetAutomotiveOverride(true);

    final budget = Stopwatch()..start();
    await CarUxRestrictionsService.instance.ensureResolved(timeout: const Duration(seconds: 2));
    budget.stop();

    expect(budget.elapsed, lessThan(const Duration(seconds: 1)), reason: 'nothing is coming; do not hold playback');
    expect(CarUxRestrictionsService.instance.state, CarUxRestrictionState.unknown);
  });

  test('a promised verdict that never arrives is waited for once, not per caller', () async {
    answerWith({'supported': false, 'pending': true, 'requiresDistractionOptimization': true});
    TvDetectionService.debugSetAutomotiveOverride(true);
    const budget = Duration(milliseconds: 300);

    final first = Stopwatch()..start();
    await CarUxRestrictionsService.instance.ensureResolved(timeout: budget);
    first.stop();

    final second = Stopwatch()..start();
    await CarUxRestrictionsService.instance.ensureResolved(timeout: budget);
    second.stop();

    expect(second.elapsed, lessThan(budget ~/ 2), reason: 'a push that never came must not delay every open');
    expect(first.elapsed, lessThan(budget * 2));
    expect(CarUxRestrictionsService.instance.state, CarUxRestrictionState.unknown);

    // And it still takes the answer if the car service eventually speaks.
    await pushChange(false);
    expect(CarUxRestrictionsService.instance.state, CarUxRestrictionState.unrestricted);
  });

  test('a stalled platform is still asked, so it can retry its own connection', () async {
    answerWith({'supported': false, 'pending': true, 'requiresDistractionOptimization': true});
    TvDetectionService.debugSetAutomotiveOverride(true);
    const budget = Duration(milliseconds: 200);

    await CarUxRestrictionsService.instance.ensureResolved(timeout: budget);
    final asksAfterFirst = calls.length;

    await CarUxRestrictionsService.instance.ensureResolved(timeout: budget);
    await pumpEventQueue();

    // Not waited for a second time, but still asked: `getState` is what makes the platform retry a
    // connection that came up without observing the vehicle.
    expect(calls.length, greaterThan(asksAfterFirst));
  });

  test('platform pushes flip the state and notify listeners', () async {
    answerWith({'supported': true, 'requiresDistractionOptimization': false});
    TvDetectionService.debugSetAutomotiveOverride(true);
    CarUxRestrictionsService.instance.state;
    await pumpEventQueue();

    final seen = <CarUxRestrictionState>[];
    void listener() => seen.add(CarUxRestrictionsService.instance.listenable.value);
    CarUxRestrictionsService.instance.listenable.addListener(listener);
    addTearDown(() => CarUxRestrictionsService.instance.listenable.removeListener(listener));

    await pushChange(true);
    await pushChange(true);
    await pushChange(false);

    expect(seen, [CarUxRestrictionState.restricted, CarUxRestrictionState.unrestricted]);
    expect(CarUxRestrictionsService.instance.state, CarUxRestrictionState.unrestricted);
  });

  test('a missing platform channel degrades to unknown instead of throwing', () async {
    messenger.setMockMethodCallHandler(CarUxRestrictionsService.channel, null);
    TvDetectionService.debugSetAutomotiveOverride(true);

    expect(CarUxRestrictionsService.instance.state, CarUxRestrictionState.unknown);
    await pumpEventQueue();
    expect(CarUxRestrictionsService.instance.state, CarUxRestrictionState.unknown);
  });
}
