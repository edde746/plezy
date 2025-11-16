import 'package:flutter/material.dart';
import '../utils/platform_detector.dart';

/// A wrapper widget that adds hover-activated navigation arrows to horizontal scrolling content.
/// The arrows only appear on desktop/web platforms and hide at scroll boundaries.
///
/// This widget creates and manages its own ScrollController internally. Use the [builder]
/// constructor to access the ScrollController for the scrollable child widget.
class HorizontalScrollWithArrows extends StatefulWidget {
  final Widget Function(ScrollController) builder;
  final double scrollAmount;

  const HorizontalScrollWithArrows({
    super.key,
    required this.builder,
    this.scrollAmount = 0.8, // Scroll by 80% of viewport width by default
  });

  @override
  State<HorizontalScrollWithArrows> createState() =>
      _HorizontalScrollWithArrowsState();
}

class _HorizontalScrollWithArrowsState
    extends State<HorizontalScrollWithArrows> {
  late final ScrollController _scrollController;
  bool _isHovering = false;
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_updateScrollState);
    // Initial state update after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollState());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollState);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollState() {
    if (!mounted) return;

    final position = _scrollController.position;
    setState(() {
      _canScrollLeft = position.pixels > 0;
      _canScrollRight = position.pixels < position.maxScrollExtent;
    });
  }

  void _scrollLeft() {
    final position = _scrollController.position;
    final targetScroll =
        (position.pixels - (position.viewportDimension * widget.scrollAmount))
            .clamp(0.0, position.maxScrollExtent);

    _scrollController.animateTo(
      targetScroll,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    final position = _scrollController.position;
    final targetScroll =
        (position.pixels + (position.viewportDimension * widget.scrollAmount))
            .clamp(0.0, position.maxScrollExtent);

    _scrollController.animateTo(
      targetScroll,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.builder(_scrollController);

    if (!PlatformDetector.isDesktop(context)) {
      // On mobile, just return the child without arrows
      return child;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Stack(
        children: [
          child,
          // Left arrow
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: AnimatedOpacity(
                opacity: (_isHovering && _canScrollLeft) ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: IgnorePointer(
                  ignoring: !(_isHovering && _canScrollLeft),
                  child: _NavigationArrow(
                    icon: Icons.chevron_left,
                    onPressed: _scrollLeft,
                  ),
                ),
              ),
            ),
          ),
          // Right arrow
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: AnimatedOpacity(
                opacity: (_isHovering && _canScrollRight) ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: IgnorePointer(
                  ignoring: !(_isHovering && _canScrollRight),
                  child: _NavigationArrow(
                    icon: Icons.chevron_right,
                    onPressed: _scrollRight,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavigationArrow extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _NavigationArrow({required this.icon, required this.onPressed});

  @override
  State<_NavigationArrow> createState() => _NavigationArrowState();
}

class _NavigationArrowState extends State<_NavigationArrow> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: _isPressed ? 0.9 : 0.7),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Icon(widget.icon, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}
