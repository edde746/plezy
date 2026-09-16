import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:plezy/database/app_database.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
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

/// The OSD used to auto-hide on the same 5s a phone gets, which is shorter
/// than a remote traversal of the control bar: the viewer reads each label
/// between presses and loses the chrome mid-way. A D-pad viewer gets 10s, and
/// a paused D-pad viewer keeps the chrome until they dismiss it — a remote has
/// no tap to bring it back.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('auto-hide on Android TV', () {
    late _RemotePlayer player;
    late PlayerChromeController chrome;
    late PlayerToastController toast;
    late VideoVolumeController volume;
    late PlaybackStateProvider playbackState;
    late WatchTogetherProvider watchTogether;
    late AppDatabase database;
    late ValueNotifier<bool> hasFirstFrame;
    late FocusNode screenFocusNode;

    setUp(() async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      await initializeDateFormatting('en');
      resetSharedPreferencesForTest();
      SettingsService.resetForTesting();
      final settings = await SettingsService.getInstance();

      // A non-Apple TV: the forced-TV override is the only way to get one,
      // since the Apple override sets both isTV and isAppleTV.
      TvDetectionService.debugSetAppleTVOverride(null);
      await TvDetectionService.getInstance(forceTv: true);
      TvDetectionService.setForceTVSync(true);
      PlatformDetector.debugSetIsDesktopOSOverride(false);

      database = AppDatabase.forTesting(NativeDatabase.memory());
      player = _RemotePlayer();
      chrome = PlayerChromeController();
      toast = PlayerToastController();
      volume = VideoVolumeController(player: player, settings: settings, initialVolume: 100);
      playbackState = PlaybackStateProvider();
      watchTogether = WatchTogetherProvider();
      hasFirstFrame = ValueNotifier<bool>(true);
      screenFocusNode = FocusNode(debugLabel: 'VideoPlayerScreen');
    });

    tearDown(() async {
      TvDetectionService.setForceTVSync(false);
      PlatformDetector.debugSetIsDesktopOSOverride(null);
      hasFirstFrame.dispose();
      screenFocusNode.dispose();
      volume.dispose();
      playbackState.dispose();
      watchTogether.dispose();
      chrome.dispose();
      toast.dispose();
      await player.close();
      await database.close();
    });

    Widget shell(Widget child) => InputModeTracker(
      child: MultiProvider(
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
              child: Focus(focusNode: screenFocusNode, autofocus: true, child: child),
            ),
          ),
        ),
      ),
    );

    /// Mounts the controls with the OSD already up and the picture playing,
    /// the state a viewer is in when they start walking the control bar.
    Future<void> pumpControls(WidgetTester tester) async {
      await tester.pumpWidget(shell(const SizedBox.expand()));
      await tester.pump();

      await tester.pumpWidget(
        shell(
          PlexVideoControls(
            player: player,
            volumeController: volume,
            metadata: testMediaItem(id: 'auto-hide'),
            toastController: toast,
            chromeController: chrome,
            hasFirstFrame: hasFirstFrame,
            canNavigateMediaItems: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(chrome.controlsVisible, isTrue, reason: 'precondition: the OSD is up');
      expect(find.byType(DesktopVideoControls), findsOneWidget);
    }

    Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
      await tester.sendKeyDownEvent(key);
      await tester.pump();
      await tester.sendKeyUpEvent(key);
      await tester.pump();
    }

    testWidgets('a remote press mid-traversal keeps the OSD up past 5s, and it hides at 10s', (tester) async {
      await pumpControls(tester);

      await tester.pump(const Duration(seconds: 4));
      await press(tester, LogicalKeyboardKey.arrowRight);

      await tester.pump(const Duration(seconds: 6));
      expect(chrome.controlsVisible, isTrue, reason: 'the viewer is still reading the next label');

      await tester.pump(const Duration(seconds: 4));
      expect(chrome.controlsVisible, isFalse, reason: 'an idle remote does let the OSD go');

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('pausing keeps the OSD up until the viewer dismisses it', (tester) async {
      await pumpControls(tester);

      player.setPlaying(false);
      await tester.pump();

      await tester.pump(const Duration(seconds: 30));
      expect(chrome.controlsVisible, isTrue, reason: 'a remote has no tap to bring the OSD back');
      expect(find.byType(DesktopVideoControls), findsOneWidget);

      chrome.cancelAutoHide();
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}

/// Minimal [Player] whose playing state the test can flip, the way a remote's
/// pause reaches the controls.
class _RemotePlayer implements Player {
  bool _playing = true;
  final StreamController<bool> _playingController = StreamController<bool>.broadcast();

  void setPlaying(bool playing) {
    _playing = playing;
    _playingController.add(playing);
  }

  Future<void> close() => _playingController.close();

  @override
  String get playerType => 'mpv';

  @override
  PlayerState get state => PlayerState(
    playing: _playing,
    position: const Duration(minutes: 5),
    duration: const Duration(minutes: 45),
    seekable: true,
  );

  @override
  Future<void> seek(Duration position) async {}

  @override
  PlayerStreams get streams => PlayerStreams(
    playing: _playingController.stream,
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
