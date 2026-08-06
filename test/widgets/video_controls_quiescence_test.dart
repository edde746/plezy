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
import 'package:plezy/widgets/video_controls/player_chrome_controller.dart';
import 'package:plezy/widgets/video_controls/video_controls.dart';
import 'package:plezy/widgets/video_controls/widgets/linux_keep_alive.dart';
import 'package:plezy/widgets/video_controls/widgets/player_toast_indicator.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';
import '../test_helpers/theme.dart';

/// Regression coverage for #1707: with the chrome hidden and nothing transient
/// on screen, the player UI must schedule no frames at all. On Windows every
/// scheduled frame becomes a DirectComposition commit, and under fullscreen
/// VRR (FreeSync/G-Sync) each commit forces a scanout off the video's cadence,
/// which the viewer sees as micro-stutter.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();


  group('hidden-chrome frame quiescence', () {
    late _IdlePlayer player;
    late PlayerChromeController chrome;
    late PlayerToastController toast;
    late VideoVolumeController volume;
    late PlaybackStateProvider playbackState;
    late WatchTogetherProvider watchTogether;
    late AppDatabase database;

    setUp(() async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      await initializeDateFormatting('en');
      resetSharedPreferencesForTest();
      SettingsService.resetForTesting();
      final settings = await SettingsService.getInstance();

      TvDetectionService.debugSetAppleTVOverride(true);
      PlatformDetector.debugSetIsDesktopOSOverride(false);

      database = AppDatabase.forTesting(NativeDatabase.memory());
      player = _IdlePlayer();
      chrome = PlayerChromeController();
      toast = PlayerToastController();
      volume = VideoVolumeController(player: player, settings: settings, initialVolume: 100);
      playbackState = PlaybackStateProvider();
      watchTogether = WatchTogetherProvider();
    });

    tearDown(() async {
      LinuxKeepAlive.debugIsLinuxOverride = null;
      TvDetectionService.debugSetAppleTVOverride(null);
      PlatformDetector.debugSetIsDesktopOSOverride(null);
      volume.dispose();
      playbackState.dispose();
      watchTogether.dispose();
      chrome.dispose();
      toast.dispose();
      await database.close();
    });

    Future<void> pumpHiddenChrome(WidgetTester tester) async {
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
                width: 1280,
                height: 720,
                child: PlexVideoControls(
                  player: player,
                  volumeController: volume,
                  metadata: testMediaItem(id: 'quiescence'),
                  toastController: toast,
                  chromeController: chrome,
                  canNavigateMediaItems: false,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      chrome.hide();
      chrome.markControlsHidden();
      chrome.cancelAutoHide();
      await tester.pump();
      expect(chrome.controlsVisible, isFalse);
    }

    testWidgets('the player UI schedules no frames while chrome is hidden', (tester) async {
      LinuxKeepAlive.debugIsLinuxOverride = false;
      await pumpHiddenChrome(tester);

      // Drain the chrome fade-out and any post-frame follow-ups.
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse);

      // Let fake time elapse without pumping: any periodic repaint (like the
      // Linux keep-alive formerly mounted on Windows) would schedule a frame.
      await tester.binding.delayed(const Duration(seconds: 5));
      expect(
        tester.binding.hasScheduledFrame,
        isFalse,
        reason: 'the player UI must stay frame-quiescent while chrome is hidden (#1707)',
      );

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Linux still repaints to keep its frame clock alive', (tester) async {
      LinuxKeepAlive.debugIsLinuxOverride = true;
      await pumpHiddenChrome(tester);

      // Drive the fade to completion with bounded pumps; pumpAndSettle would
      // never settle against the keep-alive's own repaints.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      await tester.binding.delayed(const Duration(milliseconds: 250));
      expect(
        tester.binding.hasScheduledFrame,
        isTrue,
        reason: 'the GTK frame clock workaround must keep scheduling frames on Linux',
      );

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}

/// Minimal [Player] that stays paused-forever idle so the controls have no
/// stream activity to react to — the state a real hidden-chrome session is in.
class _IdlePlayer implements Player {
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
