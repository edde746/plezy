import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/navigation/settings_shortcut.dart';
import 'package:plezy/utils/platform_detector.dart';
import 'package:plezy/utils/video_player_navigation.dart';

/// Session shell mirroring production: [SettingsShortcut] wrapping the
/// profile navigator, with a stand-in settings route so the suite does not
/// need the full settings provider graph.
class _Harness {
  final navigatorKey = GlobalKey<NavigatorState>();
  final settingsRoutes = SettingsRouteTracker();
  int settingsPushes = 0;

  Route<void> buildFakeSettingsRoute() {
    settingsPushes++;
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: kSettingsRouteName),
      builder: (_) => const Scaffold(body: Focus(autofocus: true, child: Text('settings page'))),
    );
  }
}

Future<_Harness> _pumpShortcut(WidgetTester tester) async {
  final harness = _Harness();
  await tester.pumpWidget(
    MaterialApp(
      home: SettingsShortcut(
        navigatorKey: harness.navigatorKey,
        settingsRoutes: harness.settingsRoutes,
        routeBuilder: harness.buildFakeSettingsRoute,
        child: Navigator(
          key: harness.navigatorKey,
          observers: [harness.settingsRoutes],
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const Scaffold(body: Focus(autofocus: true, child: Text('home'))),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return harness;
}

/// The chord's modifier on the variant platform under test.
LogicalKeyboardKey _platformModifier() =>
    defaultTargetPlatform == TargetPlatform.macOS ? LogicalKeyboardKey.metaLeft : LogicalKeyboardKey.controlLeft;

/// The other desktop's modifier — must never match on this platform.
LogicalKeyboardKey _wrongModifier() =>
    defaultTargetPlatform == TargetPlatform.macOS ? LogicalKeyboardKey.controlLeft : LogicalKeyboardKey.metaLeft;

/// Presses modifier+comma as a full down/up chord.
Future<void> _sendChord(WidgetTester tester, LogicalKeyboardKey modifier) async {
  await tester.sendKeyDownEvent(modifier);
  await tester.sendKeyDownEvent(LogicalKeyboardKey.comma);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.comma);
  await tester.sendKeyUpEvent(modifier);
  await tester.pumpAndSettle();
}

void main() {
  const macOSOnly = TargetPlatformVariant(<TargetPlatform>{TargetPlatform.macOS});

  setUp(() {
    // Pin the form-factor gates the chord reads rather than inheriting the
    // test host; the target platform comes from each test's variant.
    PlatformDetector.debugSetIsDesktopOSOverride(true);
    TvDetectionService.debugSetAppleTVOverride(false);
  });

  tearDown(() {
    PlatformDetector.debugSetIsDesktopOSOverride(null);
    TvDetectionService.debugSetAppleTVOverride(null);
  });

  testWidgets('the platform chord opens settings from a content route', (tester) async {
    final harness = await _pumpShortcut(tester);

    await _sendChord(tester, _platformModifier());

    expect(harness.settingsPushes, 1);
    expect(find.text('settings page'), findsOneWidget);
  }, variant: TargetPlatformVariant.desktop());

  testWidgets('the other desktop modifier and a bare comma do nothing', (tester) async {
    final harness = await _pumpShortcut(tester);

    await _sendChord(tester, _wrongModifier());
    await tester.sendKeyDownEvent(LogicalKeyboardKey.comma);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.comma);
    await tester.pumpAndSettle();

    expect(harness.settingsPushes, 0);
    expect(find.text('home'), findsOneWidget);
  }, variant: TargetPlatformVariant.desktop());

  testWidgets('repeat presses do not stack a second settings route', (tester) async {
    final harness = await _pumpShortcut(tester);

    await _sendChord(tester, LogicalKeyboardKey.metaLeft);
    await _sendChord(tester, LogicalKeyboardKey.metaLeft);

    expect(harness.settingsPushes, 1);
    expect(find.text('settings page'), findsOneWidget);

    // Closing settings re-arms the chord.
    harness.navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    await _sendChord(tester, LogicalKeyboardKey.metaLeft);

    expect(harness.settingsPushes, 2);
    expect(find.text('settings page'), findsOneWidget);
  }, variant: macOSOnly);

  testWidgets('settings below a sub-page still blocks the chord', (tester) async {
    final harness = await _pumpShortcut(tester);
    await _sendChord(tester, LogicalKeyboardKey.metaLeft);

    // A settings sub-page (unnamed route) on top of the settings route.
    unawaited(
      harness.navigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Focus(autofocus: true, child: Text('appearance sub-page'))),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _sendChord(tester, LogicalKeyboardKey.metaLeft);

    expect(harness.settingsPushes, 1);
    expect(find.text('appearance sub-page'), findsOneWidget, reason: 'the sub-page must stay current');
  }, variant: macOSOnly);

  testWidgets('the video player on top blocks the chord', (tester) async {
    final harness = await _pumpShortcut(tester);

    unawaited(
      harness.navigatorKey.currentState!.push(
        PageRouteBuilder<void>(
          settings: const RouteSettings(name: kVideoPlayerRouteName),
          pageBuilder: (_, _, _) => const Scaffold(body: Focus(autofocus: true, child: Text('player'))),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _sendChord(tester, LogicalKeyboardKey.metaLeft);

    expect(harness.settingsPushes, 0);
    expect(find.text('player'), findsOneWidget);
  }, variant: macOSOnly);

  testWidgets('a non-desktop host ignores the chord', (tester) async {
    PlatformDetector.debugSetIsDesktopOSOverride(false);
    final harness = await _pumpShortcut(tester);

    await _sendChord(tester, LogicalKeyboardKey.metaLeft);

    expect(harness.settingsPushes, 0);
  }, variant: macOSOnly);

  testWidgets('a TV host ignores the chord', (tester) async {
    TvDetectionService.debugSetAppleTVOverride(true);
    final harness = await _pumpShortcut(tester);

    await _sendChord(tester, LogicalKeyboardKey.metaLeft);

    expect(harness.settingsPushes, 0);
  }, variant: macOSOnly);
}
