import 'package:flutter/widgets.dart';

/// Provides a safe [setState] wrapper for async callbacks.
mixin MountedSetStateMixin<T extends StatefulWidget> on State<T> {
  void setStateIfMounted(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }
}
