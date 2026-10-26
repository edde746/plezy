import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../i18n/strings.g.dart';
import '../../i18n/presentation_formats.dart';
import '../../focus/focusable_slider.dart';
import '../../services/settings_service.dart';
import '../../widgets/settings_page.dart';
import '../../widgets/settings_section.dart';
import '../../widgets/settings_builder.dart';
import '../../widgets/setting_tile.dart';

class AccessibilitySettingsScreen extends StatelessWidget {
  const AccessibilitySettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => SettingsPage(
    title: Text(t.accessibility.title),
    children: [
      Padding(padding: const EdgeInsets.all(16), child: Text(t.accessibility.systemHint)),
      SettingsGroup(
        title: t.accessibility.readability,
        children: [
          SettingValueBuilder<double>(
            pref: SettingsService.accessibilityTextScale,
            builder: (context, value, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.accessibility.textSize, style: Theme.of(context).textTheme.titleMedium),
                  FocusableSlider(
                    value: value,
                    min: 1,
                    max: 2,
                    divisions: 10,
                    semanticLabel: t.accessibility.textSize,
                    semanticFormatterCallback: formatPercent,
                    onChanged: (v) => SettingsService.instance.write(SettingsService.accessibilityTextScale, v),
                  ),
                  Text(
                    t.accessibility.preview,
                    textScaler: TextScaler.linear(value),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          SettingSwitchTile(
            pref: SettingsService.boldInterfaceText,
            icon: Symbols.format_bold_rounded,
            title: t.accessibility.boldText,
          ),
          SettingSwitchTile(
            pref: SettingsService.highContrast,
            icon: Symbols.contrast_rounded,
            title: t.accessibility.highContrast,
            subtitle: t.accessibility.highContrastHint,
          ),
        ],
      ),
      SettingsGroup(
        title: t.accessibility.interaction,
        children: [
          SettingSwitchTile(
            pref: SettingsService.reduceMotion,
            icon: Symbols.motion_photos_off_rounded,
            title: t.accessibility.reduceMotion,
            subtitle: t.accessibility.reduceMotionHint,
          ),
          SettingSwitchTile(
            pref: SettingsService.largeTouchTargets,
            icon: Symbols.touch_app_rounded,
            title: t.accessibility.largeTargets,
            subtitle: t.accessibility.largeTargetsHint,
          ),
        ],
      ),
      Padding(padding: const EdgeInsets.all(16), child: Text(t.accessibility.navigationHint)),
    ],
  );
}
