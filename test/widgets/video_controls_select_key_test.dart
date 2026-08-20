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
import 'package:plezy/media/media_source_info.dart';
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

/// Pressing Enter on the player surface used to raise the chrome *and* drop
/// focus onto Play/Pause, while the global input-mode tracker separately
/// switched the whole app into keyboard mode — even with "Video Player
/// Navigation" off. Enter activates whatever already has focus; it is not a
/// request to start navigating, so it must leave focus where the viewer left it
/// while still doing its job. Tab and a remote's OK remain the deliberate ways
/// into the OSD.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _TogglePlayer player;
  late PlayerChromeController chrome;
  late PlayerToastController toast;
  late VideoVolumeController volume;
  late PlaybackStateProvider playbackState;
  late WatchTogetherProvider watchTogether;
  late AppDatabase database;
  late ValueNotifier<bool> hasFirstFrame;
  late SettingsService settings;
  late FocusNode screenFocusNode;
  var toggles = 0;

  Future<void> setNavigationEnabled(bool value) => settings.write(SettingsService.videoPlayerNavigationEnabled, value);

  setUp(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await initializeDateFormatting('en');
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    settings = await SettingsService.getInstance();

    // Desktop with a pointer: the configuration the report came from.
    TvDetectionService.debugSetAppleTVOverride(false);
    PlatformDetector.debugSetIsDesktopOSOverride(true);

    database = AppDatabase.forTesting(NativeDatabase.memory());
    player = _TogglePlayer();
    chrome = PlayerChromeController(initiallyVisible: false);
    toast = PlayerToastController();
    volume = VideoVolumeController(player: player, settings: settings, initialVolume: 100);
    playbackState = PlaybackStateProvider();
    watchTogether = WatchTogetherProvider();
    hasFirstFrame = ValueNotifier<bool>(true);
    screenFocusNode = FocusNode(debugLabel: 'VideoPlayerScreen');
    toggles = 0;
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
    await player.close();
    await database.close();
  });

  /// Mirrors the production tree: the screen-level node autofocuses during the
  /// loading phase and already holds the remote by the time the controls mount,
  /// so the controls' own `autofocus` cannot win it back. Without that, the
  /// surface would take focus by default and the startup claim would look
  /// correct even when it is not.
  Widget shell(Widget child) => InputModeTracker(
    child: MultiProvider(
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
            child: Focus(focusNode: screenFocusNode, autofocus: true, child: child),
          ),
        ),
      ),
    ),
  );

  Future<void> pumpPlayer(WidgetTester tester, {List<MediaMarker>? markers}) async {
    await tester.pumpWidget(shell(const SizedBox.expand()));
    await tester.pump();
    expect(screenFocusNode.hasPrimaryFocus, isTrue, reason: 'precondition: the screen node owns the remote');

    await tester.pumpWidget(
      shell(
        PlexVideoControls(
          player: player,
          volumeController: volume,
          metadata: testMediaItem(id: 'select-key'),
          initialMarkers: markers,
          toastController: toast,
          chromeController: chrome,
          hasFirstFrame: hasFirstFrame,
          canNavigateMediaItems: false,
          onPlayPauseRequested: (_) async => toggles++,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyDownEvent(key);
    await tester.pump();
    await tester.sendKeyUpEvent(key);
    await tester.pumpAndSettle();
  }

  String? focusLabel() => FocusManager.instance.primaryFocus?.debugLabel;

  InputMode currentMode(WidgetTester tester) =>
      InputModeTracker.of(tester.element(find.byType(PlexVideoControls)), listen: false);

  /// Mounts the player, runs [body], then unmounts and disarms the auto-hide
  /// timer so the harness's pending-timer check stays honest.
  void playerTest(String description, Future<void> Function(WidgetTester tester) body, {List<MediaMarker>? markers}) {
    testWidgets(description, (tester) async {
      await pumpPlayer(tester, markers: markers);
      await body(tester);
      chrome.cancelAutoHide();
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  group('player navigation disabled', () {
    setUp(() => setNavigationEnabled(false));

    playerTest('the player surface, not the screen node, owns the remote once mounted', (tester) async {
      expect(focusLabel(), 'PlayerSurface');
    });

    playerTest('Enter raises the chrome and toggles playback without taking focus', (tester) async {
      await press(tester, LogicalKeyboardKey.enter);

      expect(chrome.controlsVisible, isTrue, reason: 'Select is the show-me-the-controls affordance');
      expect(toggles, 1);
      expect(focusLabel(), 'PlayerSurface', reason: 'a keyboard Enter must not start a focus session');
      expect(currentMode(tester), InputMode.pointer, reason: 'and must not arm focus chrome app-wide');
    });

    playerTest('Enter keeps toggling once the chrome is up', (tester) async {
      await press(tester, LogicalKeyboardKey.enter);
      await press(tester, LogicalKeyboardKey.enter);

      expect(toggles, 2, reason: 'Select must not become a one-shot key when the chrome is visible');
      expect(focusLabel(), 'PlayerSurface');
    });

    playerTest('a remote OK does hand the chrome focus', (tester) async {
      await press(tester, LogicalKeyboardKey.select);

      expect(chrome.controlsVisible, isTrue);
      expect(focusLabel(), 'PlayPause', reason: 'a remote has no pointer, so OK is a navigation request');
      expect(currentMode(tester), InputMode.keyboard);
    });

    playerTest('Tab is the keyboard way into the OSD, and keeps traversing inside it', (tester) async {
      await press(tester, LogicalKeyboardKey.tab);
      expect(chrome.controlsVisible, isTrue);
      expect(focusLabel(), 'PlayPause', reason: 'Tab with the chrome down raises it and hands it focus');

      // The surface handler must not swallow Tab once focus is inside the OSD,
      // or the viewer is stranded on the control Tab first landed on.
      await press(tester, LogicalKeyboardKey.tab);
      expect(
        focusLabel(),
        isNot(anyOf('PlayPause', 'PlayerSurface')),
        reason: 'app-level NextFocusAction must reach the next OSD control',
      );
    });

    playerTest('an arrow seeks without switching the app into keyboard mode', (tester) async {
      await press(tester, LogicalKeyboardKey.arrowRight);

      expect(currentMode(tester), InputMode.pointer, reason: 'arrows are playback shortcuts here');
      expect(focusLabel(), 'PlayerSurface');
    });
  });

  group('player navigation enabled', () {
    setUp(() => setNavigationEnabled(true));

    playerTest('Enter shows the chrome and toggles, leaving focus put', (tester) async {
      await press(tester, LogicalKeyboardKey.enter);

      expect(chrome.controlsVisible, isTrue);
      expect(toggles, 1);
      // Opting into player navigation buys arrow keys, not a focus session from
      // a plain Enter: focus and input mode move together or not at all.
      expect(focusLabel(), 'PlayerSurface');
      expect(currentMode(tester), InputMode.pointer);
    });

    playerTest('ArrowUp raises the chrome onto Play/Pause', (tester) async {
      await press(tester, LogicalKeyboardKey.arrowUp);

      expect(chrome.controlsVisible, isTrue);
      expect(focusLabel(), 'PlayPause');
      expect(currentMode(tester), InputMode.keyboard);
    });

    playerTest('ArrowUp hands focus over when the chrome is already up', (tester) async {
      chrome.show();
      await tester.pumpAndSettle();
      expect(focusLabel(), 'PlayerSurface', reason: 'precondition: nothing in the chrome owns focus');

      await press(tester, LogicalKeyboardKey.arrowUp);

      expect(focusLabel(), 'PlayPause', reason: 'the arrow must not be consumed into a dead end');
    });

    playerTest('a horizontal arrow hands focus over when the chrome is already up', (tester) async {
      chrome.show();
      await tester.pumpAndSettle();
      expect(focusLabel(), 'PlayerSurface', reason: 'precondition: nothing in the chrome owns focus');

      await press(tester, LogicalKeyboardKey.arrowRight);

      // The surface only owns horizontals while the chrome is down, so this
      // arrow promotes the app into keyboard mode; focus has to become visible
      // with it or the two diverge.
      expect(currentMode(tester), InputMode.keyboard);
      expect(focusLabel(), 'PlayPause', reason: 'the arrow must not be consumed into a dead end');
    });

    playerTest('a horizontal arrow seeks under the chrome without arming focus', (tester) async {
      await press(tester, LogicalKeyboardKey.arrowRight);

      expect(currentMode(tester), InputMode.pointer, reason: 'a hidden-chrome seek is not navigation');
      expect(chrome.controlsVisible, isFalse);
    });
  });

  playerTest('the OSD focus entry point is raw mechanism, not policy', (tester) async {
    await setNavigationEnabled(false);
    chrome.show();
    await tester.pumpAndSettle();

    // Internal hand-offs — the skip-marker button's ArrowDown, an item swap —
    // must keep working even with navigation off and no keyboard session.
    tester.state<DesktopVideoControlsState>(find.byType(DesktopVideoControls)).requestPlayPauseFocus();
    await tester.pumpAndSettle();

    expect(focusLabel(), 'PlayPause');
  });

  // The player surface must own the remote from the moment it mounts, whatever
  // the chrome is doing. When it does not, the screen node answers the first
  // key with its chrome-raising self-heal instead of a playback shortcut.
  group('startup hands the remote to the player surface', () {
    setUp(() {
      chrome.dispose();
      chrome = PlayerChromeController(initiallyVisible: true);
    });

    playerTest('when the route opens with the chrome already up (desktop)', (tester) async {
      expect(focusLabel(), 'PlayerSurface');
    });

    playerTest('and Enter there toggles playback instead of raising a self-heal', (tester) async {
      await press(tester, LogicalKeyboardKey.enter);

      expect(toggles, 1);
      expect(focusLabel(), 'PlayerSurface');
      expect(currentMode(tester), InputMode.pointer);
    });
  });

  group('startup on a television', () {
    setUp(() async {
      TvDetectionService.debugSetAppleTVOverride(true);
      PlatformDetector.debugSetIsDesktopOSOverride(false);
      await setNavigationEnabled(true);
    });

    // A TV route opens with the chrome down, navigation on and keyboard mode
    // already active — the exact combination that used to skip the claim.
    playerTest('the surface owns the remote even though the chrome starts down', (tester) async {
      expect(chrome.controlsVisible, isFalse);
      expect(focusLabel(), 'PlayerSurface');
    });
  });

  group('skip intro on a television', () {
    setUp(() async {
      TvDetectionService.debugSetAppleTVOverride(true);
      PlatformDetector.debugSetIsDesktopOSOverride(false);
      await setNavigationEnabled(true);
    });

    // Selecting Skip Intro removes the focused button from the tree. The
    // remote must land back on the player surface — otherwise focus falls out
    // of the controls subtree, the screen node reclaims it, and its self-heal
    // turns the next Select into a chrome-raise, so pausing takes two presses
    // (#1890).
    playerTest(
      'Select toggles playback on the first press after skipping the intro',
      markers: [MediaMarker(id: 1, type: 'intro', startTimeOffset: 10000, endTimeOffset: 45000)],
      (tester) async {
        // A remote is non-pointer input, so the app is already in keyboard
        // mode when the marker appears — the combination that autofocuses the
        // skip button on TV.
        InputModeTracker.reportNonPointerInput();
        player.emitPosition(const Duration(seconds: 15));
        await tester.pumpAndSettle();
        expect(focusLabel(), 'SkipMarkerButton', reason: 'precondition: TV autofocuses the sole affordance');

        await press(tester, LogicalKeyboardKey.select);

        expect(player.state.position, const Duration(seconds: 45), reason: 'Select activated the skip');
        expect(focusLabel(), 'PlayerSurface', reason: 'the vanished button must hand the remote back');

        await press(tester, LogicalKeyboardKey.select);

        expect(toggles, 1, reason: 'one press must toggle playback, not merely raise the chrome');
      },
    );
  });
}

/// Minimal [Player] reporting steady playback; transport is routed to the
/// widget's `onPlayPauseRequested` callback so the test can count toggles.
class _TogglePlayer implements Player {
  Duration _position = const Duration(minutes: 5);
  final StreamController<Duration> _positionController = StreamController<Duration>.broadcast();

  /// Moves the playhead and announces it on the position stream, the way a
  /// real player drives marker detection.
  void emitPosition(Duration position) {
    _position = position;
    _positionController.add(position);
  }

  Future<void> close() => _positionController.close();

  @override
  String get playerType => 'mpv';

  @override
  PlayerState get state =>
      PlayerState(playing: true, position: _position, duration: const Duration(minutes: 45), seekable: true);

  /// A real player announces the new playhead right after a seek; marker
  /// detection (and its focus handling) rides on that event.
  @override
  Future<void> seek(Duration position) async => emitPosition(position);

  @override
  PlayerStreams get streams => PlayerStreams(
    playing: const Stream<bool>.empty(),
    completed: const Stream<bool>.empty(),
    buffering: const Stream<bool>.empty(),
    position: _positionController.stream,
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
