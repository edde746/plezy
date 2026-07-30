import 'package:flutter/widgets.dart';

import '../utils/platform_detector.dart';

/// Android Automotive OS driver-distraction gating for Plezy's `video` app
/// category (car app quality `DD-2` / `DD-3`).
///
/// While a vehicle's user-experience restrictions are active the system hides
/// the app's activity. That delivers `onPause` — Flutter
/// [AppLifecycleState.inactive] — at minimum; only devices carrying the
/// Automotive compatibility mode go on to deliver `onStop`
/// ([AppLifecycleState.hidden] then [AppLifecycleState.paused]). Reacting to
/// lifecycle callbacks is the mechanism the platform documents as sufficient,
/// so playback authority is derived from lifecycle state alone and no
/// `android.car` dependency is required.
///
/// Two obligations follow from `DD-2`, and this single predicate serves both:
/// audio must stop when driving starts, and it must not be resumable while
/// driving. The second obligation covers every path that can start audio, not
/// just OS media-session commands — a gapless track transition or queue
/// auto-advance landing just after the lifecycle pause must fail closed too.
///
/// The gate itself fails closed: an unknown (null) lifecycle state denies
/// playback so a command arriving before the first lifecycle message cannot
/// slip through; nothing is playing that early, so the strictness costs nothing.
bool automotivePlaybackAllowed({required bool isAutomotive, required AppLifecycleState? state}) {
  if (!isAutomotive) return true;
  return state == AppLifecycleState.resumed;
}

/// [automotivePlaybackAllowed] against the ambient form factor and lifecycle,
/// for owners that hold no injected lifecycle state of their own.
///
/// Short-circuits before reading [WidgetsBinding.instance] so this stays usable
/// from plain `test()` suites, where the binding is not initialized and the
/// `instance` getter throws.
bool automotivePlaybackAllowedNow() {
  if (!PlatformDetector.isAutomotive()) return true;
  return automotivePlaybackAllowed(isAutomotive: true, state: WidgetsBinding.instance.lifecycleState);
}
