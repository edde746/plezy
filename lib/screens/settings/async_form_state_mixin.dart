import 'package:flutter/widgets.dart';

import '../../utils/app_logger.dart';

/// Mixin for stateful screens that wrap their async work in a busy + error
/// scaffolding. Exposes [busy] and [errorText] state plus a [runAsync] helper
/// that clears the prior error, sets busy, runs the body, captures any
/// exception via an optional [errorMapper], and clears busy in `finally` —
/// all mounted-guarded.
///
/// Mid-flow state changes (e.g. clearing busy *before* the body finishes so
/// the UI can swap into a "waiting" panel) are still possible via [setBusy]
/// from inside the [runAsync] body — the `finally` clears busy idempotently.
///
/// [runAsync] calls must be sequenced, never overlapped: there is a single
/// busy flag, so the first call to finish clears it while the other is still
/// running. Don't start a second runAsync (or fire one with `unawaited`)
/// while another that can still apply state is in flight — debug-asserted,
/// and the overlapping call is refused (returns null) in release so it can't
/// corrupt the busy flag.
/// Overlapping a *stale* run whose [runAsync]'s `shouldApplyState` has gone
/// false (e.g. a cancelled poll unwinding) is fine; it no longer touches busy.
mixin AsyncFormStateMixin<T extends StatefulWidget> on State<T> {
  bool _busy = false;
  String? _errorText;
  final List<bool Function()> _activeRunAsyncGuards = [];

  bool get busy => _busy;
  String? get errorText => _errorText;

  /// Set busy without forcing a setState when the value didn't change.
  void setBusy(bool value) {
    if (!mounted || _busy == value) return;
    setState(() => _busy = value);
  }

  /// Set the error text directly (e.g. for synchronous validation failures
  /// or post-success rejections like a duplicate-account guard).
  void setErrorText(String? value) {
    if (!mounted || _errorText == value) return;
    setState(() => _errorText = value);
  }

  /// Run [body] surrounded by busy/error scaffolding. Returns the body's
  /// value, or `null` if the widget unmounted, the body threw, or the
  /// errorMapper translated the exception.
  Future<R?> runAsync<R>(
    Future<R> Function() body, {
    String Function(Object error)? errorMapper,
    bool Function()? shouldApplyState,
  }) async {
    bool canApplyState() => mounted && (shouldApplyState?.call() ?? true);
    if (!canApplyState()) return null;
    if (_activeRunAsyncGuards.any((stillApplies) => stillApplies())) {
      assert(
        false,
        'runAsync overlapped with another runAsync that can still apply state: '
        'the first to finish clears busy out from under the other. Sequence the '
        'calls (await the first) instead of nesting or unawaiting them.',
      );
      appLogger.w('runAsync overlapped with an active run; ignoring this call');
      return null;
    }
    _activeRunAsyncGuards.add(canApplyState);
    setState(() {
      _busy = true;
      _errorText = null;
    });
    try {
      return await body();
    } catch (e) {
      if (canApplyState()) {
        setState(() => _errorText = errorMapper?.call(e) ?? e.toString());
      }
      return null;
    } finally {
      _activeRunAsyncGuards.remove(canApplyState);
      if (canApplyState()) setState(() => _busy = false);
    }
  }
}
