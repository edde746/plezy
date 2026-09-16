import 'package:flutter/widgets.dart';

import '../services/settings_service.dart';

/// Owns a [State]'s listener registrations and releases them from the state's
/// `dispose` chain — by the closure object that was registered, never by
/// callback identity.
///
/// `removeListener(_callback)` is only correct when the tear-off handed to
/// `remove` is `==` to the one handed to `add`. Instance-method tear-offs are;
/// extension-method tear-offs — every callback declared in a `part` file
/// extension on the state — are not, and neither is a wrapped or curried
/// callback. Binding through this mixin keeps the registered closure and
/// removes exactly that object, so a listener may be declared anywhere.
///
/// In `initState`:
///   bindListenable(widget.controller, _onControllerChanged);
///   bindEffect(SettingsService.rotationLocked, _applyRotation);
///   bindEffect(SettingsService.audioSyncOffset, (v) => player.setAudioDelay(v));
///
/// Every binding is released in `dispose`. A registration that must end
/// earlier — a controller swapped in `didUpdateWidget`, a listener that
/// attaches and detaches with a feature — keeps the returned disposer and
/// runs it; running it again later is a no-op.
mixin ListenableBindingsMixin<T extends StatefulWidget> on State<T> {
  final List<VoidCallback> _bindingDisposers = [];
  bool _bindingsDisposed = false;

  /// Listen to [listenable] until `dispose`, or until the returned disposer runs.
  VoidCallback bindListenable(Listenable listenable, VoidCallback listener) {
    listenable.addListener(listener);
    return ownDisposer(() => listenable.removeListener(listener));
  }

  /// Run [dispose] from this state's `dispose` chain. The returned disposer
  /// runs it early instead, at most once, and drops it from the chain.
  VoidCallback ownDisposer(VoidCallback dispose) {
    assert(!_bindingsDisposed, 'ownDisposer called after dispose: the binding would never be released');
    var released = false;
    void release() {
      if (released) return;
      released = true;
      _bindingDisposers.remove(release);
      dispose();
    }

    _bindingDisposers.add(release);
    return release;
  }

  /// Subscribe to changes of [pref] and run [effect]. The effect fires
  /// immediately with the current value (unless `fireImmediately: false`) so
  /// apply-on-init wiring stays in one place, and then on every subsequent
  /// write — no `didChangeAppLifecycleState` reload.
  void bindEffect<V>(Pref<V> pref, void Function(V value) effect, {bool fireImmediately = true}) {
    final notifier = SettingsService.instance.listenable(pref);
    bindListenable(notifier, () => effect(notifier.value));
    if (fireImmediately) effect(notifier.value);
  }

  /// Rebuild this widget when any of [prefs] changes. Use for state classes
  /// that synthesize multiple settings into derived getters and need their
  /// build to refresh on any change. Equivalent to wrapping the widget tree
  /// in a [SettingsBuilder], but lets you keep raw `setState`-style state too.
  void bindRebuild(List<Pref<Object?>> prefs) {
    final svc = SettingsService.instance;
    final merged = Listenable.merge(prefs.map(svc.listenableOf).toList(growable: false));
    bindListenable(merged, () {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _bindingsDisposed = true;
    while (_bindingDisposers.isNotEmpty) {
      _bindingDisposers.removeLast()();
    }
    super.dispose();
  }
}
