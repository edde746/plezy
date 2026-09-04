import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/models/audio_quality_preset.dart';
import 'package:plezy/screens/settings/playback_settings_screen.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/models/player_setting_scope.dart';

import '../../test_helpers/prefs.dart';

void main() {
  setUp(() async {
    resetSharedPreferencesForTest(initialAsync: {'music_quality_preset': 'medium'});
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  testWidgets('shows and changes the persisted music quality', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(MaterialApp(theme: monoTheme(dark: true), home: const PlaybackSettingsScreen()));
    await tester.pumpAndSettle();

    final title = find.text('Music Quality');
    await tester.scrollUntilVisible(title, 500, scrollable: find.byType(Scrollable).first);

    final tile = find.widgetWithText(ListTile, 'Music Quality');
    expect(find.descendant(of: tile, matching: find.text('192 kbps')), findsOneWidget);

    await tester.tap(title);
    await tester.pumpAndSettle();
    await tester.tap(find.text('128 kbps'));
    await tester.pumpAndSettle();

    final settings = SettingsService.instance;
    expect(settings.read(SettingsService.musicQualityPreset), AudioQualityPreset.low);
    expect(settings.prefs.getString(SettingsService.musicQualityPreset.key), 'low');
    expect(find.descendant(of: tile, matching: find.text('128 kbps')), findsOneWidget);
  });

  testWidgets('changes a player-change persistence scope', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(MaterialApp(theme: monoTheme(dark: true), home: const PlaybackSettingsScreen()));
    await tester.pumpAndSettle();

    final title = find.text('Shader Preset');
    await tester.scrollUntilVisible(title, 500, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(title);
    await tester.pumpAndSettle();

    final tile = find.widgetWithText(ListTile, 'Shader Preset');
    expect(find.descendant(of: tile, matching: find.textContaining('Everywhere')), findsOneWidget);

    await tester.tap(title);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Per library'));
    await tester.pumpAndSettle();

    final settings = SettingsService.instance;
    expect(settings.read(SettingsService.shaderPresetScope), PlayerSettingScope.library);
    expect(settings.prefs.getString(SettingsService.shaderPresetScope.key), 'library');
    expect(find.descendant(of: tile, matching: find.textContaining('Per library')), findsOneWidget);
  });

  testWidgets('changes the play next countdown and labels zero as immediate', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(MaterialApp(theme: monoTheme(dark: true), home: const PlaybackSettingsScreen()));
    await tester.pumpAndSettle();

    final title = find.text('Play Next Countdown');
    await tester.scrollUntilVisible(title, 500, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(title);
    await tester.pumpAndSettle();

    await tester.tap(title);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final settings = SettingsService.instance;
    expect(settings.read(SettingsService.playNextCountdown), 0);
    final tile = find.widgetWithText(ListTile, 'Play Next Countdown');
    expect(find.descendant(of: tile, matching: find.text('Play immediately')), findsOneWidget);
  });

  testWidgets('toggles deinterlacing on the mpv path', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(MaterialApp(theme: monoTheme(dark: true), home: const PlaybackSettingsScreen()));
    await tester.pumpAndSettle();

    final title = find.text('Deinterlacing');
    await tester.scrollUntilVisible(title, 500, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(title);
    await tester.pumpAndSettle();
    await tester.tap(title);
    await tester.pumpAndSettle();

    expect(SettingsService.instance.read(SettingsService.deinterlace), isTrue);
  });

  testWidgets('turns the covered-source direct play off from the quality group (#2193)', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(MaterialApp(theme: monoTheme(dark: true), home: const PlaybackSettingsScreen()));
    await tester.pumpAndSettle();

    final title = find.text('Play Smaller Videos at Original Quality');
    await tester.scrollUntilVisible(title, 500, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(title);
    await tester.pumpAndSettle();

    expect(SettingsService.instance.read(SettingsService.directPlayCoveredQuality), isTrue);
    await tester.tap(title);
    await tester.pumpAndSettle();

    expect(SettingsService.instance.read(SettingsService.directPlayCoveredQuality), isFalse);
  });

  testWidgets('gesture toggles render on mobile and persist', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: monoTheme(dark: true).copyWith(platform: TargetPlatform.android),
        home: const PlaybackSettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final title = find.text('Volume Swipe');
    await tester.scrollUntilVisible(title, 500, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(title);
    await tester.pumpAndSettle();
    await tester.tap(title);
    await tester.pumpAndSettle();

    final settings = SettingsService.instance;
    expect(settings.read(SettingsService.gestureVolumeSwipe), isFalse);
    expect(settings.read(SettingsService.gestureBrightnessSwipe), isTrue);
    expect(settings.read(SettingsService.gesturePinchToZoom), isTrue);
  });

  testWidgets('gesture toggles stay hidden on non-mobile layouts', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: monoTheme(dark: true).copyWith(platform: TargetPlatform.macOS),
        home: const PlaybackSettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gestures'), findsNothing);
  });
}
