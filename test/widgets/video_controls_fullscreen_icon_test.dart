import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:plezy/database/app_database.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/services/fullscreen_state_manager.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/video_volume_controller.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/watch_together/providers/watch_together_provider.dart';
import 'package:plezy/widgets/video_controls/player_chrome_controller.dart';
import 'package:plezy/widgets/video_controls/video_controls.dart';
import 'package:plezy/widgets/video_controls/widgets/player_toast_indicator.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/player_streams.dart';
import '../test_helpers/prefs.dart';
import '../test_helpers/theme.dart';

/// Regression coverage for #2267: the player's fullscreen button kept a private
/// copy of the fullscreen state fed by window_manager's enter/leave callbacks.
/// Windows fullscreen goes through the native Win32 channel instead, so those
/// callbacks never fired and the icon stayed on "enter fullscreen" for the whole
/// session. The button now reads [FullscreenStateManager], which every desktop
/// OS keeps current.
///
/// The pre-fix code seeded and subscribed that copy under `Platform.isMacOS`,
/// which dart:io exposes with no test seam, so these cases only fail against the
/// old code where that is false — which is every CI unit-test run (ubuntu), and
/// not a macOS workstation.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const windowChannel = MethodChannel('window_manager');
  const macWindowChannel = MethodChannel('com.plezy/window_utils');

  late _PlayingPlayer player;
  late PlayerChromeController chrome;
  late PlayerToastController toast;
  late VideoVolumeController volume;
  late PlaybackStateProvider playbackState;
  late WatchTogetherProvider watchTogether;
  late AppDatabase database;
  late ValueNotifier<bool> hasFirstFrame;

  setUp(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await initializeDateFormatting('en');
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    final settings = await SettingsService.getInstance();

    TvDetectionService.debugSetAppleTVOverride(false);
    PlatformDetector.debugSetIsDesktopOSOverride(true);

    // Neither platform side exists under the test binding: the desktop branch of
    // initState asks window_manager for the always-on-top state, and on a macOS
    // host the fullscreen listener and dispose also drive the traffic lights.
    // Unanswered, those calls simply never complete and leave futures dangling.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(windowChannel, (
      call,
    ) async {
      return switch (call.method) {
        'isAlwaysOnTop' || 'isMaximized' => false,
        _ => null,
      };
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(macWindowChannel, (
      call,
    ) async {
      return call.method == 'isFullscreen' ? false : null;
    });

    database = AppDatabase.forTesting(NativeDatabase.memory());
    player = _PlayingPlayer();
    chrome = PlayerChromeController(initiallyVisible: true);
    toast = PlayerToastController();
    volume = VideoVolumeController(player: player, settings: settings, initialVolume: 100);
    playbackState = PlaybackStateProvider();
    watchTogether = WatchTogetherProvider();
    hasFirstFrame = ValueNotifier<bool>(true);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(windowChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(macWindowChannel, null);
    // The manager is a singleton; hand it back windowed.
    FullscreenStateManager().setFullscreen(false);
    TvDetectionService.debugSetAppleTVOverride(null);
    PlatformDetector.debugSetIsDesktopOSOverride(null);
    hasFirstFrame.dispose();
    volume.dispose();
    playbackState.dispose();
    watchTogether.dispose();
    chrome.dispose();
    toast.dispose();
    await database.close();
  });

  Future<void> pumpControls(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
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
              child: PlexVideoControls(
                player: player,
                volumeController: volume,
                metadata: testMediaItem(id: 'fullscreen-icon'),
                toastController: toast,
                chromeController: chrome,
                hasFirstFrame: hasFirstFrame,
                canNavigateMediaItems: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Disarm the auto-hide timer as soon as the chrome is up: flutter_test
    // checks for pending timers before any teardown runs, so a failed
    // expectation below would otherwise bury itself under a timer error.
    chrome.cancelAutoHide();
  }

  void expectEnterFullscreenAffordance() {
    expect(find.byIcon(Symbols.fullscreen_rounded), findsOneWidget);
    expect(find.byIcon(Symbols.fullscreen_exit_rounded), findsNothing);
    expect(find.byTooltip(t.videoControls.fullscreenButton), findsOneWidget);
  }

  void expectExitFullscreenAffordance() {
    expect(find.byIcon(Symbols.fullscreen_exit_rounded), findsOneWidget);
    expect(find.byIcon(Symbols.fullscreen_rounded), findsNothing);
    expect(find.byTooltip(t.videoControls.exitFullscreenButton), findsOneWidget);
  }

  /// Unmount on the happy path so the controls' dispose runs inside the test.
  Future<void> unmountControls(WidgetTester tester) => tester.pumpWidget(const SizedBox.shrink());

  testWidgets('the button opens in the exit state when the window is already fullscreen', (tester) async {
    FullscreenStateManager().setFullscreen(true);

    await pumpControls(tester);

    expectExitFullscreenAffordance();
    await unmountControls(tester);
  });

  testWidgets('a fullscreen transition the window manager never reports still flips the button', (tester) async {
    await pumpControls(tester);
    expectEnterFullscreenAffordance();

    // What the Win32 runner's onFullScreenChanged callback does: window_manager
    // emits nothing for this transition.
    FullscreenStateManager().setFullscreen(true);
    await tester.pumpAndSettle();

    expectExitFullscreenAffordance();

    FullscreenStateManager().setFullscreen(false);
    await tester.pumpAndSettle();

    expectEnterFullscreenAffordance();
    await unmountControls(tester);
  });
}

/// Minimal [Player] reporting steady playback, the state the player settles
/// into once the media is open.
class _PlayingPlayer implements Player {
  @override
  String get playerType => 'mpv';

  @override
  PlayerState get state => PlayerState(
    playing: true,
    position: const Duration(minutes: 5),
    duration: const Duration(minutes: 45),
    seekable: true,
  );

  @override
  PlayerStreams get streams => emptyPlayerStreams();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
