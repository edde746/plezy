import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../providers/multi_server_provider.dart';
import '../../providers/theme_provider.dart';
import '../../profiles/active_profile_provider.dart';
import '../../navigation/navigation_tabs.dart';
import '../../services/settings_service.dart' hide ThemeMode;
import '../../services/settings_service.dart' as settings show ThemeMode;
import '../../focus/focusable_slider.dart';
import '../../services/device_performance.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/setting_tile.dart';
import '../../widgets/settings_page.dart';
import '../../widgets/settings_builder.dart';
import '../../widgets/settings_section.dart';
import 'settings_utils.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watched at build level so the tile can be excluded with a plain `if` —
    // a child that renders SizedBox.shrink() would corrupt the group corners.
    final hasMultipleProfiles = context.watch<ActiveProfileProvider>().hasMultipleProfiles;
    return SettingsPage(
      title: Text(t.settings.appearance),
      children: [
        SettingsGroup(
          title: t.settings.display,
          children: [
            _themeSelector(),
            _languageSelector(context),
            _densitySelector(),
            _viewModeSelector(),
            _episodePosterModeSelector(),
            if (PlatformDetector.isTV())
              SettingSwitchTile(
                pref: SettingsService.tvFullCardLayout,
                icon: Symbols.image_rounded,
                title: t.settings.tvFullCardLayout,
                subtitle: t.settings.tvFullCardLayoutDescription,
              ),
            if (PlatformDetector.isTV())
              SettingSwitchTile(
                pref: SettingsService.focusGlow,
                icon: Symbols.lightbulb_rounded,
                title: t.settings.focusGlow,
                subtitle: t.settings.focusGlowDescription,
              ),
            if (Platform.isAndroid) _visualEffectsSelector(context),
            SettingSwitchTile(
              pref: SettingsService.showEpisodeNumberOnCards,
              icon: Symbols.tag_rounded,
              title: t.settings.showEpisodeNumberOnCards,
              subtitle: t.settings.showEpisodeNumberOnCardsDescription,
            ),
            if (!PlatformDetector.isTV())
              SettingSwitchTile(
                pref: SettingsService.showSeasonPostersOnTabs,
                icon: Symbols.image_rounded,
                title: t.settings.showSeasonPostersOnTabs,
                subtitle: t.settings.showSeasonPostersOnTabsDescription,
              ),
          ],
        ),

        SettingsGroup(
          title: t.settings.homeScreen,
          children: [
            if (!PlatformDetector.isTV())
              SettingSwitchTile(
                pref: SettingsService.showHeroSection,
                icon: Symbols.featured_play_list_rounded,
                title: t.settings.showHeroSection,
                subtitle: t.settings.showHeroSectionDescription,
              ),
            _continueWatchingActionSelector(),
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
          ],
        ),

        SettingsGroup(
          title: t.settings.navigation,
          children: [
            _startupSectionSelector(),
            if (Platform.isAndroid || PlatformDetector.isDesktopOS())
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
              SettingSwitchTile(
                pref: SettingsService.exitFullscreenOnPlayerClose,
                icon: Symbols.fullscreen_exit_rounded,
                title: t.settings.exitFullscreenOnPlayerClose,
                subtitle: t.settings.exitFullscreenOnPlayerCloseDescription,
              ),
            ],
          ),

        SettingsGroup(
          title: t.settings.content,
          children: [
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
            _episodeActionSelector(),
            if (hasMultipleProfiles)
              SettingSwitchTile(
                pref: SettingsService.requireProfileSelectionOnOpen,
                icon: Symbols.person_rounded,
                title: t.settings.requireProfileSelectionOnOpen,
                subtitle: t.settings.requireProfileSelectionOnOpenDescription,
              ),
            SettingSwitchTile(
              pref: SettingsService.autoHidePerformanceOverlay,
              icon: Symbols.speed_rounded,
              title: t.settings.autoHidePerformanceOverlay,
              subtitle: t.settings.autoHidePerformanceOverlayDescription,
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  String _themeModeLabel(settings.ThemeMode mode) => switch (mode) {
    settings.ThemeMode.system => t.settings.systemTheme,
    settings.ThemeMode.light => t.settings.lightTheme,
    settings.ThemeMode.dark => t.settings.darkTheme,
    settings.ThemeMode.oled => t.settings.oledTheme,
  };

  // Writes the pref directly; ThemeProvider listens to the pref's listenable
  // and applies the change live. The Consumer only feeds the dynamic icon.
  Widget _themeSelector() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return SettingSelectionTile<settings.ThemeMode, settings.ThemeMode>(
          pref: SettingsService.themeMode,
          icon: themeProvider.themeModeIcon,
          title: t.settings.theme,
          subtitleBuilder: _themeModeLabel,
          options: settings.ThemeMode.values.map((m) => DialogOption(value: m, title: _themeModeLabel(m))).toList(),
          decode: (v) => v,
          encode: (v) => v,
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
          await SettingsService.instance.write(SettingsService.appLocale, value);
          unawaited(LocaleSettings.setLocale(value));
          if (context.mounted) {
            context.read<MultiServerProvider>().serverManager.updatePlexLanguage(value.languageCode);
          }
          if (context.mounted) _restartApp(context);
        }
      },
    );
  }

  // Same label-row-plus-control layout as SegmentedSetting so slider and
  // button-group tiles read as one family inside a SettingsGroup.
  Widget _densitySelector() {
    return SettingValueBuilder<int>(
      pref: SettingsService.libraryDensity,
      builder: (context, density, _) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Row(
                children: [
                  const AppIcon(Symbols.grid_view_rounded, fill: 1),
                  const SizedBox(width: 16),
                  Text(t.settings.libraryDensity, style: theme.textTheme.bodyLarge),
                ],
              ),
              const SizedBox(height: 12),
              FocusableSlider(
                value: density.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                onChanged: (v) => SettingsService.instance.write(SettingsService.libraryDensity, v.round()),
              ),
              Row(
                mainAxisAlignment: .spaceBetween,
                children: [
                  Text(t.settings.compact, style: theme.textTheme.bodySmall),
                  Text(t.settings.comfortable, style: theme.textTheme.bodySmall),
                ],
              ),
            ],
          ),
        );
      },
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

  Widget _continueWatchingActionSelector() => SettingSegmentedTile<ContinueWatchingAction, ContinueWatchingAction>(
    pref: SettingsService.continueWatchingAction,
    icon: Symbols.play_circle_rounded,
    title: t.settings.continueWatchingAction,
    segments: [
      ButtonSegment(value: ContinueWatchingAction.play, label: Text(t.settings.continueWatchingPlay)),
      ButtonSegment(value: ContinueWatchingAction.details, label: Text(t.settings.continueWatchingDetails)),
    ],
    decode: (v) => v,
    encode: (v) => v,
  );

  Widget _episodeActionSelector() => SettingSegmentedTile<EpisodeAction, EpisodeAction>(
    pref: SettingsService.episodeAction,
    icon: Symbols.tv_rounded,
    title: t.settings.episodeAction,
    segments: [
      ButtonSegment(value: EpisodeAction.play, label: Text(t.settings.episodePlay)),
      ButtonSegment(value: EpisodeAction.details, label: Text(t.settings.episodeDetails)),
    ],
    decode: (v) => v,
    encode: (v) => v,
  );

  // Sections offered as a startup destination, in display order. Live TV is
  // always listed; if no server provides it, startup falls back to Home.
  static const _startupSectionOptions = [
    NavigationTabId.discover,
    NavigationTabId.libraries,
    NavigationTabId.liveTv,
    NavigationTabId.search,
  ];

  String _startupSectionLabel(NavigationTabId id) => allNavigationTabs.firstWhere((t) => t.id == id).getLabel();

  Widget _startupSectionSelector() => SettingSelectionTile<NavigationTabId, NavigationTabId>(
    pref: SettingsService.startupSection,
    icon: Symbols.start_rounded,
    title: t.settings.startupSection,
    subtitleBuilder: _startupSectionLabel,
    options: _startupSectionOptions.map((id) => DialogOption(value: id, title: _startupSectionLabel(id))).toList(),
    decode: (v) => v,
    encode: (v) => v,
  );

  String _visualEffectsLabel(VisualEffectsSetting value) => switch (value) {
    VisualEffectsSetting.auto => t.settings.visualEffectsAuto,
    VisualEffectsSetting.full => t.settings.visualEffectsFull,
    VisualEffectsSetting.reduced => t.settings.visualEffectsReduced,
  };

  Widget _visualEffectsSelector(BuildContext context) =>
      SettingSelectionTile<VisualEffectsSetting, VisualEffectsSetting>(
        pref: SettingsService.visualEffects,
        icon: Symbols.animation_rounded,
        title: t.settings.visualEffects,
        subtitleBuilder: _visualEffectsLabel,
        options: [
          DialogOption(
            value: VisualEffectsSetting.auto,
            title: t.settings.visualEffectsAuto,
            subtitle: t.settings.visualEffectsAutoDescription,
          ),
          DialogOption(value: VisualEffectsSetting.full, title: t.settings.visualEffectsFull),
          DialogOption(
            value: VisualEffectsSetting.reduced,
            title: t.settings.visualEffectsReduced,
            subtitle: t.settings.visualEffectsReducedDescription,
          ),
        ],
        decode: (v) => v,
        encode: (v) => v,
        onAfterWrite: (value) {
          DevicePerformance.setOverrideSync(value);
          _restartApp(context);
        },
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
      case AppLocale.bg:
        return 'Български';
    }
  }

  void _restartApp(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/', (route) => false);
  }
}
