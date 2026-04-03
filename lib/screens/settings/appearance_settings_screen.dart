import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/settings_service.dart' as settings;
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
  bool _requireProfileSelectionOnOpen = false;
  bool _confirmExitOnBack = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settingsService = await settings.SettingsService.getInstance();
    if (!mounted) return;
    setState(() {
      _requireProfileSelectionOnOpen = _settingsService.getRequireProfileSelectionOnOpen();
      _confirmExitOnBack = _settingsService.getConfirmExitOnBack();
      _isLoading = false;
    });
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

            // --- Home Screen ---
            SettingsSectionHeader(t.settings.homeScreen),
            _buildShowHeroSection(),
            _buildUseGlobalHubs(),
            _buildShowServerNameOnHubs(),

            // --- Navigation ---
            SettingsSectionHeader(t.settings.navigation),
            if (PlatformDetector.shouldUseSideNavigation(context)) _buildAlwaysKeepSidebarOpen(),
            if (!PlatformDetector.shouldUseSideNavigation(context)) _buildShowNavBarLabels(),
            _buildShowUnwatchedCount(),

            // --- Content ---
            SettingsSectionHeader(t.settings.content),
            _buildLiveTvDefaultFavorites(),
            _buildHideSpoilers(),
            _buildRequireProfileSelection(),
            if (PlatformDetector.isTV()) _buildConfirmExitOnBack(),
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
          await _settingsService.setAppLocale(value);
          LocaleSettings.setLocale(value);
          _restartApp();
        }
      },
    );
  }

  Widget _buildDensitySelector() {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
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
                    child: Slider(
                      value: settingsProvider.libraryDensity.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      onChanged: (value) => settingsProvider.setLibraryDensity(value.round()),
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
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return SegmentedSetting<settings.ViewMode>(
          icon: Symbols.view_list_rounded,
          title: t.settings.viewMode,
          segments: [
            ButtonSegment(value: settings.ViewMode.grid, label: Text(t.settings.gridView)),
            ButtonSegment(value: settings.ViewMode.list, label: Text(t.settings.listView)),
          ],
          selected: settingsProvider.viewMode,
          onChanged: (value) => settingsProvider.setViewMode(value),
        );
      },
    );
  }

  Widget _buildEpisodePosterModeSelector() {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return SegmentedSetting<settings.EpisodePosterMode>(
          icon: Symbols.image_rounded,
          title: t.settings.episodePosterMode,
          segments: [
            ButtonSegment(value: settings.EpisodePosterMode.seriesPoster, label: Text(t.settings.seriesPoster)),
            ButtonSegment(value: settings.EpisodePosterMode.seasonPoster, label: Text(t.settings.seasonPoster)),
            ButtonSegment(value: settings.EpisodePosterMode.episodeThumbnail, label: Text(t.settings.episodeThumbnail)),
          ],
          selected: settingsProvider.episodePosterMode,
          onChanged: (value) => settingsProvider.setEpisodePosterMode(value),
        );
      },
    );
  }

  // --- Home Screen section ---

  Widget _buildShowHeroSection() {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return SwitchListTile(
          secondary: const AppIcon(Symbols.featured_play_list_rounded, fill: 1),
          title: Text(t.settings.showHeroSection),
          subtitle: Text(t.settings.showHeroSectionDescription),
          value: settingsProvider.showHeroSection,
          onChanged: (value) async {
            await settingsProvider.setShowHeroSection(value);
          },
        );
      },
    );
  }

  Widget _buildUseGlobalHubs() {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return SwitchListTile(
          secondary: const AppIcon(Symbols.home_rounded, fill: 1),
          title: Text(t.settings.useGlobalHubs),
          subtitle: Text(t.settings.useGlobalHubsDescription),
          value: settingsProvider.useGlobalHubs,
          onChanged: (value) async {
            await settingsProvider.setUseGlobalHubs(value);
          },
        );
      },
    );
  }

  Widget _buildShowServerNameOnHubs() {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return SwitchListTile(
          secondary: const AppIcon(Symbols.dns_rounded, fill: 1),
          title: Text(t.settings.showServerNameOnHubs),
          subtitle: Text(t.settings.showServerNameOnHubsDescription),
          value: settingsProvider.showServerNameOnHubs,
          onChanged: (value) async {
            await settingsProvider.setShowServerNameOnHubs(value);
          },
        );
      },
    );
  }

  // --- Navigation section ---

  Widget _buildAlwaysKeepSidebarOpen() {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return SwitchListTile(
          secondary: const AppIcon(Symbols.dock_to_left_rounded, fill: 1),
          title: Text(t.settings.alwaysKeepSidebarOpen),
          subtitle: Text(t.settings.alwaysKeepSidebarOpenDescription),
          value: settingsProvider.alwaysKeepSidebarOpen,
          onChanged: (value) async {
            await settingsProvider.setAlwaysKeepSidebarOpen(value);
          },
        );
      },
    );
  }

  Widget _buildShowNavBarLabels() {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return SwitchListTile(
          secondary: const AppIcon(Symbols.label_rounded, fill: 1),
          title: Text(t.settings.showNavBarLabels),
          subtitle: Text(t.settings.showNavBarLabelsDescription),
          value: settingsProvider.showNavBarLabels,
          onChanged: (value) async {
            await settingsProvider.setShowNavBarLabels(value);
          },
        );
      },
    );
  }

  Widget _buildShowUnwatchedCount() {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return SwitchListTile(
          secondary: const AppIcon(Symbols.counter_1_rounded, fill: 1),
          title: Text(t.settings.showUnwatchedCount),
          subtitle: Text(t.settings.showUnwatchedCountDescription),
          value: settingsProvider.showUnwatchedCount,
          onChanged: (value) async {
            await settingsProvider.setShowUnwatchedCount(value);
          },
        );
      },
    );
  }

  // --- Content section ---

  Widget _buildLiveTvDefaultFavorites() {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return SwitchListTile(
          secondary: const AppIcon(Symbols.star_rounded, fill: 1),
          title: Text(t.settings.liveTvDefaultFavorites),
          subtitle: Text(t.settings.liveTvDefaultFavoritesDescription),
          value: settingsProvider.liveTvDefaultFavorites,
          onChanged: (value) async {
            await settingsProvider.setLiveTvDefaultFavorites(value);
          },
        );
      },
    );
  }

  Widget _buildHideSpoilers() {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return SwitchListTile(
          secondary: const AppIcon(Symbols.visibility_off_rounded, fill: 1),
          title: Text(t.settings.hideSpoilers),
          subtitle: Text(t.settings.hideSpoilersDescription),
          value: settingsProvider.hideSpoilers,
          onChanged: (value) async {
            await settingsProvider.setHideSpoilers(value);
          },
        );
      },
    );
  }

  Widget _buildRequireProfileSelection() {
    return Consumer<UserProfileProvider>(
      builder: (context, userProfileProvider, child) {
        if (!userProfileProvider.hasMultipleUsers) return const SizedBox.shrink();
        return SwitchListTile(
          secondary: const AppIcon(Symbols.person_rounded, fill: 1),
          title: Text(t.settings.requireProfileSelectionOnOpen),
          subtitle: Text(t.settings.requireProfileSelectionOnOpenDescription),
          value: _requireProfileSelectionOnOpen,
          onChanged: (value) async {
            setState(() => _requireProfileSelectionOnOpen = value);
            await _settingsService.setRequireProfileSelectionOnOpen(value);
          },
        );
      },
    );
  }

  Widget _buildConfirmExitOnBack() {
    return SwitchListTile(
      secondary: const AppIcon(Symbols.exit_to_app_rounded, fill: 1),
      title: Text(t.settings.confirmExitOnBack),
      subtitle: Text(t.settings.confirmExitOnBackDescription),
      value: _confirmExitOnBack,
      onChanged: (value) async {
        setState(() => _confirmExitOnBack = value);
        await _settingsService.setConfirmExitOnBack(value);
      },
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
