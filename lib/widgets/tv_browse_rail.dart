import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../focus/card_focus_scope.dart';
import '../focus/dpad_navigator.dart';
import '../focus/dpad_select_long_press_controller.dart';
import '../focus/focus_theme.dart';
import '../focus/key_event_utils.dart';
import '../focus/focus_navigation_intent.dart';
import '../focus/locked_hub_controller.dart';
import '../i18n/strings.g.dart';
import '../media/ids.dart';
import '../media/media_hub.dart';
import '../media/media_item.dart';
import '../navigation/main_screen_scope.dart';
import '../screens/hub_detail_screen.dart';
import '../services/device_performance.dart';
import '../services/settings_service.dart';
import '../theme/mono_tokens.dart';
import '../utils/layout_constants.dart';
import '../utils/media_image_helper.dart';
import '../utils/media_navigation_helper.dart';
import '../utils/provider_extensions.dart';
import 'animated_dim_scrim.dart';
import 'app_icon.dart';
import 'clickable_cursor.dart';
import 'focus_builders.dart';
import 'horizontal_scroll_with_arrows.dart';
import 'listenable_selector.dart';
import 'media_card.dart';
import 'media_context_menu.dart';
import 'optimized_media_image.dart';
import 'rasterized_gradient.dart';
import 'settings_builder.dart';

const _inactiveArtworkDimAlpha = 0.3;

class TvBrowseRailLayoutMetrics {
  final bool isPersonHub;
  final bool isMixedHub;
  final bool useWideLayout;
  final double focusExtra;
  final double railEdgePadding;
  final double itemGap;

  /// Whether the hub has a leading options card in the negative-offset region
  /// before the row's scroll anchor (see [TvBrowseRailLayout.minScrollExtentFor]).
  final bool hasLeading;
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
    this.hasLeading = false,
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

  static double fullCardItemGapForScale(double scale) => (12 * scale).clamp(8, 18).toDouble();

  static double hubStripHeightForScale(double scale) => 30 * scale;

  static double nextHubPeekHeightForScale(double scale) => 20 * scale;

  static double hubSectionHeightFor({required double scale, required double activeRailHeight}) {
    return hubStripHeightForScale(scale) + activeRailHeight;
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
    bool hasLeading = false,
  }) {
    final focusExtra = FocusTheme.focusBorderWidth * 2 * scale;
    final railEdgePadding = focusExtra + (12 * scale);
    final itemGap = fullCardLayout ? fullCardItemGapForScale(scale) : 0.0;
    final isPersonHub = TvBrowseRailLayout.isPersonHub(hub);
    final emptyEpisodeThumbnailHub =
        hub.items.isEmpty && hub.type == 'episode' && episodePosterMode == EpisodePosterMode.episodeThumbnail;
    final hasWide =
        !isPersonHub &&
        (emptyEpisodeThumbnailHub || hub.items.any((item) => item.usesWideAspectRatio(episodePosterMode)));
    final hasTall = !isPersonHub && hub.items.any((item) => !item.usesWideAspectRatio(episodePosterMode));
    final isMixedHub = hasWide && hasTall;
    final useWideLayout = hasWide && (!hasTall || episodePosterMode == EpisodePosterMode.episodeThumbnail);
    // Music hubs render square album/artist artwork (person hubs are already square).
    final isSquareHub =
        !isPersonHub &&
        hub.items.isNotEmpty &&
        hub.items.every((item) => item.cardShape(episodePosterMode) == CardShape.square);
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
    final posterHeight = (isPersonHub || isSquareHub)
        ? posterWidth
        : (useWideLayout ? posterWidth * 9 / 16 : posterWidth * 1.5);
    final labelHeight = fullCardLayout ? 0.0 : ((isPersonHub ? 52 : 36) * scale);
    final containerHeight = (posterHeight + labelHeight).ceilToDouble();
    final height = containerHeight + focusExtra + (10 * scale);

    return TvBrowseRailLayoutMetrics(
      isPersonHub: isPersonHub,
      isMixedHub: isMixedHub,
      useWideLayout: useWideLayout,
      focusExtra: focusExtra,
      railEdgePadding: railEdgePadding,
      itemGap: itemGap,
      hasLeading: hasLeading,
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
    bool? hasTrailing,
  }) {
    final showTrailing = hasTrailing ?? hub.more;
    final itemCount = hub.items.length + (showTrailing ? 1 : 0);
    // The leading options card lives BEFORE the scroll anchor (negative
    // offsets, see [minScrollExtentFor]); it never contributes here.
    final contentWidth = (metrics.railEdgePadding * 2) + (itemCount * (metrics.cardWidth + metrics.itemGap));
    return (contentWidth - viewportWidth).clamp(0.0, double.infinity).toDouble();
  }

  /// Scroll extent of the region before the anchor: the hub's leading options
  /// card plus its edge padding. Zero for hubs without a leading slot, so the
  /// row rests with its first item at the rail start and the options card
  /// sits off-screen until focus (or a drag) reveals it.
  static double minScrollExtentFor(TvBrowseRailLayoutMetrics metrics) =>
      metrics.hasLeading ? -(metrics.railEdgePadding + metrics.cardWidth) : 0.0;

  static double itemExtentForIndex({required int index, required TvBrowseRailLayoutMetrics metrics}) {
    assert(index >= 0);
    return metrics.cardWidth + metrics.itemGap;
  }

  static double scrollOffsetForIndex({
    required MediaHub hub,
    required int index,
    required TvBrowseRailLayoutMetrics metrics,
    required double viewportWidth,
    required double maxScrollExtent,
    bool? hasTrailing,
  }) {
    final showTrailing = hasTrailing ?? hub.more;
    final leadingCount = metrics.hasLeading ? 1 : 0;
    final totalCount = leadingCount + hub.items.length + (showTrailing ? 1 : 0);
    if (totalCount == 0) return 0;

    final clampedIndex = index.clamp(0, totalCount - 1).toInt();
    if (metrics.hasLeading && clampedIndex == 0) return minScrollExtentFor(metrics);
    final itemExtent = metrics.cardWidth + metrics.itemGap;
    final targetCenter = metrics.railEdgePadding + ((clampedIndex - leadingCount + 0.5) * itemExtent);
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
  final HubFocusMemory focusMemory;
  final IconData Function(MediaHub hub, int index) iconForHub;

  /// Whether to show each hub's originating server name in its header. Used when
  /// the loaded hubs span more than one connected server so their origin stays
  /// clear, mirroring the mobile [HubSection] behavior.
  final bool showServerName;
  final ValueChanged<MediaItem>? onFocusedItemChanged;
  final void Function(MediaHub hub, MediaItem item)? onFocusedHubItemChanged;
  final void Function(MediaItem source)? onRefresh;
  final VoidCallback? onRemoveFromContinueWatching;
  final bool Function(MediaHub hub)? isContinueWatchingHub;
  final bool Function(MediaHub hub)? usesContinueWatchingAction;
  final Future<List<MediaItem>> Function(MediaHub hub)? loadMoreItems;

  /// Optional per-hub trailing-slot state (loading/error/viewAll). When null the
  /// rail keeps the legacy "[MediaHub.more] → View All" behavior.
  final TvRailTrailing Function(MediaHub hub)? trailingForHub;

  /// Optional per-hub leading slot: a compact options button before the first
  /// item that opens the context menu for the returned [MediaItem] (the media
  /// detail screen returns each episode hub's season). Presence must be stable
  /// per hub key across rebuilds — slot indices are not remapped when a hub
  /// gains or loses its leading slot.
  final MediaItem? Function(MediaHub hub)? leadingItemForHub;

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

  const TvBrowseRail({
    super.key,
    required this.hubs,
    required this.focusMemory,
    required this.iconForHub,
    this.showServerName = false,
    this.onFocusedItemChanged,
    this.onFocusedHubItemChanged,
    this.onRefresh,
    this.onRemoveFromContinueWatching,
    this.isContinueWatchingHub,
    this.usesContinueWatchingAction,
    this.loadMoreItems,
    this.trailingForHub,
    this.leadingItemForHub,
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
  });

  @override
  State<TvBrowseRail> createState() => TvBrowseRailState();
}

class TvBrowseRailState extends State<TvBrowseRail> with TickerProviderStateMixin {
  // Native tvOS focus-engine scroll settles over ~450-900ms of ease-out
  // (FocusProbe capture, issue #2006). Successive steps — including
  // hold-repeats — retarget the animation, so a sustained drag trails the
  // focused index slightly and catches up in one continuous glide on
  // release, exactly like the native engine's scrollable containers.
  static const _navigationScrollDuration = Duration(milliseconds: 500);
  static const _scrollCatchUpViewportDistance = 2.5;
  // Equivalent to the former whole-rail Opacity(0.6) without keeping a
  // full-viewport saveLayer alive.
  static const _unfocusedRailDimAlpha = 0.4;

  late final FocusNode _focusNode = LockedFocusRowNode(debugLabel: 'tv_browse_rail', focusedItemRect: _focusedCardRect);
  final Map<String, ScrollController> _scrollControllers = {};
  final ScrollController _verticalController = ScrollController();
  final SnapshotController _verticalScrollSnapshotController = SnapshotController();
  final Map<int, GlobalKey> _hubSectionKeys = {};
  final Map<String, GlobalKey<MediaCardState>> _mediaCardKeys = {};
  final Map<String, TvBrowseRailLayoutMetrics> _metricsByHub = {};
  final Map<String, TvRailTrailing> _lastTrailingByHubKey = {};
  final Map<String, GlobalKey<MediaContextMenuState>> _leadingMenuKeys = {};
  final Map<int, _HubArtworkDim> _artworkDims = {};

  int _hubIndex = 0;
  int _itemIndex = 0;

  /// Mirrors (_hubIndex, _itemIndex) plus the rail's focus state for the
  /// per-card/header/artwork-dim selectors, so d-pad moves and focus flips repaint
  /// only the affected subtrees instead of setState-rebuilding every visible
  /// row (expensive on low-end TVs).
  final _RailFocusModel _focusModel = _RailFocusModel();
  List<double> _sectionOffsets = const [];
  double _sectionMaxScrollExtent = 0;
  final _selectLongPress = DpadSelectLongPressController();
  bool _hasUserInteracted = false;
  bool _hasUserChangedHub = false;
  int _verticalScrollGeneration = 0;
  bool _hasUserChangedItem = false;

  /// Hub key whose leading slot took focus only because the hub had no items
  /// yet (the clamp in [_moveHub]); when items arrive, focus advances to the
  /// first item so entering a not-yet-fetched hub still lands on item 1.
  String? _pendingLeadingAutoAdvanceHubKey;

  MediaHub? get _activeHub => widget.hubs.isEmpty ? null : widget.hubs[_hubIndex.clamp(0, widget.hubs.length - 1)];

  void requestFocus() {
    _notifyFocusedItem();
    _focusNode.requestFocus();
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
    final startHub = _activeHub;
    if (startHub != null) _itemIndex = _defaultSlotFor(startHub);
    _selectInitialHubIfPossible();
    final selectedInitialItem = _selectInitialItemIfPossible();
    _focusModel.set(_hubIndex, _itemIndex, notify: false);
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
    if (widget.hubs.length < oldWidget.hubs.length) {
      _artworkDims.removeWhere((index, dim) {
        if (index < widget.hubs.length) return false;
        dim.dispose();
        return true;
      });
    }
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

    final oldActiveHub = oldWidget.hubs.isEmpty ? null : oldWidget.hubs[_hubIndex.clamp(0, oldWidget.hubs.length - 1)];
    final oldActiveHubKey = oldActiveHub == null ? null : _hubKey(oldActiveHub);
    final oldFocusedItem = oldActiveHub == null ? null : _itemAtSlot(oldActiveHub, _itemIndex);

    if (widget.hubs.isEmpty) {
      _hubIndex = 0;
      _itemIndex = 0;
      _focusModel.set(_hubIndex, _itemIndex, notify: false);
      _rememberTrailingStates();
      return;
    }

    final selectedInitialHub = _selectInitialHubIfPossible();
    if (!selectedInitialHub && oldActiveHubKey != null) {
      final preservedIndex = widget.hubs.indexWhere((hub) => _hubKey(hub) == oldActiveHubKey);
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
    var followedFocusedItem = false;
    if (_hasUserInteracted && oldFocusedItem != null && _hubKey(hub) == oldActiveHubKey) {
      // Keep the selection on the media it was on when the active hub's items
      // reorder underneath it — a Continue Watching refresh after playback
      // moves the just-played item to the front (#1987). When the exact item
      // left the list, follow its series' replacement entry (finished episode
      // → next episode); otherwise fall through to the positional clamp.
      final followedIndex = followItemIndex(hub.items, oldFocusedItem);
      final followedSlot = followedIndex == -1 ? -1 : followedIndex + _leadingCountFor(hub);
      if (followedSlot != -1 && followedSlot != _itemIndex) {
        _itemIndex = followedSlot;
        followedFocusedItem = true;
      }
    }
    _itemIndex = _itemIndex.clamp(0, _totalItemCount(hub) == 0 ? 0 : _totalItemCount(hub) - 1);
    var autoAdvancedFromLeading = false;
    if (_pendingLeadingAutoAdvanceHubKey == _hubKey(hub) && hub.items.isNotEmpty) {
      if (_isLeadingSlot(hub, _itemIndex)) {
        _itemIndex = _defaultSlotFor(hub);
        widget.focusMemory.remapForHub(_hubKey(hub), _itemIndex);
        autoAdvancedFromLeading = true;
      }
      _pendingLeadingAutoAdvanceHubKey = null;
    }
    final selectedInitialItem = _selectInitialItemIfPossible();
    // notify:false — this runs during the build phase and the enclosing
    // rebuild already refreshes every selector.
    _focusModel.set(_hubIndex, _itemIndex, notify: false);
    final newActiveHub = _activeHub;
    final activeHubChanged = oldActiveHubKey != (newActiveHub == null ? null : _hubKey(newActiveHub));
    final activeHubStateChanged =
        _hubStateChanged(oldWidget.hubs, widget.hubs, _hubIndex) ||
        (_activeHub != null && _trailingStateChanged(_activeHub!));
    final shouldJumpAlignActiveHub = selectedInitialHub || activeHubChanged || !_hasUserChangedHub;
    final shouldAnimateAlignActiveHub = !shouldJumpAlignActiveHub && activeHubStateChanged;
    _rememberTrailingStates();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (selectedInitialItem || followedFocusedItem || autoAdvancedFromLeading) _scrollToItem(animate: false);
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
    if (_hubKey(oldHub) != _hubKey(newHub) ||
        oldHub.more != newHub.more ||
        oldHub.items.length != newHub.items.length) {
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
    final previous = _lastTrailingByHubKey[_hubKey(hub)];
    return previous != null && previous != _trailingFor(hub);
  }

  void _rememberTrailingStates() {
    _lastTrailingByHubKey
      ..clear()
      ..addEntries(widget.hubs.map((hub) => MapEntry(_hubKey(hub), _trailingFor(hub))));
  }

  @override
  void dispose() {
    _selectLongPress.dispose();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    for (final dim in _artworkDims.values) {
      dim.dispose();
    }
    _focusModel.dispose();
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    _verticalController.dispose();
    _verticalScrollGeneration++;
    _verticalScrollSnapshotController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) _resetLongPressState();
    if (_focusNode.hasFocus) _notifyFocusedItem();
    // No setState: rail focus is observed through _focusModel selectors
    // (per-card focus wrappers, headers and artwork dim), so a focus flip
    // repaints only those subtrees instead of rebuilding every visible row.
    _focusModel.setRailFocus(_focusNode.hasFocus);
  }

  void _resetLongPressState() {
    _selectLongPress.reset();
  }

  bool _hasTrailingFor(MediaHub hub) => _trailingFor(hub) != TvRailTrailing.none;

  MediaItem? _leadingItemFor(MediaHub hub) => widget.leadingItemForHub?.call(hub);

  bool _hasLeadingFor(MediaHub hub) => _leadingItemFor(hub) != null;

  int _leadingCountFor(MediaHub hub) => _hasLeadingFor(hub) ? 1 : 0;

  bool _isLeadingSlot(MediaHub hub, int slot) => slot == 0 && _hasLeadingFor(hub);

  bool _isTrailingSlot(MediaHub hub, int slot) =>
      _hasTrailingFor(hub) && slot == _leadingCountFor(hub) + hub.items.length;

  /// The media item shown at [slot], or null for the leading/trailing slots.
  MediaItem? _itemAtSlot(MediaHub hub, int slot) {
    final index = slot - _leadingCountFor(hub);
    return index >= 0 && index < hub.items.length ? hub.items[index] : null;
  }

  /// Where focus lands in [hub] with no remembered position: the first media
  /// item, so a leading slot never adds a step to normal navigation.
  int _defaultSlotFor(MediaHub hub) {
    final total = _totalItemCount(hub);
    return total == 0 ? 0 : _leadingCountFor(hub).clamp(0, total - 1);
  }

  int _totalItemCount(MediaHub hub) => _leadingCountFor(hub) + hub.items.length + (_hasTrailingFor(hub) ? 1 : 0);

  bool _isPersonHub(MediaHub hub) => TvBrowseRailLayout.isPersonHub(hub);

  void _notifyFocusedItem() {
    final hub = _activeHub;
    if (hub == null) return;
    final item = _itemAtSlot(hub, _itemIndex);
    if (item == null) return;
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
    if (_hasUserInteracted ||
        _hasUserChangedHub ||
        _hasUserChangedItem ||
        initialHubId == null ||
        widget.hubs.isEmpty) {
      return false;
    }
    // External contract: `initialHubId` is a bare `hub.id` supplied by the
    // single-server media-detail caller, so match on `hub.id` (not `_hubKey`).
    final initialIndex = widget.hubs.indexWhere((hub) => hub.id == initialHubId);
    if (initialIndex == -1) return false;
    if (initialIndex != _hubIndex) {
      _hubIndex = initialIndex;
      _itemIndex = _defaultSlotFor(widget.hubs[initialIndex]);
    }
    return true;
  }

  bool _selectInitialItemIfPossible() {
    final initialItemId = widget.initialItemId;
    final hub = _activeHub;
    if (_hasUserInteracted || _hasUserChangedHub || _hasUserChangedItem || initialItemId == null || hub == null) {
      return false;
    }
    final initialIndex = hub.items.indexWhere((item) => item.id == initialItemId);
    if (initialIndex == -1) return false;
    final initialSlot = initialIndex + _leadingCountFor(hub);
    if (initialSlot != _itemIndex) _itemIndex = initialSlot;
    return true;
  }

  _HubArtworkDim _artworkDimForHub(BuildContext context, int hubIndex) => _artworkDims.putIfAbsent(
    hubIndex,
    () => _HubArtworkDim(_focusModel, hubIndex, vsync: this, duration: FocusTheme.getAnimationDuration(context)),
  );

  KeyEventResult _handleKeyEvent(FocusNode _, KeyEvent event) {
    final key = event.logicalKey;

    if (key.isSelectKey) {
      _hasUserInteracted = true;

      return _selectLongPress.handleKeyEvent(
        event,
        isOwnerActive: () => mounted,
        onShortPress: _activateCurrentItem,
        onLongPress: _showContextMenuForCurrentItem,
      );
    }

    if (widget.onBack != null) {
      final backResult = handleBackKeyAction(event, widget.onBack!);
      if (backResult != KeyEventResult.ignored) {
        _hasUserInteracted = true;
        return backResult;
      }
    }

    if (key.isDpadDirection && event is KeyUpEvent) return KeyEventResult.handled;

    if (!event.isActionable) return KeyEventResult.ignored;
    final hub = _activeHub;
    if (hub == null) return KeyEventResult.ignored;
    if (key.isDpadDirection || key.isContextMenuKey) _hasUserInteracted = true;

    if (key.isLeftKey) {
      if (_itemIndex > 0) {
        _moveItem(-1);
      } else {
        widget.onNavigateToSidebar?.call();
      }
      return KeyEventResult.handled;
    }

    if (key.isRightKey) {
      if (_itemIndex < _totalItemCount(hub) - 1) {
        _moveItem(1);
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

  void _moveItem(int delta, {Duration duration = _navigationScrollDuration}) {
    final hub = _activeHub;
    if (hub == null) return;
    _hasUserInteracted = true;
    final next = (_itemIndex + delta).clamp(0, _totalItemCount(hub) - 1);
    if (next == _itemIndex) return;

    // No setState: the per-card focus selectors and the fixed semantics proxy
    // observe the selection through _focusModel.
    _itemIndex = next;
    _hasUserChangedItem = true;
    _pendingLeadingAutoAdvanceHubKey = null;
    _focusModel.set(_hubIndex, _itemIndex);
    _rememberFocus(hub);
    _notifyFocusedItem();
    _scrollToItem(duration: duration);
  }

  void _moveHub(int delta) {
    if (widget.hubs.isEmpty) return;
    _hasUserInteracted = true;
    final next = (_hubIndex + delta).clamp(0, widget.hubs.length - 1);
    if (next == _hubIndex) return;
    final currentHub = _activeHub;
    if (currentHub != null) _rememberFocus(currentHub);
    final nextHub = widget.hubs[next];
    final remembered = widget.focusMemory.getForHubOnly(
      _hubKey(nextHub),
      _totalItemCount(nextHub),
      fallback: _defaultSlotFor(nextHub),
    );
    // No setState: the active-hub change is observed through _focusModel
    // selectors (cards, headers, artwork dim), so a hub move repaints only the
    // two affected rows instead of rebuilding every visible card. Section
    // extents don't depend on the active hub, so no relayout is needed.
    _hubIndex = next;
    _itemIndex = remembered.clamp(0, _totalItemCount(nextHub) == 0 ? 0 : _totalItemCount(nextHub) - 1);
    // Landing on the leading slot only because the hub has no items yet is a
    // clamp artifact, not a choice: advance to the first item once they load.
    _pendingLeadingAutoAdvanceHubKey = nextHub.items.isEmpty && _isLeadingSlot(nextHub, _itemIndex)
        ? _hubKey(nextHub)
        : null;
    _hasUserChangedHub = true;
    _focusModel.set(_hubIndex, _itemIndex);
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
          _startVerticalScrollAnimation(
            () =>
                _verticalController.animateTo(target, duration: _navigationScrollDuration, curve: Curves.easeOutCubic),
          );
        } else {
          _verticalScrollGeneration++;
          _focusModel.verticalScrollActive = false;
          _verticalScrollSnapshotController.allowSnapshotting = false;
          _verticalController.jumpTo(target);
        }
        return;
      }

      final key = _hubSectionKeys[_hubIndex];
      final context = key?.currentContext;
      if (context == null) return;
      if (animate) {
        _startVerticalScrollAnimation(
          () => Scrollable.ensureVisible(
            context,
            alignment: 0,
            duration: _navigationScrollDuration,
            curve: Curves.easeOutCubic,
          ),
        );
      } else {
        _verticalScrollGeneration++;
        _focusModel.verticalScrollActive = false;
        _verticalScrollSnapshotController.allowSnapshotting = false;
        unawaited(Scrollable.ensureVisible(context, alignment: 0, duration: Duration.zero));
      }
    });
  }

  void _startVerticalScrollAnimation(Future<void> Function() animate) {
    final generation = ++_verticalScrollGeneration;
    // Suppress the focus glow while the rail animates vertically: the glow
    // paints in the root overlay, unclipped by the vertical viewport, so on UP
    // moves it would flash over the rows above while the target row is still
    // offscreen. Cleared in whenComplete (or by a non-animated jump) so the
    // glow fades back in once the row has settled.
    _focusModel.verticalScrollActive = true;
    // Full-tier row effects must stay live. The reduced tier has already
    // resolved those short effects to their final state before this snapshot.
    final useSnapshots = DevicePerformance.isReduced;
    if (useSnapshots) {
      _verticalScrollSnapshotController.allowSnapshotting = true;
    }
    unawaited(
      animate().whenComplete(() {
        if (!mounted || generation != _verticalScrollGeneration) return;
        _focusModel.verticalScrollActive = false;
        _verticalScrollSnapshotController.allowSnapshotting = false;
      }),
    );
  }

  void _setHoveredItem(MediaHub hub, int index) {
    final active = _activeHub;
    if (active == null || _hubKey(active) != _hubKey(hub) || _itemAtSlot(hub, index) == null || _itemIndex == index) {
      return;
    }
    _hasUserInteracted = true;
    _itemIndex = index;
    _hasUserChangedItem = true;
    _pendingLeadingAutoAdvanceHubKey = null;
    _focusModel.set(_hubIndex, _itemIndex);
    _rememberFocus(hub);
    _notifyFocusedItem();
  }

  void _selectHubItem(MediaHub hub, int hubIndex, int itemIndex) {
    final totalCount = _totalItemCount(hub);
    if (totalCount == 0) return;
    _hasUserInteracted = true;

    final clampedItemIndex = itemIndex.clamp(0, totalCount - 1).toInt();
    final hubChanged = _hubIndex != hubIndex;
    final previousHub = _activeHub;
    if (hubChanged && previousHub != null) _rememberFocus(previousHub);
    // No setState: observed through _focusModel selectors (see _moveHub).
    _hubIndex = hubIndex;
    _itemIndex = clampedItemIndex;
    _hasUserChangedHub = true;
    _hasUserChangedItem = true;
    _pendingLeadingAutoAdvanceHubKey = null;
    _focusModel.set(_hubIndex, _itemIndex);
    _rememberFocus(hub);
    _notifyFocusedItem();
    if (hubChanged) _notifyActiveHubChanged();
    _scrollActiveHubToTop();
    _scrollToItemAfterLayout(animate: false);
  }

  void _rememberFocus(MediaHub hub) {
    widget.focusMemory.setForHub(_hubKey(hub), _itemIndex);
  }

  void _scrollToItem({bool animate = true, Duration duration = _navigationScrollDuration}) {
    final hub = _activeHub;
    if (hub == null) return;
    final controller = _scrollControllers[_hubKey(hub)];
    if (controller == null) return;
    if (controller.positions.length != 1) return;
    final metrics = _metricsByHub[_hubKey(hub)];
    if (metrics == null) return;
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
    int initialItemIndex, {
    required bool hasTrailing,
    required bool isActiveHub,
  }) {
    return _scrollControllers.putIfAbsent(_hubKey(hub), () {
      final maxScrollExtent = TvBrowseRailLayout.estimatedMaxScrollExtent(
        hub: hub,
        metrics: metrics,
        viewportWidth: viewportWidth,
        hasTrailing: hasTrailing,
      );
      final initialScrollOffset = TvBrowseRailLayout.scrollOffsetForIndex(
        hub: hub,
        index: initialItemIndex,
        metrics: metrics,
        viewportWidth: viewportWidth,
        maxScrollExtent: maxScrollExtent,
        hasTrailing: hasTrailing,
      );
      // Only the active hub may rest in the negative region that reveals the
      // leading options card: an inactive row (e.g. a not-yet-fetched season
      // whose only slot IS the card) must still rest anchored on its first
      // item so the card stays off-screen.
      return ScrollController(
        initialScrollOffset: isActiveHub ? initialScrollOffset : math.max(0.0, initialScrollOffset),
      );
    });
  }

  /// Stable, collision-free per-hub key. `hub.id` (the backend hub key) is only
  /// unique within one server; Discover aggregates hubs from several servers, so
  /// prefix the server id to keep two same-id hubs from sharing rail state
  /// (scroll position, metrics, card GlobalKeys, focus memory).
  String _hubKey(MediaHub hub) => '${hub.serverId ?? ''}:${hub.id}';

  GlobalKey<MediaCardState> _cardKeyFor(MediaHub hub, int itemIndex) {
    return _mediaCardKeys.putIfAbsent('${_hubKey(hub)}:$itemIndex', () => GlobalKey<MediaCardState>());
  }

  /// Global rect of the active hub's selected card, pricing one swipe step by
  /// the card's geometry instead of the rail-wide focus node's (see
  /// [LockedFocusRowNode]).
  Rect? _focusedCardRect() {
    final hub = _activeHub;
    if (hub == null || _itemAtSlot(hub, _itemIndex) == null) return null;
    final context = _cardKeyFor(hub, _itemIndex).currentContext;
    final box = context?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  bool _isContinueWatchingHub(MediaHub hub) => widget.isContinueWatchingHub?.call(hub) ?? false;

  bool _usesContinueWatchingAction(MediaHub hub) {
    return widget.usesContinueWatchingAction?.call(hub) ?? _isContinueWatchingHub(hub);
  }

  GlobalKey<MediaContextMenuState> _leadingMenuKeyFor(MediaHub hub) {
    return _leadingMenuKeys.putIfAbsent(_hubKey(hub), () => GlobalKey<MediaContextMenuState>());
  }

  void _showLeadingContextMenu(MediaHub hub, {Offset? position}) {
    _leadingMenuKeyFor(hub).currentState?.showContextMenu(context, position: position);
  }

  void _showContextMenuForCurrentItem() {
    final hub = _activeHub;
    if (hub == null) return;
    if (_isLeadingSlot(hub, _itemIndex)) {
      _showLeadingContextMenu(hub);
      return;
    }
    if (_itemAtSlot(hub, _itemIndex) == null) return;
    if (_isPersonHub(hub)) return;
    _cardKeyFor(hub, _itemIndex).currentState?.showContextMenu();
  }

  Future<void> _activateCurrentItem() async {
    final hub = _activeHub;
    if (hub == null) return;
    if (_isLeadingSlot(hub, _itemIndex)) {
      _showLeadingContextMenu(hub);
      return;
    }
    if (_isTrailingSlot(hub, _itemIndex)) {
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
    final item = _itemAtSlot(hub, _itemIndex);
    if (item == null) return;
    final handled = await widget.onActivateItem?.call(hub, item);
    if (handled == true) return;
    if (!mounted) return;
    await navigateToMediaItem(
      context,
      item,
      onRefresh: widget.onRefresh,
      playDirectly: _usesContinueWatchingAction(hub),
    );
  }

  void _navigateToHubDetail(MediaHub hub) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HubDetailScreen(
          hub: hub,
          loadItems: widget.loadMoreItems == null ? null : () => widget.loadMoreItems!(hub),
          isInContinueWatching: _isContinueWatchingHub(hub),
          usesContinueWatchingAction: _usesContinueWatchingAction(hub),
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
                hasLeading: _hasLeadingFor(widget.hubs[i]),
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
                    _RailBleedPositioned(
                      width: width,
                      targetBleedLeft: widget.backgroundBleedLeft,
                      child: RasterizedGradient(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, theme.scaffoldBackgroundColor.withValues(alpha: 0.7)],
                        ),
                      ),
                    ),
                    Padding(
                      padding: .fromLTRB(
                        horizontalInset,
                        TvBrowseRailLayout.railTopPaddingForScale(scale),
                        0,
                        TvBrowseRailLayout.railBottomPaddingForScale(scale),
                      ),
                      child: ClipRect(
                        clipper: _RailClipper(leftOverflow: horizontalInset, rightOverflow: 0),
                        child: ExcludeSemantics(
                          // Both axes animate during D-pad navigation. Keeping
                          // the individual headers/cards in the semantics tree
                          // makes Android recompute every moving node's bounds
                          // on every frame when an accessibility service is
                          // active. A fixed proxy below exposes the same active
                          // selection and actions without tracking that motion.
                          child: SizedBox(
                            height: viewportHeight,
                            child: _buildHubSectionList(
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
                    Positioned(
                      left: horizontalInset,
                      top: TvBrowseRailLayout.railTopPaddingForScale(scale),
                      right: 0,
                      height: viewportHeight,
                      child: _buildSemanticSelectionProxy(context),
                    ),
                    // Unfocused-rail dim: a scrim quad on top instead of
                    // AnimatedOpacity, which would keep a full-viewport
                    // saveLayer alive every frame (see AnimatedDimScrim).
                    // Bled under the side nav like the background gradient,
                    // so its edge doesn't seam against the nav.
                    _RailBleedPositioned(
                      width: width,
                      targetBleedLeft: widget.backgroundBleedLeft,
                      child: ListenableSelector<bool>(
                        listenable: _focusModel,
                        selector: () => _focusModel.railHasFocus,
                        builder: (context, railHasFocus, _) => AnimatedDimScrim(
                          dimmed: !railHasFocus,
                          color: theme.scaffoldBackgroundColor,
                          alpha: _unfocusedRailDimAlpha,
                          // The band's top edge cuts across the spotlight
                          // artwork; ramp the dim in instead.
                          fadeTop: 36 * scale,
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
      // Inert on media lists (no keep-alive clients): dropping the per-child
      // wrappers shrinks build + semantics work per item.
      addAutomaticKeepAlives: false,
      addSemanticIndexes: false,
      clipBehavior: Clip.none,
      padding: .only(bottom: bottomPadding),
      itemExtentBuilder: (index, _) => sectionHeights[index],
      itemCount: widget.hubs.length,
      itemBuilder: (context, hubIndex) {
        final hub = widget.hubs[hubIndex];
        final metrics = metricsByHub[hubIndex];
        final sectionHeight = sectionHeights[hubIndex];
        // Active-hub state is observed through _focusModel so a hub move
        // repaints only the two affected headers/artwork tints; the row content
        // below is passed through as a stable child.
        bool isActiveHub() => _focusModel.hubIndex == hubIndex;

        return SnapshotWidget(
          controller: _verticalScrollSnapshotController,
          mode: SnapshotMode.permissive,
          autoresize: true,
          child: SizedBox(
            key: _hubSectionKeys.putIfAbsent(hubIndex, () => GlobalKey()),
            height: sectionHeight,
            child: Column(
              crossAxisAlignment: .stretch,
              children: [
                ListenableSelector<bool>(
                  listenable: _focusModel,
                  selector: isActiveHub,
                  builder: (context, isActive, _) =>
                      _buildHubHeader(context, hub: hub, hubIndex: hubIndex, isActive: isActive, scale: scale),
                ),
                _buildHubRail(
                  hub: hub,
                  hubIndex: hubIndex,
                  episodePosterMode: modes[hubIndex],
                  metrics: metrics,
                  scale: scale,
                  fullCardLayout: fullCardLayout,
                  leftOverflow: leftOverflow,
                  interactionExpansion: interactionExpansion,
                  railViewportWidth: railViewportWidth,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSemanticSelectionProxy(BuildContext context) {
    if (!MediaQuery.accessibleNavigationOf(context)) return const SizedBox.shrink();

    return ListenableSelector<(int, int)>(
      listenable: _focusModel,
      selector: () => _focusModel.position,
      builder: (context, position, _) {
        final hubIndex = position.$1;
        if (hubIndex < 0 || hubIndex >= widget.hubs.length) return const SizedBox.shrink();

        final hub = widget.hubs[hubIndex];
        final itemIndex = position.$2;
        final trailing = _trailingFor(hub);
        final totalCount = _totalItemCount(hub);
        final item = _itemAtSlot(hub, itemIndex);
        final isLeading = _isLeadingSlot(hub, itemIndex);
        final isTrailing = _isTrailingSlot(hub, itemIndex);
        final actionable = item != null || isLeading || (isTrailing && trailing != TvRailTrailing.loading);

        // The enclosing Focus publishes its focused state independently. Keeping
        // that state out of this selector avoids rebuilding the label and actions
        // when focus enters or leaves the rail.
        return Semantics(
          key: const ValueKey('tv_browse_rail_semantic_proxy'),
          identifier: 'tv_browse_rail_selection',
          container: true,
          focusable: true,
          button: actionable,
          label: _semanticSelectionLabel(hub, itemIndex, trailing),
          onTap: actionable ? () => unawaited(_activateCurrentItem()) : null,
          onLongPress: (item != null || isLeading) && !_isPersonHub(hub) ? _showContextMenuForCurrentItem : null,
          onScrollLeft: itemIndex > 0 ? () => _moveItem(-1) : null,
          onScrollRight: itemIndex < totalCount - 1 ? () => _moveItem(1) : null,
          onScrollUp: hubIndex > 0 ? () => _moveHub(-1) : null,
          onScrollDown: hubIndex < widget.hubs.length - 1 ? () => _moveHub(1) : null,
          child: const SizedBox.expand(),
        );
      },
    );
  }

  String _semanticSelectionLabel(MediaHub hub, int itemIndex, TvRailTrailing trailing) {
    String selection;
    final item = _itemAtSlot(hub, itemIndex);
    if (item != null) {
      if (_isPersonHub(hub)) {
        selection = [item.displayTitle, if (item.parentTitle?.isNotEmpty == true) item.parentTitle!].join(', ');
      } else {
        selection = mediaCardSemanticLabel(item);
      }
    } else if (_isLeadingSlot(hub, itemIndex)) {
      selection = t.common.options;
    } else {
      selection = switch (trailing) {
        TvRailTrailing.loading => t.common.loading,
        TvRailTrailing.error => t.common.retry,
        TvRailTrailing.viewAll => t.common.viewAll,
        TvRailTrailing.none => '',
      };
    }

    return [hub.title, if (selection.isNotEmpty) selection].join(', ');
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
    final showServerName = widget.showServerName && hub.serverName != null;
    final serverColor = colorScheme.primary.withValues(alpha: isActive ? 0.7 : 0.4);
    final serverStyle = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(color: serverColor, fontSize: 15 * scale, height: 1, fontWeight: FontWeight.w700);

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
                child: Row(
                  children: [
                    Flexible(
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
                    if (showServerName) ...[
                      SizedBox(width: 8 * scale),
                      Text('•', style: serverStyle),
                      SizedBox(width: 8 * scale),
                      Flexible(
                        child: Text(hub.serverName!, maxLines: 1, overflow: .ellipsis, style: serverStyle),
                      ),
                    ],
                  ],
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
    required EpisodePosterMode episodePosterMode,
    required TvBrowseRailLayoutMetrics metrics,
    required double scale,
    required bool fullCardLayout,
    required double leftOverflow,
    required double interactionExpansion,
    required double railViewportWidth,
  }) {
    final isActiveHub = hubIndex == _hubIndex;
    final hasTrailing = _hasTrailingFor(hub);
    final totalCount = _totalItemCount(hub);
    final inactiveIndex = widget.focusMemory.getForHubOnly(_hubKey(hub), totalCount, fallback: _defaultSlotFor(hub));
    final focusedIndex = isActiveHub ? _itemIndex : inactiveIndex;
    final scrollController = _scrollControllerForHub(
      hub,
      metrics,
      railViewportWidth,
      focusedIndex,
      hasTrailing: hasTrailing,
      isActiveHub: isActiveHub,
    );
    _metricsByHub[_hubKey(hub)] = metrics;

    final rail = _buildHubRailList(
      hub: hub,
      hubIndex: hubIndex,
      episodePosterMode: episodePosterMode,
      metrics: metrics,
      scale: scale,
      fullCardLayout: fullCardLayout,
      scrollController: scrollController,
      totalCount: totalCount,
    );
    final rightOverflow = metrics.railEdgePadding + metrics.cardWidth + metrics.itemGap;

    return Transform.translate(
      offset: Offset(-interactionExpansion, 0),
      child: SizedBox(
        width: railViewportWidth,
        height: metrics.height,
        child: ClipRect(
          clipper: _RailClipper(
            leftOverflow: leftOverflow,
            rightOverflow: rightOverflow,
            verticalOverflow: metrics.focusExtra,
          ),
          child: rail,
        ),
      ),
    );
  }

  Widget _buildHubRailList({
    required MediaHub hub,
    required int hubIndex,
    required EpisodePosterMode episodePosterMode,
    required TvBrowseRailLayoutMetrics metrics,
    required double scale,
    required bool fullCardLayout,
    required ScrollController scrollController,
    required int totalCount,
  }) {
    final leadingCount = _leadingCountFor(hub);
    const centerSliverKey = ValueKey('tv_browse_rail_row_center');
    return HorizontalScrollWithArrows(
      controller: scrollController,
      builder: (scrollController) => CustomScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        // The row anchors at its first media item. The leading options card
        // occupies the negative-offset region before the anchor, so at rest it
        // sits off-screen and never pushes the hub's content right; focusing
        // it (or dragging) scrolls it into view.
        center: centerSliverKey,
        slivers: [
          if (leadingCount > 0)
            SliverPadding(
              padding: .fromLTRB(metrics.railEdgePadding, 2 * scale, 0, 6 * scale),
              sliver: SliverToBoxAdapter(
                child: Align(
                  alignment: .topLeft,
                  child: ListenableSelector<bool>(
                    listenable: _focusModel,
                    selector: () => _focusModel.railHasFocus && _focusModel.position == (hubIndex, 0),
                    builder: (context, isFocused, _) =>
                        _buildLeadingSlot(context, hub, hubIndex, metrics: metrics, isFocused: isFocused, scale: scale),
                  ),
                ),
              ),
            ),
          SliverPadding(
            key: centerSliverKey,
            padding: .fromLTRB(metrics.railEdgePadding, 2 * scale, metrics.railEdgePadding, 6 * scale),
            sliver: SliverFixedExtentList(
              // A fixed extent keeps all sliver offset and child-index math O(1).
              itemExtent: TvBrowseRailLayout.itemExtentForIndex(index: 0, metrics: metrics),
              delegate: SliverChildBuilderDelegate(
                addAutomaticKeepAlives: false,
                addSemanticIndexes: false,
                childCount: totalCount - leadingCount,
                (context, childIndex) {
                  final itemIndex = childIndex + leadingCount;
                  // Focus is observed through _focusModel so a d-pad move or a
                  // rail focus flip rebuilds only the cheap wrapper of the two
                  // affected cards; the card content below is passed through as
                  // a stable child.
                  bool isItemFocused() => _focusModel.railHasFocus && _focusModel.position == (hubIndex, itemIndex);

                  if (_isTrailingSlot(hub, itemIndex)) {
                    return Padding(
                      padding: .only(right: metrics.itemGap),
                      child: Align(
                        alignment: .topLeft,
                        child: ListenableSelector<bool>(
                          listenable: _focusModel,
                          selector: isItemFocused,
                          builder: (context, isFocused, _) => _buildTrailingSlot(
                            context,
                            hub,
                            hubIndex,
                            itemIndex,
                            metrics: metrics,
                            isFocused: isFocused,
                            scale: scale,
                          ),
                        ),
                      ),
                    );
                  }

                  final item = hub.items[childIndex];
                  // Record: (focused, glow shown). The glow is additionally gated on
                  // the vertical scroll being idle — it paints in the root overlay,
                  // unclipped by the rail's viewport, so on UP moves it would flash
                  // over the spotlight while the target row is still offscreen. The
                  // selection collapses to (false, false) for unfocused cards, so the
                  // flag flip repaints only the focused card.
                  final focusableCard = ListenableSelector<(bool, bool)>(
                    listenable: _focusModel,
                    selector: () {
                      final isFocused = isItemFocused();
                      return (isFocused, isFocused && !_focusModel.verticalScrollActive);
                    },
                    builder: (context, focus, child) => FocusBuilders.buildLockedFocusWrapper(
                      context: context,
                      isFocused: focus.$1,
                      borderRadius: tokens(context).radiusSm,
                      focusScale: fullCardLayout ? TvBrowseRailLayout.fullCardFocusScale : FocusTheme.focusScale,
                      useFocusGlow: fullCardLayout,
                      showGlow: focus.$2,
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
                    child: _buildHubCard(
                      context,
                      hub: hub,
                      hubIndex: hubIndex,
                      item: item,
                      itemIndex: itemIndex,
                      episodePosterMode: episodePosterMode,
                      metrics: metrics,
                      scale: scale,
                      fullCardLayout: fullCardLayout,
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
        ],
      ),
    );
  }

  Widget _buildHubCard(
    BuildContext context, {
    required MediaHub hub,
    required int hubIndex,
    required MediaItem item,
    required int itemIndex,
    required EpisodePosterMode episodePosterMode,
    required TvBrowseRailLayoutMetrics metrics,
    required double scale,
    required bool fullCardLayout,
  }) {
    final artworkDim = _artworkDimForHub(context, hubIndex);
    return metrics.isPersonHub
        ? MergeSemantics(
            child: _buildPersonCard(
              context,
              item,
              cardWidth: metrics.cardWidth,
              imageSize: metrics.posterHeight,
              scale: scale,
              fullCardLayout: fullCardLayout,
              artworkDim: artworkDim,
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
            artworkDim: artworkDim,
            isInContinueWatching: _isContinueWatchingHub(hub),
            usesContinueWatchingAction: _usesContinueWatchingAction(hub),
            mixedHubContext: metrics.isMixedHub,
            episodePosterModeOverride: episodePosterMode,
          );
  }

  Widget _buildPersonCard(
    BuildContext context,
    MediaItem item, {
    required double cardWidth,
    required double imageSize,
    required double scale,
    required bool fullCardLayout,
    required Animation<double>? artworkDim,
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
                  imageType: ImageType.square,
                  fallbackIcon: Symbols.person_rounded,
                  artworkDim: artworkDim,
                ),
                RasterizedGradient(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.78)],
                    stops: const [0.45, 1.0],
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
                  imageType: ImageType.square,
                  fallbackIcon: Symbols.person_rounded,
                  artworkDim: artworkDim,
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

  /// The full-size options card occupying a hub's leading slot. Opens the
  /// context menu for the hub's leading item (e.g. the season an episode hub
  /// shows). Wrapped in the [MediaContextMenu] so keyboard/D-pad activation
  /// and pointer taps share one menu instance.
  Widget _buildLeadingSlot(
    BuildContext context,
    MediaHub hub,
    int hubIndex, {
    required TvBrowseRailLayoutMetrics metrics,
    required bool isFocused,
    required double scale,
  }) {
    final leadingItem = _leadingItemFor(hub);
    if (leadingItem == null) return const SizedBox.shrink();
    Offset? tapPosition;

    return MediaContextMenu(
      key: _leadingMenuKeyFor(hub),
      item: leadingItem,
      onRefresh: widget.onRefresh,
      child: ClickableCursor(
        child: GestureDetector(
          onTap: () {
            _selectHubItem(hub, hubIndex, 0);
            _showLeadingContextMenu(hub);
          },
          onSecondaryTapDown: (details) => tapPosition = details.globalPosition,
          onSecondaryTap: () {
            _selectHubItem(hub, hubIndex, 0);
            _showLeadingContextMenu(hub, position: tapPosition);
          },
          child: _buildActionCard(
            context,
            metrics: metrics,
            isFocused: isFocused,
            scale: scale,
            icon: Symbols.more_horiz_rounded,
            label: t.common.options,
          ),
        ),
      ),
    );
  }

  Widget _buildTrailingSlot(
    BuildContext context,
    MediaHub hub,
    int hubIndex,
    int itemIndex, {
    required TvBrowseRailLayoutMetrics metrics,
    required bool isFocused,
    required double scale,
  }) {
    switch (_trailingFor(hub)) {
      case TvRailTrailing.loading:
        return _buildActionCard(context, metrics: metrics, isFocused: isFocused, scale: scale, spinner: true);
      case TvRailTrailing.error:
        return ClickableCursor(
          child: GestureDetector(
            onTap: () {
              _selectHubItem(hub, hubIndex, itemIndex);
              widget.onRetryHub?.call(hub);
            },
            child: _buildActionCard(
              context,
              metrics: metrics,
              isFocused: isFocused,
              scale: scale,
              icon: Symbols.refresh_rounded,
              label: t.common.retry,
            ),
          ),
        );
      case TvRailTrailing.viewAll:
        return ClickableCursor(
          child: GestureDetector(
            onTap: () {
              _selectHubItem(hub, hubIndex, itemIndex);
              _navigateToHubDetail(hub);
            },
            child: _buildActionCard(
              context,
              metrics: metrics,
              isFocused: isFocused,
              scale: scale,
              icon: Symbols.arrow_forward_rounded,
              label: t.common.viewAll,
            ),
          ),
        );
      case TvRailTrailing.none:
        return const SizedBox.shrink();
    }
  }

  /// Shared full-size action card used by the leading options slot and the
  /// trailing View All / retry / loading slots: it matches the hub's card
  /// footprint so the row reads as cards end-to-end instead of mixing in
  /// compact pills.
  Widget _buildActionCard(
    BuildContext context, {
    required TvBrowseRailLayoutMetrics metrics,
    required bool isFocused,
    required double scale,
    IconData? icon,
    String? label,
    bool spinner = false,
  }) {
    final theme = Theme.of(context);
    final duration = FocusTheme.getAnimationDuration(context);
    final foreground = isFocused ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.78);
    final background = isFocused
        ? theme.colorScheme.primary.withValues(alpha: 0.2)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: spinner ? 0.18 : 0.42);

    return AnimatedScale(
      scale: isFocused ? FocusTheme.focusScale : 1.0,
      duration: duration,
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOutCubic,
        width: metrics.cardWidth,
        height: metrics.posterHeight,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(tokens(context).radiusSm),
          border: Border.all(
            color: isFocused ? theme.colorScheme.primary : Colors.transparent,
            width: FocusTheme.focusBorderWidth,
          ),
          boxShadow: isFocused
              ? [BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.2), blurRadius: 18, spreadRadius: 1)]
              : null,
        ),
        child: spinner
            ? Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
                ),
              )
            : Center(
                child: Column(
                  mainAxisSize: .min,
                  children: [
                    AppIcon(icon!, fill: 1, size: (26 * scale).clamp(22, 32).toDouble(), color: foreground),
                    SizedBox(height: (6 * scale).clamp(4, 9).toDouble()),
                    Padding(
                      padding: .symmetric(horizontal: (10 * scale).clamp(8, 14).toDouble()),
                      child: Text(
                        label!,
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
                  ],
                ),
              ),
      ),
    );
  }
}

/// Positions [child] over the rail's full band, bled left under the side
/// navigation (animated with the nav's expansion). Full-width layers — the
/// background gradient and the unfocused-rail dim — must live here: anything
/// clipped to the rail's own footprint terminates in a visible vertical seam
/// at the nav edge, since the backdrop artwork continues behind the nav.
class _RailBleedPositioned extends StatelessWidget {
  final double width;

  /// Explicit target; when null the value comes from [MainScreenFocusScope]
  /// (offset aspect) so sidebar flips rebuild only this widget, not the rail.
  final double? targetBleedLeft;
  final Widget child;

  const _RailBleedPositioned({required this.width, required this.targetBleedLeft, required this.child});

  @override
  Widget build(BuildContext context) {
    final target = targetBleedLeft ?? MainScreenFocusScope.sideNavigationBleedOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: target),
      duration: FocusTheme.getAnimationDuration(context),
      curve: Curves.easeOutCubic,
      child: child,
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

/// Hot rail focus state — (hubIndex, itemIndex) position and whether the rail
/// itself holds focus — observed through [ListenableSelector]s so d-pad moves
/// and rail focus flips repaint only the affected cards/headers/dim effects
/// instead of setState-rebuilding every visible row (expensive on low-end
/// TVs). `notify: false` covers build-phase syncs (initState/didUpdateWidget),
/// where notifying would call setState on descendants mid-build and the
/// enclosing rebuild refreshes the selectors anyway.
class _RailFocusModel extends ChangeNotifier {
  (int, int) _position = (0, 0);
  bool _railHasFocus = false;
  bool _verticalScrollActive = false;

  (int, int) get position => _position;
  int get hubIndex => _position.$1;
  bool get railHasFocus => _railHasFocus;

  /// Whether the rail is animating a hub row into view vertically. Gates only
  /// the focus glow (root-overlay paint, unclipped by the vertical viewport);
  /// border and scale chrome stay tied to the position alone.
  bool get verticalScrollActive => _verticalScrollActive;

  set verticalScrollActive(bool value) {
    if (value == _verticalScrollActive) return;
    _verticalScrollActive = value;
    notifyListeners();
  }

  void set(int hubIndex, int itemIndex, {bool notify = true}) {
    final next = (hubIndex, itemIndex);
    if (next == _position) return;
    _position = next;
    if (notify) notifyListeners();
  }

  void setRailFocus(bool value) {
    if (value == _railHasFocus) return;
    _railHasFocus = value;
    notifyListeners();
  }
}

/// Paint-time dim animation shared by every artwork image in one hub.
///
/// A single controller avoids one ticker per card while each image repaints
/// through its own render object, without a row-sized overlay or save layer.
class _HubArtworkDim extends Animation<double> {
  _HubArtworkDim(this._focusModel, this._hubIndex, {required TickerProvider vsync, required Duration duration})
    : _duration = duration {
    _target = _resolveTarget();
    _controller = AnimationController(vsync: vsync, duration: duration, value: _target);
    _focusModel.addListener(_handleFocusChange);
  }

  final _RailFocusModel _focusModel;
  final int _hubIndex;
  final Duration _duration;
  late final AnimationController _controller;
  late double _target;

  double _resolveTarget() => _focusModel.railHasFocus && _focusModel.hubIndex != _hubIndex ? 1 : 0;

  void _handleFocusChange() {
    final next = _resolveTarget();
    if (next == _target) return;
    _target = next;
    if (_duration == Duration.zero) {
      _controller.value = next;
    } else {
      unawaited(_controller.animateTo(next, duration: _duration, curve: Curves.easeOutCubic));
    }
  }

  @override
  double get value => _controller.value * _inactiveArtworkDimAlpha;

  @override
  AnimationStatus get status => _controller.status;

  @override
  void addListener(VoidCallback listener) => _controller.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => _controller.removeListener(listener);

  @override
  void addStatusListener(AnimationStatusListener listener) => _controller.addStatusListener(listener);

  @override
  void removeStatusListener(AnimationStatusListener listener) => _controller.removeStatusListener(listener);

  void dispose() {
    _focusModel.removeListener(_handleFocusChange);
    _controller.dispose();
  }
}
