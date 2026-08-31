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
  final Listenable? rectUpdateListenable;

  const Video({
    super.key,
    required this.player,
    this.controls,
    this.backgroundColor = Colors.black,
    this.hasFirstFrame,
    this.rectUpdateListenable,
  });

  @override
  State<Video> createState() => _VideoState();
}

class _VideoState extends State<Video> {
  // The integer physical bounds last handed to the native side, and the scale
  // that went with them. Cached as what was *sent*, not as the logical rect it
  // was derived from, because the rounding in _updateVideoRect is what decides
  // whether a layout change is visible to the plane at all.
  bool _hasSentRect = false;
  int _sentLeft = 0;
  int _sentTop = 0;
  int _sentRight = 0;
  int _sentBottom = 0;
  double _sentDevicePixelRatio = 0;
  bool _hasFirstFrame = false;
  BuildContext? _videoSurfaceContext;
  bool _rectUpdateScheduled = false;
  StreamSubscription<void>? _playbackRestartSubscription;

  @override
  void initState() {
    super.initState();
    _hasFirstFrame = widget.hasFirstFrame?.value ?? false;
    widget.hasFirstFrame?.addListener(_syncExternalFirstFrame);
    widget.rectUpdateListenable?.addListener(_scheduleVideoRectUpdate);
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
    if (oldWidget.rectUpdateListenable != widget.rectUpdateListenable) {
      oldWidget.rectUpdateListenable?.removeListener(_scheduleVideoRectUpdate);
      widget.rectUpdateListenable?.addListener(_scheduleVideoRectUpdate);
      _scheduleVideoRectUpdate();
    }
    if (oldWidget.player != widget.player) {
      _videoSurfaceContext = null;
      _playbackRestartSubscription?.cancel();
      _listenForPlaybackRestart();
      _syncExternalFirstFrame();
      // The cache describes the old player's native surface. Keeping it would
      // let the next frame short-circuit as "geometry unchanged", and the
      // replacement surface stays sizeless — invisible, with no Texture
      // fallback left to cover for it.
      _hasSentRect = false;
    }
  }

  @override
  void dispose() {
    widget.hasFirstFrame?.removeListener(_syncExternalFirstFrame);
    widget.rectUpdateListenable?.removeListener(_scheduleVideoRectUpdate);
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
          _videoSurfaceContext = context;
          _scheduleVideoRectUpdate();
          return const SizedBox.expand();
        },
      );
    }
    _videoSurfaceContext = null;
    return const SizedBox.expand();
  }

  void _scheduleVideoRectUpdate() {
    if (_rectUpdateScheduled) return;
    _rectUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rectUpdateScheduled = false;
      if (!mounted) return;
      final context = _videoSurfaceContext;
      if (context != null) _updateVideoRect(context);
    });
  }

  void _updateVideoRect(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final dpr = MediaQuery.devicePixelRatioOf(context);

    // Rounded outward, the same way the native SetRect biases: it floors the
    // position and rounds the buffer size up so the plane always covers at
    // least the region Flutter cut out for it. Truncating the far edges here
    // would undo that a layer earlier - at a fractional layout position the
    // plane comes up a physical pixel short and the desktop shows through the
    // seam, where the point of the plane is that the seam is black. Ceil and
    // floor are identity on an already-integral value, so an integral layout
    // sends exactly the numbers it sent before.
    final left = (position.dx * dpr).floor();
    final top = (position.dy * dpr).floor();
    final right = ((position.dx + size.width) * dpr).ceil();
    final bottom = ((position.dy + size.height) * dpr).ceil();

    // Keyed on the four integers actually sent rather than on a logical-pixel
    // tolerance. A sub-logical-pixel move is a real move at scale 2 or 3 -
    // worth up to three physical pixels of stale placement - while anything too
    // small to change one of these numbers cannot reach the plane at all and is
    // not worth the channel round-trip.
    //
    // The scale is part of what the native side is being told, so it has to be
    // part of what decides whether to tell it. Moving a window between a
    // scale-1 and a scale-2 output can leave all four bounds identical while
    // devicePixelRatio changes, and dropping that call leaves the native
    // surface at the old buffer resolution: soft at half resolution after
    // docking to a HiDPI output, overdrawn at double after undocking. The Steam
    // Deck's dock is exactly this.
    if (_hasSentRect &&
        _sentLeft == left &&
        _sentTop == top &&
        _sentRight == right &&
        _sentBottom == bottom &&
        _sentDevicePixelRatio == dpr) {
      return;
    }

    _hasSentRect = true;
    _sentLeft = left;
    _sentTop = top;
    _sentRight = right;
    _sentBottom = bottom;
    _sentDevicePixelRatio = dpr;

    final player = widget.player as VideoRectSupport;
    player.setVideoRect(left: left, top: top, right: right, bottom: bottom, devicePixelRatio: dpr).catchError((
      Object e,
    ) {
      // Geometry is the only thing that makes the native surface visible,
      // so a rejected rect is a black video area, not a cosmetic glitch.
      // Post-frame callbacks have nobody to rethrow to, so route it to the
      // player's error stream rather than leaving an unhandled async error.
      //
      // Drop the sent-rect cache too: it was recorded before the call
      // resolved, and keeping it would short-circuit every later identical
      // layout pass, freezing the failure in place. Cleared, the next layout
      // or resize retries for free.
      if (mounted &&
          _sentLeft == left &&
          _sentTop == top &&
          _sentRight == right &&
          _sentBottom == bottom &&
          _sentDevicePixelRatio == dpr) {
        _hasSentRect = false;
      }
      if (!player.errorController.isClosed) {
        player.errorController.add(PlayerError('Failed to set video rect: $e'));
      }
    });
  }
}
