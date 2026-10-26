import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../i18n/strings.g.dart';
import '../../sources/source_controller.dart';
import '../../sources/source_models.dart';
import '../../sources/source_playback.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/dialogs.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/app_menu.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import 'publication_reader_screen.dart';
import 'source_notes_screen.dart';
import 'source_player_screen.dart';
import 'source_widgets.dart';

class SourceDetailScreen extends StatefulWidget {
  const SourceDetailScreen({super.key, required this.entry});
  final SourceEntry entry;
  @override
  State<SourceDetailScreen> createState() => _SourceDetailScreenState();
}

class _SourceDetailScreenState extends State<SourceDetailScreen> {
  late SourceEntry _entry = widget.entry;
  bool _busy = false;
  Object? _error;
  List<PublicationProgress> _progress = [];
  final Map<String, PublicationProgress> _conflicts = {};
  final Set<String> _offline = {};
  final Map<String, double?> _transfers = {};
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final sources = context.read<SourceController>();
    setState(() => _busy = true);
    try {
      await sources.ready;
      sources.requireSession();
      final epoch = sources.generation, profile = sources.profileId!;
      if (!_entry.id.startsWith('group:') && sources.sources.any((s) => s.id == _entry.sourceId)) {
        try {
          _entry = await sources.hydrate(_entry);
        } catch (_) {
          /* Cached details are usable offline. */
        }
      }
      final seeds = [
        for (final f in _entry.ebooks)
          PublicationProgress(
            entryKey: _entry.key,
            edition: f.fingerprint,
            mode: PublicationMode.reading,
            session: const Uuid().v4(),
          ),
        if (_entry.audio.isNotEmpty)
          PublicationProgress(
            entryKey: _entry.key,
            edition: sourceDigest(jsonEncode(_entry.audio.map((f) => f.fingerprint).toList())),
            mode: PublicationMode.listening,
            session: const Uuid().v4(),
          ),
        if (_entry.kind == SourceItemKind.video && _entry.files.isNotEmpty)
          PublicationProgress(
            entryKey: _entry.key,
            edition: sourceDigest(jsonEncode(_entry.files.map((f) => f.fingerprint).toList())),
            mode: PublicationMode.watching,
            session: const Uuid().v4(),
          ),
      ];
      for (final seed in seeds) {
        await sources.openProgress(_entry, seed);
      }
      final progresses = (await sources.repository.allProgress(
        profile,
      )).where((p) => p.entryKey == _entry.key).toList();
      _conflicts.clear();
      for (final progress in progresses) {
        final conflict = await sources.repository.remoteConflict(profile, progress.key);
        if (conflict != null) _conflicts[progress.key] = conflict;
      }
      _offline.clear();
      for (final file in _entry.files) {
        if (await sources.downloads.local(profile, _entry.sourceId, file) != null) _offline.add(file.id);
      }
      sources.requireSession(epoch);
      if (mounted) setState(() => _progress = progresses);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _play(List<PublicationFile> files) async {
    final playback = context.read<SourcePlayback>();
    await playback.start(
      _entry,
      files,
      playbackMode: files.first.kind == SourceItemKind.video ? PublicationMode.watching : PublicationMode.listening,
    );
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: 'source-player'),
          builder: (_) => const SourcePlayerScreen(),
        ),
      );
    }
    if (mounted) await _load();
  }

  Future<void> _read(PublicationFile file) async {
    if (PlatformDetector.isTV()) throw const SourceException(SourceFailure.unsupported);
    await Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'publication-reader'),
        builder: (_) => PublicationReaderScreen(entry: _entry, file: file),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _download(PublicationFile file) async {
    if (_transfers.containsKey(file.id)) return;
    setState(() => _transfers[file.id] = null);
    try {
      await context.read<SourceController>().content(
        _entry,
        file,
        onProgress: (done, total) {
          if (mounted) setState(() => _transfers[file.id] = total == null ? null : done / total);
        },
      );
    } finally {
      if (mounted) {
        setState(() => _transfers.remove(file.id));
        await _load();
      }
    }
  }

  Future<void> _removeDownload(PublicationFile file) async {
    final sources = context.read<SourceController>(), profile = sourcesProfile(context);
    if (!await showConfirmDialog(
      context,
      title: t.fileSources.removeDownload,
      message: t.fileSources.confirmDelete,
      confirmText: t.fileSources.removeDownload,
      isDestructive: true,
    )) {
      return;
    }
    if (!mounted || sources.profileId != profile) return;
    await sources.downloads.remove(profile, _entry.sourceId, file);
    await _load();
  }

  Future<void> _changeProgress(PublicationProgress progress, String action) async {
    final sources = context.read<SourceController>(), profile = sourcesProfile(context);
    await context.read<SourcePlayback>().stop();
    final current = await sources.repository.progress(profile, progress.key);
    if (current == null) return;
    final value = action == 'reset'
        ? PublicationProgress(
            entryKey: current.entryKey,
            edition: current.edition,
            mode: current.mode,
            session: const Uuid().v4(),
            revision: current.revision,
          )
        : current.copyWith(finished: !current.finished);
    await sources.repository.saveProgress(profile, value, kind: action);
    await _load();
  }

  Future<void> _history(PublicationProgress progress) async {
    final sources = context.read<SourceController>(), profile = sourcesProfile(context);
    final history = await sources.repository.history(profile, progress.key);
    if (!mounted) return;
    final restore = await Navigator.push<PublicationProgress>(
      context,
      MaterialPageRoute(
        builder: (context) => FocusedScrollScaffold(
          title: Text(t.fileSources.history),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverList.builder(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final row = history[index],
                      p = PublicationProgress.fromJson(sourceMap(jsonDecode(history[index]['payload'] as String)));
                  return SourceTile(
                    title: p.mode == PublicationMode.reading
                        ? '${(p.fraction * 100).round()}%'
                        : sourceTime(p.positionMs),
                    subtitle: DateTime.fromMillisecondsSinceEpoch(row['created'] as int).toLocal().toString(),
                    icon: Symbols.history_rounded,
                    index: index,
                    count: history.length,
                    onTap: () => Navigator.pop(context, p),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (restore == null || !mounted || sources.profileId != profile) return;
    await context.read<SourcePlayback>().stop();
    final latest = await sources.repository.progress(profile, progress.key);
    await sources.repository.saveProgress(
      profile,
      restore.copyWith(revision: latest!.revision, session: const Uuid().v4()),
      kind: 'restore',
    );
    await _load();
  }

  Future<void> _reorder() async {
    final ordered = await Navigator.push<List<PublicationFile>>(
      context,
      MaterialPageRoute(builder: (_) => _AudioOrder(files: _entry.audio)),
    );
    if (ordered == null || !mounted) return;
    final sources = context.read<SourceController>();
    sources.requireSession();
    _entry = SourceEntry.fromJson({
      ..._entry.toJson(),
      'files': [...ordered, ..._entry.ebooks].map((f) => f.toJson()).toList(),
    });
    await sources.repository.cacheEntries(sources.profileId!, [_entry]);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), tk = tokens(context), audio = _entry.audio;
    return FocusedScrollScaffold(
      title: Text(_entry.displayTitle),
      focusableAppBarActions: true,
      actions: [
        IconButton(
          tooltip: t.fileSources.bookmarks,
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SourceNotesScreen(entry: _entry))),
          icon: const AppIcon(Symbols.bookmarks_rounded),
        ),
        if (_entry.id.startsWith('group:'))
          IconButton(
            tooltip: t.fileSources.order,
            onPressed: () => sourceAction(context, _reorder),
            icon: const AppIcon(Symbols.reorder_rounded),
          ),
      ],
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, size) {
                        final cover = SizedBox(width: 180, height: 270, child: SourceCover(entry: _entry));
                        final details = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_entry.displayTitle, style: theme.textTheme.headlineMedium),
                            if (_entry.author.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(_entry.author, style: theme.textTheme.titleLarge),
                              ),
                            if (_entry.narrator.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '${t.fileSources.narrator} · ${_entry.narrator}',
                                  style: theme.textTheme.bodyMedium?.copyWith(color: tk.textMuted),
                                ),
                              ),
                            if (_entry.series.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(_entry.series, style: theme.textTheme.bodyMedium),
                              ),
                            if (_entry.releaseYear != null || _entry.rating != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  [
                                    if (_entry.releaseYear != null) '${_entry.releaseYear}',
                                    if (_entry.rating != null) '★ ${_entry.rating!.toStringAsFixed(1)}/10',
                                  ].join(' · '),
                                  style: theme.textTheme.bodyMedium?.copyWith(color: tk.textMuted),
                                ),
                              ),
                            if (_entry.genres.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _entry.genres.join(' · '),
                                  style: theme.textTheme.bodyMedium?.copyWith(color: tk.textMuted),
                                ),
                              ),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                if (_entry.ebooks.isNotEmpty)
                                  FilledButton.icon(
                                    onPressed: PlatformDetector.isTV()
                                        ? null
                                        : () => sourceAction(context, () => _read(_entry.ebooks.first)),
                                    icon: const AppIcon(Symbols.menu_book_rounded),
                                    label: Text(t.fileSources.read),
                                  ),
                                if (audio.isNotEmpty)
                                  FilledButton.icon(
                                    onPressed: () => sourceAction(context, () => _play(audio)),
                                    icon: const AppIcon(Symbols.headphones_rounded),
                                    label: Text(t.fileSources.listen),
                                  ),
                                if (_entry.kind == SourceItemKind.video)
                                  FilledButton.icon(
                                    onPressed: () => sourceAction(context, () => _play(_entry.files)),
                                    icon: const AppIcon(Symbols.play_arrow_rounded, fill: 1),
                                    label: Text(t.fileSources.play),
                                  ),
                              ],
                            ),
                          ],
                        );
                        return size.maxWidth > 620
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  cover,
                                  const SizedBox(width: 32),
                                  Expanded(child: details),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(child: cover),
                                  const SizedBox(height: 24),
                                  details,
                                ],
                              );
                      },
                    ),
                    if (_busy)
                      const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: LinearProgressIndicator()),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(sourceFailureText(_error!)),
                      ),
                    if (_entry.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(_entry.description, style: theme.textTheme.bodyLarge),
                      ),
                    for (final progress in _progress) ...[
                      if (_conflicts.containsKey(progress.key))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.fileSources.conflict),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 12,
                                children: [
                                  for (final remote in [false, true])
                                    OutlinedButton(
                                      onPressed: () => sourceAction(context, () async {
                                        await context.read<SourceController>().resolveConflict(
                                          _entry,
                                          progress,
                                          useRemote: remote,
                                        );
                                        await _load();
                                      }),
                                      child: Text(
                                        '${remote ? t.fileSources.useRemote : t.fileSources.useLocal} · ${progress.mode == PublicationMode.reading ? '${(((remote ? _conflicts[progress.key]! : progress).fraction) * 100).round()}%' : sourceTime((remote ? _conflicts[progress.key]! : progress).positionMs)}',
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      SourceTile(
                        title: progress.mode == PublicationMode.reading
                            ? t.fileSources.read
                            : progress.mode == PublicationMode.listening
                            ? t.fileSources.listen
                            : t.fileSources.continueWatching,
                        subtitle: progress.finished
                            ? t.fileSources.finished
                            : progress.mode == PublicationMode.reading
                            ? '${(progress.fraction * 100).round()}%'
                            : sourceTime(progress.positionMs),
                        progress: progress.fraction,
                        icon: progress.mode == PublicationMode.reading
                            ? Symbols.menu_book_rounded
                            : progress.mode == PublicationMode.listening
                            ? Symbols.headphones_rounded
                            : Symbols.movie_rounded,
                        onTap: progress.mode == PublicationMode.watching
                            ? () => sourceAction(context, () => _play(_entry.files))
                            : null,
                        trailing: AppMenuButton<String>(
                          icon: const AppIcon(Symbols.more_vert_rounded),
                          tooltip: t.fileSources.timePosition,
                          adaptiveSheet: true,
                          entriesBuilder: (_) => [
                            AppMenuItem(
                              value: 'finished',
                              label: progress.finished ? t.fileSources.markUnfinished : t.fileSources.markFinished,
                            ),
                            AppMenuItem(value: 'reset', label: t.fileSources.startOver),
                            AppMenuItem(value: 'history', label: t.fileSources.history),
                          ],
                          onSelected: (action) => sourceAction(
                            context,
                            () => action == 'history' ? _history(progress) : _changeProgress(progress, action),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(t.fileSources.editions, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 16),
                    for (var i = 0; i < _entry.files.length; i++)
                      Builder(
                        builder: (context) {
                          final f = _entry.files[i];
                          return SourceTile(
                            title: f.name,
                            subtitle: _offline.contains(f.id) ? t.fileSources.offline : f.mimeType,
                            icon: sourceItemIcon(f.kind),
                            index: i,
                            count: _entry.files.length,
                            progress: _transfers.containsKey(f.id) ? _transfers[f.id] ?? 0 : null,
                            onTap: (f.kind == SourceItemKind.ebook || f.kind == SourceItemKind.comic)
                                ? () => sourceAction(context, () => _read(f))
                                : () => sourceAction(context, () => _play([f])),
                            trailing: _transfers.containsKey(f.id)
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : IconButton(
                                    tooltip: _offline.contains(f.id)
                                        ? t.fileSources.removeDownload
                                        : t.fileSources.download,
                                    onPressed: () => sourceAction(
                                      context,
                                      () => _offline.contains(f.id) ? _removeDownload(f) : _download(f),
                                    ),
                                    icon: AppIcon(
                                      _offline.contains(f.id)
                                          ? Symbols.download_done_rounded
                                          : Symbols.download_rounded,
                                    ),
                                  ),
                          );
                        },
                      ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AudioOrder extends StatefulWidget {
  const _AudioOrder({required this.files});
  final List<PublicationFile> files;
  @override
  State<_AudioOrder> createState() => _AudioOrderState();
}

class _AudioOrderState extends State<_AudioOrder> {
  late final List<PublicationFile> _files = [...widget.files];
  void move(int i, int direction) {
    final next = i + direction;
    if (next < 0 || next >= _files.length) return;
    setState(() {
      final f = _files.removeAt(i);
      _files.insert(next, f);
    });
  }

  @override
  Widget build(BuildContext context) => FocusedScrollScaffold(
    title: Text(t.fileSources.order),
    focusableAppBarActions: true,
    actions: [TextButton(onPressed: () => Navigator.pop(context, _files), child: Text(t.fileSources.save))],
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.all(24),
        sliver: SliverList.builder(
          itemCount: _files.length,
          itemBuilder: (context, i) => SourceTile(
            title: _files[i].name,
            index: i,
            count: _files.length,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: t.fileSources.moveUp,
                  onPressed: i > 0 ? () => move(i, -1) : null,
                  icon: const AppIcon(Symbols.arrow_upward_rounded),
                ),
                IconButton(
                  tooltip: t.fileSources.moveDown,
                  onPressed: i + 1 < _files.length ? () => move(i, 1) : null,
                  icon: const AppIcon(Symbols.arrow_downward_rounded),
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
