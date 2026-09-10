import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/services/playback_coordinator.dart';
import 'package:plezy/screens/video_player_screen.dart';
import 'package:plezy/services/settings_service.dart';
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
              unawaited(navigator.currentState!.push(buildVideoPlayerRoute(builder: (_) => screen)));
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

  // The exit's navigator can lose poppability inside the grace period. A
  // removal that could not happen must not be reported as an exit: the
  // chained UI restore stays live instead of being revoked forever (#2290).
  testWidgets('an unremovable player route keeps the system UI restore live', (tester) async {
    final systemUiReply = Completer<void>();
    final platformCalls = <MethodCall>[];
    var blockSystemUi = false;
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
      if (!systemUiReply.isCompleted) systemUiReply.complete();
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        platformCalls.add(call);
        // `SystemUiMode.manual` dispatches `setEnabledSystemUIOverlays`; the
        // chained `edgeToEdge` request is the one gated on `isCurrent`.
        if (blockSystemUi && call.method == 'SystemChrome.setEnabledSystemUIOverlays') await systemUiReply.future;
        return null;
      },
    );
    final screen = await _pushHeldPlayer(tester, _TouchExitPlayer());
    final navigator = screen.navigator;
    final playerRoute = ModalRoute.of(screen.key.currentContext!)!;
    // The blocked first request holds the restore open across the budget, so
    // its `isCurrent` gate is evaluated after navigation was attempted.
    blockSystemUi = true;
    final callsBeforeBack = platformCalls.length;
    await tester.binding.handlePopRoute();
    await tester.pump();
    navigator.currentState!.removeRouteBelow(playerRoute);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(navigator.currentState!.canPop(), isFalse, reason: 'the accepted exit has nothing left to pop');
    expect(screen.key.currentState, isNotNull, reason: 'nothing could be removed, so nothing exited');
    expect(
      platformCalls.skip(callsBeforeBack).any((call) => call.method == 'SystemChrome.setEnabledSystemUIOverlays'),
      isTrue,
      reason: 'the accepted exit dispatched its restore',
    );
    final callsBeforeReply = platformCalls.length;
    systemUiReply.complete();
    await pumpUntil(
      tester,
      () => platformCalls.skip(callsBeforeReply).any(_isEdgeToEdgeRequest),
      describe: () => platformCalls.skip(callsBeforeReply).map((call) => call.method).toList().toString(),
    );
  });
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
    navigator.currentState!.push(
      buildVideoPlayerRoute(
        builder: (_) => VideoPlayerScreen(key: key, metadata: testMediaItem(), isOffline: true),
      ),
    ),
  );
  await tester.pump();
  key.currentState!.player = player;
  return (key: key, navigator: navigator);
}

bool _isEdgeToEdgeRequest(MethodCall call) =>
    call.method == 'SystemChrome.setEnabledSystemUIMode' && call.arguments == SystemUiMode.edgeToEdge.toString();
