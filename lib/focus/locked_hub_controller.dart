import 'package:flutter/material.dart';

/// Controller for locked hub navigation.
/// Manages visual focus index separately from Flutter's focus system.
class LockedHubController extends ChangeNotifier {
  LockedHubController({
    required this.itemExtent,
    this.leadingPadding = 12.0,
    ScrollController? scrollController,
  }) : scrollController = scrollController ?? ScrollController();

  /// Width of each item (including padding/margin)
  final double itemExtent;

  /// Leading padding before first item
  final double leadingPadding;

  /// Scroll controller for the list
  final ScrollController scrollController;

  int _focusedIndex = 0;
  int _itemCount = 0;
  bool _hasFocus = false;

  /// Current visual focus index
  int get focusedIndex => _focusedIndex;

  /// Number of items in the hub
  int get itemCount => _itemCount;

  /// Whether the hub currently has focus
  bool get hasFocus => _hasFocus;

  /// Update the item count (call when hub items change)
  void updateItemCount(int count) {
    if (_itemCount != count) {
      _itemCount = count;
      // Clamp focus index if it's now out of bounds
      if (_focusedIndex >= count && count > 0) {
        _focusedIndex = count - 1;
        notifyListeners();
      }
    }
  }

  /// Set hub focus state
  void setHasFocus(bool value) {
    if (_hasFocus != value) {
      _hasFocus = value;
      notifyListeners();
    }
  }

  /// Focus a specific index, scrolling to it
  void focusIndex(int index, {bool animate = true}) {
    if (_itemCount == 0) return;

    final clamped = index.clamp(0, _itemCount - 1);
    if (_focusedIndex != clamped) {
      _focusedIndex = clamped;
      notifyListeners();
    }
    _scrollToIndex(clamped, animate: animate);
  }

  /// Move focus left, return false if at boundary
  bool moveLeft() {
    if (_focusedIndex > 0) {
      focusIndex(_focusedIndex - 1);
      return true;
    }
    return false;
  }

  /// Move focus right, return false if at boundary
  bool moveRight() {
    if (_focusedIndex < _itemCount - 1) {
      focusIndex(_focusedIndex + 1);
      return true;
    }
    return false;
  }

  /// Scroll to center the item at the given index
  void _scrollToIndex(int index, {bool animate = true}) {
    if (!scrollController.hasClients) return;

    final viewport = scrollController.position.viewportDimension;
    final targetCenter =
        leadingPadding + (index * itemExtent) + (itemExtent / 2);
    final desiredOffset = (targetCenter - (viewport / 2)).clamp(
      0.0,
      scrollController.position.maxScrollExtent,
    );

    if (animate) {
      scrollController.animateTo(
        desiredOffset,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    } else {
      scrollController.jumpTo(desiredOffset);
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}

/// Manages focus memory for hub navigation.
///
/// Tracks two things:
/// 1. Per-hub memory: Each hub remembers which item was last focused
/// 2. Global column hint: When entering a hub that hasn't been visited,
///    we use the column position from the last focused hub as a hint
class HubFocusMemory {
  static final Map<String, int> _perHubMemory = {};
  static int _lastColumnHint = 0;

  /// Remember the focused index for a specific hub
  static void setForHub(String hubKey, int index) {
    _perHubMemory[hubKey] = index;
    _lastColumnHint = index;
  }

  /// Get the remembered index for a hub, or fall back to column hint
  static int getForHub(String hubKey, int itemCount) {
    if (itemCount <= 0) return 0;

    // If this hub has memory, use it
    if (_perHubMemory.containsKey(hubKey)) {
      return _perHubMemory[hubKey]!.clamp(0, itemCount - 1);
    }

    // Otherwise use the last column hint (clamped to this hub's item count)
    return _lastColumnHint.clamp(0, itemCount - 1);
  }

  /// Clear all memory (e.g., when leaving a screen)
  static void clear() {
    _perHubMemory.clear();
    _lastColumnHint = 0;
  }
}
