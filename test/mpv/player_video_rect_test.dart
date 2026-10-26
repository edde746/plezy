import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/player/platform/player_android.dart';
import 'package:plezy/mpv/player/player_native.dart';

import '../test_helpers/mock_player_channels.dart';

Map<Object?, Object?> _rectArguments(MethodCall call) => call.arguments as Map<Object?, Object?>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('MPV forwards physical workspace bounds and scale to its native surface', () async {
    MethodCall? rectCall;
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async {
        if (call.method == 'setVideoRect') rectCall = call;
        return null;
      },
      testBody: () async {
        final player = PlayerNative();
        try {
          await player.setVideoRect(left: 21, top: 34, right: 721, bottom: 428, devicePixelRatio: 2.0);
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

  test('ExoPlayer forwards physical workspace bounds and scale to its native surface', () async {
    MethodCall? rectCall;
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/exo_player',
      eventChannelName: 'com.plezy/exo_player/events',
      methodHandler: (call) async {
        if (call.method == 'setVideoRect') rectCall = call;
        return null;
      },
      testBody: () async {
        final player = PlayerAndroid();
        try {
          await player.setVideoRect(left: 0, top: 48, right: 1184, bottom: 712, devicePixelRatio: 1.5);
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
