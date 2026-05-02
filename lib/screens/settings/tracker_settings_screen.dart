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
import '../../widgets/setting_tile.dart';
import '../../widgets/settings_builder.dart';
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
  final Pref<bool> scrobblePref;
  final Future<void> Function(bool) onScrobbleChanged;
  final Future<void> Function(TrackersProvider) disconnect;

  const TrackerConfig({
    required this.service,
    required this.displayName,
    required this.isConnected,
    required this.username,
    required this.scrobblePref,
    required this.onScrobbleChanged,
    required this.disconnect,
  });

  static TrackerConfig mal() => TrackerConfig(
    service: TrackerService.mal,
    displayName: t.trackers.services.mal,
    isConnected: (a) => a.isMalConnected,
    username: (a) => a.malUsername,
    scrobblePref: SettingsService.enableMalScrobble,
    onScrobbleChanged: MalTracker.instance.setEnabled,
    disconnect: (a) => a.disconnectMal(),
  );

  static TrackerConfig anilist() => TrackerConfig(
    service: TrackerService.anilist,
    displayName: t.trackers.services.anilist,
    isConnected: (a) => a.isAnilistConnected,
    username: (a) => a.anilistUsername,
    scrobblePref: SettingsService.enableAnilistScrobble,
    onScrobbleChanged: AnilistTracker.instance.setEnabled,
    disconnect: (a) => a.disconnectAnilist(),
  );

  static TrackerConfig simkl() => TrackerConfig(
    service: TrackerService.simkl,
    displayName: t.trackers.services.simkl,
    isConnected: (a) => a.isSimklConnected,
    username: (a) => a.simklUsername,
    scrobblePref: SettingsService.enableSimklScrobble,
    onScrobbleChanged: SimklTracker.instance.setEnabled,
    disconnect: (a) => a.disconnectSimkl(),
  );
}

/// Shared settings screen for MAL, AniList, and Simkl. Only reachable while
/// connected — if the session drops (refresh failure, back-nav race) we pop
/// back to the hub.
class TrackerSettingsScreen extends StatelessWidget {
  final TrackerConfig config;
  const TrackerSettingsScreen({super.key, required this.config});

  Future<void> _disconnect(BuildContext context, TrackersProvider account) async {
    final confirmed = await showConfirmDialog(
      context,
      title: t.trackers.disconnectConfirm(service: config.displayName),
      message: t.trackers.disconnectConfirmBody(service: config.displayName),
      confirmText: t.common.disconnect,
      isDestructive: true,
    );
    if (!confirmed) return;
    await config.disconnect(account);
  }

  @override
  Widget build(BuildContext context) {
    final title = Text(config.displayName);

    return Consumer<TrackersProvider>(
      builder: (context, account, _) {
        if (!config.isConnected(account)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).pop();
          });
          return FocusedScrollScaffold(
            title: title,
            slivers: const [SliverFillRemaining(child: SizedBox.shrink())],
          );
        }

        final username = config.username(account);
        return FocusedScrollScaffold(
          title: title,
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate([
                ListTile(
                  leading: const AppIcon(Symbols.account_circle_rounded, fill: 1),
                  title: Text(username != null ? t.trackers.connectedAs(username: username) : config.displayName),
                ),
                SettingsSectionHeader(t.settings.behavior),
                SettingSwitchTile(
                  pref: config.scrobblePref,
                  icon: Symbols.auto_timer,
                  title: t.trackers.scrobble,
                  subtitle: t.trackers.scrobbleDescription,
                  onAfterWrite: config.onScrobbleChanged,
                ),
                SettingsBuilder(
                  prefs: [
                    SettingsService.trackerFilterModePref(config.service),
                    SettingsService.trackerFilterIdsPref(config.service),
                  ],
                  builder: (context) {
                    final settings = SettingsService.instanceOrNull!;
                    return ListTile(
                      leading: const AppIcon(Symbols.filter_list_rounded, fill: 1),
                      title: Text(t.trackers.libraryFilter.title),
                      subtitle: Text(TrackerLibraryFilterScreen.subtitleFor(settings, config.service)),
                      trailing: const AppIcon(Symbols.chevron_right_rounded, fill: 1),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => TrackerLibraryFilterScreen(service: config.service)),
                      ),
                    );
                  },
                ),
                const Divider(height: 32),
                ListTile(
                  leading: AppIcon(Symbols.link_off_rounded, fill: 1, color: Theme.of(context).colorScheme.error),
                  title: Text(t.common.disconnect, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  onTap: () => _disconnect(context, account),
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
