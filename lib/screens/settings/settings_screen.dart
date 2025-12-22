import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../i18n/strings.g.dart';
import '../../services/download_storage_service.dart';
import '../../services/saf_storage_service.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/keyboard_shortcuts_service.dart';
import '../../services/settings_service.dart' as settings;
import '../../services/update_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/desktop_app_bar.dart';
import '../../widgets/tv_number_spinner.dart';
import 'hotkey_recorder_widget.dart';
import 'about_screen.dart';
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

class _SettingsScreenState extends State<SettingsScreen> {
  late settings.SettingsService _settingsService;
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
  bool _autoSkipIntro = true;
  bool _autoSkipCredits = true;
  int _autoSkipDelay = 5;
  bool _downloadOnWifiOnly = false;
  bool _videoPlayerNavigationEnabled = false;

  // Update checking state
  bool _isCheckingForUpdate = false;
  Map<String, dynamic>? _updateInfo;

  @override
  void initState() {
    super.initState();
    _loadSettings();
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
      _autoSkipIntro = _settingsService.getAutoSkipIntro();
      _autoSkipCredits = _settingsService.getAutoSkipCredits();
      _autoSkipDelay = _settingsService.getAutoSkipDelay();
      _downloadOnWifiOnly = _settingsService.getDownloadOnWifiOnly();
      _videoPlayerNavigationEnabled = _settingsService.getVideoPlayerNavigationEnabled();
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
          CustomAppBar(title: Text(t.settings.title), pinned: true),
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
                leading: AppIcon(themeProvider.themeModeIcon, fill: 1),
                title: Text(t.settings.theme),
                subtitle: Text(themeProvider.themeModeDisplayName),
                trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
                onTap: () => _showThemeDialog(themeProvider),
              );
            },
          ),
          ListTile(
            leading: const AppIcon(Symbols.language_rounded, fill: 1),
            title: Text(t.settings.language),
            subtitle: Text(_getLanguageDisplayName(LocaleSettings.currentLocale)),
            trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            onTap: () => _showLanguageDialog(),
          ),
          Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              return ListTile(
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
              return SwitchListTile(
                secondary: const AppIcon(Symbols.image_rounded, fill: 1),
                title: Text(t.settings.useSeasonPosters),
                subtitle: Text(t.settings.useSeasonPostersDescription),
                value: settingsProvider.useSeasonPoster,
                onChanged: (value) async {
                  await settingsProvider.setUseSeasonPoster(value);
                },
              );
            },
          ),
          Consumer<SettingsProvider>(
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
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlaybackSection() {
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
          SwitchListTile(
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
          ListTile(
            leading: const AppIcon(Symbols.memory_rounded, fill: 1),
            title: Text(t.settings.bufferSize),
            subtitle: Text(t.settings.bufferSizeMB(size: _bufferSize.toString())),
            trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            onTap: () => _showBufferSizeDialog(),
          ),
          ListTile(
            leading: const AppIcon(Symbols.subtitles_rounded, fill: 1),
            title: Text(t.settings.subtitleStyling),
            subtitle: Text(t.settings.subtitleStylingDescription),
            trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SubtitleStylingScreen()));
            },
          ),
          ListTile(
            leading: const AppIcon(Symbols.tune_rounded, fill: 1),
            title: Text(t.mpvConfig.title),
            subtitle: Text(t.mpvConfig.description),
            trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MpvConfigScreen()));
            },
          ),
          ListTile(
            leading: const AppIcon(Symbols.replay_10_rounded, fill: 1),
            title: Text(t.settings.smallSkipDuration),
            subtitle: Text(t.settings.secondsUnit(seconds: _seekTimeSmall.toString())),
            trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            onTap: () => _showSeekTimeSmallDialog(),
          ),
          ListTile(
            leading: const AppIcon(Symbols.replay_30_rounded, fill: 1),
            title: Text(t.settings.largeSkipDuration),
            subtitle: Text(t.settings.secondsUnit(seconds: _seekTimeLarge.toString())),
            trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            onTap: () => _showSeekTimeLargeDialog(),
          ),
          ListTile(
            leading: const AppIcon(Symbols.bedtime_rounded, fill: 1),
            title: Text(t.settings.defaultSleepTimer),
            subtitle: Text(t.settings.minutesUnit(minutes: _sleepTimerDuration.toString())),
            trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            onTap: () => _showSleepTimerDurationDialog(),
          ),
          SwitchListTile(
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
          if (!Platform.isIOS)
            FutureBuilder<String>(
              future: storageService.getCurrentDownloadPathDisplay(),
              builder: (context, snapshot) {
                final currentPath = snapshot.data ?? '...';

                return ListTile(
                  leading: const AppIcon(Symbols.folder_rounded, fill: 1),
                  title: Text(isCustom ? t.settings.downloadLocationCustom : t.settings.downloadLocationDefault),
                  subtitle: Text(currentPath, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
                  onTap: () => _showDownloadLocationDialog(),
                );
              },
            ),
          SwitchListTile(
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
            leading: const AppIcon(Symbols.keyboard_rounded, fill: 1),
            title: Text(t.settings.videoPlayerControls),
            subtitle: Text(t.settings.keyboardShortcutsDescription),
            trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            onTap: () => _showKeyboardShortcutsDialog(),
          ),
          SwitchListTile(
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
            leading: const AppIcon(Symbols.article_rounded, fill: 1),
            title: Text(t.settings.viewLogs),
            subtitle: Text(t.settings.viewLogsDescription),
            trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LogsScreen()));
            },
          ),
          ListTile(
            leading: const AppIcon(Symbols.cleaning_services_rounded, fill: 1),
            title: Text(t.settings.clearCache),
            subtitle: Text(t.settings.clearCacheDescription),
            trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            onTap: () => _showClearCacheDialog(),
          ),
          ListTile(
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
            leading: AppIcon(
              hasUpdate ? Symbols.system_update_rounded : Symbols.check_circle_rounded,
              fill: 1,
              color: hasUpdate ? Colors.orange : null,
            ),
            title: Text(hasUpdate ? t.settings.updateAvailable : t.settings.checkForUpdates),
            subtitle: hasUpdate
                ? Text(t.update.versionAvailable(version: _updateInfo!['latestVersion']))
                : Text(t.update.checkFailed),
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
    );
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
                final messenger = ScaffoldMessenger.of(context);
                await _settingsService.clearCache();
                if (mounted) {
                  navigator.pop();
                  messenger.showSnackBar(SnackBar(content: Text(t.settings.clearCacheSuccess)));
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
                final messenger = ScaffoldMessenger.of(context);
                await _settingsService.resetAllSettings();
                await _keyboardService?.resetToDefaults();
                if (mounted) {
                  navigator.pop();
                  messenger.showSnackBar(SnackBar(content: Text(t.settings.resetSettingsSuccess)));
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
                  final messenger = ScaffoldMessenger.of(context);
                  await widget.keyboardService.resetToDefaults();
                  await _loadHotkeys();
                  if (mounted) {
                    messenger.showSnackBar(SnackBar(content: Text(t.settings.shortcutsReset)));
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
            final messenger = ScaffoldMessenger.of(context);

            // Check for conflicts
            final existingAction = widget.keyboardService.getActionForHotkey(newHotkey);
            if (existingAction != null && existingAction != action) {
              navigator.pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    t.settings.shortcutAlreadyAssigned(
                      action: widget.keyboardService.getActionDisplayName(existingAction),
                    ),
                  ),
                ),
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

              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    t.settings.shortcutUpdated(action: widget.keyboardService.getActionDisplayName(action)),
                  ),
                ),
              );
            }
          },
          onCancel: () => Navigator.pop(context),
        );
      },
    );
  }
}
