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
    this.expectedAccountId,
    this.expectedProfileId,
  });

  final RemoteStreamService service;
  final String? parentId;
  final String? title;
  final String? expectedAccountId;
  final String? expectedProfileId;

  @override
  State<RemoteCloudFilesScreen> createState() => _RemoteCloudFilesScreenState();
}

class _RemoteCloudFilesScreenState extends State<RemoteCloudFilesScreen> {
  List<RemoteCloudItem> _items = const [];
  bool _loading = true;
  bool _failed = false;
  bool _accountReloadQueued = false;
  String? _loadedAccountId;
  String? _loadedProfileId;
  String? _openingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    final provider = context.read<RemoteStreamingProvider>();
    final accountId = provider.accountFor(widget.service)?.id;
    final profileId = provider.profileId;
    setState(() {
      _loading = true;
      _failed = false;
      _items = const [];
      _loadedAccountId = accountId;
      _loadedProfileId = profileId;
    });
    try {
      if (accountId == null || profileId == null || !provider.isReady) {
        throw const SourceException(SourceFailure.authentication);
      }
      if ((widget.expectedAccountId != null && widget.expectedAccountId != accountId) ||
          (widget.expectedProfileId != null && widget.expectedProfileId != profileId)) {
        throw const SourceException(SourceFailure.cancelled);
      }
      final items = await provider.browseCloud(
        widget.service,
        parentId: widget.parentId,
      );
      if (!mounted) return;
      if (provider.profileId != profileId || provider.accountFor(widget.service)?.id != accountId) {
        setState(() => _loading = false);
        return;
      }
      final visible = items
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
        _items = List.unmodifiable(visible);
        _loading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
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
            expectedAccountId: item.accountId,
            expectedProfileId: _loadedProfileId,
          ),
        ),
      );
      return;
    }
    final accountId = provider.accountFor(widget.service)?.id;
    final profileId = context.read<SourceController>().profileId;
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
          context.read<SourceController>().profileId != profileId) {
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
      await context.read<SourcePlayback>().start(
        entry,
        [file],
        playbackMode: PublicationMode.watching,
        localOverrides: {file.id: resolved.uri},
        persistProgress: true,
      );
      if (!mounted ||
          provider.profileId != profileId ||
          provider.accountFor(widget.service)?.id != accountId ||
          context.read<SourceController>().profileId != profileId) {
        return;
      }
      if (!mounted) return;
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
    final accountId = streaming.accountFor(widget.service)?.id;
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
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Text(_serviceName(widget.service), style: Theme.of(context).textTheme.bodySmall),
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
                  Text(t.streaming.cloudLoadFailed, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _load,
                    icon: const AppIcon(Symbols.refresh_rounded),
                    label: Text(t.common.retry),
                  ),
                ],
              ),
            ),
          )
        else if (_items.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text(t.streaming.cloudEmpty, textAlign: TextAlign.center)),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = _items[index];
              final busy = _openingId == item.id;
              final isFolder = item.kind == RemoteCloudItemKind.folder;
              return FocusableListTile(
                leading: AppIcon(isFolder ? Symbols.folder_rounded : Symbols.play_circle_rounded, fill: 1),
                title: Text(item.name),
                subtitle: isFolder || item.size == null ? null : Text(ByteFormatter.formatBytes(item.size!)),
                trailing: busy
                    ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2))
                    : AppIcon(isFolder ? Symbols.chevron_right_rounded : Symbols.play_arrow_rounded),
                onTap: busy ? null : () => _open(item),
              );
            }, childCount: _items.length),
          ),
      ],
    );
  }
}
