import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../focus/focusable_wrapper.dart';
import '../../i18n/strings.g.dart';
import '../../i18n/iptv_copy.dart';
import '../../iptv/iptv_models.dart';
import '../../iptv/iptv_source_repository.dart';
import '../../iptv/iptv_vod_progress_sync_service.dart';
import '../../sources/source_models.dart';
import '../../sources/source_playback.dart';
import '../../theme/mono_tokens.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/focused_scroll_scaffold.dart';
import '../../widgets/optimized_media_image.dart';
import '../sources/source_player_screen.dart';

/// Xtream and Dispatcharr VOD is a catalog view inside Live TV. Playback is
/// handed to the shared source player so audio, subtitles, and native player
/// capabilities stay consistent with the rest of PlezyNG.
class IptvVodScreen extends StatefulWidget {
  const IptvVodScreen({super.key, required this.profileId});
  final String profileId;

  @override
  State<IptvVodScreen> createState() => _IptvVodScreenState();
}

class _IptvVodScreenState extends State<IptvVodScreen> {
  final _search = TextEditingController();
  List<IptvSourceSummary> _sources = const [];
  List<IptvVodCategory> _categories = const [];
  List<IptvVodItem> _items = const [];
  Map<String, IptvVodProgress> _progressByItem = const {};
  String? _sourceId;
  String? _categoryId;
  IptvVodKind _kind = IptvVodKind.movie;
  bool _loading = true;
  String? _error;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSources());
  }

  @override
  void dispose() {
    _loadGeneration++;
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadSources() async {
    try {
      final repository = context.read<IptvSourceRepository>();
      await IptvVodProgressSyncService.instance.syncActiveProfile(
        context,
        profileId: widget.profileId,
        repository: repository,
      );
      if (!mounted) return;
      final sources = await repository.vodSources(widget.profileId);
      if (!mounted) return;
      setState(() {
        _sources = sources;
        _sourceId = sources.firstOrNull?.id;
        _progressByItem = const {};
      });
      if (sources.isEmpty) {
        setState(() => _loading = false);
        return;
      }
      await _loadCatalog();
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = t.iptv.vodUnavailable;
      });
    }
  }

  Future<void> _loadCatalog() async {
    final sourceId = _sourceId;
    if (sourceId == null) return;
    final generation = ++_loadGeneration;
    bool current() => mounted && generation == _loadGeneration;
    final repository = context.read<IptvSourceRepository>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cachedCategories = await repository.cachedVodCategories(widget.profileId, sourceId, _kind);
      if (!current()) return;
      setState(() => _categories = cachedCategories);
      try {
        final refreshed = await repository.fetchVodCategories(widget.profileId, sourceId, _kind);
        if (!current()) return;
        setState(() {
          _categories = refreshed;
          if (_categoryId != null && !refreshed.any((category) => category.id == _categoryId)) _categoryId = null;
        });
      } on Object {
        if (cachedCategories.isEmpty) rethrow;
      }

      final cachedItems = await repository.cachedVodItems(
        widget.profileId,
        sourceId,
        _kind,
        categoryId: _categoryId,
      );
      if (!current()) return;
      setState(() => _items = cachedItems);
      await _loadVodProgress(sourceId, _kind);
      if (!current()) return;
      try {
        final refreshedItems = await repository.fetchVodItems(
          widget.profileId,
          sourceId,
          _kind,
          categoryId: _categoryId,
        );
        if (!current()) return;
        setState(() => _items = refreshedItems);
      } on Object {
        if (cachedItems.isEmpty) rethrow;
      }
      if (current()) setState(() => _loading = false);
    } on Object {
      if (!current()) return;
      setState(() {
        _loading = false;
        _error = t.iptv.vodUnavailable;
      });
    }
  }

  List<IptvVodItem> get _visibleItems {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return _items;
    return _items.where((item) => item.title.toLowerCase().contains(query)).toList(growable: false);
  }

  Future<void> _loadVodProgress(String sourceId, IptvVodKind kind) async {
    try {
      final rows = await context.read<IptvSourceRepository>().vodProgresses(widget.profileId, sourceId, kind);
      if (!mounted || _sourceId != sourceId || _kind != kind) return;
      final latest = <String, IptvVodProgress>{};
      for (final row in rows) {
        if (row.finished || row.positionMs <= 0) continue;
        final previous = latest[row.itemId];
        if (previous == null || row.updatedAt > previous.updatedAt) latest[row.itemId] = row;
      }
      setState(() => _progressByItem = latest);
    } on Object {
      // Progress is a convenience layer; an unavailable cache must not hide the catalogue.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final visibleItems = _visibleItems;
    return FocusedScrollScaffold(
      title: Text(t.iptv.vodTitle),
      focusableAppBarActions: true,
      actions: [
        IconButton(
          tooltip: t.iptv.refresh,
          onPressed: _loading ? null : _loadCatalog,
          icon: const AppIcon(Symbols.refresh_rounded),
        ),
      ],
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_sources.length > 1)
                  DropdownButtonFormField<String>(
                    initialValue: _sourceId,
                    decoration: InputDecoration(labelText: t.iptv.vodSource),
                    items: [for (final source in _sources) DropdownMenuItem(value: source.id, child: Text(source.displayName))],
                    onChanged: _loading
                        ? null
                        : (value) {
                            setState(() {
                              _sourceId = value;
                              _categoryId = null;
                              _progressByItem = const {};
                            });
                            unawaited(_loadCatalog());
                          },
                  ),
                const SizedBox(height: 12),
                SegmentedButton<IptvVodKind>(
                  segments: [
                    ButtonSegment(value: IptvVodKind.movie, icon: const AppIcon(Symbols.movie_rounded), label: Text(t.iptv.movies)),
                    ButtonSegment(value: IptvVodKind.series, icon: const AppIcon(Symbols.live_tv_rounded), label: Text(t.iptv.series)),
                  ],
                  selected: {_kind},
                  onSelectionChanged: _loading
                      ? null
                      : (selection) {
                          setState(() {
                            _kind = selection.first;
                            _categoryId = null;
                            _categories = const [];
                            _items = const [];
                            _progressByItem = const {};
                          });
                          unawaited(_loadCatalog());
                        },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: t.iptv.searchVod,
                    prefixIcon: const AppIcon(Symbols.search_rounded),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: t.common.clear,
                            onPressed: () {
                              _search.clear();
                              setState(() {});
                            },
                            icon: const AppIcon(Symbols.close_rounded),
                          ),
                  ),
                ),
                if (_categories.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: _categoryId,
                    decoration: InputDecoration(labelText: t.iptv.category),
                    items: [
                      DropdownMenuItem(value: null, child: Text(t.iptv.allCategories)),
                      for (final category in _categories)
                        DropdownMenuItem(value: category.id, child: Text(category.name, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: _loading
                        ? null
                        : (value) {
                            setState(() => _categoryId = value);
                            unawaited(_loadCatalog());
                          },
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_loading)
          const SliverToBoxAdapter(child: LinearProgressIndicator(minHeight: 2))
        else if (_error != null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(_error!, textAlign: TextAlign.center))),
          )
        else if (visibleItems.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(Symbols.video_library_rounded, size: 44, color: colors.onSurfaceVariant),
                    const SizedBox(height: 12),
                    Text(_sources.isEmpty ? t.iptv.vodUnavailable : t.iptv.noVodItems, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final columns = (constraints.crossAxisExtent / 180).floor().clamp(2, 8).toInt();
                final width = (constraints.crossAxisExtent - (columns - 1) * 14) / columns;
                return SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 20,
                    mainAxisExtent: width * 1.5 + 62,
                  ),
                  itemCount: visibleItems.length,
                  itemBuilder: (context, index) => _VodPosterCard(
                    item: visibleItems[index],
                    progress: _progressByItem[visibleItems[index].id],
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => IptvVodDetailsScreen(profileId: widget.profileId, item: visibleItems[index]),
                        ),
                      );
                      if (mounted && _sourceId != null) await _loadVodProgress(_sourceId!, _kind);
                    },
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _VodPosterCard extends StatelessWidget {
  const _VodPosterCard({required this.item, required this.onTap, this.progress});
  final IptvVodItem item;
  final VoidCallback onTap;
  final IptvVodProgress? progress;

  @override
  Widget build(BuildContext context) {
    final radius = tokens(context).radiusMd;
    final theme = Theme.of(context);
    final details = [if (item.year != null) '${item.year}', if (item.kind == IptvVodKind.series) t.iptv.series].join(' · ');
    return FocusableWrapper(
      borderRadius: radius,
      semanticLabel: item.title,
      onSelect: onTap,
      child: Material(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          canRequestFocus: false,
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: OptimizedMediaImage.poster(
                  imagePath: item.posterUrl,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              if (progress != null && progress!.fraction > 0)
                LinearProgressIndicator(value: progress!.fraction, minHeight: 3),
              Padding(
                padding: const EdgeInsets.fromLTRB(9, 8, 9, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(details, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall?.copyWith(color: tokens(context).textMuted)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IptvVodDetailsScreen extends StatefulWidget {
  const IptvVodDetailsScreen({super.key, required this.profileId, required this.item});
  final String profileId;
  final IptvVodItem item;

  @override
  State<IptvVodDetailsScreen> createState() => _IptvVodDetailsScreenState();
}

class _IptvVodDetailsScreenState extends State<IptvVodDetailsScreen> {
  IptvVodSeriesDetails? _seriesDetails;
  int? _season;
  bool _loading = false;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    if (widget.item.kind == IptvVodKind.series) unawaited(_loadSeries());
  }

  Future<void> _loadSeries() async {
    setState(() => _loading = true);
    try {
      final details = await context.read<IptvSourceRepository>().fetchVodSeriesDetails(
        widget.profileId,
        widget.item.sourceId,
        widget.item,
      );
      if (!mounted) return;
      final seasons = details.episodes.map((episode) => episode.season).toSet().toList()..sort();
      setState(() {
        _seriesDetails = details;
        _season = seasons.firstOrNull;
        _loading = false;
      });
    } on Object {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _play(String id, String extension, String title, int? durationSeconds, {required bool series}) async {
    if (_playing) return;
    setState(() => _playing = true);
    try {
      final repository = context.read<IptvSourceRepository>();
      await IptvVodProgressSyncService.instance.syncActiveProfile(
        context,
        profileId: widget.profileId,
        repository: repository,
      );
      if (!mounted) return;
      final uri = await repository.vodPlaybackUri(
        widget.profileId,
        widget.item.sourceId,
        itemId: id,
        extension: extension,
        series: series,
      );
      final ext = extension.toLowerCase();
      final fileId = 'iptv-vod:${widget.item.sourceId}:$id';
      final fileName = '$title.$ext';
      final file = PublicationFile(
        id: fileId,
        name: fileName,
        mimeType: switch (ext) {
          'ts' => 'video/mp2t',
          'mkv' => 'video/x-matroska',
          _ => 'video/mp4',
        },
        durationMs: durationSeconds == null ? null : durationSeconds * 1000,
        streamOnly: true,
      );
      final entry = SourceEntry(
        sourceId: 'iptv-vod:${widget.item.sourceId}',
        id: '${widget.item.kind.name}:${widget.item.id}:$id',
        title: title,
        kind: SourceItemKind.video,
        releaseYear: widget.item.year,
        description: widget.item.plot ?? '',
        files: [file],
      );
      final episodeId = series ? id : '';
      final savedProgress = await repository.vodProgress(
        widget.profileId,
        widget.item.sourceId,
        kind: widget.item.kind,
        itemId: widget.item.id,
        episodeId: episodeId,
      );
      final durationMs = durationSeconds == null ? 0 : durationSeconds * 1000;
      final resumePositionMs = savedProgress == null || savedProgress.finished ? 0 : savedProgress.positionMs;
      await context.read<SourcePlayback>().start(
        entry,
        [file],
        playbackMode: PublicationMode.watching,
        localOverrides: {fileId: uri},
        persistProgress: false,
        initialPositionMs: resumePositionMs,
        onTransientProgress: (progress) => repository.saveVodProgress(
          widget.profileId,
          sourceId: widget.item.sourceId,
          kind: widget.item.kind,
          itemId: widget.item.id,
          episodeId: episodeId,
          positionMs: progress.positionMs,
          durationMs: durationMs,
          finished: progress.finished,
        ),
      );
      if (!mounted) return;
      await Navigator.push<void>(context, MaterialPageRoute(builder: (_) => const SourcePlayerScreen()));
      if (mounted) {
        await IptvVodProgressSyncService.instance.syncActiveProfile(
          context,
          profileId: widget.profileId,
          repository: repository,
        );
      }
      if (mounted) setState(() => _playing = false);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(t.iptv.vodPlaybackFailed)));
      setState(() => _playing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _seriesDetails?.series ?? widget.item;
    final theme = Theme.of(context);
    final episodes = _seriesDetails?.episodes.where((episode) => episode.season == _season).toList() ?? const [];
    return FocusedScrollScaffold(
      title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (item.backdropUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: OptimizedMediaImage.thumb(imagePath: item.backdropUrl, width: double.infinity, height: 220),
                  ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: OptimizedMediaImage.poster(imagePath: item.posterUrl, width: 132, height: 198),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: theme.textTheme.headlineSmall, maxLines: 3, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          Text([
                            if (item.year != null) '${item.year}',
                            if (item.rating != null) item.rating!.toStringAsFixed(1),
                            if (item.durationSeconds != null && item.durationSeconds! > 0) _formatDuration(item.durationSeconds!),
                          ].join(' · '), style: theme.textTheme.bodyMedium?.copyWith(color: tokens(context).textMuted)),
                          if (item.plot?.isNotEmpty == true) ...[
                            const SizedBox(height: 10),
                            Text(item.plot!, maxLines: 6, overflow: TextOverflow.ellipsis),
                          ],
                          if (widget.item.kind == IptvVodKind.movie) ...[
                            const SizedBox(height: 14),
                            FilledButton.icon(
                              onPressed: _playing ? null : () => _play(
                                widget.item.id,
                                widget.item.containerExtension,
                                widget.item.title,
                                widget.item.durationSeconds,
                                series: false,
                              ),
                              icon: _playing
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const AppIcon(Symbols.play_arrow_rounded),
                              label: Text(t.iptv.play),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (widget.item.kind == IptvVodKind.series) ...[
                  const SizedBox(height: 24),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (_seriesDetails == null)
                    Text(t.iptv.vodUnavailable)
                  else if (_seriesDetails!.episodes.isEmpty)
                    Text(t.iptv.noEpisodes)
                  else ...[
                    DropdownButtonFormField<int>(
                      initialValue: _season,
                      decoration: InputDecoration(labelText: t.iptv.season),
                      items: [
                        for (final season in _seriesDetails!.episodes.map((episode) => episode.season).toSet().toList()..sort())
                          DropdownMenuItem(value: season, child: Text(season == 0 ? t.iptv.specials : '${t.iptv.season} $season')),
                      ],
                      onChanged: (value) => setState(() => _season = value),
                    ),
                    const SizedBox(height: 12),
                    for (final episode in episodes)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 96,
                            height: 54,
                            child: OptimizedMediaImage.thumb(imagePath: episode.posterUrl, width: 96, height: 54),
                          ),
                        ),
                        title: Text('E${episode.episode.toString().padLeft(2, '0')} · ${episode.title}', maxLines: 2, overflow: TextOverflow.ellipsis),
                        subtitle: episode.durationSeconds == null ? null : Text(_formatDuration(episode.durationSeconds!)),
                        trailing: IconButton(
                          tooltip: t.iptv.play,
                          onPressed: _playing ? null : () => _play(
                            episode.id,
                            episode.containerExtension,
                            '${item.title} S${episode.season}E${episode.episode} ${episode.title}',
                            episode.durationSeconds,
                            series: true,
                          ),
                          icon: const AppIcon(Symbols.play_arrow_rounded),
                        ),
                        onTap: _playing ? null : () => _play(
                          episode.id,
                          episode.containerExtension,
                          '${item.title} S${episode.season}E${episode.episode} ${episode.title}',
                          episode.durationSeconds,
                          series: true,
                        ),
                      ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }
}
