import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/models.dart';
import 'package:plezy/mpv/player/player_native.dart';
import 'package:plezy/mpv/video.dart';
import 'package:plezy/services/settings_service.dart';

import '../test_helpers/mock_player_channels.dart';
import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  tearDown(SettingsService.resetForTesting);

  testWidgets('Video reports updated physical pane bounds when workspace layout moves', (tester) async {
    final rectCalls = <Map<Object?, Object?>>[];
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async {
        if (call.method == 'setVideoRect') {
          rectCalls.add(call.arguments as Map<Object?, Object?>);
        }
        if (call.method == 'initialize') return true;
        return null;
      },
      testBody: () async {
        final player = PlayerNative();
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(devicePixelRatio: 2),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(width: 300, height: 200, child: Video(player: player)),
              ),
            ),
          ),
        );
        await tester.pump();
        await player.open(Media('https://example.test/video.mp4'), play: false);

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(devicePixelRatio: 2),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, top: 10),
                  child: SizedBox(width: 300, height: 200, child: Video(player: player)),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(rectCalls, hasLength(2));
        expect(rectCalls.first, {'left': 0, 'top': 0, 'right': 600, 'bottom': 400, 'devicePixelRatio': 2.0});
        expect(rectCalls.last, {'left': 40, 'top': 20, 'right': 640, 'bottom': 420, 'devicePixelRatio': 2.0});
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.runAsync(() => player.dispose());
      },
    );
  });
}
