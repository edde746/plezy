import 'package:flutter/foundation.dart' show kIsWeb;

import '../../utils/platform_helper.dart';
import '../../utils/io_helpers.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../models/hotkey_model.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../focus/focus_memory_tracker.dart';
import '../../i18n/strings.g.dart';
import '../main_screen.dart';
import '../../mixins/refreshable.dart';
import '../../services/discord_rpc_service.dart';
import '../../services/download_storage_service.dart';
import '../../services/saf_storage_service.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/keyboard_shortcuts_service.dart';
import '../../services/settings_service.dart' as settings;
import '../../services/update_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/desktop_app_bar.dart';
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
  static const _kRequireProfileSelectionOnOpen = 'require_profile_selection_on_open';
  static const _kPlayerBackend = 'player_backend';
  static const _kExternalPlayer = 'external_player';
  static const _kHardwareDecoding = 'hardware_decoding';
  static const _kMatchContentFrameRate = 'match_content_frame_rate';
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
  static const _kDownloadLocation = 'download_location';
  static const _kDownloadOnWifiOnly = 'download_on_wifi_only';
  static const _kVideoPlayerControls = 'video_player_controls';
  static const _kVideoPlayerNavigation = 'video_player_navigation';
  static const _kDebugLogging = 'debug_logging';
  static const _kViewLogs = 'view_logs';
  static const _kClearCache = 'clear_cache';
  static const _kResetSettings = 'reset_settings';
  static const _kCheckForUpdates = 'check_for_updates';
  static const _kAbout = 'about';
  KeyboardShortcutsService? _keyboardService;
  late final bool _keyboardShortcutsSupported = KeyboardShortcutsService.isPlatformSupported();
  bool _isLoading = true;

  bool _enableDebugLogging = false;
  bool _enableHardwareDecoding = true;
  int _bufferSize = 128;
  int _seekTimeSmall = 10;
  int _seekTimeLarge = 30;
  int _sleepTimerDuration = 30;
  bool _rememberTrackSelections = true;
  bool _clickVideoTogglesPlayback = false;
  bool _autoSkipIntro = false;
  bool _autoSkipCredits = false;
  int _autoSkipDelay = 5;
  bool _downloadOnWifiOnly = false;
  bool _videoPlayerNavigationEnabled = false;
  int _maxVolume = 100;
  bool _enableDiscordRPC = false;
  bool _matchContentFrameRate = false;
  bool _useExoPlayer = true; // Android only: ExoPlayer vs MPV
  bool _requireProfileSelectionOnOpen = false;
  bool _useExternalPlayer = false;
  String _selectedExternalPlayerName = '';

  // Update checking state
  bool _isCheckingForUpdate = false;
  Map<String, dynamic>? _updateInfo;

  @override
  void initState() {
    super.initState();
    _focusTracker = FocusMemoryTracker(
      onFocusChanged: () {
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
    _focusTracker.restoreFocus(fallbackKey: _kTheme);
  }

  /// Navigate focus to the sidebar
  void _navigateToSidebar() {
    MainScreenFocusScope.of(context)?.focusSidebar();
  }

  /// Handle key events for LEFT arrow → sidebar navigation
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
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

    setState(() {
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
      _downloadOnWifiOnly = _settingsService.getDownloadOnWifiOnly();
      _videoPlayerNavigationEnabled = _settingsService.getVideoPlayerNavigationEnabled();
      _maxVolume = _settingsService.getMaxVolume();
      _enableDiscordRPC = _settingsService.getEnableDiscordRPC();
      _matchContentFrameRate = _settingsService.getMatchContentFrameRate();
      _useExoPlayer = _settingsService.getUseExoPlayer();
      _requireProfileSelectionOnOpen = _settingsService.getRequireProfileSelectionOnOpen();
      _useExternalPlayer = _settingsService.getUseExternalPlayer();
      _selectedExternalPlayerName = _settingsService.getSelectedExternalPlayer().name;
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
            CustomAppBar(title: Text(t.settings.title), pinned: true),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildAppearanceSection(),
                  const SizedBox(height: 24),
                  _buildVideoPlaybackSection(),
                  const SizedBox(height: 24),
                  if (!kIsWeb) ...[_buildDownloadsSection(), const SizedBox(height: 24)],
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
              return ListTile(
                focusNode: _focusTracker.get(_kTheme),
                leading: AppIcon(themeProvider.themeModeIcon, fill: 1),
                title: Text(t.settings.theme),
                subtitle: Text(themeProvider.themeModeDisplayName),
                trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
                onTap: () => _showThemeDialog(themeProvider),
              );
            },
          ),
          ListTile(
            focusNode: _focusTracker.get(_kLanguage),
            leading: const AppIcon(Symbols.language_rounded, fill: 1),
            title: Text(t.settings.language),
            subtitle: Text(_getLanguageDisplayName(LocaleSettings.currentLocale)),
            trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            onTap: () => _showLanguageDialog(),
          ),
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              return ListTile(
                focusNode: _focusTracker.get(_kLibraryDensity),
                leading: const AppIcon(Symbols.grid_view_rounded, fill: 1),
                title: Text(t.settings.libraryDensity),
                subtitle: Text(settingsProvider.libraryDensityDisplayName),
                trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
                onTap: () => _showLibraryDensityDialog(),
              );
            },
          ),
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              return ListTile(
                focusNode: _focusTracker.get(_kViewMode),
                leading: const AppIcon(Symbols.view_list_rounded, fill: 1),
                title: Text(t.settings.viewMode),
                subtitle: Text(
                  settingsProvider.viewMode == settings.ViewMode.grid ? t.settings.gridView : t.settings.listView,
                ),
                trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
                onTap: () => _showViewModeDialog(),
              );
            },
          ),
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              return ListTile(
                focusNode: _focusTracker.get(_kEpisodePosterMode),
                leading: const AppIcon(Symbols.image_rounded, fill: 1),
                title: Text(t.settings.episodePosterMode),
                subtitle: Text(settingsProvider.episodePosterModeDisplayName),
                trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
                onTap: () => _showEpisodePosterModeDialog(),
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
          if (AppPlatform.isAndroid)
            ListTile(
              focusNode: _focusTracker.get(_kPlayerBackend),
              leading: const AppIcon(Symbols.play_circle_rounded, fill: 1),
              title: Text(t.settings.playerBackend),
              subtitle: Text(_useExoPlayer ? t.settings.exoPlayerDescription : t.settings.mpvDescription),
              trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
              onTap: () => _showPlayerBackendDialog(),
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
          if (AppPlatform.isAndroid)
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
          ListTile(
            focusNode: _focusTracker.get(_kBufferSize),
            leading: const AppIcon(Symbols.memory_rounded, fill: 1),
            title: Text(t.settings.bufferSize),
            subtitle: Text(t.settings.bufferSizeMB(size: _bufferSize.toString())),
            trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            onTap: () => _showBufferSizeDialog(),
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
          if (!AppPlatform.isAndroid || !_useExoPlayer)
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
          if (!AppPlatform.isIOS)
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

      if (AppPlatform.isAndroid) {
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
        ],
      ),
    );
  }

  Widget _buildUpdateSection() {
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

  void _showThemeDialog(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(t.settings.theme),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: AppIcon(
                  themeProvider.themeMode == settings.ThemeMode.system
                      ? Symbols.radio_button_checked_rounded
                      : Symbols.radio_button_unchecked_rounded,
                  fill: 1,
                ),
                title: Text(t.settings.systemTheme),
                subtitle: Text(t.settings.systemThemeDescription),
                onTap: () {
                  themeProvider.setThemeMode(settings.ThemeMode.system);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: AppIcon(
                  themeProvider.themeMode == settings.ThemeMode.light
                      ? Symbols.radio_button_checked_rounded
                      : Symbols.radio_button_unchecked_rounded,
                  fill: 1,
                ),
                title: Text(t.settings.lightTheme),
                onTap: () {
                  themeProvider.setThemeMode(settings.ThemeMode.light);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: AppIcon(
                  themeProvider.themeMode == settings.ThemeMode.dark
                      ? Symbols.radio_button_checked_rounded
                      : Symbols.radio_button_unchecked_rounded,
                  fill: 1,
                ),
                title: Text(t.settings.darkTheme),
                onTap: () {
                  themeProvider.setThemeMode(settings.ThemeMode.dark);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: AppIcon(
                  themeProvider.themeMode == settings.ThemeMode.oled
                      ? Symbols.radio_button_checked_rounded
                      : Symbols.radio_button_unchecked_rounded,
                  fill: 1,
                ),
                title: Text(t.settings.oledTheme),
                subtitle: Text(t.settings.oledThemeDescription),
                onTap: () {
                  themeProvider.setThemeMode(settings.ThemeMode.oled);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(t.common.cancel))],
        );
      },
    );
  }

  void _showBufferSizeDialog() {
    final options = [64, 128, 256, 512, 1024];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(t.settings.bufferSize),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((size) {
              return ListTile(
                leading: AppIcon(
                  _bufferSize == size ? Symbols.radio_button_checked_rounded : Symbols.radio_button_unchecked_rounded,
                  fill: 1,
                ),
                title: Text('${size}MB'),
                onTap: () {
                  setState(() {
                    _bufferSize = size;
                    _settingsService.setBufferSize(size);
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(t.common.cancel))],
        );
      },
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
    final isTV = PlatformDetector.isTV();

    if (isTV) {
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

  void _showPlayerBackendDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(t.settings.playerBackend),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: AppIcon(
                  _useExoPlayer ? Symbols.radio_button_checked_rounded : Symbols.radio_button_unchecked_rounded,
                  fill: 1,
                ),
                title: Text(t.settings.exoPlayer),
                subtitle: Text(t.settings.exoPlayerDescription),
                onTap: () async {
                  setState(() {
                    _useExoPlayer = true;
                  });
                  await _settingsService.setUseExoPlayer(true);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              ListTile(
                leading: AppIcon(
                  !_useExoPlayer ? Symbols.radio_button_checked_rounded : Symbols.radio_button_unchecked_rounded,
                  fill: 1,
                ),
                title: Text(t.settings.mpv),
                subtitle: Text(t.settings.mpvDescription),
                onTap: () async {
                  setState(() {
                    _useExoPlayer = false;
                  });
                  await _settingsService.setUseExoPlayer(false);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(t.common.cancel))],
        );
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
            TextButton(onPressed: () => Navigator.pop(context), child: Text(t.common.cancel)),
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
            TextButton(onPressed: () => Navigator.pop(context), child: Text(t.common.cancel)),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                await _settingsService.resetAllSettings();
                await _keyboardService?.resetToDefaults();
                if (mounted) {
                  navigator.pop();
                  showSuccessSnackBar(this.context, t.settings.resetSettingsSuccess);
                  // Reload settings
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
    }
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(t.settings.language),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppLocale.values.map((locale) {
              final isSelected = LocaleSettings.currentLocale == locale;
              return ListTile(
                title: Text(_getLanguageDisplayName(locale)),
                leading: AppIcon(
                  isSelected ? Symbols.radio_button_checked_rounded : Symbols.radio_button_unchecked_rounded,
                  fill: 1,
                  color: isSelected ? Theme.of(context).colorScheme.primary : null,
                ),
                tileColor: isSelected ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
                onTap: () async {
                  // Save the locale to settings
                  await _settingsService.setAppLocale(locale);

                  // Set the locale immediately
                  LocaleSettings.setLocale(locale);

                  // Close dialog
                  if (context.mounted) {
                    Navigator.pop(context);
                  }

                  // Trigger app-wide rebuild by restarting the app
                  if (context.mounted) {
                    _restartApp();
                  }
                },
              );
            }).toList(),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(t.common.cancel))],
        );
      },
    );
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
            TextButton(onPressed: () => Navigator.pop(context), child: Text(t.common.close)),
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

  /// Generic option selection dialog for settings with SettingsProvider
  void _showOptionSelectionDialog<T>({
    required String title,
    required List<_DialogOption<T>> options,
    required T Function(SettingsProvider) getCurrentValue,
    required Future<void> Function(T value, SettingsProvider provider) onSelect,
  }) {
    final settingsProvider = context.read<SettingsProvider>();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<SettingsProvider>(
          builder: (context, provider, child) {
            final currentValue = getCurrentValue(provider);
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: options.map((option) {
                  return ListTile(
                    leading: AppIcon(
                      currentValue == option.value
                          ? Symbols.radio_button_checked_rounded
                          : Symbols.radio_button_unchecked_rounded,
                      fill: 1,
                    ),
                    title: Text(option.title),
                    subtitle: option.subtitle != null ? Text(option.subtitle!) : null,
                    onTap: () async {
                      await onSelect(option.value, settingsProvider);
                      if (context.mounted) Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(t.common.cancel))],
            );
          },
        );
      },
    );
  }

  void _showLibraryDensityDialog() {
    _showOptionSelectionDialog<settings.LibraryDensity>(
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
      getCurrentValue: (p) => p.libraryDensity,
      onSelect: (value, provider) => provider.setLibraryDensity(value),
    );
  }

  void _showViewModeDialog() {
    _showOptionSelectionDialog<settings.ViewMode>(
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
      getCurrentValue: (p) => p.viewMode,
      onSelect: (value, provider) => provider.setViewMode(value),
    );
  }

  void _showEpisodePosterModeDialog() {
    _showOptionSelectionDialog<settings.EpisodePosterMode>(
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
      getCurrentValue: (p) => p.episodePosterMode,
      onSelect: (value, provider) => provider.setEpisodePosterMode(value),
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
    setState(() {
      _hotkeys = widget.keyboardService.hotkeys;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CustomAppBar(
            title: Text(t.settings.keyboardShortcuts),
            pinned: true,
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
          ),
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
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(6),
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
      ),
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
