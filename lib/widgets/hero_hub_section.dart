import '../i18n/presentation_formats.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/widgets/app_icon.dart';

import '../focus/dpad_navigator.dart';
import '../focus/focus_theme.dart';
import '../focus/input_mode_tracker.dart';
import '../navigation/main_screen_scope.dart';
import '../media/ids.dart';
import '../media/media_hub.dart';
import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../media/media_server_client.dart';
import '../providers/watch_state_store.dart';
import '../services/settings_service.dart';
import '../theme/mono_tokens.dart';
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
class HeroHubSection extends StatefulWidget {
  const HeroHubSection({
    super.key,
    required this.hub,
    this.showBackdrop = true,
    required this.onVerticalNavigation,
    this.onNavigateUp,
    this.onNavigateToSidebar,
    this.onFocusedItemChanged,
  });

  final MediaHub hub;
  final bool showBackdrop;

  /// TV only — same contract as HubSection's own onFocusedItemChanged.
  /// Reported on every page change and whenever this row gains focus, so a
  /// screen-level ambient backdrop can track the hero row's own current
  /// item too, not just plain rows (per user request 2026-09-11: "have the
  /// banner card do the same thing when highlighted" — the hero row's
  /// already-big art extending to fill the dead space around it, the same
  /// way a plain row's focused card art now does).
  final ValueChanged<MediaItem>? onFocusedItemChanged;

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

  final _pageController = PageController();
  final _focusNode = FocusNode(debugLabel: 'hero_hub_section');
  final _indicatorProgress = ValueNotifier<double>(0.0);
  final _currentIndex = ValueNotifier<int>(0);

  /// TV only, gated by SettingsService.tvHeroPlayButtonFocus — whether
  /// d-pad focus has drilled down from the card itself onto its Play
  /// button specifically. Only ever set by _handleTvKeyEvent's Down/Up/
  /// Left/Right handling; cleared on page change and on losing focus so a
  /// new item never inherits the previous item's
  /// drilled-in state.
  bool _playButtonFocused = false;

  Timer? _autoScrollTimer;
  Timer? _indicatorTimer;
  bool _isAutoScrollPaused = false;
  bool _disableAnimations = false;
  bool _accessibleNavigation = false;

  /// The scrollable this row lives in doesn't lazily unmount off-screen
  /// slivers (every hub is a plain SliverToBoxAdapter, always built), so
  /// without a visibility check every hero row on the page — not just the
  /// one actually on screen — would auto-rotate at once regardless of
  /// scroll position. Per the spec this is now a pure "any part of the row
  /// overlaps the viewport" check, not a narrow centered-band — auto-
  /// rotation should run "if they are visible on the screen at all".
  bool _isVisible = false;
  ScrollPosition? _scrollPosition;

  bool _computeIsVisible() {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) return false;
    final scrollable = Scrollable.maybeOf(context);
    // TV mounts this row in a fixed position (not inside a scrolling list of
    // rows the way PC does) — no enclosing Scrollable means there's nothing
    // to scroll it out of view of, so it's always visible, not never.
    if (scrollable == null) return true;
    final viewportRenderObject = scrollable.context.findRenderObject();
    if (viewportRenderObject is! RenderBox) return false;
    final viewportHeight = viewportRenderObject.size.height;
    final topLeft = renderObject.localToGlobal(Offset.zero, ancestor: viewportRenderObject);
    final top = topLeft.dy;
    final bottom = top + renderObject.size.height;
    return bottom > 0 && top < viewportHeight;
  }

  void _onScrollChanged() {
    final visible = _computeIsVisible();
    if (visible == _isVisible) return;
    _isVisible = visible;
    if (!_isVisible) {
      _autoScrollTimer?.cancel();
      _indicatorTimer?.cancel();
    } else {
      _startAutoScroll();
    }
  }

  List<MediaItem> get _items => widget.hub.items;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onTvFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _isVisible = _computeIsVisible();
      if (_isVisible) _startAutoScroll();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.of(context);
    if (_disableAnimations != media.disableAnimations || _accessibleNavigation != media.accessibleNavigation) {
      _disableAnimations = media.disableAnimations;
      _accessibleNavigation = media.accessibleNavigation;
      _startAutoScroll();
    }
    final newPosition = Scrollable.maybeOf(context)?.position;
    if (newPosition != _scrollPosition) {
      _scrollPosition?.removeListener(_onScrollChanged);
      _scrollPosition = newPosition;
      _scrollPosition?.addListener(_onScrollChanged);
    }
  }

  @override
  void didUpdateWidget(HeroHubSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hub.items.length != widget.hub.items.length && _currentIndex.value >= _items.length) {
      _currentIndex.value = 0;
    }
    if (oldWidget.hub.heroAutoSlide != widget.hub.heroAutoSlide ||
        oldWidget.hub.items.length != widget.hub.items.length) {
      _startAutoScroll();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onTvFocusChanged);
    _scrollPosition?.removeListener(_onScrollChanged);
    _autoScrollTimer?.cancel();
    _indicatorTimer?.cancel();
    _pageController.dispose();
    _focusNode.dispose();
    _indicatorProgress.dispose();
    _currentIndex.dispose();
    super.dispose();
  }

  void requestFocusAt(int index) {
    _focusNode.requestFocus();
    _scrollIntoView();
  }

  void requestFocusFromMemory() => requestFocusAt(0);

  /// Mirrors HubSection's own _scrollHubIntoView (same InputModeTracker
  /// gate, same Scrollable.ensureVisible call, same 0.3 alignment) — this
  /// widget never had it before tonight since it was never mounted
  /// somewhere that scrolled (per user request 2026-09-11: focus was
  /// moving between rows but the page wasn't following it). Alignment
  /// matters here specifically: the default (0.0) aligns this row's top
  /// edge flush with the very top of the scroll viewport, which is where
  /// the toolbar sits as a separate overlay on top of the scrollable — with
  /// no margin above it, the row's own top edge ends up sharing space with
  /// the toolbar instead of sitting below it (2026-09-11 bug report).
  /// HubSection's 0.3 leaves real breathing room there; reused verbatim for
  /// consistency rather than picking a new number.
  void _scrollIntoView() {
    if (InputModeTracker.currentMode != InputMode.keyboard) return;
    // TV already reserves toolbar clearance with a hard Positioned boundary
    // around the whole scroll viewport (discover_screen.dart's topSpacerHeight
    // wrapper) — PC's 0.3 alignment exists because PC's toolbar instead floats
    // over the scrollable with no such boundary. Reusing 0.3 on TV double-
    // reserved that same breathing room on top of the boundary that already
    // provides it, which barely showed on a normal poster row but blew up
    // into a huge empty gap above an 80%-of-viewport-tall hero row (2026-09-11
    // bug report: "banner is too small" — it wasn't small, it was scrolled
    // most of the way off the bottom of the screen).
    final alignment = PlatformDetector.isTV() ? 0.0 : 0.3;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        alignment: alignment,
        duration: _disableAnimations ? Duration.zero : const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
      );
    });
  }

  /// Plain periodic auto-advance, gated on visibility and on the row's own
  /// Auto-slide setting. Manual paging (arrows on PC, d-pad on TV) always
  /// works either way, and lands back here via onPageChanged, so a manual
  /// page restarts the auto timer from zero rather than fighting it.
  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (!widget.hub.heroAutoSlide || _items.length < 2 || _disableAnimations || _accessibleNavigation) {
      _indicatorTimer?.cancel();
      _indicatorProgress.value = 0.0;
      return;
    }
    if (_isAutoScrollPaused || !mounted || !_isVisible) return;

    _startIndicatorProgress();
    _autoScrollTimer = Timer.periodic(_autoScrollDuration, (timer) {
      if (_isAutoScrollPaused) return;
      _advancePage();
    });
  }

  /// Pages to the next item. [onPageChanged] (in [build]) does all the
  /// actual timer restart work once the index actually changes.
  void _advancePage() => _pageBy(1, const Duration(milliseconds: 500));

  /// Pages by [delta] with wrap-around in both directions (last -> first,
  /// first -> last), shared by auto-slide, the PC arrows, and the d-pad.
  /// A normal step slides; a wrap jumps instead, so going from the last item
  /// back to the first doesn't visibly rewind through every item in between
  /// (each item's backdrop still plays its own fade/zoom entrance).
  void _pageBy(int delta, Duration duration) {
    if (_items.length < 2 || !_pageController.hasClients) return;
    final current = _currentIndex.value.clamp(0, _items.length - 1);
    final raw = current + delta;
    final target = raw % _items.length;
    if (raw < 0 || raw >= _items.length || _disableAnimations || duration == Duration.zero) {
      _pageController.jumpToPage(target);
    } else {
      _pageController.animateToPage(target, duration: duration, curve: Curves.easeInOut);
    }
  }

  /// TV only — reports the current item to any screen-level listener when
  /// this row gains d-pad focus, and drops the drilled-into-Play state when
  /// it loses focus.
  void _onTvFocusChanged() {
    if (!PlatformDetector.isTV()) return;
    if (_focusNode.hasFocus) {
      if (_currentIndex.value < _items.length) {
        widget.onFocusedItemChanged?.call(_items[_currentIndex.value]);
      }
    } else {
      if (_playButtonFocused) setState(() => _playButtonFocused = false);
    }
  }

  /// TV d-pad handling — mirrors HubSection's own onKeyEvent contract
  /// exactly (this widget's onVerticalNavigation/onNavigateUp/
  /// onNavigateToSidebar constructor params were always shaped to match
  /// it), with Left/Right paging the carousel instead of moving between
  /// poster cards, and Select reusing the same tap-action logic as a mouse
  /// click.
  ///
  /// _playButtonFocused (per user request 2026-09-11, opt-in via
  /// SettingsService.tvHeroPlayButtonFocus) adds one more stop to that:
  /// with the setting on, the first Down focuses the Play button instead of
  /// leaving the row; Select there always plays directly (matching the
  /// button's own onTap), and a second Down (or Up, or paging away) moves
  /// on as normal. With the setting off, Down behaves exactly as before —
  /// _playButtonFocused simply never becomes true.
  KeyEventResult _handleTvKeyEvent(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;

    if (key.isSelectKey) {
      if (!event.isActionable) return KeyEventResult.handled;
      if (_currentIndex.value < _items.length) {
        final item = _items[_currentIndex.value];
        if (_playButtonFocused) {
          navigateToVideoPlayer(context, metadata: context.withFreshWatchState(item));
        } else {
          unawaited(_activateItem(context, item, _currentIndex.value));
        }
      }
      return KeyEventResult.handled;
    }

    if (!event.isActionable) return KeyEventResult.ignored;

    if (key.isInlineStart(context)) {
      if (_playButtonFocused) setState(() => _playButtonFocused = false);
      // Never wraps on TV: the first card hands Left to the sidebar so it
      // stays reachable from a hero row.
      if (_items.length > 1 && _currentIndex.value > 0) {
        _pageBy(-1, const Duration(milliseconds: 300));
      } else if (widget.onNavigateToSidebar != null) {
        widget.onNavigateToSidebar!();
      }
      return KeyEventResult.handled;
    }
    if (key.isInlineEnd(context)) {
      if (_playButtonFocused) setState(() => _playButtonFocused = false);
      final atEnd = _currentIndex.value >= _items.length - 1;
      if (!atEnd || SettingsService.instance.read(SettingsService.tvHeroWrapAround)) {
        _pageBy(1, const Duration(milliseconds: 300));
      }
      return KeyEventResult.handled;
    }
    if (key.isUpKey) {
      if (_playButtonFocused) {
        setState(() => _playButtonFocused = false);
        return KeyEventResult.handled;
      }
      final handled = widget.onVerticalNavigation(true);
      if (!handled && widget.onNavigateUp != null) widget.onNavigateUp!();
      return KeyEventResult.handled;
    }
    if (key.isDownKey) {
      if (!_playButtonFocused && SettingsService.instance.read(SettingsService.tvHeroPlayButtonFocus)) {
        setState(() => _playButtonFocused = true);
        return KeyEventResult.handled;
      }
      if (_playButtonFocused) setState(() => _playButtonFocused = false);
      widget.onVerticalNavigation(false);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _startIndicatorProgress() {
    if (!mounted) return;
    _indicatorTimer?.cancel();
    _indicatorProgress.value = 0.0;
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
    // Always enabled: paging wraps around in both directions.
    return IconButton(
      tooltip: isLeft
          ? MaterialLocalizations.of(context).previousPageTooltip
          : MaterialLocalizations.of(context).nextPageTooltip,
      onPressed: () => _pageBy(isLeft ? -1 : 1, tokens(context).slow),
      style: IconButton.styleFrom(backgroundColor: Colors.black.withValues(alpha: 0.4)),
      icon: AppIcon(
        isLeft ? Symbols.chevron_left_rounded : Symbols.chevron_right_rounded,
        color: Colors.white,
        size: 22,
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
    final showPointerControls = !isTv || PlatformDetector.isDesktopOS();
    // Fixed again (2026-09-11) — sizing this per-item from
    // _measureStaticCardHeight made the box's own height (and therefore
    // the backdrop's requested width/height) change on every single page
    // change, which broke the art itself: rotating to a new item kept
    // showing the previous item's art, sized wrong, while blank fallback
    // color showed through the gap (reported as "rotates to the next
    // banner but the background doesn't change"). A stable height is more
    // important than trimming the space below the Play button, which
    // fades to black anyway and was never the actual problem — the real
    // one was the art's TOP getting cropped (see heroAspectRatio below,
    // and the alignment fix on _scrollIntoView from earlier this session).
    final heroHeight = isTv
        ? MediaQuery.sizeOf(context).height * 0.8
        : useSideNav
        ? MediaQuery.sizeOf(context).height * 0.75
        : 500 + statusBarHeight;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleTvKeyEvent,
      // TV-only: some visible sign this row itself currently has d-pad
      // focus, distinct from just auto-rotating ambiently (per user
      // request 2026-09-11 — "it needs to highlight whatever it's on").
      // PC gets no visual change here at all (decoration stays null).
      child: ListenableBuilder(
        listenable: _focusNode,
        builder: (context, child) => Container(
          decoration: isTv
              ? FocusTheme.focusDecoration(
                  context,
                  isFocused: _focusNode.hasFocus && InputModeTracker.isKeyboardMode(context),
                  borderRadius: 0,
                )
              : null,
          child: child,
        ),
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
                  _currentIndex.value = index;
                  if (PlatformDetector.isTV() && _focusNode.hasFocus) {
                    widget.onFocusedItemChanged?.call(_items[index]);
                  }
                  // Safety net for auto-rotate/swipe paths that don't go
                  // through _handleTvKeyEvent's own reset (that one already
                  // clears this before paging) — a new item should never
                  // inherit the previous item's drilled-into-Play state.
                  if (_playButtonFocused) setState(() => _playButtonFocused = false);
                  _autoScrollTimer?.cancel();
                  _indicatorTimer?.cancel();
                  _startAutoScroll();
                },
                itemBuilder: (context, index) => _buildHeroItem(context, _items[index], index, heroHeight),
              ),
              // Row name — multiple hero rows can be on screen at once, so
              // unlike the old single-hero-slot version there's otherwise no
              // way to tell which configured row a given card is showing.
              PositionedDirectional(
                top: MediaQuery.paddingOf(context).top + (isTv ? 20.0 : 16),
                start: isTv ? 20.0 : 16,
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
              // Clickable arrows wherever there's a mouse: every non-TV
              // platform, plus a computer running with Force TV mode on (TV
              // layout, but still a pointer). Real TV boxes page by d-pad only.
              if (showPointerControls && _items.length > 1)
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
              // Nothing to page or pause with a single item.
              if (showPointerControls && _items.length > 1)
                PositionedDirectional(
                  bottom: 16,
                  start: widget.hub.heroAutoSlide ? -26 : 0,
                  end: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Pause/play only means something when this row slides
                      // on its own; manual-only rows just show the dots.
                      if (widget.hub.heroAutoSlide) ...[
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
                      ],
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
                                            alignment: AlignmentDirectional.centerStart,
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
      ),
    );
  }

  /// Shared by the card's own tap handler and the TV Select key — "activate
  /// whatever's currently showing," reading the same Organizer-configured
  /// tap-action settings either way.
  Future<void> _activateItem(BuildContext context, MediaItem heroItem, int index) async {
    // User-configurable (Home layout settings → "Hero cards") —
    // some people want a tap to act like a remote (play
    // immediately), others want it to browse first (open details,
    // decide from there). The Play button in the overlay always
    // plays directly regardless of this setting.
    final tapAction = SettingsService.instance.read(SettingsService.heroCardTapAction);
    unawaited(navigateToMediaItem(context, heroItem, playDirectly: tapAction == HeroCardTapAction.play));
  }

  Widget _buildHeroItem(BuildContext context, MediaItem heroItem, int index, double heroHeight) {
    final client = _clientFor(heroItem);
    final isEpisode = heroItem.isEpisode;
    final isTv = PlatformDetector.isTV();
    // The actual rendered width, not the raw device width — on TV the side
    // nav reserves real space (MainScreenFocusScope.foregroundWidthOf
    // already accounts for it, same as TvSpotlightScaffold's own layout
    // math does), so using the full device width here made this box's real
    // aspect narrower than heroAspectRatio assumed. BoxFit.cover then
    // cropped more off the sides than intended, cutting off baked-in title
    // text near the left edge of the art (2026-09-11 bug report). PC's own
    // width is left untouched — it isn't the platform this was reported on.
    final screenWidth = isTv ? MainScreenFocusScope.foregroundWidthOf(context) : MediaQuery.sizeOf(context).width;
    // Same technique media_detail_screen.dart's own hero backdrop already
    // uses (_heroArtHeight/_buildHeroBackdropLayer there) — cover-fitting a
    // 16:9 backdrop into a card this much wider than 16:9 scales it to the
    // card's width and then throws away top AND bottom of the frame,
    // cropping baked-in title text no matter which edge BoxFit aligns to
    // (2026-09-11: neither center nor top alignment actually fixed "72
    // Hours"/"Finding Emily"/"Future Man" all getting clipped — the box's
    // own shape was the real problem, not the alignment). Painting the art
    // at its own natural height instead keeps the whole frame; the surplus
    // simply overflows past this card's bottom edge (Stack below is
    // Clip.none) into whatever the scroll view shows next, fading to the
    // theme background well before it gets there — matching "I don't need
    // to see the bottom of the banner, it fades to black anyway."
    const heroBackdropAspect = 16 / 9;
    // The image itself must always be requested (and its candidate picked)
    // at its true 16:9 aspect. `getOptimizedImageUrl` passes width/height
    // straight through to the server's `cover`-mode transcode, which crops
    // server-side to whatever box it's asked for — feeding it a squeezed,
    // card-shaped height asked the server to crop to a box wider than 16:9,
    // which silently ate the top of the frame (baked-in titles included)
    // before the image ever reached Flutter. No client-side alignment/fit
    // can undo a crop that already happened upstream.
    //
    // The visible paint box must match that same native height — a lower
    // cap (previously 0.86 of screen height) just re-introduced the same
    // crop client-side via BoxFit.cover, trimming the bottom of a frame
    // that had plenty of room to show in full (2026-09-11 user: "you have a
    // ton of room... crop the image so the whole thing fits in the box").
    // No cap at all: the box always equals the fetched image's real size,
    // so nothing is ever cut. Stack below is Clip.none, so on tall/narrow
    // screens where that exceeds the row's own heroHeight, the surplus
    // simply overflows past this card into whatever the scroll view shows
    // next, fading to the theme background well before it gets there —
    // matching "I don't need to see the bottom of the banner, it fades to
    // black anyway."
    final nativeArtHeight = screenWidth / heroBackdropAspect;
    final artHeight = isTv ? nativeArtHeight : heroHeight;
    final heroAspectRatio = isTv ? heroBackdropAspect : screenWidth / artHeight;
    final heroArtPaths = heroItem.heroArtCandidates(containerAspectRatio: heroAspectRatio);
    final colorScheme = Theme.of(context).colorScheme;
    final heroLabel = isEpisode ? '${heroItem.grandparentTitle}, ${heroItem.title}' : heroItem.title;

    return Semantics(
      label: heroLabel,
      button: true,
      hint: t.accessibility.tapToPlay,
      child: ClickableCursor(
        child: GestureDetector(
          onTap: () => unawaited(_activateItem(context, heroItem, index)),
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
              // Backdrop art.
              if (widget.showBackdrop && heroArtPaths.isNotEmpty)
                PositionedDirectional(
                  top: 0,
                  start: 0,
                  end: 0,
                  height: isTv ? artHeight : null,
                  bottom: isTv ? null : 0,
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey(heroItem.globalKey),
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: _disableAnimations ? Duration.zero : const Duration(milliseconds: 800),
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
                        // A manual-only row stays put entirely, including
                        // the item's own art rotation, which otherwise reads
                        // as the row auto-moving.
                        active: widget.hub.heroAutoSlide,
                        width: screenWidth,
                        // Always request the image at its true native
                        // height — never the clamped, card-shaped
                        // `artHeight` — so the server's cover-crop has
                        // nothing to throw away.
                        height: isTv ? nativeArtHeight : artHeight,
                        fallbackColor: colorScheme.surfaceContainerHighest,
                        // Safety net only — the image is fetched at its
                        // true aspect now, so BoxFit.cover needs little to
                        // no crop; on the rare item where the paint box
                        // (artHeight) is clamped shorter than the image's
                        // natural height, top-aligning keeps that crop off
                        // the top (where baked-in title text usually sits)
                        // instead of splitting it evenly top and bottom.
                        alignment: isTv ? Alignment.topCenter : Alignment.center,
                      ),
                    ),
                  ),
                )
              else
                PositionedDirectional(
                  top: 0,
                  start: 0,
                  end: 0,
                  height: isTv ? artHeight : null,
                  bottom: isTv ? null : 0,
                  child: ColoredBox(color: colorScheme.surfaceContainerHighest),
                ),
              _buildOverlayContent(context, heroItem, heroHeight, index),
            ],
          ),
        ),
      ),
    );
  }

  /// Gradient + title/facts/summary/play button for one hero item.
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
        PositionedDirectional(
          top: 0,
          start: 0,
          end: 0,
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
        PositionedDirectional(
          bottom: isTv
              ? 88
              : isLargeScreen
              ? 80
              : 50,
          start: 0,
          end: isTv
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
              alignment: alignLeft ? AlignmentDirectional.centerStart : Alignment.center,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isTv ? TvLayoutConstants.heroContentMaxWidth : double.infinity),
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
                          fallbackWidth: ClearLogoImage.fallbackWidthFor(
                            logoWidth: heroLogoWidth,
                            available: isTv ? TvLayoutConstants.heroContentMaxWidth : screenWidth,
                          ),
                          alignment: alignLeft
                              ? AlignmentDirectional.bottomStart.resolve(Directionality.of(context))
                              : Alignment.bottomCenter,
                          fallbackBuilder: (context) => FittingTitleText(
                            showName,
                            style: heroTitleStyle,
                            textAlign: alignLeft ? TextAlign.start : TextAlign.center,
                            alignment: alignLeft ? AlignmentDirectional.centerStart : Alignment.center,
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
                        textAlign: alignLeft ? TextAlign.start : TextAlign.center,
                      ),
                    ],
                    if (!alignLeft) ...[const SizedBox(height: 20), _buildPlayButton(context, heroItem)],
                    if (heroItem.summary != null && !shouldHideSpoiler) ...[
                      const SizedBox(height: 12),
                      Text(
                        heroItem.summary!,
                        maxLines: isTv ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: alignLeft ? TextAlign.start : TextAlign.center,
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
            // TV-only, opt-in (SettingsService.tvHeroPlayButtonFocus) — not
            // just "this row has focus" (that lit the button up any time
            // the row did, with no way to actually land on it via d-pad).
            // _playButtonFocused only ever becomes true through the
            // dedicated Down-key handling in _handleTvKeyEvent, which
            // itself only runs when the setting is on.
            final showFocus = isTv && _playButtonFocused && InputModeTracker.isKeyboardMode(context);
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
                      hasProgress
                          ? t.discover.minutesLeft(minutes: formatDecimal(minutesLeft, maximumDecimals: 0))
                          : t.common.play,
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
