import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/screens/video_player_screen.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/media_items.dart';
import '../../test_helpers/mock_player_channels.dart';
import '../../test_helpers/prefs.dart';

/// Regression coverage for #1797: while the screen node holds primary focus,
/// its self-heal answers an actionable key by raising the chrome onto the
/// Play/Pause button. With "Video Player Navigation" off, arrows are playback
/// shortcuts and must not be turned into a focus jump — but Tab is the
/// deliberate way into the OSD and must keep working.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    TvDetectionService.debugSetAppleTVOverride(false);
  });

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
  });

  testWidgets('an arrow is left to the playback shortcuts when player navigation is off', (tester) async {
    final focusedPlayPause = await _selfHealFocusesPlayPauseFor(tester, LogicalKeyboardKey.arrowLeft);

    expect(focusedPlayPause, isFalse, reason: 'an arrow must seek, not pull focus onto Play/Pause');
  });

  testWidgets('Tab still walks into the player controls when player navigation is off', (tester) async {
    final focusedPlayPause = await _selfHealFocusesPlayPauseFor(tester, LogicalKeyboardKey.tab);

    expect(focusedPlayPause, isTrue, reason: 'Tab is the deliberate way into the OSD and must keep reaching it');
  });
}

/// Sends [key] to a freshly opened player route — whose screen node still owns
/// primary focus, exactly as after a window re-activation — and reports whether
/// its self-heal queued play/pause focus on the chrome.
Future<bool> _selfHealFocusesPlayPauseFor(WidgetTester tester, LogicalKeyboardKey key) async {
  final screenKey = GlobalKey<VideoPlayerScreenState>();
  var focusedPlayPause = false;

  await withMockPlayerChannels(
    methodChannelName: 'com.plezy/mpv_player',
    eventChannelName: 'com.plezy/mpv_player/events',
    testBody: () async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => PlaybackStateProvider(),
          child: MaterialApp(
            home: VideoPlayerScreen(
              key: screenKey,
              metadata: testMediaItem(title: 'Self-heal keys'),
              isOffline: true,
            ),
          ),
        ),
      );
      await tester.pump();

      final chrome = screenKey.currentState!.chromeController;
      // Drain anything the route queued while opening, so the assertion can
      // only see what this key press produced.
      chrome.takePlayPauseFocus();

      await tester.sendKeyDownEvent(key);
      await tester.pump();
      await tester.sendKeyUpEvent(key);
      await tester.pump();

      focusedPlayPause = chrome.takePlayPauseFocus();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  return focusedPlayPause;
}
