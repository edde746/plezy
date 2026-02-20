import 'package:flutter/material.dart';

import '../focus/focusable_wrapper.dart';
import '../utils/platform_detector.dart';
import 'media_card.dart';

/// A focusable wrapper for MediaCard that handles D-pad navigation.
///
/// Wraps MediaCard with focus handling for TV/desktop navigation:
/// - Shows scale + border decoration when focused
/// - Handles SELECT key for activation with long-press detection
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

  /// True for downloaded content without server access
  final bool isOffline;

  /// True when in a hub with mixed content (movies + episodes)
  final bool mixedHubContext;

  /// Optional external focus node for programmatic focus control.
  /// If not provided, an internal focus node is created.
  final FocusNode? focusNode;

  /// Called when the user presses UP and there's no focusable item above.
  /// Used to navigate from the top row to filter chips.
  final VoidCallback? onNavigateUp;

  /// Called when the user presses LEFT and there's no focusable item to the left.
  /// Used to navigate from the first column to the sidebar.
  final VoidCallback? onNavigateLeft;

  /// Called when the user presses RIGHT and there's no focusable item to the right.
  /// Used to navigate from the last column to the alpha jump bar.
  final VoidCallback? onNavigateRight;

  /// Called when the user presses BACK.
  /// Used to navigate from tab content to tab bar.
  final VoidCallback? onBack;

  /// Called when focus changes.
  /// Used to track which grid item was last focused.
  final ValueChanged<bool>? onFocusChange;

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
    this.isOffline = false,
    this.mixedHubContext = false,
    this.focusNode,
    this.onNavigateUp,
    this.onNavigateLeft,
    this.onNavigateRight,
    this.onBack,
    this.onFocusChange,
  });

  @override
  State<FocusableMediaCard> createState() => _FocusableMediaCardState();
}

class _FocusableMediaCardState extends State<FocusableMediaCard> {
  // Key for accessing MediaCard's state
  final GlobalKey<MediaCardState> _mediaCardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return FocusableWrapper(
      focusNode: widget.focusNode,
      onSelect: () => _mediaCardKey.currentState?.handleTap(),
      onLongPress: () => _mediaCardKey.currentState?.showContextMenu(),
      onNavigateUp: widget.onNavigateUp,
      onNavigateLeft: widget.onNavigateLeft,
      onNavigateRight: widget.onNavigateRight,
      onBack: widget.onBack,
      onFocusChange: widget.onFocusChange,
      enableLongPress: true,
      useComfortableZone: !PlatformDetector.isTV(), // Always center on TV
      scrollAlignment: 0.5,
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
        isOffline: widget.isOffline,
        mixedHubContext: widget.mixedHubContext,
      ),
    );
  }
}
