import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../focus/focusable_action_bar.dart';
import '../focus/input_mode_tracker.dart';
import '../focus/key_event_utils.dart';
import '../mixins/grid_focus_node_mixin.dart';
import '../providers/settings_provider.dart';
import '../utils/grid_size_calculator.dart';
import '../widgets/focusable_media_card.dart';
import '../widgets/media_grid_delegate.dart';

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
    actionBarKey.currentState?.getFocusNode(0).requestFocus();
    // Scroll to top to show the app bar
    scrollController.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  /// Handle BACK key from content - navigate to app bar and set flag to prevent PopScope exit
  void handleBackFromContent() {
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

    if (targetIndex == 0) {
      firstItemFocusNode.requestFocus();
    } else {
      getGridItemFocusNode(targetIndex, prefix: 'detail_grid_item').requestFocus();
    }
  }

  /// Handle back navigation for PopScope. Returns true if should pop.
  bool handleBackNavigation() {
    // If BACK was already handled by a key event, don't pop
    if (backHandledByKeyEvent) {
      backHandledByKeyEvent = false;
      return false;
    }

    if (isAppBarFocused) {
      // Already on app bar, allow exit
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
    required void Function(String ratingKey) onRefresh,
    String? collectionId,
    VoidCallback? onListRefresh,
  }) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        final maxExtent = GridSizeCalculator.getMaxCrossAxisExtent(context, settingsProvider.libraryDensity);
        return SliverPadding(
          padding: const EdgeInsets.all(8),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              final columnCount = GridSizeCalculator.getColumnCount(constraints.crossAxisExtent, maxExtent);
              return SliverGrid.builder(
                gridDelegate: MediaGridDelegate.createDelegate(
                  context: context,
                  density: settingsProvider.libraryDensity,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final inFirstRow = GridSizeCalculator.isFirstRow(index, columnCount);
                  final focusNode = index == 0
                      ? firstItemFocusNode
                      : getGridItemFocusNode(index, prefix: 'detail_grid_item');

                  return FocusableMediaCard(
                    key: Key(item.ratingKey),
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
}
