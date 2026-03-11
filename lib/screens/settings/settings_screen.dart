import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../models/hotkey_model.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../focus/dpad_navigator.dart';
import '../../focus/focus_memory_tracker.dart';
import '../../focus/input_mode_tracker.dart';
import '../../i18n/strings.g.dart';
import '../../utils/focus_utils.dart';
import '../main_screen.dart';
import '../../mixins/refreshable.dart';
import '../../services/discord_rpc_service.dart';
import '../../services/download_storage_service.dart';
import '../../services/saf_storage_service.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/keyboard_shortcuts_service.dart';
import '../../mpv/player/platform/player_android.dart';
import '../../services/settings_service.dart' as settings;
import '../../services/update_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/desktop_app_bar.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/overlay_sheet.dart';
import '../../widgets/tv_number_spinner.dart';
import 'hotkey_recorder_widget.dart';
import '../../providers/companion_remote_provider.dart';
import '../../screens/companion_remote/mobile_remote_screen.dart';
import '../../widgets/companion_remote/remote_session_dialog.dart';
import 'about_screen.dart';
import 'external_player_screen.dart';
import 'logs_screen.dart';
import 'mpv_config_screen.dart';
import 'subtitle_styling_screen.dart';

/// Helper class for option selection dialog items
class _DialogOption<T> {
  final T value;
  final String title;
  final String? subtitle;

  const _DialogOption({required this.value, required this.title, this.subtitle});
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with FocusableTab {
  late settings.SettingsService _settingsService;
  late final FocusMemoryTracker _focusTracker;

  // Setting keys for focus tracking
  static const _kTheme = 'theme';
  static const _kLanguage = 'language';
  static const _kLibraryDensity = 'library_density';
  static const _kViewMode = 'view_mode';
  static const _kEpisodePosterMode = 'episode_poster_mode';
  static const _kShowHeroSection = 'show_hero_section';
  static const _kUseGlobalHubs = 'use_global_hubs';
  static const _kShowServerNameOnHubs = 'show_server_name_on_hubs';
  static const _kAlwaysKeepSidebarOpen = 'always_keep_sidebar_open';
  static const _kShowUnwatchedCount = 'show_unwatched_count';
  static const _kHideSpoilers = 'hide_spoilers';
  static const _kShowNavBarLabels = 'show_nav_bar_labels';
  static const _kRequireProfileSelectionOnOpen = 'require_profile_selection_on_open';
  static const _kConfirmExitOnBack = 'confirm_exit_on_back';
  static const _kPlayerBackend = 'player_backend';
  static const _kExternalPlayer = 'external_player';
  static const _kHardwareDecoding = 'hardware_decoding';
  static const _kAutoPip = 'auto_pip';
  static const _kMatchContentFrameRate = 'match_content_frame_rate';
  static const _kTunneledPlayback = 'tunneled_playback';
  static const _kBufferSize = 'buffer_size';
  static const _kSubtitleStyling = 'subtitle_styling';
  static const _kMpvConfig = 'mpv_config';
  static const _kSmallSkipDuration = 'small_skip_duration';
  static const _kLargeSkipDuration = 'large_skip_duration';
  static const _kDefaultSleepTimer = 'default_sleep_timer';
  static const _kMaxVolume = 'max_volume';
  static const _kDiscordRichPresence = 'discord_rich_presence';
  static const _kRememberTrackSelections = 'remember_track_selections';
  static const _kClickVideoTogglesPlayback = 'click_video_toggles_playback';
  static const _kAutoSkipIntro = 'auto_skip_intro';
  static const _kAutoSkipCredits = 'auto_skip_credits';
  static const _kAutoSkipDelay = 'auto_skip_delay';
  static const _kIntroPattern = 'intro_pattern';
  static const _kCreditsPattern = 'credits_pattern';
  static const _kDownloadLocation = 'download_location';
  static const _kDownloadOnWifiOnly = 'download_on_wifi_only';
  static const _kVideoPlayerControls = 'video_player_controls';
  static const _kVideoPlayerNavigation = 'video_player_navigation';
  static const _kCrashReporting = 'crash_reporting';
  static const _kDebugLogging = 'debug_logging';
  static const _kViewLogs = 'view_logs';
  static const _kClearCache = 'clear_cache';
  static const _kResetSettings = 'reset_settings';
  static const _kCheckForUpdates = 'check_for_updates';
  static const _kAbout = 'about';
  KeyboardShortcutsService? _keyboardService;
  late final bool _keyboardShortcutsSupported = KeyboardShortcutsService.isPlatformSupported();
  bool _isLoading = true;

  bool _crashReporting = true;
  bool _enableDebugLogging = false;
  bool _enableHardwareDecoding = true;
  int _bufferSize = 0;
  int _seekTimeSmall = 10;
  int _seekTimeLarge = 30;
  int _sleepTimerDuration = 30;
  bool _rememberTrackSelections = true;
  bool _clickVideoTogglesPlayback = false;
  bool _autoSkipIntro = false;
  bool _autoSkipCredits = false;
  int _autoSkipDelay = 5;
  String _introPattern = settings.SettingsService.defaultIntroPattern;
  String _creditsPattern = settings.SettingsService.defaultCreditsPattern;
  bool _downloadOnWifiOnly = false;
  bool _videoPlayerNavigationEnabled = false;
  int _maxVolume = 100;
  bool _enableDiscordRPC = false;
  bool _autoPip = true;
  bool _matchContentFrameRate = false;
  bool _tunneledPlayback = true;
  bool _useExoPlayer = true; // Android only: ExoPlayer vs MPV
  bool _requireProfileSelectionOnOpen = false;
  bool _useExternalPlayer = false;
  bool _confirmExitOnBack = true;
  String _selectedExternalPlayerName = '';

  // Update checking state
  bool _isCheckingForUpdate = false;
  Map<String, dynamic>? _updateInfo;

  @override
  void initState() {
    super.initState();
    _focusTracker = FocusMemoryTracker(
      onFocusChanged: () {
        // ignore: no-empty-block - setState triggers rebuild to update focus styling
        if (mounted) setState(() {});
      },
      debugLabelPrefix: 'settings',
    );
    _loadSettings();
  }

  @override
  void dispose() {
    _focusTracker.dispose();
    super.dispose();
  }

  @override
  void focusActiveTabIfReady() {
    if (InputModeTracker.isKeyboardMode(context)) {
      _focusTracker.restoreFocus(fallbackKey: _kTheme);
    }
  }

  /// Navigate focus to the sidebar
  void _navigateToSidebar() {
    MainScreenFocusScope.of(context)?.focusSidebar();
  }

  /// Handle key events for LEFT arrow → sidebar navigation
  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _navigateToSidebar();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _loadSettings() async {
    _settingsService = await settings.SettingsService.getInstance();
    if (_keyboardShortcutsSupported) {
      _keyboardService = await KeyboardShortcutsService.getInstance();
    }

    if (!mounted) return;
    setState(() {
      _crashReporting = _settingsService.getCrashReporting();
      _enableDebugLogging = _settingsService.getEnableDebugLogging();
      _enableHardwareDecoding = _settingsService.getEnableHardwareDecoding();
      _bufferSize = _settingsService.getBufferSize();
      _seekTimeSmall = _settingsService.getSeekTimeSmall();
      _seekTimeLarge = _settingsService.getSeekTimeLarge();
      _sleepTimerDuration = _settingsService.getSleepTimerDuration();
      _rememberTrackSelections = _settingsService.getRememberTrackSelections();
      _clickVideoTogglesPlayback = _settingsService.getClickVideoTogglesPlayback();
      _autoSkipIntro = _settingsService.getAutoSkipIntro();
      _autoSkipCredits = _settingsService.getAutoSkipCredits();
      _autoSkipDelay = _settingsService.getAutoSkipDelay();
      _introPattern = _settingsService.getIntroPattern();
      _creditsPattern = _settingsService.getCreditsPattern();
      _downloadOnWifiOnly = _settingsService.getDownloadOnWifiOnly();
      _videoPlayerNavigationEnabled = _settingsService.getVideoPlayerNavigationEnabled();
      _maxVolume = _settingsService.getMaxVolume();
      _enableDiscordRPC = _settingsService.getEnableDiscordRPC();
      _autoPip = _settingsService.getAutoPip();
      _matchContentFrameRate = _settingsService.getMatchContentFrameRate();
      _tunneledPlayback = _settingsService.getTunneledPlayback();
      _useExoPlayer = _settingsService.getUseExoPlayer();
      _requireProfileSelectionOnOpen = _settingsService.getRequireProfileSelectionOnOpen();
      _useExternalPlayer = _settingsService.getUseExternalPlayer();
      _selectedExternalPlayerName = _settingsService.getSelectedExternalPlayer().name;
      _confirmExitOnBack = _settingsService.getConfirmExitOnBack();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Focus(
        onKeyEvent: _handleKeyEvent,
        child: CustomScrollView(
          slivers: [
            ExcludeFocus(child: CustomAppBar(title: Text(t.settings.title), pinned: true)),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildAppearanceSection(),
                  const SizedBox(height: 24),
                  _buildVideoPlaybackSection(),
                  const SizedBox(height: 24),
                  _buildDownloadsSection(),
                  const SizedBox(height: 24),
                  if (_keyboardShortcutsSupported) ...[_buildKeyboardShortcutsSection(), const SizedBox(height: 24)],
                  _buildCompanionRemoteSection(),
                  const SizedBox(height: 24),
                  _buildAdvancedSection(),
                  const SizedBox(height: 24),
                  if (UpdateService.isUpdateCheckEnabled) ...[_buildUpdateSection(), const SizedBox(height: 24)],
                  _buildAboutSection(),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              t.settings.appearance,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return Builder(
                builder: (tileContext) => ListTile(
                  focusNode: _focusTracker.get(_kTheme),
                  leading: AppIcon(themeProvider.themeModeIcon, fill: 1),
                  title: Text(t.settings.theme),
                  subtitle: Text(themeProvider.themeModeDisplayName),
                  trailing: const AppIcon(Symbols.arrow_drop_down_rounded, fill: 1),
                  onTap: () async {
                    final value = await _showSettingsMenu<settings.ThemeMode>(
                      tileContext: tileContext,
                      title: t.settings.theme,
                      options: [
                        _DialogOption(
                          value: settings.ThemeMode.system,
                          title: t.settings.systemTheme,
                          subtitle: t.settings.systemThemeDescription,
                        ),
                        _DialogOption(value: settings.ThemeMode.light, title: t.settings.lightTheme),
                        _DialogOption(value: settings.ThemeMode.dark, title: t.settings.darkTheme),
                        _DialogOption(
                          value: settings.ThemeMode.oled,
                          title: t.settings.oledTheme,
                          subtitle: t.settings.oledThemeDescription,
                        ),
                      ],
                      currentValue: themeProvider.themeMode,
                    );
                    if (value != null) {
                      themeProvider.setThemeMode(value);
                    }
                  },
                ),
              );
            },
          ),
          Builder(
            builder: (tileContext) => ListTile(
              focusNode: _focusTracker.get(_kLanguage),
              leading: const AppIcon(Symbols.language_rounded, fill: 1),
              title: Text(t.settings.language),
              subtitle: Text(_getLanguageDisplayName(LocaleSettings.currentLocale)),
              trailing: const AppIcon(Symbols.arrow_drop_down_rounded, fill: 1),
              onTap: () async {
                final value = await _showSettingsMenu<AppLocale>(
                  tileContext: tileContext,
                  title: t.settings.language,
                  options: AppLocale.values
                      .map((locale) => _DialogOption(value: locale, title: _getLanguageDisplayName(locale)))
                      .toList(),
                  currentValue: LocaleSettings.currentLocale,
                );
                if (value != null) {
                  await _settingsService.setAppLocale(value);
                  LocaleSettings.setLocale(value);
                  _restartApp();
                }
              },
            ),
          ),
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              return Builder(
                builder: (tileContext) => ListTile(
                  focusNode: _focusTracker.get(_kLibraryDensity),
                  leading: const AppIcon(Symbols.grid_view_rounded, fill: 1),
                  title: Text(t.settings.libraryDensity),
                  subtitle: Text(settingsProvider.libraryDensityDisplayName),
                  trailing: const AppIcon(Symbols.arrow_drop_down_rounded, fill: 1),
                  onTap: () async {
                    final value = await _showSettingsMenu<settings.LibraryDensity>(
                      tileContext: tileContext,
                      title: t.settings.libraryDensity,
                      options: [
                        _DialogOption(
                          value: settings.LibraryDensity.compact,
                          title: t.settings.compact,
                          subtitle: t.settings.compactDescription,
                        ),
                        _DialogOption(
                          value: settings.LibraryDensity.normal,
                          title: t.settings.normal,
                          subtitle: t.settings.normalDescription,
                        ),
                        _DialogOption(
                          value: settings.LibraryDensity.comfortable,
                          title: t.settings.comfortable,
                          subtitle: t.settings.comfortableDescription,
                        ),
                      ],
                      currentValue: settingsProvider.libraryDensity,
                    );
                    if (value != null) {
                      settingsProvider.setLibraryDensity(value);
                    }
                  },
                ),
              );
            },
          ),
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              return Builder(
                builder: (tileContext) => ListTile(
                  focusNode: _focusTracker.get(_kViewMode),
                  leading: const AppIcon(Symbols.view_list_rounded, fill: 1),
                  title: Text(t.settings.viewMode),
                  subtitle: Text(
                    settingsProvider.viewMode == settings.ViewMode.grid ? t.settings.gridView : t.settings.listView,
                  ),
                  trailing: const AppIcon(Symbols.arrow_drop_down_rounded, fill: 1),
                  onTap: () async {
                    final value = await _showSettingsMenu<settings.ViewMode>(
                      tileContext: tileContext,
                      title: t.settings.viewMode,
                      options: [
                        _DialogOption(
                          value: settings.ViewMode.grid,
                          title: t.settings.gridView,
                          subtitle: t.settings.gridViewDescription,
                        ),
                        _DialogOption(
                          value: settings.ViewMode.list,
                          title: t.settings.listView,
                          subtitle: t.settings.listViewDescription,
                        ),
                      ],
                      currentValue: settingsProvider.viewMode,
                    );
                    if (value != null) {
                      settingsProvider.setViewMode(value);
                    }
                  },
                ),
              );
            },
          ),
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              return Builder(
                builder: (tileContext) => ListTile(
                  focusNode: _focusTracker.get(_kEpisodePosterMode),
                  leading: const AppIcon(Symbols.image_rounded, fill: 1),
                  title: Text(t.settings.episodePosterMode),
                  subtitle: Text(settingsProvider.episodePosterModeDisplayName),
                  trailing: const AppIcon(Symbols.arrow_drop_down_rounded, fill: 1),
                  onTap: () async {
                    final value = await _showSettingsMenu<settings.EpisodePosterMode>(
                      tileContext: tileContext,
                      title: t.settings.episodePosterMode,
                      options: [
                        _DialogOption(
                          value: settings.EpisodePosterMode.seriesPoster,
                          title: t.settings.seriesPoster,
                          subtitle: t.settings.seriesPosterDescription,
                        ),
                        _DialogOption(
                          value: settings.EpisodePosterMode.seasonPoster,
                          title: t.settings.seasonPoster,
                          subtitle: t.settings.seasonPosterDescription,
                        ),
                        _DialogOption(
                          value: settings.EpisodePosterMode.episodeThumbnail,
                          title: t.settings.episodeThumbnail,
                          subtitle: t.settings.episodeThumbnailDescription,
                        ),
                      ],
                      currentValue: settingsProvider.episodePosterMode,
                    );
                    if (value != null) {
                      settingsProvider.setEpisodePosterMode(value);
                    }
                  },
                ),
              );
            },
          ),
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              return SwitchListTile(
                focusNode: _focusTracker.get(_kShowHeroSection),
                secondary: const AppIcon(Symbols.featured_play_list_rounded, fill: 1),
                title: Text(t.settings.showHeroSection),
                subtitle: Text(t.settings.showHeroSectionDescription),
                value: settingsProvider.showHeroSection,
                onChanged: (value) async {
                  await settingsProvider.setShowHeroSection(value);
                },
              );
            },
          ),
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              return SwitchListTile(
                focusNode: _focusTracker.get(_kUseGlobalHubs),
                secondary: const AppIcon(Symbols.home_rounded, fill: 1),
                title: Text(t.settings.useGlobalHubs),
                subtitle: Text(t.settings.useGlobalHubsDescription),
                value: settingsProvider.useGlobalHubs,
                onChanged: (value) async {
                  await settingsProvider.setUseGlobalHubs(value);
                },
              );
            },
          ),
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              return SwitchListTile(
                focusNode: _focusTracker.get(_kShowServerNameOnHubs),
                secondary: const AppIcon(Symbols.dns_rounded, fill: 1),
                title: Text(t.settings.showServerNameOnHubs),
                subtitle: Text(t.settings.showServerNameOnHubsDescription),
                value: settingsProvider.showServerNameOnHubs,
                onChanged: (value) async {
                  await settingsProvider.setShowServerNameOnHubs(value);
                },
              );
            },
          ),
          if (PlatformDetector.shouldUseSideNavigation(context))
            Consumer<SettingsProvider>(
              builder: (context, settingsProvider, child) {
                return SwitchListTile(
                  focusNode: _focusTracker.get(_kAlwaysKeepSidebarOpen),
                  secondary: const AppIcon(Symbols.dock_to_left_rounded, fill: 1),
                  title: Text(t.settings.alwaysKeepSidebarOpen),
                  subtitle: Text(t.settings.alwaysKeepSidebarOpenDescription),
                  value: settingsProvider.alwaysKeepSidebarOpen,
                  onChanged: (value) async {
                    await settingsProvider.setAlwaysKeepSidebarOpen(value);
                  },
                );
              },
            ),
          if (!PlatformDetector.shouldUseSideNavigation(context))
            Consumer<SettingsProvider>(
              builder: (context, settingsProvider, child) {
                return SwitchListTile(
                  focusNode: _focusTracker.get(_kShowNavBarLabels),
                  secondary: const AppIcon(Symbols.label_rounded, fill: 1),
                  title: Text(t.settings.showNavBarLabels),
                  subtitle: Text(t.settings.showNavBarLabelsDescription),
                  value: settingsProvider.showNavBarLabels,
                  onChanged: (value) async {
                    await settingsProvider.setShowNavBarLabels(value);
                  },
                );
              },
            ),
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              return SwitchListTile(
                focusNode: _focusTracker.get(_kShowUnwatchedCount),
                secondary: const AppIcon(Symbols.counter_1_rounded, fill: 1),
                title: Text(t.settings.showUnwatchedCount),
                subtitle: Text(t.settings.showUnwatchedCountDescription),
                value: settingsProvider.showUnwatchedCount,
                onChanged: (value) async {
                  await settingsProvider.setShowUnwatchedCount(value);
                },
              );
            },
          ),
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              return SwitchListTile(
                focusNode: _focusTracker.get(_kHideSpoilers),
                secondary: const AppIcon(Symbols.visibility_off_rounded, fill: 1),
                title: Text(t.settings.hideSpoilers),
                subtitle: Text(t.settings.hideSpoilersDescription),
                value: settingsProvider.hideSpoilers,
                onChanged: (value) async {
                  await settingsProvider.setHideSpoilers(value);
                },
              );
            },
          ),
          Consumer<UserProfileProvider>(
            builder: (context, userProfileProvider, child) {
              if (!userProfileProvider.hasMultipleUsers) return const SizedBox.shrink();
              return SwitchListTile(
                focusNode: _focusTracker.get(_kRequireProfileSelectionOnOpen),
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
          ),
          if (PlatformDetector.isTV())
            SwitchListTile(
              focusNode: _focusTracker.get(_kConfirmExitOnBack),
              secondary: const AppIcon(Symbols.exit_to_app_rounded, fill: 1),
              title: Text(t.settings.confirmExitOnBack),
              subtitle: Text(t.settings.confirmExitOnBackDescription),
              value: _confirmExitOnBack,
              onChanged: (value) async {
                setState(() => _confirmExitOnBack = value);
                await _settingsService.setConfirmExitOnBack(value);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildVideoPlaybackSection() {
    final isMobile = PlatformDetector.isMobile(context);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              t.settings.videoPlayback,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          if (Platform.isAndroid)
            Builder(
              builder: (tileContext) => ListTile(
                focusNode: _focusTracker.get(_kPlayerBackend),
                leading: const AppIcon(Symbols.play_circle_rounded, fill: 1),
                title: Text(t.settings.playerBackend),
                subtitle: Text(_useExoPlayer ? t.settings.exoPlayerDescription : t.settings.mpvDescription),
                trailing: const AppIcon(Symbols.arrow_drop_down_rounded, fill: 1),
                onTap: () async {
                  final value = await _showSettingsMenu<bool>(
                    tileContext: tileContext,
                    title: t.settings.playerBackend,
                    options: [
                      _DialogOption(
                        value: true,
                        title: t.settings.exoPlayer,
                        subtitle: t.settings.exoPlayerDescription,
                      ),
                      _DialogOption(value: false, title: t.settings.mpv, subtitle: t.settings.mpvDescription),
                    ],
                    currentValue: _useExoPlayer,
                  );
                  if (value != null) {
                    setState(() => _useExoPlayer = value);
                    await _settingsService.setUseExoPlayer(value);
                  }
                },
              ),
            ),
          ListTile(
            focusNode: _focusTracker.get(_kExternalPlayer),
            leading: const AppIcon(Symbols.open_in_new_rounded, fill: 1),
            title: Text(t.externalPlayer.title),
            subtitle: Text(_useExternalPlayer ? _selectedExternalPlayerName : t.externalPlayer.off),
            trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => const ExternalPlayerScreen()));
              // Reload to reflect any changes
              final s = await settings.SettingsService.getInstance();
              if (!mounted) return;
              setState(() {
                _useExternalPlayer = s.getUseExternalPlayer();
                _selectedExternalPlayerName = s.getSelectedExternalPlayer().name;
              });
            },
          ),
          SwitchListTile(
            focusNode: _focusTracker.get(_kHardwareDecoding),
            secondary: const AppIcon(Symbols.hardware_rounded, fill: 1),
            title: Text(t.settings.hardwareDecoding),
            subtitle: Text(t.settings.hardwareDecodingDescription),
            value: _enableHardwareDecoding,
            onChanged: (value) async {
              setState(() {
                _enableHardwareDecoding = value;
              });
              await _settingsService.setEnableHardwareDecoding(value);
            },
          ),
          if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)
            SwitchListTile(
              focusNode: _focusTracker.get(_kAutoPip),
              secondary: const AppIcon(Symbols.picture_in_picture_alt_rounded, fill: 1),
              title: Text(t.settings.autoPip),
              subtitle: Text(t.settings.autoPipDescription),
              value: _autoPip,
              onChanged: (value) async {
                setState(() {
                  _autoPip = value;
                });
                await _settingsService.setAutoPip(value);
              },
            ),
          if (Platform.isAndroid)
            SwitchListTile(
              focusNode: _focusTracker.get(_kMatchContentFrameRate),
              secondary: const AppIcon(Symbols.display_settings_rounded, fill: 1),
              title: Text(t.settings.matchContentFrameRate),
              subtitle: Text(t.settings.matchContentFrameRateDescription),
              value: _matchContentFrameRate,
              onChanged: (value) async {
                setState(() {
                  _matchContentFrameRate = value;
                });
                await _settingsService.setMatchContentFrameRate(value);
              },
            ),
          if (Platform.isAndroid && _useExoPlayer)
            SwitchListTile(
              focusNode: _focusTracker.get(_kTunneledPlayback),
              secondary: const AppIcon(Symbols.tv_options_input_settings_rounded, fill: 1),
              title: Text(t.settings.tunneledPlayback),
              subtitle: Text(t.settings.tunneledPlaybackDescription),
              value: _tunneledPlayback,
              onChanged: (value) async {
                setState(() {
                  _tunneledPlayback = value;
                });
                await _settingsService.setTunneledPlayback(value);
              },
            ),
          Builder(
            builder: (tileContext) => ListTile(
              focusNode: _focusTracker.get(_kBufferSize),
              leading: const AppIcon(Symbols.memory_rounded, fill: 1),
              title: Text(t.settings.bufferSize),
              subtitle: Text(
                _bufferSize == 0 ? t.settings.bufferSizeAuto : t.settings.bufferSizeMB(size: _bufferSize.toString()),
              ),
              trailing: const AppIcon(Symbols.arrow_drop_down_rounded, fill: 1),
              onTap: () async {
                final bufferOptions = [0, 64, 128, 256, 512, 1024];
                final value = await _showSettingsMenu<int>(
                  tileContext: tileContext,
                  title: t.settings.bufferSize,
                  options: bufferOptions
                      .map(
                        (size) =>
                            _DialogOption(value: size, title: size == 0 ? t.settings.bufferSizeAuto : '${size}MB'),
                      )
                      .toList(),
                  currentValue: _bufferSize,
                );
                if (value != null) {
                  setState(() {
                    _bufferSize = value;
                    _settingsService.setBufferSize(value);
                  });
                  if (Platform.isAndroid && value > 0) {
                    final heapMB = await PlayerAndroid.getHeapSize();
                    if (heapMB > 0 && value > heapMB ~/ 4 && mounted) {
                      showAppSnackBar(
                        context,
                        t.settings.bufferSizeWarning(heap: heapMB.toString(), size: value.toString()),
                      );
                    }
                  }
                }
              },
            ),
          ),
          ListTile(
            focusNode: _focusTracker.get(_kSubtitleStyling),
            leading: const AppIcon(Symbols.subtitles_rounded, fill: 1),
            title: Text(t.settings.subtitleStyling),
            subtitle: Text(t.settings.subtitleStylingDescription),
            trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SubtitleStylingScreen()));
            },
          ),
          // MPV Config is only available when using MPV player backend
          if (!Platform.isAndroid || !_useExoPlayer)
            ListTile(
              focusNode: _focusTracker.get(_kMpvConfig),
              leading: const AppIcon(Symbols.tune_rounded, fill: 1),
              title: Text(t.mpvConfig.title),
              subtitle: Text(t.mpvConfig.description),
              trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MpvConfigScreen()));
              },
            ),
          ListTile(
            focusNode: _focusTracker.get(_kSmallSkipDuration),
            leading: const AppIcon(Symbols.replay_10_rounded, fill: 1),
            title: Text(t.settings.smallSkipDuration),
            subtitle: Text(t.settings.secondsUnit(seconds: _seekTimeSmall.toString())),
            trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            onTap: () => _showSeekTimeSmallDialog(),
          ),
          ListTile(
            focusNode: _focusTracker.get(_kLargeSkipDuration),
            leading: const AppIcon(Symbols.replay_30_rounded, fill: 1),
            title: Text(t.settings.largeSkipDuration),
            subtitle: Text(t.settings.secondsUnit(seconds: _seekTimeLarge.toString())),
            trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            onTap: () => _showSeekTimeLargeDialog(),
          ),
          ListTile(
            focusNode: _focusTracker.get(_kDefaultSleepTimer),
            leading: const AppIcon(Symbols.bedtime_rounded, fill: 1),
            title: Text(t.settings.defaultSleepTimer),
            subtitle: Text(t.settings.minutesUnit(minutes: _sleepTimerDuration.toString())),
            trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            onTap: () => _showSleepTimerDurationDialog(),
          ),
          ListTile(
            focusNode: _focusTracker.get(_kMaxVolume),
            leading: const AppIcon(Symbols.volume_up_rounded, fill: 1),
            title: Text(t.settings.maxVolume),
            subtitle: Text(t.settings.maxVolumePercent(percent: _maxVolume.toString())),
            trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            onTap: () => _showMaxVolumeDialog(),
          ),
          if (DiscordRPCService.isAvailable)
            SwitchListTile(
              focusNode: _focusTracker.get(_kDiscordRichPresence),
              secondary: const AppIcon(Symbols.chat_rounded, fill: 1),
              title: Text(t.settings.discordRichPresence),
              subtitle: Text(t.settings.discordRichPresenceDescription),
              value: _enableDiscordRPC,
              onChanged: (value) async {
                setState(() => _enableDiscordRPC = value);
                await _settingsService.setEnableDiscordRPC(value);
                await DiscordRPCService.instance.setEnabled(value);
              },
            ),
          SwitchListTile(
            focusNode: _focusTracker.get(_kRememberTrackSelections),
            secondary: const AppIcon(Symbols.bookmark_rounded, fill: 1),
            title: Text(t.settings.rememberTrackSelections),
            subtitle: Text(t.settings.rememberTrackSelectionsDescription),
            value: _rememberTrackSelections,
            onChanged: (value) async {
              setState(() {
                _rememberTrackSelections = value;
              });
              await _settingsService.setRememberTrackSelections(value);
            },
          ),
          if (!isMobile)
            SwitchListTile(
              focusNode: _focusTracker.get(_kClickVideoTogglesPlayback),
              secondary: const AppIcon(Symbols.play_pause_rounded, fill: 1),
              title: Text(t.settings.clickVideoTogglesPlayback),
              subtitle: Text(t.settings.clickVideoTogglesPlaybackDescription),
              value: _clickVideoTogglesPlayback,
              onChanged: (value) async {
                setState(() {
                  _clickVideoTogglesPlayback = value;
                });
                await _settingsService.setClickVideoTogglesPlayback(value);
              },
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 8, right: 16),
            child: Text(
              t.settings.autoSkip,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          SwitchListTile(
            focusNode: _focusTracker.get(_kAutoSkipIntro),
            secondary: const AppIcon(Symbols.fast_forward_rounded, fill: 1),
            title: Text(t.settings.autoSkipIntro),
            subtitle: Text(t.settings.autoSkipIntroDescription),
            value: _autoSkipIntro,
            onChanged: (value) async {
              setState(() {
                _autoSkipIntro = value;
              });
              await _settingsService.setAutoSkipIntro(value);
            },
          ),
          SwitchListTile(
            focusNode: _focusTracker.get(_kAutoSkipCredits),
            secondary: const AppIcon(Symbols.skip_next_rounded, fill: 1),
            title: Text(t.settings.autoSkipCredits),
            subtitle: Text(t.settings.autoSkipCreditsDescription),
            value: _autoSkipCredits,
            onChanged: (value) async {
              setState(() {
                _autoSkipCredits = value;
              });
              await _settingsService.setAutoSkipCredits(value);
            },
          ),
          ListTile(
            focusNode: _focusTracker.get(_kAutoSkipDelay),
            leading: const AppIcon(Symbols.timer_rounded, fill: 1),
            title: Text(t.settings.autoSkipDelay),
            subtitle: Text(t.settings.autoSkipDelayDescription(seconds: _autoSkipDelay.toString())),
            trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            onTap: () => _showAutoSkipDelayDialog(),
          ),
          ListTile(
            focusNode: _focusTracker.get(_kIntroPattern),
            leading: const AppIcon(Symbols.match_case_rounded, fill: 1),
            title: Text(t.settings.introPattern),
            subtitle: Text(t.settings.introPatternDescription),
            trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            onTap: () => _showTextInputDialog(
              title: t.settings.introPattern,
              currentValue: _introPattern,
              defaultValue: settings.SettingsService.defaultIntroPattern,
              onSave: (value) async {
                setState(() => _introPattern = value);
                await _settingsService.setIntroPattern(value);
              },
            ),
          ),
          ListTile(
            focusNode: _focusTracker.get(_kCreditsPattern),
            leading: const AppIcon(Symbols.match_case_rounded, fill: 1),
            title: Text(t.settings.creditsPattern),
            subtitle: Text(t.settings.creditsPatternDescription),
            trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            onTap: () => _showTextInputDialog(
              title: t.settings.creditsPattern,
              currentValue: _creditsPattern,
              defaultValue: settings.SettingsService.defaultCreditsPattern,
              onSave: (value) async {
                setState(() => _creditsPattern = value);
                await _settingsService.setCreditsPattern(value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadsSection() {
    final storageService = DownloadStorageService.instance;
    final isCustom = storageService.isUsingCustomPath();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              t.settings.downloads,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          // Download location picker - not available on iOS
          if (!Platform.isIOS)
            FutureBuilder<String>(
              future: storageService.getCurrentDownloadPathDisplay(),
              builder: (context, snapshot) {
                final currentPath = snapshot.data ?? '...';

                return ListTile(
                  focusNode: _focusTracker.get(_kDownloadLocation),
                  leading: const AppIcon(Symbols.folder_rounded, fill: 1),
                  title: Text(isCustom ? t.settings.downloadLocationCustom : t.settings.downloadLocationDefault),
                  subtitle: Text(currentPath, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
                  onTap: () => _showDownloadLocationDialog(),
                );
              },
            ),
          SwitchListTile(
            focusNode: _focusTracker.get(_kDownloadOnWifiOnly),
            secondary: const AppIcon(Symbols.wifi_rounded, fill: 1),
            title: Text(t.settings.downloadOnWifiOnly),
            subtitle: Text(t.settings.downloadOnWifiOnlyDescription),
            value: _downloadOnWifiOnly,
            onChanged: (value) async {
              setState(() => _downloadOnWifiOnly = value);
              await _settingsService.setDownloadOnWifiOnly(value);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showDownloadLocationDialog() async {
    final storageService = DownloadStorageService.instance;
    final isCustom = storageService.isUsingCustomPath();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.settings.downloads),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.settings.downloadLocationDescription),
            const SizedBox(height: 16),
            FutureBuilder<String>(
              future: storageService.getCurrentDownloadPathDisplay(),
              builder: (context, snapshot) {
                return Text(
                  t.settings.currentPath(path: snapshot.data ?? '...'),
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
            ),
          ],
        ),
        actions: [
          if (isCustom)
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _resetDownloadLocation();
              },
              child: Text(t.settings.resetToDefault),
            ),
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.common.cancel)),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _selectDownloadLocation();
            },
            child: Text(t.settings.selectFolder),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDownloadLocation() async {
    try {
      String? selectedPath;
      String pathType = 'file';

      if (Platform.isAndroid) {
        // Use SAF on Android
        final safService = SafStorageService.instance;
        selectedPath = await safService.pickDirectory();
        if (selectedPath != null) {
          pathType = 'saf';
        }
      } else {
        // Use file_picker on desktop
        final result = await FilePicker.platform.getDirectoryPath(dialogTitle: t.settings.selectFolder);
        selectedPath = result;
      }

      if (selectedPath != null) {
        // Validate the path is writable (for non-SAF paths)
        if (pathType == 'file') {
          final dir = Directory(selectedPath);
          final isWritable = await DownloadStorageService.instance.isDirectoryWritable(dir);
          if (!isWritable) {
            if (mounted) {
              showErrorSnackBar(context, t.settings.downloadLocationInvalid);
            }
            return;
          }
        }

        // Save the setting
        await _settingsService.setCustomDownloadPath(selectedPath, type: pathType);
        await DownloadStorageService.instance.refreshCustomPath();

        if (mounted) {
          // ignore: no-empty-block - setState triggers rebuild to reflect new download path
          setState(() {});
          showSuccessSnackBar(context, t.settings.downloadLocationChanged);
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, t.settings.downloadLocationSelectError);
      }
    }
  }

  Future<void> _resetDownloadLocation() async {
    await _settingsService.setCustomDownloadPath(null);
    await DownloadStorageService.instance.refreshCustomPath();

    if (mounted) {
      // ignore: no-empty-block - setState triggers rebuild to reflect reset path
      setState(() {});
      showAppSnackBar(context, t.settings.downloadLocationReset);
    }
  }

  Widget _buildKeyboardShortcutsSection() {
    if (_keyboardService == null) return const SizedBox.shrink();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              t.settings.keyboardShortcuts,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            focusNode: _focusTracker.get(_kVideoPlayerControls),
            leading: const AppIcon(Symbols.keyboard_rounded, fill: 1),
            title: Text(t.settings.videoPlayerControls),
            subtitle: Text(t.settings.keyboardShortcutsDescription),
            trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            onTap: () => _showKeyboardShortcutsDialog(),
          ),
          SwitchListTile(
            focusNode: _focusTracker.get(_kVideoPlayerNavigation),
            secondary: const AppIcon(Symbols.gamepad_rounded, fill: 1),
            title: Text(t.settings.videoPlayerNavigation),
            subtitle: Text(t.settings.videoPlayerNavigationDescription),
            value: _videoPlayerNavigationEnabled,
            onChanged: (value) async {
              setState(() {
                _videoPlayerNavigationEnabled = value;
              });
              await _settingsService.setVideoPlayerNavigationEnabled(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompanionRemoteSection() {
    return Consumer<CompanionRemoteProvider>(
      builder: (context, companionRemote, child) {
        return Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  t.companionRemote.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (PlatformDetector.isDesktop(context))
                ListTile(
                  leading: const AppIcon(Symbols.phone_android_rounded, fill: 1),
                  title: Text(t.companionRemote.hostRemoteSession),
                  subtitle: companionRemote.isConnected
                      ? Text(t.companionRemote.connectedTo(name: companionRemote.connectedDevice?.name ?? ''))
                      : Text(t.companionRemote.controlThisDevice),
                  trailing: companionRemote.isConnected
                      ? const AppIcon(Symbols.check_circle_rounded, fill: 1, color: Colors.green)
                      : const AppIcon(Symbols.chevron_right_rounded, fill: 1),
                  onTap: () => RemoteSessionDialog.show(context),
                )
              else
                ListTile(
                  leading: const AppIcon(Symbols.phone_android_rounded, fill: 1),
                  title: Text(t.companionRemote.remoteControl),
                  subtitle: companionRemote.isConnected
                      ? Text(t.companionRemote.connectedTo(name: companionRemote.connectedDevice?.name ?? ''))
                      : Text(t.companionRemote.controlDesktop),
                  trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const MobileRemoteScreen()));
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdvancedSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              t.settings.advanced,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            focusNode: _focusTracker.get(_kCrashReporting),
            secondary: const AppIcon(Symbols.monitoring_rounded, fill: 1),
            title: Text(t.settings.crashReporting),
            subtitle: Text(t.settings.crashReportingDescription),
            value: _crashReporting,
            onChanged: (value) async {
              setState(() {
                _crashReporting = value;
              });
              await _settingsService.setCrashReporting(value);
            },
          ),
          SwitchListTile(
            focusNode: _focusTracker.get(_kDebugLogging),
            secondary: const AppIcon(Symbols.bug_report_rounded, fill: 1),
            title: Text(t.settings.debugLogging),
            subtitle: Text(t.settings.debugLoggingDescription),
            value: _enableDebugLogging,
            onChanged: (value) async {
              setState(() {
                _enableDebugLogging = value;
              });
              await _settingsService.setEnableDebugLogging(value);
            },
          ),
          ListTile(
            focusNode: _focusTracker.get(_kViewLogs),
            leading: const AppIcon(Symbols.article_rounded, fill: 1),
            title: Text(t.settings.viewLogs),
            subtitle: Text(t.settings.viewLogsDescription),
            trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LogsScreen()));
            },
          ),
          ListTile(
            focusNode: _focusTracker.get(_kClearCache),
            leading: const AppIcon(Symbols.cleaning_services_rounded, fill: 1),
            title: Text(t.settings.clearCache),
            subtitle: Text(t.settings.clearCacheDescription),
            trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            onTap: () => _showClearCacheDialog(),
          ),
          ListTile(
            focusNode: _focusTracker.get(_kResetSettings),
            leading: const AppIcon(Symbols.restore_rounded, fill: 1),
            title: Text(t.settings.resetSettings),
            subtitle: Text(t.settings.resetSettingsDescription),
            trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            onTap: () => _showResetSettingsDialog(),
          ),
          if (kDebugMode)
            ListTile(
              leading: const AppIcon(Symbols.error_rounded, fill: 1),
              title: const Text('Test Sentry'),
              subtitle: const Text('Send a test error'),
              trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
              onTap: () {
                throw Exception("Example exception");
              },
            ),
          if (kDebugMode)
            ListTile(
              leading: const AppIcon(Symbols.timer_rounded, fill: 1),
              title: const Text('Test ANR'),
              subtitle: const Text('Block the main thread for 10 seconds'),
              trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
              onTap: () {
                showSnackBar(context, 'Blocking main thread...');
                final end = DateTime.now().add(const Duration(seconds: 10));
                while (DateTime.now().isBefore(end)) {}
              },
            ),
        ],
      ),
    );
  }

  Widget _buildUpdateSection() {
    // Native updater: simple tile that triggers Sparkle/WinSparkle native dialog
    if (UpdateService.useNativeUpdater) {
      return Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                t.settings.updates,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              focusNode: _focusTracker.get(_kCheckForUpdates),
              leading: const AppIcon(Symbols.system_update_rounded, fill: 1),
              title: Text(t.settings.checkForUpdates),
              trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
              onTap: () => UpdateService.checkForUpdatesNative(inBackground: false),
            ),
          ],
        ),
      );
    }

    final hasUpdate = _updateInfo != null && _updateInfo!['hasUpdate'] == true;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              t.settings.updates,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            focusNode: _focusTracker.get(_kCheckForUpdates),
            leading: AppIcon(
              hasUpdate ? Symbols.system_update_rounded : Symbols.check_circle_rounded,
              fill: 1,
              color: hasUpdate ? Colors.orange : null,
            ),
            title: Text(hasUpdate ? t.settings.updateAvailable : t.settings.checkForUpdates),
            subtitle: hasUpdate ? Text(t.update.versionAvailable(version: _updateInfo!['latestVersion'])) : null,
            trailing: _isCheckingForUpdate
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            onTap: _isCheckingForUpdate
                ? null
                : () {
                    if (hasUpdate) {
                      _showUpdateDialog();
                    } else {
                      _checkForUpdates();
                    }
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: ListTile(
        focusNode: _focusTracker.get(_kAbout),
        leading: const AppIcon(Symbols.info_rounded, fill: 1),
        title: Text(t.settings.about),
        subtitle: Text(t.settings.aboutDescription),
        trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
        },
      ),
    );
  }

  /// Shows a platform-adaptive settings menu: popup dropdown on desktop/TV,
  /// bottom sheet on mobile.
  Future<T?> _showSettingsMenu<T>({
    required BuildContext tileContext,
    required String title,
    required List<_DialogOption<T>> options,
    required T currentValue,
  }) {
    final useBottomSheet = Platform.isIOS || Platform.isAndroid;
    final focusFirstItem = InputModeTracker.isKeyboardMode(context);

    if (useBottomSheet) {
      return _showSettingsMenuSheet<T>(
        title: title,
        options: options,
        currentValue: currentValue,
        focusFirstItem: focusFirstItem,
      );
    } else {
      return _showSettingsMenuPopup<T>(
        tileContext: tileContext,
        options: options,
        currentValue: currentValue,
        focusFirstItem: focusFirstItem,
      );
    }
  }

  /// Mobile path: bottom sheet via OverlaySheetController.showAdaptive
  Future<T?> _showSettingsMenuSheet<T>({
    required String title,
    required List<_DialogOption<T>> options,
    required T currentValue,
    required bool focusFirstItem,
  }) {
    return OverlaySheetController.showAdaptive<T>(
      context,
      showDragHandle: true,
      builder: (context) => _SettingsMenuSheet<T>(
        title: title,
        options: options,
        currentValue: currentValue,
        focusFirstItem: focusFirstItem,
      ),
    );
  }

  /// Desktop/TV path: positioned popup dropdown
  Future<T?> _showSettingsMenuPopup<T>({
    required BuildContext tileContext,
    required List<_DialogOption<T>> options,
    required T currentValue,
    required bool focusFirstItem,
  }) {
    final renderBox = tileContext.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final tileSize = renderBox.size;

    return showDialog<T>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => _SettingsMenuPopup<T>(
        position: Offset(position.dx + tileSize.width, position.dy + tileSize.height),
        options: options,
        currentValue: currentValue,
        focusFirstItem: focusFirstItem,
      ),
    );
  }

  /// Generic numeric input dialog to avoid duplication across settings.
  /// On TV, uses a spinner widget with +/- buttons for D-pad navigation.
  /// On other platforms, uses a TextField with focus management.
  void _showNumericInputDialog({
    required String title,
    required String labelText,
    required String suffixText,
    required int min,
    required int max,
    required int currentValue,
    required Future<void> Function(int value) onSave,
  }) {
    final useDpadControls = InputModeTracker.isKeyboardMode(context);

    if (useDpadControls) {
      _showNumericInputDialogTV(
        title: title,
        suffixText: suffixText,
        min: min,
        max: max,
        currentValue: currentValue,
        onSave: onSave,
      );
    } else {
      _showNumericInputDialogStandard(
        title: title,
        labelText: labelText,
        suffixText: suffixText,
        min: min,
        max: max,
        currentValue: currentValue,
        onSave: onSave,
      );
    }
  }

  /// TV-specific numeric input dialog with spinner widget.
  void _showNumericInputDialogTV({
    required String title,
    required String suffixText,
    required int min,
    required int max,
    required int currentValue,
    required Future<void> Function(int value) onSave,
  }) {
    int spinnerValue = currentValue;
    final saveFocusNode = FocusNode();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TvNumberSpinner(
                    value: spinnerValue,
                    min: min,
                    max: max,
                    suffix: suffixText,
                    autofocus: true,
                    onChanged: (value) {
                      setDialogState(() {
                        spinnerValue = value;
                      });
                    },
                    onConfirm: () => saveFocusNode.requestFocus(),
                    onCancel: () => Navigator.pop(dialogContext),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.settings.durationHint(min: min, max: max),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.common.cancel)),
                TextButton(
                  focusNode: saveFocusNode,
                  onPressed: () async {
                    await onSave(spinnerValue);
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: Text(t.common.save),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => saveFocusNode.dispose());
  }

  /// Standard numeric input dialog with TextField for non-TV platforms.
  void _showNumericInputDialogStandard({
    required String title,
    required String labelText,
    required String suffixText,
    required int min,
    required int max,
    required int currentValue,
    required Future<void> Function(int value) onSave,
  }) {
    final controller = TextEditingController(text: currentValue.toString());
    String? errorText;
    final saveFocusNode = FocusNode();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: labelText,
                  hintText: t.settings.durationHint(min: min, max: max),
                  errorText: errorText,
                  suffixText: suffixText,
                ),
                autofocus: true,
                textInputAction: TextInputAction.done,
                onEditingComplete: () {
                  // Move focus to Save button when keyboard checkmark is pressed
                  saveFocusNode.requestFocus();
                },
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  setDialogState(() {
                    if (parsed == null) {
                      errorText = t.settings.validationErrorEnterNumber;
                    } else if (parsed < min || parsed > max) {
                      errorText = t.settings.validationErrorDuration(min: min, max: max, unit: labelText.toLowerCase());
                    } else {
                      errorText = null;
                    }
                  });
                },
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.common.cancel)),
                TextButton(
                  focusNode: saveFocusNode,
                  onPressed: () async {
                    final parsed = int.tryParse(controller.text);
                    if (parsed != null && parsed >= min && parsed <= max) {
                      await onSave(parsed);
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    }
                  },
                  child: Text(t.common.save),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // Clean up focus node when dialog is dismissed
      saveFocusNode.dispose();
    });
  }

  void _showSeekTimeSmallDialog() {
    _showNumericInputDialog(
      title: t.settings.smallSkipDuration,
      labelText: t.settings.secondsLabel,
      suffixText: t.settings.secondsShort,
      min: 1,
      max: 120,
      currentValue: _seekTimeSmall,
      onSave: (value) async {
        setState(() {
          _seekTimeSmall = value;
          _settingsService.setSeekTimeSmall(value);
        });
        await _keyboardService?.refreshFromStorage();
      },
    );
  }

  void _showSeekTimeLargeDialog() {
    _showNumericInputDialog(
      title: t.settings.largeSkipDuration,
      labelText: t.settings.secondsLabel,
      suffixText: t.settings.secondsShort,
      min: 1,
      max: 120,
      currentValue: _seekTimeLarge,
      onSave: (value) async {
        setState(() {
          _seekTimeLarge = value;
          _settingsService.setSeekTimeLarge(value);
        });
        await _keyboardService?.refreshFromStorage();
      },
    );
  }

  void _showSleepTimerDurationDialog() {
    _showNumericInputDialog(
      title: t.settings.defaultSleepTimer,
      labelText: t.settings.minutesLabel,
      suffixText: t.settings.minutesShort,
      min: 5,
      max: 240,
      currentValue: _sleepTimerDuration,
      onSave: (value) async {
        setState(() => _sleepTimerDuration = value);
        await _settingsService.setSleepTimerDuration(value);
      },
    );
  }

  void _showAutoSkipDelayDialog() {
    _showNumericInputDialog(
      title: t.settings.autoSkipDelay,
      labelText: t.settings.secondsLabel,
      suffixText: t.settings.secondsShort,
      min: 1,
      max: 30,
      currentValue: _autoSkipDelay,
      onSave: (value) async {
        setState(() => _autoSkipDelay = value);
        await _settingsService.setAutoSkipDelay(value);
      },
    );
  }

  void _showTextInputDialog({
    required String title,
    required String currentValue,
    required String defaultValue,
    required Future<void> Function(String value) onSave,
  }) {
    final controller = TextEditingController(text: currentValue);
    String? errorText;
    final saveFocusNode = FocusNode();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Regex',
                  errorText: errorText,
                ),
                autofocus: true,
                textInputAction: TextInputAction.done,
                onEditingComplete: () => saveFocusNode.requestFocus(),
                onChanged: (value) {
                  setDialogState(() {
                    try {
                      RegExp(value, caseSensitive: false);
                      errorText = null;
                    } catch (_) {
                      errorText = t.settings.invalidRegex;
                    }
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    controller.text = defaultValue;
                    setDialogState(() => errorText = null);
                  },
                  child: Text(t.settings.resetToDefault),
                ),
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.common.cancel)),
                TextButton(
                  focusNode: saveFocusNode,
                  onPressed: () async {
                    if (errorText != null) return;
                    await onSave(controller.text);
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
                  child: Text(t.common.save),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => saveFocusNode.dispose());
  }

  void _showMaxVolumeDialog() {
    _showNumericInputDialog(
      title: t.settings.maxVolume,
      labelText: t.settings.maxVolumeDescription,
      suffixText: '%',
      min: 100,
      max: 300,
      currentValue: _maxVolume,
      onSave: (value) async {
        setState(() => _maxVolume = value);
        await _settingsService.setMaxVolume(value);
      },
    );
  }

  void _showKeyboardShortcutsDialog() {
    if (_keyboardService == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => _KeyboardShortcutsScreen(keyboardService: _keyboardService!)),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(t.settings.clearCache),
          content: Text(t.settings.clearCacheDescription),
          actions: [
            TextButton(autofocus: true, onPressed: () => Navigator.pop(context), child: Text(t.common.cancel)),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                await _settingsService.clearCache();
                if (mounted) {
                  navigator.pop();
                  showSuccessSnackBar(this.context, t.settings.clearCacheSuccess);
                }
              },
              child: Text(t.common.clear),
            ),
          ],
        );
      },
    );
  }

  void _showResetSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(t.settings.resetSettings),
          content: Text(t.settings.resetSettingsDescription),
          actions: [
            TextButton(autofocus: true, onPressed: () => Navigator.pop(context), child: Text(t.common.cancel)),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                await _settingsService.resetAllSettings();
                await _keyboardService?.resetToDefaults();
                if (mounted) {
                  navigator.pop();
                  showSuccessSnackBar(this.context, t.settings.resetSettingsSuccess);
                  _loadSettings();
                }
              },
              child: Text(t.common.reset),
            ),
          ],
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

  void _restartApp() {
    // Navigate to the root and remove all previous routes
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingForUpdate = true;
    });

    try {
      final updateInfo = await UpdateService.checkForUpdates();

      if (mounted) {
        setState(() {
          _updateInfo = updateInfo;
          _isCheckingForUpdate = false;
        });

        if (updateInfo == null || updateInfo['hasUpdate'] != true) {
          // Show "no updates" message
          showAppSnackBar(context, t.update.latestVersion);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingForUpdate = false;
        });

        showErrorSnackBar(context, t.update.checkFailed);
      }
    }
  }

  void _showUpdateDialog() {
    if (_updateInfo == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(t.settings.updateAvailable),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.update.versionAvailable(version: _updateInfo!['latestVersion']),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                t.update.currentVersion(version: _updateInfo!['currentVersion']),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(autofocus: true, onPressed: () => Navigator.pop(context), child: Text(t.common.close)),
            FilledButton(
              onPressed: () async {
                final url = Uri.parse(_updateInfo!['releaseUrl']);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(t.update.viewRelease),
            ),
          ],
        );
      },
    );
  }
}

/// Bottom sheet content for settings menu (mobile)
class _SettingsMenuSheet<T> extends StatefulWidget {
  final String title;
  final List<_DialogOption<T>> options;
  final T currentValue;
  final bool focusFirstItem;

  const _SettingsMenuSheet({
    required this.title,
    required this.options,
    required this.currentValue,
    this.focusFirstItem = false,
  });

  @override
  State<_SettingsMenuSheet<T>> createState() => _SettingsMenuSheetState<T>();
}

class _SettingsMenuSheetState<T> extends State<_SettingsMenuSheet<T>> {
  late final FocusNode _initialFocusNode;

  @override
  void initState() {
    super.initState();
    _initialFocusNode = FocusNode(debugLabel: 'SettingsMenuSheetInitialFocus');
  }

  @override
  void dispose() {
    _initialFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            widget.title,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...widget.options.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  final isSelected = widget.currentValue == option.value;
                  return FocusableListTile(
                    focusNode: index == 0 && widget.focusFirstItem ? _initialFocusNode : null,
                    dense: true,
                    leading: AppIcon(
                      isSelected ? Symbols.radio_button_checked_rounded : Symbols.radio_button_unchecked_rounded,
                      fill: 1,
                    ),
                    title: Text(option.title),
                    subtitle: option.subtitle != null ? Text(option.subtitle!) : null,
                    onTap: () => OverlaySheetController.closeAdaptive(context, option.value),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Positioned popup menu for settings menu (desktop/TV)
class _SettingsMenuPopup<T> extends StatefulWidget {
  final Offset position;
  final List<_DialogOption<T>> options;
  final T currentValue;
  final bool focusFirstItem;

  const _SettingsMenuPopup({
    required this.position,
    required this.options,
    required this.currentValue,
    this.focusFirstItem = false,
  });

  @override
  State<_SettingsMenuPopup<T>> createState() => _SettingsMenuPopupState<T>();
}

class _SettingsMenuPopupState<T> extends State<_SettingsMenuPopup<T>> {
  late final FocusNode _initialFocusNode;

  @override
  void initState() {
    super.initState();
    _initialFocusNode = FocusNode(debugLabel: 'SettingsMenuPopupInitialFocus');
    if (widget.focusFirstItem) {
      FocusUtils.requestFocusAfterBuild(this, _initialFocusNode);
    }
  }

  @override
  void dispose() {
    _initialFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const menuWidth = 280.0;
    const edgePadding = 8.0;

    // Right-align: position.dx is the tile's right edge
    final left = (widget.position.dx - menuWidth).clamp(edgePadding, screenSize.width - menuWidth - edgePadding);

    final estimatedHeight = widget.options.length * 56.0 + 16;
    final spaceBelow = screenSize.height - widget.position.dy - edgePadding;
    final spaceAbove = widget.position.dy - edgePadding;

    final double top;
    final double maxHeight;
    if (estimatedHeight <= spaceBelow) {
      top = widget.position.dy;
      maxHeight = spaceBelow;
    } else if (spaceAbove > spaceBelow) {
      final menuHeight = estimatedHeight.clamp(0.0, spaceAbove);
      top = widget.position.dy - menuHeight;
      maxHeight = menuHeight;
    } else {
      top = widget.position.dy;
      maxHeight = spaceBelow;
    }

    return FocusScope(
      autofocus: false,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (node, event) {
          if (SelectKeyUpSuppressor.consumeIfSuppressed(event)) {
            return KeyEventResult.handled;
          }
          if (BackKeyUpSuppressor.consumeIfSuppressed(event)) {
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              child: Material(
                elevation: 8,
                color: Color.alphaBlend(
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                  Theme.of(context).colorScheme.surface,
                ),
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: menuWidth, maxWidth: menuWidth, maxHeight: maxHeight),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: widget.options.asMap().entries.map((entry) {
                        final index = entry.key;
                        final option = entry.value;
                        final isSelected = widget.currentValue == option.value;
                        return FocusableListTile(
                          focusNode: index == 0 && widget.focusFirstItem ? _initialFocusNode : null,
                          dense: true,
                          leading: AppIcon(
                            isSelected ? Symbols.radio_button_checked_rounded : Symbols.radio_button_unchecked_rounded,
                            fill: 1,
                          ),
                          title: Text(option.title),
                          subtitle: option.subtitle != null ? Text(option.subtitle!) : null,
                          onTap: () => Navigator.pop(context, option.value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyboardShortcutsScreen extends StatefulWidget {
  final KeyboardShortcutsService keyboardService;

  const _KeyboardShortcutsScreen({required this.keyboardService});

  @override
  State<_KeyboardShortcutsScreen> createState() => _KeyboardShortcutsScreenState();
}

class _KeyboardShortcutsScreenState extends State<_KeyboardShortcutsScreen> {
  Map<String, HotKey> _hotkeys = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHotkeys();
  }

  Future<void> _loadHotkeys() async {
    await widget.keyboardService.refreshFromStorage();
    if (!mounted) return;
    setState(() {
      _hotkeys = widget.keyboardService.hotkeys;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FocusedScrollScaffold(
      title: Text(t.settings.keyboardShortcuts),
      actions: [
        TextButton(
          onPressed: () async {
            await widget.keyboardService.resetToDefaults();
            await _loadHotkeys();
            if (mounted) {
              showSuccessSnackBar(this.context, t.settings.shortcutsReset);
            }
          },
          child: Text(t.common.reset),
        ),
      ],
      slivers: _isLoading
          ? [const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))]
          : [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final actions = _hotkeys.keys.toList();
                    final action = actions[index];
                    final hotkey = _hotkeys[action]!;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(widget.keyboardService.getActionDisplayName(action)),
                        subtitle: Text(action),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.fromBorderSide(BorderSide(color: Theme.of(context).dividerColor)),
                            borderRadius: const BorderRadius.all(Radius.circular(6)),
                          ),
                          child: Text(
                            widget.keyboardService.formatHotkey(hotkey),
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                        onTap: () => _editHotkey(action, hotkey),
                      ),
                    );
                  }, childCount: _hotkeys.length),
                ),
              ),
            ],
    );
  }

  void _editHotkey(String action, HotKey currentHotkey) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return HotKeyRecorderWidget(
          actionName: widget.keyboardService.getActionDisplayName(action),
          currentHotKey: currentHotkey,
          onHotKeyRecorded: (newHotkey) async {
            final navigator = Navigator.of(context);

            // Check for conflicts
            final existingAction = widget.keyboardService.getActionForHotkey(newHotkey);
            if (existingAction != null && existingAction != action) {
              navigator.pop();
              showErrorSnackBar(
                context,
                t.settings.shortcutAlreadyAssigned(action: widget.keyboardService.getActionDisplayName(existingAction)),
              );
              return;
            }

            // Save the new hotkey
            await widget.keyboardService.setHotkey(action, newHotkey);

            if (mounted) {
              // Update UI directly instead of reloading from storage
              setState(() {
                _hotkeys[action] = newHotkey;
              });

              navigator.pop();

              showSuccessSnackBar(
                this.context,
                t.settings.shortcutUpdated(action: widget.keyboardService.getActionDisplayName(action)),
              );
            }
          },
          onCancel: () => Navigator.pop(context),
        );
      },
    );
  }
}
