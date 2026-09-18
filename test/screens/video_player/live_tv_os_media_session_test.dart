import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/models/livetv_channel.dart';
import 'package:plezy/providers/multi_server_provider.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/screens/video_player/live_tv_session_args.dart';
import 'package:plezy/screens/video_player_screen.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/media_items.dart';
import '../../test_helpers/mock_player_channels.dart';
import '../../test_helpers/multi_server_fixtures.dart';
import '../../test_helpers/prefs.dart';
import '../../test_helpers/watch_together_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const methodChannel = MethodChannel('com.edde746.os_media_controls/methods');
  const eventChannel = MethodChannel('com.edde746.os_media_controls/events');
  final calls = <MethodCall>[];
  TargetPlatform? previousPlatformOverride;

  setUp(() async {
    previousPlatformOverride = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    calls.clear();
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(methodChannel, (call) async {
      calls.add(call);
      return null;
    });
    messenger.setMockMethodCallHandler(eventChannel, (call) async => null);
  });

  tearDown(() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(methodChannel, null);
    messenger.setMockMethodCallHandler(eventChannel, null);
    debugDefaultTargetPlatformOverride = previousPlatformOverride;
  });

  testWidgets('a live channel registers an OS media session named after the channel', (tester) async {
    final multi = testMultiServer();
    final player = FakeSyncPlayer(playing: true, seekable: false);

    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      testBody: () async {
        final screenKey = GlobalKey<VideoPlayerScreenState>();
        await tester.pumpWidget(_liveScreen(screenKey, multi.provider));
        screenKey.currentState!.player = player;

        await screenKey.currentState!.debugInitializeServicesForTesting();
        await tester.pump(const Duration(seconds: 3));

        final titles = calls
            .where((call) => call.method == 'setMetadata')
            .map((call) => (call.arguments as Map)['title']);
        expect(titles, ['Rai 1']);

        final enabled = _controls(calls, 'enableControls');
        final disabled = _controls(calls, 'disableControls');
        expect(enabled, containsAll(['play', 'pause', 'stop', 'skipForward', 'skipBackward']));
        expect(disabled, containsAll(['seek', 'changeSpeed', 'next', 'previous']));
        expect(enabled, isNot(contains('seek')), reason: 'a live edge has no absolute position to seek to');

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  });
}

Set<String> _controls(List<MethodCall> calls, String method) => {
  for (final call in calls.where((call) => call.method == method)) ...(call.arguments as List).cast<String>(),
};

Widget _liveScreen(GlobalKey<VideoPlayerScreenState> key, MultiServerProvider multiServer) {
  final channel = LiveTvChannel(key: 'channel-rai-1', serverId: 'srv-1', title: 'Rai 1');
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => PlaybackStateProvider()),
      ChangeNotifierProvider<MultiServerProvider>.value(value: multiServer),
    ],
    child: MaterialApp(
      home: VideoPlayerScreen(
        key: key,
        metadata: testMediaItem(id: channel.key, serverId: 'srv-1', kind: MediaKind.clip, title: channel.title),
        live: LiveTvSessionArgs(channel: channel, channels: [channel], currentChannelIndex: 0),
      ),
    ),
  );
}
