import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../discovery/discovery_choice.dart';
import '../../i18n/strings.g.dart';
import '../../sources/publication_shelf.dart';
import '../../sources/source_controller.dart';
import '../../sources/source_models.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/layout_constants.dart';
import '../../widgets/app_icon.dart';
import '../sources/canonical_library_navigation.dart';
import '../../media/canonical_library.dart';
import '../../media/media_item.dart';
import '../sources/source_widgets.dart';
import '../sources/sources_screen.dart';

/// A compact Home continuation of the existing Files & books video shelf.
/// It reads the local source index only, so it never makes Home wait on a
/// provider inventory request or exposes signed URLs in discover state.
class RemoteCloudHomeRail extends StatefulWidget {
  const RemoteCloudHomeRail({
    super.key,
    this.tvMode = false,
    this.onNavigateUp,
    this.onNavigateDown,
    this.onEntriesChanged,
    this.representedIdentities = const {},
    this.representedItems = const [],
  });

  final bool tvMode;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onNavigateDown;
  final ValueChanged<bool>? onEntriesChanged;
  final Set<String> representedIdentities;
  final List<MediaItem> representedItems;

  @override
  RemoteCloudHomeRailState createState() => RemoteCloudHomeRailState();
}

class RemoteCloudHomeRailState extends State<RemoteCloudHomeRail> {
  SourceController? _sources;
  Timer? _refreshDebounce;
  List<SourceEntry> _entries = const [];
  Map<String, Set<String>> _canonicalAliases = const {};
  List<PublicationProgress> _progress = const [];
  String? _loadedProfileId;
  int _request = 0;
  final FocusNode _firstCardFocusNode = FocusNode(debugLabel: 'Cloud files first poster');

  bool get hasEntries => _visibleEntries().isNotEmpty;

  List<SourceEntry> _visibleEntries([List<SourceEntry>? entries]) {
    final rows = entries ?? _entries;
    final represented = widget.representedIdentities;
    if (represented.isEmpty) return rows;
    return [
      for (final entry in rows)
        if (!(_canonicalAliases[entry.key] ?? canonicalVideoIdentitiesForSourceEntry(entry)).any(represented.contains))
          entry,
    ];
  }

  void requestFirstCardFocus() {
    if (!hasEntries) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && hasEntries) _firstCardFocusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant RemoteCloudHomeRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIds = oldWidget.representedIdentities;
    final newIds = widget.representedIdentities;
    final oldCopies = oldWidget.representedItems.map((item) => item.globalKey).toSet();
    final newCopies = widget.representedItems.map((item) => item.globalKey).toSet();
    if (oldIds.length != newIds.length ||
        !oldIds.containsAll(newIds) ||
        oldCopies.length != newCopies.length ||
        !oldCopies.containsAll(newCopies)) {
      _scheduleRefresh(const Duration(milliseconds: 250));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onEntriesChanged?.call(hasEntries);
      });
    }
  }

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
      widget.onEntriesChanged?.call(false);
      if (mounted) {
        setState(() {
          _entries = const [];
          _progress = const [];
          _loadedProfileId = null;
        });
      }
      return;
    }
    if (sources.profileId != _loadedProfileId) {
      widget.onEntriesChanged?.call(false);
      if (mounted && (_entries.isNotEmpty || _progress.isNotEmpty)) {
        setState(() {
          _entries = const [];
          _progress = const [];
        });
      }
    }
    if (sources.blocked || sources.profileId == null) {
      widget.onEntriesChanged?.call(false);
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
      final representedItems = widget.representedItems.toList(growable: false);
      final recent = await sources.recentRemoteCloudVideos();
      if (!mounted || request != _request || !sources.current(epoch) || sources.blocked) return;
      final identity = CanonicalLibrary(sources.repository.database);
      // The existing Home cards participate in the same persistent identity
      // graph as Videos and library browsing, without crawling a server here.
      await identity.recordServerItems(profile, representedItems);
      final seen = <String>{};
      final entries = <SourceEntry>[];
      final aliases = <String, Set<String>>{};
      for (final entry in recent) {
        final card = await identity.cardForCopy(profile, CanonicalLibrary.entryKey(entry));
        if (seen.add(card?.id ?? entry.key)) {
          entries.add(entry);
          if (card != null) aliases[entry.key] = await identity.aliases(profile, card.id);
        }
      }
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
        _canonicalAliases = aliases;
        _progress = progress;
        _loadedProfileId = profile;
      });
      widget.onEntriesChanged?.call(_visibleEntries(entries).isNotEmpty);
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
    final profile = _loadedProfileId;
    if (profile == null || _sources?.profileId != profile || _sources?.blocked != false) return;
    unawaited(openCanonicalEntry(context, entry, profile: profile));
  }

  @override
  void dispose() {
    _request++;
    _refreshDebounce?.cancel();
    _sources?.removeListener(_onSourcesChanged);
    _firstCardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = _visibleEntries();
    if (entries.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tvMode = widget.tvMode;
    final tvScale = tvMode ? TvLayoutConstants.scaleOf(context) : 1.0;
    return Padding(
      padding: EdgeInsets.only(top: tvMode ? 4 : 24, bottom: tvMode ? 2 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: 24 * tvScale,
              end: 16 * tvScale,
              bottom: tvMode ? 6 * tvScale : 12,
            ),
            child: Row(
              children: [
                Icon(Symbols.cloud_rounded, size: tvMode ? 18 : 20, color: colors.primary),
                SizedBox(width: tvMode ? 6 : 8),
                Expanded(
                  child: Text(
                    t.streaming.cloudFiles,
                    style: tvMode ? theme.textTheme.titleSmall : theme.textTheme.titleLarge,
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
            height: tvMode ? 176 * tvScale : 292,
            child: ListView.separated(
              padding: EdgeInsetsDirectional.only(start: 24 * tvScale, end: 24 * tvScale),
              scrollDirection: Axis.horizontal,
              itemCount: entries.length,
              separatorBuilder: (_, _) => SizedBox(width: tvMode ? 12 * tvScale : 16),
              itemBuilder: (context, index) {
                final entry = entries[index];
                final watched = _progress
                    .where(
                      (item) => item.entryKey == entry.key && item.mode == PublicationMode.watching && !item.finished,
                    )
                    .firstOrNull;
                return SizedBox(
                  width: tvMode ? 108 * tvScale : 156,
                  child: SourcePosterCard(
                    entry: entry,
                    onTap: () => _openEntry(entry),
                    progress: watched?.fraction,
                    focusNode: index == 0 ? _firstCardFocusNode : null,
                    onNavigateUp: widget.onNavigateUp,
                    onNavigateDown: widget.onNavigateDown,
                  ),
                );
              },
            ),
          ),
          if (!tvMode) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 24, end: 24),
              child: Text(
                t.fileSources.title,
                style: theme.textTheme.labelMedium?.copyWith(color: tokens(context).textMuted),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
