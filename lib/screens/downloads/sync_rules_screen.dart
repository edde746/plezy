import 'package:flutter/material.dart';
import '../../media/ids.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../connection/connection.dart';
import '../../connection/connection_registry.dart';
import '../../database/app_database.dart';
import '../../focus/focusable_wrapper.dart';
import '../../focus/input_mode_tracker.dart';
import '../../media/media_item.dart';
import '../../providers/download_provider.dart';
import '../../providers/multi_server_provider.dart';
import '../../services/sync_rule_executor.dart';
import '../../services/settings_service.dart';
import '../../models/transcode_quality_preset.dart';
import '../../media/media_backend.dart';
import '../../utils/content_utils.dart';
import '../../utils/download_utils.dart';
import '../../utils/quality_preset_labels.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/app_icon.dart';
import '../libraries/state_messages.dart';
import '../../i18n/strings.g.dart';

class SyncRulesScreen extends StatefulWidget {
  const SyncRulesScreen({super.key});

  @override
  State<SyncRulesScreen> createState() => _SyncRulesScreenState();
}

class _SyncRulesScreenState extends State<SyncRulesScreen> {
  late final Stream<List<Connection>> _connections;

  @override
  void initState() {
    super.initState();
    _connections = context.read<ConnectionRegistry>().watchConnections();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadProvider>(
      builder: (context, downloadProvider, _) {
        final syncRules = downloadProvider.syncRules;
        final multiServerProvider = context.watch<MultiServerProvider>();

        return StreamBuilder<List<Connection>>(
          stream: _connections,
          initialData: const [],
          builder: (context, snapshot) {
            final connections = snapshot.data ?? const <Connection>[];
            final autofocusFirstRule = InputModeTracker.isKeyboardMode(context);
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
                        autofocus: autofocusFirstRule && index == 0,
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
  final bool? isPlex;

  const _RuleServerInfo({required this.label, required this.isKnown, required this.isPlex});
}

class _SyncRuleTile extends StatefulWidget {
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

  @override
  State<_SyncRuleTile> createState() => _SyncRuleTileState();
}

class _SyncRuleTileState extends State<_SyncRuleTile> {
  final _rowFocusNode = FocusNode(debugLabel: 'sync_rule_row');
  final _switchFocusNode = FocusNode(debugLabel: 'sync_rule_switch');

  SyncRuleItem get rule => widget.rule;
  Map<String, MediaItem> get metadata => widget.metadata;
  DownloadProvider get downloadProvider => widget.downloadProvider;
  MultiServerProvider get multiServerProvider => widget.multiServerProvider;
  List<Connection> get connections => widget.connections;

  @override
  void dispose() {
    _rowFocusNode.dispose();
    _switchFocusNode.dispose();
    super.dispose();
  }

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
    final activeClient = multiServerProvider.getClientForServer(ServerId(rule.serverId));
    final activeName = activeClient?.serverName;
    if (activeName != null && activeName.isNotEmpty) {
      return _RuleServerInfo(label: activeName, isKnown: true, isPlex: activeClient?.backend == MediaBackend.plex);
    }

    final publicGlobalKey = '${rule.serverId}:${rule.ratingKey}';
    final meta = metadata[rule.globalKey] ?? metadata[publicGlobalKey];
    final metadataName = meta?.serverName;
    if (metadataName != null && metadataName.isNotEmpty) {
      return _RuleServerInfo(label: metadataName, isKnown: true, isPlex: meta?.backend == MediaBackend.plex);
    }

    for (final connection in connections) {
      switch (connection) {
        case PlexAccountConnection(:final servers):
          for (final server in servers) {
            if (server.clientIdentifier == rule.serverId && server.name.isNotEmpty) {
              return _RuleServerInfo(label: server.name, isKnown: true, isPlex: true);
            }
          }
        case JellyfinConnection(:final serverMachineId, :final serverName):
          if (serverMachineId == rule.serverId && serverName.isNotEmpty) {
            return _RuleServerInfo(label: serverName, isKnown: true, isPlex: false);
          }
      }
    }

    return _RuleServerInfo(label: rule.serverId, isKnown: false, isPlex: null);
  }

  String _qualityLabel() {
    final override = rule.downloadQualityPreset == null
        ? null
        : TranscodeQualityPreset.fromStorage(rule.downloadQualityPreset);
    final TranscodeQualityPreset resolved =
        override ??
        SettingsService.instanceOrNull?.read(SettingsService.defaultDownloadQualityPreset) ??
        TranscodeQualityPreset.original;
    final label = override == null
        ? t.downloads.defaultQualityOption(quality: qualityPresetLabel(resolved))
        : qualityPresetLabel(resolved);
    return t.downloads.syncRuleQuality(quality: label);
  }

  Future<void> _editQuality(BuildContext context) async {
    final settings = await SettingsService.getInstance();
    if (!context.mounted) return;
    final selected = await showDownloadQualityPickerDialog(
      context,
      defaultPreset: settings.read(SettingsService.defaultDownloadQualityPreset),
      currentOverride: rule.downloadQualityPreset == null
          ? null
          : TranscodeQualityPreset.fromStorage(rule.downloadQualityPreset),
    );
    if (selected == null || !context.mounted) return;
    await downloadProvider.updateSyncRuleDownloadQuality(rule.globalKey, selected.override);
    await downloadProvider.executeSyncRuleFor(rule.globalKey, multiServerProvider.serverManager);
  }

  String _serverStatusForRule(_RuleServerInfo serverInfo) {
    if (!serverInfo.isKnown) return t.downloads.syncRuleUnknownServer;
    if (multiServerProvider.authErrorServerIds.contains(rule.serverId)) return t.downloads.syncRuleSignInRequired;
    if (!multiServerProvider.serverIds.contains(rule.serverId)) return t.downloads.syncRuleNotAvailableForProfile;
    return multiServerProvider.isServerOnline(ServerId(rule.serverId))
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
        displayTitle: _title(),
      );
    }
  }

  String _title() {
    final publicGlobalKey = '${rule.serverId}:${rule.ratingKey}';
    final meta = metadata[rule.globalKey] ?? metadata[publicGlobalKey];
    return meta?.title ?? rule.ratingKey;
  }

  Future<void> _removeRule(BuildContext context) async {
    await removeSyncRuleAndSnack(
      context,
      downloadProvider: downloadProvider,
      globalKey: rule.globalKey,
      displayTitle: _title(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _title();
    final serverInfo = _serverLabelForRule();
    final serverLine = t.downloads.syncRuleServerContext(
      server: serverInfo.label,
      status: _serverStatusForRule(serverInfo),
    );

    return _SwipeRevealDeleteAction(
      onDelete: () => _removeRule(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: FocusableWrapper(
          autofocus: widget.autofocus,
          focusNode: _rowFocusNode,
          disableScale: true,
          useBackgroundFocus: true,
          borderRadius: 12,
          onSelect: () => _onTap(context),
          onNavigateRight: () => _switchFocusNode.requestFocus(),
          child: Material(
            type: MaterialType.transparency,
            child: ListTile(
              dense: true,
              visualDensity: const VisualDensity(vertical: -3),
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
              leading: AppIcon(_leadingIcon(), color: rule.enabled ? Colors.teal : null, size: 20),
              title: Text(title, maxLines: 1, overflow: .ellipsis),
              subtitle: Column(
                crossAxisAlignment: .start,
                mainAxisSize: .min,
                children: [
                  Text(_subtitle(), maxLines: 1, overflow: .ellipsis),
                  Text(serverLine, maxLines: 1, overflow: .ellipsis),
                  if (serverInfo.isPlex == true) Text(_qualityLabel(), maxLines: 1, overflow: .ellipsis),
                  if (serverInfo.isPlex == null)
                    Text(t.downloads.syncRuleQualityPlexOnly, maxLines: 1, overflow: .ellipsis),
                ],
              ),
              trailing: Row(
                mainAxisSize: .min,
                children: [
                  if (serverInfo.isPlex == true)
                    IconButton(
                      tooltip: t.downloads.downloadQuality,
                      onPressed: () => _editQuality(context),
                      icon: const AppIcon(Symbols.high_quality_rounded, size: 20),
                    ),
                  FocusableWrapper(
                    focusNode: _switchFocusNode,
                    disableScale: true,
                    useBackgroundFocus: true,
                    descendantsAreFocusable: false,
                    borderRadius: 20,
                    onSelect: () async {
                      final enabled = !rule.enabled;
                      await downloadProvider.setSyncRuleEnabled(rule.globalKey, enabled);
                      if (enabled) {
                        await downloadProvider.executeSyncRuleFor(rule.globalKey, multiServerProvider.serverManager);
                      }
                    },
                    onNavigateLeft: () => _rowFocusNode.requestFocus(),
                    child: Switch(
                      value: rule.enabled,
                      onChanged: (value) async {
                        await downloadProvider.setSyncRuleEnabled(rule.globalKey, value);
                        if (value) {
                          await downloadProvider.executeSyncRuleFor(rule.globalKey, multiServerProvider.serverManager);
                        }
                      },
                    ),
                  ),
                ],
              ),
              onTap: () => _onTap(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeRevealDeleteAction extends StatefulWidget {
  final Widget child;
  final VoidCallback onDelete;

  const _SwipeRevealDeleteAction({required this.child, required this.onDelete});

  @override
  State<_SwipeRevealDeleteAction> createState() => _SwipeRevealDeleteActionState();
}

class _SwipeRevealDeleteActionState extends State<_SwipeRevealDeleteAction> {
  static const double _deleteWidth = 88;
  double _dragExtent = 0;

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent = (_dragExtent - details.delta.dx).clamp(0, _deleteWidth);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final shouldOpen =
        _dragExtent > _deleteWidth / 2 || details.primaryVelocity != null && details.primaryVelocity! < -500;
    setState(() => _dragExtent = shouldOpen ? _deleteWidth : 0);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return ClipRect(
      child: Stack(
        children: [
          if (_dragExtent > 0)
            Positioned.fill(
              right: 8,
              child: Align(
                alignment: .centerRight,
                child: SizedBox(
                  width: _deleteWidth,
                  child: ExcludeFocus(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Material(
                        color: colorScheme.error,
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          key: const ValueKey('sync_rule_swipe_delete'),
                          onTap: widget.onDelete,
                          child: Tooltip(
                            message: t.downloads.removeSyncRule,
                            child: Column(
                              mainAxisAlignment: .center,
                              children: [
                                AppIcon(Symbols.delete_rounded, color: colorScheme.onError, size: 20),
                                const SizedBox(height: 2),
                                Text(
                                  t.common.delete,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onError,
                                    fontWeight: .w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: _handleDragUpdate,
            onHorizontalDragEnd: _handleDragEnd,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(-_dragExtent, 0, 0),
              child: DecoratedBox(
                decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
