import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../connection/connection.dart';
import '../../connection/connection_registry.dart';
import '../../i18n/strings.g.dart';
import '../../services/settings_mutation_service.dart';
import '../../services/settings_service.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/loading_indicator_box.dart';
import '../../widgets/settings_page.dart';
import '../../widgets/settings_section.dart';

class ServerStartupSettingsScreen extends StatefulWidget {
  const ServerStartupSettingsScreen({super.key});

  @override
  State<ServerStartupSettingsScreen> createState() => _ServerStartupSettingsScreenState();
}

class _ServerStartupSettingsScreenState extends State<ServerStartupSettingsScreen> {
  late final Future<List<_StartupServer>> _servers;

  @override
  void initState() {
    super.initState();
    _servers = context.read<ConnectionRegistry>().list().then(_collectServers);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: Text(t.settings.dontWaitForServers),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Text(t.settings.dontWaitForServersDescription),
        ),
        FutureBuilder<List<_StartupServer>>(
          future: _servers,
          builder: (context, snapshot) {
            if (snapshot.hasError) return const SizedBox.shrink();
            final servers = snapshot.data;
            if (servers == null) return const Center(child: LoadingIndicatorBox(size: 24));
            if (servers.isEmpty) {
              return Padding(padding: const EdgeInsets.all(20), child: Text(t.settings.noServersConfigured));
            }
            return ValueListenableBuilder<List<String>>(
              valueListenable: SettingsService.instance.listenable(SettingsService.startupWaitExcludedServers),
              builder: (context, excluded, _) => SettingsGroup(
                title: t.settings.servers,
                children: [
                  for (final server in servers)
                    FocusableCheckboxListTile(
                      secondary: const AppIcon(Symbols.dns_rounded, fill: 1),
                      title: Text(server.name),
                      subtitle: Text(server.backend),
                      value: excluded.contains(server.id),
                      onChanged: (value) => _setExcluded(excluded, server.id, value == true),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _setExcluded(List<String> current, String id, bool excluded) async {
    final next = Set<String>.of(current);
    if (excluded) {
      next.add(id);
    } else {
      next.remove(id);
    }
    await const SettingsMutationService().write(
      context,
      SettingsService.startupWaitExcludedServers,
      next.toList()..sort(),
    );
  }

  List<_StartupServer> _collectServers(List<Connection> connections) {
    final servers = <String, _StartupServer>{};
    for (final connection in connections) {
      switch (connection) {
        case PlexAccountConnection():
          for (final server in connection.servers) {
            final id = 'plex:${server.clientIdentifier}';
            servers.putIfAbsent(id, () => _StartupServer(id, server.name, 'Plex'));
          }
        case JellyfinConnection():
          final id = 'mediabrowser:${connection.serverMachineId}';
          servers.putIfAbsent(id, () => _StartupServer(id, connection.serverName, connection.kind.id));
      }
    }
    return servers.values.toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }
}

class _StartupServer {
  const _StartupServer(this.id, this.name, this.backend);

  final String id;
  final String name;
  final String backend;
}
