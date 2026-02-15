import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../focus/dpad_navigator.dart';
import '../focus/input_mode_tracker.dart';
import '../focus/key_event_utils.dart';
import '../mixins/grid_focus_node_mixin.dart';
import '../providers/settings_provider.dart';
import '../utils/grid_size_calculator.dart';
import '../widgets/app_icon.dart';
import '../widgets/focusable_media_card.dart';
import '../widgets/media_grid_delegate.dart';

/// Configuration for app bar buttons
class AppBarButtonConfig {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  const AppBarButtonConfig({required this.icon, required this.tooltip, required this.onPressed, this.color});
}

/// Mixin that provides common focus navigation functionality for detail screens.
/// Handles app bar focus, back navigation, scroll-to-top, and grid item focus management.
///
/// Classes using this mixin must also use [GridFocusNodeMixin].
mixin FocusableDetailScreenMixin<T extends StatefulWidget> on State<T>, GridFocusNodeMixin<T> {
  // Scroll controller for scrolling to top when app bar is focused
  final ScrollController scrollController = ScrollController();

  // App bar focus nodes
  final FocusNode playButtonFocusNode = FocusNode(debugLabel: 'detail_play');
  final FocusNode shuffleButtonFocusNode = FocusNode(debugLabel: 'detail_shuffle');
  final FocusNode deleteButtonFocusNode = FocusNode(debugLabel: 'detail_delete');

  // Grid item focus
  final FocusNode firstItemFocusNode = FocusNode(debugLabel: 'detail_first_item');

  // App bar focus state
  bool isAppBarFocused = false;
  int appBarFocusedButton = 0; // 0=play, 1=shuffle, 2=delete (or less if fewer buttons)

  // Flag to prevent PopScope from exiting when BACK was handled by a key handler
  bool backHandledByKeyEvent = false;

  /// Number of app bar buttons (override if different from 3)
  int get appBarButtonCount => 3;

  /// Called when items are available and we want to check if focus should be set
  bool get hasItems;

  /// Called to get the list of app bar button configurations
  List<AppBarButtonConfig> getAppBarButtons();

  /// Dispose focus-related resources. Call this from your dispose() method.
  void disposeFocusResources() {
    scrollController.dispose();
    playButtonFocusNode.dispose();
    shuffleButtonFocusNode.dispose();
    deleteButtonFocusNode.dispose();
    firstItemFocusNode.dispose();
    disposeGridFocusNodes();
  }

  /// Navigate from content to app bar
  void navigateToAppBar() {
    setState(() {
      isAppBarFocused = true;
      appBarFocusedButton = 0;
    });
    _focusAppBarButton(0);
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

  /// Focus a specific app bar button by index
  void _focusAppBarButton(int index) {
    switch (index) {
      case 0:
        playButtonFocusNode.requestFocus();
        break;
      case 1:
        shuffleButtonFocusNode.requestFocus();
        break;
      case 2:
        deleteButtonFocusNode.requestFocus();
        break;
    }
  }

  /// Handle key events when app bar is focused
  KeyEventResult handleAppBarKeyEvent(FocusNode _, KeyEvent event) {
    final key = event.logicalKey;
    final maxButton = appBarButtonCount - 1;

    final backResult = handleBackKeyAction(event, () => Navigator.pop(context));
    if (backResult != KeyEventResult.ignored) {
      return backResult;
    }

    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (key.isLeftKey && appBarFocusedButton > 0) {
      setState(() => appBarFocusedButton--);
      _focusAppBarButton(appBarFocusedButton);
      return KeyEventResult.handled;
    }
    if (key.isRightKey && appBarFocusedButton < maxButton) {
      setState(() => appBarFocusedButton++);
      _focusAppBarButton(appBarFocusedButton);
      return KeyEventResult.handled;
    }
    if (key.isDownKey) {
      // Return focus to grid
      navigateToGrid();
      return KeyEventResult.handled;
    }
    if (key.isSelectKey) {
      final buttons = getAppBarButtons();
      if (appBarFocusedButton < buttons.length) {
        buttons[appBarFocusedButton].onPressed();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Build focusable app bar action widgets
  List<Widget> buildFocusableAppBarActions() {
    final colorScheme = Theme.of(context).colorScheme;
    final isKeyboardMode = InputModeTracker.isKeyboardMode(context);
    final buttons = getAppBarButtons();

    return buttons.asMap().entries.map((entry) {
      final index = entry.key;
      final config = entry.value;
      final isFocused = isKeyboardMode && isAppBarFocused && appBarFocusedButton == index;

      FocusNode focusNode;
      switch (index) {
        case 0:
          focusNode = playButtonFocusNode;
          break;
        case 1:
          focusNode = shuffleButtonFocusNode;
          break;
        case 2:
          focusNode = deleteButtonFocusNode;
          break;
        default:
          focusNode = FocusNode();
      }

      return Focus(
        focusNode: focusNode,
        onKeyEvent: handleAppBarKeyEvent,
        child: Container(
          decoration: isFocused
              ? BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.all(Radius.circular(20)),
                )
              : null,
          child: IconButton(
            icon: AppIcon(config.icon, fill: 1),
            tooltip: config.tooltip,
            onPressed: config.onPressed,
            color: config.color,
          ),
        ),
      );
    }).toList();
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
