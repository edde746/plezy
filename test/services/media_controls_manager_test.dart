import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/services/media_controls_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.edde746.os_media_controls/methods');
  final calls = <MethodCall>[];
  TargetPlatform? previousPlatformOverride;

  setUp(() {
    previousPlatformOverride = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = previousPlatformOverride;
  });

  test('guest, anyone, and host capability snapshots advertise exact authority', () async {
    final manager = MediaControlsManager();
    addTearDown(manager.dispose);

    await manager.setControlsEnabled(
      canPlayPause: false,
      canGoNext: false,
      canGoPrevious: false,
      canSeek: false,
      canStop: true,
      canSkip: false,
      canSetSpeed: false,
    );

    _expectControlTransition(
      calls,
      enabled: const ['stop'],
      disabled: const ['play', 'pause', 'previous', 'next', 'seek', 'skipForward', 'skipBackward', 'changeSpeed'],
    );

    calls.clear();
    await manager.setControlsEnabled(
      canPlayPause: true,
      canGoNext: false,
      canGoPrevious: false,
      canSeek: true,
      canStop: true,
      canSkip: true,
      canSetSpeed: true,
    );
    _expectControlTransition(
      calls,
      enabled: const ['play', 'pause', 'seek', 'skipForward', 'skipBackward', 'changeSpeed'],
    );

    calls.clear();
    await manager.setControlsEnabled(
      canPlayPause: true,
      canGoNext: true,
      canGoPrevious: true,
      canSeek: true,
      canStop: true,
      canSkip: true,
      canSetSpeed: true,
    );
    _expectControlTransition(calls, enabled: const ['previous', 'next']);

    calls.clear();
    await manager.setControlsEnabled(
      canPlayPause: true,
      canGoNext: true,
      canGoPrevious: true,
      canSeek: true,
      canStop: true,
      canSkip: true,
      canSetSpeed: true,
    );
    expect(calls, isEmpty);
  });
}

void _expectControlTransition(
  List<MethodCall> calls, {
  List<String> enabled = const [],
  List<String> disabled = const [],
}) {
  final expectedCalls = <({String method, List<String> controls})>[
    if (enabled.isNotEmpty) (method: 'enableControls', controls: enabled),
    if (disabled.isNotEmpty) (method: 'disableControls', controls: disabled),
  ];

  expect(calls, hasLength(expectedCalls.length));
  for (var index = 0; index < expectedCalls.length; index++) {
    expect(calls[index].method, expectedCalls[index].method);
    expect(calls[index].arguments, expectedCalls[index].controls);
  }
}
