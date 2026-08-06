import 'dart:async';
import 'dart:math' as math;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:plezy/database/app_database.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/media/media_source_info.dart';
import 'package:plezy/mpv/mpv.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/video_volume_controller.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/watch_together/providers/watch_together_provider.dart';
import 'package:plezy/widgets/video_controls/player_chrome_controller.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:plezy/widgets/video_controls/desktop_video_controls.dart';
import 'package:plezy/widgets/video_controls/video_controls.dart';
import 'package:plezy/widgets/video_controls/widgets/double_tap_feedback.dart';
import 'package:plezy/widgets/video_controls/widgets/player_toast_indicator.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/widgets/video_controls/widgets/transport_feedback_indicator.dart';

import '../test_helpers/media_items.dart';
import '../test_helpers/prefs.dart';
import '../test_helpers/theme.dart';

/// Regression coverage for #1676: remote/keyboard seeking and pausing must
/// drive playback through a transient badge instead of raising the full player
/// chrome, which covers the subtitles the user is trying to read.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('transient player feedback', () {
    late _RecordingPlayer player;
    late PlayerChromeController chrome;
    late PlayerToastController toast;
    late VideoVolumeController volume;
    late PlaybackStateProvider playbackState;
    late WatchTogetherProvider watchTogether;
    late AppDatabase database;
    late List<TransportCommand> transportCommands;

    setUp(() async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      await initializeDateFormatting('en');
      resetSharedPreferencesForTest();
      SettingsService.resetForTesting();
      final settings = await SettingsService.getInstance();
      await settings.write(SettingsService.seekTimeSmall, 10);
      await settings.write(SettingsService.rewindOnResume, 5);

      // Android TV: PlatformDetector.isTV() drives both the directional-seek
      // branch and the videoPlayerNavigationEnabled default.
      TvDetectionService.debugSetAppleTVOverride(true);
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
      await player.dispose();
    });

    Future<void> pumpControls(
      WidgetTester tester, {
      List<MediaChapter>? chapters,
      bool wireTransportCallback = false,
      bool isLive = false,
      ValueChanged<int>? onLiveSeekBy,
      String itemId = 'transient-feedback',
    }) async {
      transportCommands = [];
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
                  metadata: testMediaItem(id: itemId),
                  toastController: toast,
                  chromeController: chrome,
                  initialChapters: chapters,
                  canNavigateMediaItems: false,
                  isLive: isLive,
                  onLiveSeekBy: onLiveSeekBy,
                  onPlayPauseRequested: wireTransportCallback
                      ? (command) async {
                          transportCommands.add(command);
                          await switch (command) {
                            TransportCommand.play => player.play(),
                            TransportCommand.pause => player.pause(),
                            TransportCommand.toggle => player.playOrPause(),
                          };
                        }
                      : null,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      // Every case below starts from hidden chrome — the state the issue is about.
      chrome.hide();
      chrome.markControlsHidden();
      await tester.pump();
      expect(chrome.controlsVisible, isFalse);
    }

    Future<void> settleFeedback(WidgetTester tester) async {
      chrome.cancelAutoHide();
      toast.hide();
      await tester.pumpWidget(const SizedBox.shrink());
    }

    testWidgets('a right-arrow tap seeks without raising the chrome', (tester) async {
      await pumpControls(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(chrome.controlsVisible, isFalse, reason: 'seeking must not cover the picture');
      expect(find.byType(DoubleTapFeedback), findsOneWidget);
      expect(find.text('10s'), findsOneWidget);

      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(chrome.controlsVisible, isFalse);
      expect(player.seeks, [const Duration(minutes: 10, seconds: 10)]);

      await settleFeedback(tester);
    });

    testWidgets('repeated taps in one direction stack into a running total', (tester) async {
      await pumpControls(tester);

      for (var i = 0; i < 3; i++) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
      }

      expect(find.text('30s'), findsOneWidget);
      expect(chrome.controlsVisible, isFalse);

      await settleFeedback(tester);
    });

    testWidgets('flipping direction restarts the badge count', (tester) async {
      await pumpControls(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(find.text('10s'), findsOneWidget);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      expect(find.text('10s'), findsOneWidget, reason: 'the reverse burst is counted on its own');
      expect(chrome.controlsVisible, isFalse);

      await settleFeedback(tester);
    });

    testWidgets('a held arrow accelerates and commits exactly one seek on release', (tester) async {
      await pumpControls(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      for (var i = 0; i < 8; i++) {
        await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
      }

      expect(chrome.controlsVisible, isFalse, reason: 'a held seek must not escalate to the scrub bar');
      expect(player.seeks, isEmpty, reason: 'the burst is coalesced, not dispatched per repeat');

      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(player.seeks, hasLength(1));
      // 1 press at 10s + 5 repeats at 1.5x + 3 repeats at 3x = 10 + 75 + 90.
      expect(player.seeks.single, const Duration(minutes: 10) + const Duration(seconds: 175));

      await settleFeedback(tester);
    });

    testWidgets('up-arrow still raises the chrome as the deliberate escape hatch', (tester) async {
      await pumpControls(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      expect(chrome.controlsVisible, isTrue);

      await settleFeedback(tester);
    });

    testWidgets('a media fast-forward key skips with a badge and no chrome', (tester) async {
      await pumpControls(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.mediaFastForward);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.mediaFastForward);
      await tester.pump();

      expect(chrome.controlsVisible, isFalse);
      expect(find.text('10s'), findsOneWidget);
      expect(player.seeks, [const Duration(minutes: 10, seconds: 10)]);

      await settleFeedback(tester);
    });

    testWidgets('a rapid media-key burst commits the total the badge reports', (tester) async {
      // No chapters, so the transport key falls back to a timed skip. A slow
      // backend must not let the badge climb past what actually gets seeked.
      player.freezePositionOnSeek = true;
      await pumpControls(tester);

      for (var i = 0; i < 3; i++) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.mediaFastForward);
        await tester.pump();
        await tester.sendKeyUpEvent(LogicalKeyboardKey.mediaFastForward);
        await tester.pump();
      }

      expect(find.text('30s'), findsOneWidget);
      expect(player.seeks, [
        const Duration(minutes: 10, seconds: 10),
        const Duration(minutes: 10, seconds: 20),
        const Duration(minutes: 10, seconds: 30),
      ]);
      expect(chrome.controlsVisible, isFalse);

      await settleFeedback(tester);
    });

    testWidgets('a skip after a jump elsewhere starts from where the jump landed', (tester) async {
      // #1819: the timeline, a chapter jump, an OS media control and a Watch
      // Together peer all land on Player.seek. Whichever of them moves the
      // playhead, the coalesced target the previous skip pinned is stale, and a
      // skip that resumes from it rewinds the user back across their own jump.
      await pumpControls(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.mediaFastForward);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.mediaFastForward);
      await tester.pump();
      expect(player.seeks, [const Duration(minutes: 10, seconds: 10)]);

      await player.seek(const Duration(minutes: 30));
      await tester.pump();
      expect(
        find.text('10s'),
        findsNothing,
        reason: 'the readout promised a skip the jump just cancelled, so it must come down at once',
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.mediaFastForward);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.mediaFastForward);
      await tester.pump();

      expect(
        player.seeks.last,
        const Duration(minutes: 30, seconds: 10),
        reason: 'the skip must be relative to the new position, not to the superseded 10:10 target',
      );
      expect(find.text('10s'), findsOneWidget, reason: 'the abandoned burst total must not keep climbing');

      await settleFeedback(tester);
    });

    testWidgets('a skip after a stream rebuilt at a resume position starts from there', (tester) async {
      // Dead-stream recovery answers a seek request by reopening the source at
      // the target rather than seeking, so a fix that only watched Player.seek
      // would leave the pin stale here.
      await pumpControls(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.mediaFastForward);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.mediaFastForward);
      await tester.pump();
      final seeksBeforeReload = player.seeks.length;

      player.reopenAt(const Duration(minutes: 3));
      await tester.pump();
      expect(player.seeks, hasLength(seeksBeforeReload), reason: 'a reload is not a seek');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.mediaFastForward);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.mediaFastForward);
      await tester.pump();

      expect(player.seeks.last, const Duration(minutes: 3, seconds: 10));

      await settleFeedback(tester);
    });

    testWidgets('a new item drops the previous item\'s pending skip and its badge total', (tester) async {
      // The controls survive an in-place episode swap. A pending target is an
      // offset into the outgoing item's timeline, and the badge total describes
      // a burst that will never be committed.
      player.freezePositionOnSeek = true;
      await pumpControls(tester);

      for (var i = 0; i < 2; i++) {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.mediaFastForward);
        await tester.pump();
        await tester.sendKeyUpEvent(LogicalKeyboardKey.mediaFastForward);
        await tester.pump();
      }
      expect(find.text('20s'), findsOneWidget);
      expect(player.seeks.last, const Duration(minutes: 10, seconds: 20));

      await pumpControls(tester, itemId: 'next-episode');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.mediaFastForward);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.mediaFastForward);
      await tester.pump();

      expect(
        player.seeks.last,
        const Duration(minutes: 10, seconds: 10),
        reason: 'the new item restarts from the live position, not from the outgoing 10:20 target',
      );
      expect(find.text('10s'), findsOneWidget, reason: 'the badge must not keep counting the abandoned burst');

      await settleFeedback(tester);
    });

    testWidgets('a media fast-forward key announces the chapter it lands on', (tester) async {
      await pumpControls(
        tester,
        chapters: [
          MediaChapter(id: 1, startTimeOffset: 0, endTimeOffset: 900000, title: 'Cold Open'),
          MediaChapter(id: 2, startTimeOffset: 900000, endTimeOffset: 1800000, title: 'The Heist'),
        ],
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.mediaFastForward);
      await tester.pump();

      expect(chrome.controlsVisible, isFalse);
      expect(find.byType(DoubleTapFeedback), findsNothing, reason: 'a chapter jump is not an N-second skip');
      expect(find.byType(PlayerToastIndicator), findsOneWidget);
      expect(find.text('The Heist'), findsOneWidget);

      await settleFeedback(tester);
    });

    testWidgets('a chapter seek past the last chapter announces nothing', (tester) async {
      // Position 10:00 sits inside the final chapter, so there is nowhere
      // forward to jump; the badge must not claim a jump that never happens.
      await pumpControls(
        tester,
        chapters: [
          MediaChapter(id: 1, startTimeOffset: 0, endTimeOffset: 300000, title: 'Cold Open'),
          MediaChapter(id: 2, startTimeOffset: 300000, endTimeOffset: 2700000, title: 'The Heist'),
        ],
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.mediaFastForward);
      await tester.pump();

      expect(find.byType(PlayerToastIndicator), findsNothing);
      expect(find.byType(DoubleTapFeedback), findsNothing);
      expect(player.seeks, isEmpty);
      expect(chrome.controlsVisible, isFalse);

      await settleFeedback(tester);
    });

    testWidgets('a backward chapter seek at the very start announces nothing', (tester) async {
      await pumpControls(
        tester,
        chapters: [
          MediaChapter(id: 1, startTimeOffset: 0, endTimeOffset: 900000, title: 'Cold Open'),
          MediaChapter(id: 2, startTimeOffset: 900000, endTimeOffset: 1800000, title: 'The Heist'),
        ],
      );
      player.setPosition(Duration.zero);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.mediaRewind);
      await tester.pump();

      expect(find.byType(PlayerToastIndicator), findsNothing);
      expect(player.seeks, isEmpty, reason: 'already at the start — nothing to rewind to');
      expect(chrome.controlsVisible, isFalse);

      await settleFeedback(tester);
    });

    testWidgets('a live hold resets its acceleration tier when the key is released', (tester) async {
      // Live seeks bypass the accumulator entirely, so nothing is ever pending;
      // the release must still reset the tier or the next hold in the same
      // direction resumes mid-acceleration.
      final liveOffsets = <int>[];
      await pumpControls(tester, isLive: true, onLiveSeekBy: liveOffsets.add);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      for (var i = 0; i < 6; i++) {
        await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
      }
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(liveOffsets, [10, 15, 15, 15, 15, 15, 30], reason: 'the first hold climbs through the tiers');

      liveOffsets.clear();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(liveOffsets, [10, 15], reason: 'a fresh hold restarts at the slowest tier');
      expect(chrome.controlsVisible, isFalse);

      await settleFeedback(tester);
    });

    testWidgets('a directed pause on an already-paused video neither resumes nor rewinds', (tester) async {
      player.setPlaying(false);
      await pumpControls(tester, wireTransportCallback: true);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.mediaPause);
      await tester.pump();

      expect(transportCommands, [TransportCommand.pause]);
      expect(player.playOrPauseCalls, 0, reason: 'a dedicated pause button must never toggle');
      expect(player.pauseCalls, 1);
      expect(
        player.seeks,
        isEmpty,
        reason: 'rewind-on-resume must follow the resolved intent, not the current paused state',
      );
      expect(player.state.position, const Duration(minutes: 10));
      expect(chrome.controlsVisible, isFalse);

      await settleFeedback(tester);
    });

    testWidgets('a directed play on a paused video rewinds then resumes', (tester) async {
      player.setPlaying(false);
      await pumpControls(tester, wireTransportCallback: true);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.mediaPlay);
      await tester.pump();

      expect(transportCommands, [TransportCommand.play]);
      expect(player.seeks, [const Duration(minutes: 9, seconds: 55)]);
      expect(player.playCalls, 1);
      expect(player.playOrPauseCalls, 0);
      expect(chrome.controlsVisible, isFalse);

      await settleFeedback(tester);
    });

    testWidgets('the combined play/pause key toggles without raising the chrome', (tester) async {
      await pumpControls(tester, wireTransportCallback: true);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.mediaPlayPause);
      await tester.pump();

      expect(transportCommands, [TransportCommand.toggle]);
      expect(player.playOrPauseCalls, 1);
      expect(chrome.controlsVisible, isFalse, reason: 'pausing must not cover the subtitles either');

      await settleFeedback(tester);
    });

    testWidgets('select raises the chrome before toggling so no badge flashes under it', (tester) async {
      await pumpControls(tester, wireTransportCallback: true);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
      await tester.pump();

      expect(chrome.controlsVisible, isTrue);
      expect(transportCommands, [TransportCommand.toggle]);

      await settleFeedback(tester);
    });

    /// Scale of the disc's one-shot pop. Reading it back is how "the animation
    /// replayed" becomes observable rather than assumed.
    double discScale(WidgetTester tester) => tester
        .widget<ScaleTransition>(
          find.descendant(of: find.byType(TransportFeedbackIndicator), matching: find.byType(ScaleTransition)),
        )
        .scale
        .value;

    testWidgets('an accepted transport command shows a centred disc, not the top pill', (tester) async {
      await pumpControls(tester);

      toast.showTransport(Symbols.pause_rounded, 'Paused');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 520));

      expect(find.byType(TransportFeedbackIndicator), findsOneWidget);
      expect(
        find.byType(PlayerToastIndicator),
        findsNothing,
        reason: 'a top pill would land on ASS \\an8 subtitles - the readability complaint itself',
      );
      // Centred in the frame, clear of both subtitle bands.
      final disc = tester.getRect(find.byType(TransportFeedbackIndicator));
      final surface = tester.getRect(find.byType(PlexVideoControls));
      expect(disc.center.dx, moreOrLessEquals(surface.center.dx, epsilon: 1));
      expect(disc.center.dy, moreOrLessEquals(surface.center.dy, epsilon: 1));
      // Still announced, so assistive tech and the E2E tree keep reading it.
      expect(find.bySemanticsLabel('Paused'), findsOneWidget);

      // The glyph nearly fills the disc. It is a state cue, not a button, so a
      // wide ring of padding would just cover more picture for no gain. Measured
      // at the held scale, where the transform is identity.
      final circle = tester.getRect(
        find.descendant(of: find.byType(TransportFeedbackIndicator), matching: find.byType(DecoratedBox)),
      );
      final glyph = tester.getRect(
        find.descendant(of: find.byType(TransportFeedbackIndicator), matching: find.byType(AppIcon)),
      );
      expect(circle.width, moreOrLessEquals(circle.height, epsilon: 0.5), reason: 'a circle, not an oval');
      expect(
        glyph.width / circle.width,
        greaterThan(0.55),
        reason: 'the icon should nearly fill the disc rather than float in padding',
      );

      await settleFeedback(tester);
    });

    testWidgets('a repeated identical transport command replays the pop', (tester) async {
      await pumpControls(tester);

      toast.showTransport(Symbols.pause_rounded, 'Paused');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 520));
      final settled = discScale(tester);

      // Same icon and same label: without a per-command pulse this reuses the
      // State and the pop would never run again.
      toast.showTransport(Symbols.pause_rounded, 'Paused');
      await tester.pump();

      expect(
        discScale(tester),
        lessThan(settled),
        reason: 'an identical repeat must restart the pop, not sit at its finished scale',
      );

      await settleFeedback(tester);
    });

    testWidgets('the disc leaves the way it arrived', (tester) async {
      await pumpControls(tester);

      double discOpacity() => tester
          .widget<FadeTransition>(
            find.descendant(of: find.byType(TransportFeedbackIndicator), matching: find.byType(FadeTransition)),
          )
          .opacity
          .value;

      toast.showTransport(Symbols.pause_rounded, 'Paused');
      await tester.pump();

      // Grows and fades in from 0.8/0.
      expect(discScale(tester), lessThan(1.0));
      expect(discOpacity(), lessThan(1.0));

      // Holds fully visible at rest, long enough to read.
      await tester.pump(const Duration(milliseconds: 300));
      expect(discScale(tester), moreOrLessEquals(1.0, epsilon: 0.01));
      expect(discOpacity(), moreOrLessEquals(1.0, epsilon: 0.01));
      await tester.pump(const Duration(milliseconds: 300));
      expect(discScale(tester), moreOrLessEquals(1.0, epsilon: 0.01), reason: 'still held at 600ms');

      // Then runs the same motion backwards rather than expanding away.
      await tester.pump(const Duration(milliseconds: 120));
      expect(discScale(tester), lessThan(1.0), reason: 'shrinks back toward 0.8, never past 1.0');
      expect(discOpacity(), lessThan(1.0));

      await settleFeedback(tester);
    });

    testWidgets('the seek readout sits unbacked at the edge it seeks toward', (tester) async {
      await pumpControls(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final feedback = find.byType(DoubleTapFeedback);
      // Nothing is painted behind it. A backdrop large enough to read as a
      // surface is exactly what covers the picture and subtitles.
      expect(find.descendant(of: feedback, matching: find.byType(ClipPath)), findsNothing);
      expect(find.descendant(of: feedback, matching: find.byType(ColoredBox)), findsNothing);
      expect(find.descendant(of: feedback, matching: find.byType(DecoratedBox)), findsNothing);

      // Amount and exactly one chevron, on one line, near the seek-side edge.
      final chevron = find.descendant(of: feedback, matching: find.byType(AppIcon));
      expect(chevron, findsOneWidget);
      final label = tester.getRect(find.text('10s'));
      final arrow = tester.getRect(chevron);
      expect(arrow.left, greaterThan(label.left), reason: 'the chevron leads in the travel direction');
      expect(
        arrow.center.dy,
        moreOrLessEquals(label.center.dy, epsilon: 2),
        reason: 'chevron and amount share one line',
      );

      final surface = tester.getRect(find.byType(PlexVideoControls));
      expect(arrow.right, lessThan(surface.right), reason: 'inside the overscan-safe inset');
      expect(label.left, greaterThan(surface.center.dx), reason: 'anchored to the right half, not centred');
      expect(label.center.dy, moreOrLessEquals(surface.center.dy, epsilon: 2));

      await settleFeedback(tester);
    });

    /// Opacity of the drifting chevron. Sampling it is how "still animating"
    /// becomes observable.
    double chevronOpacity(WidgetTester tester) => tester
        .widget<Opacity>(find.descendant(of: find.byType(DoubleTapFeedback), matching: find.byType(Opacity)))
        .opacity;

    double chevronDx(WidgetTester tester) => tester
        .widget<Transform>(find.descendant(of: find.byType(DoubleTapFeedback), matching: find.byType(Transform)))
        .transform
        .getTranslation()
        .x;

    testWidgets('each stacked press shows its new total', (tester) async {
      await pumpControls(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('10s'), findsOneWidget);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      // The amount is the per-press feedback here; no extra kick is needed.
      expect(find.text('20s'), findsOneWidget);
      expect(find.text('10s'), findsNothing);

      await settleFeedback(tester);
    });

    testWidgets('the chevron stays visible and travels one way through a held burst', (tester) async {
      // It is a persistent cue, not a blinking one: it must never fade out
      // entirely, and it must only ever displace toward the seek direction.
      await pumpControls(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      var peak = 0.0;
      var floor = 1.0;
      var mostBackward = 0.0;
      var peakDx = 0.0;
      final samples = <double>[];
      final positions = <double>{};
      for (var i = 0; i < 20; i++) {
        await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump(const Duration(milliseconds: 60));
        final o = chevronOpacity(tester);
        peak = math.max(peak, o);
        floor = math.min(floor, o);
        final dx = chevronDx(tester);
        mostBackward = math.min(mostBackward, dx);
        peakDx = math.max(peakDx, dx);
        samples.add(dx);
        positions.add(double.parse(dx.toStringAsFixed(2)));
      }

      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(floor, greaterThan(0.6), reason: 'the chevron must never blink out mid-burst');
      expect(peak, greaterThan(0.9), reason: 'and must reach full strength as it travels');
      expect(mostBackward, greaterThanOrEqualTo(-0.01), reason: 'a forward seek never crosses behind its origin');
      expect(positions.length, greaterThan(3), reason: 'it keeps moving rather than sitting still');
      // The outward stroke dominates. Mean displacement over a cycle is exactly
      // half the amplitude for a symmetric wobble, and higher when the chevron
      // dwells at the far end and returns briefly.
      final mean = samples.reduce((a, b) => a + b) / samples.length;
      expect(
        mean / peakDx,
        greaterThan(0.55),
        reason: 'travel should read as directional, not as an even back-and-forth',
      );

      await settleFeedback(tester);
    });

    testWidgets('the seek readout fits a narrow portrait viewport', (tester) async {
      // Rotation is unlockable, so portrait playback is reachable, and the inset
      // is derived from viewport width. Pump the readout at the real viewport
      // size rather than through the harness, whose surface is pinned landscape.
      const narrow = Size(400, 800);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: narrow),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SizedBox.fromSize(
                key: const ValueKey('viewport'),
                size: narrow,
                child: const Stack(children: [Positioned.fill(child: DoubleTapFeedback(isForward: true, seconds: 10))]),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull, reason: 'must not overflow at 400px wide');
      final viewport = tester.getRect(find.byKey(const ValueKey('viewport')));
      final row = tester.getRect(find.byType(Row));
      expect(row.left, greaterThanOrEqualTo(viewport.left), reason: 'stays on screen');
      expect(row.right, lessThanOrEqualTo(viewport.right));
      expect(row.width, lessThan(viewport.width), reason: 'a readout, not a full-width band');
    });
  });

  // Desktop keyboard seeking never reaches the D-pad branch above: with
  // videoPlayerNavigationEnabled false and no TV, the configured Left/Right and
  // Shift+Left/Right shortcuts fall through to KeyboardShortcutsService.
  group('desktop keyboard seeking', () {
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
      await settings.write(SettingsService.seekTimeLarge, 30);
      await settings.write(SettingsService.videoPlayerNavigationEnabled, false);

      TvDetectionService.debugSetAppleTVOverride(false);
      PlatformDetector.debugSetIsDesktopOSOverride(true);

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
      await player.dispose();
    });

    Future<void> pumpDesktopControls(
      WidgetTester tester, {
      _RecordingPlayer? withPlayer,
      bool isLive = false,
      ValueChanged<int>? onLiveSeekBy,
      ValueChanged<int>? onLiveSeek,
      VoidCallback? onNext,
      bool canNavigateMediaItems = false,
    }) async {
      final active = withPlayer ?? player;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AppDatabase>.value(value: database),
            ChangeNotifierProvider<PlaybackStateProvider>.value(value: playbackState),
            ChangeNotifierProvider<WatchTogetherProvider>.value(value: watchTogether),
          ],
          child: MaterialApp(
            theme: ThemeData(platform: TargetPlatform.macOS, extensions: const [testMonoTokens]),
            home: Scaffold(
              body: SizedBox(
                width: 1280,
                height: 720,
                child: PlexVideoControls(
                  player: active,
                  volumeController: volume,
                  metadata: testMediaItem(id: 'desktop-keyboard-seek'),
                  toastController: toast,
                  chromeController: chrome,
                  canNavigateMediaItems: canNavigateMediaItems,
                  isLive: isLive,
                  onLiveSeekBy: onLiveSeekBy,
                  onLiveSeek: onLiveSeek,
                  onNext: onNext,
                ),
              ),
            ),
          ),
        ),
      );
      // The shortcuts service loads asynchronously; without it the arrow keys
      // are consumed before ever reaching a seek.
      await tester.pumpAndSettle();
      chrome.hide();
      chrome.markControlsHidden();
      await tester.pump();
      expect(chrome.controlsVisible, isFalse);
    }

    Future<void> settleFeedback(WidgetTester tester) async {
      chrome.cancelAutoHide();
      toast.hide();
      await tester.pumpWidget(const SizedBox.shrink());
    }

    Future<void> pressKey(WidgetTester tester, LogicalKeyboardKey key) async {
      await tester.sendKeyDownEvent(key);
      await tester.pump();
      await tester.sendKeyUpEvent(key);
      await tester.pump();
    }

    testWidgets('the configured seek shortcut shows the badge and leaves the chrome down', (tester) async {
      await pumpDesktopControls(tester);

      await pressKey(tester, LogicalKeyboardKey.arrowRight);

      expect(chrome.controlsVisible, isFalse, reason: 'keyboard seeking must not cover the subtitles either');
      expect(find.byType(DoubleTapFeedback), findsOneWidget);
      expect(find.text('10s'), findsOneWidget);
      expect(player.seeks, [const Duration(minutes: 10, seconds: 10)]);

      await settleFeedback(tester);
    });

    testWidgets('the backward shortcut reports its own direction', (tester) async {
      await pumpDesktopControls(tester);

      await pressKey(tester, LogicalKeyboardKey.arrowLeft);

      expect(find.text('10s'), findsOneWidget);
      expect(player.seeks, [const Duration(minutes: 9, seconds: 50)]);
      expect(chrome.controlsVisible, isFalse);

      await settleFeedback(tester);
    });

    testWidgets('the large seek shortcut reports the large amount', (tester) async {
      await pumpDesktopControls(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await pressKey(tester, LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      expect(find.text('30s'), findsOneWidget);
      expect(player.seeks, [const Duration(minutes: 10, seconds: 30)]);
      expect(chrome.controlsVisible, isFalse);

      await settleFeedback(tester);
    });

    testWidgets('a rapid burst commits the total the badge reports, even when seeks lag', (tester) async {
      // A slow backend has not moved the position when the next press lands.
      // Rebasing off player.state.position would peg every request near +10s
      // while the badge climbed to 30s.
      player.freezePositionOnSeek = true;
      await pumpDesktopControls(tester);

      for (var i = 0; i < 3; i++) {
        await pressKey(tester, LogicalKeyboardKey.arrowRight);
      }

      expect(find.text('30s'), findsOneWidget);
      expect(player.seeks, [
        const Duration(minutes: 10, seconds: 10),
        const Duration(minutes: 10, seconds: 20),
        const Duration(minutes: 10, seconds: 30),
      ]);
      expect(
        player.seeks.last,
        const Duration(minutes: 10) + const Duration(seconds: 30),
        reason: 'the committed target must equal the badge total',
      );
      expect(chrome.controlsVisible, isFalse);

      await settleFeedback(tester);
    });

    testWidgets('a lagging backend still yields the pin to a jump elsewhere', (tester) async {
      // The two invariants pull in opposite directions: a slow seek must not
      // retire the pin (#1676), a jump from anywhere else must (#1819). Freeze
      // the reported position so only the seek announcement can tell them apart.
      player.freezePositionOnSeek = true;
      await pumpDesktopControls(tester);

      await pressKey(tester, LogicalKeyboardKey.arrowRight);
      await pressKey(tester, LogicalKeyboardKey.arrowRight);
      expect(player.seeks.last, const Duration(minutes: 10, seconds: 20), reason: 'the burst is still pinned');

      player.setPosition(const Duration(minutes: 2));
      await player.seek(const Duration(minutes: 2));
      await tester.pump();

      await pressKey(tester, LogicalKeyboardKey.arrowRight);

      expect(player.seeks.last, const Duration(minutes: 2, seconds: 10));
      expect(find.text('10s'), findsOneWidget);

      await settleFeedback(tester);
    });

    testWidgets('swapping the player moves the pin listener with it', (tester) async {
      // The controls survive a player replacement (didUpdateWidget accepts a new
      // instance), so an accumulator left bound to the retired player would keep
      // a pin from a timeline that no longer exists and take orders from a
      // player nobody is watching.
      final replacement = _RecordingPlayer()
        ..setPosition(const Duration(minutes: 4))
        // Frozen, so a pinned chain stays distinguishable from a rebase.
        ..freezePositionOnSeek = true;
      addTearDown(replacement.dispose);

      await pumpDesktopControls(tester);
      await pressKey(tester, LogicalKeyboardKey.arrowRight);
      expect(player.seeks.last, const Duration(minutes: 10, seconds: 10));

      await pumpDesktopControls(tester, withPlayer: replacement);
      expect(tester.takeException(), isNull);

      await pressKey(tester, LogicalKeyboardKey.arrowRight);
      expect(
        replacement.seeks.last,
        const Duration(minutes: 4, seconds: 10),
        reason: 'the retired pin must not survive the swap and chain to 10:20',
      );
      // The badge is not asserted here: pumping the replacement settles the
      // feedback timer, which clears the total on its own.

      // Build a fresh pin on the new player, then let the retired one shout.
      await pressKey(tester, LogicalKeyboardKey.arrowRight);
      expect(replacement.seeks.last, const Duration(minutes: 4, seconds: 20));
      await player.seek(const Duration(minutes: 30));
      await tester.pump();

      await pressKey(tester, LogicalKeyboardKey.arrowRight);
      expect(
        replacement.seeks.last,
        const Duration(minutes: 4, seconds: 30),
        reason: 'a jump from the retired player must not retire the current pin',
      );

      await settleFeedback(tester);
    });

    testWidgets('an absolute live seek takes down the badge a live skip raised', (tester) async {
      // Live relative skips go to the parent epoch accumulator, not _hiddenSeek
      // (#1253), so no playhead jump can retire this badge. The absolute seek
      // cancels the queued skip, so its promised total is going nowhere.
      final liveOffsets = <int>[];
      final absoluteSeeks = <int>[];
      await pumpDesktopControls(tester, isLive: true, onLiveSeekBy: liveOffsets.add, onLiveSeek: absoluteSeeks.add);

      await pressKey(tester, LogicalKeyboardKey.arrowRight);
      expect(liveOffsets, [10]);
      expect(find.text('10s'), findsOneWidget);

      chrome.show();
      await tester.pump();
      final live = tester.widget<DesktopVideoControls>(find.byType(DesktopVideoControls));
      live.onLiveSeek!(120);
      await tester.pump();

      expect(absoluteSeeks, [120], reason: 'the wrapper still delegates to the screen');
      expect(find.byType(DoubleTapFeedback), findsNothing, reason: 'the skip it promised was cancelled with it');

      await settleFeedback(tester);
    });

    testWidgets('switching what is playing takes the badge with the old timeline', (tester) async {
      // A live channel switch cancels the queued live offset, and an item
      // change re-keys the whole timeline. Neither runs through _hiddenSeek, so
      // nothing else would retire a readout that now describes nothing.
      final liveOffsets = <int>[];
      var nextPresses = 0;
      await pumpDesktopControls(tester, isLive: true, onLiveSeekBy: liveOffsets.add, onNext: () => nextPresses++);

      await pressKey(tester, LogicalKeyboardKey.arrowRight);
      expect(liveOffsets, [10]);
      expect(find.text('10s'), findsOneWidget);

      chrome.show();
      await tester.pump();
      tester.widget<DesktopVideoControls>(find.byType(DesktopVideoControls)).onNext!();
      await tester.pump();

      expect(nextPresses, 1, reason: 'the wrapper still delegates to the screen');
      expect(find.byType(DoubleTapFeedback), findsNothing);

      await settleFeedback(tester);
    });
  });

  group('formatSkipFeedbackLabel', () {
    setUp(() => LocaleSettings.setLocaleSync(AppLocale.en));

    test('keeps a bare second count below a minute', () {
      expect(formatSkipFeedbackLabel(10), '10s');
      expect(formatSkipFeedbackLabel(59), '59s');
    });

    test('switches to a timestamp once a held seek passes a minute', () {
      expect(formatSkipFeedbackLabel(60), '1:00');
      expect(formatSkipFeedbackLabel(175), '2:55');
    });
  });
}

/// Minimal [Player] that records transport calls and keeps a settable
/// playing/position state so intent-dependent behaviour can be asserted.
class _RecordingPlayer implements Player {
  final List<Duration> seeks = [];
  final StreamController<Duration?> _jumpController = StreamController<Duration?>.broadcast();
  int playCalls = 0;
  int pauseCalls = 0;
  int playOrPauseCalls = 0;

  /// Simulates a backend that has not applied the seek yet, so a caller that
  /// rebases off [state] would compute a stale target.
  bool freezePositionOnSeek = false;

  bool _playing = true;
  Duration _position = const Duration(minutes: 10);

  void setPlaying(bool value) => _playing = value;

  void setPosition(Duration value) => _position = value;

  /// Mirrors [PlayerBase.resetPlaybackProgress]: an in-place reload rebuilds
  /// the stream at a resume position without ever calling [seek].
  void reopenAt(Duration value) {
    _position = value;
    _jumpController.add(value);
  }

  @override
  String get playerType => 'mpv';

  @override
  PlayerState get state =>
      PlayerState(playing: _playing, position: _position, duration: const Duration(minutes: 45), seekable: true);

  @override
  PlayerStreams get streams => PlayerStreams(
    playing: const Stream<bool>.empty(),
    completed: const Stream<bool>.empty(),
    buffering: const Stream<bool>.empty(),
    position: const Stream<Duration>.empty(),
    playheadJump: _jumpController.stream,
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

  /// Mirrors [PlayerBase.runSeek]: the requested target is announced whatever
  /// asked for it, while [freezePositionOnSeek] models a backend that has not
  /// moved the reported position yet.
  @override
  Future<void> seek(Duration position) async {
    seeks.add(position);
    if (!freezePositionOnSeek) _position = position;
    _jumpController.add(position);
  }

  @override
  Future<void> dispose({bool preserveDisplayMode = false}) async {
    await _jumpController.close();
  }

  @override
  Future<void> play() async {
    playCalls++;
    _playing = true;
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
    _playing = false;
  }

  @override
  Future<void> playOrPause() async {
    playOrPauseCalls++;
    _playing = !_playing;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
