import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/utils/immersive_mode_guard.dart';

/// The engine posts `SystemChrome.systemUIChange` when Android re-shows the
/// system bars (a fold/unfold keeps the activity resumed, so nothing else
/// re-applies the requested mode). The guard answers it only while a player
/// owns immersive mode.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> platformCalls;

  setUp(() {
    platformCalls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        platformCalls.add(call);
        return null;
      },
    );
  });

  tearDown(() {
    ImmersiveModeGuard.resetForTesting();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });

  Future<void> systemShowsOverlays() async {
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.platform.name,
      SystemChannels.platform.codec.encodeMethodCall(const MethodCall('SystemChrome.systemUIChange', [true])),
      (_) {},
    );
  }

  Iterable<MethodCall> immersiveRequests() => platformCalls.where(
    (call) => call.method == 'SystemChrome.setEnabledSystemUIMode' && call.arguments == 'SystemUiMode.immersiveSticky',
  );

  test('re-requests immersive mode while owned, not after release', () async {
    final owner = Object();
    ImmersiveModeGuard.acquire(owner);
    await systemShowsOverlays();
    expect(immersiveRequests(), hasLength(1));

    ImmersiveModeGuard.release(owner);
    await systemShowsOverlays();
    expect(immersiveRequests(), hasLength(1));
  });

  test('bars staying hidden is not a re-show', () async {
    ImmersiveModeGuard.acquire(Object());
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.platform.name,
      SystemChannels.platform.codec.encodeMethodCall(const MethodCall('SystemChrome.systemUIChange', [false])),
      (_) {},
    );
    expect(immersiveRequests(), isEmpty);
  });

  test('a predecessor releasing after its successor acquired keeps the successor owning', () async {
    final predecessor = Object();
    final successor = Object();
    ImmersiveModeGuard.acquire(predecessor);
    ImmersiveModeGuard.acquire(successor);
    ImmersiveModeGuard.release(predecessor);
    await systemShowsOverlays();
    expect(immersiveRequests(), hasLength(1));

    ImmersiveModeGuard.release(successor);
    await systemShowsOverlays();
    expect(immersiveRequests(), hasLength(1));
  });

  test('registers the native listener once across owners', () async {
    ImmersiveModeGuard.acquire(Object());
    ImmersiveModeGuard.acquire(Object());
    await Future<void>.delayed(Duration.zero);
    expect(platformCalls.where((call) => call.method == 'SystemChrome.setSystemUIChangeListener'), hasLength(1));
  });
}
