import 'dart:async' show unawaited;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../media/playback_rate.dart';
import '../models/hotkey_model.dart';
import '../i18n/strings.g.dart';
import '../mpv/mpv.dart';
import 'settings_binding_owner.dart';
import 'settings_service.dart';
import 'shortcut_action.dart';
import '../utils/platform_detector.dart';
import '../utils/player_utils.dart';

class KeyboardShortcutsService extends ChangeNotifier {
  static KeyboardShortcutsService? _instance;
  static Future<void>? _initialization;
  late final SettingsBindingOwner _settingsBinding;
  Map<String, HotKey?> _hotkeys = {};
  Future<void> _shortcutMutationTail = Future.value();
  int _seekTimeSmall = 10; // Default, loaded from settings
  int _seekTimeLarge = 30; // Default, loaded from settings
  bool _disposed = false;
  bool _settingsInitialized = false;

  KeyboardShortcutsService._() {
    _settingsBinding = SettingsBindingOwner(
      prefs: [SettingsService.keyboardHotkeys, SettingsService.seekTimeSmall, SettingsService.seekTimeLarge],
      onRefresh: _syncFromSettings,
    );
  }

  SettingsService get _settingsService => _settingsBinding.settings!;

  static Future<KeyboardShortcutsService> getInstance() async {
    var instance = _instance;
    if (instance == null) {
      instance = KeyboardShortcutsService._();
      _instance = instance;
      final initialization = instance._init();
      _initialization = initialization;
    }

    final initialization = _initialization;
    if (initialization != null) {
      try {
        await initialization;
      } catch (_) {
        if (identical(_instance, instance)) {
          instance._settingsBinding.dispose();
          instance._disposed = true;
          _instance = null;
        }
        rethrow;
      } finally {
        if (identical(_initialization, initialization)) _initialization = null;
      }
    }
    if (instance._disposed) throw StateError('KeyboardShortcutsService was disposed during initialization');
    return instance;
  }

  /// Keyboard shortcut customization is only supported on desktop platforms.
  static bool isPlatformSupported() {
    return PlatformDetector.isDesktopOS();
  }

  Future<void> _init() async {
    await _settingsBinding.bind();
  }

  void _syncFromSettings(SettingsService service) {
    final hotkeys = service.read(SettingsService.keyboardHotkeys);
    final seekTimeSmall = service.read(SettingsService.seekTimeSmall);
    final seekTimeLarge = service.read(SettingsService.seekTimeLarge);

    final changed =
        !_hotkeyMapsEqual(_hotkeys, hotkeys) || _seekTimeSmall != seekTimeSmall || _seekTimeLarge != seekTimeLarge;

    _hotkeys = Map<String, HotKey?>.from(hotkeys);
    _seekTimeSmall = seekTimeSmall;
    _seekTimeLarge = seekTimeLarge;

    final notify = _settingsInitialized;
    _settingsInitialized = true;
    if (notify && changed) notifyListeners();
  }

  bool _hotkeyMapsEqual(Map<String, HotKey?> a, Map<String, HotKey?> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key)) return false;
      final value = entry.value;
      final other = b[entry.key];
      if (value == null || other == null) {
        if (value != other) return false;
      } else if (!_hotkeyEquals(value, other)) {
        return false;
      }
    }
    return true;
  }

  Map<String, HotKey?> get hotkeys => Map.from(_hotkeys);

  @visibleForTesting
  HotKey? getHotkey(String action) {
    return _hotkeys[action];
  }

  Future<void> setHotkey(String action, HotKey? hotkey) {
    return _serializeShortcutMutation(() async {
      await _settingsService.write(SettingsService.keyboardHotkeys, <String, HotKey?>{..._hotkeys, action: hotkey});
    });
  }

  Future<void> refreshFromStorage() async {
    _settingsBinding.refresh();
  }

  Future<void> resetToDefaults() {
    return _serializeShortcutMutation(() async {
      await _settingsService.write(SettingsService.keyboardHotkeys, <String, HotKey?>{
        ...SettingsService.defaultKeyboardHotkeys(),
      });
    });
  }

  Future<void> _serializeShortcutMutation(Future<void> Function() operation) {
    final result = _shortcutMutationTail.then((_) => operation());
    _shortcutMutationTail = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _settingsBinding.dispose();
    if (identical(_instance, this)) {
      _instance = null;
      _initialization = null;
    }
    super.dispose();
  }

  String formatHotkey(HotKey? hotKey) {
    if (hotKey == null) return t.hotkeys.noShortcutSet;

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
    required bool canControlPlayback,
    required bool canNavigateMediaItems,
    VoidCallback? onPlayPause,
    VoidCallback? onToggleShader,
    VoidCallback? onSkipMarker,
    VoidCallback? onNextEpisode,
    VoidCallback? onPreviousEpisode,
    VoidCallback? onScreenshot,
    VoidCallback? onZoomIn,
    VoidCallback? onZoomOut,
    VoidCallback? onZoomReset,
    VoidCallback? onVolumeUp,
    VoidCallback? onVolumeDown,
    VoidCallback? onToggleMute,
    ValueChanged<int>? onLiveSeekBy,
    Future<void> Function(Duration position)? onSeekRequested,

    /// Takes over relative seeking entirely when supplied, so the caller can
    /// coalesce a burst of presses and report the accepted offset. Without it
    /// each press rebases off `player.state.position`, which a slow backend
    /// has not applied yet.
    ValueChanged<int>? onSeekBy,
  }) {
    final isRepeat = event is KeyRepeatEvent;
    if (event is! KeyDownEvent && !isRepeat) return KeyEventResult.ignored;

    final physicalKey = event.physicalKey;
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
    final isControlPressed = HardwareKeyboard.instance.isControlPressed;
    final isAltPressed = HardwareKeyboard.instance.isAltPressed;
    final isMetaPressed = HardwareKeyboard.instance.isMetaPressed;

    for (final entry in _hotkeys.entries) {
      final hotkey = entry.value;
      if (hotkey == null) continue;

      if (physicalKey != hotkey.key) continue;

      // Null for an id this build does not know: the event is still consumed so
      // a stale binding never leaks through to another handler.
      final action = ShortcutAction.fromId(entry.key);

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

        if (isRepeat && !(action?.repeatable ?? false)) {
          return KeyEventResult.handled;
        }

        if (action == null ||
            (action.requiresPlayback && !canControlPlayback) ||
            (action.requiresMediaNavigation && !canNavigateMediaItems)) {
          return KeyEventResult.handled;
        }

        void performSeek(int offsetSeconds) {
          if (onSeekBy != null) {
            onSeekBy(offsetSeconds);
            return;
          }
          // Relative live-TV skip: route through the parent accumulator, which
          // coalesces a rapid burst into one transcode re-open (#1253).
          if (onLiveSeekBy != null) {
            onLiveSeekBy(offsetSeconds);
          } else {
            final target = clampSeekPosition(player, player.state.position + Duration(seconds: offsetSeconds));
            unawaited((onSeekRequested ?? player.seek)(target));
          }
        }

        switch (action) {
          case ShortcutAction.playPause:
            (onPlayPause ?? player.playOrPause).call();
          case ShortcutAction.volumeUp:
            onVolumeUp?.call();
          case ShortcutAction.volumeDown:
            onVolumeDown?.call();
          case ShortcutAction.seekForward:
            performSeek(_seekTimeSmall);
          case ShortcutAction.seekBackward:
            performSeek(-_seekTimeSmall);
          case ShortcutAction.seekForwardLarge:
            performSeek(_seekTimeLarge);
          case ShortcutAction.seekBackwardLarge:
            performSeek(-_seekTimeLarge);
          case ShortcutAction.fullscreenToggle:
            onToggleFullscreen?.call();
          case ShortcutAction.muteToggle:
            onToggleMute?.call();
          case ShortcutAction.subtitleToggle:
            onToggleSubtitles?.call();
          case ShortcutAction.audioTrackNext:
            onNextAudioTrack?.call();
          case ShortcutAction.subtitleTrackNext:
            onNextSubtitleTrack?.call();
          case ShortcutAction.chapterNext:
            onNextChapter?.call();
          case ShortcutAction.chapterPrevious:
            onPreviousChapter?.call();
          case ShortcutAction.episodeNext:
            onNextEpisode?.call();
          case ShortcutAction.episodePrevious:
            onPreviousEpisode?.call();
          case ShortcutAction.speedIncrease:
            final newRateUp = (player.state.rate + 0.25).clamp(minimumPlaybackRate, maximumPlaybackRate);
            player.setRate(newRateUp);
            _settingsService.write(SettingsService.defaultPlaybackSpeed, newRateUp);
          case ShortcutAction.speedDecrease:
            final newRateDown = (player.state.rate - 0.25).clamp(minimumPlaybackRate, maximumPlaybackRate);
            player.setRate(newRateDown);
            _settingsService.write(SettingsService.defaultPlaybackSpeed, newRateDown);
          case ShortcutAction.speedReset:
            player.setRate(1.0);
            _settingsService.write(SettingsService.defaultPlaybackSpeed, 1.0);
          case ShortcutAction.subSeekNext:
            player.command(['sub-seek', '1']);
          case ShortcutAction.subSeekPrev:
            player.command(['sub-seek', '-1']);
          case ShortcutAction.shaderToggle:
            onToggleShader?.call();
          case ShortcutAction.skipMarker:
            onSkipMarker?.call();
          case ShortcutAction.screenshot:
            unawaited(player.command(['screenshot', 'subtitles']).then((_) => onScreenshot?.call()));
          case ShortcutAction.zoomIn:
            onZoomIn?.call();
          case ShortcutAction.zoomOut:
            onZoomOut?.call();
          case ShortcutAction.zoomReset:
            onZoomReset?.call();
        }
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  String getActionDisplayName(String action) {
    final shortcut = ShortcutAction.fromId(action);
    if (shortcut == null) return action;
    return shortcut.label(seekTimeSmall: _seekTimeSmall, seekTimeLarge: _seekTimeLarge);
  }

  // Check if a hotkey is already assigned to another action
  String? getActionForHotkey(HotKey hotkey) {
    for (final entry in _hotkeys.entries) {
      final assignedHotkey = entry.value;
      if (assignedHotkey != null && _hotkeyEquals(assignedHotkey, hotkey)) {
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
