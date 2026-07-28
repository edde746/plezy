import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/driver_distraction.dart';
import 'package:plezy/utils/platform_detector.dart';

void main() {
  group('automotivePlaybackAllowed', () {
    test('never restricts playback off Android Automotive OS', () {
      for (final state in [...AppLifecycleState.values, null]) {
        expect(
          automotivePlaybackAllowed(isAutomotive: false, state: state),
          isTrue,
          reason: 'non-automotive playback must not depend on lifecycle state ($state)',
        );
      }
    });

    test('allows playback on a car only while the app is resumed', () {
      expect(automotivePlaybackAllowed(isAutomotive: true, state: AppLifecycleState.resumed), isTrue);
    });

    test('stops playback on the onPause edge that every car delivers', () {
      // Android `onPause` maps to `inactive`, and cars without the Automotive
      // compatibility mode never go on to deliver `onStop`. This is the edge
      // the rejected build ignored.
      expect(automotivePlaybackAllowed(isAutomotive: true, state: AppLifecycleState.inactive), isFalse);
    });

    test('stops playback on the onStop edges compatibility-mode cars deliver', () {
      expect(automotivePlaybackAllowed(isAutomotive: true, state: AppLifecycleState.hidden), isFalse);
      expect(automotivePlaybackAllowed(isAutomotive: true, state: AppLifecycleState.paused), isFalse);
      expect(automotivePlaybackAllowed(isAutomotive: true, state: AppLifecycleState.detached), isFalse);
    });

    test('fails closed on an unknown lifecycle state', () {
      expect(automotivePlaybackAllowed(isAutomotive: true, state: null), isFalse);
    });
  });

  group('automotivePlaybackAllowedNow', () {
    setUp(() {
      TvDetectionService.debugReset();
      addTearDown(TvDetectionService.debugReset);
    });

    testWidgets('reads the ambient form factor and lifecycle', (tester) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(automotivePlaybackAllowedNow(), isTrue);

      TvDetectionService.debugSetAutomotiveOverride(true);
      expect(automotivePlaybackAllowedNow(), isTrue);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      expect(automotivePlaybackAllowedNow(), isFalse);

      TvDetectionService.debugSetAutomotiveOverride(false);
      expect(automotivePlaybackAllowedNow(), isTrue);
    });
  });
}
