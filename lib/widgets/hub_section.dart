import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../focus/dpad_navigator.dart';
import '../focus/focus_theme.dart';
import '../focus/input_mode_tracker.dart';
import '../focus/key_event_utils.dart';
import '../services/settings_service.dart';
import 'settings_builder.dart';
import '../utils/grid_size_calculator.dart';
import '../utils/layout_constants.dart';
import '../utils/platform_detector.dart';
import '../theme/mono_tokens.dart';
import '../focus/locked_hub_controller.dart';
import '../media/media_hub.dart';
import '../media/media_item.dart';
import '../mixins/mounted_set_state_mixin.dart';
import '../screens/hub_detail_screen.dart';
import '../screens/main_screen.dart';
import '../utils/media_navigation_helper.dart';
import 'focus_builders.dart';
import 'media_card.dart';
import '../utils/scroll_utils.dart';
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
  final MediaHub hub;
  final IconData icon;
  final void Function(String)? onRefresh;
  final VoidCallback? onRemoveFromContinueWatching;
  final bool isInContinueWatching;
  final bool showServerName;
  final Future<List<MediaItem>> Function()? loadMoreItems;

  /// Reports the current focused media item. Used by TV spotlight layouts.
  final ValueChanged<MediaItem>? onFocusedItemChanged;

  /// Callback for vertical navigation (up/down). Return true if handled.
  final bool Function(bool isUp)? onVerticalNavigation;

  /// Called when the user presses BACK.
  /// Used to navigate focus back to the tab bar.
  final VoidCallback? onBack;

  /// Called when the user presses UP while at the topmost item (first hub).
  /// Used to navigate focus to the tab bar.
  final VoidCallback? onNavigateUp;

  /// Called when the user presses LEFT while at the leftmost item (index 0).
  /// Used to navigate focus to the sidebar.
  final VoidCallback? onNavigateToSidebar;

  /// When true, removes internal horizontal padding (header + list).
  /// Use when the parent already provides edge spacing (e.g. inside Padding(16)).
  final bool inset;

  /// Vertical viewport alignment when this hub is focused.
  final double focusScrollAlignment;

  const HubSection({
    super.key,
    required this.hub,
    required this.icon,
    this.onRefresh,
    this.onRemoveFromContinueWatching,
    this.isInContinueWatching = false,
    this.showServerName = false,
    this.loadMoreItems,
    this.onFocusedItemChanged,
    this.onVerticalNavigation,
    this.onBack,
    this.onNavigateUp,
    this.onNavigateToSidebar,
    this.inset = false,
    this.focusScrollAlignment = 0.3,
  });

  @override
  State<HubSection> createState() => HubSectionState();
}

class HubSectionState extends State<HubSection> with MountedSetStateMixin {
  static const _longPressDuration = Duration(milliseconds: 500);

  late FocusNode _hubFocusNode;
  final ScrollController _scrollController = ScrollController();

  /// Current visual focus index (not tied to Flutter's focus system)
  int _focusedIndex = 0;

  double _itemExtent = 0;
  double _leadingPaddingFor(bool isTv) => widget.inset
      ? 0.0
      : isTv
      ? TvLayoutConstants.shelfHorizontalInset
      : 12.0;
  double get _leadingPadding => _leadingPaddingFor(PlatformDetector.isTV());
  double get _visibleRightInset => MainScreenFocusScope.clippedContentRightInsetOf(context);

  Timer? _longPressTimer;
  bool _isSelectKeyDown = false;
  bool _longPressTriggered = false;

  @override
  void initState() {
    super.initState();
    _hubFocusNode = FocusNode(debugLabel: 'hub_${widget.hub.id}');
    _hubFocusNode.addListener(_onFocusChange);
  }

  /// Total item count including the optional "View All" card
  int get _totalItemCount => widget.hub.items.length + (widget.hub.more ? 1 : 0);

  @override
  void didUpdateWidget(HubSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hub.id != oldWidget.hub.id) {
      _mediaCardKeys.clear();
    } else if (widget.hub.items.length != oldWidget.hub.items.length) {
      _mediaCardKeys.removeWhere((index, _) => index >= widget.hub.items.length);
    }

    if (widget.hub.items.length != oldWidget.hub.items.length) {
      final maxIndex = _totalItemCount == 0 ? 0 : _totalItemCount - 1;
      if (_focusedIndex > maxIndex) {
        _focusedIndex = maxIndex;
      }
    }
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _hubFocusNode.removeListener(_onFocusChange);
    _hubFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    // Reset long press state when focus is lost
    if (!_hubFocusNode.hasFocus) {
      _longPressTimer?.cancel();
      _isSelectKeyDown = false;
      _longPressTriggered = false;
    } else {
      _notifyFocusedItemChanged();
    }
    // ignore: no-empty-block - setState triggers rebuild to update focus styling
    setStateIfMounted(() {});
  }

  /// Request focus on this hub at a specific item index
  void requestFocusAt(int index) {
    if (_totalItemCount == 0) return;

    final clamped = index.clamp(0, _totalItemCount - 1).toInt();
    _focusedIndex = clamped;
    // Remember this position for this specific hub
    HubFocusMemory.setForHub(widget.hub.id, clamped);
    _notifyFocusedItemChanged();
    _scrollToIndex(clamped);
    _hubFocusNode.requestFocus();
    // ignore: no-empty-block - setState triggers rebuild to update focus styling
    setStateIfMounted(() {});

    _scrollHubIntoView();
  }

  /// Request focus using the stored memory for this hub
  void requestFocusFromMemory() {
    final index = HubFocusMemory.getForHub(widget.hub.id, _totalItemCount);
    requestFocusAt(index);
  }

  /// Scroll this hub into view in the parent scroll view
  void _scrollHubIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        alignment: widget.focusScrollAlignment,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  /// Check if this hub currently has focus
  bool get hasFocusedItem => _hubFocusNode.hasFocus;

  /// Get the number of items in this hub
  int get itemCount => _totalItemCount;

  /// Scroll to center the item at the given index
  void _scrollToIndex(int index, {bool animate = true}) {
    scrollListToIndex(
      _scrollController,
      index,
      itemExtent: _itemExtent,
      leadingPadding: _leadingPadding,
      visibleTrailingInset: _visibleRightInset,
      animate: animate,
    );
  }

  /// Handle ALL key events at the hub level
  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    final key = event.logicalKey;

    if (key.isSelectKey) {
      if (event is KeyDownEvent) {
        if (!_isSelectKeyDown) {
          _isSelectKeyDown = true;
          _longPressTriggered = false;
          _longPressTimer?.cancel();
          _longPressTimer = Timer(_longPressDuration, () {
            if (!mounted) return;
            if (_isSelectKeyDown) {
              _longPressTriggered = true;
              SelectKeyUpSuppressor.suppressSelectUntilKeyUp();
              _showContextMenuForCurrentItem();
            }
          });
        }
        return KeyEventResult.handled;
      } else if (event is KeyRepeatEvent) {
        return KeyEventResult.handled;
      } else if (event is KeyUpEvent) {
        final timerWasActive = _longPressTimer?.isActive ?? false;
        _longPressTimer?.cancel();
        if (!_longPressTriggered && timerWasActive && _isSelectKeyDown) {
          _activateCurrentItem();
        }
        _isSelectKeyDown = false;
        _longPressTriggered = false;
        return KeyEventResult.handled;
      }
    }

    if (widget.onBack != null) {
      final backResult = handleBackKeyAction(event, widget.onBack!);
      if (backResult != KeyEventResult.ignored) {
        return backResult;
      }
    }

    // Handle key down and repeat events
    if (!event.isActionable) {
      return KeyEventResult.ignored;
    }

    final totalCount = _totalItemCount;
    if (totalCount == 0) return KeyEventResult.ignored;

    // Left: move to previous item, or navigate to sidebar at left edge
    if (key.isLeftKey) {
      if (_focusedIndex > 0) {
        setState(() {
          _focusedIndex--;
        });
        HubFocusMemory.setForHub(widget.hub.id, _focusedIndex);
        _notifyFocusedItemChanged();
        _scrollToIndex(_focusedIndex);
      } else if (widget.onNavigateToSidebar != null) {
        // At leftmost item: navigate to sidebar
        widget.onNavigateToSidebar!();
      }
      // Always consume to prevent focus escape
      return KeyEventResult.handled;
    }

    // Right: move to next item, ALWAYS consume to prevent escape
    if (key.isRightKey) {
      if (_focusedIndex < totalCount - 1) {
        setState(() {
          _focusedIndex++;
        });
        HubFocusMemory.setForHub(widget.hub.id, _focusedIndex);
        _notifyFocusedItemChanged();
        _scrollToIndex(_focusedIndex);
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

    // Context menu key: show context menu
    if (key.isContextMenuKey) {
      _showContextMenuForCurrentItem();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// GlobalKeys for MediaCards to access their state (for context menu)
  final Map<int, GlobalKey<MediaCardState>> _mediaCardKeys = {};

  GlobalKey<MediaCardState> _getMediaCardKey(int index) {
    return _mediaCardKeys.putIfAbsent(index, () => GlobalKey<MediaCardState>());
  }

  void _notifyFocusedItemChanged() {
    if (_focusedIndex < 0 || _focusedIndex >= widget.hub.items.length) return;
    widget.onFocusedItemChanged?.call(widget.hub.items[_focusedIndex]);
  }

  void _activateCurrentItem() {
    if (_focusedIndex == widget.hub.items.length && widget.hub.more) {
      _navigateToHubDetail(context);
      return;
    }
    if (_focusedIndex >= widget.hub.items.length) return;
    final item = widget.hub.items[_focusedIndex];
    _navigateToItem(item);
  }

  void _showContextMenuForCurrentItem() {
    // No context menu for the "View All" card
    if (_focusedIndex >= widget.hub.items.length) return;
    _mediaCardKeys[_focusedIndex]?.currentState?.showContextMenu();
  }

  Future<void> _navigateToItem(MediaItem item) async {
    await navigateToMediaItem(context, item, onRefresh: widget.onRefresh, playDirectly: widget.isInContinueWatching);
  }

  void _navigateToHubDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HubDetailScreen(
          hub: widget.hub,
          loadItems: widget.loadMoreItems,
          isInContinueWatching: widget.isInContinueWatching,
          onRemoveFromContinueWatching: widget.onRemoveFromContinueWatching,
        ),
      ),
    );
  }

  double _getTvCardWidth(double availableWidth, int density, double leadingPadding) {
    final f = LibraryDensity.factor(density);
    final targetCards = 7.0 - (f * 2.0);
    final usableWidth = (availableWidth - (leadingPadding * 2)).clamp(1.0, double.infinity);
    return (usableWidth / targetCards).clamp(210.0, 340.0);
  }

  @override
  Widget build(BuildContext context) {
    final hasFocus = _hubFocusNode.hasFocus;
    final isKeyboardMode = InputModeTracker.isKeyboardMode(context);
    final isTv = PlatformDetector.isTV();
    final leadingPadding = _leadingPaddingFor(isTv);
    final titleStyle = Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontSize: isTv ? 26 : null, fontWeight: isTv ? FontWeight.w700 : null);

    return Padding(
      padding: EdgeInsets.only(bottom: isTv && !widget.inset ? TvLayoutConstants.shelfVerticalGap : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hub header (NOT focusable - titles should not be focusable)
          Padding(
            padding: widget.inset
                ? EdgeInsets.symmetric(vertical: isTv ? 6 : 2)
                : EdgeInsets.fromLTRB(leadingPadding - 4, isTv ? 6 : 2, 8, isTv ? 8 : 2),
            child: ExcludeFocus(
              child: InkWell(
                mouseCursor: widget.hub.more ? SystemMouseCursors.click : MouseCursor.defer,
                onTap: widget.hub.more ? () => _navigateToHubDetail(context) : null,
                borderRadius: BorderRadius.circular(tokens(context).radiusSm),
                child: Padding(
                  padding: widget.inset
                      ? const EdgeInsets.symmetric(vertical: 2)
                      : const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIcon(widget.icon, fill: 1, size: isTv ? 28 : null),
                      SizedBox(width: isTv ? 12 : 8),
                      Flexible(
                        child: Text(widget.hub.title, style: titleStyle, overflow: TextOverflow.ellipsis, maxLines: 1),
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
                      if (widget.hub.more && !isKeyboardMode) ...[
                        const SizedBox(width: 4),
                        AppIcon(Symbols.chevron_right_rounded, fill: 1, size: isTv ? 26 : 20),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (widget.hub.items.isNotEmpty)
            Focus(
              focusNode: _hubFocusNode,
              onKeyEvent: _handleKeyEvent,
              child: SettingsBuilder(
                prefs: const [SettingsService.libraryDensity, SettingsService.episodePosterMode],
                builder: (context) => LayoutBuilder(
                  builder: (context, constraints) {
                    final svc = SettingsService.instanceOrNull;
                    if (svc == null) return const SizedBox.shrink();
                    final density = svc.read(SettingsService.libraryDensity);
                    final baseCardWidth = isTv
                        ? _getTvCardWidth(constraints.maxWidth, density, leadingPadding)
                        : GridSizeCalculator.getCellWidth(constraints.maxWidth, context, density);

                    final episodePosterMode = svc.read(SettingsService.episodePosterMode);

                    final hasEpisodes = widget.hub.items.any((item) => item.usesWideAspectRatio(episodePosterMode));
                    final hasNonEpisodes = widget.hub.items.any((item) => !item.usesWideAspectRatio(episodePosterMode));

                    final isMixedHub = hasEpisodes && hasNonEpisodes;

                    final isEpisodeOnlyHub = hasEpisodes && !hasNonEpisodes;

                    // Use 16:9 for episode-only hubs OR mixed hubs (with episode thumbnail mode)
                    final useWideLayout =
                        episodePosterMode == EpisodePosterMode.episodeThumbnail && (isEpisodeOnlyHub || isMixedHub);

                    // Card dimensions based on hub type
                    const wideCardMultiplier = 1.5;
                    final cardWidth = useWideLayout ? baseCardWidth * wideCardMultiplier : baseCardWidth;
                    final posterWidth = cardWidth - 6; // 3px padding on each side
                    final posterHeight = useWideLayout
                        ? posterWidth *
                              (9 / 16) // 16:9 for wide layout
                        : posterWidth * 1.5; // 2:3 for poster layout

                    final containerHeight = posterHeight + (isTv ? 48 : 33);
                    final focusBorderWidth = FocusTheme.focusBorderWidth;
                    final focusExtra = focusBorderWidth * 2; // border on both sides
                    _itemExtent = cardWidth + focusExtra + 4;

                    return SizedBox(
                      height: containerHeight + focusExtra + (isTv ? 12 : 4), // extra for scale + border top/bottom
                      child: HorizontalScrollWithArrows(
                        controller: _scrollController,
                        builder: (scrollController) => ListView.builder(
                          controller: scrollController,
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          padding: widget.inset
                              ? EdgeInsets.fromLTRB(0, isTv ? 6 : 2, _visibleRightInset + 4, isTv ? 6 : 2)
                              : EdgeInsets.fromLTRB(
                                  isTv ? leadingPadding : 8,
                                  isTv ? 6 : 2,
                                  (isTv ? leadingPadding : 8) + _visibleRightInset,
                                  isTv ? 6 : 2,
                                ),
                          itemCount: isKeyboardMode ? _totalItemCount : widget.hub.items.length,
                          itemBuilder: (context, index) {
                            final isItemFocused = hasFocus && index == _focusedIndex;

                            if (index == widget.hub.items.length) {
                              return Padding(
                                padding: widget.inset
                                    ? const EdgeInsets.only(right: 4)
                                    : const EdgeInsets.symmetric(horizontal: 2),
                                child: FocusBuilders.buildLockedFocusWrapper(
                                  context: context,
                                  isFocused: isItemFocused,
                                  onTap: () {
                                    _onItemTapped(index);
                                    _navigateToHubDetail(context);
                                  },
                                  child: SizedBox(
                                    width: isTv ? 118 : 80,
                                    height: containerHeight - 10,
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Symbols.arrow_forward_rounded,
                                            size: isTv ? 42 : 32,
                                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            t.common.viewAll,
                                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                              fontSize: isTv ? 16 : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }

                            final item = widget.hub.items[index];

                            return Padding(
                              padding: widget.inset
                                  ? const EdgeInsets.only(right: 4)
                                  : const EdgeInsets.symmetric(horizontal: 2),
                              child: FocusBuilders.buildLockedFocusWrapper(
                                context: context,
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
              ),
            )
          else
            Padding(
              padding: widget.inset
                  ? const EdgeInsets.symmetric(vertical: 8)
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                t.messages.noItemsAvailable,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    if (_totalItemCount == 0) return;
    final clamped = index.clamp(0, _totalItemCount - 1).toInt();
    setState(() {
      _focusedIndex = clamped;
    });
    HubFocusMemory.setForHub(widget.hub.id, clamped);
    _notifyFocusedItemChanged();
    _scrollToIndex(clamped);
    _hubFocusNode.requestFocus();
  }
}
