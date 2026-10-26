import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../sources/source_controller.dart';
import '../../sources/source_models.dart';
import '../../sources/publication_library.dart';
import '../../utils/dialogs.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/provider_mark.dart';
import '../../widgets/music/mini_player.dart';
import '../../widgets/app_menu.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import 'add_source_screen.dart';
import 'source_detail_screen.dart';
import 'source_widgets.dart';
import '../../sources/publication_shelf.dart';
import 'source_navigation.dart';
import 'source_sync_screen.dart';
import '../lending/public_libraries_screen.dart';

String sourceTransportLabel(FileSource source) {
  final type = sourceKindName(source.kind);
  final scheme = Uri.tryParse(source.endpoint)?.scheme.toLowerCase();
  final endpointSecurity = switch (scheme) {
    'https' => 'HTTPS',
    'http' => 'HTTP without transport encryption',
    _ => 'Check endpoint security',
  };
  return switch (source.kind) {
    FileSourceKind.nfs =>
      '$type · ${source.options['rpcTls'] == 'required' ? 'RPC-with-TLS required' : 'Unencrypted NFS'}',
    FileSourceKind.ftp =>
      '$type · ${scheme == 'ftpes' || scheme == 'ftps' ? 'TLS encrypted' : 'Plain FTP'}',
    FileSourceKind.sftp => '$type · SSH encrypted · host key pinned',
    FileSourceKind.smb =>
      '$type · ${source.options['encryptSmb'] == 'true' ? 'SMB3 encryption requested' : 'SMB3 encryption not requested'}',
    FileSourceKind.webdav || FileSourceKind.opds || FileSourceKind.dlna ||
    FileSourceKind.s3 || FileSourceKind.audiobookshelf || FileSourceKind.komga => '$type · $endpointSecurity',
    FileSourceKind.local => '$type · On this device',
    FileSourceKind.googleDrive || FileSourceKind.oneDrive || FileSourceKind.dropbox =>
      '$type · Provider sign-in',
  };
}

class SourcesScreen extends StatefulWidget {
  const SourcesScreen({
    super.key,
    this.source,
    this.folder,
    this.offlineOnly = false,
    this.shelf,
    this.title,
    this.embedded = false,
  });
  final FileSource? source;
  final SourceEntry? folder;
  final bool offlineOnly;
  final PublicationShelf? shelf;
  final Widget? title;
  final bool embedded;
  @override
  State<SourcesScreen> createState() => _SourcesScreenState();
}

class _SourcesScreenState extends State<SourcesScreen> {
  List<SourceEntry> _entries = [];
  List<PublicationProgress> _progress = [];
  final Set<String> _offline = {};
  bool _loading = true;
  Object? _error;
  String? _next;
  String _query = '';
  SourceItemKind? _filter;
  int _request = 0;
  PublicationSort _sort = PublicationSort.title;
  PublicationStatus _status = PublicationStatus.all;
  String? _preferenceProfile;
  String get _browsePreference => 'publication-browse:${widget.source?.id ?? widget.shelf?.name ?? 'all'}';
  Future<void> _saveBrowsePreference() async {
    final sources = context.read<SourceController>();
    await sourceAction(context, () async {
      sources.requireSession();
      await sources.repository.savePreference(sources.profileId!, _browsePreference, {
        'sort': _sort.name,
        'status': _status.name,
      });
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool more = false}) async {
    final controller = context.read<SourceController>(), request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await controller.ready;
      controller.requireSession();
      final epoch = controller.generation, profile = controller.profileId!;
      if (_preferenceProfile != profile) {
        final prefs = await controller.repository.preference(profile, _browsePreference);
        controller.requireSession(epoch);
        _sort = PublicationSort.values.where((v) => v.name == prefs['sort']).firstOrNull ?? PublicationSort.title;
        _status = PublicationStatus.values.where((v) => v.name == prefs['status']).firstOrNull ?? PublicationStatus.all;
        _preferenceProfile = profile;
      }
      List<SourceEntry> items;
      if (widget.source == null || widget.offlineOnly) {
        items = await controller.repository.entries(profile);
        _next = null;
      } else {
        try {
          final page = await controller.browse(
            widget.source!.id,
            parent: widget.folder?.id,
            cursor: more ? _next : null,
          );
          items = more ? [..._entries, ...page.entries] : page.entries;
          _next = page.next;
        } catch (e) {
          if (more) rethrow;
          final cached = await controller.repository.entries(profile);
          items = cached
              .where((e) => e.sourceId == widget.source!.id && e.parentId == (widget.folder?.id ?? ''))
              .toList();
          _error = e;
        }
      }
      final progress = await controller.repository.allProgress(profile);
      final downloads = await controller.repository.downloads(profile);
      controller.requireSession(epoch);
      if (!mounted || request != _request) return;
      _offline
        ..clear()
        ..addAll(downloads.where((d) => d['complete'] == 1).map((d) => d['key'] as String));
      setState(() {
        _entries = {for (final e in items) e.key: e}.values.toList();
        _progress = progress;
      });
    } catch (e) {
      if (mounted && request == _request) setState(() => _error = e);
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  Future<void> _open(SourceEntry entry) async {
    if (entry.isFolder) {
      final source = context.read<SourceController>().sources.where((s) => s.id == entry.sourceId).firstOrNull;
      if (source == null) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SourcesScreen(source: source, folder: entry),
        ),
      );
    } else {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => SourceDetailScreen(entry: entry)));
    }
    if (mounted) await _load();
  }

  Future<void> _import() async {
    final files = await FilePicker.pickFiles(allowMultiple: true, withReadStream: true);
    if (files == null || !mounted) return;
    await sourceAction(context, () async {
      await context.read<SourceController>().importFiles(files.files, name: t.fileSources.localFiles);
    });
    if (mounted) await _load();
  }

  Future<void> _sourceAction(String action, FileSource source) async {
    final controller = context.read<SourceController>();
    if (action == 'scan') {
      await sourceAction(context, () => controller.scan(source.id));
    } else if (action == 'cancel-scan') {
      controller.cancelScan(source.id);
    } else if (action == 'remove') {
      final removesSyncSource = controller.syncConfig?.sourceId == source.id;
      if (!await showConfirmDialog(
        context,
        title: t.fileSources.removeSource,
        message: removesSyncSource
            ? '${t.fileSources.disconnectMessage}\n${t.audiobook.syncSourceDisconnect}'
            : t.fileSources.disconnectMessage,
        confirmText: t.fileSources.removeSource,
      )) {
        return;
      }
      if (!mounted) return;
      await sourceAction(context, () => controller.remove(source));
    } else {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => AddSourceScreen(existing: source)));
    }
    if (mounted) await _load();
  }

  bool downloaded(SourceEntry e) => e.files.any((f) => _offline.contains(sourceKey(e.sourceId, f.id)));
  Widget itemTile(SourceEntry e, int index, int count, {PublicationProgress? progress}) => SourceTile(
    key: ValueKey('${e.key}:${progress?.mode.name ?? ''}'),
    title: e.displayTitle,
    subtitle: [e.author, e.series, if (downloaded(e)) t.fileSources.offline].where((s) => s.isNotEmpty).join(' · '),
    icon: sourceItemIcon(e.kind),
    onTap: () => _open(e),
    index: index,
    count: count,
    progress: progress?.fraction,
  );
  @override
  Widget build(BuildContext context) {
    final sources = context.watch<SourceController>();
    final root = widget.source == null && !widget.offlineOnly && widget.shelf == null;
    final filtered = _entries
        .where(
          (e) =>
              (widget.shelf == null || widget.shelf!.includes(e)) &&
              (!widget.offlineOnly || downloaded(e)) &&
              (_filter == null || e.kind == _filter) &&
              ('${e.title} ${e.author} ${e.narrator} ${e.series}').toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    final entries = organizePublications(
      filtered,
      _progress,
      sort: _sort,
      status: _status,
      mode: widget.shelf == PublicationShelf.audiobooks
          ? PublicationMode.listening
          : widget.shelf != null
          ? PublicationMode.reading
          : null,
    );
    final continuations =
        _progress.where((p) => !p.finished && p.fraction < 1 && _entries.any((e) => e.key == p.entryKey)).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return FocusedScrollScaffold(
      automaticallyImplyLeading: !widget.embedded,
      title:
          widget.title ??
          Text(
            widget.offlineOnly
                ? t.fileSources.downloads
                : widget.folder?.title ??
                      widget.source?.name ??
                      (widget.shelf == null ? t.fileSources.title : shelfLabel(widget.shelf!)),
          ),
      focusableAppBarActions: true,
      actions: [
        AppMenuButton<String>(
          tooltip: t.common.options,
          icon: const AppIcon(Symbols.more_vert_rounded),
          adaptiveSheet: true,
          entriesBuilder: (_) => [
            AppMenuHeader(label: t.audiobook.librarySort),
            for (final value in PublicationSort.values)
              AppMenuItem(
                value: 'sort:${value.name}',
                selected: _sort == value,
                label: switch (value) {
                  PublicationSort.title => t.audiobook.sortTitle,
                  PublicationSort.author => t.audiobook.sortAuthor,
                  PublicationSort.narrator => t.audiobook.sortNarrator,
                  PublicationSort.series => t.audiobook.sortSeries,
                  PublicationSort.recent => t.audiobook.sortRecent,
                },
              ),
            AppMenuHeader(label: t.audiobook.statusFilter),
            for (final value in PublicationStatus.values)
              AppMenuItem(
                value: 'status:${value.name}',
                selected: _status == value,
                label: switch (value) {
                  PublicationStatus.all => t.audiobook.statusAll,
                  PublicationStatus.unstarted => t.audiobook.statusNew,
                  PublicationStatus.inProgress => t.audiobook.statusProgress,
                  PublicationStatus.finished => t.audiobook.statusFinished,
                },
              ),
            if (widget.source == null) ...[
              const AppMenuDivider(),
              AppMenuItem(
                value: 'reading-listening-sync',
                label: t.audiobook.syncTitle,
                icon: Symbols.cloud_sync_rounded,
              ),
            ],
            const AppMenuDivider(),
            AppMenuItem(
              value: 'refresh',
              label: t.fileSources.refresh,
              icon: Symbols.refresh_rounded,
              enabled: !_loading,
            ),
          ],
          onSelected: (action) async {
            if (action.startsWith('sort:')) {
              final value = PublicationSort.values.firstWhere((value) => value.name == action.substring(5));
              setState(() => _sort = value);
              unawaited(_saveBrowsePreference());
            } else if (action.startsWith('status:')) {
              final value = PublicationStatus.values.firstWhere((value) => value.name == action.substring(7));
              setState(() => _status = value);
              unawaited(_saveBrowsePreference());
            } else if (action == 'reading-listening-sync') {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const SourceSyncScreen()));
              if (mounted) await _load();
            } else if (action == 'refresh') {
              await _load();
            }
          },
        ),
        if (root)
          IconButton(
            tooltip: t.fileSources.importFiles,
            onPressed: _loading ? null : () => sourceAction(context, _import),
            icon: const AppIcon(Symbols.file_open_rounded),
          ),
        if (root)
          IconButton(
            tooltip: t.fileSources.add,
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSourceScreen()));
              if (mounted) await _load();
            },
            icon: const AppIcon(Symbols.add_rounded),
          ),
        if (widget.folder != null && _entries.any((e) => e.audio.isNotEmpty))
          IconButton(
            tooltip: t.fileSources.groupAudio,
            onPressed: _next != null || _loading
                ? null
                : () => sourceAction(context, () async {
                    final book = await sources.groupAudio(widget.folder!, _entries, title: widget.folder!.title);
                    if (mounted) await _open(book);
                  }),
            icon: const AppIcon(Symbols.library_music_rounded),
          ),
        if (root)
          IconButton(
            tooltip: t.fileSources.sync,
            onPressed: () => sourceAction(context, () async {
              await sources.sync();
              if (context.mounted) showSnackBar(context, t.fileSources.synced);
              await _load();
            }),
            icon: const AppIcon(Symbols.sync_rounded),
          ),
      ],
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (root) ...[
                  Text(t.fileSources.subtitle, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 24),
                  SourceTile(
                    title: t.lending.title,
                    icon: Symbols.local_library_rounded,
                    onTap: () =>
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PublicLibrariesScreen())),
                  ),
                  const SizedBox(height: 16),
                  for (var i = 0; i < sources.sources.length; i++)
                    SourceTile(
                      title: sources.sources[i].name,
                      subtitle: sourceTransportLabel(sources.sources[i]),
                      icon: Symbols.cloud_queue_rounded,
                      leading: FileSourceMark(sources.sources[i].kind),
                      index: i,
                      count: sources.sources.length,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SourcesScreen(source: sources.sources[i])),
                        );
                        if (mounted) await _load();
                      },
                      trailing: AppMenuButton<String>(
                        icon: const AppIcon(Symbols.more_vert_rounded),
                        tooltip: t.fileSources.preferences,
                        adaptiveSheet: true,
                        entriesBuilder: (_) => [
                          AppMenuItem(
                            value: sources.scanning.containsKey(sources.sources[i].id) ? 'cancel-scan' : 'scan',
                            label: sources.scanning.containsKey(sources.sources[i].id)
                                ? t.fileSources.cancelScan
                                : t.fileSources.scan,
                          ),
                          AppMenuItem(value: 'reconnect', label: t.fileSources.reconnect),
                          AppMenuItem(value: 'remove', label: t.fileSources.removeSource, destructive: true),
                        ],
                        onSelected: (value) => _sourceAction(value, sources.sources[i]),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SourcesScreen(offlineOnly: true)),
                      );
                      if (mounted) await _load();
                    },
                    icon: const AppIcon(Symbols.download_done_rounded),
                    label: Text(t.fileSources.downloads),
                  ),
                  if (_query.isEmpty)
                    for (final mode in PublicationMode.values) ...[
                      if (continuations.any((p) => p.mode == mode))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(switch (mode) {
                            PublicationMode.reading => t.fileSources.continueReading,
                            PublicationMode.listening => t.fileSources.continueListening,
                            PublicationMode.watching => t.fileSources.continueWatching,
                          }, style: Theme.of(context).textTheme.titleLarge),
                        ),
                      for (final progress in continuations.where((p) => p.mode == mode).take(6))
                        itemTile(_entries.firstWhere((e) => e.key == progress.entryKey), 0, 1, progress: progress),
                    ],
                  const SizedBox(height: 16),
                ],
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const AppIcon(Symbols.search_rounded),
                    labelText: root ? t.fileSources.searchCached : t.fileSources.search,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final pair in <SourceItemKind?, String>{
                      null: t.fileSources.all,
                      SourceItemKind.ebook: t.fileSources.ebooks,
                      SourceItemKind.audiobook: t.fileSources.audiobooks,
                      SourceItemKind.music: t.fileSources.audio,
                      SourceItemKind.video: t.fileSources.video,
                    }.entries)
                      FilterChip(
                        label: Text(pair.value),
                        selected: _filter == pair.key,
                        onSelected: (_) => setState(() => _filter = pair.key),
                      ),
                  ],
                ),
                if (_error != null)
                  Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(sourceFailureText(_error!))),
                if (_loading)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: LinearProgressIndicator()),
                if (entries.isEmpty && !_loading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(root ? t.fileSources.emptyHint : t.fileSources.empty),
                  ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: widget.shelf != null
              ? SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final scaler = MediaQuery.textScalerOf(context);
                    final columns = (constraints.crossAxisExtent / (160 * (scaler.scale(14) / 14).clamp(1, 2)))
                        .floor()
                        .clamp(1, 8);
                    final width = (constraints.crossAxisExtent - (columns - 1) * 20) / columns;
                    return SliverGrid.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 24,
                        crossAxisSpacing: 20,
                        mainAxisExtent: width * 1.5 + scaler.scale(14) * 2.8 + scaler.scale(12) * 1.5 + 10,
                      ),
                      itemCount: entries.length,
                      itemBuilder: (context, i) => SourcePosterCard(
                        entry: entries[i],
                        onTap: () => _open(entries[i]),
                        progress: _progress
                            .where((p) => p.entryKey == entries[i].key && !p.finished)
                            .firstOrNull
                            ?.fraction,
                      ),
                    );
                  },
                )
              : SliverList.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, i) => itemTile(entries[i], i, entries.length),
                ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              32 + (context.watch<MiniPlayerInsetController?>()?.overlayHeight ?? 88),
            ),
            child: Column(
              children: [
                if (_next != null)
                  OutlinedButton(
                    onPressed: _loading ? null : () => _load(more: true),
                    child: Text(t.fileSources.loadMore),
                  ),
                if (widget.folder != null && _next != null) Text(t.fileSources.groupHint),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
