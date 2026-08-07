import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
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

    InputModeTracker.reportNonPointerInput();
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

    InputModeTracker.reportNonPointerInput();
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

    InputModeTracker.reportNonPointerInput();
    await tester.pump();

    expect(find.byType(MouseRegion), findsNothing);
    await tester.tap(find.byKey(const Key('tv-target')));
    await tester.pump();
    expect(taps, 1);
  });
  testWidgets('a physical-keyboard Enter does not switch the app into keyboard mode', (tester) async {
    expect(await _modeAfterKey(tester, LogicalKeyboardKey.enter), InputMode.pointer);
  });

  testWidgets('Escape dismisses without switching the app into keyboard mode', (tester) async {
    expect(await _modeAfterKey(tester, LogicalKeyboardKey.escape), InputMode.pointer);
  });

  testWidgets('an arrow key still switches the app into keyboard mode', (tester) async {
    expect(await _modeAfterKey(tester, LogicalKeyboardKey.arrowDown), InputMode.keyboard);
  });

  testWidgets('Tab still switches the app into keyboard mode', (tester) async {
    expect(await _modeAfterKey(tester, LogicalKeyboardKey.tab), InputMode.keyboard);
  });

  // Startup replaces the bootstrap tree with the app tree: the incoming tracker
  // initialises during the build pass and the outgoing one disposes afterwards.
  // An unguarded teardown left no tracker registered, so gamepad and companion
  // remote input silently stopped switching the app into keyboard mode.
  testWidgets('a tracker swap keeps device input reporting', (tester) async {
    late InputMode observed;
    Widget tree(Key key) => InputModeTracker(
      key: key,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) {
            observed = InputModeTracker.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    await tester.pumpWidget(tree(const Key('bootstrap')));
    await tester.pumpWidget(tree(const Key('app')));

    InputModeTracker.reportNonPointerInput();
    await tester.pump();

    expect(observed, InputMode.keyboard);
  });

  testWidgets('reporting device input with no tracker mounted is a no-op', (tester) async {
    await tester.pumpWidget(const SizedBox.shrink());

    expect(InputModeTracker.reportNonPointerInput, returnsNormally);
  });
}

/// Pumps a tracker, sends [key], and reports the mode the tree observes.
Future<InputMode> _modeAfterKey(WidgetTester tester, LogicalKeyboardKey key) async {
  late InputMode observed;

  await tester.pumpWidget(
    InputModeTracker(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) {
            observed = InputModeTracker.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  expect(observed, InputMode.pointer, reason: 'precondition: the app starts pointer-driven off TV');

  await tester.sendKeyDownEvent(key);
  await tester.pump();
  await tester.sendKeyUpEvent(key);
  await tester.pump();

  return observed;
}
