import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/number_symbols_data.dart';

import '../../i18n/strings.g.dart';
import '../../i18n/app_locale_utils.dart';
import '../../i18n/locale_preferences.dart';
import '../../i18n/locale_names.g.dart';
import '../../i18n/presentation_formats.dart';
import '../../utils/language_codes.dart';
import '../../media/ids.dart';
import '../../navigation/navigation_tabs.dart';
import '../../profiles/active_profile_provider.dart';
import '../../providers/multi_server_provider.dart';
import '../../services/settings_service.dart';
import '../../services/settings_mutation_service.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/setting_tile.dart';
import '../../widgets/settings_page.dart';
import '../../widgets/settings_section.dart';
import 'settings_utils.dart';

/// App-level preferences that are not about looks or playback: language,
/// what happens at startup, and desktop window behavior.
class GeneralSettingsScreen extends StatelessWidget {
  const GeneralSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watched at build level so the tiles can be excluded with a plain `if` —
    // a child that renders SizedBox.shrink() would corrupt the group corners.
    final hasMultipleProfiles = context.watch<ActiveProfileProvider>().hasMultipleProfiles;
    final activeProfileId = context.watch<ActiveProfileProvider>().active?.id;
    final serverProvider = context.watch<MultiServerProvider>();
    final visibleServerIds = serverProvider.serverIds;
    return SettingsPage(
      title: Text(t.settings.general),
      children: [
        SettingsGroup(
          title: t.settings.languageAndRegion,
          children: [_languageSelector(context), _formatSelector(context), _metadataSelector(context)],
        ),

        SettingsGroup(
          title: t.settings.startup,
          children: [
            _startupSectionSelector(),
            if (hasMultipleProfiles)
              SettingSwitchTile(
                pref: SettingsService.requireProfileSelectionOnOpen,
                icon: Symbols.person_rounded,
                title: t.settings.requireProfileSelectionOnOpen,
                subtitle: t.settings.requireProfileSelectionOnOpenDescription,
              ),
            if (Platform.isAndroid || PlatformDetector.isDesktopOS())
              SettingSwitchTile(
                pref: SettingsService.forceTvMode,
                icon: Symbols.tv_rounded,
                title: t.settings.forceTvMode,
                subtitle: t.settings.forceTvModeDescription,
              ),
          ],
        ),

        if (activeProfileId != null && visibleServerIds.isNotEmpty)
          SettingsGroup(
            title: t.connections.sectionTitle,
            children: [_PreferredServerTile(profileId: activeProfileId)],
          ),

        if (PlatformDetector.isDesktopOS())
          SettingsGroup(
            title: t.settings.window,
            children: [
              SettingSwitchTile(
                pref: SettingsService.startInFullscreen,
                icon: Symbols.fullscreen_rounded,
                title: t.settings.startInFullscreen,
                subtitle: t.settings.startInFullscreenDescription,
              ),
            ],
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _languageSelector(BuildContext context) {
    final followsSystem = LocalePreferences.followsSystem;
    return FocusableListTile(
      leading: const AppIcon(Symbols.language_rounded, fill: 1),
      title: Text(t.settings.language),
      subtitle: Text(
        followsSystem
            ? '${t.settings.followSystem} · ${LocaleSettings.currentLocale.nativeName}'
            : LocaleSettings.currentLocale.nativeName,
      ),
      trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
      onTap: () async {
        final picked = await showSelectionDialog<String>(
          context: context,
          title: t.settings.language,
          searchable: true,
          options: [
            DialogOption(value: '', title: t.settings.followSystem),
            for (final locale in AppLocale.values)
              DialogOption(
                value: locale.name,
                title: locale.nativeName,
                subtitle: '${LanguageCodes.getDisplayName(locale.languageTag)} · ${locale.languageTag}',
              ),
          ],
          currentValue: followsSystem ? '' : LocaleSettings.currentLocale.name,
        );
        if (picked != null && context.mounted) {
          final locale = picked.value.isEmpty ? LocaleSettings.currentLocale : AppLocale.values.byName(picked.value);
          await const SettingsMutationService().write(
            context,
            SettingsService.appLocale,
            locale,
            reset: picked.value.isEmpty,
          );
        }
      },
    );
  }

  Widget _formatSelector(BuildContext context) {
    final current = SettingsService.instance.read(SettingsService.formatLocale);
    final label = switch (current) {
      'app' => t.settings.followAppLanguage,
      'system' => t.settings.followSystem,
      _ => LanguageCodes.getDisplayName(current),
    };
    return FocusableListTile(
      leading: const AppIcon(Symbols.public_rounded),
      title: Text(t.settings.regionFormat),
      subtitle: Text(
        '$label · ${isolateDisplayText(formatDecimal(12345.67, grouping: true))}\n${t.settings.regionFormatDescription}',
      ),
      trailing: const AppIcon(Symbols.chevron_right_rounded),
      onTap: () async {
        final current = SettingsService.instance.read(SettingsService.formatLocale);
        final locales = numberFormatSymbols.keys.toList()..sort();
        final picked = await showSelectionDialog<String>(
          context: context,
          title: t.settings.regionFormat,
          currentValue: current,
          searchable: true,
          options: [
            DialogOption(value: 'app', title: t.settings.followAppLanguage),
            DialogOption(value: 'system', title: t.settings.followSystem),
            for (final code in locales)
              DialogOption(
                value: code.replaceAll('_', '-'),
                title: LanguageCodes.getDisplayName(code),
                subtitle:
                    '${code.replaceAll('_', '-')} · ${isolateDisplayText(NumberFormat.decimalPattern(code).format(12345.67))}',
              ),
          ],
        );
        if (picked != null && context.mounted) {
          await const SettingsMutationService().write(context, SettingsService.formatLocale, picked.value);
        }
      },
    );
  }

  Widget _metadataSelector(BuildContext context) {
    final current = SettingsService.instance.read(SettingsService.metadataLocale);
    final label = current.isEmpty ? t.settings.followAppLanguage : LanguageCodes.getDisplayName(current);
    return FocusableListTile(
      leading: const AppIcon(Symbols.translate_rounded),
      title: Text(t.settings.metadataLanguage),
      subtitle: Text('$label\n${t.settings.metadataLanguageDescription}'),
      trailing: const AppIcon(Symbols.chevron_right_rounded),
      onTap: () async {
        final picked = await showSelectionDialog<String>(
          context: context,
          title: t.settings.metadataLanguage,
          currentValue: SettingsService.instance.read(SettingsService.metadataLocale),
          searchable: true,
          options: [
            DialogOption(value: '', title: t.settings.followAppLanguage),
            for (final language in LanguageCodes.getAllLanguages())
              DialogOption(
                value: language.code,
                title: language.name,
                subtitle: localizedLanguageNames['en']![language.code],
              ),
          ],
        );
        if (picked != null && context.mounted) {
          await const SettingsMutationService().write(context, SettingsService.metadataLocale, picked.value);
        }
      },
    );
  }

  // Sections offered as a startup destination, in display order. Live TV is
  // always listed; if no server provides it, startup falls back to Home.
  static const _startupSectionOptions = [
    NavigationTabId.discover,
    NavigationTabId.libraries,
    NavigationTabId.liveTv,
    NavigationTabId.search,
  ];

  String _startupSectionLabel(NavigationTabId id) => allNavigationTabs.firstWhere((t) => t.id == id).getLabel();

  Widget _startupSectionSelector() => SettingSelectionTile<NavigationTabId>(
    pref: SettingsService.startupSection,
    icon: Symbols.start_rounded,
    title: t.settings.startupSection,
    subtitleBuilder: _startupSectionLabel,
    options: _startupSectionOptions.map((id) => DialogOption(value: id, title: _startupSectionLabel(id))).toList(),
  );
}

class _PreferredServerTile extends StatelessWidget {
  final String profileId;

  const _PreferredServerTile({required this.profileId});

  @override
  Widget build(BuildContext context) {
    final serverProvider = context.watch<MultiServerProvider>();
    final manager = serverProvider.serverManager;
    final pref = SettingsService.preferredServerForProfile(profileId);
    final currentId = SettingsService.instance.read(pref);
    final currentLabel = currentId.isEmpty
        ? t.settings.preferredServerAutomatic
        : manager.serverDisplayName(ServerId(currentId));

    return FocusableListTile(
      leading: const AppIcon(Symbols.dns_rounded, fill: 1),
      title: Text(t.settings.preferredServer),
      subtitle: Text(t.settings.preferredServerDescription),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(currentLabel, overflow: TextOverflow.ellipsis),
          const SizedBox(width: 8),
          const AppIcon(Symbols.chevron_right_rounded, fill: 1),
        ],
      ),
      onTap: () async {
        final ids = serverProvider.serverIds;
        final picked = await showSelectionDialog<String>(
          context: context,
          title: t.settings.preferredServer,
          options: [
            DialogOption(value: '', title: t.settings.preferredServerAutomatic),
            for (final id in ids) DialogOption(value: id, title: manager.serverDisplayName(ServerId(id))),
          ],
          currentValue: currentId,
        );
        if (picked == null || !context.mounted) return;
        await SettingsService.instance.write(pref, picked.value);
        if (context.mounted) manager.setPreferredServerId(picked.value);
      },
    );
  }
}
