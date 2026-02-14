import 'dart:async';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'player/player.dart';
import 'player/player_web.dart';

/// Web-specific video widget that uses HtmlElementView to display
/// the HTML5 <video> element.
class VideoWeb extends StatefulWidget {
  /// The player instance (must be a PlayerWeb).
  final Player player;

  /// Builder for custom video controls overlay.
  final Widget Function(BuildContext context)? controls;

  /// Background color shown behind the video.
  final Color backgroundColor;

  const VideoWeb({
    super.key,
    required this.player,
    this.controls,
    this.backgroundColor = Colors.black,
  });

  @override
  State<VideoWeb> createState() => _VideoWebState();
}

class _VideoWebState extends State<VideoWeb> {
  bool _hasFirstFrame = false;
  StreamSubscription<void>? _playbackRestartSubscription;
  bool _registered = false;

  PlayerWeb get _webPlayer => widget.player as PlayerWeb;

  @override
  void initState() {
    super.initState();
    _registerViewFactory();
    _playbackRestartSubscription = widget.player.streams.playbackRestart.listen((_) {
      if (!_hasFirstFrame && mounted) {
        setState(() => _hasFirstFrame = true);
      }
    });
  }

  void _registerViewFactory() {
    final viewId = _webPlayer.viewId;
    final videoElement = _webPlayer.videoElement;
    if (viewId != null && videoElement != null && !_registered) {
      ui_web.platformViewRegistry.registerViewFactory(
        viewId,
        (int id) => videoElement,
      );
      _registered = true;
    }
  }

  @override
  void dispose() {
    _playbackRestartSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewId = _webPlayer.viewId;

    return Container(
      color: _hasFirstFrame ? Colors.transparent : widget.backgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video rendering via HtmlElementView
          if (viewId != null)
            HtmlElementView(viewType: viewId),

          // Controls overlay
          if (widget.controls != null) widget.controls!(context),
        ],
      ),
    );
  }
}
