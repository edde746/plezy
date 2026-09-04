import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/screens/video_player_screen.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/services/sleep_timer_service.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/media_items.dart';
import '../../test_helpers/mock_player_channels.dart';
import '../../test_helpers/prefs.dart';

/// Regression coverage for the sleep timer's "Still watching?" acknowledgement
/// semantics: dismissing the visible prompt via system back must re-arm the
/// timer exactly like Continue, while a back with no prompt on screen must
/// leave the timer untouched.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    SleepTimerService().cancelTimer();
  });

  tearDown(() {
    SleepTimerService().cancelTimer();
  });

  testWidgets('back on the visible still-watching prompt re-arms the sleep timer with its original duration', (
    tester,
  ) async {
    final nativeInitialize = Completer<bool>();

    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) {
        if (call.method == 'initialize') return nativeInitialize.future;
        return Future<Object?>.value(null);
      },
      eventHandler: (_) async => null,
      testBody: () async {
        final key = GlobalKey<VideoPlayerScreenState>();
        await tester.pumpWidget(_screen(key));
        expect(key.currentState, isNotNull);

        final sleepTimer = SleepTimerService();
        sleepTimer.startTimer(const Duration(minutes: 30), () {});
        // Move the deadline into the past; the next 1s heartbeat fires the
        // still-watching prompt while _originalDuration stays 30 minutes.
        sleepTimer.extendTimer(const Duration(minutes: -31));
        await tester.pump(const Duration(seconds: 1));
        // Let the onPrompt stream event reach the screen's listener.
        await tester.pump();

        // The prompt consumed the countdown: the timer parks awaiting an answer.
        expect(sleepTimer.isActive, isFalse);
        expect(sleepTimer.originalDuration, const Duration(minutes: 30));

        // System back dismisses the visible prompt — the same acknowledgement
        // as Continue, so the timer must restart with its original duration.
        await tester.binding.handlePopRoute();
        await tester.pump();

        expect(sleepTimer.isActive, isTrue);
        expect(sleepTimer.duration, const Duration(minutes: 30));
        expect(sleepTimer.originalDuration, const Duration(minutes: 30));

        sleepTimer.cancelTimer();
        await tester.pumpWidget(const SizedBox.shrink());
        nativeInitialize.complete(true);
        await tester.pump();
      },
    );
  });

  testWidgets('back with no prompt visible leaves the sleep timer untouched', (tester) async {
    final nativeInitialize = Completer<bool>();

    await withMockPlayerChannels(
      methodChannelName: 'com.plezy/mpv_player',
      eventChannelName: 'com.plezy/mpv_player/events',
      methodHandler: (call) {
        if (call.method == 'initialize') return nativeInitialize.future;
        return Future<Object?>.value(null);
      },
      eventHandler: (_) async => null,
      testBody: () async {
        final key = GlobalKey<VideoPlayerScreenState>();
        await tester.pumpWidget(_screen(key));
        expect(key.currentState, isNotNull);

        final sleepTimer = SleepTimerService();
        sleepTimer.startTimer(const Duration(minutes: 30), () {});
        final endTimeBefore = sleepTimer.endTime;
        expect(endTimeBefore, isNotNull);

        // No prompt is on screen: back walks the ordinary exit pipeline and
        // must not reset (or restart) the armed timer.
        await tester.binding.handlePopRoute();
        await tester.pump();

        expect(sleepTimer.isActive, isTrue);
        expect(sleepTimer.endTime, endTimeBefore);
        expect(sleepTimer.duration, const Duration(minutes: 30));

        sleepTimer.cancelTimer();
        await tester.pumpWidget(const SizedBox.shrink());
        nativeInitialize.complete(true);
        await tester.pump();
      },
    );
  });
}

Widget _screen(GlobalKey<VideoPlayerScreenState> key) {
  return ChangeNotifierProvider(
    create: (_) => PlaybackStateProvider(),
    child: MaterialApp(
      home: VideoPlayerScreen(
        key: key,
        metadata: testMediaItem(title: 'Still watching sleep timer test'),
        isOffline: true,
      ),
    ),
  );
}
