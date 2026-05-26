import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../media/media_item.dart';
import '../../../mixins/library_tab_focus_mixin.dart';
import '../../../mixins/tracker_sync_aware.dart';
import '../../../providers/multi_server_provider.dart';
import '../../../services/plex_client.dart';
import '../../../services/settings_service.dart';
import '../../../services/trackers/watch_state_overlay.dart';
import '../../../utils/grid_size_calculator.dart';
import '../../../utils/layout_constants.dart';
import '../../../widgets/focusable_media_card.dart';
import '../../../widgets/media_grid_delegate.dart';
import '../../../widgets/settings_builder.dart';
import '../../../i18n/strings.g.dart';
import '../../main_screen.dart';
import 'base_library_tab.dart';

/// Variant of the Playlists tab shown when a tracker watch-state authority is
/// active. Renders the authority's primary curated list (e.g. Trakt watchlist,
/// MAL/AniList "Plan to Watch") instead of Plex playlists — the parent screen
/// swaps this widget in based on [SettingsService.trackerStateAuthority]. No
/// pagination, no skeletons; the overlay returns an eager list resolved
/// against the available Plex clients.
class LibraryTrackerPlaylistsTab extends BaseLibraryTab<MediaItem> {
  const LibraryTrackerPlaylistsTab({
    super.key,
    required super.library,
    super.viewMode,
    super.density,
    super.onDataLoaded,
    super.isActive,
    super.suppressAutoFocus,
    super.onBack,
  });

  @override
  State<LibraryTrackerPlaylistsTab> createState() => _LibraryTrackerPlaylistsTabState();
}

class _LibraryTrackerPlaylistsTabState extends BaseLibraryTabState<MediaItem, LibraryTrackerPlaylistsTab>
    with LibraryTabFocusMixin<LibraryTrackerPlaylistsTab>, TrackerSyncAware<LibraryTrackerPlaylistsTab> {
  @override
  String get focusNodeDebugLabel => 'tracker_playlists_first_item';

  @override
  int get itemCount => items.length;

  @override
  IconData get emptyIcon => Symbols.playlist_play_rounded;

  @override
  String get emptyMessage => t.playlists.noPlaylists;

  @override
  String get errorContext => t.playlists.title;

  @override
  Future<List<MediaItem>> loadData() => WatchStateOverlay.instance.getAuthorityListItems(_plexClients());

  @override
  void onTrackerSyncChanged() {
    unawaited(loadItems());
  }

  Map<String, PlexClient> _plexClients() {
    final manager = context.read<MultiServerProvider>().serverManager;
    return Map.fromEntries(
      manager.onlineClients.entries
          .where((e) => e.value is PlexClient)
          .map((e) => MapEntry(e.key, e.value as PlexClient)),
    );
  }

  @override
  Widget buildContent(List<MediaItem> items) {
    return SettingsBuilder(
      prefs: const [SettingsService.viewMode, SettingsService.libraryDensity],
      builder: (context) {
        final settings = SettingsService.instanceOrNull!;
        final viewMode = settings.read(SettingsService.viewMode);
        final density = settings.read(SettingsService.libraryDensity);
        return CustomScrollView(
          clipBehavior: Clip.none,
          slivers: [
            SliverOverlapInjector(handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context)),
            if (viewMode == ViewMode.list) _buildListSliver(items) else _buildGridSliver(items, density),
          ],
        );
      },
    );
  }

  static const double _focusDecorationPadding = 3.0;

  EdgeInsets get _effectivePadding {
    final base = GridLayoutConstants.gridPadding;
    return base.copyWith(top: base.top + _focusDecorationPadding);
  }

  Widget _buildListSliver(List<MediaItem> data) {
    return SliverPadding(
      padding: _effectivePadding,
      sliver: SliverList.builder(
        itemCount: data.length,
        itemBuilder: (context, index) => _buildItemCard(data, index, isFirstColumn: true, disableScale: true),
      ),
    );
  }

  Widget _buildGridSliver(List<MediaItem> data, int density) {
    return SliverPadding(
      padding: _effectivePadding,
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final maxCrossAxisExtent = GridSizeCalculator.getMaxCrossAxisExtent(context, density);
          final columnCount = GridSizeCalculator.getColumnCount(constraints.crossAxisExtent, maxCrossAxisExtent);
          return SliverGrid.builder(
            gridDelegate: MediaGridDelegate.createDelegate(context: context, density: density),
            itemCount: data.length,
            itemBuilder: (context, index) =>
                _buildItemCard(data, index, isFirstColumn: GridSizeCalculator.isFirstColumn(index, columnCount)),
          );
        },
      ),
    );
  }

  Widget _buildItemCard(List<MediaItem> data, int index, {required bool isFirstColumn, bool disableScale = false}) {
    final item = data[index];
    return FocusableMediaCard(
      key: Key(item.id),
      item: item,
      focusNode: index == 0 ? firstItemFocusNode : null,
      disableScale: disableScale,
      onListRefresh: loadItems,
      onBack: widget.onBack,
      onNavigateLeft: isFirstColumn ? _navigateToSidebar : null,
    );
  }

  void _navigateToSidebar() {
    MainScreenFocusScope.of(context, listen: false)?.focusSidebar();
  }
}
