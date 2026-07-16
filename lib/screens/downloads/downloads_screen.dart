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
import '../../widgets/app_icon.dart';
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
import '../main_screen.dart';
import '../libraries/state_messages.dart';
import '../../i18n/strings.g.dart';
import 'sync_rules_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => DownloadsScreenState();
}

class DownloadsScreenState extends State<DownloadsScreen>
    with TickerProviderStateMixin, TabNavigationMixin, FocusableTab {
  // Focus nodes for tab chips
  final _queueTabChipFocusNode = FocusNode(debugLabel: 'tab_chip_queue');
  final _tvShowsTabChipFocusNode = FocusNode(debugLabel: 'tab_chip_tv_shows');
  final _moviesTabChipFocusNode = FocusNode(debugLabel: 'tab_chip_movies');
  final _musicTabChipFocusNode = FocusNode(debugLabel: 'tab_chip_music');
  final _actionBarKey = GlobalKey<FocusableActionBarState>();

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
    suppressAutoFocus = true; // Start suppressed
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

  /// Focus the first item in the currently active tab
  void _focusCurrentTab() {
    // Re-enable auto-focus since user is navigating into tab content
    setState(() {
      suppressAutoFocus = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Focus will be handled by the tab content
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
    // On desktop/TV with side nav, show tabs in app bar
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

    // On mobile, show simple title
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
                    onPressed: () =>
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const SyncRulesScreen())),
                  ),
                ],
              ),
            ],
          ),
          SliverFillRemaining(
            child: Column(
              children: [
                // Tab selector chips (only on mobile - desktop has them in app bar)
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
                // Tab content
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
                      _DownloadsGridContent(
                        type: DownloadType.tvShows,
                        suppressAutoFocus: suppressAutoFocus,
                        onBack: focusTabBar,
                      ),
                      _DownloadsGridContent(
                        type: DownloadType.movies,
                        suppressAutoFocus: suppressAutoFocus,
                        onBack: focusTabBar,
                      ),
                      _DownloadedMusicContent(suppressAutoFocus: suppressAutoFocus, onBack: focusTabBar),
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

enum DownloadType { manage, tvShows, movies }

/// Grid content for TV Shows and Movies tabs
class _DownloadsGridContent extends StatefulWidget {
  final DownloadType type;
  final bool suppressAutoFocus;
  final VoidCallback? onBack;

  const _DownloadsGridContent({required this.type, required this.suppressAutoFocus, this.onBack});

  @override
  State<_DownloadsGridContent> createState() => _DownloadsGridContentState();
}

class _DownloadsGridContentState extends State<_DownloadsGridContent> {
  final FocusNode _firstItemFocusNode = FocusNode(debugLabel: 'DownloadsGrid_firstItem');

  @override
  void dispose() {
    _firstItemFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_DownloadsGridContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When suppressAutoFocus changes from true to false, focus the first item
    if (oldWidget.suppressAutoFocus && !widget.suppressAutoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _firstItemFocusNode.canRequestFocus) {
          _firstItemFocusNode.requestFocus();
        }
      });
    }
  }

  /// Navigate focus to the sidebar
  void _navigateToSidebar() {
    MainScreenFocusScope.focusSidebarOf(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadProvider>(
      builder: (context, downloadProvider, _) {
        final List<MediaItem> items = widget.type == DownloadType.tvShows
            ? downloadProvider.downloadedShows
            : downloadProvider.downloadedMovies;

        if (items.isEmpty) {
          return _buildEmptyState();
        }

        // Extra top padding for focus decoration (scale + border extends beyond item bounds)
        const effectivePadding = EdgeInsets.only(left: 8, right: 8, top: 8);

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
                MediaCardSliverLayout(
                  viewMode: viewMode,
                  itemCount: items.length,
                  density: density,
                  padding: effectivePadding,
                  fullBleedImage: fullCardLayout,
                  itemBuilder: (context, position) {
                    final item = items[position.index];
                    return FocusableMediaCard(
                      item: item,
                      focusNode: position.index == 0 ? _firstItemFocusNode : null,
                      disableScale: position.disableScale,
                      onBack: widget.onBack,
                      isOffline: true, // Downloaded content works without server
                      fullBleedImage: fullCardLayout && position.isGrid,
                      onNavigateLeft: position.isFirstColumn ? _navigateToSidebar : null,
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      message: t.downloads.noDownloads,
      subtitle: t.downloads.noDownloadsDescription,
      icon: Symbols.download_rounded,
      iconSize: 80,
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
/// artist header, [TrackRow] entries). Tapping a track plays the album's
/// downloaded tracks in disc/track order — fully offline through the shared
/// music playback path.
class _DownloadedMusicContent extends StatefulWidget {
  final bool suppressAutoFocus;
  final VoidCallback? onBack;

  const _DownloadedMusicContent({required this.suppressAutoFocus, this.onBack});

  @override
  State<_DownloadedMusicContent> createState() => _DownloadedMusicContentState();
}

class _DownloadedMusicContentState extends State<_DownloadedMusicContent> {
  final FocusNode _firstItemFocusNode = FocusNode(debugLabel: 'DownloadsMusic_firstItem');

  @override
  void dispose() {
    _firstItemFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_DownloadedMusicContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.suppressAutoFocus && !widget.suppressAutoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _firstItemFocusNode.canRequestFocus) {
          _firstItemFocusNode.requestFocus();
        }
      });
    }
  }

  Future<void> _playAlbumFrom(List<MediaItem> albumTracks, MediaItem track) async {
    final album = track.parentId;
    await playTracks(
      context,
      tracks: albumTracks,
      startTrack: track,
      playContext: MusicPlayContext(id: album, title: track.albumTitle ?? '', kind: MusicPlayContextKind.album),
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
      final dpr = MediaImageHelper.effectiveDevicePixelRatio(context);
      final (memWidth, memHeight) = MediaImageHelper.getMemCacheDimensions(
        displayWidth: (48 * dpr).round(),
        displayHeight: (48 * dpr).round(),
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

  List<_MusicListEntry> _rowModels(DownloadProvider provider) {
    final rows = <_MusicListEntry>[];
    for (final album in provider.downloadedAlbums) {
      final tracks = provider.getDownloadedTracksForAlbum(album.id);
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
    return Consumer<DownloadProvider>(
      builder: (context, downloadProvider, _) {
        final rows = _rowModels(downloadProvider);

        if (rows.isEmpty) {
          return EmptyStateWidget(
            message: t.downloads.noDownloads,
            subtitle: t.downloads.noDownloadsDescription,
            icon: Symbols.music_note_rounded,
            iconSize: 80,
          );
        }

        // Keep the last rows reachable above the floating mini-player.
        final bottomInset = context.watch<MiniPlayerInsetController?>()?.overlayHeight ?? 0;

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final row = rows[index];
            final album = row.album;
            if (album != null) {
              return _buildAlbumHeader(context, downloadProvider, album);
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
                focusNode: isFirstTrackRow ? _firstItemFocusNode : null,
                onBack: widget.onBack,
                onTap: () => _playAlbumFrom(row.albumTracks, item),
              ),
            );
          },
        );
      },
    );
  }
}
