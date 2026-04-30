import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../connection/connection.dart';
import '../../connection/connection_registry.dart';
import '../../database/app_database.dart';
import '../../media/media_item.dart';
import '../../providers/download_provider.dart';
import '../../providers/multi_server_provider.dart';
import '../../services/sync_rule_executor.dart';
import '../../utils/content_utils.dart';
import '../../utils/download_utils.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/focusable_list_tile.dart';
import '../libraries/state_messages.dart';
import '../../i18n/strings.g.dart';

class SyncRulesScreen extends StatelessWidget {
  const SyncRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadProvider>(
      builder: (context, downloadProvider, _) {
        final syncRules = downloadProvider.syncRules;
        final multiServerProvider = context.watch<MultiServerProvider>();
        final connectionRegistry = context.read<ConnectionRegistry>();

        return StreamBuilder<List<Connection>>(
          stream: connectionRegistry.watchConnections(),
          initialData: const [],
          builder: (context, snapshot) {
            final connections = snapshot.data ?? const <Connection>[];
            return FocusedScrollScaffold(
              title: Text(t.downloads.activeSyncRules),
              slivers: [
                if (syncRules.isEmpty)
                  SliverFillRemaining(
                    child: EmptyStateWidget(message: t.downloads.noSyncRules, icon: Symbols.sync_rounded, iconSize: 80),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final entry = syncRules.entries.elementAt(index);
                      final rule = entry.value;
                      return _SyncRuleTile(
                        rule: rule,
                        metadata: downloadProvider.metadata,
                        downloadProvider: downloadProvider,
                        multiServerProvider: multiServerProvider,
                        connections: connections,
                        autofocus: index == 0,
                      );
                    }, childCount: syncRules.length),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _RuleServerInfo {
  final String label;
  final bool isKnown;

  const _RuleServerInfo({required this.label, required this.isKnown});
}

class _SyncRuleTile extends StatelessWidget {
  final SyncRuleItem rule;
  final Map<String, MediaItem> metadata;
  final DownloadProvider downloadProvider;
  final MultiServerProvider multiServerProvider;
  final List<Connection> connections;
  final bool autofocus;

  const _SyncRuleTile({
    required this.rule,
    required this.metadata,
    required this.downloadProvider,
    required this.multiServerProvider,
    required this.connections,
    this.autofocus = false,
  });

  IconData _leadingIcon() {
    switch (rule.targetType) {
      case ContentTypes.playlist:
        return Symbols.playlist_play_rounded;
      case ContentTypes.collection:
        return Symbols.collections_bookmark_rounded;
      case ContentTypes.show:
      case ContentTypes.season:
        return Symbols.tv_rounded;
      default:
        return Symbols.sync_rounded;
    }
  }

  String _subtitle() {
    switch (rule.targetType) {
      case ContentTypes.collection:
      case ContentTypes.playlist:
        return rule.downloadFilter == SyncRuleFilter.all ? t.downloads.syncAllItems : t.downloads.syncUnwatchedItems;
      default:
        return t.downloads.keepNUnwatched(count: rule.episodeCount.toString());
    }
  }

  _RuleServerInfo _serverLabelForRule() {
    final activeName = multiServerProvider.getClientForServer(rule.serverId)?.serverName;
    if (activeName != null && activeName.isNotEmpty) {
      return _RuleServerInfo(label: activeName, isKnown: true);
    }

    final publicGlobalKey = '${rule.serverId}:${rule.ratingKey}';
    final meta = metadata[rule.globalKey] ?? metadata[publicGlobalKey];
    final metadataName = meta?.serverName;
    if (metadataName != null && metadataName.isNotEmpty) {
      return _RuleServerInfo(label: metadataName, isKnown: true);
    }

    for (final connection in connections) {
      switch (connection) {
        case PlexAccountConnection(:final servers):
          for (final server in servers) {
            if (server.clientIdentifier == rule.serverId && server.name.isNotEmpty) {
              return _RuleServerInfo(label: server.name, isKnown: true);
            }
          }
        case JellyfinConnection(:final serverMachineId, :final serverName):
          if (serverMachineId == rule.serverId && serverName.isNotEmpty) {
            return _RuleServerInfo(label: serverName, isKnown: true);
          }
      }
    }

    return _RuleServerInfo(label: rule.serverId, isKnown: false);
  }

  String _serverStatusForRule(_RuleServerInfo serverInfo) {
    if (!serverInfo.isKnown) return t.downloads.syncRuleUnknownServer;
    if (multiServerProvider.authErrorServerIds.contains(rule.serverId)) return t.downloads.syncRuleSignInRequired;
    if (!multiServerProvider.serverIds.contains(rule.serverId)) return t.downloads.syncRuleNotAvailableForProfile;
    return multiServerProvider.isServerOnline(rule.serverId)
        ? t.downloads.syncRuleAvailable
        : t.downloads.syncRuleOffline;
  }

  Future<void> _onTap(BuildContext context) async {
    if (rule.isListRule) {
      await editSyncRuleFilter(
        context,
        downloadProvider: downloadProvider,
        globalKey: rule.globalKey,
        currentFilter: rule.downloadFilter,
      );
    } else {
      await editSyncRuleCount(
        context,
        downloadProvider: downloadProvider,
        globalKey: rule.globalKey,
        currentCount: rule.episodeCount,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final publicGlobalKey = '${rule.serverId}:${rule.ratingKey}';
    final meta = metadata[rule.globalKey] ?? metadata[publicGlobalKey];
    final title = meta?.title ?? rule.ratingKey;
    final serverInfo = _serverLabelForRule();
    final serverLine = t.downloads.syncRuleServerContext(
      server: serverInfo.label,
      status: _serverStatusForRule(serverInfo),
    );

    return FocusableListTile(
      autofocus: autofocus,
      leading: Icon(_leadingIcon(), color: rule.enabled ? Colors.teal : null, size: 20),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_subtitle(), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(serverLine, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
      trailing: Switch(
        value: rule.enabled,
        onChanged: (value) => downloadProvider.setSyncRuleEnabled(rule.globalKey, value),
      ),
      onTap: () => _onTap(context),
    );
  }
}
