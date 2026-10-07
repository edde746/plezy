import 'package:drift/native.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:plezy/database/app_database.dart';
import 'package:plezy/focus/transport_keys.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/services/fullscreen_state_manager.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/video_volume_controller.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/watch_together/providers/watch_together_provider.dart';
import 'package:plezy/widgets/video_controls/player_chrome_controller.dart';
import 'package:plezy/widgets/video_controls/video_control_button.dart';
import 'package:plezy/widgets/video_controls/video_controls.dart';
import 'package:plezy/widgets/video_controls/widgets/player_toast_indicator.dart';
import 'package:plezy/widgets/video_controls/widgets/timeline_slider.dart';
import 'package:plezy/widgets/video_controls/widgets/video_controls_header.dart';
import 'package:plezy/widgets/video_controls/widgets/video_timeline_bar.dart';
import 'package:plezy/widgets/video_controls/widgets/volume_control.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/player_streams.dart';
import '../test_helpers/prefs.dart';
import '../test_helpers/theme.dart';

/// Regression coverage for #2578: with the desktop chrome up, the controls
/// overlay behind it took every tap no control claimed as a click on the video.
/// A click that missed the seek bar or a button by a few pixels — or landed on
/// a label, a disabled button, or the top bar — paused playback (or hid the
/// chrome with click-to-pause off).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const windowChannel = MethodChannel('window_manager');
  const macWindowChannel = MethodChannel('com.plezy/window_utils');
  const surface = Size(1280, 720);

  late SettingsService settings;
  late _PlayingPlayer player;
  late PlayerChromeController chrome;
  late PlayerToastController toast;
  late VideoVolumeController volume;
  late PlaybackStateProvider playbackState;
  late WatchTogetherProvider watchTogether;
  late AppDatabase database;
  late ValueNotifier<bool> hasFirstFrame;
  late int playPauseRequests;
  late List<Duration> seekRequests;

  setUp(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await initializeDateFormatting('en');
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    settings = await SettingsService.getInstance();

    TvDetectionService.debugSetAppleTVOverride(false);
    PlatformDetector.debugSetIsDesktopOSOverride(true);

    // Neither platform side exists under the test binding; unanswered calls
    // from the desktop branch of initState would leave futures dangling.
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
    playPauseRequests = 0;
    seekRequests = [];
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(windowChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(macWindowChannel, null);
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

  Future<void> pumpControls(WidgetTester tester, {required bool clickTogglesPlayback}) async {
    await settings.write(SettingsService.clickVideoTogglesPlayback, clickTogglesPlayback);
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppDatabase>.value(value: database),
          ChangeNotifierProvider<PlaybackStateProvider>.value(value: playbackState),
          ChangeNotifierProvider<WatchTogetherProvider>.value(value: watchTogether),
        ],
        child: MaterialApp(
          theme: ThemeData(platform: TargetPlatform.linux, extensions: const [testMonoTokens]),
          home: Scaffold(
            body: PlexVideoControls(
              player: player,
              volumeController: volume,
              metadata: testMediaItem(id: 'desktop-click', title: 'Desktop Click'),
              toastController: toast,
              chromeController: chrome,
              hasFirstFrame: hasFirstFrame,
              canNavigateMediaItems: false,
              onPlayPauseRequested: (TransportCommand _) async => playPauseRequests++,
              onSeekRequested: (position) async => seekRequests.add(position),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Keep the chrome up for the whole test; flutter_test also rejects a
    // pending auto-hide timer at teardown.
    chrome.cancelAutoHide();
  }

  /// Unmount on the happy path so the controls' dispose runs inside the test.
  Future<void> unmountControls(WidgetTester tester) => tester.pumpWidget(const SizedBox.shrink());

  /// A single click, then enough time that the next one cannot pair with it
  /// into a double click. Playback and scrub input re-arm the auto-hide timer;
  /// disarm it so the chrome stays up and no timer outlives the test.
  Future<void> click(WidgetTester tester, Offset position) async {
    await tester.tapAt(position);
    await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 100));
    chrome.cancelAutoHide();
  }

  Rect buttonRect(WidgetTester tester, IconData icon) =>
      tester.getRect(find.ancestor(of: find.byIcon(icon), matching: find.byType(VideoControlButton)));

  /// Points inside the chrome bars that no control owns.
  Map<String, Offset> missedClicks(WidgetTester tester) {
    final slider = tester.getRect(find.byType(TimelineSlider));
    final elapsed = tester.getRect(
      find.descendant(of: find.byType(VideoTimelineBar), matching: find.byType(Text)).first,
    );
    final playPause = buttonRect(tester, Symbols.pause_rounded);
    final volumeControl = tester.getRect(find.byType(VolumeControl));
    final header = tester.getRect(find.byType(VideoControlsHeader));
    return {
      'just above the seek bar': Offset(slider.center.dx, slider.top - 3),
      'just below the seek bar': Offset(slider.center.dx, slider.bottom + 3),
      'the elapsed timestamp': elapsed.center,
      // No chapters, so this button is disabled.
      'the disabled next-chapter button': buttonRect(tester, Symbols.fast_forward_rounded).center,
      'the space beside the volume control': Offset(volumeControl.left - 10, playPause.center.dy),
      'the padding under the buttons': Offset(playPause.center.dx, surface.height - 4),
      'the top bar beside the title': Offset(header.center.dx + 200, header.center.dy),
    };
  }

  const videoCentre = Offset(640, 360);

  testWidgets('a click that misses the bar controls does not toggle playback', (tester) async {
    await pumpControls(tester, clickTogglesPlayback: true);

    for (final MapEntry(key: target, value: position) in missedClicks(tester).entries) {
      await click(tester, position);
      expect(playPauseRequests, 0, reason: 'a click on $target toggled playback');
      expect(chrome.controlsVisible, isTrue, reason: 'a click on $target hid the chrome');
    }

    await click(tester, videoCentre);
    expect(playPauseRequests, 1, reason: 'a click on the video itself still toggles playback');

    await unmountControls(tester);
  });

  testWidgets('with click-to-pause off, a click that misses the bar controls keeps the chrome up', (tester) async {
    await pumpControls(tester, clickTogglesPlayback: false);

    for (final MapEntry(key: target, value: position) in missedClicks(tester).entries) {
      await click(tester, position);
      expect(chrome.controlsVisible, isTrue, reason: 'a click on $target hid the chrome');
    }

    await click(tester, videoCentre);
    expect(chrome.controlsVisible, isFalse, reason: 'a click on the video itself still hides the chrome');
    expect(playPauseRequests, 0);

    await unmountControls(tester);
  });

  testWidgets('the bar controls still take their own clicks', (tester) async {
    await pumpControls(tester, clickTogglesPlayback: true);

    await click(tester, buttonRect(tester, Symbols.pause_rounded).center);
    expect(playPauseRequests, 1);

    final slider = tester.getRect(find.byType(TimelineSlider));
    await click(tester, Offset(slider.left + slider.width * 0.75, slider.center.dy));
    await tester.pumpAndSettle();
    expect(seekRequests, isNotEmpty);
    // Three quarters of the 45-minute timeline, give or take the track inset.
    expect(seekRequests.last.inSeconds, closeTo(const Duration(minutes: 45).inSeconds * 0.75, 60));
    expect(playPauseRequests, 1, reason: 'a click on the seek bar also toggled playback');

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
