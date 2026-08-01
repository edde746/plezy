import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/services/gamepad_service.dart';
import 'package:plezy/utils/platform_detector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('one-shot reads do not subscribe to input-mode changes', (tester) async {
    var listeningBuilds = 0;
    var oneShotBuilds = 0;
    InputMode? listeningMode;
    InputMode? oneShotMode;

    await tester.pumpWidget(
      InputModeTracker(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            children: [
              Builder(
                builder: (context) {
                  listeningBuilds++;
                  listeningMode = InputModeTracker.of(context);
                  return const SizedBox.shrink();
                },
              ),
              Builder(
                builder: (context) {
                  oneShotBuilds++;
                  oneShotMode = InputModeTracker.of(context, listen: false);
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );

    expect(listeningMode, InputMode.pointer);
    expect(oneShotMode, InputMode.pointer);
    expect(listeningBuilds, 1);
    expect(oneShotBuilds, 1);

    GamepadService.onGamepadInput!.call();
    await tester.pump();

    expect(listeningMode, InputMode.keyboard);
    expect(listeningBuilds, 2);
    expect(oneShotMode, InputMode.pointer);
    expect(oneShotBuilds, 1);
  });

  testWidgets('keyboard-mode cursor shield preserves pointer activation', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      InputModeTracker(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: GestureDetector(
            key: const Key('target'),
            behavior: HitTestBehavior.opaque,
            onTap: () => taps++,
            child: const SizedBox(width: 120, height: 80),
          ),
        ),
      ),
    );

    GamepadService.onGamepadInput!.call();
    await tester.pump();

    expect(tester.widget<MouseRegion>(find.byType(MouseRegion)).cursor, SystemMouseCursors.none);

    await tester.tap(find.byKey(const Key('target')));
    await tester.pump();

    expect(taps, 1);
    expect(find.byType(MouseRegion), findsNothing);
  });

  testWidgets('non-desktop TV path has no cursor shield and remains pointer-reachable', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    PlatformDetector.debugSetIsDesktopOSOverride(false);
    addTearDown(() {
      TvDetectionService.debugSetAppleTVOverride(null);
      PlatformDetector.debugSetIsDesktopOSOverride(null);
    });
    var taps = 0;

    await tester.pumpWidget(
      InputModeTracker(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: GestureDetector(
            key: const Key('tv-target'),
            behavior: HitTestBehavior.opaque,
            onTap: () => taps++,
            child: const SizedBox(width: 120, height: 80),
          ),
        ),
      ),
    );

    GamepadService.onGamepadInput!.call();
    await tester.pump();

    expect(find.byType(MouseRegion), findsNothing);
    await tester.tap(find.byKey(const Key('tv-target')));
    await tester.pump();
    expect(taps, 1);
  });
}
