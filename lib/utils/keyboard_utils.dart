import 'package:flutter/services.dart';

/// Check if a logical key is a back navigation key
bool isBackKey(LogicalKeyboardKey key) {
  return key == LogicalKeyboardKey.escape ||
      key == LogicalKeyboardKey.backspace ||
      key == LogicalKeyboardKey.goBack ||
      key == LogicalKeyboardKey.gameButtonB;
}

/// Check if a key event is a back navigation key down event
bool isBackKeyEvent(KeyEvent event) {
  if (event is! KeyDownEvent) return false;
  return isBackKey(event.logicalKey);
}
