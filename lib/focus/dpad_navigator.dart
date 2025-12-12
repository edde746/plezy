import 'package:flutter/services.dart';

/// Shared sets for keyboard key categories.
final _dpadDirectionKeys = {
  LogicalKeyboardKey.arrowUp,
  LogicalKeyboardKey.arrowDown,
  LogicalKeyboardKey.arrowLeft,
  LogicalKeyboardKey.arrowRight,
};

final _selectKeys = {
  LogicalKeyboardKey.select,
  LogicalKeyboardKey.enter,
  LogicalKeyboardKey.numpadEnter,
  LogicalKeyboardKey.gameButtonA,
};

final _backKeys = {
  LogicalKeyboardKey.escape,
  LogicalKeyboardKey.goBack,
  LogicalKeyboardKey.browserBack,
  LogicalKeyboardKey.gameButtonB,
};

final _contextMenuKeys = {
  LogicalKeyboardKey.contextMenu,
  LogicalKeyboardKey.gameButtonX,
};

/// Extension methods for checking D-pad related keys.
extension DpadKeyExtension on LogicalKeyboardKey {
  /// Whether this key is a D-pad directional key.
  bool get isDpadDirection => _dpadDirectionKeys.contains(this);

  /// Whether this key is a select/activate key.
  bool get isSelectKey => _selectKeys.contains(this);

  /// Whether this key is a back/cancel key.
  bool get isBackKey => _backKeys.contains(this);

  /// Whether this key is a context menu key.
  bool get isContextMenuKey => _contextMenuKeys.contains(this);

  /// Whether this key moves focus left.
  bool get isLeftKey => this == LogicalKeyboardKey.arrowLeft;

  /// Whether this key moves focus right.
  bool get isRightKey => this == LogicalKeyboardKey.arrowRight;

  /// Whether this key moves focus up.
  bool get isUpKey => this == LogicalKeyboardKey.arrowUp;

  /// Whether this key moves focus down.
  bool get isDownKey => this == LogicalKeyboardKey.arrowDown;
}
