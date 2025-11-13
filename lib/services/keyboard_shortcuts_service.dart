import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'settings_service.dart';

class KeyboardShortcutsService {
  static KeyboardShortcutsService? _instance;
  late SettingsService _settingsService;
  Map<String, String> _shortcuts =
      {}; // Legacy string shortcuts for backward compatibility
  Map<String, HotKey> _hotkeys = {}; // New HotKey objects
  int _seekTimeSmall = 10; // Default, loaded from settings
  int _seekTimeLarge = 30; // Default, loaded from settings

  KeyboardShortcutsService._();

  static Future<KeyboardShortcutsService> getInstance() async {
    if (_instance == null) {
      _instance = KeyboardShortcutsService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    _settingsService = await SettingsService.getInstance();
    // Ensure settings service is fully initialized before loading data
    await Future.delayed(Duration.zero); // Allow event loop to complete
    _shortcuts = _settingsService
        .getKeyboardShortcuts(); // Keep for legacy compatibility
    _hotkeys = await _settingsService.getKeyboardHotkeys(); // Primary method
    _seekTimeSmall = _settingsService.getSeekTimeSmall();
    _seekTimeLarge = _settingsService.getSeekTimeLarge();
  }

  Map<String, String> get shortcuts => Map.from(_shortcuts);
  Map<String, HotKey> get hotkeys => Map.from(_hotkeys);

  String getShortcut(String action) {
    return _shortcuts[action] ?? '';
  }

  HotKey? getHotkey(String action) {
    return _hotkeys[action];
  }

  Future<void> setShortcut(String action, String key) async {
    _shortcuts[action] = key;
    await _settingsService.setKeyboardShortcuts(_shortcuts);
  }

  Future<void> setHotkey(String action, HotKey hotkey) async {
    // Update local cache first
    _hotkeys[action] = hotkey;

    // Save to persistent storage
    await _settingsService.setKeyboardHotkey(action, hotkey);

    // Verify local cache is still correct
    if (_hotkeys[action] != hotkey) {
      _hotkeys[action] = hotkey; // Restore correct value
    }
  }

  Future<void> refreshFromStorage() async {
    _hotkeys = await _settingsService.getKeyboardHotkeys();
    _seekTimeSmall = _settingsService.getSeekTimeSmall();
    _seekTimeLarge = _settingsService.getSeekTimeLarge();
  }

  Future<void> resetToDefaults() async {
    _shortcuts = _settingsService.getDefaultKeyboardShortcuts();
    _hotkeys = _settingsService.getDefaultKeyboardHotkeys();
    await _settingsService.setKeyboardShortcuts(_shortcuts);
    await _settingsService.setKeyboardHotkeys(_hotkeys);
    // Refresh cache to ensure consistency
    await refreshFromStorage();
  }

  // Format HotKey for display
  String formatHotkey(HotKey? hotKey) {
    if (hotKey == null) return 'No shortcut set';

    final modifiers = <String>[];
    for (final modifier in hotKey.modifiers ?? []) {
      switch (modifier) {
        case HotKeyModifier.alt:
          modifiers.add('Alt');
          break;
        case HotKeyModifier.control:
          modifiers.add('Ctrl');
          break;
        case HotKeyModifier.shift:
          modifiers.add('Shift');
          break;
        case HotKeyModifier.meta:
          modifiers.add('Meta');
          break;
        case HotKeyModifier.capsLock:
          modifiers.add('CapsLock');
          break;
        case HotKeyModifier.fn:
          modifiers.add('Fn');
          break;
      }
    }

    // Format the key name
    String keyName = hotKey.key.keyLabel;
    if (keyName.startsWith('PhysicalKeyboardKey#')) {
      keyName = keyName.substring(20, keyName.length - 1);
    }
    if (keyName.startsWith('key')) {
      keyName = keyName.substring(3).toUpperCase();
    }

    // Special cases for common keys
    switch (keyName.toLowerCase()) {
      case 'space':
        keyName = 'Space';
        break;
      case 'arrowup':
        keyName = 'Arrow Up';
        break;
      case 'arrowdown':
        keyName = 'Arrow Down';
        break;
      case 'arrowleft':
        keyName = 'Arrow Left';
        break;
      case 'arrowright':
        keyName = 'Arrow Right';
        break;
      case 'equal':
        keyName = 'Plus';
        break;
      case 'minus':
        keyName = 'Minus';
        break;
    }

    return modifiers.isEmpty ? keyName : '${modifiers.join(' + ')} + $keyName';
  }

  // Handle keyboard input for video player
  KeyEventResult handleVideoPlayerKeyEvent(
    KeyEvent event,
    Player player,
    VoidCallback? onToggleFullscreen,
    VoidCallback? onToggleSubtitles,
    VoidCallback? onNextAudioTrack,
    VoidCallback? onNextSubtitleTrack,
    VoidCallback? onNextChapter,
    VoidCallback? onPreviousChapter,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final physicalKey = event.physicalKey;
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
    final isControlPressed = HardwareKeyboard.instance.isControlPressed;
    final isAltPressed = HardwareKeyboard.instance.isAltPressed;
    final isMetaPressed = HardwareKeyboard.instance.isMetaPressed;

    // Check each hotkey
    for (final entry in _hotkeys.entries) {
      final action = entry.key;
      final hotkey = entry.value;

      // Check if the physical key matches
      if (physicalKey != hotkey.key) continue;

      // Check if modifiers match
      final requiredModifiers = hotkey.modifiers ?? [];
      bool modifiersMatch = true;

      // Check each required modifier
      for (final modifier in requiredModifiers) {
        switch (modifier) {
          case HotKeyModifier.shift:
            if (!isShiftPressed) modifiersMatch = false;
            break;
          case HotKeyModifier.control:
            if (!isControlPressed) modifiersMatch = false;
            break;
          case HotKeyModifier.alt:
            if (!isAltPressed) modifiersMatch = false;
            break;
          case HotKeyModifier.meta:
            if (!isMetaPressed) modifiersMatch = false;
            break;
          case HotKeyModifier.capsLock:
            // CapsLock is typically not used for shortcuts, ignore for now
            break;
          case HotKeyModifier.fn:
            // Fn key is typically not used for shortcuts, ignore for now
            break;
        }
        if (!modifiersMatch) break;
      }

      // Check that no extra modifiers are pressed
      if (modifiersMatch) {
        final hasShift = requiredModifiers.contains(HotKeyModifier.shift);
        final hasControl = requiredModifiers.contains(HotKeyModifier.control);
        final hasAlt = requiredModifiers.contains(HotKeyModifier.alt);
        final hasMeta = requiredModifiers.contains(HotKeyModifier.meta);

        if (isShiftPressed != hasShift ||
            isControlPressed != hasControl ||
            isAltPressed != hasAlt ||
            isMetaPressed != hasMeta) {
          continue;
        }

        _executeAction(
          action,
          player,
          onToggleFullscreen,
          onToggleSubtitles,
          onNextAudioTrack,
          onNextSubtitleTrack,
          onNextChapter,
          onPreviousChapter,
        );
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  /// Seeks by the given offset (can be positive or negative) while clamping
  /// the result between 0 and the video duration
  void _seekWithClamping(Player player, Duration offset) {
    final currentPosition = player.state.position;
    final duration = player.state.duration;
    final newPosition = currentPosition + offset;

    // Clamp between 0 and video duration
    final clampedPosition = newPosition.isNegative
        ? Duration.zero
        : (newPosition > duration ? duration : newPosition);

    player.seek(clampedPosition);
  }

  void _executeAction(
    String action,
    Player player,
    VoidCallback? onToggleFullscreen,
    VoidCallback? onToggleSubtitles,
    VoidCallback? onNextAudioTrack,
    VoidCallback? onNextSubtitleTrack,
    VoidCallback? onNextChapter,
    VoidCallback? onPreviousChapter,
  ) {
    switch (action) {
      case 'play_pause':
        player.playOrPause();
        break;
      case 'volume_up':
        final newVolume = (player.state.volume + 10).clamp(0.0, 100.0);
        player.setVolume(newVolume);
        _settingsService.setVolume(newVolume);
        break;
      case 'volume_down':
        final newVolume = (player.state.volume - 10).clamp(0.0, 100.0);
        player.setVolume(newVolume);
        _settingsService.setVolume(newVolume);
        break;
      case 'seek_forward':
        _seekWithClamping(player, Duration(seconds: _seekTimeSmall));
        break;
      case 'seek_backward':
        _seekWithClamping(player, Duration(seconds: -_seekTimeSmall));
        break;
      case 'seek_forward_large':
        _seekWithClamping(player, Duration(seconds: _seekTimeLarge));
        break;
      case 'seek_backward_large':
        _seekWithClamping(player, Duration(seconds: -_seekTimeLarge));
        break;
      case 'fullscreen_toggle':
        onToggleFullscreen?.call();
        break;
      case 'mute_toggle':
        final newVolume = player.state.volume > 0 ? 0.0 : 100.0;
        player.setVolume(newVolume);
        _settingsService.setVolume(newVolume);
        break;
      case 'subtitle_toggle':
        onToggleSubtitles?.call();
        break;
      case 'audio_track_next':
        onNextAudioTrack?.call();
        break;
      case 'subtitle_track_next':
        onNextSubtitleTrack?.call();
        break;
      case 'chapter_next':
        onNextChapter?.call();
        break;
      case 'chapter_previous':
        onPreviousChapter?.call();
        break;
      case 'speed_increase':
        final newRate = (player.state.rate + 0.1).clamp(0.1, 3.0);
        player.setRate(newRate);
        break;
      case 'speed_decrease':
        final newRate = (player.state.rate - 0.1).clamp(0.1, 3.0);
        player.setRate(newRate);
        break;
      case 'speed_reset':
        player.setRate(1.0);
        break;
    }
  }

  // Get human-readable action names
  String getActionDisplayName(String action) {
    switch (action) {
      case 'play_pause':
        return 'Play/Pause';
      case 'volume_up':
        return 'Volume Up';
      case 'volume_down':
        return 'Volume Down';
      case 'seek_forward':
        return 'Seek Forward (${_seekTimeSmall}s)';
      case 'seek_backward':
        return 'Seek Backward (${_seekTimeSmall}s)';
      case 'seek_forward_large':
        return 'Seek Forward (${_seekTimeLarge}s)';
      case 'seek_backward_large':
        return 'Seek Backward (${_seekTimeLarge}s)';
      case 'fullscreen_toggle':
        return 'Toggle Fullscreen';
      case 'mute_toggle':
        return 'Toggle Mute';
      case 'subtitle_toggle':
        return 'Toggle Subtitles';
      case 'audio_track_next':
        return 'Next Audio Track';
      case 'subtitle_track_next':
        return 'Next Subtitle Track';
      case 'chapter_next':
        return 'Next Chapter';
      case 'chapter_previous':
        return 'Previous Chapter';
      case 'speed_increase':
        return 'Increase Speed';
      case 'speed_decrease':
        return 'Decrease Speed';
      case 'speed_reset':
        return 'Reset Speed';
      default:
        return action;
    }
  }

  // Validate if a key combination is valid (legacy method for backward compatibility)
  bool isValidKeyShortcut(String keyString) {
    // For backward compatibility, assume all non-empty strings are valid
    // The new system will use HotKey objects for validation
    return keyString.isNotEmpty;
  }

  // Check if a shortcut is already assigned to another action
  String? getActionForShortcut(String keyString) {
    for (final entry in _shortcuts.entries) {
      if (entry.value == keyString) {
        return entry.key;
      }
    }
    return null;
  }

  // Check if a hotkey is already assigned to another action
  String? getActionForHotkey(HotKey hotkey) {
    for (final entry in _hotkeys.entries) {
      if (_hotkeyEquals(entry.value, hotkey)) {
        return entry.key;
      }
    }
    return null;
  }

  // Helper method to compare two HotKey objects
  bool _hotkeyEquals(HotKey a, HotKey b) {
    if (a.key != b.key) return false;

    final aModifiers = Set.from(a.modifiers ?? []);
    final bModifiers = Set.from(b.modifiers ?? []);

    return aModifiers.length == bModifiers.length &&
        aModifiers.every((modifier) => bModifiers.contains(modifier));
  }
}
