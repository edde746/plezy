import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/models/transcode_quality_preset.dart';
import 'package:plezy/screens/settings/settings_utils.dart';
import 'package:plezy/services/settings_service.dart';
import 'package:plezy/utils/quality_preset_labels.dart';
import 'package:plezy/widgets/setting_tile.dart';

import '../test_helpers/prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    resetSharedPreferencesForTest();
    SettingsService.resetForTesting();
    await SettingsService.getInstance();
  });

  // The regression this defends: showSelectionDialog pops the picked
  // DialogOption rather than its raw value, so choosing a null-valued option
  // (the cellular tile's "Same as Default") stays distinguishable from
  // dismissing the dialog.
  group('SettingSelectionTile with a nullable pref', () {
    Widget buildTile() {
      return MaterialApp(
        home: Scaffold(
          body: SettingSelectionTile<TranscodeQualityPreset?>(
            pref: SettingsService.cellularQualityPreset,
            icon: Symbols.signal_cellular_alt_rounded,
            title: t.settings.cellularQualityTitle,
            subtitleBuilder: (p) => p == null ? t.settings.cellularQualitySameAsDefault : qualityPresetLabel(p),
            options: [
              DialogOption<TranscodeQualityPreset?>(value: null, title: t.settings.cellularQualitySameAsDefault),
              ...TranscodeQualityPreset.displayOrder.map(
                (p) => DialogOption<TranscodeQualityPreset?>(value: p, title: qualityPresetLabel(p)),
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('picking a preset writes it, dismissing writes nothing', (tester) async {
      final settings = SettingsService.instance;
      await tester.pumpWidget(buildTile());

      await tester.tap(find.text(t.settings.cellularQualityTitle));
      await tester.pumpAndSettle();
      await tester.tap(find.text(qualityPresetLabel(TranscodeQualityPreset.p720_2mbps)).last);
      await tester.pumpAndSettle();

      expect(settings.read(SettingsService.cellularQualityPreset), TranscodeQualityPreset.p720_2mbps);

      // Dismissal via barrier must not touch the stored value.
      await tester.tap(find.text(t.settings.cellularQualityTitle));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(1, 1));
      await tester.pumpAndSettle();

      expect(settings.read(SettingsService.cellularQualityPreset), TranscodeQualityPreset.p720_2mbps);
    });

    testWidgets('picking the null option clears the stored value', (tester) async {
      final settings = SettingsService.instance;
      await settings.write(SettingsService.cellularQualityPreset, TranscodeQualityPreset.p1080_8mbps);
      await tester.pumpWidget(buildTile());

      await tester.tap(find.text(t.settings.cellularQualityTitle));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.settings.cellularQualitySameAsDefault).last);
      await tester.pumpAndSettle();

      expect(settings.read(SettingsService.cellularQualityPreset), isNull);
      expect(settings.prefs.containsKey(SettingsService.cellularQualityPreset.key), isFalse);
    });
  });
}
