import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'back_press.dart';
import 'dpad_navigator.dart';

/// Turns a Back key press that no focused owner consumed into
/// `Navigator.maybePop` on [navigatorKey], so key back and system back both end
/// in the route's `PopScope`.
///
/// Wrap each [Navigator] (root and profile session) once. The wrapper sits in
/// the focus chain above every route of that navigator, so it sees only the
/// presses that bubbled out of the focused subtree. It decides on KeyDown, from
/// the route's synchronous [ModalRoute.popDisposition], whether this navigator
/// owns the press:
///
/// * `pop` / `doNotPop` — a route below or a `PopScope(canPop: false)`: the
///   press is consumed and `maybePop` runs on the configured [BackPhase].
/// * `bubble` — nothing to pop and no `PopScope`: the press is declined, both
///   KeyDown and KeyUp bubble on. On Android an unhandled Back becomes the
///   platform's own `onBackPressed` → `popRoute` → `SystemNavigator.pop`, which
///   is the correct "leave the app" behavior at the true root.
///
/// A KeyUp or KeyRepeat that arrives with no armed press — the press acted on
/// another focus chain before focus moved here — is swallowed. Letting it reach
/// the platform unhandled would synthesize a second, system-driven back.
class NavigatorBackHandler extends StatefulWidget {
  const NavigatorBackHandler({super.key, required this.navigatorKey, required this.child});

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<NavigatorBackHandler> createState() => _NavigatorBackHandlerState();
}

/// What this navigator does with the Back press whose KeyDown just arrived.
enum _Claim {
  /// Consume the press and run `maybePop` on the configured phase.
  pop,

  /// Consume the press and do nothing: the focused route is not the current
  /// one. A route was just pushed and the new route's autofocus has not been
  /// applied yet (FocusManager applies it in a microtask), so the old chain
  /// still receives keys; `maybePop` would pop the route that was just pushed.
  swallow,

  /// Leave both events to the platform: nothing to pop and no `PopScope`.
  decline,
}

class _NavigatorBackHandlerState extends State<NavigatorBackHandler> {
  final BackPressGate _gate = BackPressGate();
  bool _declined = false;

  /// The route of this navigator that contains the primary focus, walking out
  /// of nested navigators. Null when the focus is not inside any route of this
  /// navigator (e.g. chrome mounted beside the navigator).
  ModalRoute<Object?>? _routeForPrimaryFocus() {
    final navigator = widget.navigatorKey.currentState;
    if (navigator == null) return null;
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) return null;
    var route = ModalRoute.of(context);
    while (route != null && !identical(route.navigator, navigator)) {
      final navigatorContext = route.navigator?.context;
      if (navigatorContext == null) return null;
      route = ModalRoute.of(navigatorContext);
    }
    return route;
  }

  _Claim _claimForPrimaryFocus() {
    final route = _routeForPrimaryFocus();
    if (route == null) return _Claim.decline;
    if (!route.isCurrent) return _Claim.swallow;
    return route.popDisposition == RoutePopDisposition.bubble ? _Claim.decline : _Claim.pop;
  }

  void _pop() {
    unawaited(widget.navigatorKey.currentState?.maybePop());
  }

  static void _noop() {}

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!event.logicalKey.isBackKey) return KeyEventResult.ignored;

    if (event is KeyDownEvent) {
      switch (_claimForPrimaryFocus()) {
        case _Claim.decline:
          _declined = true;
          _gate.reset();
          return KeyEventResult.ignored;
        case _Claim.swallow:
          _declined = false;
          return _gate.handle(event, _noop, phase: BackPhase.keyDown);
        case _Claim.pop:
          _declined = false;
          return _gate.handle(event, _pop);
      }
    }

    if (_declined) {
      if (event is KeyUpEvent) _declined = false;
      return KeyEventResult.ignored;
    }

    // An armed press acts (or, already acted on KeyDown, is finished); an
    // unarmed KeyUp/KeyRepeat acted on another focus chain and is swallowed.
    final result = _gate.handle(event, _pop);
    return result == KeyEventResult.ignored ? KeyEventResult.handled : result;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      debugLabel: 'NavigatorBackHandler',
      onKeyEvent: _handleKeyEvent,
      child: widget.child,
    );
  }
}
