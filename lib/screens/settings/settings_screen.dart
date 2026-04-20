import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../focus/focus_memory_tracker.dart';
import '../../focus/input_mode_tracker.dart';
import '../../i18n/strings.g.dart';
import '../main_screen.dart';
import '../../mixins/refreshable.dart';
import '../../providers/hidden_libraries_provider.dart';
import '../../providers/libraries_provider.dart';
import '../../services/donation_service.dart';
import '../../services/download_storage_service.dart';
import '../../services/file_picker_service.dart';
import '../../services/saf_storage_service.dart';
import '../../services/settings_export_service.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/trakt_account_provider.dart';
import '../../services/keyboard_shortcuts_service.dart';
import '../../services/settings_service.dart' as settings;
import '../../services/update_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/desktop_app_bar.dart';
import '../../widgets/settings_section.dart';
import 'about_screen.dart';
import 'appearance_settings_screen.dart';
import 'keyboard_shortcuts_screen.dart';
import 'logs_screen.dart';
import 'playback_settings_screen.dart';
import 'trakt_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with FocusableTab {
  late settings.SettingsService _settingsService;
  late final FocusMemoryTracker _focusTracker;

  // Focus tracking keys
  static const _kDonate = 'donate';
  static const _kAppearance = 'appearance';
  static const _kPlayback = 'playback';
  static const _kTrakt = 'trakt';
  static const _kDownloadLocation = 'download_location';
  static const _kDownloadOnWifiOnly = 'download_on_wifi_only';
  static const _kAutoRemoveWatchedDownloads = 'auto_remove_watched_downloads';
  static const _kVideoPlayerControls = 'video_player_controls';
  static const _kVideoPlayerNavigation = 'video_player_navigation';
  static const _kCrashReporting = 'crash_reporting';
  static const _kDebugLogging = 'debug_logging';
  static const _kViewLogs = 'view_logs';
  static const _kClearCache = 'clear_cache';
  static const _kResetSettings = 'reset_settings';
  static const _kCheckForUpdates = 'check_for_updates';
  static const _kAbout = 'about';
  static const _kWatchTogetherRelay = 'watch_together_relay';
  static const _kExportSettings = 'export_settings';
  static const _kImportSettings = 'import_settings';

  KeyboardShortcutsService? _keyboardService;
  late final bool _keyboardShortcutsSupported = KeyboardShortcutsService.isPlatformSupported();
  bool _isLoading = true;

  bool _crashReporting = true;
  bool _enableDebugLogging = false;
  bool _downloadOnWifiOnly = false;
  bool _autoRemoveWatchedDownloads = false;
  bool _videoPlayerNavigationEnabled = false;
  String? _customRelayUrl;

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
      _focusTracker.restoreFocus(fallbackKey: DonationService.isEnabled ? _kDonate : _kAppearance);
    }
  }

  void _navigateToSidebar() {
    MainScreenFocusScope.of(context)?.focusSidebar();
  }

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
      _downloadOnWifiOnly = _settingsService.getDownloadOnWifiOnly();
      _autoRemoveWatchedDownloads = _settingsService.getAutoRemoveWatchedDownloads();
      _videoPlayerNavigationEnabled = _settingsService.getVideoPlayerNavigationEnabled();
      _customRelayUrl = _settingsService.getCustomRelayUrl();
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
          primary: false,
          slivers: [
            ExcludeFocus(child: CustomAppBar(title: Text(t.settings.title), pinned: true)),
            SliverList(
              delegate: SliverChildListDelegate([
                // --- Donate (non-store builds only) ---
                if (DonationService.isEnabled) _buildDonateTile(),

                // --- Appearance (navigation tile) ---
                _buildAppearanceTile(),

                // --- Playback (navigation tile) ---
                _buildPlaybackTile(),

                // --- Trakt.tv (navigation tile) ---
                _buildTraktTile(),

                // --- Downloads (inline) ---
                _buildDownloadsSection(),

                // --- Keyboard Shortcuts (inline, conditional) ---
                if (_keyboardShortcutsSupported) ...[_buildKeyboardShortcutsSection()],

                // --- Advanced (inline) ---
                _buildAdvancedSection(),

                // --- Updates (conditional) ---
                if (UpdateService.isUpdateCheckEnabled) ...[_buildUpdateSection()],

                // --- Backup ---
                _buildBackupSection(),

                // --- About ---
                ListTile(
                  focusNode: _focusTracker.get(_kAbout),
                  leading: const AppIcon(Symbols.info_rounded, fill: 1),
                  title: Text(t.settings.about),
                  subtitle: Text(t.settings.aboutDescription),
                  trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
                  },
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonateTile() {
    return ListTile(
      focusNode: _focusTracker.get(_kDonate),
      leading: const AppIcon(Symbols.favorite_rounded, fill: 1),
      title: Text(t.settings.supportDeveloper),
      subtitle: Text(t.settings.supportDeveloperDescription),
      trailing: const AppIcon(Symbols.open_in_new_rounded, fill: 1),
      onTap: () async {
        final url = Uri.parse(DonationService.donationUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      },
    );
  }

  Widget _buildAppearanceTile() {
    return Consumer2<ThemeProvider, SettingsProvider>(
      builder: (context, themeProvider, settingsProvider, child) {
        final summary =
            '${themeProvider.themeModeDisplayName} · ${t.settings.libraryDensity} ${settingsProvider.libraryDensity}';
        return ListTile(
          focusNode: _focusTracker.get(_kAppearance),
          leading: const AppIcon(Symbols.palette_rounded, fill: 1),
          title: Text(t.settings.appearance),
          subtitle: Text(summary),
          trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const AppearanceSettingsScreen()));
          },
        );
      },
    );
  }

  Widget _buildPlaybackTile() {
    return ListTile(
      focusNode: _focusTracker.get(_kPlayback),
      leading: const AppIcon(Symbols.play_circle_rounded, fill: 1),
      title: Text(t.settings.videoPlayback),
      subtitle: Text(t.settings.videoPlaybackDescription),
      trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const PlaybackSettingsScreen()));
      },
    );
  }

  Widget _buildTraktTile() {
    return Consumer<TraktAccountProvider>(
      builder: (context, account, _) {
        final connected = account.isConnected;
        final username = account.username;
        final iconColor = IconTheme.of(context).color ?? Theme.of(context).colorScheme.onSurface;
        return ListTile(
          focusNode: _focusTracker.get(_kTrakt),
          leading: SvgPicture.asset(
            'assets/trakt_circlemark.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
          title: Text(t.settings.trakt),
          subtitle: Text(
            connected && username != null ? t.trakt.connectedAs(username: username) : t.settings.traktDescription,
          ),
          trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
          onTap: () {
            if (account.isConnected) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const TraktSettingsScreen()));
            } else {
              startTraktConnection(context);
            }
          },
        );
      },
    );
  }

  Widget _buildDownloadsSection() {
    final storageService = DownloadStorageService.instance;
    final isCustom = storageService.isUsingCustomPath();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(t.settings.downloads),
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
        SwitchListTile(
          focusNode: _focusTracker.get(_kAutoRemoveWatchedDownloads),
          secondary: const AppIcon(Symbols.delete_sweep_rounded, fill: 1),
          title: Text(t.settings.autoRemoveWatchedDownloads),
          subtitle: Text(t.settings.autoRemoveWatchedDownloadsDescription),
          value: _autoRemoveWatchedDownloads,
          onChanged: (value) async {
            setState(() => _autoRemoveWatchedDownloads = value);
            await _settingsService.setAutoRemoveWatchedDownloads(value);
          },
        ),
      ],
    );
  }

  Widget _buildKeyboardShortcutsSection() {
    if (_keyboardService == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(t.settings.keyboardShortcuts),
        ListTile(
          focusNode: _focusTracker.get(_kVideoPlayerControls),
          leading: const AppIcon(Symbols.keyboard_rounded, fill: 1),
          title: Text(t.settings.videoPlayerControls),
          subtitle: Text(t.settings.keyboardShortcutsDescription),
          trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => KeyboardShortcutsScreen(keyboardService: _keyboardService!)),
            );
          },
        ),
        SwitchListTile(
          focusNode: _focusTracker.get(_kVideoPlayerNavigation),
          secondary: const AppIcon(Symbols.gamepad_rounded, fill: 1),
          title: Text(t.settings.videoPlayerNavigation),
          subtitle: Text(t.settings.videoPlayerNavigationDescription),
          value: _videoPlayerNavigationEnabled,
          onChanged: (value) async {
            setState(() => _videoPlayerNavigationEnabled = value);
            await _settingsService.setVideoPlayerNavigationEnabled(value);
          },
        ),
      ],
    );
  }

  Widget _buildAdvancedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(t.settings.advanced),
        ListTile(
          focusNode: _focusTracker.get(_kWatchTogetherRelay),
          leading: const AppIcon(Symbols.dns_rounded, fill: 1),
          title: Text(t.settings.watchTogetherRelay),
          subtitle: Text(t.settings.watchTogetherRelayDescription),
          trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
          onTap: () => _showRelayUrlDialog(),
        ),
        SwitchListTile(
          focusNode: _focusTracker.get(_kCrashReporting),
          secondary: const AppIcon(Symbols.monitoring_rounded, fill: 1),
          title: Text(t.settings.crashReporting),
          subtitle: Text(t.settings.crashReportingDescription),
          value: _crashReporting,
          onChanged: (value) async {
            setState(() => _crashReporting = value);
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
            setState(() => _enableDebugLogging = value);
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
    );
  }

  Widget _buildBackupSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(t.settings.backup),
        ListTile(
          focusNode: _focusTracker.get(_kExportSettings),
          leading: const AppIcon(Symbols.upload_rounded, fill: 1),
          title: Text(t.settings.exportSettings),
          subtitle: Text(t.settings.exportSettingsDescription),
          trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
          onTap: _handleExportSettings,
        ),
        ListTile(
          focusNode: _focusTracker.get(_kImportSettings),
          leading: const AppIcon(Symbols.download_rounded, fill: 1),
          title: Text(t.settings.importSettings),
          subtitle: Text(t.settings.importSettingsDescription),
          trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
          onTap: _showImportSettingsDialog,
        ),
      ],
    );
  }

  Widget _buildUpdateSection() {
    if (UpdateService.useNativeUpdater) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SettingsSectionHeader(t.settings.updates),
          ListTile(
            focusNode: _focusTracker.get(_kCheckForUpdates),
            leading: const AppIcon(Symbols.system_update_rounded, fill: 1),
            title: Text(t.settings.checkForUpdates),
            trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
            onTap: () => UpdateService.checkForUpdatesNative(inBackground: false),
          ),
        ],
      );
    }

    final hasUpdate = _updateInfo != null && _updateInfo!['hasUpdate'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(t.settings.updates),
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
    );
  }

  // --- Dialogs ---

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
        final safService = SafStorageService.instance;
        selectedPath = await safService.pickDirectory();
        if (selectedPath != null) {
          pathType = 'saf';
        } else if (PlatformDetector.isTV()) {
          if (mounted) {
            showErrorSnackBar(context, t.settings.downloadLocationSelectError);
          }
          return;
        }
      } else {
        final result = await FilePickerService.instance.getDirectoryPath(dialogTitle: t.settings.selectFolder);
        selectedPath = result;
      }

      if (selectedPath != null) {
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

  void _showRelayUrlDialog() {
    final controller = TextEditingController(text: _customRelayUrl ?? '');
    final saveFocusNode = FocusNode();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(t.settings.watchTogetherRelay),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: 'URL', hintText: t.settings.watchTogetherRelayHint),
            autofocus: true,
            textInputAction: TextInputAction.done,
            onEditingComplete: () => saveFocusNode.requestFocus(),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                controller.clear();
                await _settingsService.setCustomRelayUrl(null);
                if (mounted) setState(() => _customRelayUrl = null);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: Text(t.settings.resetToDefault),
            ),
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.common.cancel)),
            TextButton(
              focusNode: saveFocusNode,
              onPressed: () async {
                final url = controller.text.trim().isEmpty ? null : controller.text.trim();
                await _settingsService.setCustomRelayUrl(url);
                if (mounted) setState(() => _customRelayUrl = url);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: Text(t.common.save),
            ),
          ],
        );
      },
    ).then((_) {
      controller.dispose();
      saveFocusNode.dispose();
    });
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

  Future<void> _handleExportSettings() async {
    try {
      final path = await SettingsExportService.exportToFile();
      if (!mounted) return;
      if (path == null) return; // user cancelled
      showSuccessSnackBar(context, t.settings.exportSettingsSuccess);
    } on SettingsExportException {
      if (mounted) showErrorSnackBar(context, t.settings.exportSettingsFailed);
    } catch (_) {
      if (mounted) showErrorSnackBar(context, t.settings.exportSettingsFailed);
    }
  }

  void _showImportSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(t.settings.importSettings),
          content: Text(t.settings.importSettingsConfirm),
          actions: [
            TextButton(autofocus: true, onPressed: () => Navigator.pop(dialogContext), child: Text(t.common.cancel)),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _handleImportSettings();
              },
              child: Text(t.settings.importSettings),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleImportSettings() async {
    // Capture providers before any awaits so we don't reach through `context`
    // after the widget may have been unmounted.
    final themeProvider = context.read<ThemeProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final hiddenLibrariesProvider = context.read<HiddenLibrariesProvider>();
    final librariesProvider = context.read<LibrariesProvider>();

    try {
      final result = await SettingsExportService.importFromFile();
      if (!mounted) return;
      if (result == null) return; // user cancelled file picker

      LocaleSettings.setLocale(_settingsService.getAppLocale());
      await Future.wait([
        themeProvider.reload(),
        settingsProvider.reload(),
        hiddenLibrariesProvider.refresh(),
        if (_keyboardService != null) _keyboardService!.refreshFromStorage(),
      ]);
      unawaited(librariesProvider.refresh());

      if (!mounted) return;
      _loadSettings();
      showSuccessSnackBar(context, t.settings.importSettingsSuccess);
    } on NoUserSignedInException {
      if (mounted) showErrorSnackBar(context, t.settings.importSettingsNoUser);
    } on InvalidExportFileException {
      if (mounted) showErrorSnackBar(context, t.settings.importSettingsInvalidFile);
    } on SettingsExportException {
      if (mounted) showErrorSnackBar(context, t.settings.importSettingsFailed);
    } catch (_) {
      if (mounted) showErrorSnackBar(context, t.settings.importSettingsFailed);
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() => _isCheckingForUpdate = true);

    try {
      final updateInfo = await UpdateService.checkForUpdates();

      if (mounted) {
        setState(() {
          _updateInfo = updateInfo;
          _isCheckingForUpdate = false;
        });

        if (updateInfo == null || updateInfo['hasUpdate'] != true) {
          showAppSnackBar(context, t.update.latestVersion);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingForUpdate = false);
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
