import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/providers/playback_state_provider.dart';
import 'package:plezy/screens/video_player_screen.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/widgets/video_controls/player_chrome_controller.dart';
import 'package:provider/provider.dart';

import '../../test_helpers/media_items.dart';
import '../../test_helpers/mock_player_channels.dart';
import '../../test_helpers/prefs.dart';

/// Regression coverage for #1765: a television opened the player with the whole
/// OSD and timebar up, and auto-hide cannot arm before the first frame, so the
/// chrome sat over the opening seconds of every video.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  tearDown(() {
    TvDetectionService.debugSetAppleTVOverride(null);
  });


  testWidgets('the TV player route opens with the chrome down and unpresented', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);

    final chrome = await _openPlayerChrome(tester);

    expect(chrome.controlsVisible, isFalse);
    // Presented must fall with visible, or PlayerNavigationCoordinator reads
    // back as "hide the chrome", hide() no-ops, and back is swallowed.
    expect(chrome.controlsPresented, isFalse);
  });

  testWidgets('pointer and touch routes keep the chrome over the loading surface', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(false);

    final chrome = await _openPlayerChrome(tester);

    expect(chrome.controlsVisible, isTrue);
    expect(chrome.controlsPresented, isTrue);
  });

  testWidgets('the route announces loading from its first frame, with or without chrome', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final semantics = tester.ensureSemantics();

    // The Maestro TV flows replaced the Pause button with this label as their
    // readiness gate, which only holds if it is on screen from the moment the
    // player route owns the frame — long before any media opens.
    await _openPlayerChrome(
      tester,
      whileMounted: () {
        expect(find.bySemanticsLabel('Loading video'), findsOneWidget);
      },
    );

    semantics.dispose();
  });
}

Future<PlayerChromeController> _openPlayerChrome(WidgetTester tester, {VoidCallback? whileMounted}) async {
  final key = GlobalKey<VideoPlayerScreenState>();
  late PlayerChromeController chrome;

  await withMockPlayerChannels(
    methodChannelName: 'com.plezy/mpv_player',
    eventChannelName: 'com.plezy/mpv_player/events',
    testBody: () async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => PlaybackStateProvider(),
          child: MaterialApp(
            home: VideoPlayerScreen(
              key: key,
              metadata: testMediaItem(title: 'Startup chrome video'),
              isOffline: true,
            ),
          ),
        ),
      );
      chrome = key.currentState!.chromeController;
      whileMounted?.call();
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  return chrome;
}
