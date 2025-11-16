import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/platform_detector.dart';
import '../../utils/tv_ui_helper.dart';

/// A standardized button for video player controls with improved tap targets.
///
/// This widget ensures consistent tap target sizing across all video control
/// buttons without changing their visual appearance. The larger tap area makes
/// buttons easier to interact with, especially on mobile devices and TV remotes.
/// On TV, buttons have enhanced focus indicators and larger touch targets.
class VideoControlButton extends StatefulWidget {
  /// The icon to display in the button.
  final IconData icon;

  /// Called when the button is tapped.
  final VoidCallback? onPressed;

  /// The color of the icon. Defaults to white, or amber if [isActive] is true.
  final Color? color;

  /// Optional tooltip text shown on hover or long press.
  final String? tooltip;

  /// Whether this button represents an active state (e.g., a feature is enabled).
  /// When true, the icon color defaults to amber instead of white.
  final bool isActive;

  const VideoControlButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.color,
    this.tooltip,
    this.isActive = false,
  });

  @override
  State<VideoControlButton> createState() => _VideoControlButtonState();
}

class _VideoControlButtonState extends State<VideoControlButton> {
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    final isTV = PlatformDetector.isTVSync();
    _focusNode = FocusNode(skipTraversal: isTV);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine the effective color: explicit color > active amber > default white
    final effectiveColor =
        widget.color ?? (widget.isActive ? Colors.amber : Colors.white);
    final isTV = PlatformDetector.isTVSync();
    final minSize = isTV ? TVUIHelper.getMinTouchTarget() : 40.0;

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        // Handle Enter/Select key on TV
        if (isTV && event is KeyDownEvent && widget.onPressed != null) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            widget.onPressed!();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: _isFocused && isTV
              ? Border.all(color: Colors.white, width: 2)
              : null,
        ),
        child: IconButton(
          icon: Icon(widget.icon, color: effectiveColor),
          onPressed: widget.onPressed,
          tooltip: widget.tooltip,
          constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
          iconSize: isTV ? 28 : 24,
          autofocus: false,
        ),
      ),
    );
  }
}
