import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:plezy/database/app_database.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_item.dart';
import 'package:plezy/models/player_setting_scope.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/services/scoped_player_prefs.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/video_volume_controller.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/watch_together/providers/watch_together_provider.dart';
import 'package:plezy/widgets/video_controls/models/track_controls_state.dart';
import 'package:plezy/widgets/video_controls/player_chrome_controller.dart';
import 'package:plezy/widgets/video_controls/video_controls.dart';
import 'package:plezy/widgets/video_controls/widgets/player_toast_indicator.dart';
import 'package:plezy/widgets/video_controls/widgets/track_chapter_controls.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';
import '../test_helpers/theme.dart';

/// The sync-offset display must resolve through the same scope the write and
/// the player-apply path use. With "Scope sync offsets" set to Title, a scoped
/// write previously stored into [SettingsService.scopedPlayerPrefValues] while
/// the chrome kept reading the untouched global pref: the sheet rows showed
/// 0 ms and the sync slider seeded from centre while mpv was applying the
/// stored offset, so the first nudge jumped by the whole stored amount.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SettingsService settings;
  late _IdlePlayer player;
  late PlayerChromeController chrome;
  late PlayerToastController toast;
  late VideoVolumeController volume;
  late PlaybackStateProvider playbackState;
  late WatchTogetherProvider watchTogether;
  late AppDatabase database;

  // A movie with a server id, so the title scope has the identity it keys by.
  final MediaItem metadata = testMediaItem(id: 'sync-offset-scope', serverId: 'server-a');

  setUp(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await initializeDateFormatting('en');
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    settings = await SettingsService.getInstance();

    // Phone layout: the chrome mounts TrackChapterControls in the top bar.
    TvDetectionService.debugSetAppleTVOverride(false);
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
    TvDetectionService.debugSetAppleTVOverride(null);
    PlatformDetector.debugSetIsDesktopOSOverride(null);
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
          theme: ThemeData(platform: TargetPlatform.android, extensions: const [testMonoTokens]),
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: PlexVideoControls(
                player: player,
                volumeController: volume,
                metadata: metadata,
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
    expect(find.byType(TrackChapterControls), findsOneWidget);
  }

  /// The state the visible chrome feeds both the sheet rows (displayed value,
  /// highlight) and the sync slider seed ([TrackControlsState.audioSyncOffset]
  /// is what VideoSettingsSheet reads into its `initialOffset`).
  TrackControlsState displayedTrackState(WidgetTester tester) =>
      tester.widget<TrackChapterControls>(find.byType(TrackChapterControls)).trackControlsState;

  /// Disarm the auto-hide timer and unmount so the pending-timer check at the
  /// end of the test stays honest.
  Future<void> unmountControls(WidgetTester tester) async {
    chrome.cancelAutoHide();
    await tester.pumpWidget(const SizedBox.shrink());
  }

  testWidgets('a title-scoped write updates the displayed offsets and slider seed', (tester) async {
    await settings.write(SettingsService.syncOffsetScope, PlayerSettingScope.title);
    await pumpControls(tester);

    expect(displayedTrackState(tester).audioSyncOffset, 0);
    expect(displayedTrackState(tester).subtitleSyncOffset, 0);

    await ScopedPlayerPrefs.write(ScopedPlayerPrefs.audioSyncOffset, metadata, -400);
    await ScopedPlayerPrefs.write(ScopedPlayerPrefs.subtitleSyncOffset, metadata, 150);
    await tester.pump();

    final state = displayedTrackState(tester);
    expect(state.audioSyncOffset, -400, reason: 'display and slider seed must read the title-scoped store');
    expect(state.subtitleSyncOffset, 150);
    expect(
      settings.read(SettingsService.audioSyncOffset),
      0,
      reason: 'the scoped write never touches the global pref, so a global read would show 0 ms',
    );

    await unmountControls(tester);
  });

  testWidgets('switching the sync-offset scope re-resolves the displayed offsets', (tester) async {
    await settings.write(SettingsService.syncOffsetScope, PlayerSettingScope.title);
    await ScopedPlayerPrefs.write(ScopedPlayerPrefs.audioSyncOffset, metadata, -400);
    await settings.write(SettingsService.audioSyncOffset, 75);
    await pumpControls(tester);

    expect(displayedTrackState(tester).audioSyncOffset, -400);

    await settings.write(SettingsService.syncOffsetScope, PlayerSettingScope.global);
    await tester.pump();

    expect(
      displayedTrackState(tester).audioSyncOffset,
      75,
      reason: 'a scope change alone must rebuild the chrome and re-resolve against the new scope',
    );

    await unmountControls(tester);
  });
}

/// Minimal [Player] with static state so the controls have no stream activity
/// to react to; rebuilds in these tests can then only come from settings
/// notifications.
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
