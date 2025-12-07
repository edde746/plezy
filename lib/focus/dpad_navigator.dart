import 'package:flutter/services.dart';

/// Extension methods for checking D-pad related keys.
extension DpadKeyExtension on LogicalKeyboardKey {
  /// Whether this key is a D-pad directional key.
  bool get isDpadDirection {
    return this == LogicalKeyboardKey.arrowUp ||
        this == LogicalKeyboardKey.arrowDown ||
        this == LogicalKeyboardKey.arrowLeft ||
        this == LogicalKeyboardKey.arrowRight;
  }

  /// Whether this key is a select/activate key.
  bool get isSelectKey {
    return this == LogicalKeyboardKey.select ||
        this == LogicalKeyboardKey.enter ||
        this == LogicalKeyboardKey.numpadEnter ||
        this == LogicalKeyboardKey.gameButtonA;
  }

  /// Whether this key is a back/cancel key.
  bool get isBackKey {
    return this == LogicalKeyboardKey.escape ||
        this == LogicalKeyboardKey.goBack ||
        this == LogicalKeyboardKey.browserBack ||
        this == LogicalKeyboardKey.gameButtonB;
  }

  /// Whether this key is a context menu key.
  bool get isContextMenuKey {
    return this == LogicalKeyboardKey.contextMenu ||
        this == LogicalKeyboardKey.gameButtonX;
  }

  /// Whether this key moves focus left.
  bool get isLeftKey {
    return this == LogicalKeyboardKey.arrowLeft;
  }

  /// Whether this key moves focus right.
  bool get isRightKey {
    return this == LogicalKeyboardKey.arrowRight;
  }

  /// Whether this key moves focus up.
  bool get isUpKey {
    return this == LogicalKeyboardKey.arrowUp;
  }

  /// Whether this key moves focus down.
  bool get isDownKey {
    return this == LogicalKeyboardKey.arrowDown;
  }
}
