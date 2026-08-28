import 'dart:async' show StreamSubscription, Timer, unawaited;
import 'dart:io' show Platform;

import '../../media/ids.dart';

import 'package:flutter/gestures.dart'
    show
        PointerCancelEvent,
        PointerDeviceKind,
        PointerDownEvent,
        PointerMoveEvent,
        PointerScrollEvent,
        PointerSignalEvent,
        PointerUpEvent,
        kDoubleTapTimeout;
import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:rate_limiter/rate_limiter.dart';
import 'package:flutter/services.dart'
    show
        SystemChrome,
        DeviceOrientation,
        LogicalKeyboardKey,
        PhysicalKeyboardKey,
        KeyEvent,
        KeyDownEvent,
        KeyUpEvent,
        KeyRepeatEvent,
        HardwareKeyboard;
import '../../services/fullscreen_state_manager.dart';
import '../../services/macos_window_service.dart';
import '../../services/pip_service.dart';
import '../../services/playback_initialization_types.dart';
import '../../services/playback_subtitle_resolver.dart';
import 'package:window_manager/window_manager.dart';

import '../../mixins/settings_effect_mixin.dart';
import '../../mixins/mounted_set_state_mixin.dart';
import '../../mpv/mpv.dart';
import '../overlay_sheet.dart';
import '../../focus/dpad_navigator.dart';
import '../../focus/focus_navigation_intent.dart';
import '../../focus/transport_keys.dart';

import '../../database/app_database.dart';
import '../../media/media_backend.dart';
import '../../media/media_item.dart';
import '../../media/packed_stereo_layout.dart';
import '../../media/stepped_seek.dart';
import '../../models/livetv_capture_buffer.dart';
import '../../providers/multi_server_provider.dart';
import '../../media/media_source_info.dart';
import '../../models/transcode_quality_preset.dart';
import '../../media/media_version.dart';
import '../../screens/video_player_screen.dart';
import '../../focus/key_event_utils.dart';
import '../../services/keyboard_shortcuts_service.dart';
import '../../services/device_adjustment_service.dart';
import '../../services/scrub_preview_source.dart';
import '../../services/scoped_player_prefs.dart';
import '../../services/settings_service.dart';
import '../../services/video_volume_controller.dart';
import '../../utils/codec_utils.dart';
import '../../utils/formatters.dart';
import '../../utils/platform_detector.dart';
import '../../utils/player_utils.dart';
import '../../utils/route_visibility.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/provider_extensions.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/latest_async_write.dart';
import 'icons.dart';
import 'player_chrome_controller.dart';
import 'playback_extras_loader.dart';
import 'widgets/player_toast_indicator.dart';
import 'widgets/transport_feedback_indicator.dart';
import '../../utils/app_logger.dart';
import '../../i18n/strings.g.dart';
import '../../focus/input_mode_tracker.dart';
import 'models/track_controls_state.dart';
import 'widgets/double_tap_feedback.dart';
import 'helpers/mobile_edge_adjustment_tracker.dart';
import 'helpers/two_finger_tap_tracker.dart';
import 'widgets/linux_keep_alive.dart';
import 'widgets/mobile_edge_adjustment_indicator.dart';
import 'widgets/mobile_skip_zones.dart';
import 'widgets/skip_marker_button.dart';
import 'widgets/track_chapter_controls.dart';
import 'widgets/performance_overlay/performance_overlay.dart';
import '../rasterized_gradient.dart';
import 'mobile_video_controls.dart';
import 'desktop_video_controls.dart';
import 'package:provider/provider.dart';

import '../../models/shader_preset.dart';
import '../../providers/playback_state_provider.dart';
import '../../providers/shader_provider.dart';
import '../../services/shader_service.dart';

part 'parts/key_events.dart';
part 'parts/markers.dart';
part 'parts/navigation.dart';
part 'parts/playback_extras.dart';
part 'parts/playback_input.dart';
part 'parts/track_controls.dart';
part 'parts/visibility.dart';

/// Subtitle tracks offered in the player's "source" subtitle list.
///
/// Direct play exposes embedded tracks in the native player and can attach
/// arbitrary sidecars itself. A transcode can only deliver a resolved sidecar or
/// an embedded codec the server can burn into the rendition — which every
/// backend can be asked to do (Plex `subtitles=burn`, Jellyfin/Emby an `Encode`
/// subtitle profile plus `SubtitleStreamIndex`), so the codec is the only
/// discriminator here.
List<MediaSubtitleTrack> selectableSourceSubtitleTracks(
  List<MediaSubtitleTrack> tracks, {
  required bool isTranscoding,
  required Set<int> sidecarSourceIds,
}) {
  if (!isTranscoding) {
    return tracks
        .where((track) {
          final requiresSidecar =
              track.isExternalFile || (!track.usesExternalDelivery && track.key != null && track.key!.isNotEmpty);
          return !requiresSidecar || sidecarSourceIds.contains(track.id);
        })
        .toList(growable: false);
  }
  return tracks
      .where((track) {
        if (sidecarSourceIds.contains(track.id)) return true;
        // A row the client has to fetch itself is selectable only once its sidecar resolved: when that
        // build failed nothing can put it on screen and reloading cannot help.
        //
        // Bitmaps are not fetched at all. The transcode profile offers image formats as `Embed` with
        // no `External` entry, so the server burns them into the picture - external files included -
        // and they never get a sidecar by design. Gating those on one made the active track vanish
        // from the picker while its captions were still burned into the video, with no row left to
        // switch or turn off. So burn eligibility is decided by the codec, not by where the row came
        // from.
        final burnedByServer = CodecUtils.isImageSubtitleCodec(track.codec);
        final requiresSidecar =
            !burnedByServer &&
            (track.isExternalFile || (!track.usesExternalDelivery && track.key != null && track.key!.isNotEmpty));
        if (requiresSidecar) return false;
        return CodecUtils.isTranscodableSubtitleCodec(track.codec);
      })
      .toList(growable: false);
}

@visibleForTesting
MediaSubtitleTrack? findNewExternalSubtitleTrack(List<MediaSubtitleTrack> tracks, Set<int> existingSourceIds) {
  for (final track in tracks) {
    if (track.isExternal && !existingSourceIds.contains(track.id)) return track;
  }
  return null;
}

@visibleForTesting
SubtitleDownloadApplyOutcome subtitleDownloadApplyOutcomeFor(PlaybackSourceChangeOutcome outcome) {
  return switch (outcome) {
    PlaybackSourceChangeOutcome.applied ||
    PlaybackSourceChangeOutcome.unchanged => SubtitleDownloadApplyOutcome.applied,
    PlaybackSourceChangeOutcome.busy => SubtitleDownloadApplyOutcome.busy,
    PlaybackSourceChangeOutcome.superseded => SubtitleDownloadApplyOutcome.superseded,
    PlaybackSourceChangeOutcome.unavailable => SubtitleDownloadApplyOutcome.unavailable,
    PlaybackSourceChangeOutcome.failed => SubtitleDownloadApplyOutcome.failed,
  };
}

@visibleForTesting
ShaderPreset resolveShaderTogglePreset({
  required ShaderPreset currentPreset,
  required ShaderPreset savedPreset,
  required List<ShaderPreset> allPresets,
}) {
  if (currentPreset.isEnabled) return ShaderPreset.none;
  if (savedPreset.isEnabled) return savedPreset;
  return allPresets.firstWhere((p) => p.isEnabled, orElse: () => ShaderPreset.nvscalerDefault);
}

@visibleForTesting
({
  List<MediaVersion> availableVersions,
  bool serverSupportsTranscoding,
  bool isTranscoding,
  List<MediaAudioTrack> sourceAudioTracks,
  int? selectedAudioStreamId,
  List<MediaSubtitleTrack> sourceSubtitleTracks,
  PlaybackSourceSubtitleChoice? selectedSubtitleChoice,
  bool canSwitch,
})
effectiveVersionQualityControls({
  required bool isOfflinePlayback,
  required List<MediaVersion> availableVersions,
  required bool serverSupportsTranscoding,
  required bool isTranscoding,
  required List<MediaAudioTrack> sourceAudioTracks,
  required int? selectedAudioStreamId,
  required List<MediaSubtitleTrack> sourceSubtitleTracks,
  required PlaybackSourceSubtitleChoice? selectedSubtitleChoice,
}) {
  if (isOfflinePlayback) {
    return (
      availableVersions: const <MediaVersion>[],
      serverSupportsTranscoding: false,
      isTranscoding: false,
      sourceAudioTracks: const <MediaAudioTrack>[],
      selectedAudioStreamId: null,
      sourceSubtitleTracks: const <MediaSubtitleTrack>[],
      selectedSubtitleChoice: null,
      canSwitch: false,
    );
  }
  return (
    availableVersions: availableVersions,
    serverSupportsTranscoding: serverSupportsTranscoding,
    isTranscoding: isTranscoding,
    sourceAudioTracks: sourceAudioTracks,
    selectedAudioStreamId: selectedAudioStreamId,
    sourceSubtitleTracks: sourceSubtitleTracks,
    selectedSubtitleChoice: selectedSubtitleChoice,
    canSwitch: true,
  );
}

@visibleForTesting
bool shouldShowSkipMarkerButton({
  required bool hasFirstFrame,
  required bool hasMarker,
  required bool hasPlayNextPrompt,
  required bool skipButtonDismissed,
  required bool controlsVisible,
}) {
  return hasFirstFrame && hasMarker && !hasPlayNextPrompt && (!skipButtonDismissed || controlsVisible);
}

/// The viewer's raw "Video Player Navigation" preference, ignoring TV.
///
/// Use this for genuine preferences — auto-hide delay, Escape semantics,
/// hardware transport interception. For "do arrow keys move focus in the
/// player?" use [playerDirectionalNavigationEnabled] instead: OR-ing `isTV()`
/// into a preference read changes behaviour for a TV viewer who turned the
/// preference off.
///
/// Reads through [SettingsService.instanceOrNull] because focus policy is
/// consulted from a global key handler that can run before startup finishes.
/// The pre-init answer is `false`; the preference's real default is
/// `TvDetectionService.isTVSync`, so a pre-init read understates it on TV —
/// harmless only because no player route, and so no
/// [DirectionalShortcutFocusNode], can mount before settings are loaded.
bool videoPlayerNavigationPreference() =>
    SettingsService.instanceOrNull?.read(SettingsService.videoPlayerNavigationEnabled) ?? false;

/// Whether the video player treats arrow / D-pad keys as focus navigation
/// rather than playback shortcuts. A television always navigates.
///
/// This is the single derivation of that policy. Every site that used to spell
/// it `pref || PlatformDetector.isTV()` by hand reads it from here.
bool playerDirectionalNavigationEnabled() => videoPlayerNavigationPreference() || PlatformDetector.isTV();

/// Builds one of the player's catch-all surface nodes.
///
/// Both the screen node and the player-surface node can hold primary focus
/// without the viewer ever having navigated — they autofocus and are actively
/// reclaimed — so an arrow pressed while they hold focus is a playback
/// shortcut, not traversal, and must not switch the app into keyboard mode.
/// Minting them here keeps that derivation in one place; [alsoOwns] adds the
/// per-key exceptions a surface still claims once navigation is enabled.
///
/// `skipTraversal` keeps these full-screen invisible nodes out of the Tab ring:
/// they are entered by autofocus and explicit requests, never by traversal.
DirectionalShortcutFocusNode playerSurfaceFocusNode(
  String debugLabel, {
  bool Function(LogicalKeyboardKey key)? alsoOwns,
}) {
  return DirectionalShortcutFocusNode(
    debugLabel: debugLabel,
    skipTraversal: true,
    consumesDirectionalKeys: (key) => !playerDirectionalNavigationEnabled() || (alsoOwns?.call(key) ?? false),
  );
}

@visibleForTesting
bool shouldShowClipButton({required bool isLive, required bool isDesktop, required bool hasClipHandler}) {
  return hasClipHandler && isDesktop && !isLive;
}

enum PlayerNavigationKey { none, physicalEscape, back, home }

enum PlayerBackDisposition { closeContentStrip, exitFullscreenIfActive, hideControls, exitPlayer }

bool shouldPhysicalEscapeExitFullscreen({
  required bool isMacOS,
  required bool videoPlayerNavigationEnabled,
  required bool playerEnteredFullscreen,
}) {
  return !isMacOS && !videoPlayerNavigationEnabled && playerEnteredFullscreen;
}

/// Coordinates the player-level stages shared by keyboard, controller, and
/// companion navigation after descendants have handled local overlays.
class PlayerNavigationCoordinator {
  final PlayerChromeController chromeController;
  final bool Function() isPromptOpen;
  final VoidCallback dismissPrompt;
  final bool Function() isChromePresented;
  final Future<bool> Function() exitFullscreenIfActive;
  final bool Function() _physicalEscapeExitsFullscreen;
  final bool Function() _exitPlayerBeforeChrome;
  final VoidCallback exitPlayer;
  final VoidCallback navigateHome;
  final bool Function() isActive;

  bool _handlingPhysicalEscape = false;

  PlayerNavigationCoordinator({
    required this.chromeController,
    required this.isPromptOpen,
    required this.dismissPrompt,
    required this.isChromePresented,
    required this.exitFullscreenIfActive,
    bool Function()? physicalEscapeExitsFullscreen,
    bool Function()? exitPlayerBeforeChrome,
    required this.exitPlayer,
    required this.navigateHome,
    bool Function()? isActive,
  }) : _physicalEscapeExitsFullscreen = physicalEscapeExitsFullscreen ?? _alwaysTrue,
       _exitPlayerBeforeChrome = exitPlayerBeforeChrome ?? _alwaysFalse,
       isActive = isActive ?? _alwaysActive;

  static bool _alwaysActive() => true;
  static bool _alwaysTrue() => true;
  static bool _alwaysFalse() => false;

  void handle(PlayerNavigationKey navigationKey) {
    if (navigationKey == PlayerNavigationKey.home) {
      navigateHome();
      return;
    }
    if (isPromptOpen()) {
      dismissPrompt();
      return;
    }
    if (navigationKey == PlayerNavigationKey.back && _exitPlayerBeforeChrome()) {
      // Mobile Back exits even with the chrome up (#1938); the staged
      // strip/fullscreen/hide/exit chain is TV and desktop behavior.
      exitPlayer();
      return;
    }
    final disposition = resolvePlayerBackDisposition(
      navigationKey: navigationKey,
      contentStripVisible: chromeController.contentStripVisible,
      controlsVisible: isChromePresented(),
      physicalEscapeExitsFullscreen: _physicalEscapeExitsFullscreen(),
    );
    _applyDisposition(disposition);
  }

  void _applyDisposition(PlayerBackDisposition disposition) {
    switch (disposition) {
      case PlayerBackDisposition.closeContentStrip:
        chromeController.setContentStripVisible(false);
        return;
      case PlayerBackDisposition.exitFullscreenIfActive:
        unawaited(_handlePhysicalEscape());
        return;
      case PlayerBackDisposition.hideControls:
        chromeController.hide();
        return;
      case PlayerBackDisposition.exitPlayer:
        exitPlayer();
        return;
    }
  }

  Future<void> _handlePhysicalEscape() async {
    if (_handlingPhysicalEscape) return;
    _handlingPhysicalEscape = true;
    final chromeWasPresented = isChromePresented();
    try {
      if (await exitFullscreenIfActive()) return;
      if (!isActive()) return;
      final disposition = resolvePlayerBackDisposition(
        navigationKey: PlayerNavigationKey.back,
        contentStripVisible: chromeController.contentStripVisible,
        controlsVisible: chromeWasPresented || isChromePresented(),
      );
      _applyDisposition(disposition);
    } finally {
      _handlingPhysicalEscape = false;
    }
  }
}

/// Whether a Back press should answer a visible skip prompt instead of walking
/// the screen's staged Back chain.
///
/// Mirrors the "sole affordance on screen" rule Select already uses in
/// `_activatePlayerSurfaceSelect`: the prompt owns the key only while the
/// chrome is down, the button is up, and the viewer can actually drive
/// playback. With the chrome up the button is an ordinary focusable control
/// and `skipButtonDismissed` would not hide it anyway, so Back stays the
/// chrome's own key there; without [canControl] the button is inert, and
/// eating a guest's exit press for a control they cannot operate is worse than
/// leaving the prompt up.
///
/// Both Back flavours count. A local layer takes the dismiss key ahead of the
/// screen's fullscreen and exit stages, the same way an open sheet already
/// swallows a physical Escape — and Escape is only a fullscreen key when
/// [shouldPhysicalEscapeExitFullscreen] holds, so excluding it would leave it
/// exiting the player outright on macOS, on a windowed player, or with player
/// navigation turned on.
///
/// Phones are excluded: there Back is unconditionally "leave the player"
/// (#1938), and a stage sitting above the coordinator would quietly revoke
/// that. So is an open playback prompt, whose own Back stage lives on the
/// screen and would otherwise never be reached.
bool shouldDismissSkipMarkerOnBack({
  required PlayerNavigationKey navigationKey,
  required bool controlsVisible,
  required bool skipMarkerButtonVisible,
  required bool canControl,
  required bool isMobile,
  required bool playbackPromptOpen,
}) {
  if (isMobile || playbackPromptOpen) return false;
  if (navigationKey != PlayerNavigationKey.back && navigationKey != PlayerNavigationKey.physicalEscape) {
    return false;
  }
  return canControl && !controlsVisible && skipMarkerButtonVisible;
}

// ignore: unused-code
PlayerBackDisposition resolvePlayerBackDisposition({
  required PlayerNavigationKey navigationKey,
  required bool contentStripVisible,
  required bool controlsVisible,
  bool physicalEscapeExitsFullscreen = true,
}) {
  assert(navigationKey == PlayerNavigationKey.physicalEscape || navigationKey == PlayerNavigationKey.back);
  if (contentStripVisible) return PlayerBackDisposition.closeContentStrip;
  if (navigationKey == PlayerNavigationKey.physicalEscape && physicalEscapeExitsFullscreen) {
    return PlayerBackDisposition.exitFullscreenIfActive;
  }
  return controlsVisible ? PlayerBackDisposition.hideControls : PlayerBackDisposition.exitPlayer;
}

/// Maps a key event to the player-level navigation stage it should drive.
///
/// [textEditingActive] defaults to [isTextEditingFocused]; inject it in tests.
/// Bare Backspace and Home double as player navigation *and* as caret editing
/// keys, so a focused text editor takes them back — otherwise typing in a
/// player sheet (subtitle search) walks the back pipeline out of the player
/// instead of correcting a character (#1741). Only physical-keyboard presses
/// are surrendered: a synthesized dpad/gamepad/companion press has no caret,
/// and [LogicalKeyboardKey.browserHome] is a dedicated navigation key with no
/// editing role at all.
PlayerNavigationKey classifyPlayerNavigationKey(
  KeyEvent event, {
  required bool isAppleTV,
  bool? hasModifiers,
  bool? textEditingActive,
}) {
  final key = event.logicalKey;
  if (key == LogicalKeyboardKey.escape) {
    return event.isPhysicalKeyboardEvent && !isAppleTV ? PlayerNavigationKey.physicalEscape : PlayerNavigationKey.back;
  }
  if (key.isBackKey) return PlayerNavigationKey.back;

  final modifiersPressed =
      hasModifiers ??
      (HardwareKeyboard.instance.isShiftPressed ||
          HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isAltPressed ||
          HardwareKeyboard.instance.isMetaPressed);
  // Resolved lazily: only the two editing keys below pay for the focus lookup.
  bool textEditorOwnsKey() => event.isPhysicalKeyboardEvent && (textEditingActive ?? isTextEditingFocused());

  if (key == LogicalKeyboardKey.backspace && event.isPhysicalKeyboardEvent && !modifiersPressed) {
    return textEditorOwnsKey() ? PlayerNavigationKey.none : PlayerNavigationKey.back;
  }
  if ((key == LogicalKeyboardKey.home || key == LogicalKeyboardKey.browserHome) && !modifiersPressed) {
    if (key == LogicalKeyboardKey.home && textEditorOwnsKey()) return PlayerNavigationKey.none;
    return PlayerNavigationKey.home;
  }
  return PlayerNavigationKey.none;
}

/// Gives the player route ownership of navigation that arrives while its
/// loading/error body is still establishing focus. The matching key-up still
/// performs the action through the normal [Focus.onKeyEvent] path.
bool primePlayerNavigationFocusForEvent(
  KeyEvent event, {
  required FocusNode focusNode,
  required bool playerReady,
  required bool isCurrentRoute,
  required bool isAppleTV,
}) {
  if (!isCurrentRoute || playerReady || event is! KeyDownEvent) return false;
  if (classifyPlayerNavigationKey(event, isAppleTV: isAppleTV) == PlayerNavigationKey.none) {
    return false;
  }
  focusNode.requestFocus();
  return true;
}

KeyEventResult handlePlayerNavigationKeyAction(
  KeyEvent event,
  PlayerNavigationKey navigationKey,
  VoidCallback onAction,
) {
  if (navigationKey == PlayerNavigationKey.none) return KeyEventResult.ignored;

  // macOS may also translate Backspace / Escape / browser Back into a route
  // pop on key-down. Suppress that parallel path before the player performs
  // its single staged action on key-up.
  if (navigationKey != PlayerNavigationKey.home && event is KeyDownEvent) {
    BackKeyCoordinator.markHandled();
  }
  if (event.logicalKey.isBackKey) return handleBackKeyAction(event, onAction);

  if (event is KeyUpEvent) {
    if (navigationKey != PlayerNavigationKey.home) {
      BackKeyCoordinator.markHandled();
    }
    onAction();
  }
  return KeyEventResult.handled;
}

@visibleForTesting
bool shouldSkipDuplicateTimelineSeek({required Duration? lastDispatchedSeek, required Duration finalSeek}) {
  return lastDispatchedSeek == finalSeek;
}

/// Directional seeking with the chrome hidden owns the whole key burst —
/// repeats accelerate in place rather than escalating to the timeline — so
/// both the initial press and its repeats perform a step.
@visibleForTesting
bool shouldStartHiddenDirectionalSeek(KeyEvent event) => event.isActionable;

typedef PlaybackSourceChangeCallback =
    Future<PlaybackSourceChangeOutcome> Function({
      int? newMediaIndex,
      TranscodeQualityPreset? newPreset,
      int? newAudioStreamId,
      PlaybackSourceSubtitleChoice? newSubtitleChoice,
    });

enum PlaybackSourceChangeOutcome { applied, unchanged, busy, unavailable, superseded, failed }

typedef _EdgeAdjustmentIndicatorState = ({bool visible, MobileEdgeAdjustmentSide? side, double value});

class PlexVideoControls extends StatefulWidget {
  final Player player;
  final VideoVolumeController volumeController;
  final MediaItem metadata;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final List<MediaVersion> availableVersions;
  final int selectedMediaIndex;
  final TranscodeQualityPreset selectedQualityPreset;
  final bool serverSupportsTranscoding;
  final bool isTranscoding;
  final bool isOfflinePlayback;
  final List<MediaAudioTrack> sourceAudioTracks;
  final int? selectedAudioStreamId;
  final List<MediaSubtitleTrack> sourceSubtitleTracks;
  final PlaybackSourceSubtitleChoice? selectedSubtitleChoice;
  final int? selectedSecondarySubtitleStreamId;
  final List<PlaybackSubtitleSidecar> sourceSubtitleSidecars;
  final int? sourcePartId;
  final PlaybackSourceChangeCallback? onPlaybackSourceChanged;
  final int boxFitMode;
  final PackedStereoLayout packedStereoLayout;
  final double videoZoomScale;
  final VoidCallback? onTogglePIPMode;
  final VoidCallback? onCycleBoxFitMode;
  final ValueChanged<double>? onVideoZoomChanged;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onResetVideoZoom;
  final VoidCallback? onCycleAudioTrack;
  final VoidCallback? onCycleSubtitleTrack;
  final Function(AudioTrack)? onAudioTrackChanged;
  final Function(SubtitleTrack)? onSubtitleTrackChanged;
  final Function(SubtitleTrack)? onSecondarySubtitleTrackChanged;
  final Future<void> Function()? onClipRequested;

  /// Called for app-level seek requests so the owning screen can coordinate
  /// playback state around the native player seek.
  final Future<void> Function(Duration position)? onSeekRequested;

  /// Called for app-level transport requests so the owning screen can track
  /// user playback intent separately from transient buffering state, and
  /// announce the accepted command.
  final Future<void> Function(TransportCommand command)? onPlayPauseRequested;

  /// Called when a seek operation completes (for Watch Together sync)
  final Function(Duration position)? onSeekCompleted;

  /// Called when back button is pressed (for Watch Together session leave confirmation)
  final VoidCallback? onBack;

  /// Called when the video has effectively reached the end (e.g. credits extend
  /// to EOF and can't be seeked past). Parent should route this into its normal
  /// completion flow so the auto-play-next setting is honored.
  final void Function({required bool skipAutoPlayCountdown})? onReachedEnd;

  /// Whether the user can control playback (false in host-only mode for non-host).
  final bool canControl;

  /// Whether the user may choose another queue item or episode. Watch
  /// Together guests never own this capability, even in anyone-control mode.
  final bool canNavigateMediaItems;

  /// Notifier for whether first video frame has rendered (shows loading state when false).
  final ValueNotifier<bool>? hasFirstFrame;

  /// Optional focus node for Play Next dialog button (for TV navigation from timeline)
  final FocusNode? playNextFocusNode;

  /// Whether a screen-level playback prompt (e.g. "Still watching?") owns the
  /// remote. The Play Next dialog announces itself through
  /// [playNextFocusNode]; the others have no node here, and a local layer must
  /// not answer a Back the prompt is waiting for.
  final bool playbackPromptOpen;

  /// Shared controller for player chrome visibility, auto-hide, and layout state.
  final PlayerChromeController chromeController;

  /// Optional shader service for MPV shader control
  final ShaderService? shaderService;

  /// Called when shader preset changes
  final VoidCallback? onShaderChanged;

  /// Optional callback that returns thumbnail image bytes for a given timestamp.
  final ScrubFrame? Function(Duration time)? thumbnailDataBuilder;

  /// Whether this is a live TV stream (disables seek, progress, etc.)
  final bool isLive;

  /// Channel name for live TV display
  final String? liveChannelName;

  /// Capture buffer for live TV time-shift (null = no time-shift support)
  final CaptureBuffer? captureBuffer;

  /// Whether playback is at the live edge
  final bool isAtLiveEdge;

  /// Epoch seconds corresponding to player position 0 (for live TV)
  final double streamStartEpoch;

  /// Current playback position as absolute epoch seconds (for live TV)
  final int? currentPositionEpoch;

  /// Seek callback for live TV time-shift (absolute epoch seconds; scrubber)
  final ValueChanged<int>? onLiveSeek;

  /// Relative live-TV skip callback (delta seconds). The owning screen
  /// accumulates rapid presses and debounces the transcode re-open, so skip
  /// buttons/dpad/remote keys must use this rather than `onLiveSeek` (#1253).
  final ValueChanged<int>? onLiveSeekBy;

  /// Jump to live edge callback
  final VoidCallback? onJumpToLive;

  /// Whether ambient lighting is enabled (passed to settings sheet)
  final bool isAmbientLightingEnabled;

  /// Called to toggle ambient lighting (passed to settings sheet)
  final VoidCallback? onToggleAmbientLighting;

  /// Toast controller for VLC-style in-player notifications (rate changes, backend switch).
  final PlayerToastController toastController;

  /// Seeds the chapter list so widget tests can exercise chapter-dependent
  /// behaviour without a media-server client. Production always loads through
  /// [VideoControlsPlaybackExtrasLoader].
  @visibleForTesting
  final List<MediaChapter>? initialChapters;

  /// Seeds the marker list so widget tests can exercise skip-marker behaviour
  /// without a media-server client. Production always loads through
  /// [VideoControlsPlaybackExtrasLoader].
  @visibleForTesting
  final List<MediaMarker>? initialMarkers;

  const PlexVideoControls({
    super.key,
    required this.player,
    required this.volumeController,
    required this.metadata,
    required this.toastController,
    this.initialChapters,
    this.initialMarkers,
    this.onNext,
    this.onPrevious,
    this.availableVersions = const [],
    this.selectedMediaIndex = 0,
    this.selectedQualityPreset = TranscodeQualityPreset.original,
    this.serverSupportsTranscoding = false,
    this.isTranscoding = false,
    this.isOfflinePlayback = false,
    this.sourceAudioTracks = const [],
    this.selectedAudioStreamId,
    this.sourceSubtitleTracks = const [],
    this.selectedSubtitleChoice,
    this.selectedSecondarySubtitleStreamId,
    this.sourceSubtitleSidecars = const <PlaybackSubtitleSidecar>[],
    this.sourcePartId,
    this.onPlaybackSourceChanged,
    this.boxFitMode = 0,
    this.packedStereoLayout = PackedStereoLayout.unknown,
    this.videoZoomScale = 1.0,
    this.onTogglePIPMode,
    this.onCycleBoxFitMode,
    this.onVideoZoomChanged,
    this.onZoomIn,
    this.onZoomOut,
    this.onResetVideoZoom,
    this.onCycleAudioTrack,
    this.onCycleSubtitleTrack,
    this.onAudioTrackChanged,
    this.onSubtitleTrackChanged,
    this.onSecondarySubtitleTrackChanged,
    this.onClipRequested,
    this.onSeekRequested,
    this.onPlayPauseRequested,
    this.onSeekCompleted,
    this.onBack,
    this.onReachedEnd,
    this.canControl = true,
    required this.canNavigateMediaItems,
    this.hasFirstFrame,
    this.playNextFocusNode,
    this.playbackPromptOpen = false,
    required this.chromeController,
    this.shaderService,
    this.onShaderChanged,
    this.thumbnailDataBuilder,
    this.isLive = false,
    this.liveChannelName,
    this.captureBuffer,
    this.isAtLiveEdge = true,
    this.streamStartEpoch = 0,
    this.currentPositionEpoch,
    this.onLiveSeek,
    this.onLiveSeekBy,
    this.onJumpToLive,
    this.isAmbientLightingEnabled = false,
    this.onToggleAmbientLighting,
  });

  @override
  State<PlexVideoControls> createState() => _PlexVideoControlsState();
}

class _PlexVideoControlsState extends State<PlexVideoControls>
    with WindowListener, SettingsEffectMixin, MountedSetStateMixin {
  bool get _showControls => widget.chromeController.controlsVisible;
  bool get _hasRenderedFirstFrame => widget.hasFirstFrame?.value ?? true;

  late bool _lastControlsVisible;
  late bool _controlsMounted;
  late bool _controlsOpaque;
  bool _isLoadingExtras = false;
  // Item key the in-flight extras load belongs to, so a load for a swapped
  // item can start while a stale one is still in flight (and the stale
  // response is discarded).
  String? _extrasLoadKey;
  late List<MediaChapter> _chapters = widget.initialChapters ?? [];
  late bool _chaptersLoaded = widget.initialChapters != null;
  bool _isFullscreen = false;
  bool _isAlwaysOnTop = false;
  late final FocusNode _focusNode;
  KeyboardShortcutsService? _keyboardService;
  // Live settings — read through the service so a change anywhere in the app
  // reflects here without a manual reload. UI rebuilds are wired via
  // [bindRebuild] in [initState]; side effects (rotation, sync) via [bindEffect].
  SettingsService get _settings => SettingsService.instance;
  int get _seekTimeSmall => _settings.read(SettingsService.seekTimeSmall);
  int get _rewindOnResume => _settings.read(SettingsService.rewindOnResume);
  // Resolved through the configured sync-offset scope so the sheet rows, the
  // tune indicator, and the sync-slider seed agree with the value the player
  // actually applies (video_player_screen resolves the same way).
  int get _audioSyncOffset => ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.audioSyncOffset, widget.metadata);
  int get _subtitleSyncOffset => ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.subtitleSyncOffset, widget.metadata);
  bool get _isRotationLocked => _settings.read(SettingsService.rotationLocked);
  bool _isScreenLocked = false; // Touch lock during playback
  bool _showLockIcon = false; // Whether to show the lock overlay icon
  Timer? _lockIconTimer;
  bool get _clickVideoTogglesPlayback => _settings.read(SettingsService.clickVideoTogglesPlayback);
  bool get _showChapterMarkersOnTimeline => _settings.read(SettingsService.showChapterMarkersOnTimeline);
  int _trafficLightVisibilityGeneration = 0;

  // GlobalKey to access DesktopVideoControls state for focus management
  final GlobalKey<DesktopVideoControlsState> _desktopControlsKey = GlobalKey<DesktopVideoControlsState>();

  // Double-tap feedback state
  bool _showDoubleTapFeedback = false;
  double _doubleTapFeedbackOpacity = 0.0;
  bool _lastDoubleTapWasForward = true;
  Timer? _feedbackTimer;
  final ValueNotifier<int> _accumulatedSkipSeconds = ValueNotifier<int>(0);
  // Desktop double-click detection (more reliable than Flutter's onDoubleTap).
  // The mobile skip zones do not use this; they pair off _singleTapTimer.
  DateTime? _lastSkipTapTime;
  // Direction of the skip-zone tap _singleTapTimer is currently counting down.
  bool _lastSkipTapWasForward = true;
  Timer? _feedbackHideTimer; // Removes the skip readout after its fade-out completes
  // Deferred lone-tap action for the skip zones, and the pairing window itself:
  // while it is active the tap that started it can still become a double tap.
  Timer? _singleTapTimer;
  final TwoFingerTapTracker _twoFingerTapTracker = TwoFingerTapTracker();
  final MobileEdgeAdjustmentTracker _edgeAdjustmentTracker = MobileEdgeAdjustmentTracker();
  final DeviceAdjustmentService _deviceAdjustmentService = DeviceAdjustmentService.instance;
  DateTime? _suppressTouchTapUntil;
  final ValueNotifier<_EdgeAdjustmentIndicatorState> _edgeAdjustmentIndicator = ValueNotifier((
    visible: false,
    side: null,
    value: 0.0,
  ));
  double? _edgeAdjustmentStartValue;
  bool _edgeAdjustmentWasActive = false;
  MobileEdgeAdjustmentSide? _pendingEdgeAdjustmentSide;
  double _pendingEdgeAdjustmentDelta = 0.0;
  int? _pendingEdgeAdjustmentGeneration;
  Future<double?>? _edgeAdjustmentBaselineFuture;
  MobileEdgeAdjustmentSide? _edgeAdjustmentBaselineSide;
  int _edgeAdjustmentBaselineGeneration = 0;
  double? _lastKnownBrightness;
  double? _lastKnownMediaVolume;
  DateTime? _lastEdgeAdjustmentWriteAt;
  double? _lastEdgeAdjustmentWriteValue;
  Timer? _edgeAdjustmentIndicatorHideTimer;
  Timer? _edgeAdjustmentIndicatorClearTimer;
  // Seek throttle
  late final Throttle _seekThrottle;
  Duration? _lastDispatchedTimelineSeek;
  Future<void>? _lastDispatchedTimelineSeekFuture;
  // Directional key seeking while the chrome is hidden (#1676). Owns the whole
  // key burst — repeats accelerate in place rather than escalating to the
  // timeline — and coalesces it into one absolute seek, like the timeline does.
  late final DebouncedSeekAccumulator _hiddenSeek;
  bool? _hiddenSeekForward;
  int _hiddenSeekRepeatCount = 0;
  // Current marker state
  MediaMarker? _currentMarker;

  /// Latched for the whole Back press; see [_handleLocalPlayerNavigationKeyEvent].
  bool _skipMarkerOwnsBackPress = false;
  late List<MediaMarker> _markers = widget.initialMarkers ?? [];
  late bool _markersLoaded = widget.initialMarkers != null;
  // Playback state subscription for auto-hide timer
  StreamSubscription<bool>? _playingSubscription;
  // Completed subscription to show controls when video ends
  StreamSubscription<bool>? _completedSubscription;
  // Position subscription for marker tracking
  StreamSubscription<Duration>? _positionSubscription;
  // Auto-skip state
  bool get _autoSkipIntro => _settings.read(SettingsService.autoSkipIntro);
  bool get _autoSkipCredits => _settings.read(SettingsService.autoSkipCredits);
  int get _autoSkipDelay => _settings.read(SettingsService.autoSkipDelay);
  Timer? _autoSkipTimer;
  final ValueNotifier<double> _autoSkipProgress = ValueNotifier<double>(0.0);
  final ValueNotifier<bool> _autoSkipActive = ValueNotifier<bool>(false);
  // Skip button dismiss state
  bool _skipButtonDismissed = false;
  Timer? _skipButtonDismissTimer;
  // Performance overlay
  bool get _showPerformanceOverlay => _settings.read(SettingsService.showPerformanceOverlay);
  bool get _autoHidePerformanceOverlay => _settings.read(SettingsService.autoHidePerformanceOverlay);
  // Long-press 2x speed state
  bool _isLongPressing = false;
  // Subtitle visibility toggle state
  bool _subtitlesVisible = true;
  bool _confirmedSubtitlesVisible = true;
  int _subtitleVisibilityWriteGeneration = 0;
  // Skip marker button focus node (for TV D-pad navigation)
  late final FocusNode _skipMarkerFocusNode;
  final ValueNotifier<bool> _fallbackHasFirstFrame = ValueNotifier<bool>(true);
  double? _rateBeforeLongPress;
  bool _showSpeedIndicator = false;
  StreamSubscription<double>? _rateSubscription;
  double? _lastReportedRate;
  // Suppression window used when long-press ends so the rate-restore emission
  // doesn't flash a second notice as the rate snaps back.
  DateTime? _suppressRateToastUntil;

  // PiP support
  bool _isPipSupported = false;
  final PipService _pipService = PipService();
  AppLifecycleListener? _edgeAdjustmentLifecycleListener;

  @override
  void initState() {
    super.initState();
    _lastControlsVisible = widget.chromeController.controlsVisible;
    _controlsMounted = _lastControlsVisible;
    _controlsOpaque = _lastControlsVisible;
    if (_controlsOpaque) widget.chromeController.markControlsOpaque();
    // Horizontal arrows stay the player's even with navigation enabled: with
    // the chrome down they run a hidden seek (see parts/key_events.dart), so
    // they are not evidence of a focus session. Up/Down raises the chrome and
    // is traversal, so it promotes.
    _focusNode = playerSurfaceFocusNode(
      'PlayerSurface',
      alsoOwns: (key) => !_showControls && (key.isLeftKey || key.isRightKey),
    );
    _skipMarkerFocusNode = FocusNode(debugLabel: 'SkipMarkerButton');
    _seekThrottle = throttle(
      (Duration pos) {
        unawaited(_seekToTimelinePosition(pos));
      },
      const Duration(milliseconds: 200),
      leading: true,
      trailing: true,
    );
    _hiddenSeek = DebouncedSeekAccumulator(
      currentPosition: () => widget.player.state.position,
      duration: () => widget.player.state.duration,
      seek: (target) => unawaited(_seekToPosition(target)),
      playheadJumps: widget.player.streams.playheadJump,
      // The badge is a promise about the coalesced burst. Once that burst is
      // abandoned — the timeline, a chapter jump, a peer, a stream rebuilt at a
      // resume position, a new item, a swapped player — the promise is void, so
      // take the readout down instead of leaving a total nothing will seek to
      // (#1819, keeping the #1676 badge-matches-seek invariant).
      onBurstAbandoned: _dismissSkipFeedback,
    );
    // Side effects: rotation lock + focus on nav-enable. Both fire immediately
    // so init wiring (orientation, focus) lives in one place.
    bindEffect<bool>(SettingsService.rotationLocked, _applyRotationLock);
    bindEffect<bool>(SettingsService.videoPlayerNavigationEnabled, (enabled) {
      _configureChromeController();
      if (enabled && _showControls) _focusPlayPauseIfKeyboardMode();
    }, fireImmediately: false);
    // Rebuild on any setting that affects build output (seek labels, skip
    // logic, perf overlay visibility, click-toggles, etc.).
    bindRebuild([
      SettingsService.seekTimeSmall,
      SettingsService.rewindOnResume,
      SettingsService.audioSyncOffset,
      SettingsService.subtitleSyncOffset,
      // The sync-offset getters resolve through ScopedPlayerPrefs, so scoped
      // writes and scope changes must rebuild too.
      SettingsService.scopedPlayerPrefValues,
      SettingsService.syncOffsetScope,
      SettingsService.rotationLocked,
      SettingsService.autoSkipIntro,
      SettingsService.autoSkipCredits,
      SettingsService.autoSkipDelay,
      SettingsService.videoPlayerNavigationEnabled,
      SettingsService.showPerformanceOverlay,
      SettingsService.autoHidePerformanceOverlay,
      SettingsService.clickVideoTogglesPlayback,
      SettingsService.showChapterMarkersOnTimeline,
    ]);
    widget.chromeController.addListener(_onChromeChanged);
    _configureChromeController();
    widget.chromeController.setPlaying(widget.player.state.playing);
    _initKeyboardService();
    _listenToPosition();
    _listenToPlayingState();
    _listenToCompleted();
    _checkPipSupport();
    _deviceAdjustmentService.onResume = _refreshDeviceAdjustmentValues;
    _deviceAdjustmentService.setRestoreSuppressed(_pipService.isPipActive.value);
    _pipService.isPipActive.addListener(_onEdgeAdjustmentPipChanged);
    _edgeAdjustmentLifecycleListener = AppLifecycleListener(
      onResume: _refreshDeviceAdjustmentValues,
      onShow: _refreshDeviceAdjustmentValues,
      onHide: _cancelEdgeAdjustmentGesture,
      onPause: _cancelEdgeAdjustmentGesture,
    );
    // Add window listener for tracking fullscreen state (for button icon)
    if (PlatformDetector.isDesktopOS()) {
      if (Platform.isMacOS) {
        _isFullscreen = FullscreenStateManager().isFullscreen;
        FullscreenStateManager().addListener(_onFullscreenStateChanged);
      }
      windowManager.addListener(this);
      _initAlwaysOnTopState();
    }

    // Register global key handler for focus-independent shortcuts (desktop only)
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
    // Listen for first frame to start auto-hide timer
    widget.hasFirstFrame?.addListener(_onFirstFrameReady);
    // Defer context-dependent initialization to after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Subscribe to rate stream *after* first frame so the initial
      // setRate(defaultSpeed) emission during player startup is missed.
      _lastReportedRate = widget.player.state.rate;
      _rateSubscription = widget.player.streams.rate.listen(_onRateChanged);
      _loadPlaybackExtras();
      // The player surface owns the remote whenever no chrome control was
      // deliberately given focus. A route that opens with the chrome already up
      // (every desktop route — see playerChromeStartsVisible) never runs the
      // hide transition that normally hands focus down here, and this Focus
      // autofocuses too late to win it back from the screen node claimed during
      // the loading phase. Leaving focus parked up there is what turns the first
      // actionable key into a chrome-raising self-heal instead of a playback
      // shortcut.
      if (!_focusPlayPauseIfKeyboardMode()) _claimPlayerSurfaceFocus();
      if (PlatformDetector.isMobile(context) && !PlatformDetector.isTV()) {
        _refreshDeviceAdjustmentValues();
      }
    });
  }

  void _setControlsState(VoidCallback fn) => setStateIfMounted(fn);

  void _configureChromeController() {
    widget.chromeController.configure(hideDelay: _hideDelay, hasFirstFrame: widget.hasFirstFrame?.value ?? true);
  }

  @override
  void didUpdateWidget(PlexVideoControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.player != widget.player) {
      ++_subtitleVisibilityWriteGeneration;
      // Otherwise the accumulator keeps listening to the retired player and
      // never hears the new one move.
      _hiddenSeek.attachPlayheadJumps(widget.player.streams.playheadJump);
    }
    if (oldWidget.chromeController != widget.chromeController) {
      oldWidget.chromeController.removeListener(_onChromeChanged);
      _lastControlsVisible = widget.chromeController.controlsVisible;
      _controlsMounted = _lastControlsVisible;
      _controlsOpaque = _lastControlsVisible;
      if (_controlsOpaque) widget.chromeController.markControlsOpaque();
      widget.chromeController.addListener(_onChromeChanged);
    }
    // The same controls instance survives in-place episode swaps — re-key
    // the per-item chapters/markers/skip state when the item changes.
    // (Quality/version switches keep the same item, so no refetch churn.)
    if (oldWidget.metadata.globalKey != widget.metadata.globalKey) {
      // A pending skip is an offset into the outgoing item's timeline; letting
      // it survive would rebase the next press onto the previous episode. This
      // is the lifecycle backstop for every route that replaces the item
      // without going through a wrapped next/previous callback — natural
      // completion, a peer, an external change — so it also has to reach the
      // desktop timeline's own accumulator and the shared readout.
      _hiddenSeek.cancel();
      _desktopControlsKey.currentState?.abandonPendingSeek();
      _dismissSkipFeedback();
      _setControlsState(() {
        _chapters = [];
        _chaptersLoaded = false;
        _markers = [];
        _markersLoaded = false;
      });
      _clearCurrentMarker();
      _loadPlaybackExtras();
    }
    _configureChromeController();
  }

  @override
  void dispose() {
    ++_subtitleVisibilityWriteGeneration;
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    widget.chromeController.removeListener(_onChromeChanged);
    widget.hasFirstFrame?.removeListener(_onFirstFrameReady);
    _feedbackTimer?.cancel();
    _feedbackHideTimer?.cancel();
    _accumulatedSkipSeconds.dispose();
    _lockIconTimer?.cancel();
    _edgeAdjustmentIndicatorHideTimer?.cancel();
    _edgeAdjustmentIndicatorClearTimer?.cancel();
    _edgeAdjustmentLifecycleListener?.dispose();
    _edgeAdjustmentLifecycleListener = null;
    _autoSkipTimer?.cancel();
    _autoSkipProgress.dispose();
    _autoSkipActive.dispose();
    _skipButtonDismissTimer?.cancel();
    _singleTapTimer?.cancel();
    _seekThrottle.cancel();
    _hiddenSeek.dispose();
    _edgeAdjustmentTracker.cancel();
    _edgeAdjustmentIndicator.dispose();
    _pipService.isPipActive.removeListener(_onEdgeAdjustmentPipChanged);
    _deviceAdjustmentService.onResume = null;
    _deviceAdjustmentService.setRestoreSuppressed(false);
    unawaited(_deviceAdjustmentService.restoreBrightness());
    // A player exit mid-scrub must not leak the hold into the route teardown.
    widget.chromeController.release(PlayerChromeHold.scrub, notify: false, restartAutoHide: false);
    _playingSubscription?.cancel();
    _completedSubscription?.cancel();
    _positionSubscription?.cancel();
    _rateSubscription?.cancel();
    _focusNode.dispose();
    _skipMarkerFocusNode.dispose();
    _fallbackHasFirstFrame.dispose();
    // Restore original rate if long-press was active when disposed
    if (_isLongPressing && _rateBeforeLongPress != null) {
      widget.player.setRate(_rateBeforeLongPress!);
    }
    // Remove window listener and reset always-on-top if it was enabled
    if (PlatformDetector.isDesktopOS()) {
      windowManager.removeListener(this);
      if (_isAlwaysOnTop) {
        windowManager.setAlwaysOnTop(false);
      }
    }
    if (Platform.isMacOS) {
      FullscreenStateManager().removeListener(_onFullscreenStateChanged);
      _trafficLightVisibilityGeneration++;
      unawaited(MacOSWindowService.setTrafficLightsVisible(true));
    }
    super.dispose();
  }

  void _onFullscreenStateChanged() {
    final isFullscreen = FullscreenStateManager().isFullscreen;
    if (!mounted || _isFullscreen == isFullscreen) return;
    setState(() {
      _isFullscreen = isFullscreen;
    });
    _updateTrafficLightVisibility();
  }

  void _onEdgeAdjustmentPipChanged() {
    final isInPip = _pipService.isPipActive.value;
    _deviceAdjustmentService.setRestoreSuppressed(isInPip);
    if (isInPip) {
      widget.chromeController.hold(PlayerChromeHold.pip);
      _cancelEdgeAdjustmentGesture();
    } else {
      widget.chromeController.release(PlayerChromeHold.pip);
    }
  }

  @override
  void onWindowEnterFullScreen() {
    if (mounted) {
      setState(() {
        _isFullscreen = true;
      });
    }
  }

  @override
  void onWindowLeaveFullScreen() {
    if (mounted) {
      setState(() {
        _isFullscreen = false;
      });
    }
  }

  @override
  void onWindowMaximize() {
    // On macOS, maximize is the same as fullscreen (green button)
    if (mounted && Platform.isMacOS) {
      setState(() {
        _isFullscreen = true;
      });
    }
  }

  @override
  void onWindowUnmaximize() {
    // On macOS, unmaximize means exiting fullscreen
    if (mounted && Platform.isMacOS) {
      setState(() {
        _isFullscreen = false;
      });
    }
  }

  /// Re-activating the window drops Flutter's primary focus to the root scope,
  /// and the enclosing player screen reclaims it onto its own node. Nothing
  /// hands it back down while the chrome stays visible — the hide transition is
  /// the only other handoff — so the next arrow key reaches the screen's
  /// self-heal and jumps focus into the OSD (#1797). Take the surface back
  /// unless a control below already owns it.
  @override
  void onWindowFocus() {
    // Claim now rather than post-frame: this arrives on a platform callback,
    // which is not guaranteed to be followed by a frame. The screen's own
    // reclaim re-tests `hasFocus` when it runs, so once the surface holds the
    // remote the two no longer compete.
    if (!mounted || _focusNode.hasFocus) return;
    // A route pushed above the player still leaves these controls mounted —
    // on this navigator or an ancestor one (root-navigator dialogs/picker);
    // re-activating the window must not pull the remote off the top route.
    if (!isRouteChainCurrent(context)) return;
    _claimPlayerSurfaceFocus();
  }

  @override
  // ignore: no-empty-block - required by WindowListener interface
  void onWindowResize() {}

  @override
  Widget build(BuildContext context) {
    final isMobile = PlatformDetector.isMobile(context) && !PlatformDetector.isTV();

    // Hide ALL controls when in PiP mode (except macOS where main window stays visible)
    return ValueListenableBuilder<bool>(
      valueListenable: _pipService.isPipActive,
      builder: (context, isInPip, _) {
        if (isInPip && !Platform.isMacOS) return const SizedBox.shrink();
        return Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: (node, event) => _handleControlsKeyEvent(event, isMobile),
          child: Listener(
            behavior: HitTestBehavior.translucent,
            // Any pointer input cancels an in-progress auto-skip countdown. This
            // root Listener observes every pointer event over the player without
            // consuming it, so it's the single cancel point for clicks, touches,
            // mouse moves, scroll, and trackpad. Keys are handled the same way in
            // _handleGlobalKeyEvent.
            onPointerDown: (event) {
              _cancelAutoSkipFromUserInteraction();
              if (isMobile) _handleTouchPointerDown(event);
            },
            onPointerHover: (_) => _cancelAutoSkipFromUserInteraction(),
            onPointerMove: isMobile ? _handleTouchPointerMove : null,
            onPointerUp: isMobile ? _handleTouchPointerUp : null,
            onPointerCancel: isMobile ? _handleTouchPointerCancel : null,
            onPointerSignal: _handlePointerSignal,
            onPointerPanZoomStart: (_) => _cancelAutoSkipFromUserInteraction(),
            child: MouseRegion(
              onHover: (_) => _showControlsFromPointerActivity(),
              child: Stack(
                children: [
                  // Keep-alive for Linux's idle GTK frame clock; inert on every
                  // other platform (the widget owns the platform decision).
                  // Windows must NOT tick here: forced repaints during playback
                  // perturb VRR scanout in fullscreen (#1707).
                  const Positioned(top: 0, left: 0, child: LinuxKeepAlive()),
                  // Also handles long-press for 2x speed.
                  Positioned.fill(
                    child: Semantics(
                      button: true,
                      label: _showControls
                          ? t.videoControls.hidePlaybackControls
                          : t.videoControls.showPlaybackControls,
                      onTap: _toggleControlsFromSemantics,
                      child: GestureDetector(
                        excludeFromSemantics: true,
                        onTap: _handleOuterTap,
                        onLongPressStart: (_) => _handleLongPressStart(),
                        onLongPressEnd: (_) => _handleLongPressEnd(),
                        onLongPressCancel: _handleLongPressCancel,
                        behavior: HitTestBehavior.opaque,
                        child: const ColoredBox(color: Colors.transparent),
                      ),
                    ),
                  ),
                  // Mobile double-tap zones for skip forward/backward
                  if (isMobile)
                    MobileSkipZones(
                      onTapInSkipZone: (isForward) => _handleTapInSkipZone(isForward: isForward),
                      onLongPressStart: (_) => _handleLongPressStart(),
                      onLongPressEnd: (_) => _handleLongPressEnd(),
                      onLongPressCancel: _handleLongPressCancel,
                    ),
                  // Custom controls overlay
                  // Positioned AFTER double-tap zones so controls receive taps first
                  Positioned.fill(
                    child: !_controlsMounted
                        ? const SizedBox.shrink()
                        : IgnorePointer(
                            ignoring: !_showControls,
                            child: FocusScope(
                              // Prevent focus from entering controls when hidden
                              canRequestFocus: _showControls,
                              child: AnimatedOpacity(
                                opacity: _controlsOpaque ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                onEnd: () {
                                  if (!_showControls) {
                                    widget.chromeController.markControlsHidden();
                                    if (_controlsMounted) {
                                      setState(() => _controlsMounted = false);
                                    }
                                  } else {
                                    // The fade-in genuinely completed, so a later
                                    // hide() can rely on a real fade-out retiring
                                    // controlsPresented via markControlsHidden.
                                    widget.chromeController.markControlsOpaque();
                                  }
                                },
                                child: Builder(
                                  builder: (context) {
                                    return GestureDetector(
                                      onTapUp: (details) => _handleControlsOverlayTap(details, _sizeOf(context)),
                                      onLongPressStart: (_) => _handleLongPressStart(),
                                      onLongPressEnd: (_) => _handleLongPressEnd(),
                                      onLongPressCancel: _handleLongPressCancel,
                                      behavior: HitTestBehavior.deferToChild,
                                      child: ValueListenableBuilder<bool>(
                                        valueListenable: widget.hasFirstFrame ?? _fallbackHasFirstFrame,
                                        builder: (context, hasFrame, child) {
                                          // Solid black while loading, scrim once frames flow.
                                          // Both states share one widget type: hasFrame flips
                                          // on every in-place episode switch / live-TV zap, and
                                          // a runtimeType change here would re-inflate the whole
                                          // controls subtree and drop its state.
                                          return RasterizedGradient(
                                            gradient: hasFrame
                                                ? LinearGradient(
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                    colors: [
                                                      Colors.black.withValues(alpha: 0.7),
                                                      Colors.transparent,
                                                      Colors.transparent,
                                                      Colors.black.withValues(alpha: 0.7),
                                                    ],
                                                    stops: const [0.0, 0.2, 0.8, 1.0],
                                                  )
                                                : const LinearGradient(colors: [Colors.black, Colors.black]),
                                            child: child,
                                          );
                                        },
                                        child: isMobile
                                            ? Listener(
                                                behavior: HitTestBehavior.translucent,
                                                onPointerDown: (_) {
                                                  if (!widget.chromeController.contentStripVisible) {
                                                    _restartHideTimerForCurrentPlaybackState();
                                                  }
                                                },
                                                child: Builder(
                                                  builder: (context) {
                                                    final playbackState = context.watch<PlaybackStateProvider>();
                                                    final canShowQueue =
                                                        playbackState.isQueueActive && widget.canNavigateMediaItems;
                                                    final hasStripContent = _chapters.isNotEmpty || canShowQueue;
                                                    return MobileVideoControls(
                                                      player: widget.player,
                                                      metadata: widget.metadata,
                                                      chapters: _chapters,
                                                      chaptersLoaded: _chaptersLoaded,
                                                      showChapterMarkersOnTimeline: _showChapterMarkersOnTimeline,
                                                      seekTimeSmall: _seekTimeSmall,
                                                      trackChapterControls: _buildTrackChapterControlsWidget(
                                                        hideChaptersAndQueue: hasStripContent,
                                                      ),
                                                      onSeek: _throttledSeek,
                                                      onSeekEnd: _finalizeSeek,
                                                      onScrubStart: _holdTimelineScrub,
                                                      onScrubEnd: _releaseTimelineScrub,
                                                      onSeekRequested: widget.onSeekRequested,
                                                      onSeekCompleted: widget.onSeekCompleted,
                                                      onPlayPause: () => unawaited(_playOrPause()),
                                                      onCancelAutoHide: widget.chromeController.cancelAutoHide,
                                                      onStartAutoHide: widget.chromeController.startAutoHide,
                                                      onBack: widget.onBack,
                                                      onNext: _abandoningBurst(widget.onNext),
                                                      onPrevious: _abandoningBurst(widget.onPrevious),
                                                      canControl: widget.canControl,
                                                      hasFirstFrame: widget.hasFirstFrame,
                                                      thumbnailDataBuilder: widget.thumbnailDataBuilder,
                                                      isLive: widget.isLive,
                                                      liveChannelName: widget.liveChannelName,
                                                      captureBuffer: widget.captureBuffer,
                                                      isAtLiveEdge: widget.isAtLiveEdge,
                                                      streamStartEpoch: widget.streamStartEpoch,
                                                      onLiveSeek: _liveSeekAbandoningBurst(widget.onLiveSeek),
                                                      serverId: widget.metadata.serverId,
                                                      showQueueTab: canShowQueue,
                                                      onQueueItemSelected: canShowQueue ? _onQueueItemSelected : null,
                                                      chromeController: widget.chromeController,
                                                      onStripVisibilityChanged: (visible) {
                                                        if (visible) {
                                                          widget.chromeController.setContentStripVisible(true);
                                                        } else {
                                                          widget.chromeController.setContentStripVisible(false);
                                                        }
                                                      },
                                                      isInEdgeAdjustmentZone: _isGlobalPositionInEdgeAdjustmentZone,
                                                    );
                                                  },
                                                ),
                                              )
                                            : _buildDesktopControlsListener(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                  ),
                  // Transient skip badge: mobile double-tap and keyboard/remote
                  // seeking both use it so neither has to raise the full chrome.
                  if (_showDoubleTapFeedback)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          opacity: _doubleTapFeedbackOpacity,
                          duration: tokens(context).slow,
                          child: RepaintBoundary(
                            child: DoubleTapFeedback(
                              isForward: _lastDoubleTapWasForward,
                              seconds: _accumulatedSkipSeconds,
                              animate: _doubleTapFeedbackOpacity > 0.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Speed indicator overlay for long-press 2x
                  if (_showSpeedIndicator) Positioned.fill(child: IgnorePointer(child: _buildSpeedIndicator())),
                  // Stream-driven transient feedback: an icon-only disc centred
                  // in the frame for accepted transport commands, a textual pill
                  // at the top for rate changes and other notices.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ListenableBuilder(
                        listenable: widget.toastController,
                        builder: (context, _) {
                          final toast = widget.toastController.current;
                          if (toast == null) return const SizedBox.shrink();
                          return switch (toast.kind) {
                            PlayerToastKind.transport => TransportFeedbackIndicator(
                              icon: toast.icon,
                              text: toast.text,
                              pulse: toast.pulse,
                            ),
                            PlayerToastKind.notice => AnimatedSwitcher(
                              duration: const Duration(milliseconds: 150),
                              child: PlayerToastIndicator(
                                key: ValueKey('${toast.icon.codePoint}:${toast.text}'),
                                icon: toast.icon,
                                text: toast.text,
                              ),
                            ),
                          };
                        },
                      ),
                    ),
                  ),
                  if (isMobile)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ValueListenableBuilder<_EdgeAdjustmentIndicatorState>(
                          valueListenable: _edgeAdjustmentIndicator,
                          builder: (context, indicator, _) {
                            final side = indicator.side;
                            if (side == null) {
                              return const SizedBox.shrink();
                            }
                            return AnimatedOpacity(
                              opacity: indicator.visible ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 160),
                              child: RepaintBoundary(
                                child: MobileEdgeAdjustmentIndicator(
                                  key: ValueKey(side),
                                  side: side,
                                  value: indicator.value,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  // Skip intro/credits button (auto-dismisses after 7s, then only shows with controls)
                  if (_isSkipMarkerButtonVisible)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      right: 24,
                      bottom: () {
                        if (!_showControls) return 24.0;
                        if (widget.chromeController.contentStripVisible) {
                          return 180.0;
                        }
                        return isMobile ? 80.0 : 115.0;
                      }(),
                      child: AnimatedOpacity(
                        opacity: 1.0,
                        duration: tokens(context).slow,
                        child: _buildSkipMarkerButton(),
                      ),
                    ),
                  if (_showPerformanceOverlay)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      top: _showControls ? (isMobile ? 100.0 : 60.0) : 16.0,
                      left: 16,
                      right: 16,
                      // Clear the bottom controls (same clearance as the skip button) so the
                      // overlay can shrink to fit instead of being clipped by the screen edge.
                      bottom: !_showControls ? 16.0 : (isMobile ? 80.0 : 115.0),
                      // Align loosens the tight constraints from the fully-anchored Positioned;
                      // without it the card would stretch to fill the whole region.
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: AnimatedOpacity(
                          opacity: (!_autoHidePerformanceOverlay || _showControls) ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: IgnorePointer(child: PlayerPerformanceOverlay(player: widget.player)),
                        ),
                      ),
                    ),
                  if (_isScreenLocked)
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() => _showLockIcon = true);
                          _startLockIconHideTimer();
                        },
                        onLongPress: _unlockScreen,
                        child: AnimatedOpacity(
                          opacity: _showLockIcon ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: const BorderRadius.all(Radius.circular(28)),
                              ),
                              child: Row(
                                mainAxisSize: .min,
                                children: [
                                  const AppIcon(Symbols.lock_rounded, fill: 1, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    t.videoControls.longPressToUnlock,
                                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: .w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
