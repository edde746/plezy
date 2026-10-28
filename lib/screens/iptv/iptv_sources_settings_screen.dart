import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../i18n/iptv_copy.dart';
import '../../iptv/iptv_models.dart';
import '../../iptv/iptv_source_repository.dart';
import '../../services/settings_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/settings_section.dart';
import 'add_iptv_source_screen.dart';
import 'iptv_channels_settings_screen.dart';

enum _SourceAction { edit, channels, refresh, remove }

class IptvSourcesSettingsScreen extends StatefulWidget {
  const IptvSourcesSettingsScreen({super.key, required this.profileId});

  final String? profileId;

  @override
  State<IptvSourcesSettingsScreen> createState() => _IptvSourcesSettingsScreenState();
}

class _IptvSourcesSettingsScreenState extends State<IptvSourcesSettingsScreen> {
  List<IptvSourceSummary> _sources = const [];
  bool _loading = true;
  String? _busySourceId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final profileId = widget.profileId;
    if (profileId == null) {
      if (mounted) setState(() {
        _sources = const [];
        _loading = false;
      });
      return;
    }
    if (mounted) setState(() => _loading = true);
    try {
      final sources = await context.read<IptvSourceRepository>().sources(profileId);
      if (mounted) setState(() {
        _sources = sources;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _kindName(IptvInputKind kind) => switch (kind) {
    IptvInputKind.m3u => t.iptv.m3u,
    IptvInputKind.xtream => t.iptv.xtream,
    IptvInputKind.tunerr => t.iptv.tunerr,
    IptvInputKind.dispatcharr => t.iptv.dispatcharr,
    IptvInputKind.stalker => t.iptv.stalker,
  };

  String _date(DateTime value) {
    final local = value.toLocal();
    String two(int part) => part.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }

  Future<void> _openEditor([IptvSourceSummary? source]) async {
    final profileId = widget.profileId;
    if (profileId == null) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddIptvSourceScreen(profileId: profileId, sourceId: source?.id),
      ),
    );
    if (changed == true && mounted) await _load();
  }

  Future<void> _refresh(IptvSourceSummary source) async {
    final profileId = widget.profileId;
    if (profileId == null || _busySourceId != null) return;
    setState(() => _busySourceId = source.id);
    try {
      final count = await context.read<IptvSourceRepository>().refresh(profileId, source.id);
      if (!mounted) return;
      showSuccessSnackBar(context, t.iptv.importComplete(count: count));
    } catch (error) {
      if (!mounted) return;
      showErrorSnackBar(context, _messageFor(error));
    } finally {
      if (mounted) setState(() => _busySourceId = null);
      await _load();
    }
  }

  Future<void> _remove(IptvSourceSummary source) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.iptv.removeTitle),
        content: Text(t.iptv.removeMessage(name: source.displayName)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(t.common.cancel)),
          FilledButton.tonal(onPressed: () => Navigator.pop(dialogContext, true), child: Text(t.common.delete)),
        ],
      ),
    );
    if (confirmed != true || widget.profileId == null || !mounted) return;
    try {
      await context.read<IptvSourceRepository>().deleteSource(widget.profileId!, source.id);
      await _load();
    } catch (error) {
      if (mounted) showErrorSnackBar(context, _messageFor(error));
    }
  }

  String _messageFor(Object error) {
    if (error is! IptvImportException) return t.iptv.providerUnavailable;
    return switch (error.code) {
      'authentication' => t.iptv.authentication,
      'permission' => t.iptv.permission,
      'invalid_data' => t.iptv.invalidData,
      'playlist_is_stream' => t.iptv.playlistIsStream,
      'http_not_allowed' => t.iptv.httpNotAllowed,
      'source_changed' => t.iptv.sourceChanged,
      'credential_unavailable' => t.iptv.credentialUnavailable,
      _ => t.iptv.providerUnavailable,
    };
  }

  String _sourceError(String? code) => switch (code) {
    'authentication' => t.iptv.authentication,
    'permission' => t.iptv.permission,
    'invalid_data' => t.iptv.invalidData,
    'playlist_is_stream' => t.iptv.playlistIsStream,
    'http_not_allowed' => t.iptv.httpNotAllowed,
    'source_changed' => t.iptv.sourceChanged,
    'credential_unavailable' => t.iptv.credentialUnavailable,
    _ => t.iptv.providerUnavailable,
  };

  Future<void> _handleAction(IptvSourceSummary source, _SourceAction action) async {
    switch (action) {
      case _SourceAction.edit:
        await _openEditor(source);
        break;
      case _SourceAction.channels:
        await Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => IptvChannelsSettingsScreen(profileId: widget.profileId!, sourceId: source.id),
          ),
        );
        await _load();
        break;
      case _SourceAction.refresh:
        await _refresh(source);
        break;
      case _SourceAction.remove:
        await _remove(source);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileId = widget.profileId;
    final colors = Theme.of(context).colorScheme;
    return FocusedScrollScaffold(
      title: Text(t.iptv.sourcesTitle),
      actions: [
        IconButton(
          tooltip: t.iptv.refresh,
          onPressed: _loading || profileId == null ? null : _load,
          icon: const AppIcon(Symbols.refresh_rounded, fill: 1),
        ),
      ],
      bottomBar: profileId == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  onPressed: _busySourceId == null ? () => _openEditor() : null,
                  icon: const AppIcon(Symbols.add_rounded, fill: 1),
                  label: Text(t.iptv.addSource),
                ),
              ),
            ),
      slivers: [
        if (profileId != null)
          SliverPadding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            sliver: SliverToBoxAdapter(
              child: SettingsGroup(
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: SettingsService.instance.listenable(SettingsService.iptvVodProgressSyncEnabled),
                    builder: (context, enabled, _) => SwitchListTile.adaptive(
                      secondary: const AppIcon(Symbols.sync_rounded),
                      title: Text(t.iptv.vodProgressSync),
                      subtitle: Text(t.iptv.vodProgressSyncHelp),
                      value: enabled,
                      onChanged: (value) => SettingsService.instance.write(
                        SettingsService.iptvVodProgressSyncEnabled,
                        value,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (profileId == null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(t.iptv.noActiveProfile, textAlign: TextAlign.center),
              ),
            ),
          )
        else if (_loading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_sources.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(Symbols.live_tv_rounded, size: 48, color: colors.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text(t.iptv.emptyTitle, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(t.iptv.emptyDescription, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.only(top: 8, bottom: 20),
            sliver: SliverToBoxAdapter(
              child: SettingsGroup(children: [for (final source in _sources) _sourceTile(source)]),
            ),
          ),
      ],
    );
  }

  Widget _sourceTile(IptvSourceSummary source) {
    final subtitleParts = <String>[
      _kindName(source.kind),
      t.iptv.channels(count: source.channelCount),
      t.iptv.programmes(count: source.programmeCount),
      source.lastSuccessAt == null ? t.iptv.neverUpdated : t.iptv.lastUpdated(date: _date(source.lastSuccessAt!)),
      if (source.lastErrorCode != null) _sourceError(source.lastErrorCode),
    ];
    final busy = _busySourceId == source.id;
    return ListTile(
      leading: const AppIcon(Symbols.live_tv_rounded, fill: 1),
      title: Text(source.displayName),
      subtitle: Text(subtitleParts.join(' · '), maxLines: 2, overflow: TextOverflow.ellipsis),
      onTap: () => _openEditor(source),
      trailing: busy
          ? const SizedBox(width: 44, height: 44, child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(strokeWidth: 2),
            ))
          : PopupMenuButton<_SourceAction>(
              tooltip: t.iptv.edit,
              onSelected: (action) => _handleAction(source, action),
              itemBuilder: (context) => [
                PopupMenuItem(value: _SourceAction.edit, child: Text(t.iptv.edit)),
                PopupMenuItem(value: _SourceAction.channels, child: Text(t.iptv.manageChannels)),
                PopupMenuItem(value: _SourceAction.refresh, child: Text(t.iptv.refresh)),
                PopupMenuItem(value: _SourceAction.remove, child: Text(t.iptv.remove)),
              ],
            ),
    );
  }
}
