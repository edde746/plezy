import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../../models/plex_metadata.dart';
import '../../providers/download_provider.dart';
import '../../providers/multi_server_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/gamepad_service.dart';
import '../../utils/platform_detector.dart';
import '../../widgets/desktop_app_bar.dart';
import '../../widgets/focusable_tab_chip.dart';
import '../../widgets/focusable_media_card.dart';
import '../../widgets/media_grid_delegate.dart';
import '../../widgets/download_tree_view.dart';
import '../main_screen.dart';
import '../../i18n/strings.g.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => DownloadsScreenState();
}

class DownloadsScreenState extends State<DownloadsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Focus nodes for tab chips
  final _queueTabChipFocusNode = FocusNode(debugLabel: 'tab_chip_queue');
  final _tvShowsTabChipFocusNode = FocusNode(debugLabel: 'tab_chip_tv_shows');
  final _moviesTabChipFocusNode = FocusNode(debugLabel: 'tab_chip_movies');

  /// When true, suppress auto-focus in tabs (used when navigating via tab bar)
  bool _suppressAutoFocus = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Register L1/R1 callbacks for tab navigation
    GamepadService.onL1Pressed = _goToPreviousTab;
    GamepadService.onR1Pressed = _goToNextTab;
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _queueTabChipFocusNode.dispose();
    _tvShowsTabChipFocusNode.dispose();
    _moviesTabChipFocusNode.dispose();
    // Clear L1/R1 callbacks
    GamepadService.onL1Pressed = null;
    GamepadService.onR1Pressed = null;
    super.dispose();
  }

  void _goToPreviousTab() {
    if (_tabController.index > 0) {
      setState(() {
        _suppressAutoFocus = true;
        _tabController.index = _tabController.index - 1;
      });
      _getTabChipFocusNode(_tabController.index).requestFocus();
    }
  }

  void _goToNextTab() {
    if (_tabController.index < _tabController.length - 1) {
      setState(() {
        _suppressAutoFocus = true;
        _tabController.index = _tabController.index + 1;
      });
      _getTabChipFocusNode(_tabController.index).requestFocus();
    }
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      // Rebuild to update chip selection state
      setState(() {});
    }
  }

  /// Get the focus node for a tab chip by index
  FocusNode _getTabChipFocusNode(int index) {
    switch (index) {
      case 0:
        return _queueTabChipFocusNode;
      case 1:
        return _tvShowsTabChipFocusNode;
      case 2:
        return _moviesTabChipFocusNode;
      default:
        return _queueTabChipFocusNode;
    }
  }

  /// Focus the currently selected tab chip in the tab bar.
  /// Called when BACK is pressed in tab content.
  void focusTabBar() {
    setState(() {
      _suppressAutoFocus = true;
    });
    final focusNode = _getTabChipFocusNode(_tabController.index);
    focusNode.requestFocus();
  }

  /// Handle BACK from tab bar - navigate to sidenav
  void _onTabBarBack() {
    final focusScope = MainScreenFocusScope.of(context);
    focusScope?.focusSidebar();
  }

  /// Focus the first item in the currently active tab
  void _focusCurrentTab() {
    // Re-enable auto-focus since user is navigating into tab content
    setState(() {
      _suppressAutoFocus = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Focus will be handled by the tab content
    });
  }

  Widget _buildTabChip(String label, int index) {
    final isSelected = _tabController.index == index;
    const tabCount = 3; // Queue, TV Shows, Movies

    return FocusableTabChip(
      label: label,
      isSelected: isSelected,
      focusNode: _getTabChipFocusNode(index),
      onSelect: () {
        if (isSelected) {
          // Already selected - navigate to tab content
          _focusCurrentTab();
        } else {
          // Switch to this tab
          setState(() {
            _tabController.index = index;
          });
        }
      },
      onNavigateLeft: index > 0
          ? () {
              final newIndex = index - 1;
              setState(() {
                _suppressAutoFocus = true;
                _tabController.index = newIndex;
              });
              _getTabChipFocusNode(newIndex).requestFocus();
            }
          : null,
      onNavigateRight: index < tabCount - 1
          ? () {
              final newIndex = index + 1;
              setState(() {
                _suppressAutoFocus = true;
                _tabController.index = newIndex;
              });
              _getTabChipFocusNode(newIndex).requestFocus();
            }
          : null,
      onNavigateDown: _focusCurrentTab,
      onBack: _onTabBarBack,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
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
                    controller: _tabController,
                    children: [
                      Consumer2<DownloadProvider, MultiServerProvider>(
                        builder: (context, downloadProvider, serverProvider, _) {
                          // Helper to get client from globalKey (serverId:ratingKey)
                          getClient(String globalKey) {
                            final serverId = globalKey.split(':').first;
                            return serverProvider.serverManager.getClient(
                              serverId,
                            );
                          }

                          return DownloadTreeView(
                            downloads: downloadProvider.downloads,
                            metadata: downloadProvider.metadata,
                            onPause: downloadProvider.pauseDownload,
                            onResume: (globalKey) {
                              final client = getClient(globalKey);
                              if (client != null) {
                                downloadProvider.resumeDownload(
                                  globalKey,
                                  client,
                                );
                              }
                            },
                            onRetry: (globalKey) {
                              final client = getClient(globalKey);
                              if (client != null) {
                                downloadProvider.retryDownload(
                                  globalKey,
                                  client,
                                );
                              }
                            },
                            onCancel: downloadProvider.cancelDownload,
                            onDelete: downloadProvider.deleteDownload,
                          );
                        },
                      ),
                      _DownloadsGridContent(
                        type: DownloadType.tvShows,
                        suppressAutoFocus: _suppressAutoFocus,
                        onBack: focusTabBar,
                      ),
                      _DownloadsGridContent(
                        type: DownloadType.movies,
                        suppressAutoFocus: _suppressAutoFocus,
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
class _DownloadsGridContent extends StatelessWidget {
  final DownloadType type;
  final bool suppressAutoFocus;
  final VoidCallback? onBack;

  const _DownloadsGridContent({
    required this.type,
    required this.suppressAutoFocus,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer2<DownloadProvider, SettingsProvider>(
      builder: (context, downloadProvider, settingsProvider, _) {
        final List<PlexMetadata> items = type == DownloadType.tvShows
            ? downloadProvider.downloadedShows
            : downloadProvider.downloadedMovies;

        if (items.isEmpty) {
          return _buildEmptyState(context);
        }

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          gridDelegate: MediaGridDelegate.createDelegate(
            context: context,
            density: settingsProvider.libraryDensity,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return FocusableMediaCard(
              item: item,
              onBack: onBack,
              isOffline: true, // Downloaded content works without server
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(
              Symbols.download_rounded,
              fill: 1,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              t.downloads.noDownloads,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.downloads.noDownloadsDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
