import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../theme/theme_helper.dart';
import '../utils/platform_detector.dart';

/// A wrapper widget that adds hover-activated navigation arrows to horizontal scrolling content.
/// The arrows only appear on desktop/web platforms and hide at scroll boundaries.
///
/// This widget creates and manages its own ScrollController internally. Use the [builder]
/// constructor to access the ScrollController for the scrollable child widget.
class HorizontalScrollWithArrows extends StatefulWidget {
  final Widget Function(ScrollController) builder;
  final double scrollAmount;
  final ScrollController? controller;

  const HorizontalScrollWithArrows({
    super.key,
    required this.builder,
    this.scrollAmount = 0.8, // Scroll by 80% of viewport width by default
    this.controller,
  });

  @override
  State<HorizontalScrollWithArrows> createState() =>
      _HorizontalScrollWithArrowsState();
}

class _HorizontalScrollWithArrowsState
    extends State<HorizontalScrollWithArrows> {
  late final ScrollController _scrollController;
  late final bool _ownsController;
  bool _isHovering = false;
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_updateScrollState);
    // Initial state update after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollState());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollState);
    if (_ownsController) {
      _scrollController.dispose();
    }
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
      duration: tokens(context).slow,
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
      duration: tokens(context).slow,
      curve: Curves.easeInOut,
    );
  }

  Widget _buildArrowButton({
    required double position,
    required IconData icon,
    required VoidCallback onPressed,
    required bool canScroll,
  }) {
    return Positioned(
      left: position < 0 ? null : position,
      right: position < 0 ? -position : null,
      top: 0,
      bottom: 0,
      child: Center(
        child: AnimatedOpacity(
          opacity: (_isHovering && canScroll) ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: IgnorePointer(
            ignoring: !(_isHovering && canScroll),
            child: _NavigationArrow(icon: icon, onPressed: onPressed),
          ),
        ),
      ),
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
          _buildArrowButton(
            position: 8,
            icon: Symbols.chevron_left_rounded,
            onPressed: _scrollLeft,
            canScroll: _canScrollLeft,
          ),
          _buildArrowButton(
            position: -8,
            icon: Symbols.chevron_right_rounded,
            onPressed: _scrollRight,
            canScroll: _canScrollRight,
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
          child: AppIcon(widget.icon, fill: 1, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}
