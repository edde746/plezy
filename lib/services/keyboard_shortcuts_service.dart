import 'dart:async' show unawaited;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/hotkey_model.dart';
import '../i18n/strings.g.dart';
import '../mpv/mpv.dart';
import 'settings_service.dart';
import '../utils/platform_detector.dart';
import '../utils/player_utils.dart';

class KeyboardShortcutsService extends ChangeNotifier {
  static KeyboardShortcutsService? _instance;
  late SettingsService _settingsService;
  final List<VoidCallback> _settingsDisposers = [];
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
    return PlatformDetector.isDesktopOS();
  }

  Future<void> _init() async {
    _settingsService = await SettingsService.getInstance();
    _bindSettings();
    _syncFromSettings(notify: false);
  }

  void _bindSettings() {
    if (_settingsDisposers.isNotEmpty) return;
    void bind<T>(Pref<T> pref) {
      final notifier = _settingsService.listenable(pref);
      notifier.addListener(_onSettingsChanged);
      _settingsDisposers.add(() => notifier.removeListener(_onSettingsChanged));
    }

    bind(SettingsService.keyboardShortcuts);
    bind(SettingsService.keyboardHotkeys);
    bind(SettingsService.seekTimeSmall);
    bind(SettingsService.seekTimeLarge);
    bind(SettingsService.maxVolume);
  }

  void _onSettingsChanged() => _syncFromSettings();

  void _syncFromSettings({bool notify = true}) {
    final shortcuts = _settingsService.read(SettingsService.keyboardShortcuts);
    final hotkeys = _settingsService.read(SettingsService.keyboardHotkeys);
    final seekTimeSmall = _settingsService.read(SettingsService.seekTimeSmall);
    final seekTimeLarge = _settingsService.read(SettingsService.seekTimeLarge);
    final maxVolume = _settingsService.read(SettingsService.maxVolume);

    final changed =
        !mapEquals(_shortcuts, shortcuts) ||
        !_hotkeyMapsEqual(_hotkeys, hotkeys) ||
        _seekTimeSmall != seekTimeSmall ||
        _seekTimeLarge != seekTimeLarge ||
        _maxVolume != maxVolume;

    _shortcuts = Map<String, String>.from(shortcuts);
    _hotkeys = Map<String, HotKey>.from(hotkeys);
    _seekTimeSmall = seekTimeSmall;
    _seekTimeLarge = seekTimeLarge;
    _maxVolume = maxVolume;

    if (notify && changed) notifyListeners();
  }

  bool _hotkeyMapsEqual(Map<String, HotKey> a, Map<String, HotKey> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      final other = b[entry.key];
      if (other == null || !_hotkeyEquals(entry.value, other)) return false;
    }
    return true;
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
    await _settingsService.write(SettingsService.keyboardShortcuts, {..._shortcuts, action: key});
  }

  Future<void> setHotkey(String action, HotKey hotkey) async {
    await _settingsService.write(SettingsService.keyboardHotkeys, {..._hotkeys, action: hotkey});
  }

  Future<void> refreshFromStorage() async {
    _syncFromSettings();
  }

  Future<void> resetToDefaults() async {
    final shortcuts = SettingsService.defaultKeyboardShortcuts();
    final hotkeys = SettingsService.defaultKeyboardHotkeys();
    await _settingsService.write(SettingsService.keyboardShortcuts, shortcuts);
    await _settingsService.write(SettingsService.keyboardHotkeys, hotkeys);
  }

  @override
  void dispose() {
    for (final dispose in _settingsDisposers) {
      dispose();
    }
    _settingsDisposers.clear();
    if (identical(_instance, this)) _instance = null;
    super.dispose();
  }

  String formatHotkey(HotKey? hotKey) {
    if (hotKey == null) return 'No shortcut set';

    final isMac = Platform.isMacOS;

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
    VoidCallback? onNextEpisode,
    VoidCallback? onPreviousEpisode,
    int? currentPositionEpoch,
    ValueChanged<int>? onLiveSeek,
  }) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      onBack?.call();
      return KeyEventResult.handled;
    }

    final physicalKey = event.physicalKey;
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
    final isControlPressed = HardwareKeyboard.instance.isControlPressed;
    final isAltPressed = HardwareKeyboard.instance.isAltPressed;
    final isMetaPressed = HardwareKeyboard.instance.isMetaPressed;

    for (final entry in _hotkeys.entries) {
      final action = entry.key;
      final hotkey = entry.value;

      if (physicalKey != hotkey.key) continue;

      final requiredModifiers = hotkey.modifiers ?? [];
      bool modifiersMatch = true;

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
          onNextEpisode: onNextEpisode,
          onPreviousEpisode: onPreviousEpisode,
          currentPositionEpoch: currentPositionEpoch,
          onLiveSeek: onLiveSeek,
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
    VoidCallback? onNextEpisode,
    VoidCallback? onPreviousEpisode,
    int? currentPositionEpoch,
    ValueChanged<int>? onLiveSeek,
  }) {
    void performSeek(int offsetSeconds) {
      if (onLiveSeek != null && currentPositionEpoch != null) {
        onLiveSeek(currentPositionEpoch + offsetSeconds);
      } else {
        final target = clampSeekPosition(player, player.state.position + Duration(seconds: offsetSeconds));
        unawaited(player.seek(target));
      }
    }

    switch (action) {
      case 'play_pause':
        player.playOrPause();
        break;
      case 'volume_up':
        final newVolume = (player.state.volume + 10).clamp(0.0, _maxVolume.toDouble());
        player.setVolume(newVolume);
        _settingsService.write(SettingsService.volume, newVolume);
        break;
      case 'volume_down':
        final newVolume = (player.state.volume - 10).clamp(0.0, _maxVolume.toDouble());
        player.setVolume(newVolume);
        _settingsService.write(SettingsService.volume, newVolume);
        break;
      case 'seek_forward':
        performSeek(_seekTimeSmall);
        break;
      case 'seek_backward':
        performSeek(-_seekTimeSmall);
        break;
      case 'seek_forward_large':
        performSeek(_seekTimeLarge);
        break;
      case 'seek_backward_large':
        performSeek(-_seekTimeLarge);
        break;
      case 'fullscreen_toggle':
        onToggleFullscreen?.call();
        break;
      case 'mute_toggle':
        final newVolume = player.state.volume > 0 ? 0.0 : 100.0;
        player.setVolume(newVolume);
        _settingsService.write(SettingsService.volume, newVolume);
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
      case 'episode_next':
        onNextEpisode?.call();
        break;
      case 'episode_previous':
        onPreviousEpisode?.call();
        break;
      case 'speed_increase':
        final newRateUp = (player.state.rate + 0.25).clamp(0.25, 3.0);
        player.setRate(newRateUp);
        _settingsService.write(SettingsService.defaultPlaybackSpeed, newRateUp);
        break;
      case 'speed_decrease':
        final newRateDown = (player.state.rate - 0.25).clamp(0.25, 3.0);
        player.setRate(newRateDown);
        _settingsService.write(SettingsService.defaultPlaybackSpeed, newRateDown);
        break;
      case 'speed_reset':
        player.setRate(1.0);
        _settingsService.write(SettingsService.defaultPlaybackSpeed, 1.0);
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
      case 'episode_next':
        return t.hotkeys.actions.episodeNext;
      case 'episode_previous':
        return t.hotkeys.actions.episodePrevious;
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
