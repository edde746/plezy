import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../media/ids.dart';
import '../../i18n/strings.g.dart';
import '../../profiles/active_profile_provider.dart';
import '../../providers/multi_server_provider.dart';
import '../../sources/source_controller.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/setting_tile.dart';
import '../../widgets/settings_section.dart';
import '../profile/profile_switch_screen.dart';
import '../sources/file_sources_setup.dart';
import 'add_connection_screen.dart';
import 'logs_screen.dart';

/// A compact household setup and connection check built from the existing
/// profile, server, Files and books, and diagnostics flows.
class HouseholdSetupScreen extends StatelessWidget {
  const HouseholdSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profiles = context.watch<ActiveProfileProvider>();
    final servers = context.watch<MultiServerProvider>();
    final sources = context.watch<SourceController?>();
    final active = profiles.active;
    final expectedServers = servers.expectedServerIds.length;
    final onlineServers = servers.onlineServerCount;
    final sourceCount = sources?.sources.length ?? 0;
    final authErrors = servers.authErrorServers;
    final denied = servers.accessDeniedServers;
    final sourceDetail = sourceCount == 0 ? t.fileSources.emptyHint : '$sourceCount · ${t.fileSources.source}';
    final serverProblem = _serverProblem(authErrors, denied, onlineServers, expectedServers);
    final hasMedia = expectedServers > 0 || sourceCount > 0;
    final hasConnectionProblem = serverProblem != null;
    final isReady = hasMedia && !hasConnectionProblem;
    final statusIcon = isReady ? Symbols.check_circle_rounded : Symbols.warning_rounded;
    final statusColor = isReady ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.tertiary;
    final connectionDetail =
        serverProblem ??
        (expectedServers == 0
            ? (sourceCount == 0 ? t.profiles.noConnectionsHint : sourceDetail)
            : t.connections.sectionTitle);
    final profileDetail = profiles.profiles.length > 1
        ? t.profiles.summaryMultiple(count: profiles.profiles.length)
        : t.profiles.summarySingle;

    return FocusedScrollScaffold(
      title: Text(t.householdSetup.title),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsGroup(
                  title: t.connections.sectionTitle,
                  children: [
                    ListTile(
                      leading: AppIcon(statusIcon, fill: 1, color: statusColor),
                      title: Text(active?.displayName ?? t.profiles.noConnections),
                      subtitle: Text(
                        active == null
                            ? t.profiles.noConnectionsHint
                            : '$onlineServers / $expectedServers · $connectionDetail',
                      ),
                    ),
                    ListTile(
                      leading: const AppIcon(Symbols.group_rounded, fill: 1),
                      title: Text(t.profiles.sectionTitle),
                      subtitle: Text(profileDetail),
                    ),
                    ListTile(
                      leading: const AppIcon(Symbols.folder_rounded, fill: 1),
                      title: Text(t.fileSources.title),
                      subtitle: Text(sourceDetail),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SettingsGroup(
                  children: [
                    SettingNavigationTile(
                      icon: Symbols.add_link_rounded,
                      title: authErrors.isNotEmpty ? t.connections.signInAgain : t.connections.addConnection,
                      subtitle: active == null
                          ? t.connections.addConnectionSubtitleNoProfile
                          : t.connections.addConnectionSubtitleScoped(displayName: active.displayName),
                      destinationBuilder: (_) => AddConnectionScreen(targetProfile: active),
                    ),
                    SettingNavigationTile(
                      icon: Symbols.group_rounded,
                      title: t.profiles.manage,
                      subtitle: profileDetail,
                      destinationBuilder: (_) => const ProfileSwitchScreen(),
                    ),
                    SettingNavigationTile(
                      icon: Symbols.folder_rounded,
                      title: t.fileSources.title,
                      subtitle: sourceDetail,
                      onTap: () {
                        openFileSourcesSession(context, createIfEmpty: true);
                      },
                    ),
                    SettingNavigationTile(
                      icon: Symbols.description_rounded,
                      title: t.settings.viewLogs,
                      subtitle: t.settings.viewLogsDescription,
                      destinationBuilder: (_) => const LogsScreen(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String? _serverProblem(
    List<({ServerId serverId, String displayName})> authErrors,
    List<({ServerId serverId, String displayName})> denied,
    int online,
    int expected,
  ) {
    if (authErrors.length == 1) return t.connections.sessionExpiredOne(name: authErrors.single.displayName);
    if (authErrors.length > 1) return t.connections.sessionExpiredMany(count: authErrors.length);
    if (denied.length == 1) return t.connections.accessDeniedOne(name: denied.single.displayName);
    if (denied.length > 1) return t.connections.accessDeniedMany(count: denied.length);
    if (expected > online) return t.common.reconnect;
    return null;
  }
}
