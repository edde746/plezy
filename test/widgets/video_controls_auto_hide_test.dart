import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:plezy/database/app_database.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/models/livetv_capture_buffer.dart';
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
import 'package:plezy/widgets/video_controls/widgets/live_timeline_bar.dart';
import 'package:plezy/widgets/video_controls/widgets/volume_control.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';
import '../test_helpers/theme.dart';

/// The OSD used to auto-hide on the same 5s a phone gets, which is shorter
/// than a remote traversal of the control bar: the viewer reads each label
/// between presses and loses the chrome mid-way. A D-pad viewer gets 10s, and
/// a paused D-pad viewer keeps the chrome until they dismiss it — a remote has
/// no tap to bring it back.
///
/// A press on the controls holds them until it lifts, on desktop even when the
/// drag leaves the player: a slider or scrubber unmounted mid-drag drops the
/// volume or seek it was about to commit.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('player controls auto-hide', () {
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

    Widget shell(Widget child, {bool desktop = false}) => InputModeTracker(
      child: MultiProvider(
        providers: [
          Provider<AppDatabase>.value(value: database),
          ChangeNotifierProvider<PlaybackStateProvider>.value(value: playbackState),
          ChangeNotifierProvider<WatchTogetherProvider>.value(value: watchTogether),
        ],
        child: MaterialApp(
          theme: ThemeData(
            platform: desktop ? TargetPlatform.macOS : TargetPlatform.android,
            extensions: const [testMonoTokens],
          ),
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
    /// [liveSeeks] makes it a time-shiftable live TV stream that records seeks.
    Future<void> pumpControls(WidgetTester tester, {_Surface surface = _Surface.tv, List<int>? liveSeeks}) async {
      if (surface != _Surface.tv) TvDetectionService.setForceTVSync(false);
      final desktop = surface == _Surface.desktop;
      if (desktop) PlatformDetector.debugSetIsDesktopOSOverride(true);
      await tester.pumpWidget(shell(const SizedBox.expand(), desktop: desktop));
      await tester.pump();

      final controls = PlexVideoControls(
        player: player,
        volumeController: volume,
        metadata: testMediaItem(id: 'auto-hide'),
        toastController: toast,
        chromeController: chrome,
        hasFirstFrame: hasFirstFrame,
        canNavigateMediaItems: false,
        isLive: liveSeeks != null,
        captureBuffer: liveSeeks == null
            ? null
            : CaptureBuffer(startedAt: _liveStartEpoch.toDouble(), seekStartSeconds: 0, seekEndSeconds: 3600),
        liveEpochForPosition: liveSeeks == null ? null : (position) => _liveStartEpoch + position.inSeconds,
        onLiveSeek: liveSeeks?.add,
      );
      await tester.pumpWidget(
        shell(
          desktop ? PlayerChromeInteractionRegion(controller: chrome, hideOnExit: true, child: controls) : controls,
          desktop: desktop,
        ),
      );
      await tester.pumpAndSettle();
      expect(chrome.controlsVisible, isTrue, reason: 'precondition: the OSD is up');
      expect(find.byType(surface == _Surface.phone ? MobileVideoControls : DesktopVideoControls), findsOneWidget);
    }

    Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
      await tester.sendKeyDownEvent(key);
      await tester.pump();
      await tester.sendKeyUpEvent(key);
      await tester.pump();
    }

    Finder volumeSlider() => find.descendant(of: find.byType(VolumeControl), matching: find.byType(Slider));

    /// Presses the volume slider and drags it lower, leaving the button held.
    Future<TestGesture> grabVolumeSlider(WidgetTester tester) async {
      expect(volumeSlider(), findsOneWidget);
      final gesture = await tester.startGesture(tester.getCenter(volumeSlider()), kind: PointerDeviceKind.mouse);
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump();
      expect(volume.value, lessThan(100), reason: 'precondition: the drag previewed a lower volume');
      return gesture;
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

    testWidgets('a held volume slider keeps desktop controls up and saves the volume on release', (tester) async {
      await pumpControls(tester, surface: _Surface.desktop);
      final gesture = await grabVolumeSlider(tester);
      final dragged = volume.value;

      // Hold still well past the 3s delay and any fade-out.
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 300));
      expect(chrome.controlsVisible, isTrue, reason: 'a held slider keeps the chrome up');
      expect(volumeSlider(), findsOneWidget, reason: 'the slider stays mounted under the pointer');

      await gesture.up();
      await tester.pump();
      await volume.idle;
      expect(SettingsService.instance.read(SettingsService.volume), dragged);

      await tester.pump(const Duration(seconds: 3));
      expect(chrome.controlsVisible, isFalse, reason: 'releasing the slider resumes auto-hide');
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('dragging the volume slider out of the player hides the controls only on release', (tester) async {
      await pumpControls(tester, surface: _Surface.desktop);
      final gesture = await grabVolumeSlider(tester);

      await gesture.moveTo(const Offset(-20, -20));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(chrome.controlsVisible, isTrue, reason: 'the drag still owns the slider');
      expect(volumeSlider(), findsOneWidget, reason: 'the slider stays mounted under the drag');
      final dragged = volume.value;

      await gesture.up();
      await tester.pump();
      await volume.idle;
      expect(SettingsService.instance.read(SettingsService.volume), dragged);
      expect(chrome.controlsVisible, isFalse, reason: 'the button was released outside the player');
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a slider drag that leaves and returns keeps the controls after release', (tester) async {
      await pumpControls(tester, surface: _Surface.desktop);
      final gesture = await grabVolumeSlider(tester);
      final sliderCenter = tester.getCenter(volumeSlider());

      await gesture.moveTo(const Offset(-20, -20));
      await tester.pump();
      await gesture.moveTo(sliderCenter);
      await tester.pump();
      await gesture.up();
      await tester.pump();
      expect(chrome.controlsVisible, isTrue, reason: 'the button was released over the player');

      await tester.pump(const Duration(seconds: 3));
      expect(chrome.controlsVisible, isFalse, reason: 'auto-hide resumes after release');
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a held live TV timeline keeps phone controls up and seeks on release', (tester) async {
      final liveSeeks = <int>[];
      await pumpControls(tester, surface: _Surface.phone, liveSeeks: liveSeeks);
      final scrubber = find.descendant(
        of: find.byType(LiveTimelineBar),
        matching: find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.label == t.videoControls.timelineSlider,
        ),
      );
      expect(scrubber, findsOneWidget);

      final gesture = await tester.startGesture(tester.getCenter(scrubber));
      await gesture.moveBy(const Offset(-40, 0));
      await tester.pump();

      // Hold still well past the delay and any fade-out.
      await tester.pump(const Duration(seconds: 6));
      await tester.pump(const Duration(milliseconds: 300));
      expect(chrome.controlsVisible, isTrue, reason: 'a held scrubber keeps the chrome up');
      expect(scrubber, findsOneWidget, reason: 'the scrubber stays mounted under the finger');

      await gesture.up();
      await tester.pump();
      expect(liveSeeks, hasLength(1), reason: 'releasing the scrubber seeks');

      await tester.pump(const Duration(seconds: 3));
      expect(chrome.controlsVisible, isFalse, reason: 'releasing the scrubber resumes auto-hide');
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}

enum _Surface { tv, desktop, phone }

const _liveStartEpoch = 1767268800;

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
  Future<void> setVolume(double volume) async {}

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
