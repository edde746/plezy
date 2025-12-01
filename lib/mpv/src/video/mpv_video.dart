import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import '../player/mpv_player.dart';
import '../player/mpv_player_windows.dart';

/// Video widget for displaying MPV player output.
///
/// This widget displays the video output from an [MpvPlayer] instance
/// and optionally overlays custom controls.
///
/// Example usage:
/// ```dart
/// final player = MpvPlayer();
///
/// MpvVideo(
///   player: player,
///   fit: BoxFit.contain,
///   controls: (context) => MyCustomControls(),
/// )
/// ```
class MpvVideo extends StatefulWidget {
  /// The player instance.
  final MpvPlayer player;

  /// How the video should be inscribed into the widget's box.
  final BoxFit fit;

  /// Builder for custom video controls overlay.
  final Widget Function(BuildContext context)? controls;

  /// Background color shown behind the video.
  final Color backgroundColor;

  const MpvVideo({
    super.key,
    required this.player,
    this.fit = BoxFit.contain,
    this.controls,
    this.backgroundColor = Colors.black,
  });

  @override
  State<MpvVideo> createState() => _MpvVideoState();
}

class _MpvVideoState extends State<MpvVideo> {
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
    if (Platform.isWindows) {
      // On Windows, use native window embedding.
      // The mpv window is positioned behind Flutter, and we need to
      // communicate the video rect to the native side.
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

    // Update the native mpv window position
    if (widget.player is MpvPlayerWindows) {
      final windowsPlayer = widget.player as MpvPlayerWindows;
      windowsPlayer.setVideoRect(
        left: (position.dx * dpr).toInt(),
        top: (position.dy * dpr).toInt(),
        right: ((position.dx + size.width) * dpr).toInt(),
        bottom: ((position.dy + size.height) * dpr).toInt(),
        devicePixelRatio: dpr,
      );
    }
  }
}
