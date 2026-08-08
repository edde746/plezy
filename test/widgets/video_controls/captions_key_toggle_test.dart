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
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/video_volume_controller.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/watch_together/providers/watch_together_provider.dart';
import 'package:plezy/widgets/overlay_sheet.dart';
import 'package:plezy/widgets/video_controls/player_chrome_controller.dart';
import 'package:plezy/widgets/video_controls/sheets/track_sheet.dart';
import 'package:plezy/widgets/video_controls/sheets/video_settings_sheet.dart';
import 'package:plezy/widgets/video_controls/video_controls.dart';
import 'package:plezy/widgets/video_controls/widgets/player_toast_indicator.dart';

import '../../test_helpers/media_items.dart';
import '../../test_helpers/prefs.dart';
import '../../test_helpers/theme.dart';

/// The Android TV remote's subtitles/CC button (KEYCODE_CAPTIONS) arrives
/// through Flutter's framework as [LogicalKeyboardKey.closedCaptionToggle] and
/// must toggle subtitle visibility, dismissing an open tracks sheet instead.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CAPTIONS key', () {
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

      // Fake a TV device so the player chrome renders the TV layout and the
      // controls' device-adjustment probe (mobile-only) is skipped.
      TvDetectionService.debugSetAppleTVOverride(true);
      PlatformDetector.debugSetIsDesktopOSOverride(false);

      database = AppDatabase.forTesting(NativeDatabase.memory());
      player = _CaptionsPlayer();
      chrome = PlayerChromeController(initiallyVisible: true);
      toast = PlayerToastController();
      volume = VideoVolumeController(player: player, settings: settings, initialVolume: 100);
      playbackState = PlaybackStateProvider();
      watchTogether = WatchTogetherProvider();
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
            body: SizedBox(width: 1280, height: 720, child: OverlaySheetHost(child: child)),
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

    /// Presses the Android TV remote's subtitles/CC button (KEYCODE_CAPTIONS),
    /// which the Flutter engine maps to [LogicalKeyboardKey.closedCaptionToggle].
    Future<void> pressCaptionsKey(WidgetTester tester) async {
      await tester.sendKeyDownEvent(
        LogicalKeyboardKey.closedCaptionToggle,
        physicalKey: PhysicalKeyboardKey.closedCaptionToggle,
        platform: 'android',
      );
      await tester.pump();
    }

    testWidgets('toggles subtitle visibility off, then back on', (tester) async {
      await pumpControls(tester);

      await pressCaptionsKey(tester);
      expect(player.subtitleVisibilityWrites, ['no']);

      await pressCaptionsKey(tester);
      expect(player.subtitleVisibilityWrites, ['no', 'yes']);

      chrome.cancelAutoHide();
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('closes an open tracks sheet', (tester) async {
      await pumpControls(tester);
      await tester.tap(find.byTooltip(t.videoControls.tracksButton));
      await tester.pumpAndSettle();
      expect(find.byType(TrackSheet), findsOneWidget);

      await pressCaptionsKey(tester);
      await tester.pumpAndSettle();
      expect(find.byType(TrackSheet), findsNothing);

      chrome.cancelAutoHide();
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('leaves a non-tracks sheet open', (tester) async {
      await pumpControls(tester);
      await tester.tap(find.byTooltip(t.videoControls.settingsButton));
      await tester.pumpAndSettle();
      expect(find.byType(VideoSettingsSheet), findsOneWidget);

      await pressCaptionsKey(tester);
      await tester.pumpAndSettle();
      expect(find.byType(VideoSettingsSheet), findsOneWidget);

      // Disposing the host completes the sheet's future, whose whenComplete
      // restarts the hide timer — cancel it after disposal so no timer lingers.
      await tester.pumpWidget(const SizedBox.shrink());
      chrome.cancelAutoHide();
    });

    testWidgets('has no effect while the player controls are unmounted', (tester) async {
      await pressCaptionsKey(tester);

      expect(player.subtitleVisibilityWrites, isEmpty);
      expect(find.byType(TrackSheet), findsNothing);
    });
  });
}

/// Minimal [Player] reporting steady playback with one embedded subtitle track
/// and recording subtitle-visibility writes.
class _CaptionsPlayer implements Player {
  final List<String> subtitleVisibilityWrites = [];

  @override
  String get playerType => 'mpv';

  @override
  bool get supportsSecondarySubtitles => false;

  @override
  PlayerState get state => const PlayerState(
    playing: true,
    duration: Duration(minutes: 45),
    seekable: true,
    tracks: Tracks(
      subtitle: [SubtitleTrack(id: 's1', title: 'English')],
    ),
    track: TrackSelection(
      subtitle: SubtitleTrack(id: 's1', title: 'English'),
    ),
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
  Future<void> setProperty(String name, String value) async {
    if (name == 'sub-visibility') subtitleVisibilityWrites.add(value);
  }

  @override
  Future<String?> getProperty(String name) async => null;

  @override
  Future<AudioRenderingMode?> getAudioRenderingMode() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
