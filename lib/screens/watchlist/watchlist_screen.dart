import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../database/app_database.dart';
import '../../media/media_backend.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../providers/watchlist_provider.dart';
import '../../services/settings_service.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/focusable_media_card.dart';
import '../../widgets/media_grid_delegate.dart';
import '../../widgets/settings_builder.dart';
import '../libraries/state_messages.dart';
import '../../i18n/strings.g.dart';

/// Screen that displays the user's watchlist items grouped by media kind.
///
/// Each non-empty group (movies, shows, seasons, episodes) renders as a
/// labelled section with a horizontal grid of [FocusableMediaCard] widgets.
/// The empty state shows an [EmptyStateWidget] with a contextual message.
/// A clear-all button in the action bar triggers a confirmation dialog,
/// after which all items are removed via [WatchlistProvider.clearAll].
class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  /// Converts a persisted [WatchlistItem] into a [MediaItem] so it can be fed
  /// to [FocusableMediaCard] (which delegates to [MediaCard] — both expect an
  /// `Object` that is either a [MediaItem] or [MediaPlaylist]).
  static MediaItem _toMediaItem(WatchlistItem item) {
    return MediaItem(
      id: item.ratingKey,
      backend: MediaBackend.plex,
      kind: MediaKind.fromString(item.kind),
      title: item.title,
      thumbPath: item.thumbPath,
      artPath: item.backdropPath,
      year: item.year,
      index: item.index,
      serverId: item.serverId,
      parentTitle: item.parentTitle,
    );
  }

  Future<void> _showClearAllDialog(BuildContext context) async {
    final t = Translations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.watchlist.clearAll),
        content: Text(t.watchlist.clearAllConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.common.clear),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<WatchlistProvider>().clearAll();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.watchlist.clearAllConfirm)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final provider = context.watch<WatchlistProvider>();

    final movies = provider.movies;
    final shows = provider.shows;
    final seasons = provider.seasons;
    final episodes = provider.episodes;

    final hasAnyItems =
        movies.isNotEmpty || shows.isNotEmpty || seasons.isNotEmpty || episodes.isNotEmpty;

    // Empty state — no items in any group.
    if (!hasAnyItems) {
      return Scaffold(
        body: EmptyStateWidget(
          message: t.watchlist.emptyTitle,
          subtitle: t.watchlist.emptySubtitle,
          icon: Symbols.bookmark_rounded,
          iconSize: 80,
        ),
      );
    }

    final groups = <_WatchlistGroup>[
      if (movies.isNotEmpty) _WatchlistGroup(label: t.watchlist.movies, items: movies),
      if (shows.isNotEmpty) _WatchlistGroup(label: t.watchlist.shows, items: shows),
      if (seasons.isNotEmpty) _WatchlistGroup(label: t.watchlist.seasons, items: seasons),
      if (episodes.isNotEmpty) _WatchlistGroup(label: t.watchlist.episodes, items: episodes),
    ];

    return Scaffold(
      body: SettingsBuilder(
        prefs: const [SettingsService.libraryDensity],
        builder: (context) {
          final density = SettingsService.instance.read(SettingsService.libraryDensity);

          return CustomScrollView(
            primary: false,
            slivers: [
              // Clear-all action bar at the top.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _showClearAllDialog(context),
                        icon: const Icon(Symbols.delete_forever_rounded, size: 18),
                        label: Text(t.watchlist.clearAll),
                      ),
                    ],
                  ),
                ),
              ),
              // One section per non-empty group.
              for (final group in groups)
                _WatchlistGroupSection(
                  label: group.label,
                  items: group.items,
                  density: density,
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Lightweight model for a labelled group of watchlist items.
class _WatchlistGroup {
  final String label;
  final List<WatchlistItem> items;
  const _WatchlistGroup({required this.label, required this.items});
}

/// Renders a single section: a header label followed by a horizontally
/// scrollable grid of [FocusableMediaCard] items.
class _WatchlistGroupSection extends StatelessWidget {
  final String label;
  final List<WatchlistItem> items;
  final int density;

  const _WatchlistGroupSection({
    required this.label,
    required this.items,
    required this.density,
  });

  @override
  Widget build(BuildContext context) {
    final fullCardLayout = PlatformDetector.isTV() &&
        SettingsService.instance.read(SettingsService.tvFullCardLayout);

    return SliverMainAxisGroup(slivers: [
      // Section header.
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
      // Grid of items.
      SliverLayoutBuilder(
        builder: (context, constraints) {
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            sliver: SliverGrid(
              gridDelegate: MediaGridDelegate.createDelegate(
                context: context,
                density: density,
                fullBleedImage: fullCardLayout,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = items[index];
                  return FocusableMediaCard(
                    item: _WatchlistScreenState._toMediaItem(item),
                    isOffline: true,
                    fullBleedImage: fullCardLayout,
                  );
                },
                childCount: items.length,
              ),
            ),
          );
        },
      ),
    ]);
  }
}
