import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'player/player.dart';
import 'player/video_rect_support.dart';

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
///   controls: (context) => MyCustomControls(),
/// )
/// ```
class Video extends StatefulWidget {
  final Player player;
  final Widget Function(BuildContext context)? controls;
  final Color backgroundColor;
  final ValueListenable<bool>? hasFirstFrame;

  const Video({
    super.key,
    required this.player,
    this.controls,
    this.backgroundColor = Colors.black,
    this.hasFirstFrame,
  });

  @override
  State<Video> createState() => _VideoState();
}

class _VideoState extends State<Video> {
  Rect? _lastRect;
  bool _hasFirstFrame = false;
  StreamSubscription<void>? _playbackRestartSubscription;

  @override
  void initState() {
    super.initState();
    _hasFirstFrame = widget.hasFirstFrame?.value ?? false;
    widget.hasFirstFrame?.addListener(_syncExternalFirstFrame);
    _listenForPlaybackRestart();
  }

  @override
  void didUpdateWidget(covariant Video oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hasFirstFrame != widget.hasFirstFrame) {
      oldWidget.hasFirstFrame?.removeListener(_syncExternalFirstFrame);
      widget.hasFirstFrame?.addListener(_syncExternalFirstFrame);
      _syncExternalFirstFrame();
    }
    if (oldWidget.player != widget.player) {
      _playbackRestartSubscription?.cancel();
      _listenForPlaybackRestart();
      _syncExternalFirstFrame();
    }
  }

  @override
  void dispose() {
    widget.hasFirstFrame?.removeListener(_syncExternalFirstFrame);
    _playbackRestartSubscription?.cancel();
    super.dispose();
  }

  void _listenForPlaybackRestart() {
    _playbackRestartSubscription = widget.player.streams.playbackRestart.listen((_) {
      _setHasFirstFrame(true);
    });
  }

  void _syncExternalFirstFrame() {
    final external = widget.hasFirstFrame;
    if (external == null) return;
    _setHasFirstFrame(external.value);
  }

  void _setHasFirstFrame(bool value) {
    if (_hasFirstFrame == value || !mounted) return;
    setState(() => _hasFirstFrame = value);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _hasFirstFrame ? Colors.transparent : widget.backgroundColor,
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
    final textureId = widget.player.textureId;
    if (textureId != null) {
      return Texture(textureId: textureId);
    }

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

  void _updateVideoRect(BuildContext context, BoxConstraints _) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final dpr = MediaQuery.devicePixelRatioOf(context);

    final newRect = Rect.fromLTWH(position.dx, position.dy, size.width, size.height);

    if (_lastRect != null &&
        (newRect.left - _lastRect!.left).abs() < 1 &&
        (newRect.top - _lastRect!.top).abs() < 1 &&
        (newRect.width - _lastRect!.width).abs() < 1 &&
        (newRect.height - _lastRect!.height).abs() < 1) {
      return;
    }

    _lastRect = newRect;

    (widget.player as VideoRectSupport).setVideoRect(
      left: (position.dx * dpr).toInt(),
      top: (position.dy * dpr).toInt(),
      right: ((position.dx + size.width) * dpr).toInt(),
      bottom: ((position.dy + size.height) * dpr).toInt(),
      devicePixelRatio: dpr,
    );
  }
}
