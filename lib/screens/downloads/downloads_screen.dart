import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../models/plex_metadata.dart';
import '../../providers/download_provider.dart';
import '../../providers/multi_server_provider.dart';
import '../../providers/settings_provider.dart';
import '../../utils/global_key_utils.dart';
import '../../utils/snackbar_helper.dart';
import '../../mixins/tab_navigation_mixin.dart';
import '../../utils/grid_size_calculator.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/desktop_app_bar.dart';
import '../../widgets/focusable_tab_chip.dart';
import '../../widgets/focusable_media_card.dart';
import '../../widgets/media_grid_delegate.dart';
import '../../widgets/download_tree_view.dart';
import '../../widgets/download_settings_dialog.dart';
import '../../services/auto_download_service.dart';
import '../main_screen.dart';
import '../libraries/state_messages.dart';
import '../../i18n/strings.g.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => DownloadsScreenState();
}

class DownloadsScreenState extends State<DownloadsScreen> with SingleTickerProviderStateMixin, TabNavigationMixin {
  // Focus nodes for tab chips
  final _queueTabChipFocusNode = FocusNode(debugLabel: 'tab_chip_queue');
  final _tvShowsTabChipFocusNode = FocusNode(debugLabel: 'tab_chip_tv_shows');
  final _moviesTabChipFocusNode = FocusNode(debugLabel: 'tab_chip_movies');

  @override
  List<FocusNode> get tabChipFocusNodes => [_queueTabChipFocusNode, _tvShowsTabChipFocusNode, _moviesTabChipFocusNode];

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
    disposeTabNavigation();
    super.dispose();
  }

  @override
  void onTabChanged() {
    if (!tabController.indexIsChanging) {
      super.onTabChanged();
    }
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
    final isSelected = tabController.index == index;

    return FocusableTabChip(
      label: label,
      isSelected: isSelected,
      focusNode: getTabChipFocusNode(index),
      onSelect: () {
        if (isSelected) {
          // Already selected - navigate to tab content
          _focusCurrentTab();
        } else {
          // Switch to this tab
          setState(() {
            tabController.index = index;
          });
        }
      },
      onNavigateLeft: index > 0
          ? () {
              final newIndex = index - 1;
              setState(() {
                suppressAutoFocus = true;
                tabController.index = newIndex;
              });
              getTabChipFocusNode(newIndex).requestFocus();
            }
          : onTabBarBack,
      onNavigateRight: index < tabCount - 1
          ? () {
              final newIndex = index + 1;
              setState(() {
                suppressAutoFocus = true;
                tabController.index = newIndex;
              });
              getTabChipFocusNode(newIndex).requestFocus();
            }
          : null,
      onNavigateDown: _focusCurrentTab,
      onBack: onTabBarBack,
    );
  }

  /// Build the app bar title - either tabs on desktop or simple title on mobile
  Widget _buildAppBarTitle() {
    // On desktop/TV with side nav, show tabs in app bar
    if (PlatformDetector.shouldUseSideNavigation(context)) {
      return Row(
        children: [
          _buildTabChip(t.downloads.manage, 0),
          const SizedBox(width: 8),
          _buildTabChip(t.downloads.tvShows, 1),
          const SizedBox(width: 8),
          _buildTabChip(t.downloads.movies, 2),
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
        slivers: [
          DesktopSliverAppBar(
            title: _buildAppBarTitle(),
            floating: true,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            scrolledUnderElevation: 0,
          ),
          SliverFillRemaining(
            child: Column(
              children: [
                // Tab selector chips (only on mobile - desktop has them in app bar)
                if (!PlatformDetector.shouldUseSideNavigation(context))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    alignment: Alignment.centerLeft,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildTabChip(t.downloads.manage, 0),
                          const SizedBox(width: 8),
                          _buildTabChip(t.downloads.tvShows, 1),
                          const SizedBox(width: 8),
                          _buildTabChip(t.downloads.movies, 2),
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
                          // Helper to get client from globalKey (serverId:ratingKey)
                          getClient(String globalKey) {
                            final serverId = parseGlobalKey(globalKey)?.serverId ?? globalKey;
                            return serverProvider.serverManager.getClient(serverId);
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
                            onRefresh: (globalKey) async {
                              final meta = downloadProvider.getMetadata(globalKey);
                              if (meta == null) return;
                              final client = getClient(globalKey);
                              if (client == null) return;
                              final autoDownload = AutoDownloadService();
                              final result = await autoDownload.refreshShow(meta, client, downloadProvider);
                              if (context.mounted) {
                                if (result.queued > 0) {
                                  showSuccessSnackBar(context, t.downloads.episodesQueued(count: result.queued));
                                } else if (result.trimmed > 0) {
                                  showSuccessSnackBar(context, t.downloads.downloadDeleted);
                                } else {
                                  showAppSnackBar(context, t.downloads.noNewEpisodesFound);
                                }
                              }
                            },
                            onSettings: (ratingKey, title, isSeries) {
                              final globalKey = downloadProvider.metadata.keys.firstWhere(
                                (k) => k.endsWith(':$ratingKey'),
                                orElse: () => '',
                              );
                              final client = globalKey.isNotEmpty ? getClient(globalKey) : null;
                              showDownloadSettingsDialog(
                                context,
                                ratingKey: ratingKey,
                                title: title,
                                isSeries: isSeries,
                                downloadProvider: downloadProvider,
                                client: client,
                              );
                            },
                            onNavigateLeft: () => MainScreenFocusScope.of(context)?.focusSidebar(),
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
    MainScreenFocusScope.of(context)?.focusSidebar();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<DownloadProvider, SettingsProvider>(
      builder: (context, downloadProvider, settingsProvider, _) {
        final List<PlexMetadata> items = widget.type == DownloadType.tvShows
            ? downloadProvider.downloadedShows
            : downloadProvider.downloadedMovies;

        if (items.isEmpty) {
          return _buildEmptyState();
        }

        // Extra top padding for focus decoration (scale + border extends beyond item bounds)
        const effectivePadding = EdgeInsets.only(left: 8, right: 8, top: 8);
        final maxCrossAxisExtent = GridSizeCalculator.getMaxCrossAxisExtent(context, settingsProvider.libraryDensity);

        // Use LayoutBuilder to get actual available width (accounting for sidebar)
        return LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth - effectivePadding.left - effectivePadding.right;
            final columnCount = GridSizeCalculator.getColumnCount(availableWidth, maxCrossAxisExtent);

            return GridView.builder(
              padding: effectivePadding,
              // Allow focus decoration to render outside scroll bounds
              clipBehavior: Clip.none,
              gridDelegate: MediaGridDelegate.createDelegate(
                context: context,
                density: settingsProvider.libraryDensity,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isFirstColumn = GridSizeCalculator.isFirstColumn(index, columnCount);
                final isFirst = index == 0;
                return FocusableMediaCard(
                  item: item,
                  focusNode: isFirst ? _firstItemFocusNode : null,
                  onBack: widget.onBack,
                  isOffline: true, // Downloaded content works without server
                  onNavigateLeft: isFirstColumn ? _navigateToSidebar : null,
                );
              },
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
