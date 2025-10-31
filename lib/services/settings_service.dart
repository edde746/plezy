import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

enum ThemeMode { system, light, dark }

class SettingsService {
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyEnableDebugLogging = 'enable_debug_logging';
  static const String _keyVideoBufferSize = 'video_buffer_size';
  static const String _keyAudioBufferSize = 'audio_buffer_size';
  static const String _keyKeyboardShortcuts = 'keyboard_shortcuts';
  static const String _keyKeyboardHotkeys = 'keyboard_hotkeys';
  static const String _keyEnableHardwareDecoding = 'enable_hardware_decoding';
  static const String _keyPreferredVideoCodec = 'preferred_video_codec';
  static const String _keyPreferredAudioCodec = 'preferred_audio_codec';

  static SettingsService? _instance;
  late SharedPreferences _prefs;

  SettingsService._();

  static Future<SettingsService> getInstance() async {
    if (_instance == null) {
      _instance = SettingsService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Theme Mode
  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_keyThemeMode, mode.name);
  }

  ThemeMode getThemeMode() {
    final modeString = _prefs.getString(_keyThemeMode);
    return ThemeMode.values
        .firstWhere((mode) => mode.name == modeString, orElse: () => ThemeMode.system);
  }


  // Debug Logging
  Future<void> setEnableDebugLogging(bool enabled) async {
    await _prefs.setBool(_keyEnableDebugLogging, enabled);
  }

  bool getEnableDebugLogging() {
    return _prefs.getBool(_keyEnableDebugLogging) ?? false;
  }

  // Video Buffer Size (in MB)
  Future<void> setVideoBufferSize(int sizeInMB) async {
    await _prefs.setInt(_keyVideoBufferSize, sizeInMB);
  }

  int getVideoBufferSize() {
    return _prefs.getInt(_keyVideoBufferSize) ?? 64; // Default 64MB
  }

  // Audio Buffer Size (in MB)
  Future<void> setAudioBufferSize(int sizeInMB) async {
    await _prefs.setInt(_keyAudioBufferSize, sizeInMB);
  }

  int getAudioBufferSize() {
    return _prefs.getInt(_keyAudioBufferSize) ?? 8; // Default 8MB
  }

  // Hardware Decoding
  Future<void> setEnableHardwareDecoding(bool enabled) async {
    await _prefs.setBool(_keyEnableHardwareDecoding, enabled);
  }

  bool getEnableHardwareDecoding() {
    return _prefs.getBool(_keyEnableHardwareDecoding) ?? true; // Default enabled
  }

  // Preferred Video Codec
  Future<void> setPreferredVideoCodec(String codec) async {
    await _prefs.setString(_keyPreferredVideoCodec, codec);
  }

  String getPreferredVideoCodec() {
    return _prefs.getString(_keyPreferredVideoCodec) ?? 'auto';
  }

  // Preferred Audio Codec
  Future<void> setPreferredAudioCodec(String codec) async {
    await _prefs.setString(_keyPreferredAudioCodec, codec);
  }

  String getPreferredAudioCodec() {
    return _prefs.getString(_keyPreferredAudioCodec) ?? 'auto';
  }

  // Keyboard Shortcuts (Legacy String-based)
  Map<String, String> getDefaultKeyboardShortcuts() {
    return {
      'play_pause': 'Space',
      'volume_up': 'Arrow Up',
      'volume_down': 'Arrow Down',
      'seek_forward': 'Arrow Right',
      'seek_backward': 'Arrow Left',
      'seek_forward_large': 'Shift+Arrow Right',
      'seek_backward_large': 'Shift+Arrow Left',
      'fullscreen_toggle': 'F',
      'mute_toggle': 'M',
      'subtitle_toggle': 'S',
      'audio_track_next': 'A',
      'subtitle_track_next': 'Shift+S',
      'chapter_next': 'N',
      'chapter_previous': 'P',
      'speed_increase': 'Plus',
      'speed_decrease': 'Minus',
      'speed_reset': 'R',
    };
  }

  // HotKey Objects (New implementation)
  Map<String, HotKey> getDefaultKeyboardHotkeys() {
    return {
      'play_pause': HotKey(key: PhysicalKeyboardKey.space),
      'volume_up': HotKey(key: PhysicalKeyboardKey.arrowUp),
      'volume_down': HotKey(key: PhysicalKeyboardKey.arrowDown),
      'seek_forward': HotKey(key: PhysicalKeyboardKey.arrowRight),
      'seek_backward': HotKey(key: PhysicalKeyboardKey.arrowLeft),
      'seek_forward_large': HotKey(key: PhysicalKeyboardKey.arrowRight, modifiers: [HotKeyModifier.shift]),
      'seek_backward_large': HotKey(key: PhysicalKeyboardKey.arrowLeft, modifiers: [HotKeyModifier.shift]),
      'fullscreen_toggle': HotKey(key: PhysicalKeyboardKey.keyF),
      'mute_toggle': HotKey(key: PhysicalKeyboardKey.keyM),
      'subtitle_toggle': HotKey(key: PhysicalKeyboardKey.keyS),
      'audio_track_next': HotKey(key: PhysicalKeyboardKey.keyA),
      'subtitle_track_next': HotKey(key: PhysicalKeyboardKey.keyS, modifiers: [HotKeyModifier.shift]),
      'chapter_next': HotKey(key: PhysicalKeyboardKey.keyN),
      'chapter_previous': HotKey(key: PhysicalKeyboardKey.keyP),
      'speed_increase': HotKey(key: PhysicalKeyboardKey.equal),
      'speed_decrease': HotKey(key: PhysicalKeyboardKey.minus),
      'speed_reset': HotKey(key: PhysicalKeyboardKey.keyR),
    };
  }

  Future<void> setKeyboardShortcuts(Map<String, String> shortcuts) async {
    final jsonString = json.encode(shortcuts);
    await _prefs.setString(_keyKeyboardShortcuts, jsonString);
  }

  Map<String, String> getKeyboardShortcuts() {
    final jsonString = _prefs.getString(_keyKeyboardShortcuts);
    if (jsonString == null) return getDefaultKeyboardShortcuts();

    try {
      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      final shortcuts = decoded.map((key, value) => MapEntry(key, value.toString()));

      // Merge with defaults to ensure all keys exist
      final defaults = getDefaultKeyboardShortcuts();
      defaults.addAll(shortcuts);
      return defaults;
    } catch (e) {
      return getDefaultKeyboardShortcuts();
    }
  }

  Future<void> setKeyboardShortcut(String action, String key) async {
    final shortcuts = getKeyboardShortcuts();
    shortcuts[action] = key;
    await setKeyboardShortcuts(shortcuts);
  }

  String getKeyboardShortcut(String action) {
    final shortcuts = getKeyboardShortcuts();
    return shortcuts[action] ?? '';
  }

  Future<void> resetKeyboardShortcuts() async {
    await setKeyboardShortcuts(getDefaultKeyboardShortcuts());
  }

  // HotKey Objects Methods
  Future<void> setKeyboardHotkeys(Map<String, HotKey> hotkeys) async {
    final Map<String, Map<String, dynamic>> serializedHotkeys = {};
    for (final entry in hotkeys.entries) {
      serializedHotkeys[entry.key] = _serializeHotKey(entry.value);
    }
    final jsonString = json.encode(serializedHotkeys);
    await _prefs.setString(_keyKeyboardHotkeys, jsonString);
  }

  Future<Map<String, HotKey>> getKeyboardHotkeys() async {
    final jsonString = _prefs.getString(_keyKeyboardHotkeys);
    if (jsonString == null) {
      return getDefaultKeyboardHotkeys();
    }

    try {
      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      final Map<String, HotKey> hotkeys = {};

      for (final entry in decoded.entries) {
        final hotKey = _deserializeHotKey(entry.value as Map<String, dynamic>);
        if (hotKey != null) {
          hotkeys[entry.key] = hotKey;
        }
      }

      // Merge with defaults to ensure all keys exist, but keep saved hotkeys priority
      final defaults = getDefaultKeyboardHotkeys();
      final result = <String, HotKey>{};

      // Start with defaults
      result.addAll(defaults);
      // Override with saved hotkeys (this preserves user customizations)
      result.addAll(hotkeys);

      return result;
    } catch (e) {
      return getDefaultKeyboardHotkeys();
    }
  }

  Future<void> setKeyboardHotkey(String action, HotKey hotKey) async {
    final hotkeys = await getKeyboardHotkeys();
    hotkeys[action] = hotKey;
    await setKeyboardHotkeys(hotkeys);
  }

  Future<HotKey?> getKeyboardHotkey(String action) async {
    final hotkeys = await getKeyboardHotkeys();
    return hotkeys[action];
  }

  Future<void> resetKeyboardHotkeys() async {
    await setKeyboardHotkeys(getDefaultKeyboardHotkeys());
  }

  // Helper methods for HotKey serialization
  Map<String, dynamic> _serializeHotKey(HotKey hotKey) {
    return {
      'key': hotKey.key.toString(),
      'modifiers': hotKey.modifiers?.map((m) => m.name).toList() ?? [],
    };
  }

  HotKey? _deserializeHotKey(Map<String, dynamic> data) {
    try {
      final keyString = data['key'] as String;
      final modifierNames = (data['modifiers'] as List<dynamic>).cast<String>();

      final modifiers = modifierNames.map((name) {
        switch (name) {
          case 'alt':
            return HotKeyModifier.alt;
          case 'control':
            return HotKeyModifier.control;
          case 'shift':
            return HotKeyModifier.shift;
          case 'meta':
            return HotKeyModifier.meta;
          case 'capsLock':
            return HotKeyModifier.capsLock;
          case 'fn':
            return HotKeyModifier.fn;
          default:
            return null;
        }
      }).where((m) => m != null).cast<HotKeyModifier>().toList();

      final key = _findKeyByString(keyString);
      if (key != null) {
        return HotKey(key: key, modifiers: modifiers.isNotEmpty ? modifiers : null);
      }
    } catch (e) {
      // Ignore deserialization errors
    }
    return null;
  }

  // Helper method to find PhysicalKeyboardKey by string representation
  PhysicalKeyboardKey? _findKeyByString(String keyString) {

    // Handle exact string matches first for better performance
    const keyMap = {
      'PhysicalKeyboardKey#0002c': PhysicalKeyboardKey.space,
      'PhysicalKeyboardKey#7002a': PhysicalKeyboardKey.backspace,
      'PhysicalKeyboardKey#7004c': PhysicalKeyboardKey.delete,
      'PhysicalKeyboardKey#70028': PhysicalKeyboardKey.enter,
      'PhysicalKeyboardKey#70029': PhysicalKeyboardKey.escape,
      'PhysicalKeyboardKey#7002b': PhysicalKeyboardKey.tab,
      'PhysicalKeyboardKey#7004a': PhysicalKeyboardKey.home,
      'PhysicalKeyboardKey#7004d': PhysicalKeyboardKey.end,
      'PhysicalKeyboardKey#7004b': PhysicalKeyboardKey.pageUp,
      'PhysicalKeyboardKey#7004e': PhysicalKeyboardKey.pageDown,
      'PhysicalKeyboardKey#70050': PhysicalKeyboardKey.arrowLeft,
      'PhysicalKeyboardKey#70052': PhysicalKeyboardKey.arrowUp,
      'PhysicalKeyboardKey#7004f': PhysicalKeyboardKey.arrowRight,
      'PhysicalKeyboardKey#70051': PhysicalKeyboardKey.arrowDown,
    };

    // Check exact matches first
    if (keyMap.containsKey(keyString)) {
      return keyMap[keyString];
    }

    // Alternative approach: extract USB HID usage code from the toString() output
    // Format: PhysicalKeyboardKey#ec9ed(usbHidUsage: "0x0007002c", debugName: "Space")
    try {
      final usbHidMatch = RegExp(r'usbHidUsage: "0x([0-9a-fA-F]+)"').firstMatch(keyString);
      if (usbHidMatch != null) {
        final usbHidCode = usbHidMatch.group(1)!.toLowerCase();

        // Map USB HID codes to PhysicalKeyboardKey objects
        const usbHidMap = {
          '0007002c': PhysicalKeyboardKey.space,
          '0007002a': PhysicalKeyboardKey.backspace,
          '0007004c': PhysicalKeyboardKey.delete,
          '00070028': PhysicalKeyboardKey.enter,
          '00070029': PhysicalKeyboardKey.escape,
          '0007002b': PhysicalKeyboardKey.tab,
          '00070039': PhysicalKeyboardKey.capsLock,
          // Function keys
          '0007003a': PhysicalKeyboardKey.f1,
          '0007003b': PhysicalKeyboardKey.f2,
          '0007003c': PhysicalKeyboardKey.f3,
          '0007003d': PhysicalKeyboardKey.f4,
          '0007003e': PhysicalKeyboardKey.f5,
          '0007003f': PhysicalKeyboardKey.f6,
          '00070040': PhysicalKeyboardKey.f7,
          '00070041': PhysicalKeyboardKey.f8,
          '00070042': PhysicalKeyboardKey.f9,
          '00070043': PhysicalKeyboardKey.f10,
          '00070044': PhysicalKeyboardKey.f11,
          '00070045': PhysicalKeyboardKey.f12,
          // Number keys
          '00070027': PhysicalKeyboardKey.digit0,
          '0007001e': PhysicalKeyboardKey.digit1,
          '0007001f': PhysicalKeyboardKey.digit2,
          '00070020': PhysicalKeyboardKey.digit3,
          '00070021': PhysicalKeyboardKey.digit4,
          '00070022': PhysicalKeyboardKey.digit5,
          '00070023': PhysicalKeyboardKey.digit6,
          '00070024': PhysicalKeyboardKey.digit7,
          '00070025': PhysicalKeyboardKey.digit8,
          '00070026': PhysicalKeyboardKey.digit9,
          // Letter keys
          '00070004': PhysicalKeyboardKey.keyA,
          '00070005': PhysicalKeyboardKey.keyB,
          '00070006': PhysicalKeyboardKey.keyC,
          '00070007': PhysicalKeyboardKey.keyD,
          '00070008': PhysicalKeyboardKey.keyE,
          '00070009': PhysicalKeyboardKey.keyF,
          '0007000a': PhysicalKeyboardKey.keyG,
          '0007000b': PhysicalKeyboardKey.keyH,
          '0007000c': PhysicalKeyboardKey.keyI,
          '0007000d': PhysicalKeyboardKey.keyJ,
          '0007000e': PhysicalKeyboardKey.keyK,
          '0007000f': PhysicalKeyboardKey.keyL,
          '00070010': PhysicalKeyboardKey.keyM,
          '00070011': PhysicalKeyboardKey.keyN,
          '00070012': PhysicalKeyboardKey.keyO,
          '00070013': PhysicalKeyboardKey.keyP,
          '00070014': PhysicalKeyboardKey.keyQ,
          '00070015': PhysicalKeyboardKey.keyR,
          '00070016': PhysicalKeyboardKey.keyS,
          '00070017': PhysicalKeyboardKey.keyT,
          '00070018': PhysicalKeyboardKey.keyU,
          '00070019': PhysicalKeyboardKey.keyV,
          '0007001a': PhysicalKeyboardKey.keyW,
          '0007001b': PhysicalKeyboardKey.keyX,
          '0007001c': PhysicalKeyboardKey.keyY,
          '0007001d': PhysicalKeyboardKey.keyZ,
          // Arrow keys
          '00070050': PhysicalKeyboardKey.arrowLeft,
          '00070052': PhysicalKeyboardKey.arrowUp,
          '0007004f': PhysicalKeyboardKey.arrowRight,
          '00070051': PhysicalKeyboardKey.arrowDown,
          // Other common keys
          '0007002d': PhysicalKeyboardKey.equal,
          '0007002e': PhysicalKeyboardKey.minus,
          '0007004a': PhysicalKeyboardKey.home,
          '0007004d': PhysicalKeyboardKey.end,
          '0007004b': PhysicalKeyboardKey.pageUp,
          '0007004e': PhysicalKeyboardKey.pageDown,
        };

        if (usbHidMap.containsKey(usbHidCode)) {
          return usbHidMap[usbHidCode];
        }
      }
    } catch (e) {
      // Ignore parsing errors
    }

    // Fall back to contains() checks for partial matches
    if (keyString.contains('space')) {
      return PhysicalKeyboardKey.space;
    } else if (keyString.contains('arrowUp')) {
      return PhysicalKeyboardKey.arrowUp;
    } else if (keyString.contains('arrowDown')) {
      return PhysicalKeyboardKey.arrowDown;
    } else if (keyString.contains('arrowLeft')) {
      return PhysicalKeyboardKey.arrowLeft;
    } else if (keyString.contains('arrowRight')) {
      return PhysicalKeyboardKey.arrowRight;
    } else if (keyString.contains('equal')) {
      return PhysicalKeyboardKey.equal;
    } else if (keyString.contains('minus')) {
      return PhysicalKeyboardKey.minus;
    } else if (keyString.contains('escape')) {
      return PhysicalKeyboardKey.escape;
    } else if (keyString.contains('enter')) {
      return PhysicalKeyboardKey.enter;
    } else if (keyString.contains('tab')) {
      return PhysicalKeyboardKey.tab;
    } else if (keyString.contains('backspace')) {
      return PhysicalKeyboardKey.backspace;
    } else if (keyString.contains('delete')) {
      return PhysicalKeyboardKey.delete;
    } else if (keyString.contains('home')) {
      return PhysicalKeyboardKey.home;
    } else if (keyString.contains('end')) {
      return PhysicalKeyboardKey.end;
    } else if (keyString.contains('pageUp')) {
      return PhysicalKeyboardKey.pageUp;
    } else if (keyString.contains('pageDown')) {
      return PhysicalKeyboardKey.pageDown;
    } else {
      // Try function keys F1-F12
      for (int i = 1; i <= 12; i++) {
        if (keyString.contains('f$i') || keyString.contains('F$i')) {
          switch (i) {
            case 1: return PhysicalKeyboardKey.f1;
            case 2: return PhysicalKeyboardKey.f2;
            case 3: return PhysicalKeyboardKey.f3;
            case 4: return PhysicalKeyboardKey.f4;
            case 5: return PhysicalKeyboardKey.f5;
            case 6: return PhysicalKeyboardKey.f6;
            case 7: return PhysicalKeyboardKey.f7;
            case 8: return PhysicalKeyboardKey.f8;
            case 9: return PhysicalKeyboardKey.f9;
            case 10: return PhysicalKeyboardKey.f10;
            case 11: return PhysicalKeyboardKey.f11;
            case 12: return PhysicalKeyboardKey.f12;
          }
        }
      }

      // Try number keys 0-9
      for (int i = 0; i <= 9; i++) {
        if (keyString.contains('digit$i') || keyString.contains('Digit$i')) {
          switch (i) {
            case 0: return PhysicalKeyboardKey.digit0;
            case 1: return PhysicalKeyboardKey.digit1;
            case 2: return PhysicalKeyboardKey.digit2;
            case 3: return PhysicalKeyboardKey.digit3;
            case 4: return PhysicalKeyboardKey.digit4;
            case 5: return PhysicalKeyboardKey.digit5;
            case 6: return PhysicalKeyboardKey.digit6;
            case 7: return PhysicalKeyboardKey.digit7;
            case 8: return PhysicalKeyboardKey.digit8;
            case 9: return PhysicalKeyboardKey.digit9;
          }
        }
      }

      // Try letter keys A-Z (both upper and lower case patterns)
      const letterKeys = {
        'A': PhysicalKeyboardKey.keyA, 'B': PhysicalKeyboardKey.keyB, 'C': PhysicalKeyboardKey.keyC,
        'D': PhysicalKeyboardKey.keyD, 'E': PhysicalKeyboardKey.keyE, 'F': PhysicalKeyboardKey.keyF,
        'G': PhysicalKeyboardKey.keyG, 'H': PhysicalKeyboardKey.keyH, 'I': PhysicalKeyboardKey.keyI,
        'J': PhysicalKeyboardKey.keyJ, 'K': PhysicalKeyboardKey.keyK, 'L': PhysicalKeyboardKey.keyL,
        'M': PhysicalKeyboardKey.keyM, 'N': PhysicalKeyboardKey.keyN, 'O': PhysicalKeyboardKey.keyO,
        'P': PhysicalKeyboardKey.keyP, 'Q': PhysicalKeyboardKey.keyQ, 'R': PhysicalKeyboardKey.keyR,
        'S': PhysicalKeyboardKey.keyS, 'T': PhysicalKeyboardKey.keyT, 'U': PhysicalKeyboardKey.keyU,
        'V': PhysicalKeyboardKey.keyV, 'W': PhysicalKeyboardKey.keyW, 'X': PhysicalKeyboardKey.keyX,
        'Y': PhysicalKeyboardKey.keyY, 'Z': PhysicalKeyboardKey.keyZ,
      };

      for (final entry in letterKeys.entries) {
        if (keyString.contains('key${entry.key}') || keyString.contains('Key${entry.key}')) {
          return entry.value;
        }
      }

      return null;
    }

    return null;
  }


  // Reset all settings to defaults
  Future<void> resetAllSettings() async {
    await Future.wait([
      _prefs.remove(_keyThemeMode),
      _prefs.remove(_keyEnableDebugLogging),
      _prefs.remove(_keyVideoBufferSize),
      _prefs.remove(_keyAudioBufferSize),
      _prefs.remove(_keyKeyboardShortcuts),
      _prefs.remove(_keyKeyboardHotkeys),
      _prefs.remove(_keyEnableHardwareDecoding),
      _prefs.remove(_keyPreferredVideoCodec),
      _prefs.remove(_keyPreferredAudioCodec),
    ]);
  }

  // Clear cache (for storage cleanup)
  Future<void> clearCache() async {
    // This would be expanded to clear various cache directories
    // For now, we'll just clear any cache-related preferences
    await Future.wait([
      // Add cache clearing logic here
    ]);
  }

  // Get all settings as a map for debugging/export
  Future<Map<String, dynamic>> getAllSettings() async {
    final hotkeys = await getKeyboardHotkeys();
    return {
      'themeMode': getThemeMode().name,
      'enableDebugLogging': getEnableDebugLogging(),
      'videoBufferSize': getVideoBufferSize(),
      'audioBufferSize': getAudioBufferSize(),
      'enableHardwareDecoding': getEnableHardwareDecoding(),
      'preferredVideoCodec': getPreferredVideoCodec(),
      'preferredAudioCodec': getPreferredAudioCodec(),
      'keyboardShortcuts': getKeyboardShortcuts(),
      'keyboardHotkeys': hotkeys.map((key, value) => MapEntry(key, _serializeHotKey(value))),
    };
  }
}