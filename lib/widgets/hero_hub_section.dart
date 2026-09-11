import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/widgets/app_icon.dart';

import '../focus/input_mode_tracker.dart';
import '../media/ids.dart';
import '../media/media_hub.dart';
import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../media/media_server_client.dart';
import '../mpv/video.dart';
import '../providers/watch_state_store.dart';
import '../services/hover_trailer_service.dart';
import '../services/settings_service.dart';
import '../theme/mono_tokens.dart';
import '../utils/app_logger.dart';
import '../utils/content_utils.dart';
import '../utils/formatters.dart';
import '../utils/layout_constants.dart';
import '../utils/media_navigation_helper.dart';
import '../utils/platform_detector.dart';
import '../utils/provider_extensions.dart';
import '../utils/video_player_navigation.dart';
import 'clickable_cursor.dart';
import 'cycling_media_backdrop.dart';
import 'fitting_title_text.dart';
import 'hover_preview/hover_preview_player_controller.dart';
import 'optimized_media_image.dart' show ClearLogoImage, blurArtwork;
import '../i18n/strings.g.dart';

/// A per-row hero banner: backdrop, title, play button, description, paging
/// dots — the same visual language as the old screen-level "Continue
/// Watching only" hero, but self-contained so any number of Home rows can
/// each be one of these at once, each with its own rotation/paging state.
///
/// Deliberately NOT a port of the outer-scroll-linked parallax the old
/// single-hero version had (`_scrollController.offset * 0.3`) — that only
/// made sense for a hero pinned at the very top of the page. A hero row
/// anywhere else in the list has no single sensible "outer scroll offset"
/// to parallax against, so this uses only the fade/zoom-in entrance effect,
/// independent of scroll position.
///
/// Trailer-preview trigger model (revised 2026-09-10 after hands-on testing
/// showed the original "dwell while auto-rotating" design fighting itself
/// across every hero row mounted at once): auto-rotation is purely
/// visibility-based and runs identically whether or not a row has trailers
/// enabled — see [_isVisible]/[_computeIsVisible]. A trailer only starts
/// on genuine mouse hover (or, on TV, d-pad focus — not yet wired, see
/// [_onHoverEnter]) over the specific card, after a 3s dwell, and stops the
/// instant hover ends. Paging to a new item — by arrow, by auto-rotate, or
/// by a trailer finishing — always requires a fresh dwell before that new
/// item's trailer can start, even if the pointer never physically moved
/// (see the `onPageChanged` handling in [build]).
class HeroHubSection extends StatefulWidget {
  const HeroHubSection({
    super.key,
    required this.hub,
    required this.onVerticalNavigation,
    required this.playerController,
    this.onNavigateUp,
    this.onNavigateToSidebar,
  });

  final MediaHub hub;

  /// Shared, not owned by this widget — Windows' native video plugin only
  /// backs one process-wide video core, so only one hero/hover-preview
  /// trailer can actually be playing anywhere in the app at a time,
  /// regardless of how many hero rows are configured. Owned by
  /// DiscoverScreen (also where the global mute icon lives) and passed
  /// down, matching the same pattern the hover-preview rows already use.
  final HoverPreviewPlayerController playerController;

  /// Same contract as [HubSection.onVerticalNavigation]: return true if this
  /// row handled the up/down request itself (e.g. moving between paged
  /// items), false to let the screen move focus to the next/previous row.
  final bool Function(bool isUp) onVerticalNavigation;
  final VoidCallback? onNavigateUp;
  final VoidCallback? onNavigateToSidebar;

  @override
  State<HeroHubSection> createState() => HeroHubSectionState();
}

class HeroHubSectionState extends State<HeroHubSection> {
  static const _autoScrollDuration = Duration(seconds: 8);
  static const _indicatorUpdateInterval = Duration(milliseconds: 50);

  /// Per the spec: dwell for 3 seconds on a hero item before its trailer
  /// starts. Deliberately shorter than [_autoScrollDuration] — trailer-off
  /// hero rows still just auto-advance every 8s, only trailer-on rows use
  /// this faster dwell instead of advancing.
  static const _trailerDwellDuration = Duration(seconds: 3);

  /// Confirmed via the native source (windows/runner/mpv/mpv_plugin.cpp +
  /// flutter_window.cpp): the video's child HWND is parented directly to
  /// Flutter's own rendering window, so by basic Win32 rules it always
  /// paints over Flutter's own content within its bounds — no widget, in
  /// any part of the tree, can ever appear on top of it. Genuine
  /// non-overlap is therefore the only sound approach: this insets the
  /// video just enough to leave the arrow buttons and the title/summary
  /// safe zone (see [_buildOverlayContent]) clear of its rect.
  static const _videoSideInset = 56.0;

  final _pageController = PageController();
  final _focusNode = FocusNode(debugLabel: 'hero_hub_section');
  final _indicatorProgress = ValueNotifier<double>(0.0);
  final _currentIndex = ValueNotifier<int>(0);
  final _trailerResolver = HoverPreviewSourceResolver();

  /// Key on the title/facts/summary/play-button block so its real rendered
  /// height can be measured after layout — the video's own bottom inset is
  /// sized to exactly this (see [_measureContentBlock]) rather than a
  /// guessed fraction of [heroHeight], so the video gets as much of the
  /// card as it genuinely can without ever touching the text underneath it.
  final _contentBlockKey = GlobalKey();

  /// Bottom inset the video needs to clear the content block, from the most
  /// recent measurement — null until the first item has been laid out once,
  /// at which point [_videoBottomInset] falls back to a rough fraction of
  /// [heroHeight] for that first frame only.
  double? _measuredVideoBottomInset;

  double _videoBottomInset(double heroHeight, bool isTv) => _measuredVideoBottomInset ?? (isTv ? 140.0 : 110.0);

  /// Measures the content block actually painted this frame and, if it
  /// differs from what the video is currently inset by, schedules a rebuild
  /// with the corrected inset. [bottomAnchor] is the same offset
  /// [_buildOverlayContent] anchors the block's own bottom edge to (its
  /// `Positioned.bottom`), so the video's inset covers the anchor gap too,
  /// not just the block's own height.
  void _measureContentBlock(double bottomAnchor) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final renderBox = _contentBlockKey.currentContext?.findRenderObject();
      if (renderBox is! RenderBox || !renderBox.hasSize) return;
      final needed = bottomAnchor + renderBox.size.height;
      if (_measuredVideoBottomInset != null && (needed - _measuredVideoBottomInset!).abs() < 1.0) return;
      setState(() => _measuredVideoBottomInset = needed);
    });
  }

  Timer? _autoScrollTimer;
  Timer? _indicatorTimer;
  bool _isAutoScrollPaused = false;

  /// The scrollable this row lives in doesn't lazily unmount off-screen
  /// slivers (every hub is a plain SliverToBoxAdapter, always built), so
  /// without a visibility check every hero row on the page — not just the
  /// one actually on screen — would auto-rotate at once regardless of
  /// scroll position. Per the spec this is now a pure "any part of the row
  /// overlaps the viewport" check, not a narrow centered-band — auto-
  /// rotation should run "if they are visible on the screen at all",
  /// independent of trailer-enabled status (revised 2026-09-10; the
  /// earlier centered-band gate existed to solve a different problem — all
  /// rows fighting over the single shared trailer player — which hover-
  /// exclusivity now solves on its own).
  bool _isVisible = false;
  ScrollPosition? _scrollPosition;

  bool _computeIsVisible() {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) return false;
    final scrollable = Scrollable.maybeOf(context);
    final viewportRenderObject = scrollable?.context.findRenderObject();
    if (viewportRenderObject is! RenderBox) return false;
    final viewportHeight = viewportRenderObject.size.height;
    final topLeft = renderObject.localToGlobal(Offset.zero, ancestor: viewportRenderObject);
    final top = topLeft.dy;
    final bottom = top + renderObject.size.height;
    return bottom > 0 && top < viewportHeight;
  }

  void _onScrollChanged() {
    // The native video plane's on-screen position is only recomputed on a
    // real Flutter layout pass — plain scrolling moves this row via the
    // Scrollable's paint transform alone, which the video plugin has no way
    // to observe, so it keeps rendering at its last-known screen position
    // while the app scrolls underneath it (looks exactly like "a second
    // window I can't get rid of", reported 2026-09-10). Stop on ANY scroll
    // rather than try to keep a native plane glued to a Scrollable's offset.
    if (_trailerIndex != null) _stopTrailer();

    final visible = _computeIsVisible();
    if (visible == _isVisible) return;
    _isVisible = visible;
    if (!_isVisible) {
      _autoScrollTimer?.cancel();
      _indicatorTimer?.cancel();
      _hoverDwellTimer?.cancel();
    } else {
      _startAutoScroll();
    }
  }

  /// Index of the item currently showing a trailer in place of its static
  /// backdrop, or null if none is (this row might not even be the one
  /// playing — [widget.playerController] is shared across every hero row on
  /// screen, since only one video can physically play at once).
  int? _trailerIndex;
  int _trailerRequestToken = 0;

  /// True while the pointer is genuinely hovering the current card of a
  /// trailer-enabled row. Drives the dwell timer directly — no more
  /// starting a trailer just because a row happened to auto-rotate into
  /// view; per spec it should "just sit on the poster card" until actually
  /// hovered (or, on TV, focused — not yet wired here).
  bool _isHovering = false;
  Timer? _hoverDwellTimer;

  /// Continue Watching hero rows preview the user's actual resume point
  /// instead of a trailer (per user request 2026-09-10: "don't play the
  /// trailer, play the first 30 seconds of where you left off... if you
  /// click play it resumes"). [_trailerResolver.resolve]'s own
  /// `preferResumePosition` already resolves that clip when this is true —
  /// this only decides whether to ask for it, not how it's fetched.
  bool get _isContinueWatching => widget.hub.isContinueWatchingHub;

  /// Caps a Continue Watching row's resume-clip preview at 30s of playback
  /// — there's no natural end-of-stream to key off since it's the real
  /// file, not a short trailer, so this manufactures one, then goes back to
  /// hero art exactly like a trailer that finished on its own.
  static const _resumeClipPreviewCap = Duration(seconds: 30);
  Timer? _resumeClipCapTimer;

  List<MediaItem> get _items => widget.hub.items;

  @override
  void initState() {
    super.initState();
    widget.playerController.addListener(_onPlayerStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _isVisible = _computeIsVisible();
      if (_isVisible) _startAutoScroll();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newPosition = Scrollable.maybeOf(context)?.position;
    if (newPosition != _scrollPosition) {
      _scrollPosition?.removeListener(_onScrollChanged);
      _scrollPosition = newPosition;
      _scrollPosition?.addListener(_onScrollChanged);
    }
  }

  /// A failed or naturally-completed trailer only stops rendering it (via
  /// the ListenableBuilder in _buildHeroItem) — without this, _trailerIndex
  /// stays set forever, and _startAutoScroll's "already playing, nothing to
  /// dwell toward" guard would permanently freeze this row instead of
  /// resuming normal auto-advance. Ignores changes that aren't about a
  /// trailer THIS row started (_trailerIndex == null means nothing here is
  /// tracked as playing, regardless of what the shared controller is doing
  /// for some other row).
  void _onPlayerStateChanged() {
    if (_trailerIndex == null) return;
    if (widget.playerController.playbackCompleted) {
      // Per spec: a trailer that finishes on its own goes back to the hero
      // art for the SAME item, not straight on to the next one — the user
      // is still hovering it, there's just nothing left to play.
      // _startAutoScroll re-arms the normal visibility-based rotation clock
      // for this item (it already no-ops while still hovered, same as any
      // other transition).
      _resumeClipCapTimer?.cancel();
      setState(() => _trailerIndex = null);
      _startAutoScroll();
    } else if (widget.playerController.playbackFailed) {
      // A broken stream, unlike a clean finish, has nothing worth sitting
      // on — advance past it so a bad trailer URL can't freeze the row.
      _resumeClipCapTimer?.cancel();
      setState(() => _trailerIndex = null);
      _advancePage();
    }
  }

  @override
  void didUpdateWidget(HeroHubSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hub.items.length != widget.hub.items.length && _currentIndex.value >= _items.length) {
      _currentIndex.value = 0;
    }
  }

  @override
  void dispose() {
    // Stop, don't dispose — playerController is shared and owned by
    // DiscoverScreen, not this row. Only stop it if THIS row was actually
    // the one playing, so unmounting an unrelated hero row (e.g. reordered
    // out of view) can't cut off a different row's trailer.
    if (_trailerIndex != null) unawaited(widget.playerController.stop());
    widget.playerController.removeListener(_onPlayerStateChanged);
    _scrollPosition?.removeListener(_onScrollChanged);
    _autoScrollTimer?.cancel();
    _indicatorTimer?.cancel();
    _hoverDwellTimer?.cancel();
    _resumeClipCapTimer?.cancel();
    _pageController.dispose();
    _focusNode.dispose();
    _indicatorProgress.dispose();
    _currentIndex.dispose();
    super.dispose();
  }

  void requestFocusAt(int index) => _focusNode.requestFocus();

  void requestFocusFromMemory() => _focusNode.requestFocus();

  bool get _trailerEnabled => widget.hub.heroTrailerPreview;

  /// Plain periodic auto-advance — identical for every row, trailer-enabled
  /// or not, gated only on visibility (and, for trailer rows, not currently
  /// hovered/playing). TV dwell-trailer (d-pad focus instead of mouse hover)
  /// needs its own integration with the TV spotlight/focus system this
  /// widget doesn't have yet — deliberately out of scope for this pass, so
  /// TV keeps the pre-existing early-return here.
  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (PlatformDetector.isTV() || _isAutoScrollPaused || !mounted || !_isVisible) return;
    if (_isHovering && _trailerEnabled) return; // the hover dwell timer owns the schedule right now
    if (_trailerIndex != null) return; // trailer currently playing this slide

    _startIndicatorProgress();
    _autoScrollTimer = Timer.periodic(_autoScrollDuration, (timer) {
      if (_isAutoScrollPaused) return;
      _advancePage();
    });
  }

  /// Pages to the next item. [onPageChanged] (in [build]) does all the
  /// actual timer/dwell restart work once the index actually changes —
  /// shared by plain auto-advance and every trailer outcome (played to
  /// completion, failed, or nothing to play), so a trailer-enabled row
  /// always eventually keeps moving through its items instead of freezing
  /// on whichever one it dwelled on first.
  void _advancePage() {
    if (_items.isEmpty || !_pageController.hasClients) return;
    if (_currentIndex.value >= _items.length) _currentIndex.value = 0;
    final nextPage = (_currentIndex.value + 1) % _items.length;
    _pageController.animateToPage(nextPage, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
  }

  /// Pointer entered this specific card. Only trailer-enabled rows react —
  /// plain rows keep auto-rotating through hover untouched. Starts a fresh
  /// 3s dwell before actually calling [_startTrailer]; per spec nothing
  /// should play "unless the cursor... is [over it]", so hover is the only
  /// thing that can ever arm this timer.
  void _onHoverEnter(int index) {
    if (PlatformDetector.isTV() || !_trailerEnabled) return;
    _isHovering = true;
    _autoScrollTimer?.cancel();
    _indicatorTimer?.cancel();
    if (_trailerIndex == index) return; // already playing this exact slide
    _hoverDwellTimer?.cancel();
    _hoverDwellTimer = Timer(_trailerDwellDuration, () {
      if (!mounted || !_isHovering) return;
      unawaited(_startTrailer());
    });
  }

  /// Pointer left the card. Stops any trailer instantly (per spec: "move
  /// it, it stops instantly... otherwise it should just sit on the poster
  /// card") and resumes normal auto-rotation on the current item rather
  /// than skipping ahead.
  void _onHoverExit() {
    if (PlatformDetector.isTV() || !_trailerEnabled) return;
    _isHovering = false;
    _hoverDwellTimer?.cancel();
    if (_trailerIndex != null) _stopTrailer();
    _startAutoScroll();
  }

  /// `PlayerNative.open()` calls `setVisible(true)` on the shared native
  /// child HWND right at its own start (player_native.dart), before media
  /// even loads — showing that window at whatever rect it was last
  /// positioned to. The just-mounted [Video] widget's own on-screen rect
  /// only reaches native from a `postFrameCallback` registered during ITS
  /// first layout pass, which only happens on Flutter's next frame after
  /// the `setState` that mounts it. Without waiting here, the shared HWND
  /// pops up at the previous card's position (or the native default
  /// 0,0,100x100 on the very first play ever) before ever being told where
  /// this card actually is — confirmed by reading both call sites directly,
  /// not guessed; this is the "secondary popup not covering the card" bug
  /// reported 2026-09-10. One frame is enough: Dart resumes an `await`
  /// continuation as a microtask, so the rect-push callback (registered and
  /// invoked synchronously within the same postFrameCallback pass this
  /// waiter's own callback fires in) has already dispatched its channel
  /// message by the time control returns to this function.
  Future<void> _waitForNextFrame() {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) => completer.complete());
    return completer.future;
  }

  /// Resolves and plays a trailer/scene clip for whatever item is currently
  /// showing, in place of its static backdrop. Guarded by
  /// [_trailerRequestToken] so a resolution that finishes after the user has
  /// already paged away (during the async gap) can't start playing over the
  /// wrong item.
  Future<void> _startTrailer() async {
    if (_currentIndex.value >= _items.length) return;
    // The raw hub item's own viewOffsetMs can be stale — it's whatever Plex
    // returned whenever this hub was last fetched, not necessarily the
    // user's actual latest position (e.g. updated from another
    // session/device since). WatchStateStore tracks the real current value
    // separately; _buildPlayButton already refreshes through it for the
    // same reason. Without this, Continue Watching's resume-clip preview
    // (_isContinueWatching below) only worked for whichever items' stale
    // hub data happened to still be accurate — the "works for some movies"
    // bug reported 2026-09-10.
    final item = context.readFreshWatchState(_items[_currentIndex.value]);
    final client = _clientFor(item);
    if (client == null) {
      _advancePage(); // no client to resolve against - don't freeze here
      return;
    }
    final requestIndex = _currentIndex.value;
    final token = ++_trailerRequestToken;
    final HoverPreviewSource source;
    try {
      source = await _trailerResolver.resolve(client, item, preferResumePosition: _isContinueWatching);
    } catch (e) {
      appLogger.d('[hero-trailer] resolve FAILED id=${item.id}: $e');
      if (token == _trailerRequestToken) _advancePage();
      return;
    }
    // Also bail if hover ended during the resolve gap — otherwise a trailer
    // can start playing for a card the pointer has already left, which is
    // exactly the "should just sit on the poster card" case the hover gate
    // exists to prevent.
    if (!mounted || token != _trailerRequestToken || !_isHovering) return;
    switch (source) {
      case TrailerPreviewSource(:final streamUrl):
        appLogger.i('[hero-trailer] playing trailer for "${item.title}": $streamUrl');
        setState(() => _trailerIndex = requestIndex);
        await _waitForNextFrame();
        if (!mounted || token != _trailerRequestToken || !_isHovering) return;
        await widget.playerController.play(streamUrl);
      case SceneClipPreviewSource(:final streamUrl, :final startOffset):
        appLogger.i('[hero-trailer] playing scene clip for "${item.title}" at $startOffset: $streamUrl');
        setState(() => _trailerIndex = requestIndex);
        await _waitForNextFrame();
        if (!mounted || token != _trailerRequestToken || !_isHovering) return;
        await widget.playerController.play(streamUrl, startAt: startOffset);
        if (_isContinueWatching && mounted && token == _trailerRequestToken) {
          _resumeClipCapTimer?.cancel();
          _resumeClipCapTimer = Timer(_resumeClipPreviewCap, () {
            if (!mounted || token != _trailerRequestToken || _trailerIndex != requestIndex) return;
            setState(() => _trailerIndex = null);
            unawaited(widget.playerController.stop());
            _startAutoScroll();
          });
        }
      case NoPreviewSource():
        // Nothing to play for this item - move on rather than freezing here
        // forever (this dwell timer is one-shot, nothing else would ever
        // re-arm it otherwise).
        appLogger.d('[hero-trailer] no preview source for "${item.title}"');
        _advancePage();
    }
  }

  /// Stops any trailer this row started and clears its slide marker. Called
  /// on any manual navigation (paging, tapping away) so leaving an item
  /// always leaves its trailer behind rather than carrying it onto the next
  /// one, per spec ("moving to the next hero item stops the preview
  /// instantly"). Safe to call even if a DIFFERENT row is the one actually
  /// playing — only tears down playback if this row believes it owns it.
  void _stopTrailer() {
    _trailerRequestToken++; // invalidate any in-flight resolve/play
    _resumeClipCapTimer?.cancel();
    if (_trailerIndex == null) return;
    setState(() => _trailerIndex = null);
    unawaited(widget.playerController.stop());
  }

  void _startIndicatorProgress() {
    if (!mounted) return;
    _indicatorTimer?.cancel();
    _indicatorProgress.value = 0.0;
    // Only ever called for the plain auto-advance schedule now — hover-
    // gated trailer dwell doesn't drive this indicator.
    final totalSteps = _autoScrollDuration.inMilliseconds ~/ _indicatorUpdateInterval.inMilliseconds;
    var step = 0;
    _indicatorTimer = Timer.periodic(_indicatorUpdateInterval, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      step++;
      _indicatorProgress.value = (step / totalSteps).clamp(0.0, 1.0);
      if (step >= totalSteps) timer.cancel();
    });
  }

  void _pauseAutoScroll() {
    setState(() => _isAutoScrollPaused = true);
    _autoScrollTimer?.cancel();
    _indicatorTimer?.cancel();
  }

  void _resumeAutoScroll() {
    setState(() => _isAutoScrollPaused = false);
    _startAutoScroll();
  }

  ({int start, int end}) _visibleDotRange() {
    final total = _items.length;
    if (total <= 5) return (start: 0, end: total - 1);
    final center = _currentIndex.value;
    final start = (center - 2).clamp(0, total - 5);
    return (start: start, end: start + 4);
  }

  Widget _buildArrowButton({required bool isLeft, required int currentIndex}) {
    final enabled = isLeft ? currentIndex > 0 : currentIndex < _items.length - 1;
    return ClickableCursor(
      child: GestureDetector(
        onTap: !enabled
            ? null
            : () {
                if (isLeft) {
                  _pageController.previousPage(duration: tokens(context).slow, curve: Curves.easeInOut);
                } else {
                  _pageController.nextPage(duration: tokens(context).slow, curve: Curves.easeInOut);
                }
              },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.4), shape: BoxShape.circle),
          child: AppIcon(
            isLeft ? Symbols.chevron_left_rounded : Symbols.chevron_right_rounded,
            color: Colors.white.withValues(alpha: enabled ? 1.0 : 0.3),
            size: 22,
          ),
        ),
      ),
    );
  }

  double _dotSize(int dotIndex, int start, int end) {
    if (_items.length <= 5) return 8.0;
    if (dotIndex == start || dotIndex == end) return 4.0;
    if (dotIndex == start + 1 || dotIndex == end - 1) return 6.0;
    return 8.0;
  }

  MediaServerClient? _clientFor(MediaItem item) {
    final serverId = item.serverId;
    if (serverId == null) return context.tryGetMediaClientForServer(null);
    return context.tryGetMediaClientForServer(ServerId(serverId));
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();

    final statusBarHeight = MediaQuery.paddingOf(context).top;
    final useSideNav = PlatformDetector.shouldUseSideNavigation(context);
    final isTv = PlatformDetector.isTV();
    final heroHeight = isTv
        ? MediaQuery.sizeOf(context).height * 0.82
        : useSideNav
        ? MediaQuery.sizeOf(context).height * 0.75
        : 500 + statusBarHeight;

    return Focus(
      focusNode: _focusNode,
      child: SizedBox(
        height: heroHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _items.length,
              onPageChanged: (index) {
                if (index < 0 || index >= _items.length) return;
                _stopTrailer();
                _currentIndex.value = index;
                _autoScrollTimer?.cancel();
                _indicatorTimer?.cancel();
                _hoverDwellTimer?.cancel();
                // Arriving at a new item — by arrow, by auto-rotate, or by
                // the previous item's trailer finishing — always shows its
                // poster first, never chains straight into its trailer, even
                // if the pointer never physically left the card (e.g. it's
                // still sitting over an arrow button). Only a genuinely
                // fresh dwell earns that new item a trailer.
                if (_isHovering && _trailerEnabled) {
                  _hoverDwellTimer = Timer(_trailerDwellDuration, () {
                    if (!mounted || !_isHovering) return;
                    unawaited(_startTrailer());
                  });
                } else {
                  _startAutoScroll();
                }
              },
              itemBuilder: (context, index) => _buildHeroItem(context, _items[index], index, heroHeight),
            ),
            // Row name — multiple hero rows can be on screen at once, so
            // unlike the old single-hero-slot version there's otherwise no
            // way to tell which configured row a given card is showing.
            Positioned(
              top: MediaQuery.paddingOf(context).top + (isTv ? TvLayoutConstants.horizontalInset : 16),
              left: isTv ? TvLayoutConstants.horizontalInset : 16,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.hub.title,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: isTv ? 16 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            if (!isTv && _items.length > 1)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ValueListenableBuilder<int>(
                        valueListenable: _currentIndex,
                        builder: (context, index, _) => _buildArrowButton(isLeft: true, currentIndex: index),
                      ),
                      ValueListenableBuilder<int>(
                        valueListenable: _currentIndex,
                        builder: (context, index, _) => _buildArrowButton(isLeft: false, currentIndex: index),
                      ),
                    ],
                  ),
                ),
              ),
            if (!isTv)
              Positioned(
                bottom: 16,
                left: -26,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClickableCursor(
                      child: GestureDetector(
                        onTap: () => _isAutoScrollPaused ? _resumeAutoScroll() : _pauseAutoScroll(),
                        child: AppIcon(
                          _isAutoScrollPaused ? Symbols.play_arrow_rounded : Symbols.pause_rounded,
                          fill: 1,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ValueListenableBuilder<int>(
                      valueListenable: _currentIndex,
                      builder: (context, current, _) {
                        final range = _visibleDotRange();
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(range.end - range.start + 1, (i) {
                            final index = range.start + i;
                            final isActive = current == index;
                            final dotSize = _dotSize(index, range.start, range.end);
                            final onSurface = Theme.of(context).colorScheme.onSurface;
                            return isActive
                                ? ValueListenableBuilder<double>(
                                    valueListenable: _indicatorProgress,
                                    builder: (context, progress, child) {
                                      final maxWidth = dotSize * 3;
                                      final fillWidth = dotSize + ((maxWidth - dotSize) * progress);
                                      return Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        width: maxWidth,
                                        height: dotSize,
                                        decoration: BoxDecoration(
                                          color: onSurface.withValues(alpha: 0.4),
                                          borderRadius: BorderRadius.circular(dotSize / 2),
                                        ),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            width: fillWidth,
                                            height: dotSize,
                                            decoration: BoxDecoration(
                                              color: onSurface,
                                              borderRadius: BorderRadius.circular(dotSize / 2),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : AnimatedContainer(
                                    duration: tokens(context).slow,
                                    curve: Curves.easeInOut,
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: dotSize,
                                    height: dotSize,
                                    decoration: BoxDecoration(
                                      color: onSurface.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(dotSize / 2),
                                    ),
                                  );
                          }),
                        );
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroItem(BuildContext context, MediaItem heroItem, int index, double heroHeight) {
    final client = _clientFor(heroItem);
    final isEpisode = heroItem.isEpisode;
    final isTv = PlatformDetector.isTV();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final heroAspectRatio = screenWidth / heroHeight;
    final heroArtPaths = heroItem.heroArtCandidates(containerAspectRatio: heroAspectRatio);
    final colorScheme = Theme.of(context).colorScheme;
    final heroLabel = isEpisode ? '${heroItem.grandparentTitle}, ${heroItem.title}' : heroItem.title;

    return Semantics(
      label: heroLabel,
      button: true,
      hint: t.accessibility.tapToPlay,
      child: MouseRegion(
        onEnter: (_) => _onHoverEnter(index),
        onExit: (_) => _onHoverExit(),
        child: ClickableCursor(
          child: GestureDetector(
            onTap: () async {
              // Captured before stop() below — that call doesn't touch
              // _trailerIndex itself (only _stopTrailer does), but reading
              // it after an await risks a rebuild changing it first.
              final wasShowingTrailer = _trailerIndex == index;
              // Stop and await the shared controller before handing off to
              // real playback — Windows backs the whole app with one
              // process-wide native video core; the video player screen
              // initializing before this controller's own teardown finishes
              // races for that same channel (observed as a hard crash on the
              // old branch this was ported from). Resolves near-instantly
              // when nothing's actually playing. Also worth doing before
              // opening details — a trailer shouldn't keep playing in the
              // background once the user has navigated away from the card.
              await widget.playerController.stop();
              if (!context.mounted) return;
              // User-configurable (Home layout settings → "Hero cards") —
              // some people want a tap to act like a remote (play
              // immediately), others want it to browse first (open details,
              // decide from there). Tapping the static poster and tapping a
              // playing trailer are independently configurable (per user
              // request 2026-09-10) — the same card can play on a poster tap
              // but open details on a mid-trailer tap, or vice versa. The
              // Play button in the overlay always plays directly regardless
              // of either setting.
              final tapAction = SettingsService.instance.read(
                wasShowingTrailer ? SettingsService.heroCardTrailerTapAction : SettingsService.heroCardTapAction,
              );
              unawaited(navigateToMediaItem(context, heroItem, playDirectly: tapAction == HeroCardTapAction.play));
            },
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                // Backdrop art — always rendered, independent of trailer
                // state, and unconditionally painted whether or not a
                // trailer is currently showing over it.
                if (heroArtPaths.isNotEmpty)
                  TweenAnimationBuilder<double>(
                    key: ValueKey(heroItem.globalKey),
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 1.0 + (0.1 * (1 - value)),
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: blurArtwork(
                      CyclingMediaBackdrop(
                        mediaKey: heroItem.globalKey,
                        imagePaths: heroItem.heroRotationPaths(containerAspectRatio: heroAspectRatio),
                        fallbackImagePaths: heroArtPaths,
                        client: client,
                        active: true,
                        width: screenWidth,
                        height: heroHeight,
                        fallbackColor: colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  )
                else
                  ColoredBox(color: colorScheme.surfaceContainerHighest),
                // Reactive to widget.playerController, not a plain local bool —
                // play() marks player non-null synchronously, before the
                // stream has actually opened or decoded, and a resolved-but-
                // broken stream only reveals itself asynchronously afterward
                // via playbackFailed. Without listening here, a failed stream
                // left a dead black video surface up permanently instead of
                // falling back to the backdrop (the actual bug reported
                // 2026-09-10) — this controller's own doc comment describes
                // exactly this scenario and the fallback it's meant to enable;
                // the hover-preview cards elsewhere already rely on it too.
                //
                // Inset, not full-bleed — confirmed via the native source
                // (not a guess or an empirical trial-and-error): mpv's video
                // child HWND is created as a child of
                // registrar_->GetView()->GetNativeWindow() (mpv_plugin.cpp,
                // FlutterWindow::OnCreate in flutter_window.cpp) — Flutter's
                // OWN rendering surface. A Win32 child window always paints
                // over its parent's content within its bounds; this is
                // structural, not a z-order setting, so NO Flutter widget
                // anywhere in the tree can ever appear on top of this video
                // within its rect, full stop. Three different placements
                // were tried and failed for exactly this reason (separate
                // Positioned sibling, Video's own `controls` slot, and a
                // row-level Stack) before finding this in the native code.
                // The only sound fix is genuine non-overlap: keep the
                // video's rect and _buildOverlayContent's rect from ever
                // intersecting on screen. Side inset clears the arrow
                // buttons; bottom inset is [_measuredVideoBottomInset] — the
                // content block's actual measured height, not a guessed
                // fraction — so the video gets as much of the card as it
                // genuinely can (per spec: "add a space on the bottom that
                // all that information can sit... [rest is] full video").
                ListenableBuilder(
                  listenable: widget.playerController,
                  builder: (context, _) {
                    final showTrailer =
                        _trailerIndex == index &&
                        widget.playerController.player != null &&
                        !widget.playerController.playbackFailed;
                    if (!showTrailer) return const SizedBox.shrink();
                    return Positioned(
                      top: 0,
                      left: _videoSideInset,
                      right: _videoSideInset,
                      bottom: _videoBottomInset(heroHeight, isTv),
                      child: ClipRect(child: Video(player: widget.playerController.player!)),
                    );
                  },
                ),
                _buildOverlayContent(context, heroItem, heroHeight, index),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Gradient + title/facts/summary/play button for one hero item. Called
  /// unconditionally from [_buildHeroItem] (not gated on trailer state) so
  /// this content never moves or flickers when playback starts or stops —
  /// see the video inset comment there for why it has to stay genuinely
  /// outside the video's own rect rather than drawn over it.
  ///
  /// [index] gates [_contentBlockKey] to only the currently-displayed page —
  /// PageView keeps neighboring pages built (viewport/cache extent), so
  /// every visible `_buildOverlayContent` call happens at once; attaching a
  /// single GlobalKey to more than one of them at a time is an assertion
  /// failure, not just a measurement bug.
  Widget _buildOverlayContent(BuildContext context, MediaItem heroItem, double heroHeight, int index) {
    final client = _clientFor(heroItem);
    final showName = heroItem.grandparentTitle ?? heroItem.displayTitle;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isLargeScreen = ScreenBreakpoints.isWideTabletOrLarger(screenWidth);
    final isTv = PlatformDetector.isTV();
    final alignLeft = isTv || isLargeScreen;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final heroLogoWidth = isTv ? TvLayoutConstants.heroLogoWidth : 400.0;
    final heroLogoHeight = isTv ? TvLayoutConstants.heroLogoHeight : 120.0;
    final heroTitleStyle = theme.textTheme.displaySmall?.copyWith(
      color: colorScheme.onSurface,
      fontWeight: FontWeight.bold,
      fontSize: isTv ? 52 : null,
      shadows: [Shadow(color: colorScheme.surface.withValues(alpha: 0.8), blurRadius: 8)],
    );
    final contentTypeLabel = heroItem.isMovie ? t.discover.movie : t.discover.tvShow;
    final hideSpoilers = SettingsService.instance.read(SettingsService.hideSpoilers);
    final shouldHideSpoiler = hideSpoilers && heroItem.shouldHideSpoiler;
    final isCurrentPage = index == _currentIndex.value;
    final factsText = [
      contentTypeLabel,
      if (heroItem.rating != null) '★ ${formatRating(heroItem.rating!)}',
      if (heroItem.contentRating != null) formatContentRating(heroItem.contentRating!),
      if (heroItem.year != null) heroItem.year.toString(),
    ].join(' • ');
    // Title specifically opens the details/metadata page (playDirectly:
    // false) rather than starting playback — a deliberately different
    // action from tapping the rest of the card (plays directly) or the
    // Play button (also plays directly). Nested inside the card's own
    // GestureDetector in both layouts below; Flutter's gesture arena
    // resolves a plain tap to whichever recognizer is innermost, so this
    // wins over the card's own onTap without also triggering it.
    void openDetails() => unawaited(navigateToMediaItem(context, heroItem));

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: -4,
          child: IgnorePointer(
            child: Builder(
              builder: (context) {
                final bgColor = Theme.of(context).scaffoldBackgroundColor;
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, bgColor.withValues(alpha: 0.9), bgColor, bgColor],
                      stops: isTv ? const [0.25, 0.78, 0.94, 1.0] : const [0.5, 0.85, 0.94, 1.0],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // Reactive: a genuinely compact strip while a trailer plays (per
        // spec — "full screen like before and a strip at the bottom with
        // the info" — so the video gets nearly the whole card), the full
        // logo/facts/summary/play-button block otherwise, for the static
        // poster where there's no video to make room for. Only the compact
        // strip's height feeds [_measureContentBlock] — the full block
        // never needs measuring since nothing insets around it.
        ListenableBuilder(
          listenable: widget.playerController,
          builder: (context, _) {
            final showTrailer =
                _trailerIndex == index &&
                widget.playerController.player != null &&
                !widget.playerController.playbackFailed;
            if (showTrailer) {
              const compactBottomAnchor = 20.0;
              if (isCurrentPage) _measureContentBlock(compactBottomAnchor);
              return Positioned(
                bottom: compactBottomAnchor,
                left: 0,
                right: 0,
                child: Padding(
                  key: isCurrentPage ? _contentBlockKey : null,
                  padding: EdgeInsets.symmetric(horizontal: isTv ? TvLayoutConstants.horizontalInset : 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ClickableCursor(
                          child: GestureDetector(
                            onTap: openDetails,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  showName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isTv ? 24 : 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  factsText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                                    fontSize: isTv ? 14 : 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (heroItem.summary != null && !shouldHideSpoiler) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    heroItem.summary!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                                      fontSize: isTv ? 13 : 11,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildPlayButton(context, heroItem),
                    ],
                  ),
                ),
              );
            }
            return Positioned(
              bottom: isTv
                  ? 88
                  : isLargeScreen
                  ? 80
                  : 50,
              left: 0,
              right: isTv
                  ? screenWidth * 0.36
                  : isLargeScreen
                  ? 200
                  : 0,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTv
                      ? TvLayoutConstants.horizontalInset
                      : isLargeScreen
                      ? 40
                      : 24,
                ),
                child: Align(
                  alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTv ? TvLayoutConstants.heroContentMaxWidth : double.infinity,
                    ),
                    child: Column(
                      crossAxisAlignment: alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClickableCursor(
                          child: GestureDetector(
                            onTap: openDetails,
                            child: ClearLogoImage(
                              client: client,
                              logoPath: heroItem.clearLogoPath,
                              width: heroLogoWidth,
                              height: heroLogoHeight,
                              alignment: alignLeft ? Alignment.bottomLeft : Alignment.bottomCenter,
                              fallbackBuilder: (context) => FittingTitleText(
                                showName,
                                style: heroTitleStyle,
                                textAlign: alignLeft ? TextAlign.left : TextAlign.center,
                                alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
                              ),
                            ),
                          ),
                        ),
                        if (heroItem.year != null || heroItem.contentRating != null || heroItem.rating != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            factsText,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: isTv ? 18 : 14,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: alignLeft ? TextAlign.left : TextAlign.center,
                          ),
                        ],
                        if (!alignLeft) ...[const SizedBox(height: 20), _buildPlayButton(context, heroItem)],
                        if (heroItem.summary != null && !shouldHideSpoiler) ...[
                          const SizedBox(height: 12),
                          Text(
                            heroItem.summary!,
                            maxLines: isTv ? 3 : 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: alignLeft ? TextAlign.left : TextAlign.center,
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                              fontSize: isTv ? 18 : 14,
                              height: isTv ? 1.45 : 1.4,
                            ),
                          ),
                        ],
                        if (alignLeft) ...[const SizedBox(height: 20), _buildPlayButton(context, heroItem)],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPlayButton(BuildContext context, MediaItem rawHeroItem) {
    return Builder(
      builder: (context) {
        final heroItem = context.withFreshWatchState(rawHeroItem);
        final hasProgress = heroItem.hasActiveProgress;
        final isTv = PlatformDetector.isTV();
        final minutesLeft = hasProgress ? ((heroItem.durationMs! - heroItem.viewOffsetMs!) / 60_000).round() : 0;
        return ListenableBuilder(
          listenable: _focusNode,
          builder: (context, _) {
            final showFocus = isTv && _focusNode.hasFocus && InputModeTracker.isKeyboardMode(context);
            final colorScheme = Theme.of(context).colorScheme;
            final backgroundColor = showFocus ? colorScheme.primary : Colors.white;
            final foregroundColor = showFocus ? colorScheme.onPrimary : Colors.black;
            return InkWell(
              onTap: () => navigateToVideoPlayer(context, metadata: heroItem),
              borderRadius: BorderRadius.all(Radius.circular(isTv ? 32 : 24)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(horizontal: isTv ? 34 : 24, vertical: isTv ? 16 : 12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.all(Radius.circular(isTv ? 32 : 24)),
                  boxShadow: showFocus
                      ? [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.35), blurRadius: 28, spreadRadius: 4)]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(Symbols.play_arrow_rounded, fill: 1, size: isTv ? 28 : 20, color: foregroundColor),
                    const SizedBox(width: 8),
                    Text(
                      hasProgress ? '$minutesLeft min left' : t.common.play,
                      style: TextStyle(color: foregroundColor, fontWeight: FontWeight.bold, fontSize: isTv ? 18 : 14),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
