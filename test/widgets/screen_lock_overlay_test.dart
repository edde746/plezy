import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/widgets/video_controls/widgets/screen_lock_overlay.dart';

void main() {
  Future<void> pumpOverlay(
    WidgetTester tester, {
    int fingers = 1,
    Duration duration = const Duration(milliseconds: 500),
    required VoidCallback onUnlock,
    String Function(int)? progressLabel,
    bool disableAnimations = false,
    bool autoHideHint = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Scaffold(
            body: ScreenLockOverlay(
              requiredFingers: fingers,
              holdDuration: duration,
              onUnlock: onUnlock,
              instruction: 'Hold $fingers fingers to unlock',
              touchProgressLabelBuilder: progressLabel,
              autoHideHint: autoHideHint,
            ),
          ),
        ),
      ),
    );
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
  }

  Future<TestGesture> touch(WidgetTester tester, int pointer, {Offset? position}) async {
    final gesture = await tester.createGesture(pointer: pointer, kind: PointerDeviceKind.touch);
    await gesture.down(position ?? Offset(50 + pointer * 50, 80));
    return gesture;
  }

  testWidgets('the complete hold duration is required, including with reduced animations', (tester) async {
    var unlocked = 0;
    await pumpOverlay(tester, onUnlock: () => unlocked++, disableAnimations: true);
    final finger = await touch(tester, 1);
    await tester.pump(const Duration(milliseconds: 499));
    expect(unlocked, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(unlocked, 1);
    await tester.pump(const Duration(seconds: 2));
    expect(unlocked, 1);
    await finger.up();
  });

  testWidgets('three fingers must overlap for the entire hold', (tester) async {
    var unlocked = 0;
    await pumpOverlay(tester, fingers: 3, onUnlock: () => unlocked++);
    final first = await touch(tester, 1);
    final second = await touch(tester, 2);
    await tester.pump(const Duration(seconds: 1));
    expect(unlocked, 0);
    final third = await touch(tester, 3);
    await tester.pump(const Duration(milliseconds: 499));
    expect(unlocked, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(unlocked, 1);
    await first.up();
    await second.up();
    await third.up();
  });

  testWidgets('four and five finger holds are supported', (tester) async {
    for (final count in [4, 5]) {
      var unlocked = 0;
      await pumpOverlay(tester, fingers: count, onUnlock: () => unlocked++);
      final fingers = <TestGesture>[];
      for (var i = 1; i <= count; i++) {
        fingers.add(await touch(tester, i));
      }
      await tester.pump(const Duration(milliseconds: 500));
      expect(unlocked, 1);
      for (final finger in fingers) {
        await finger.up();
      }
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('excess fingers interrupt the hold and returning to the exact count starts over', (tester) async {
    var unlocked = 0;
    await pumpOverlay(tester, fingers: 2, onUnlock: () => unlocked++);
    final first = await touch(tester, 1);
    final second = await touch(tester, 2);
    await tester.pump(const Duration(milliseconds: 400));
    final extra = await touch(tester, 3);
    await tester.pump(const Duration(seconds: 1));
    expect(unlocked, 0);
    await extra.up();
    await tester.pump(const Duration(milliseconds: 499));
    expect(unlocked, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(unlocked, 1);
    await first.up();
    await second.up();
  });

  testWidgets('lifting and replacing a finger does not retain elapsed time', (tester) async {
    var unlocked = 0;
    await pumpOverlay(tester, fingers: 2, onUnlock: () => unlocked++);
    final first = await touch(tester, 1);
    final second = await touch(tester, 2);
    await tester.pump(const Duration(milliseconds: 400));
    await second.up();
    final replacement = await touch(tester, 3);
    await tester.pump(const Duration(milliseconds: 499));
    expect(unlocked, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(unlocked, 1);
    await first.up();
    await replacement.up();
  });

  testWidgets('a canceled touch requires every remaining finger to release before retrying', (tester) async {
    var unlocked = 0;
    await pumpOverlay(tester, fingers: 2, onUnlock: () => unlocked++);
    final first = await touch(tester, 1);
    final second = await touch(tester, 2);
    await tester.pump(const Duration(milliseconds: 400));
    await second.cancel();
    final replacement = await touch(tester, 3);
    await tester.pump(const Duration(seconds: 1));
    expect(unlocked, 0);
    await first.up();
    await replacement.up();
    final retryFirst = await touch(tester, 4);
    final retrySecond = await touch(tester, 5);
    await tester.pump(const Duration(milliseconds: 500));
    expect(unlocked, 1);
    await retryFirst.up();
    await retrySecond.up();
  });

  testWidgets('swiping cannot turn into an unlock by stopping or returning to the origin', (tester) async {
    var unlocked = 0;
    await pumpOverlay(tester, onUnlock: () => unlocked++);
    final finger = await touch(tester, 1, position: const Offset(100, 100));
    await tester.pump(const Duration(milliseconds: 300));
    await finger.moveTo(const Offset(130, 100));
    await finger.moveTo(const Offset(100, 100));
    await tester.pump(const Duration(seconds: 1));
    expect(unlocked, 0);
    await finger.up();
    final retry = await touch(tester, 2);
    await tester.pump(const Duration(milliseconds: 500));
    expect(unlocked, 1);
    await retry.up();
  });

  testWidgets('small normal finger movement remains a stationary hold', (tester) async {
    var unlocked = 0;
    await pumpOverlay(tester, onUnlock: () => unlocked++);
    final finger = await touch(tester, 1, position: const Offset(100, 100));
    await finger.moveTo(const Offset(105, 104));
    await tester.pump(const Duration(milliseconds: 500));
    expect(unlocked, 1);
    await finger.up();
  });

  testWidgets('mouse and stylus pointers cannot satisfy a finger requirement', (tester) async {
    var unlocked = 0;
    await pumpOverlay(tester, onUnlock: () => unlocked++);
    for (final kind in [PointerDeviceKind.mouse, PointerDeviceKind.stylus]) {
      final pointer = await tester.createGesture(pointer: kind.index + 10, kind: kind);
      await pointer.down(const Offset(100, 100));
      await tester.pump(const Duration(seconds: 1));
      expect(unlocked, 0);
      await pointer.up();
    }
  });

  testWidgets('inactive and resumed app states discard an interrupted hold', (tester) async {
    var unlocked = 0;
    await pumpOverlay(tester, onUnlock: () => unlocked++);
    final finger = await touch(tester, 1);
    await tester.pump(const Duration(milliseconds: 400));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump(const Duration(seconds: 1));
    expect(unlocked, 0);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 1));
    expect(unlocked, 0);
    await finger.up();
    final retry = await touch(tester, 2);
    await tester.pump(const Duration(milliseconds: 500));
    expect(unlocked, 1);
    await retry.up();
  });

  testWidgets('changing the required count cancels touches held under the old requirement', (tester) async {
    var unlocked = 0;
    await pumpOverlay(tester, onUnlock: () => unlocked++);
    final first = await touch(tester, 1);
    await tester.pump(const Duration(milliseconds: 400));
    await pumpOverlay(tester, fingers: 2, onUnlock: () => unlocked++);
    final second = await touch(tester, 2);
    await tester.pump(const Duration(seconds: 1));
    expect(unlocked, 0);
    await first.up();
    await second.up();
    final retryFirst = await touch(tester, 3);
    final retrySecond = await touch(tester, 4);
    await tester.pump(const Duration(milliseconds: 500));
    expect(unlocked, 1);
    await retryFirst.up();
    await retrySecond.up();
  });

  testWidgets('changing the duration requires a fresh hold with the new duration', (tester) async {
    var unlocked = 0;
    await pumpOverlay(tester, onUnlock: () => unlocked++);
    final finger = await touch(tester, 1);
    await tester.pump(const Duration(milliseconds: 400));
    await pumpOverlay(tester, duration: const Duration(seconds: 2), onUnlock: () => unlocked++);
    await tester.pump(const Duration(seconds: 3));
    expect(unlocked, 0);
    await finger.up();
    final retry = await touch(tester, 2);
    await tester.pump(const Duration(milliseconds: 1999));
    expect(unlocked, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(unlocked, 1);
    await retry.up();
  });

  testWidgets('disposing the overlay cancels pending unlock and hint timers', (tester) async {
    var unlocked = 0;
    await pumpOverlay(tester, onUnlock: () => unlocked++);
    final finger = await touch(tester, 1);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 4));
    expect(unlocked, 0);
    expect(tester.takeException(), isNull);
    await finger.up();
  });

  testWidgets('the hidden hint still absorbs touches and reappears on a touch', (tester) async {
    var underlyingTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => underlyingTaps++),
              ScreenLockOverlay(
                requiredFingers: 2,
                holdDuration: const Duration(milliseconds: 500),
                onUnlock: () {},
                instruction: 'Hold two fingers',
              ),
            ],
          ),
        ),
      ),
    );
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity, 0);
    final finger = await touch(tester, 1);
    await tester.pump();
    expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity, 1);
    await finger.up();
    await tester.pump();
    expect(underlyingTaps, 0);
  });

  testWidgets('the hint remains visible throughout a hold longer than its normal timeout', (tester) async {
    var unlocked = 0;
    await pumpOverlay(tester, duration: const Duration(seconds: 5), onUnlock: () => unlocked++);
    final finger = await touch(tester, 1);
    await tester.pump(const Duration(seconds: 4));
    expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity, 1);
    expect(unlocked, 0);
    await tester.pump(const Duration(seconds: 1));
    expect(unlocked, 1);
    await finger.up();
  });

  testWidgets('preview mode keeps the instruction visible without a touch', (tester) async {
    await pumpOverlay(tester, onUnlock: () {}, autoHideHint: false);
    await tester.pump(const Duration(seconds: 5));
    expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity, 1);
  });

  testWidgets('lifting the unlocking finger after removing the overlay does not tap playback', (tester) async {
    var locked = true;
    var underlyingTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => underlyingTaps++),
                if (locked)
                  ScreenLockOverlay(
                    requiredFingers: 1,
                    holdDuration: const Duration(milliseconds: 500),
                    onUnlock: () => setState(() => locked = false),
                    instruction: 'Hold to unlock',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    final finger = await touch(tester, 1);
    await tester.pump(const Duration(milliseconds: 500));
    expect(locked, isFalse);
    expect(find.byType(ScreenLockOverlay), findsNothing);
    await finger.up();
    await tester.pump();
    expect(underlyingTaps, 0);
    await tester.tapAt(const Offset(100, 80));
    expect(underlyingTaps, 1);
  });

  testWidgets('incomplete unlock touches do not activate an ancestor playback gesture', (tester) async {
    var playbackTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GestureDetector(
            onTap: () => playbackTaps++,
            child: ScreenLockOverlay(
              requiredFingers: 3,
              holdDuration: const Duration(milliseconds: 500),
              onUnlock: () {},
              instruction: 'Hold three fingers',
            ),
          ),
        ),
      ),
    );
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester.tapAt(const Offset(100, 100));
    expect(playbackTaps, 0);
  });

  testWidgets('semantics describes the hold without a tap or long-press bypass', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpOverlay(tester, fingers: 3, onUnlock: () {});
      final node = tester.getSemantics(find.byType(ScreenLockOverlay));
      expect(node.label, 'Hold 3 fingers to unlock');
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      expect(node.getSemanticsData().hasAction(SemanticsAction.longPress), isFalse);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('optional feedback reports the current number of touch fingers', (tester) async {
    await pumpOverlay(tester, fingers: 3, onUnlock: () {}, progressLabel: (count) => '$count / 3');
    expect(find.text('0 / 3'), findsOneWidget);
    final finger = await touch(tester, 1);
    await tester.pump();
    expect(find.text('1 / 3'), findsOneWidget);
    await finger.up();
    await tester.pump();
    expect(find.text('0 / 3'), findsOneWidget);
  });
}
