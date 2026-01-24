import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../focus/dpad_navigator.dart';
import '../focus/input_mode_tracker.dart';
import '../widgets/app_icon.dart';

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
mixin FocusableDetailScreenMixin<T extends StatefulWidget> on State<T> {
  // Scroll controller for scrolling to top when app bar is focused
  final ScrollController scrollController = ScrollController();

  // App bar focus nodes
  final FocusNode playButtonFocusNode = FocusNode(debugLabel: 'detail_play');
  final FocusNode shuffleButtonFocusNode = FocusNode(debugLabel: 'detail_shuffle');
  final FocusNode deleteButtonFocusNode = FocusNode(debugLabel: 'detail_delete');

  // Grid item focus
  final FocusNode firstItemFocusNode = FocusNode(debugLabel: 'detail_first_item');
  final Map<int, FocusNode> gridItemFocusNodes = {};

  // Focus restoration
  int? lastFocusedIndex;
  int contentVersion = 0;
  int lastFocusedContentVersion = 0;

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
    for (final node in gridItemFocusNodes.values) {
      node.dispose();
    }
    gridItemFocusNodes.clear();
  }

  /// Get or create a focus node for a grid item at the given index
  FocusNode getGridItemFocusNode(int index) {
    return gridItemFocusNodes.putIfAbsent(index, () => FocusNode(debugLabel: 'detail_grid_item_$index'));
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

    // Check if we should restore focus to the last focused item
    final shouldRestoreFocus =
        lastFocusedIndex != null && lastFocusedContentVersion == contentVersion && lastFocusedIndex! >= 0;

    final targetIndex = shouldRestoreFocus ? lastFocusedIndex! : 0;

    setState(() {
      isAppBarFocused = false;
    });

    if (targetIndex == 0) {
      firstItemFocusNode.requestFocus();
    } else {
      getGridItemFocusNode(targetIndex).requestFocus();
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
  KeyEventResult handleAppBarKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    final maxButton = appBarButtonCount - 1;

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
    if (key.isBackKey) {
      // Already on app bar, exit the screen
      Navigator.pop(context);
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
              ? BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(20))
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

  /// Track focus on a grid item. Call from onFocusChange of grid items.
  void trackGridItemFocus(int index, bool hasFocus) {
    if (hasFocus) {
      lastFocusedIndex = index;
      lastFocusedContentVersion = contentVersion;
    }
  }
}
