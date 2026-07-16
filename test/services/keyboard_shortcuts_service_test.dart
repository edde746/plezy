import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/models/hotkey_model.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/services/keyboard_shortcuts_service.dart';
import 'package:plezy/services/base_shared_preferences_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/video_filter_manager.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

import '../test_helpers/prefs.dart';
import '../test_helpers/watch_together_fakes.dart';

void main() {
  setUp(() {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
  });

  test('concurrent callers wait for settings binding', () async {
    final preferences = _BlockingReadPreferences(const {});
    SharedPreferencesAsyncPlatform.instance = preferences;
    BaseSharedPreferencesService.resetForTesting();
    SettingsService.resetForTesting();
    addTearDown(preferences.release);

    final first = KeyboardShortcutsService.getInstance();
    await preferences.entered;
    var secondCompleted = false;
    final second = KeyboardShortcutsService.getInstance();
    unawaited(second.then((_) => secondCompleted = true));
    await Future<void>.delayed(Duration.zero);

    expect(secondCompleted, isFalse);
    preferences.release();

    final instances = await Future.wait([first, second]);
    expect(identical(instances.first, instances.last), isTrue);
    addTearDown(instances.first.dispose);
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
      expect(service.getHotkey('frame_previous')?.key, PhysicalKeyboardKey.comma);
      expect(service.getHotkey('frame_next')?.key, PhysicalKeyboardKey.period);
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

    test('explicit unassignment survives restart and reset restores dispatch', () async {
      final service = await KeyboardShortcutsService.getInstance();
      await service.setHotkey('play_pause', null);
      await service.setHotkey('volume_up', const HotKey(key: PhysicalKeyboardKey.keyQ));

      final stored =
          json.decode(SettingsService.instance.prefs.getString(SettingsService.keyboardHotkeys.key)!)
              as Map<String, dynamic>;
      expect(stored['play_pause'], {'disabled': true});
      expect(service.getHotkey('play_pause'), isNull);
      expect(service.getActionForHotkey(const HotKey(key: PhysicalKeyboardKey.space)), isNull);

      service.dispose();
      SettingsService.resetForTesting();
      BaseSharedPreferencesService.resetForTesting();

      final reloaded = await KeyboardShortcutsService.getInstance();
      addTearDown(reloaded.dispose);
      expect(reloaded.getHotkey('play_pause'), isNull);
      expect(reloaded.getHotkey('volume_up')?.key, PhysicalKeyboardKey.keyQ);
      expect(reloaded.getHotkey('volume_down')?.key, PhysicalKeyboardKey.arrowDown);

      var playPauseCalls = 0;
      final player = _FakePlayer();
      KeyEventResult dispatch() {
        return reloaded.handleVideoPlayerKeyEvent(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.space,
            logicalKey: LogicalKeyboardKey.space,
            timeStamp: Duration.zero,
          ),
          player,
          null,
          null,
          null,
          null,
          null,
          null,
          canControlPlayback: true,
          canNavigateMediaItems: true,
          onPlayPause: () => playPauseCalls++,
        );
      }

      expect(dispatch(), KeyEventResult.ignored);
      expect(playPauseCalls, 0);
      await reloaded.resetToDefaults();
      expect(dispatch(), KeyEventResult.handled);
      expect(playPauseCalls, 1);

      final resetStored =
          json.decode(SettingsService.instance.prefs.getString(SettingsService.keyboardHotkeys.key)!)
              as Map<String, dynamic>;
      expect(resetStored['play_pause'], {'key': '0007002c', 'modifiers': <dynamic>[]});
    });

    test('serialized writes preserve rapid edits and recover after a failure', () async {
      final preferences = _HotkeyPreferences(const {});
      SharedPreferencesAsyncPlatform.instance = preferences;
      SettingsService.resetForTesting();
      BaseSharedPreferencesService.resetForTesting();
      final service = await KeyboardShortcutsService.getInstance();
      addTearDown(service.dispose);

      preferences.blockNextHotkeyWrite();
      final first = service.setHotkey('play_pause', const HotKey(key: PhysicalKeyboardKey.keyQ));
      await preferences.blocked;
      final second = service.setHotkey('volume_up', const HotKey(key: PhysicalKeyboardKey.keyW));
      await Future<void>.delayed(Duration.zero);

      expect(preferences.hotkeyWriteCount, 1);
      expect(service.getHotkey('play_pause')?.key, PhysicalKeyboardKey.space);
      preferences.release();
      await Future.wait([first, second]);

      expect(preferences.hotkeyWriteCount, 2);
      expect(service.getHotkey('play_pause')?.key, PhysicalKeyboardKey.keyQ);
      expect(service.getHotkey('volume_up')?.key, PhysicalKeyboardKey.keyW);

      preferences.failNextHotkeyWrite = true;
      await expectLater(
        service.setHotkey('play_pause', const HotKey(key: PhysicalKeyboardKey.keyE)),
        throwsA(isA<PlatformException>()),
      );
      expect(service.getHotkey('play_pause')?.key, PhysicalKeyboardKey.keyQ);

      await service.setHotkey('volume_down', const HotKey(key: PhysicalKeyboardKey.keyR));
      expect(service.getHotkey('play_pause')?.key, PhysicalKeyboardKey.keyQ);
      expect(service.getHotkey('volume_down')?.key, PhysicalKeyboardKey.keyR);
    });
  });

  testWidgets('speed increase reaches the supported 8x boundary', (tester) async {
    final service = await KeyboardShortcutsService.getInstance();
    addTearDown(service.dispose);
    await service.setHotkey('speed_increase', const HotKey(key: PhysicalKeyboardKey.f12));
    final player = _FakePlayer(rate: 7.75);
    final persistedSpeeds = <double>[];

    final result = service.handleVideoPlayerKeyEvent(
      const KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.f12,
        logicalKey: LogicalKeyboardKey.f12,
        timeStamp: Duration.zero,
      ),
      player,
      null,
      null,
      null,
      null,
      null,
      null,
      canControlPlayback: true,
      canNavigateMediaItems: true,
      onSpeedPersist: persistedSpeeds.add,
    );
    await tester.pump();

    expect(result, KeyEventResult.handled);
    expect(player.rateChanges, [8.0]);
    // Persistence is the surface's responsibility (scope-aware); the service
    // reports the clamped rate it applied.
    expect(persistedSpeeds, [8.0]);
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
      canControlPlayback: true,
      canNavigateMediaItems: true,
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
      canControlPlayback: true,
      canNavigateMediaItems: true,
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

  testWidgets('frame navigation handles direction, queued repeats, and playback guards', (tester) async {
    final service = await KeyboardShortcutsService.getInstance();
    addTearDown(service.dispose);
    final player = _FramePlayer();

    _handleFrameShortcut(service, player, PhysicalKeyboardKey.comma);
    _handleFrameShortcut(service, player, PhysicalKeyboardKey.period);
    _handleFrameShortcut(service, player, PhysicalKeyboardKey.period, repeat: true);
    expect(player.commands, [
      ['frame-step', '-1', 'seek'],
    ]);

    player.emitPlaybackRestart();
    await tester.pump();
    expect(player.commands, [
      ['frame-step', '-1', 'seek'],
      ['frame-step', '2', 'seek'],
    ]);
    player.emitPlaybackRestart();
    await tester.pump();

    for (final blockedPlayer in [_FramePlayer(playing: true), _FramePlayer(seekable: false)]) {
      _handleFrameShortcut(service, blockedPlayer, PhysicalKeyboardKey.comma);
      expect(blockedPlayer.commands, isEmpty);
    }
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
      canControlPlayback: true,
      canNavigateMediaItems: true,
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
      canControlPlayback: true,
      canNavigateMediaItems: true,
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
      canControlPlayback: true,
      canNavigateMediaItems: true,
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
      canControlPlayback: true,
      canNavigateMediaItems: true,
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
      canControlPlayback: true,
      canNavigateMediaItems: true,
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
      canControlPlayback: true,
      canNavigateMediaItems: true,
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
      canControlPlayback: true,
      canNavigateMediaItems: true,
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
      canControlPlayback: true,
      canNavigateMediaItems: true,
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
      canControlPlayback: true,
      canNavigateMediaItems: true,
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
      canControlPlayback: true,
      canNavigateMediaItems: true,
    );

    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);

    expect(commandMResult, KeyEventResult.ignored);
    expect(commandQResult, KeyEventResult.ignored);
    expect(commandCommaResult, KeyEventResult.ignored);
  });

  testWidgets('volume shortcuts delegate without mutating player or settings', (tester) async {
    final service = await KeyboardShortcutsService.getInstance();
    addTearDown(service.dispose);
    final settings = SettingsService.instance;
    await settings.write(SettingsService.volume, 37.0);
    final player = _FakePlayer(volume: 37);
    var upCalls = 0;
    var downCalls = 0;
    var muteCalls = 0;
    const bindings = [
      (action: 'volume_up', physical: PhysicalKeyboardKey.f10, logical: LogicalKeyboardKey.f10),
      (action: 'volume_down', physical: PhysicalKeyboardKey.f11, logical: LogicalKeyboardKey.f11),
      (action: 'mute_toggle', physical: PhysicalKeyboardKey.f12, logical: LogicalKeyboardKey.f12),
    ];

    for (final binding in bindings) {
      await service.setHotkey(binding.action, HotKey(key: binding.physical));
      final result = service.handleVideoPlayerKeyEvent(
        KeyDownEvent(physicalKey: binding.physical, logicalKey: binding.logical, timeStamp: Duration.zero),
        player,
        null,
        null,
        null,
        null,
        null,
        null,
        canControlPlayback: true,
        canNavigateMediaItems: true,
        onVolumeUp: () => upCalls++,
        onVolumeDown: () => downCalls++,
        onToggleMute: () => muteCalls++,
      );
      expect(result, KeyEventResult.handled);
    }

    expect(upCalls, 1);
    expect(downCalls, 1);
    expect(muteCalls, 1);
    expect(player.volume, 37);
    expect(player.volumeChanges, isEmpty);
    expect(settings.read(SettingsService.volume), 37);

    await service.setHotkey('volume_up', const HotKey(key: PhysicalKeyboardKey.f12));
    final repeatResult = service.handleVideoPlayerKeyEvent(
      const KeyRepeatEvent(
        physicalKey: PhysicalKeyboardKey.f12,
        logicalKey: LogicalKeyboardKey.f12,
        timeStamp: Duration(milliseconds: 1),
      ),
      player,
      null,
      null,
      null,
      null,
      null,
      null,
      canControlPlayback: true,
      canNavigateMediaItems: true,
      onVolumeUp: () => upCalls++,
    );
    expect(repeatResult, KeyEventResult.handled);
    expect(upCalls, 1);
  });

  test('denied playback shortcuts are consumed before any mutation', () async {
    final service = await KeyboardShortcutsService.getInstance();
    addTearDown(service.dispose);
    final player = _FakePlayer();
    final settings = SettingsService.instance;
    final initialRate = settings.read(SettingsService.defaultPlaybackSpeed);
    var callbacks = 0;
    var seekCalls = 0;
    const event = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.f12,
      logicalKey: LogicalKeyboardKey.f12,
      timeStamp: Duration.zero,
    );
    const controlledActions = <String>[
      'play_pause',
      'seek_forward',
      'seek_backward_large',
      'audio_track_next',
      'subtitle_track_next',
      'chapter_next',
      'chapter_previous',
      'speed_increase',
      'speed_decrease',
      'speed_reset',
      'sub_seek_next',
      'sub_seek_prev',
      'skip_marker',
    ];

    for (final action in controlledActions) {
      await service.setHotkey(action, const HotKey(key: PhysicalKeyboardKey.f12));
      final result = service.handleVideoPlayerKeyEvent(
        event,
        player,
        null,
        null,
        () => callbacks++,
        () => callbacks++,
        () => callbacks++,
        () => callbacks++,
        canControlPlayback: false,
        canNavigateMediaItems: true,
        onPlayPause: () => callbacks++,
        onSkipMarker: () => callbacks++,
        onSeekRequested: (_) async => seekCalls++,
      );
      expect(result, KeyEventResult.handled, reason: action);
    }

    expect(callbacks, 0);
    expect(seekCalls, 0);
    expect(player.commands, isEmpty);
    expect(settings.read(SettingsService.defaultPlaybackSpeed), initialRate);
  });

  test('media-item authority is separate and local presentation remains available', () async {
    final service = await KeyboardShortcutsService.getInstance();
    addTearDown(service.dispose);
    final player = _FakePlayer();
    var nextCalls = 0;
    var localCalls = 0;
    const event = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.f12,
      logicalKey: LogicalKeyboardKey.f12,
      timeStamp: Duration.zero,
    );

    for (final action in const ['episode_next', 'episode_previous']) {
      await service.setHotkey(action, const HotKey(key: PhysicalKeyboardKey.f12));
      expect(
        service.handleVideoPlayerKeyEvent(
          event,
          player,
          null,
          null,
          null,
          null,
          null,
          null,
          canControlPlayback: true,
          canNavigateMediaItems: false,
          onNextEpisode: () => nextCalls++,
          onPreviousEpisode: () => nextCalls++,
        ),
        KeyEventResult.handled,
      );
    }
    expect(nextCalls, 0);

    for (final action in const [
      'fullscreen_toggle',
      'subtitle_toggle',
      'shader_toggle',
      'screenshot',
      'zoom_in',
      'zoom_out',
      'zoom_reset',
    ]) {
      await service.setHotkey(action, const HotKey(key: PhysicalKeyboardKey.f12));
      expect(
        service.handleVideoPlayerKeyEvent(
          event,
          player,
          () => localCalls++,
          () => localCalls++,
          null,
          null,
          null,
          null,
          canControlPlayback: false,
          canNavigateMediaItems: false,
          onToggleShader: () => localCalls++,
          onScreenshot: () => localCalls++,
          onZoomIn: () => localCalls++,
          onZoomOut: () => localCalls++,
          onZoomReset: () => localCalls++,
        ),
        KeyEventResult.handled,
      );
      await Future<void>.delayed(Duration.zero);
    }
    expect(localCalls, 7);
  });

  test('video zoom scale maps to mpv logarithmic property', () {
    expect(VideoFilterManager.videoZoomPropertyForScale(1.0), closeTo(0.0, 0.0001));
    expect(VideoFilterManager.videoZoomPropertyForScale(2.0), closeTo(1.0, 0.0001));
    expect(VideoFilterManager.videoZoomPropertyForScale(0.5), closeTo(-1.0, 0.0001));
  });
}

KeyEventResult _handleFrameShortcut(
  KeyboardShortcutsService service,
  Player player,
  PhysicalKeyboardKey key, {
  bool repeat = false,
}) {
  final logicalKey = key == PhysicalKeyboardKey.comma ? LogicalKeyboardKey.comma : LogicalKeyboardKey.period;
  final event = repeat
      ? KeyRepeatEvent(physicalKey: key, logicalKey: logicalKey, timeStamp: Duration.zero)
      : KeyDownEvent(physicalKey: key, logicalKey: logicalKey, timeStamp: Duration.zero);
  return service.handleVideoPlayerKeyEvent(
    event,
    player,
    null,
    null,
    null,
    null,
    null,
    null,
    canControlPlayback: true,
    canNavigateMediaItems: true,
  );
}

class _FramePlayer extends FakeSyncPlayer {
  _FramePlayer({super.playing, super.seekable});

  final commands = <List<String>>[];

  @override
  Future<void> command(List<String> args) async => commands.add(args);
}

class _FakePlayer implements Player {
  _FakePlayer({this.volume = 100, this.rate = 1});

  final commands = <List<String>>[];
  final volumeChanges = <double>[];
  final rateChanges = <double>[];
  double volume;
  double rate;

  @override
  Future<void> command(List<String> args) async {
    commands.add(args);
  }

  @override
  PlayerState get state => PlayerState(volume: volume, rate: rate);

  @override
  Future<void> setVolume(double volume) async {
    this.volume = volume;
    volumeChanges.add(volume);
  }

  @override
  Future<void> setRate(double rate) async {
    this.rate = rate;
    rateChanges.add(rate);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _BlockingReadPreferences extends InMemorySharedPreferencesAsync {
  _BlockingReadPreferences(super.data) : super.withData();

  final _entered = Completer<void>();
  final _release = Completer<void>();

  Future<void> get entered => _entered.future;

  void release() {
    if (!_release.isCompleted) _release.complete();
  }

  @override
  Future<Map<String, Object>> getPreferences(
    GetPreferencesParameters parameters,
    SharedPreferencesOptions options,
  ) async {
    if (!_entered.isCompleted) _entered.complete();
    await _release.future;
    return super.getPreferences(parameters, options);
  }
}

final class _HotkeyPreferences extends InMemorySharedPreferencesAsync {
  _HotkeyPreferences(super.data) : super.withData();

  Completer<void>? _entered;
  Completer<void>? _release;
  int hotkeyWriteCount = 0;
  bool failNextHotkeyWrite = false;

  Future<void> get blocked => _entered!.future;

  void blockNextHotkeyWrite() {
    _entered = Completer<void>();
    _release = Completer<void>();
  }

  void release() {
    final release = _release;
    if (release != null && !release.isCompleted) release.complete();
  }

  @override
  Future<bool> setString(String key, String value, SharedPreferencesOptions options) async {
    if (key == SettingsService.keyboardHotkeys.key) {
      hotkeyWriteCount++;
      if (failNextHotkeyWrite) {
        failNextHotkeyWrite = false;
        throw PlatformException(code: 'write_failed');
      }
      final entered = _entered;
      if (entered != null && !entered.isCompleted) {
        entered.complete();
        await _release!.future;
      }
    }
    return super.setString(key, value, options);
  }
}
