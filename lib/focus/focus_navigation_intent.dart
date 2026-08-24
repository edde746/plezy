import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../utils/platform_detector.dart';
import 'dpad_navigator.dart';

/// A [FocusNode] whose owner consumes arrow / D-pad keys itself instead of
/// letting them traverse focus — the video player seeks with them.
///
/// Focus-mode detection needs this fact: an arrow pressed while such a node
/// holds focus is not evidence that the viewer wants to navigate by focus, so
/// it must not switch the app into keyboard mode and light up focus chrome
/// everywhere.
///
/// The fact rides on the node rather than on a subtree because it depends on
/// *what has focus*, not on where a widget sits. Every ordinary control, sheet,
/// prompt and OSD button therefore stays a plain [FocusNode] and keeps working.
///
/// Declare a node only when it can hold primary focus **without the viewer
/// having navigated to it** — autofocus, a focus reclaim, a self-heal.
/// Everything reached by traversal is already in keyboard mode, so the marker
/// would be redundant there: sliders, spinners, the TV keyboard and the OSD's
/// own buttons all consume arrows and all correctly stay plain nodes.
class DirectionalShortcutFocusNode extends FocusNode {
  DirectionalShortcutFocusNode({required this.consumesDirectionalKeys, super.debugLabel, super.skipTraversal});

  /// Evaluated per key press, so live settings and chrome state need no
  /// syncing. Takes the key because a feature can own one axis and not the
  /// other — the player seeks with Left/Right while Up/Down raises the chrome.
  final bool Function(LogicalKeyboardKey key) consumesDirectionalKeys;

  static bool ownsDirectionalKeys(FocusNode? node, LogicalKeyboardKey key) =>
      node is DirectionalShortcutFocusNode && node.consumesDirectionalKeys(key);
}

/// Whether [event] is evidence that the viewer wants to navigate by focus.
///
/// This is the single answer to two questions that must never disagree:
/// whether [InputModeTracker] switches to keyboard mode, and whether a key may
/// hand focus to the video player's chrome. Deciding them separately is what
/// produced focus appearing on a control while the app still believed a pointer
/// was driving — focus chrome is mode-gated, so the viewer got an invisible
/// selection.
///
/// Activation (Enter) and dismissal (Escape) from a physical keyboard are *not*
/// navigation: they act on whatever already has focus. Promoting on them arms
/// focus chrome — and hides the desktop cursor — for a viewer who only pressed
/// play.
///
/// [focused] is the node that will receive the event; it defaults to the
/// primary focus. Handlers inside a `Focus.onKeyEvent` pass their own node
/// instead of re-reading the global.
bool eventRequestsFocusNavigation(KeyEvent event, {FocusNode? focused}) {
  if (event is! KeyDownEvent) return false;
  final key = event.logicalKey;

  // Unambiguous traversal on every platform.
  if (key == LogicalKeyboardKey.tab) return true;

  // Opens a menu that takes focus into a new scope, so it does start a session.
  if (key.isContextMenuKey) return true;

  // `select` / `gameButtonA` are remote-only whatever the engine claims about
  // deviceType; `enter` counts from a non-keyboard device, or on TV where a
  // remote's OK legitimately arrives as a keyboard `enter` (the same shape
  // pin_entry_dialog.dart already compensates for).
  if (key.isSelectKey) {
    return event.isTvSelectEvent || (PlatformDetector.isTV() && event.isPhysicalKeyboardEnter);
  }

  // Remote BACK proves a pointerless device. A physical keyboard's `escape` and
  // a media keyboard's `browserBack` only dismiss, so they stay out — matching
  // how classifyPlayerNavigationKey already reads a non-keyboard `escape`.
  if (key.isBackKey) {
    return key == LogicalKeyboardKey.goBack || key == LogicalKeyboardKey.gameButtonB || !event.isPhysicalKeyboardEvent;
  }

  // Arrows are navigation only where they are not the focused feature's own
  // shortcut.
  if (key.isDpadDirection) {
    return !DirectionalShortcutFocusNode.ownsDirectionalKeys(focused ?? FocusManager.instance.primaryFocus, key);
  }

  return false;
}
