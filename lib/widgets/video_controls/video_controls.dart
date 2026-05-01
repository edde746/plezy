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

import '../../mpv/mpv.dart';
import '../overlay_sheet.dart';
import '../../focus/dpad_navigator.dart';
import '../../focus/focusable_wrapper.dart';

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
import '../../services/cached_playback_metadata_service.dart';
import '../../services/scrub_preview_source.dart';
import '../../services/settings_service.dart';
import '../../utils/formatters.dart';
import '../../utils/global_key_utils.dart';
import '../../utils/platform_detector.dart';
import '../../utils/player_utils.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/provider_extensions.dart';
import '../../utils/snackbar_helper.dart';
import 'icons.dart';
import 'widgets/player_toast_indicator.dart';
import '../../utils/app_logger.dart';
import '../../i18n/strings.g.dart';
import '../../focus/input_mode_tracker.dart';
import 'models/track_controls_state.dart';
import 'widgets/track_chapter_controls.dart';
import 'widgets/performance_overlay/performance_overlay.dart';
import 'mobile_video_controls.dart';
import 'desktop_video_controls.dart';
import 'package:provider/provider.dart';

import '../../models/shader_preset.dart';
import '../../providers/playback_state_provider.dart';
import '../../providers/shader_provider.dart';
import '../../services/shader_service.dart';

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
  VoidCallback? onReachedEnd,
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
  /// to EOF and can't be seeked past). Parent should route this into its
  /// normal completion flow so the auto-play-next setting is honored.
  final VoidCallback? onReachedEnd;

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

class _PlexVideoControlsState extends State<PlexVideoControls>
    with WindowListener, WidgetsBindingObserver, TickerProviderStateMixin {
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
  int _seekTimeSmall = 10; // Default, loaded from settings
  int _rewindOnResume = 0; // Default, loaded from settings
  int _audioSyncOffset = 0; // Default, loaded from settings
  int _subtitleSyncOffset = 0; // Default, loaded from settings
  bool _isRotationLocked = true; // Default locked (landscape only)
  bool _isScreenLocked = false; // Touch lock during playback
  bool _showLockIcon = false; // Whether to show the lock overlay icon
  Timer? _lockIconTimer;
  bool _clickVideoTogglesPlayback = false; // Default, loaded from settings
  bool _isContentStripVisible = false; // Whether the swipe-up content strip is showing

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
  DateTime? _lastSkipMarkerActionTime; // Debounce for skip-marker button only
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
  bool _autoSkipIntro = false;
  bool _autoSkipCredits = false;
  int _autoSkipDelay = 5;
  Timer? _autoSkipTimer;
  double _autoSkipProgress = 0.0;
  AnimationController? _autoSkipController;
  // Skip button dismiss state
  bool _skipButtonDismissed = false;
  Timer? _skipButtonDismissTimer;
  // Video player navigation (use arrow keys to navigate controls)
  bool _videoPlayerNavigationEnabled = false;
  // Performance overlay
  bool _showPerformanceOverlay = false;
  bool _autoHidePerformanceOverlay = true;
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
    _loadSeekTimes();
    _startHideTimer();
    _initKeyboardService();
    _listenToPosition();
    _listenToPlayingState();
    _listenToCompleted();
    _checkPipSupport();
    // Add lifecycle observer to reload settings when app resumes
    WidgetsBinding.instance.addObserver(this);
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

  void _onRateChanged(double newRate) {
    if (!mounted) return;
    if (_isLongPressing) return;
    if (_suppressRateToastUntil != null && DateTime.now().isBefore(_suppressRateToastUntil!)) return;
    final prev = _lastReportedRate;
    if (prev != null && (prev - newRate).abs() < 0.005) return;
    _lastReportedRate = newRate;
    final icon = newRate >= 1.0 ? Symbols.fast_forward_rounded : Symbols.slow_motion_video_rounded;
    widget.toastController.show(icon, formatPlaybackRate(newRate));
  }

  /// Called when hasFirstFrame changes - start auto-hide timer when first frame is ready
  void _onFirstFrameReady() {
    if (widget.hasFirstFrame?.value == true) {
      _startHideTimer();
      // Retry with network-first if initial cache-first returned empty
      if (_chapters.isEmpty && _markers.isEmpty) {
        _loadPlaybackExtras(forceRefresh: true);
      }
    }
  }

  /// Called when controlsVisible is set externally (e.g. screen-level focus recovery
  /// after controls auto-hide ejects focus on Android TV).
  void _onControlsVisibleExternal() {
    if (widget.controlsVisible?.value == true && !_showControls && mounted) {
      _showControlsWithFocus();
    }
  }

  /// Focus play/pause button if we're in keyboard navigation mode (desktop/TV only)
  void _focusPlayPauseIfKeyboardMode() {
    if (!mounted) return;
    if (!_videoPlayerNavigationEnabled) return;
    final isMobile = PlatformDetector.isMobile(context) && !PlatformDetector.isTV();
    if (!isMobile && InputModeTracker.isKeyboardMode(context)) {
      _desktopControlsKey.currentState?.requestPlayPauseFocus();
    }
  }

  Future<void> _initKeyboardService() async {
    _keyboardService = await KeyboardShortcutsService.getInstance();
  }

  void _listenToPosition() {
    _positionSubscription = widget.player.streams.position.listen((position) {
      if (_markers.isEmpty || !_markersLoaded) {
        return;
      }

      MediaMarker? foundMarker;
      for (final marker in _markers) {
        if (marker.containsPosition(position)) {
          foundMarker = marker;
          break;
        }
      }

      if (foundMarker != _currentMarker && mounted) {
        _updateCurrentMarker(foundMarker);
      }
    });
  }

  /// Updates the current marker and manages auto-skip/focus behavior.
  void _updateCurrentMarker(MediaMarker? foundMarker) {
    setState(() {
      _currentMarker = foundMarker;
      _skipButtonDismissed = false;
    });

    if (foundMarker == null) {
      _cancelAutoSkipTimer();
      _cancelSkipButtonDismissTimer();
      return;
    }

    _startAutoSkipTimer(foundMarker);

    // Auto-skip OFF: dismiss button after 7s if no interaction
    // Auto-skip ON: button stays until controls hide
    if (!_shouldAutoSkipForMarker(foundMarker)) {
      _startSkipButtonDismissTimer();
    }

    // Auto-focus skip button on TV when marker appears (only in keyboard/TV mode)
    if (PlatformDetector.isTV() && InputModeTracker.isKeyboardMode(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _skipMarkerFocusNode.requestFocus();
        }
      });
    }
  }

  /// Listen to playback state changes to manage auto-hide timer
  void _listenToPlayingState() {
    _playingSubscription = widget.player.streams.playing.listen((isPlaying) {
      if (isPlaying && _showControls) {
        _startHideTimer();
      } else if (!isPlaying && _showControls) {
        _startPausedHideTimer();
      }
    });
  }

  /// Listen to completed stream to show controls when video ends
  void _listenToCompleted() {
    _completedSubscription = widget.player.streams.completed.listen((completed) {
      if (completed && mounted) {
        // Cancel long-press 2x speed if active
        if (_isLongPressing) {
          _handleLongPressCancel();
        }
        // Show controls when video completes (for play next dialog etc.)
        setState(() {
          _showControls = true;
        });
        // Notify parent of visibility change (for popup positioning)
        widget.controlsVisible?.value = true;
        _hideTimer?.cancel();
      }
    });
  }

  Future<void> _skipMarker() async {
    if (_currentMarker == null) return;

    final marker = _currentMarker!;
    final endTime = marker.endTime;
    final duration = widget.player.state.duration;
    final isAtEnd = duration > Duration.zero && (duration - endTime).inMilliseconds <= 1000;

    if (marker.isCredits && isAtEnd) {
      // Seeking to EOF is unreliable due to position stream throttling,
      // so pause and defer to the parent's completion flow.
      await widget.player.pause();
      widget.onReachedEnd?.call();
    } else {
      await _seekToPosition(endTime);
    }

    if (!mounted) return;
    setState(() {
      _currentMarker = null;
    });
    _cancelAutoSkipTimer();
    _cancelSkipButtonDismissTimer();
  }

  void _startAutoSkipTimer(MediaMarker marker) {
    _cancelAutoSkipTimer();

    final shouldAutoSkip = (marker.isCredits && _autoSkipCredits) || (!marker.isCredits && _autoSkipIntro);

    if (!shouldAutoSkip || _autoSkipDelay <= 0) return;

    _autoSkipProgress = 0.0;

    _autoSkipController?.dispose();
    _autoSkipController = AnimationController(duration: Duration(seconds: _autoSkipDelay), vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (!mounted || _currentMarker != marker) return;
          _performAutoSkip();
        }
      });

    final isTVPlatform = PlatformDetector.isTV();
    if (isTVPlatform) {
      // TV hardware: Use frame-rate capped Timer.periodic (200ms) to avoid performance regression
      _autoSkipTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
        if (!mounted || _currentMarker != marker || _autoSkipController == null) {
          timer.cancel();
          return;
        }
        setState(() {
          _autoSkipProgress = _autoSkipController!.value;
        });
      });
    } else {
      // Non-TV platforms: Avoid a controller listener and use AnimatedBuilder for button-only updates.
    }

    _autoSkipController!.forward(from: 0.0);
  }

  void _cancelAutoSkipTimer() {
    _autoSkipTimer?.cancel();
    _autoSkipTimer = null;
    _autoSkipController?.stop();
    _autoSkipController?.dispose();
    _autoSkipController = null;
    if (mounted) {
      setState(() {
        _autoSkipProgress = 0.0;
      });
    }
  }

  /// Starts/restarts the skip button dismiss timer. When it fires, hides the
  /// button and cancels any active auto-skip countdown.
  void _startSkipButtonDismissTimer() {
    _skipButtonDismissTimer?.cancel();
    _skipButtonDismissTimer = Timer(const Duration(seconds: 7), () {
      if (!mounted || _currentMarker == null) return;
      setState(() {
        _skipButtonDismissed = true;
      });
      _cancelAutoSkipTimer();
    });
  }

  void _cancelSkipButtonDismissTimer() {
    _skipButtonDismissTimer?.cancel();
    _skipButtonDismissTimer = null;
  }

  /// Perform a debounced auto-skip from the marker button only.
  void _performAutoSkip() {
    if (_currentMarker == null) return;

    // Debounce skip-marker presses separately from seek double-tap actions.
    final now = DateTime.now();
    if (_lastSkipMarkerActionTime != null && now.difference(_lastSkipMarkerActionTime!).inMilliseconds < 200) {
      return;
    }

    _lastSkipMarkerActionTime = now;
    unawaited(_skipMarker());
  }

  /// Check if auto-skip should be active for the current marker
  bool _shouldAutoSkipForMarker(MediaMarker marker) {
    return (marker.isCredits && _autoSkipCredits) || (!marker.isCredits && _autoSkipIntro);
  }

  bool _shouldShowAutoSkip() {
    if (_currentMarker == null) return false;
    return _shouldAutoSkipForMarker(_currentMarker!);
  }

  Future<void> _loadSeekTimes() async {
    final settingsService = await SettingsService.getInstance();
    if (mounted) {
      setState(() {
        _seekTimeSmall = settingsService.read(SettingsService.seekTimeSmall);
        _rewindOnResume = settingsService.read(SettingsService.rewindOnResume);
        _audioSyncOffset = settingsService.read(SettingsService.audioSyncOffset);
        _subtitleSyncOffset = settingsService.read(SettingsService.subtitleSyncOffset);
        _isRotationLocked = settingsService.read(SettingsService.rotationLocked);
        _autoSkipIntro = settingsService.read(SettingsService.autoSkipIntro);
        _autoSkipCredits = settingsService.read(SettingsService.autoSkipCredits);
        _autoSkipDelay = settingsService.read(SettingsService.autoSkipDelay);
        _videoPlayerNavigationEnabled = settingsService.read(SettingsService.videoPlayerNavigationEnabled);
        _showPerformanceOverlay = settingsService.read(SettingsService.showPerformanceOverlay);
        _autoHidePerformanceOverlay = settingsService.read(SettingsService.autoHidePerformanceOverlay);
        _clickVideoTogglesPlayback = settingsService.read(SettingsService.clickVideoTogglesPlayback);
      });

      // Focus play/pause if navigation is now enabled and controls are visible
      // (handles case where initState focus attempt failed due to async settings load)
      if (_videoPlayerNavigationEnabled && _showControls) {
        _focusPlayPauseIfKeyboardMode();
      }

      // Apply rotation lock setting
      if (_isRotationLocked) {
        unawaited(
          SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]),
        );
      } else {
        unawaited(SystemChrome.setPreferredOrientations(DeviceOrientation.values));
      }
    }
  }

  void _toggleSubtitles() {
    final currentTrack = widget.player.state.track.subtitle;
    // No-op if no subtitle track is selected
    if (currentTrack == null || currentTrack.id == 'no') return;

    final newVisible = !_subtitlesVisible;
    widget.player.setProperty('sub-visibility', newVisible ? 'yes' : 'no');
    setState(() {
      _subtitlesVisible = newVisible;
    });
  }

  void _onSubtitleTrackChanged(SubtitleTrack track) {
    // Reset visibility when user explicitly picks a new subtitle track
    if (track.id != 'no' && !_subtitlesVisible) {
      widget.player.setProperty('sub-visibility', 'yes');
      setState(() {
        _subtitlesVisible = true;
      });
    }
    widget.onSubtitleTrackChanged?.call(track);
  }

  void _toggleShader() {
    final shaderService = widget.shaderService;
    if (shaderService == null || !shaderService.isSupported) return;

    if (shaderService.currentPreset.isEnabled) {
      // Currently active - disable temporarily
      unawaited(
        shaderService
            .applyPreset(ShaderPreset.none)
            .then((_) {
              // ignore: no-empty-block - setState triggers rebuild to reflect disabled shader
              if (mounted) setState(() {});
              widget.onShaderChanged?.call();
            })
            .catchError((Object e, StackTrace st) {
              appLogger.w('Failed to disable shader', error: e, stackTrace: st);
            }),
      );
    } else {
      // Currently off - restore saved preset
      final shaderProvider = context.read<ShaderProvider>();
      final saved = shaderProvider.savedPreset;
      final allPresets = shaderProvider.allPresets;
      final targetPreset = saved.isEnabled
          ? saved
          : allPresets.firstWhere((p) => p.isEnabled, orElse: () => allPresets[1]);
      unawaited(
        shaderService
            .applyPreset(targetPreset)
            .then((_) {
              shaderProvider.setCurrentPreset(targetPreset);
              // ignore: no-empty-block - setState triggers rebuild to reflect restored shader
              if (mounted) setState(() {});
              widget.onShaderChanged?.call();
            })
            .catchError((Object e, StackTrace st) {
              appLogger.w('Failed to apply shader preset', error: e, stackTrace: st);
            }),
      );
    }
  }

  void _nextAudioTrack() {
    if (!widget.canControl) return;
    widget.onCycleAudioTrack?.call();
  }

  void _nextSubtitleTrack() {
    if (!widget.canControl) return;
    widget.onCycleSubtitleTrack?.call();
  }

  void _nextChapter() => _seekToNextChapter();

  void _previousChapter() => _seekToPreviousChapter();

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    widget.controlsVisible?.removeListener(_onControlsVisibleExternal);
    widget.hasFirstFrame?.removeListener(_onFirstFrameReady);
    _hideTimer?.cancel();
    _feedbackTimer?.cancel();
    _lockIconTimer?.cancel();
    _autoSkipTimer?.cancel();
    _autoSkipController?.dispose();
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
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    // Remove window listener and reset always-on-top if it was enabled
    if (PlatformDetector.isDesktopOS()) {
      windowManager.removeListener(this);
      if (_isAlwaysOnTop) {
        windowManager.setAlwaysOnTop(false);
      }
    }
    if (Platform.isMacOS) {
      _pipService.isPipActive.removeListener(_onMacPipChanged);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload seek times when app resumes (e.g., returning from settings)
      _loadSeekTimes();
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

  @override
  // ignore: no-empty-block - required by WindowListener interface
  void onWindowResize() {}

  /// Controls hide delay: 5s on mobile/TV/keyboard-nav, 3s on desktop with mouse.
  Duration get _hideDelay {
    final isMobile = (Platform.isIOS || Platform.isAndroid) && !PlatformDetector.isTV();
    if (isMobile || PlatformDetector.isTV() || _videoPlayerNavigationEnabled) {
      return const Duration(seconds: 5);
    }
    return const Duration(seconds: 3);
  }

  /// Shared hide logic: hides controls, notifies parent, updates traffic lights, restores focus.
  void _hideControls() {
    if (!mounted || !_showControls || _forceShowControls) return;
    setState(() {
      _showControls = false;
      _isContentStripVisible = false;
      // Dismiss skip button with controls — after this it only re-appears with controls
      if (_currentMarker != null) {
        _skipButtonDismissed = true;
      }
    });
    _desktopControlsKey.currentState?.hideContentStrip();
    _cancelSkipButtonDismissTimer();
    widget.controlsVisible?.value = false;
    if (Platform.isMacOS) {
      _updateTrafficLightVisibility();
    }
    // Reclaim focus so the global key handler stays active for TV dpad,
    // but skip if an overlay sheet owns focus — stealing it would break
    // sheet navigation (e.g. the compact sync bar).
    final sheetOpen = OverlaySheetController.maybeOf(context)?.isOpen ?? false;
    if (!sheetOpen) {
      // Always request primary focus on _focusNode — not just when hasFocus is
      // false. hasFocus is true when a descendant (e.g. play/pause) has focus,
      // but we need _focusNode itself to hold primary focus so its onKeyEvent
      // fires for the next d-pad press (otherwise focus escapes to the screen-
      // level self-heal handler which shows controls with play/pause focus).
      _focusNode.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_focusNode.hasPrimaryFocus) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();

    // Don't auto-hide while loading first frame (user needs to see spinner and back button)
    final hasFrame = widget.hasFirstFrame?.value ?? true;
    if (!hasFrame) return;

    if (_forceShowControls) return;

    // Only auto-hide if playing
    if (widget.player.state.playing) {
      _hideTimer = Timer(_hideDelay, () {
        // Also check hasFirstFrame in callback (in case it changed)
        final stillLoading = !(widget.hasFirstFrame?.value ?? true);
        if (mounted && widget.player.state.playing && !stillLoading) {
          _hideControls();
        }
      });
    }
  }

  /// Auto-hide controls after pause (does not check playing state in callback).
  void _startPausedHideTimer() {
    _hideTimer?.cancel();
    if (_forceShowControls) return;
    _hideTimer = Timer(_hideDelay, () {
      _hideControls();
    });
  }

  /// Restart the hide timer on user interaction (if video is playing)
  void _restartHideTimerIfPlaying() {
    if (widget.player.state.playing) {
      _startHideTimer();
    }
  }

  /// Hide controls immediately when the mouse leaves the player area (desktop only).
  void _hideControlsFromPointerExit() {
    final isMobile = PlatformDetector.isMobile(context) && !PlatformDetector.isTV();
    if (isMobile) return;

    _hideTimer?.cancel();
    _hideControls();
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent && _keyboardService != null) {
      final delta = event.scrollDelta.dy;
      final volume = widget.player.state.volume;
      final maxVol = _keyboardService!.maxVolume.toDouble();
      final newVolume = (volume - delta / 20).clamp(0.0, maxVol);
      widget.player.setVolume(newVolume);
      unawaited(SettingsService.getInstance().then((s) => s.write(SettingsService.volume, newVolume)));
      _showControlsFromPointerActivity();
    }
  }

  /// Show controls in response to pointer activity (mouse/trackpad movement).
  void _showControlsFromPointerActivity() {
    // Cancel auto-skip timer when user interacts with mouse/pointer
    _cancelAutoSkipTimer();

    if (!_showControls) {
      setState(() {
        _showControls = true;
      });
      // Notify parent of visibility change (for popup positioning)
      widget.controlsVisible?.value = true;
      // On macOS, keep window controls in sync with the overlay
      if (Platform.isMacOS) {
        _updateTrafficLightVisibility();
      }
    }

    // Keep the overlay visible while the user is moving the pointer
    _restartHideTimerIfPlaying();
  }

  void _toggleControls() {
    if (_showControls) {
      _hideControls();
    } else {
      setState(() {
        _showControls = true;
      });
      widget.controlsVisible?.value = true;
      _startHideTimer();
      if (Platform.isMacOS) {
        _updateTrafficLightVisibility();
      }
    }
    // Don't cancel auto-skip just for showing/hiding the overlay. If the user wants
    // to interrupt, seeking/tapping the skip button already does that.
  }

  void _toggleRotationLock() async {
    setState(() {
      _isRotationLocked = !_isRotationLocked;
    });

    // Save to settings
    final settingsService = await SettingsService.getInstance();
    await settingsService.write(SettingsService.rotationLocked, _isRotationLocked);

    if (_isRotationLocked) {
      // Locked: Allow landscape orientations only
      await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    } else {
      // Unlocked: Allow all orientations including portrait
      await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
  }

  void _toggleScreenLock() {
    final locking = !_isScreenLocked;
    setState(() {
      _isScreenLocked = locking;
      if (locking) {
        _showLockIcon = true;
      }
    });
    if (locking) {
      _hideControls();
      _startLockIconHideTimer();
    }
  }

  void _startLockIconHideTimer() {
    _lockIconTimer?.cancel();
    _lockIconTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showLockIcon = false);
    });
  }

  void _unlockScreen() {
    setState(() {
      _isScreenLocked = false;
      _showLockIcon = false;
      _showControls = true;
    });
    _lockIconTimer?.cancel();
    widget.controlsVisible?.value = true;
    _startHideTimer();
  }

  void _updateTrafficLightVisibility() async {
    // When maximized or fullscreen, always keep traffic lights visible so the
    // user can reach them without the controls-hide-on-mouse-leave race.
    // In normal windowed mode, toggle with controls as before.
    final isMaximizedOrFullscreen = await windowManager.isMaximized() || await windowManager.isFullScreen();
    final visible = isMaximizedOrFullscreen || _forceShowControls ? true : _showControls;
    await MacOSWindowService.setTrafficLightsVisible(visible);
  }

  /// Check whether PiP is supported on this device
  Future<void> _checkPipSupport() async {
    if (!Platform.isAndroid && !Platform.isIOS && !Platform.isMacOS) {
      return;
    }

    try {
      final supported = await PipService.isSupported();
      if (mounted) {
        setState(() {
          _isPipSupported = supported;
        });
      }
    } catch (e) {
      return;
    }
  }

  /// macOS PiP changed — force controls visible while PiP is active
  void _onMacPipChanged() {
    if (!mounted) return;
    final inPip = _pipService.isPipActive.value;
    setState(() => _forceShowControls = inPip);
    if (inPip) {
      _hideTimer?.cancel();
      widget.controlsVisible?.value = true;
    } else {
      _startHideTimer();
    }
  }

  Future<void> _loadPlaybackExtras({bool forceRefresh = false}) async {
    // Live TV metadata uses EPG rating keys, not library items
    if (widget.isLive) return;
    if (_isLoadingExtras) return;
    _isLoadingExtras = true;

    final serverId = widget.metadata.serverId;
    // Read providers before any await — `context` after an async gap is
    // a lint trigger and can crash if the widget unmounts mid-load.
    final client = serverId != null ? context.tryGetMediaClientForServer(serverId) : null;
    final database = context.read<AppDatabase>();
    if (client == null) {
      await _loadPlaybackExtrasFromCacheOnly(cacheServerId: await _resolveCacheServerId(database));
      _isLoadingExtras = false;
      return;
    }

    try {
      appLogger.d('_loadPlaybackExtras: starting for ${widget.metadata.id} (forceRefresh=$forceRefresh)');
      final settings = await SettingsService.getInstance();
      final introPattern = settings.read(SettingsService.introPattern);
      final creditsPattern = settings.read(SettingsService.creditsPattern);
      // Backend-aware: Plex hits /library/metadata?includeChapters=1; Jellyfin
      // pulls Chapters from /Users/{userId}/Items/{id}.
      final extras = await client.fetchPlaybackExtras(
        widget.metadata.id,
        introPattern: introPattern,
        creditsPattern: creditsPattern,
        forceRefresh: forceRefresh,
      );
      appLogger.d('_loadPlaybackExtras: got ${extras.chapters.length} chapters');

      _applyPlaybackExtras(extras);
    } catch (e, stack) {
      // Fallback: serve extras from the per-backend cache (for offline
      // playback after the network call threw).
      appLogger.d('_loadPlaybackExtras: network path failed, trying cache fallback');
      try {
        final settings = await SettingsService.getInstance();
        final extras = await client.fetchPlaybackExtrasFromCacheOnly(
          widget.metadata.id,
          introPattern: settings.read(SettingsService.introPattern),
          creditsPattern: settings.read(SettingsService.creditsPattern),
        );
        if (extras != null) {
          appLogger.d('_loadPlaybackExtras: loaded ${extras.chapters.length} chapters from cache');
          _applyPlaybackExtras(extras);
          return;
        }
      } catch (cacheError) {
        appLogger.d('_loadPlaybackExtras: cache fallback failed', error: cacheError);
      }
      appLogger.e('_loadPlaybackExtras failed', error: e, stackTrace: stack);
    } finally {
      _isLoadingExtras = false;
    }
  }

  Future<void> _loadPlaybackExtrasFromCacheOnly({required String? cacheServerId}) async {
    if (cacheServerId == null) {
      appLogger.w('_loadPlaybackExtras: no client or cache scope for server ${widget.metadata.serverId}');
      return;
    }
    try {
      final settings = await SettingsService.getInstance();
      final extras = await CachedPlaybackMetadataService.fetchPlaybackExtras(
        backend: widget.metadata.backend,
        cacheServerId: cacheServerId,
        itemId: widget.metadata.id,
        introPattern: settings.read(SettingsService.introPattern),
        creditsPattern: settings.read(SettingsService.creditsPattern),
      );
      if (extras != null) _applyPlaybackExtras(extras);
    } catch (e) {
      appLogger.d('_loadPlaybackExtras: cache-only path failed', error: e);
    }
  }

  Future<String?> _resolveCacheServerId(AppDatabase database) async {
    final serverId = widget.metadata.serverId;
    if (serverId == null) return null;
    try {
      final row = await (database.select(
        database.downloadedMedia,
      )..where((tbl) => tbl.globalKey.equals(buildGlobalKey(serverId, widget.metadata.id)))).getSingleOrNull();
      return row?.clientScopeId ?? serverId;
    } catch (_) {
      return serverId;
    }
  }

  void _applyPlaybackExtras(PlaybackExtras extras) {
    if (!mounted) return;
    setState(() {
      _chapters = extras.chapters;
      _markers = extras.markers;
      _chaptersLoaded = true;
      _markersLoaded = true;
    });
  }

  TrackControlsState _buildTrackControlsState({
    required PlaybackStateProvider playbackState,
    required VoidCallback? onToggleAlwaysOnTop,
  }) {
    final versionQuality = effectiveVersionQualityControls(
      isOfflinePlayback: widget.isOfflinePlayback,
      availableVersions: widget.availableVersions,
      serverSupportsTranscoding: widget.serverSupportsTranscoding,
      isTranscoding: widget.isTranscoding,
      sourceAudioTracks: widget.sourceAudioTracks,
      selectedAudioStreamId: widget.selectedAudioStreamId,
    );
    return TrackControlsState(
      availableVersions: versionQuality.availableVersions,
      selectedMediaIndex: widget.selectedMediaIndex,
      selectedQualityPreset: widget.selectedQualityPreset,
      serverSupportsTranscoding: versionQuality.serverSupportsTranscoding,
      isTranscoding: versionQuality.isTranscoding,
      sourceAudioTracks: versionQuality.sourceAudioTracks,
      selectedAudioStreamId: versionQuality.selectedAudioStreamId,
      sourceDurationMs: widget.metadata.durationMs,
      boxFitMode: widget.boxFitMode,
      audioSyncOffset: _audioSyncOffset,
      subtitleSyncOffset: _subtitleSyncOffset,
      isRotationLocked: _isRotationLocked,
      isScreenLocked: _isScreenLocked,
      isFullscreen: _isFullscreen,
      isAlwaysOnTop: _isAlwaysOnTop,
      onTogglePIPMode: (_isPipSupported && !PlatformDetector.isTV()) ? widget.onTogglePIPMode : null,
      onCycleBoxFitMode: widget.onCycleBoxFitMode,
      onToggleRotationLock: _toggleRotationLock,
      onToggleScreenLock: _toggleScreenLock,
      onToggleFullscreen: _toggleFullscreen,
      onToggleAlwaysOnTop: onToggleAlwaysOnTop,
      onSwitchVersion: versionQuality.canSwitch ? (i) => _switchVersionAndQuality(newMediaIndex: i) : null,
      onSwitchQualityPreset: versionQuality.canSwitch ? (p) => _switchVersionAndQuality(newPreset: p) : null,
      onSwitchAudioStreamId: versionQuality.canSwitch ? (id) => _switchVersionAndQuality(newAudioStreamId: id) : null,
      onAudioTrackChanged: widget.onAudioTrackChanged,
      onSubtitleTrackChanged: _onSubtitleTrackChanged,
      onSecondarySubtitleTrackChanged: widget.onSecondarySubtitleTrackChanged,
      onLoadSeekTimes: () async {
        if (mounted) {
          await _loadSeekTimes();
        }
      },
      onCancelAutoHide: () => _hideTimer?.cancel(),
      onStartAutoHide: _startHideTimer,
      onSyncOffsetChanged: (propertyName, offset) {
        setState(() {
          if (propertyName == 'sub-delay') {
            _subtitleSyncOffset = offset;
          } else {
            _audioSyncOffset = offset;
          }
        });
      },
      serverId: widget.metadata.serverId ?? '',
      shaderService: widget.shaderService,
      onShaderChanged: widget.onShaderChanged,
      isAmbientLightingEnabled: widget.isAmbientLightingEnabled,
      onToggleAmbientLighting: widget.player.playerType != 'exoplayer' ? widget.onToggleAmbientLighting : null,
      canControl: widget.canControl,
      isLive: widget.isLive,
      subtitlesVisible: _subtitlesVisible,
      showQueueButton: playbackState.isQueueActive,
      onQueueItemSelected: playbackState.isQueueActive ? _onQueueItemSelected : null,
      ratingKey: widget.metadata.id,
      mediaTitle: widget.metadata.title,
      onSubtitleDownloaded: _onSubtitleDownloaded,
      // Plex proxies OpenSubtitles via its server-side plugin; Jellyfin
      // doesn't expose an equivalent so the Search Subtitles tile is hidden
      // for Jellyfin items. The check uses the registered client type for
      // this metadata's serverId.
      subtitleSearchSupported: _isPlexBackedMetadata(),
    );
  }

  /// True when the active server supports external subtitle search (Plex
  /// today). Requires a server id because the download callback needs the
  /// Plex client/token for that server.
  bool _isPlexBackedMetadata() {
    try {
      final serverId = widget.metadata.serverId;
      if (serverId == null) return false;
      final manager = context.read<MultiServerProvider>().serverManager;
      final c = manager.getClient(serverId);
      return c?.capabilities.externalSubtitleSearch ?? false;
    } catch (_) {
      return false;
    }
  }

  Widget _buildTrackChapterControlsWidget({bool hideChaptersAndQueue = false}) {
    final playbackState = context.watch<PlaybackStateProvider>();
    final trackControlsState = _buildTrackControlsState(
      playbackState: playbackState,
      onToggleAlwaysOnTop: _toggleAlwaysOnTop,
    );

    return TrackChapterControls(
      player: widget.player,
      chapters: _chapters,
      chaptersLoaded: _chaptersLoaded,
      trackControlsState: trackControlsState,
      onSeekCompleted: widget.onSeekCompleted,
      hideChaptersAndQueue: hideChaptersAndQueue,
    );
  }

  void _seekToPreviousChapter() => unawaited(_seekToChapter(forward: false));

  void _seekToNextChapter() => unawaited(_seekToChapter(forward: true));

  Future<void> _seekByTime({required bool forward}) async {
    final delta = Duration(seconds: forward ? _seekTimeSmall : -_seekTimeSmall);
    await _seekByOffset(delta);
  }

  Future<void> _seekToChapter({required bool forward}) async {
    if (_chapters.isEmpty) {
      // No chapters - seek by configured amount
      final delta = Duration(seconds: forward ? _seekTimeSmall : -_seekTimeSmall);
      await _seekByOffset(delta);
      return;
    }

    final currentPositionMs = widget.player.state.position.inMilliseconds;

    if (forward) {
      // Find next chapter
      for (final chapter in _chapters) {
        final chapterStart = chapter.startTimeOffset ?? 0;
        if (chapterStart > currentPositionMs) {
          await _seekToPosition(Duration(milliseconds: chapterStart));
          return;
        }
      }
    } else {
      // Find previous/current chapter
      for (int i = _chapters.length - 1; i >= 0; i--) {
        final chapterStart = _chapters[i].startTimeOffset ?? 0;
        if (currentPositionMs > chapterStart + 3000) {
          // If more than 3 seconds into chapter, go to start of current chapter
          await _seekToPosition(Duration(milliseconds: chapterStart));
          return;
        }
      }
      // If at start of first chapter, go to beginning
      await _seekToPosition(Duration.zero);
    }
  }

  Future<void> _seekToPosition(Duration position, {bool notifyCompletion = true}) async {
    // Cancel auto-skip when user manually seeks
    _cancelAutoSkipTimer();

    final clamped = clampSeekPosition(widget.player, position);
    await widget.player.seek(clamped);
    if (notifyCompletion && mounted) {
      widget.onSeekCompleted?.call(clamped);
    }
  }

  Future<void> _seekByOffset(Duration delta, {bool notifyCompletion = true}) async {
    // Route through live seek callback for time-shifted live TV
    if (widget.isLive && widget.onLiveSeek != null && widget.currentPositionEpoch != null) {
      widget.onLiveSeek!(widget.currentPositionEpoch! + delta.inSeconds);
      return;
    }
    final target = widget.player.state.position + delta;
    final clamped = clampSeekPosition(widget.player, target);
    await widget.player.seek(clamped);
    if (notifyCompletion && mounted) {
      widget.onSeekCompleted?.call(clamped);
    }
  }

  Future<void> _playOrPause() async {
    if (!widget.player.state.playing && _rewindOnResume > 0) {
      final target = widget.player.state.position - Duration(seconds: _rewindOnResume);
      final clamped = clampSeekPosition(widget.player, target);
      await widget.player.seek(clamped);
    }
    await widget.player.playOrPause();
  }

  /// Throttled seek for timeline slider - executes immediately then throttles to 200ms
  void _throttledSeek(Duration position) => _seekThrottle([position]);

  /// Finalizes the seek when user stops scrubbing the timeline
  void _finalizeSeek(Duration position) {
    _seekThrottle.cancel();
    unawaited(_seekToPosition(position));
  }

  /// Timing-based double-click detection: avoids `onDoubleTap`'s ~300 ms
  /// tap-resolution delay and the arena competition it introduces.
  void _handleOuterTap() {
    if (widget.canControl && _clickVideoTogglesPlayback) {
      _playOrPause();
    } else {
      _toggleControls();
    }

    if (PlatformDetector.isMobile(context)) return;

    final now = DateTime.now();
    if (_lastSkipTapTime != null && now.difference(_lastSkipTapTime!).inMilliseconds < 250) {
      _lastSkipTapTime = null;
      _toggleFullscreen();
      return;
    }
    _lastSkipTapTime = now;
  }

  /// Handle tap in skip zone with custom double-tap detection
  void _handleTapInSkipZone({required bool isForward}) {
    final now = DateTime.now();

    // Cancel any pending single-tap action
    _singleTapTimer?.cancel();
    _singleTapTimer = null;

    // Debounce: ignore taps within 200ms of last skip action
    // This prevents double-taps from counting as two separate skips
    if (_lastSkipActionTime != null && now.difference(_lastSkipActionTime!).inMilliseconds < 200) {
      return;
    }

    // Check if this qualifies as a double-tap (within 250ms of last tap, same side)
    final isDoubleTap =
        _lastSkipTapTime != null &&
        now.difference(_lastSkipTapTime!).inMilliseconds < 250 &&
        _lastSkipTapWasForward == isForward;

    // Skip ONLY on detected double-tap (no single-tap-to-add behavior)
    if (isDoubleTap) {
      _lastSkipTapTime = null; // Reset to prevent triple-tap chaining

      if (_showDoubleTapFeedback && _lastDoubleTapWasForward == isForward) {
        // Stacking skip - add to accumulated
        unawaited(_handleStackingSkip(isForward: isForward));
      } else {
        // First double-tap - initiate skip
        unawaited(_handleDoubleTapSkip(isForward: isForward));
      }
    } else {
      // First tap - record timestamp and start timer for single-tap action
      _lastSkipTapTime = now;
      _lastSkipTapWasForward = isForward;

      // If no second tap within 250ms, treat as single tap to toggle controls
      _singleTapTimer = Timer(const Duration(milliseconds: 250), () {
        if (mounted) {
          _toggleControls();
        }
      });
    }
  }

  /// Handle stacking skip - add to accumulated skip when feedback is active
  Future<void> _handleStackingSkip({required bool isForward}) async {
    if (!widget.canControl) return;

    // Add to accumulated skip
    _accumulatedSkipSeconds += _seekTimeSmall;

    // Calculate and perform seek
    final delta = Duration(seconds: isForward ? _seekTimeSmall : -_seekTimeSmall);
    await _seekByOffset(delta);

    // Refresh feedback (extends timer, updates display)
    _showSkipFeedback(isForward: isForward);

    // Record skip time for debounce
    _lastSkipActionTime = DateTime.now();
  }

  /// Handle double-tap skip forward or backward
  Future<void> _handleDoubleTapSkip({required bool isForward}) async {
    // Ignore if user cannot control playback
    if (!widget.canControl) return;

    // Reset accumulated skip for new gesture
    _accumulatedSkipSeconds = _seekTimeSmall;

    final delta = Duration(seconds: isForward ? _seekTimeSmall : -_seekTimeSmall);
    await _seekByOffset(delta);

    // Show visual feedback
    _showSkipFeedback(isForward: isForward);

    // Record skip time for debounce
    _lastSkipActionTime = DateTime.now();
  }

  /// Show animated visual feedback for skip gesture
  void _showSkipFeedback({required bool isForward}) {
    _feedbackTimer?.cancel();

    setState(() {
      _lastDoubleTapWasForward = isForward;
      _showDoubleTapFeedback = true;
      _doubleTapFeedbackOpacity = 1.0;
    });

    // Capture duration before timer to avoid context access in callback
    final slowDuration = tokens(context).slow;

    // Fade out after delay (1200ms gives time to see value and continue tapping)
    _feedbackTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _doubleTapFeedbackOpacity = 0.0;
        });

        Timer(slowDuration, () {
          if (mounted) {
            setState(() {
              _showDoubleTapFeedback = false;
              _accumulatedSkipSeconds = 0; // Reset when feedback hides
            });
          }
        });
      }
    });
  }

  /// Handle tap on controls overlay - route to skip zones or toggle controls
  void _handleControlsOverlayTap(TapUpDetails details, BoxConstraints constraints) {
    final isMobile = PlatformDetector.isMobile(context);

    if (!isMobile) {
      final DateTime now = DateTime.now();

      // Always perform the single-click behavior immediately
      if (widget.canControl && _clickVideoTogglesPlayback) {
        _playOrPause();
      } else {
        _toggleControls();
      }

      // Detect double-click
      final bool isDoubleClick = _lastSkipTapTime != null && now.difference(_lastSkipTapTime!).inMilliseconds < 250;

      if (isDoubleClick) {
        _lastSkipTapTime = null;

        // Perform desktop double-click action: toggle fullscreen
        _toggleFullscreen();

        return;
      }

      // Record this click as a candidate for double-click detection
      _lastSkipTapTime = now;
      return;
    }

    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    final tapX = details.localPosition.dx;
    final tapY = details.localPosition.dy;

    // Skip zone dimensions (must match the skip zone Positioned widgets)
    final topExclude = height * 0.15;
    final bottomExclude = height * 0.15;
    final leftZoneWidth = width * 0.35;

    // Check if tap is in vertical range for skip zones
    final inVerticalRange = tapY > topExclude && tapY < (height - bottomExclude);

    if (inVerticalRange) {
      if (tapX < leftZoneWidth) {
        // Left skip zone
        _handleTapInSkipZone(isForward: false);
        return;
      } else if (tapX > (width - leftZoneWidth)) {
        // Right skip zone
        _handleTapInSkipZone(isForward: true);
        return;
      }
    }

    // Not in skip zone, toggle controls
    _toggleControls();
  }

  /// Handle long-press start - activate 2x speed
  void _handleLongPressStart() {
    if (!widget.canControl || widget.isLive) return;

    setState(() {
      _isLongPressing = true;
      _rateBeforeLongPress = widget.player.state.rate;
      _showSpeedIndicator = true;
    });
    widget.player.setRate(2.0);
  }

  /// Handle long-press end - restore original speed
  void _handleLongPressEnd() {
    if (!_isLongPressing) return;
    // Swallow the rate-restore emission so the stream-driven toast doesn't
    // flash as the rate snaps back to the prior value.
    _suppressRateToastUntil = DateTime.now().add(const Duration(milliseconds: 250));
    widget.player.setRate(_rateBeforeLongPress ?? 1.0);
    setState(() {
      _isLongPressing = false;
      _rateBeforeLongPress = null;
      _showSpeedIndicator = false;
    });
  }

  /// Handle long-press cancel (same as end)
  void _handleLongPressCancel() => _handleLongPressEnd();

  /// Build the visual feedback widget for double-tap skip
  Widget _buildDoubleTapFeedback() {
    return Align(
      alignment: _lastDoubleTapWasForward ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 60),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              _lastDoubleTapWasForward ? Symbols.forward_media_rounded : Symbols.replay_rounded,
              fill: 1,
              color: Colors.white,
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              '$_accumulatedSkipSeconds${t.settings.secondsShort}',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the visual indicator for long-press 2x speed.
  /// Manual (persistent for duration of press) — separate from the stream-driven
  /// toast so it stays visible for the full long-press rather than auto-hiding.
  Widget _buildSpeedIndicator() => const PlayerToastIndicator(icon: Symbols.fast_forward_rounded, text: '2x');

  Future<void> _toggleFullscreen() async {
    if (!PlatformDetector.isMobile(context)) {
      await FullscreenStateManager().toggleFullscreen();
    }
  }

  /// Exit fullscreen if the window is actually fullscreen (async check).
  /// Used by ESC handler on Windows/Linux to avoid relying on _isFullscreen flag.
  Future<void> _exitFullscreenIfNeeded() async {
    if (await windowManager.isFullScreen()) {
      await FullscreenStateManager().exitFullscreen();
    }
  }

  /// Initialize always-on-top state from window manager (desktop only)
  Future<void> _initAlwaysOnTopState() async {
    final isOnTop = await windowManager.isAlwaysOnTop();
    if (mounted && isOnTop != _isAlwaysOnTop) {
      setState(() {
        _isAlwaysOnTop = isOnTop;
      });
    }
  }

  /// Toggle always-on-top window mode (desktop only)
  Future<void> _toggleAlwaysOnTop() async {
    if (!PlatformDetector.isMobile(context)) {
      final newValue = !_isAlwaysOnTop;
      await windowManager.setAlwaysOnTop(newValue);
      if (!mounted) return;
      setState(() {
        _isAlwaysOnTop = newValue;
      });
    }
  }

  /// Check if a key is a directional key (arrow keys)
  bool _isDirectionalKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight;
  }

  /// Check if a key is a select/enter key
  bool _isSelectKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.gameButtonA;
  }

  /// Determine if the key event should toggle play/pause based on configured hotkeys.
  bool _isPlayPauseKey(KeyEvent event) {
    final logicalKey = event.logicalKey;
    final physicalKey = event.physicalKey;

    // Always accept hardware media play/pause keys (Android TV remotes)
    if (logicalKey == LogicalKeyboardKey.mediaPlayPause ||
        logicalKey == LogicalKeyboardKey.mediaPlay ||
        logicalKey == LogicalKeyboardKey.mediaPause) {
      return true;
    }

    // When the shortcuts service is available, respect the configured play/pause hotkey
    if (_keyboardService != null) {
      final hotkey = _keyboardService!.hotkeys['play_pause'];
      if (hotkey == null) return false;
      return hotkey.key == physicalKey;
    }

    // Fallback to defaults while the service is loading
    return physicalKey == PhysicalKeyboardKey.space || physicalKey == PhysicalKeyboardKey.mediaPlayPause;
  }

  /// Check if a key is a media seek key (Android TV remotes)
  bool _isMediaSeekKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.mediaFastForward ||
        key == LogicalKeyboardKey.mediaRewind ||
        key == LogicalKeyboardKey.mediaSkipForward ||
        key == LogicalKeyboardKey.mediaSkipBackward;
  }

  /// Check if a key is a media track key (Android TV remotes)
  bool _isMediaTrackKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.mediaTrackNext || key == LogicalKeyboardKey.mediaTrackPrevious;
  }

  bool _isPlayPauseActivation(KeyEvent event) {
    return event is KeyDownEvent && _isPlayPauseKey(event);
  }

  /// Global key event handler for focus-independent shortcuts (desktop only)
  bool _handleGlobalKeyEvent(KeyEvent event) {
    if (!mounted) return false;

    // When an overlay sheet is open (e.g. subtitle search with text fields),
    // don't consume key events — let text input work normally.
    if (OverlaySheetController.maybeOf(context)?.isOpen ?? false) {
      return false;
    }

    // Back key fallback when _focusNode lost focus (TV, or desktop with nav on).
    // Focus.onKeyEvent won't fire if _focusNode lost focus, so handle ESC here.
    if ((_videoPlayerNavigationEnabled || PlatformDetector.isTV()) && event.logicalKey.isBackKey) {
      if (!_focusNode.hasFocus) {
        // Skip if an overlay sheet is open — the sheet's FocusScope handles
        // back keys via its own onKeyEvent. Without this check, this global
        // handler would call Navigator.pop() alongside the sheet's handler.
        final sheetOpen = OverlaySheetController.maybeOf(context)?.isOpen ?? false;
        if (sheetOpen) return false;
        // On TV, mark coordinator early (KeyDown) so PopScope.onPopInvokedWithResult
        // sees it before KeyUp — prevents the system back from racing ahead.
        if (PlatformDetector.isTV() && event is KeyDownEvent) {
          BackKeyCoordinator.markHandled();
        }
        final backResult = handleBackKeyAction(event, () {
          if (PlatformDetector.isTV()) {
            if (_showControls) {
              if (_isContentStripVisible) {
                _desktopControlsKey.currentState?.dismissContentStrip();
                setState(() => _isContentStripVisible = false);
                _restartHideTimerIfPlaying();
                return;
              }
              _hideControls();
              return;
            }
            (widget.onBack ?? () => Navigator.of(context).pop(true))();
            return;
          }
          if (!_showControls) {
            _showControlsWithFocus();
          } else {
            (widget.onBack ?? () => Navigator.of(context).pop(true))();
          }
        });
        if (backResult != KeyEventResult.ignored) return true;
      }
    }

    // Only handle when video player navigation is disabled (desktop mode without D-pad nav)
    if (_videoPlayerNavigationEnabled) return false;

    // Skip on mobile (unless TV)
    final isMobile = PlatformDetector.isMobile(context) && !PlatformDetector.isTV();
    if (isMobile) return false;

    // Handle play/pause globally - works regardless of focus
    if (_isPlayPauseActivation(event)) {
      _playOrPause();
      _showControlsWithFocus(requestFocus: false);
      return true; // Event handled, stop propagation
    }

    // Fallback: handle all other shortcuts when focus has drifted away
    // (e.g. after controls auto-hide). The !hasFocus guard prevents
    // double-handling when the Focus onKeyEvent already processes the event.
    if (!_focusNode.hasFocus && _keyboardService != null) {
      // On Windows/Linux with navigation off, ESC only exits fullscreen —
      // never exits the player. Intercept before the keyboard shortcuts
      // service which would call onBack and pop the route.
      // Skip if an overlay sheet is open — let the sheet handle ESC.
      if (!_videoPlayerNavigationEnabled && (Platform.isWindows || Platform.isLinux) && event.logicalKey.isBackKey) {
        final sheetOpen = OverlaySheetController.maybeOf(context)?.isOpen ?? false;
        if (!sheetOpen) {
          if (event is KeyUpEvent) {
            _exitFullscreenIfNeeded();
          }
          _focusNode.requestFocus();
          return true;
        }
      }
      final result = _keyboardService!.handleVideoPlayerKeyEvent(
        event,
        widget.player,
        _toggleFullscreen,
        _toggleSubtitles,
        _nextAudioTrack,
        _nextSubtitleTrack,
        _nextChapter,
        _previousChapter,
        onBack: widget.onBack ?? () => Navigator.of(context).pop(true),
        onToggleShader: _toggleShader,
        onNextEpisode: widget.onNext,
        onPreviousEpisode: widget.onPrevious,
        currentPositionEpoch: widget.currentPositionEpoch,
        onLiveSeek: widget.onLiveSeek,
      );
      if (result == KeyEventResult.handled) {
        _focusNode.requestFocus(); // self-heal focus
        return true;
      }
    }

    return true; // Consume all events while video player is active
  }

  /// Show controls and optionally focus play/pause on keyboard input (desktop only)
  void _showControlsWithFocus({bool requestFocus = true}) {
    if (!_showControls) {
      setState(() {
        _showControls = true;
      });
      // Notify parent of visibility change (for popup positioning)
      widget.controlsVisible?.value = true;
      if (Platform.isMacOS) {
        _updateTrafficLightVisibility();
      }
    }
    _startHideTimer();

    // Request focus on play/pause button after controls are shown
    if (requestFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _desktopControlsKey.currentState?.requestPlayPauseFocus();
      });
    } else {
      // When not requesting focus on play/pause, ensure main focus node keeps focus
      // This prevents focus from being lost when controls become visible
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  /// Show controls and focus timeline on LEFT/RIGHT input (TV/desktop)
  void _showControlsWithTimelineFocus() {
    if (!_showControls) {
      setState(() {
        _showControls = true;
      });
      // Notify parent of visibility change (for popup positioning)
      widget.controlsVisible?.value = true;
      if (Platform.isMacOS) {
        _updateTrafficLightVisibility();
      }
    }
    _startHideTimer();

    // Request focus on timeline after controls are shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _desktopControlsKey.currentState?.requestTimelineFocus();
    });
  }

  /// Hide controls when navigating up from timeline (keyboard mode)
  /// If skip marker button or Play Next dialog is visible, focus it instead of hiding controls
  void _hideControlsFromKeyboard() {
    // If skip marker button is visible, focus it instead of hiding controls
    if (_currentMarker != null) {
      _skipMarkerFocusNode.requestFocus();
      return;
    }

    // If Play Next dialog is visible (focus node provided), focus it instead of hiding controls
    if (widget.playNextFocusNode != null) {
      widget.playNextFocusNode!.requestFocus();
      return;
    }

    if (_showControls) {
      _hideControls();
    }
  }

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
          onKeyEvent: (node, event) {
            // On Windows/Linux with navigation off, ESC only exits fullscreen —
            // never exits the player. Consume all back key events and check
            // actual window state asynchronously.
            if (!_videoPlayerNavigationEnabled &&
                (Platform.isWindows || Platform.isLinux) &&
                event.logicalKey.isBackKey) {
              if (event is KeyUpEvent) {
                _exitFullscreenIfNeeded();
              }
              return KeyEventResult.handled;
            }
            // On TV, mark coordinator early (KeyDown) so PopScope.onPopInvokedWithResult
            // sees it before KeyUp — prevents the system back from racing ahead.
            if (PlatformDetector.isTV() && event.logicalKey.isBackKey && event is KeyDownEvent) {
              BackKeyCoordinator.markHandled();
            }
            final backResult = handleBackKeyAction(event, () {
              if (PlatformDetector.isTV()) {
                if (_showControls) {
                  if (_isContentStripVisible) {
                    _desktopControlsKey.currentState?.dismissContentStrip();
                    setState(() => _isContentStripVisible = false);
                    _restartHideTimerIfPlaying();
                    return;
                  }
                  _hideControls();
                  return;
                }
                (widget.onBack ?? () => Navigator.of(context).pop(true))();
                return;
              }
              if (!_showControls) {
                _showControlsWithFocus();
                return;
              }
              // Controls visible - navigate back
              (widget.onBack ?? () => Navigator.of(context).pop(true))();
            });
            if (backResult != KeyEventResult.ignored) {
              return backResult;
            }

            // Only handle KeyDown and KeyRepeat events
            // Consume KeyUp events for navigation keys to prevent leaking to previous routes
            // Let non-navigation keys (volume, etc.) pass through to the OS
            if (!event.isActionable) {
              if (!event.logicalKey.isNavigationKey) return KeyEventResult.ignored;
              return KeyEventResult.handled;
            }

            // Reset hide timer on any keyboard/controller input when controls are visible
            if (_showControls) {
              _restartHideTimerIfPlaying();
            }

            final key = event.logicalKey;
            final isPlayPauseKey = _isPlayPauseKey(event);

            // Always consume play/pause keys to prevent propagation to background routes
            // On TV/mobile, handle play/pause here; on desktop, the global handler does it
            if (isPlayPauseKey) {
              if (_videoPlayerNavigationEnabled || isMobile) {
                if (_isPlayPauseActivation(event)) {
                  _playOrPause();
                  _showControlsWithFocus(requestFocus: _videoPlayerNavigationEnabled);
                }
              }
              return KeyEventResult.handled;
            }

            // Handle media seek keys (Android TV remotes)
            // Uses chapter navigation if chapters are available, otherwise seeks by configured time
            if (event is KeyDownEvent && _isMediaSeekKey(key)) {
              if (widget.canControl) {
                final isForward =
                    key == LogicalKeyboardKey.mediaFastForward || key == LogicalKeyboardKey.mediaSkipForward;
                unawaited(_seekToChapter(forward: isForward));
              }
              _showControlsWithFocus(requestFocus: _videoPlayerNavigationEnabled);
              return KeyEventResult.handled;
            }

            // Handle next/previous track keys (Android TV remotes)
            // Uses same behavior as seek keys: chapter navigation or time-based seek
            if (event is KeyDownEvent && _isMediaTrackKey(key)) {
              if (widget.canControl) {
                unawaited(_seekToChapter(forward: key == LogicalKeyboardKey.mediaTrackNext));
              }
              _showControlsWithFocus(requestFocus: _videoPlayerNavigationEnabled);
              return KeyEventResult.handled;
            }

            // Handle Select/Enter when controls are hidden: pause and show controls
            // Only intercept if this Focus node itself has primary focus (not a descendant)
            if (_isSelectKey(key) && !_showControls && _focusNode.hasPrimaryFocus) {
              _playOrPause();
              _showControlsWithFocus();
              return KeyEventResult.handled;
            }

            // On desktop/TV, show controls on directional input
            // LEFT/RIGHT focuses timeline for seeking, UP/DOWN focuses play/pause
            if (!isMobile && _isDirectionalKey(key) && (_videoPlayerNavigationEnabled || PlatformDetector.isTV())) {
              if (!_showControls) {
                final isHorizontal = key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight;
                if (isHorizontal) {
                  _showControlsWithTimelineFocus();
                  if (widget.canControl) {
                    final forward = key == LogicalKeyboardKey.arrowRight;
                    unawaited(_seekByTime(forward: forward));
                  }
                } else {
                  _showControlsWithFocus();
                }
                return KeyEventResult.handled;
              }
              // Children (DesktopVideoControls) handle navigation first via their own onKeyEvent.
              // If we reach here, children already declined the event — consume it to prevent leaking.
              return KeyEventResult.handled;
            }

            // Pass other events to the keyboard shortcuts service
            if (_keyboardService == null) return KeyEventResult.handled;

            final result = _keyboardService!.handleVideoPlayerKeyEvent(
              event,
              widget.player,
              _toggleFullscreen,
              _toggleSubtitles,
              _nextAudioTrack,
              _nextSubtitleTrack,
              _nextChapter,
              _previousChapter,
              onBack: widget.onBack ?? () => Navigator.of(context).pop(true),
              onToggleShader: _toggleShader,
              onSkipMarker: _performAutoSkip,
              onNextEpisode: widget.onNext,
              onPreviousEpisode: widget.onPrevious,
              currentPositionEpoch: widget.currentPositionEpoch,
              onLiveSeek: widget.onLiveSeek,
            );
            // Let non-navigation keys (volume, etc.) pass through to the OS
            if (!event.logicalKey.isNavigationKey) return KeyEventResult.ignored;
            // Never return .ignored for navigation keys — prevent leaking to previous routes
            return result == KeyEventResult.ignored ? KeyEventResult.handled : result;
          },
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
                    const Positioned(top: 0, left: 0, child: _LinuxKeepAlive()),
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
                    Positioned.fill(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final height = constraints.maxHeight;
                          final width = constraints.maxWidth;
                          final topExclude = height * 0.15; // Exclude top 15% (top bar)
                          final bottomExclude = height * 0.15; // Exclude bottom 15% (seek slider)
                          final leftZoneWidth = width * 0.35; // Left 35%

                          return Stack(
                            children: [
                              // Left zone - skip backward (custom double-tap detection)
                              Positioned(
                                left: 0,
                                top: topExclude,
                                bottom: bottomExclude,
                                width: leftZoneWidth,
                                child: GestureDetector(
                                  onTap: () => _handleTapInSkipZone(isForward: false),
                                  onLongPressStart: (_) => _handleLongPressStart(),
                                  onLongPressEnd: (_) => _handleLongPressEnd(),
                                  onLongPressCancel: _handleLongPressCancel,
                                  behavior: HitTestBehavior.opaque,
                                  child: const ColoredBox(color: Colors.transparent),
                                ),
                              ),
                              // Right zone - skip forward (custom double-tap detection)
                              Positioned(
                                right: 0,
                                top: topExclude,
                                bottom: bottomExclude,
                                width: leftZoneWidth,
                                child: GestureDetector(
                                  onTap: () => _handleTapInSkipZone(isForward: true),
                                  onLongPressStart: (_) => _handleLongPressStart(),
                                  onLongPressEnd: (_) => _handleLongPressEnd(),
                                  onLongPressCancel: _handleLongPressCancel,
                                  behavior: HitTestBehavior.opaque,
                                  child: const ColoredBox(color: Colors.transparent),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
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
                          child: _buildDoubleTapFeedback(),
                        ),
                      ),
                    ),
                  // Speed indicator overlay for long-press 2x
                  if (_showSpeedIndicator) Positioned.fill(child: IgnorePointer(child: _buildSpeedIndicator())),
                  // Stream-driven VLC-style pill (rate changes, backend-switch notifications)
                  Positioned.fill(
                    child: IgnorePointer(
                      // Visual-only overlay; must not steal taps from controls/toggle layer below.
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

  Widget _buildDesktopControlsListener() {
    final playbackState = context.watch<PlaybackStateProvider>();
    final trackControlsState = _buildTrackControlsState(
      playbackState: playbackState,
      onToggleAlwaysOnTop: Platform.isMacOS ? null : _toggleAlwaysOnTop,
    );
    final useDpad = _videoPlayerNavigationEnabled || PlatformDetector.isTV();

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _restartHideTimerIfPlaying(),
      child: DesktopVideoControls(
        key: _desktopControlsKey,
        player: widget.player,
        metadata: widget.metadata,
        onNext: widget.onNext,
        onPrevious: widget.onPrevious,
        chapters: _chapters,
        chaptersLoaded: _chaptersLoaded,
        seekTimeSmall: _seekTimeSmall,
        onSeekToPreviousChapter: _seekToPreviousChapter,
        onSeekToNextChapter: _seekToNextChapter,
        onSeekBackward: () => unawaited(_seekByTime(forward: false)),
        onSeekForward: () => unawaited(_seekByTime(forward: true)),
        onSeek: _throttledSeek,
        onSeekEnd: _finalizeSeek,
        getReplayIcon: getReplayIcon,
        getForwardIcon: getForwardIcon,
        onFocusActivity: _restartHideTimerIfPlaying,
        onHideControls: _hideControlsFromKeyboard,
        trackControlsState: trackControlsState,
        onBack: widget.onBack,
        hasFirstFrame: widget.hasFirstFrame,
        thumbnailDataBuilder: widget.thumbnailDataBuilder,
        liveChannelName: widget.liveChannelName,
        captureBuffer: widget.captureBuffer,
        isAtLiveEdge: widget.isAtLiveEdge,
        streamStartEpoch: widget.streamStartEpoch,
        currentPositionEpoch: widget.currentPositionEpoch,
        onLiveSeek: widget.onLiveSeek,
        onJumpToLive: widget.onJumpToLive,
        useDpadNavigation: useDpad,
        serverId: widget.metadata.serverId,
        showQueueTab: playbackState.isQueueActive,
        onQueueItemSelected: playbackState.isQueueActive ? _onQueueItemSelected : null,
        onCancelAutoHide: () => _hideTimer?.cancel(),
        onStartAutoHide: _startHideTimer,
        onSeekCompleted: widget.onSeekCompleted,
        onContentStripVisibilityChanged: (visible) {
          setState(() => _isContentStripVisible = visible);
          if (visible) {
            _hideTimer?.cancel();
          } else {
            _restartHideTimerIfPlaying();
          }
        },
      ),
    );
  }

  Widget _buildSkipMarkerButton() {
    final isCredits = _currentMarker!.isCredits;
    final hasNextEpisode = widget.onNext != null;

    // Show "Next Episode" only when credits extend to end AND there's a next episode
    final bool creditsAtEnd =
        isCredits &&
        widget.player.state.duration > Duration.zero &&
        (widget.player.state.duration - _currentMarker!.endTime).inMilliseconds <= 1000;
    final bool showNextEpisode = creditsAtEnd && hasNextEpisode;
    String baseButtonText;
    if (showNextEpisode) {
      baseButtonText = 'Next Episode';
    } else if (isCredits) {
      baseButtonText = 'Skip Credits';
    } else {
      baseButtonText = 'Skip Intro';
    }

    final bool isTV = PlatformDetector.isTV();
    final IconData buttonIcon = showNextEpisode ? Symbols.skip_next_rounded : Symbols.fast_forward_rounded;

    String getButtonText(double autoSkipProgress) {
      if (isTV && _autoSkipController?.isAnimating == true && _shouldShowAutoSkip()) {
        final remainingSeconds = ((_autoSkipDelay * (1.0 - autoSkipProgress))).ceil();
        return remainingSeconds > 0 ? '$baseButtonText ($remainingSeconds)' : baseButtonText;
      }
      return baseButtonText;
    }

    Widget buildButtonContent() {
      final bool isAutoSkipActive = _autoSkipController?.isAnimating ?? false;
      final double autoSkipProgress = isTV ? _autoSkipProgress : (_autoSkipController?.value ?? 0.0);
      final String buttonText = getButtonText(autoSkipProgress);

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isAutoSkipActive) {
              _cancelAutoSkipTimer();
            }
            _performAutoSkip();
          },
          borderRadius: BorderRadius.circular(tokens(context).radiusSm),
          // Keep the hitbox to just the chip width.
          child: IntrinsicWidth(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(tokens(context).radiusSm),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  // Netflix-ish base: grey chip with subtle shadow.
                  color: Colors.grey.shade700.withValues(alpha: 0.9),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Stack(
                  children: [
                    if (autoSkipProgress > 0 && !isTV)
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: autoSkipProgress,
                            heightFactor: 1,
                            alignment: Alignment.centerLeft,
                            child: const ColoredBox(color: Colors.white),
                          ),
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Stack(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                buttonText,
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 8),
                              AppIcon(buttonIcon, fill: 1, color: Colors.white, size: 20),
                            ],
                          ),

                          if (autoSkipProgress > 0 && !isTV)
                            Positioned.fill(
                              child: ClipRect(
                                clipper: _ProgressClipper(autoSkipProgress),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        buttonText,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      AppIcon(buttonIcon, fill: 1, color: Colors.black, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final Widget content = (!isTV && _autoSkipController != null)
        ? AnimatedBuilder(animation: _autoSkipController!, builder: (context, _) => buildButtonContent())
        : buildButtonContent();

    return FocusableWrapper(
      focusNode: _skipMarkerFocusNode,
      onSelect: () {
        if (_autoSkipController?.isAnimating == true) {
          _cancelAutoSkipTimer();
        }
        _performAutoSkip();
      },
      borderRadius: tokens(context).radiusSm,
      useBackgroundFocus: true,
      autoScroll: false,
      onKeyEvent: (node, event) {
        // DOWN arrow returns focus to play/pause button
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowDown) {
          _desktopControlsKey.currentState?.requestPlayPauseFocus();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: content,
    );
  }

  /// Switch to a different media version
  void _onQueueItemSelected(MediaItem item) {
    final videoPlayerState = context.findAncestorStateOfType<VideoPlayerScreenState>();
    videoPlayerState?.navigateToQueueItem(item);
  }

  Future<void> _onSubtitleDownloaded() async {
    if (!mounted) return;

    // Plex-only: the OpenSubtitles polling flow uses [getVideoPlaybackData]
    // and the Plex token. Jellyfin has no analogue and the entry point
    // (`subtitleSearchSupported`) is already gated on backend, but guard
    // here too in case a future caller wires the same handler elsewhere.
    if (widget.metadata.backend != MediaBackend.plex) return;
    final serverId = widget.metadata.serverId;
    if (serverId == null) return;

    try {
      final client = context.getPlexClientForServer(serverId);
      final token = client.config.token;
      if (token == null) return;

      // Plex's OpenSubtitles download is asynchronous: the PUT returns immediately
      // but the new stream entry shows up in metadata seconds later. Poll until it
      // appears. Up to 15s matches what Plex-web tolerates before giving up.
      // Snapshot what's already attached so we can identify the new download.
      final existingUris = widget.player.state.tracks.subtitle.where((t) => t.uri != null).map((t) => t.uri!).toSet();

      final deadline = DateTime.now().add(const Duration(seconds: 15));
      MediaSubtitleTrack? newTrack;
      String? newUrl;
      MediaSourceInfo? latestInfo;

      while (mounted && DateTime.now().isBefore(deadline)) {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;

        try {
          final data = await client.getVideoPlaybackData(widget.metadata.id);
          if (!mounted) return;
          if (data.mediaInfo == null) continue;
          latestInfo = data.mediaInfo;

          for (final plexTrack in data.mediaInfo!.subtitleTracks) {
            if (!plexTrack.isExternal) continue;
            final url = client.buildExternalSubtitleUrl(plexTrack);
            if (url == null) continue;
            if (existingUris.any((uri) => uri.contains(plexTrack.key!))) continue;

            newTrack = plexTrack;
            newUrl = url;
            break;
          }
          if (newTrack != null) break;
        } catch (e) {
          appLogger.w('Subtitle download poll iteration failed', error: e);
        }
      }

      if (!mounted || newTrack == null || newUrl == null) return;

      await widget.player.addSubtitleTrack(
        uri: newUrl,
        title: newTrack.displayTitle ?? newTrack.language ?? 'Downloaded',
        language: newTrack.languageCode,
        select: true,
      );

      final partId = latestInfo?.partId;
      if (partId != null) {
        await client.selectStreams(partId, subtitleStreamID: newTrack.id);
      }
    } catch (e) {
      appLogger.w('Failed to refresh subtitles after download', error: e);
    }
  }

  /// Switch version, quality preset, or audio stream ID. Any combination may
  /// change in one invocation; unspecified values retain their current value.
  /// Always routes through pushReplacement, preserving playback position and
  /// the transcode session identifiers.
  Future<void> _switchVersionAndQuality({
    int? newMediaIndex,
    TranscodeQualityPreset? newPreset,
    int? newAudioStreamId,
  }) async {
    final effectiveMediaIndex = newMediaIndex ?? widget.selectedMediaIndex;
    final effectivePreset = newPreset ?? widget.selectedQualityPreset;
    final effectiveAudioStreamId = newAudioStreamId ?? widget.selectedAudioStreamId;

    final isVersionChange = effectiveMediaIndex != widget.selectedMediaIndex;
    final isPresetChange = effectivePreset != widget.selectedQualityPreset;
    final isAudioChange = effectiveAudioStreamId != widget.selectedAudioStreamId;
    if (!isVersionChange && !isPresetChange && !isAudioChange) {
      return;
    }

    try {
      // Save current playback position
      final currentPosition = widget.player.state.position;

      // Get state reference before async operations
      final videoPlayerState = context.findAncestorStateOfType<VideoPlayerScreenState>();

      if (isVersionChange) {
        final settingsService = await SettingsService.getInstance();
        final seriesKey = widget.metadata.grandparentId ?? widget.metadata.id;
        await settingsService.write(SettingsService.mediaVersionPreferences, {
          ...settingsService.read(SettingsService.mediaVersionPreferences),
          seriesKey: effectiveMediaIndex,
        });
      }

      // Preserve session identifiers across the reload so Plex reuses the
      // transcode session rather than spinning up a new one.
      final sessionId = videoPlayerState?.playbackSessionIdentifier;
      final transcodeSessionId = videoPlayerState?.playbackTranscodeSessionId;

      // Set flag on parent VideoPlayerScreen to skip orientation restoration
      videoPlayerState?.setReplacingWithVideo();
      // Dispose the existing player before spinning up the replacement to avoid race conditions
      await videoPlayerState?.disposePlayerForNavigation();

      // Navigate to new player screen with the updated selection
      // Use PageRouteBuilder with zero-duration transitions to prevent orientation reset
      if (mounted) {
        unawaited(
          Navigator.pushReplacement(
            context,
            PageRouteBuilder<bool>(
              pageBuilder: (context, animation, secondaryAnimation) => VideoPlayerScreen(
                metadata: widget.metadata.copyWith(viewOffsetMs: currentPosition.inMilliseconds),
                selectedMediaIndex: effectiveMediaIndex,
                selectedQualityPreset: effectivePreset,
                selectedAudioStreamId: effectiveAudioStreamId,
                reusedSessionIdentifier: sessionId,
                reusedTranscodeSessionId: transcodeSessionId,
              ),
              transitionDuration: Duration.zero,
              reverseTransitionDuration: Duration.zero,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
      }
    }
  }
}

/// A 1x1 pixel widget that continuously repaints to keep Flutter's frame clock active on Linux.
/// This prevents animations from freezing when GTK's frame clock goes idle.
class _LinuxKeepAlive extends StatefulWidget {
  const _LinuxKeepAlive();

  @override
  State<_LinuxKeepAlive> createState() => _LinuxKeepAliveState();
}

class _ProgressClipper extends CustomClipper<Rect> {
  final double progress;
  const _ProgressClipper(this.progress);

  @override
  Rect getClip(Size size) {
    final p = progress.clamp(0.0, 1.0);
    return Rect.fromLTWH(0, 0, size.width * p, size.height);
  }

  @override
  bool shouldReclip(covariant _ProgressClipper oldClipper) => oldClipper.progress != progress;
}

class _LinuxKeepAliveState extends State<_LinuxKeepAlive> {
  Timer? _timer;
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    // Repaint every 100ms to keep Flutter's frame scheduler active
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) {
        setState(() {
          _tick++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use _tick to force rebuild, render a 1x1 transparent pixel
    return SizedBox(
      width: 1,
      height: 1,
      child: ColoredBox(
        color: Color.fromRGBO(0, 0, 0, _tick % 2 == 0 ? 0.1 : 0.2), // Alternate alpha
      ),
    );
  }
}
