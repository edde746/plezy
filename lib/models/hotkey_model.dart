import 'package:flutter/services.dart';

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
  return _knownKeyLabels[key.usbHidUsage] ?? key.debugName ?? 'Unknown';
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

const _knownKeyLabels = <int, String>{
  0x00070004: 'A', // keyA
  0x00070005: 'B', // keyB
  0x00070006: 'C', // keyC
  0x00070007: 'D', // keyD
  0x00070008: 'E', // keyE
  0x00070009: 'F', // keyF
  0x0007000a: 'G', // keyG
  0x0007000b: 'H', // keyH
  0x0007000c: 'I', // keyI
  0x0007000d: 'J', // keyJ
  0x0007000e: 'K', // keyK
  0x0007000f: 'L', // keyL
  0x00070010: 'M', // keyM
  0x00070011: 'N', // keyN
  0x00070012: 'O', // keyO
  0x00070013: 'P', // keyP
  0x00070014: 'Q', // keyQ
  0x00070015: 'R', // keyR
  0x00070016: 'S', // keyS
  0x00070017: 'T', // keyT
  0x00070018: 'U', // keyU
  0x00070019: 'V', // keyV
  0x0007001a: 'W', // keyW
  0x0007001b: 'X', // keyX
  0x0007001c: 'Y', // keyY
  0x0007001d: 'Z', // keyZ
  0x0007001e: '1', // digit1
  0x0007001f: '2', // digit2
  0x00070020: '3', // digit3
  0x00070021: '4', // digit4
  0x00070022: '5', // digit5
  0x00070023: '6', // digit6
  0x00070024: '7', // digit7
  0x00070025: '8', // digit8
  0x00070026: '9', // digit9
  0x00070027: '0', // digit0
  0x00070028: 'Enter', // enter
  0x00070029: 'Escape', // escape
  0x0007002a: 'Backspace', // backspace
  0x0007002b: 'Tab', // tab
  0x0007002c: 'Space', // space
  0x0007002d: '=', // equal
  0x0007002e: '-', // minus
  0x0007002f: '[', // bracketLeft
  0x00070030: ']', // bracketRight
  0x00070031: r'\', // backslash
  0x00070033: ';', // semicolon
  0x00070034: "'", // quote
  0x00070035: '`', // backquote
  0x00070036: ',', // comma
  0x00070037: '.', // period
  0x00070038: '/', // slash
  0x00070039: 'CapsLock', // capsLock
  0x0007003a: 'F1',
  0x0007003b: 'F2',
  0x0007003c: 'F3',
  0x0007003d: 'F4',
  0x0007003e: 'F5',
  0x0007003f: 'F6',
  0x00070040: 'F7',
  0x00070041: 'F8',
  0x00070042: 'F9',
  0x00070043: 'F10',
  0x00070044: 'F11',
  0x00070045: 'F12',
  0x0007004a: 'Home', // home
  0x0007004b: 'Page Up', // pageUp
  0x0007004c: 'Delete', // delete
  0x0007004d: 'End', // end
  0x0007004e: 'Page Down', // pageDown
  0x0007004f: 'Arrow Right', // arrowRight
  0x00070050: 'Arrow Left', // arrowLeft
  0x00070051: 'Arrow Down', // arrowDown
  0x00070052: 'Arrow Up', // arrowUp
  0x000700e0: 'Ctrl', // controlLeft
  0x000700e1: 'Shift', // shiftLeft
  0x000700e2: 'Alt', // altLeft
  0x000700e3: 'Meta', // metaLeft
  0x000700e4: 'Ctrl', // controlRight
  0x000700e5: 'Shift', // shiftRight
  0x000700e6: 'Alt', // altRight
  0x000700e7: 'Meta', // metaRight
  0x00000012: 'Fn', // fn
};
