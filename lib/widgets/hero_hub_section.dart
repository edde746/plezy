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
import '../providers/watch_state_store.dart';
import '../utils/provider_extensions.dart';
import '../services/settings_service.dart';
import '../theme/mono_tokens.dart';
import '../utils/content_utils.dart';
import '../utils/formatters.dart';
import '../utils/layout_constants.dart';
import '../utils/media_navigation_helper.dart';
import '../utils/platform_detector.dart';
import '../utils/video_player_navigation.dart';
import '../widgets/clickable_cursor.dart';
import '../widgets/cycling_media_backdrop.dart';
import '../widgets/fitting_title_text.dart';
import '../widgets/optimized_media_image.dart' show ClearLogoImage, blurArtwork;
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
/// Trailer-preview (dwell-triggered playback) is intentionally not wired up
/// here yet — hero-row rendering is the must-have per the spec, trailer is
/// the stretch goal layered on top in a follow-up pass.
class HeroHubSection extends StatefulWidget {
  const HeroHubSection({
    super.key,
    required this.hub,
    required this.onVerticalNavigation,
    this.onNavigateUp,
    this.onNavigateToSidebar,
  });

  final MediaHub hub;

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

  Timer? _autoScrollTimer;
  Timer? _indicatorTimer;
  bool _isAutoScrollPaused = false;

  List<MediaItem> get _items => widget.hub.items;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
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
    _autoScrollTimer?.cancel();
    _indicatorTimer?.cancel();
    _pageController.dispose();
    _focusNode.dispose();
    _indicatorProgress.dispose();
    _currentIndex.dispose();
    super.dispose();
  }

  void requestFocusAt(int index) => _focusNode.requestFocus();

  void requestFocusFromMemory() => _focusNode.requestFocus();

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (PlatformDetector.isTV() || _isAutoScrollPaused || !mounted) return;

    _startIndicatorProgress();
    _autoScrollTimer = Timer.periodic(_autoScrollDuration, (timer) {
      if (_items.isEmpty || !_pageController.hasClients || _isAutoScrollPaused) return;
      if (_currentIndex.value >= _items.length) _currentIndex.value = 0;
      final nextPage = (_currentIndex.value + 1) % _items.length;
      _pageController.animateToPage(nextPage, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_isAutoScrollPaused) _startIndicatorProgress();
      });
    });
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
                if (index >= 0 && index < _items.length) {
                  _currentIndex.value = index;
                  _autoScrollTimer?.cancel();
                  _startAutoScroll();
                }
              },
              itemBuilder: (context, index) => _buildHeroItem(context, _items[index], heroHeight),
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

  Widget _buildHeroItem(BuildContext context, MediaItem heroItem, double heroHeight) {
    final client = _clientFor(heroItem);
    final isEpisode = heroItem.isEpisode;
    final showName = heroItem.grandparentTitle ?? heroItem.displayTitle;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final heroAspectRatio = screenWidth / heroHeight;
    final heroArtPaths = heroItem.heroArtCandidates(containerAspectRatio: heroAspectRatio);
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
    final heroLabel = isEpisode ? '${heroItem.grandparentTitle}, ${heroItem.title}' : heroItem.title;

    return Semantics(
      label: heroLabel,
      button: true,
      hint: t.accessibility.tapToPlay,
      child: ClickableCursor(
        child: GestureDetector(
          onTap: () => navigateToMediaItem(context, heroItem, playDirectly: true),
          child: Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.none,
            children: [
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
              Positioned(
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
                          ClearLogoImage(
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
                          if (heroItem.year != null || heroItem.contentRating != null || heroItem.rating != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              [
                                contentTypeLabel,
                                if (heroItem.rating != null) '★ ${formatRating(heroItem.rating!)}',
                                if (heroItem.contentRating != null) formatContentRating(heroItem.contentRating!),
                                if (heroItem.year != null) heroItem.year.toString(),
                              ].join(' • '),
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
              ),
            ],
          ),
        ),
      ),
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
