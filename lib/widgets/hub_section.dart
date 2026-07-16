import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../focus/dpad_navigator.dart';
import '../focus/dpad_select_long_press_controller.dart';
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
import '../utils/media_navigation_helper.dart';
import 'card_inflation_budget.dart';
import 'focus_builders.dart';
import 'media_card.dart';
import 'skeleton_media_card.dart';
import 'sliver_child_memo.dart';
import '../utils/scroll_utils.dart';
import 'horizontal_scroll_with_arrows.dart';
import '../i18n/strings.g.dart';

enum HubCardSizing {
  /// Larger cards optimized for top-level TV shelves.
  shelf,

  /// Grid-equivalent cards for shelves embedded in dense detail content.
  grid,
}

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
  final void Function(MediaItem source)? onRefresh;
  final VoidCallback? onRemoveFromContinueWatching;
  final bool isInContinueWatching;
  final bool usesContinueWatchingAction;
  final bool showServerName;
  final Future<List<MediaItem>> Function()? loadMoreItems;

  /// Reports the current focused media item. Used by TV spotlight layouts.
  final ValueChanged<MediaItem>? onFocusedItemChanged;

  /// Overrides the default media navigation for an item.
  final ValueChanged<MediaItem>? onItemTap;

  /// Overrides the standard media context menu for an item.
  final ValueChanged<MediaItem>? onItemLongPress;

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

  /// Controls whether cards follow top-level shelf or grid geometry.
  final HubCardSizing cardSizing;

  /// Overrides the global episode artwork mode for this hub.
  final EpisodePosterMode? episodePosterModeOverride;

  /// Vertical viewport alignment when this hub is focused.
  final double focusScrollAlignment;

  const HubSection({
    super.key,
    required this.hub,
    required this.icon,
    this.onRefresh,
    this.onRemoveFromContinueWatching,
    this.isInContinueWatching = false,
    bool? usesContinueWatchingAction,
    this.showServerName = false,
    this.loadMoreItems,
    this.onFocusedItemChanged,
    this.onItemTap,
    this.onItemLongPress,
    this.onVerticalNavigation,
    this.onBack,
    this.onNavigateUp,
    this.onNavigateToSidebar,
    this.inset = false,
    this.cardSizing = HubCardSizing.shelf,
    this.episodePosterModeOverride,
    this.focusScrollAlignment = 0.3,
  }) : usesContinueWatchingAction = usesContinueWatchingAction ?? isInContinueWatching;

  @override
  State<HubSection> createState() => HubSectionState();
}

class HubSectionState extends State<HubSection> with MountedSetStateMixin, SkeletonUpgradeScheduler {
  late FocusNode _hubFocusNode;
  final ScrollController _scrollController = ScrollController();

  /// Current visual focus index (not tied to Flutter's focus system)
  int _focusedIndex = 0;

  /// Reuses card widgets across rebuilds (parent setStates, focus moves) so
  /// only changed indices rebuild instead of every realized card in the row.
  final SliverChildMemo<MediaItem> _cardMemo = SliverChildMemo<MediaItem>();

  double _itemExtent = 0;
  double _leadingPaddingFor(bool isTv) => widget.inset
      ? 0.0
      : isTv
      ? TvLayoutConstants.shelfHorizontalInset
      : 12.0;
  double get _leadingPadding => _leadingPaddingFor(PlatformDetector.isTV());
  String get _focusMemoryKey {
    final serverId = widget.hub.serverId;
    return serverId == null ? widget.hub.id : '$serverId:${widget.hub.id}';
  }

  final _selectLongPress = DpadSelectLongPressController();

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
      _itemKeys.clear();
      _mediaCardKeys.clear();
    } else if (widget.hub.items.length != oldWidget.hub.items.length || widget.hub.more != oldWidget.hub.more) {
      _itemKeys.removeWhere((index, _) => index >= _totalItemCount);
      _mediaCardKeys.removeWhere((index, _) => index >= widget.hub.items.length);
    }

    if (widget.hub.items.length != oldWidget.hub.items.length || widget.hub.more != oldWidget.hub.more) {
      final maxIndex = _totalItemCount == 0 ? 0 : _totalItemCount - 1;
      if (_focusedIndex > maxIndex) {
        _focusedIndex = maxIndex;
      }
    }
  }

  @override
  void dispose() {
    _selectLongPress.dispose();
    _hubFocusNode.removeListener(_onFocusChange);
    _hubFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    // Reset long press state when focus is lost
    if (!_hubFocusNode.hasFocus) {
      _selectLongPress.reset();
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
    HubFocusMemory.setForHub(_focusMemoryKey, clamped);
    _notifyFocusedItemChanged();
    _scrollToIndex(clamped);
    _hubFocusNode.requestFocus();
    // ignore: no-empty-block - setState triggers rebuild to update focus styling
    setStateIfMounted(() {});

    _scrollHubIntoView();
  }

  /// Request focus using the stored memory for this hub
  void requestFocusFromMemory() {
    final index = HubFocusMemory.getForHub(_focusMemoryKey, _totalItemCount);
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
      animate: animate,
    );
    if (index >= 0 && index < _totalItemCount) {
      scrollKeyedChildToHorizontalCenter(
        _scrollController,
        _itemKeyFor(index),
        animate: animate,
        isCurrent: () => _focusedIndex == index && index < _totalItemCount,
      );
    }
  }

  /// Handle ALL key events at the hub level
  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    final key = event.logicalKey;

    final selectResult = _selectLongPress.handleKeyEvent(
      event,
      isOwnerActive: () => mounted,
      onShortPress: _activateCurrentItem,
      onLongPress: _showContextMenuForCurrentItem,
    );
    if (selectResult != KeyEventResult.ignored) return selectResult;

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
        HubFocusMemory.setForHub(_focusMemoryKey, _focusedIndex);
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
        HubFocusMemory.setForHub(_focusMemoryKey, _focusedIndex);
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
  final Map<int, GlobalKey> _itemKeys = {};
  final Map<int, GlobalKey<MediaCardState>> _mediaCardKeys = {};

  GlobalKey _itemKeyFor(int index) {
    return _itemKeys.putIfAbsent(index, () => GlobalKey());
  }

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
    if (widget.onItemTap case final onItemTap?) {
      onItemTap(item);
      return;
    }
    _navigateToItem(item);
  }

  void _showContextMenuForCurrentItem() {
    // No context menu for the "View All" card
    if (_focusedIndex >= widget.hub.items.length) return;
    final item = widget.hub.items[_focusedIndex];
    if (widget.onItemLongPress case final onItemLongPress?) {
      onItemLongPress(item);
      return;
    }
    _mediaCardKeys[_focusedIndex]?.currentState?.showContextMenu();
  }

  Future<void> _navigateToItem(MediaItem item) async {
    await navigateToMediaItem(
      context,
      item,
      onRefresh: widget.onRefresh,
      playDirectly: widget.usesContinueWatchingAction,
    );
  }

  void _navigateToHubDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HubDetailScreen(
          hub: widget.hub,
          loadItems: widget.loadMoreItems,
          isInContinueWatching: widget.isInContinueWatching,
          usesContinueWatchingAction: widget.usesContinueWatchingAction,
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
      padding: .only(
        bottom: isTv && !widget.inset && widget.cardSizing == HubCardSizing.shelf
            ? TvLayoutConstants.shelfVerticalGap
            : 0,
      ),
      child: Column(
        crossAxisAlignment: .start,
        mainAxisSize: .min,
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
                    mainAxisSize: .min,
                    children: [
                      AppIcon(widget.icon, fill: 1, size: isTv ? 28 : null),
                      SizedBox(width: isTv ? 12 : 8),
                      Flexible(
                        child: Text(widget.hub.title, style: titleStyle, overflow: .ellipsis, maxLines: 1),
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
                    final baseCardWidth = isTv && widget.cardSizing == HubCardSizing.shelf
                        ? _getTvCardWidth(constraints.maxWidth, density, leadingPadding)
                        : GridSizeCalculator.getCellWidth(constraints.maxWidth, context, density);

                    final EpisodePosterMode episodePosterMode =
                        widget.episodePosterModeOverride ?? svc.read(SettingsService.episodePosterMode);

                    final hasEpisodes = widget.hub.items.any((item) => item.usesWideAspectRatio(episodePosterMode));
                    final hasNonEpisodes = widget.hub.items.any((item) => !item.usesWideAspectRatio(episodePosterMode));

                    final isMixedHub = hasEpisodes && hasNonEpisodes;

                    final isEpisodeOnlyHub = hasEpisodes && !hasNonEpisodes;

                    // Use 16:9 for episode-only hubs OR mixed hubs (with episode thumbnail mode)
                    final useWideLayout =
                        episodePosterMode == EpisodePosterMode.episodeThumbnail && (isEpisodeOnlyHub || isMixedHub);

                    // Music hubs render square album/artist artwork
                    final isSquareHub =
                        widget.hub.items.isNotEmpty &&
                        widget.hub.items.every((item) => item.cardShape(episodePosterMode) == CardShape.square);

                    // Card dimensions based on hub type
                    const wideCardMultiplier = 1.5;
                    final cardWidth = useWideLayout ? baseCardWidth * wideCardMultiplier : baseCardWidth;
                    final posterWidth = cardWidth - 6; // 3px padding on each side
                    final posterHeight = useWideLayout
                        ? posterWidth *
                              (9 / 16) // 16:9 for wide layout
                        : isSquareHub
                        ? posterWidth // 1:1 for music artwork
                        : posterWidth * 1.5; // 2:3 for poster layout

                    final containerHeight = posterHeight + (isTv ? 48 : 33);
                    final focusBorderWidth = FocusTheme.focusBorderWidth;
                    final focusExtra = focusBorderWidth * 2; // border on both sides
                    _itemExtent = cardWidth + focusExtra + 4;

                    // Everything the card closures capture; a change flushes
                    // the memo so cached cards can't carry stale geometry.
                    final cardEpoch = (
                      cardWidth,
                      posterHeight,
                      useWideLayout,
                      isMixedHub,
                      episodePosterMode,
                      isKeyboardMode,
                      widget.inset,
                      widget.isInContinueWatching,
                      widget.usesContinueWatchingAction,
                    );

                    return SizedBox(
                      height: containerHeight + focusExtra + (isTv ? 12 : 4), // extra for scale + border top/bottom
                      child: HorizontalScrollWithArrows(
                        controller: _scrollController,
                        builder: (scrollController) => ListView.builder(
                          // Inert on media lists (no keep-alive clients): dropping the
                          // per-child wrappers shrinks build + semantics work per item.
                          addAutomaticKeepAlives: false,
                          addSemanticIndexes: false,
                          controller: scrollController,
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          // On touch, don't pre-inflate off-screen cards when a row
                          // enters the viewport — the default 250px realizes 2+ extra
                          // cards per side in the same frame, fattening the row-entry
                          // spike. Cards inflate as they scroll in instead (a few ms
                          // each). TV keeps the default: d-pad animateTo benefits from
                          // the prefetch and TV rows inflate via the focus path anyway.
                          scrollCacheExtent: isTv ? null : const ScrollCacheExtent.pixels(0),
                          padding: widget.inset
                              ? EdgeInsets.symmetric(vertical: isTv ? 6 : 2)
                              : EdgeInsets.symmetric(horizontal: isTv ? leadingPadding : 8, vertical: isTv ? 6 : 2),
                          itemCount: isKeyboardMode ? _totalItemCount : widget.hub.items.length,
                          itemBuilder: (context, index) {
                            final isItemFocused = hasFocus && index == _focusedIndex;

                            if (index == widget.hub.items.length) {
                              return Padding(
                                key: _itemKeyFor(index),
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
                                        mainAxisSize: .min,
                                        children: [
                                          AppIcon(
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

                            final cached = _cardMemo.tryGet(index, item, epoch: cardEpoch, salt: isItemFocused);
                            if (cached != null) return cached;
                            // Budget fresh inflations while an enclosing
                            // scrollable is moving (rows enter on the parent's
                            // vertical scroll); skeletons upgrade a frame
                            // later. Keyboard mode is exempt — skeletons
                            // aren't focus targets.
                            if (!isKeyboardMode &&
                                CardInflationBudget.isScrollingContext(context) &&
                                !CardInflationBudget.tryTake()) {
                              scheduleSkeletonUpgrade();
                              return Padding(
                                padding: widget.inset
                                    ? const EdgeInsets.only(right: 4)
                                    : const EdgeInsets.symmetric(horizontal: 2),
                                child: SizedBox(width: cardWidth, child: const SkeletonMediaCard()),
                              );
                            }
                            return _cardMemo.widgetFor(
                              index,
                              item,
                              epoch: cardEpoch,
                              // Focus moves only rebuild the two affected
                              // indices instead of the whole realized row.
                              salt: isItemFocused,
                              build: () => Padding(
                                key: _itemKeyFor(index),
                                padding: widget.inset
                                    ? const EdgeInsets.only(right: 4)
                                    : const EdgeInsets.symmetric(horizontal: 2),
                                child: FocusBuilders.buildLockedFocusWrapper(
                                  context: context,
                                  isFocused: isItemFocused,
                                  // Pointer/touch taps never reach these: MediaCard's own
                                  // tap region is deeper in the tree and always wins the
                                  // gesture arena. Passing null lets the wrapper collapse
                                  // to the bare card outside keyboard mode instead of
                                  // building a second dead gesture-detector stack per card.
                                  onTap: isKeyboardMode ? () => _onItemTapped(index) : null,
                                  onLongPress: isKeyboardMode
                                      ? () {
                                          _onItemTapped(index);
                                          _mediaCardKeys[index]?.currentState?.showContextMenu();
                                        }
                                      : null,
                                  delegateFocusBorder: true,
                                  child: MediaCard(
                                    key: _getMediaCardKey(index),
                                    item: item,
                                    width: cardWidth,
                                    height: posterHeight,
                                    onRefresh: widget.onRefresh,
                                    onRemoveFromContinueWatching: widget.onRemoveFromContinueWatching,
                                    onTap: widget.onItemTap == null
                                        ? null
                                        : () {
                                            _onItemTapped(index);
                                            widget.onItemTap!(item);
                                          },
                                    onLongPress: widget.onItemLongPress == null
                                        ? null
                                        : () {
                                            _onItemTapped(index);
                                            widget.onItemLongPress!(item);
                                          },
                                    forceGridMode: true,
                                    isInContinueWatching: widget.isInContinueWatching,
                                    usesContinueWatchingAction: widget.usesContinueWatchingAction,
                                    mixedHubContext: isMixedHub,
                                    episodePosterModeOverride: episodePosterMode,
                                  ),
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
              child: Text(t.messages.noItemsAvailable, style: Theme.of(context).textTheme.bodySmall),
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
    HubFocusMemory.setForHub(_focusMemoryKey, clamped);
    _notifyFocusedItemChanged();
    _scrollToIndex(clamped);
    _hubFocusNode.requestFocus();
  }
}
