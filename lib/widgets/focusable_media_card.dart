import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../focus/dpad_navigator.dart';
import '../focus/focus_theme.dart';
import '../focus/input_mode_tracker.dart';
import 'media_card.dart';

/// A focusable wrapper for MediaCard that handles D-pad navigation.
///
/// Wraps MediaCard with focus handling for TV/desktop navigation:
/// - Shows scale + border decoration when focused
/// - Handles SELECT key for activation
/// - Accepts optional external focusNode for programmatic focus control
class FocusableMediaCard extends StatefulWidget {
  final dynamic item; // PlexMetadata or PlexPlaylist
  final double? width;
  final double? height;
  final void Function(String ratingKey)? onRefresh;
  final VoidCallback? onRemoveFromContinueWatching;
  final VoidCallback? onListRefresh;
  final bool forceGridMode;
  final bool isInContinueWatching;
  final String? collectionId;

  /// Optional external focus node for programmatic focus control.
  /// If not provided, an internal focus node is created.
  final FocusNode? focusNode;

  /// Called when the user presses UP and there's no focusable item above.
  /// Used to navigate from the top row to filter chips.
  final VoidCallback? onNavigateUp;

  /// Called when the user presses BACK.
  /// Used to navigate from tab content to tab bar.
  final VoidCallback? onBack;

  const FocusableMediaCard({
    super.key,
    required this.item,
    this.width,
    this.height,
    this.onRefresh,
    this.onRemoveFromContinueWatching,
    this.onListRefresh,
    this.forceGridMode = false,
    this.isInContinueWatching = false,
    this.collectionId,
    this.focusNode,
    this.onNavigateUp,
    this.onBack,
  });

  @override
  State<FocusableMediaCard> createState() => _FocusableMediaCardState();
}

class _FocusableMediaCardState extends State<FocusableMediaCard> {
  FocusNode? _internalFocusNode;
  bool _isFocused = false;

  // Key for accessing MediaCard's state
  final GlobalKey<MediaCardState> _mediaCardKey = GlobalKey();

  // Long-press detection for SELECT key
  Timer? _longPressTimer;
  bool _isSelectKeyDown = false;
  static const _longPressDuration = Duration(milliseconds: 500);

  FocusNode get _focusNode {
    // Use external focus node if provided, otherwise use internal
    return widget.focusNode ??
        (_internalFocusNode ??= FocusNode(
          debugLabel: 'focusable_media_card_${widget.item.ratingKey}',
        ));
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(FocusableMediaCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle focus node changes
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChange);
      _focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _focusNode.removeListener(_onFocusChange);
    // Only dispose the internal focus node, not external ones
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) {
      final hasFocus = _focusNode.hasFocus;
      setState(() => _isFocused = hasFocus);

      // Scroll to center when gaining focus
      if (hasFocus) {
        _scrollIntoView();
      }
    }
  }

  /// Scrolls this card into view, centering it vertically in the viewport.
  /// Only scrolls if the item is outside the "comfortable zone" (middle 60%)
  /// to prevent jitter when navigating horizontally within the same row.
  void _scrollIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isFocused) return;

      final renderObject = context.findRenderObject();
      if (renderObject == null) return;

      // Get the scrollable ancestor
      final scrollable = Scrollable.maybeOf(context);
      if (scrollable == null) return;

      final viewport = scrollable.context.findRenderObject() as RenderBox?;
      if (viewport == null) return;

      // Get item's position relative to viewport
      final itemBox = renderObject as RenderBox;
      final itemPosition = itemBox.localToGlobal(
        Offset.zero,
        ancestor: viewport,
      );

      // Check if item is already in the comfortable zone
      final viewportHeight = viewport.size.height;
      final itemHeight = itemBox.size.height;
      final itemVerticalCenter = itemPosition.dy + itemHeight / 2;

      // Define comfortable zone - if item center is within middle 60% of viewport, don't scroll
      final comfortZoneTop = viewportHeight * 0.2;
      final comfortZoneBottom = viewportHeight * 0.8;

      if (itemVerticalCenter >= comfortZoneTop &&
          itemVerticalCenter <= comfortZoneBottom) {
        // Item is in comfortable zone, no need to scroll
        return;
      }

      // Item is outside comfortable zone, scroll to center
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;

    // Handle SELECT key with long-press detection
    if (key.isSelectKey) {
      if (event is KeyDownEvent) {
        // Only start timer on initial press, not repeats
        if (!_isSelectKeyDown) {
          _isSelectKeyDown = true;
          _longPressTimer?.cancel();
          _longPressTimer = Timer(_longPressDuration, () {
            // Long press detected - show context menu immediately
            if (mounted) {
              _mediaCardKey.currentState?.showContextMenu();
            }
          });
        }
        return KeyEventResult.handled;
      } else if (event is KeyRepeatEvent) {
        // Consume repeat events to prevent system sounds
        return KeyEventResult.handled;
      } else if (event is KeyUpEvent) {
        final timerWasActive = _longPressTimer?.isActive ?? false;
        _longPressTimer?.cancel();
        if (timerWasActive && _isSelectKeyDown) {
          // Timer still active - short press, trigger tap
          _mediaCardKey.currentState?.handleTap();
        }
        // If timer already fired, context menu was shown - do nothing on key up
        _isSelectKeyDown = false;
        return KeyEventResult.handled;
      }
    }

    // Ignore key repeat events for other keys
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    // Context menu key shows context menu
    if (key.isContextMenuKey) {
      _mediaCardKey.currentState?.showContextMenu();
      return KeyEventResult.handled;
    }

    // UP arrow - if callback provided, navigate up (to filter chips)
    if (key == LogicalKeyboardKey.arrowUp && widget.onNavigateUp != null) {
      widget.onNavigateUp!();
      return KeyEventResult.handled;
    }

    // BACK key - navigate to tab bar
    if (key.isBackKey && widget.onBack != null) {
      widget.onBack!();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final duration = FocusTheme.getAnimationDuration(context);
    // Only show focus effects during keyboard/d-pad navigation
    final showFocus = _isFocused && InputModeTracker.isKeyboardMode(context);

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: AnimatedScale(
        scale: showFocus ? FocusTheme.focusScale : 1.0,
        duration: duration,
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: duration,
          curve: Curves.easeOutCubic,
          decoration: FocusTheme.focusDecoration(
            context,
            isFocused: showFocus,
            borderRadius: FocusTheme.defaultBorderRadius,
          ),
          child: MediaCard(
            key: _mediaCardKey,
            item: widget.item,
            width: widget.width,
            height: widget.height,
            onRefresh: widget.onRefresh,
            onRemoveFromContinueWatching: widget.onRemoveFromContinueWatching,
            onListRefresh: widget.onListRefresh,
            forceGridMode: widget.forceGridMode,
            isInContinueWatching: widget.isInContinueWatching,
            collectionId: widget.collectionId,
          ),
        ),
      ),
    );
  }
}
