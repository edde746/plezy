import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'focus_theme.dart';

/// Renders the focus glow for a focused card in the root [Overlay] so it paints
/// ABOVE sibling cards on all four sides.
///
/// The glow is an outward blur ([FocusTheme.focusGlowShadows]). When drawn
/// in-tree behind a packed rail/grid it is occluded by later-painted neighbours
/// on the trailing edges and only escapes on the leading (left) edge — producing
/// a one-sided halo (issue #1231). Lifting it into an [OverlayPortal] that
/// follows the card via [LayerLink] makes it render above every sibling, so the
/// glow is symmetric on all sides. The crisp focus border stays in-card; only
/// the glow moves to the overlay.
///
/// Only mounts the overlay/leader while the card is focused (or fading out), so
/// there is at most one [LeaderLayer] on screen regardless of how many cards a
/// grid builds.
class FocusGlowOverlay extends StatefulWidget {
  const FocusGlowOverlay({
    super.key,
    required this.isFocused,
    required this.borderRadius,
    required this.color,
    required this.child,
    this.glowSize,
  });

  /// Whether the wrapped card currently shows focus. Drives the glow.
  final bool isFocused;

  /// Border radius of the card, used for the glow's rounded rect.
  final double borderRadius;

  /// Glow colour, resolved from the card's theme at the call site (the overlay
  /// builds in the root Overlay's context, which may not carry a nested theme).
  final Color color;

  /// Explicit card size. When null, falls back to [LayerLink.leaderSize] (one
  /// frame late on first show, hidden under the opacity-0 fade-in).
  final Size? glowSize;

  final Widget child;

  @override
  State<FocusGlowOverlay> createState() => _FocusGlowOverlayState();
}

class _FocusGlowOverlayState extends State<FocusGlowOverlay> {
  final OverlayPortalController _controller = OverlayPortalController();
  final LayerLink _link = LayerLink();

  /// Drives the [AnimatedOpacity] target. Set false on focus loss so the glow
  /// fades out before the portal is hidden in [_handleFadeEnd].
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    if (widget.isFocused) {
      _visible = true;
      _controller.show();
    }
  }

  @override
  void didUpdateWidget(FocusGlowOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFocused == oldWidget.isFocused) return;
    if (widget.isFocused) {
      _controller.show();
      // Start hidden, then fade in next frame.
      _visible = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.isFocused) setState(() => _visible = true);
      });
    } else {
      // Fade out; _handleFadeEnd hides the portal once opacity reaches 0.
      setState(() => _visible = false);
    }
  }

  void _handleFadeEnd() {
    if (!_visible && mounted && _controller.isShowing) {
      _controller.hide();
      setState(() {}); // drop the OverlayPortal/leader from the tree
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gate the LeaderLayer to the focused card only: when not focused and not
    // mid-fade, return the bare child (no OverlayPortal, no leader).
    if (!widget.isFocused && !_controller.isShowing) {
      return widget.child;
    }

    final duration = FocusTheme.getAnimationDuration(context);

    return OverlayPortal(
      controller: _controller,
      overlayChildBuilder: (overlayContext) {
        final size = widget.glowSize ?? _link.leaderSize;
        final extent = FocusTheme.focusGlowExtent;

        return CompositedTransformFollower(
          link: _link,
          targetAnchor: Alignment.topLeft,
          followerAnchor: Alignment.topLeft,
          offset: Offset(-extent, -extent),
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _visible ? 1.0 : 0.0,
              duration: duration,
              curve: Curves.easeOutCubic,
              onEnd: _handleFadeEnd,
              child: size == null
                  ? const SizedBox.shrink()
                  : CustomPaint(
                      size: Size(size.width + extent * 2, size.height + extent * 2),
                      painter: _FocusGlowPainter(
                        rect: Offset(extent, extent) & size,
                        borderRadius: widget.borderRadius,
                        shadows: FocusTheme.focusGlowShadows(widget.color),
                      ),
                    ),
            ),
          ),
        );
      },
      child: CompositedTransformTarget(link: _link, child: widget.child),
    );
  }
}

/// Paints [shadows] around [rect] with the rect interior clipped out, so only
/// the outer glow shows — matching the original look where the opaque card hid
/// the inner part of the shadow.
class _FocusGlowPainter extends CustomPainter {
  const _FocusGlowPainter({required this.rect, required this.borderRadius, required this.shadows});

  final Rect rect;
  final double borderRadius;
  final List<BoxShadow> shadows;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    final clip = Path.combine(PathOperation.difference, Path()..addRect(Offset.zero & size), Path()..addRRect(rrect));
    canvas.save();
    canvas.clipPath(clip);
    for (final shadow in shadows) {
      canvas.drawRRect(rrect.shift(shadow.offset).inflate(shadow.spreadRadius), shadow.toPaint());
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FocusGlowPainter oldDelegate) {
    return oldDelegate.rect != rect ||
        oldDelegate.borderRadius != borderRadius ||
        !listEquals(oldDelegate.shadows, shadows);
  }
}
