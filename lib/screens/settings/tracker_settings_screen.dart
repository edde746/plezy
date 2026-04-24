import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../focus/input_mode_tracker.dart';
import '../../i18n/strings.g.dart';
import '../../providers/trackers_provider.dart';
import '../../services/trackers/anilist/anilist_tracker.dart';
import '../../services/trackers/mal/mal_tracker.dart';
import '../../services/trackers/simkl/simkl_tracker.dart';
import '../../services/settings_service.dart';
import '../../utils/app_logger.dart';
import '../../utils/dialogs.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/device_code_dialog.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/settings_section.dart';

/// Start MAL's loopback-OAuth flow from anywhere. The user's browser opens to
/// complete the flow; no in-app dialog is needed. Shows a snackbar on failure.
Future<void> startMalConnection(BuildContext context) async {
  final account = context.read<TrackersProvider>();
  if (account.isConnecting(TrackerService.mal) || account.isMalConnected) return;
  final ok = await account.connectMal();
  if (!context.mounted) return;
  if (!ok && !account.isMalConnected) {
    showAppSnackBar(context, t.trackers.connectFailed(service: t.trackers.services.mal));
  }
}

/// Start AniList's loopback-OAuth flow from anywhere.
Future<void> startAnilistConnection(BuildContext context) async {
  final account = context.read<TrackersProvider>();
  if (account.isConnecting(TrackerService.anilist) || account.isAnilistConnected) return;
  final ok = await account.connectAnilist();
  if (!context.mounted) return;
  if (!ok && !account.isAnilistConnected) {
    showAppSnackBar(context, t.trackers.connectFailed(service: t.trackers.services.anilist));
  }
}

/// Start Simkl's device-code flow. Mirrors `startTraktConnection` — shows the
/// PIN dialog, polls, auto-launches the browser on pointer-driven platforms.
Future<void> startSimklConnection(BuildContext context) async {
  final account = context.read<TrackersProvider>();
  if (account.isConnecting(TrackerService.simkl) || account.isSimklConnected) return;

  final autoLaunchBrowser = !InputModeTracker.isKeyboardMode(context);
  var dialogOpen = false;

  final ok = await account.connectSimkl(
    onCodeReady: (code) {
      if (!context.mounted) return;
      dialogOpen = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => DeviceCodeDialog(
          code: code,
          serviceName: t.trackers.services.simkl,
          onCancel: account.cancelConnect,
        ),
      ).whenComplete(() => dialogOpen = false);
      if (autoLaunchBrowser) {
        unawaited(
          launchUrl(Uri.parse(code.verificationUrl), mode: LaunchMode.externalApplication).catchError((Object e) {
            appLogger.d('Simkl: failed to auto-launch browser', error: e);
            return false;
          }),
        );
      }
    },
  );

  if (!context.mounted) return;
  if (dialogOpen) {
    Navigator.of(context, rootNavigator: true).pop();
  }
  if (!ok && !account.isSimklConnected) {
    showAppSnackBar(context, t.trackers.connectFailed(service: t.trackers.services.simkl));
  }
}

/// Per-service wiring for [TrackerSettingsScreen]. Keeps tracker-specific
/// method names out of the shared screen body.
class TrackerConfig {
  final String displayName;
  final bool Function(TrackersProvider) isConnected;
  final String? Function(TrackersProvider) username;
  final bool Function(SettingsService) readScrobbleEnabled;
  final Future<void> Function(SettingsService, bool) setScrobbleEnabled;
  final Future<void> Function(TrackersProvider) disconnect;

  const TrackerConfig({
    required this.displayName,
    required this.isConnected,
    required this.username,
    required this.readScrobbleEnabled,
    required this.setScrobbleEnabled,
    required this.disconnect,
  });

  static TrackerConfig mal() => TrackerConfig(
    displayName: t.trackers.services.mal,
    isConnected: (a) => a.isMalConnected,
    username: (a) => a.malUsername,
    readScrobbleEnabled: (s) => s.getEnableMalScrobble(),
    setScrobbleEnabled: (s, v) async {
      await s.setEnableMalScrobble(v);
      await MalTracker.instance.setEnabled(v);
    },
    disconnect: (a) => a.disconnectMal(),
  );

  static TrackerConfig anilist() => TrackerConfig(
    displayName: t.trackers.services.anilist,
    isConnected: (a) => a.isAnilistConnected,
    username: (a) => a.anilistUsername,
    readScrobbleEnabled: (s) => s.getEnableAnilistScrobble(),
    setScrobbleEnabled: (s, v) async {
      await s.setEnableAnilistScrobble(v);
      await AnilistTracker.instance.setEnabled(v);
    },
    disconnect: (a) => a.disconnectAnilist(),
  );

  static TrackerConfig simkl() => TrackerConfig(
    displayName: t.trackers.services.simkl,
    isConnected: (a) => a.isSimklConnected,
    username: (a) => a.simklUsername,
    readScrobbleEnabled: (s) => s.getEnableSimklScrobble(),
    setScrobbleEnabled: (s, v) async {
      await s.setEnableSimklScrobble(v);
      await SimklTracker.instance.setEnabled(v);
    },
    disconnect: (a) => a.disconnectSimkl(),
  );
}

/// Shared settings screen for MAL, AniList, and Simkl. Only reachable while
/// connected — if the session drops (refresh failure, back-nav race) we pop
/// back to the hub.
class TrackerSettingsScreen extends StatefulWidget {
  final TrackerConfig config;
  const TrackerSettingsScreen({super.key, required this.config});

  @override
  State<TrackerSettingsScreen> createState() => _TrackerSettingsScreenState();
}

class _TrackerSettingsScreenState extends State<TrackerSettingsScreen> {
  SettingsService? _settings;
  bool _scrobbleEnabled = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await SettingsService.getInstance();
    if (!mounted) return;
    setState(() {
      _settings = s;
      _scrobbleEnabled = widget.config.readScrobbleEnabled(s);
      _loaded = true;
    });
  }

  Future<void> _disconnect(TrackersProvider account) async {
    final confirmed = await showConfirmDialog(
      context,
      title: t.trackers.disconnectConfirm(service: widget.config.displayName),
      message: t.trackers.disconnectConfirmBody(service: widget.config.displayName),
      confirmText: t.common.disconnect,
      isDestructive: true,
    );
    if (!confirmed) return;
    await widget.config.disconnect(account);
  }

  @override
  Widget build(BuildContext context) {
    final title = Text(widget.config.displayName);
    if (!_loaded) {
      return FocusedScrollScaffold(
        title: title,
        slivers: const [SliverFillRemaining(child: Center(child: CircularProgressIndicator()))],
      );
    }

    return Consumer<TrackersProvider>(
      builder: (context, account, _) {
        if (!widget.config.isConnected(account)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.of(context).pop();
          });
          return FocusedScrollScaffold(
            title: title,
            slivers: const [SliverFillRemaining(child: SizedBox.shrink())],
          );
        }

        final username = widget.config.username(account);
        return FocusedScrollScaffold(
          title: title,
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate([
                ListTile(
                  leading: const AppIcon(Symbols.account_circle_rounded, fill: 1),
                  title: Text(
                    username != null
                        ? t.trackers.connectedAs(username: username)
                        : widget.config.displayName,
                  ),
                ),
                SettingsSectionHeader(t.settings.behavior),
                SwitchListTile(
                  secondary: const AppIcon(Symbols.auto_timer, fill: 1),
                  title: Text(t.trackers.scrobble),
                  subtitle: Text(t.trackers.scrobbleDescription),
                  value: _scrobbleEnabled,
                  onChanged: (value) async {
                    setState(() => _scrobbleEnabled = value);
                    await widget.config.setScrobbleEnabled(_settings!, value);
                  },
                ),
                const Divider(height: 32),
                ListTile(
                  leading: AppIcon(Symbols.link_off_rounded, fill: 1, color: Theme.of(context).colorScheme.error),
                  title: Text(
                    t.common.disconnect,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  onTap: () => _disconnect(account),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ],
        );
      },
    );
  }
}
