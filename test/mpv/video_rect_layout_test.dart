import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/player/player_native.dart';
import 'package:plezy/mpv/video.dart';

import '../test_helpers/mock_player_channels.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Video reports updated physical pane bounds when workspace layout moves', (tester) async {
    final rectCalls = <Map<Object?, Object?>>[];
    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) async {
        if (call.method == 'setVideoRect') {
          rectCalls.add(call.arguments as Map<Object?, Object?>);
        }
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
        await player.dispose();
      },
    );
  });
}
