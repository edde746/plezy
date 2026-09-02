import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';

/// Lets the app decline to build a semantics tree while the platform has
/// accessibility switched on but nothing is going to read the tree.
///
/// Android turns Flutter semantics on whenever *any* accessibility service is
/// bound, and on TV that is routinely a utility with no interest in app
/// content — a launcher's "current app" hook, a key remapper. The framework
/// then compiles and ships a full semantics tree every frame that touches a
/// node: measured on an Android 14 TV box with the Projectivy Launcher service
/// bound, 2 ms of every frame and ~20 ms on each spotlight swap, plus the
/// allocation churn behind it. A screen reader must see everything, so the
/// decision is made per enabled service by `AssistiveTechnologyService`; this
/// mixin is only the switch.
///
/// The switch sits under [SemanticsBinding.semanticsEnabled], the single value
/// the pipeline owner and the engine handshake consult, so turning it off tears
/// the semantics owner down exactly as if the platform had disabled
/// accessibility: no tree is compiled, no update is sent, and the engine is
/// told through `setSemanticsTreeEnabled` to drop its copy. Defaults to wanted.
///
/// An explicit [ensureSemantics] client (the debug-build handle kept for UI
/// automation) always wins: the gate only ever suppresses the platform's own
/// request. Disposing such a client is not observable here, so a closed gate
/// takes effect again at the next platform or gate change rather than at once.
mixin SemanticsTreeGate on SemanticsBinding {
  final _GateNotifier _gate = _GateNotifier();

  /// Whether a platform request for semantics should produce a tree.
  bool get semanticsTreeWanted => _gate.wanted;
  set semanticsTreeWanted(bool value) {
    if (_gate.wanted == value) return;
    _gate.wanted = value;
    _gate.notify();
  }

  /// Whether the platform (or an explicit [ensureSemantics] client) asked for
  /// semantics, before this gate is applied.
  bool get platformSemanticsRequested => super.semanticsEnabled;

  /// The platform holds at most one handle; anything beyond it is an explicit
  /// client that must keep receiving a tree.
  bool get _hasExplicitClient => debugOutstandingSemanticsHandles > (platformDispatcher.semanticsEnabled ? 1 : 0);

  @override
  bool get semanticsEnabled => super.semanticsEnabled && (_gate.wanted || _hasExplicitClient);

  @override
  SemanticsHandle ensureSemantics() {
    final handle = super.ensureSemantics();
    // A new explicit client may have just re-enabled a gated tree; the base
    // notifier only fires on the false→true edge, which the platform's own
    // handle has already consumed.
    if (!_gate.wanted && _hasExplicitClient) _gate.notify();
    return handle;
  }

  @override
  void addSemanticsEnabledListener(VoidCallback listener) {
    super.addSemanticsEnabledListener(listener);
    _gate.addListener(listener);
  }

  @override
  void removeSemanticsEnabledListener(VoidCallback listener) {
    super.removeSemanticsEnabledListener(listener);
    _gate.removeListener(listener);
  }

  /// Listens to [platformSemanticsRequested] only; unlike
  /// [addSemanticsEnabledListener] it does not fire when the gate flips, so the
  /// service driving the gate can react to platform changes without re-entering
  /// its own decision.
  void addPlatformSemanticsListener(VoidCallback listener) => super.addSemanticsEnabledListener(listener);

  void removePlatformSemanticsListener(VoidCallback listener) => super.removeSemanticsEnabledListener(listener);
}

class _GateNotifier extends ChangeNotifier {
  bool wanted = true;

  void notify() => notifyListeners();
}
