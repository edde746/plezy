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
import 'package:plezy/services/player_sync_offsets.dart';
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

/// The sync-offset display follows the offset the player applies, not the
/// stored pref. Under "Don't save" nothing is stored, so a display that read
/// the pref showed 0 ms while mpv applied the viewer's change, and the sync
/// slider seeded from centre (#2069).
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

  testWidgets('a "Don\'t save" offset shows while applied and clears on the next item', (tester) async {
    await settings.write(SettingsService.syncOffsetScope, PlayerSettingScope.off);
    await pumpControls(tester);
    final offsets = PlayerSyncOffsets.of(player);

    // What SyncOffsetControl records after its native write.
    offsets.recordApplied(PlayerSyncOffsets.subtitleProperty, 500);
    await tester.pump();

    expect(
      displayedTrackState(tester).subtitleSyncOffset,
      500,
      reason: 'display and slider seed show the applied offset',
    );
    expect(settings.read(SettingsService.subtitleSyncOffset), 0, reason: '"Don\'t save" stores nothing');

    await offsets.applyFor(testMediaItem(id: 'next-item', serverId: 'server-a'));
    await tester.pump();

    expect(displayedTrackState(tester).subtitleSyncOffset, 0);

    await unmountControls(tester);
  });
}

/// Minimal [Player] with static state so the controls have no stream activity
/// to react to; rebuilds in these tests can then only come from the offsets.
class _IdlePlayer implements Player {
  @override
  Future<void> setProperty(String name, String value) async {}

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
