import 'dart:io' show Platform;

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
  return _keyLabels[key.usbHidUsage] ?? 'Unknown';
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

/// Comprehensive key labels sourced from Flutter's PhysicalKeyboardKey._debugNames
/// (keyboard_key.g.dart, USB HID keyboard usage page 0x0007).
/// Common keys use short curated labels; the rest use Flutter's default names.
const _keyLabels = <int, String>{
  // Letters
  0x00070004: 'A',
  0x00070005: 'B',
  0x00070006: 'C',
  0x00070007: 'D',
  0x00070008: 'E',
  0x00070009: 'F',
  0x0007000a: 'G',
  0x0007000b: 'H',
  0x0007000c: 'I',
  0x0007000d: 'J',
  0x0007000e: 'K',
  0x0007000f: 'L',
  0x00070010: 'M',
  0x00070011: 'N',
  0x00070012: 'O',
  0x00070013: 'P',
  0x00070014: 'Q',
  0x00070015: 'R',
  0x00070016: 'S',
  0x00070017: 'T',
  0x00070018: 'U',
  0x00070019: 'V',
  0x0007001a: 'W',
  0x0007001b: 'X',
  0x0007001c: 'Y',
  0x0007001d: 'Z',
  // Digits
  0x0007001e: '1',
  0x0007001f: '2',
  0x00070020: '3',
  0x00070021: '4',
  0x00070022: '5',
  0x00070023: '6',
  0x00070024: '7',
  0x00070025: '8',
  0x00070026: '9',
  0x00070027: '0',
  // Special keys
  0x00070028: 'Enter',
  0x00070029: 'Escape',
  0x0007002a: 'Backspace',
  0x0007002b: 'Tab',
  0x0007002c: 'Space',
  // Symbols
  0x0007002d: '-',
  0x0007002e: '=',
  0x0007002f: '[',
  0x00070030: ']',
  0x00070031: r'\',
  0x00070033: ';',
  0x00070034: "'",
  0x00070035: '`',
  0x00070036: ',',
  0x00070037: '.',
  0x00070038: '/',
  // Lock & function keys
  0x00070039: 'Caps Lock',
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
  0x00070046: 'Print Screen',
  0x00070047: 'Scroll Lock',
  0x00070048: 'Pause',
  0x00070049: 'Insert',
  // Navigation
  0x0007004a: 'Home',
  0x0007004b: 'Page Up',
  0x0007004c: 'Delete',
  0x0007004d: 'End',
  0x0007004e: 'Page Down',
  0x0007004f: 'Arrow Right',
  0x00070050: 'Arrow Left',
  0x00070051: 'Arrow Down',
  0x00070052: 'Arrow Up',
  // Numpad
  0x00070053: 'Num Lock',
  0x00070054: 'Numpad /',
  0x00070055: 'Numpad *',
  0x00070056: 'Numpad -',
  0x00070057: 'Numpad +',
  0x00070058: 'Numpad Enter',
  0x00070059: 'Numpad 1',
  0x0007005a: 'Numpad 2',
  0x0007005b: 'Numpad 3',
  0x0007005c: 'Numpad 4',
  0x0007005d: 'Numpad 5',
  0x0007005e: 'Numpad 6',
  0x0007005f: 'Numpad 7',
  0x00070060: 'Numpad 8',
  0x00070061: 'Numpad 9',
  0x00070062: 'Numpad 0',
  0x00070063: 'Numpad .',
  0x00070064: 'Intl Backslash',
  0x00070065: 'Context Menu',
  0x00070066: 'Power',
  0x00070067: 'Numpad =',
  // Extended function keys
  0x00070068: 'F13',
  0x00070069: 'F14',
  0x0007006a: 'F15',
  0x0007006b: 'F16',
  0x0007006c: 'F17',
  0x0007006d: 'F18',
  0x0007006e: 'F19',
  0x0007006f: 'F20',
  0x00070070: 'F21',
  0x00070071: 'F22',
  0x00070072: 'F23',
  0x00070073: 'F24',
  // Editing
  0x00070074: 'Open',
  0x00070075: 'Help',
  0x00070077: 'Select',
  0x00070079: 'Again',
  0x0007007a: 'Undo',
  0x0007007b: 'Cut',
  0x0007007c: 'Copy',
  0x0007007d: 'Paste',
  0x0007007e: 'Find',
  // Audio
  0x0007007f: 'Volume Mute',
  0x00070080: 'Volume Up',
  0x00070081: 'Volume Down',
  // Numpad extras
  0x00070085: 'Numpad ,',
  // International
  0x00070087: 'Intl Ro',
  0x00070088: 'Kana Mode',
  0x00070089: 'Intl Yen',
  0x0007008a: 'Convert',
  0x0007008b: 'Non Convert',
  0x00070090: 'Lang 1',
  0x00070091: 'Lang 2',
  0x00070092: 'Lang 3',
  0x00070093: 'Lang 4',
  0x00070094: 'Lang 5',
  0x0007009b: 'Abort',
  0x000700a3: 'Props',
  // Numpad advanced
  0x000700b6: 'Numpad (',
  0x000700b7: 'Numpad )',
  0x000700bb: 'Numpad Backspace',
  0x000700d0: 'Numpad Memory Store',
  0x000700d1: 'Numpad Memory Recall',
  0x000700d2: 'Numpad Memory Clear',
  0x000700d3: 'Numpad Memory Add',
  0x000700d4: 'Numpad Memory Subtract',
  0x000700d7: 'Numpad Sign Change',
  0x000700d8: 'Numpad Clear',
  0x000700d9: 'Numpad Clear Entry',
  // Modifiers
  0x000700e0: 'Ctrl',
  0x000700e1: 'Shift',
  0x000700e2: 'Alt',
  0x000700e3: 'Meta',
  0x000700e4: 'Ctrl',
  0x000700e5: 'Shift',
  0x000700e6: 'Alt',
  0x000700e7: 'Meta',
  // Fn
  0x00000012: 'Fn',
};
