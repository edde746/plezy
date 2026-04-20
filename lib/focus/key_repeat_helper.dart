import 'dart:async';

import 'package:flutter/widgets.dart';

/// Key-repeat timer for held dpad/keyboard inputs: fires immediately, then
/// every 100 ms after a 400 ms initial delay. Call [stopRepeat] in `dispose`.
mixin KeyRepeatHelper<T extends StatefulWidget> on State<T> {
  static const _initialDelay = Duration(milliseconds: 400);
  static const _repeatInterval = Duration(milliseconds: 100);

  Timer? _repeatTimer;

  void startRepeat(VoidCallback action) {
    action();
    _repeatTimer?.cancel();
    _repeatTimer = Timer(_initialDelay, () {
      _repeatTimer = Timer.periodic(_repeatInterval, (_) => action());
    });
  }

  void stopRepeat() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }
}
