import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../i18n/strings.g.dart';
import '../../services/settings_service.dart' as settings;
import '../../services/update_service.dart';
import '../../utils/dialogs.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/update_dialog.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/loading_indicator_box.dart';
import '../../widgets/setting_tile.dart';
import '../../widgets/settings_section.dart';

/// Labs-only update controls kept outside the upstream settings screen so
/// routine Plezy UI changes do not create release-sync conflicts.
class LabsUpdateSettingsSection extends StatefulWidget {
  const LabsUpdateSettingsSection({
    required this.officialFocusNode,
    required this.labsFocusNode,
    required this.checkFocusNode,
    required this.autoCheckFocusNode,
    super.key,
  });

  final FocusNode officialFocusNode;
  final FocusNode labsFocusNode;
  final FocusNode checkFocusNode;
  final FocusNode autoCheckFocusNode;

  @override
  State<LabsUpdateSettingsSection> createState() => _LabsUpdateSettingsSectionState();
}

class _LabsUpdateSettingsSectionState extends State<LabsUpdateSettingsSection> {
  bool _isCheckingForUpdate = false;
  Map<String, dynamic>? _updateInfo;
  UpdateReleaseSources? _releaseSources;
  UpdateChannel _updateChannel = UpdateChannel.labs;

  @override
  void initState() {
    super.initState();
    unawaited(_loadUpdateSources());
  }

  @override
  Widget build(BuildContext context) {
    final official = _releaseSources?.official;
    final labs = _releaseSources?.labs;
    final labsSubtitle = _releaseSources?.labsIsBehindOfficial == true && official != null
        ? t.settings.labsNotAvailable(version: official.version)
        : labs == null
        ? t.settings.releaseStatusUnavailable
        : t.settings.latestLabsRelease(version: labs.displayVersion);

    return SettingsGroup(
      title: t.settings.updates,
      children: [
        FocusableListTile(
          focusNode: widget.officialFocusNode,
          leading: const AppIcon(Symbols.verified_rounded, fill: 1),
          title: Text(t.settings.officialPlezy),
          subtitle: Text(
            official == null
                ? t.settings.releaseStatusUnavailable
                : t.settings.latestOfficialRelease(version: official.version),
          ),
          trailing: _updateChannel == UpdateChannel.official
              ? const AppIcon(Symbols.check_circle_rounded, fill: 1)
              : const AppIcon(Symbols.open_in_new_rounded, fill: 1),
          onTap: _confirmOfficialHandoff,
        ),
        FocusableListTile(
          focusNode: widget.labsFocusNode,
          leading: const AppIcon(Symbols.science_rounded, fill: 1),
          title: Text(t.settings.plezyLabs),
          subtitle: Text(labsSubtitle),
          trailing: _updateChannel == UpdateChannel.labs
              ? const AppIcon(Symbols.check_circle_rounded, fill: 1)
              : const AppIcon(Symbols.chevron_right_rounded, fill: 1),
          onTap: _activateLabsChannel,
        ),
        FocusableListTile(
          focusNode: widget.checkFocusNode,
          leading: const AppIcon(Symbols.refresh_rounded, fill: 1),
          title: Text(t.settings.checkForUpdates),
          trailing: _isCheckingForUpdate
              ? const LoadingIndicatorBox(size: 24)
              : const AppIcon(Symbols.chevron_right_rounded, fill: 1),
          onTap: _isCheckingForUpdate ? null : _checkForUpdates,
        ),
        SettingSwitchTile(
          focusNode: widget.autoCheckFocusNode,
          pref: settings.SettingsService.autoCheckUpdatesOnStartup,
          icon: Symbols.notifications_active_rounded,
          title: t.settings.autoCheckUpdatesOnStartup,
          subtitle: t.settings.autoCheckUpdatesOnStartupDescription,
        ),
      ],
    );
  }

  Future<void> _loadUpdateSources() async {
    final results = await Future.wait<Object>([UpdateService.fetchReleaseSources(), UpdateService.getUpdateChannel()]);
    if (!mounted) return;
    setState(() {
      _releaseSources = results[0] as UpdateReleaseSources;
      _updateChannel = results[1] as UpdateChannel;
    });
  }

  Future<void> _confirmOfficialHandoff() async {
    final confirmed = await showConfirmDialog(
      context,
      title: t.update.returnToOfficialTitle,
      message: t.update.returnToOfficialWarning,
      confirmText: t.update.openOfficialRelease,
      isDestructive: true,
    );
    if (!confirmed) return;

    final url = _releaseSources?.official?.releaseUrl ?? UpdateService.officialReleasesUrl;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _activateLabsChannel() async {
    await UpdateService.setUpdateChannel(UpdateChannel.labs);
    if (mounted) setState(() => _updateChannel = UpdateChannel.labs);
    if (UpdateService.useNativeUpdater) {
      await UpdateService.checkForUpdatesNative(inBackground: false);
    } else {
      await _checkForUpdates();
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() => _isCheckingForUpdate = true);

    try {
      if (_updateChannel == UpdateChannel.labs && UpdateService.useNativeUpdater) {
        await UpdateService.checkForUpdatesNative(inBackground: false);
        await _loadUpdateSources();
        if (mounted) setState(() => _isCheckingForUpdate = false);
        return;
      }

      final updateInfo = await UpdateService.checkForUpdates();
      final releaseSources = await UpdateService.fetchReleaseSources();
      if (!mounted) return;

      setState(() {
        _updateInfo = updateInfo;
        _releaseSources = releaseSources;
        _isCheckingForUpdate = false;
      });

      if (updateInfo != null && updateInfo['hasUpdate'] == true) {
        _showUpdateDialog();
      } else {
        showAppSnackBar(context, t.update.latestVersion);
      }
    } catch (_) {
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
