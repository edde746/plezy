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
        HardwareKeyboard;
import '../../services/fullscreen_state_manager.dart';
import '../../services/macos_window_service.dart';
import '../../services/pip_service.dart';
import 'package:window_manager/window_manager.dart';

import '../../mixins/settings_effect_mixin.dart';
import '../../mixins/mounted_set_state_mixin.dart';
import '../../mpv/mpv.dart';
import '../overlay_sheet.dart';
import '../../focus/dpad_navigator.dart';

import '../../database/app_database.dart';
import '../../media/media_backend.dart';
import '../../media/media_item.dart';
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
import '../../services/settings_service.dart';
import '../../utils/codec_utils.dart';
import '../../utils/formatters.dart';
import '../../utils/platform_detector.dart';
import '../../utils/player_utils.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/provider_extensions.dart';
import '../../utils/snackbar_helper.dart';
import 'icons.dart';
import 'player_chrome_controller.dart';
import 'playback_extras_loader.dart';
import 'widgets/player_toast_indicator.dart';
import '../../utils/app_logger.dart';
import '../../i18n/strings.g.dart';
import '../../focus/input_mode_tracker.dart';
import 'models/track_controls_state.dart';
import 'widgets/double_tap_feedback.dart';
import 'helpers/mobile_edge_adjustment_tracker.dart';
import 'helpers/two_finger_double_tap_tracker.dart';
import 'widgets/linux_keep_alive.dart';
import 'widgets/mobile_edge_adjustment_indicator.dart';
import 'widgets/mobile_skip_zones.dart';
import 'widgets/skip_marker_button.dart';
import 'widgets/track_chapter_controls.dart';
import 'widgets/performance_overlay/performance_overlay.dart';
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
/// While transcoding, only tracks the HTTP/MKV stream can actually deliver are
/// shown: keyed sidecars plus any codec the transcode can embed (text or
/// image — see [CodecUtils.isEmbeddableSubtitleCodec]). Outside transcode the
/// full list is returned unchanged, since the player has direct access to every
/// embedded stream.
List<MediaSubtitleTrack> selectableSourceSubtitleTracks(
  List<MediaSubtitleTrack> tracks, {
  required bool isTranscoding,
}) {
  if (!isTranscoding) return tracks;
  return tracks
      .where((track) {
        final hasKey = track.key != null && track.key!.isNotEmpty;
        return hasKey || CodecUtils.isEmbeddableSubtitleCodec(track.codec);
      })
      .toList(growable: false);
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
  int? selectedSubtitleStreamId,
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
  required int? selectedSubtitleStreamId,
}) {
  if (isOfflinePlayback) {
    return (
      availableVersions: const <MediaVersion>[],
      serverSupportsTranscoding: false,
      isTranscoding: false,
      sourceAudioTracks: const <MediaAudioTrack>[],
      selectedAudioStreamId: null,
      sourceSubtitleTracks: const <MediaSubtitleTrack>[],
      selectedSubtitleStreamId: null,
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
    selectedSubtitleStreamId: selectedSubtitleStreamId,
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

@visibleForTesting
KeyEventResult handlePromptDismissBackKey(KeyEvent event, VoidCallback? onDismissPrompt) {
  if (onDismissPrompt == null || !event.logicalKey.isBackKey) return KeyEventResult.ignored;
  return handleBackKeyAction(event, onDismissPrompt);
}

typedef PlaybackSourceChangeCallback =
    Future<void> Function({
      int? newMediaIndex,
      TranscodeQualityPreset? newPreset,
      int? newAudioStreamId,
      int? newSubtitleStreamId,
    });

typedef _EdgeAdjustmentIndicatorState = ({bool visible, MobileEdgeAdjustmentSide? side, double value});

class PlexVideoControls extends StatefulWidget {
  final Player player;
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
  final int? selectedSubtitleStreamId;
  final int? sourcePartId;
  final PlaybackSourceChangeCallback? onPlaybackSourceChanged;
  final int boxFitMode;
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

  /// Called for app-level seek requests. Plex transcodes use this to restart
  /// the server-side transcode session at the requested absolute timestamp.
  final Future<void> Function(Duration position)? onSeekRequested;

  /// Called for app-level play/pause requests so the owning screen can track
  /// user playback intent separately from transient buffering state.
  final Future<void> Function()? onPlayPauseRequested;

  /// Called when a seek operation completes (for Watch Together sync)
  final Function(Duration position)? onSeekCompleted;

  /// Called when back button is pressed (for Watch Together session leave confirmation)
  final VoidCallback? onBack;

  /// Called when Back should dismiss a visible playback prompt before normal
  /// player back handling.
  final VoidCallback? onDismissPrompt;

  /// Called when the video has effectively reached the end (e.g. credits extend
  /// to EOF and can't be seeked past). Parent should route this into its normal
  /// completion flow so the auto-play-next setting is honored.
  final void Function({required bool skipAutoPlayCountdown})? onReachedEnd;

  /// Whether the user can control playback (false in host-only mode for non-host).
  final bool canControl;

  /// Notifier for whether first video frame has rendered (shows loading state when false).
  final ValueNotifier<bool>? hasFirstFrame;

  /// Optional focus node for Play Next dialog button (for TV navigation from timeline)
  final FocusNode? playNextFocusNode;

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

  const PlexVideoControls({
    super.key,
    required this.player,
    required this.metadata,
    required this.toastController,
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
    this.selectedSubtitleStreamId,
    this.sourcePartId,
    this.onPlaybackSourceChanged,
    this.boxFitMode = 0,
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
    this.onSeekRequested,
    this.onPlayPauseRequested,
    this.onSeekCompleted,
    this.onBack,
    this.onDismissPrompt,
    this.onReachedEnd,
    this.canControl = true,
    this.hasFirstFrame,
    this.playNextFocusNode,
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
  bool _isLoadingExtras = false;
  // Item key the in-flight extras load belongs to, so a load for a swapped
  // item can start while a stale one is still in flight (and the stale
  // response is discarded).
  String? _extrasLoadKey;
  List<MediaChapter> _chapters = [];
  bool _chaptersLoaded = false;
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
  int get _audioSyncOffset => _settings.read(SettingsService.audioSyncOffset);
  int get _subtitleSyncOffset => _settings.read(SettingsService.subtitleSyncOffset);
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
  int _accumulatedSkipSeconds = 0; // Stacking skip: total skip during active feedback
  // Custom tap detection state (more reliable than Flutter's onDoubleTap)
  DateTime? _lastSkipTapTime;
  bool _lastSkipTapWasForward = true;
  Timer? _feedbackHideTimer; // Removes the skip pill after its fade-out completes
  Timer? _singleTapTimer; // Timer for delayed single-tap action (toggle controls)
  final TwoFingerDoubleTapTracker _twoFingerDoubleTapTracker = TwoFingerDoubleTapTracker();
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
  // Current marker state
  MediaMarker? _currentMarker;
  List<MediaMarker> _markers = [];
  bool _markersLoaded = false;
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
  double _autoSkipProgress = 0.0;
  // Skip button dismiss state
  bool _skipButtonDismissed = false;
  Timer? _skipButtonDismissTimer;
  // Video player navigation (use arrow keys to navigate controls)
  bool get _videoPlayerNavigationEnabled => _settings.read(SettingsService.videoPlayerNavigationEnabled);
  // Performance overlay
  bool get _showPerformanceOverlay => _settings.read(SettingsService.showPerformanceOverlay);
  bool get _autoHidePerformanceOverlay => _settings.read(SettingsService.autoHidePerformanceOverlay);
  // Long-press 2x speed state
  bool _isLongPressing = false;
  // Subtitle visibility toggle state
  bool _subtitlesVisible = true;
  // Skip marker button focus node (for TV D-pad navigation)
  late final FocusNode _skipMarkerFocusNode;
  final ValueNotifier<bool> _fallbackHasFirstFrame = ValueNotifier<bool>(true);
  double? _rateBeforeLongPress;
  bool _showSpeedIndicator = false;
  StreamSubscription<double>? _rateSubscription;
  double? _lastReportedRate;
  // Suppression window used when long-press ends so the rate-restore emission
  // doesn't flash a second pill as the rate snaps back.
  DateTime? _suppressRateToastUntil;

  // PiP support
  bool _isPipSupported = false;
  final PipService _pipService = PipService();
  AppLifecycleListener? _edgeAdjustmentLifecycleListener;

  @override
  void initState() {
    super.initState();
    _lastControlsVisible = widget.chromeController.controlsVisible;
    _focusNode = FocusNode();
    _skipMarkerFocusNode = FocusNode(debugLabel: 'SkipMarkerButton');
    _seekThrottle = throttle(
      (Duration pos) {
        unawaited(_seekToPosition(pos, notifyCompletion: false));
      },
      const Duration(milliseconds: 200),
      leading: true,
      trailing: true,
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
    // On macOS, show controls and disable auto-hide when PiP activates
    if (Platform.isMacOS) {
      _pipService.isPipActive.addListener(_onMacPipChanged);
    }

    // Defer context-dependent initialization to after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Subscribe to rate stream *after* first frame so the initial
      // setRate(defaultSpeed) emission during player startup is missed.
      _lastReportedRate = widget.player.state.rate;
      _rateSubscription = widget.player.streams.rate.listen(_onRateChanged);
      _loadPlaybackExtras();
      _focusPlayPauseIfKeyboardMode();
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
    if (oldWidget.chromeController != widget.chromeController) {
      oldWidget.chromeController.removeListener(_onChromeChanged);
      _lastControlsVisible = widget.chromeController.controlsVisible;
      widget.chromeController.addListener(_onChromeChanged);
    }
    // The same controls instance survives in-place episode swaps — re-key
    // the per-item chapters/markers/skip state when the item changes.
    // (Quality/version switches keep the same item, so no refetch churn.)
    if (oldWidget.metadata.globalKey != widget.metadata.globalKey) {
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
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    widget.chromeController.removeListener(_onChromeChanged);
    widget.hasFirstFrame?.removeListener(_onFirstFrameReady);
    _feedbackTimer?.cancel();
    _feedbackHideTimer?.cancel();
    _lockIconTimer?.cancel();
    _edgeAdjustmentIndicatorHideTimer?.cancel();
    _edgeAdjustmentIndicatorClearTimer?.cancel();
    _edgeAdjustmentLifecycleListener?.dispose();
    _edgeAdjustmentLifecycleListener = null;
    _autoSkipTimer?.cancel();
    _skipButtonDismissTimer?.cancel();
    _singleTapTimer?.cancel();
    _seekThrottle.cancel();
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
      _pipService.isPipActive.removeListener(_onMacPipChanged);
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
    if (isInPip) _cancelEdgeAdjustmentGesture();
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
                  // Keep-alive: 1px widget that continuously repaints to prevent
                  // Flutter animations from freezing when the frame clock goes idle
                  if (Platform.isLinux || Platform.isWindows)
                    const Positioned(top: 0, left: 0, child: LinuxKeepAlive()),
                  // Also handles long-press for 2x speed.
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _handleOuterTap,
                      onLongPressStart: (_) => _handleLongPressStart(),
                      onLongPressEnd: (_) => _handleLongPressEnd(),
                      onLongPressCancel: _handleLongPressCancel,
                      behavior: HitTestBehavior.opaque,
                      child: const ColoredBox(color: Colors.transparent),
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
                    child: IgnorePointer(
                      ignoring: !_showControls,
                      child: FocusScope(
                        // Prevent focus from entering controls when hidden
                        canRequestFocus: _showControls,
                        child: AnimatedOpacity(
                          opacity: _showControls ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
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
                                    return Container(
                                      decoration: BoxDecoration(
                                        // Use solid black when loading, gradient when loaded
                                        color: hasFrame ? null : Colors.black,
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
                                            : null,
                                      ),
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
                                              final hasStripContent =
                                                  _chapters.isNotEmpty || playbackState.isQueueActive;
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
                                                // ignore: no-empty-block - play/pause handled by parent VideoControlsState
                                                onPlayPause: () {},
                                                onCancelAutoHide: widget.chromeController.cancelAutoHide,
                                                onStartAutoHide: widget.chromeController.startAutoHide,
                                                onBack: widget.onBack,
                                                onNext: widget.onNext,
                                                onPrevious: widget.onPrevious,
                                                canControl: widget.canControl,
                                                hasFirstFrame: widget.hasFirstFrame,
                                                thumbnailDataBuilder: widget.thumbnailDataBuilder,
                                                isLive: widget.isLive,
                                                liveChannelName: widget.liveChannelName,
                                                captureBuffer: widget.captureBuffer,
                                                isAtLiveEdge: widget.isAtLiveEdge,
                                                streamStartEpoch: widget.streamStartEpoch,
                                                onLiveSeek: widget.onLiveSeek,
                                                serverId: widget.metadata.serverId,
                                                showQueueTab: playbackState.isQueueActive,
                                                onQueueItemSelected: playbackState.isQueueActive
                                                    ? _onQueueItemSelected
                                                    : null,
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
                  // Visual feedback overlay for double-tap
                  if (isMobile && _showDoubleTapFeedback)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          opacity: _doubleTapFeedbackOpacity,
                          duration: tokens(context).slow,
                          child: DoubleTapFeedback(
                            isForward: _lastDoubleTapWasForward,
                            seconds: _accumulatedSkipSeconds,
                          ),
                        ),
                      ),
                    ),
                  // Speed indicator overlay for long-press 2x
                  if (_showSpeedIndicator) Positioned.fill(child: IgnorePointer(child: _buildSpeedIndicator())),
                  // Stream-driven VLC-style pill (rate changes, backend-switch notifications)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ListenableBuilder(
                        listenable: widget.toastController,
                        builder: (context, _) {
                          final toast = widget.toastController.current;
                          if (toast == null) return const SizedBox.shrink();
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: PlayerToastIndicator(
                              key: ValueKey('${toast.icon.codePoint}:${toast.text}'),
                              icon: toast.icon,
                              text: toast.text,
                            ),
                          );
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
                            if (side == null) return const SizedBox.shrink();
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
                        if (widget.chromeController.contentStripVisible) return 180.0;
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
                      child: AnimatedOpacity(
                        opacity: (!_autoHidePerformanceOverlay || _showControls) ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: IgnorePointer(child: PlayerPerformanceOverlay(player: widget.player)),
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
