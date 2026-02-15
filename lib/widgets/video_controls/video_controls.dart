import 'dart:async' show StreamSubscription, Timer;
import '../../utils/platform_helper.dart';

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
        HardwareKeyboard;
import '../../services/fullscreen_state_manager.dart';
import '../../services/macos_window_service.dart';
import '../../services/pip_service.dart';
import 'package:window_manager/window_manager.dart';

import '../../mpv/mpv.dart';
import '../../focus/dpad_navigator.dart';
import '../../focus/focusable_wrapper.dart';

import '../../services/plex_client.dart';
import '../../services/plex_api_cache.dart';
import '../../models/plex_media_info.dart';
import '../../models/plex_media_version.dart';
import '../../models/plex_metadata.dart';
import '../../screens/video_player_screen.dart';
import '../../focus/key_event_utils.dart';
import '../../services/keyboard_shortcuts_service.dart';
import '../../services/settings_service.dart';
import '../../utils/platform_detector.dart';
import '../../utils/plex_cache_parser.dart';
import '../../utils/player_utils.dart';
import '../../theme/mono_tokens.dart';
import '../../utils/provider_extensions.dart';
import '../../utils/snackbar_helper.dart';
import 'icons.dart';
import '../../utils/app_logger.dart';
import '../../i18n/strings.g.dart';
import '../../focus/input_mode_tracker.dart';
import 'widgets/track_chapter_controls.dart';
import 'widgets/performance_overlay/performance_overlay.dart';
import 'mobile_video_controls.dart';
import 'desktop_video_controls.dart';
import 'package:provider/provider.dart';

import '../../models/shader_preset.dart';
import '../../providers/shader_provider.dart';
import '../../services/shader_service.dart';

/// Custom video controls builder for Plex with chapter, audio, and subtitle support
Widget plexVideoControlsBuilder(
  Player player,
  PlexMetadata metadata, {
  VoidCallback? onNext,
  VoidCallback? onPrevious,
  List<PlexMediaVersion>? availableVersions,
  int? selectedMediaIndex,
  VoidCallback? onTogglePIPMode,
  int boxFitMode = 0,
  VoidCallback? onCycleBoxFitMode,
  Function(AudioTrack)? onAudioTrackChanged,
  Function(SubtitleTrack)? onSubtitleTrackChanged,
  Function(Duration position)? onSeekCompleted,
  VoidCallback? onBack,
  bool canControl = true,
  ValueNotifier<bool>? hasFirstFrame,
  FocusNode? playNextFocusNode,
  ValueNotifier<bool>? controlsVisible,
  ShaderService? shaderService,
  VoidCallback? onShaderChanged,
  String Function(Duration time)? thumbnailUrlBuilder,
}) {
  return PlexVideoControls(
    player: player,
    metadata: metadata,
    onNext: onNext,
    onPrevious: onPrevious,
    availableVersions: availableVersions ?? [],
    selectedMediaIndex: selectedMediaIndex ?? 0,
    boxFitMode: boxFitMode,
    onTogglePIPMode: onTogglePIPMode,
    onCycleBoxFitMode: onCycleBoxFitMode,
    onAudioTrackChanged: onAudioTrackChanged,
    onSubtitleTrackChanged: onSubtitleTrackChanged,
    onSeekCompleted: onSeekCompleted,
    onBack: onBack,
    canControl: canControl,
    hasFirstFrame: hasFirstFrame,
    playNextFocusNode: playNextFocusNode,
    controlsVisible: controlsVisible,
    shaderService: shaderService,
    onShaderChanged: onShaderChanged,
    thumbnailUrlBuilder: thumbnailUrlBuilder,
  );
}

class PlexVideoControls extends StatefulWidget {
  final Player player;
  final PlexMetadata metadata;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final List<PlexMediaVersion> availableVersions;
  final int selectedMediaIndex;
  final int boxFitMode;
  final VoidCallback? onTogglePIPMode;
  final VoidCallback? onCycleBoxFitMode;
  final Function(AudioTrack)? onAudioTrackChanged;
  final Function(SubtitleTrack)? onSubtitleTrackChanged;

  /// Called when a seek operation completes (for Watch Together sync)
  final Function(Duration position)? onSeekCompleted;

  /// Called when back button is pressed (for Watch Together session leave confirmation)
  final VoidCallback? onBack;

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

  /// Optional callback that returns a thumbnail URL for a given timestamp.
  final String Function(Duration time)? thumbnailUrlBuilder;

  const PlexVideoControls({
    super.key,
    required this.player,
    required this.metadata,
    this.onNext,
    this.onPrevious,
    this.availableVersions = const [],
    this.selectedMediaIndex = 0,
    this.boxFitMode = 0,
    this.onTogglePIPMode,
    this.onCycleBoxFitMode,
    this.onAudioTrackChanged,
    this.onSubtitleTrackChanged,
    this.onSeekCompleted,
    this.onBack,
    this.canControl = true,
    this.hasFirstFrame,
    this.playNextFocusNode,
    this.controlsVisible,
    this.shaderService,
    this.onShaderChanged,
    this.thumbnailUrlBuilder,
  });

  @override
  State<PlexVideoControls> createState() => _PlexVideoControlsState();
}

class _PlexVideoControlsState extends State<PlexVideoControls> with WindowListener, WidgetsBindingObserver {
  bool _showControls = true;
  List<PlexChapter> _chapters = [];
  bool _chaptersLoaded = false;
  Timer? _hideTimer;
  bool _isFullscreen = false;
  bool _isAlwaysOnTop = false;
  late final FocusNode _focusNode;
  KeyboardShortcutsService? _keyboardService;
  int _seekTimeSmall = 10; // Default, loaded from settings
  int _audioSyncOffset = 0; // Default, loaded from settings
  int _subtitleSyncOffset = 0; // Default, loaded from settings
  bool _isRotationLocked = true; // Default locked (landscape only)
  bool _clickVideoTogglesPlayback = false; // Default, loaded from settings

  // GlobalKey to access DesktopVideoControls state for focus management
  final GlobalKey<DesktopVideoControlsState> _desktopControlsKey = GlobalKey<DesktopVideoControlsState>();

  /// Get the correct PlexClient for this metadata's server
  PlexClient _getClientForMetadata() {
    return context.getClientForServer(widget.metadata.serverId!);
  }

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
  PlexMarker? _currentMarker;
  List<PlexMarker> _markers = [];
  bool _markersLoaded = false;
  // Playback state subscription for auto-hide timer
  StreamSubscription<bool>? _playingSubscription;
  // Completed subscription to show controls when video ends
  StreamSubscription<bool>? _completedSubscription;
  // Auto-skip state
  bool _autoSkipIntro = false;
  bool _autoSkipCredits = false;
  int _autoSkipDelay = 5;
  Timer? _autoSkipTimer;
  double _autoSkipProgress = 0.0;
  // Video player navigation (use arrow keys to navigate controls)
  bool _videoPlayerNavigationEnabled = false;
  // Performance overlay
  bool _showPerformanceOverlay = false;
  // Long-press 2x speed state
  bool _isLongPressing = false;
  // Skip marker button focus node (for TV D-pad navigation)
  late final FocusNode _skipMarkerFocusNode;
  double? _rateBeforeLongPress;
  bool _showSpeedIndicator = false;

  // PiP support
  bool _isPipSupported = false;
  final PipService _pipService = PipService();

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _skipMarkerFocusNode = FocusNode(debugLabel: 'SkipMarkerButton');
    _seekThrottle = throttle(
      (Duration pos) => widget.player.seek(pos),
      const Duration(milliseconds: 200),
      leading: true,
      trailing: true,
    );
    _loadPlaybackExtras();
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
    if (AppPlatform.isWindows || AppPlatform.isLinux || AppPlatform.isMacOS) {
      windowManager.addListener(this);
      _initAlwaysOnTopState();
    }


    // Focus play/pause button on first frame if in keyboard mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusPlayPauseIfKeyboardMode();
    });
    // Register global key handler for focus-independent shortcuts (desktop only)
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
    // Listen for first frame to start auto-hide timer
    widget.hasFirstFrame?.addListener(_onFirstFrameReady);
    // Listen for external requests to show controls (e.g. screen-level focus recovery)
    widget.controlsVisible?.addListener(_onControlsVisibleExternal);
  }

  /// Called when hasFirstFrame changes - start auto-hide timer when first frame is ready
  void _onFirstFrameReady() {
    if (widget.hasFirstFrame?.value == true) {
      _startHideTimer();
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
    widget.player.streams.position.listen((position) {
      if (_markers.isEmpty || !_markersLoaded) {
        return;
      }

      PlexMarker? foundMarker;
      for (final marker in _markers) {
        if (marker.containsPosition(position)) {
          foundMarker = marker;
          break;
        }
      }

      if (foundMarker != _currentMarker) {
        if (mounted) {
          setState(() {
            _currentMarker = foundMarker;
          });

          // Start auto-skip timer for new marker
          if (foundMarker != null) {
            _startAutoSkipTimer(foundMarker);

            // Auto-focus skip button on TV when marker appears (only in keyboard/TV mode, if controls hidden)
            if (PlatformDetector.isTV() && InputModeTracker.isKeyboardMode(context)) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_showControls) {
                  _skipMarkerFocusNode.requestFocus();
                }
              });
            }
          } else {
            _cancelAutoSkipTimer();
          }
        }
      }
    });
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

  void _skipMarker() {
    if (_currentMarker != null) {
      final endTime = _currentMarker!.endTime;
      widget.player.seek(endTime);
      widget.onSeekCompleted?.call(endTime);
    }
    _cancelAutoSkipTimer();
  }

  void _startAutoSkipTimer(PlexMarker marker) {
    _cancelAutoSkipTimer();

    final shouldAutoSkip = (marker.isCredits && _autoSkipCredits) || (!marker.isCredits && _autoSkipIntro);

    if (!shouldAutoSkip || _autoSkipDelay <= 0) return;

    _autoSkipProgress = 0.0;
    const tickDuration = Duration(milliseconds: 50);
    final totalTicks = (_autoSkipDelay * 1000) / tickDuration.inMilliseconds;

    if (totalTicks <= 0) return;

    _autoSkipTimer = Timer.periodic(tickDuration, (timer) {
      if (!mounted || _currentMarker != marker) {
        timer.cancel();
        return;
      }

      setState(() {
        _autoSkipProgress = (timer.tick / totalTicks).clamp(0.0, 1.0);
      });

      if (timer.tick >= totalTicks) {
        timer.cancel();
        try {
          _performAutoSkip();
        } catch (e) {
          // Handle any errors during skip gracefully
        }
      }
    });
  }

  void _cancelAutoSkipTimer() {
    _autoSkipTimer?.cancel();
    _autoSkipTimer = null;
    if (mounted) {
      setState(() {
        _autoSkipProgress = 0.0;
      });
    }
  }

  /// Perform the appropriate skip action based on marker type and next episode availability
  void _performAutoSkip() {
    if (_currentMarker == null) return;

    final isCredits = _currentMarker!.isCredits;
    final hasNextEpisode = widget.onNext != null;
    final showNextEpisode = isCredits && hasNextEpisode;

    if (showNextEpisode) {
      widget.onNext?.call();
    } else {
      _skipMarker();
    }
  }

  /// Check if auto-skip should be active for the current marker
  bool _shouldShowAutoSkip() {
    if (_currentMarker == null) return false;
    return (_currentMarker!.isCredits && _autoSkipCredits) || (!_currentMarker!.isCredits && _autoSkipIntro);
  }

  Future<void> _loadSeekTimes() async {
    final settingsService = await SettingsService.getInstance();
    if (mounted) {
      setState(() {
        _seekTimeSmall = settingsService.getSeekTimeSmall();
        _audioSyncOffset = settingsService.getAudioSyncOffset();
        _subtitleSyncOffset = settingsService.getSubtitleSyncOffset();
        _isRotationLocked = settingsService.getRotationLocked();
        _autoSkipIntro = settingsService.getAutoSkipIntro();
        _autoSkipCredits = settingsService.getAutoSkipCredits();
        _autoSkipDelay = settingsService.getAutoSkipDelay();
        _videoPlayerNavigationEnabled = settingsService.getVideoPlayerNavigationEnabled();
        _showPerformanceOverlay = settingsService.getShowPerformanceOverlay();
        _clickVideoTogglesPlayback = settingsService.getClickVideoTogglesPlayback();
      });

      // Focus play/pause if navigation is now enabled and controls are visible
      // (handles case where initState focus attempt failed due to async settings load)
      if (_videoPlayerNavigationEnabled && _showControls) {
        _focusPlayPauseIfKeyboardMode();
      }

      // Apply rotation lock setting
      if (_isRotationLocked) {
        SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
      } else {
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      }
    }
  }

  void _toggleSubtitles() {
    // Toggle subtitle visibility - this would need to be implemented based on your subtitle system
    // For now, this is a placeholder
  }

  void _toggleShader() {
    final shaderService = widget.shaderService;
    if (shaderService == null || !shaderService.isSupported) return;

    if (shaderService.currentPreset.isEnabled) {
      // Currently active - disable temporarily
      shaderService.applyPreset(ShaderPreset.none).then((_) {
        if (mounted) setState(() {});
        widget.onShaderChanged?.call();
      });
    } else {
      // Currently off - restore saved preset
      final shaderProvider = context.read<ShaderProvider>();
      final saved = shaderProvider.savedPreset;
      final targetPreset = saved.isEnabled
          ? saved
          : ShaderPreset.allPresets.firstWhere((p) => p.isEnabled, orElse: () => ShaderPreset.allPresets[1]);
      shaderService.applyPreset(targetPreset).then((_) {
        shaderProvider.setCurrentPreset(targetPreset);
        if (mounted) setState(() {});
        widget.onShaderChanged?.call();
      });
    }
  }

  void _nextAudioTrack() {
    // Switch to next audio track - this would need to be implemented based on your track system
    // For now, this is a placeholder
  }

  void _nextSubtitleTrack() {
    // Switch to next subtitle track - this would need to be implemented based on your subtitle system
    // For now, this is a placeholder
  }

  void _nextChapter() {
    // Go to next chapter - this would use your existing chapter navigation
    if (widget.onNext != null) {
      widget.onNext!();
    }
  }

  void _previousChapter() {
    // Go to previous chapter - this would use your existing chapter navigation
    if (widget.onPrevious != null) {
      widget.onPrevious!();
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    widget.controlsVisible?.removeListener(_onControlsVisibleExternal);
    widget.hasFirstFrame?.removeListener(_onFirstFrameReady);
    _hideTimer?.cancel();
    _feedbackTimer?.cancel();
    _autoSkipTimer?.cancel();
    _singleTapTimer?.cancel();
    _seekThrottle.cancel();
    _playingSubscription?.cancel();
    _completedSubscription?.cancel();
    _focusNode.dispose();
    _skipMarkerFocusNode.dispose();
    // Restore original rate if long-press was active when disposed
    if (_isLongPressing && _rateBeforeLongPress != null) {
      widget.player.setRate(_rateBeforeLongPress!);
    }
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    // Remove window listener
    if (AppPlatform.isWindows || AppPlatform.isLinux || AppPlatform.isMacOS) {
      windowManager.removeListener(this);
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
    if (mounted && AppPlatform.isMacOS) {
      setState(() {
        _isFullscreen = true;
      });
    }
  }

  @override
  void onWindowUnmaximize() {
    // On macOS, unmaximize means exiting fullscreen
    if (mounted && AppPlatform.isMacOS) {
      setState(() {
        _isFullscreen = false;
      });
    }
  }

  @override
  void onWindowResize() {
    // Lag during resize is now handled in native code (glViewport + resize signal handler)
  }

  /// Controls hide delay: 5s on mobile/TV/keyboard-nav, 3s on desktop with mouse.
  Duration get _hideDelay {
    final isMobile = PlatformDetector.isMobile(context) && !PlatformDetector.isTV();
    if (isMobile || PlatformDetector.isTV() || _videoPlayerNavigationEnabled) {
      return const Duration(seconds: 5);
    }
    return const Duration(seconds: 3);
  }

  /// Shared hide logic: hides controls, notifies parent, updates traffic lights, restores focus.
  void _hideControls() {
    if (!mounted || !_showControls) return;
    setState(() {
      _showControls = false;
    });
    widget.controlsVisible?.value = false;
    if (AppPlatform.isMacOS) {
      _updateTrafficLightVisibility();
    }
    // Immediately try to reclaim focus (important for TV where global handler
    // won't fire if _focusNode lost focus)
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focusNode.hasFocus) {
        _focusNode.requestFocus();
      }
    });
  }

  void _startHideTimer() {
    _hideTimer?.cancel();

    // Don't auto-hide while loading first frame (user needs to see spinner and back button)
    final hasFrame = widget.hasFirstFrame?.value ?? true;
    if (!hasFrame) return;

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
      SettingsService.getInstance().then((s) => s.setVolume(newVolume));
      _showControlsFromPointerActivity();
    }
  }

  /// Show controls in response to pointer activity (mouse/trackpad movement).
  void _showControlsFromPointerActivity() {
    if (!_showControls) {
      setState(() {
        _showControls = true;
      });
      // Notify parent of visibility change (for popup positioning)
      widget.controlsVisible?.value = true;
      // On macOS, keep window controls in sync with the overlay
      if (AppPlatform.isMacOS) {
        _updateTrafficLightVisibility();
      }
    }

    // Keep the overlay visible while the user is moving the pointer
    _restartHideTimerIfPlaying();

    // Cancel auto-skip when user moves pointer over the player
    _cancelAutoSkipTimer();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    // Notify parent of visibility change (for popup positioning)
    widget.controlsVisible?.value = _showControls;
    // Cancel auto-skip on any tap, not just when controls become visible
    _cancelAutoSkipTimer();
    if (_showControls) {
      _startHideTimer();
    }

    // On macOS, hide/show traffic lights with controls
    if (AppPlatform.isMacOS) {
      _updateTrafficLightVisibility();
    }
  }

  void _toggleRotationLock() async {
    setState(() {
      _isRotationLocked = !_isRotationLocked;
    });

    // Save to settings
    final settingsService = await SettingsService.getInstance();
    await settingsService.setRotationLocked(_isRotationLocked);

    if (_isRotationLocked) {
      // Locked: Allow landscape orientations only
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    } else {
      // Unlocked: Allow all orientations including portrait
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
  }

  void _updateTrafficLightVisibility() async {
    // When maximized or fullscreen, always keep traffic lights visible so the
    // user can reach them without the controls-hide-on-mouse-leave race.
    // In normal windowed mode, toggle with controls as before.
    final isMaximizedOrFullscreen = await windowManager.isMaximized() || await windowManager.isFullScreen();
    final visible = isMaximizedOrFullscreen ? true : _showControls;
    await MacOSWindowService.setTrafficLightsVisible(visible);
  }

  /// Check whether PiP is supported on this device
  Future<void> _checkPipSupport() async {
    if (!AppPlatform.isAndroid) {
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

  Future<void> _loadPlaybackExtras() async {
    try {
      appLogger.d('_loadPlaybackExtras: starting for ${widget.metadata.ratingKey}');
      final client = _getClientForMetadata();
      appLogger.d('_loadPlaybackExtras: got client with serverId=${client.serverId}');

      final extras = await client.getPlaybackExtras(widget.metadata.ratingKey);
      appLogger.d('_loadPlaybackExtras: got ${extras.chapters.length} chapters');

      if (mounted) {
        setState(() {
          _chapters = extras.chapters;
          _markers = extras.markers;
          _chaptersLoaded = true;
          _markersLoaded = true;
        });
      }
    } catch (e, stack) {
      // Fallback: try to load from cache directly (for offline playback)
      appLogger.d('_loadPlaybackExtras: client unavailable, trying cache fallback');
      final serverId = widget.metadata.serverId;
      if (serverId != null) {
        final cacheKey = '/library/metadata/${widget.metadata.ratingKey}';
        final cached = await PlexApiCache.instance.get(serverId, cacheKey);
        if (cached != null) {
          final extras = _parsePlaybackExtrasFromCache(cached);
          appLogger.d('_loadPlaybackExtras: loaded ${extras.chapters.length} chapters from cache');
          if (mounted) {
            setState(() {
              _chapters = extras.chapters;
              _markers = extras.markers;
              _chaptersLoaded = true;
              _markersLoaded = true;
            });
          }
          return;
        }
      }
      appLogger.e('_loadPlaybackExtras failed', error: e, stackTrace: stack);
    }
  }

  /// Parse PlaybackExtras from cached API response (for offline playback)
  PlaybackExtras _parsePlaybackExtrasFromCache(Map<String, dynamic> cached) {
    final chapters = <PlexChapter>[];
    final markers = <PlexMarker>[];

    final metadataJson = PlexCacheParser.extractFirstMetadata(cached);
    if (metadataJson != null) {
      // Parse chapters
      if (metadataJson['Chapter'] != null) {
        for (var chapter in metadataJson['Chapter'] as List) {
          chapters.add(
            PlexChapter(
              id: chapter['id'] as int,
              index: chapter['index'] as int?,
              startTimeOffset: chapter['startTimeOffset'] as int?,
              endTimeOffset: chapter['endTimeOffset'] as int?,
              title: chapter['tag'] as String?,
              thumb: chapter['thumb'] as String?,
            ),
          );
        }
      }

      // Parse markers
      if (metadataJson['Marker'] != null) {
        for (var marker in metadataJson['Marker'] as List) {
          markers.add(
            PlexMarker(
              id: marker['id'] as int,
              type: marker['type'] as String,
              startTimeOffset: marker['startTimeOffset'] as int,
              endTimeOffset: marker['endTimeOffset'] as int,
            ),
          );
        }
      }
    }

    return PlaybackExtras(chapters: chapters, markers: markers);
  }

  Widget _buildTrackChapterControlsWidget() {
    return TrackChapterControls(
      player: widget.player,
      chapters: _chapters,
      chaptersLoaded: _chaptersLoaded,
      availableVersions: widget.availableVersions,
      selectedMediaIndex: widget.selectedMediaIndex,
      boxFitMode: widget.boxFitMode,
      audioSyncOffset: _audioSyncOffset,
      subtitleSyncOffset: _subtitleSyncOffset,
      isRotationLocked: _isRotationLocked,
      isFullscreen: _isFullscreen,
      onTogglePIPMode: (_isPipSupported && AppPlatform.isAndroid) ? widget.onTogglePIPMode : null,
      onCycleBoxFitMode: widget.player.playerType != 'exoplayer' ? widget.onCycleBoxFitMode : null,
      onToggleRotationLock: _toggleRotationLock,
      onToggleFullscreen: _toggleFullscreen,
      onSwitchVersion: _switchMediaVersion,
      onAudioTrackChanged: widget.onAudioTrackChanged,
      onSubtitleTrackChanged: widget.onSubtitleTrackChanged,
      onLoadSeekTimes: () async {
        if (mounted) {
          await _loadSeekTimes();
        }
      },
      onCancelAutoHide: () => _hideTimer?.cancel(),
      onStartAutoHide: _startHideTimer,
      serverId: widget.metadata.serverId ?? '',
      canControl: widget.canControl,
      shaderService: widget.shaderService,
      onShaderChanged: widget.onShaderChanged,
    );
  }

  void _seekToPreviousChapter() => _seekToChapter(forward: false);

  void _seekToNextChapter() => _seekToChapter(forward: true);

  void _seekByTime({required bool forward}) {
    final delta = Duration(seconds: forward ? _seekTimeSmall : -_seekTimeSmall);
    final newPosition = seekWithClamping(widget.player, delta);
    widget.onSeekCompleted?.call(newPosition);
  }

  void _seekToChapter({required bool forward}) {
    if (_chapters.isEmpty) {
      // No chapters - seek by configured amount
      final delta = Duration(seconds: forward ? _seekTimeSmall : -_seekTimeSmall);
      final duration = widget.player.state.duration;
      final unclamped = widget.player.state.position + delta;
      final newPosition = unclamped < Duration.zero ? Duration.zero : (unclamped > duration ? duration : unclamped);
      seekWithClamping(widget.player, delta);
      widget.onSeekCompleted?.call(newPosition);
      return;
    }

    final currentPositionMs = widget.player.state.position.inMilliseconds;

    if (forward) {
      // Find next chapter
      for (final chapter in _chapters) {
        final chapterStart = chapter.startTimeOffset ?? 0;
        if (chapterStart > currentPositionMs) {
          _seekToPosition(Duration(milliseconds: chapterStart));
          return;
        }
      }
    } else {
      // Find previous/current chapter
      for (int i = _chapters.length - 1; i >= 0; i--) {
        final chapterStart = _chapters[i].startTimeOffset ?? 0;
        if (currentPositionMs > chapterStart + 3000) {
          // If more than 3 seconds into chapter, go to start of current chapter
          _seekToPosition(Duration(milliseconds: chapterStart));
          return;
        }
      }
      // If at start of first chapter, go to beginning
      _seekToPosition(Duration.zero);
    }
  }

  void _seekToPosition(Duration position) {
    widget.player.seek(position);
    widget.onSeekCompleted?.call(position);
  }

  /// Throttled seek for timeline slider - executes immediately then throttles to 200ms
  void _throttledSeek(Duration position) => _seekThrottle([position]);

  /// Finalizes the seek when user stops scrubbing the timeline
  void _finalizeSeek(Duration position) {
    _seekThrottle.cancel();
    widget.player.seek(position);
    widget.onSeekCompleted?.call(position);
  }

  /// Handle tap in skip zone for desktop mode
  void _handleTapInSkipZoneDesktop() {
    if (widget.canControl && _clickVideoTogglesPlayback) {
      widget.player.playOrPause();
    }

    _toggleControls();
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
        _handleStackingSkip(isForward: isForward);
      } else {
        // First double-tap - initiate skip
        _handleDoubleTapSkip(isForward: isForward);
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
  void _handleStackingSkip({required bool isForward}) {
    if (!widget.canControl) return;

    // Add to accumulated skip
    _accumulatedSkipSeconds += _seekTimeSmall;

    // Calculate and perform seek
    final delta = Duration(seconds: isForward ? _seekTimeSmall : -_seekTimeSmall);
    final newPosition = seekWithClamping(widget.player, delta);

    // Notify Watch Together
    widget.onSeekCompleted?.call(newPosition);

    // Refresh feedback (extends timer, updates display)
    _showSkipFeedback(isForward: isForward);

    // Record skip time for debounce
    _lastSkipActionTime = DateTime.now();
  }

  /// Handle double-tap skip forward or backward
  void _handleDoubleTapSkip({required bool isForward}) {
    // Ignore if user cannot control playback
    if (!widget.canControl) return;

    // Reset accumulated skip for new gesture
    _accumulatedSkipSeconds = _seekTimeSmall;

    // Calculate the new position (clamped to valid range)
    final currentPosition = widget.player.state.position;
    final duration = widget.player.state.duration;
    final delta = Duration(seconds: isForward ? _seekTimeSmall : -_seekTimeSmall);
    final unclamped = currentPosition + delta;
    final newPosition = unclamped < Duration.zero ? Duration.zero : (unclamped > duration ? duration : unclamped);

    // Perform the seek
    seekWithClamping(widget.player, delta);

    // Notify Watch Together
    widget.onSeekCompleted?.call(newPosition);

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
        widget.player.playOrPause();
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
    if (!widget.canControl) return; // Respect Watch Together permissions

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
              _lastDoubleTapWasForward ? Symbols.fast_forward_rounded : Symbols.fast_rewind_rounded,
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

  /// Build the visual indicator for long-press 2x speed
  Widget _buildSpeedIndicator() {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(Symbols.fast_forward_rounded, fill: 1, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              const Text(
                '2x',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFullscreen() async {
    if (!PlatformDetector.isMobile(context)) {
      await FullscreenStateManager().toggleFullscreen();
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
      _isAlwaysOnTop = !_isAlwaysOnTop;
      await windowManager.setAlwaysOnTop(_isAlwaysOnTop);
      setState(() {});
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

    // TV back key fallback — Focus.onKeyEvent won't fire if _focusNode lost focus
    if (PlatformDetector.isTV() && event.logicalKey.isBackKey) {
      if (!_focusNode.hasFocus) {
        final backResult = handleBackKeyAction(event, () {
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
      widget.player.playOrPause();
      _showControlsWithFocus(requestFocus: false);
      return true; // Event handled, stop propagation
    }

    // Fallback: handle all other shortcuts when focus has drifted away
    // (e.g. after controls auto-hide). The !hasFocus guard prevents
    // double-handling when the Focus onKeyEvent already processes the event.
    if (!_focusNode.hasFocus && _keyboardService != null) {
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
      if (AppPlatform.isMacOS) {
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
      if (AppPlatform.isMacOS) {
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
      setState(() {
        _showControls = false;
      });
      // Notify parent of visibility change (for popup positioning)
      widget.controlsVisible?.value = false;
      // Return focus to the main focus node
      _focusNode.requestFocus();
      if (AppPlatform.isMacOS) {
        _updateTrafficLightVisibility();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use desktop controls for desktop platforms AND Android TV
    final isMobile = PlatformDetector.isMobile(context) && !PlatformDetector.isTV();

    // Hide ALL controls when in PiP mode (Android only)
    return ValueListenableBuilder<bool>(
      valueListenable: _pipService.isPipActive,
      builder: (context, isInPip, _) {
        if (isInPip) return const SizedBox.shrink();
        return Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: (node, event) {
            final backResult = handleBackKeyAction(event, () {
              // On Windows/Linux with navigation off, ESC first exits fullscreen
              if (!_videoPlayerNavigationEnabled && _isFullscreen && (AppPlatform.isWindows || AppPlatform.isLinux)) {
                _toggleFullscreen();
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
                  widget.player.playOrPause();
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
                _seekToChapter(forward: isForward);
              }
              _showControlsWithFocus(requestFocus: _videoPlayerNavigationEnabled);
              return KeyEventResult.handled;
            }

            // Handle next/previous track keys (Android TV remotes)
            // Uses same behavior as seek keys: chapter navigation or time-based seek
            if (event is KeyDownEvent && _isMediaTrackKey(key)) {
              if (widget.canControl) {
                _seekToChapter(forward: key == LogicalKeyboardKey.mediaTrackNext);
              }
              _showControlsWithFocus(requestFocus: _videoPlayerNavigationEnabled);
              return KeyEventResult.handled;
            }

            // Handle Select/Enter when controls are hidden: pause and show controls
            // Only intercept if this Focus node itself has primary focus (not a descendant)
            if (_isSelectKey(key) && !_showControls && _focusNode.hasPrimaryFocus) {
              widget.player.playOrPause();
              _showControlsWithFocus();
              return KeyEventResult.handled;
            }

            // On desktop/TV, show controls on directional input
            // LEFT/RIGHT focuses timeline for seeking, UP/DOWN focuses play/pause
            if (!isMobile && _isDirectionalKey(key) && _videoPlayerNavigationEnabled) {
              if (!_showControls) {
                final isHorizontal = key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight;
                if (isHorizontal) {
                  _showControlsWithTimelineFocus();
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
              cursor: _showControls ? SystemMouseCursors.basic : SystemMouseCursors.none,
              onHover: (_) => _showControlsFromPointerActivity(),
              onExit: (_) => _hideControlsFromPointerExit(),
              child: Stack(
                children: [
                  // Keep-alive: 1px widget that continuously repaints to prevent
                  // Flutter animations from freezing when the frame clock goes idle
                  if (AppPlatform.isLinux || AppPlatform.isWindows)
                    const Positioned(top: 0, left: 0, child: _LinuxKeepAlive()),
                  // Invisible tap detector that always covers the full area
                  // Also handles long-press for 2x speed
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _toggleControls,
                      onLongPressStart: (_) => _handleLongPressStart(),
                      onLongPressEnd: (_) => _handleLongPressEnd(),
                      onLongPressCancel: _handleLongPressCancel,
                      behavior: HitTestBehavior.opaque,
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  // Middle area double-tap detector for fullscreen (desktop only)
                  // Only covers the clear video area (20% to 80% vertically)
                  if (!isMobile)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final height = constraints.maxHeight;
                          final topExclude = height * 0.20; // Top 20%
                          final bottomExclude = height * 0.20; // Bottom 20%

                          return Stack(
                            children: [
                              Positioned(
                                top: topExclude,
                                left: 0,
                                right: 0,
                                bottom: bottomExclude,
                                child: GestureDetector(
                                  onTap: _handleTapInSkipZoneDesktop,
                                  onDoubleTap: _toggleFullscreen,
                                  behavior: HitTestBehavior.translucent,
                                  child: Container(color: Colors.transparent),
                                ),
                              ),
                            ],
                          );
                        },
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
                                  child: Container(color: Colors.transparent),
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
                                  child: Container(color: Colors.transparent),
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
                        canRequestFocus: _showControls,
                        child: AnimatedOpacity(
                          opacity: _showControls ? 1.0 : 0.0,
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
                                          onPointerDown: (_) => _restartHideTimerIfPlaying(),
                                          child: MobileVideoControls(
                                            player: widget.player,
                                            metadata: widget.metadata,
                                            chapters: _chapters,
                                            chaptersLoaded: _chaptersLoaded,
                                            seekTimeSmall: _seekTimeSmall,
                                            trackChapterControls: _buildTrackChapterControlsWidget(),
                                            onSeek: _throttledSeek,
                                            onSeekEnd: _finalizeSeek,
                                            onSeekCompleted: widget.onSeekCompleted,
                                            onPlayPause: () {}, // Not used, handled internally
                                            onCancelAutoHide: () => _hideTimer?.cancel(),
                                            onStartAutoHide: _startHideTimer,
                                            onBack: widget.onBack,
                                            onNext: widget.onNext,
                                            onPrevious: widget.onPrevious,
                                            canControl: widget.canControl,
                                            hasFirstFrame: widget.hasFirstFrame,
                                            thumbnailUrlBuilder: widget.thumbnailUrlBuilder,
                                          ),
                                        )
                                      : Listener(
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
                                            onSeekBackward: () => _seekByTime(forward: false),
                                            onSeekForward: () => _seekByTime(forward: true),
                                            onSeek: _throttledSeek,
                                            onSeekEnd: _finalizeSeek,
                                            getReplayIcon: getReplayIcon,
                                            getForwardIcon: getForwardIcon,
                                            onFocusActivity: _restartHideTimerIfPlaying,
                                            onHideControls: _hideControlsFromKeyboard,
                                            // Track chapter controls data
                                            availableVersions: widget.availableVersions,
                                            selectedMediaIndex: widget.selectedMediaIndex,
                                            boxFitMode: widget.boxFitMode,
                                            audioSyncOffset: _audioSyncOffset,
                                            subtitleSyncOffset: _subtitleSyncOffset,
                                            isFullscreen: _isFullscreen,
                                            isAlwaysOnTop: _isAlwaysOnTop,
                                            onTogglePIPMode: (_isPipSupported && AppPlatform.isAndroid)
                                                ? widget.onTogglePIPMode
                                                : null,
                                            onCycleBoxFitMode: widget.player.playerType != 'exoplayer'
                                                ? widget.onCycleBoxFitMode
                                                : null,
                                            onToggleFullscreen: _toggleFullscreen,
                                            onToggleAlwaysOnTop: _toggleAlwaysOnTop,
                                            onSwitchVersion: _switchMediaVersion,
                                            onAudioTrackChanged: widget.onAudioTrackChanged,
                                            onSubtitleTrackChanged: widget.onSubtitleTrackChanged,
                                            onLoadSeekTimes: () async {
                                              if (mounted) {
                                                await _loadSeekTimes();
                                              }
                                            },
                                            onCancelAutoHide: () => _hideTimer?.cancel(),
                                            onStartAutoHide: _startHideTimer,
                                            serverId: widget.metadata.serverId ?? '',
                                            onBack: widget.onBack,
                                            canControl: widget.canControl,
                                            hasFirstFrame: widget.hasFirstFrame,
                                            shaderService: widget.shaderService,
                                            onShaderChanged: widget.onShaderChanged,
                                            thumbnailUrlBuilder: widget.thumbnailUrlBuilder,
                                          ),
                                        ),
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
                  // Skip intro/credits button
                  if (_currentMarker != null)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      right: 24,
                      bottom: _showControls ? (isMobile ? 80 : 115) : 24,
                      child: AnimatedOpacity(
                        opacity: 1.0,
                        duration: tokens(context).slow,
                        child: _buildSkipMarkerButton(),
                      ),
                    ),
                  // Performance overlay (top-left)
                  if (_showPerformanceOverlay)
                    Positioned(
                      top: isMobile ? 60 : 16,
                      left: 16,
                      child: IgnorePointer(child: PlayerPerformanceOverlay(player: widget.player)),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkipMarkerButton() {
    final isCredits = _currentMarker!.isCredits;
    final hasNextEpisode = widget.onNext != null;

    // Show "Next Episode" for credits when next episode is available
    final bool showNextEpisode = isCredits && hasNextEpisode;
    final String baseButtonText = showNextEpisode ? 'Next Episode' : (isCredits ? 'Skip Credits' : 'Skip Intro');

    final isAutoSkipActive = _autoSkipTimer?.isActive ?? false;
    final shouldShowAutoSkip = _shouldShowAutoSkip();

    final int remainingSeconds = isAutoSkipActive && shouldShowAutoSkip
        ? (_autoSkipDelay - (_autoSkipProgress * _autoSkipDelay)).ceil().clamp(0, _autoSkipDelay)
        : 0;

    final String buttonText = isAutoSkipActive && shouldShowAutoSkip && remainingSeconds > 0
        ? '$baseButtonText ($remainingSeconds)'
        : baseButtonText;
    final IconData buttonIcon = showNextEpisode ? Symbols.skip_next_rounded : Symbols.fast_forward_rounded;

    return FocusableWrapper(
      focusNode: _skipMarkerFocusNode,
      onSelect: () {
        if (isAutoSkipActive) {
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isAutoSkipActive) {
              _cancelAutoSkipTimer();
            }
            _performAutoSkip();
          },
          borderRadius: BorderRadius.circular(tokens(context).radiusSm),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(tokens(context).radiusSm),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      buttonText,
                      style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    AppIcon(buttonIcon, fill: 1, color: Colors.black, size: 20),
                  ],
                ),
              ),
              // Progress indicator overlay
              if (isAutoSkipActive && shouldShowAutoSkip)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(tokens(context).radiusSm),
                    child: Row(
                      children: [
                        Expanded(
                          flex: (_autoSkipProgress * 100).round(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(tokens(context).radiusSm),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: ((1.0 - _autoSkipProgress) * 100).round(),
                          child: Container(decoration: const BoxDecoration(color: Colors.transparent)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Switch to a different media version
  Future<void> _switchMediaVersion(int newMediaIndex) async {
    if (newMediaIndex == widget.selectedMediaIndex) {
      return; // Already using this version
    }

    try {
      // Save current playback position
      final currentPosition = widget.player.state.position;

      // Get state reference before async operations
      final videoPlayerState = context.findAncestorStateOfType<VideoPlayerScreenState>();

      // Save the preference
      final settingsService = await SettingsService.getInstance();
      final seriesKey = widget.metadata.grandparentRatingKey ?? widget.metadata.ratingKey;
      await settingsService.setMediaVersionPreference(seriesKey, newMediaIndex);

      // Set flag on parent VideoPlayerScreen to skip orientation restoration
      videoPlayerState?.setReplacingWithVideo();
      // Dispose the existing player before spinning up the replacement to avoid race conditions
      await videoPlayerState?.disposePlayerForNavigation();

      // Navigate to new player screen with the selected version
      // Use PageRouteBuilder with zero-duration transitions to prevent orientation reset
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder<bool>(
            pageBuilder: (context, animation, secondaryAnimation) => VideoPlayerScreen(
              metadata: widget.metadata.copyWith(viewOffset: currentPosition.inMilliseconds),
              selectedMediaIndex: newMediaIndex,
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
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
