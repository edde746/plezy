import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:os_media_controls/os_media_controls.dart';
import 'package:plezy/media/media_kind.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/screens/video_player_screen.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/media_items.dart';
import '../../test_helpers/mock_player_channels.dart';
import '../../test_helpers/prefs.dart';
import '../../test_helpers/watch_together_fakes.dart';

/// "Ask for a profile on open" raises the picker on resume over an open
/// player (#2195). Until the picker gets a choice, nothing may play the
/// previous profile's session: not a media key or headset through the OS
/// media session, and not a native resume that skips the Dart wrappers.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  testWidgets('the picker keeps the covered player paused until a profile is chosen', (tester) async {
    final player = _HoldPlayer(playing: true);
    addTearDown(player.dispose);

    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      testBody: () async {
        final key = GlobalKey<VideoPlayerScreenState>();
        await tester.pumpWidget(_screen(key));
        final state = key.currentState!;
        state.player = player;
        await state.debugWirePlayerStreamsForTesting();
        final router = state.debugMediaControlRouterForTesting();

        final selection = Completer<void>();
        VideoPlayerScreenState.holdActivePlaybackUntil(selection.future);
        await tester.pump();
        expect(player.state.playing, isFalse, reason: 'what started before the picker landed is paused');

        final commandsUnderPicker = player.commandLog.length;
        router.route(const PlayEvent());
        router.route(const TogglePlayPauseEvent());
        await tester.pump();
        expect(player.state.playing, isFalse, reason: 'a media key or headset cannot start it');
        expect(player.commandLog.skip(commandsUnderPicker), isNot(contains('play')), reason: 'not even briefly');

        // Audio-focus regain resumes the native player without the Dart wrappers.
        player.emitPlaying(true);
        await tester.pump();
        expect(player.state.playing, isFalse, reason: 'a native resume is paused again');

        selection.complete();
        await tester.pump();
        expect(player.state.playing, isFalse, reason: 'choosing a profile does not resume by itself');

        router.route(const PlayEvent());
        await tester.pump();
        expect(player.state.playing, isTrue, reason: 'the chosen profile resumes it');

        await tester.pumpWidget(const SizedBox.shrink());
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
        metadata: testMediaItem(kind: MediaKind.episode, title: 'Left paused overnight'),
        isOffline: true,
      ),
    ),
  );
}

class _HoldPlayer extends FakeSyncPlayer {
  _HoldPlayer({super.playing}) : super(position: const Duration(minutes: 10), duration: const Duration(minutes: 40));

  @override
  Future<void> updateFrame() async {}
}
