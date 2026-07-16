import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/hotkey_model.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/services/keyboard_shortcuts_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/video_filter_manager.dart';

import '../test_helpers/prefs.dart';

void main() {
  setUp(() {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
  });

  group('HotKey persistence', () {
    test('loads shortcuts saved with the shipped pre-HID key format', () async {
      resetSharedPreferencesForTest(
        initialAsync: {
          'keyboard_hotkeys': json.encode({
            'play_pause': {
              'key': 'PhysicalKeyboardKey#abcde(usbHidUsage: "0x00070013", debugName: "Key P")',
              'modifiers': ['control'],
            },
          }),
        },
      );
      SettingsService.resetForTesting();
      final service = await KeyboardShortcutsService.getInstance();
      addTearDown(service.dispose);

      final hotkey = service.getHotkey('play_pause');
      expect(hotkey?.key, PhysicalKeyboardKey.keyP);
      expect(hotkey?.modifiers, [HotKeyModifier.control]);
      expect(service.getHotkey('volume_up')?.key, PhysicalKeyboardKey.arrowUp);
    });

    test('saves shortcuts in the current HID format', () async {
      final service = await KeyboardShortcutsService.getInstance();
      addTearDown(service.dispose);

      await service.setHotkey(
        'play_pause',
        const HotKey(key: PhysicalKeyboardKey.keyQ, modifiers: [HotKeyModifier.shift]),
      );

      final stored =
          json.decode(SettingsService.instance.prefs.getString(SettingsService.keyboardHotkeys.key)!)
              as Map<String, dynamic>;
      expect(stored['play_pause'], {
        'key': '00070014',
        'modifiers': ['shift'],
      });
      expect(service.getHotkey('play_pause')?.key, PhysicalKeyboardKey.keyQ);
      expect(service.getHotkey('play_pause')?.modifiers, [HotKeyModifier.shift]);
    });

    test('resets shortcuts to active defaults', () async {
      final service = await KeyboardShortcutsService.getInstance();
      addTearDown(service.dispose);
      await service.setHotkey(
        'play_pause',
        const HotKey(key: PhysicalKeyboardKey.f12, modifiers: [HotKeyModifier.alt]),
      );

      await service.resetToDefaults();

      expect(service.getHotkey('play_pause')?.key, PhysicalKeyboardKey.space);
      expect(service.getHotkey('play_pause')?.modifiers, isNull);
      final stored =
          json.decode(SettingsService.instance.prefs.getString(SettingsService.keyboardHotkeys.key)!)
              as Map<String, dynamic>;
      expect(stored['play_pause'], {'key': '0007002c', 'modifiers': <dynamic>[]});
    });

    test('tracks resetAllSettings through the active preference listener', () async {
      final service = await KeyboardShortcutsService.getInstance();
      addTearDown(service.dispose);
      await service.setHotkey('play_pause', const HotKey(key: PhysicalKeyboardKey.f12));

      await SettingsService.instance.resetAllSettings();

      expect(service.getHotkey('play_pause')?.key, PhysicalKeyboardKey.space);
      expect(SettingsService.instance.prefs.containsKey(SettingsService.keyboardHotkeys.key), isFalse);
    });
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

  testWidgets('mute shortcut matches the button restoration behavior', (tester) async {
    final service = await KeyboardShortcutsService.getInstance();
    addTearDown(service.dispose);
    final settings = SettingsService.instance;
    await settings.write(SettingsService.volume, 37.0);
    final player = _FakePlayer(volume: 37);
    const muteKey = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.keyM,
      logicalKey: LogicalKeyboardKey.keyM,
      timeStamp: Duration.zero,
    );

    final muteResult = service.handleVideoPlayerKeyEvent(muteKey, player, null, null, null, null, null, null);
    await tester.pumpAndSettle();

    expect(muteResult, KeyEventResult.handled);
    expect(player.volume, 0);
    expect(settings.read(SettingsService.volume), 37);

    final unmuteResult = service.handleVideoPlayerKeyEvent(muteKey, player, null, null, null, null, null, null);
    await tester.pumpAndSettle();

    expect(unmuteResult, KeyEventResult.handled);
    expect(player.volume, 37);
    expect(settings.read(SettingsService.volume), 37);
    expect(player.volumeChanges, [0, 37]);
  });

  test('video zoom scale maps to mpv logarithmic property', () {
    expect(VideoFilterManager.videoZoomPropertyForScale(1.0), closeTo(0.0, 0.0001));
    expect(VideoFilterManager.videoZoomPropertyForScale(2.0), closeTo(1.0, 0.0001));
    expect(VideoFilterManager.videoZoomPropertyForScale(0.5), closeTo(-1.0, 0.0001));
  });
}

class _FakePlayer implements Player {
  _FakePlayer({this.volume = 100});

  final commands = <List<String>>[];
  final volumeChanges = <double>[];
  double volume;

  @override
  Future<void> command(List<String> args) async {
    commands.add(args);
  }

  @override
  PlayerState get state => PlayerState(volume: volume);

  @override
  Future<void> setVolume(double volume) async {
    this.volume = volume;
    volumeChanges.add(volume);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
