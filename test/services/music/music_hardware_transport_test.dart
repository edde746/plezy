import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/focused_media_play_action.dart';
import 'package:plezy/services/music/music_hardware_transport.dart';
import 'package:plezy/utils/platform_detector.dart';

/// Foreground hardware media keys (#1948): while a music session is live,
/// transport keys control music unless Android TV focus owns video Play, and are
/// consumed for the whole down/repeat/up burst, so a press can neither leak
/// to Android's fallback MediaSession dispatch (#1375) nor double as input to
/// a focused item (#1510).
void main() {
  var sessionLive = true;
  final calls = <String, int>{};

  void record(String name) => calls.update(name, (count) => count + 1, ifAbsent: () => 1);

  late MusicHardwareTransportHandler handler;

  setUp(() {
    sessionLive = true;
    calls.clear();
    handler = MusicHardwareTransportHandler(
      hasActiveSession: () => sessionLive,
      onPlay: () => record('play'),
      onPause: () => record('pause'),
      onTogglePlayPause: () => record('toggle'),
      onNext: () => record('next'),
      onPrevious: () => record('previous'),
      onStop: () => record('stop'),
      onSkipForward: () => record('skipForward'),
      onSkipBackward: () => record('skipBackward'),
    );
  });

  tearDown(() {
    handler.unregister();
    debugDefaultTargetPlatformOverride = null;
    TvDetectionService.debugReset();
  });

  testWidgets('focused play action handles a held press once and ignores pause', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TvDetectionService.debugSetAppleTVOverride(true);
    final pending = Completer<void>();
    var launches = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Actions(
          actions: {
            FocusedMediaPlayIntent: FocusedMediaPlayAction(
              canPlay: () => true,
              onPlay: () async {
                launches++;
                await pending.future;
              },
            ),
          },
          child: Focus(
            autofocus: true,
            onKeyEvent: (_, event) => handleFocusedMediaPlayKey(event),
            child: const SizedBox(),
          ),
        ),
      ),
    );
    await tester.pump();
    handler.register();
    expect(await tester.sendKeyDownEvent(LogicalKeyboardKey.mediaPlay), isTrue);
    expect(await tester.sendKeyRepeatEvent(LogicalKeyboardKey.mediaPlay), isTrue);
    expect(await tester.sendKeyUpEvent(LogicalKeyboardKey.mediaPlay), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.mediaPlayPause);
    expect(launches, 1);
    expect(await tester.sendKeyEvent(LogicalKeyboardKey.mediaPause), isTrue);
    expect(calls, {'pause': 1});
    pending.complete();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.mediaPlayPause);
    expect(launches, 2);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('focused play action is disabled outside Android TV', (tester) async {
    var launches = 0;
    final action = FocusedMediaPlayAction(canPlay: () => true, onPlay: () async => launches++);
    for (final platform in [TargetPlatform.android, TargetPlatform.iOS, TargetPlatform.linux]) {
      debugDefaultTargetPlatformOverride = platform;
      TvDetectionService.debugSetAppleTVOverride(platform != TargetPlatform.android);
      expect(action.isEnabled(const FocusedMediaPlayIntent()), isFalse);
    }
    expect(launches, 0);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('new play press works when the previous release reached another route', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    var launches = 0;
    Widget browser() => MaterialApp(
      home: Actions(
        actions: {FocusedMediaPlayIntent: FocusedMediaPlayAction(canPlay: () => true, onPlay: () async => launches++)},
        child: Focus(
          autofocus: true,
          onKeyEvent: (_, event) => handleFocusedMediaPlayKey(event),
          child: const SizedBox(),
        ),
      ),
    );
    await tester.pumpWidget(browser());
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.mediaPlay);
    await tester.pumpWidget(const MaterialApp(home: Focus(autofocus: true, child: SizedBox())));
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.mediaPlay);
    await tester.pumpWidget(browser());
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.mediaPlay);
    expect(launches, 2);
  });

  testWidgets('acts on key-down only and consumes down, repeat, and up per key', (tester) async {
    handler.register();

    // The Android key map has no physical entry for the skip variants; the
    // handler only reads the logical key, so simulate those with a stand-in.
    final keyCases = <(LogicalKeyboardKey, PhysicalKeyboardKey?, String)>[
      (LogicalKeyboardKey.mediaPlay, null, 'play'),
      (LogicalKeyboardKey.mediaPause, null, 'pause'),
      (LogicalKeyboardKey.mediaPlayPause, null, 'toggle'),
      (LogicalKeyboardKey.mediaTrackNext, null, 'next'),
      (LogicalKeyboardKey.mediaTrackPrevious, null, 'previous'),
      (LogicalKeyboardKey.mediaStop, null, 'stop'),
      (LogicalKeyboardKey.mediaFastForward, null, 'skipForward'),
      (LogicalKeyboardKey.mediaRewind, null, 'skipBackward'),
      (LogicalKeyboardKey.mediaSkipForward, PhysicalKeyboardKey.f13, 'skipForward'),
      (LogicalKeyboardKey.mediaSkipBackward, PhysicalKeyboardKey.f13, 'skipBackward'),
    ];

    for (final (key, physicalKey, action) in keyCases) {
      calls.clear();
      expect(await tester.sendKeyDownEvent(key, physicalKey: physicalKey), isTrue, reason: '$key down');
      expect(await tester.sendKeyRepeatEvent(key, physicalKey: physicalKey), isTrue, reason: '$key repeat');
      expect(await tester.sendKeyUpEvent(key, physicalKey: physicalKey), isTrue, reason: '$key up');
      expect(calls, {action: 1}, reason: '$key must fire $action exactly once on the initial down');
    }
  });

  testWidgets('ignores transport keys when no session is live', (tester) async {
    handler.register();
    sessionLive = false;

    expect(await tester.sendKeyDownEvent(LogicalKeyboardKey.mediaPlayPause), isFalse);
    expect(await tester.sendKeyUpEvent(LogicalKeyboardKey.mediaPlayPause), isFalse);
    expect(calls, isEmpty);
  });

  testWidgets('ignores non-transport keys', (tester) async {
    handler.register();

    for (final key in [LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.enter, LogicalKeyboardKey.space]) {
      expect(await tester.sendKeyDownEvent(key), isFalse, reason: '$key is not a transport key');
      expect(await tester.sendKeyUpEvent(key), isFalse);
    }
    expect(calls, isEmpty);
  });

  testWidgets('register is a no-op off Android', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    handler.register();
    debugDefaultTargetPlatformOverride = null;

    expect(await tester.sendKeyDownEvent(LogicalKeyboardKey.mediaPlayPause), isFalse);
    expect(await tester.sendKeyUpEvent(LogicalKeyboardKey.mediaPlayPause), isFalse);
    expect(calls, isEmpty);
  });

  testWidgets('unregister stops handling and is idempotent', (tester) async {
    handler.register();
    expect(await tester.sendKeyDownEvent(LogicalKeyboardKey.mediaPlayPause), isTrue);
    expect(await tester.sendKeyUpEvent(LogicalKeyboardKey.mediaPlayPause), isTrue);

    handler.unregister();
    handler.unregister();

    expect(await tester.sendKeyDownEvent(LogicalKeyboardKey.mediaPlayPause), isFalse);
    expect(await tester.sendKeyUpEvent(LogicalKeyboardKey.mediaPlayPause), isFalse);
    expect(calls, {'toggle': 1});
  });
}
