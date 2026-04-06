import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/services.dart';
import 'package:os_media_controls/os_media_controls.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:window_manager/window_manager.dart';

import '../mpv/mpv.dart';
import '../mpv/player/platform/player_android.dart';

import '../../services/bif_thumbnail_service.dart';
import '../../services/plex_client.dart';
import '../models/livetv_capture_buffer.dart';
import '../models/livetv_channel.dart';
import '../services/plex_api_cache.dart';
import '../models/plex_media_version.dart';
import '../models/plex_metadata.dart';
import '../models/plex_video_playback_data.dart';
import '../utils/content_utils.dart';
import '../utils/plex_cache_parser.dart';
import '../models/plex_media_info.dart';
import '../providers/download_provider.dart';
import '../providers/multi_server_provider.dart';
import '../providers/playback_state_provider.dart';
import '../models/companion_remote/remote_command.dart';
import '../providers/companion_remote_provider.dart';
import '../services/companion_remote/companion_remote_receiver.dart';
import '../services/fullscreen_state_manager.dart';
import '../services/discord_rpc_service.dart';
import '../services/episode_navigation_service.dart';
import '../services/media_controls_manager.dart';
import '../services/playback_initialization_service.dart';
import '../services/playback_progress_tracker.dart';
import '../services/offline_watch_sync_service.dart';
import '../services/display_mode_service.dart';
import '../services/settings_service.dart';
import '../services/sleep_timer_service.dart';
import '../services/track_manager.dart';
import '../services/ambient_lighting_service.dart';
import '../services/video_filter_manager.dart';
import '../services/video_pip_manager.dart';
import '../services/pip_service.dart';
import '../models/shader_preset.dart';
import '../services/shader_service.dart';
import '../providers/shader_provider.dart';
import '../providers/user_profile_provider.dart';
import '../utils/app_logger.dart';
import '../utils/dialogs.dart';
import '../utils/player_utils.dart';
import '../utils/orientation_helper.dart';
import '../utils/platform_detector.dart';
import '../utils/provider_extensions.dart';
import '../utils/snackbar_helper.dart';
import '../utils/plex_url_helper.dart';
import '../utils/video_player_navigation.dart';
import '../widgets/overlay_sheet.dart';
import '../widgets/video_controls/video_controls.dart';
import '../focus/focusable_button.dart';
import '../focus/input_mode_tracker.dart';
import '../focus/dpad_navigator.dart';
import '../focus/key_event_utils.dart';
import '../i18n/strings.g.dart';
import '../watch_together/providers/watch_together_provider.dart';
import '../watch_together/widgets/watch_together_overlay.dart';

Future<void> _setWakelock(bool enabled) async {
  try {
    if (enabled) {
      await WakelockPlus.enable();
    } else {
      await WakelockPlus.disable();
    }
  } catch (e) {
    appLogger.w('Wakelock ${enabled ? 'enable' : 'disable'} failed: $e');
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final PlexMetadata metadata;
  final AudioTrack? preferredAudioTrack;
  final SubtitleTrack? preferredSubtitleTrack;
  final SubtitleTrack? preferredSecondarySubtitleTrack;
  final int selectedMediaIndex;
  final bool isOffline;
  final PlexVideoPlaybackData? playbackData;

  // Live TV fields
  final bool isLive;
  final String? liveChannelName;
  final String? liveStreamUrl;
  final List<LiveTvChannel>? liveChannels;
  final int? liveCurrentChannelIndex;
  final String? liveDvrKey;
  final PlexClient? liveClient;
  final String? liveSessionIdentifier;
  final String? liveSessionPath;

  const VideoPlayerScreen({
    super.key,
    required this.metadata,
    this.preferredAudioTrack,
    this.preferredSubtitleTrack,
    this.preferredSecondarySubtitleTrack,
    this.selectedMediaIndex = 0,
    this.isOffline = false,
    this.playbackData,
    this.isLive = false,
    this.liveChannelName,
    this.liveStreamUrl,
    this.liveChannels,
    this.liveCurrentChannelIndex,
    this.liveDvrKey,
    this.liveClient,
    this.liveSessionIdentifier,
    this.liveSessionPath,
  });

  @override
  State<VideoPlayerScreen> createState() => VideoPlayerScreenState();
}

class VideoPlayerScreenState extends State<VideoPlayerScreen> with WidgetsBindingObserver {
  static const int _liveEdgeThresholdSeconds = 5;

  // Track the currently active video to guard against duplicate navigation
  static String? _activeRatingKey;
  static int? _activeMediaIndex;

  static String? get activeRatingKey => _activeRatingKey;
  static int? get activeMediaIndex => _activeMediaIndex;

  Player? player;
  bool _isPlayerInitialized = false;
  PlexMetadata? _nextEpisode;
  PlexMetadata? _previousEpisode;
  bool _isLoadingNext = false;
  bool _showPlayNextDialog = false;
  bool _isPhone = false;
  List<PlexMediaVersion> _availableVersions = [];
  PlexMediaInfo? _currentMediaInfo;
  StreamSubscription<String>? _errorSubscription;
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<bool>? _completedSubscription;
  StreamSubscription<dynamic>? _mediaControlSubscription;
  StreamSubscription<bool>? _bufferingSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<void>? _playbackRestartSubscription;
  StreamSubscription<void>? _backendSwitchedSubscription;
  TrackManager? _trackManager;
  StreamSubscription<PlayerLog>? _logSubscription;
  StreamSubscription<void>? _sleepTimerSubscription;
  StreamSubscription<bool>? _mediaControlsPlayingSubscription;
  StreamSubscription<Duration>? _mediaControlsPositionSubscription;
  StreamSubscription<double>? _mediaControlsRateSubscription;
  StreamSubscription<bool>? _mediaControlsSeekableSubscription;
  StreamSubscription<Map<String, bool>>? _serverStatusSubscription;
  bool _isReplacingWithVideo = false; // Flag to skip orientation restoration during video-to-video navigation
  bool _isDisposingForNavigation = false;
  bool _isHandlingBack = false;
  BifThumbnailService? _bifService;

  // Live TV channel navigation
  int _liveChannelIndex = -1;
  String? _liveChannelName;
  String? _liveSessionIdentifier;
  String? _liveSessionPath;
  Timer? _liveTimelineTimer;
  DateTime? _livePlaybackStartTime;
  String? _liveRatingKey;
  int? _liveDurationMs;

  // Live TV time-shift
  CaptureBuffer? _captureBuffer;
  int? _programBeginsAt;
  double _streamStartEpoch = 0;
  bool _isAtLiveEdge = true;
  String? _transcodeSessionId;

  // Auto-play next episode
  Timer? _autoPlayTimer;
  int _autoPlayCountdown = 5;
  bool _completionTriggered = false;

  // Play Next dialog focus nodes (for TV D-pad navigation)
  late final FocusNode _playNextCancelFocusNode;
  late final FocusNode _playNextConfirmFocusNode;

  // "Still watching?" prompt (sleep timer)
  bool _showStillWatchingPrompt = false;
  int _stillWatchingCountdown = 30;
  Timer? _stillWatchingTimer;
  late final FocusNode _stillWatchingPauseFocusNode;
  late final FocusNode _stillWatchingContinueFocusNode;

  // Screen-level focus node: persists across loading/initialized phases so
  // key events never escape the video player route.
  late final FocusNode _screenFocusNode;
  bool _reclaimingFocus = false;

  // Cached setting: when false on Windows/Linux, ESC should not exit the player
  bool _videoPlayerNavigationEnabled = false;

  // App lifecycle state tracking
  bool _wasPlayingBeforeInactive = false;
  bool _hiddenForBackground = false;
  bool _autoPipEnabled = false;
  int _rewindOnResume = 0;
  Future<void> _lifecycleTransition = Future<void>.value();

  /// Whether to skip lifecycle actions because PiP is active or about to start.
  /// iOS auto-PiP is system-initiated during the background transition, so
  /// isPipActive may not be true yet — we also check the auto-PiP setting.
  bool get _shouldSkipForPip =>
      PipService().isPipActive.value || ((Platform.isIOS || Platform.isMacOS) && _autoPipEnabled);

  // Services
  MediaControlsManager? _mediaControlsManager;
  PlaybackProgressTracker? _progressTracker;
  VideoFilterManager? _videoFilterManager;
  VideoPIPManager? _videoPIPManager;
  ShaderService? _shaderService;
  AmbientLightingService? _ambientLightingService;
  final EpisodeNavigationService _episodeNavigation = EpisodeNavigationService();

  // Watch Together provider reference (stored early to use in dispose)
  WatchTogetherProvider? _watchTogetherProvider;

  // Companion remote state (stored early for use in dispose)
  CompanionRemoteProvider? _companionRemoteProvider;
  VoidCallback? _savedOnHome;

  /// Get the correct PlexClient for this metadata's server
  PlexClient _getClientForMetadata(BuildContext context) {
    return context.getClientForServer(widget.metadata.serverId!);
  }

  Uint8List? _getThumbnailData(Duration time) => _bifService?.getThumbnail(time);

  final ValueNotifier<bool> _isBuffering = ValueNotifier<bool>(false); // Track if video is currently buffering
  final ValueNotifier<bool> _hasFirstFrame = ValueNotifier<bool>(false); // Track if first video frame has rendered
  final ValueNotifier<bool> _isExiting = ValueNotifier<bool>(false); // Track if navigating away (for black overlay)
  final ValueNotifier<bool> _controlsVisible = ValueNotifier<bool>(
    true,
  ); // Track if video controls are visible (for popup positioning)

  @override
  void initState() {
    super.initState();

    _activeRatingKey = widget.metadata.ratingKey;
    _activeMediaIndex = widget.selectedMediaIndex;

    // Initialize live TV channel tracking
    _liveChannelIndex = widget.liveCurrentChannelIndex ?? -1;
    _liveChannelName = widget.liveChannelName;
    _liveSessionIdentifier = widget.liveSessionIdentifier;
    _liveSessionPath = widget.liveSessionPath;

    // Initialize Play Next dialog focus nodes
    _playNextCancelFocusNode = FocusNode(debugLabel: 'PlayNextCancel');
    _playNextConfirmFocusNode = FocusNode(debugLabel: 'PlayNextConfirm');

    // Initialize "Still watching?" dialog focus nodes
    _stillWatchingPauseFocusNode = FocusNode(debugLabel: 'StillWatchingPause');
    _stillWatchingContinueFocusNode = FocusNode(debugLabel: 'StillWatchingContinue');

    // Screen-level focus node that wraps the entire build output.
    // Ensures a single stable focus target across loading → initialized phases.
    _screenFocusNode = FocusNode(debugLabel: 'VideoPlayerScreen');
    _screenFocusNode.addListener(_onScreenFocusChanged);

    appLogger.d('VideoPlayerScreen initialized for: ${widget.metadata.title}');
    if (widget.preferredAudioTrack != null) {
      appLogger.d(
        'Preferred audio track: ${widget.preferredAudioTrack!.title ?? widget.preferredAudioTrack!.id} (${widget.preferredAudioTrack!.language ?? "unknown"})',
      );
    }
    if (widget.preferredSubtitleTrack != null) {
      final subtitleDesc = widget.preferredSubtitleTrack!.id == "no"
          ? "OFF"
          : "${widget.preferredSubtitleTrack!.title ?? widget.preferredSubtitleTrack!.id} (${widget.preferredSubtitleTrack!.language ?? "unknown"})";
      appLogger.d('Preferred subtitle track: $subtitleDesc');
    }

    // Update current item in playback state provider
    try {
      final playbackState = context.read<PlaybackStateProvider>();

      // Defer both operations until after the first frame to avoid calling
      // notifyListeners() during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // If this item doesn't have a playQueueItemID, it's a standalone item
        // Clear any existing queue so next/previous work correctly for this content
        if (widget.metadata.playQueueItemID == null) {
          playbackState.clearShuffle();
        } else {
          playbackState.setCurrentItem(widget.metadata);
        }
      });
    } catch (e) {
      // Provider might not be available yet during initialization
      appLogger.d('Deferred playback state update (provider not ready)', error: e);
    }

    // Register app lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    // Wire companion remote playback callbacks
    _setupCompanionRemoteCallbacks();

    // Show "Still watching?" prompt when sleep timer fires
    _sleepTimerSubscription = SleepTimerService().onPrompt.listen((_) {
      if (mounted) _showStillWatchingDialog();
    });

    // Initialize player asynchronously with buffer size from settings
    _initializePlayer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Cache device type for safe access in dispose()
    try {
      _isPhone = PlatformDetector.isPhone(context);
    } catch (e) {
      appLogger.w('Failed to determine device type', error: e);
      _isPhone = false; // Default to tablet/desktop (all orientations)
    }

    // Update video filter when dependencies change (orientation, screen size, etc.)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _videoFilterManager?.debouncedUpdateVideoFilter();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.inactive:
        // App is inactive (notification shade, split-screen, etc.)
        // Don't pause - user may still be watching
        break;
      case AppLifecycleState.hidden:
        _enqueueLifecycleTransition('hidden', _handleAppHidden);
        break;
      case AppLifecycleState.paused:
        if (_shouldSkipForPip) break;
        // Clear media controls when app truly goes to background
        // (we don't support background playback)
        _mediaControlsManager?.clear();
        // Disable wakelock when app goes to background
        _setWakelock(false);
        appLogger.d('Media controls cleared and wakelock disabled due to app being paused/backgrounded');
        break;
      case AppLifecycleState.resumed:
        _enqueueLifecycleTransition('resumed', _handleAppResumed);
        break;
      case AppLifecycleState.detached:
        // No action needed for this state
        break;
    }
  }

  void _enqueueLifecycleTransition(String label, Future<void> Function() transition) {
    _lifecycleTransition = _lifecycleTransition
        .catchError((Object error, StackTrace stackTrace) {
          appLogger.w('Previous lifecycle transition failed', error: error, stackTrace: stackTrace);
        })
        .then((_) async {
          if (!mounted) return;
          try {
            await transition();
          } catch (e, stackTrace) {
            appLogger.w('Lifecycle transition failed during $label', error: e, stackTrace: stackTrace);
          }
        });
  }

  Future<void> _handleAppHidden() async {
    if (_shouldSkipForPip) return;

    final currentPlayer = player;
    if (currentPlayer == null || !_isPlayerInitialized) return;

    // Pause first so Android MPV does not keep decoding against a transient
    // background surface while the app is locking or hiding.
    if (PlatformDetector.isMobile(context)) {
      _wasPlayingBeforeInactive = currentPlayer.state.playing;
      if (_wasPlayingBeforeInactive) {
        try {
          await currentPlayer.pause();
          appLogger.d('Video paused due to app being hidden (mobile)');
        } catch (e) {
          appLogger.w('Failed to pause video before hiding render layer', error: e);
        }
      }
    }

    if (!mounted || currentPlayer != player) return;

    _hiddenForBackground = true;
    _liveTimelineTimer?.cancel();
    await currentPlayer.setVisible(false);
    appLogger.d('Render layer hidden due to app being hidden');
  }

  Future<void> _handleAppResumed() async {
    final currentPlayer = player;

    // Restore render layer if it was hidden for background, then force a
    // video-output refresh before any auto-resume logic runs.
    if (_hiddenForBackground && currentPlayer != null && _isPlayerInitialized) {
      await currentPlayer.setVisible(true);
      await currentPlayer.updateFrame();

      if (!mounted || currentPlayer != player) return;

      _hiddenForBackground = false;
      if (_liveSessionIdentifier != null) {
        _startLiveTimelineUpdates();
      }
      appLogger.d('Render layer restored after app resumed');
    }

    // Restore media controls and wakelock when app is resumed.
    if (_isPlayerInitialized && mounted) {
      await _restoreMediaControlsAfterResume();
    }
  }

  Future<void> _initializePlayer() async {
    try {
      // Load buffer size from settings
      final settingsService = await SettingsService.getInstance();
      _videoPlayerNavigationEnabled = settingsService.getVideoPlayerNavigationEnabled();
      _autoPipEnabled = settingsService.getAutoPip();
      _rewindOnResume = settingsService.getRewindOnResume();
      final bufferSizeMB = settingsService.getBufferSize();
      final enableHardwareDecoding = settingsService.getEnableHardwareDecoding();
      final debugLoggingEnabled = settingsService.getEnableDebugLogging();
      final useExoPlayer = settingsService.getUseExoPlayer();

      // Initialize Windows display mode service.
      if (Platform.isWindows) {
        _displayModeService = DisplayModeService(settingsService, FullscreenStateManager());
        FullscreenStateManager().addListener(_onFullscreenChanged);
      }

      // Create player (on Android, uses ExoPlayer by default, MPV as fallback)
      player = Player(useExoPlayer: useExoPlayer);

      await player!.configureSubtitleFonts();
      await player!.setProperty('sub-ass', 'yes'); // Enable libass
      if (Platform.isAndroid && useExoPlayer) {
        final tunneledPlayback = settingsService.getTunneledPlayback();
        await player!.setProperty('tunneled-playback', tunneledPlayback ? 'yes' : 'no');
      }
      if (bufferSizeMB > 0) {
        final bufferSizeBytes = bufferSizeMB * 1024 * 1024;
        await player!.setProperty('demuxer-max-bytes', bufferSizeBytes.toString());
        // Set back-buffer to 1/4 of forward buffer
        final backBytes = bufferSizeBytes ~/ 4;
        await player!.setProperty('demuxer-max-back-bytes', backBytes.toString());
      }
      if (Platform.isAndroid) {
        // Cap demuxer buffers based on device heap to prevent OOM crashes.
        // Without limits, mpv defaults can consume 225MB+ just for demuxer
        // buffering, which combined with decoded frames and GPU textures
        // exhausts the process address space on memory-constrained devices.
        final heapMB = await PlayerAndroid.getHeapSize();
        if (heapMB > 0) {
          int autoBackMB;
          if (heapMB <= 256) {
            autoBackMB = 16;
          } else if (heapMB <= 512) {
            autoBackMB = 32;
          } else {
            autoBackMB = 48;
          }
          if (bufferSizeMB == 0) {
            // Auto mode: cap both forward and back buffer based on heap
            int autoForwardMB;
            if (heapMB <= 256) {
              autoForwardMB = 32;
            } else if (heapMB <= 512) {
              autoForwardMB = 64;
            } else {
              autoForwardMB = 100;
            }
            await player!.setProperty('demuxer-max-bytes', '${autoForwardMB * 1024 * 1024}');
            await player!.setProperty('demuxer-max-back-bytes', '${autoBackMB * 1024 * 1024}');
          } else {
            // Manual mode: cap back-buffer relative to heap if 1/4 ratio is too high
            final maxBackBytes = min(bufferSizeMB * 1024 * 1024 ~/ 4, autoBackMB * 1024 * 1024);
            await player!.setProperty('demuxer-max-back-bytes', maxBackBytes.toString());
          }
        }
      }
      await player!.setProperty('msg-level', debugLoggingEnabled ? 'all=debug' : 'all=error');
      await player!.setLogLevel(debugLoggingEnabled ? 'v' : 'warn');
      await player!.setProperty('hwdec', _getHwdecValue(enableHardwareDecoding));

      // Subtitle styling
      await player!.setProperty('sub-font-size', settingsService.getSubtitleFontSize().toString());
      await player!.setProperty('sub-color', settingsService.getSubtitleTextColor());
      await player!.setProperty('sub-border-size', settingsService.getSubtitleBorderSize().toString());
      await player!.setProperty('sub-border-color', settingsService.getSubtitleBorderColor());
      final bgOpacity = (settingsService.getSubtitleBackgroundOpacity() * 255 / 100).toInt();
      final bgColor = settingsService.getSubtitleBackgroundColor().replaceFirst('#', '');
      await player!.setProperty(
        'sub-back-color',
        '#${bgOpacity.toRadixString(16).padLeft(2, '0').toUpperCase()}$bgColor',
      );
      await player!.setProperty('sub-ass-override', 'no');
      await player!.setProperty('sub-ass-video-aspect-override', '1');
      await player!.setProperty('sub-pos', settingsService.getSubtitlePosition().toString());

      // Platform-specific settings
      if (Platform.isIOS) {
        await player!.setProperty('audio-exclusive', 'yes');
      }

      // Audio passthrough (desktop only - sends bitstream to receiver)
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        if (settingsService.getAudioPassthrough()) {
          await player!.setAudioPassthrough(true);
        }
      }

      // HDR is controlled via custom hdr-enabled property on iOS/macOS/Windows
      if (Platform.isIOS || Platform.isMacOS || Platform.isWindows) {
        final enableHDR = settingsService.getEnableHDR();
        await player!.setProperty('hdr-enabled', enableHDR ? 'yes' : 'no');
      }

      // Apply audio sync offset
      final audioSyncOffset = settingsService.getAudioSyncOffset();
      if (audioSyncOffset != 0) {
        final offsetSeconds = audioSyncOffset / 1000.0;
        await player!.setProperty('audio-delay', offsetSeconds.toString());
      }

      // Apply subtitle sync offset
      final subtitleSyncOffset = settingsService.getSubtitleSyncOffset();
      if (subtitleSyncOffset != 0) {
        final offsetSeconds = subtitleSyncOffset / 1000.0;
        await player!.setProperty('sub-delay', offsetSeconds.toString());
      }

      // Apply audio normalization (loudnorm filter)
      if (settingsService.getAudioNormalization()) {
        await player!.setProperty('af', 'loudnorm=I=-14:TP=-3:LRA=4');
      }

      // Apply custom MPV config entries
      final customMpvConfig = settingsService.getEnabledMpvConfigEntries();
      for (final entry in customMpvConfig.entries) {
        try {
          await player!.setProperty(entry.key, entry.value);
          appLogger.d('Applied custom MPV property: ${entry.key}=${entry.value}');
        } catch (e) {
          appLogger.w('Failed to set MPV property ${entry.key}', error: e);
        }
      }

      // Set max volume limit for volume boost
      final maxVolume = settingsService.getMaxVolume();
      await player!.setProperty('volume-max', maxVolume.toString());

      // Apply saved volume (clamped to max volume)
      final savedVolume = settingsService.getVolume().clamp(0.0, maxVolume.toDouble());
      player!.setVolume(savedVolume);

      // Notify that player is ready
      if (mounted) {
        setState(() {
          _isPlayerInitialized = true;
        });

        // Restart sleep timer if we're starting a new playback session
        final p = player;
        if (p != null) {
          SleepTimerService().restartIfNeeded(() => p.pause());
        }

        // Enable wakelock to prevent screen from turning off during playback
        _setWakelock(true);
        appLogger.d('Wakelock enabled for video playback');
      }

      // Get the video URL and start playback
      await _startPlayback();

      // Set fullscreen mode and orientation based on rotation lock setting
      if (mounted) {
        try {
          // Check rotation lock setting before applying orientation
          final isRotationLocked = settingsService.getRotationLocked();

          if (isRotationLocked) {
            // Locked: Apply landscape orientation only
            OrientationHelper.setLandscapeOrientation();
          } else {
            // Unlocked: Allow all orientations immediately
            SystemChrome.setPreferredOrientations(DeviceOrientation.values);
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
          }
        } catch (e) {
          appLogger.w('Failed to set orientation', error: e);
          // Don't crash if orientation fails - video can still play
        }
      }

      // Listen to playback state changes
      _playingSubscription = player!.streams.playing.listen(_onPlayingStateChanged);

      // Listen to completion
      _completedSubscription = player!.streams.completed.listen(_onVideoCompleted);

      // Listen to MPV errors
      _errorSubscription = player!.streams.error.listen(_onPlayerError);

      // Listen to error-level log messages for user-visible snackbars
      _logSubscription = player!.streams.log
          .where((log) => log.level == PlayerLogLevel.error || log.level == PlayerLogLevel.fatal)
          .listen(_onPlayerLogError);

      // Listen for backend switched event (ExoPlayer -> MPV fallback on Android)
      if (Platform.isAndroid && useExoPlayer) {
        _backendSwitchedSubscription = player!.streams.backendSwitched.listen((_) => _onBackendSwitched());
      }

      // Listen to buffering state
      _bufferingSubscription = player!.streams.buffering.listen((isBuffering) {
        _isBuffering.value = isBuffering;
      });

      // When server comes back online while buffering, force mpv to reconnect
      // immediately instead of waiting for ffmpeg's exponential backoff
      if (!widget.isOffline && !widget.isLive) {
        final serverId = widget.metadata.serverId;
        if (serverId != null) {
          if (!mounted) return;
          final serverManager = context.read<MultiServerProvider>().serverManager;
          bool wasOffline = false;
          _serverStatusSubscription = serverManager.statusStream.listen((statusMap) {
            final isOnline = statusMap[serverId] == true;
            if (!isOnline) {
              wasOffline = true;
            } else if (wasOffline && _isBuffering.value) {
              wasOffline = false;
              _forceStreamReconnect();
            }
          });
        }
      }

      // Listen to playback restart to detect first frame ready
      _playbackRestartSubscription = player!.streams.playbackRestart.listen((_) async {
        _lastLogError = null;
        if (!_hasFirstFrame.value) {
          _hasFirstFrame.value = true;
          Sentry.addBreadcrumb(Breadcrumb(message: 'First frame ready', category: 'player'));

          // Apply frame rate matching on Android if enabled
          if (Platform.isAndroid && settingsService.getMatchContentFrameRate()) {
            await _applyFrameRateMatching();
          }

          // Apply Windows display mode matching (refresh rate, HDR)
          if (Platform.isWindows && _displayModeService != null) {
            await _applyWindowsDisplayMatching();
          }
        }
        _trackManager?.onPlaybackRestart();
      });

      // Listen to position for completion detection (fallback for unreliable MPV events)
      _positionSubscription = player!.streams.position.listen((position) {
        // Fallback for cases where playbackRestart doesn't fire (observed on some
        // offline Android playback flows). Prevents a permanent loading spinner.
        if (!_hasFirstFrame.value && position.inMilliseconds > 0) {
          _hasFirstFrame.value = true;

          // Apply frame rate matching here too, since this fallback may fire
          // before playbackRestart (race condition with resume positions > 0)
          if (Platform.isAndroid && settingsService.getMatchContentFrameRate()) {
            _applyFrameRateMatching();
          }
        }

        final duration = player!.state.duration;
        if (duration.inMilliseconds > 0 &&
            position.inMilliseconds >= duration.inMilliseconds - 1000 &&
            !_showPlayNextDialog &&
            !_completionTriggered) {
          _onVideoCompleted(true);
        }
      });

      // Initialize services
      await _initializeServices();

      // Ensure play queue exists for sequential playback
      await _ensurePlayQueue();

      // Load next/previous episodes
      _loadAdjacentEpisodes();
    } catch (e) {
      appLogger.e('Failed to initialize player', error: e);
      if (mounted) {
        setState(() {
          _isPlayerInitialized = false;
        });
      }
    }
  }

  /// Windows display mode matching service.
  DisplayModeService? _displayModeService;

  /// Apply frame rate matching on Android by setting the display refresh rate
  /// to match the video content's frame rate.
  int _frameRateRetries = 0;
  Future<void> _applyFrameRateMatching() async {
    if (player == null || !Platform.isAndroid) return;

    try {
      final fpsStr = await player!.getProperty('container-fps');
      final fps = double.tryParse(fpsStr ?? '');
      if (fps == null || fps <= 0) {
        // ExoPlayer detects FPS from frame timestamps after ~8 rendered frames.
        // STATE_READY fires before frames render, so retry until detection completes.
        if (player is PlayerAndroid && _frameRateRetries < 10) {
          _frameRateRetries++;
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && player != null) _applyFrameRateMatching();
          });
          return;
        }
        appLogger.d('Frame rate matching: No valid fps available ($fpsStr)');
        return;
      }

      _frameRateRetries = 0;
      final durationMs = player!.state.duration.inMilliseconds;
      await player!.setVideoFrameRate(fps, durationMs);

      // Set MPV video-sync mode for smoother playback when display is synced
      await player!.setProperty('video-sync', 'display-tempo');

      Sentry.addBreadcrumb(Breadcrumb(message: 'Frame rate matching: ${fps}fps', category: 'player'));
      appLogger.d('Frame rate matching: Set display to ${fps}fps (duration: ${durationMs}ms)');
    } catch (e) {
      appLogger.w('Failed to apply frame rate matching', error: e);
    }
  }

  /// Clear frame rate matching and restore default display mode
  Future<void> _clearFrameRateMatching() async {
    if (player == null || !Platform.isAndroid) return;

    try {
      await player!.clearVideoFrameRate();
      await player!.setProperty('video-sync', 'audio');
      Sentry.addBreadcrumb(Breadcrumb(message: 'Frame rate matching cleared', category: 'player'));
      appLogger.d('Frame rate matching: Cleared, restored default display mode');
    } catch (e) {
      appLogger.d('Failed to clear frame rate matching', error: e);
    }
  }

  /// Apply Windows display mode matching (refresh rate, HDR).
  Future<void> _applyWindowsDisplayMatching() async {
    if (player == null || _displayModeService == null) return;

    try {
      final fpsStr = await player!.getProperty('container-fps');
      final fps = double.tryParse(fpsStr ?? '');

      final sigPeakStr = await player!.getProperty('video-params/sig-peak');
      final sigPeak = double.tryParse(sigPeakStr ?? '');

      final delay = await _displayModeService!.applyDisplayMatching(
        fps: fps,
        sigPeak: sigPeak,
      );

      if (delay > Duration.zero) {
        await Future.delayed(delay);
      }
    } catch (e) {
      appLogger.w('Failed to apply display mode matching', error: e);
    }
  }

  /// Called when fullscreen state changes — restore display mode if exiting fullscreen.
  void _onFullscreenChanged() {
    if (!FullscreenStateManager().isFullscreen &&
        _displayModeService != null &&
        _displayModeService!.anyChangeApplied) {
      _restoreWindowsDisplayMode();
    }
  }

  /// Restore Windows display mode to original state.
  Future<void> _restoreWindowsDisplayMode() async {
    if (_displayModeService == null || !_displayModeService!.anyChangeApplied) return;

    try {
      // If HDR was toggled, release mpv's HDR swapchain first.
      if (_displayModeService!.hdrStateChanged && player != null) {
        await player!.setProperty('target-colorspace-hint', 'no');
        await Future.delayed(const Duration(milliseconds: 200));
      }

      await _displayModeService!.restoreAll();
    } catch (e) {
      appLogger.w('Failed to restore display mode', error: e);
    }
  }

  /// Initialize the service layer
  Future<void> _initializeServices() async {
    if (!mounted || player == null) return;

    // Live TV: send timeline heartbeats to keep transcode session alive
    if (widget.isLive) {
      _startLiveTimelineUpdates();
      return;
    }

    // Get client (null in offline mode)
    final client = widget.isOffline ? null : _getClientForMetadata(context);

    // Initialize progress tracker
    if (widget.isOffline) {
      // Offline mode: queue progress updates for later sync
      final offlineWatchService = context.read<OfflineWatchSyncService>();
      _progressTracker = PlaybackProgressTracker(
        client: null,
        metadata: widget.metadata,
        player: player!,
        isOffline: true,
        offlineWatchService: offlineWatchService,
      );
      _progressTracker!.startTracking();
    } else if (client != null) {
      // Online mode: send progress to server
      _progressTracker = PlaybackProgressTracker(client: client, metadata: widget.metadata, player: player!);
      _progressTracker!.startTracking();
    }

    // Initialize media controls manager
    _mediaControlsManager = MediaControlsManager();

    // Set up media control event handling
    _mediaControlSubscription = _mediaControlsManager!.controlEvents.listen((event) {
      final currentPlayer = player;
      if (currentPlayer == null && event is! NextTrackEvent && event is! PreviousTrackEvent) return;

      if (event is PlayEvent) {
        appLogger.d('Media control: Play event received');
        _seekBackForRewind(currentPlayer!);
        currentPlayer.play();
        _wasPlayingBeforeInactive = false;
        _updateMediaControlsPlaybackState();
      } else if (event is PauseEvent) {
        appLogger.d('Media control: Pause event received');
        currentPlayer!.pause();
        _updateMediaControlsPlaybackState();
      } else if (event is TogglePlayPauseEvent) {
        appLogger.d('Media control: Toggle play/pause event received');
        if (currentPlayer!.state.playing) {
          currentPlayer.pause();
        } else {
          _seekBackForRewind(currentPlayer);
          currentPlayer.play();
          _wasPlayingBeforeInactive = false;
        }
        _updateMediaControlsPlaybackState();
      } else if (event is SeekEvent) {
        appLogger.d('Media control: Seek event received to ${event.position}');
        unawaited(currentPlayer!.seek(clampSeekPosition(currentPlayer, event.position)));
      } else if (event is NextTrackEvent) {
        appLogger.d('Media control: Next track event received');
        if (_nextEpisode != null) _playNext();
      } else if (event is PreviousTrackEvent) {
        appLogger.d('Media control: Previous track event received');
        if (_previousEpisode != null) _playPrevious();
      }
    });

    // Update media metadata (client can be null in offline mode - artwork won't be shown)
    await _mediaControlsManager!.updateMetadata(
      metadata: widget.metadata,
      client: client,
      duration: widget.metadata.duration != null ? Duration(milliseconds: widget.metadata.duration!) : null,
    );

    if (!mounted) return;

    await _syncMediaControlsAvailability();

    // Listen to playing state and update media controls
    _mediaControlsPlayingSubscription = player!.streams.playing.listen((isPlaying) {
      _updateMediaControlsPlaybackState();
    });

    // Listen to position updates for media controls and Discord
    _mediaControlsPositionSubscription = player!.streams.position.listen((position) {
      _mediaControlsManager?.updatePlaybackState(
        isPlaying: player!.state.playing,
        position: position,
        speed: player!.state.rate,
      );
      DiscordRPCService.instance.updatePosition(position);
    });

    // Listen to playback rate changes for Discord Rich Presence
    _mediaControlsRateSubscription = player!.streams.rate.listen((rate) {
      DiscordRPCService.instance.updatePlaybackSpeed(rate);
    });

    _mediaControlsSeekableSubscription = player!.streams.seekable.listen((_) {
      unawaited(_syncMediaControlsAvailability());
    });

    // Start Discord Rich Presence for current media
    if (client != null) {
      DiscordRPCService.instance.startPlayback(widget.metadata, client);
    }
  }

  /// Ensure a play queue exists for sequential episode playback
  Future<void> _ensurePlayQueue() async {
    if (!mounted) return;

    // Skip play queue in offline mode (requires server connection)
    if (widget.isOffline) return;

    // Skip play queue for live TV (would interfere with tuner session)
    if (widget.isLive) return;

    // Only create play queues for episodes
    if (!widget.metadata.isEpisode) {
      return;
    }

    try {
      final client = _getClientForMetadata(context);

      final playbackState = context.read<PlaybackStateProvider>();

      // Determine the show's rating key
      // For episodes, grandparentRatingKey points to the show
      final showRatingKey = widget.metadata.grandparentRatingKey;
      if (showRatingKey == null) {
        appLogger.d('Episode missing grandparentRatingKey, skipping play queue creation');
        return;
      }

      // Check if there's already an active queue
      final existingContextKey = playbackState.shuffleContextKey;
      final isQueueActive = playbackState.isQueueActive;

      if (isQueueActive) {
        // A queue already exists (could be shuffle, playlist, or sequential)
        // Just update the current item, don't create a new queue
        playbackState.setCurrentItem(widget.metadata);
        appLogger.d('Using existing play queue (context: $existingContextKey)');
        return;
      }

      // Create a new sequential play queue for the show
      appLogger.d('Creating sequential play queue for show $showRatingKey');
      final playQueue = await client.createShowPlayQueue(
        showRatingKey: showRatingKey,
        shuffle: 0, // Sequential order
        startingEpisodeKey: widget.metadata.ratingKey,
      );

      if (playQueue != null && playQueue.items != null && playQueue.items!.isNotEmpty) {
        // Initialize playback state with the play queue
        await playbackState.setPlaybackFromPlayQueue(playQueue, showRatingKey);

        // Set the client for loading more items
        playbackState.setClient(client);

        appLogger.d('Sequential play queue created with ${playQueue.items!.length} items');
      }
    } catch (e) {
      // Non-critical: Sequential playback will fall back to non-queue navigation
      appLogger.d('Could not create play queue for sequential playback', error: e);
    }
  }

  Future<void> _loadAdjacentEpisodes() async {
    if (!mounted || widget.isLive) return;

    if (widget.isOffline) {
      // Offline mode: find next/previous from downloaded episodes
      _loadAdjacentEpisodesOffline();
      return;
    }

    try {
      // Load adjacent episodes using the service
      final adjacentEpisodes = await _episodeNavigation.loadAdjacentEpisodes(
        context: context,
        metadata: widget.metadata,
      );

      if (mounted) {
        setState(() {
          _nextEpisode = adjacentEpisodes.next;
          _previousEpisode = adjacentEpisodes.previous;
        });
      }
    } catch (e) {
      // Non-critical: Failed to load next/previous episode metadata
      appLogger.d('Could not load adjacent episodes', error: e);
    }
  }

  /// Load next/previous episodes from locally downloaded content
  void _loadAdjacentEpisodesOffline() {
    if (!widget.metadata.isEpisode) return;

    final showKey = widget.metadata.grandparentRatingKey;
    if (showKey == null) return;

    try {
      final downloadProvider = context.read<DownloadProvider>();
      final episodes = downloadProvider.getDownloadedEpisodesForShow(showKey);

      if (episodes.isEmpty) return;

      // Sort by aired date, falling back to season/episode number
      final sorted = List<PlexMetadata>.from(episodes)
        ..sort((a, b) {
          final aDate = a.originallyAvailableAt ?? '';
          final bDate = b.originallyAvailableAt ?? '';
          if (aDate.isEmpty && bDate.isEmpty) {
            final seasonCmp = (a.parentIndex ?? 0).compareTo(b.parentIndex ?? 0);
            if (seasonCmp != 0) return seasonCmp;
            return (a.index ?? 0).compareTo(b.index ?? 0);
          }
          if (aDate.isEmpty) return 1;
          if (bDate.isEmpty) return -1;
          return aDate.compareTo(bDate);
        });

      // Find current episode in the sorted list
      final currentIdx = sorted.indexWhere((ep) => ep.ratingKey == widget.metadata.ratingKey);

      if (currentIdx == -1) return;

      if (mounted) {
        setState(() {
          _previousEpisode = currentIdx > 0 ? sorted[currentIdx - 1] : null;
          _nextEpisode = currentIdx < sorted.length - 1 ? sorted[currentIdx + 1] : null;
        });
      }
    } catch (e) {
      appLogger.d('Could not load offline adjacent episodes', error: e);
    }
  }

  Future<void> _startPlayback() async {
    if (!mounted) return;

    // Live TV mode: bypass standard playback initialization
    if (widget.isLive) {
      try {
        _hasFirstFrame.value = false;
        await player!.requestAudioFocus();
        await _setLiveStreamOptions();

        String streamUrl;
        if (widget.liveStreamUrl != null) {
          streamUrl = widget.liveStreamUrl!;
        } else {
          // Tune channel inside the player (shows loading spinner while tuning)
          final channels = widget.liveChannels;
          final channelIndex = _liveChannelIndex;
          if (channels == null || channelIndex < 0 || channelIndex >= channels.length) {
            throw Exception('No channel to tune');
          }
          final channel = channels[channelIndex];
          appLogger.d('Tune: dvrKey=${widget.liveDvrKey} channelKey=${channel.key}');
          final client = widget.liveClient!;
          final tuneResult = await client.tuneChannel(widget.liveDvrKey!, channel.key);
          if (tuneResult == null) throw Exception('Failed to tune channel');

          _liveSessionIdentifier = tuneResult.sessionIdentifier;
          _liveSessionPath = tuneResult.sessionPath;
          _liveRatingKey = tuneResult.metadata.ratingKey;
          _liveDurationMs = tuneResult.metadata.duration;
          _captureBuffer = tuneResult.captureBuffer;
          _programBeginsAt = tuneResult.beginsAt;
          _transcodeSessionId = PlexClient.generateSessionIdentifier();

          // Show "Watch from Start" dialog when an existing capture session has >60s of history.
          // On a fresh tune (no active recording), the buffer is empty so this won't trigger.
          int? offsetSeconds;
          if (_captureBuffer != null && _programBeginsAt != null) {
            final nowEpoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            final effectiveStart = max(_captureBuffer!.seekableStartEpoch, _programBeginsAt!);
            final elapsed = nowEpoch - effectiveStart;
            appLogger.d('Time-shift: buffer=${_captureBuffer!.seekableDurationSeconds}s, '
                'beginsAt=$_programBeginsAt, elapsed=${elapsed}s (need >60 for dialog)');
            if (elapsed > 60) {
              final watchFromStart = await _showWatchFromStartDialog(effectiveStart, nowEpoch);
              if (!mounted) return;
              if (watchFromStart == true) {
                final programBeginsAtOffset = _programBeginsAt! - _captureBuffer!.startedAt.round();
                offsetSeconds = max(programBeginsAtOffset, _captureBuffer!.seekStartSeconds.round());
              }
            }
          }

          // Build the stream URL (with optional offset for time-shift)
          final streamPath = await client.buildLiveStreamPath(
            sessionPath: tuneResult.sessionPath,
            sessionIdentifier: tuneResult.sessionIdentifier,
            transcodeSessionId: _transcodeSessionId!,
            offsetSeconds: offsetSeconds,
          );
          if (streamPath == null || !mounted) throw Exception('Failed to build stream path');

          streamUrl = '${client.config.baseUrl}$streamPath'.withPlexToken(client.config.token);

          // Track stream start epoch for position calculations
          if (offsetSeconds != null) {
            _streamStartEpoch = _captureBuffer!.startedAt + offsetSeconds;
            _isAtLiveEdge = false;
          } else {
            _streamStartEpoch = DateTime.now().millisecondsSinceEpoch / 1000.0;
            _isAtLiveEdge = true;
          }
        }

        _livePlaybackStartTime = DateTime.now();
        await player!.open(Media(streamUrl, headers: const {'Accept-Language': 'en'}), play: true, isLive: true);

        _trackManager?.cacheExternalSubtitles(const []);

        await _initVideoFilterAndPip();

        if (mounted) {
          setState(() {
            _availableVersions = [];
            _currentMediaInfo = null;
            _isPlayerInitialized = true;
          });
          _trackManager?.mediaInfo = null;
        }
      } catch (e) {
        appLogger.e('Failed to start live TV playback', error: e);
        _sendLiveTimeline('stopped');
        if (mounted) {
          showErrorSnackBar(context, e.toString());
          _handleBackButton();
        }
      }
      return;
    }

    // Capture providers before async gaps
    final offlineWatchService = widget.isOffline ? context.read<OfflineWatchSyncService>() : null;

    try {
      PlaybackInitializationResult result;
      Map<String, String>? plexHeaders;

      if (widget.isOffline) {
        // Offline mode: get video path from downloads without requiring server
        result = await _startOfflinePlayback();
      } else {
        // Online mode: use server-specific client
        final client = _getClientForMetadata(context);
        plexHeaders = client.config.headers;
        final playbackService = PlaybackInitializationService(client: client, database: PlexApiCache.instance.database);
        result = await playbackService.getPlaybackData(
          metadata: widget.metadata,
          selectedMediaIndex: widget.selectedMediaIndex,
          preferOffline: true, // Use downloaded file if available
          playbackData: widget.playbackData,
        );
      }

      // Open video through Player
      if (result.videoUrl != null) {
        // Reset first frame flag and frame rate retry counter for new video
        _hasFirstFrame.value = false;
        _frameRateRetries = 0;

        // Request audio focus before starting playback (Android)
        // This causes other media apps (Spotify, podcasts, etc.) to pause
        await player!.requestAudioFocus();

        // Pass resume position if available.
        // In offline mode, prefer locally tracked progress over the cached server value
        // since the user may have watched further since downloading.
        Duration? resumePosition;
        if (widget.isOffline) {
          final globalKey = widget.metadata.globalKey;
          final localOffset = await offlineWatchService!.getLocalViewOffset(globalKey);
          if (localOffset != null && localOffset > 0) {
            resumePosition = Duration(milliseconds: localOffset);
            appLogger.d('Resuming offline playback from local progress: ${localOffset}ms');
          }
        }
        resumePosition ??= widget.metadata.viewOffset != null
            ? Duration(milliseconds: widget.metadata.viewOffset!)
            : null;

        // Enable FFmpeg auto-reconnect for VOD streams (covers network drops up to 10 min)
        if (!widget.isOffline && !widget.isLive) {
          await player!.setProperty(
            'stream-lavf-o',
            'reconnect=1,reconnect_on_network_error=1,reconnect_streamed=1,reconnect_delay_max=600',
          );
        }

        final hasExternalSubs = result.externalSubtitles.isNotEmpty;
        final isExoPlayer = player is PlayerAndroid;

        // ExoPlayer: attach external subs at open time so it discovers
        // them in a single prepare() — no media reload needed for selection.
        // MPV (all platforms including Android): external subs added after open via sub-add.
        await player!.open(
          Media(result.videoUrl!, start: resumePosition, headers: plexHeaders),
          play: isExoPlayer || !hasExternalSubs,
          externalSubtitles: isExoPlayer && hasExternalSubs ? result.externalSubtitles : null,
        );

        // Apply subtitle styling to ExoPlayer native layer (CaptionStyleCompat + libass font scale)
        // Must be called after open() since that's when ExoPlayer initializes
        if (player is PlayerAndroid) {
          final settingsService = await SettingsService.getInstance();
          await (player as PlayerAndroid).setSubtitleStyle(
            fontSize: settingsService.getSubtitleFontSize().toDouble(),
            textColor: settingsService.getSubtitleTextColor(),
            borderSize: settingsService.getSubtitleBorderSize().toDouble(),
            borderColor: settingsService.getSubtitleBorderColor(),
            bgColor: settingsService.getSubtitleBackgroundColor(),
            bgOpacity: settingsService.getSubtitleBackgroundOpacity(),
            subtitlePosition: settingsService.getSubtitlePosition(),
          );
        }

        // Attach player to Watch Together session for sync (if in session)
        if (mounted && !widget.isOffline) {
          _attachToWatchTogetherSession();
          _notifyWatchTogetherMediaChange();
        }
      }

      // Update available versions from the playback data
      if (mounted) {
        setState(() {
          _availableVersions = result.availableVersions.cast();
          _currentMediaInfo = result.mediaInfo;
          _bifService?.dispose();
          _bifService = null;
        });

        // Download and cache BIF thumbnail file
        if (_currentMediaInfo?.partId != null && !widget.isOffline) {
          final partId = _currentMediaInfo!.partId!;
          final client = _getClientForMetadata(context);
          final service = BifThumbnailService();
          service.load(client, partId).then((_) {
            // Guard against media having changed while the download was in flight
            if (mounted && _currentMediaInfo?.partId == partId) {
              setState(() => _bifService = service);
            } else {
              service.dispose();
            }
          });
        }

        await _initVideoFilterAndPip();

        if (player != null) {
          // Auto-PiP: set up callback for API 26-30 path and initial state
          if (_autoPipEnabled) {
            PipService.onAutoPipEntering = () {
              _videoFilterManager?.enterPipMode();
            };
            if (player!.state.playing) {
              _videoPIPManager!.updateAutoPipState(isPlaying: true);
            }
          }

          // Shader Service (MPV only)
          _shaderService = ShaderService(player!);
          if (_shaderService!.isSupported) {
            // Ambient Lighting Service
            _ambientLightingService = AmbientLightingService(player!);
            _shaderService!.ambientLightingService = _ambientLightingService;
            _videoFilterManager?.ambientLightingService = _ambientLightingService;

            await _applySavedShaderPreset();
            await _restoreAmbientLighting();
          }
        }

        // Track manager: owns track selection, external subtitle loading, and server sync
        _trackManager = TrackManager(
          player: player!,
          isActive: () => mounted && player != null,
          getClient: () => _getClientForMetadata(context),
          getProfileSettings: () => context.read<UserProfileProvider>().profileSettings,
          waitForProfileSettings: _waitForProfileSettingsIfNeeded,
          metadata: widget.metadata,
          mediaInfo: _currentMediaInfo,
          preferredAudioTrack: widget.preferredAudioTrack,
          preferredSubtitleTrack: widget.preferredSubtitleTrack,
          preferredSecondarySubtitleTrack: widget.preferredSecondarySubtitleTrack,
          showMessage: (message, {duration}) {
            if (mounted) showAppSnackBar(context, message, duration: duration);
          },
        );

        // Store external subtitles for re-use after backend fallback
        _trackManager!.cacheExternalSubtitles(result.externalSubtitles);

        // MPV with external subs: add after open via sub-add,
        // opened paused to avoid race condition (issue #226)
        if (player is! PlayerAndroid && result.externalSubtitles.isNotEmpty) {
          _hasFirstFrame.value = false;
          _trackManager!.waitingForExternalSubsTrackSelection = true;

          try {
            await _trackManager!.addExternalSubtitles(result.externalSubtitles);
          } finally {
            await _trackManager!.resumeAfterSubtitleLoad();
          }
        } else {
          // Android (subs attached at open time) or no external subs:
          // apply once tracks are available
          _trackManager!.applyTrackSelectionWhenReady();
        }
      }
    } on PlaybackException catch (e) {
      if (mounted) {
        _hasFirstFrame.value = true; // Hide spinner on error
        showErrorSnackBar(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        _hasFirstFrame.value = true; // Hide spinner on error
        showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
      }
    }
  }

  /// Start playback for offline/downloaded content
  Future<PlaybackInitializationResult> _startOfflinePlayback() async {
    final downloadProvider = context.read<DownloadProvider>();

    // Debug: log metadata info
    appLogger.d('Offline playback - serverId: ${widget.metadata.serverId}, ratingKey: ${widget.metadata.ratingKey}');

    final globalKey = widget.metadata.globalKey;
    appLogger.d('Looking up video with globalKey: $globalKey');

    final videoPath = await downloadProvider.getVideoFilePath(globalKey);
    if (videoPath == null) {
      appLogger.e('Video file path not found for globalKey: $globalKey');
      throw PlaybackException(t.messages.fileInfoNotAvailable);
    }

    appLogger.d('Starting offline playback: $videoPath');

    // Load cached media info so track selection (audio language) works offline
    PlexMediaInfo? mediaInfo;
    try {
      final serverId = widget.metadata.serverId;
      if (serverId != null) {
        final cached = await PlexApiCache.instance.get(serverId, '/library/metadata/${widget.metadata.ratingKey}');
        final metadataJson = PlexCacheParser.extractFirstMetadata(cached);
        if (metadataJson != null) {
          mediaInfo = PlexMediaInfo.fromMetadataJson(metadataJson);
        }
        appLogger.d(
          'Offline media info: cached=${cached != null}, hasMedia=${metadataJson?['Media'] != null}, '
          'audioTracks=${mediaInfo?.audioTracks.length ?? 0}, subtitleTracks=${mediaInfo?.subtitleTracks.length ?? 0}',
        );
      }
    } catch (e) {
      appLogger.d('Could not load cached media info for offline playback', error: e);
    }

    // Discover downloaded subtitle files for offline playback
    final offlineSubtitles = <SubtitleTrack>[];
    if (!videoPath.startsWith('content://')) {
      final subsPath = videoPath.replaceAll(RegExp(r'\.[^.]+$'), '_subs');
      var subsDir = Directory(subsPath);

      // Fallback: legacy structure uses 'subtitles/' in parent dir
      if (!await subsDir.exists()) {
        final legacyDir = Directory(p.join(File(videoPath).parent.path, 'subtitles'));
        if (await legacyDir.exists()) subsDir = legacyDir;
      }

      if (await subsDir.exists()) {
        final entities = await subsDir.list().toList();
        for (final entity in entities) {
          if (entity is! File) continue;
          final fileName = p.basenameWithoutExtension(entity.path);
          final trackId = int.tryParse(fileName);

          final plexTrack = trackId != null
              ? mediaInfo?.subtitleTracks.where((t) => t.id == trackId).firstOrNull
              : null;

          offlineSubtitles.add(
            SubtitleTrack.uri(
              'file://${entity.path}',
              title: plexTrack?.displayTitle ?? plexTrack?.language ?? 'Subtitle $fileName',
              language: plexTrack?.languageCode,
            ),
          );
        }
      }
    }

    return PlaybackInitializationResult(
      availableVersions: [],
      videoUrl: videoPath.contains('://') ? videoPath : 'file://$videoPath',
      mediaInfo: mediaInfo,
      externalSubtitles: offlineSubtitles,
      isOffline: true,
    );
  }

  /// Initialize VideoFilterManager and VideoPIPManager if not already set up.
  /// Called from both live TV and VOD playback paths.
  Future<void> _initVideoFilterAndPip() async {
    if (player == null || _videoFilterManager != null) return;
    final settings = await SettingsService.getInstance();
    _videoFilterManager = VideoFilterManager(
      player: player!,
      availableVersions: _availableVersions,
      selectedMediaIndex: widget.selectedMediaIndex,
      initialBoxFitMode: settings.getDefaultBoxFitMode(),
      onBoxFitModeChanged: (mode) => settings.setDefaultBoxFitMode(mode),
    );
    _videoFilterManager!.updateVideoFilter();

    _videoPIPManager = VideoPIPManager(player: player!);
    _videoPIPManager!.onBeforeEnterPip = () {
      _videoFilterManager?.enterPipMode();
    };
    _videoPIPManager!.isPipActive.addListener(_onPipStateChanged);
  }

  Future<void> _togglePIPMode() async {
    final result = await _videoPIPManager?.togglePIP();
    if (result != null && !result.$1 && mounted) {
      showErrorSnackBar(context, result.$2 ?? t.videoControls.pipFailed);
    }
  }

  /// Handle PiP state changes to restore video scaling when exiting PiP
  void _onPipStateChanged() {
    if (_videoPIPManager == null || _videoFilterManager == null) return;

    final isInPip = _videoPIPManager!.isPipActive.value;
    // Only handle exit - entry is handled by onBeforeEnterPip callback
    if (!isInPip) {
      final restoreAmbient = _videoFilterManager!.hadAmbientLightingBeforePip;
      _videoFilterManager!.exitPipMode();
      // Restore ambient lighting if it was active before PiP
      if (restoreAmbient) {
        _videoFilterManager!.clearPipAmbientLightingFlag();
        _restoreAmbientLighting();
      }
    }
  }

  /// Apply the saved shader preset on playback start.
  /// Reads directly from SettingsService (synchronous SharedPreferences) to
  /// avoid a race with ShaderProvider's async initialization.
  Future<void> _applySavedShaderPreset() async {
    if (_shaderService == null || !_shaderService!.isSupported) return;

    try {
      final shaderProvider = context.read<ShaderProvider>();
      final settings = await SettingsService.getInstance();
      final presetId = settings.getGlobalShaderPreset();
      final preset =
          (shaderProvider.initialized ? shaderProvider.findPresetById(presetId) : ShaderPreset.fromId(presetId)) ??
          ShaderPreset.none;
      await _shaderService!.applyPreset(preset);
      if (!mounted) return;
      shaderProvider.setCurrentPreset(preset);
    } catch (e) {
      appLogger.d('Could not apply shader preset', error: e);
    }
  }

  /// Restore ambient lighting from persisted setting
  Future<void> _restoreAmbientLighting() async {
    final shaderProvider = context.read<ShaderProvider>();
    final settings = await SettingsService.getInstance();
    if (!settings.getAmbientLighting()) return;

    final ambientLighting = _ambientLightingService;
    if (ambientLighting == null || !ambientLighting.isSupported) return;

    // Same enable logic as _toggleAmbientLighting
    final dwidth = await player?.getProperty('dwidth');
    final dheight = await player?.getProperty('dheight');
    if (dwidth == null || dheight == null) return;
    final w = double.tryParse(dwidth);
    final h = double.tryParse(dheight);
    if (w == null || h == null || h == 0) return;
    final videoAspect = w / h;

    final playerSize = _videoFilterManager?.playerSize;
    if (playerSize == null || playerSize.height == 0) return;
    final outputAspect = playerSize.width / playerSize.height;

    // Clear shaders — ambient lighting and shaders are mutually exclusive
    if (shaderProvider.isShaderEnabled) {
      await _shaderService!.applyPreset(ShaderPreset.none);
      shaderProvider.setCurrentPreset(ShaderPreset.none);
    }

    _videoFilterManager?.resetToContain();
    await ambientLighting.enable(videoAspect, outputAspect);
    if (mounted) setState(() {});
  }

  /// Cycle through BoxFit modes: contain → cover → fill → contain (for button)
  void _cycleBoxFitMode() {
    // Disable ambient lighting when switching boxfit modes
    // (cover/fill change the video rect, making the baked-in shader incorrect)
    _ambientLightingService?.disable();
    setState(() {
      _videoFilterManager?.cycleBoxFitMode();
    });
  }

  /// Update video-aspect-override when player size changes.
  /// The shader adapts automatically via built-in target_size uniform.
  void _updateAmbientLightingOnResize(Size newSize) {
    final ambientLighting = _ambientLightingService;
    if (ambientLighting == null || !ambientLighting.isEnabled) return;
    if (newSize.height == 0) return;

    ambientLighting.updateOutputAspect(newSize.width / newSize.height);
  }

  /// Toggle ambient lighting effect on/off
  Future<void> _toggleAmbientLighting() async {
    final ambientLighting = _ambientLightingService;
    if (ambientLighting == null || !ambientLighting.isSupported) return;
    final shaderProvider = context.read<ShaderProvider>();

    if (ambientLighting.isEnabled) {
      await ambientLighting.disable();
      _videoFilterManager?.updateVideoFilter();
    } else {
      // Get video display aspect ratio
      final dwidth = await player?.getProperty('dwidth');
      final dheight = await player?.getProperty('dheight');
      if (dwidth == null || dheight == null) return;
      final w = double.tryParse(dwidth);
      final h = double.tryParse(dheight);
      if (w == null || h == null || h == 0) return;
      final videoAspect = w / h;

      // Get player widget aspect ratio
      final playerSize = _videoFilterManager?.playerSize;
      if (playerSize == null || playerSize.height == 0) return;
      final outputAspect = playerSize.width / playerSize.height;

      // Clear shaders — ambient lighting and shaders are mutually exclusive
      if (shaderProvider.isShaderEnabled) {
        await _shaderService!.applyPreset(ShaderPreset.none);
        shaderProvider.setCurrentPreset(ShaderPreset.none);
      }

      // Force contain mode when enabling ambient lighting
      _videoFilterManager?.resetToContain();

      await ambientLighting.enable(videoAspect, outputAspect);
    }

    // Persist ambient lighting state
    final settings = await SettingsService.getInstance();
    settings.setAmbientLighting(ambientLighting.isEnabled);

    if (mounted) setState(() {});
  }

  /// Toggle between contain and cover modes only (for pinch gesture)
  void _toggleContainCover() {
    setState(() {
      _videoFilterManager?.toggleContainCover();
    });
  }

  /// Attach player to Watch Together session for playback sync
  void _attachToWatchTogetherSession() {
    try {
      final watchTogether = context.read<WatchTogetherProvider>();
      _watchTogetherProvider = watchTogether; // Store reference for use in dispose
      if (watchTogether.isInSession && player != null) {
        watchTogether.attachPlayer(player!);
        appLogger.d('WatchTogether: Player attached for sync');

        // If guest, handle mediaSwitch internally for proper navigation context
        if (!watchTogether.isHost) {
          watchTogether.onPlayerMediaSwitched = _handlePlayerMediaSwitch;
        }
      }
    } catch (e) {
      // Watch together provider not available or not in session - non-critical
      appLogger.d('Could not attach player to watch together', error: e);
    }
  }

  /// Detach player from Watch Together session
  void _detachFromWatchTogetherSession() {
    try {
      final watchTogether = _watchTogetherProvider ?? context.read<WatchTogetherProvider>();
      if (watchTogether.isInSession) {
        watchTogether.detachPlayer();
        appLogger.d('WatchTogether: Player detached');
      }
      watchTogether.onPlayerMediaSwitched = null; // Always clear player callback
    } catch (e) {
      // Non-critical
      appLogger.d('Could not detach player from watch together', error: e);
    }
  }

  /// Check if episode navigation controls should be enabled
  /// Returns true if not in Watch Together session, or if user is the host
  bool _canNavigateEpisodes() {
    if (_watchTogetherProvider == null) return true;
    if (!_watchTogetherProvider!.isInSession) return true;
    return _watchTogetherProvider!.isHost;
  }

  /// Notify watch together session of current media change (host only)
  /// If [metadata] is provided, uses that instead of widget.metadata (for episode navigation)
  void _notifyWatchTogetherMediaChange({PlexMetadata? metadata}) {
    final targetMetadata = metadata ?? widget.metadata;
    try {
      final watchTogether = context.read<WatchTogetherProvider>();
      if (watchTogether.isHost && watchTogether.isInSession) {
        watchTogether.setCurrentMedia(
          ratingKey: targetMetadata.ratingKey,
          serverId: targetMetadata.serverId!,
          mediaTitle: targetMetadata.displayTitle,
        );
      }
    } catch (e) {
      // Watch together provider not available or not in session - non-critical
      appLogger.d('Could not notify watch together of media change', error: e);
    }
  }

  /// Handle media switch from host (guest only)
  /// Uses VideoPlayerScreen's context for proper navigation (pushReplacement)
  Future<void> _handlePlayerMediaSwitch(String ratingKey, String serverId, String title) async {
    if (!mounted) return;

    appLogger.d('WatchTogether: Guest handling media switch to $title');

    // Fetch metadata for the new episode
    final multiServer = context.read<MultiServerProvider>();
    final client = multiServer.getClientForServer(serverId);
    if (client == null) {
      appLogger.w('WatchTogether: Server $serverId not found for media switch');
      return;
    }

    final metadata = await client.getMetadataWithImages(ratingKey);
    if (metadata == null || !mounted) {
      appLogger.w('WatchTogether: Could not fetch metadata for $ratingKey');
      return;
    }

    // Detach and dispose current player before switching to avoid sync calls on a disposed instance
    await disposePlayerForNavigation();
    if (!mounted) return;

    // Use same navigation as local episode change (pushReplacement from player context)
    _isReplacingWithVideo = true;
    navigateToVideoPlayer(context, metadata: metadata, usePushReplacement: true);
  }

  void _setupCompanionRemoteCallbacks() {
    final receiver = CompanionRemoteReceiver.instance;
    receiver.onStop = () {
      if (mounted) _handleBackButton();
    };
    receiver.onNextTrack = () {
      if (mounted && _nextEpisode != null) _playNext();
    };
    receiver.onPreviousTrack = () {
      if (mounted && _previousEpisode != null) _playPrevious();
    };
    receiver.onSeekForward = () async {
      if (player == null) return;
      final settings = await SettingsService.getInstance();
      final target = clampSeekPosition(
        player!,
        player!.state.position + Duration(seconds: settings.getSeekTimeSmall()),
      );
      await player!.seek(target);
    };
    receiver.onSeekBackward = () async {
      if (player == null) return;
      final settings = await SettingsService.getInstance();
      final target = clampSeekPosition(
        player!,
        player!.state.position - Duration(seconds: settings.getSeekTimeSmall()),
      );
      await player!.seek(target);
    };
    receiver.onVolumeUp = () async {
      if (player == null) return;
      final settings = await SettingsService.getInstance();
      final maxVol = settings.getMaxVolume().toDouble();
      final newVolume = (player!.state.volume + 10).clamp(0.0, maxVol);
      player!.setVolume(newVolume);
      settings.setVolume(newVolume);
    };
    receiver.onVolumeDown = () async {
      if (player == null) return;
      final settings = await SettingsService.getInstance();
      final maxVol = settings.getMaxVolume().toDouble();
      final newVolume = (player!.state.volume - 10).clamp(0.0, maxVol);
      player!.setVolume(newVolume);
      settings.setVolume(newVolume);
    };
    receiver.onVolumeMute = () async {
      if (player == null) return;
      final settings = await SettingsService.getInstance();
      final newVolume = player!.state.volume > 0 ? 0.0 : 100.0;
      player!.setVolume(newVolume);
      settings.setVolume(newVolume);
    };
    receiver.onSubtitles = _cycleSubtitleTrack;
    receiver.onAudioTracks = _cycleAudioTrack;
    receiver.onFullscreen = _toggleFullscreen;

    // Override home to exit the player first (main screen handler runs after pop)
    _savedOnHome = receiver.onHome;
    receiver.onHome = () {
      if (mounted) _handleBackButton();
    };

    // Store provider reference for use in dispose and notify remote
    try {
      _companionRemoteProvider = context.read<CompanionRemoteProvider>();
      _companionRemoteProvider!.sendCommand(RemoteCommandType.syncState, data: {'playerActive': true});
    } catch (_) {}
  }

  void _cleanupCompanionRemoteCallbacks() {
    final receiver = CompanionRemoteReceiver.instance;
    receiver.onStop = null;
    receiver.onNextTrack = null;
    receiver.onPreviousTrack = null;
    receiver.onSeekForward = null;
    receiver.onSeekBackward = null;
    receiver.onVolumeUp = null;
    receiver.onVolumeDown = null;
    receiver.onVolumeMute = null;
    receiver.onSubtitles = null;
    receiver.onAudioTracks = null;
    receiver.onFullscreen = null;
    receiver.onHome = _savedOnHome;
    _savedOnHome = null;

    // Notify remote that player is no longer active
    _companionRemoteProvider?.sendCommand(RemoteCommandType.syncState, data: {'playerActive': false});
    _companionRemoteProvider = null;
  }

  void _cycleSubtitleTrack() => _trackManager?.cycleSubtitleTrack();

  void _cycleAudioTrack() => _trackManager?.cycleAudioTrack();

  Future<void> _toggleFullscreen() async {
    if (PlatformDetector.isMobile(context)) return;
    await FullscreenStateManager().toggleFullscreen();
  }

  /// Exit fullscreen before leaving the player (Windows/Linux only).
  /// macOS is excluded because we can't distinguish native fullscreen
  /// from maximized state, so we leave the window state unchanged.
  Future<void> _exitFullscreenIfNeeded() async {
    if (Platform.isWindows || Platform.isLinux) {
      final isFullscreen = await windowManager.isFullScreen();
      if (isFullscreen) {
        await FullscreenStateManager().exitFullscreen();
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  /// Handle back button press
  /// For non-host participants in Watch Together, shows leave session confirmation
  Future<void> _handleBackButton() async {
    if (_isHandlingBack) return;
    _isHandlingBack = true;
    try {
      // For non-host participants, show leave session confirmation
      if (_watchTogetherProvider != null && _watchTogetherProvider!.isInSession && !_watchTogetherProvider!.isHost) {
        final confirmed = await showConfirmDialog(
          context,
          title: 'Leave Session?',
          message: 'You will be removed from the session.',
          confirmText: 'Leave',
          isDestructive: true,
        );

        if (confirmed && mounted) {
          await _watchTogetherProvider!.leaveSession();
          if (mounted) {
            await _exitFullscreenIfNeeded();
            if (!mounted) return;
            _isExiting.value = true;
            Navigator.of(context).pop(true);
          }
        }
        return;
      }

      await _exitFullscreenIfNeeded();

      // Default behavior for hosts or non-session users
      if (!mounted) return;
      _isExiting.value = true;
      Navigator.of(context).pop(true);
    } finally {
      _isHandlingBack = false;
    }
  }

  @override
  void dispose() {
    // Unregister app lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    // Clean up companion remote playback callbacks
    _cleanupCompanionRemoteCallbacks();

    // Notify Watch Together guests that host is exiting the player
    // Use stored reference since context.read() may fail in dispose
    // Skip if replacing with another video (episode navigation)
    if (!_isReplacingWithVideo &&
        _watchTogetherProvider != null &&
        _watchTogetherProvider!.isHost &&
        _watchTogetherProvider!.isInSession) {
      _watchTogetherProvider!.notifyHostExitedPlayer();
    }

    // Detach from Watch Together session
    _detachFromWatchTogetherSession();

    // Dispose value notifiers
    _isBuffering.dispose();
    _hasFirstFrame.dispose();
    _isExiting.dispose();
    _controlsVisible.dispose();

    // Stop progress tracking and send final state.
    // Fire-and-forget: dispose() is synchronous so we can't await, but the
    // database write is app-level and will typically complete before teardown.
    _progressTracker?.sendProgress('stopped');
    _progressTracker?.stopTracking();
    _progressTracker?.dispose();
    _sendLiveTimeline('stopped');
    _stopLiveTimelineUpdates();

    // Remove PiP state listener, clear callbacks, disable auto-PiP, and dispose video filter manager
    _videoPIPManager?.isPipActive.removeListener(_onPipStateChanged);
    _videoPIPManager?.onBeforeEnterPip = null;
    _videoPIPManager?.disableAutoPip();
    PipService.onAutoPipEntering = null;
    _videoFilterManager?.dispose();

    // Release cached BIF thumbnail data
    _bifService?.dispose();

    // Mark sleep timer for restart if truly exiting (not episode transition)
    if (!_isReplacingWithVideo) {
      SleepTimerService().markNeedsRestart();
    }

    // Cancel stream subscriptions
    _playingSubscription?.cancel();
    _completedSubscription?.cancel();
    _errorSubscription?.cancel();
    _mediaControlSubscription?.cancel();
    _bufferingSubscription?.cancel();
    _trackManager?.dispose();
    _positionSubscription?.cancel();
    _playbackRestartSubscription?.cancel();
    _backendSwitchedSubscription?.cancel();
    _logSubscription?.cancel();
    _sleepTimerSubscription?.cancel();
    _mediaControlsPlayingSubscription?.cancel();
    _mediaControlsPositionSubscription?.cancel();
    _mediaControlsRateSubscription?.cancel();
    _mediaControlsSeekableSubscription?.cancel();
    _serverStatusSubscription?.cancel();

    // Cancel auto-play timer
    _autoPlayTimer?.cancel();

    // Cancel still watching timer
    _stillWatchingTimer?.cancel();

    // Dispose Play Next dialog focus nodes
    _playNextCancelFocusNode.dispose();
    _playNextConfirmFocusNode.dispose();

    // Dispose "Still watching?" dialog focus nodes
    _stillWatchingPauseFocusNode.dispose();
    _stillWatchingContinueFocusNode.dispose();

    // Dispose screen-level focus node
    _screenFocusNode.removeListener(_onScreenFocusChanged);
    _screenFocusNode.dispose();

    // Clear media controls and dispose manager
    _mediaControlsManager?.clear();
    _mediaControlsManager?.dispose();

    // Clear Discord Rich Presence
    DiscordRPCService.instance.stopPlayback();

    // Clean up Windows display mode service
    if (Platform.isWindows && _displayModeService != null) {
      FullscreenStateManager().removeListener(_onFullscreenChanged);
    }
    if (Platform.isWindows && _displayModeService != null && _displayModeService!.anyChangeApplied) {
      if (_displayModeService!.hdrStateChanged && player != null) {
        player!.setProperty('target-colorspace-hint', 'no');
      }
      _displayModeService!.restoreAll();
    }

    // Clear frame rate matching and abandon audio focus before disposing player (Android only)
    if (Platform.isAndroid && player != null) {
      player!.clearVideoFrameRate();
      player!.abandonAudioFocus();
    }

    // Disable wakelock when leaving the video player
    _setWakelock(false);
    appLogger.d('Wakelock disabled');

    // Restore system UI and orientation preferences (skip if navigating to another video)
    if (!_isReplacingWithVideo) {
      OrientationHelper.restoreSystemUI();

      // Restore orientation based on cached device type (no context needed)
      try {
        if (_isPhone) {
          // Phone: portrait only
          SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
        } else {
          // Tablet/Desktop: all orientations
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
        }
      } catch (e) {
        appLogger.w('Failed to restore orientation in dispose', error: e);
      }
    }

    Sentry.addBreadcrumb(Breadcrumb(message: 'Player dispose', category: 'player'));
    player?.dispose();
    if (_activeRatingKey == widget.metadata.ratingKey) {
      _activeRatingKey = null;
      _activeMediaIndex = null;
    }
    super.dispose();
  }

  /// When focus leaves the entire video player subtree, reclaim it.
  /// `_screenFocusNode.hasFocus` is true when the node itself OR any
  /// descendant has focus, so internal movement between child controls
  /// does NOT trigger this.
  void _onScreenFocusChanged() {
    if (_reclaimingFocus) return;
    if (!_screenFocusNode.hasFocus && mounted && !_isExiting.value) {
      _reclaimingFocus = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _reclaimingFocus = false;
        if (mounted && !_isExiting.value && !_screenFocusNode.hasFocus) {
          _screenFocusNode.requestFocus();
        }
      });
    }
  }

  void _onPlayingStateChanged(bool isPlaying) {
    _setWakelock(isPlaying);

    if (isPlaying) {
      // Force a texture refresh on resume to unstick stale frames
      // (Linux/macOS texture registrars can miss frame-available
      // notifications after extended pause periods)
      player?.updateFrame();
    }

    // Send timeline update when playback state changes
    _progressTracker?.sendProgress(isPlaying ? 'playing' : 'paused');

    // Update OS media controls playback state
    _updateMediaControlsPlaybackState();

    // Update Discord Rich Presence
    if (isPlaying) {
      DiscordRPCService.instance.resumePlayback();
    } else {
      DiscordRPCService.instance.pausePlayback();
    }

    // Update auto-PiP readiness
    if (_autoPipEnabled) {
      _videoPIPManager?.updateAutoPipState(isPlaying: isPlaying);
    }
  }

  void _onVideoCompleted(bool completed) async {
    // Live TV streams are continuous — ignore spurious EOF events caused by
    // inter-segment gaps in the chunked MKV transcode stream.
    if (widget.isLive) return;

    if (completed &&
        _nextEpisode != null &&
        !_showPlayNextDialog &&
        !_showStillWatchingPrompt &&
        !_completionTriggered) {
      _completionTriggered = true;

      // Capture keyboard mode before async gap
      final isKeyboardMode = PlatformDetector.isTV() && InputModeTracker.isKeyboardMode(context);

      final settings = await SettingsService.getInstance();
      final autoPlayEnabled = settings.getAutoPlayNextEpisode();

      if (!mounted) return;
      setState(() {
        _showPlayNextDialog = true;
        _autoPlayCountdown = autoPlayEnabled ? 5 : -1;
      });

      // Auto-focus Play Next button on TV when dialog appears (only in keyboard/TV mode)
      if (isKeyboardMode) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _playNextConfirmFocusNode.requestFocus();
          }
        });
      }

      if (autoPlayEnabled) {
        _startAutoPlayTimer();
      }
    } else if (completed && _nextEpisode == null && !_completionTriggered) {
      _completionTriggered = true;
      _handleBackButton();
    }
  }

  void _onPlayerError(String error) {
    appLogger.e('[Player ERROR] $error');
    if (!mounted || _isExiting.value) return;
    showGlobalErrorSnackBar(_lastLogError ?? error);
    _handleBackButton();
  }

  String? _lastLogError;

  void _onPlayerLogError(PlayerLog log) {
    appLogger.e('[Player LOG ERROR] [${log.prefix}] ${log.text}');
    _lastLogError = log.text.trim();
  }

  /// Handle notification when native player switched from ExoPlayer to MPV
  Future<void> _onBackendSwitched() async {
    if (mounted) {
      showAppSnackBar(context, t.messages.switchingToCompatiblePlayer);
    }

    await _trackManager?.onBackendSwitched();
  }

  // OS Media Controls Integration

  Future<void> _syncMediaControlsAvailability() async {
    final manager = _mediaControlsManager;
    final currentPlayer = player;
    if (!mounted || manager == null || currentPlayer == null) return;

    final playbackState = context.read<PlaybackStateProvider>();
    final canNavigateEpisodes = widget.metadata.isEpisode || playbackState.isPlaylistActive;
    final canSeek = !widget.isLive && currentPlayer.state.seekable;

    if (!mounted || currentPlayer != player || manager != _mediaControlsManager) return;

    await manager.setControlsEnabled(
      canGoNext: canNavigateEpisodes,
      canGoPrevious: canNavigateEpisodes,
      canSeek: canSeek,
    );
  }

  Future<void> _seekBackForRewind(Player p) async {
    if (_rewindOnResume <= 0) return;
    final target = p.state.position - Duration(seconds: _rewindOnResume);
    await p.seek(clampSeekPosition(p, target));
  }

  Future<void> _restoreMediaControlsAfterResume() async {
    if (!_isPlayerInitialized || !mounted) return;

    _setWakelock(true);

    final manager = _mediaControlsManager;
    final currentPlayer = player;
    if (manager != null && currentPlayer != null) {
      final client = widget.isOffline ? null : _getClientForMetadata(context);
      await manager.updateMetadata(
        metadata: widget.metadata,
        client: client,
        duration: widget.metadata.duration != null ? Duration(milliseconds: widget.metadata.duration!) : null,
      );
      await _syncMediaControlsAvailability();
    }

    if (!mounted || currentPlayer != player || currentPlayer == null) return;

    if (_wasPlayingBeforeInactive) {
      try {
        await _seekBackForRewind(currentPlayer);
        await currentPlayer.play();
        appLogger.d('Video resumed after returning from inactive state');
      } catch (e) {
        appLogger.w('Failed to resume playback after returning from inactive state', error: e);
      } finally {
        _wasPlayingBeforeInactive = false;
      }
    }

    _updateMediaControlsPlaybackState();
    appLogger.d('Media controls restored and wakelock re-enabled on app resume');
  }

  /// Wrapper method to update media controls playback state
  void _updateMediaControlsPlaybackState() {
    if (player == null) return;

    _mediaControlsManager?.updatePlaybackState(
      isPlaying: player!.state.playing,
      position: player!.state.position,
      speed: player!.state.rate,
      force: true, // Force update since this is an explicit state change
    );
  }

  Future<void> _playNext() async {
    if (_nextEpisode == null || _isLoadingNext) return;

    // Cancel auto-play timer if running
    _autoPlayTimer?.cancel();
    _dismissStillWatching();

    // Notify Watch Together of episode change before navigating
    _notifyWatchTogetherMediaChange(metadata: _nextEpisode);

    setState(() {
      _isLoadingNext = true;
      _showPlayNextDialog = false;
    });

    await _navigateToEpisode(_nextEpisode!);
  }

  Future<void> _playPrevious() async {
    if (_previousEpisode == null) return;

    // Notify Watch Together of episode change before navigating
    _notifyWatchTogetherMediaChange(metadata: _previousEpisode);

    await _navigateToEpisode(_previousEpisode!);
  }

  /// Navigate to a specific queue item (called from QueueSheet)
  Future<void> navigateToQueueItem(PlexMetadata metadata) async {
    _notifyWatchTogetherMediaChange(metadata: metadata);
    await _navigateToEpisode(metadata);
  }

  bool _isSwitchingChannel = false;

  /// Switch to an adjacent live TV channel (delta: +1 for next, -1 for previous)
  /// Start periodic timeline heartbeats for live TV transcode session.
  void _startLiveTimelineUpdates() {
    _liveTimelineTimer?.cancel();
    _liveTimelineTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final state = player?.state.playing == true ? 'playing' : 'paused';
      _sendLiveTimeline(state);
    });
    // Delay initial heartbeat to let the transcode session stabilize.
    // Sending time=0 immediately after player.open() causes the server
    // to spawn a duplicate transcode job with offset=-1 that 404s.
    Future.delayed(const Duration(seconds: 3), () {
      if (_liveTimelineTimer != null) {
        final state = player?.state.playing == true ? 'playing' : 'paused';
        _sendLiveTimeline(state);
      }
    });
  }

  void _stopLiveTimelineUpdates() {
    _liveTimelineTimer?.cancel();
    _liveTimelineTimer = null;
  }

  Future<void> _sendLiveTimeline(String state) async {
    final sessionId = _liveSessionIdentifier;
    final sessionPath = _liveSessionPath;
    if (sessionId == null || sessionPath == null) return;

    final client = widget.liveClient;
    if (client == null) return;

    try {
      // Use the program ratingKey from tune metadata, not the channel key
      final ratingKey = _liveRatingKey ?? widget.metadata.ratingKey;

      // playbackTime: wall-clock ms since playback started
      final playbackTime = _livePlaybackStartTime != null
          ? DateTime.now().difference(_livePlaybackStartTime!).inMilliseconds
          : 0;

      // For live TV, player position/duration are unreliable (often 0).
      // Use playbackTime as time, and program duration from tune metadata.
      final time = playbackTime;
      final duration = _liveDurationMs ?? 0;

      final updatedBuffer = await client.updateLiveTimeline(
        ratingKey: ratingKey,
        sessionPath: sessionPath,
        sessionIdentifier: sessionId,
        state: state,
        time: time,
        duration: duration,
        playbackTime: playbackTime,
      );
      if (updatedBuffer != null && mounted) {
        setState(() {
          _captureBuffer = updatedBuffer;
          _isAtLiveEdge = (_currentPositionEpoch >= updatedBuffer.seekableEndEpoch - _liveEdgeThresholdSeconds);
        });
      }
    } catch (e) {
      appLogger.d('Live timeline update failed', error: e);
    }
  }

  /// Force mpv to reconnect its HTTP stream by seeking to the current position.
  /// This bypasses ffmpeg's exponential reconnect backoff when the app detects
  /// that network connectivity has been restored.
  void _forceStreamReconnect() {
    final p = player;
    if (p == null || !_isPlayerInitialized) return;
    final pos = p.state.position;
    appLogger.i('Network restored while buffering, forcing stream reconnect at ${pos.inSeconds}s');
    p.seek(pos);
  }

  /// Configure MPV/FFmpeg options for live streaming resilience.
  /// Enables automatic reconnection on EOF and network errors.
  Future<void> _setLiveStreamOptions() async {
    final p = player!;
    // FFmpeg HTTP protocol reconnection
    await p.setProperty(
      'stream-lavf-o',
      'reconnect=1,reconnect_streamed=1,reconnect_on_network_error=1,reconnect_delay_max=30',
    );
    // Demuxer: retry up to 1000 times on stream reload failures
    await p.setProperty('demuxer-lavf-o', 'max_reload=1000');
    await p.setProperty('force-seekable', 'no');
  }

  /// The current playback position as an absolute epoch second (for live TV time-shift).
  int get _currentPositionEpoch =>
      (_streamStartEpoch + (player?.state.position.inSeconds ?? 0)).round();

  /// Show "Watch from Start" / "Watch Live" dialog.
  /// Returns true if user chose "Watch from start", false for "Watch Live", null if dismissed.
  Future<bool?> _showWatchFromStartDialog(int effectiveStartEpoch, int nowEpoch) {
    final minutesAgo = ((nowEpoch - effectiveStartEpoch) / 60).round();
    return showOptionPickerDialog<bool>(
      context,
      title: t.liveTv.joinSession,
      options: [
        (icon: Symbols.replay_rounded, label: t.liveTv.watchFromStart(minutes: minutesAgo), value: true),
        (icon: Symbols.live_tv_rounded, label: t.liveTv.watchLive, value: false),
      ],
    );
  }

  /// Seek the live TV stream to an absolute epoch second.
  /// Creates a new transcode session at the target offset.
  Future<void> _seekLivePosition(int targetEpochSeconds) async {
    if (_captureBuffer == null || _liveSessionPath == null || _liveSessionIdentifier == null || _transcodeSessionId == null) return;

    final clamped = targetEpochSeconds.clamp(
      _captureBuffer!.seekableStartEpoch,
      _captureBuffer!.seekableEndEpoch,
    );

    final offsetSeconds = clamped - _captureBuffer!.startedAt.round();

    final client = widget.liveClient;
    if (client == null) return;

    final streamPath = await client.buildLiveStreamPath(
      sessionPath: _liveSessionPath!,
      sessionIdentifier: _liveSessionIdentifier!,
      transcodeSessionId: _transcodeSessionId!,
      offsetSeconds: offsetSeconds,
    );
    if (streamPath == null || !mounted) return;

    final streamUrl = '${client.config.baseUrl}$streamPath'.withPlexToken(client.config.token);

    _streamStartEpoch = _captureBuffer!.startedAt + offsetSeconds;
    _isAtLiveEdge = (clamped >= _captureBuffer!.seekableEndEpoch - _liveEdgeThresholdSeconds);
    _livePlaybackStartTime = DateTime.now();

    await _setLiveStreamOptions();
    await player!.open(
      Media(streamUrl, headers: const {'Accept-Language': 'en'}),
      play: true,
      isLive: true,
    );
    if (mounted) setState(() {});
  }

  /// Jump to the live edge of the capture buffer.
  Future<void> _jumpToLiveEdge() async {
    if (_captureBuffer == null) return;
    await _seekLivePosition(_captureBuffer!.seekableEndEpoch);
  }

  Future<void> _switchLiveChannel(int delta) async {
    final channels = widget.liveChannels;
    if (channels == null || channels.isEmpty) return;
    if (_isSwitchingChannel) return; // debounce concurrent switches

    final newIndex = _liveChannelIndex + delta;
    if (newIndex < 0 || newIndex >= channels.length) return;

    _isSwitchingChannel = true;

    // Stop old session heartbeats and notify server
    _stopLiveTimelineUpdates();
    await _sendLiveTimeline('stopped');

    final channel = channels[newIndex];
    appLogger.d('Switching to channel: ${channel.displayName} (${channel.key})');

    if (!mounted) return;
    setState(() => _hasFirstFrame.value = false);

    try {
      // Look up the correct client/DVR for this channel's server
      final multiServer = context.read<MultiServerProvider>();
      final serverInfo =
          multiServer.liveTvServers.where((s) => s.serverId == channel.serverId).firstOrNull ??
          multiServer.liveTvServers.firstOrNull;

      if (serverInfo == null) return;

      final client = multiServer.getClientForServer(serverInfo.serverId);
      if (client == null) return;

      final tuneResult = await client.tuneChannel(serverInfo.dvrKey, channel.key);
      if (tuneResult == null || !mounted) return;

      _transcodeSessionId = PlexClient.generateSessionIdentifier();

      final streamPath = await client.buildLiveStreamPath(
        sessionPath: tuneResult.sessionPath,
        sessionIdentifier: tuneResult.sessionIdentifier,
        transcodeSessionId: _transcodeSessionId!,
      );
      if (streamPath == null || !mounted) return;

      final streamUrl = '${client.config.baseUrl}$streamPath'.withPlexToken(client.config.token);

      await _setLiveStreamOptions();
      await player!.open(Media(streamUrl, headers: const {'Accept-Language': 'en'}), play: true, isLive: true);

      _livePlaybackStartTime = DateTime.now();
      _liveRatingKey = tuneResult.metadata.ratingKey;
      _liveDurationMs = tuneResult.metadata.duration;

      // Reset time-shift state for new channel
      _captureBuffer = tuneResult.captureBuffer;
      _programBeginsAt = tuneResult.beginsAt;
      _streamStartEpoch = DateTime.now().millisecondsSinceEpoch / 1000.0;
      _isAtLiveEdge = true;

      if (!mounted) return;
      setState(() {
        _liveChannelIndex = newIndex;
        _liveChannelName = channel.displayName;
        _liveSessionIdentifier = tuneResult.sessionIdentifier;
        _liveSessionPath = tuneResult.sessionPath;
      });

      // Restart timeline heartbeats for the new session
      _startLiveTimelineUpdates();
    } catch (e) {
      appLogger.e('Failed to switch channel', error: e);
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      _isSwitchingChannel = false;
    }
  }

  bool get _hasNextChannel =>
      widget.isLive &&
      widget.liveChannels != null &&
      _liveChannelIndex >= 0 &&
      _liveChannelIndex < (widget.liveChannels!.length - 1);

  bool get _hasPreviousChannel => widget.isLive && widget.liveChannels != null && _liveChannelIndex > 0;

  void _startAutoPlayTimer() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _autoPlayCountdown--;
      });
      if (_autoPlayCountdown <= 0) {
        timer.cancel();
        _playNext();
      }
    });
  }

  void _cancelAutoPlay() {
    _autoPlayTimer?.cancel();
    _completionTriggered = false; // Reset so it can trigger again if user seeks near end
    setState(() {
      _showPlayNextDialog = false;
    });
  }

  // -- "Still watching?" prompt --

  void _showStillWatchingDialog() {
    // Don't show if auto-play dialog is already visible
    if (_showPlayNextDialog) return;

    final isKeyboardMode = PlatformDetector.isTV() && InputModeTracker.isKeyboardMode(context);

    setState(() {
      _showStillWatchingPrompt = true;
      _stillWatchingCountdown = 30;
    });

    if (isKeyboardMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _stillWatchingContinueFocusNode.requestFocus();
      });
    }

    _stillWatchingTimer?.cancel();
    _stillWatchingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _stillWatchingCountdown--;
      });
      if (_stillWatchingCountdown <= 0) {
        timer.cancel();
        _onStillWatchingTimeout();
      }
    });
  }

  void _onStillWatchingTimeout() {
    player?.pause();
    setState(() {
      _showStillWatchingPrompt = false;
    });
  }

  void _onStillWatchingContinue() {
    _stillWatchingTimer?.cancel();
    SleepTimerService().restartTimer();
    setState(() {
      _showStillWatchingPrompt = false;
    });
  }

  void _onStillWatchingPause() {
    _stillWatchingTimer?.cancel();
    player?.pause();
    setState(() {
      _showStillWatchingPrompt = false;
    });
  }

  void _dismissStillWatching() {
    _stillWatchingTimer?.cancel();
    if (_showStillWatchingPrompt) {
      setState(() {
        _showStillWatchingPrompt = false;
      });
    }
  }

  /// Wait briefly for profile settings to load in offline mode.
  /// This prevents default-track fallback when playback starts before
  /// UserProfileProvider finishes initialization.
  Future<void> _waitForProfileSettingsIfNeeded() async {
    if (!widget.isOffline || !mounted) return;

    final provider = context.read<UserProfileProvider>();
    if (provider.profileSettings != null) return;

    final completer = Completer<void>();
    late VoidCallback listener;
    listener = () {
      if (provider.profileSettings != null && !completer.isCompleted) {
        completer.complete();
      }
    };

    provider.addListener(listener);
    try {
      await Future.any<void>([completer.future, Future.delayed(const Duration(seconds: 2))]);
    } finally {
      provider.removeListener(listener);
    }
  }

  Future<void> _onAudioTrackChanged(AudioTrack track) async => _trackManager?.onAudioTrackChanged(track);

  Future<void> _onSubtitleTrackChanged(SubtitleTrack track) async => _trackManager?.onSubtitleTrackChanged(track);

  void _onSecondarySubtitleTrackChanged(SubtitleTrack track) => _trackManager?.onSecondarySubtitleTrackChanged(track);

  /// Set flag to skip orientation restoration when replacing with another video
  void setReplacingWithVideo() {
    _isReplacingWithVideo = true;
  }

  /// Navigates to a new episode, preserving playback state and track selections
  Future<void> _navigateToEpisode(PlexMetadata episodeMetadata) async {
    // Set flag to skip orientation restoration in dispose()
    _isReplacingWithVideo = true;

    // Clear Discord Rich Presence before switching episodes
    DiscordRPCService.instance.stopPlayback();

    // If player isn't available, navigate without preserving settings
    if (player == null) {
      if (mounted) {
        navigateToVideoPlayer(
          context,
          metadata: episodeMetadata,
          usePushReplacement: true,
          isOffline: widget.isOffline,
        );
      }
      return;
    }

    // Capture current state atomically to avoid race conditions
    final currentPlayer = player;
    if (currentPlayer == null) {
      // Player already disposed, navigate without preserving settings
      if (mounted) {
        navigateToVideoPlayer(
          context,
          metadata: episodeMetadata,
          usePushReplacement: true,
          isOffline: widget.isOffline,
        );
      }
      return;
    }

    final currentAudioTrack = currentPlayer.state.track.audio;
    final currentSubtitleTrack = currentPlayer.state.track.subtitle;
    final currentSecondarySubtitleTrack = currentPlayer.state.track.secondarySubtitle;

    // Pause and stop current playback
    currentPlayer.pause();
    await _progressTracker?.sendProgress('stopped');
    _progressTracker?.stopTracking();

    // Ensure the native player is fully disposed before creating the next one
    await disposePlayerForNavigation();

    // Navigate to the episode using pushReplacement to destroy current player
    if (mounted) {
      navigateToVideoPlayer(
        context,
        metadata: episodeMetadata,
        preferredAudioTrack: currentAudioTrack,
        preferredSubtitleTrack: currentSubtitleTrack,
        preferredSecondarySubtitleTrack: currentSecondarySubtitleTrack,
        usePushReplacement: true,
        isOffline: widget.isOffline,
      );
    }
  }

  /// Dispose the player before replacing the video to avoid race conditions
  Future<void> disposePlayerForNavigation() async {
    if (_isDisposingForNavigation) return;
    _isDisposingForNavigation = true;
    _isExiting.value = true; // Show black overlay during transition

    try {
      _detachFromWatchTogetherSession();
      await _progressTracker?.sendProgress('stopped');
      _progressTracker?.stopTracking();
      // Clear frame rate matching before disposing (Android only)
      await _clearFrameRateMatching();
      // Restore Windows display mode before disposing
      await _restoreWindowsDisplayMode();
      await player?.dispose();
    } catch (e) {
      appLogger.d('Error disposing player before navigation', error: e);
    } finally {
      player = null;
      _isPlayerInitialized = false;
    }
  }

  Widget _buildLoadingSpinner() {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;
    // Screen-level Focus wraps ALL phases (loading + initialized).
    // - autofocus: grabs focus when no deeper child claims it.
    // - onKeyEvent: self-heals when this node has primary focus (no descendant
    //   focused). Nav keys are only consumed in that case; otherwise they pass
    //   through so DirectionalFocusAction can drive dpad nav in overlay sheets.
    return Focus(
      focusNode: _screenFocusNode,
      autofocus: isCurrentRoute,
      canRequestFocus: isCurrentRoute,
      onKeyEvent: (node, event) {
        if (!isCurrentRoute) return KeyEventResult.ignored;
        // On Windows/Linux with navigation off, consume ESC so Flutter's
        // DismissAction doesn't trigger a route pop. The video controls'
        // global key handler manages fullscreen/controls toggle instead.
        if (!_videoPlayerNavigationEnabled && (Platform.isWindows || Platform.isLinux) && event.logicalKey.isBackKey) {
          return KeyEventResult.handled;
        }
        // Back keys pass through — handled by PopScope (system back
        // gesture) or overlay sheet's onKeyEvent.
        if (event.logicalKey.isBackKey) return KeyEventResult.ignored;
        // Self-heal: if this node itself has primary focus (no descendant
        // focused, e.g. after controls auto-hide), redirect to first descendant.
        if (node.hasPrimaryFocus) {
          if (event.isActionable) {
            _controlsVisible.value = true;
            final descendants = node.traversalDescendants;
            if (descendants.isNotEmpty) {
              descendants.first.requestFocus();
            }
          }
          return event.logicalKey.isNavigationKey ? KeyEventResult.handled : KeyEventResult.ignored;
        }
        // A descendant has focus — let events pass through so
        // DirectionalFocusAction / ActivateAction can process them.
        return KeyEventResult.ignored;
      },
      child: OverlaySheetHost(
        child: Builder(
          builder: (sheetContext) =>
              _isPlayerInitialized && player != null ? _buildVideoPlayer(sheetContext) : _buildLoadingSpinner(),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(BuildContext context) {
    // Cache platform detection to avoid multiple calls
    final isMobile = PlatformDetector.isMobile(context);

    return PopScope(
      canPop: false, // Disable swipe-back gesture to prevent interference with timeline scrubbing
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // If an overlay sheet is open, delegate back to it instead of
          // exiting the player. This prevents the double-pop on Android TV
          // where the system back gesture would otherwise reach both the
          // sheet and the player's PopScope.
          final sheetController = OverlaySheetController.maybeOf(context);
          if (sheetController != null && sheetController.isOpen) {
            sheetController.pop();
            return;
          }
          if (BackKeyCoordinator.consumeIfHandled()) return;
          BackKeyCoordinator.markHandled();
          _handleBackButton();
        }
      },
      child: Scaffold(
        // Use transparent background on macOS when native video layer is active
        backgroundColor: Colors.transparent,
        body: GestureDetector(
          behavior: HitTestBehavior.translucent, // Allow taps to pass through to controls
          onScaleStart: (details) {
            // Initialize pinch gesture tracking (mobile only)
            if (!isMobile) return;
            if (_videoFilterManager != null) {
              _videoFilterManager!.isPinching = false;
            }
          },
          onScaleUpdate: (details) {
            // Track if this is a pinch gesture (2+ fingers) on mobile
            if (!isMobile) return;
            if (details.pointerCount >= 2 && _videoFilterManager != null) {
              _videoFilterManager!.isPinching = true;
            }
          },
          onScaleEnd: (details) {
            // Only toggle if we detected a pinch gesture on mobile
            if (!isMobile) return;
            if (_videoFilterManager != null && _videoFilterManager!.isPinching) {
              _toggleContainCover();
              _videoFilterManager!.isPinching = false;
            }
          },
          child: Stack(
            children: [
              // macOS PiP placeholder — video is in PiP window, show background with icon
              // Placed before Video so controls render on top
              if (Platform.isMacOS)
                ValueListenableBuilder<bool>(
                  valueListenable: PipService().isPipActive,
                  builder: (context, isInPip, child) {
                    if (!isInPip) return const SizedBox.shrink();
                    return Positioned.fill(
                      child: Container(
                        color: Colors.black,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Symbols.picture_in_picture_alt_rounded,
                                size: 48,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                t.videoControls.pipActive,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              // Video player
              Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Update player size when layout changes
                    final newSize = Size(constraints.maxWidth, constraints.maxHeight);

                    // Update player size in video filter manager, PiP manager, and native layer
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && player != null) {
                        _videoFilterManager?.updatePlayerSize(newSize);
                        _videoPIPManager?.updatePlayerSize(newSize);
                        // Update ambient lighting shader if active (output aspect changed)
                        _updateAmbientLightingOnResize(newSize);
                        // Update Metal layer frame on iOS/macOS for rotation
                        player!.updateFrame();
                      }
                    });

                    // Compute canControl from Watch Together provider (reactive)
                    bool canControl = true;
                    try {
                      canControl = context.select<WatchTogetherProvider, bool>(
                        (wt) => wt.isInSession ? wt.canControl() : true,
                      );
                    } catch (e) {
                      // Watch Together not available, default to can control
                    }

                    VoidCallback? onNext;
                    if (widget.isLive) {
                      onNext = _hasNextChannel ? () => _switchLiveChannel(1) : null;
                    } else {
                      onNext = (_nextEpisode != null && _canNavigateEpisodes()) ? _playNext : null;
                    }

                    VoidCallback? onPrevious;
                    if (widget.isLive) {
                      onPrevious = _hasPreviousChannel ? () => _switchLiveChannel(-1) : null;
                    } else {
                      onPrevious = (_previousEpisode != null && _canNavigateEpisodes()) ? _playPrevious : null;
                    }

                    return Video(
                      player: player!,
                      controls: (context) => plexVideoControlsBuilder(
                        player!,
                        widget.metadata,
                        onNext: onNext,
                        onPrevious: onPrevious,
                        availableVersions: _availableVersions,
                        selectedMediaIndex: widget.selectedMediaIndex,
                        onTogglePIPMode: _togglePIPMode,
                        boxFitMode: _videoFilterManager?.boxFitMode ?? 0,
                        onCycleBoxFitMode: _cycleBoxFitMode,
                        onCycleAudioTrack: _cycleAudioTrack,
                        onCycleSubtitleTrack: _cycleSubtitleTrack,
                        onAudioTrackChanged: _onAudioTrackChanged,
                        onSubtitleTrackChanged: _onSubtitleTrackChanged,
                        onSecondarySubtitleTrackChanged: _onSecondarySubtitleTrackChanged,
                        onSeekCompleted: (position) {
                          // Notify Watch Together of seek for sync
                          // Note: canControl() check is done in sync manager, not here
                          // This matches play/pause behavior and avoids timing issues
                          try {
                            final watchTogether = this.context.read<WatchTogetherProvider>();
                            if (watchTogether.isInSession) {
                              watchTogether.onLocalSeek(position);
                            }
                          } catch (e) {
                            // Watch Together not available, ignore
                          }
                        },
                        onBack: _handleBackButton,
                        canControl: canControl,
                        hasFirstFrame: _hasFirstFrame,
                        playNextFocusNode: _showPlayNextDialog ? _playNextConfirmFocusNode : null,
                        controlsVisible: _controlsVisible,
                        shaderService: _shaderService,
                        // ignore: no-empty-block - setState triggers rebuild to reflect shader change
                        onShaderChanged: () => setState(() {}),
                        thumbnailDataBuilder: _bifService?.isAvailable == true ? _getThumbnailData : null,
                        isLive: widget.isLive,
                        liveChannelName: _liveChannelName,
                        captureBuffer: _captureBuffer,
                        isAtLiveEdge: _isAtLiveEdge,
                        streamStartEpoch: _streamStartEpoch,
                        currentPositionEpoch: widget.isLive ? _currentPositionEpoch : null,
                        onLiveSeek: _captureBuffer != null ? _seekLivePosition : null,
                        onJumpToLive: _captureBuffer != null && !_isAtLiveEdge ? _jumpToLiveEdge : null,
                        isAmbientLightingEnabled: _ambientLightingService?.isEnabled ?? false,
                        onToggleAmbientLighting: _toggleAmbientLighting,
                      ),
                    );
                  },
                ),
              ),
              // Netflix-style auto-play overlay (hidden in PiP mode)
              ValueListenableBuilder<bool>(
                valueListenable: PipService().isPipActive,
                builder: (context, isInPip, child) {
                  if (isInPip || !_showPlayNextDialog || _nextEpisode == null) {
                    return const SizedBox.shrink();
                  }
                  return ValueListenableBuilder<bool>(
                    valueListenable: _controlsVisible,
                    builder: (context, controlsShown, child) {
                      return AnimatedPositioned(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        right: 24,
                        bottom: controlsShown ? 100 : 24,
                        child: Container(
                          width: 320,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.9),
                            borderRadius: const BorderRadius.all(Radius.circular(12)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Consumer<PlaybackStateProvider>(
                                          builder: (context, playbackState, child) {
                                            final isShuffleActive = playbackState.isShuffleActive;
                                            return Row(
                                              children: [
                                                Text(
                                                  'Next Episode',
                                                  style: TextStyle(
                                                    color: Colors.white.withValues(alpha: 0.7),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                if (isShuffleActive) ...[
                                                  const SizedBox(width: 4),
                                                  AppIcon(
                                                    Symbols.shuffle_rounded,
                                                    fill: 1,
                                                    size: 12,
                                                    color: Colors.white.withValues(alpha: 0.7),
                                                  ),
                                                ],
                                              ],
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 4),
                                        if (_nextEpisode!.parentIndex != null && _nextEpisode!.index != null)
                                          Text(
                                            'S${_nextEpisode!.parentIndex} E${_nextEpisode!.index} · ${_nextEpisode!.title}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          )
                                        else
                                          Text(
                                            _nextEpisode!.title!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: FocusableButton(
                                      focusNode: _playNextCancelFocusNode,
                                      onPressed: _cancelAutoPlay,
                                      autoScroll: false,
                                      onNavigateRight: () => _playNextConfirmFocusNode.requestFocus(),
                                      onNavigateUp: () {}, // Trap focus
                                      onNavigateDown: () {}, // Trap focus
                                      child: OutlinedButton(
                                        onPressed: _cancelAutoPlay,
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        child: Text(t.common.cancel),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FocusableButton(
                                      focusNode: _playNextConfirmFocusNode,
                                      onPressed: _playNext,
                                      autoScroll: false,
                                      onNavigateLeft: () => _playNextCancelFocusNode.requestFocus(),
                                      onNavigateUp: () {}, // Trap focus
                                      onNavigateDown: () {}, // Trap focus
                                      child: FilledButton(
                                        onPressed: _playNext,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            if (_autoPlayCountdown > 0) ...[
                                              Text('$_autoPlayCountdown'),
                                              const SizedBox(width: 4),
                                              const AppIcon(Symbols.play_arrow_rounded, fill: 1, size: 18),
                                            ] else
                                              Text(t.videoControls.playNext),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              // "Still watching?" overlay (hidden in PiP mode)
              ValueListenableBuilder<bool>(
                valueListenable: PipService().isPipActive,
                builder: (context, isInPip, child) {
                  if (isInPip || !_showStillWatchingPrompt) {
                    return const SizedBox.shrink();
                  }
                  return ValueListenableBuilder<bool>(
                    valueListenable: _controlsVisible,
                    builder: (context, controlsShown, child) {
                      return AnimatedPositioned(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        right: 24,
                        bottom: controlsShown ? 100 : 24,
                        child: Container(
                          width: 320,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.9),
                            borderRadius: const BorderRadius.all(Radius.circular(12)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t.videoControls.stillWatching,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t.videoControls.pausingIn(seconds: '$_stillWatchingCountdown'),
                                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: FocusableButton(
                                      focusNode: _stillWatchingPauseFocusNode,
                                      onPressed: _onStillWatchingPause,
                                      autoScroll: false,
                                      onNavigateRight: () => _stillWatchingContinueFocusNode.requestFocus(),
                                      onNavigateUp: () {},
                                      onNavigateDown: () {},
                                      child: OutlinedButton(
                                        onPressed: _onStillWatchingPause,
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        child: Text(t.videoControls.pauseButton),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FocusableButton(
                                      focusNode: _stillWatchingContinueFocusNode,
                                      onPressed: _onStillWatchingContinue,
                                      autoScroll: false,
                                      onNavigateLeft: () => _stillWatchingPauseFocusNode.requestFocus(),
                                      onNavigateUp: () {},
                                      onNavigateDown: () {},
                                      child: FilledButton(
                                        onPressed: _onStillWatchingContinue,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text('$_stillWatchingCountdown'),
                                            const SizedBox(width: 4),
                                            Text(t.videoControls.continueWatching),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              // Buffering indicator (also shows during initial load, but not when exiting)
              // Hidden in PiP mode
              ValueListenableBuilder<bool>(
                valueListenable: PipService().isPipActive,
                builder: (context, isInPip, child) {
                  if (isInPip) return const SizedBox.shrink();
                  return ValueListenableBuilder<bool>(
                    valueListenable: _isBuffering,
                    builder: (context, isBuffering, child) {
                      return ValueListenableBuilder<bool>(
                        valueListenable: _hasFirstFrame,
                        builder: (context, hasFrame, child) {
                          if ((!isBuffering && hasFrame) || _isExiting.value) return const SizedBox.shrink();
                          // Show spinner only - controls overlay provides its own black background during loading
                          return Positioned.fill(
                            child: IgnorePointer(
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
              // Watch Together overlays (isolated from video surface repaints)
              RepaintBoundary(
                child: Stack(
                  children: [
                    // Watch Together: reconnecting to host overlay
                    Selector<WatchTogetherProvider, bool>(
                      selector: (_, provider) => provider.isWaitingForHostReconnect,
                      builder: (context, isWaiting, child) {
                        if (!isWaiting) return const SizedBox.shrink();
                        return Positioned(
                          bottom: 120,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.all(Radius.circular(20)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (PlatformDetector.isTV())
                                    const Icon(Symbols.sync_rounded, size: 14, color: Colors.white)
                                  else
                                    const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    ),
                                  const SizedBox(width: 8),
                                  Text(
                                    t.watchTogether.reconnectingToHost,
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // Watch Together: participant join/leave notifications
                    const ParticipantNotificationOverlay(),
                  ],
                ),
              ),
              // Black overlay during exit (no spinner - just covers transparency)
              ValueListenableBuilder<bool>(
                valueListenable: _isExiting,
                builder: (context, isExiting, child) {
                  if (!isExiting) return const SizedBox.shrink();
                  return Positioned.fill(child: Container(color: Colors.black));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Returns the appropriate hwdec value based on platform and user preference.
String _getHwdecValue(bool enabled) {
  if (!enabled) return 'no';

  if (Platform.isMacOS || Platform.isIOS) {
    return 'videotoolbox';
  } else if (Platform.isAndroid) {
    return 'mediacodec,mediacodec-copy';
  } else {
    return 'auto'; // Windows, Linux
  }
}
