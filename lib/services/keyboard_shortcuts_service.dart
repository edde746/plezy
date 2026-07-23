import 'dart:async' show unawaited;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/hotkey_model.dart';
import '../i18n/strings.g.dart';
import '../mpv/mpv.dart';
import 'settings_binding_owner.dart';
import 'settings_service.dart';
import '../utils/platform_detector.dart';
import '../utils/player_utils.dart';

class KeyboardShortcutsService extends ChangeNotifier {
  static const Set<String> _repeatableVideoActions = {'zoom_in', 'zoom_out'};

  static KeyboardShortcutsService? _instance;
  late final SettingsBindingOwner _settingsBinding;
  Map<String, HotKey?> _hotkeys = {};
  Future<void> _shortcutMutationTail = Future.value();
  int _seekTimeSmall = 10; // Default, loaded from settings
  int _seekTimeLarge = 30; // Default, loaded from settings
  bool _settingsInitialized = false;

  KeyboardShortcutsService._() {
    _settingsBinding = SettingsBindingOwner(
      prefs: [SettingsService.keyboardHotkeys, SettingsService.seekTimeSmall, SettingsService.seekTimeLarge],
      onRefresh: _syncFromSettings,
    );
  }

  SettingsService get _settingsService => _settingsBinding.settings!;

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
    _settingsBinding.dispose();
    if (identical(_instance, this)) _instance = null;
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
    int? currentPositionEpoch,
    ValueChanged<int>? onLiveSeek,
    ValueChanged<int>? onLiveSeekBy,
    Future<void> Function(Duration position)? onSeekRequested,
  }) {
    final isRepeat = event is KeyRepeatEvent;
    if (event is! KeyDownEvent && !isRepeat) return KeyEventResult.ignored;

    final physicalKey = event.physicalKey;
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
    final isControlPressed = HardwareKeyboard.instance.isControlPressed;
    final isAltPressed = HardwareKeyboard.instance.isAltPressed;
    final isMetaPressed = HardwareKeyboard.instance.isMetaPressed;

    for (final entry in _hotkeys.entries) {
      final action = entry.key;
      final hotkey = entry.value;
      if (hotkey == null) continue;

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

        if (isRepeat && !_repeatableVideoActions.contains(action)) {
          return KeyEventResult.handled;
        }

        const playbackControlledActions = <String>{
          'play_pause',
          'seek_forward',
          'seek_backward',
          'seek_forward_large',
          'seek_backward_large',
          'audio_track_next',
          'subtitle_track_next',
          'chapter_next',
          'chapter_previous',
          'speed_increase',
          'speed_decrease',
          'speed_reset',
          'sub_seek_next',
          'sub_seek_prev',
          'skip_marker',
        };
        const mediaItemActions = <String>{'episode_next', 'episode_previous'};
        if ((playbackControlledActions.contains(action) && !canControlPlayback) ||
            (mediaItemActions.contains(action) && !canNavigateMediaItems)) {
          return KeyEventResult.handled;
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
          onPlayPause: onPlayPause,
          onToggleShader: onToggleShader,
          onSkipMarker: onSkipMarker,
          onNextEpisode: onNextEpisode,
          onPreviousEpisode: onPreviousEpisode,
          onScreenshot: onScreenshot,
          onZoomIn: onZoomIn,
          onZoomOut: onZoomOut,
          onZoomReset: onZoomReset,
          onVolumeUp: onVolumeUp,
          onVolumeDown: onVolumeDown,
          onToggleMute: onToggleMute,
          currentPositionEpoch: currentPositionEpoch,
          onLiveSeek: onLiveSeek,
          onLiveSeekBy: onLiveSeekBy,
          onSeekRequested: onSeekRequested,
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
    int? currentPositionEpoch,
    ValueChanged<int>? onLiveSeek,
    ValueChanged<int>? onLiveSeekBy,
    Future<void> Function(Duration position)? onSeekRequested,
  }) {
    void performSeek(int offsetSeconds) {
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
      case 'play_pause':
        (onPlayPause ?? player.playOrPause).call();
        break;
      case 'volume_up':
        onVolumeUp?.call();
        break;
      case 'volume_down':
        onVolumeDown?.call();
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
        onToggleMute?.call();
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
      case 'screenshot':
        unawaited(player.command(['screenshot', 'subtitles']).then((_) => onScreenshot?.call()));
        break;
      case 'zoom_in':
        onZoomIn?.call();
        break;
      case 'zoom_out':
        onZoomOut?.call();
        break;
      case 'zoom_reset':
        onZoomReset?.call();
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
      case 'screenshot':
        return t.hotkeys.actions.screenshot;
      case 'zoom_in':
        return t.hotkeys.actions.zoomIn;
      case 'zoom_out':
        return t.hotkeys.actions.zoomOut;
      case 'zoom_reset':
        return t.hotkeys.actions.zoomReset;
      default:
        return action;
    }
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
