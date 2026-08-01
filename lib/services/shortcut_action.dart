import 'package:flutter/services.dart';

import '../i18n/strings.g.dart';
import '../models/hotkey_model.dart';
import 'shader_service.dart';

/// Every keyboard shortcut the video player understands.
///
/// One row per action carries everything about it except the behaviour: the
/// persisted [id], the [defaultHotKey] shipped with the app, the localized
/// [label], and the capability flags that gate dispatch. Adding a shortcut is
/// one entry here plus a case in
/// `KeyboardShortcutsService.handleVideoPlayerKeyEvent`, which the analyzer
/// demands because that switch is exhaustive over this enum.
///
/// Declaration order is the order shortcuts are listed in settings, and [id] is
/// persisted in preferences — do not reorder or rename existing entries.
enum ShortcutAction {
  playPause('play_pause', HotKey(key: PhysicalKeyboardKey.space), requiresPlayback: true),
  volumeUp('volume_up', HotKey(key: PhysicalKeyboardKey.arrowUp)),
  volumeDown('volume_down', HotKey(key: PhysicalKeyboardKey.arrowDown)),
  seekForward('seek_forward', HotKey(key: PhysicalKeyboardKey.arrowRight), requiresPlayback: true),
  seekBackward('seek_backward', HotKey(key: PhysicalKeyboardKey.arrowLeft), requiresPlayback: true),
  seekForwardLarge(
    'seek_forward_large',
    HotKey(key: PhysicalKeyboardKey.arrowRight, modifiers: [HotKeyModifier.shift]),
    requiresPlayback: true,
  ),
  seekBackwardLarge(
    'seek_backward_large',
    HotKey(key: PhysicalKeyboardKey.arrowLeft, modifiers: [HotKeyModifier.shift]),
    requiresPlayback: true,
  ),
  fullscreenToggle('fullscreen_toggle', HotKey(key: PhysicalKeyboardKey.keyF)),
  muteToggle('mute_toggle', HotKey(key: PhysicalKeyboardKey.keyM)),
  subtitleToggle('subtitle_toggle', HotKey(key: PhysicalKeyboardKey.keyS)),
  audioTrackNext('audio_track_next', HotKey(key: PhysicalKeyboardKey.keyA), requiresPlayback: true),
  subtitleTrackNext(
    'subtitle_track_next',
    HotKey(key: PhysicalKeyboardKey.keyS, modifiers: [HotKeyModifier.shift]),
    requiresPlayback: true,
  ),
  chapterNext('chapter_next', HotKey(key: PhysicalKeyboardKey.keyN), requiresPlayback: true),
  chapterPrevious('chapter_previous', HotKey(key: PhysicalKeyboardKey.keyP), requiresPlayback: true),
  episodeNext(
    'episode_next',
    HotKey(key: PhysicalKeyboardKey.keyN, modifiers: [HotKeyModifier.shift]),
    requiresMediaNavigation: true,
  ),
  episodePrevious(
    'episode_previous',
    HotKey(key: PhysicalKeyboardKey.keyP, modifiers: [HotKeyModifier.shift]),
    requiresMediaNavigation: true,
  ),
  speedIncrease('speed_increase', HotKey(key: PhysicalKeyboardKey.equal), requiresPlayback: true),
  speedDecrease('speed_decrease', HotKey(key: PhysicalKeyboardKey.minus), requiresPlayback: true),
  speedReset('speed_reset', HotKey(key: PhysicalKeyboardKey.keyR), requiresPlayback: true),
  zoomIn('zoom_in', HotKey(key: PhysicalKeyboardKey.equal, modifiers: [HotKeyModifier.alt]), repeatable: true),
  zoomOut('zoom_out', HotKey(key: PhysicalKeyboardKey.minus, modifiers: [HotKeyModifier.alt]), repeatable: true),
  zoomReset('zoom_reset', HotKey(key: PhysicalKeyboardKey.backspace, modifiers: [HotKeyModifier.alt])),
  subSeekNext(
    'sub_seek_next',
    HotKey(key: PhysicalKeyboardKey.arrowRight, modifiers: [HotKeyModifier.control]),
    requiresPlayback: true,
  ),
  subSeekPrev(
    'sub_seek_prev',
    HotKey(key: PhysicalKeyboardKey.arrowLeft, modifiers: [HotKeyModifier.control]),
    requiresPlayback: true,
  ),
  shaderToggle('shader_toggle', HotKey(key: PhysicalKeyboardKey.keyG), requiresShaderSupport: true),
  skipMarker('skip_marker', HotKey(key: PhysicalKeyboardKey.enter), requiresPlayback: true),
  screenshot('screenshot', HotKey(key: PhysicalKeyboardKey.keyS, modifiers: [HotKeyModifier.control]));

  const ShortcutAction(
    this.id,
    this.defaultHotKey, {
    this.repeatable = false,
    this.requiresPlayback = false,
    this.requiresMediaNavigation = false,
    this.requiresShaderSupport = false,
  });

  /// Stable key this action is stored under in preferences.
  final String id;

  /// Shortcut used until the user assigns their own.
  final HotKey defaultHotKey;

  /// Whether holding the key repeats the action instead of swallowing repeats.
  final bool repeatable;

  /// Whether the action drives playback and needs playback authority.
  final bool requiresPlayback;

  /// Whether the action switches media item and needs navigation authority.
  final bool requiresMediaNavigation;

  /// Whether the action is only meaningful where shaders are available.
  final bool requiresShaderSupport;

  static final Map<String, ShortcutAction> _byId = {for (final action in values) action.id: action};

  /// The action stored under [id], or null for an id this build does not know.
  static ShortcutAction? fromId(String id) => _byId[id];

  /// Whether this action can be used on the current platform.
  bool get isSupported => !requiresShaderSupport || ShaderService.isPlatformSupported;

  /// Localized name shown in settings; seek labels embed the configured steps.
  String label({required int seekTimeSmall, required int seekTimeLarge}) => switch (this) {
    ShortcutAction.playPause => t.hotkeys.actions.playPause,
    ShortcutAction.volumeUp => t.hotkeys.actions.volumeUp,
    ShortcutAction.volumeDown => t.hotkeys.actions.volumeDown,
    ShortcutAction.seekForward => t.hotkeys.actions.seekForward(seconds: seekTimeSmall),
    ShortcutAction.seekBackward => t.hotkeys.actions.seekBackward(seconds: seekTimeSmall),
    ShortcutAction.seekForwardLarge => t.hotkeys.actions.seekForward(seconds: seekTimeLarge),
    ShortcutAction.seekBackwardLarge => t.hotkeys.actions.seekBackward(seconds: seekTimeLarge),
    ShortcutAction.fullscreenToggle => t.hotkeys.actions.fullscreenToggle,
    ShortcutAction.muteToggle => t.hotkeys.actions.muteToggle,
    ShortcutAction.subtitleToggle => t.hotkeys.actions.subtitleToggle,
    ShortcutAction.audioTrackNext => t.hotkeys.actions.audioTrackNext,
    ShortcutAction.subtitleTrackNext => t.hotkeys.actions.subtitleTrackNext,
    ShortcutAction.chapterNext => t.hotkeys.actions.chapterNext,
    ShortcutAction.chapterPrevious => t.hotkeys.actions.chapterPrevious,
    ShortcutAction.episodeNext => t.hotkeys.actions.episodeNext,
    ShortcutAction.episodePrevious => t.hotkeys.actions.episodePrevious,
    ShortcutAction.speedIncrease => t.hotkeys.actions.speedIncrease,
    ShortcutAction.speedDecrease => t.hotkeys.actions.speedDecrease,
    ShortcutAction.speedReset => t.hotkeys.actions.speedReset,
    ShortcutAction.zoomIn => t.hotkeys.actions.zoomIn,
    ShortcutAction.zoomOut => t.hotkeys.actions.zoomOut,
    ShortcutAction.zoomReset => t.hotkeys.actions.zoomReset,
    ShortcutAction.subSeekNext => t.hotkeys.actions.subSeekNext,
    ShortcutAction.subSeekPrev => t.hotkeys.actions.subSeekPrev,
    ShortcutAction.shaderToggle => t.hotkeys.actions.shaderToggle,
    ShortcutAction.skipMarker => t.hotkeys.actions.skipMarker,
    ShortcutAction.screenshot => t.hotkeys.actions.screenshot,
  };
}
