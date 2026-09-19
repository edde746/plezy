import 'package:flutter/material.dart';

import '../../../focus/card_focus_scope.dart';
import '../../../focus/focus_theme.dart';

/// Focus chrome for a round player control sitting on video.
///
/// The app-wide translucent fill (`useBackgroundFocus`) is tuned for opaque
/// surfaces; over a scrim on top of a bright frame it disappears (#2383). Over
/// video the focused control instead becomes a solid disc with the icon
/// inverted — the treatment the tvOS system player, Netflix and Plex use — so
/// it reads at ten feet on any frame. An active control fills amber so that
/// state survives the inversion.
///
/// Reads the [CardFocusScope] installed by
/// `FocusableWrapper(delegateFocusBorder: true)`: a decoration-only wrapper
/// cannot recolour the icon, so the control builds its icon through [builder]
/// with the colour to use. Renders nothing extra in pointer/touch mode, where
/// no scope is present.
class PlayerFocusDisc extends StatelessWidget {
  const PlayerFocusDisc({super.key, required this.iconColor, this.isActive = false, required this.builder});

  /// Idle icon colour. Its alpha is preserved when focused so a dimmed
  /// (unavailable) control stays visibly dimmed on the disc.
  final Color iconColor;

  /// Whether the control represents an engaged state (amber icon when idle).
  final bool isActive;

  final Widget Function(BuildContext context, Color iconColor) builder;

  static const Color _fill = Colors.white;
  static const Color _activeFill = Colors.amber;

  @override
  Widget build(BuildContext context) {
    final showFocus = CardFocusScope.maybeOf(context) ?? false;
    return AnimatedContainer(
      duration: FocusTheme.getAnimationDuration(context),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: showFocus ? (isActive ? _activeFill : _fill) : Colors.transparent,
        boxShadow: showFocus ? const [playerFocusShadow] : const [],
      ),
      child: builder(context, showFocus ? Colors.black.withValues(alpha: iconColor.a) : iconColor),
    );
  }
}

/// Drop shadow that separates focused player chrome from a bright frame.
const BoxShadow playerFocusShadow = BoxShadow(color: Color(0x59000000), blurRadius: 14, offset: Offset(0, 4));

/// Radius of the knob a focused timeline shows in place of its handle.
const double playerFocusKnobRadius = 9;

/// Paints the focused-timeline knob: a white disc with the same shadow as
/// [PlayerFocusDisc], shared by the VOD slider thumb and the live-TV painter.
void paintPlayerFocusKnob(Canvas canvas, Offset center) {
  canvas.drawCircle(
    center + playerFocusShadow.offset / 2,
    playerFocusKnobRadius,
    Paint()
      ..color = playerFocusShadow.color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, playerFocusShadow.blurSigma),
  );
  canvas.drawCircle(center, playerFocusKnobRadius, Paint()..color = Colors.white);
}
