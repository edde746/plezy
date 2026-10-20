import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:os_media_controls/os_media_controls.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/screens/video_player_screen.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/media_items.dart';
import '../../test_helpers/mock_player_channels.dart';
import '../../test_helpers/prefs.dart';

/// Regression coverage for #2662, #2647 and #2657: an Android mpv session
/// condemned by a native call that never answered (or a failed video output)
/// refuses every property write for the rest of its life, while the remote
/// keeps delivering play/pause through the OS media session. Those commands
/// run unawaited, so the screen must own the refusal instead of letting it
/// escape as an uncaught error.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  testWidgets('media session play and pause refused by the backend stay inside the screen', (tester) async {
    final player = _RefusingPlayer();

    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      testBody: () async {
        final screenKey = GlobalKey<VideoPlayerScreenState>();
        await tester.pumpWidget(_screen(screenKey));
        screenKey.currentState!.player = player;

        final router = screenKey.currentState!.debugMediaControlRouterForTesting();
        router.route(const PlayEvent());
        router.route(const PauseEvent());
        // Paused, so the toggle resolves to a play.
        router.route(const TogglePlayPauseEvent());
        await tester.pump();

        expect(player.writes, ['play', 'pause', 'play'], reason: 'every command still reaches the player');
        expect(tester.takeException(), isNull);

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
        metadata: testMediaItem(title: 'Media session refusal'),
        isOffline: true,
      ),
    ),
  );
}

/// A player whose native session refuses every play-state write, the way the
/// Android mpv bridge answers once its session is condemned.
class _RefusingPlayer implements Player {
  final PlayerState _state = PlayerState(duration: const Duration(minutes: 45), seekable: true);
  final List<String> writes = [];

  static PlatformException _refusal() => PlatformException(
    code: 'SET_PROPERTY_FAILED',
    message: 'MPV property write was rejected',
    details: {'property': 'pause', 'sessionFailed': true, 'failure': 'unresponsive', 'operation': 'property write'},
  );

  @override
  PlayerState get state => _state;

  @override
  Future<void> play() async {
    writes.add('play');
    throw _refusal();
  }

  @override
  Future<void> pause() async {
    writes.add('pause');
    throw _refusal();
  }

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> dispose({bool preserveDisplayMode = false}) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
