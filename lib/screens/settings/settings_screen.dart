import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../focus/focus_memory_tracker.dart';
import '../../focus/focusable_text_field.dart';
import '../../focus/input_mode_tracker.dart';
import '../../i18n/strings.g.dart';
import '../main_screen.dart';
import '../../mixins/mounted_set_state_mixin.dart';
import '../../mixins/refreshable.dart';
import '../../providers/hidden_libraries_provider.dart';
import '../../providers/libraries_provider.dart';
import '../../services/donation_service.dart';
import '../../services/download_storage_service.dart';
import '../../services/file_picker_service.dart';
import '../../services/saf_storage_service.dart';
import '../../services/settings_export_service.dart';
import '../../providers/theme_provider.dart';
import '../../providers/trackers_provider.dart';
import '../../providers/trakt_account_provider.dart';
import '../../services/keyboard_shortcuts_service.dart';
import '../../services/settings_service.dart' as settings;
import '../../services/update_service.dart';
import '../../utils/dialogs.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/platform_detector.dart';
import '../../utils/update_dialog.dart';
import '../../widgets/desktop_app_bar.dart';
import '../../widgets/dialog_action_button.dart';
import '../../widgets/setting_tile.dart';
import '../../widgets/settings_builder.dart';
import '../../widgets/settings_section.dart';
import '../../profiles/active_profile_provider.dart';
import '../../profiles/profile.dart';
import '../../profiles/profile_registry.dart';
import 'about_screen.dart';
import 'add_connection_screen.dart';
import 'appearance_settings_screen.dart';
import 'keyboard_shortcuts_screen.dart';
import 'logs_screen.dart';
import 'playback_settings_screen.dart';
import '../profile/profile_switch_screen.dart';
import 'trackers_settings_screen.dart';
import '../../widgets/loading_indicator_box.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with FocusableTab, MountedSetStateMixin {
  late final FocusMemoryTracker _focusTracker;

  // Focus tracking keys
  static const _kDonate = 'donate';
  static const _kAppearance = 'appearance';
  static const _kPlayback = 'playback';
  static const _kTrackers = 'trackers';
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
  static const _kAutoCheckUpdatesOnStartup = 'auto_check_updates_on_startup';
  static const _kAbout = 'about';
  static const _kWatchTogetherRelay = 'watch_together_relay';
  static const _kExportSettings = 'export_settings';
  static const _kImportSettings = 'import_settings';

  KeyboardShortcutsService? _keyboardService;
  late final bool _keyboardShortcutsSupported = KeyboardShortcutsService.isPlatformSupported();

  // Update checking state
  bool _isCheckingForUpdate = false;
  Map<String, dynamic>? _updateInfo;

  @override
  void initState() {
    super.initState();
    _focusTracker = FocusMemoryTracker(
      onFocusChanged: () {
        // ignore: no-empty-block - setState triggers rebuild to update focus styling
        setStateIfMounted(() {});
      },
      debugLabelPrefix: 'settings',
    );
    if (_keyboardShortcutsSupported) {
      KeyboardShortcutsService.getInstance().then((s) {
        setStateIfMounted(() => _keyboardService = s);
      });
    }
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

  settings.SettingsService get _settingsService => settings.SettingsService.instanceOrNull!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Focus(
        onKeyEvent: _handleKeyEvent,
        child: CustomScrollView(
          primary: false,
          slivers: [
            ExcludeFocus(child: CustomAppBar(title: Text(t.settings.title), pinned: true)),
            SliverList(
              delegate: SliverChildListDelegate([
                if (DonationService.isEnabled) _buildDonateTile(),

                _buildAppearanceTile(),

                _buildPlaybackTile(),

                _buildTrackersTile(),

                _buildConnectionsSection(),

                _buildProfilesSection(),

                if (!PlatformDetector.isAppleTV()) _buildDownloadsSection(),

                if (_keyboardShortcutsSupported) ...[_buildKeyboardShortcutsSection()],

                _buildAdvancedSection(),

                if (UpdateService.isUpdateCheckEnabled) ...[_buildUpdateSection()],

                if (!PlatformDetector.isTV()) _buildBackupSection(),

                SettingNavigationTile(
                  focusNode: _focusTracker.get(_kAbout),
                  icon: Symbols.info_rounded,
                  title: t.settings.about,
                  subtitle: t.settings.aboutDescription,
                  destinationBuilder: (context) => const AboutScreen(),
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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) => SettingValueBuilder<int>(
        pref: settings.SettingsService.libraryDensity,
        builder: (context, libraryDensity, _) {
          final summary = '${themeProvider.themeModeDisplayName} · ${t.settings.libraryDensity} $libraryDensity';
          return SettingNavigationTile(
            focusNode: _focusTracker.get(_kAppearance),
            icon: Symbols.palette_rounded,
            title: t.settings.appearance,
            subtitle: summary,
            destinationBuilder: (context) => const AppearanceSettingsScreen(),
          );
        },
      ),
    );
  }

  Widget _buildPlaybackTile() {
    return SettingNavigationTile(
      focusNode: _focusTracker.get(_kPlayback),
      icon: Symbols.play_circle_rounded,
      title: t.settings.videoPlayback,
      subtitle: t.settings.videoPlaybackDescription,
      destinationBuilder: (context) => const PlaybackSettingsScreen(),
    );
  }

  Widget _buildTrackersTile() {
    return Consumer2<TraktAccountProvider, TrackersProvider>(
      builder: (context, trakt, trackers, _) {
        final connectedNames = <String>[
          if (trakt.isConnected) t.trakt.title,
          if (trackers.isMalConnected) t.trackers.services.mal,
          if (trackers.isAnilistConnected) t.trackers.services.anilist,
          if (trackers.isSimklConnected) t.trackers.services.simkl,
        ];
        final subtitle = connectedNames.isEmpty ? t.settings.trackersDescription : connectedNames.join(' · ');
        return SettingNavigationTile(
          focusNode: _focusTracker.get(_kTrackers),
          icon: Symbols.sync_rounded,
          title: t.settings.trackers,
          subtitle: subtitle,
          destinationBuilder: (_) => const TrackersSettingsScreen(),
        );
      },
    );
  }

  Widget _buildConnectionsSection() {
    final active = context.select<ActiveProfileProvider, Profile?>((p) => p.active);
    final subtitle = active == null
        ? t.connections.addConnectionSubtitleNoProfile
        : t.connections.addConnectionSubtitleScoped(displayName: active.displayName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(t.connections.sectionTitle),
        // Connections are managed per-profile (via the Profiles section
        // and each profile's detail screen). The shortcut here just opens
        // the picker scoped to the active profile so users can add a Plex
        // account, Jellyfin server, or borrow from another profile.
        SettingNavigationTile(
          icon: Symbols.add_link_rounded,
          title: t.connections.addConnection,
          subtitle: subtitle,
          onTap: () {
            final active = context.read<ActiveProfileProvider>().active;
            Navigator.push(context, MaterialPageRoute(builder: (_) => AddConnectionScreen(targetProfile: active)));
          },
        ),
      ],
    );
  }

  Widget _buildProfilesSection() {
    return StreamBuilder<List<Profile>>(
      stream: context.read<ProfileRegistry>().watchProfiles(),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        // `context.select` so this StreamBuilder doesn't rebuild on every
        // ActiveProfileProvider notification — only when the active
        // profile's display name actually changes.
        final activeName = context.select<ActiveProfileProvider, String?>((p) => p.active?.displayName);
        final subtitle = count <= 1
            ? t.profiles.summarySingle
            : (activeName != null
                  ? t.profiles.summaryMultipleWithActive(count: count, activeName: activeName)
                  : t.profiles.summaryMultiple(count: count));
        return SettingNavigationTile(
          icon: Symbols.group_rounded,
          title: t.profiles.sectionTitle,
          subtitle: subtitle,
          destinationBuilder: (_) => const ProfileSwitchScreen(),
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
        SettingSwitchTile(
          focusNode: _focusTracker.get(_kDownloadOnWifiOnly),
          pref: settings.SettingsService.downloadOnWifiOnly,
          icon: Symbols.wifi_rounded,
          title: t.settings.downloadOnWifiOnly,
          subtitle: t.settings.downloadOnWifiOnlyDescription,
        ),
        SettingSwitchTile(
          focusNode: _focusTracker.get(_kAutoRemoveWatchedDownloads),
          pref: settings.SettingsService.autoRemoveWatchedDownloads,
          icon: Symbols.delete_sweep_rounded,
          title: t.settings.autoRemoveWatchedDownloads,
          subtitle: t.settings.autoRemoveWatchedDownloadsDescription,
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
        SettingNavigationTile(
          focusNode: _focusTracker.get(_kVideoPlayerControls),
          icon: Symbols.keyboard_rounded,
          title: t.settings.videoPlayerControls,
          subtitle: t.settings.keyboardShortcutsDescription,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => KeyboardShortcutsScreen(keyboardService: _keyboardService!)),
            );
          },
        ),
        SettingSwitchTile(
          focusNode: _focusTracker.get(_kVideoPlayerNavigation),
          pref: settings.SettingsService.videoPlayerNavigationEnabled,
          icon: Symbols.gamepad_rounded,
          title: t.settings.videoPlayerNavigation,
          subtitle: t.settings.videoPlayerNavigationDescription,
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
        SettingSwitchTile(
          focusNode: _focusTracker.get(_kCrashReporting),
          pref: settings.SettingsService.crashReporting,
          icon: Symbols.monitoring_rounded,
          title: t.settings.crashReporting,
          subtitle: t.settings.crashReportingDescription,
        ),
        SettingSwitchTile(
          focusNode: _focusTracker.get(_kDebugLogging),
          pref: settings.SettingsService.enableDebugLogging,
          icon: Symbols.bug_report_rounded,
          title: t.settings.debugLogging,
          subtitle: t.settings.debugLoggingDescription,
        ),
        SettingNavigationTile(
          focusNode: _focusTracker.get(_kViewLogs),
          icon: Symbols.article_rounded,
          title: t.settings.viewLogs,
          subtitle: t.settings.viewLogsDescription,
          destinationBuilder: (context) => const LogsScreen(),
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

  Widget _buildAutoCheckUpdatesOnStartupTile() => SettingSwitchTile(
    focusNode: _focusTracker.get(_kAutoCheckUpdatesOnStartup),
    pref: settings.SettingsService.autoCheckUpdatesOnStartup,
    icon: Symbols.notifications_active_rounded,
    title: t.settings.autoCheckUpdatesOnStartup,
    subtitle: t.settings.autoCheckUpdatesOnStartupDescription,
  );

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
          _buildAutoCheckUpdatesOnStartupTile(),
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
              ? const LoadingIndicatorBox(size: 24)
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
        _buildAutoCheckUpdatesOnStartupTile(),
      ],
    );
  }

  Future<void> _showDownloadLocationDialog() async {
    final storageService = DownloadStorageService.instance;
    final isCustom = storageService.isUsingCustomPath();

    await showDialog<void>(
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
            DialogActionButton(
              onPressed: () async {
                // Run the async work first, then pop — popping first leaves
                // setState inside _resetDownloadLocation racing against the
                // already-dismissed dialog (and any re-opened instance).
                await _resetDownloadLocation();
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              label: t.settings.resetToDefault,
            ),
          DialogActionButton(onPressed: () => Navigator.pop(dialogContext), label: t.common.cancel),
          DialogActionButton(
            onPressed: () async {
              await _selectDownloadLocation();
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            label: t.settings.selectFolder,
            isPrimary: true,
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

        await _settingsService.write(settings.SettingsService.customDownloadPath, selectedPath);
        await _settingsService.write(settings.SettingsService.customDownloadPathType, pathType);
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
    await _settingsService.write(settings.SettingsService.customDownloadPath, null);
    await _settingsService.write(settings.SettingsService.customDownloadPathType, null);
    await DownloadStorageService.instance.refreshCustomPath();

    if (mounted) {
      // ignore: no-empty-block - setState triggers rebuild to reflect reset path
      setState(() {});
      showAppSnackBar(context, t.settings.downloadLocationReset);
    }
  }

  Future<void> _showRelayUrlDialog() async {
    final controller = TextEditingController(
      text: _settingsService.read(settings.SettingsService.customRelayUrl) ?? '',
    );
    final saveFocusNode = FocusNode();
    // try/finally guarantees disposal on every dismissal path (button,
    // back, tap-outside) without depending on `.then` chaining.
    try {
      await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(t.settings.watchTogetherRelay),
            content: FocusableTextField(
              controller: controller,
              decoration: InputDecoration(labelText: 'URL', hintText: t.settings.watchTogetherRelayHint),
              autofocus: true,
              textInputAction: TextInputAction.done,
              onEditingComplete: () => saveFocusNode.requestFocus(),
            ),
            actions: [
              DialogActionButton(
                onPressed: () async {
                  controller.clear();
                  await _settingsService.write(settings.SettingsService.customRelayUrl, null);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
                label: t.settings.resetToDefault,
              ),
              DialogActionButton(onPressed: () => Navigator.pop(dialogContext), label: t.common.cancel),
              DialogActionButton(
                focusNode: saveFocusNode,
                onPressed: () async {
                  final url = controller.text.trim().isEmpty ? null : controller.text.trim();
                  await _settingsService.write(settings.SettingsService.customRelayUrl, url);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                },
                label: t.common.save,
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
      saveFocusNode.dispose();
    }
  }

  Future<void> _showClearCacheDialog() async {
    final confirmed = await showConfirmDialog(
      context,
      title: t.settings.clearCache,
      message: t.settings.clearCacheDescription,
      confirmText: t.common.clear,
    );
    if (!confirmed) return;
    await _settingsService.clearCache();
    if (mounted) showSuccessSnackBar(context, t.settings.clearCacheSuccess);
  }

  Future<void> _showResetSettingsDialog() async {
    final confirmed = await showConfirmDialog(
      context,
      title: t.settings.resetSettings,
      message: t.settings.resetSettingsDescription,
      confirmText: t.common.reset,
      isDestructive: true,
    );
    if (!confirmed) return;
    await _settingsService.resetAllSettings();
    await _keyboardService?.resetToDefaults();
    if (mounted) showSuccessSnackBar(context, t.settings.resetSettingsSuccess);
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

  Future<void> _showImportSettingsDialog() async {
    final confirmed = await showConfirmDialog(
      context,
      title: t.settings.importSettings,
      message: t.settings.importSettingsConfirm,
      confirmText: t.settings.importSettings,
    );
    if (!confirmed) return;
    await _handleImportSettings();
  }

  Future<void> _handleImportSettings() async {
    // Capture providers before any awaits so we don't reach through `context`
    // after the widget may have been unmounted.
    final themeProvider = context.read<ThemeProvider>();
    final hiddenLibrariesProvider = context.read<HiddenLibrariesProvider>();
    final librariesProvider = context.read<LibrariesProvider>();

    try {
      final result = await SettingsExportService.importFromFile();
      if (!mounted) return;
      if (result == null) return; // user cancelled file picker

      // Import wrote directly to SharedPreferences, bypassing `write`. Push
      // fresh values into active listenables before providers re-read settings.
      _settingsService.refreshListenables();
      unawaited(LocaleSettings.setLocale(_settingsService.read(settings.SettingsService.appLocale)));
      await Future.wait([
        themeProvider.reload(),
        hiddenLibrariesProvider.refresh(),
        if (_keyboardService != null) _keyboardService!.refreshFromStorage(),
      ]);
      unawaited(librariesProvider.refresh());

      if (!mounted) return;
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
    final updateInfo = _updateInfo;
    if (updateInfo == null) return;
    unawaited(
      showUpdateAvailableDialog(context, updateInfo, title: t.settings.updateAvailable, dismissLabel: t.common.close),
    );
  }
}
