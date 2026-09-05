import 'package:flutter/material.dart';
import '../focus/focusable_action_bar.dart';
import '../focus/input_mode_tracker.dart';
import '../i18n/strings.g.dart';
import '../media/media_item.dart';
import '../mixins/grid_focus_node_mixin.dart';
import '../services/settings_service.dart';
import '../utils/platform_detector.dart';
import '../widgets/ios_status_bar_tap_scroll_to_top.dart';
import '../widgets/settings_builder.dart';
import '../widgets/focusable_media_card.dart';
import '../widgets/media_card_sliver_layout.dart';
import '../widgets/overlay_sheet.dart';
import '../widgets/skeleton_media_card.dart';
import '../widgets/system_bottom_inset.dart';

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

  /// Whether the mounted app bar has actions. Derived from the bar itself so it
  /// is safe in callbacks: [getAppBarActions] may read providers with
  /// `context.select`, which is only legal during build.
  bool get hasAppBarActions => actionBarKey.currentState?.widget.actions.isNotEmpty ?? false;

  /// Back handler for focused content (grid cards, track rows): the content
  /// widget's gate consumes the press and moves focus to the app bar, or pops
  /// the route when there is no app bar to move to. Decided at press time, so a
  /// bar mounted after the content was built is still honored.
  void onBackFromContent() {
    if (hasAppBarActions) {
      navigateToAppBar();
    } else if (mounted) {
      Navigator.pop(context);
    }
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
  /// host whose route back (key or system) runs [handleBackNavigation], plus a
  /// Scaffold with a CustomScrollView bound as the primary scroll view. Callers build
  /// the slivers themselves (typically
  /// `[appBar, ...header, ...buildStateSlivers(), grid]`); a trailing
  /// [SliverSystemBottomInset] is appended so the last row clears the system
  /// navigation bar. Screens that add their own trailing spacer (the music
  /// detail screens reserve the floating mini-player) stack on top of it.
  ///
  /// [behind] and [above] are painted in a Stack under and over the scroll
  /// view — artwork that must be taller than the header sliver, or chrome
  /// pinned to the viewport. Both are usually [Positioned].
  Widget buildDetailScaffold({
    required List<Widget> slivers,
    List<Widget> behind = const [],
    List<Widget> above = const [],
  }) {
    Widget body = CustomScrollView(primary: true, slivers: [...slivers, const SliverSystemBottomInset()]);
    if (behind.isNotEmpty || above.isNotEmpty) {
      body = Stack(children: [...behind, body, ...above]);
    }
    return PrimaryScrollController(
      controller: scrollController,
      child: IosStatusBarTapScrollToTop(
        controller: scrollController,
        child: OverlaySheetHost(
          canPop: PlatformDetector.isHandheldIOS(context),
          onBack: () {
            if (handleBackNavigation() && mounted) Navigator.pop(context);
          },
          child: Scaffold(body: body),
        ),
      ),
    );
  }

  /// The route's back policy, for key and system back alike: pop once the app
  /// bar is focused (or there is none); otherwise focus the app bar first.
  /// Returns true if the route should pop.
  bool handleBackNavigation() {
    if (isAppBarFocused || !hasAppBarActions) return true;
    navigateToAppBar();
    return false;
  }

  /// Build focusable app bar action widgets. The bar handles no Back key of its
  /// own: a press with the bar focused bubbles to the route, whose PopScope
  /// runs [handleBackNavigation] (true once the bar is focused) and pops.
  List<Widget> buildFocusableAppBarActions() {
    return [
      FocusableActionBar(
        key: actionBarKey,
        onNavigateDown: navigateToGrid,
        onFocusChange: (hasFocus) {
          if (hasFocus && !isAppBarFocused) setState(() => isAppBarFocused = true);
        },
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
  ///
  /// Fully-loaded case of [buildSparseFocusableGrid]: every slot resolves to an
  /// item, so the skeleton branch is unreachable.
  Widget buildFocusableGrid({
    required List<MediaItem> items,
    required void Function(MediaItem source) onRefresh,
    String? collectionId,
    VoidCallback? onListRefresh,
    CardShape? shape,
    int indexOffset = 0,
  }) {
    return buildSparseFocusableGrid(
      totalItems: items.length,
      itemAt: (index) => items[index],
      onRefresh: onRefresh,
      collectionId: collectionId,
      onListRefresh: onListRefresh,
      shape: shape,
      indexOffset: indexOffset,
    );
  }

  /// Sparse-loading counterpart of [buildFocusableGrid]. Renders [totalItems]
  /// slots; for each, [itemAt] returns the loaded item or null if not yet
  /// fetched. Null slots render a skeleton and invoke [onSkeletonVisible] so
  /// the caller can kick off a page fetch containing that index.
  ///
  /// [indexOffset] shifts this grid's slots into the screen-global focus
  /// index space (focus nodes and [lastFocusedGridIndex] are keyed 0..n-1
  /// across every grid on the screen). Screens that stack several titled
  /// grids pass the running total; single-grid screens keep the default 0.
  /// With an offset, up-navigation from this grid's first row falls through
  /// to framework traversal (crossing into the previous section's grid)
  /// instead of jumping to the app bar.
  Widget buildSparseFocusableGrid({
    required int totalItems,
    required MediaItem? Function(int index) itemAt,
    required void Function(MediaItem source) onRefresh,
    void Function(int index)? onSkeletonVisible,
    String? collectionId,
    VoidCallback? onListRefresh,
    CardShape? shape,
    int indexOffset = 0,
  }) {
    final onBack = onBackFromContent;
    return SettingsBuilder(
      prefs: const [SettingsService.viewMode, SettingsService.libraryDensity, SettingsService.tvFullCardLayout],
      builder: (context) {
        final svc = SettingsService.instance;
        final viewMode = svc.read(SettingsService.viewMode);
        final libraryDensity = svc.read(SettingsService.libraryDensity);
        final fullCardLayout = PlatformDetector.isTV() && svc.read(SettingsService.tvFullCardLayout);
        final useFullCardLayout = fullCardLayout && shape != CardShape.square;

        Widget buildTile(MediaCardSliverPosition position) {
          final index = position.index;
          final globalIndex = index + indexOffset;
          final item = itemAt(index);
          if (item == null) {
            onSkeletonVisible?.call(index);
            return const SkeletonMediaCard();
          }
          final focusNode = _focusNodeForIndex(globalIndex);
          return FocusableMediaCard(
            key: Key(item.id),
            item: item,
            focusNode: focusNode,
            semanticValue: _semanticPosition(position),
            disableScale: position.disableScale,
            onRefresh: onRefresh,
            collectionId: collectionId,
            onListRefresh: onListRefresh,
            fullBleedImage: useFullCardLayout && position.isGrid,
            cardShapeOverride: shape,
            // The first section's first row reaches the app bar; later
            // sections fall through to traversal, which enters the previous
            // section's grid.
            onNavigateUp: position.isFirstRow && indexOffset == 0 ? navigateToAppBar : null,
            onBack: onBack,
            onFocusChange: (hasFocus) => trackGridItemFocus(globalIndex, hasFocus),
          );
        }

        return MediaCardSliverLayout(
          viewMode: viewMode,
          itemCount: totalItems,
          density: libraryDensity,
          padding: const EdgeInsets.all(8),
          fullBleedImage: useFullCardLayout,
          shape: shape,
          itemBuilder: (context, position) => buildTile(position),
        );
      },
    );
  }

  String _semanticPosition(MediaCardSliverPosition position) {
    if (!position.isGrid) {
      return t.accessibility.rowPosition(row: position.index + 1, rowCount: position.itemCount);
    }

    final rowCount = (position.itemCount + position.columnCount - 1) ~/ position.columnCount;
    return t.accessibility.rowColumnPosition(
      row: position.index ~/ position.columnCount + 1,
      rowCount: rowCount,
      column: position.index % position.columnCount + 1,
      columnCount: position.columnCount,
    );
  }
}
