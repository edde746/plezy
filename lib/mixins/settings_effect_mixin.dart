import 'package:flutter/widgets.dart';

import '../services/settings_service.dart';

/// Wires up settings → side-effect bindings without manual addListener/dispose.
///
/// In `initState`:
///   bindEffect(SettingsService.rotationLocked, _applyRotation);
///   bindEffect(SettingsService.audioSyncOffset, (v) => player.setAudioDelay(v));
///
/// The callback fires immediately with the current value (unless
/// `fireImmediately: false`) so apply-on-init wiring stays in one place, and
/// then on every subsequent write — no `didChangeAppLifecycleState` reload.
mixin SettingsEffectMixin<T extends StatefulWidget> on State<T> {
  final List<VoidCallback> _settingsEffectDisposers = [];

  /// Subscribe to changes of [pref] and run [effect]. Auto-disposed in [dispose].
  void bindEffect<V>(Pref<V> pref, void Function(V value) effect, {bool fireImmediately = true}) {
    final notifier = SettingsService.instanceOrNull!.listenable(pref);
    void listener() => effect(notifier.value);
    notifier.addListener(listener);
    _settingsEffectDisposers.add(() => notifier.removeListener(listener));
    if (fireImmediately) effect(notifier.value);
  }

  /// Rebuild this widget when any of [prefs] changes. Use for state classes
  /// that synthesize multiple settings into derived getters and need their
  /// build to refresh on any change. Equivalent to wrapping the widget tree
  /// in a [SettingsBuilder], but lets you keep raw `setState`-style state too.
  void bindRebuild(List<Pref<Object?>> prefs) {
    final svc = SettingsService.instanceOrNull!;
    final merged = Listenable.merge(prefs.map(svc.listenableOf).toList(growable: false));
    void listener() {
      if (mounted) setState(() {});
    }

    merged.addListener(listener);
    _settingsEffectDisposers.add(() => merged.removeListener(listener));
  }

  @override
  void dispose() {
    for (final d in _settingsEffectDisposers) {
      d();
    }
    _settingsEffectDisposers.clear();
    super.dispose();
  }
}
