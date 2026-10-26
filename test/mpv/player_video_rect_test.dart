import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/models.dart';
import 'package:plezy/mpv/player/platform/player_android.dart';
import 'package:plezy/mpv/player/player_native.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/mock_player_channels.dart';
import '../test_helpers/prefs.dart';

Map<Object?, Object?> _rectArguments(MethodCall call) => call.arguments as Map<Object?, Object?>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  tearDown(SettingsService.resetForTesting);

  test('MPV applies the latest physical workspace bounds after native initialization', () async {
    MethodCall? rectCall;
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async {
        if (call.method == 'setVideoRect') rectCall = call;
        if (call.method == 'initialize') return true;
        return null;
      },
      testBody: () async {
        final player = PlayerNative();
        try {
          await player.setVideoRect(left: 21, top: 34, right: 721, bottom: 428, devicePixelRatio: 2.0);
          await player.open(Media('https://example.test/video.mp4'), play: false);
        } finally {
          await player.dispose();
        }
      },
    );

    expect(rectCall?.method, 'setVideoRect');
    expect(_rectArguments(rectCall!), {
      'left': 21,
      'top': 34,
      'right': 721,
      'bottom': 428,
      'devicePixelRatio': 2.0,
    });
  });

  test('ExoPlayer applies the latest physical workspace bounds after native initialization', () async {
    MethodCall? rectCall;
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/exo_player',
      eventChannelName: 'com.plezy/exo_player/events',
      methodHandler: (call) async {
        if (call.method == 'setVideoRect') rectCall = call;
        if (call.method == 'initialize') return true;
        return null;
      },
      testBody: () async {
        final player = PlayerAndroid();
        try {
          await player.setVideoRect(left: 0, top: 48, right: 1184, bottom: 712, devicePixelRatio: 1.5);
          await player.open(Media('https://example.test/video.mp4'), play: false);
        } finally {
          await player.dispose();
        }
      },
    );

    expect(rectCall?.method, 'setVideoRect');
    expect(_rectArguments(rectCall!), {
      'left': 0,
      'top': 48,
      'right': 1184,
      'bottom': 712,
      'devicePixelRatio': 1.5,
    });
  });
}
