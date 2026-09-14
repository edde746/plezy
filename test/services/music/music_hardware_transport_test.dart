import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/music/music_hardware_transport.dart';

/// Foreground hardware media keys (#1948): while a music session is live,
/// transport keys pressed anywhere in the app must control music and be
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
