import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../i18n/strings.g.dart';
import '../../sources/publication_shelf.dart';
import '../../sources/source_controller.dart';
import '../../sources/source_models.dart';
import '../../theme/mono_tokens.dart';
import '../../widgets/app_icon.dart';
import '../sources/source_detail_screen.dart';
import '../sources/source_widgets.dart';
import '../sources/sources_screen.dart';

/// A compact Home continuation of the existing Files & books video shelf.
/// It reads the local source index only, so it never makes Home wait on a
/// provider inventory request or exposes signed URLs in discover state.
class RemoteCloudHomeRail extends StatefulWidget {
  const RemoteCloudHomeRail({super.key});

  @override
  State<RemoteCloudHomeRail> createState() => _RemoteCloudHomeRailState();
}

class _RemoteCloudHomeRailState extends State<RemoteCloudHomeRail> {
  SourceController? _sources;
  Timer? _refreshDebounce;
  List<SourceEntry> _entries = const [];
  List<PublicationProgress> _progress = const [];
  String? _loadedProfileId;
  int _request = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sources = context.read<SourceController?>();
    if (!identical(_sources, sources)) {
      _sources?.removeListener(_onSourcesChanged);
      _sources = sources;
      _sources?.addListener(_onSourcesChanged);
      _scheduleRefresh(const Duration(milliseconds: 1));
    }
  }

  void _onSourcesChanged() => _scheduleRefresh(const Duration(milliseconds: 250));

  void _scheduleRefresh(Duration delay) {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(delay, () => unawaited(_refresh()));
  }

  Future<void> _refresh() async {
    final sources = _sources;
    final request = ++_request;
    if (sources == null) {
      if (mounted) {
        setState(() {
          _entries = const [];
          _progress = const [];
          _loadedProfileId = null;
        });
      }
      return;
    }
    if (mounted && sources.profileId != _loadedProfileId && (_entries.isNotEmpty || _progress.isNotEmpty)) {
      setState(() {
        _entries = const [];
        _progress = const [];
      });
    }
    if (sources.blocked || sources.profileId == null) {
      if (mounted && (_entries.isNotEmpty || _progress.isNotEmpty)) {
        setState(() {
          _entries = const [];
          _progress = const [];
        });
      }
      _loadedProfileId = sources.profileId;
      return;
    }
    try {
      await sources.ready;
      if (!mounted || request != _request || sources.blocked || sources.profileId == null) return;
      final epoch = sources.generation;
      final profile = sources.profileId!;
      final entries = await sources.recentRemoteCloudVideos();
      final progress = await sources.repository.progressForEntries(profile, entries.map((entry) => entry.key));
      if (!mounted ||
          request != _request ||
          sources.blocked ||
          sources.profileId != profile ||
          !sources.current(epoch)) {
        return;
      }
      setState(() {
        _entries = entries;
        _progress = progress;
        _loadedProfileId = profile;
      });
    } on Object {
      // The primary Home shelves remain usable while a source index is
      // reconnecting or being replaced with another profile.
    }
  }

  void _openAll() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'cloud-video-library'),
        builder: (_) => const SourcesScreen(shelf: PublicationShelf.videos),
      ),
    );
  }

  void _openEntry(SourceEntry entry) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'cloud-video-detail'),
        builder: (_) => SourceDetailScreen(entry: entry),
      ),
    );
  }

  @override
  void dispose() {
    _request++;
    _refreshDebounce?.cancel();
    _sources?.removeListener(_onSourcesChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_entries.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 24, end: 16, bottom: 12),
            child: Row(
              children: [
                Icon(Symbols.cloud_rounded, size: 20, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t.streaming.cloudFiles,
                    style: theme.textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: _openAll,
                  icon: const AppIcon(Symbols.arrow_forward_rounded, size: 18),
                  label: Text(t.common.viewAll),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 292,
            child: ListView.separated(
              padding: const EdgeInsetsDirectional.only(start: 24, end: 24),
              scrollDirection: Axis.horizontal,
              itemCount: _entries.length,
              separatorBuilder: (_, _) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final entry = _entries[index];
                final watched = _progress
                    .where((item) => item.entryKey == entry.key && item.mode == PublicationMode.watching && !item.finished)
                    .firstOrNull;
                return SizedBox(
                  width: 156,
                  child: SourcePosterCard(
                    entry: entry,
                    onTap: () => _openEntry(entry),
                    progress: watched?.fraction,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 24, end: 24),
            child: Text(
              t.fileSources.title,
              style: theme.textTheme.labelMedium?.copyWith(color: tokens(context).textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
