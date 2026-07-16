import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plezy/theme/mono_theme.dart';
import 'package:plezy/widgets/focusable_list_tile.dart';
import 'package:plezy/widgets/setting_tile.dart';
import 'package:plezy/widgets/settings_section.dart';

void main() {
  testWidgets('mobile settings option titles match compact native rows', (tester) async {
    await tester.pumpWidget(_harness(TargetPlatform.android, referenceDense: true));

    final referenceHeight = tester.getSize(find.text('Clear Cache')).height;
    expect(tester.getSize(find.text('View Logs')).height, referenceHeight);
    expect(tester.getSize(find.text('View Mode')).height, referenceHeight);

    final referenceSubtitleHeight = tester.getSize(find.text('Clear cached data')).height;
    expect(tester.getSize(find.text('View application logs')).height, referenceSubtitleHeight);
  });

  testWidgets('desktop settings option titles retain standard row size', (tester) async {
    await tester.pumpWidget(_harness(TargetPlatform.macOS, referenceDense: false));

    final referenceHeight = tester.getSize(find.text('Clear Cache')).height;
    expect(tester.getSize(find.text('View Logs')).height, referenceHeight);
    expect(tester.getSize(find.text('View Mode')).height, referenceHeight);
  });
}

Widget _harness(TargetPlatform platform, {required bool referenceDense}) {
  return MaterialApp(
    theme: monoTheme(dark: false).copyWith(platform: platform),
    home: Scaffold(
      body: Column(
        children: [
          SettingNavigationTile(
            icon: Icons.article,
            title: 'View Logs',
            subtitle: 'View application logs',
            onTap: () {},
          ),
          FocusableListTile(
            leading: const Icon(Icons.cleaning_services),
            title: const Text('Clear Cache'),
            subtitle: const Text('Clear cached data'),
            trailing: const Icon(Icons.chevron_right),
            dense: referenceDense,
            visualDensity: referenceDense ? const VisualDensity(vertical: -3) : VisualDensity.standard,
            onTap: () {},
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
        ],
      ),
    ),
  );
}
