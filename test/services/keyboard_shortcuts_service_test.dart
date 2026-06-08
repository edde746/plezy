import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vibe_stream/mpv/mpv.dart';
import 'package:vibe_stream/services/keyboard_shortcuts_service.dart';
import 'package:vibe_stream/services/settings_service.dart';
import 'package:vibe_stream/services/video_filter_manager.dart';

import '../test_helpers/prefs.dart';

void main() {
  setUp(() {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
  });

  testWidgets('Ctrl+S takes a screenshot once while held', (tester) async {
    final service = await KeyboardShortcutsService.getInstance();
    addTearDown(service.dispose);
    final player = _FakePlayer();
    var feedbackCount = 0;

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    final result = service.handleVideoPlayerKeyEvent(
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyS,
        logicalKey: LogicalKeyboardKey.keyS,
        timeStamp: Duration.zero,
      ),
      player,
      null,
      null,
      null,
      null,
      null,
      null,
      onScreenshot: () => feedbackCount++,
    );
    final repeatResult = service.handleVideoPlayerKeyEvent(
      const KeyRepeatEvent(
        physicalKey: PhysicalKeyboardKey.keyS,
        logicalKey: LogicalKeyboardKey.keyS,
        timeStamp: Duration(milliseconds: 30),
      ),
      player,
      null,
      null,
      null,
      null,
      null,
      null,
      onScreenshot: () => feedbackCount++,
    );
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(result, KeyEventResult.handled);
    expect(repeatResult, KeyEventResult.handled);
    expect(player.commands, [
      ['screenshot', 'subtitles'],
    ]);
    expect(feedbackCount, 1);
  });

  testWidgets('Alt+Plus triggers zoom in callback', (tester) async {
    final service = await KeyboardShortcutsService.getInstance();
    addTearDown(service.dispose);
    final player = _FakePlayer();
    var zoomInCount = 0;

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    final result = service.handleVideoPlayerKeyEvent(
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.equal,
        logicalKey: LogicalKeyboardKey.equal,
        timeStamp: Duration.zero,
      ),
      player,
      null,
      null,
      null,
      null,
      null,
      null,
      onZoomIn: () => zoomInCount++,
    );
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);

    expect(result, KeyEventResult.handled);
    expect(zoomInCount, 1);
  });

  testWidgets('Alt+Plus repeats zoom in callback while held', (tester) async {
    final service = await KeyboardShortcutsService.getInstance();
    addTearDown(service.dispose);
    final player = _FakePlayer();
    var zoomInCount = 0;

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    final downResult = service.handleVideoPlayerKeyEvent(
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.equal,
        logicalKey: LogicalKeyboardKey.equal,
        timeStamp: Duration.zero,
      ),
      player,
      null,
      null,
      null,
      null,
      null,
      null,
      onZoomIn: () => zoomInCount++,
    );
    final repeatResult = service.handleVideoPlayerKeyEvent(
      const KeyRepeatEvent(
        physicalKey: PhysicalKeyboardKey.equal,
        logicalKey: LogicalKeyboardKey.equal,
        timeStamp: Duration(milliseconds: 30),
      ),
      player,
      null,
      null,
      null,
      null,
      null,
      null,
      onZoomIn: () => zoomInCount++,
    );
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);

    expect(downResult, KeyEventResult.handled);
    expect(repeatResult, KeyEventResult.handled);
    expect(zoomInCount, 2);
  });

  testWidgets('Alt+Minus repeats zoom out callback while held', (tester) async {
    final service = await KeyboardShortcutsService.getInstance();
    addTearDown(service.dispose);
    final player = _FakePlayer();
    var zoomOutCount = 0;

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    final downResult = service.handleVideoPlayerKeyEvent(
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.minus,
        logicalKey: LogicalKeyboardKey.minus,
        timeStamp: Duration.zero,
      ),
      player,
      null,
      null,
      null,
      null,
      null,
      null,
      onZoomOut: () => zoomOutCount++,
    );
    final repeatResult = service.handleVideoPlayerKeyEvent(
      const KeyRepeatEvent(
        physicalKey: PhysicalKeyboardKey.minus,
        logicalKey: LogicalKeyboardKey.minus,
        timeStamp: Duration(milliseconds: 30),
      ),
      player,
      null,
      null,
      null,
      null,
      null,
      null,
      onZoomOut: () => zoomOutCount++,
    );
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);

    expect(downResult, KeyEventResult.handled);
    expect(repeatResult, KeyEventResult.handled);
    expect(zoomOutCount, 2);
  });

  testWidgets('Alt+Backspace reset does not repeat while held', (tester) async {
    final service = await KeyboardShortcutsService.getInstance();
    addTearDown(service.dispose);
    final player = _FakePlayer();
    var resetCount = 0;

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    final downResult = service.handleVideoPlayerKeyEvent(
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.backspace,
        logicalKey: LogicalKeyboardKey.backspace,
        timeStamp: Duration.zero,
      ),
      player,
      null,
      null,
      null,
      null,
      null,
      null,
      onZoomReset: () => resetCount++,
    );
    final repeatResult = service.handleVideoPlayerKeyEvent(
      const KeyRepeatEvent(
        physicalKey: PhysicalKeyboardKey.backspace,
        logicalKey: LogicalKeyboardKey.backspace,
        timeStamp: Duration(milliseconds: 30),
      ),
      player,
      null,
      null,
      null,
      null,
      null,
      null,
      onZoomReset: () => resetCount++,
    );
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);

    expect(downResult, KeyEventResult.handled);
    expect(repeatResult, KeyEventResult.handled);
    expect(resetCount, 1);
  });

  testWidgets('command-modified keys are not treated as video hotkeys', (tester) async {
    final service = await KeyboardShortcutsService.getInstance();
    addTearDown(service.dispose);
    final player = _FakePlayer();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);

    final commandMResult = service.handleVideoPlayerKeyEvent(
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyM,
        logicalKey: LogicalKeyboardKey.keyM,
        timeStamp: Duration.zero,
      ),
      player,
      null,
      null,
      null,
      null,
      null,
      null,
    );
    final commandQResult = service.handleVideoPlayerKeyEvent(
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyQ,
        logicalKey: LogicalKeyboardKey.keyQ,
        timeStamp: Duration(milliseconds: 1),
      ),
      player,
      null,
      null,
      null,
      null,
      null,
      null,
    );
    final commandCommaResult = service.handleVideoPlayerKeyEvent(
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.comma,
        logicalKey: LogicalKeyboardKey.comma,
        timeStamp: Duration(milliseconds: 2),
      ),
      player,
      null,
      null,
      null,
      null,
      null,
      null,
    );

    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);

    expect(commandMResult, KeyEventResult.ignored);
    expect(commandQResult, KeyEventResult.ignored);
    expect(commandCommaResult, KeyEventResult.ignored);
  });

  test('video zoom scale maps to mpv logarithmic property', () {
    expect(VideoFilterManager.videoZoomPropertyForScale(1.0), closeTo(0.0, 0.0001));
    expect(VideoFilterManager.videoZoomPropertyForScale(2.0), closeTo(1.0, 0.0001));
    expect(VideoFilterManager.videoZoomPropertyForScale(0.5), closeTo(-1.0, 0.0001));
  });
}

class _FakePlayer implements Player {
  final commands = <List<String>>[];

  @override
  Future<void> command(List<String> args) async {
    commands.add(args);
  }

  @override
  PlayerState get state => PlayerState();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
