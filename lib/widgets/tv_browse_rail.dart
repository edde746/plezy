import 'dart:async';
import '../media/ids.dart';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../focus/card_focus_scope.dart';
import '../focus/dpad_navigator.dart';
import '../focus/focus_theme.dart';
import '../focus/key_event_utils.dart';
import '../focus/locked_hub_controller.dart';
import '../i18n/strings.g.dart';
import '../navigation/main_screen_scope.dart';
import '../media/media_hub.dart';
import '../media/media_item.dart';
import '../screens/hub_detail_screen.dart';
import '../services/settings_service.dart';
import '../theme/mono_tokens.dart';
import '../utils/media_image_helper.dart';
import '../utils/media_navigation_helper.dart';
import '../utils/provider_extensions.dart';
import '../utils/layout_constants.dart';
import 'app_icon.dart';
import 'clickable_cursor.dart';
import 'focus_builders.dart';
import 'horizontal_scroll_with_arrows.dart';
import 'listenable_selector.dart';
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
  static const double compactTallPosterScale = 0.8;
  static const double compactEpisodeThumbnailScale = compactTallPosterScale;
  static const double fullCardFocusScale = FocusTheme.fullCardFocusScale;

  static double scaleForSize(Size size) => TvLayoutConstants.scaleForSize(size);

  static double horizontalInsetForScale(double scale) => (24 * scale).clamp(18, 40).toDouble();

  static double railTopPaddingForScale(double scale) => 12 * scale;

  static double railBottomPaddingForScale(double scale) => 8 * scale;

  static double railInteractionExpansionForScale(double scale) => (12 * scale).clamp(8, 18).toDouble();

  static double itemGapForScale(double _) => 0;

  static double fullCardItemGapForScale(double scale) => (12 * scale).clamp(8, 18).toDouble();

  static double viewAllItemWidthForScale(double scale) => (104 * scale).clamp(88, 132).toDouble();

  static double viewAllPillHeightForScale(double scale) => (44 * scale).clamp(36, 54).toDouble();

  static double hubStripHeightForScale(double scale) => 36 * scale;

  static double hubStripGapForScale(double _) => 0;

  static double nextHubPeekHeightForScale(double scale) => 30 * scale;

  static double hubSectionHeightFor({required double scale, required double activeRailHeight}) {
    return hubStripHeightForScale(scale) + hubStripGapForScale(scale) + activeRailHeight;
  }

  static double viewportHeightFor({required int hubCount, required double scale, required double sectionHeight}) {
    final peekHeight = hubCount > 1 ? nextHubPeekHeightForScale(scale) : 0.0;
    return sectionHeight + peekHeight;
  }

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
    bool fullCardLayout = false,
    double tallPosterScale = 1.0,
    double widePosterScale = 1.0,
  }) {
    final focusExtra = FocusTheme.focusBorderWidth * 2 * scale;
    final railEdgePadding = focusExtra + (12 * scale);
    final itemGap = fullCardLayout ? fullCardItemGapForScale(scale) : itemGapForScale(scale);
    final isPersonHub = TvBrowseRailLayout.isPersonHub(hub);
    final emptyEpisodeThumbnailHub =
        hub.items.isEmpty && hub.type == 'episode' && episodePosterMode == EpisodePosterMode.episodeThumbnail;
    final hasWide =
        !isPersonHub &&
        (emptyEpisodeThumbnailHub || hub.items.any((item) => item.usesWideAspectRatio(episodePosterMode)));
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
    final cardWidth = baseCardWidth * (useWideLayout ? widePosterScale : tallPosterScale);
    final posterWidth = fullCardLayout ? cardWidth : cardWidth - (6 * scale);
    final posterHeight = isPersonHub ? posterWidth : (useWideLayout ? posterWidth * 9 / 16 : posterWidth * 1.5);
    final labelHeight = fullCardLayout ? 0.0 : ((isPersonHub ? 58 : 42) * scale);
    final containerHeight = (posterHeight + labelHeight).ceilToDouble();
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
    double Function(MediaHub hub)? widePosterScaleForHub,
    required double scale,
    bool fullCardLayout = false,
    double tallPosterScale = 1.0,
    double widePosterScale = 1.0,
  }) {
    var maxHeight = 0.0;
    for (final hub in hubs) {
      final metrics = metricsForHub(
        hub: hub,
        availableWidth: availableWidth,
        density: density,
        episodePosterMode: episodePosterModeForHub?.call(hub) ?? episodePosterMode,
        scale: scale,
        fullCardLayout: fullCardLayout,
        tallPosterScale: tallPosterScale,
        widePosterScale: widePosterScaleForHub?.call(hub) ?? widePosterScale,
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
    bool? hasTrailing,
  }) {
    final showTrailing = hasTrailing ?? hub.more;
    final itemContentWidth = hub.items.length * (metrics.cardWidth + metrics.itemGap);
    final moreContentWidth = showTrailing ? viewAllItemWidthForScale(scale) + metrics.itemGap : 0.0;
    final contentWidth = (metrics.railEdgePadding * 2) + itemContentWidth + moreContentWidth;
    return (contentWidth - viewportWidth).clamp(0.0, double.infinity).toDouble();
  }

  static double itemExtentForIndex({
    required MediaHub hub,
    required int index,
    required TvBrowseRailLayoutMetrics metrics,
    required double scale,
    bool? hasTrailing,
  }) {
    final showTrailing = hasTrailing ?? hub.more;
    if (index == hub.items.length && showTrailing) return viewAllItemWidthForScale(scale) + metrics.itemGap;
    return metrics.cardWidth + metrics.itemGap;
  }

  static double scrollOffsetForIndex({
    required MediaHub hub,
    required int index,
    required TvBrowseRailLayoutMetrics metrics,
    required double viewportWidth,
    required double maxScrollExtent,
    required double scale,
    bool? hasTrailing,
  }) {
    final showTrailing = hasTrailing ?? hub.more;
    final totalCount = hub.items.length + (showTrailing ? 1 : 0);
    if (totalCount == 0) return 0;

    final clampedIndex = index.clamp(0, totalCount - 1).toInt();
    final normalItemExtent = metrics.cardWidth + metrics.itemGap;
    final normalItemsBefore = clampedIndex < hub.items.length ? clampedIndex : hub.items.length;
    final leadingOffset = metrics.railEdgePadding + (normalItemsBefore * normalItemExtent);
    final targetExtent = itemExtentForIndex(
      hub: hub,
      index: clampedIndex,
      metrics: metrics,
      scale: scale,
      hasTrailing: showTrailing,
    );
    final targetCenter = leadingOffset + (targetExtent / 2);
    return (targetCenter - (viewportWidth / 2)).clamp(0.0, maxScrollExtent).toDouble();
  }

  static double estimateHeight({
    required Size size,
    required List<MediaHub> hubs,
    required int density,
    required EpisodePosterMode episodePosterMode,
    EpisodePosterMode Function(MediaHub hub)? episodePosterModeForHub,
    double Function(MediaHub hub)? widePosterScaleForHub,
    bool fullCardLayout = false,
    double tallPosterScale = 1.0,
    double widePosterScale = 1.0,
  }) {
    if (hubs.isEmpty) return 0;

    final scale = scaleForSize(size);
    final availableWidth = size.width - horizontalInsetForScale(scale);
    if (availableWidth <= 0) return 0;

    final railHeight = maxActiveRailHeight(
      hubs: hubs,
      availableWidth: availableWidth,
      density: density,
      episodePosterMode: episodePosterMode,
      episodePosterModeForHub: episodePosterModeForHub,
      widePosterScaleForHub: widePosterScaleForHub,
      scale: scale,
      fullCardLayout: fullCardLayout,
      tallPosterScale: tallPosterScale,
      widePosterScale: widePosterScale,
    );

    final sectionHeight = hubSectionHeightFor(scale: scale, activeRailHeight: railHeight);

    return railTopPaddingForScale(scale) +
        viewportHeightFor(hubCount: hubs.length, scale: scale, sectionHeight: sectionHeight) +
        railBottomPaddingForScale(scale);
  }
}

/// What [TvBrowseRail] renders in a hub's trailing slot (after the last item).
enum TvRailTrailing { none, loading, error, viewAll }

class TvBrowseRail extends StatefulWidget {
  final List<MediaHub> hubs;
  final IconData Function(MediaHub hub, int index) iconForHub;
  final ValueChanged<MediaItem>? onFocusedItemChanged;
  final void Function(MediaHub hub, MediaItem item)? onFocusedHubItemChanged;
  final void Function(String)? onRefresh;
  final VoidCallback? onRemoveFromContinueWatching;
  final bool Function(MediaHub hub)? isContinueWatchingHub;
  final Future<List<MediaItem>> Function(MediaHub hub)? loadMoreItems;

  /// Optional per-hub trailing-slot state (loading/error/viewAll). When null the
  /// rail keeps the legacy "[MediaHub.more] → View All" behavior.
  final TvRailTrailing Function(MediaHub hub)? trailingForHub;

  /// Invoked when the user activates a hub's trailing retry tile.
  final void Function(MediaHub hub)? onRetryHub;
  final void Function(MediaHub hub, int index)? onActiveHubChanged;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onNavigateToSidebar;
  final VoidCallback? onBack;
  final FutureOr<bool> Function(MediaHub hub, MediaItem item)? onActivateItem;
  final double tallPosterScale;
  final double widePosterScale;
  final String? initialHubId;
  final String? initialItemId;
  final bool autofocus;
  final EpisodePosterMode Function(MediaHub hub)? episodePosterModeForHub;
  final double Function(MediaHub hub)? widePosterScaleForHub;

  /// Explicit background bleed override. When null, the bleed target is read
  /// from [MainScreenFocusScope] (offset aspect) inside the bleed widget
  /// itself, so sidebar flips never rebuild the rail — only the bleed layer.
  final double? backgroundBleedLeft;

  /// Optional signal that is `true` while an input gesture (e.g. a Siri-remote
  /// touch) is in progress. When select-suppression is armed during an active
  /// gesture, it is held until the gesture ends (finger lift) rather than the
  /// short no-touch timeout — one activation per touch. Generic by design: no
  /// platform/service coupling here.
  final ValueListenable<bool>? selectSuppressionGestureSignal;

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
    this.trailingForHub,
    this.onRetryHub,
    this.onActiveHubChanged,
    this.onNavigateUp,
    this.onNavigateToSidebar,
    this.onBack,
    this.onActivateItem,
    this.tallPosterScale = 1.0,
    this.widePosterScale = 1.0,
    this.initialHubId,
    this.initialItemId,
    this.autofocus = false,
    this.episodePosterModeForHub,
    this.widePosterScaleForHub,
    this.backgroundBleedLeft,
    this.selectSuppressionGestureSignal,
  });

  @override
  State<TvBrowseRail> createState() => TvBrowseRailState();
}

class TvBrowseRailState extends State<TvBrowseRail> {
  static const _longPressDuration = Duration(milliseconds: 500);
  // No-touch fallback only: clear suppression even if no select key-up is seen
  // (e.g. a held-key carry-over on a non-touch remote). Touch-driven clicks use
  // the gesture path instead, which is bounded by the physical touch.
  static const _selectSuppressionTimeout = Duration(milliseconds: 220);
  // Touch path safety net only. The deterministic clear is the touch ending
  // (finger lift); this guards solely against a dropped touch-end event and is
  // generous enough never to fire mid-gesture in practice.
  static const _selectSuppressionGestureBackstop = Duration(seconds: 3);
  static const _navigationScrollDuration = Duration(milliseconds: 130);
  static const _repeatNavigationScrollDuration = Duration(milliseconds: 65);
  static const _scrollCatchUpViewportDistance = 2.5;
  static const _inactiveHubContentOpacity = 0.7;

  final FocusNode _focusNode = FocusNode(debugLabel: 'tv_browse_rail');
  final Map<String, ScrollController> _scrollControllers = {};
  final ScrollController _verticalController = ScrollController();
  final Map<int, GlobalKey> _hubSectionKeys = {};
  final Map<String, GlobalKey<MediaCardState>> _mediaCardKeys = {};
  final Map<String, TvBrowseRailLayoutMetrics> _metricsByHub = {};
  final Map<String, double> _scaleByHub = {};
  final Map<String, TvRailTrailing> _lastTrailingByHubId = {};

  int _hubIndex = 0;
  int _itemIndex = 0;

  /// Mirrors (_hubIndex, _itemIndex) for the per-card focus selectors, so
  /// plain left/right moves repaint only the two affected cards instead of
  /// setState-rebuilding every visible row (expensive on low-end TVs).
  final _RailFocusPosition _focusPosition = _RailFocusPosition();
  List<double> _sectionOffsets = const [];
  double _sectionMaxScrollExtent = 0;
  Timer? _longPressTimer;
  Timer? _selectSuppressionTimer;
  Timer? _selectSuppressionMaxTimer;
  VoidCallback? _gestureSignalListener;
  bool _isSelectKeyDown = false;
  bool _longPressTriggered = false;
  bool _suppressSelectUntilKeyUp = false;
  bool _hasUserChangedHub = false;
  bool _hasUserChangedItem = false;

  MediaHub? get _activeHub => widget.hubs.isEmpty ? null : widget.hubs[_hubIndex.clamp(0, widget.hubs.length - 1)];

  void requestFocus() {
    _notifyFocusedItem();
    _focusNode.requestFocus();
  }

  void suppressSelectUntilKeyUp() {
    _resetLongPressState();
    _suppressSelectUntilKeyUp = true;
    _selectSuppressionTimer?.cancel();
    _selectSuppressionMaxTimer?.cancel();
    _detachGestureSignalListener();

    final gesture = widget.selectSuppressionGestureSignal;
    if (gesture != null && gesture.value) {
      // A Siri-remote touch is in progress. The stray select that would auto-play
      // a Continue Watching item is delivered within this same uninterrupted
      // touch: one physical press navigates Home, then bounces a second select
      // mid-drag (#1281). Hold suppression until the finger lifts — one
      // activation per touch, no time heuristic. The next observed select key-up
      // also clears it; the backstop only guards against a dropped touch-end.
      _gestureSignalListener = () {
        if (!(widget.selectSuppressionGestureSignal?.value ?? false)) {
          _clearSelectSuppression();
        }
      };
      gesture.addListener(_gestureSignalListener!);
      _selectSuppressionMaxTimer = Timer(_selectSuppressionGestureBackstop, _clearSelectSuppression);
    } else {
      // No touch in progress (held-key carry-over on a non-touch remote): clear
      // on the next select key-up, with the short legacy safety timeout.
      _selectSuppressionTimer = Timer(_selectSuppressionTimeout, _clearSelectSuppression);
    }
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
    _selectInitialHubIfPossible();
    final selectedInitialItem = _selectInitialItemIfPossible();
    _focusPosition.set(_hubIndex, _itemIndex, notify: false);
    _rememberTrailingStates();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.hubs.isEmpty) return;
      if (selectedInitialItem) _scrollToItem(animate: false);
      _scrollActiveHubToTop(animate: false);
      _notifyActiveHubChanged();
      _notifyFocusedItem();
      if (widget.autofocus) _focusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant TvBrowseRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    final trailingStateChanged = _hasTrailingStateChanged(widget.hubs);
    final hubStateChanged = trailingStateChanged || !_hasSameHubState(oldWidget.hubs, widget.hubs);
    final initialSelectionChanged =
        oldWidget.initialHubId != widget.initialHubId || oldWidget.initialItemId != widget.initialItemId;

    if (!hubStateChanged && !initialSelectionChanged) {
      _rememberTrailingStates();
      if (!oldWidget.autofocus && widget.autofocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focusNode.requestFocus();
        });
      }
      return;
    }

    final oldActiveHubId = oldWidget.hubs.isEmpty
        ? null
        : oldWidget.hubs[_hubIndex.clamp(0, oldWidget.hubs.length - 1)].id;

    if (widget.hubs.isEmpty) {
      _hubIndex = 0;
      _itemIndex = 0;
      _focusPosition.set(_hubIndex, _itemIndex, notify: false);
      _rememberTrailingStates();
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
    // notify:false — this runs during the build phase and the enclosing
    // rebuild already refreshes every selector.
    _focusPosition.set(_hubIndex, _itemIndex, notify: false);
    final activeHubChanged = oldActiveHubId != _activeHub?.id;
    final activeHubStateChanged =
        _hubStateChanged(oldWidget.hubs, widget.hubs, _hubIndex) ||
        (_activeHub != null && _trailingStateChanged(_activeHub!));
    final shouldJumpAlignActiveHub = selectedInitialHub || activeHubChanged || !_hasUserChangedHub;
    final shouldAnimateAlignActiveHub = !shouldJumpAlignActiveHub && activeHubStateChanged;
    _rememberTrailingStates();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (selectedInitialItem) _scrollToItem(animate: false);
      if (shouldJumpAlignActiveHub) {
        _scrollActiveHubToTop(animate: false);
      } else if (shouldAnimateAlignActiveHub) {
        _scrollActiveHubToTop();
      }
      if (!oldWidget.autofocus && widget.autofocus) _focusNode.requestFocus();
      if (activeHubChanged) _notifyActiveHubChanged();
      _notifyFocusedItem();
    });
  }

  bool _hasSameHubState(List<MediaHub> oldHubs, List<MediaHub> newHubs) {
    if (oldHubs.length != newHubs.length) return false;
    for (var i = 0; i < oldHubs.length; i++) {
      if (_hubStateChanged(oldHubs, newHubs, i)) return false;
    }
    return true;
  }

  bool _hubStateChanged(List<MediaHub> oldHubs, List<MediaHub> newHubs, int index) {
    if (index < 0 || index >= oldHubs.length || index >= newHubs.length) return true;
    final oldHub = oldHubs[index];
    final newHub = newHubs[index];
    if (oldHub.id != newHub.id || oldHub.more != newHub.more || oldHub.items.length != newHub.items.length) {
      return true;
    }
    for (var j = 0; j < oldHub.items.length; j++) {
      if (oldHub.items[j].globalKey != newHub.items[j].globalKey) return true;
    }
    return false;
  }

  bool _hasTrailingStateChanged(List<MediaHub> hubs) {
    for (final hub in hubs) {
      if (_trailingStateChanged(hub)) return true;
    }
    return false;
  }

  bool _trailingStateChanged(MediaHub hub) {
    final previous = _lastTrailingByHubId[hub.id];
    return previous != null && previous != _trailingFor(hub);
  }

  void _rememberTrailingStates() {
    _lastTrailingByHubId
      ..clear()
      ..addEntries(widget.hubs.map((hub) => MapEntry(hub.id, _trailingFor(hub))));
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _selectSuppressionTimer?.cancel();
    _selectSuppressionMaxTimer?.cancel();
    _detachGestureSignalListener();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _focusPosition.dispose();
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    _verticalController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) _resetLongPressState();
    if (_focusNode.hasFocus) _notifyFocusedItem();
    setState(() {});
  }

  void _resetLongPressState() {
    _longPressTimer?.cancel();
    _isSelectKeyDown = false;
    _longPressTriggered = false;
  }

  void _clearSelectSuppression() {
    _selectSuppressionTimer?.cancel();
    _selectSuppressionTimer = null;
    _selectSuppressionMaxTimer?.cancel();
    _selectSuppressionMaxTimer = null;
    _suppressSelectUntilKeyUp = false;
    _detachGestureSignalListener();
  }

  void _detachGestureSignalListener() {
    final listener = _gestureSignalListener;
    if (listener != null) {
      widget.selectSuppressionGestureSignal?.removeListener(listener);
      _gestureSignalListener = null;
    }
  }

  bool _hasTrailingFor(MediaHub hub) => _trailingFor(hub) != TvRailTrailing.none;

  int _totalItemCount(MediaHub hub) => hub.items.length + (_hasTrailingFor(hub) ? 1 : 0);

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
      if (_suppressSelectUntilKeyUp) {
        if (event is KeyUpEvent) _clearSelectSuppression();
        return KeyEventResult.handled;
      }

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
        // No setState: the per-card focus selectors repaint the two affected
        // cards via _focusPosition; nothing else in the rail depends on it.
        _itemIndex--;
        _hasUserChangedItem = true;
        _focusPosition.set(_hubIndex, _itemIndex);
        _rememberFocus(hub);
        _notifyFocusedItem();
        _scrollToItem(duration: event is KeyRepeatEvent ? _repeatNavigationScrollDuration : _navigationScrollDuration);
      } else {
        widget.onNavigateToSidebar?.call();
      }
      return KeyEventResult.handled;
    }

    if (key.isRightKey) {
      if (_itemIndex < _totalItemCount(hub) - 1) {
        _itemIndex++;
        _hasUserChangedItem = true;
        _focusPosition.set(_hubIndex, _itemIndex);
        _rememberFocus(hub);
        _notifyFocusedItem();
        _scrollToItem(duration: event is KeyRepeatEvent ? _repeatNavigationScrollDuration : _navigationScrollDuration);
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
    final currentHub = _activeHub;
    if (currentHub != null) _rememberFocus(currentHub);
    final nextHub = widget.hubs[next];
    final remembered = HubFocusMemory.getForHubOnly(nextHub.id, _totalItemCount(nextHub));
    setState(() {
      _hubIndex = next;
      _itemIndex = remembered.clamp(0, _totalItemCount(nextHub) == 0 ? 0 : _totalItemCount(nextHub) - 1);
      _hasUserChangedHub = true;
      _focusPosition.set(_hubIndex, _itemIndex, notify: false);
    });
    _notifyFocusedItem();
    _notifyActiveHubChanged();
    _scrollToItemAfterLayout(animate: false);
    _scrollActiveHubToTop();
  }

  void _scrollActiveHubToTop({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_verticalController.hasClients && _hubIndex >= 0 && _hubIndex < _sectionOffsets.length) {
        final target = _sectionOffsets[_hubIndex].clamp(0.0, _sectionMaxScrollExtent).toDouble();
        if (animate) {
          unawaited(
            _verticalController.animateTo(
              target,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
            ),
          );
        } else {
          _verticalController.jumpTo(target);
        }
        return;
      }

      final key = _hubSectionKeys[_hubIndex];
      final context = key?.currentContext;
      if (context == null) return;

      unawaited(
        Scrollable.ensureVisible(
          context,
          alignment: 0,
          duration: animate ? const Duration(milliseconds: 250) : Duration.zero,
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  void _setHoveredItem(MediaHub hub, int index) {
    if (_activeHub?.id != hub.id || index >= hub.items.length || _itemIndex == index) return;
    _itemIndex = index;
    _hasUserChangedItem = true;
    _focusPosition.set(_hubIndex, _itemIndex);
    _rememberFocus(hub);
    _notifyFocusedItem();
  }

  void _selectHubItem(MediaHub hub, int hubIndex, int itemIndex) {
    final totalCount = _totalItemCount(hub);
    if (totalCount == 0) return;

    final clampedItemIndex = itemIndex.clamp(0, totalCount - 1).toInt();
    final hubChanged = _hubIndex != hubIndex;
    final previousHub = _activeHub;
    if (hubChanged && previousHub != null) _rememberFocus(previousHub);
    setState(() {
      _hubIndex = hubIndex;
      _itemIndex = clampedItemIndex;
      _hasUserChangedHub = true;
      _hasUserChangedItem = true;
      _focusPosition.set(_hubIndex, _itemIndex, notify: false);
    });
    _rememberFocus(hub);
    _notifyFocusedItem();
    if (hubChanged) _notifyActiveHubChanged();
    _scrollActiveHubToTop();
    _scrollToItemAfterLayout(animate: false);
  }

  void _rememberFocus(MediaHub hub) {
    HubFocusMemory.setForHub(hub.id, _itemIndex);
  }

  void _scrollToItem({bool animate = true, Duration duration = _navigationScrollDuration}) {
    final hub = _activeHub;
    if (hub == null) return;
    final controller = _scrollControllers[hub.id];
    if (controller == null) return;
    if (controller.positions.length != 1) return;
    final metrics = _metricsByHub[hub.id];
    if (metrics == null) return;
    final scale = _scaleByHub[hub.id] ?? 1.0;
    final position = controller.position;
    final viewportWidth = position.viewportDimension;
    final maxScrollExtent = position.maxScrollExtent;
    if (!viewportWidth.isFinite || !maxScrollExtent.isFinite) return;
    final target = TvBrowseRailLayout.scrollOffsetForIndex(
      hub: hub,
      index: _itemIndex,
      metrics: metrics,
      viewportWidth: viewportWidth,
      maxScrollExtent: maxScrollExtent,
      scale: scale,
      hasTrailing: _hasTrailingFor(hub),
    );

    final distance = (position.pixels - target).abs();
    if (distance < 0.5) return;
    if (!animate || duration == Duration.zero || distance > viewportWidth * _scrollCatchUpViewportDistance) {
      position.jumpTo(target);
    } else {
      unawaited(position.animateTo(target, duration: duration, curve: Curves.easeOutCubic));
    }
  }

  void _scrollToItemAfterLayout({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToItem(animate: animate);
    });
  }

  ScrollController _scrollControllerForHub(
    MediaHub hub,
    TvBrowseRailLayoutMetrics metrics,
    double viewportWidth,
    double scale,
    int initialItemIndex,
  ) {
    return _scrollControllers.putIfAbsent(hub.id, () {
      final maxScrollExtent = TvBrowseRailLayout.estimatedMaxScrollExtent(
        hub: hub,
        metrics: metrics,
        viewportWidth: viewportWidth,
        scale: scale,
        hasTrailing: _hasTrailingFor(hub),
      );
      final initialScrollOffset = TvBrowseRailLayout.scrollOffsetForIndex(
        hub: hub,
        index: initialItemIndex,
        metrics: metrics,
        viewportWidth: viewportWidth,
        maxScrollExtent: maxScrollExtent,
        scale: scale,
        hasTrailing: _hasTrailingFor(hub),
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
    if (_itemIndex == hub.items.length && _hasTrailingFor(hub)) {
      switch (_trailingFor(hub)) {
        case TvRailTrailing.error:
          widget.onRetryHub?.call(hub);
          break;
        case TvRailTrailing.loading:
          break; // no-op while the page loads
        case TvRailTrailing.viewAll:
        case TvRailTrailing.none:
          _navigateToHubDetail(hub);
      }
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
    if (_activeHub == null) return const SizedBox.shrink();
    return SettingsBuilder(
      prefs: const [
        SettingsService.libraryDensity,
        SettingsService.episodePosterMode,
        SettingsService.tvFullCardLayout,
      ],
      builder: (context) => LayoutBuilder(
        builder: (context, constraints) {
          final svc = SettingsService.instance;
          final hasFocus = _focusNode.hasFocus;
          final theme = Theme.of(context);
          final scale = _scale(context);
          final horizontalInset = _horizontalInset(context);
          final interactionExpansion = TvBrowseRailLayout.railInteractionExpansionForScale(
            scale,
          ).clamp(0.0, horizontalInset).toDouble();
          final width = constraints.maxWidth.isFinite ? constraints.maxWidth : MediaQuery.sizeOf(context).width;
          final availableWidth = (width - horizontalInset).clamp(1.0, double.infinity).toDouble();
          final railViewportWidth = (availableWidth + interactionExpansion).clamp(1.0, double.infinity).toDouble();
          final density = svc.read(SettingsService.libraryDensity);
          final episodePosterMode = svc.read(SettingsService.episodePosterMode);
          final fullCardLayout = svc.read(SettingsService.tvFullCardLayout);
          final modes = [for (final hub in widget.hubs) widget.episodePosterModeForHub?.call(hub) ?? episodePosterMode];
          final wideScales = [
            for (final hub in widget.hubs) widget.widePosterScaleForHub?.call(hub) ?? widget.widePosterScale,
          ];
          final metricsByHub = [
            for (var i = 0; i < widget.hubs.length; i++)
              TvBrowseRailLayout.metricsForHub(
                hub: widget.hubs[i],
                availableWidth: availableWidth,
                density: density,
                episodePosterMode: modes[i],
                scale: scale,
                fullCardLayout: fullCardLayout,
                tallPosterScale: widget.tallPosterScale,
                widePosterScale: wideScales[i],
              ),
          ];
          final sectionHeights = [
            for (final metrics in metricsByHub)
              TvBrowseRailLayout.hubSectionHeightFor(scale: scale, activeRailHeight: metrics.height),
          ];
          final offsets = <double>[];
          var nextOffset = 0.0;
          for (final height in sectionHeights) {
            offsets.add(nextOffset);
            nextOffset += height;
          }
          _sectionOffsets = offsets;

          var viewportSectionHeight = 0.0;
          for (final height in sectionHeights) {
            if (height > viewportSectionHeight) viewportSectionHeight = height;
          }
          final viewportHeight = TvBrowseRailLayout.viewportHeightFor(
            hubCount: widget.hubs.length,
            scale: scale,
            sectionHeight: viewportSectionHeight,
          );
          final bottomPadding = (viewportHeight - sectionHeights.last).clamp(0.0, double.infinity).toDouble();
          _sectionMaxScrollExtent = (nextOffset + bottomPadding - viewportHeight)
              .clamp(0.0, double.infinity)
              .toDouble();
          final totalHeight =
              TvBrowseRailLayout.railTopPaddingForScale(scale) +
              viewportHeight +
              TvBrowseRailLayout.railBottomPaddingForScale(scale);
          return Focus(
            focusNode: _focusNode,
            onKeyEvent: _handleKeyEvent,
            child: Align(
              alignment: .bottomCenter,
              heightFactor: 1,
              child: SizedBox(
                height: totalHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _RailBackgroundBleed(
                      width: width,
                      targetBleedLeft: widget.backgroundBleedLeft,
                      backgroundColor: theme.scaffoldBackgroundColor,
                    ),
                    Padding(
                      padding: .fromLTRB(
                        horizontalInset,
                        TvBrowseRailLayout.railTopPaddingForScale(scale),
                        0,
                        TvBrowseRailLayout.railBottomPaddingForScale(scale),
                      ),
                      child: AnimatedOpacity(
                        opacity: hasFocus ? 1 : 0.6,
                        duration: FocusTheme.getAnimationDuration(context),
                        curve: Curves.easeOutCubic,
                        child: ClipRect(
                          clipper: _RailClipper(leftOverflow: horizontalInset, rightOverflow: 0),
                          child: SizedBox(
                            height: viewportHeight,
                            child: _buildHubSectionList(
                              hasFocus: hasFocus,
                              modes: modes,
                              metricsByHub: metricsByHub,
                              sectionHeights: sectionHeights,
                              scale: scale,
                              fullCardLayout: fullCardLayout,
                              leftOverflow: horizontalInset,
                              interactionExpansion: interactionExpansion,
                              railViewportWidth: railViewportWidth,
                              bottomPadding: bottomPadding,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHubSectionList({
    required bool hasFocus,
    required List<EpisodePosterMode> modes,
    required List<TvBrowseRailLayoutMetrics> metricsByHub,
    required List<double> sectionHeights,
    required double scale,
    required bool fullCardLayout,
    required double leftOverflow,
    required double interactionExpansion,
    required double railViewportWidth,
    required double bottomPadding,
  }) {
    return ListView.builder(
      key: const ValueKey('tv_browse_rail_vertical'),
      controller: _verticalController,
      physics: const NeverScrollableScrollPhysics(),
      clipBehavior: Clip.none,
      padding: .only(bottom: bottomPadding),
      itemExtentBuilder: (index, _) => sectionHeights[index],
      itemCount: widget.hubs.length,
      itemBuilder: (context, hubIndex) {
        final hub = widget.hubs[hubIndex];
        final isActive = hubIndex == _hubIndex;
        final metrics = metricsByHub[hubIndex];
        final sectionHeight = sectionHeights[hubIndex];

        return SizedBox(
          key: _hubSectionKeys.putIfAbsent(hubIndex, () => GlobalKey()),
          height: sectionHeight,
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              _buildHubHeader(context, hub: hub, hubIndex: hubIndex, isActive: isActive, scale: scale),
              SizedBox(height: TvBrowseRailLayout.hubStripGapForScale(scale)),
              AnimatedOpacity(
                opacity: isActive ? 1 : _inactiveHubContentOpacity,
                duration: FocusTheme.getAnimationDuration(context),
                curve: Curves.easeOutCubic,
                child: _buildHubRail(
                  hub: hub,
                  hubIndex: hubIndex,
                  hasFocus: hasFocus,
                  episodePosterMode: modes[hubIndex],
                  metrics: metrics,
                  scale: scale,
                  fullCardLayout: fullCardLayout,
                  leftOverflow: leftOverflow,
                  interactionExpansion: interactionExpansion,
                  railViewportWidth: railViewportWidth,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHubHeader(
    BuildContext context, {
    required MediaHub hub,
    required int hubIndex,
    required bool isActive,
    required double scale,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final titleColor = isActive ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.54);
    final iconColor = isActive ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.42);

    return SizedBox(
      height: TvBrowseRailLayout.hubStripHeightForScale(scale),
      child: ExcludeFocus(
        child: Align(
          alignment: .centerLeft,
          child: Row(
            children: [
              AppIcon(widget.iconForHub(hub, hubIndex), fill: 1, size: 20 * scale, color: iconColor),
              SizedBox(width: 8 * scale),
              Expanded(
                child: Text(
                  hub.title,
                  maxLines: 1,
                  overflow: .ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: titleColor,
                    fontSize: 18 * scale,
                    height: 1,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ),
              if (_trailingFor(hub) == TvRailTrailing.viewAll) ...[
                SizedBox(width: 8 * scale),
                AppIcon(Symbols.chevron_right_rounded, fill: 1, size: 20 * scale, color: iconColor),
                SizedBox(width: 30 * scale),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHubRail({
    required MediaHub hub,
    required int hubIndex,
    required bool hasFocus,
    required EpisodePosterMode episodePosterMode,
    required TvBrowseRailLayoutMetrics metrics,
    required double scale,
    required bool fullCardLayout,
    required double leftOverflow,
    required double interactionExpansion,
    required double railViewportWidth,
  }) {
    final isActiveHub = hubIndex == _hubIndex;
    final totalCount = _totalItemCount(hub);
    final inactiveIndex = HubFocusMemory.getForHubOnly(hub.id, totalCount);
    final focusedIndex = isActiveHub ? _itemIndex : inactiveIndex;
    final scrollController = _scrollControllerForHub(hub, metrics, railViewportWidth, scale, focusedIndex);
    _metricsByHub[hub.id] = metrics;
    _scaleByHub[hub.id] = scale;

    return Transform.translate(
      offset: Offset(-interactionExpansion, 0),
      child: SizedBox(
        width: railViewportWidth,
        height: metrics.height,
        child: ClipRect(
          clipper: _RailClipper(
            leftOverflow: leftOverflow,
            rightOverflow: metrics.railEdgePadding + metrics.cardWidth + metrics.itemGap,
            verticalOverflow: metrics.focusExtra,
          ),
          child: HorizontalScrollWithArrows(
            controller: scrollController,
            builder: (scrollController) => ListView.builder(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: .fromLTRB(metrics.railEdgePadding, 2 * scale, metrics.railEdgePadding, 6 * scale),
              itemExtentBuilder: (itemIndex, _) => TvBrowseRailLayout.itemExtentForIndex(
                hub: hub,
                index: itemIndex,
                metrics: metrics,
                scale: scale,
                hasTrailing: _hasTrailingFor(hub),
              ),
              itemCount: totalCount,
              itemBuilder: (context, itemIndex) {
                // Focus is observed through _focusPosition so a d-pad move
                // rebuilds only the cheap wrapper of the two affected cards;
                // the card content below is passed through as a stable child.
                bool isItemFocused() => hasFocus && _focusPosition.value == (hubIndex, itemIndex);

                if (itemIndex == hub.items.length) {
                  return Padding(
                    padding: .only(right: metrics.itemGap),
                    child: Align(
                      alignment: .centerLeft,
                      child: ListenableSelector<bool>(
                        listenable: _focusPosition,
                        selector: isItemFocused,
                        builder: (context, isFocused, _) =>
                            _buildTrailingSlot(context, hub, hubIndex, itemIndex, isFocused: isFocused, scale: scale),
                      ),
                    ),
                  );
                }

                final item = hub.items[itemIndex];
                final focusableCard = ListenableSelector<bool>(
                  listenable: _focusPosition,
                  selector: isItemFocused,
                  builder: (context, isFocused, child) => FocusBuilders.buildLockedFocusWrapper(
                    context: context,
                    isFocused: isFocused,
                    borderRadius: tokens(context).radiusSm,
                    focusScale: fullCardLayout ? TvBrowseRailLayout.fullCardFocusScale : FocusTheme.focusScale,
                    useFocusGlow: fullCardLayout,
                    // The card draws the border itself (poster rect for
                    // standard cards, whole card when full-bleed).
                    delegateFocusBorder: true,
                    glowSize: fullCardLayout ? Size(metrics.cardWidth, metrics.posterHeight) : null,
                    onTap: () {
                      _selectHubItem(hub, hubIndex, itemIndex);
                      unawaited(_activateCurrentItem());
                    },
                    onLongPress: metrics.isPersonHub
                        ? null
                        : () {
                            _selectHubItem(hub, hubIndex, itemIndex);
                            _cardKeyFor(hub, itemIndex).currentState?.showContextMenu();
                          },
                    child: child!,
                  ),
                  // MergeSemantics: one node per card (MediaCard merges
                  // internally) — the per-frame semantics pass scales with
                  // node count on TV boxes with an accessibility service.
                  child: metrics.isPersonHub
                      ? MergeSemantics(
                          child: _buildPersonCard(
                            context,
                            item,
                            cardWidth: metrics.cardWidth,
                            imageSize: metrics.posterHeight,
                            scale: scale,
                            fullCardLayout: fullCardLayout,
                          ),
                        )
                      : MediaCard(
                          key: _cardKeyFor(hub, itemIndex),
                          item: item,
                          width: metrics.cardWidth,
                          height: metrics.posterHeight,
                          onRefresh: widget.onRefresh,
                          onRemoveFromContinueWatching: widget.onRemoveFromContinueWatching,
                          forceGridMode: true,
                          fullBleedImage: fullCardLayout,
                          isInContinueWatching: widget.isContinueWatchingHub?.call(hub) ?? false,
                          mixedHubContext: metrics.isMixedHub,
                          episodePosterModeOverride: episodePosterMode,
                        ),
                );

                return Padding(
                  padding: .only(right: metrics.itemGap),
                  child: MouseRegion(
                    onEnter: (_) => _setHoveredItem(hub, itemIndex),
                    child: Align(alignment: .topLeft, child: focusableCard),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonCard(
    BuildContext context,
    MediaItem item, {
    required double cardWidth,
    required double imageSize,
    required double scale,
    required bool fullCardLayout,
  }) {
    final theme = Theme.of(context);
    final characterName = item.parentTitle;

    if (fullCardLayout) {
      return SizedBox(
        width: cardWidth,
        height: imageSize,
        child: CardFocusBorder(
          borderRadius: tokens(context).radiusSm,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(tokens(context).radiusSm),
            child: Stack(
              fit: StackFit.expand,
              children: [
                OptimizedMediaImage(
                  client: context.tryGetMediaClientWithFallback(serverIdOrNull(item.serverId)),
                  imagePath: item.thumbPath,
                  width: cardWidth,
                  height: imageSize,
                  fit: BoxFit.cover,
                  imageType: ImageType.avatar,
                  fallbackIcon: Symbols.person_rounded,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.78)],
                      stops: const [0.45, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  left: 10 * scale,
                  right: 10 * scale,
                  bottom: 9 * scale,
                  child: Column(
                    mainAxisSize: .min,
                    crossAxisAlignment: .start,
                    children: [
                      Text(
                        item.displayTitle,
                        maxLines: 1,
                        overflow: .ellipsis,
                        style: TextStyle(color: Colors.white, fontSize: 13 * scale, height: 1.1, fontWeight: .w800),
                      ),
                      if (characterName != null && characterName.isNotEmpty) ...[
                        SizedBox(height: 2 * scale),
                        Text(
                          characterName,
                          maxLines: 1,
                          overflow: .ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 11 * scale,
                            height: 1.1,
                            fontWeight: .w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: cardWidth,
      child: Padding(
        padding: .fromLTRB(3 * scale, 3 * scale, 3 * scale, scale),
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            CardFocusBorder(
              borderRadius: tokens(context).radiusSm,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(tokens(context).radiusSm),
                child: OptimizedMediaImage(
                  client: context.tryGetMediaClientWithFallback(serverIdOrNull(item.serverId)),
                  imagePath: item.thumbPath,
                  width: imageSize,
                  height: imageSize,
                  fit: BoxFit.cover,
                  imageType: ImageType.avatar,
                  fallbackIcon: Symbols.person_rounded,
                ),
              ),
            ),
            SizedBox(height: 6 * scale),
            Text(
              item.displayTitle,
              maxLines: 1,
              overflow: .ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens(context).text,
                fontSize: 13 * scale,
                height: 1.1,
                fontWeight: .w700,
              ),
            ),
            if (characterName != null && characterName.isNotEmpty) ...[
              SizedBox(height: 2 * scale),
              Text(
                characterName,
                maxLines: 1,
                overflow: .ellipsis,
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

  /// Resolve the trailing-slot state for [hub], defaulting to the legacy
  /// "[MediaHub.more] → View All" behavior when no resolver was supplied.
  TvRailTrailing _trailingFor(MediaHub hub) =>
      widget.trailingForHub?.call(hub) ?? (hub.more ? TvRailTrailing.viewAll : TvRailTrailing.none);

  Widget _buildTrailingSlot(
    BuildContext context,
    MediaHub hub,
    int hubIndex,
    int itemIndex, {
    required bool isFocused,
    required double scale,
  }) {
    switch (_trailingFor(hub)) {
      case TvRailTrailing.loading:
        return _buildTrailingSpinner(context, isFocused: isFocused, scale: scale);
      case TvRailTrailing.error:
        return _buildViewAllButton(
          context,
          isFocused: isFocused,
          scale: scale,
          label: t.common.retry,
          icon: Symbols.refresh_rounded,
          onTap: () {
            _selectHubItem(hub, hubIndex, itemIndex);
            widget.onRetryHub?.call(hub);
          },
        );
      case TvRailTrailing.viewAll:
        return _buildViewAllButton(
          context,
          isFocused: isFocused,
          scale: scale,
          onTap: () {
            _selectHubItem(hub, hubIndex, itemIndex);
            _navigateToHubDetail(hub);
          },
        );
      case TvRailTrailing.none:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTrailingSpinner(BuildContext context, {required bool isFocused, required double scale}) {
    final theme = Theme.of(context);
    final duration = FocusTheme.getAnimationDuration(context);
    final width = TvBrowseRailLayout.viewAllItemWidthForScale(scale);
    final height = TvBrowseRailLayout.viewAllPillHeightForScale(scale);
    final foreground = isFocused ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.78);
    final background = isFocused
        ? theme.colorScheme.primary.withValues(alpha: 0.2)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.18);
    return AnimatedScale(
      scale: isFocused ? 1.04 : 1.0,
      duration: duration,
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOutCubic,
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(height / 2),
          boxShadow: isFocused
              ? [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.2), blurRadius: 18, spreadRadius: 1)]
              : null,
        ),
        child: Center(
          child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: foreground)),
        ),
      ),
    );
  }

  Widget _buildViewAllButton(
    BuildContext context, {
    required bool isFocused,
    required double scale,
    required VoidCallback onTap,
    String? label,
    IconData icon = Symbols.arrow_forward_rounded,
  }) {
    final theme = Theme.of(context);
    final duration = FocusTheme.getAnimationDuration(context);
    final width = TvBrowseRailLayout.viewAllItemWidthForScale(scale);
    final height = TvBrowseRailLayout.viewAllPillHeightForScale(scale);
    final foreground = isFocused ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.78);
    final background = isFocused
        ? theme.colorScheme.primary.withValues(alpha: 0.2)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.42);

    return ClickableCursor(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: isFocused ? 1.04 : 1.0,
          duration: duration,
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutCubic,
            width: width,
            height: height,
            padding: .symmetric(horizontal: (12 * scale).clamp(10, 16).toDouble()),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(height / 2),
              boxShadow: isFocused
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: .center,
              children: [
                Flexible(
                  child: Text(
                    label ?? t.common.viewAll,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: (13 * scale).clamp(12, 16).toDouble(),
                      fontWeight: .w800,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                SizedBox(width: (5 * scale).clamp(4, 7).toDouble()),
                AppIcon(icon, fill: 1, size: (18 * scale).clamp(16, 22).toDouble(), color: foreground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RailBackgroundBleed extends StatelessWidget {
  final double width;

  /// Explicit target; when null the value comes from [MainScreenFocusScope]
  /// (offset aspect) so sidebar flips rebuild only this widget, not the rail.
  final double? targetBleedLeft;
  final Color backgroundColor;

  const _RailBackgroundBleed({required this.width, required this.targetBleedLeft, required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    final target = targetBleedLeft ?? MainScreenFocusScope.sideNavigationBleedOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: target),
      duration: FocusTheme.getAnimationDuration(context),
      curve: Curves.easeOutCubic,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, backgroundColor.withValues(alpha: 0.7)],
          ),
        ),
      ),
      builder: (context, bleedLeft, child) {
        final backgroundWidth = math.max(width + bleedLeft, MediaQuery.sizeOf(context).width);
        return Positioned(top: 0, bottom: 0, left: -bleedLeft, width: backgroundWidth, child: child!);
      },
    );
  }
}

class _RailClipper extends CustomClipper<Rect> {
  final double leftOverflow;
  final double rightOverflow;
  final double topOverflow;
  final double bottomOverflow;

  const _RailClipper({
    this.leftOverflow = 0,
    required this.rightOverflow,
    double verticalOverflow = 0,
    double? topOverflow,
    double? bottomOverflow,
  }) : topOverflow = topOverflow ?? verticalOverflow,
       bottomOverflow = bottomOverflow ?? verticalOverflow;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(-leftOverflow, -topOverflow, size.width + rightOverflow, size.height + bottomOverflow);

  @override
  bool shouldReclip(covariant _RailClipper oldClipper) {
    return oldClipper.leftOverflow != leftOverflow ||
        oldClipper.rightOverflow != rightOverflow ||
        oldClipper.topOverflow != topOverflow ||
        oldClipper.bottomOverflow != bottomOverflow;
  }
}

/// (hubIndex, itemIndex) focus position observed by the per-card
/// [ListenableSelector]s. `notify: false` covers build-phase syncs
/// (initState/didUpdateWidget/setState), where notifying would call setState
/// on descendants mid-build and the enclosing rebuild refreshes the selectors
/// anyway.
class _RailFocusPosition extends ChangeNotifier {
  (int, int) _value = (0, 0);

  (int, int) get value => _value;

  void set(int hubIndex, int itemIndex, {bool notify = true}) {
    final next = (hubIndex, itemIndex);
    if (next == _value) return;
    _value = next;
    if (notify) notifyListeners();
  }
}
