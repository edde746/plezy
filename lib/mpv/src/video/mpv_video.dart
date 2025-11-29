import 'dart:io' show Platform;

import 'package:flutter/material.dart';

import '../player/mpv_player.dart';

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
    return const SizedBox.expand();
  }
}
