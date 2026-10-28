import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../services/remote_streams/real_debrid_client.dart';
import '../../services/remote_streams/remote_stream_models.dart';
import '../../services/remote_streams/remote_streaming_provider.dart';
import '../../sources/source_controller.dart';
import '../../sources/source_models.dart';
import '../../sources/source_playback.dart';
import '../../utils/formatters.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focusable_list_tile.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../sources/source_player_screen.dart';

class RemoteCloudFilesScreen extends StatefulWidget {
  const RemoteCloudFilesScreen({
    super.key,
    required this.service,
    this.parentId,
    this.title,
    this.onManageConnections,
    this.expectedAccountId,
    this.expectedProfileId,
  });

  final RemoteStreamService service;
  final String? parentId;
  final String? title;
  final Future<void> Function()? onManageConnections;
  final String? expectedAccountId;
  final String? expectedProfileId;

  @override
  State<RemoteCloudFilesScreen> createState() => _RemoteCloudFilesScreenState();
}

class _RemoteCloudFilesScreenState extends State<RemoteCloudFilesScreen> {
  List<RemoteCloudItem> _items = const [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _failed = false;
  bool _moreFailed = false;
  bool _accountReloadQueued = false;
  String? _loadedAccountId;
  String? _loadedProfileId;
  String? _openingId;
  String? _nextCursor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool more = false}) async {
    if (!mounted) return;
    if (more && (_loading || _loadingMore || _nextCursor == null)) return;
    final provider = context.read<RemoteStreamingProvider>();
    final accountId = provider.accountFor(widget.service)?.id;
    final profileId = provider.profileId;
    final cursor = more ? _nextCursor : null;
    setState(() {
      _loading = !more;
      _loadingMore = more;
      _failed = false;
      _moreFailed = false;
      if (!more) {
        _items = const [];
        _nextCursor = null;
        _loadedAccountId = accountId;
        _loadedProfileId = profileId;
      }
    });
    try {
      if (accountId == null || profileId == null || !provider.isReady) {
        throw const SourceException(SourceFailure.authentication);
      }
      if ((widget.expectedAccountId != null && widget.expectedAccountId != accountId) ||
          (widget.expectedProfileId != null && widget.expectedProfileId != profileId)) {
        throw const SourceException(SourceFailure.cancelled);
      }
      final page = await provider.browseCloud(
        widget.service,
        parentId: widget.parentId,
        cursor: cursor,
      );
      if (!mounted) return;
      if (provider.profileId != profileId || provider.accountFor(widget.service)?.id != accountId) {
        setState(() => _loading = false);
        return;
      }
      final visible = page.items
          .where(
            (item) =>
                item.kind == RemoteCloudItemKind.folder ||
                classifySourceFile(item.name, _safeMimeType(item.mimeType, item.name)) == SourceItemKind.video,
          )
          .toList();
      visible.sort((a, b) {
        final kind = (a.kind == RemoteCloudItemKind.folder ? 0 : 1).compareTo(
          b.kind == RemoteCloudItemKind.folder ? 0 : 1,
        );
        return kind == 0 ? a.name.toLowerCase().compareTo(b.name.toLowerCase()) : kind;
      });
      setState(() {
        _loadedAccountId = accountId;
        _loadedProfileId = profileId;
        final knownIds = _items.map((item) => item.id).toSet();
        _items = List.unmodifiable([
          if (more) ..._items,
          ...visible.where((item) => knownIds.add(item.id)),
        ]);
        _nextCursor = page.nextCursor;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        if (more) {
          _moreFailed = true;
        } else {
          _failed = true;
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _manageConnections() async {
    await widget.onManageConnections?.call();
    if (mounted && (ModalRoute.of(context)?.isCurrent ?? true)) await _load();
  }

  Future<void> _open(RemoteCloudItem item) async {
    if (_openingId != null) return;
    final provider = context.read<RemoteStreamingProvider>();
    final activeAccountId = provider.accountFor(widget.service)?.id;
    if (!provider.isReady ||
        provider.profileId != _loadedProfileId ||
        item.accountId == null ||
        activeAccountId != item.accountId) {
      return;
    }
    if (item.kind == RemoteCloudItemKind.folder) {
      final parentId = item.providerId;
      if (parentId == null) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RemoteCloudFilesScreen(
            service: widget.service,
            parentId: parentId,
            title: item.name,
            onManageConnections: widget.onManageConnections,
            expectedAccountId: item.accountId,
            expectedProfileId: _loadedProfileId,
          ),
        ),
      );
      return;
    }
    final accountId = provider.accountFor(widget.service)?.id;
    final sourceController = context.read<SourceController>();
    final sourcePlayback = context.read<SourcePlayback>();
    final profileId = sourceController.profileId;
    if (!provider.isReady ||
        accountId == null ||
        accountId != item.accountId ||
        profileId == null ||
        profileId != _loadedProfileId) {
      return;
    }
    setState(() => _openingId = item.id);
    try {
      final resolved = await provider.resolveCloudFile(item);
      if (provider.profileId != profileId ||
          provider.accountFor(widget.service)?.id != accountId ||
          sourceController.profileId != profileId) {
        return;
      }
      final fileId = sourceDigest('${widget.service.name}\u0000${item.id}');
      final file = PublicationFile(
        id: fileId,
        name: resolved.fileName,
        mimeType: _safeMimeType(item.mimeType, resolved.fileName),
        size: resolved.size ?? item.size,
        streamOnly: true,
      );
      final entry = SourceEntry(
        sourceId: 'debrid:${widget.service.name}:${item.accountId}',
        id: item.id,
        title: item.name,
        kind: SourceItemKind.video,
        files: [file],
        onlineTitle: item.name,
      );
      await sourcePlayback.start(
        entry,
        [file],
        playbackMode: PublicationMode.watching,
        localOverrides: {file.id: resolved.uri},
        persistProgress: true,
      );
      if (!mounted) return;
      if (provider.profileId != profileId ||
          provider.accountFor(widget.service)?.id != accountId ||
          sourceController.profileId != profileId) {
        return;
      }
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: 'remote-cloud-player'),
          builder: (_) => const SourcePlayerScreen(),
        ),
      );
    } on RemoteProviderException catch (error) {
      if (mounted && error.reason != RemoteProviderFailure.cancelled) {
        showAppSnackBar(context, t.streaming.streamPrepareFailed);
      }
    } on RealDebridException catch (error) {
      if (mounted && error.reason != RealDebridFailure.cancelled) {
        showAppSnackBar(context, t.streaming.streamPrepareFailed);
      }
    } on SourceException catch (error) {
      if (mounted && error.reason != SourceFailure.cancelled) showAppSnackBar(context, t.streaming.streamUnsupported);
    } on Object {
      if (mounted) showAppSnackBar(context, t.streaming.streamPrepareFailed);
    } finally {
      if (mounted) setState(() => _openingId = null);
    }
  }

  String _serviceName(RemoteStreamService service) => switch (service) {
    RemoteStreamService.realDebrid => t.streaming.realDebrid,
    RemoteStreamService.allDebrid => t.streaming.allDebrid,
    RemoteStreamService.premiumize => t.streaming.premiumize,
    RemoteStreamService.torbox => t.streaming.torbox,
  };

  String _mimeType(String name) => switch (name.toLowerCase().split('.').last) {
    'mkv' => 'video/x-matroska',
    'm4v' => 'video/x-m4v',
    'mov' => 'video/quicktime',
    'webm' => 'video/webm',
    'avi' => 'video/x-msvideo',
    'ts' => 'video/mp2t',
    _ => 'video/mp4',
  };

  String _safeMimeType(String? value, String fileName) {
    final mime = value?.trim().toLowerCase();
    return mime != null &&
            mime.startsWith('video/') &&
            mime.length <= 128 &&
            RegExp(r'^[a-z0-9.+-]+/[a-z0-9.+-]+$').hasMatch(mime)
        ? mime
        : _mimeType(fileName);
  }

  @override
  Widget build(BuildContext context) {
    final streaming = context.watch<RemoteStreamingProvider>();
    final account = streaming.accountFor(widget.service);
    final accountId = account?.id;
    final profileId = streaming.profileId;
    final staleContext = streaming.isReady && (accountId != _loadedAccountId || profileId != _loadedProfileId);
    if (staleContext && !_loading && !_accountReloadQueued) {
      _accountReloadQueued = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _accountReloadQueued = false;
        if (mounted && !_loading) _load();
      });
    }
    final ready = streaming.isReady && accountId != null;
    return FocusedScrollScaffold(
      title: Text(widget.title ?? t.streaming.cloudFiles),
      focusableAppBarActions: true,
      actions: [
        IconButton(
          tooltip: t.fileSources.refresh,
          onPressed: _loading || !ready ? null : _load,
          icon: const AppIcon(Symbols.refresh_rounded),
        ),
      ],
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(
              account == null
                  ? _serviceName(widget.service)
                  : '${_serviceName(widget.service)} · ${t.streaming.accountConnected(username: account.displayName)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        if (_loading || streaming.loading || staleContext)
          const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))
        else if (_failed || !ready)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    liveRegion: true,
                    child: Text(t.streaming.cloudLoadFailed, textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: ready ? _load : null,
                    icon: const AppIcon(Symbols.refresh_rounded),
                    label: Text(t.common.retry),
                  ),
                  TextButton.icon(
                    onPressed: widget.onManageConnections == null ? null : _manageConnections,
                    icon: const AppIcon(Symbols.tune_rounded),
                    label: Text(t.streaming.manageConnections),
                  ),
                ],
              ),
            ),
          )
        else if (_items.isEmpty && _nextCursor == null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(
                      Symbols.video_library_rounded,
                      size: 40,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(t.streaming.cloudEmpty, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: widget.onManageConnections == null ? null : _manageConnections,
                      icon: const AppIcon(Symbols.tune_rounded),
                      label: Text(t.streaming.manageConnections),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index == _items.length) {
                if (_loadingMore) {
                  return Semantics(
                    liveRegion: true,
                    label: t.common.loading,
                    child: const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                if (_nextCursor == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: _loading || !ready || staleContext ? null : () => _load(more: true),
                      icon: AppIcon(_moreFailed ? Symbols.refresh_rounded : Symbols.expand_more_rounded),
                      label: Text(_moreFailed ? t.common.retry : t.fileSources.loadMore),
                    ),
                  ),
                );
              }
              final item = _items[index];
              final busy = _openingId == item.id;
              final isFolder = item.kind == RemoteCloudItemKind.folder;
              return Semantics(
                hint: busy
                    ? t.streaming.streamPrepare
                    : isFolder
                    ? t.streaming.browseCloud
                    : t.common.play,
                child: FocusableListTile(
                  leading: AppIcon(isFolder ? Symbols.folder_rounded : Symbols.play_circle_rounded, fill: 1),
                  title: Text(item.name),
                  subtitle: isFolder || item.size == null ? null : Text(ByteFormatter.formatBytes(item.size!)),
                  trailing: busy
                      ? Semantics(
                          label: t.streaming.streamPrepare,
                          liveRegion: true,
                          child: const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : AppIcon(isFolder ? Symbols.chevron_right_rounded : Symbols.play_arrow_rounded),
                  onTap: busy ? null : () => _open(item),
                ),
              );
            }, childCount: _items.length + (_nextCursor != null || _loadingMore ? 1 : 0)),
          ),
      ],
    );
  }
}
