import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/car_ux_restrictions_service.dart';
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

    test('a vehicle reporting restrictions overrides lifecycle in both directions', () {
      // The point of the platform signal: parked-but-backgrounded keeps playing,
      // and driving stops audio even while the app still looks resumed.
      for (final state in [...AppLifecycleState.values, null]) {
        expect(
          automotivePlaybackAllowed(isAutomotive: true, state: state, restrictions: CarUxRestrictionState.unrestricted),
          isTrue,
          reason: 'a parked car must allow playback regardless of lifecycle ($state)',
        );
        expect(
          automotivePlaybackAllowed(isAutomotive: true, state: state, restrictions: CarUxRestrictionState.restricted),
          isFalse,
          reason: 'a driving car must deny playback regardless of lifecycle ($state)',
        );
      }
    });

    test('an unknown vehicle keeps the lifecycle rule', () {
      expect(
        automotivePlaybackAllowed(
          isAutomotive: true,
          state: AppLifecycleState.resumed,
          restrictions: CarUxRestrictionState.unknown,
        ),
        isTrue,
      );
      expect(
        automotivePlaybackAllowed(
          isAutomotive: true,
          state: AppLifecycleState.inactive,
          restrictions: CarUxRestrictionState.unknown,
        ),
        isFalse,
      );
    });

    test('a restricted vehicle never unlocks playback off a car', () {
      expect(
        automotivePlaybackAllowed(
          isAutomotive: false,
          state: AppLifecycleState.resumed,
          restrictions: CarUxRestrictionState.restricted,
        ),
        isTrue,
      );
    });
  });

  group('automotivePlaybackAllowedNow', () {
    setUp(() {
      TvDetectionService.debugReset();
      addTearDown(TvDetectionService.debugReset);
      addTearDown(() => CarUxRestrictionsService.debugSetOverride(null));
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

    testWidgets('a parked vehicle keeps playback alive while the app is backgrounded', (tester) async {
      TvDetectionService.debugSetAutomotiveOverride(true);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      expect(automotivePlaybackAllowedNow(), isFalse, reason: 'no vehicle signal yet: lifecycle still rules');

      CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.unrestricted);
      expect(automotivePlaybackAllowedNow(), isTrue);

      CarUxRestrictionsService.debugSetOverride(CarUxRestrictionState.restricted);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(automotivePlaybackAllowedNow(), isFalse, reason: 'driving denies playback even while resumed');
    });
  });
}
