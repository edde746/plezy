import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../utils/platform_helper.dart';
import 'package:flutter/services.dart';
import '../models/hotkey_model.dart';
import '../i18n/strings.g.dart';
import '../mpv/mpv.dart';
import 'settings_service.dart';
import '../utils/player_utils.dart';

class KeyboardShortcutsService {
  static KeyboardShortcutsService? _instance;
  late SettingsService _settingsService;
  Map<String, String> _shortcuts = {}; // Legacy string shortcuts for backward compatibility
  Map<String, HotKey> _hotkeys = {}; // New HotKey objects
  int _seekTimeSmall = 10; // Default, loaded from settings
  int _seekTimeLarge = 30; // Default, loaded from settings
  int _maxVolume = 100; // Default, loaded from settings (100-300%)

  KeyboardShortcutsService._();

  static Future<KeyboardShortcutsService> getInstance() async {
    if (_instance == null) {
      _instance = KeyboardShortcutsService._();
      await _instance!._init();
    }
    return _instance!;
  }

  /// Keyboard shortcut customization is only supported on desktop platforms.
  static bool isPlatformSupported() {
    return AppPlatform.isWindows || AppPlatform.isLinux || AppPlatform.isMacOS;
  }

  Future<void> _init() async {
    _settingsService = await SettingsService.getInstance();
    // Ensure settings service is fully initialized before loading data
    await Future.delayed(Duration.zero); // Allow event loop to complete
    _shortcuts = _settingsService.getKeyboardShortcuts(); // Keep for legacy compatibility
    _hotkeys = await _settingsService.getKeyboardHotkeys(); // Primary method
    _seekTimeSmall = _settingsService.getSeekTimeSmall();
    _seekTimeLarge = _settingsService.getSeekTimeLarge();
    _maxVolume = _settingsService.getMaxVolume();
  }

  Map<String, String> get shortcuts => Map.from(_shortcuts);
  Map<String, HotKey> get hotkeys => Map.from(_hotkeys);
  int get maxVolume => _maxVolume;

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

    final isMac = AppPlatform.isMacOS;

    // macOS standard modifier order: ⌃ ⌥ ⇧ ⌘
    const macModifierLabels = <HotKeyModifier, String>{
      HotKeyModifier.control: '\u2303',
      HotKeyModifier.alt: '\u2325',
      HotKeyModifier.shift: '\u21e7',
      HotKeyModifier.meta: '\u2318',
      HotKeyModifier.capsLock: '\u21ea',
      HotKeyModifier.fn: 'fn',
    };

    const defaultModifierLabels = <HotKeyModifier, String>{
      HotKeyModifier.alt: 'Alt',
      HotKeyModifier.control: 'Ctrl',
      HotKeyModifier.shift: 'Shift',
      HotKeyModifier.meta: 'Meta',
      HotKeyModifier.capsLock: 'CapsLock',
      HotKeyModifier.fn: 'Fn',
    };

    final labels = isMac ? macModifierLabels : defaultModifierLabels;
    final modifiers = (hotKey.modifiers ?? []).map((m) => labels[m] ?? m.name).toList();

    // The key label already uses macOS symbols via physicalKeyLabel()
    final keyName = physicalKeyLabel(hotKey.key);

    if (isMac) {
      return [...modifiers, keyName].join();
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
    VoidCallback? onPreviousChapter, {
    VoidCallback? onBack,
    VoidCallback? onToggleShader,
    VoidCallback? onSkipMarker,
  }) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Handle back navigation keys (Escape)
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      onBack?.call();
      return KeyEventResult.handled;
    }

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
          onToggleShader: onToggleShader,
          onSkipMarker: onSkipMarker,
        );
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  void _executeAction(
    String action,
    Player player,
    VoidCallback? onToggleFullscreen,
    VoidCallback? onToggleSubtitles,
    VoidCallback? onNextAudioTrack,
    VoidCallback? onNextSubtitleTrack,
    VoidCallback? onNextChapter,
    VoidCallback? onPreviousChapter, {
    VoidCallback? onToggleShader,
    VoidCallback? onSkipMarker,
  }) {
    switch (action) {
      case 'play_pause':
        player.playOrPause();
        break;
      case 'volume_up':
        final newVolume = (player.state.volume + 10).clamp(0.0, _maxVolume.toDouble());
        player.setVolume(newVolume);
        _settingsService.setVolume(newVolume);
        break;
      case 'volume_down':
        final newVolume = (player.state.volume - 10).clamp(0.0, _maxVolume.toDouble());
        player.setVolume(newVolume);
        _settingsService.setVolume(newVolume);
        break;
      case 'seek_forward':
        seekWithClamping(player, Duration(seconds: _seekTimeSmall));
        break;
      case 'seek_backward':
        seekWithClamping(player, Duration(seconds: -_seekTimeSmall));
        break;
      case 'seek_forward_large':
        seekWithClamping(player, Duration(seconds: _seekTimeLarge));
        break;
      case 'seek_backward_large':
        seekWithClamping(player, Duration(seconds: -_seekTimeLarge));
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
        final newRateUp = (player.state.rate + 0.1).clamp(0.1, 3.0);
        player.setRate(newRateUp);
        _settingsService.setDefaultPlaybackSpeed(newRateUp);
        break;
      case 'speed_decrease':
        final newRateDown = (player.state.rate - 0.1).clamp(0.1, 3.0);
        player.setRate(newRateDown);
        _settingsService.setDefaultPlaybackSpeed(newRateDown);
        break;
      case 'speed_reset':
        player.setRate(1.0);
        _settingsService.setDefaultPlaybackSpeed(1.0);
        break;
      case 'sub_seek_next':
        player.command(['sub-seek', '1']);
        break;
      case 'sub_seek_prev':
        player.command(['sub-seek', '-1']);
        break;
      case 'shader_toggle':
        onToggleShader?.call();
        break;
      case 'skip_marker':
        onSkipMarker?.call();
        break;
    }
  }

  // Get human-readable action names
  String getActionDisplayName(String action) {
    switch (action) {
      case 'play_pause':
        return t.hotkeys.actions.playPause;
      case 'volume_up':
        return t.hotkeys.actions.volumeUp;
      case 'volume_down':
        return t.hotkeys.actions.volumeDown;
      case 'seek_forward':
        return t.hotkeys.actions.seekForward(seconds: _seekTimeSmall);
      case 'seek_backward':
        return t.hotkeys.actions.seekBackward(seconds: _seekTimeSmall);
      case 'seek_forward_large':
        return t.hotkeys.actions.seekForward(seconds: _seekTimeLarge);
      case 'seek_backward_large':
        return t.hotkeys.actions.seekBackward(seconds: _seekTimeLarge);
      case 'fullscreen_toggle':
        return t.hotkeys.actions.fullscreenToggle;
      case 'mute_toggle':
        return t.hotkeys.actions.muteToggle;
      case 'subtitle_toggle':
        return t.hotkeys.actions.subtitleToggle;
      case 'audio_track_next':
        return t.hotkeys.actions.audioTrackNext;
      case 'subtitle_track_next':
        return t.hotkeys.actions.subtitleTrackNext;
      case 'chapter_next':
        return t.hotkeys.actions.chapterNext;
      case 'chapter_previous':
        return t.hotkeys.actions.chapterPrevious;
      case 'speed_increase':
        return t.hotkeys.actions.speedIncrease;
      case 'speed_decrease':
        return t.hotkeys.actions.speedDecrease;
      case 'speed_reset':
        return t.hotkeys.actions.speedReset;
      case 'sub_seek_next':
        return t.hotkeys.actions.subSeekNext;
      case 'sub_seek_prev':
        return t.hotkeys.actions.subSeekPrev;
      case 'shader_toggle':
        return t.hotkeys.actions.shaderToggle;
      case 'skip_marker':
        return t.hotkeys.actions.skipMarker;
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

    return aModifiers.length == bModifiers.length && aModifiers.every((modifier) => bModifiers.contains(modifier));
  }
}
