import 'package:flutter/foundation.dart';

/// Adds [safeNotifyListeners] which no-ops after [dispose]. Use in providers
/// that fire from async paths where a late callback could otherwise trip
/// Flutter's debug-only "used after dispose" assert.
mixin DisposableChangeNotifierMixin on ChangeNotifier {
  bool _disposed = false;

  bool get isDisposed => _disposed;

  bool safeNotifyListeners() {
    if (_disposed) return false;
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
