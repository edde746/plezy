import 'dart:async' show StreamSubscription, Timer, unawaited;
import 'dart:io' show Platform;

import 'package:flutter/gestures.dart' show PointerSignalEvent, PointerScrollEvent;
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
import '../../services/scrub_preview_source.dart';
import '../../services/settings_service.dart';
import '../../utils/formatters.dart';
import '../../utils/platform_detector.dart';
import '../../utils/player_utils.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/provider_extensions.dart';
import '../../utils/snackbar_helper.dart';
import 'icons.dart';
import 'playback_extras_loader.dart';
import 'widgets/player_toast_indicator.dart';
import '../../utils/app_logger.dart';
import '../../i18n/strings.g.dart';
import '../../focus/input_mode_tracker.dart';
import 'models/track_controls_state.dart';
import 'widgets/double_tap_feedback.dart';
import 'widgets/linux_keep_alive.dart';
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

/// Custom video controls builder for Plex with chapter, audio, and subtitle support
Widget plexVideoControlsBuilder(
  Player player,
  MediaItem metadata, {
  VoidCallback? onNext,
  VoidCallback? onPrevious,
  List<MediaVersion>? availableVersions,
  int? selectedMediaIndex,
  TranscodeQualityPreset selectedQualityPreset = TranscodeQualityPreset.original,
  bool serverSupportsTranscoding = false,
  bool isTranscoding = false,
  bool isOfflinePlayback = false,
  List<MediaAudioTrack> sourceAudioTracks = const [],
  int? selectedAudioStreamId,
  VoidCallback? onTogglePIPMode,
  int boxFitMode = 0,
  VoidCallback? onCycleBoxFitMode,
  VoidCallback? onCycleAudioTrack,
  VoidCallback? onCycleSubtitleTrack,
  Function(AudioTrack)? onAudioTrackChanged,
  Function(SubtitleTrack)? onSubtitleTrackChanged,
  Function(SubtitleTrack)? onSecondarySubtitleTrackChanged,
  Function(Duration position)? onSeekCompleted,
  VoidCallback? onBack,
  void Function({required bool skipAutoPlayCountdown})? onReachedEnd,
  bool canControl = true,
  ValueNotifier<bool>? hasFirstFrame,
  FocusNode? playNextFocusNode,
  ValueNotifier<bool>? controlsVisible,
  ShaderService? shaderService,
  VoidCallback? onShaderChanged,
  ScrubFrame? Function(Duration time)? thumbnailDataBuilder,
  bool isLive = false,
  String? liveChannelName,
  CaptureBuffer? captureBuffer,
  bool isAtLiveEdge = true,
  double streamStartEpoch = 0,
  int? currentPositionEpoch,
  ValueChanged<int>? onLiveSeek,
  VoidCallback? onJumpToLive,
  bool isAmbientLightingEnabled = false,
  VoidCallback? onToggleAmbientLighting,
  required PlayerToastController toastController,
}) {
  return PlexVideoControls(
    player: player,
    metadata: metadata,
    toastController: toastController,
    onNext: onNext,
    onPrevious: onPrevious,
    availableVersions: availableVersions ?? [],
    selectedMediaIndex: selectedMediaIndex ?? 0,
    selectedQualityPreset: selectedQualityPreset,
    serverSupportsTranscoding: serverSupportsTranscoding,
    isTranscoding: isTranscoding,
    isOfflinePlayback: isOfflinePlayback,
    sourceAudioTracks: sourceAudioTracks,
    selectedAudioStreamId: selectedAudioStreamId,
    boxFitMode: boxFitMode,
    onTogglePIPMode: onTogglePIPMode,
    onCycleBoxFitMode: onCycleBoxFitMode,
    onCycleAudioTrack: onCycleAudioTrack,
    onCycleSubtitleTrack: onCycleSubtitleTrack,
    onAudioTrackChanged: onAudioTrackChanged,
    onSubtitleTrackChanged: onSubtitleTrackChanged,
    onSecondarySubtitleTrackChanged: onSecondarySubtitleTrackChanged,
    onSeekCompleted: onSeekCompleted,
    onBack: onBack,
    onReachedEnd: onReachedEnd,
    canControl: canControl,
    hasFirstFrame: hasFirstFrame,
    playNextFocusNode: playNextFocusNode,
    controlsVisible: controlsVisible,
    shaderService: shaderService,
    onShaderChanged: onShaderChanged,
    thumbnailDataBuilder: thumbnailDataBuilder,
    isLive: isLive,
    liveChannelName: liveChannelName,
    captureBuffer: captureBuffer,
    isAtLiveEdge: isAtLiveEdge,
    streamStartEpoch: streamStartEpoch,
    currentPositionEpoch: currentPositionEpoch,
    onLiveSeek: onLiveSeek,
    onJumpToLive: onJumpToLive,
    isAmbientLightingEnabled: isAmbientLightingEnabled,
    onToggleAmbientLighting: onToggleAmbientLighting,
  );
}

@visibleForTesting
({
  List<MediaVersion> availableVersions,
  bool serverSupportsTranscoding,
  bool isTranscoding,
  List<MediaAudioTrack> sourceAudioTracks,
  int? selectedAudioStreamId,
  bool canSwitch,
})
effectiveVersionQualityControls({
  required bool isOfflinePlayback,
  required List<MediaVersion> availableVersions,
  required bool serverSupportsTranscoding,
  required bool isTranscoding,
  required List<MediaAudioTrack> sourceAudioTracks,
  required int? selectedAudioStreamId,
}) {
  if (isOfflinePlayback) {
    return (
      availableVersions: const <MediaVersion>[],
      serverSupportsTranscoding: false,
      isTranscoding: false,
      sourceAudioTracks: const <MediaAudioTrack>[],
      selectedAudioStreamId: null,
      canSwitch: false,
    );
  }
  return (
    availableVersions: availableVersions,
    serverSupportsTranscoding: serverSupportsTranscoding,
    isTranscoding: isTranscoding,
    sourceAudioTracks: sourceAudioTracks,
    selectedAudioStreamId: selectedAudioStreamId,
    canSwitch: true,
  );
}

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
  final int boxFitMode;
  final VoidCallback? onTogglePIPMode;
  final VoidCallback? onCycleBoxFitMode;
  final VoidCallback? onCycleAudioTrack;
  final VoidCallback? onCycleSubtitleTrack;
  final Function(AudioTrack)? onAudioTrackChanged;
  final Function(SubtitleTrack)? onSubtitleTrackChanged;
  final Function(SubtitleTrack)? onSecondarySubtitleTrackChanged;

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

  /// Notifier for whether first video frame has rendered (shows loading state when false).
  final ValueNotifier<bool>? hasFirstFrame;

  /// Optional focus node for Play Next dialog button (for TV navigation from timeline)
  final FocusNode? playNextFocusNode;

  /// Notifier to report controls visibility to parent (for popup positioning)
  final ValueNotifier<bool>? controlsVisible;

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

  /// Seek callback for live TV time-shift (epoch seconds)
  final ValueChanged<int>? onLiveSeek;

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
    this.boxFitMode = 0,
    this.onTogglePIPMode,
    this.onCycleBoxFitMode,
    this.onCycleAudioTrack,
    this.onCycleSubtitleTrack,
    this.onAudioTrackChanged,
    this.onSubtitleTrackChanged,
    this.onSecondarySubtitleTrackChanged,
    this.onSeekCompleted,
    this.onBack,
    this.onReachedEnd,
    this.canControl = true,
    this.hasFirstFrame,
    this.playNextFocusNode,
    this.controlsVisible,
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
    this.onJumpToLive,
    this.isAmbientLightingEnabled = false,
    this.onToggleAmbientLighting,
  });

  @override
  State<PlexVideoControls> createState() => _PlexVideoControlsState();
}

class _PlexVideoControlsState extends State<PlexVideoControls> with WindowListener, SettingsEffectMixin {
  bool _showControls = true;
  bool _forceShowControls = false;
  bool _isLoadingExtras = false;
  List<MediaChapter> _chapters = [];
  bool _chaptersLoaded = false;
  Timer? _hideTimer;
  bool _isFullscreen = false;
  bool _isAlwaysOnTop = false;
  late final FocusNode _focusNode;
  KeyboardShortcutsService? _keyboardService;
  // Live settings — read through the service so a change anywhere in the app
  // reflects here without a manual reload. UI rebuilds are wired via
  // [bindRebuild] in [initState]; side effects (rotation, sync) via [bindEffect].
  SettingsService get _settings => SettingsService.instanceOrNull!;
  int get _seekTimeSmall => _settings.read(SettingsService.seekTimeSmall);
  int get _rewindOnResume => _settings.read(SettingsService.rewindOnResume);
  int get _audioSyncOffset => _settings.read(SettingsService.audioSyncOffset);
  int get _subtitleSyncOffset => _settings.read(SettingsService.subtitleSyncOffset);
  bool get _isRotationLocked => _settings.read(SettingsService.rotationLocked);
  bool _isScreenLocked = false; // Touch lock during playback
  bool _showLockIcon = false; // Whether to show the lock overlay icon
  Timer? _lockIconTimer;
  bool get _clickVideoTogglesPlayback => _settings.read(SettingsService.clickVideoTogglesPlayback);
  bool _isContentStripVisible = false; // Whether the swipe-up content strip is showing
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
  DateTime? _lastSkipActionTime; // Debounce: prevents double-tap counting as 2 skips
  Timer? _singleTapTimer; // Timer for delayed single-tap action (toggle controls)
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

  @override
  void initState() {
    super.initState();
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
    ]);
    _startHideTimer();
    _initKeyboardService();
    _listenToPosition();
    _listenToPlayingState();
    _listenToCompleted();
    _checkPipSupport();
    // Add window listener for tracking fullscreen state (for button icon)
    if (PlatformDetector.isDesktopOS()) {
      windowManager.addListener(this);
      _initAlwaysOnTopState();
    }

    // Register global key handler for focus-independent shortcuts (desktop only)
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
    // Listen for first frame to start auto-hide timer
    widget.hasFirstFrame?.addListener(_onFirstFrameReady);
    // Listen for external requests to show controls (e.g. screen-level focus recovery)
    widget.controlsVisible?.addListener(_onControlsVisibleExternal);
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
    });
  }

  void _setControlsState(VoidCallback fn) => setState(fn);

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    widget.controlsVisible?.removeListener(_onControlsVisibleExternal);
    widget.hasFirstFrame?.removeListener(_onFirstFrameReady);
    _hideTimer?.cancel();
    _feedbackTimer?.cancel();
    _lockIconTimer?.cancel();
    _autoSkipTimer?.cancel();
    _skipButtonDismissTimer?.cancel();
    _singleTapTimer?.cancel();
    _seekThrottle.cancel();
    _playingSubscription?.cancel();
    _completedSubscription?.cancel();
    _positionSubscription?.cancel();
    _rateSubscription?.cancel();
    _focusNode.dispose();
    _skipMarkerFocusNode.dispose();
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
      _pipService.isPipActive.removeListener(_onMacPipChanged);
      _trafficLightVisibilityGeneration++;
      unawaited(MacOSWindowService.setTrafficLightsVisible(true));
    }
    super.dispose();
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
    // Use desktop controls for desktop platforms AND Android TV
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
            onPointerHover: (_) => _showControlsFromPointerActivity(),
            onPointerSignal: _handlePointerSignal,
            child: MouseRegion(
              cursor: (_showControls || _forceShowControls) ? SystemMouseCursors.basic : SystemMouseCursors.none,
              onHover: (_) => _showControlsFromPointerActivity(),
              onExit: (_) => _hideControlsFromPointerExit(),
              child: Stack(
                children: [
                  // Keep-alive: 1px widget that continuously repaints to prevent
                  // Flutter animations from freezing when the frame clock goes idle
                  if (Platform.isLinux || Platform.isWindows)
                    const Positioned(top: 0, left: 0, child: LinuxKeepAlive()),
                  // Invisible tap detector that always covers the full area.
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
                        canRequestFocus: _showControls || _forceShowControls,
                        child: AnimatedOpacity(
                          opacity: (_showControls || _forceShowControls) ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return GestureDetector(
                                onTapUp: (details) => _handleControlsOverlayTap(details, constraints),
                                onLongPressStart: (_) => _handleLongPressStart(),
                                onLongPressEnd: (_) => _handleLongPressEnd(),
                                onLongPressCancel: _handleLongPressCancel,
                                behavior: HitTestBehavior.deferToChild,
                                child: ValueListenableBuilder<bool>(
                                  valueListenable: widget.hasFirstFrame ?? ValueNotifier(true),
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
                                            if (!_isContentStripVisible) _restartHideTimerIfPlaying();
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
                                                seekTimeSmall: _seekTimeSmall,
                                                trackChapterControls: _buildTrackChapterControlsWidget(
                                                  hideChaptersAndQueue: hasStripContent,
                                                ),
                                                onSeek: _throttledSeek,
                                                onSeekEnd: _finalizeSeek,
                                                onSeekCompleted: widget.onSeekCompleted,
                                                // ignore: no-empty-block - play/pause handled by parent VideoControlsState
                                                onPlayPause: () {},
                                                onCancelAutoHide: () => _hideTimer?.cancel(),
                                                onStartAutoHide: _startHideTimer,
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
                                                controlsVisible: widget.controlsVisible,
                                                onStripVisibilityChanged: (visible) {
                                                  setState(() => _isContentStripVisible = visible);
                                                  if (visible) {
                                                    _hideTimer?.cancel();
                                                  } else {
                                                    _restartHideTimerIfPlaying();
                                                  }
                                                },
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
                  // Skip intro/credits button (auto-dismisses after 7s, then only shows with controls)
                  if (_currentMarker != null && (!_skipButtonDismissed || _showControls))
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      right: 24,
                      bottom: () {
                        if (!_showControls) return 24.0;
                        if (_isContentStripVisible) return 180.0;
                        return isMobile ? 80.0 : 115.0;
                      }(),
                      child: AnimatedOpacity(
                        opacity: 1.0,
                        duration: tokens(context).slow,
                        child: _buildSkipMarkerButton(),
                      ),
                    ),
                  // Performance overlay (top-left)
                  if (_showPerformanceOverlay)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      top: _showControls && isMobile ? 80.0 : 16.0,
                      left: 16,
                      child: AnimatedOpacity(
                        opacity: (!_autoHidePerformanceOverlay || _showControls || _forceShowControls) ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: IgnorePointer(child: PlayerPerformanceOverlay(player: widget.player)),
                      ),
                    ),
                  // Screen lock overlay - absorbs all touches when active
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
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const AppIcon(Symbols.lock_rounded, fill: 1, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    t.videoControls.longPressToUnlock,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
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
