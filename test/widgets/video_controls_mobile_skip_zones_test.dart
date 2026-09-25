import 'dart:async';
import 'package:drift/native.dart';
import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
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
import 'package:plezy/widgets/video_controls/player_chrome_controller.dart';
import 'package:plezy/widgets/video_controls/video_controls.dart';
import 'package:plezy/widgets/video_controls/widgets/double_tap_feedback.dart';
import 'package:plezy/widgets/video_controls/widgets/player_toast_indicator.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';
import '../test_helpers/theme.dart';

/// A skip in the mobile skip zones costs one full same-direction double tap.
///
/// An earlier revision let the leftover skip badge stand in for an armed state,
/// so every later lone tap seeked: the side zones — nearly half the picture —
/// could not raise the chrome for as long as the badge stayed up, and a badge
/// raised by a keyboard or remote seek armed one-tap seeking on the touch
/// surface with no double tap at all.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingPlayer player;
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
    await settings.write(SettingsService.seekTimeSmall, 10);

    // Phone layout: the skip zones only exist when PlatformDetector.isMobile.
    TvDetectionService.debugSetAppleTVOverride(false);
    PlatformDetector.debugSetIsDesktopOSOverride(false);

    database = AppDatabase.forTesting(NativeDatabase.memory());
    player = _RecordingPlayer();
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

  // Derived from the laid-out player rather than hard-coded, so the cases
  // survive a change of test surface. mobileSkipZoneDimensions: each side zone
  // is 35% of the width, excluding the top and bottom 15% of the height.
  const surface = Size(800, 600);

  Offset forwardZoneOf(WidgetTester tester) {
    final rect = tester.getRect(find.byType(PlexVideoControls));
    return Offset(rect.right - rect.width * 0.1, rect.center.dy);
  }

  Offset backwardZoneOf(WidgetTester tester) {
    final rect = tester.getRect(find.byType(PlexVideoControls));
    return Offset(rect.left + rect.width * 0.1, rect.center.dy);
  }

  Offset neutralZoneOf(WidgetTester tester) => tester.getRect(find.byType(PlexVideoControls)).center;

  Future<void> pumpControls(WidgetTester tester, {bool isLive = false}) async {
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
                metadata: testMediaItem(id: 'mobile-skip-zones'),
                toastController: toast,
                chromeController: chrome,
                canNavigateMediaItems: false,
                isLive: isLive,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    // Every case starts from hidden chrome — the state the skip zones own.
    chrome.hide();
    chrome.markControlsHidden();
    await tester.pump();
    expect(chrome.controlsVisible, isFalse);
  }

  /// Two taps inside [kDoubleTapTimeout], which pair into one skip.
  ///
  /// Pairing runs off `_singleTapTimer`, a fake-clock timer, so the pumped
  /// durations here are the real contract and not decoration — see the
  /// pairing-window cases below.
  Future<void> doubleTap(WidgetTester tester, Offset zone) async {
    await tester.tapAt(zone);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(zone);
    await tester.pump();
  }

  /// One tap, then past [kDoubleTapTimeout] so the deferred lone-tap action
  /// fires.
  Future<void> loneTap(WidgetTester tester, Offset zone) async {
    await tester.tapAt(zone);
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> settleFeedback(WidgetTester tester) async {
    chrome.cancelAutoHide();
    toast.hide();
    await tester.pumpWidget(const SizedBox.shrink());
  }

  testWidgets('a double tap in the forward zone skips once', (tester) async {
    await pumpControls(tester);

    await doubleTap(tester, forwardZoneOf(tester));

    expect(player.seeks, [const Duration(minutes: 10, seconds: 10)]);
    expect(find.text('10s'), findsOneWidget);
    expect(chrome.controlsVisible, isFalse, reason: 'skipping must not raise the chrome');

    await settleFeedback(tester);
  });

  testWidgets('a live stream without a capture buffer is not seeked by a double tap', (tester) async {
    await pumpControls(tester, isLive: true);

    await doubleTap(tester, forwardZoneOf(tester));
    await doubleTap(tester, backwardZoneOf(tester));

    expect(player.seeks, isEmpty, reason: 'there is no seekable window behind the live edge');

    await settleFeedback(tester);
  });

  testWidgets('a double tap in the backward zone rewinds once', (tester) async {
    await pumpControls(tester);

    await doubleTap(tester, backwardZoneOf(tester));

    expect(player.seeks, [const Duration(minutes: 9, seconds: 50)]);
    expect(find.text('10s'), findsOneWidget);

    await settleFeedback(tester);
  });

  testWidgets('a lone tap after a skip toggles the chrome instead of skipping again', (tester) async {
    await pumpControls(tester);

    await doubleTap(tester, forwardZoneOf(tester));
    expect(player.seeks.length, 1);
    // The badge is still up. It is a readout, not an armed state.
    expect(find.byType(DoubleTapFeedback), findsOneWidget);

    await loneTap(tester, forwardZoneOf(tester));

    expect(player.seeks.length, 1, reason: 'a single tap must never seek');
    expect(chrome.controlsVisible, isTrue, reason: 'a single tap in a skip zone toggles the chrome');

    await settleFeedback(tester);
  });

  testWidgets('a second tap just inside the pairing window skips', (tester) async {
    await pumpControls(tester);

    await tester.tapAt(forwardZoneOf(tester));
    await tester.pump(kDoubleTapTimeout - const Duration(milliseconds: 1));
    await tester.tapAt(forwardZoneOf(tester));
    await tester.pump();

    expect(player.seeks, [const Duration(minutes: 10, seconds: 10)]);
    expect(chrome.controlsVisible, isFalse);

    await settleFeedback(tester);
  });

  testWidgets('a second tap just past the pairing window does not skip', (tester) async {
    await pumpControls(tester);

    await tester.tapAt(forwardZoneOf(tester));
    await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 1));
    // The window closed, so the first tap already resolved as a lone tap.
    expect(chrome.controlsVisible, isTrue);

    await tester.tapAt(forwardZoneOf(tester));
    await tester.pump();

    expect(player.seeks, isEmpty, reason: 'two taps a window apart are two lone taps, not a skip');

    await settleFeedback(tester);
  });

  testWidgets('an uninterrupted tap stream pairs into one skip per two taps', (tester) async {
    await pumpControls(tester);

    // Six taps, nothing between them. Pairs must not overlap: taps 1+2, 3+4 and
    // 5+6 each buy one skip, and no tap is left over to toggle the chrome.
    final skipped = <bool>[];
    for (var i = 0; i < 6; i++) {
      final before = player.seeks.length;
      await tester.tapAt(forwardZoneOf(tester));
      await tester.pump();
      skipped.add(player.seeks.length > before);
    }

    expect(skipped, [false, true, false, true, false, true]);
    expect(player.seeks, [
      const Duration(minutes: 10, seconds: 10),
      const Duration(minutes: 10, seconds: 20),
      const Duration(minutes: 10, seconds: 30),
    ]);
    expect(find.text('30s'), findsOneWidget, reason: 'consecutive skips accumulate into one readout');

    // The last tap completed a pair, so nothing is pending to raise the chrome.
    await tester.pump(const Duration(milliseconds: 400));
    expect(chrome.controlsVisible, isFalse);

    await settleFeedback(tester);
  });

  testWidgets('a double tap at the end of the item reports only the distance left', (tester) async {
    // #2425: five seconds from the end, a 10s skip travels five. The readout
    // says so, and a second pair at the end adds nothing to it — and dispatches
    // nothing: a seek to the position already occupied would re-poke the
    // end-of-item trigger and announce itself to a Watch Together room.
    player.setPosition(const Duration(minutes: 44, seconds: 55));
    await pumpControls(tester);

    await doubleTap(tester, forwardZoneOf(tester));
    expect(player.seeks, [const Duration(minutes: 45)]);
    expect(find.text('5s'), findsOneWidget);

    await doubleTap(tester, forwardZoneOf(tester));
    expect(find.text('5s'), findsOneWidget, reason: 'nothing left to skip through');
    expect(find.text('15s'), findsNothing);
    expect(player.seeks, [const Duration(minutes: 45)], reason: 'a tap that travels nothing must not seek');

    await settleFeedback(tester);
  });

  testWidgets('a backward double tap at the start neither seeks nor raises a badge', (tester) async {
    player.setPosition(Duration.zero);
    await pumpControls(tester);

    await doubleTap(tester, backwardZoneOf(tester));

    expect(player.seeks, isEmpty);
    expect(find.byType(DoubleTapFeedback), findsNothing, reason: 'a 0s badge would describe a seek not happening');
    expect(chrome.controlsVisible, isFalse, reason: 'the pair still counts as a skip attempt, not a chrome toggle');

    await settleFeedback(tester);
  });

  testWidgets('a position reported past the end counts as the end', (tester) async {
    // The duration is authoritative; a playhead reported beyond it is a
    // reporting artifact. A forward tap there has nowhere to go and must not
    // clamp backwards under a forward chevron; a backward tap travels its full
    // step from the end itself.
    player.setPosition(const Duration(minutes: 45, milliseconds: 500));
    await pumpControls(tester);

    await doubleTap(tester, forwardZoneOf(tester));
    expect(player.seeks, isEmpty);
    expect(find.byType(DoubleTapFeedback), findsNothing);

    await doubleTap(tester, backwardZoneOf(tester));
    expect(player.seeks, [const Duration(minutes: 44, seconds: 50)]);
    expect(find.text('10s'), findsOneWidget);

    await settleFeedback(tester);
  });

  testWidgets('an odd tap left over by a tap stream toggles the chrome', (tester) async {
    await pumpControls(tester);

    for (var i = 0; i < 5; i++) {
      await tester.tapAt(forwardZoneOf(tester));
      await tester.pump();
    }

    expect(player.seeks.length, 2, reason: 'five taps buy two skips');
    expect(chrome.controlsVisible, isFalse, reason: 'the fifth tap is still waiting for a partner');

    await tester.pump(const Duration(milliseconds: 400));
    expect(chrome.controlsVisible, isTrue, reason: 'the unpaired tap resolves as a lone tap');
    expect(player.seeks.length, 2);

    await settleFeedback(tester);
  });

  testWidgets('a keyboard seek does not arm one-tap seeking on the touch surface', (tester) async {
    await pumpControls(tester);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(player.seeks.length, 1);
    expect(find.byType(DoubleTapFeedback), findsOneWidget);

    await loneTap(tester, forwardZoneOf(tester));

    expect(player.seeks.length, 1, reason: 'the badge a keyboard seek raised must not make a lone tap seek');

    await settleFeedback(tester);
  });

  testWidgets('a media-key seek does not arm one-tap seeking either', (tester) async {
    await pumpControls(tester);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.mediaFastForward);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.mediaFastForward);
    await tester.pump();
    expect(find.byType(DoubleTapFeedback), findsOneWidget, reason: 'the media key raised the readout');
    final seeksBefore = player.seeks.length;

    await loneTap(tester, forwardZoneOf(tester));

    expect(player.seeks.length, seeksBefore, reason: 'a lone tap is not a skip');

    await settleFeedback(tester);
  });

  testWidgets('a double tap keeps its own readout while a keyboard burst is pending', (tester) async {
    // Both input paths share one badge. The tap's seek is foreign to the
    // keyboard accumulator, so retiring that burst must not take down the
    // readout the tap just raised.
    await pumpControls(tester);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(find.byType(DoubleTapFeedback), findsOneWidget);

    await doubleTap(tester, forwardZoneOf(tester));

    expect(find.byType(DoubleTapFeedback), findsOneWidget, reason: 'the tap that just seeked owns the readout now');
    expect(find.text('10s'), findsOneWidget, reason: 'and it counts only its own step');

    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await settleFeedback(tester);
  });

  testWidgets('a lone tap in the opposite zone does not skip', (tester) async {
    await pumpControls(tester);

    await doubleTap(tester, forwardZoneOf(tester));
    expect(player.seeks.length, 1);

    await loneTap(tester, backwardZoneOf(tester));

    expect(player.seeks.length, 1);

    await settleFeedback(tester);
  });

  testWidgets('taps split across the two zones never pair into a skip', (tester) async {
    await pumpControls(tester);

    await tester.tapAt(forwardZoneOf(tester));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(backwardZoneOf(tester));
    await tester.pump(const Duration(milliseconds: 400));

    expect(player.seeks, isEmpty, reason: 'both halves of a double tap must land in one direction');

    await settleFeedback(tester);
  });

  testWidgets('a lone tap outside the skip zones toggles the chrome', (tester) async {
    await pumpControls(tester);

    await loneTap(tester, neutralZoneOf(tester));

    expect(player.seeks, isEmpty);
    expect(chrome.controlsVisible, isTrue);

    await settleFeedback(tester);
  });
}

/// Minimal [Player] recording seek targets against a fixed 45-minute item.
class _RecordingPlayer implements Player {
  final List<Duration> seeks = [];
  final StreamController<Duration?> _jumpController = StreamController<Duration?>.broadcast();

  bool _playing = true;
  Duration _position = const Duration(minutes: 10);

  void setPosition(Duration value) => _position = value;

  @override
  String get playerType => 'mpv';

  @override
  PlayerState get state =>
      PlayerState(playing: _playing, position: _position, duration: const Duration(minutes: 45), seekable: true);

  @override
  PlayerStreams get streams => PlayerStreams(
    playheadJump: _jumpController.stream,
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
  Future<void> seek(Duration position) async {
    seeks.add(position);
    _position = position;
    _jumpController.add(position);
  }

  @override
  Future<void> dispose({bool preserveDisplayMode = false}) async {
    await _jumpController.close();
  }

  @override
  Future<void> play() async => _playing = true;

  @override
  Future<void> pause() async => _playing = false;

  @override
  Future<void> playOrPause() async => _playing = !_playing;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
