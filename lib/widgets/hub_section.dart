import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import '../focus/dpad_navigator.dart';
import '../providers/settings_provider.dart';
import '../services/settings_service.dart' show EpisodePosterMode;
import '../theme/mono_tokens.dart';
import '../utils/layout_constants.dart';
import '../focus/locked_hub_controller.dart';
import '../models/plex_hub.dart';
import '../screens/hub_detail_screen.dart';
import '../utils/media_navigation_helper.dart';
import 'focus_builders.dart';
import 'media_card.dart';
import 'horizontal_scroll_with_arrows.dart';
import '../i18n/strings.g.dart';

/// Shared hub section widget used in both discover and library screens
/// Displays a hub title with icon and a horizontal scrollable list of items
///
/// Uses a "locked" focus pattern where:
/// - A single Focus widget at the hub level intercepts ALL arrow keys
/// - Visual focus index is tracked in state (not Flutter's focus system)
/// - Children render focus visuals based on the passed index
/// - Focus never "escapes" to random elements
class HubSection extends StatefulWidget {
  final PlexHub hub;
  final IconData icon;
  final void Function(String)? onRefresh;
  final VoidCallback? onRemoveFromContinueWatching;
  final bool isInContinueWatching;
  final bool showServerName;

  /// Callback for vertical navigation (up/down). Return true if handled.
  final bool Function(bool isUp)? onVerticalNavigation;

  /// Called when the user presses BACK.
  /// Used to navigate focus back to the tab bar.
  final VoidCallback? onBack;

  /// Called when the user presses LEFT while at the leftmost item.
  /// Used to navigate focus to the side navigation rail.
  final VoidCallback? onNavigateLeft;

  /// Called when the user presses UP while at the topmost item (first hub).
  /// Used to navigate focus to the tab bar.
  final VoidCallback? onNavigateUp;

  const HubSection({
    super.key,
    required this.hub,
    required this.icon,
    this.onRefresh,
    this.onRemoveFromContinueWatching,
    this.isInContinueWatching = false,
    this.showServerName = false,
    this.onVerticalNavigation,
    this.onBack,
    this.onNavigateLeft,
    this.onNavigateUp,
  });

  @override
  State<HubSection> createState() => HubSectionState();
}

class HubSectionState extends State<HubSection> {
  late FocusNode _hubFocusNode;
  final ScrollController _scrollController = ScrollController();

  /// Current visual focus index (not tied to Flutter's focus system)
  int _focusedIndex = 0;

  /// Item extent for scroll calculations
  double _itemExtent = 0;
  static const double _leadingPadding = 12.0;

  @override
  void initState() {
    super.initState();
    _hubFocusNode = FocusNode(debugLabel: 'hub_${widget.hub.hubKey}');
    _hubFocusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(HubSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Clamp focus index if item count changed
    if (widget.hub.items.length != oldWidget.hub.items.length) {
      final maxIndex = widget.hub.items.isEmpty ? 0 : widget.hub.items.length - 1;
      if (_focusedIndex > maxIndex) {
        _focusedIndex = maxIndex;
      }
    }
  }

  @override
  void dispose() {
    _hubFocusNode.removeListener(_onFocusChange);
    _hubFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    // Rebuild to update visual focus state
    if (mounted) setState(() {});
  }

  /// Request focus on this hub at a specific item index
  void requestFocusAt(int index) {
    if (widget.hub.items.isEmpty) return;

    final clamped = index.clamp(0, widget.hub.items.length - 1);
    _focusedIndex = clamped;
    // Remember this position for this specific hub
    HubFocusMemory.setForHub(widget.hub.hubKey, clamped);
    _scrollToIndex(clamped);
    _hubFocusNode.requestFocus();
    if (mounted) setState(() {});

    // Scroll the hub into view in the parent scroll view
    _scrollHubIntoView();
  }

  /// Request focus using the stored memory for this hub
  void requestFocusFromMemory() {
    final index = HubFocusMemory.getForHub(widget.hub.hubKey, widget.hub.items.length);
    requestFocusAt(index);
  }

  /// Scroll this hub into view in the parent scroll view
  void _scrollHubIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.3, // Position hub near top third of viewport
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  /// Check if this hub currently has focus
  bool get hasFocusedItem => _hubFocusNode.hasFocus;

  /// Get the number of items in this hub
  int get itemCount => widget.hub.items.length;

  /// Scroll to center the item at the given index
  void _scrollToIndex(int index, {bool animate = true}) {
    if (!_scrollController.hasClients || _itemExtent <= 0) return;

    final viewport = _scrollController.position.viewportDimension;
    final targetCenter = _leadingPadding + (index * _itemExtent) + (_itemExtent / 2);
    final desiredOffset = (targetCenter - (viewport / 2)).clamp(0.0, _scrollController.position.maxScrollExtent);

    if (animate) {
      _scrollController.animateTo(desiredOffset, duration: const Duration(milliseconds: 150), curve: Curves.easeOut);
    } else {
      _scrollController.jumpTo(desiredOffset);
    }
  }

  /// Handle ALL key events at the hub level
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // Handle key down and repeat events
    if (!event.isActionable) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    final itemCount = widget.hub.items.length;
    if (itemCount == 0) return KeyEventResult.ignored;

    // Left: move to previous item, ALWAYS consume to prevent escape
    if (key.isLeftKey) {
      if (_focusedIndex > 0) {
        _focusedIndex--;
        HubFocusMemory.setForHub(widget.hub.hubKey, _focusedIndex);
        _scrollToIndex(_focusedIndex);
        setState(() {});
      } else if (widget.onNavigateLeft != null) {
        // At leftmost item - navigate to sidebar
        widget.onNavigateLeft!();
      }
      return KeyEventResult.handled;
    }

    // Right: move to next item, ALWAYS consume to prevent escape
    if (key.isRightKey) {
      if (_focusedIndex < itemCount - 1) {
        _focusedIndex++;
        HubFocusMemory.setForHub(widget.hub.hubKey, _focusedIndex);
        _scrollToIndex(_focusedIndex);
        setState(() {});
      }
      return KeyEventResult.handled;
    }

    // Up/Down: delegate to parent for vertical hub navigation, ALWAYS consume
    if (key.isUpKey) {
      final handled = widget.onVerticalNavigation?.call(true) ?? false;
      // If not handled (at top boundary) and we have onNavigateUp, call it
      if (!handled && widget.onNavigateUp != null) {
        widget.onNavigateUp!();
      }
      return KeyEventResult.handled;
    }
    if (key.isDownKey) {
      widget.onVerticalNavigation?.call(false);
      return KeyEventResult.handled;
    }

    // Select: activate the current item
    if (key.isSelectKey) {
      _activateCurrentItem();
      return KeyEventResult.handled;
    }

    // Context menu key: show context menu
    if (key.isContextMenuKey) {
      _showContextMenuForCurrentItem();
      return KeyEventResult.handled;
    }

    // Back key: navigate to tab bar
    if (key.isBackKey && widget.onBack != null) {
      widget.onBack!();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// GlobalKeys for MediaCards to access their state (for context menu)
  final Map<int, GlobalKey<MediaCardState>> _mediaCardKeys = {};

  GlobalKey<MediaCardState> _getMediaCardKey(int index) {
    return _mediaCardKeys.putIfAbsent(index, () => GlobalKey<MediaCardState>());
  }

  void _activateCurrentItem() {
    if (_focusedIndex >= widget.hub.items.length) return;
    final item = widget.hub.items[_focusedIndex];
    _navigateToItem(item);
  }

  void _showContextMenuForCurrentItem() {
    _mediaCardKeys[_focusedIndex]?.currentState?.showContextMenu();
  }

  Future<void> _navigateToItem(dynamic item) async {
    await navigateToMediaItem(context, item, onRefresh: widget.onRefresh, playDirectly: widget.isInContinueWatching);
  }

  void _navigateToHubDetail(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => HubDetailScreen(hub: widget.hub)));
  }

  @override
  Widget build(BuildContext context) {
    final hasFocus = _hubFocusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hub header (NOT focusable - titles should not be focusable)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: ExcludeFocus(
            child: InkWell(
              onTap: widget.hub.more ? () => _navigateToHubDetail(context) : null,
              borderRadius: BorderRadius.circular(tokens(context).radiusSm),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(widget.icon, fill: 1),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.hub.title,
                        style: Theme.of(context).textTheme.titleLarge,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (widget.showServerName && widget.hub.serverName != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.hub.serverName!,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                    if (widget.hub.more) ...[
                      const SizedBox(width: 4),
                      const AppIcon(Symbols.chevron_right_rounded, fill: 1, size: 20),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),

        // Hub items with locked focus control
        if (widget.hub.items.isNotEmpty)
          Focus(
            focusNode: _hubFocusNode,
            onKeyEvent: _handleKeyEvent,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Responsive base card width for posters (2:3 aspect ratio)
                final screenWidth = constraints.maxWidth;
                final baseCardWidth = ScreenBreakpoints.isLargeDesktop(screenWidth)
                    ? 220.0
                    : ScreenBreakpoints.isDesktop(screenWidth)
                    ? 200.0
                    : ScreenBreakpoints.isWideTablet(screenWidth)
                    ? 190.0
                    : 160.0;

                // Get episode poster mode setting
                final episodePosterMode = context.watch<SettingsProvider>().episodePosterMode;

                // Determine hub content type for layout decisions
                final hasEpisodes = widget.hub.items.any((item) => item.usesWideAspectRatio(episodePosterMode));
                final hasNonEpisodes = widget.hub.items.any((item) => !item.usesWideAspectRatio(episodePosterMode));

                // Mixed hub = has both episodes AND non-episodes (like Continue Watching)
                final isMixedHub = hasEpisodes && hasNonEpisodes;

                // Episode-only = all items are episodes with thumbnails
                final isEpisodeOnlyHub = hasEpisodes && !hasNonEpisodes;

                // Use 16:9 for episode-only hubs OR mixed hubs (with episode thumbnail mode)
                final useWideLayout =
                    episodePosterMode == EpisodePosterMode.episodeThumbnail && (isEpisodeOnlyHub || isMixedHub);

                // Card dimensions based on hub type
                const wideCardMultiplier = 1.5;
                final cardWidth = useWideLayout ? baseCardWidth * wideCardMultiplier : baseCardWidth;
                final posterWidth = cardWidth - 16; // 8px padding on each side
                final posterHeight = useWideLayout
                    ? posterWidth *
                          (9 / 16) // 16:9 for wide layout
                    : posterWidth * 1.5; // 2:3 for poster layout

                final containerHeight = posterHeight + 66;
                _itemExtent = cardWidth + 4;

                return SizedBox(
                  height: containerHeight,
                  child: HorizontalScrollWithArrows(
                    controller: _scrollController,
                    builder: (scrollController) => ListView.builder(
                      controller: scrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      itemCount: widget.hub.items.length,
                      itemBuilder: (context, index) {
                        final item = widget.hub.items[index];
                        final isItemFocused = hasFocus && index == _focusedIndex;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: _LockedHubItemWrapper(
                            isFocused: isItemFocused,
                            onTap: () => _onItemTapped(index),
                            onLongPress: () => _mediaCardKeys[index]?.currentState?.showContextMenu(),
                            child: MediaCard(
                              key: _getMediaCardKey(index),
                              item: item,
                              width: cardWidth,
                              height: posterHeight,
                              onRefresh: widget.onRefresh,
                              onRemoveFromContinueWatching: widget.onRemoveFromContinueWatching,
                              forceGridMode: true,
                              isInContinueWatching: widget.isInContinueWatching,
                              mixedHubContext: isMixedHub,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              t.messages.noItemsAvailable,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
      ],
    );
  }

  /// Called when an item is tapped (mouse/touch)
  void _onItemTapped(int index) {
    // Update focus to tapped item and request hub focus
    _focusedIndex = index;
    HubFocusMemory.setForHub(widget.hub.hubKey, index);
    _hubFocusNode.requestFocus();
    setState(() {});
  }
}

/// Wrapper that provides visual focus decoration without using Flutter's focus system.
class _LockedHubItemWrapper extends StatelessWidget {
  final bool isFocused;
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _LockedHubItemWrapper({required this.isFocused, required this.child, this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return FocusBuilders.buildLockedFocusWrapper(
      context: context,
      isFocused: isFocused,
      onTap: onTap,
      onLongPress: onLongPress,
      child: child,
    );
  }
}
