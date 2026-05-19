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
  static double scaleForSize(Size size) => TvLayoutConstants.scaleForSize(size);

  static double horizontalInsetForScale(double scale) => (24 * scale).clamp(18, 40).toDouble();

  static double selectorWidthForScale(double scale) => (230 * scale).clamp(210, 310).toDouble();

  static double selectorGapForScale(double scale) => 14 * scale;

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
    final targetWidth = (useWideLayout ? 330 : 205) * scale * (1 + (f * 0.12));
    final minCards = useWideLayout ? 3 : 5;
    final maxCards = useWideLayout ? 7 : 12;
    final cardCount = (availableWidth / targetWidth).floor().clamp(minCards, maxCards);
    final fittedWidth = (availableWidth - horizontalPadding - (itemGap * cardCount)) / cardCount;
    final minWidth = (useWideLayout ? 280 : 170) * scale;
    final maxWidth = (useWideLayout ? 420 : 250) * scale;
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

  static double estimateHeight({
    required Size size,
    required List<MediaHub> hubs,
    required int density,
    required EpisodePosterMode episodePosterMode,
    double tallPosterScale = 1.0,
  }) {
    if (hubs.isEmpty) return 0;

    final scale = scaleForSize(size);
    final availableWidth =
        size.width - horizontalInsetForScale(scale) - selectorWidthForScale(scale) - selectorGapForScale(scale);
    if (availableWidth <= 0) return 0;

    var activeRailHeight = 0.0;
    for (final hub in hubs) {
      final metrics = metricsForHub(
        hub: hub,
        availableWidth: availableWidth,
        density: density,
        episodePosterMode: episodePosterMode,
        scale: scale,
        tallPosterScale: tallPosterScale,
      );
      if (metrics.height > activeRailHeight) activeRailHeight = metrics.height;
    }

    final visibleShelfCount = hubs.length < 5 ? hubs.length : 5;
    final selectorHeight = (46 * scale * visibleShelfCount) + (4 * scale * (visibleShelfCount - 1).clamp(0, 4));
    final rowHeight = activeRailHeight > selectorHeight ? activeRailHeight : selectorHeight;
    return (12 * scale) + rowHeight + (24 * scale);
  }
}

class TvBrowseRail extends StatefulWidget {
  final List<MediaHub> hubs;
  final IconData Function(MediaHub hub, int index) iconForHub;
  final ValueChanged<MediaItem>? onFocusedItemChanged;
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

  const TvBrowseRail({
    super.key,
    required this.hubs,
    required this.iconForHub,
    this.onFocusedItemChanged,
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
  });

  @override
  State<TvBrowseRail> createState() => TvBrowseRailState();
}

class TvBrowseRailState extends State<TvBrowseRail> {
  static const _longPressDuration = Duration(milliseconds: 500);

  final FocusNode _focusNode = FocusNode(debugLabel: 'tv_browse_rail');
  final ScrollController _scrollController = ScrollController();
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

  MediaHub? get _activeHub => widget.hubs.isEmpty ? null : widget.hubs[_hubIndex.clamp(0, widget.hubs.length - 1)];

  void requestFocus() {
    _notifyFocusedItem();
    _focusNode.requestFocus();
  }

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
    _selectInitialHubIfPossible();
    final selectedInitialItem = _selectInitialItemIfPossible();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.hubs.isEmpty) return;
      if (selectedInitialItem) _scrollToItem(animate: false);
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
    _scrollController.dispose();
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
    widget.onFocusedItemChanged?.call(hub.items[_itemIndex]);
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
    });
    _notifyFocusedItem();
    _notifyActiveHubChanged();
    _scrollToItem(animate: false);
  }

  void _rememberFocus(MediaHub hub) {
    HubFocusMemory.setForHub(hub.id, _itemIndex);
  }

  void _scrollToItem({bool animate = true}) {
    scrollListToIndex(
      _scrollController,
      _itemIndex,
      itemExtent: _itemExtent,
      leadingPadding: _railLeadingPadding,
      animate: animate,
    );
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

  double _selectorWidth(BuildContext context) => TvBrowseRailLayout.selectorWidthForScale(_scale(context));

  double _selectorGap(BuildContext context) => TvBrowseRailLayout.selectorGapForScale(_scale(context));

  List<int> _visibleShelfIndices() {
    const visibleCount = 5;
    if (widget.hubs.length <= visibleCount) return List.generate(widget.hubs.length, (index) => index);
    final start = (_hubIndex - 2).clamp(0, widget.hubs.length - visibleCount);
    return List.generate(visibleCount, (index) => start + index);
  }

  _ShelfTitleParts _shelfTitleParts(String title) {
    final titleWords = _titleWords(title);
    if (titleWords.length < 3) return _ShelfTitleParts(title: title);

    var bestPrefixLength = 0;
    var bestSupport = 0;
    for (var prefixLength = 2; prefixLength < titleWords.length; prefixLength++) {
      if (_suffixStartsWithPunctuation(titleWords, prefixLength)) continue;

      final support = _prefixSupport(titleWords, prefixLength);
      if (support < 2) continue;
      if (support > bestSupport || (support == bestSupport && prefixLength > bestPrefixLength)) {
        bestSupport = support;
        bestPrefixLength = prefixLength;
      }
    }

    if (bestPrefixLength < 2) return _ShelfTitleParts(title: title);
    bestPrefixLength = _preferConnectorBoundary(titleWords, bestPrefixLength, bestSupport);
    return _splitTitleAtWord(title, bestPrefixLength);
  }

  List<String> _titleWords(String title) =>
      title.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();

  int _prefixSupport(List<String> titleWords, int prefixLength) {
    var support = 0;
    for (final hub in widget.hubs) {
      final otherWords = _titleWords(hub.title);
      if (_commonPrefixLength(titleWords, otherWords) >= prefixLength) support++;
    }
    return support;
  }

  int _commonPrefixLength(List<String> a, List<String> b) {
    final maxLength = a.length < b.length ? a.length : b.length;
    var length = 0;
    while (length < maxLength && a[length].toLowerCase() == b[length].toLowerCase()) {
      length++;
    }
    return length;
  }

  int _preferConnectorBoundary(List<String> titleWords, int prefixLength, int support) {
    for (var candidate = prefixLength; candidate >= 2; candidate--) {
      if (_prefixSupport(titleWords, candidate) != support) continue;
      if (_looksLikeConnector(titleWords[candidate - 1])) return candidate;
    }
    return prefixLength;
  }

  bool _looksLikeConnector(String word) {
    final stripped = word.replaceAll(RegExp(r'[^\p{L}]', unicode: true), '');
    return stripped.length <= 5 && stripped.isNotEmpty && stripped == stripped.toLowerCase();
  }

  bool _suffixStartsWithPunctuation(List<String> words, int prefixLength) {
    if (prefixLength >= words.length) return true;
    return RegExp(r'^[^\p{L}\p{N}]', unicode: true).hasMatch(words[prefixLength]);
  }

  _ShelfTitleParts _splitTitleAtWord(String title, int wordCount) {
    final matches = RegExp(r'\S+').allMatches(title).toList();
    if (wordCount <= 0 || wordCount >= matches.length) return _ShelfTitleParts(title: title);
    final split = matches[wordCount - 1].end;
    return _ShelfTitleParts(eyebrow: title.substring(0, split).trim(), title: title.substring(split).trim());
  }

  @override
  Widget build(BuildContext context) {
    final hub = _activeHub;
    if (hub == null) return const SizedBox.shrink();
    final hasFocus = _focusNode.hasFocus;
    final theme = Theme.of(context);
    final scale = _scale(context);
    final horizontalInset = _horizontalInset(context);
    final selectorGap = _selectorGap(context);

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        padding: EdgeInsets.fromLTRB(horizontalInset, 12 * scale, 0, 24 * scale),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, theme.scaffoldBackgroundColor.withValues(alpha: 0.7)],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(width: _selectorWidth(context), child: _buildShelfSelector(context)),
            SizedBox(width: selectorGap),
            Expanded(child: _buildActiveRail(hub, hasFocus)),
          ],
        ),
      ),
    );
  }

  Widget _buildShelfSelector(BuildContext context) {
    final scale = _scale(context);
    final visibleIndices = _visibleShelfIndices();
    final isScrollable = widget.hubs.length > visibleIndices.length;
    final hasAbove = isScrollable && visibleIndices.first > 0;
    final hasBelow = isScrollable && visibleIndices.last < widget.hubs.length - 1;
    final rowHeight = 46 * scale;
    final rowGap = 4 * scale;
    final viewportHeight = isScrollable
        ? (rowHeight * 5) + (rowGap * 4)
        : (rowHeight * visibleIndices.length) + (rowGap * (visibleIndices.length - 1).clamp(0, 4));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: viewportHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _buildFadedShelfRows(
                visibleIndices: visibleIndices,
                hasAbove: hasAbove,
                hasBelow: hasBelow,
                rowGap: rowGap,
                rowHeight: rowHeight,
                scale: scale,
                viewportHeight: viewportHeight,
              ),
              if (hasAbove) _buildSelectorChevron(Symbols.keyboard_arrow_up_rounded, scale, top: 0),
              if (hasBelow) _buildSelectorChevron(Symbols.keyboard_arrow_down_rounded, scale, bottom: 0),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFadedShelfRows({
    required List<int> visibleIndices,
    required bool hasAbove,
    required bool hasBelow,
    required double rowGap,
    required double rowHeight,
    required double scale,
    required double viewportHeight,
  }) {
    final rows = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var visibleIndex = 0; visibleIndex < visibleIndices.length; visibleIndex++)
          Padding(
            padding: EdgeInsets.only(bottom: visibleIndex == visibleIndices.length - 1 ? 0 : rowGap),
            child: _buildShelfRow(context, visibleIndices[visibleIndex], scale, rowHeight),
          ),
      ],
    );

    if (!hasAbove && !hasBelow) return rows;

    final fadeStop = ((68 * scale) / viewportHeight).clamp(0.0, 0.45).toDouble();
    final colors = <Color>[];
    final stops = <double>[];
    if (hasAbove) {
      colors.addAll([Colors.transparent, Colors.white]);
      stops.addAll([0, fadeStop]);
    } else {
      colors.add(Colors.white);
      stops.add(0);
    }
    if (hasBelow) {
      colors.addAll([Colors.white, Colors.transparent]);
      stops.addAll([1 - fadeStop, 1]);
    } else {
      colors.add(Colors.white);
      stops.add(1);
    }

    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
        stops: stops,
      ).createShader(bounds),
      child: rows,
    );
  }

  Widget _buildShelfRow(BuildContext context, int index, double scale, double rowHeight) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = index == _hubIndex;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: rowHeight,
      padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 6 * scale),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withValues(alpha: 0.16) : Colors.transparent,
        borderRadius: BorderRadius.circular(tokens(context).radiusMd),
      ),
      child: Row(
        children: [
          AppIcon(
            widget.iconForHub(widget.hubs[index], index),
            fill: 1,
            size: 22 * scale,
            color: isActive ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.54),
          ),
          SizedBox(width: 12 * scale),
          Expanded(child: _buildShelfTitle(context, widget.hubs[index], isActive, scale)),
        ],
      ),
    );
  }

  Widget _buildSelectorChevron(IconData icon, double scale, {double? top, double? bottom}) {
    return Positioned(
      left: 0,
      right: 0,
      top: top,
      bottom: bottom,
      child: IgnorePointer(
        child: Center(
          child: AppIcon(icon, fill: 1, size: 18 * scale, color: Colors.white.withValues(alpha: 0.45)),
        ),
      ),
    );
  }

  Widget _buildShelfTitle(BuildContext context, MediaHub hub, bool isActive, double scale) {
    final parts = hub.id.startsWith('detail_season_')
        ? _ShelfTitleParts(title: hub.title)
        : _shelfTitleParts(hub.title);
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = isActive ? Colors.white : colorScheme.onSurface.withValues(alpha: 0.62);
    final secondaryColor = isActive
        ? Colors.white.withValues(alpha: 0.62)
        : colorScheme.onSurface.withValues(alpha: 0.42);

    if (parts.eyebrow == null) {
      return Text(
        parts.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: primaryColor,
          fontSize: 16 * scale,
          height: 1.05,
          fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          parts.eyebrow!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: secondaryColor,
            fontSize: 10.5 * scale,
            height: 0.95,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        SizedBox(height: scale),
        Text(
          parts.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: primaryColor,
            fontSize: 16 * scale,
            height: 1,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
          ),
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
          final episodePosterMode = svc.read(SettingsService.episodePosterMode);
          final scale = _scale(context);
          final metrics = TvBrowseRailLayout.metricsForHub(
            hub: hub,
            availableWidth: constraints.maxWidth,
            density: density,
            episodePosterMode: episodePosterMode,
            scale: scale,
            tallPosterScale: widget.tallPosterScale,
          );
          _railLeadingPadding = metrics.railEdgePadding;
          _itemExtent = metrics.cardWidth + metrics.itemGap;

          return SizedBox(
            height: metrics.height,
            child: ClipRect(
              clipper: _RailClipper(
                rightOverflow: metrics.railEdgePadding + metrics.cardWidth + metrics.itemGap,
                verticalOverflow: metrics.focusExtra,
              ),
              child: HorizontalScrollWithArrows(
                controller: _scrollController,
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
                                AppIcon(Symbols.arrow_forward_rounded, fill: 1, size: 42 * scale, color: Colors.white),
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
                              ),
                      ),
                    );
                  },
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

class _ShelfTitleParts {
  final String? eyebrow;
  final String title;

  const _ShelfTitleParts({this.eyebrow, required this.title});
}
