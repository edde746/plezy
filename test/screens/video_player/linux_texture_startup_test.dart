import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/mpv/player/player_native.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/screens/video_player_screen.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/media_items.dart';
import '../../test_helpers/mock_player_channels.dart';
import '../../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    PlayerNative.debugUseLinuxVideoBootstrap = true;
  });

  tearDown(() => PlayerNative.debugUseLinuxVideoBootstrap = null);

  testWidgets('Linux mounts its provisional texture while initialization is pending', (tester) async {
    final ready = Completer<void>();
    final calls = <MethodCall>[];
    final eventCalls = <MethodCall>[];

    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) {
        calls.add(call);
        return switch (call.method) {
          'initialize' => Future<Object?>.value(73),
          'waitForVideoReady' => ready.future,
          _ => Future<Object?>.value(null),
        };
      },
      eventHandler: (call) async {
        eventCalls.add(call);
        return null;
      },
      testBody: () async {
        final key = GlobalKey<VideoPlayerScreenState>();
        await tester.pumpWidget(_screen(key));
        await _pumpUntil(tester, () => calls.any((call) => call.method == 'waitForVideoReady'));

        expect(tester.widget<Texture>(find.byType(Texture)).textureId, 73);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(key.currentState?.player, isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpUntil(
          tester,
          () => calls.any((call) => call.method == 'dispose') && eventCalls.any((call) => call.method == 'cancel'),
        );
        ready.complete();
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pump();
      },
    );
  });
}

Widget _screen(GlobalKey<VideoPlayerScreenState> key) {
  return ChangeNotifierProvider(
    create: (_) => PlaybackStateProvider(),
    child: MaterialApp(
      home: VideoPlayerScreen(
        key: key,
        metadata: testMediaItem(title: 'Linux startup test video'),
        isOffline: true,
      ),
    ),
  );
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var i = 0; i < 200 && !condition(); i++) {
    await tester.pump(const Duration(milliseconds: 10));
    if (!condition()) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    }
  }
  expect(condition(), isTrue);
}
