import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:plezy/i18n/strings.g.dart';
import 'package:plezy/widgets/app_icon.dart';

import 'transport_feedback_indicator.dart';

/// VLC-style dark pill shown at top-center of the video player.
/// Used for rate changes and other transient in-player notifications.
class PlayerToastIndicator extends StatelessWidget {
  const PlayerToastIndicator({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    // Own semantics node: without it the pill's text merges into whatever
    // full-screen control sits behind it (the "show playback controls" tap
    // target), corrupting that button's name and hiding the status. liveRegion
    // makes assistive tech announce the transition.
    return Semantics(
      container: true,
      liveRegion: true,
      excludeSemantics: true,
      label: text,
      child: Align(
        alignment: .topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.8),
          child: Container(
            margin: const EdgeInsets.only(top: 20),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: const BorderRadius.all(Radius.circular(20)),
            ),
            child: Row(
              mainAxisSize: .min,
              children: [
                AppIcon(icon, fill: 1, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: .bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// How a transient in-player notification presents itself.
enum PlayerToastKind {
  /// Textual dark pill at the top of the frame: rate changes, chapter titles,
  /// backend switches, errors.
  notice,

  /// Icon-only disc at the centre of the frame confirming an accepted
  /// play/pause command, in the shape viewers know from YouTube.
  transport,
}

/// Owns the currently-displayed toast + auto-hide timer.
/// Created per video-player session; disposed with the screen.
class PlayerToastController extends ChangeNotifier {
  ({IconData icon, String text, PlayerToastKind kind, int pulse})? _current;
  Timer? _timer;
  int _pulse = 0;
  int _frameSteps = 0;

  ({IconData icon, String text, PlayerToastKind kind, int pulse})? get current => _current;

  /// Maestro builds hold every pill far longer: accessibility-tree queries on
  /// physical devices routinely outlast the production timeout, the same
  /// reason the chrome hide delay is extended for E2E.
  static const Duration _maestroMinimumDuration = Duration(seconds: 30);

  /// Confirms an accepted play/pause command. [text] is not drawn - the disc is
  /// icon-only - but it remains the semantics label so assistive tech and the
  /// E2E accessibility tree still read "Paused"/"Playing".
  ///
  /// Lifetime comes from the disc itself, which fades itself back out, so the
  /// widget is never unmounted mid-exit.
  void showTransport(IconData icon, String text) {
    show(icon, text, kind: PlayerToastKind.transport, duration: TransportFeedbackIndicator.totalDuration);
  }

  void show(
    IconData icon,
    String text, {
    Duration duration = const Duration(milliseconds: 1200),
    PlayerToastKind kind = PlayerToastKind.notice,
  }) {
    _frameSteps = 0;
    _show(icon, text, duration, kind: kind);
  }

  void showFrameStep(int step) {
    _frameSteps = _frameSteps.sign == step.sign ? _frameSteps + step : step;
    _show(
      step > 0 ? Symbols.fast_forward_rounded : Symbols.fast_rewind_rounded,
      t.videoControls.frameCount(n: _frameSteps.abs()),
      const Duration(milliseconds: 1200),
      kind: PlayerToastKind.notice,
    );
  }

  void _show(IconData icon, String text, Duration duration, {required PlayerToastKind kind}) {
    _timer?.cancel();
    // Every accepted command carries a fresh pulse. Two identical commands in a
    // row (an explicit pause while already paused, say) produce an identical
    // icon/text pair, so without this the animated child would be reused and
    // its one-shot pop would never replay.
    _current = (icon: icon, text: text, kind: kind, pulse: ++_pulse);
    notifyListeners();
    final effective = const bool.fromEnvironment('PLEZY_MAESTRO_E2E') && duration < _maestroMinimumDuration
        ? _maestroMinimumDuration
        : duration;
    _timer = Timer(effective, () {
      _current = null;
      _timer = null;
      _frameSteps = 0;
      notifyListeners();
    });
  }

  void hide() {
    _timer?.cancel();
    _timer = null;
    _frameSteps = 0;
    if (_current != null) {
      _current = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
