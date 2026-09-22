import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:plezy/database/app_database.dart';
import 'package:plezy/focus/input_mode_tracker.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/providers/playback_state_provider.dart';
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

/// The screen's first-frame gate outlives the controls: a failed open swaps
/// the controls for the failure view, and Retry flips the gate again. The
/// controls used to leave their first-frame listener behind on it (2.20.0,
/// "Null check operator used on a null value" from a defunct controls state
/// reading `context` in `_loadPlaybackExtras`), so every later flip ran on a
/// widget that no longer existed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _StillPlayer player;
  late PlayerChromeController chrome;
  late PlayerToastController toast;
  late VideoVolumeController volume;
  late PlaybackStateProvider playbackState;
  late WatchTogetherProvider watchTogether;
  late AppDatabase database;
  late _Gate hasFirstFrame;

  setUp(() async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await initializeDateFormatting('en');
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    final settings = await SettingsService.getInstance();
    PlatformDetector.debugSetIsDesktopOSOverride(true);

    database = AppDatabase.forTesting(NativeDatabase.memory());
    player = _StillPlayer();
    chrome = PlayerChromeController();
    toast = PlayerToastController();
    volume = VideoVolumeController(player: player, settings: settings, initialVolume: 100);
    playbackState = PlaybackStateProvider();
    watchTogether = WatchTogetherProvider();
    hasFirstFrame = _Gate();
  });

  tearDown(() async {
    PlatformDetector.debugSetIsDesktopOSOverride(null);
    hasFirstFrame.dispose();
    volume.dispose();
    playbackState.dispose();
    watchTogether.dispose();
    chrome.dispose();
    toast.dispose();
    await player.close();
    await database.close();
  });

  Widget shell(Widget child) => InputModeTracker(
    child: MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        ChangeNotifierProvider<PlaybackStateProvider>.value(value: playbackState),
        ChangeNotifierProvider<WatchTogetherProvider>.value(value: watchTogether),
      ],
      child: MaterialApp(
        theme: ThemeData(platform: TargetPlatform.windows, extensions: const [testMonoTokens]),
        home: Scaffold(body: SizedBox(width: 1280, height: 720, child: child)),
      ),
    ),
  );

  testWidgets('unmounted controls no longer listen to the first-frame gate', (tester) async {
    await tester.pumpWidget(
      shell(
        PlexVideoControls(
          player: player,
          volumeController: volume,
          metadata: testMediaItem(id: 'gate'),
          toastController: toast,
          chromeController: chrome,
          hasFirstFrame: hasFirstFrame,
          canNavigateMediaItems: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(hasFirstFrame.isListened, isTrue, reason: 'precondition: mounted controls follow the gate');

    // The failure view replacing the player subtree.
    await tester.pumpWidget(shell(const SizedBox.expand()));
    await tester.pumpAndSettle();
    expect(hasFirstFrame.isListened, isFalse, reason: 'dispose must release the listener it registered');

    // Retry: the reload resets the gate and the retried open (or its rollback) raises it again.
    hasFirstFrame.value = false;
    hasFirstFrame.value = true;
    await tester.pump();
    expect(tester.takeException(), isNull, reason: 'no defunct controls state may run on the gate');
    chrome.cancelAutoHide();
  });
}

class _Gate extends ValueNotifier<bool> {
  _Gate() : super(true);

  bool get isListened => hasListeners;
}

/// A [Player] that never moves; the controls only need its streams to exist.
class _StillPlayer implements Player {
  final StreamController<bool> _playingController = StreamController<bool>.broadcast();

  Future<void> close() => _playingController.close();

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
  Future<void> seek(Duration position) async {}

  @override
  PlayerStreams get streams => PlayerStreams(
    playing: _playingController.stream,
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
