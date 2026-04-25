import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../models/trackers/device_code.dart';
import '../../providers/trackers_provider.dart';
import '../../services/trackers/anilist/anilist_tracker.dart';
import '../../services/trackers/mal/mal_tracker.dart';
import '../../services/trackers/oauth_proxy_client.dart';
import '../../services/trackers/simkl/simkl_tracker.dart';
import '../../services/trackers/tracker_constants.dart';
import '../../services/settings_service.dart';
import '../../utils/dialogs.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/device_code_dialog.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/oauth_proxy_dialog.dart';
import '../../widgets/settings_section.dart';
import 'tracker_connect_launcher.dart';
import 'tracker_library_filter_screen.dart';

Future<void> startMalConnection(BuildContext context) {
  final account = context.read<TrackersProvider>();
  final name = t.trackers.services.mal;
  return launchTrackerConnect<OAuthProxyStart>(
    context,
    isBusyOrConnected: account.isConnecting(TrackerService.mal) || account.isMalConnected,
    serviceName: name,
    connect: (cb) => account.connectMal(onCodeReady: cb),
    onCancel: account.cancelConnect,
    buildDialog: (p, cancel) => OAuthProxyDialog(start: p, serviceName: name, onCancel: cancel),
    urlFor: (p) => p.url,
  );
}

Future<void> startAnilistConnection(BuildContext context) {
  final account = context.read<TrackersProvider>();
  final name = t.trackers.services.anilist;
  return launchTrackerConnect<OAuthProxyStart>(
    context,
    isBusyOrConnected: account.isConnecting(TrackerService.anilist) || account.isAnilistConnected,
    serviceName: name,
    connect: (cb) => account.connectAnilist(onCodeReady: cb),
    onCancel: account.cancelConnect,
    buildDialog: (p, cancel) => OAuthProxyDialog(start: p, serviceName: name, onCancel: cancel),
    urlFor: (p) => p.url,
  );
}

Future<void> startSimklConnection(BuildContext context) {
  final account = context.read<TrackersProvider>();
  final name = t.trackers.services.simkl;
  return launchTrackerConnect<DeviceCode>(
    context,
    isBusyOrConnected: account.isConnecting(TrackerService.simkl) || account.isSimklConnected,
    serviceName: name,
    connect: (cb) => account.connectSimkl(onCodeReady: cb),
    onCancel: account.cancelConnect,
    buildDialog: (p, cancel) => DeviceCodeDialog(code: p, serviceName: name, onCancel: cancel),
    urlFor: (p) => p.verificationUrlComplete ?? p.verificationUrl,
  );
}

/// Per-service wiring for [TrackerSettingsScreen]. Keeps tracker-specific
/// method names out of the shared screen body.
class TrackerConfig {
  final TrackerService service;
  final String displayName;
  final bool Function(TrackersProvider) isConnected;
  final String? Function(TrackersProvider) username;
  final bool Function(SettingsService) readScrobbleEnabled;
  final Future<void> Function(SettingsService, bool) setScrobbleEnabled;
  final Future<void> Function(TrackersProvider) disconnect;

  const TrackerConfig({
    required this.service,
    required this.displayName,
    required this.isConnected,
    required this.username,
    required this.readScrobbleEnabled,
    required this.setScrobbleEnabled,
    required this.disconnect,
  });

  static TrackerConfig mal() => TrackerConfig(
    service: TrackerService.mal,
    displayName: t.trackers.services.mal,
    isConnected: (a) => a.isMalConnected,
    username: (a) => a.malUsername,
    readScrobbleEnabled: (s) => s.read(SettingsService.enableMalScrobble),
    setScrobbleEnabled: (s, v) async {
      await s.write(SettingsService.enableMalScrobble, v);
      await MalTracker.instance.setEnabled(v);
    },
    disconnect: (a) => a.disconnectMal(),
  );

  static TrackerConfig anilist() => TrackerConfig(
    service: TrackerService.anilist,
    displayName: t.trackers.services.anilist,
    isConnected: (a) => a.isAnilistConnected,
    username: (a) => a.anilistUsername,
    readScrobbleEnabled: (s) => s.read(SettingsService.enableAnilistScrobble),
    setScrobbleEnabled: (s, v) async {
      await s.write(SettingsService.enableAnilistScrobble, v);
      await AnilistTracker.instance.setEnabled(v);
    },
    disconnect: (a) => a.disconnectAnilist(),
  );

  static TrackerConfig simkl() => TrackerConfig(
    service: TrackerService.simkl,
    displayName: t.trackers.services.simkl,
    isConnected: (a) => a.isSimklConnected,
    username: (a) => a.simklUsername,
    readScrobbleEnabled: (s) => s.read(SettingsService.enableSimklScrobble),
    setScrobbleEnabled: (s, v) async {
      await s.write(SettingsService.enableSimklScrobble, v);
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
                    username != null ? t.trackers.connectedAs(username: username) : widget.config.displayName,
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
                ListTile(
                  leading: const AppIcon(Symbols.filter_list_rounded, fill: 1),
                  title: Text(t.trackers.libraryFilter.title),
                  subtitle: Text(TrackerLibraryFilterScreen.subtitleFor(_settings!, widget.config.service)),
                  trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TrackerLibraryFilterScreen(service: widget.config.service),
                      ),
                    );
                    if (mounted) setState(() {});
                  },
                ),
                const Divider(height: 32),
                ListTile(
                  leading: AppIcon(Symbols.link_off_rounded, fill: 1, color: Theme.of(context).colorScheme.error),
                  title: Text(t.common.disconnect, style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
