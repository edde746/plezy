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
import 'package:plezy/services/device_adjustment_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/video_volume_controller.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/watch_together/providers/watch_together_provider.dart';
import 'package:plezy/widgets/video_controls/player_chrome_controller.dart';
import 'package:plezy/widgets/video_controls/video_controls.dart';
import 'package:plezy/widgets/video_controls/widgets/player_toast_indicator.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';
import '../test_helpers/theme.dart';

/// Flutter keeps routing a held finger's move, up and cancel events to
/// the hit-test path captured at pointer down, so they reach the controls'
/// touch handlers after the player screen has swapped the controls out (its
/// failure view, a player re-init) or closed. The handlers read the State's
/// context and crashed; a finger still on the glass must find nothing left to
/// drive.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const adjustmentChannel = MethodChannel('com.plezy/device_adjustment');

  late _RecordingPlayer player;
  late PlayerChromeController chrome;
  late PlayerToastController toast;
  late VideoVolumeController volume;
  late PlaybackStateProvider playbackState;
  late WatchTogetherProvider watchTogether;
  late AppDatabase database;
  late List<MethodCall> adjustmentCalls;

  setUp(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await initializeDateFormatting('en');
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    final settings = await SettingsService.getInstance();

    // Phone layout: the touch pointer pipeline is wired only when
    // isMobile(context) && !isTV().
    TvDetectionService.debugSetAppleTVOverride(false);
    PlatformDetector.debugSetIsDesktopOSOverride(false);

    adjustmentCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(adjustmentChannel, (
      call,
    ) async {
      adjustmentCalls.add(call);
      return switch (call.method) {
        'getBrightness' || 'getMediaVolume' => 0.5,
        _ => null,
      };
    });

    database = AppDatabase.forTesting(NativeDatabase.memory());
    player = _RecordingPlayer();
    chrome = PlayerChromeController();
    toast = PlayerToastController();
    volume = VideoVolumeController(player: player, settings: settings, initialVolume: 100);
    playbackState = PlaybackStateProvider();
    watchTogether = WatchTogetherProvider();
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(adjustmentChannel, null);
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

  Iterable<MethodCall> callsTo(String method) => adjustmentCalls.where((c) => c.method == method);

  Future<void> pumpControls(WidgetTester tester) async {
    // Reset the shared brightness queue inside this test's fake-async zone.
    DeviceAdjustmentService.instance.resetForTesting();
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
                metadata: testMediaItem(id: 'touch-after-unmount'),
                toastController: toast,
                chromeController: chrome,
                canNavigateMediaItems: false,
                canControl: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    // Hidden chrome leaves the edge zones and the chord to the root Listener.
    chrome.hide();
    chrome.markControlsHidden();
    await tester.pump();
    expect(chrome.controlsVisible, isFalse);
  }

  /// The player screen replacing the controls while fingers stay down.
  Future<void> unmountControls(WidgetTester tester) async {
    chrome.cancelAutoHide();
    toast.hide();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  testWidgets('a brightness swipe still moving after the controls unmount neither throws nor writes', (tester) async {
    await pumpControls(tester);
    final origin = tester.getRect(find.byType(PlexVideoControls)).topLeft;
    final gesture = await tester.startGesture(origin + const Offset(40, 400));
    await tester.pump(); // Resolve the candidate baseline read.
    await gesture.moveTo(origin + const Offset(40, 316));
    await tester.pump();
    expect(callsTo('setBrightness'), isNotEmpty, reason: 'the swipe must be live when the controls go');

    await unmountControls(tester);
    final writesAtExit = callsTo('setBrightness').length;

    await gesture.moveTo(origin + const Offset(40, 250));
    await gesture.up();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      callsTo('setBrightness'),
      hasLength(writesAtExit),
      reason: 'a finger on controls that are gone must not override the brightness the exit restored',
    );
  });

  testWidgets('a two-finger tap lifting after the controls unmount leaves playback alone', (tester) async {
    await pumpControls(tester);
    final centre = tester.getRect(find.byType(PlexVideoControls)).center;
    final first = await tester.startGesture(centre - const Offset(20, 0));
    final second = await tester.startGesture(centre + const Offset(20, 0));

    await unmountControls(tester);
    await first.up();
    await second.up();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(player.playOrPauseCalls, 0, reason: 'a chord on a surface that is gone must not toggle playback');
  });
}

/// Minimal [Player] against a fixed 45-minute item that counts toggles.
class _RecordingPlayer implements Player {
  int playOrPauseCalls = 0;

  @override
  String get playerType => 'mpv';

  @override
  PlayerState get state => PlayerState(
    playing: true,
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
  Future<void> playOrPause() async {
    playOrPauseCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
