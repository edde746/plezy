import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../focus/dpad_navigator.dart';
import '../focus/focus_theme.dart';
import '../focus/key_event_utils.dart';
import '../focus/locked_hub_controller.dart';
import '../i18n/strings.g.dart';
import '../media/media_hub.dart';
import '../media/media_item.dart';
import '../screens/hub_detail_screen.dart';
import '../services/settings_service.dart';
import '../theme/mono_tokens.dart';
import '../utils/media_image_helper.dart';
import '../utils/media_navigation_helper.dart';
import '../utils/provider_extensions.dart';
import '../utils/layout_constants.dart';
import '../utils/scroll_utils.dart';
import 'app_icon.dart';
import 'focus_builders.dart';
import 'horizontal_scroll_with_arrows.dart';
import 'media_card.dart';
import 'optimized_media_image.dart';
import 'settings_builder.dart';

class TvBrowseRailLayoutMetrics {
  final bool isPersonHub;
  final bool isMixedHub;
  final bool useWideLayout;
  final double focusExtra;
  final double railEdgePadding;
  final double itemGap;
  final double cardWidth;
  final double posterWidth;
  final double posterHeight;
  final double containerHeight;
  final double height;

  const TvBrowseRailLayoutMetrics({
    required this.isPersonHub,
    required this.isMixedHub,
    required this.useWideLayout,
    required this.focusExtra,
    required this.railEdgePadding,
    required this.itemGap,
    required this.cardWidth,
    required this.posterWidth,
    required this.posterHeight,
    required this.containerHeight,
    required this.height,
  });
}

class TvBrowseRailLayout {
  static const double compactTallPosterScale = 0.84;

  static double scaleForSize(Size size) => TvLayoutConstants.scaleForSize(size);

  static double horizontalInsetForScale(double scale) => (24 * scale).clamp(18, 40).toDouble();

  static double railTopPaddingForScale(double scale) => 12 * scale;

  static double railBottomPaddingForScale(double scale) => 8 * scale;

  static double hubStripHeightForScale(double scale) => 44 * scale;

  static double hubStripGapForScale(double scale) => 8 * scale;

  static bool isPersonHub(MediaHub hub) => hub.type == 'person';

  static double cardWidthFor({
    required double availableWidth,
    required int density,
    required bool useWideLayout,
    required double scale,
    required double horizontalPadding,
    required double itemGap,
  }) {
    final f = LibraryDensity.factor(density);
    final minWidth = (useWideLayout ? 280 : 170) * scale;
    final maxWidth = (useWideLayout ? 420 : 250) * scale;
    final targetCards = useWideLayout ? 4.2 - (f * 1.4) : 7.0 - (f * 2.0);
    final usableWidth = (availableWidth - horizontalPadding).clamp(1.0, double.infinity).toDouble();
    final gapCount = targetCards > 1 ? targetCards - 1 : 0.0;
    final fittedWidth = (usableWidth - (itemGap * gapCount)) / targetCards;
    return fittedWidth.clamp(minWidth, maxWidth).toDouble();
  }

  static TvBrowseRailLayoutMetrics metricsForHub({
    required MediaHub hub,
    required double availableWidth,
    required int density,
    required EpisodePosterMode episodePosterMode,
    required double scale,
    double tallPosterScale = 1.0,
  }) {
    final focusExtra = FocusTheme.focusBorderWidth * 2 * scale;
    final railEdgePadding = focusExtra + (12 * scale);
    final itemGap = 8 * scale;
    final isPersonHub = TvBrowseRailLayout.isPersonHub(hub);
    final hasWide = !isPersonHub && hub.items.any((item) => item.usesWideAspectRatio(episodePosterMode));
    final hasTall = !isPersonHub && hub.items.any((item) => !item.usesWideAspectRatio(episodePosterMode));
    final isMixedHub = hasWide && hasTall;
    final useWideLayout = hasWide && (!hasTall || episodePosterMode == EpisodePosterMode.episodeThumbnail);
    final baseCardWidth = cardWidthFor(
      availableWidth: availableWidth,
      density: density,
      useWideLayout: useWideLayout,
      scale: scale,
      horizontalPadding: railEdgePadding * 2,
      itemGap: itemGap,
    );
    final cardWidth = useWideLayout ? baseCardWidth : baseCardWidth * tallPosterScale;
    final posterWidth = cardWidth - (6 * scale);
    final posterHeight = isPersonHub ? posterWidth : (useWideLayout ? posterWidth * 9 / 16 : posterWidth * 1.5);
    final containerHeight = (posterHeight + ((isPersonHub ? 58 : 42) * scale)).ceilToDouble();
    final height = containerHeight + focusExtra + (14 * scale);

    return TvBrowseRailLayoutMetrics(
      isPersonHub: isPersonHub,
      isMixedHub: isMixedHub,
      useWideLayout: useWideLayout,
      focusExtra: focusExtra,
      railEdgePadding: railEdgePadding,
      itemGap: itemGap,
      cardWidth: cardWidth,
      posterWidth: posterWidth,
      posterHeight: posterHeight,
      containerHeight: containerHeight,
      height: height,
    );
  }

  static double maxActiveRailHeight({
    required List<MediaHub> hubs,
    required double availableWidth,
    required int density,
    required EpisodePosterMode episodePosterMode,
    EpisodePosterMode Function(MediaHub hub)? episodePosterModeForHub,
    required double scale,
    double tallPosterScale = 1.0,
  }) {
    var maxHeight = 0.0;
    for (final hub in hubs) {
      final metrics = metricsForHub(
        hub: hub,
        availableWidth: availableWidth,
        density: density,
        episodePosterMode: episodePosterModeForHub?.call(hub) ?? episodePosterMode,
        scale: scale,
        tallPosterScale: tallPosterScale,
      );
      if (metrics.height > maxHeight) maxHeight = metrics.height;
    }
    return maxHeight;
  }

  static double estimatedMaxScrollExtent({
    required MediaHub hub,
    required TvBrowseRailLayoutMetrics metrics,
    required double viewportWidth,
    required double scale,
  }) {
    final itemContentWidth = hub.items.length * (metrics.cardWidth + metrics.itemGap);
    final moreContentWidth = hub.more ? (132 * scale) + metrics.itemGap : 0.0;
    final contentWidth = (metrics.railEdgePadding * 2) + itemContentWidth + moreContentWidth;
    return (contentWidth - viewportWidth).clamp(0.0, double.infinity).toDouble();
  }

  static double scrollOffsetForIndex({
    required int index,
    required TvBrowseRailLayoutMetrics metrics,
    required double viewportWidth,
    required double maxScrollExtent,
  }) {
    final itemExtent = metrics.cardWidth + metrics.itemGap;
    final targetCenter = metrics.railEdgePadding + (index * itemExtent) + (itemExtent / 2);
    return (targetCenter - (viewportWidth / 2)).clamp(0.0, maxScrollExtent).toDouble();
  }

  static double estimateHeight({
    required Size size,
    required List<MediaHub> hubs,
    required int density,
    required EpisodePosterMode episodePosterMode,
    EpisodePosterMode Function(MediaHub hub)? episodePosterModeForHub,
    double tallPosterScale = 1.0,
  }) {
    if (hubs.isEmpty) return 0;

    final scale = scaleForSize(size);
    final availableWidth = size.width - horizontalInsetForScale(scale);
    if (availableWidth <= 0) return 0;

    final activeRailHeight = maxActiveRailHeight(
      hubs: hubs,
      availableWidth: availableWidth,
      density: density,
      episodePosterMode: episodePosterMode,
      episodePosterModeForHub: episodePosterModeForHub,
      scale: scale,
      tallPosterScale: tallPosterScale,
    );

    return railTopPaddingForScale(scale) +
        hubStripHeightForScale(scale) +
        hubStripGapForScale(scale) +
        activeRailHeight +
        railBottomPaddingForScale(scale);
  }
}

class TvBrowseRail extends StatefulWidget {
  final List<MediaHub> hubs;
  final IconData Function(MediaHub hub, int index) iconForHub;
  final ValueChanged<MediaItem>? onFocusedItemChanged;
  final void Function(MediaHub hub, MediaItem item)? onFocusedHubItemChanged;
  final void Function(String)? onRefresh;
  final VoidCallback? onRemoveFromContinueWatching;
  final bool Function(MediaHub hub)? isContinueWatchingHub;
  final Future<List<MediaItem>> Function(MediaHub hub)? loadMoreItems;
  final void Function(MediaHub hub, int index)? onActiveHubChanged;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onNavigateToSidebar;
  final VoidCallback? onBack;
  final FutureOr<bool> Function(MediaHub hub, MediaItem item)? onActivateItem;
  final double tallPosterScale;
  final String? initialHubId;
  final String? initialItemId;
  final bool autofocus;
  final EpisodePosterMode Function(MediaHub hub)? episodePosterModeForHub;

  const TvBrowseRail({
    super.key,
    required this.hubs,
    required this.iconForHub,
    this.onFocusedItemChanged,
    this.onFocusedHubItemChanged,
    this.onRefresh,
    this.onRemoveFromContinueWatching,
    this.isContinueWatchingHub,
    this.loadMoreItems,
    this.onActiveHubChanged,
    this.onNavigateUp,
    this.onNavigateToSidebar,
    this.onBack,
    this.onActivateItem,
    this.tallPosterScale = 1.0,
    this.initialHubId,
    this.initialItemId,
    this.autofocus = false,
    this.episodePosterModeForHub,
  });

  @override
  State<TvBrowseRail> createState() => TvBrowseRailState();
}

class TvBrowseRailState extends State<TvBrowseRail> {
  static const _longPressDuration = Duration(milliseconds: 500);

  final FocusNode _focusNode = FocusNode(debugLabel: 'tv_browse_rail');
  final Map<String, ScrollController> _scrollControllers = {};
  final ScrollController _hubStripController = ScrollController();
  final Map<int, GlobalKey> _hubStripKeys = {};
  final Map<String, GlobalKey<MediaCardState>> _mediaCardKeys = {};

  int _hubIndex = 0;
  int _itemIndex = 0;
  double _itemExtent = 260;
  double _railLeadingPadding = 0;
  Timer? _longPressTimer;
  bool _isSelectKeyDown = false;
  bool _longPressTriggered = false;
  bool _hasUserChangedHub = false;
  bool _hasUserChangedItem = false;
  bool _railScrollCorrectionPending = false;
  bool _hubStripCanScrollLeft = false;
  bool _hubStripCanScrollRight = false;

  MediaHub? get _activeHub => widget.hubs.isEmpty ? null : widget.hubs[_hubIndex.clamp(0, widget.hubs.length - 1)];

  void requestFocus() {
    _notifyFocusedItem();
    _focusNode.requestFocus();
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
    _hubStripController.addListener(_updateHubStripScrollState);
    _selectInitialHubIfPossible();
    final selectedInitialItem = _selectInitialItemIfPossible();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.hubs.isEmpty) return;
      if (selectedInitialItem) _scrollToItem(animate: false);
      _scrollHubStripToActive(animate: false);
      _updateHubStripScrollState();
      _notifyActiveHubChanged();
      _notifyFocusedItem();
      if (widget.autofocus) _focusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant TvBrowseRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldActiveHubId = oldWidget.hubs.isEmpty
        ? null
        : oldWidget.hubs[_hubIndex.clamp(0, oldWidget.hubs.length - 1)].id;

    if (widget.hubs.isEmpty) {
      _hubIndex = 0;
      _itemIndex = 0;
      return;
    }

    final selectedInitialHub = _selectInitialHubIfPossible();
    if (!selectedInitialHub && oldActiveHubId != null) {
      final preservedIndex = widget.hubs.indexWhere((hub) => hub.id == oldActiveHubId);
      if (preservedIndex != -1) {
        _hubIndex = preservedIndex;
      } else {
        _hubIndex = _hubIndex.clamp(0, widget.hubs.length - 1);
      }
    } else if (!selectedInitialHub) {
      _hubIndex = _hubIndex.clamp(0, widget.hubs.length - 1);
    }

    final hub = _activeHub;
    if (hub == null) return;
    _itemIndex = _itemIndex.clamp(0, _totalItemCount(hub) == 0 ? 0 : _totalItemCount(hub) - 1);
    final selectedInitialItem = _selectInitialItemIfPossible();
    final activeHubChanged = oldActiveHubId != _activeHub?.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (selectedInitialItem) _scrollToItem(animate: false);
      _scrollHubStripToActive(animate: false);
      _updateHubStripScrollState();
      if (!oldWidget.autofocus && widget.autofocus) _focusNode.requestFocus();
      if (activeHubChanged) _notifyActiveHubChanged();
      _notifyFocusedItem();
    });
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _hubStripController.removeListener(_updateHubStripScrollState);
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    _hubStripController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) _notifyFocusedItem();
    setState(() {});
  }

  int _totalItemCount(MediaHub hub) => hub.items.length + (hub.more ? 1 : 0);

  bool _isPersonHub(MediaHub hub) => TvBrowseRailLayout.isPersonHub(hub);

  void _notifyFocusedItem() {
    final hub = _activeHub;
    if (hub == null || hub.items.isEmpty || _itemIndex >= hub.items.length) return;
    final item = hub.items[_itemIndex];
    widget.onFocusedItemChanged?.call(item);
    widget.onFocusedHubItemChanged?.call(hub, item);
  }

  void _notifyActiveHubChanged() {
    final hub = _activeHub;
    if (hub == null) return;
    widget.onActiveHubChanged?.call(hub, _hubIndex);
  }

  bool _selectInitialHubIfPossible() {
    final initialHubId = widget.initialHubId;
    if (_hasUserChangedHub || initialHubId == null || widget.hubs.isEmpty) return false;
    final initialIndex = widget.hubs.indexWhere((hub) => hub.id == initialHubId);
    if (initialIndex == -1) return false;
    if (initialIndex != _hubIndex) {
      _hubIndex = initialIndex;
      _itemIndex = 0;
    }
    return true;
  }

  bool _selectInitialItemIfPossible() {
    final initialItemId = widget.initialItemId;
    final hub = _activeHub;
    if (_hasUserChangedHub || _hasUserChangedItem || initialItemId == null || hub == null) return false;
    final initialIndex = hub.items.indexWhere((item) => item.id == initialItemId);
    if (initialIndex == -1) return false;
    if (initialIndex != _itemIndex) _itemIndex = initialIndex;
    return true;
  }

  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    final key = event.logicalKey;

    if (key.isSelectKey) {
      if (event is KeyDownEvent) {
        if (!_isSelectKeyDown) {
          _isSelectKeyDown = true;
          _longPressTriggered = false;
          _longPressTimer?.cancel();
          _longPressTimer = Timer(_longPressDuration, () {
            if (!mounted || !_isSelectKeyDown) return;
            _longPressTriggered = true;
            SelectKeyUpSuppressor.suppressSelectUntilKeyUp();
            _showContextMenuForCurrentItem();
          });
        }
        return KeyEventResult.handled;
      }
      if (event is KeyRepeatEvent) return KeyEventResult.handled;
      if (event is KeyUpEvent) {
        final timerWasActive = _longPressTimer?.isActive ?? false;
        _longPressTimer?.cancel();
        if (!_longPressTriggered && timerWasActive && _isSelectKeyDown) _activateCurrentItem();
        _isSelectKeyDown = false;
        _longPressTriggered = false;
        return KeyEventResult.handled;
      }
    }

    if (widget.onBack != null) {
      final backResult = handleBackKeyAction(event, widget.onBack!);
      if (backResult != KeyEventResult.ignored) return backResult;
    }

    if (key.isDpadDirection && event is KeyUpEvent) return KeyEventResult.handled;

    if (!event.isActionable) return KeyEventResult.ignored;
    final hub = _activeHub;
    if (hub == null) return KeyEventResult.ignored;

    if (key.isLeftKey) {
      if (_itemIndex > 0) {
        setState(() {
          _itemIndex--;
          _hasUserChangedItem = true;
        });
        _rememberFocus(hub);
        _notifyFocusedItem();
        _scrollToItem();
      } else {
        widget.onNavigateToSidebar?.call();
      }
      return KeyEventResult.handled;
    }

    if (key.isRightKey) {
      if (_itemIndex < _totalItemCount(hub) - 1) {
        setState(() {
          _itemIndex++;
          _hasUserChangedItem = true;
        });
        _rememberFocus(hub);
        _notifyFocusedItem();
        _scrollToItem();
      }
      return KeyEventResult.handled;
    }

    if (key.isUpKey) {
      if (_hubIndex > 0) {
        _moveHub(-1);
      } else {
        widget.onNavigateUp?.call();
      }
      return KeyEventResult.handled;
    }

    if (key.isDownKey) {
      _moveHub(1);
      return KeyEventResult.handled;
    }

    if (key.isContextMenuKey) {
      _showContextMenuForCurrentItem();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _moveHub(int delta) {
    if (widget.hubs.isEmpty) return;
    final next = (_hubIndex + delta).clamp(0, widget.hubs.length - 1);
    if (next == _hubIndex) return;
    final nextHub = widget.hubs[next];
    final remembered = HubFocusMemory.getForHub(nextHub.id, _totalItemCount(nextHub));
    setState(() {
      _hubIndex = next;
      _itemIndex = remembered.clamp(0, _totalItemCount(nextHub) == 0 ? 0 : _totalItemCount(nextHub) - 1);
      _hasUserChangedHub = true;
      _railScrollCorrectionPending = true;
    });
    _notifyFocusedItem();
    _notifyActiveHubChanged();
    _scrollToItemAfterLayout(animate: false, revealRail: true);
    _scrollHubStripToActive();
  }

  void _scrollHubStripToActive({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = _hubStripKeys[_hubIndex];
      final context = key?.currentContext;
      if (context == null) return;

      unawaited(
        Scrollable.ensureVisible(
          context,
          alignment: 0.35,
          duration: animate ? const Duration(milliseconds: 180) : Duration.zero,
          curve: Curves.easeOutCubic,
        ).then((_) {
          if (mounted) _updateHubStripScrollState();
        }),
      );
    });
  }

  void _scheduleHubStripScrollStateUpdate() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateHubStripScrollState());
  }

  void _updateHubStripScrollState() {
    if (!mounted) return;

    var canScrollLeft = false;
    var canScrollRight = false;
    if (_hubStripController.hasClients && _hubStripController.position.hasContentDimensions) {
      const edgeTolerance = 0.5;
      final position = _hubStripController.position;
      canScrollLeft = position.pixels > position.minScrollExtent + edgeTolerance;
      canScrollRight = position.pixels < position.maxScrollExtent - edgeTolerance;
    }

    if (canScrollLeft == _hubStripCanScrollLeft && canScrollRight == _hubStripCanScrollRight) return;
    setState(() {
      _hubStripCanScrollLeft = canScrollLeft;
      _hubStripCanScrollRight = canScrollRight;
    });
  }

  void _setHoveredItem(MediaHub hub, int index) {
    if (_activeHub?.id != hub.id || index >= hub.items.length || _itemIndex == index) return;
    setState(() {
      _itemIndex = index;
      _hasUserChangedItem = true;
    });
    _rememberFocus(hub);
    _notifyFocusedItem();
  }

  void _rememberFocus(MediaHub hub) {
    HubFocusMemory.setForHub(hub.id, _itemIndex);
  }

  void _scrollToItem({bool animate = true}) {
    final hub = _activeHub;
    if (hub == null) return;
    final controller = _scrollControllers[hub.id];
    if (controller == null) return;

    scrollListToIndex(
      controller,
      _itemIndex,
      itemExtent: _itemExtent,
      leadingPadding: _railLeadingPadding,
      animate: animate,
    );
  }

  void _scrollToItemAfterLayout({bool animate = true, bool revealRail = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToItem(animate: animate);
      if (revealRail && _railScrollCorrectionPending) {
        setState(() => _railScrollCorrectionPending = false);
      }
    });
  }

  ScrollController _scrollControllerForHub(
    MediaHub hub,
    TvBrowseRailLayoutMetrics metrics,
    double viewportWidth,
    double scale,
  ) {
    return _scrollControllers.putIfAbsent(hub.id, () {
      final maxScrollExtent = TvBrowseRailLayout.estimatedMaxScrollExtent(
        hub: hub,
        metrics: metrics,
        viewportWidth: viewportWidth,
        scale: scale,
      );
      final initialScrollOffset = TvBrowseRailLayout.scrollOffsetForIndex(
        index: _itemIndex,
        metrics: metrics,
        viewportWidth: viewportWidth,
        maxScrollExtent: maxScrollExtent,
      );
      return ScrollController(initialScrollOffset: initialScrollOffset);
    });
  }

  GlobalKey<MediaCardState> _cardKeyFor(MediaHub hub, int itemIndex) {
    return _mediaCardKeys.putIfAbsent('${hub.id}:$itemIndex', () => GlobalKey<MediaCardState>());
  }

  void _showContextMenuForCurrentItem() {
    final hub = _activeHub;
    if (hub == null || _itemIndex >= hub.items.length) return;
    if (_isPersonHub(hub)) return;
    _cardKeyFor(hub, _itemIndex).currentState?.showContextMenu();
  }

  Future<void> _activateCurrentItem() async {
    final hub = _activeHub;
    if (hub == null) return;
    if (_itemIndex == hub.items.length && hub.more) {
      _navigateToHubDetail(hub);
      return;
    }
    if (_itemIndex >= hub.items.length) return;
    final item = hub.items[_itemIndex];
    final handled = await widget.onActivateItem?.call(hub, item);
    if (handled == true) return;
    if (!mounted) return;
    await navigateToMediaItem(
      context,
      item,
      onRefresh: widget.onRefresh,
      playDirectly: widget.isContinueWatchingHub?.call(hub) ?? false,
    );
  }

  void _navigateToHubDetail(MediaHub hub) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HubDetailScreen(
          hub: hub,
          loadItems: widget.loadMoreItems == null ? null : () => widget.loadMoreItems!(hub),
          isInContinueWatching: widget.isContinueWatchingHub?.call(hub) ?? false,
          onRemoveFromContinueWatching: widget.onRemoveFromContinueWatching,
        ),
      ),
    );
  }

  double _scale(BuildContext context) => TvBrowseRailLayout.scaleForSize(MediaQuery.sizeOf(context));

  double _horizontalInset(BuildContext context) => TvBrowseRailLayout.horizontalInsetForScale(_scale(context));

  @override
  Widget build(BuildContext context) {
    final hub = _activeHub;
    if (hub == null) return const SizedBox.shrink();
    final hasFocus = _focusNode.hasFocus;
    final theme = Theme.of(context);
    final scale = _scale(context);
    final horizontalInset = _horizontalInset(context);

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          horizontalInset,
          TvBrowseRailLayout.railTopPaddingForScale(scale),
          0,
          TvBrowseRailLayout.railBottomPaddingForScale(scale),
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, theme.scaffoldBackgroundColor.withValues(alpha: 0.7)],
          ),
        ),
        child: AnimatedOpacity(
          opacity: hasFocus ? 1 : 0.6,
          duration: FocusTheme.getAnimationDuration(context),
          curve: Curves.easeOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHubStrip(context),
              SizedBox(height: TvBrowseRailLayout.hubStripGapForScale(scale)),
              _buildActiveRail(hub, hasFocus),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHubStrip(BuildContext context) {
    final scale = _scale(context);
    final height = TvBrowseRailLayout.hubStripHeightForScale(scale);

    return SizedBox(
      height: height,
      child: ExcludeFocus(
        child: Row(
          children: [
            if (widget.hubs.length > 1) ...[
              _buildHubStripAffordance(
                scale: scale,
                hasAbove: _hubIndex > 0,
                hasBelow: _hubIndex < widget.hubs.length - 1,
              ),
              SizedBox(width: 8 * scale),
            ],
            Expanded(
              child: NotificationListener<ScrollMetricsNotification>(
                onNotification: (_) {
                  _scheduleHubStripScrollStateUpdate();
                  return false;
                },
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (bounds) {
                    final fadeStop = bounds.width <= 0
                        ? 0.08
                        : ((32 * scale) / bounds.width).clamp(0.02, 0.12).toDouble();
                    return LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        _hubStripCanScrollLeft ? Colors.transparent : Colors.white,
                        Colors.white,
                        Colors.white,
                        _hubStripCanScrollRight ? Colors.transparent : Colors.white,
                      ],
                      stops: [0, fadeStop, 1 - fadeStop, 1],
                    ).createShader(bounds);
                  },
                  child: ListView.separated(
                    controller: _hubStripController,
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    clipBehavior: Clip.hardEdge,
                    padding: EdgeInsets.only(right: 36 * scale),
                    itemCount: widget.hubs.length,
                    separatorBuilder: (context, index) => SizedBox(width: 8 * scale),
                    itemBuilder: _buildHubStripChip,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHubStripChip(BuildContext context, int index) {
    final scale = _scale(context);
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = index == _hubIndex;
    final hub = widget.hubs[index];
    final primaryColor = isActive ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.62);

    return AnimatedContainer(
      key: _hubStripKeys.putIfAbsent(index, () => GlobalKey()),
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 7 * scale),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withValues(alpha: 0.16) : Colors.transparent,
        borderRadius: BorderRadius.circular(tokens(context).radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            widget.iconForHub(hub, index),
            fill: 1,
            size: 21 * scale,
            color: isActive ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          SizedBox(width: 8 * scale),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 260 * scale),
            child: Text(
              hub.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: primaryColor,
                fontSize: 16 * scale,
                height: 1,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHubStripAffordance({required double scale, required bool hasAbove, required bool hasBelow}) {
    final enabledColor = Colors.white.withValues(alpha: 0.62);
    final disabledColor = Colors.white.withValues(alpha: 0.18);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(
          Symbols.keyboard_arrow_up_rounded,
          fill: 1,
          size: 12 * scale,
          color: hasAbove ? enabledColor : disabledColor,
        ),
        AppIcon(
          Symbols.keyboard_arrow_down_rounded,
          fill: 1,
          size: 12 * scale,
          color: hasBelow ? enabledColor : disabledColor,
        ),
      ],
    );
  }

  Widget _buildActiveRail(MediaHub hub, bool hasFocus) {
    return SettingsBuilder(
      prefs: const [SettingsService.libraryDensity, SettingsService.episodePosterMode],
      builder: (context) => LayoutBuilder(
        builder: (context, constraints) {
          final svc = SettingsService.instanceOrNull!;
          final density = svc.read(SettingsService.libraryDensity);
          final EpisodePosterMode episodePosterMode =
              widget.episodePosterModeForHub?.call(hub) ?? svc.read(SettingsService.episodePosterMode);
          final scale = _scale(context);
          final metrics = TvBrowseRailLayout.metricsForHub(
            hub: hub,
            availableWidth: constraints.maxWidth,
            density: density,
            episodePosterMode: episodePosterMode,
            scale: scale,
            tallPosterScale: widget.tallPosterScale,
          );
          final scrollController = _scrollControllerForHub(hub, metrics, constraints.maxWidth, scale);
          final maxActiveRailHeight = TvBrowseRailLayout.maxActiveRailHeight(
            hubs: widget.hubs,
            availableWidth: constraints.maxWidth,
            density: density,
            episodePosterMode: svc.read(SettingsService.episodePosterMode),
            episodePosterModeForHub: widget.episodePosterModeForHub,
            scale: scale,
            tallPosterScale: widget.tallPosterScale,
          );
          _railLeadingPadding = metrics.railEdgePadding;
          _itemExtent = metrics.cardWidth + metrics.itemGap;

          return Opacity(
            opacity: _railScrollCorrectionPending ? 0 : 1,
            child: SizedBox(
              height: maxActiveRailHeight,
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  height: metrics.height,
                  child: ClipRect(
                    clipper: _RailClipper(
                      rightOverflow: metrics.railEdgePadding + metrics.cardWidth + metrics.itemGap,
                      verticalOverflow: metrics.focusExtra,
                    ),
                    child: HorizontalScrollWithArrows(
                      controller: scrollController,
                      builder: (scrollController) => ListView.builder(
                        controller: scrollController,
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        padding: EdgeInsets.symmetric(horizontal: metrics.railEdgePadding, vertical: 6 * scale),
                        itemCount: _totalItemCount(hub),
                        itemBuilder: (context, index) {
                          final isFocused = hasFocus && index == _itemIndex;
                          if (index == hub.items.length) {
                            return Padding(
                              padding: EdgeInsets.only(right: metrics.itemGap),
                              child: FocusBuilders.buildLockedFocusWrapper(
                                context: context,
                                isFocused: isFocused,
                                onTap: () {
                                  setState(() {
                                    _itemIndex = index;
                                    _hasUserChangedItem = true;
                                  });
                                  _navigateToHubDetail(hub);
                                },
                                child: SizedBox(
                                  width: 132 * scale,
                                  height: metrics.containerHeight - metrics.itemGap,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AppIcon(
                                        Symbols.arrow_forward_rounded,
                                        fill: 1,
                                        size: 42 * scale,
                                        color: Colors.white,
                                      ),
                                      SizedBox(height: 6 * scale),
                                      Text(
                                        t.common.viewAll,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          final item = hub.items[index];
                          return Padding(
                            padding: EdgeInsets.only(right: metrics.itemGap),
                            child: MouseRegion(
                              onEnter: (_) => _setHoveredItem(hub, index),
                              child: FocusBuilders.buildLockedFocusWrapper(
                                context: context,
                                isFocused: isFocused,
                                onTap: () {
                                  setState(() {
                                    _itemIndex = index;
                                    _hasUserChangedItem = true;
                                  });
                                  _activateCurrentItem();
                                },
                                onLongPress: metrics.isPersonHub
                                    ? null
                                    : () => _cardKeyFor(hub, index).currentState?.showContextMenu(),
                                child: metrics.isPersonHub
                                    ? _buildPersonCard(
                                        context,
                                        item,
                                        cardWidth: metrics.cardWidth,
                                        imageSize: metrics.posterHeight,
                                        scale: scale,
                                      )
                                    : MediaCard(
                                        key: _cardKeyFor(hub, index),
                                        item: item,
                                        width: metrics.cardWidth,
                                        height: metrics.posterHeight,
                                        onRefresh: widget.onRefresh,
                                        onRemoveFromContinueWatching: widget.onRemoveFromContinueWatching,
                                        forceGridMode: true,
                                        isInContinueWatching: widget.isContinueWatchingHub?.call(hub) ?? false,
                                        mixedHubContext: metrics.isMixedHub,
                                        episodePosterModeOverride: episodePosterMode,
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPersonCard(
    BuildContext context,
    MediaItem item, {
    required double cardWidth,
    required double imageSize,
    required double scale,
  }) {
    final theme = Theme.of(context);
    final characterName = item.parentTitle;

    return SizedBox(
      width: cardWidth,
      child: Padding(
        padding: EdgeInsets.fromLTRB(3 * scale, 3 * scale, 3 * scale, scale),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(tokens(context).radiusSm),
              child: OptimizedMediaImage(
                client: context.tryGetMediaClientWithFallback(item.serverId),
                imagePath: item.thumbPath,
                width: imageSize,
                height: imageSize,
                fit: BoxFit.cover,
                imageType: ImageType.avatar,
                fallbackIcon: Symbols.person_rounded,
              ),
            ),
            SizedBox(height: 6 * scale),
            Text(
              item.displayTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens(context).text,
                fontSize: 13 * scale,
                height: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (characterName != null && characterName.isNotEmpty) ...[
              SizedBox(height: 2 * scale),
              Text(
                characterName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens(context).textMuted,
                  fontSize: 11 * scale,
                  height: 1.1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RailClipper extends CustomClipper<Rect> {
  final double rightOverflow;
  final double verticalOverflow;

  const _RailClipper({required this.rightOverflow, required this.verticalOverflow});

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, -verticalOverflow, size.width + rightOverflow, size.height + verticalOverflow);

  @override
  bool shouldReclip(covariant _RailClipper oldClipper) {
    return oldClipper.rightOverflow != rightOverflow || oldClipper.verticalOverflow != verticalOverflow;
  }
}
