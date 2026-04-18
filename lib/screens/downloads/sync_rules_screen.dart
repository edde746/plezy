import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../database/app_database.dart';
import '../../models/plex_metadata.dart';
import '../../providers/download_provider.dart';
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
                    autofocus: index == 0,
                  );
                }, childCount: syncRules.length),
              ),
          ],
        );
      },
    );
  }
}

class _SyncRuleTile extends StatelessWidget {
  final SyncRuleItem rule;
  final Map<String, PlexMetadata> metadata;
  final DownloadProvider downloadProvider;
  final bool autofocus;

  const _SyncRuleTile({
    required this.rule,
    required this.metadata,
    required this.downloadProvider,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final meta = metadata[rule.globalKey];
    final title = meta?.title ?? rule.ratingKey;

    return FocusableListTile(
      autofocus: autofocus,
      leading: Icon(Symbols.sync_rounded, color: rule.enabled ? Colors.teal : null, size: 20),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(t.downloads.keepNUnwatched(count: rule.episodeCount.toString())),
      trailing: Switch(
        value: rule.enabled,
        onChanged: (value) => downloadProvider.setSyncRuleEnabled(rule.globalKey, value),
      ),
      onTap: () => editSyncRuleCount(
        context,
        downloadProvider: downloadProvider,
        globalKey: rule.globalKey,
        currentCount: rule.episodeCount,
      ),
    );
  }
}
