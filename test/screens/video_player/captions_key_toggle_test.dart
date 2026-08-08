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
import 'package:plezy/services/captions_service.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/video_volume_controller.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/watch_together/providers/watch_together_provider.dart';
import 'package:plezy/widgets/overlay_sheet.dart';
import 'package:plezy/widgets/video_controls/player_chrome_controller.dart';
import 'package:plezy/widgets/video_controls/sheets/track_sheet.dart';
import 'package:plezy/widgets/video_controls/video_controls.dart';
import 'package:plezy/widgets/video_controls/widgets/player_toast_indicator.dart';

import '../../test_helpers/media_items.dart';
import '../../test_helpers/prefs.dart';
import '../../test_helpers/theme.dart';

/// The Android TV remote's subtitles/CC button (KEYCODE_CAPTIONS) must toggle
/// the player's subtitle selector sheet: a press opens it, a second press
/// closes it. The native activity forwards the key over `com.plezy/captions`,
/// which [CaptionsService] bridges to the mounted player controls.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CAPTIONS key toggles the subtitle selector', () {
    late _CaptionsPlayer player;
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
      player = _CaptionsPlayer();
      chrome = PlayerChromeController(initiallyVisible: true);
      toast = PlayerToastController();
      volume = VideoVolumeController(player: player, settings: settings, initialVolume: 100);
      playbackState = PlaybackStateProvider();
      watchTogether = WatchTogetherProvider();
      CaptionsService();
    });

    tearDown(() async {
      CaptionsService.onToggleSubtitleSelector = null;
      TvDetectionService.debugSetAppleTVOverride(null);
      PlatformDetector.debugSetIsDesktopOSOverride(null);
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
              child: OverlaySheetHost(child: child),
            ),
          ),
        ),
      );
    }

    Future<void> pumpControls(WidgetTester tester) async {
      await tester.pumpWidget(
        shell(
          PlexVideoControls(
            player: player,
            volumeController: volume,
            metadata: testMediaItem(id: 'captions-key'),
            toastController: toast,
            chromeController: chrome,
            canNavigateMediaItems: false,
          ),
        ),
      );
      await tester.pump();
    }

    /// Simulates the native activity's `com.plezy/captions` invocation.
    Future<void> pressCaptionsKey(WidgetTester tester) async {
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'com.plezy/captions',
        const StandardMethodCodec().encodeMethodCall(const MethodCall('toggleSubtitleSelector')),
        (_) {},
      );
      await tester.pump();
    }

    testWidgets('a CAPTIONS press opens the subtitle selector', (tester) async {
      await pumpControls(tester);
      expect(find.byType(TrackSheet), findsNothing);

      await pressCaptionsKey(tester);

      expect(find.byType(TrackSheet), findsOneWidget);

      chrome.cancelAutoHide();
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a second CAPTIONS press closes the subtitle selector', (tester) async {
      await pumpControls(tester);

      await pressCaptionsKey(tester);
      expect(find.byType(TrackSheet), findsOneWidget);

      await pressCaptionsKey(tester);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TrackSheet), findsNothing);

      chrome.cancelAutoHide();
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('CAPTIONS has no effect while the player controls are unmounted', (tester) async {
      await pressCaptionsKey(tester);
      await tester.pump();

      expect(find.byType(TrackSheet), findsNothing);
    });
  });
}

/// Minimal [Player] reporting steady playback with one embedded subtitle track,
/// the state a live subtitle selector needs.
class _CaptionsPlayer implements Player {
  @override
  String get playerType => 'mpv';

  @override
  bool get supportsSecondarySubtitles => false;

  @override
  PlayerState get state => const PlayerState(
    playing: true,
    duration: Duration(minutes: 45),
    seekable: true,
    tracks: Tracks(subtitle: [SubtitleTrack(id: 's1', title: 'English')]),
    track: TrackSelection(subtitle: SubtitleTrack(id: 's1', title: 'English')),
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
  dynamic noSuchMethod(Invocation invocation) => null;
}
