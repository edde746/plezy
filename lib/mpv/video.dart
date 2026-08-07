import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'models.dart';
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
  double? _lastDevicePixelRatio;
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
      // The cache describes the old player's native surface. Keeping it would
      // let the next frame short-circuit as "geometry unchanged", and the
      // replacement surface stays sizeless — invisible, with no Texture
      // fallback left to cover for it.
      _lastRect = null;
      _lastDevicePixelRatio = null;
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

    // The scale is part of what the native side is being told, so it has to be
    // part of what decides whether to tell it. Moving a window between a
    // scale-1 and a scale-2 output changes devicePixelRatio while leaving the
    // logical geometry identical, and dropping that call leaves the native
    // surface at the old buffer resolution: soft at half resolution after
    // docking to a HiDPI output, overdrawn at double after undocking. The Steam
    // Deck's dock is exactly this.
    if (_lastRect != null &&
        _lastDevicePixelRatio == dpr &&
        (newRect.left - _lastRect!.left).abs() < 1 &&
        (newRect.top - _lastRect!.top).abs() < 1 &&
        (newRect.width - _lastRect!.width).abs() < 1 &&
        (newRect.height - _lastRect!.height).abs() < 1) {
      return;
    }

    _lastRect = newRect;
    _lastDevicePixelRatio = dpr;

    final player = widget.player as VideoRectSupport;
    player
        .setVideoRect(
          left: (position.dx * dpr).toInt(),
          top: (position.dy * dpr).toInt(),
          right: ((position.dx + size.width) * dpr).toInt(),
          bottom: ((position.dy + size.height) * dpr).toInt(),
          devicePixelRatio: dpr,
        )
        .catchError((Object e) {
          // Geometry is the only thing that makes the native surface visible,
          // so a rejected rect is a black video area, not a cosmetic glitch.
          // Post-frame callbacks have nobody to rethrow to, so route it to the
          // player's error stream rather than leaving an unhandled async error.
          if (!player.errorController.isClosed) {
            player.errorController.add(PlayerError('Failed to set video rect: $e'));
          }
        });
  }
}
