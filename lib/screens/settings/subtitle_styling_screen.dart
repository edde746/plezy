import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../i18n/strings.g.dart';
import '../../services/settings_service.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/setting_tile.dart';
import '../../widgets/settings_section.dart';
import 'settings_utils.dart';

class SubtitleStylingScreen extends StatelessWidget {
  const SubtitleStylingScreen({super.key});

  String _assOverrideLabel(SubAssOverride value) {
    return switch (value) {
      SubAssOverride.no => 'No',
      SubAssOverride.yes => 'Yes',
      SubAssOverride.scale => 'Scale',
      SubAssOverride.force => 'Force',
      SubAssOverride.strip => 'Strip',
    };
  }

  String _formatPosition(int value) {
    if (value == 0) return 'Top';
    if (value == 100) return 'Bottom';
    return '$value%';
  }

  @override
  Widget build(BuildContext context) {
    return FocusedScrollScaffold(
      title: Text(t.screens.subtitleStyling),
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate([
            SettingsSectionHeader(t.subtitlingStyling.text),
            SettingSelectionTile<SubAssOverride, SubAssOverride>(
              pref: SettingsService.subAssOverride,
              icon: Symbols.subtitles_rounded,
              title: t.subtitlingStyling.assOverride,
              subtitleBuilder: _assOverrideLabel,
              options: SubAssOverride.values.map((v) => DialogOption(value: v, title: _assOverrideLabel(v))).toList(),
              decode: (v) => v,
              encode: (v) => v,
            ),
            SettingNumberTile(
              pref: SettingsService.subtitleFontSize,
              icon: Symbols.format_size_rounded,
              title: t.subtitlingStyling.fontSize,
              subtitleBuilder: (v) => '$v',
              labelText: t.subtitlingStyling.fontSize,
              suffixText: '',
              min: 10,
              max: 80,
            ),
            SettingColorTile(
              pref: SettingsService.subtitleTextColor,
              icon: Symbols.format_color_text_rounded,
              title: t.subtitlingStyling.textColor,
            ),
            SettingNumberTile(
              pref: SettingsService.subtitlePosition,
              icon: Symbols.vertical_align_bottom_rounded,
              title: t.subtitlingStyling.position,
              subtitleBuilder: _formatPosition,
              labelText: t.subtitlingStyling.position,
              suffixText: '%',
              min: 0,
              max: 100,
            ),
            SettingSwitchTile(
              pref: SettingsService.subtitleBold,
              icon: Symbols.format_bold_rounded,
              title: t.subtitlingStyling.bold,
            ),
            SettingSwitchTile(
              pref: SettingsService.subtitleItalic,
              icon: Symbols.format_italic_rounded,
              title: t.subtitlingStyling.italic,
            ),

            SettingsSectionHeader(t.subtitlingStyling.border),
            SettingNumberTile(
              pref: SettingsService.subtitleBorderSize,
              icon: Symbols.border_style_rounded,
              title: t.subtitlingStyling.borderSize,
              subtitleBuilder: (v) => '$v',
              labelText: t.subtitlingStyling.borderSize,
              suffixText: '',
              min: 0,
              max: 5,
            ),
            SettingColorTile(
              pref: SettingsService.subtitleBorderColor,
              icon: Symbols.border_color_rounded,
              title: t.subtitlingStyling.borderColor,
            ),

            SettingsSectionHeader(t.subtitlingStyling.background),
            SettingNumberTile(
              pref: SettingsService.subtitleBackgroundOpacity,
              icon: Symbols.opacity_rounded,
              title: t.subtitlingStyling.backgroundOpacity,
              subtitleBuilder: (v) => '$v%',
              labelText: t.subtitlingStyling.backgroundOpacity,
              suffixText: '%',
              min: 0,
              max: 100,
            ),
            SettingColorTile(
              pref: SettingsService.subtitleBackgroundColor,
              icon: Symbols.format_color_fill_rounded,
              title: t.subtitlingStyling.backgroundColor,
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ],
    );
  }
}
