import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../i18n/strings.g.dart';
import '../../../utils/formatters.dart';
import '../../../utils/platform_detector.dart';
import '../../app_icon.dart';

/// Label for the skip feedback. Plain `Ns` stays readable up to a minute; beyond
/// that (reachable by held D-pad seeking, which accelerates) a raw second
/// count is unreadable, so fall back to the M:SS timestamp form.
@visibleForTesting
String formatSkipFeedbackLabel(int seconds) {
  if (seconds < 60) return '$seconds${t.settings.secondsShort}';
  return formatDurationTimestamp(Duration(seconds: seconds));
}

/// Transient seek readout at the side of the frame the seek travels toward: the
/// amount, and a single chevron on the same line drifting that way.
///
/// Deliberately unbacked — no scrim, no puck. Anything large enough to read as a
/// surface also covers picture and subtitles, which is the complaint this
/// feedback exists to answer. Legibility comes from shadows instead.
///
/// Only the chevron moves. The amount is what the viewer reads, so it stays put.
class DoubleTapFeedback extends StatefulWidget {
  final bool isForward;
  final int seconds;

  const DoubleTapFeedback({super.key, required this.isForward, required this.seconds});

  /// Inset from the anchored edge. TVs overscan roughly 5% of each edge, so
  /// derive it from the viewport rather than assuming 1080p logical geometry — a
  /// TV reporting 960dp at 2x would otherwise get double the intended inset.
  /// Clamped so the readout never sits tighter than the touch layout, never
  /// drifts toward centre on an ultra-wide viewport, and always leaves itself
  /// room on a narrow one.
  static double _horizontalInset(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final overscan = PlatformDetector.isTV() ? (width * 0.05).clamp(60.0, 160.0) : 60.0;
    return overscan.clamp(0.0, math.max(0.0, (width - _minReadoutWidth) / 2));
  }

  /// Chevron plus a few characters of label at the largest step.
  static const double _minReadoutWidth = 200;

  /// Type scale. A TV is read from across the room, so it needs a bigger step
  /// than a handset at arm's length even though the two report a similar
  /// logical width — 960dp at 2x versus roughly 900dp in landscape.
  static double _labelSize(BuildContext context) => PlatformDetector.isTV() ? 34 : 26;

  static double _chevronSize(BuildContext context) => PlatformDetector.isTV() ? 46 : 36;

  /// How far the chevron drifts either side of centre, in logical pixels. Scaled
  /// with the glyph so the motion stays proportional.
  static double _driftDistance(BuildContext context) => _chevronSize(context) * 0.22;

  static const Duration _driftPeriod = Duration(milliseconds: 1100);

  @override
  State<DoubleTapFeedback> createState() => _DoubleTapFeedbackState();
}

class _DoubleTapFeedbackState extends State<DoubleTapFeedback> with SingleTickerProviderStateMixin {
  /// The chevron drifts the way the seek goes, looping free for as long as the
  /// readout is up so a held key reads as continuous travel.
  ///
  /// Deliberately never restarted per press: key repeats arrive every few tens
  /// of milliseconds, far faster than the cycle, so restarting would pin the
  /// chevron at the start of its nudge for the whole burst. No per-press kick is
  /// needed anyway - a same-direction press changes the amount, and a direction
  /// flip flips the chevron and the side it sits on.
  late final AnimationController _drift = AnimationController(duration: DoubleTapFeedback._driftPeriod, vsync: this)
    ..repeat();

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  /// The chevron never disappears; it only brightens as it travels.
  static const double _minChevronOpacity = 0.7;

  /// Share of the cycle spent travelling outward, the rest returning.
  static const double _outwardFraction = 0.7;

  static const List<Shadow> _legibility = [Shadow(color: Colors.black87, blurRadius: 6)];

  Widget _buildChevron(BuildContext context) {
    return AnimatedBuilder(
      animation: _drift,
      builder: (context, child) {
        // Most of the cycle is the outward stroke; the return is brief, so the
        // eye reads travel in the seek direction rather than a symmetric wobble.
        // Both ends rest at zero, so the wrap needs no fade to hide a snap - the
        // chevron is a persistent cue, never a blinking one.
        final phase = _drift.value;
        final travel = phase < _outwardFraction
            ? Curves.easeOut.transform(phase / _outwardFraction)
            : 1 - Curves.easeInOut.transform((phase - _outwardFraction) / (1 - _outwardFraction));
        final dx = travel * DoubleTapFeedback._driftDistance(context) * (widget.isForward ? 1 : -1);
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Opacity(opacity: _minChevronOpacity + (1 - _minChevronOpacity) * travel, child: child),
        );
      },
      child: AppIcon(
        widget.isForward ? Symbols.chevron_right_rounded : Symbols.chevron_left_rounded,
        fill: 1,
        color: Colors.white,
        size: DoubleTapFeedback._chevronSize(context),
        shadows: _legibility,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isForward = widget.isForward;

    // Own semantics node with a spoken label: the visible "10s"/"2:55" is a
    // glance affordance, while assistive tech gets the direction and amount.
    // Without the container the text merges into the full-screen playback
    // control behind it and never reaches the user.
    return Semantics(
      container: true,
      liveRegion: true,
      excludeSemantics: true,
      label: isForward
          ? t.videoControls.seekForwardButton(seconds: widget.seconds)
          : t.videoControls.seekBackwardButton(seconds: widget.seconds),
      child: Align(
        alignment: isForward ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: DoubleTapFeedback._horizontalInset(context)),
          child: Row(
            mainAxisSize: .min,
            children: [
              // Chevron leads on the side the seek travels toward.
              if (!isForward) ...[_buildChevron(context), const SizedBox(width: 6)],
              Text(
                formatSkipFeedbackLabel(widget.seconds),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: DoubleTapFeedback._labelSize(context),
                  fontWeight: .bold,
                  shadows: _legibility,
                ),
              ),
              if (isForward) ...[const SizedBox(width: 6), _buildChevron(context)],
            ],
          ),
        ),
      ),
    );
  }
}
