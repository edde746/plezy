import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/services/keyboard_shortcuts_service.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/prefs.dart';

void main() {
  setUp(() {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
  });

  testWidgets('Ctrl+S takes a screenshot and shows feedback', (tester) async {
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
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(result, KeyEventResult.handled);
    expect(player.commands, [
      ['screenshot', 'subtitles'],
    ]);
    expect(feedbackCount, 1);
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
