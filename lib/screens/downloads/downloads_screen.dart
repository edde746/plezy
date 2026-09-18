import 'dart:io';

import 'package:flutter/material.dart';
import '../../media/ids.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../focus/focusable_action_bar.dart';
import '../../media/media_item.dart';
import '../../providers/download_provider.dart';
import '../../providers/multi_server_provider.dart';
import '../../services/music/music_playback_service.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/music_navigation.dart';
import '../../models/download_models.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/background_download_warning_banner.dart';
import '../../widgets/focusable_tab_chip.dart';
import '../../widgets/music/mini_player.dart';
import '../../widgets/music/track_row.dart';
import '../../services/settings_service.dart';
import '../../widgets/settings_builder.dart';
import '../../utils/global_key_utils.dart';
import '../../mixins/tab_navigation_mixin.dart';
import '../../mixins/refreshable.dart';
import '../../utils/media_image_helper.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/desktop_app_bar.dart';
import '../../widgets/focusable_media_card.dart';
import '../../widgets/media_card_sliver_layout.dart';
import '../../widgets/download_tree_view.dart';
import '../libraries/library_browse_grouping.dart';
import '../main_screen.dart';
import '../libraries/state_messages.dart';
import 'downloads_options.dart';
import '../../i18n/strings.g.dart';
import 'sync_rules_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => DownloadsScreenState();
}

class DownloadsScreenState extends State<DownloadsScreen>
    with TickerProviderStateMixin, TabNavigationMixin, FocusableTab {
  final _queueTabChipFocusNode = FocusNode(debugLabel: 'tab_chip_queue');
  final _tvShowsTabChipFocusNode = FocusNode(debugLabel: 'tab_chip_tv_shows');
  final _moviesTabChipFocusNode = FocusNode(debugLabel: 'tab_chip_movies');
  final _musicTabChipFocusNode = FocusNode(debugLabel: 'tab_chip_music');
  final _actionBarKey = GlobalKey<FocusableActionBarState>();
  final _tvShowsTabKey = GlobalKey<_DownloadsGridContentState>();
  final _moviesTabKey = GlobalKey<_DownloadsGridContentState>();
  final _musicTabKey = GlobalKey<_DownloadedMusicContentState>();

  @override
  List<FocusNode> get tabChipFocusNodes => [
    _queueTabChipFocusNode,
    _tvShowsTabChipFocusNode,
    _moviesTabChipFocusNode,
    _musicTabChipFocusNode,
  ];

  @override
  void initState() {
    super.initState();
    initTabNavigation();
  }

  @override
  void dispose() {
    _queueTabChipFocusNode.dispose();
    _tvShowsTabChipFocusNode.dispose();
    _moviesTabChipFocusNode.dispose();
    _musicTabChipFocusNode.dispose();
    disposeTabNavigation();
    super.dispose();
  }

  @override
  void onTabChanged() {
    if (!tabController.indexIsChanging) {
      super.onTabChanged();
    }
  }

  @override
  void focusActiveTabIfReady() {
    suppressAutoFocus = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      getTabChipFocusNode(tabController.index).requestFocus();
    });
  }

  /// The options-capable tab currently in view, or null on the Manage tab.
  DownloadsOptionsTab? _activeOptionsTab() {
    return switch (tabController.index) {
      1 => _tvShowsTabKey.currentState,
      2 => _moviesTabKey.currentState,
      3 => _musicTabKey.currentState,
      _ => null,
    };
  }

  /// Focus the top of the currently active tab — its chips bar on
  /// desktop/TV, its first content item on mobile.
  void _focusCurrentTab() {
    setState(() {
      suppressAutoFocus = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _activeOptionsTab()?.focusTopContent();
    });
  }

  Widget _buildTabChip(String label, int index) {
    return buildTabChip(
      label,
      index,
      onSelectWhenActive: _focusCurrentTab,
      onNavigateDown: _focusCurrentTab,
      onNavigateToActions: () => _actionBarKey.currentState?.requestFocusOnFirst(),
    );
  }

  /// Build the app bar title - either tabs on desktop or simple title on mobile
  Widget _buildAppBarTitle() {
    if (PlatformDetector.shouldUseSideNavigation(context)) {
      return TabChipStrip(
        children: [
          _buildTabChip(t.downloads.manage, 0),
          const SizedBox(width: 8),
          _buildTabChip(t.downloads.tvShows, 1),
          const SizedBox(width: 8),
          _buildTabChip(t.downloads.movies, 2),
          const SizedBox(width: 8),
          _buildTabChip(t.downloads.music, 3),
        ],
      );
    }

    return Text(t.downloads.title);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: [
          DesktopSliverAppBar(
            title: _buildAppBarTitle(),
            floating: true,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            scrolledUnderElevation: 0,
            actions: [
              FocusableActionBar(
                key: _actionBarKey,
                onNavigateLeft: () => getTabChipFocusNode(tabCount - 1).requestFocus(),
                onNavigateDown: _focusCurrentTab,
                actions: [
                  FocusableAction(
                    icon: Symbols.rule_settings_rounded,
                    tooltip: t.downloads.activeSyncRules,
                    debugLabel: 'downloads_sync_rules',
                    onPressed: () =>
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SyncRulesScreen())),
                  ),
                  // Mobile mirrors the library browse options action; desktop
                  // and TV expose the same options as per-tab chips instead.
                  if (PlatformDetector.isMobile(context) && tabController.index > 0)
                    FocusableAction(
                      icon: Symbols.tune_rounded,
                      tooltip: t.downloads.options,
                      debugLabel: 'downloads_options',
                      onPressed: () => _activeOptionsTab()?.showOptionsSheet(),
                    ),
                ],
              ),
            ],
          ),
          SliverFillRemaining(
            child: Column(
              children: [
                // Only while something is actually queued or transferring —
                // an idle Downloads screen has nothing to warn about.
                Selector<DownloadProvider, bool>(
                  selector: (_, provider) => provider.downloads.values.any(
                    (progress) =>
                        progress.status == DownloadStatus.downloading || progress.status == DownloadStatus.queued,
                  ),
                  builder: (context, hasPendingDownloads, _) =>
                      BackgroundDownloadWarningBanner(hasPendingDownloads: hasPendingDownloads),
                ),
                if (!PlatformDetector.shouldUseSideNavigation(context))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    alignment: .centerLeft,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildTabChip(t.downloads.manage, 0),
                          const SizedBox(width: 8),
                          _buildTabChip(t.downloads.tvShows, 1),
                          const SizedBox(width: 8),
                          _buildTabChip(t.downloads.movies, 2),
                          const SizedBox(width: 8),
                          _buildTabChip(t.downloads.music, 3),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    controller: tabController,
                    children: [
                      Consumer2<DownloadProvider, MultiServerProvider>(
                        builder: (context, downloadProvider, serverProvider, _) {
                          // Resolve the owning server's client from a download's
                          // globalKey (`serverId:ratingKey`). Backend-neutral —
                          // Jellyfin downloads also surface here, so the
                          // resume/retry buttons need a [MediaServerClient]
                          // (not a [PlexClient]) for both code paths.
                          getClient(String globalKey) {
                            final serverId = parseGlobalKey(globalKey)?.serverId ?? globalKey;
                            return serverProvider.serverManager.getClient(ServerId(serverId));
                          }

                          return DownloadTreeView(
                            downloads: downloadProvider.downloads,
                            metadata: downloadProvider.metadata,
                            onPause: downloadProvider.pauseDownload,
                            onResume: (globalKey) {
                              final client = getClient(globalKey);
                              if (client != null) {
                                downloadProvider.resumeDownload(globalKey, client);
                              }
                            },
                            onRetry: (globalKey) {
                              final client = getClient(globalKey);
                              if (client != null) {
                                downloadProvider.retryDownload(globalKey, client);
                              }
                            },
                            onCancel: downloadProvider.cancelDownload,
                            onDelete: downloadProvider.deleteDownload,
                            onNavigateLeft: () => MainScreenFocusScope.focusSidebarOf(context),
                            onBack: focusTabBar,
                            suppressAutoFocus: suppressAutoFocus,
                          );
                        },
                      ),
                      _DownloadsGridContent(key: _tvShowsTabKey, type: DownloadType.tvShows, onBack: focusTabBar),
                      _DownloadsGridContent(key: _moviesTabKey, type: DownloadType.movies, onBack: focusTabBar),
                      _DownloadedMusicContent(key: _musicTabKey, onBack: focusTabBar),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum DownloadType { tvShows, movies }

/// Grid content for the TV Shows and Movies tabs. [type] selects the
/// persistence section and grouping list; the active grouping picks which
/// provider collection renders — shows, seasons, or a flat episode grid for
/// TV, movies for Movies, or library-bucketed sections of the tab's default
/// item kind under the `library` grouping.
class _DownloadsGridContent extends StatefulWidget {
  final DownloadType type;
  final VoidCallback? onBack;

  const _DownloadsGridContent({super.key, required this.type, this.onBack});

  @override
  State<_DownloadsGridContent> createState() => _DownloadsGridContentState();
}

class _DownloadsGridContentState extends State<_DownloadsGridContent>
    with AutomaticKeepAliveClientMixin, DownloadsTabOptionsMixin<_DownloadsGridContent> {
  @override
  bool get wantKeepAlive => true;

  @override
  String get optionsSectionId => widget.type == DownloadType.tvShows ? 'downloads:tv' : 'downloads:movies';

  @override
  List<String> get groupingOptions => switch (widget.type) {
    DownloadType.tvShows => const [
      browseGroupingShows,
      browseGroupingSeasons,
      browseGroupingEpisodes,
      browseGroupingLibrary,
    ],
    DownloadType.movies => const [browseGroupingMovies, browseGroupingLibrary],
  };

  @override
  void initState() {
    super.initState();
    initDownloadsOptions();
  }

  @override
  void dispose() {
    disposeDownloadsOptions();
    super.dispose();
  }

  @override
  void navigateToTabBar() => widget.onBack?.call();

  @override
  void navigateToSidebar() => MainScreenFocusScope.focusSidebarOf(context);

  /// Items for the active grouping with filters and sort applied. The
  /// `library` grouping buckets the tab's default item kind (shows/movies).
  List<MediaItem> _items(DownloadProvider provider) {
    final raw = switch (widget.type) {
      DownloadType.tvShows => switch (selectedGrouping) {
        browseGroupingSeasons => provider.downloadedSeasons,
        browseGroupingEpisodes => provider.downloadedEpisodes,
        _ => provider.downloadedShows,
      },
      DownloadType.movies => provider.downloadedMovies,
    };
    return applyDownloadsOptions(provider, raw);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<DownloadProvider>(
      builder: (context, downloadProvider, _) {
        final items = _items(downloadProvider);
        final sections = selectedGrouping == browseGroupingLibrary
            ? bucketDownloadsByLibrary(
                items,
                serverNameOf: (serverId) =>
                    context.read<MultiServerProvider>().serverManager.serverDisplayName(ServerId(serverId)),
              )
            : null;

        return SettingsBuilder(
          prefs: const [
            SettingsService.viewMode,
            SettingsService.libraryDensity,
            SettingsService.tvFullCardLayout,
            SettingsService.episodePosterMode,
          ],
          builder: (context) {
            final settings = SettingsService.instance;
            final viewMode = settings.read(SettingsService.viewMode);
            final density = settings.read(SettingsService.libraryDensity);
            final fullCardLayout = PlatformDetector.isTV() && settings.read(SettingsService.tvFullCardLayout);
            // Episode grids use the wide 16:9 cell when episode thumbnails are
            // the configured poster mode, matching the library browse grid.
            final useWideRatio =
                selectedGrouping == browseGroupingEpisodes &&
                settings.read(SettingsService.episodePosterMode) == EpisodePosterMode.episodeThumbnail;

            return CustomScrollView(
              // Allow focus decoration to render outside scroll bounds.
              clipBehavior: Clip.none,
              slivers: [
                optionsChipsBarSliver(),
                if (sections != null)
                  ..._librarySlivers(sections, viewMode: viewMode, density: density, fullCardLayout: fullCardLayout)
                else if (items.isEmpty)
                  _emptySliver()
                else
                  _itemsSliver(
                    items,
                    viewMode: viewMode,
                    density: density,
                    fullCardLayout: fullCardLayout,
                    useWideAspectRatio: useWideRatio,
                    attachFirstItemFocus: true,
                    firstRowUp: navigateToChips,
                  ),
              ],
            );
          },
        );
      },
    );
  }

  /// One [MediaCardSliverLayout] of [items]. [attachFirstItemFocus] hands the
  /// tab's first-item node to card 0; [firstRowUp] is the UP target of the
  /// first row (the chips bar for the flat grid and first library section,
  /// null for later sections so default traversal reaches the section above).
  Widget _itemsSliver(
    List<MediaItem> items, {
    required ViewMode viewMode,
    required int density,
    required bool fullCardLayout,
    bool useWideAspectRatio = false,
    bool attachFirstItemFocus = false,
    VoidCallback? firstRowUp,
  }) {
    // Extra top padding for focus decoration (scale + border extends beyond item bounds)
    const effectivePadding = EdgeInsets.only(left: 8, right: 8, top: 8);
    return MediaCardSliverLayout(
      viewMode: viewMode,
      itemCount: items.length,
      density: density,
      padding: effectivePadding,
      fullBleedImage: fullCardLayout,
      useWideAspectRatio: useWideAspectRatio,
      itemBuilder: (context, position) {
        final item = items[position.index];
        return FocusableMediaCard(
          item: item,
          focusNode: attachFirstItemFocus && position.index == 0 ? firstItemFocusNode : null,
          disableScale: position.disableScale,
          onBack: widget.onBack,
          isOffline: true, // Downloaded content works without server
          fullBleedImage: fullCardLayout && position.isGrid,
          onNavigateUp: position.isFirstRow ? firstRowUp : null,
          onNavigateLeft: position.isFirstColumn ? navigateToSidebar : null,
        );
      },
    );
  }

  List<Widget> _librarySlivers(
    List<DownloadsLibrarySection> sections, {
    required ViewMode viewMode,
    required int density,
    required bool fullCardLayout,
  }) {
    if (sections.isEmpty) return [_emptySliver()];
    return [
      for (var i = 0; i < sections.length; i++) ...[
        SliverToBoxAdapter(child: DownloadsLibrarySectionHeader(section: sections[i])),
        _itemsSliver(
          sections[i].items,
          viewMode: viewMode,
          density: density,
          fullCardLayout: fullCardLayout,
          attachFirstItemFocus: i == 0,
          firstRowUp: i == 0 ? navigateToChips : null,
        ),
      ],
    ];
  }

  Widget _emptySliver() {
    return SliverFillRemaining(
      child: EmptyStateWidget(
        message: t.downloads.noDownloads,
        subtitle: t.downloads.noDownloadsDescription,
        icon: Symbols.download_rounded,
        iconSize: 80,
      ),
    );
  }
}

/// A row of the downloaded-music list: an album header ([album] non-null) or
/// a track at [trackIndex] within [albumTracks].
class _MusicListEntry {
  final MediaItem? album;
  final List<MediaItem> albumTracks;
  final int trackIndex;
  final bool isFirst;
  final bool isLast;

  const _MusicListEntry.header(MediaItem this.album)
    : albumTracks = const [],
      trackIndex = -1,
      isFirst = false,
      isLast = false;

  const _MusicListEntry.track(this.albumTracks, this.trackIndex, {required this.isFirst, required this.isLast})
    : album = null;
}

/// Music tab: downloaded tracks grouped under their album (square cover +
/// artist header, [TrackRow] entries), a flat track list, or album cards
/// bucketed per library. Tapping a track plays its downloaded siblings —
/// fully offline through the shared music playback path.
class _DownloadedMusicContent extends StatefulWidget {
  final VoidCallback? onBack;

  const _DownloadedMusicContent({super.key, this.onBack});

  @override
  State<_DownloadedMusicContent> createState() => _DownloadedMusicContentState();
}

class _DownloadedMusicContentState extends State<_DownloadedMusicContent>
    with AutomaticKeepAliveClientMixin, DownloadsTabOptionsMixin<_DownloadedMusicContent> {
  @override
  bool get wantKeepAlive => true;

  @override
  String get optionsSectionId => 'downloads:music';

  @override
  List<String> get groupingOptions => const [browseGroupingAlbums, browseGroupingTracks, browseGroupingLibrary];

  @override
  void initState() {
    super.initState();
    initDownloadsOptions();
  }

  @override
  void dispose() {
    disposeDownloadsOptions();
    super.dispose();
  }

  @override
  void navigateToTabBar() => widget.onBack?.call();

  @override
  void navigateToSidebar() => MainScreenFocusScope.focusSidebarOf(context);

  Future<void> _playAlbumFrom(List<MediaItem> albumTracks, MediaItem track) async {
    await playTracks(
      context,
      tracks: albumTracks,
      startTrack: track,
      playContext: MusicPlayContext(title: track.albumTitle ?? '', kind: MusicPlayContextKind.album),
    );
  }

  /// Play the flat track list (tracks grouping) starting at [track].
  Future<void> _playTracks(List<MediaItem> tracks, MediaItem track) async {
    await playTracks(
      context,
      tracks: tracks,
      startTrack: track,
      playContext: MusicPlayContext(title: t.downloads.title, kind: MusicPlayContextKind.tracks),
    );
  }

  Widget _buildAlbumHeader(BuildContext context, DownloadProvider provider, MediaItem album) {
    final tk = tokens(context);
    final textTheme = Theme.of(context).textTheme;
    final artist = album.albumArtistTitle;
    final serverId = album.serverId;
    final localArt = serverId == null ? null : provider.getArtworkLocalPath(ServerId(serverId), album.thumbPath);
    final ImageProvider? localCoverImage;
    if (localArt == null) {
      localCoverImage = null;
    } else {
      final pixelRatio = MediaImageHelper.artworkPixelRatio(context, imageType: ImageType.square);
      final (memWidth, memHeight) = MediaImageHelper.getMemCacheDimensions(
        displayWidth: (48 * pixelRatio).round(),
        displayHeight: (48 * pixelRatio).round(),
        imageType: ImageType.square,
      );
      localCoverImage = MediaImageHelper.boundedDecode(
        FileImage(File(localArt)),
        memWidth: memWidth,
        memHeight: memHeight,
      );
    }
    Widget fallbackCover() => Container(
      width: 48,
      height: 48,
      color: tk.surface,
      child: AppIcon(Symbols.album_rounded, fill: 1, size: 24, color: tk.textMuted),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(tk.radiusSm),
            child: localCoverImage != null
                ? Image(
                    image: localCoverImage,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    filterQuality: MediaImageHelper.artworkFilterQuality(context, ImageType.square),
                    errorBuilder: (_, _, _) => fallbackCover(),
                  )
                : fallbackCover(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(album.displayTitle, style: textTheme.titleSmall, maxLines: 1, overflow: .ellipsis),
                if (artist != null && artist.isNotEmpty)
                  Text(
                    artist,
                    style: textTheme.bodySmall?.copyWith(color: tk.textMuted),
                    maxLines: 1,
                    overflow: .ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Album-grouped rows: each album with downloaded tracks contributes a
  /// header plus its tracks in disc/track order. The album list itself is
  /// filtered and sorted by the active options.
  List<_MusicListEntry> _rowModels(DownloadProvider provider) {
    final albums = applyDownloadsOptions(provider, provider.downloadedAlbums);
    final rows = <_MusicListEntry>[];
    for (final album in albums) {
      final tracks = provider.getDownloadedTracksForAlbum(album.globalKey);
      if (tracks.isEmpty) continue;
      rows.add(_MusicListEntry.header(album));
      for (var i = 0; i < tracks.length; i++) {
        rows.add(_MusicListEntry.track(tracks, i, isFirst: i == 0, isLast: i == tracks.length - 1));
      }
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<DownloadProvider>(
      builder: (context, downloadProvider, _) {
        // Keep the last rows reachable above the floating mini-player.
        final bottomInset = context.watch<MiniPlayerInsetController?>()?.overlayHeight ?? 0;

        return SettingsBuilder(
          prefs: const [SettingsService.viewMode, SettingsService.libraryDensity, SettingsService.tvFullCardLayout],
          builder: (context) {
            final settings = SettingsService.instance;
            final viewMode = settings.read(SettingsService.viewMode);
            final density = settings.read(SettingsService.libraryDensity);
            final fullCardLayout = PlatformDetector.isTV() && settings.read(SettingsService.tvFullCardLayout);

            return CustomScrollView(
              // Allow focus decoration to render outside scroll bounds.
              clipBehavior: Clip.none,
              slivers: [
                optionsChipsBarSliver(),
                ..._contentSlivers(
                  downloadProvider,
                  bottomInset: bottomInset,
                  viewMode: viewMode,
                  density: density,
                  fullCardLayout: fullCardLayout,
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<Widget> _contentSlivers(
    DownloadProvider provider, {
    required double bottomInset,
    required ViewMode viewMode,
    required int density,
    required bool fullCardLayout,
  }) {
    return switch (selectedGrouping) {
      browseGroupingTracks => _tracksSlivers(provider, bottomInset),
      browseGroupingLibrary => _librarySlivers(
        provider,
        bottomInset: bottomInset,
        viewMode: viewMode,
        density: density,
        fullCardLayout: fullCardLayout,
      ),
      _ => _albumSlivers(provider, bottomInset),
    };
  }

  /// The default albums view: album headers with their downloaded tracks.
  List<Widget> _albumSlivers(DownloadProvider provider, double bottomInset) {
    final rows = _rowModels(provider);
    if (rows.isEmpty) return [_emptySliver()];

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
        sliver: SliverList.builder(
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final row = rows[index];
            final album = row.album;
            if (album != null) {
              return _buildAlbumHeader(context, provider, album);
            }
            final item = row.albumTracks[row.trackIndex];
            // Row 0 is always the first album's header, so the first track
            // row sits at index 1.
            final isFirstTrackRow = index == 1;
            return Padding(
              padding: EdgeInsets.only(top: row.isFirst ? 0 : tokens(context).groupGap),
              child: TrackRow(
                key: ValueKey(item.globalKey),
                item: item,
                isFirst: row.isFirst,
                isLast: row.isLast,
                showArtist: true,
                focusNode: isFirstTrackRow ? firstItemFocusNode : null,
                onNavigateUp: isFirstTrackRow ? navigateToChips : null,
                onBack: widget.onBack,
                onTap: () => _playAlbumFrom(row.albumTracks, item),
              ),
            );
          },
        ),
      ),
    ];
  }

  /// The flat all-tracks list. Track numbers stay hidden — they are
  /// album-relative and read as a sorting bug in a cross-album list.
  List<Widget> _tracksSlivers(DownloadProvider provider, double bottomInset) {
    final tracks = applyDownloadsOptions(provider, provider.downloadedTracks);
    if (tracks.isEmpty) return [_emptySliver()];

    return [
      SliverPadding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
        sliver: SliverList.builder(
          itemCount: tracks.length,
          itemBuilder: (context, index) {
            final item = tracks[index];
            return Padding(
              padding: EdgeInsets.only(top: index == 0 ? 0 : tokens(context).groupGap),
              child: TrackRow(
                key: ValueKey(item.globalKey),
                item: item,
                isFirst: index == 0,
                isLast: index == tracks.length - 1,
                showArtist: true,
                showTrackNumber: false,
                focusNode: index == 0 ? firstItemFocusNode : null,
                onNavigateUp: index == 0 ? navigateToChips : null,
                onBack: widget.onBack,
                onTap: () => _playTracks(tracks, item),
              ),
            );
          },
        ),
      ),
    ];
  }

  /// Album cards bucketed per library, mirroring the grid tabs' sections.
  List<Widget> _librarySlivers(
    DownloadProvider provider, {
    required double bottomInset,
    required ViewMode viewMode,
    required int density,
    required bool fullCardLayout,
  }) {
    final albums = applyDownloadsOptions(provider, provider.downloadedAlbums);
    final sections = bucketDownloadsByLibrary(
      albums,
      serverNameOf: (serverId) =>
          context.read<MultiServerProvider>().serverManager.serverDisplayName(ServerId(serverId)),
    );
    if (sections.isEmpty) return [_emptySliver()];

    // Extra top padding for focus decoration (scale + border extends beyond item bounds)
    const effectivePadding = EdgeInsets.only(left: 8, right: 8, top: 8);
    return [
      for (var i = 0; i < sections.length; i++) ...[
        SliverToBoxAdapter(child: DownloadsLibrarySectionHeader(section: sections[i])),
        MediaCardSliverLayout(
          viewMode: viewMode,
          itemCount: sections[i].items.length,
          density: density,
          padding: effectivePadding,
          fullBleedImage: fullCardLayout,
          itemBuilder: (context, position) {
            final item = sections[i].items[position.index];
            return FocusableMediaCard(
              item: item,
              focusNode: i == 0 && position.index == 0 ? firstItemFocusNode : null,
              disableScale: position.disableScale,
              onBack: widget.onBack,
              isOffline: true, // Downloaded content works without server
              fullBleedImage: fullCardLayout && position.isGrid,
              onNavigateUp: i == 0 && position.isFirstRow ? navigateToChips : null,
              onNavigateLeft: position.isFirstColumn ? navigateToSidebar : null,
            );
          },
        ),
      ],
      // Keep the last section's cards reachable above the mini-player.
      SliverToBoxAdapter(child: SizedBox(height: bottomInset)),
    ];
  }

  Widget _emptySliver() {
    return SliverFillRemaining(
      child: EmptyStateWidget(
        message: t.downloads.noDownloads,
        subtitle: t.downloads.noDownloadsDescription,
        icon: Symbols.music_note_rounded,
        iconSize: 80,
      ),
    );
  }
}
