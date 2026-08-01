import 'package:flutter/material.dart';
import '../services/device_performance.dart';
import 'mono_tokens.dart';

/// Motion vocabulary for the M3E-style components. All durations collapse to
/// [Duration.zero] on the reduced performance tier so low-end TVs get instant
/// snaps instead of animations.
class MonoMotion {
  MonoMotion._();

  /// M3 emphasized-decelerate. Monotonic in [0,1], so a single
  /// AnimatedContainer can animate color and border radius together without
  /// overshooting into out-of-gamut colors or negative radii.
  static const Curve emphasized = Easing.emphasizedDecelerate;

  /// The app-wide standard curve.
  static const Curve standard = Curves.easeOutCubic;

  /// Shape morphs (segment square→pill, group corner changes).
  static Duration shape(BuildContext context) => DevicePerformance.reducedDuration(tokens(context).expressive);

  /// Fill/text color transitions.
  static Duration fill(BuildContext context) => DevicePerformance.reducedDuration(tokens(context).normal);

  /// Press squish in/out.
  static Duration press(BuildContext context) => DevicePerformance.reducedDuration(tokens(context).fast);
}
