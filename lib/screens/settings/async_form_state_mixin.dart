import 'package:flutter/widgets.dart';

/// Mixin for stateful screens that wrap their async work in a busy + error
/// scaffolding. Exposes [busy] and [errorText] state plus a [runAsync] helper
/// that clears the prior error, sets busy, runs the body, captures any
/// exception via an optional [errorMapper], and clears busy in `finally` —
/// all mounted-guarded.
///
/// Mid-flow state changes (e.g. clearing busy *before* the body finishes so
/// the UI can swap into a "waiting" panel) are still possible via [setBusy]
/// from inside the [runAsync] body — the `finally` clears busy idempotently.
mixin AsyncFormStateMixin<T extends StatefulWidget> on State<T> {
  bool _busy = false;
  String? _errorText;

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
      if (canApplyState()) setState(() => _busy = false);
    }
  }
}
