import 'package:flutter/material.dart';
import '../focus/focusable_action_bar.dart';
import '../focus/input_mode_tracker.dart';
import '../focus/key_event_utils.dart';
import '../media/media_item.dart';
import '../media/media_playlist.dart';
import '../mixins/grid_focus_node_mixin.dart';
import '../services/settings_service.dart';
import '../widgets/settings_builder.dart';
import '../utils/grid_size_calculator.dart';
import '../widgets/focusable_media_card.dart';
import '../widgets/media_grid_delegate.dart';
import '../widgets/skeleton_media_card.dart';

/// Extract the stable id from a [MediaItem]/[MediaPlaylist] for use as a
/// Flutter widget Key.
String _idForItem(Object item) {
  if (item is MediaItem) return item.id;
  if (item is MediaPlaylist) return item.id;
  return identityHashCode(item).toString();
}

/// Mixin that provides common focus navigation functionality for detail screens.
/// Handles app bar focus, back navigation, scroll-to-top, and grid item focus management.
///
/// Classes using this mixin must also use [GridFocusNodeMixin].
mixin FocusableDetailScreenMixin<T extends StatefulWidget> on State<T>, GridFocusNodeMixin<T> {
  // Scroll controller for scrolling to top when app bar is focused
  final ScrollController scrollController = ScrollController();

  // Action bar key for accessing focus nodes
  final GlobalKey<FocusableActionBarState> actionBarKey = GlobalKey<FocusableActionBarState>();

  // Grid item focus
  final FocusNode firstItemFocusNode = FocusNode(debugLabel: 'detail_first_item');

  // App bar focus state
  bool isAppBarFocused = false;

  // Flag to prevent PopScope from exiting when BACK was handled by a key handler
  bool backHandledByKeyEvent = false;

  /// Called when items are available and we want to check if focus should be set
  bool get hasItems;

  /// Called to get the list of app bar action configurations
  List<FocusableAction> getAppBarActions();

  /// Dispose focus-related resources. Call this from your dispose() method.
  void disposeFocusResources() {
    scrollController.dispose();
    firstItemFocusNode.dispose();
    disposeGridFocusNodes();
  }

  /// Navigate from content to app bar
  void navigateToAppBar() {
    setState(() {
      isAppBarFocused = true;
    });
    actionBarKey.currentState?.requestFocusOnFirst();
    // Scroll to top to show the app bar
    scrollController.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  /// Handle BACK key from content - navigate to app bar and set flag to prevent PopScope exit
  void handleBackFromContent() {
    if (getAppBarActions().isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }
    backHandledByKeyEvent = true;
    navigateToAppBar();
  }

  /// Navigate focus from app bar down to the grid
  void navigateToGrid() {
    if (!hasItems) return;

    final targetIndex = shouldRestoreGridFocus ? lastFocusedGridIndex! : 0;

    setState(() {
      isAppBarFocused = false;
    });

    _focusNodeForIndex(targetIndex).requestFocus();
  }

  FocusNode _focusNodeForIndex(int index) => focusNodeForIndex(index, firstItemFocusNode, prefix: 'detail_grid_item');

  /// Wrap [slivers] in the standard detail-screen scaffold — PopScope that
  /// defers to [handleBackNavigation], plus a Scaffold with a CustomScrollView
  /// bound to [scrollController]. Callers build the slivers themselves
  /// (typically `[appBar, ...header, ...buildStateSlivers(), grid]`).
  Widget buildDetailScaffold({required List<Widget> slivers}) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (BackKeyCoordinator.consumeIfHandled()) return;
        if (didPop) return;
        final shouldPop = handleBackNavigation();
        if (shouldPop && mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        body: CustomScrollView(controller: scrollController, slivers: slivers),
      ),
    );
  }

  /// Handle back navigation for PopScope. Returns true if should pop.
  bool handleBackNavigation() {
    // If BACK was already handled by a key event, don't pop
    if (backHandledByKeyEvent) {
      backHandledByKeyEvent = false;
      return false;
    }

    if (isAppBarFocused || getAppBarActions().isEmpty) {
      return true;
    } else {
      // Focus app bar first
      navigateToAppBar();
      return false;
    }
  }

  /// Build focusable app bar action widgets
  List<Widget> buildFocusableAppBarActions() {
    return [
      FocusableActionBar(
        key: actionBarKey,
        onNavigateDown: navigateToGrid,
        onBack: () => Navigator.pop(context),
        actions: getAppBarActions(),
      ),
    ];
  }

  /// Auto-focus first item after load if in keyboard mode.
  /// Call this from loadItems() after items are loaded.
  void autoFocusFirstItemAfterLoad() {
    if (mounted && hasItems) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (InputModeTracker.isKeyboardMode(context)) {
          setState(() {
            isAppBarFocused = false;
          });
          firstItemFocusNode.requestFocus();
        }
      });
    }
  }

  /// Build a standard focusable grid sliver for media items.
  /// Used by collection and smart playlist detail screens.
  Widget buildFocusableGrid({
    required List<dynamic> items,
    required void Function(String itemId) onRefresh,
    String? collectionId,
    VoidCallback? onListRefresh,
  }) {
    return SettingsBuilder(
      prefs: const [SettingsService.viewMode, SettingsService.libraryDensity],
      builder: (context) {
        final svc = SettingsService.instanceOrNull!;
        final isListMode = svc.read(SettingsService.viewMode) == ViewMode.list;
        final libraryDensity = svc.read(SettingsService.libraryDensity);

        if (isListMode) {
          return SliverPadding(
            padding: const EdgeInsets.all(8),
            sliver: SliverList.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final focusNode = _focusNodeForIndex(index);

                return FocusableMediaCard(
                  key: Key(_idForItem(item)),
                  item: item,
                  focusNode: focusNode,
                  disableScale: true,
                  onRefresh: onRefresh,
                  collectionId: collectionId,
                  onListRefresh: onListRefresh,
                  onNavigateUp: index == 0 ? navigateToAppBar : null,
                  onBack: handleBackFromContent,
                  onFocusChange: (hasFocus) => trackGridItemFocus(index, hasFocus),
                );
              },
            ),
          );
        }

        final maxExtent = GridSizeCalculator.getMaxCrossAxisExtent(context, libraryDensity);
        return SliverPadding(
          padding: const EdgeInsets.all(8),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              final columnCount = GridSizeCalculator.getColumnCount(constraints.crossAxisExtent, maxExtent);
              return SliverGrid.builder(
                gridDelegate: MediaGridDelegate.createDelegate(context: context, density: libraryDensity),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final inFirstRow = GridSizeCalculator.isFirstRow(index, columnCount);
                  final focusNode = _focusNodeForIndex(index);

                  return FocusableMediaCard(
                    key: Key(_idForItem(item)),
                    item: item,
                    focusNode: focusNode,
                    onRefresh: onRefresh,
                    collectionId: collectionId,
                    onListRefresh: onListRefresh,
                    onNavigateUp: inFirstRow ? navigateToAppBar : null,
                    onBack: handleBackFromContent,
                    onFocusChange: (hasFocus) => trackGridItemFocus(index, hasFocus),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  /// Sparse-loading version of [buildFocusableGrid]. Renders [totalItems]
  /// slots; for each, [itemAt] returns the loaded item or null if not yet
  /// fetched. Null slots render a skeleton and invoke [onSkeletonVisible] so
  /// the caller can kick off a page fetch containing that index.
  Widget buildSparseFocusableGrid({
    required int totalItems,
    required MediaItem? Function(int index) itemAt,
    required void Function(String itemId) onRefresh,
    void Function(int index)? onSkeletonVisible,
    String? collectionId,
    VoidCallback? onListRefresh,
  }) {
    return SettingsBuilder(
      prefs: const [SettingsService.viewMode, SettingsService.libraryDensity],
      builder: (context) {
        final svc = SettingsService.instanceOrNull!;
        final isListMode = svc.read(SettingsService.viewMode) == ViewMode.list;
        final libraryDensity = svc.read(SettingsService.libraryDensity);

        Widget buildTile(int index, {required bool inFirstRow, required bool disableScale}) {
          final item = itemAt(index);
          if (item == null) {
            onSkeletonVisible?.call(index);
            return const SkeletonMediaCard();
          }
          final focusNode = index == 0 ? firstItemFocusNode : getGridItemFocusNode(index, prefix: 'detail_grid_item');
          return FocusableMediaCard(
            key: Key(item.id),
            item: item,
            focusNode: focusNode,
            disableScale: disableScale,
            onRefresh: onRefresh,
            collectionId: collectionId,
            onListRefresh: onListRefresh,
            onNavigateUp: inFirstRow ? navigateToAppBar : null,
            onBack: handleBackFromContent,
            onFocusChange: (hasFocus) => trackGridItemFocus(index, hasFocus),
          );
        }

        if (isListMode) {
          return SliverPadding(
            padding: const EdgeInsets.all(8),
            sliver: SliverList.builder(
              itemCount: totalItems,
              itemBuilder: (context, index) => buildTile(index, inFirstRow: index == 0, disableScale: true),
            ),
          );
        }

        final maxExtent = GridSizeCalculator.getMaxCrossAxisExtent(context, libraryDensity);
        return SliverPadding(
          padding: const EdgeInsets.all(8),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              final columnCount = GridSizeCalculator.getColumnCount(constraints.crossAxisExtent, maxExtent);
              return SliverGrid.builder(
                gridDelegate: MediaGridDelegate.createDelegate(context: context, density: libraryDensity),
                itemCount: totalItems,
                itemBuilder: (context, index) => buildTile(
                  index,
                  inFirstRow: GridSizeCalculator.isFirstRow(index, columnCount),
                  disableScale: false,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
