import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../providers/theme_provider.dart';
import '../../profiles/active_profile_provider.dart';
import '../../services/settings_service.dart' hide ThemeMode;
import '../../services/settings_service.dart' as settings show ThemeMode;
import '../../focus/focusable_slider.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/setting_tile.dart';
import '../../widgets/settings_builder.dart';
import '../../widgets/settings_section.dart';
import 'settings_utils.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FocusedScrollScaffold(
      title: Text(t.settings.appearance),
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate([
            SettingsSectionHeader(t.settings.display),
            _themeSelector(),
            _languageSelector(context),
            _densitySelector(),
            _viewModeSelector(),
            _episodePosterModeSelector(),
            SettingSwitchTile(
              pref: SettingsService.showEpisodeNumberOnCards,
              icon: Symbols.tag_rounded,
              title: t.settings.showEpisodeNumberOnCards,
              subtitle: t.settings.showEpisodeNumberOnCardsDescription,
            ),
            SettingSwitchTile(
              pref: SettingsService.showSeasonPostersOnTabs,
              icon: Symbols.image_rounded,
              title: t.settings.showSeasonPostersOnTabs,
              subtitle: t.settings.showSeasonPostersOnTabsDescription,
            ),

            SettingsSectionHeader(t.settings.homeScreen),
            SettingSwitchTile(
              pref: SettingsService.showHeroSection,
              icon: Symbols.featured_play_list_rounded,
              title: t.settings.showHeroSection,
              subtitle: t.settings.showHeroSectionDescription,
            ),
            SettingSwitchTile(
              pref: SettingsService.useGlobalHubs,
              icon: Symbols.home_rounded,
              title: t.settings.useGlobalHubs,
              subtitle: t.settings.useGlobalHubsDescription,
            ),
            SettingSwitchTile(
              pref: SettingsService.showServerNameOnHubs,
              icon: Symbols.dns_rounded,
              title: t.settings.showServerNameOnHubs,
              subtitle: t.settings.showServerNameOnHubsDescription,
            ),

            SettingsSectionHeader(t.settings.navigation),
            if (Platform.isAndroid)
              SettingSwitchTile(
                pref: SettingsService.forceTvMode,
                icon: Symbols.tv_rounded,
                title: t.settings.forceTvMode,
                subtitle: t.settings.forceTvModeDescription,
                onAfterWrite: (value) {
                  TvDetectionService.setForceTVSync(value);
                  _restartApp(context);
                },
              ),
            if (PlatformDetector.shouldUseSideNavigation(context))
              SettingSwitchTile(
                pref: SettingsService.alwaysKeepSidebarOpen,
                icon: Symbols.dock_to_left_rounded,
                title: t.settings.alwaysKeepSidebarOpen,
                subtitle: t.settings.alwaysKeepSidebarOpenDescription,
              ),
            if (PlatformDetector.shouldUseSideNavigation(context))
              SettingSwitchTile(
                pref: SettingsService.groupLibrariesByServer,
                icon: Symbols.dns_rounded,
                title: t.settings.groupLibrariesByServer,
                subtitle: t.settings.groupLibrariesByServerDescription,
              ),
            if (!PlatformDetector.shouldUseSideNavigation(context))
              SettingSwitchTile(
                pref: SettingsService.showNavBarLabels,
                icon: Symbols.label_rounded,
                title: t.settings.showNavBarLabels,
                subtitle: t.settings.showNavBarLabelsDescription,
              ),
            SettingSwitchTile(
              pref: SettingsService.showUnwatchedCount,
              icon: Symbols.counter_1_rounded,
              title: t.settings.showUnwatchedCount,
              subtitle: t.settings.showUnwatchedCountDescription,
            ),

            if (Platform.isWindows || Platform.isLinux) ...[
              SettingsSectionHeader(t.settings.window),
              SettingSwitchTile(
                pref: SettingsService.startInFullscreen,
                icon: Symbols.fullscreen_rounded,
                title: t.settings.startInFullscreen,
                subtitle: t.settings.startInFullscreenDescription,
              ),
            ],

            SettingsSectionHeader(t.settings.content),
            SettingSwitchTile(
              pref: SettingsService.liveTvDefaultFavorites,
              icon: Symbols.star_rounded,
              title: t.settings.liveTvDefaultFavorites,
              subtitle: t.settings.liveTvDefaultFavoritesDescription,
            ),
            SettingSwitchTile(
              pref: SettingsService.hideSpoilers,
              icon: Symbols.visibility_off_rounded,
              title: t.settings.hideSpoilers,
              subtitle: t.settings.hideSpoilersDescription,
            ),
            _requireProfileSelection(),
            if (PlatformDetector.isTV())
              SettingSwitchTile(
                pref: SettingsService.confirmExitOnBack,
                icon: Symbols.exit_to_app_rounded,
                title: t.settings.confirmExitOnBack,
                subtitle: t.settings.confirmExitOnBackDescription,
              ),
            SettingSwitchTile(
              pref: SettingsService.autoHidePerformanceOverlay,
              icon: Symbols.speed_rounded,
              title: t.settings.autoHidePerformanceOverlay,
              subtitle: t.settings.autoHidePerformanceOverlayDescription,
            ),
            const SizedBox(height: 24),
          ]),
        ),
      ],
    );
  }

  Widget _themeSelector() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return SegmentedSetting<settings.ThemeMode>(
          icon: themeProvider.themeModeIcon,
          title: t.settings.theme,
          segments: [
            ButtonSegment(value: settings.ThemeMode.system, label: Text(t.settings.systemTheme)),
            ButtonSegment(value: settings.ThemeMode.light, label: Text(t.settings.lightTheme)),
            ButtonSegment(value: settings.ThemeMode.dark, label: Text(t.settings.darkTheme)),
            ButtonSegment(value: settings.ThemeMode.oled, label: Text(t.settings.oledTheme)),
          ],
          selected: themeProvider.themeMode,
          onChanged: themeProvider.setThemeMode,
        );
      },
    );
  }

  Widget _languageSelector(BuildContext context) {
    return ListTile(
      leading: const AppIcon(Symbols.language_rounded, fill: 1),
      title: Text(t.settings.language),
      subtitle: Text(_getLanguageDisplayName(LocaleSettings.currentLocale)),
      trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
      onTap: () async {
        final value = await showSelectionDialog<AppLocale>(
          context: context,
          title: t.settings.language,
          options: AppLocale.values
              .map((locale) => DialogOption(value: locale, title: _getLanguageDisplayName(locale)))
              .toList(),
          currentValue: LocaleSettings.currentLocale,
        );
        if (value != null) {
          await SettingsService.instanceOrNull!.write(SettingsService.appLocale, value);
          unawaited(LocaleSettings.setLocale(value));
          if (context.mounted) _restartApp(context);
        }
      },
    );
  }

  Widget _densitySelector() {
    return SettingValueBuilder<int>(
      pref: SettingsService.libraryDensity,
      builder: (_, density, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const AppIcon(Symbols.grid_view_rounded, fill: 1),
            const SizedBox(width: 16),
            Text(t.settings.compact, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Expanded(
              child: FocusableSlider(
                value: density.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                onChanged: (v) => SettingsService.instanceOrNull!.write(SettingsService.libraryDensity, v.round()),
              ),
            ),
            Text(t.settings.comfortable, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _viewModeSelector() => SettingSegmentedTile<ViewMode, ViewMode>(
    pref: SettingsService.viewMode,
    icon: Symbols.view_list_rounded,
    title: t.settings.viewMode,
    segments: [
      ButtonSegment(value: ViewMode.grid, label: Text(t.settings.gridView)),
      ButtonSegment(value: ViewMode.list, label: Text(t.settings.listView)),
    ],
    decode: (v) => v,
    encode: (v) => v,
  );

  Widget _episodePosterModeSelector() => SettingSegmentedTile<EpisodePosterMode, EpisodePosterMode>(
    pref: SettingsService.episodePosterMode,
    icon: Symbols.image_rounded,
    title: t.settings.episodePosterMode,
    segments: [
      ButtonSegment(value: EpisodePosterMode.seriesPoster, label: Text(t.settings.seriesPoster)),
      ButtonSegment(value: EpisodePosterMode.seasonPoster, label: Text(t.settings.seasonPoster)),
      ButtonSegment(value: EpisodePosterMode.episodeThumbnail, label: Text(t.settings.episodeThumbnail)),
    ],
    decode: (v) => v,
    encode: (v) => v,
  );

  Widget _requireProfileSelection() {
    return Consumer<ActiveProfileProvider>(
      builder: (context, activeProvider, _) {
        if (!activeProvider.hasMultipleProfiles) return const SizedBox.shrink();
        return SettingSwitchTile(
          pref: SettingsService.requireProfileSelectionOnOpen,
          icon: Symbols.person_rounded,
          title: t.settings.requireProfileSelectionOnOpen,
          subtitle: t.settings.requireProfileSelectionOnOpenDescription,
        );
      },
    );
  }

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
      case AppLocale.zh:
        return '中文';
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
    }
  }

  void _restartApp(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }
}
