import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:plezy/database/app_database.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/video_volume_controller.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/watch_together/providers/watch_together_provider.dart';
import 'package:plezy/widgets/video_controls/desktop_video_controls.dart';
import 'package:plezy/widgets/video_controls/mobile_video_controls.dart';
import 'package:plezy/widgets/video_controls/player_chrome_controller.dart';
import 'package:plezy/widgets/video_controls/video_controls.dart';
import 'package:plezy/widgets/video_controls/widgets/player_toast_indicator.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';
import '../test_helpers/theme.dart';

/// Regression coverage for #1765: a player route that opens with its chrome
/// down must stay down across the whole startup sequence. Auto-hide cannot arm
/// before the first frame, so chrome that survives into the picture parks the
/// OSD and timebar over the opening seconds of the video.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('startup chrome', () {
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

      TvDetectionService.debugSetAppleTVOverride(true);
      PlatformDetector.debugSetIsDesktopOSOverride(false);

      database = AppDatabase.forTesting(NativeDatabase.memory());
      player = _PlayingPlayer();
      chrome = PlayerChromeController(initiallyVisible: false);
      toast = PlayerToastController();
      volume = VideoVolumeController(player: player, settings: settings, initialVolume: 100);
      playbackState = PlaybackStateProvider();
      watchTogether = WatchTogetherProvider();
      hasFirstFrame = ValueNotifier<bool>(false);
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
          theme: ThemeData(platform: TargetPlatform.android, extensions: const [testMonoTokens]),
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

    Future<void> pumpControls(WidgetTester tester) async {
      // Two phases, like the route itself: the loading surface first, so the
      // screen node owns primary focus before the controls exist. The controls'
      // own `autofocus` cannot win it back afterwards — an explicit claim must.
      await tester.pumpWidget(shell(const SizedBox.expand()));
      await tester.pump();
      expect(screenFocusNode.hasPrimaryFocus, isTrue, reason: 'the loading phase owns focus, as on the real route');

      await tester.pumpWidget(
        shell(
          PlexVideoControls(
            player: player,
            volumeController: volume,
            metadata: testMediaItem(id: 'startup-chrome'),
            toastController: toast,
            chromeController: chrome,
            hasFirstFrame: hasFirstFrame,
            canNavigateMediaItems: false,
          ),
        ),
      );
      await tester.pump();
    }

    void expectNoChrome(String reason) {
      expect(chrome.controlsVisible, isFalse, reason: reason);
      // Presented must fall with visible, or Back is classified as "hide the
      // chrome", no-ops against already-hidden chrome, and never exits.
      expect(chrome.controlsPresented, isFalse, reason: reason);
      expect(find.byType(DesktopVideoControls), findsNothing, reason: reason);
      expect(find.byType(MobileVideoControls), findsNothing, reason: reason);
    }

    testWidgets('a hidden start never mounts the OSD while loading or once the picture arrives', (tester) async {
      await pumpControls(tester);

      expectNoChrome('the route opened with the chrome down');

      hasFirstFrame.value = true;
      await tester.pump();
      expectNoChrome('the first frame must not raise the OSD over the picture');

      // Well past the TV auto-hide delay: nothing may surface late either.
      await tester.pump(const Duration(seconds: 10));
      expectNoChrome('no deferred timer may raise the OSD after startup');

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('the viewer can still raise the OSD after a hidden start', (tester) async {
      await pumpControls(tester);
      hasFirstFrame.value = true;
      await tester.pump();

      chrome.show();
      await tester.pumpAndSettle();

      expect(chrome.controlsVisible, isTrue);
      expect(chrome.controlsPresented, isTrue);
      expect(find.byType(DesktopVideoControls), findsOneWidget);

      chrome.cancelAutoHide();
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a hidden start hands the remote to the hidden-chrome key layer', (tester) async {
      await pumpControls(tester);
      hasFirstFrame.value = true;
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      // The controls' own Focus autofocuses too late to win the scope: without
      // an explicit claim the screen node keeps primary focus, the arrow
      // reaches it first, and its self-heal raises the whole OSD on this very
      // first press (#1765).
      expect(
        keysReachingScreen,
        isEmpty,
        reason: 'the hidden-chrome layer must own the remote, not the screen self-heal',
      );
      expect(find.text('10s'), findsOneWidget, reason: 'the seek badge answers, not the chrome');
      expectNoChrome('a directional seek must leave the picture alone');

      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(player.seeks, [const Duration(seconds: 10)]);

      chrome.cancelAutoHide();
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}

/// Minimal [Player] that reports steady playback, the state a startup sequence
/// settles into once the media opens.
class _PlayingPlayer implements Player {
  final List<Duration> seeks = [];
  Duration _position = Duration.zero;

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
