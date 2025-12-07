import 'package:flutter/material.dart';

import '../focus/focusable_wrapper.dart';
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
  // Key for accessing MediaCard's state
  final GlobalKey<MediaCardState> _mediaCardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return FocusableWrapper(
      focusNode: widget.focusNode,
      onSelect: () => _mediaCardKey.currentState?.handleTap(),
      onLongPress: () => _mediaCardKey.currentState?.showContextMenu(),
      onNavigateUp: widget.onNavigateUp,
      onBack: widget.onBack,
      enableLongPress: true,
      useComfortableZone: true,
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
      ),
    );
  }
}
