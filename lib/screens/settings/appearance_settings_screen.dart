import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/settings_service.dart' as settings;
import '../../focus/focusable_slider.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/settings_section.dart';
import 'settings_utils.dart';

class AppearanceSettingsScreen extends StatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  State<AppearanceSettingsScreen> createState() => _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen> {
  late settings.SettingsService _settingsService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settingsService = await settings.SettingsService.getInstance();
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return FocusedScrollScaffold(
        title: Text(t.settings.appearance),
        slivers: [const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))],
      );
    }

    return FocusedScrollScaffold(
      title: Text(t.settings.appearance),
      slivers: [
        SliverList(
          delegate: SliverChildListDelegate([
            // --- Display ---
            SettingsSectionHeader(t.settings.display),
            _buildThemeSelector(),
            _buildLanguageSelector(),
            _buildDensitySelector(),
            _buildViewModeSelector(),
            _buildEpisodePosterModeSelector(),
            _buildShowEpisodeNumberOnCards(),
            _buildShowSeasonPostersOnTabs(),

            // --- Home Screen ---
            SettingsSectionHeader(t.settings.homeScreen),
            _buildShowHeroSection(),
            _buildUseGlobalHubs(),
            _buildShowServerNameOnHubs(),

            // --- Navigation ---
            SettingsSectionHeader(t.settings.navigation),
            if (Platform.isAndroid) _buildForceTvMode(),
            if (PlatformDetector.shouldUseSideNavigation(context)) _buildAlwaysKeepSidebarOpen(),
            if (PlatformDetector.shouldUseSideNavigation(context)) _buildGroupLibrariesByServer(),
            if (!PlatformDetector.shouldUseSideNavigation(context)) _buildShowNavBarLabels(),
            _buildShowUnwatchedCount(),

            // --- Window (Windows/Linux only) ---
            if (Platform.isWindows || Platform.isLinux) ...[
              SettingsSectionHeader(t.settings.window),
              _buildStartInFullscreen(),
            ],

            // --- Content ---
            SettingsSectionHeader(t.settings.content),
            _buildLiveTvDefaultFavorites(),
            _buildHideSpoilers(),
            _buildRequireProfileSelection(),
            if (PlatformDetector.isTV()) _buildConfirmExitOnBack(),
            _buildAutoHidePerformanceOverlay(),
            const SizedBox(height: 24),
          ]),
        ),
      ],
    );
  }

  // --- Display section ---

  Widget _buildThemeSelector() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
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
          onChanged: (value) => themeProvider.setThemeMode(value),
        );
      },
    );
  }

  Widget _buildLanguageSelector() {
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
          await _settingsService.write(settings.SettingsService.appLocale, value);
          unawaited(LocaleSettings.setLocale(value));
          _restartApp();
        }
      },
    );
  }

  Widget _buildDensitySelector() {
    return Selector<SettingsProvider, int>(
      selector: (_, p) => p.libraryDensity,
      builder: (context, density, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                      onChanged: (value) => context.read<SettingsProvider>().setLibraryDensity(value.round()),
                    ),
                  ),
                  Text(t.settings.comfortable, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildViewModeSelector() {
    return Selector<SettingsProvider, settings.ViewMode>(
      selector: (_, p) => p.viewMode,
      builder: (context, viewMode, _) {
        return SegmentedSetting<settings.ViewMode>(
          icon: Symbols.view_list_rounded,
          title: t.settings.viewMode,
          segments: [
            ButtonSegment(value: settings.ViewMode.grid, label: Text(t.settings.gridView)),
            ButtonSegment(value: settings.ViewMode.list, label: Text(t.settings.listView)),
          ],
          selected: viewMode,
          onChanged: (value) => context.read<SettingsProvider>().setViewMode(value),
        );
      },
    );
  }

  Widget _buildEpisodePosterModeSelector() {
    return Selector<SettingsProvider, settings.EpisodePosterMode>(
      selector: (_, p) => p.episodePosterMode,
      builder: (context, mode, _) {
        return SegmentedSetting<settings.EpisodePosterMode>(
          icon: Symbols.image_rounded,
          title: t.settings.episodePosterMode,
          segments: [
            ButtonSegment(value: settings.EpisodePosterMode.seriesPoster, label: Text(t.settings.seriesPoster)),
            ButtonSegment(value: settings.EpisodePosterMode.seasonPoster, label: Text(t.settings.seasonPoster)),
            ButtonSegment(value: settings.EpisodePosterMode.episodeThumbnail, label: Text(t.settings.episodeThumbnail)),
          ],
          selected: mode,
          onChanged: (value) => context.read<SettingsProvider>().setEpisodePosterMode(value),
        );
      },
    );
  }

  Widget _buildShowEpisodeNumberOnCards() => _buildBoolToggle(
    icon: Symbols.tag_rounded,
    title: t.settings.showEpisodeNumberOnCards,
    subtitle: t.settings.showEpisodeNumberOnCardsDescription,
    getter: (p) => p.showEpisodeNumberOnCards,
    setter: (p, v) => p.setShowEpisodeNumberOnCards(v),
  );

  Widget _buildShowSeasonPostersOnTabs() => _buildBoolToggle(
    icon: Symbols.image_rounded,
    title: t.settings.showSeasonPostersOnTabs,
    subtitle: t.settings.showSeasonPostersOnTabsDescription,
    getter: (p) => p.showSeasonPostersOnTabs,
    setter: (p, v) => p.setShowSeasonPostersOnTabs(v),
  );

  /// Shared scaffolding for the bool toggles on this screen. Each toggle
  /// watches one `SettingsProvider` field via `Selector`, so flipping one
  /// switch doesn't rebuild the others.
  Widget _buildBoolToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool Function(SettingsProvider) getter,
    required Future<void> Function(SettingsProvider, bool) setter,
  }) {
    return Selector<SettingsProvider, bool>(
      selector: (_, p) => getter(p),
      builder: (context, value, _) => SwitchListTile(
        secondary: AppIcon(icon, fill: 1),
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: (v) => setter(context.read<SettingsProvider>(), v),
      ),
    );
  }

  // --- Home Screen section ---

  Widget _buildShowHeroSection() => _buildBoolToggle(
    icon: Symbols.featured_play_list_rounded,
    title: t.settings.showHeroSection,
    subtitle: t.settings.showHeroSectionDescription,
    getter: (p) => p.showHeroSection,
    setter: (p, v) => p.setShowHeroSection(v),
  );

  Widget _buildUseGlobalHubs() => _buildBoolToggle(
    icon: Symbols.home_rounded,
    title: t.settings.useGlobalHubs,
    subtitle: t.settings.useGlobalHubsDescription,
    getter: (p) => p.useGlobalHubs,
    setter: (p, v) => p.setUseGlobalHubs(v),
  );

  Widget _buildShowServerNameOnHubs() => _buildBoolToggle(
    icon: Symbols.dns_rounded,
    title: t.settings.showServerNameOnHubs,
    subtitle: t.settings.showServerNameOnHubsDescription,
    getter: (p) => p.showServerNameOnHubs,
    setter: (p, v) => p.setShowServerNameOnHubs(v),
  );

  // --- Navigation section ---

  Widget _buildAlwaysKeepSidebarOpen() => _buildBoolToggle(
    icon: Symbols.dock_to_left_rounded,
    title: t.settings.alwaysKeepSidebarOpen,
    subtitle: t.settings.alwaysKeepSidebarOpenDescription,
    getter: (p) => p.alwaysKeepSidebarOpen,
    setter: (p, v) => p.setAlwaysKeepSidebarOpen(v),
  );

  Widget _buildGroupLibrariesByServer() => _buildBoolToggle(
    icon: Symbols.dns_rounded,
    title: t.settings.groupLibrariesByServer,
    subtitle: t.settings.groupLibrariesByServerDescription,
    getter: (p) => p.groupLibrariesByServer,
    setter: (p, v) => p.setGroupLibrariesByServer(v),
  );

  Widget _buildShowNavBarLabels() => _buildBoolToggle(
    icon: Symbols.label_rounded,
    title: t.settings.showNavBarLabels,
    subtitle: t.settings.showNavBarLabelsDescription,
    getter: (p) => p.showNavBarLabels,
    setter: (p, v) => p.setShowNavBarLabels(v),
  );

  Widget _buildShowUnwatchedCount() => _buildBoolToggle(
    icon: Symbols.counter_1_rounded,
    title: t.settings.showUnwatchedCount,
    subtitle: t.settings.showUnwatchedCountDescription,
    getter: (p) => p.showUnwatchedCount,
    setter: (p, v) => p.setShowUnwatchedCount(v),
  );

  // --- Content section ---

  Widget _buildLiveTvDefaultFavorites() => _buildBoolToggle(
    icon: Symbols.star_rounded,
    title: t.settings.liveTvDefaultFavorites,
    subtitle: t.settings.liveTvDefaultFavoritesDescription,
    getter: (p) => p.liveTvDefaultFavorites,
    setter: (p, v) => p.setLiveTvDefaultFavorites(v),
  );

  Widget _buildHideSpoilers() => _buildBoolToggle(
    icon: Symbols.visibility_off_rounded,
    title: t.settings.hideSpoilers,
    subtitle: t.settings.hideSpoilersDescription,
    getter: (p) => p.hideSpoilers,
    setter: (p, v) => p.setHideSpoilers(v),
  );

  Widget _buildAutoHidePerformanceOverlay() => _buildBoolToggle(
    icon: Symbols.speed_rounded,
    title: t.settings.autoHidePerformanceOverlay,
    subtitle: t.settings.autoHidePerformanceOverlayDescription,
    getter: (p) => p.autoHidePerformanceOverlay,
    setter: (p, v) => p.setAutoHidePerformanceOverlay(v),
  );

  Widget _buildRequireProfileSelection() {
    return Consumer<UserProfileProvider>(
      builder: (context, userProfileProvider, child) {
        if (!userProfileProvider.hasMultipleUsers) return const SizedBox.shrink();
        return _buildListenableSwitch(
          icon: Symbols.person_rounded,
          title: t.settings.requireProfileSelectionOnOpen,
          subtitle: t.settings.requireProfileSelectionOnOpenDescription,
          pref: settings.SettingsService.requireProfileSelectionOnOpen,
        );
      },
    );
  }

  Widget _buildConfirmExitOnBack() => _buildListenableSwitch(
    icon: Symbols.exit_to_app_rounded,
    title: t.settings.confirmExitOnBack,
    subtitle: t.settings.confirmExitOnBackDescription,
    pref: settings.SettingsService.confirmExitOnBack,
  );

  Widget _buildStartInFullscreen() => _buildListenableSwitch(
    icon: Symbols.fullscreen_rounded,
    title: t.settings.startInFullscreen,
    subtitle: t.settings.startInFullscreenDescription,
    pref: settings.SettingsService.startInFullscreen,
  );

  Widget _buildForceTvMode() => _buildListenableSwitch(
    icon: Symbols.tv_rounded,
    title: t.settings.forceTvMode,
    subtitle: t.settings.forceTvModeDescription,
    pref: settings.SettingsService.forceTvMode,
    onAfterWrite: (value) {
      TvDetectionService.setForceTVSync(value);
      if (mounted) _restartApp();
    },
  );

  /// Generic bool toggle that listens to a [Pref] directly via [ValueNotifier].
  /// No local state; rebuilds across the app stay consistent.
  Widget _buildListenableSwitch({
    required IconData icon,
    required String title,
    required String subtitle,
    required settings.Pref<bool> pref,
    void Function(bool)? onAfterWrite,
  }) {
    return ValueListenableBuilder<bool>(
      valueListenable: _settingsService.listenable(pref),
      builder: (_, value, _) => SwitchListTile(
        secondary: AppIcon(icon, fill: 1),
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: (v) async {
          await _settingsService.write(pref, v);
          onAfterWrite?.call(v);
        },
      ),
    );
  }

  // --- Helpers ---

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

  void _restartApp() {
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }
}
