import 'dart:async';

import 'package:flutter/foundation.dart';

/// Trailing-edge debouncer: [run] (re)starts the timer; only the last action
/// within [delay] executes. Call [dispose] from the owning State's dispose.
class Debouncer {
  Debouncer(this.delay);

  final Duration delay;
  Timer? _timer;

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() => _timer?.cancel();

  void dispose() => cancel();
}
