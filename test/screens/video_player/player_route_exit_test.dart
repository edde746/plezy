import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/services/playback_coordinator.dart';
import 'package:plezy/screens/video_player_screen.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/utils/video_player_navigation.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/media_items.dart';
import '../../test_helpers/mock_player_channels.dart';
import '../../test_helpers/prefs.dart';
import '../../test_helpers/pump.dart';
import '../../test_helpers/watch_together_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  // Route-global wakelock serialization spans these successive routes. Keep
  // their lifecycle on one clock, like the application, not separate FakeAsync zones.
  testWidgets('Back bounds removable routes without fencing Retry on a root route', (tester) async {
    for (final pushed in [true, false]) {
      final key = GlobalKey<VideoPlayerScreenState>();
      final navigator = GlobalKey<NavigatorState>();
      var initializations = 0;
      await withMockPlayerChannels(
        methodChannelName: 'com.plezy/mpv_player',
        eventChannelName: 'com.plezy/mpv_player/events',
        methodHandler: (call) async {
          if (call.method == 'initialize') {
            initializations++;
            return true;
          }
          if (call.method == 'observeProperty') {
            throw PlatformException(code: 'initialization_failure');
          }
          return null;
        },
        testBody: () async {
          final player = _TouchExitPlayer();
          try {
            final screen = VideoPlayerScreen(key: key, metadata: testMediaItem(), isOffline: true);
            await tester.pumpWidget(
              ChangeNotifierProvider(
                create: (_) => PlaybackStateProvider(),
                child: MaterialApp(
                  navigatorKey: navigator,
                  home: pushed ? const Scaffold(body: Text('Browse')) : screen,
                ),
              ),
            );
            if (pushed) {
              unawaited(VideoPlayerRoute(builder: (_) => screen).push(navigator.currentState!));
            }
            await pumpUntil(tester, () => find.widgetWithText(OutlinedButton, 'Back').evaluate().isNotEmpty);
            key.currentState!.player = player;
            await tester.tap(find.widgetWithText(OutlinedButton, 'Back'));
            await tester.pump();
            if (pushed) {
              await tester.tap(find.widgetWithText(OutlinedButton, 'Back'));
              await tester.pump(const Duration(seconds: 1));
              await tester.pump();
              expect(key.currentState, isNull);
              expect(find.text('Browse'), findsOneWidget);
              expect(player.pauseCalls, 1);
              var stoppedDone = false;
              final stopped = expectLater(
                PlaybackCoordinator.instance.shutdownVideo(),
                throwsA(isA<PlatformException>().having((error) => error.code, 'code', 'late_pause_failure')),
              ).whenComplete(() => stoppedDone = true);
              player.pauseGate.completeError(PlatformException(code: 'late_pause_failure'));
              await pumpUntil(tester, () => stoppedDone);
              await stopped;
              expect(find.text('Browse'), findsOneWidget);
              expect(tester.takeException(), isNull);
            } else {
              await tester.pump(const Duration(seconds: 2));
              expect(key.currentState, isNotNull);
              expect(player.pauseCalls, 0);
              await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
              await pumpUntil(
                tester,
                () => initializations == 2 && find.widgetWithText(FilledButton, 'Retry').evaluate().isNotEmpty,
              );
            }
          } finally {
            if (!player.pauseGate.isCompleted) player.pauseGate.complete();
            await tester.pumpWidget(const SizedBox.shrink());
            var retirementDone = false;
            final retirement = PlaybackCoordinator.instance.shutdownVideo().whenComplete(() => retirementDone = true);
            await pumpUntil(tester, () => retirementDone);
            await retirement;
          }
        },
      );
    }
  });

  // A route pushed onto the player's own navigator inside the exit grace
  // period must not fence the accepted exit: the player leaves by identity
  // and the covering route stays put (#2290).
  testWidgets('Back removes a covered player route without taking the covering route', (tester) async {
    final player = _TouchExitPlayer();
    final screen = await _pushHeldPlayer(tester, player);
    final navigator = screen.navigator;
    await tester.binding.handlePopRoute();
    await tester.pump();
    // Held startup keeps cleanup pending, so the 1 s navigation budget is
    // what releases navigation: this push lands inside the grace period.
    unawaited(
      navigator.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('Cover')))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(screen.key.currentState, isNotNull, reason: 'the pending cleanup still owns the grace period');
    expect(find.text('Cover'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(screen.key.currentState, isNull);
    expect(find.text('Cover'), findsOneWidget, reason: 'removing the player cannot take the covering route');
    expect(find.text('Browse'), findsNothing, reason: 'the exit must not unwind past the covering route');
    expect(player.pauseCalls, 1);
  });

  // With frame-rate matching, restoring the display mode renegotiates HDMI.
  // The page underneath must not be shown at the content rate first, so an
  // Android TV exit holds the player route until the restore has landed.
  group('Android display-mode restore on exit', () {
    Future<void> onAndroid({required bool tv, required Future<void> Function() body}) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      TvDetectionService.debugSetAppleTVOverride(null);
      if (tv) await TvDetectionService.getInstance(forceTv: true);
      try {
        await body();
      } finally {
        debugDefaultTargetPlatformOverride = null;
        TvDetectionService.debugReset();
      }
    }

    testWidgets('Back on a TV hides the output, restores the mode, then leaves', (tester) async {
      await onAndroid(
        tv: true,
        body: () async {
          final player = _DisplayRestorePlayer();
          player.pauseGate.complete();
          final screen = await _pushHeldPlayer(tester, player);
          await tester.binding.handlePopRoute();
          await tester.pump();
          await tester.pump(const Duration(seconds: 2));
          expect(player.calls, ['pause', 'setVisible(false)', 'clearVideoFrameRate(awaitDisplayRestore: true)']);
          expect(
            screen.key.currentState,
            isNotNull,
            reason: 'the page below must not show while the link renegotiates',
          );

          player.restoreGate.complete();
          await tester.pump();
          await tester.pump();
          expect(screen.key.currentState, isNull);
          expect(find.text('Browse'), findsOneWidget);
        },
      );
    });

    testWidgets('A restore that never lands still lets Back leave', (tester) async {
      await onAndroid(
        tv: true,
        body: () async {
          final player = _DisplayRestorePlayer();
          player.pauseGate.complete();
          final screen = await _pushHeldPlayer(tester, player);
          await tester.binding.handlePopRoute();
          await tester.pump();
          await tester.pump(const Duration(seconds: 4));
          expect(screen.key.currentState, isNotNull);
          await tester.pump(const Duration(seconds: 1));
          await tester.pump();
          expect(screen.key.currentState, isNull);
          expect(find.text('Browse'), findsOneWidget);
        },
      );
    });

    testWidgets('A player that never pauses leaves on the navigation budget without a restore', (tester) async {
      await onAndroid(
        tv: true,
        body: () async {
          final player = _DisplayRestorePlayer();
          final screen = await _pushHeldPlayer(tester, player);
          await tester.binding.handlePopRoute();
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          await tester.pump();
          expect(screen.key.currentState, isNull);
          expect(player.calls, ['pause', 'setVisible(false)'], reason: 'dispose restores the mode instead');
        },
      );
    });

    testWidgets('Back off a TV keeps the output and leaves the restore to dispose', (tester) async {
      // Nothing hides the surface there, and the 400 ms HDR-exit deferral
      // relies on the surface being gone.
      await onAndroid(
        tv: false,
        body: () async {
          final player = _DisplayRestorePlayer();
          player.pauseGate.complete();
          final screen = await _pushHeldPlayer(tester, player);
          await tester.binding.handlePopRoute();
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          await tester.pump();
          expect(screen.key.currentState, isNull);
          expect(player.calls, ['pause']);
        },
      );
    });

    testWidgets('A replacement during the exit leaves the mode to its successor', (tester) async {
      await onAndroid(
        tv: true,
        body: () async {
          final player = _DisplayRestorePlayer();
          final screen = await _pushHeldPlayer(tester, player);
          await tester.binding.handlePopRoute();
          await tester.pump();
          unawaited(
            VideoPlayerRoute(builder: (_) => const Scaffold(body: Text('Next'))).push(screen.navigator.currentState!),
          );
          // The output retires while the replaced screen is still mounted.
          player.pauseGate.complete();
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          await tester.pump();
          expect(find.text('Next'), findsOneWidget);
          expect(player.calls, isNot(contains('clearVideoFrameRate(awaitDisplayRestore: true)')));
        },
      );
    });
  });
}

class _DisplayRestorePlayer extends _TouchExitPlayer {
  final restoreGate = Completer<void>();
  final calls = <String>[];

  @override
  Future<void> pause() {
    calls.add('pause');
    return super.pause();
  }

  @override
  Future<bool> setVisible(bool visible, {bool restoreOnWindowVisible = false}) async {
    calls.add('setVisible($visible)');
    return true;
  }

  @override
  Future<void> clearVideoFrameRate({bool awaitDisplayRestore = false}) async {
    calls.add('clearVideoFrameRate(awaitDisplayRestore: $awaitDisplayRestore)');
    if (awaitDisplayRestore) await restoreGate.future;
  }
}

class _TouchExitPlayer extends FakeSyncPlayer {
  _TouchExitPlayer() : super(playing: true);

  final pauseGate = Completer<void>();
  int pauseCalls = 0;

  @override
  Future<void> abandonAudioFocus() async {}

  @override
  Future<void> pause() async {
    pauseCalls++;
    await pauseGate.future;
  }
}

/// Mounts a player route over a `Browse` root with startup held by music
/// arbitration and [player] already installed.
///
/// A second `VideoPlayerScreen` in this isolate never reaches `initialize` -
/// it inherits the predecessor's native-channel release, which no longer
/// settles once that test's clock is gone (see `test_helpers/hdr_startup.dart`).
/// The route-exit path does not need startup at all, and holding it also keeps
/// cleanup pending so the navigation budget governs the exit.
Future<({GlobalKey<VideoPlayerScreenState> key, GlobalKey<NavigatorState> navigator})> _pushHeldPlayer(
  WidgetTester tester,
  _TouchExitPlayer player,
) async {
  final key = GlobalKey<VideoPlayerScreenState>();
  final navigator = GlobalKey<NavigatorState>();
  final initializationHold = Completer<void>();
  Future<void> holdInitialization() => initializationHold.future;
  PlaybackCoordinator.instance.registerMusicSession(stopAndDispose: holdInitialization);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    PlaybackCoordinator.instance.unregisterMusicSession(holdInitialization);
    if (!player.pauseGate.isCompleted) player.pauseGate.complete();
    if (!initializationHold.isCompleted) initializationHold.complete();
    await tester.pump();
  });
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => PlaybackStateProvider(),
      child: MaterialApp(
        navigatorKey: navigator,
        home: const Scaffold(body: Text('Browse')),
      ),
    ),
  );
  unawaited(
    VideoPlayerRoute(
      builder: (_) => VideoPlayerScreen(key: key, metadata: testMediaItem(), isOffline: true),
    ).push(navigator.currentState!),
  );
  await tester.pump();
  key.currentState!.player = player;
  return (key: key, navigator: navigator);
}
