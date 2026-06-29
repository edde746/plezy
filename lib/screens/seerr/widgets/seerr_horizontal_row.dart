import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../utils/platform_detector.dart';
import '../../../widgets/app_icon.dart';

/// Horizontal scroller for Seerr hub rows. Provides:
///   - mouse-wheel-as-horizontal-scroll on desktop (vertical wheel ticks
///     translate to horizontal scroll, matching how the rest of the app
///     handles desktop input)
///   - always-visible chevron buttons on desktop when there's room to
///     scroll left/right (Plezy's shared HorizontalScrollWithArrows hides
///     them until hover, which isn't discoverable enough for new users
///     landing on the Discover tab for the first time)
class SeerrHorizontalRow extends StatefulWidget {
  final Widget Function(BuildContext context, ScrollController controller) builder;
  final double scrollAmount;

  const SeerrHorizontalRow({super.key, required this.builder, this.scrollAmount = 0.85});

  @override
  State<SeerrHorizontalRow> createState() => _SeerrHorizontalRowState();
}

class _SeerrHorizontalRowState extends State<SeerrHorizontalRow> {
  final ScrollController _controller = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateBounds);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateBounds());
  }

  @override
  void dispose() {
    _controller.removeListener(_updateBounds);
    _controller.dispose();
    super.dispose();
  }

  void _updateBounds() {
    if (!mounted || _controller.positions.length != 1) return;
    final pos = _controller.position;
    final isScrollable = pos.maxScrollExtent > 0;
    final left = isScrollable && pos.pixels > 0;
    final right = isScrollable && pos.pixels < pos.maxScrollExtent;
    if (left != _canScrollLeft || right != _canScrollRight) {
      setState(() {
        _canScrollLeft = left;
        _canScrollRight = right;
      });
    }
  }

  void _animateBy(int direction) {
    if (_controller.positions.length != 1) return;
    final pos = _controller.position;
    final target = (pos.pixels + direction * pos.viewportDimension * widget.scrollAmount)
        .clamp(0.0, pos.maxScrollExtent);
    _controller.animateTo(target, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final child = NotificationListener<ScrollMetricsNotification>(
      onNotification: (_) {
        _updateBounds();
        return false;
      },
      child: Listener(
        onPointerSignal: (event) {
          if (event is PointerScrollEvent && _controller.hasClients) {
            final delta = event.scrollDelta.dy;
            if (delta != 0) {
              final target = (_controller.position.pixels + delta).clamp(
                0.0,
                _controller.position.maxScrollExtent,
              );
              _controller.jumpTo(target);
            }
          }
        },
        child: widget.builder(context, _controller),
      ),
    );
    if (!PlatformDetector.isDesktop(context)) return child;
    return Stack(
      children: [
        child,
        _ChevronButton(
          alignment: Alignment.centerLeft,
          icon: Symbols.chevron_left_rounded,
          visible: _canScrollLeft,
          onPressed: () => _animateBy(-1),
        ),
        _ChevronButton(
          alignment: Alignment.centerRight,
          icon: Symbols.chevron_right_rounded,
          visible: _canScrollRight,
          onPressed: () => _animateBy(1),
        ),
      ],
    );
  }
}

class _ChevronButton extends StatefulWidget {
  final Alignment alignment;
  final IconData icon;
  final bool visible;
  final VoidCallback onPressed;

  const _ChevronButton({
    required this.alignment,
    required this.icon,
    required this.visible,
    required this.onPressed,
  });

  @override
  State<_ChevronButton> createState() => _ChevronButtonState();
}

class _ChevronButtonState extends State<_ChevronButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: widget.alignment,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          // Always visible (faint) when scrolling is possible; brighter on
          // hover. Hidden entirely when there's nothing to scroll to.
          opacity: widget.visible ? (_hovering ? 1.0 : 0.65) : 0.0,
          child: IgnorePointer(
            ignoring: !widget.visible,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _hovering = true),
              onExit: (_) => setState(() => _hovering = false),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Material(
                  color: Colors.black.withValues(alpha: _hovering ? 0.85 : 0.55),
                  shape: const CircleBorder(),
                  elevation: _hovering ? 4 : 0,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: widget.onPressed,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: AppIcon(widget.icon, fill: 1, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
