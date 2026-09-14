import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'package:plezy/database/app_database.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/video_volume_controller.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/watch_together/providers/watch_together_provider.dart';
import 'package:plezy/widgets/video_controls/desktop_video_controls.dart';
import 'package:plezy/widgets/video_controls/player_chrome_controller.dart';
import 'package:plezy/widgets/video_controls/video_controls.dart';
import 'package:plezy/widgets/video_controls/widgets/player_toast_indicator.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';
import '../test_helpers/theme.dart';

/// Regression coverage for #1797: returning to the desktop window while the
/// chrome is up left primary focus parked on the enclosing screen node. The
/// chrome-hide transition is the only other handoff back to the player surface,
/// so with the OSD visible nothing reclaimed it, and the screen's self-heal
/// turned the next arrow key into a jump onto the Play/Pause button — from
/// there every further arrow navigated the OSD instead of seeking.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('window refocus', () {
    late _PlayingPlayer player;
    late PlayerChromeController chrome;
    late PlayerToastController toast;
    late VideoVolumeController volume;
    late PlaybackStateProvider playbackState;
    late WatchTogetherProvider watchTogether;
    late AppDatabase database;
    late ValueNotifier<bool> hasFirstFrame;
    late FocusNode screenFocusNode;
    late List<LogicalKeyboardKey> keysReachingScreen;

    setUp(() async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      await initializeDateFormatting('en');
      resetSharedPreferencesForTest();
      SettingsService.resetForTesting();
      final settings = await SettingsService.getInstance();

      TvDetectionService.debugSetAppleTVOverride(false);
      PlatformDetector.debugSetIsDesktopOSOverride(false);

      database = AppDatabase.forTesting(NativeDatabase.memory());
      player = _PlayingPlayer();
      // The reported state: the viewer came back with the OSD still up.
      chrome = PlayerChromeController(initiallyVisible: true);
      toast = PlayerToastController();
      volume = VideoVolumeController(player: player, settings: settings, initialVolume: 100);
      playbackState = PlaybackStateProvider();
      watchTogether = WatchTogetherProvider();
      hasFirstFrame = ValueNotifier<bool>(true);
      screenFocusNode = FocusNode(debugLabel: 'VideoPlayerScreen');
      keysReachingScreen = <LogicalKeyboardKey>[];
    });

    tearDown(() async {
      TvDetectionService.debugSetAppleTVOverride(null);
      PlatformDetector.debugSetIsDesktopOSOverride(null);
      hasFirstFrame.dispose();
      screenFocusNode.dispose();
      volume.dispose();
      playbackState.dispose();
      watchTogether.dispose();
      chrome.dispose();
      toast.dispose();
      await database.close();
    });

    Widget shell(Widget child) {
      return MultiProvider(
        providers: [
          Provider<AppDatabase>.value(value: database),
          ChangeNotifierProvider<PlaybackStateProvider>.value(value: playbackState),
          ChangeNotifierProvider<WatchTogetherProvider>.value(value: watchTogether),
        ],
        child: MaterialApp(
          theme: ThemeData(platform: TargetPlatform.windows, extensions: const [testMonoTokens]),
          home: Scaffold(
            body: SizedBox(
              width: 1280,
              height: 720,
              child: Focus(
                focusNode: screenFocusNode,
                autofocus: true,
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent) keysReachingScreen.add(event.logicalKey);
                  return KeyEventResult.ignored;
                },
                child: child,
              ),
            ),
          ),
        ),
      );
    }

    /// Reproduces the post-blur layout: the screen node owns primary focus (the
    /// player screen reclaims it whenever focus leaves the subtree) while the
    /// controls are mounted with their chrome up.
    Future<void> pumpControlsUnderScreenFocus(WidgetTester tester) async {
      await tester.pumpWidget(shell(const SizedBox.expand()));
      await tester.pump();
      expect(screenFocusNode.hasPrimaryFocus, isTrue);

      await tester.pumpWidget(
        shell(
          PlexVideoControls(
            player: player,
            volumeController: volume,
            metadata: testMediaItem(id: 'window-refocus'),
            toastController: toast,
            chromeController: chrome,
            hasFirstFrame: hasFirstFrame,
            canNavigateMediaItems: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Mounting parks the remote on the player surface. A window blur then
      // drops focus to the root scope and the screen node's reclaim takes it,
      // which is the state this suite is about — stage it explicitly.
      screenFocusNode.requestFocus();
      await tester.pumpAndSettle();
      expect(
        screenFocusNode.hasPrimaryFocus,
        isTrue,
        reason: 'precondition: focus is stranded on the screen node with the OSD up',
      );
    }

    testWidgets('re-activating the window hands the remote back to the player surface', (tester) async {
      await pumpControlsUnderScreenFocus(tester);

      (tester.state(find.byType(PlexVideoControls)) as WindowListener).onWindowFocus();
      await tester.pumpAndSettle();

      expect(
        screenFocusNode.hasPrimaryFocus,
        isFalse,
        reason: 'the player surface owns the remote again, not the screen node',
      );

      // The reported symptom lands on the second press: the first is answered
      // while the very same event also steals focus into the OSD.
      for (var press = 0; press < 2; press++) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();
        await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pump();
      }

      expect(
        keysReachingScreen,
        isEmpty,
        reason: 'no arrow may reach the screen self-heal, or it jumps focus onto Play/Pause',
      );

      chrome.cancelAutoHide();
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a control the viewer focused on purpose keeps the remote', (tester) async {
      await pumpControlsUnderScreenFocus(tester);

      // Deliberate focus inside the OSD, as traversal or a TV remote leaves it.
      tester.state<DesktopVideoControlsState>(find.byType(DesktopVideoControls)).requestPlayPauseFocus();
      await tester.pumpAndSettle();
      final focusedControl = FocusManager.instance.primaryFocus;
      expect(focusedControl?.debugLabel, 'PlayPause', reason: 'a control took the remote');

      (tester.state(find.byType(PlexVideoControls)) as WindowListener).onWindowFocus();
      await tester.pumpAndSettle();

      expect(
        FocusManager.instance.primaryFocus,
        same(focusedControl),
        reason: 'the surface claim must not yank focus off a control the viewer chose',
      );

      chrome.cancelAutoHide();
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}

/// Minimal [Player] reporting steady playback, the state the player settles
/// into once the media is open.
class _PlayingPlayer implements Player {
  final List<Duration> seeks = [];
  Duration _position = const Duration(minutes: 5);

  @override
  String get playerType => 'mpv';

  @override
  PlayerState get state =>
      PlayerState(playing: true, position: _position, duration: const Duration(minutes: 45), seekable: true);

  @override
  Future<void> seek(Duration position) async {
    seeks.add(position);
    _position = position;
  }

  @override
  PlayerStreams get streams => PlayerStreams(
    playing: const Stream<bool>.empty(),
    completed: const Stream<bool>.empty(),
    buffering: const Stream<bool>.empty(),
    position: const Stream<Duration>.empty(),
    duration: const Stream<Duration>.empty(),
    seekable: const Stream<bool>.empty(),
    buffer: const Stream<Duration>.empty(),
    volume: const Stream<double>.empty(),
    rate: const Stream<double>.empty(),
    tracks: const Stream<Tracks>.empty(),
    track: const Stream<TrackSelection>.empty(),
    log: const Stream<PlayerLog>.empty(),
    error: const Stream<PlayerError>.empty(),
    audioDevice: const Stream<AudioDevice>.empty(),
    audioDevices: const Stream<List<AudioDevice>>.empty(),
    bufferRanges: const Stream<List<BufferRange>>.empty(),
    playbackRestart: const Stream<void>.empty(),
    backendSwitched: const Stream<void>.empty(),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
