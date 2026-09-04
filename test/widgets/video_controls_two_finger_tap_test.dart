import 'package:drift/native.dart';
import 'package:flutter/material.dart';
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
import 'package:plezy/focus/transport_keys.dart';
import 'package:plezy/widgets/video_controls/player_chrome_controller.dart';
import 'package:plezy/widgets/video_controls/video_controls.dart';
import 'package:plezy/widgets/video_controls/widgets/player_toast_indicator.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';
import '../test_helpers/theme.dart';

/// Issue #1505: on touch devices a two-finger tap toggles playback and leaves
/// the chrome down, so the frame the viewer paused to read stays uncovered.
///
/// The gesture takes over the two-finger chord that previously reset the video
/// zoom on a double tap. The two cannot coexist — a two-finger double tap is
/// two two-finger taps, so recognising a pair means holding the toggle back for
/// kDoubleTapTimeout first, and pausing late is pausing on the wrong frame. The
/// reset binding was therefore dropped, not deferred: the tap fires the moment
/// it resolves, in every player state including while zoomed, and zoom reset
/// lives in the settings sheet, the keyboard shortcut, and pinching back
/// through the 100% detent.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingPlayer player;
  late PlayerChromeController chrome;
  late PlayerToastController toast;
  late VideoVolumeController volume;
  late PlaybackStateProvider playbackState;
  late WatchTogetherProvider watchTogether;
  late AppDatabase database;
  late List<TransportCommand> transportCommands;
  late int zoomResets;

  setUp(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await initializeDateFormatting('en');
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    final settings = await SettingsService.getInstance();
    await settings.write(SettingsService.seekTimeSmall, 10);

    // Phone layout: the touch pointer pipeline is wired only when
    // PlatformDetector.isMobile(context) && !PlatformDetector.isTV().
    TvDetectionService.debugSetAppleTVOverride(false);
    PlatformDetector.debugSetIsDesktopOSOverride(false);

    database = AppDatabase.forTesting(NativeDatabase.memory());
    player = _RecordingPlayer();
    chrome = PlayerChromeController();
    toast = PlayerToastController();
    volume = VideoVolumeController(player: player, settings: settings, initialVolume: 100);
    playbackState = PlaybackStateProvider();
    watchTogether = WatchTogetherProvider();
    transportCommands = [];
    zoomResets = 0;
  });

  tearDown(() async {
    TvDetectionService.debugSetAppleTVOverride(null);
    PlatformDetector.debugSetIsDesktopOSOverride(null);
    volume.dispose();
    playbackState.dispose();
    watchTogether.dispose();
    chrome.dispose();
    toast.dispose();
    await database.close();
  });

  const surface = Size(800, 600);

  Future<void> pumpControls(
    WidgetTester tester, {
    bool wireTransportCallback = true,
    double videoZoomScale = 1.0,
    bool canControl = true,
    bool startPaused = false,
  }) async {
    if (startPaused) await player.pause();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppDatabase>.value(value: database),
          ChangeNotifierProvider<PlaybackStateProvider>.value(value: playbackState),
          ChangeNotifierProvider<WatchTogetherProvider>.value(value: watchTogether),
        ],
        child: MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android, extensions: const [testMonoTokens]),
          home: Scaffold(
            body: SizedBox(
              width: surface.width,
              height: surface.height,
              child: PlexVideoControls(
                player: player,
                volumeController: volume,
                metadata: testMediaItem(id: 'two-finger-tap'),
                toastController: toast,
                chromeController: chrome,
                canNavigateMediaItems: false,
                canControl: canControl,
                videoZoomScale: videoZoomScale,
                onResetVideoZoom: () => zoomResets++,
                // Mirrors the screen wiring at video_player/parts/build.dart:311.
                // _handleControlsTransport announces every accepted command, so
                // recording one here is recording the transport disc the viewer
                // gets — the gesture is silent chrome, not silent playback.
                onPlayPauseRequested: wireTransportCallback
                    ? (command) async {
                        transportCommands.add(command);
                        await switch (command) {
                          TransportCommand.play => player.play(),
                          TransportCommand.pause => player.pause(),
                          TransportCommand.toggle => player.playOrPause(),
                        };
                      }
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    // Every case starts from hidden chrome — the state the issue is about.
    chrome.hide();
    chrome.markControlsHidden();
    await tester.pump();
    expect(chrome.controlsVisible, isFalse);
  }

  Offset centreOf(WidgetTester tester) => tester.getRect(find.byType(PlexVideoControls)).center;

  /// Two fingers down, then both up — the production gesture.
  Future<void> twoFingerTap(WidgetTester tester, {Offset? at, double spread = 40}) async {
    final origin = at ?? centreOf(tester);
    final first = await tester.startGesture(origin - Offset(spread / 2, 0), pointer: _nextPointer());
    final second = await tester.startGesture(origin + Offset(spread / 2, 0), pointer: _nextPointer());
    await first.up();
    await second.up();
    await tester.pump();
  }

  Future<void> settle(WidgetTester tester) async {
    chrome.cancelAutoHide();
    toast.hide();
    await tester.pumpWidget(const SizedBox.shrink());
  }

  testWidgets('a two-finger tap pauses without raising the chrome', (tester) async {
    await pumpControls(tester);
    expect(player.state.playing, isTrue);

    await twoFingerTap(tester);

    expect(transportCommands, [TransportCommand.toggle]);
    expect(player.state.playing, isFalse);
    expect(chrome.controlsVisible, isFalse, reason: 'the paused frame must stay uncovered');

    await settle(tester);
  });

  testWidgets('a second two-finger tap resumes — no pair is ever swallowed', (tester) async {
    await pumpControls(tester);

    await twoFingerTap(tester);
    expect(player.state.playing, isFalse);

    await twoFingerTap(tester);

    expect(transportCommands, [TransportCommand.toggle, TransportCommand.toggle]);
    expect(player.state.playing, isTrue);
    expect(chrome.controlsVisible, isFalse);

    await settle(tester);
  });

  testWidgets('a zoomed tap toggles immediately, with no waiting period', (tester) async {
    await pumpControls(tester, videoZoomScale: 1.6);

    await twoFingerTap(tester);

    expect(transportCommands, [TransportCommand.toggle], reason: 'zoom must not delay or disable the gesture');
    expect(player.state.playing, isFalse);
    expect(chrome.controlsVisible, isFalse);

    await settle(tester);
  });

  testWidgets('a zoomed tap dispatches nothing further once the double-tap window lapses', (tester) async {
    await pumpControls(tester, videoZoomScale: 1.6);

    await twoFingerTap(tester);
    await tester.pump(const Duration(milliseconds: 400));

    expect(transportCommands, [TransportCommand.toggle], reason: 'no deferred action may be left pending');

    await settle(tester);
  });

  testWidgets('a two-finger double tap never resets the zoom', (tester) async {
    await pumpControls(tester, videoZoomScale: 1.6);

    await twoFingerTap(tester);
    await twoFingerTap(tester);

    expect(zoomResets, 0, reason: 'the chord is transport-only; reset lives in the sheet, keys and pinch');
    expect(transportCommands, [TransportCommand.toggle, TransportCommand.toggle]);
    expect(player.state.playing, isTrue, reason: 'two toggles return to the starting state');

    await settle(tester);
  });

  testWidgets('a paused viewer is not resumed by anything but their own tap', (tester) async {
    await pumpControls(tester, videoZoomScale: 1.6, startPaused: true);

    await twoFingerTap(tester);

    expect(player.state.playing, isTrue, reason: 'one tap toggles, from either direction');
    expect(transportCommands, [TransportCommand.toggle]);
    expect(zoomResets, 0);

    await settle(tester);
  });

  testWidgets('a two-finger double tap while unzoomed does not touch the zoom', (tester) async {
    await pumpControls(tester);

    await twoFingerTap(tester);
    await twoFingerTap(tester);

    expect(zoomResets, 0, reason: 'resetting 100% to 100% would only flash a pointless zoom toast');

    await settle(tester);
  });

  testWidgets('without a transport callback the gesture drives the player directly', (tester) async {
    await pumpControls(tester, wireTransportCallback: false);

    await twoFingerTap(tester);

    expect(transportCommands, isEmpty);
    expect(player.state.playing, isFalse);
    expect(chrome.controlsVisible, isFalse);

    await settle(tester);
  });

  testWidgets('a one-finger tap still toggles the chrome instead of playback', (tester) async {
    await pumpControls(tester);

    await tester.tapAt(centreOf(tester));
    await tester.pump(const Duration(milliseconds: 400));

    expect(transportCommands, isEmpty);
    expect(player.state.playing, isTrue);
    expect(chrome.controlsVisible, isTrue);

    await settle(tester);
  });

  testWidgets('a three-finger tap does nothing', (tester) async {
    await pumpControls(tester);
    final origin = centreOf(tester);

    final a = await tester.startGesture(origin - const Offset(40, 0), pointer: _nextPointer());
    final b = await tester.startGesture(origin, pointer: _nextPointer());
    final c = await tester.startGesture(origin + const Offset(40, 0), pointer: _nextPointer());
    await a.up();
    await b.up();
    await c.up();
    await tester.pump();

    expect(transportCommands, isEmpty);
    expect(player.state.playing, isTrue);
    expect(chrome.controlsVisible, isFalse);

    await settle(tester);
  });

  testWidgets('a pinch does not toggle playback', (tester) async {
    await pumpControls(tester);
    final origin = centreOf(tester);

    final first = await tester.startGesture(origin - const Offset(20, 0), pointer: _nextPointer());
    final second = await tester.startGesture(origin + const Offset(20, 0), pointer: _nextPointer());
    await first.moveTo(origin - const Offset(140, 0));
    await second.moveTo(origin + const Offset(140, 0));
    await first.up();
    await second.up();
    await tester.pump();

    expect(transportCommands, isEmpty);
    expect(player.state.playing, isTrue);

    await settle(tester);
  });

  testWidgets('the gesture is inert while the content strip is open', (tester) async {
    await pumpControls(tester);
    // Opening the strip forces the chrome visible, so this spot is chosen to
    // miss every control in both states: the differential below is only
    // meaningful because the same point toggles playback with the strip shut.
    final rect = tester.getRect(find.byType(PlexVideoControls));
    final clearOfControls = Offset(rect.left + rect.width * 0.08, rect.top + rect.height * 0.30);

    await twoFingerTap(tester, at: clearOfControls, spread: 24);
    expect(transportCommands, hasLength(1), reason: 'baseline: the spot is live with the strip shut');

    chrome.setContentStripVisible(true);
    await tester.pump();

    await twoFingerTap(tester, at: clearOfControls, spread: 24);

    expect(transportCommands, hasLength(1), reason: 'chapter/queue browsing owns the surface');

    chrome.setContentStripVisible(false);
    await settle(tester);
  });

  testWidgets('a guest without playback control cannot toggle', (tester) async {
    await pumpControls(tester, canControl: false);

    await twoFingerTap(tester);

    expect(transportCommands, isEmpty);
    expect(player.state.playing, isTrue);

    await settle(tester);
  });
}

int _pointerSequence = 0;

int _nextPointer() => ++_pointerSequence;

/// Minimal [Player] tracking playback state against a fixed 45-minute item.
class _RecordingPlayer implements Player {
  bool _playing = true;

  @override
  String get playerType => 'mpv';

  @override
  PlayerState get state => PlayerState(
    playing: _playing,
    position: const Duration(minutes: 10),
    duration: const Duration(minutes: 45),
    seekable: true,
  );

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
  Future<void> play() async => _playing = true;

  @override
  Future<void> pause() async => _playing = false;

  @override
  Future<void> playOrPause() async => _playing = !_playing;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
