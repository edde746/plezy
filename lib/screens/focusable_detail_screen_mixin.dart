import 'package:flutter/material.dart';
import '../focus/focusable_action_bar.dart';
import '../focus/input_mode_tracker.dart';
import '../focus/key_event_utils.dart';
import '../media/media_item.dart';
import '../media/media_playlist.dart';
import '../mixins/grid_focus_node_mixin.dart';
import '../services/settings_service.dart';
import '../utils/platform_detector.dart';
import '../widgets/ios_status_bar_tap_scroll_to_top.dart';
import '../widgets/settings_builder.dart';
import '../widgets/focusable_media_card.dart';
import '../widgets/media_card_sliver_layout.dart';
import '../widgets/overlay_sheet.dart';
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

  /// Wrap [slivers] in the standard detail-screen scaffold — an overlay-sheet
  /// host that defers route back to [handleBackNavigation], plus a Scaffold
  /// with a CustomScrollView bound as the primary scroll view. Callers build
  /// the slivers themselves (typically
  /// `[appBar, ...header, ...buildStateSlivers(), grid]`).
  Widget buildDetailScaffold({required List<Widget> slivers}) {
    return PrimaryScrollController(
      controller: scrollController,
      child: IosStatusBarTapScrollToTop(
        controller: scrollController,
        child: OverlaySheetHost(
          canPop: PlatformDetector.isHandheldIOS(context),
          onSystemBack: () {
            if (BackKeyCoordinator.consumeIfHandled()) return;
            if (handleBackNavigation() && mounted) {
              Navigator.pop(context);
            }
          },
          child: Scaffold(body: CustomScrollView(primary: true, slivers: slivers)),
        ),
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
        if (InputModeTracker.isKeyboardMode(context, listen: false)) {
          setState(() {
            isAppBarFocused = false;
          });
          firstItemFocusNode.requestFocus();
        }
      });
    }
  }

  /// Build a standard focusable grid sliver for media items.
  /// Used by collection, smart playlist, and music artist detail screens.
  /// [shape] overrides the grid cell silhouette (e.g. [CardShape.square]
  /// for album grids); null keeps the stock poster geometry.
  Widget buildFocusableGrid({
    required List<dynamic> items,
    required void Function(MediaItem source) onRefresh,
    String? collectionId,
    VoidCallback? onListRefresh,
    CardShape? shape,
  }) {
    return SettingsBuilder(
      prefs: const [SettingsService.viewMode, SettingsService.libraryDensity, SettingsService.tvFullCardLayout],
      builder: (context) {
        final svc = SettingsService.instance;
        final viewMode = svc.read(SettingsService.viewMode);
        final libraryDensity = svc.read(SettingsService.libraryDensity);
        final fullCardLayout = PlatformDetector.isTV() && svc.read(SettingsService.tvFullCardLayout);

        return MediaCardSliverLayout(
          viewMode: viewMode,
          itemCount: items.length,
          density: libraryDensity,
          padding: const EdgeInsets.all(8),
          fullBleedImage: fullCardLayout,
          shape: shape,
          itemBuilder: (context, position) {
            final index = position.index;
            final item = items[index];
            final focusNode = _focusNodeForIndex(index);

            return FocusableMediaCard(
              key: Key(_idForItem(item)),
              item: item,
              focusNode: focusNode,
              disableScale: position.disableScale,
              onRefresh: onRefresh,
              collectionId: collectionId,
              onListRefresh: onListRefresh,
              fullBleedImage: fullCardLayout && position.isGrid,
              onNavigateUp: position.isFirstRow ? navigateToAppBar : null,
              onBack: handleBackFromContent,
              onFocusChange: (hasFocus) => trackGridItemFocus(index, hasFocus),
            );
          },
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
    required void Function(MediaItem source) onRefresh,
    void Function(int index)? onSkeletonVisible,
    String? collectionId,
    VoidCallback? onListRefresh,
  }) {
    return SettingsBuilder(
      prefs: const [SettingsService.viewMode, SettingsService.libraryDensity, SettingsService.tvFullCardLayout],
      builder: (context) {
        final svc = SettingsService.instance;
        final viewMode = svc.read(SettingsService.viewMode);
        final libraryDensity = svc.read(SettingsService.libraryDensity);
        final fullCardLayout = PlatformDetector.isTV() && svc.read(SettingsService.tvFullCardLayout);

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
            fullBleedImage: fullCardLayout && !disableScale,
            onNavigateUp: inFirstRow ? navigateToAppBar : null,
            onBack: handleBackFromContent,
            onFocusChange: (hasFocus) => trackGridItemFocus(index, hasFocus),
          );
        }

        return MediaCardSliverLayout(
          viewMode: viewMode,
          itemCount: totalItems,
          density: libraryDensity,
          padding: const EdgeInsets.all(8),
          fullBleedImage: fullCardLayout,
          itemBuilder: (context, position) =>
              buildTile(position.index, inFirstRow: position.isFirstRow, disableScale: position.disableScale),
        );
      },
    );
  }
}
