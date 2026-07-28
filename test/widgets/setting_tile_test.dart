import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/focusable_list_tile.dart';
import 'package:plezy/widgets/setting_tile.dart';
import 'package:plezy/widgets/settings_section.dart';

/// Settings rows must render exactly like every other row in the app on every
/// platform. Each row type is measured against an untouched [FocusableListTile]
/// — the app-wide reference row — rather than against a hard-coded size, so the
/// assertions still hold if the app's row density is ever retuned.
void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.macOS]) {
    testWidgets('settings rows match the standard app row on $platform', (tester) async {
      await tester.pumpWidget(_harness(platform));

      final referenceTitle = _titleFontSize(tester, 'Clear Cache');
      final referenceSubtitle = _subtitleFontSize(tester, 'Clear cached data');
      final referenceHeight = tester.getSize(find.byKey(const ValueKey('reference'))).height;

      // The dense ListTile title/subtitle sizes; spelled out so a silent
      // theme-wide inflation can't make every side of the comparison agree.
      expect(referenceTitle, 13);
      expect(referenceSubtitle, 12);

      for (final title in ['View Logs', 'Enable Thing', 'View Mode', 'Account']) {
        expect(_titleFontSize(tester, title), referenceTitle, reason: '$title title size');
      }
      for (final subtitle in ['View application logs', 'Toggles the thing', 'signed in']) {
        expect(_subtitleFontSize(tester, subtitle), referenceSubtitle, reason: '$subtitle subtitle size');
      }
      for (final key in ['navigation', 'switch', 'plain']) {
        expect(tester.getSize(find.byKey(ValueKey(key))).height, referenceHeight, reason: '$key row height');
      }
    });
  }
}

double? _titleFontSize(WidgetTester tester, String text) {
  final finder = find.text(text);
  final inherited = DefaultTextStyle.of(tester.element(finder)).style;
  return inherited.merge(tester.widget<Text>(finder).style).fontSize;
}

double? _subtitleFontSize(WidgetTester tester, String text) =>
    DefaultTextStyle.of(tester.element(find.text(text))).style.fontSize;

Widget _harness(TargetPlatform platform) {
  return MaterialApp(
    theme: monoTheme(dark: false).copyWith(platform: platform),
    home: Scaffold(
      body: SettingsGroup(
        children: [
          SettingNavigationTile(
            key: const ValueKey('navigation'),
            icon: Icons.article,
            title: 'View Logs',
            subtitle: 'View application logs',
            onTap: () {},
          ),
          FocusableListTile(
            key: const ValueKey('reference'),
            leading: const Icon(Icons.cleaning_services),
            title: const Text('Clear Cache'),
            subtitle: const Text('Clear cached data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          FocusableSwitchListTile(
            key: const ValueKey('switch'),
            secondary: const Icon(Icons.toggle_on),
            title: const Text('Enable Thing'),
            subtitle: const Text('Toggles the thing'),
            value: true,
            onChanged: (_) {},
          ),
          SegmentedSetting<String>(
            icon: Icons.view_list,
            title: 'View Mode',
            segments: const [
              ButtonSegment(value: 'grid', label: Text('Grid')),
              ButtonSegment(value: 'list', label: Text('List')),
            ],
            selected: 'grid',
            onChanged: (_) {},
          ),
          // Non-interactive info rows are plain ListTiles; the group hands them
          // the same geometry as their interactive siblings.
          const ListTile(key: ValueKey('plain'), title: Text('Account'), subtitle: Text('signed in')),
        ],
      ),
    ),
  );
}
