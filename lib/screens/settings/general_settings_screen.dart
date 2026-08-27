import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/app_locale_utils.dart';
import '../../i18n/strings.g.dart';
import '../../navigation/navigation_tabs.dart';
import '../../profiles/active_profile_provider.dart';
import '../../providers/multi_server_provider.dart';
import '../../services/settings_service.dart';
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
    return SettingsPage(
      title: Text(t.settings.general),
      children: [
        SettingsGroup(
          title: t.settings.languageAndRegion,
          children: [
            _languageSelector(context),
            // TODO: Metadata language for Plex discover/metadata queries (#1668)
            // goes here once the client threads a language override through
            // the catalog/watchlist requests.
          ],
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
                onAfterWrite: (value) {
                  TvDetectionService.setForceTVSync(value);
                  restartApp(context);
                },
              ),
          ],
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
              // TODO: Always-on-top selector (Off / Always / While playing)
              // (#1386, #931) goes here; needs a persisted pref replacing the
              // session-only window flag.
            ],
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _languageSelector(BuildContext context) {
    return FocusableListTile(
      leading: const AppIcon(Symbols.language_rounded, fill: 1),
      title: Text(t.settings.language),
      subtitle: Text(_getLanguageDisplayName(LocaleSettings.currentLocale)),
      trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
      onTap: () async {
        final picked = await showSelectionDialog<AppLocale>(
          context: context,
          title: t.settings.language,
          options: AppLocale.values
              .map((locale) => DialogOption(value: locale, title: _getLanguageDisplayName(locale)))
              .toList(),
          currentValue: LocaleSettings.currentLocale,
        );
        if (picked != null) {
          final value = picked.value;
          await SettingsService.instance.write(SettingsService.appLocale, value);
          unawaited(LocaleSettings.setLocale(value));
          if (context.mounted) {
            context.read<MultiServerProvider>().serverManager.updatePlexLanguage(value.plexLanguageCode);
          }
          if (context.mounted) restartApp(context);
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

  String _getLanguageDisplayName(AppLocale locale) {
    switch (locale) {
      case AppLocale.en:
        return 'English';
      case AppLocale.sv:
        return 'Svenska';
      case AppLocale.fr:
        return 'Français';
      case AppLocale.it:
        return 'Italiano';
      case AppLocale.nl:
        return 'Nederlands';
      case AppLocale.de:
        return 'Deutsch';
      case AppLocale.hu:
        return 'Magyar';
      case AppLocale.zh:
        return '简体中文';
      case AppLocale.zhHant:
        return '繁體中文';
      case AppLocale.ko:
        return '한국어';
      case AppLocale.es:
        return 'Español';
      case AppLocale.pt:
        return 'Português';
      case AppLocale.ja:
        return '日本語';
      case AppLocale.ru:
        return 'Русский';
      case AppLocale.pl:
        return 'Polski';
      case AppLocale.da:
        return 'Dansk';
      case AppLocale.nb:
        return 'Norsk bokmål';
      case AppLocale.bg:
        return 'Български';
      case AppLocale.tr:
        return 'Türkçe';
      case AppLocale.az:
        return 'Azərbaycanca';
      case AppLocale.kk:
        return 'Қазақша';
      case AppLocale.uz:
        return 'Oʻzbekcha';
    }
  }
}
