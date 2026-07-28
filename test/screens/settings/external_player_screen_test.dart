import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/focus/focusable_button.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/models/external_player_models.dart';
import 'package:plezy/screens/settings/external_player_screen.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/focusable_list_tile.dart';

import '../../test_helpers/prefs.dart';

void main() {
  late SettingsService settings;

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    KnownPlayers.resetForTesting();
    KnownPlayers.probe = const _AllPlayersInstalled();
    settings = await SettingsService.getInstance();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  tearDown(() {
    SettingsService.resetForTesting();
    KnownPlayers.resetForTesting();
  });

  testWidgets('only custom players expose a focusable delete action', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final customPlayer = ExternalPlayer.custom(
      id: 'custom-test-player',
      name: 'Custom Test Player',
      value: 'custom-player',
      type: CustomPlayerType.command,
    );
    await settings.write(SettingsService.useExternalPlayer, true);
    await settings.write(SettingsService.customExternalPlayers, [customPlayer]);
    await settings.write(SettingsService.selectedExternalPlayer, customPlayer);

    await tester.pumpWidget(MaterialApp(theme: monoTheme(dark: true), home: const ExternalPlayerScreen()));
    await tester.pumpAndSettle();

    for (final player in await KnownPlayers.getForCurrentPlatform()) {
      final title = player.id == KnownPlayers.systemDefault.id ? 'System Default' : player.name;
      final row = find.widgetWithText(FocusableListTile, title);
      expect(row, findsOneWidget);
      expect(find.descendant(of: row, matching: find.byType(FocusableButton)), findsNothing);
      expect(find.descendant(of: row, matching: find.byType(IconButton)), findsNothing);
    }

    final customRow = find.widgetWithText(FocusableListTile, customPlayer.name);
    expect(customRow, findsOneWidget);
    final focusableDelete = find.descendant(of: customRow, matching: find.byType(FocusableButton));
    final deleteControl = find.descendant(of: customRow, matching: find.byType(IconButton));
    expect(focusableDelete, findsOneWidget);
    expect(deleteControl, findsOneWidget);
    expect(tester.widget<FocusableButton>(focusableDelete).onPressed, isNotNull);

    await tester.tap(deleteControl);
    await tester.pumpAndSettle();

    expect(settings.read(SettingsService.customExternalPlayers), isEmpty);
    expect(settings.read(SettingsService.selectedExternalPlayer), KnownPlayers.systemDefault);
    expect(find.text(customPlayer.name), findsNothing);
  });

  testWidgets('a selected known player stays listed when detection misses it', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 1400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    // VLC is supported on every platform Plezy ships, so with detection
    // reporting nothing installed it is always one of the filtered-out ids.
    KnownPlayers.resetForTesting();
    KnownPlayers.probe = const _NoPlayersInstalled();
    final selected = KnownPlayers.findById('vlc')!;
    expect(selected.isAvailable, isTrue);
    expect((await KnownPlayers.getForCurrentPlatform()).map((p) => p.id), isNot(contains('vlc')));

    await settings.write(SettingsService.useExternalPlayer, true);
    await settings.write(SettingsService.selectedExternalPlayer, selected);

    await tester.pumpWidget(MaterialApp(theme: monoTheme(dark: true), home: const ExternalPlayerScreen()));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FocusableListTile, selected.name), findsOneWidget);
    expect(find.widgetWithText(FocusableListTile, 'System Default'), findsOneWidget);
  });
}

/// Reports every player as installed so the screen renders the full platform
/// list regardless of what the host running the suite happens to have.
class _AllPlayersInstalled extends PlayerInstallProbe {
  const _AllPlayersInstalled();

  @override
  Future<ProcessResult> run(String executable, List<String> arguments) async => ProcessResult(0, 0, '', '');

  @override
  Future<bool> applicationInstalled(String bundleId) async => true;

  @override
  Future<bool> fileExists(String path) async => true;

  @override
  Future<bool> schemeHasHandler(String scheme) async => true;
}

/// Reports nothing as installed, so only players without a detector survive.
class _NoPlayersInstalled extends PlayerInstallProbe {
  const _NoPlayersInstalled();

  @override
  Future<ProcessResult> run(String executable, List<String> arguments) async => ProcessResult(0, 1, '', '');

  @override
  Future<bool> applicationInstalled(String bundleId) async => false;

  @override
  Future<bool> fileExists(String path) async => false;

  @override
  Future<bool> schemeHasHandler(String scheme) async => false;
}
