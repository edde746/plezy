import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/player/platform/player_android.dart';
import 'package:plezy/mpv/player/player_native.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('MPV primary and workspace sessions have isolated method and event channels', () async {
    final primary = PlayerNative(listenToNativeEvents: false);
    final companion = PlayerNative(companionSession: true, listenToNativeEvents: false);
    addTearDown(primary.dispose);
    addTearDown(companion.dispose);

    expect(primary.methodChannel.name, 'com.plezy/mpv_player');
    expect(primary.eventChannel.name, 'com.plezy/mpv_player/events');
    expect(companion.methodChannel.name, 'com.plezy/mpv_player/workspace');
    expect(companion.eventChannel.name, 'com.plezy/mpv_player/workspace/events');
    expect(primary.methodChannel.name, isNot(companion.methodChannel.name));
    expect(primary.eventChannel.name, isNot(companion.eventChannel.name));
  });

  test('Android ExoPlayer primary and workspace sessions have isolated channels', () async {
    final primary = PlayerAndroid(listenToNativeEvents: false);
    final companion = PlayerAndroid(companionSession: true, listenToNativeEvents: false);
    addTearDown(primary.dispose);
    addTearDown(companion.dispose);

    expect(primary.methodChannel.name, 'com.plezy/exo_player');
    expect(primary.eventChannel.name, 'com.plezy/exo_player/events');
    expect(companion.methodChannel.name, 'com.plezy/exo_player/workspace');
    expect(companion.eventChannel.name, 'com.plezy/exo_player/workspace/events');
    expect(primary.methodChannel.name, isNot(companion.methodChannel.name));
    expect(primary.eventChannel.name, isNot(companion.eventChannel.name));

    final calls = <(String, Object?)>[];
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(companion.methodChannel, (call) async {
      calls.add((call.method, call.arguments));
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(companion.methodChannel, null));

    await companion.setAudioFocusEnabled(false);

    expect(calls, hasLength(1));
    expect(calls.single.$1, 'setAudioFocusEnabled');
    expect(calls.single.$2, {'enabled': false});
  });
}
