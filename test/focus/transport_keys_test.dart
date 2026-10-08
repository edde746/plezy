import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/transport_keys.dart';

void main() {
  group('classifyTransportKey', () {
    test('maps the logical media keys to their intent', () {
      expect(classifyTransportKey(LogicalKeyboardKey.mediaPlay), TransportCommand.play);
      expect(classifyTransportKey(LogicalKeyboardKey.mediaPause), TransportCommand.pause);
      expect(classifyTransportKey(LogicalKeyboardKey.mediaPlayPause), TransportCommand.toggle);
      expect(classifyTransportKey(LogicalKeyboardKey.space), isNull);
    });

    // On Linux, XKB maps the Play/Pause key (evdev KEY_PLAYPAUSE) to the
    // XF86AudioPlay keysym, so the logical key is mediaPlay; only the physical
    // key still says it is the combined button.
    test('treats the physical Play/Pause key as a toggle whatever its logical key', () {
      expect(
        classifyTransportKey(LogicalKeyboardKey.mediaPlay, PhysicalKeyboardKey.mediaPlayPause),
        TransportCommand.toggle,
      );
    });

    test('keeps dedicated play and pause keys directed', () {
      expect(classifyTransportKey(LogicalKeyboardKey.mediaPlay, PhysicalKeyboardKey.mediaPlay), TransportCommand.play);
      expect(
        classifyTransportKey(LogicalKeyboardKey.mediaPause, PhysicalKeyboardKey.mediaPause),
        TransportCommand.pause,
      );
    });
  });
}
