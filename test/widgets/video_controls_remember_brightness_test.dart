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

/// Remember Brightness Level (#2178): with the gestures-menu toggle on, the
/// level a brightness swipe settled on is persisted and reapplied when the
/// next playback starts; the player exit still restores the pre-playback
/// brightness so the rest of the app is untouched.
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
  late SettingsService settings;
  late List<MethodCall> adjustmentCalls;
  late double nativeBrightness;

  setUp(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await initializeDateFormatting('en');
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    settings = await SettingsService.getInstance();

    // Phone layout: the touch pointer pipeline and the post-frame device
    // adjustment hook are wired only when isMobile(context) && !isTV().
    TvDetectionService.debugSetAppleTVOverride(false);
    PlatformDetector.debugSetIsDesktopOSOverride(false);

    adjustmentCalls = <MethodCall>[];
    nativeBrightness = 0.5;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(adjustmentChannel, (
      call,
    ) async {
      adjustmentCalls.add(call);
      switch (call.method) {
        case 'getBrightness':
          return nativeBrightness;
        case 'setBrightness':
          nativeBrightness = call.arguments as double;
          return null;
        case 'getMediaVolume':
          return 0.5;
        default:
          return null;
      }
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
    // Reset the shared brightness queue *inside* this test's fake-async zone:
    // a queue future minted in setUp (real zone) or a previous test's zone
    // schedules its completion on a microtask queue this test never flushes.
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
                metadata: testMediaItem(id: 'remember-brightness'),
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
    // Post-frame device-adjustment hook, then the queued channel round trips.
    await tester.pump();
    await tester.pump();
    // Swipes start from hidden chrome — visible controls cover the left edge
    // zone and swallow the pointer before the edge Listener sees it.
    chrome.hide();
    chrome.markControlsHidden();
    await tester.pump();
    expect(chrome.controlsVisible, isFalse);
  }

  Future<void> settle(WidgetTester tester) async {
    chrome.cancelAutoHide();
    toast.hide();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  /// One vertical edge swipe: down, resolve the baseline read, drag, lift.
  /// 84px up over the 420px active band (600 minus the 15% exclusion bands)
  /// is a +0.2 brightness/volume delta.
  Future<void> edgeSwipe(WidgetTester tester, {required double x}) async {
    final origin = tester.getRect(find.byType(PlexVideoControls)).topLeft;
    final gesture = await tester.startGesture(origin + Offset(x, 400));
    await tester.pump(); // Resolve the candidate baseline read deterministically.
    await gesture.moveTo(origin + Offset(x, 316));
    await tester.pump();
    await gesture.up();
    await tester.pump();
  }

  testWidgets('playback opens at the remembered level and exit still restores', (tester) async {
    await settings.write(SettingsService.rememberBrightnessLevel, true);
    await settings.write(SettingsService.rememberedBrightnessLevel, 0.35);

    await pumpControls(tester);

    expect(callsTo('setBrightness').map((c) => c.arguments), [closeTo(0.35, 0.001)]);

    await settle(tester);
    expect(
      callsTo('restoreBrightness'),
      hasLength(1),
      reason: 'leaving the player must not darken the rest of the app',
    );
  });

  testWidgets('an unset remembered level writes nothing at startup', (tester) async {
    await settings.write(SettingsService.rememberBrightnessLevel, true);

    await pumpControls(tester);

    expect(callsTo('setBrightness'), isEmpty);

    await settle(tester);
  });

  testWidgets('with the toggle off a stored level is left alone at startup', (tester) async {
    await settings.write(SettingsService.rememberedBrightnessLevel, 0.35);

    await pumpControls(tester);

    expect(callsTo('setBrightness'), isEmpty);

    await settle(tester);
  });

  testWidgets('a disabled brightness swipe never reapplies a remembered level', (tester) async {
    await settings.write(SettingsService.rememberBrightnessLevel, true);
    await settings.write(SettingsService.rememberedBrightnessLevel, 0.35);
    await settings.write(SettingsService.gestureBrightnessSwipe, false);

    await pumpControls(tester);

    expect(callsTo('setBrightness'), isEmpty);

    await settle(tester);
  });

  testWidgets('a finished brightness swipe persists the level it settled on', (tester) async {
    await settings.write(SettingsService.rememberBrightnessLevel, true);

    await pumpControls(tester);
    await edgeSwipe(tester, x: 40);

    expect(callsTo('setBrightness').map((c) => c.arguments).last, closeTo(0.7, 0.001));
    expect(settings.read(SettingsService.rememberedBrightnessLevel), closeTo(0.7, 0.001));

    await settle(tester);
  });

  testWidgets('with the toggle off a brightness swipe persists nothing', (tester) async {
    await pumpControls(tester);
    await edgeSwipe(tester, x: 40);

    expect(callsTo('setBrightness'), isNotEmpty, reason: 'the gesture itself stays live without the toggle');
    expect(settings.read(SettingsService.rememberedBrightnessLevel), -1.0);

    await settle(tester);
  });

  testWidgets('a volume swipe never writes the remembered brightness', (tester) async {
    await settings.write(SettingsService.rememberBrightnessLevel, true);

    await pumpControls(tester);
    await edgeSwipe(tester, x: surface.width - 40);

    expect(callsTo('setMediaVolume'), isNotEmpty);
    expect(settings.read(SettingsService.rememberedBrightnessLevel), -1.0);

    await settle(tester);
  });
}

/// Minimal [Player] with a fixed playing state against a 45-minute item.
class _RecordingPlayer implements Player {
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
