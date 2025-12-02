import 'package:flutter/material.dart';

import '../player/player.dart';
import '../player/video_rect_support.dart';

/// Video widget for displaying player output.
///
/// This widget displays the video output from a [Player] instance
/// and optionally overlays custom controls.
///
/// Example usage:
/// ```dart
/// final player = Player();
///
/// Video(
///   player: player,
///   fit: BoxFit.contain,
///   controls: (context) => MyCustomControls(),
/// )
/// ```
class Video extends StatefulWidget {
  /// The player instance.
  final Player player;

  /// How the video should be inscribed into the widget's box.
  final BoxFit fit;

  /// Builder for custom video controls overlay.
  final Widget Function(BuildContext context)? controls;

  /// Background color shown behind the video.
  final Color backgroundColor;

  const Video({
    super.key,
    required this.player,
    this.fit = BoxFit.contain,
    this.controls,
    this.backgroundColor = Colors.black,
  });

  @override
  State<Video> createState() => _VideoState();
}

class _VideoState extends State<Video> {
  Rect? _lastRect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video rendering area
          _buildVideoSurface(),

          // Controls overlay
          if (widget.controls != null) widget.controls!(context),
        ],
      ),
    );
  }

  Widget _buildVideoSurface() {
    // For players that support video rect positioning (Windows, Linux),
    // communicate layout changes to the native side.
    if (widget.player is VideoRectSupport) {
      return LayoutBuilder(
        builder: (context, constraints) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateVideoRect(context, constraints);
          });
          return const SizedBox.expand();
        },
      );
    }
    return const SizedBox.expand();
  }

  void _updateVideoRect(BuildContext context, BoxConstraints constraints) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final dpr = MediaQuery.of(context).devicePixelRatio;

    final newRect = Rect.fromLTWH(
      position.dx,
      position.dy,
      size.width,
      size.height,
    );

    // Only update if the rect has changed significantly
    if (_lastRect != null &&
        (newRect.left - _lastRect!.left).abs() < 1 &&
        (newRect.top - _lastRect!.top).abs() < 1 &&
        (newRect.width - _lastRect!.width).abs() < 1 &&
        (newRect.height - _lastRect!.height).abs() < 1) {
      return;
    }

    _lastRect = newRect;

    // Update the native video rect
    (widget.player as VideoRectSupport).setVideoRect(
      left: (position.dx * dpr).toInt(),
      top: (position.dy * dpr).toInt(),
      right: ((position.dx + size.width) * dpr).toInt(),
      bottom: ((position.dy + size.height) * dpr).toInt(),
      devicePixelRatio: dpr,
    );
  }
}
