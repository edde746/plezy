import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../media/ids.dart';
import '../../media/media_item.dart';
import '../../media/media_kind.dart';
import '../../media/media_role.dart';
import '../../media/media_server_client.dart';
import '../../mpv/video.dart';
import '../../services/hover_trailer_service.dart';
import '../../services/settings_service.dart' show EpisodePosterMode;
import '../../utils/content_utils.dart';
import '../../utils/media_image_helper.dart';
import '../../utils/media_navigation_helper.dart';
import '../../utils/provider_extensions.dart';
import '../media_card.dart';
import '../optimized_media_image.dart';
import 'hover_preview_player_controller.dart';

/// Wraps [MediaCard] with a Netflix-style hover-expand preview — does not
/// modify [MediaCard] itself, which stays exactly as every other screen
/// uses it. Only present where this wrapper is explicitly used (home rows,
/// Discover), never injected into the shared card widget globally.
///
/// The expanded state renders through [Overlay], not a paint-time
/// transform (`Transform.scale`/`AnimatedScale`), for a real reason: the
/// native video surface on Windows is positioned via
/// `VideoRectSupport.setVideoRect`, computed from the hosting widget's
/// *actual layout size*. A paint transform changes what's drawn but never
/// the underlying `RenderBox` size, so the video would render at the
/// pre-expand size while everything else visually scaled up around it —
/// exactly the small-video/blurry/behind-neighbors bug this replaced.
///
/// [playerController] is shared across every card in the surrounding
/// row/grid, not created per-card — pass the same instance to each
/// [HoverPreviewCard] so hovering a new card reuses one native player.
class HoverPreviewCard extends StatefulWidget {
  const HoverPreviewCard({
    super.key,
    required this.item,
    required this.playerController,
    this.width,
    this.height,
    this.onTap,
    this.onLongPress,
    this.mixedHubContext = false,
    this.episodePosterModeOverride,
    this.mediaCardKey,
    this.isContinueWatching = false,
  });

  final MediaItem item;
  final HoverPreviewPlayerController playerController;
  final double? width;
  final double? height;

  /// Continue Watching cards resolve to the item's own resume position
  /// instead of a trailer/scene-clip, and auto-collapse back to the cover
  /// after a short preview window rather than playing indefinitely while
  /// hovered — see [_HoverPreviewOverlayContentState._resumePreviewTimer].
  final bool isContinueWatching;

  /// Pass-through to the wrapped [MediaCard] — this wrapper only adds
  /// hover-expand behavior, it doesn't own tap semantics itself (the base,
  /// non-expanded card still needs the same keyboard-mode tap/long-press
  /// override its callers already rely on elsewhere).
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool mixedHubContext;
  final EpisodePosterMode? episodePosterModeOverride;

  /// The `key` that identifies *[MediaCard]'s own state* (e.g. for
  /// `currentState?.showContextMenu()` from a caller) — kept distinct from
  /// this widget's own [Key] (`super.key`, for Flutter's element diffing),
  /// which the wrapped card must not also receive or two different call
  /// sites would collide on the same identity.
  final Key? mediaCardKey;

  @override
  State<HoverPreviewCard> createState() => _HoverPreviewCardState();
}

class _HoverPreviewCardState extends State<HoverPreviewCard> {
  // Long enough that sweeping the mouse across a row to reach a title
  // doesn't trigger a preview on every card it passes over on the way.
  static const _hoverDebounce = Duration(milliseconds: 1200);

  final _cardKey = GlobalKey();
  Timer? _debounceTimer;
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    // Deliberately not calling _removeOverlay() here — its setState() call
    // is illegal during dispose(). `mounted` is still true for the entire
    // duration of dispose() (the framework only flips it after this method
    // returns), so the `if (mounted)` guard in _removeOverlay() does not
    // actually protect against this; it throws a defunct-element assertion
    // that cascades into duplicate-GlobalKey and lifecycle errors elsewhere
    // in the tree. This inlines the same cleanup, minus the state update a
    // disposing widget will never read again anyway.
    _debounceTimer?.cancel();
    widget.playerController.unregisterActive(_removeOverlay);
    unawaited(widget.playerController.stop());
    _overlayEntry?.remove();
    super.dispose();
  }

  void _onEnter(PointerEvent _) {
    if (_overlayEntry != null) return; // already expanded — overlay owns exit detection now
    // A genuinely different card just got engaged — collapse whatever else
    // is currently expanded immediately rather than letting it linger out
    // its own exit grace period. Without this, hovering across a row could
    // leave several overlays alive at once, all fighting over the single
    // shared player.
    widget.playerController.collapseActive();
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_hoverDebounce, _showOverlay);
  }

  void _onExit(PointerEvent _) {
    // Once the overlay exists it visually covers this widget's area, so this
    // fires as the overlay takes over hit-testing — not a real "left the
    // card" signal. Only relevant before expansion, to cancel a pending show.
    if (_overlayEntry != null) return;
    _debounceTimer?.cancel();
  }

  Future<void> _showOverlay() async {
    if (!mounted || _overlayEntry != null) return;

    // Deliberately NOT scrolling a barely-visible edge card into view here.
    // An earlier version called Scrollable.ensureVisible() first, which
    // shifted the row's content out from under a stationary cursor — that
    // relocated whatever card the cursor was resting on, which fired ITS
    // hover, which could itself trigger another scroll, cascading into the
    // preview appearing to jump between titles on its own with no mouse
    // movement. Several rounds of trying to guard that scroll (suppression
    // windows, waiting an extra frame for layout to catch up) never fully
    // closed the race. The edge-card cutoff case this served is a much
    // smaller loss than that cascade, and _computeTargetRect below already
    // clamps the expanded rect to stay fully on-screen regardless.
    final renderBox = _cardKey.currentContext?.findRenderObject();
    if (renderBox is! RenderBox || !renderBox.hasSize) return;

    // Positioned coordinates inside an Overlay are relative to that
    // Overlay's OWN origin, not the screen's global origin — passing
    // `ancestor: overlayBox` here converts to that local space. Without it,
    // a plain `localToGlobal(Offset.zero)` only happens to be correct when
    // the Overlay's own origin coincides with the screen's, which breaks
    // the moment there's any offsetting ancestor (a side nav rail, a nested
    // Navigator's own Overlay, etc.) between them — exactly the kind of
    // mismatch that snaps the animated rect toward (0,0), clamped to the
    // corner, regardless of which card was actually hovered.
    final overlayBox = Overlay.of(context).context.findRenderObject();
    final origin = overlayBox is RenderBox
        ? renderBox.localToGlobal(Offset.zero, ancestor: overlayBox)
        : renderBox.localToGlobal(Offset.zero);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) => _HoverPreviewOverlayContent(
        item: widget.item,
        originRect: origin & renderBox.size,
        playerController: widget.playerController,
        isContinueWatching: widget.isContinueWatching,
        onCollapse: () {
          if (_overlayEntry == entry) _removeOverlay();
        },
      ),
    );
    setState(() => _overlayEntry = entry);
    Overlay.of(context).insert(entry);
    widget.playerController.registerActive(_removeOverlay);
  }

  void _removeOverlay() {
    widget.playerController.unregisterActive(_removeOverlay);
    unawaited(widget.playerController.stop());
    _overlayEntry?.remove();
    if (mounted) {
      setState(() => _overlayEntry = null);
    } else {
      _overlayEntry = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      // Keep the original card's layout space reserved (and itself visible
      // as the base layer) even while the overlay floats above it — the
      // grid shouldn't reflow just because a neighbor is being previewed.
      child: KeyedSubtree(
        key: _cardKey,
        child: MediaCard(
          key: widget.mediaCardKey,
          item: widget.item,
          width: widget.width,
          height: widget.height,
          onTap: widget.onTap == null ? null : () => _stopThenInvoke(widget.onTap!),
          onLongPress: widget.onLongPress == null ? null : () => _stopThenInvoke(widget.onLongPress!),
          mixedHubContext: widget.mixedHubContext,
          episodePosterModeOverride: widget.episodePosterModeOverride,
          forceGridMode: true,
        ),
      ),
    );
  }

  /// Stops the shared native player and waits for it before running a tap
  /// action that may itself start real playback (Continue Watching's tap-
  /// to-resume, in particular). Windows backs the whole app with a single
  /// process-wide native video core — real playback initializing before
  /// this controller's own teardown finishes races for that same channel
  /// and can fail outright ("Failed to initialize player", observed as a
  /// hard crash from the video player screen). `stop()` resolves almost
  /// immediately when nothing is actually playing, so this only adds real
  /// delay in exactly the case it exists to prevent.
  Future<void> _stopThenInvoke(VoidCallback callback) async {
    await widget.playerController.stop();
    callback();
  }
}

/// The actual expanded preview, rendered inside an [OverlayEntry] so it has
/// a real, independently laid-out `RenderBox` — see [HoverPreviewCard]'s
/// doc comment for why that matters for video rendering specifically.
class _HoverPreviewOverlayContent extends StatefulWidget {
  const _HoverPreviewOverlayContent({
    required this.item,
    required this.originRect,
    required this.playerController,
    required this.onCollapse,
    this.isContinueWatching = false,
  });

  final MediaItem item;
  final Rect originRect;
  final HoverPreviewPlayerController playerController;
  final VoidCallback onCollapse;
  final bool isContinueWatching;

  @override
  State<_HoverPreviewOverlayContent> createState() => _HoverPreviewOverlayContentState();
}

class _HoverPreviewOverlayContentState extends State<_HoverPreviewOverlayContent>
    with SingleTickerProviderStateMixin {
  // Target shape is a landscape "big thumbnail", not a scaled-up portrait
  // poster: about two poster-widths across, only slightly taller than one
  // poster — this is what actually makes it read as a preview thumbnail
  // rather than just a zoomed poster. Anchored so growth is downward/sideways
  // from the original top edge, not a centered zoom that eats into the row
  // above just as much as the row below.
  //
  // Continue Watching's own cards are already landscape thumbnails, not
  // portrait posters — applying the same 2.0x multiplier to an
  // already-wide originRect compounded into a card noticeably wider than
  // every other row's, so it gets a smaller multiplier here instead.
  double get _widthMultiplier => widget.isContinueWatching ? 1.4 : 2.0;
  double get _heightMultiplier => widget.isContinueWatching ? 1.3 : 1.15;

  final _resolver = HoverPreviewSourceResolver();
  late final AnimationController _controller;
  Animation<Rect?>? _rectAnimation;

  HoverPreviewSource? _previewSource;
  MediaItem? _detailItem;
  bool _requestSuperseded = false;

  // Short, not zero: a raw MouseRegion.onExit fires on any sub-pixel gap
  // between nested widgets (e.g. moving toward the mute button in the
  // corner), so collapsing on the very same event tears the overlay down
  // before the pointer can ever reach it. This just bridges that gap — the
  // preview should stop as soon as the cursor genuinely leaves it, not
  // linger for seconds after.
  static const _collapseGracePeriod = Duration(milliseconds: 120);
  Timer? _collapseTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    unawaited(_loadPreview());
  }

  void _scheduleCollapse() {
    _collapseTimer?.cancel();
    _collapseTimer = Timer(_collapseGracePeriod, widget.onCollapse);
  }

  void _cancelScheduledCollapse() {
    _collapseTimer?.cancel();
    _collapseTimer = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery (needed to clamp the target rect on-screen) isn't
    // guaranteed resolved yet in initState() for a widget just inserted
    // into an Overlay — reading it there risks a bad/zero size feeding
    // invalid bounds into the clamp math below, which throws. This is the
    // correct lifecycle point for a first-time InheritedWidget-dependent
    // computation.
    if (_rectAnimation == null) {
      _rectAnimation = RectTween(
        begin: widget.originRect,
        end: _computeTargetRect(context),
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _requestSuperseded = true;
    _collapseTimer?.cancel();
    _resumePreviewTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Rect _computeTargetRect(BuildContext context) {
    // Clamp against the Overlay's own size, not MediaQuery's — [originRect]
    // is already expressed relative to the Overlay's local origin (see
    // HoverPreviewCard._showOverlay), and if the Overlay doesn't fill the
    // full window (e.g. sits beside a persistent nav rail), MediaQuery's
    // size would overstate the actually-available space and let the clamp
    // allow an out-of-bounds rect through.
    final overlayBox = Overlay.of(context).context.findRenderObject();
    final screen = overlayBox is RenderBox ? overlayBox.size : MediaQuery.sizeOf(context);
    final origin = widget.originRect;

    var targetWidth = origin.width * _widthMultiplier;
    var targetHeight = origin.height * _heightMultiplier;
    var left = origin.left - (targetWidth - origin.width) / 2;
    final top = origin.top;

    // Clamp fully on-screen. Every clamp lower-bounds its own upper bound
    // first so a tiny/zero screen size can never produce lower > upper,
    // which `num.clamp` throws on — that failure mode is exactly what
    // silently blanks the overlay while still absorbing input.
    const margin = 8.0;
    final maxWidth = (screen.width - margin * 2).clamp(0.0, double.infinity);
    targetWidth = targetWidth.clamp(0.0, maxWidth);
    final maxLeft = (screen.width - targetWidth - margin).clamp(margin, double.infinity);
    left = left.clamp(margin, maxLeft);
    final maxHeight = (screen.height - top - margin).clamp(0.0, double.infinity);
    targetHeight = targetHeight.clamp(0.0, maxHeight);

    return Rect.fromLTWH(left, top, targetWidth, targetHeight);
  }

  Future<void> _loadPreview() async {
    final client = context.tryGetMediaClientWithFallback(serverIdOrNull(widget.item.serverId));
    if (client == null) return;

    final results = await Future.wait([
      _resolver.resolve(client, widget.item, preferResumePosition: widget.isContinueWatching),
      client.fetchItem(widget.item.id),
    ]);
    if (_requestSuperseded || !mounted) return;

    final source = results[0] as HoverPreviewSource;
    final detail = results[1] as MediaItem?;
    setState(() {
      _previewSource = source;
      _detailItem = detail ?? widget.item;
    });

    switch (source) {
      case TrailerPreviewSource(:final streamUrl):
        await widget.playerController.play(streamUrl);
        _scheduleResumePreviewCollapse();
      case SceneClipPreviewSource(:final streamUrl, :final startOffset):
        await widget.playerController.play(streamUrl, startAt: startOffset);
        _scheduleResumePreviewCollapse();
      case NoPreviewSource():
        break;
    }
  }

  /// Continue Watching cards preview for a fixed window, not indefinitely —
  /// unlike every other row, this one is showing the user's actual resume
  /// point, and letting it run on while still hovered would just replay
  /// footage they've already watched. No-op for regular hover-preview cards.
  static const _resumePreviewDuration = Duration(seconds: 12);
  Timer? _resumePreviewTimer;

  void _scheduleResumePreviewCollapse() {
    if (!widget.isContinueWatching) return;
    _resumePreviewTimer?.cancel();
    _resumePreviewTimer = Timer(_resumePreviewDuration, () {
      if (mounted) widget.onCollapse();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Not yet resolved on the very first build (didChangeDependencies runs
    // after initState but the animation is set up there) — render at the
    // pre-expand rect for that one frame rather than crashing on a null
    // Listenable.
    final animation = _rectAnimation;
    if (animation == null) {
      return Positioned.fromRect(rect: widget.originRect, child: const SizedBox.shrink());
    }
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final rect = animation.value ?? widget.originRect;
        // Interactive area stays at the ORIGINAL card's width, centered
        // within the wider animated rect. The visual content still paints
        // across the full expanded width (see below) — that's what gives
        // the "lifts in front, covers a sliver of the neighboring posters"
        // effect — but it's wrapped in IgnorePointer, so that overflow
        // slice no longer intercepts pointer events. Without this split,
        // the expanded card's overflow was physically sitting on top of
        // neighboring cards, stealing their hover/click events: moving
        // toward a neighbor got attributed to this card instead, made
        // clicking a neighbor impossible while this one was expanded, and
        // fed bad state into the exclusivity/collapse logic (stuck overlays,
        // preview jumping to the wrong spot).
        final coreLeft = (rect.width - widget.originRect.width) / 2;
        return Positioned.fromRect(
          rect: rect,
          // Rebuilds on mute-state AND playback-failure changes — the mute
          // button's visibility and the video-vs-backdrop background choice
          // both depend on live controller state, not just the one-time
          // preview-source resolution.
          child: ListenableBuilder(
            listenable: widget.playerController,
            builder: (context, _) {
              // TEMP DIAGNOSTIC: the mute button visually vanishes ~1s into
              // playback while the rest of the preview stays put. Logging
              // _hasVideo on every rebuild this widget sees tells us whether
              // the button is being removed from the tree (a logic bug) or
              // staying in the tree but getting visually covered (a native
              // video-window z-order issue, since the video renders via a
              // separate native HWND on Windows, not a normal texture).
              debugPrint(
                '[hover-preview] mute button rebuild: hasVideo=$_hasVideo previewSource=${_previewSource.runtimeType} playbackFailed=${widget.playerController.playbackFailed}',
              );
              return Stack(
            fit: StackFit.expand,
            children: [
              // Decorative visual layer — full expanded size. Tracks hover
              // for collapse purposes (opaque: true, so it also claims the
              // overlap sliver away from whatever neighboring card sits
              // underneath it — otherwise crossing that sliver to reach the
              // mute button fell through to the neighbor's own hover,
              // collapsing this card mid-move) but carries no GestureDetector
              // of its own, so a tap here is a no-op rather than accidentally
              // navigating to either card.
              MouseRegion(
                opaque: true,
                onEnter: (_) => _cancelScheduledCollapse(),
                onExit: (_) => _scheduleCollapse(),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 24, offset: const Offset(0, 12))],
                  ),
                  child: ClipRRect(borderRadius: BorderRadius.circular(8), child: _buildContent(context)),
                ),
              ),
              // Interactive core: tap-to-navigate and "stay expanded" hover
              // tracking, confined to the original card's footprint.
              Positioned(
                left: coreLeft,
                top: 0,
                width: widget.originRect.width,
                height: rect.height,
                child: MouseRegion(
                  onEnter: (_) => _cancelScheduledCollapse(),
                  onExit: (_) => _scheduleCollapse(),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      // Navigate first, while this widget's context is still
                      // definitely mounted — collapsing tears the overlay entry
                      // down, and doing that before the Navigator call risks
                      // racing this widget's own disposal against still-using its
                      // context.
                      unawaited(navigateToMediaItemDetails(context, _detailItem ?? widget.item));
                      widget.onCollapse();
                    },
                  ),
                ),
              ),
            ],
            );
            },
          ),
        );
      },
    );
  }

  bool get _hasVideo =>
      (_previewSource is TrailerPreviewSource || _previewSource is SceneClipPreviewSource) &&
      !widget.playerController.playbackFailed &&
      !widget.playerController.playbackCompleted;

  // Real video content is ~16:9; the card's own overall shape (2.0x wide,
  // only 1.15x tall) isn't that ratio, so a full-bleed video would letterbox
  // with dead black bars top/bottom. Instead of fighting that, the video
  // gets its own properly-shaped 16:9 zone and the remaining space becomes a
  // dedicated metadata panel — turns wasted letterbox space into the info
  // panel on purpose, rather than overlaying text on top of the video.
  static const _videoAspectRatio = 16 / 9;

  Widget _buildContent(BuildContext context) {
    final detail = _detailItem ?? widget.item;
    final client = context.tryGetMediaClientWithFallback(serverIdOrNull(widget.item.serverId));

    return ColoredBox(
      color: const Color(0xFF141414),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // A true 16:9 zone sized purely from width, like AspectRatio did,
          // can come out taller than the whole card for a landscape-shaped
          // original (e.g. Continue Watching's wide thumbnails give this
          // widget a much wider originRect than a portrait poster would) —
          // AspectRatio doesn't know or care that a metadata panel sibling
          // still needs room below it, which is exactly what overflowed for
          // those cards. Deriving from height first, capped by the natural
          // width-based value, guarantees the metadata panel always gets its
          // share regardless of the original card's own proportions.
          final naturalVideoHeight = constraints.maxWidth / _videoAspectRatio;
          final videoHeight = naturalVideoHeight.clamp(0.0, constraints.maxHeight * 0.7);
          return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: videoHeight, child: _buildBackground(client)),
          // Mute button lives here, over the metadata panel's own plain dark
          // background — NOT over the video zone above. On Windows, video
          // renders via a native child HWND (see mpv_player.cpp), which
          // visually covers ordinary Flutter content painted over its own
          // screen rect regardless of widget tree position — confirmed by
          // moving the button through Video's own `controls` slot (thought
          // to carry a native "stay above video" guarantee) and it still
          // vanished. Placing it outside the video's rect entirely sidesteps
          // the problem rather than fighting native z-order further.
          // Continue Watching skips the mute button — it's a short, silent
          // resume-position preview capped at a fixed duration (see
          // _scheduleResumePreviewCollapse), not something worth an audio
          // control for.
          if (_hasVideo && !widget.isContinueWatching)
            Flexible(
              child: Stack(
                children: [
                  _buildMetadataPanel(detail),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: MouseRegion(
                      onEnter: (_) => _cancelScheduledCollapse(),
                      onExit: (_) => _scheduleCollapse(),
                      child: _buildMuteButton(),
                    ),
                  ),
                ],
              ),
            )
          else
            Flexible(child: _buildMetadataPanel(detail)),
        ],
          );
        },
      ),
    );
  }

  Widget _buildMuteButton() {
    return ListenableBuilder(
      listenable: widget.playerController,
      builder: (context, _) {
        final muted = widget.playerController.isMuted;
        return Material(
          color: Colors.black.withValues(alpha: 0.55),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => unawaited(widget.playerController.toggleMuted()),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackground(MediaServerClient? client) {
    // `_hasVideo` already excludes a source whose playback actually failed
    // (see HoverPreviewPlayerController.playbackFailed) — falls through to
    // the same static-backdrop rendering used when there was never a
    // preview source to begin with, instead of a dead blank video surface.
    if (_hasVideo) {
      final player = widget.playerController.player;
      // No controls passed here — the mute button lives in the metadata
      // panel below instead (see _buildContent), outside the video's own
      // rect entirely. Content placed over the video's rect on Windows gets
      // visually covered by the native video window regardless of where in
      // the widget tree it comes from, Video's own `controls` slot included
      // (confirmed empirically — moving the button there didn't help).
      if (player != null) return Video(player: player);
    }

    final backdropPath = widget.item.backdropPaths?.firstOrNull;
    return OptimizedMediaImage(
      client: client,
      imagePath: backdropPath,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      imageType: ImageType.thumb,
    );
  }

  Widget _buildMetadataPanel(MediaItem detail) {
    final roles = detail.roles?.take(5).toList() ?? const [];
    // Wrapped in a scroll view as an overflow safety net — panel height
    // varies with card width (16:9 video zone eats a different share of the
    // total height at different card sizes), so this guards against a
    // RenderFlex overflow if a title/summary combination doesn't quite fit
    // rather than clipping or crashing.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            detail.displayTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          _buildFactsRow(detail),
          if (detail.summary case final summary? when summary.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.2),
            ),
          ],
          if (roles.isNotEmpty) ...[const SizedBox(height: 6), _buildCastBubbles(roles, context)],
        ],
      ),
    );
  }

  /// Coarse type label. [MediaKind] only distinguishes movie/show at the
  /// model level — a genre tag (when present) narrows this further, which
  /// naturally surfaces things like "Stand-up" for libraries organized that
  /// way, without needing a dedicated content-type taxonomy.
  String _typeLabel(MediaItem detail) {
    final base = switch (detail.kind) {
      MediaKind.movie => 'Movie',
      MediaKind.show => 'Series',
      _ => null,
    };
    final genre = detail.genres?.firstOrNull;
    if (base == null) return genre ?? '';
    return genre != null ? '$base • $genre' : base;
  }

  /// Prefers an explicitly IMDb-sourced rating over the generic `.rating`
  /// field, which reflects whatever the server's configured primary rating
  /// agent happens to be (not necessarily IMDb) — mislabeling a Rotten
  /// Tomatoes or TMDb score as "IMDb" would just be wrong.
  double? _imdbRating(MediaItem detail) {
    final imdbSource = detail.ratings?.firstWhereOrNull((r) => r.source == 'imdb');
    return imdbSource?.value;
  }

  Widget _buildFactsRow(MediaItem detail) {
    final episodeCount = detail.childCount ?? detail.leafCount;
    final formattedContentRating = formatContentRating(detail.contentRating);
    final imdbRating = _imdbRating(detail);
    final parts = <String>[
      if (_typeLabel(detail) case final type when type.isNotEmpty) type,
      if (detail.year case final year?) '$year',
      if (detail.kind == MediaKind.show && episodeCount != null)
        '$episodeCount episodes'
      else if (detail.durationMs case final ms?)
        '${(ms / 60000).round()}m',
      if (formattedContentRating.isNotEmpty) formattedContentRating,
      if (imdbRating != null)
        'IMDb ${imdbRating.toStringAsFixed(1)}'
      else if (detail.rating case final rating?)
        '${rating.toStringAsFixed(1)}★',
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(parts.join('  •  '), style: const TextStyle(color: Colors.white70, fontSize: 11));
  }

  static const _castBubbleDiameter = 22.0;

  Widget _buildCastBubbles(List<MediaRole> roles, BuildContext context) {
    final client = context.tryGetMediaClientWithFallback(serverIdOrNull(widget.item.serverId));
    return SizedBox(
      height: _castBubbleDiameter,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final role in roles)
            Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Tooltip(
                message: role.tag,
                child: ClipOval(
                  child: SizedBox(
                    width: _castBubbleDiameter,
                    height: _castBubbleDiameter,
                    child: role.thumbPath == null
                        ? _castInitial(role)
                        : OptimizedMediaImage(
                            client: client,
                            imagePath: role.thumbPath,
                            width: _castBubbleDiameter,
                            height: _castBubbleDiameter,
                            fit: BoxFit.cover,
                            imageType: ImageType.square,
                            errorWidget: (_, _, _) => _castInitial(role),
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _castInitial(MediaRole role) {
    return ColoredBox(
      color: Colors.white24,
      child: Center(
        child: Text(
          role.tag.isNotEmpty ? role.tag[0] : '?',
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      ),
    );
  }
}
