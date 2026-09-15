import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Keeps the player immersive across system-UI re-shows the engine does not
/// handle on its own.
///
/// Flutter's Android `PlatformPlugin` re-applies the requested
/// [SystemUiMode] only in `onPostResume`. A configuration change that keeps
/// the activity resumed — folding or unfolding, a display switch — lets
/// Android show the bars again with nothing to hide them. The engine's hook
/// for that is `SystemChrome.systemUIChange`: Android posts it when the
/// system re-shows the overlays, and the owner answers by re-requesting
/// [SystemUiMode.immersiveSticky]. Other platforms never post it, so the
/// guard is a no-op there; TV has no bars to re-hide.
///
/// One owner at a time. A successor player acquires before its predecessor
/// releases, so [release] only clears a matching owner. The native listener
/// is registered once and stays registered — Flutter never unregisters it —
/// and does nothing while nobody owns immersive mode.
abstract final class ImmersiveModeGuard {
  static Object? _owner;
  static bool _listening = false;

  static void acquire(Object owner) {
    _owner = owner;
    if (_listening) return;
    _listening = true;
    unawaited(SystemChrome.setSystemUIChangeCallback(_onSystemUiChange));
  }

  static void release(Object owner) {
    if (identical(_owner, owner)) _owner = null;
  }

  static Future<void> _onSystemUiChange(bool systemOverlaysAreVisible) async {
    if (!systemOverlaysAreVisible || _owner == null) return;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @visibleForTesting
  static void resetForTesting() {
    _owner = null;
    _listening = false;
    unawaited(SystemChrome.setSystemUIChangeCallback(null));
  }
}
