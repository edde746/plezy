import 'dart:io' show Platform;

import 'package:flutter/services.dart';

import '../data/hid_key_labels.dart';

/// Modifier keys that can be combined with a primary key to form a hotkey.
///
/// Each value holds the physical keys that correspond to it (e.g. shift maps
/// to both shiftLeft and shiftRight). The [name] strings are used for
/// serialization and must stay stable across versions.
enum HotKeyModifier {
  alt([PhysicalKeyboardKey.altLeft, PhysicalKeyboardKey.altRight]),
  capsLock([PhysicalKeyboardKey.capsLock]),
  control([PhysicalKeyboardKey.controlLeft, PhysicalKeyboardKey.controlRight]),
  fn([PhysicalKeyboardKey.fn]),
  meta([PhysicalKeyboardKey.metaLeft, PhysicalKeyboardKey.metaRight]),
  shift([PhysicalKeyboardKey.shiftLeft, PhysicalKeyboardKey.shiftRight]);

  const HotKeyModifier(this.physicalKeys);

  final List<PhysicalKeyboardKey> physicalKeys;
}

/// A keyboard shortcut consisting of a primary [key] and optional [modifiers].
class HotKey {
  const HotKey({required this.key, this.modifiers});

  final PhysicalKeyboardKey key;
  final List<HotKeyModifier>? modifiers;
}

/// Whether to use macOS keyboard symbols.
final bool _isMacOS = Platform.isMacOS;

/// Human-readable label for a [PhysicalKeyboardKey].
///
/// On macOS, returns standard symbols (⌘, ⇧, ⌥, ⌃, ←, etc.).
/// Keyed by [PhysicalKeyboardKey.usbHidUsage] (an int) so maps can be const.
String physicalKeyLabel(PhysicalKeyboardKey key) {
  if (_isMacOS) {
    final macLabel = _macKeyLabels[key.usbHidUsage];
    if (macLabel != null) return macLabel;
  }
  return hidKeyLabels[key.usbHidUsage] ?? 'Key 0x${key.usbHidUsage.toRadixString(16).padLeft(8, '0')}';
}

/// macOS-specific overrides for keys that have standard symbols.
const _macKeyLabels = <int, String>{
  0x00070028: '\u21a9', // enter → ↩
  0x00070029: '\u238b', // escape → ⎋
  0x0007002a: '\u232b', // backspace → ⌫
  0x0007002b: '\u21e5', // tab → ⇥
  0x00070039: '\u21ea', // capsLock → ⇪
  0x0007004a: '\u2196', // home → ↖
  0x0007004b: '\u21de', // pageUp → ⇞
  0x0007004c: '\u2326', // delete → ⌦
  0x0007004d: '\u2198', // end → ↘
  0x0007004e: '\u21df', // pageDown → ⇟
  0x0007004f: '\u2192', // arrowRight → →
  0x00070050: '\u2190', // arrowLeft → ←
  0x00070051: '\u2193', // arrowDown → ↓
  0x00070052: '\u2191', // arrowUp → ↑
  0x000700e0: '\u2303', // controlLeft → ⌃
  0x000700e1: '\u21e7', // shiftLeft → ⇧
  0x000700e2: '\u2325', // altLeft (Option) → ⌥
  0x000700e3: '\u2318', // metaLeft (Command) → ⌘
  0x000700e4: '\u2303', // controlRight → ⌃
  0x000700e5: '\u21e7', // shiftRight → ⇧
  0x000700e6: '\u2325', // altRight (Option) → ⌥
  0x000700e7: '\u2318', // metaRight (Command) → ⌘
  0x00000012: 'fn', // fn
};
