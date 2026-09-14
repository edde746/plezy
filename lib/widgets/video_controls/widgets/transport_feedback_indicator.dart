import 'package:flutter/material.dart';

import '../../app_icon.dart';

/// Centre-screen confirmation of an accepted play/pause command, in the shape
/// viewers know from YouTube: a translucent disc that grows and fades in, holds
/// briefly at rest, then leaves the way it arrived.
///
/// Deliberately icon-only and centred. Subtitles are horizontally centred and
/// sit in the top or bottom band of the frame - a textual pill at the top
/// overlapped ASS `\an8` placement (song lyrics, sign translations), which is
/// exactly the readability complaint this feedback exists to avoid.
class TransportFeedbackIndicator extends StatefulWidget {
  const TransportFeedbackIndicator({super.key, required this.icon, required this.text, required this.pulse});

  final IconData icon;

  /// Not drawn. Carried for assistive tech and the E2E accessibility tree.
  final String text;

  /// Monotonic per accepted command. Two identical commands in a row reuse this
  /// State, so the pop replays off a pulse change rather than off icon/text.
  final int pulse;

  /// Grow and fade in, hold long enough to read, then run the same motion in
  /// reverse. Symmetric on purpose: the disc leaves the way it arrived.
  static const Duration _enter = Duration(milliseconds: 150);
  static const Duration _hold = Duration(milliseconds: 500);
  static const Duration totalDuration = Duration(milliseconds: 800);

  /// The glyph nearly fills the disc — it is a state cue, not a button, so the
  /// surface only needs to be big enough to keep the icon legible over bright
  /// picture rather than to look tappable.
  @visibleForTesting
  static const double diameter = 72;

  @visibleForTesting
  static const double iconSize = 44;

  @override
  State<TransportFeedbackIndicator> createState() => _TransportFeedbackIndicatorState();
}

class _TransportFeedbackIndicatorState extends State<TransportFeedbackIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: TransportFeedbackIndicator.totalDuration,
    vsync: this,
  );

  static final double _enterWeight = TransportFeedbackIndicator._enter.inMilliseconds.toDouble();
  static final double _holdWeight = TransportFeedbackIndicator._hold.inMilliseconds.toDouble();
  static final double _exitWeight =
      TransportFeedbackIndicator.totalDuration.inMilliseconds - _enterWeight - _holdWeight;

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 0.8, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
      weight: _enterWeight,
    ),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: _holdWeight),
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 0.8).chain(CurveTween(curve: Curves.easeIn)),
      weight: _exitWeight,
    ),
  ]).animate(_controller);

  late final Animation<double> _opacity = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
      weight: _enterWeight,
    ),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: _holdWeight),
    TweenSequenceItem(
      tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
      weight: _exitWeight,
    ),
  ]).animate(_controller);

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void didUpdateWidget(TransportFeedbackIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pulse != widget.pulse) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Own semantics node: without it the label merges into the full-screen
    // "show playback controls" target behind it, corrupting that button's name
    // and hiding the status. liveRegion announces the transition.
    return Semantics(
      container: true,
      liveRegion: true,
      excludeSemantics: true,
      label: widget.text,
      child: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: ScaleTransition(
            scale: _scale,
            child: Container(
              width: TransportFeedbackIndicator.diameter,
              height: TransportFeedbackIndicator.diameter,
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), shape: BoxShape.circle),
              child: Center(
                child: AppIcon(widget.icon, fill: 1, color: Colors.white, size: TransportFeedbackIndicator.iconSize),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
