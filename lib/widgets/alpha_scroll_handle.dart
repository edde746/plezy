import 'dart:async';

import 'package:flutter/material.dart';

import '../models/plex_first_character.dart';
import 'alpha_jump_helper.dart';

/// Phone-optimized draggable scroll handle that appears on scroll and shows
/// a letter bubble when dragged. Designed to match the Plex app's scroll
/// indicator behavior.
///
/// Desktop/tablet/TV should use [AlphaJumpBar] instead.
class AlphaScrollHandle extends StatefulWidget {
  final List<PlexFirstCharacter> firstCharacters;
  final void Function(int targetIndex) onJump;
  final int currentFirstVisibleIndex;

  /// Whether the parent scroll view is currently scrolling.
  final bool isScrolling;

  const AlphaScrollHandle({
    super.key,
    required this.firstCharacters,
    required this.onJump,
    required this.currentFirstVisibleIndex,
    required this.isScrolling,
  });

  @override
  State<AlphaScrollHandle> createState() => _AlphaScrollHandleState();
}

class _AlphaScrollHandleState extends State<AlphaScrollHandle> with SingleTickerProviderStateMixin {
  late AlphaJumpHelper _helper;
  late AnimationController _opacityController;
  Timer? _hideTimer;
  bool _isDragging = false;
  String? _dragLetter;

  /// Accumulated fraction (0.0–1.0) during drag, driven by delta movement.
  double? _dragFraction;

  /// Cached track height from the last layout pass, used in drag callbacks.
  double _trackHeight = 0;

  static const _showDuration = Duration(milliseconds: 200);
  static const _hideDuration = Duration(milliseconds: 200);
  static const _autoHideDelay = Duration(seconds: 2);

  // Handle dimensions
  static const double _handleWidth = 6.0;
  static const double _handleHeight = 44.0;
  static const double _touchTargetWidth = 44.0;
  static const double _touchTargetVerticalPadding = 20.0;
  static const double _handleRadius = 3.0;

  // Bubble dimensions
  static const double _bubbleSize = 56.0;
  static const double _bubbleFontSize = 24.0;
  static const double _bubbleMarginRight = 8.0;

  @override
  void initState() {
    super.initState();
    _helper = AlphaJumpHelper(widget.firstCharacters);
    _opacityController = AnimationController(vsync: this, duration: _showDuration, reverseDuration: _hideDuration);
  }

  @override
  void didUpdateWidget(AlphaScrollHandle oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.firstCharacters != widget.firstCharacters) {
      _helper = AlphaJumpHelper(widget.firstCharacters);
    }

    if (widget.isScrolling && !oldWidget.isScrolling) {
      _show();
    } else if (!widget.isScrolling && oldWidget.isScrolling) {
      _scheduleHide();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _opacityController.dispose();
    super.dispose();
  }

  void _show() {
    _hideTimer?.cancel();
    _opacityController.forward();
  }

  void _scheduleHide() {
    if (_isDragging) return;
    _hideTimer?.cancel();
    _hideTimer = Timer(_autoHideDelay, () {
      if (mounted && !_isDragging) {
        _opacityController.reverse();
      }
    });
  }

  void _onDragStart(DragStartDetails details) {
    final currentLetter = _helper.currentLetter(widget.currentFirstVisibleIndex);
    setState(() {
      _isDragging = true;
      _dragFraction = _helper.fractionForLetter(currentLetter);
      _dragLetter = currentLetter;
    });
    _hideTimer?.cancel();
    _show();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final usableHeight = _trackHeight - _handleHeight;
    if (usableHeight <= 0 || _dragFraction == null) return;

    final newFraction = (_dragFraction! + details.delta.dy / usableHeight).clamp(0.0, 1.0);
    _dragFraction = newFraction;

    final letter = _helper.letterAtFraction(newFraction);

    setState(() => _dragLetter = letter);
    widget.onJump(_helper.indexForLetter(letter) ?? 0);
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _dragLetter = null;
      _dragFraction = null;
    });
    _scheduleHide();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityController,
      builder: (context, child) {
        final opacity = _opacityController.value;
        // Prevent stealing taps when fully hidden
        if (opacity == 0.0) return const SizedBox.shrink();

        return Opacity(opacity: opacity, child: child);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackHeight = constraints.maxHeight;
          _trackHeight = trackHeight;

          final currentLetter = _helper.currentLetter(widget.currentFirstVisibleIndex);
          final fraction = _isDragging && _dragFraction != null
              ? _dragFraction!
              : _helper.fractionForLetter(currentLetter);
          final usableHeight = trackHeight - _handleHeight;
          final handleTop = usableHeight > 0 ? (fraction * usableHeight) : 0.0;

          final colorScheme = Theme.of(context).colorScheme;

          return SizedBox(
            width: _touchTargetWidth + _bubbleSize + _bubbleMarginRight,
            height: trackHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Handle pill with touch target — only around the pill's position,
                // not the full track, so it doesn't steal scroll gestures.
                // Extra vertical padding makes it easier to grab.
                Positioned(
                  right: 0,
                  top: handleTop - _touchTargetVerticalPadding,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragStart: _onDragStart,
                    onVerticalDragUpdate: _onDragUpdate,
                    onVerticalDragEnd: _onDragEnd,
                    child: SizedBox(
                      width: _touchTargetWidth,
                      height: _handleHeight + _touchTargetVerticalPadding * 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: Container(
                            width: _handleWidth,
                            height: _handleHeight,
                            decoration: BoxDecoration(
                              color: colorScheme.onSurface.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(_handleRadius),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Letter bubble (only while dragging)
                if (_isDragging && _dragLetter != null)
                  Positioned(
                    right: _touchTargetWidth + _bubbleMarginRight,
                    top: handleTop + (_handleHeight - _bubbleSize) / 2,
                    child: Container(
                      width: _bubbleSize,
                      height: _bubbleSize,
                      decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(
                        _dragLetter!,
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: _bubbleFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
