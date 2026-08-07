import 'package:flutter_test/flutter_test.dart';

/// Pumps frames until [condition] holds, yielding to the real event loop
/// between frames so work that is not driven by the test clock - platform
/// channel replies, microtask chains behind `runAsync` - can land.
///
/// Fails the test if [condition] is still false after 200 frames - 2 s of test
/// clock, plus a 5 ms real-time yield per frame. Worth knowing that 2 s is
/// shorter than `PlayerBase.debugNativeOwnershipDisposeTimeout`'s 3 s default,
/// so a wait blocked behind a player handover expires here first and reports an
/// empty observation rather than the timeout. Pass [describe] to attach the
/// observed state to that failure.
Future<void> pumpUntil(WidgetTester tester, bool Function() condition, {String Function()? describe}) async {
  for (var i = 0; i < 200 && !condition(); i++) {
    await tester.pump(const Duration(milliseconds: 10));
    if (!condition()) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    }
  }
  expect(condition(), isTrue, reason: describe == null ? null : 'observed ${describe()}');
}
