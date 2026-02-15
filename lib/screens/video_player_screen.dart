import 'dart:async';
import '../utils/platform_helper.dart';

import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/services.dart';
import 'package:os_media_controls/os_media_controls.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:window_manager/window_manager.dart';

import '../mpv/mpv.dart';
import '../mpv/player/player_android.dart';

import '../../services/plex_client.dart';
import '../services/plex_api_cache.dart';
import '../models/plex_media_version.dart';
import '../models/plex_metadata.dart';
import '../utils/content_utils.dart';
import '../models/plex_media_info.dart';
import '../providers/download_provider.dart';
import '../providers/multi_server_provider.dart';
import '../providers/playback_state_provider.dart';
import '../models/companion_remote/remote_command_type.dart';
import '../providers/companion_remote_provider.dart';
import '../services/companion_remote/companion_remote_receiver.dart';
import '../services/fullscreen_state_manager.dart';
import '../services/discord_rpc_service.dart';
import '../services/episode_navigation_service.dart';
import '../services/media_controls_manager.dart';
import '../services/playback_initialization_service.dart';
import '../services/playback_progress_tracker.dart';
import '../services/offline_watch_sync_service.dart';
import '../services/settings_service.dart';
import '../services/sleep_timer_service.dart';
import '../services/track_selection_service.dart';
import '../services/video_filter_manager.dart';
import '../services/video_pip_manager.dart';
import '../services/pip_service.dart';
import '../services/shader_service.dart';
import '../providers/shader_provider.dart';
import '../providers/user_profile_provider.dart';
import '../utils/app_logger.dart';
import '../utils/dialogs.dart';
import '../utils/player_utils.dart';
import '../utils/orientation_helper.dart';
import '../utils/platform_detector.dart';
import '../utils/provider_extensions.dart';
import '../utils/language_codes.dart';
import '../utils/snackbar_helper.dart';
import '../utils/track_label_builder.dart' as tlb;
import '../utils/plex_url_helper.dart';
import '../utils/video_player_navigation.dart';
import '../widgets/video_controls/video_controls.dart';
import '../focus/focusable_wrapper.dart';
import '../focus/input_mode_tracker.dart';
import '../focus/dpad_navigator.dart';
import '../focus/key_event_utils.dart';
import '../i18n/strings.g.dart';
import '../watch_together/providers/watch_together_provider.dart';
import '../watch_together/widgets/watch_together_overlay.dart';

class VideoPlayerScreen extends StatefulWidget {
  final PlexMetadata metadata;
  final AudioTrack? preferredAudioTrack;
  final SubtitleTrack? preferredSubtitleTrack;
  final int selectedMediaIndex;
  final bool isOffline;

  const VideoPlayerScreen({
    super.key,
    required this.metadata,
    this.preferredAudioTrack,
    this.preferredSubtitleTrack,
    this.selectedMediaIndex = 0,
    this.isOffline = false,
  });

  @override
  State<VideoPlayerScreen> createState() => VideoPlayerScreenState();
}

class VideoPlayerScreenState extends State<VideoPlayerScreen> with WidgetsBindingObserver {
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
  StreamSubscription<Tracks>? _trackLoadingSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<void>? _playbackRestartSubscription;
  StreamSubscription<void>? _backendSwitchedSubscription;
  StreamSubscription<void>? _sleepTimerSubscription;
  bool _isReplacingWithVideo = false; // Flag to skip orientation restoration during video-to-video navigation
  bool _isDisposingForNavigation = false;
  bool _waitingForExternalSubsTrackSelection = false;
  bool _isHandlingBack = false;
  bool _hasThumbnails = false;

  // Auto-play next episode
  Timer? _autoPlayTimer;
  int _autoPlayCountdown = 5;
  bool _completionTriggered = false;

  // Play Next dialog focus nodes (for TV D-pad navigation)
  late final FocusNode _playNextCancelFocusNode;
  late final FocusNode _playNextConfirmFocusNode;

  // Screen-level focus node: persists across loading/initialized phases so
  // key events never escape the video player route.
  late final FocusNode _screenFocusNode;

  // App lifecycle state tracking
  bool _wasPlayingBeforeInactive = false;

  // Services
  MediaControlsManager? _mediaControlsManager;
  PlaybackProgressTracker? _progressTracker;
  VideoFilterManager? _videoFilterManager;
  VideoPIPManager? _videoPIPManager;
  ShaderService? _shaderService;
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

  String? _buildThumbnailUrl(BuildContext context, Duration time) {
    final partId = _currentMediaInfo?.partId;
    if (partId == null || widget.isOffline) return null;
    final client = _getClientForMetadata(context);
    return '${client.config.baseUrl}/library/parts/$partId/indexes/sd/${time.inMilliseconds}'.withPlexToken(
      client.config.token,
    );
  }

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

    // Initialize Play Next dialog focus nodes
    _playNextCancelFocusNode = FocusNode(debugLabel: 'PlayNextCancel');
    _playNextConfirmFocusNode = FocusNode(debugLabel: 'PlayNextConfirm');

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

    // Exit the player when the sleep timer completes so the device can auto-lock
    _sleepTimerSubscription = SleepTimerService().onCompleted.listen((_) {
      if (mounted) _handleBackButton();
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
        // App is being hidden (user is switching away)
        // Pause video since we don't support background playback (mobile only)
        if (PlatformDetector.isMobile(context)) {
          if (player != null && _isPlayerInitialized) {
            _wasPlayingBeforeInactive = player!.state.playing;
            if (_wasPlayingBeforeInactive) {
              player!.pause();
              appLogger.d('Video paused due to app being hidden (mobile)');
            }
          }
        }
        break;
      case AppLifecycleState.paused:
        // Clear media controls when app truly goes to background
        // (we don't support background playback)
        OsMediaControls.clear();
        // Disable wakelock when app goes to background
        WakelockPlus.disable();
        appLogger.d('Media controls cleared and wakelock disabled due to app being paused/backgrounded');
        break;
      case AppLifecycleState.resumed:
        // Restore media controls and wakelock when app is resumed
        if (_isPlayerInitialized && mounted) {
          // Re-enable wakelock since we're back in the video player
          WakelockPlus.enable();

          // Restore media metadata (only in online mode - requires client for artwork URLs)
          if (!widget.isOffline && _mediaControlsManager != null) {
            final client = _getClientForMetadata(context);
            _mediaControlsManager!.updateMetadata(
              metadata: widget.metadata,
              client: client,
              duration: widget.metadata.duration != null ? Duration(milliseconds: widget.metadata.duration!) : null,
            );
          }

          // Resume playback if it was playing before going inactive
          if (_wasPlayingBeforeInactive && player != null) {
            player!.play();
            _wasPlayingBeforeInactive = false;
            appLogger.d('Video resumed after returning from inactive state');
          }

          _updateMediaControlsPlaybackState();
          appLogger.d('Media controls restored and wakelock re-enabled on app resume');
        }
        break;
      case AppLifecycleState.detached:
        // No action needed for this state
        break;
    }
  }

  /// Converts a 2-letter code like "fr", "nl", "ca" to a Plex 3-letter code, or returns null if unknown
  String? _iso6391ToPlex6392(String? code) {
    if (code == null || code.isEmpty) return null;
    // Takes the base "fr" from "fr-FR"
    final lang = code.split('-').first.toLowerCase();

    // Use LanguageCodes utility to get variations and find the 639-2 code
    try {
      final variations = LanguageCodes.getVariations(lang);
      // The getVariations method returns all variations including 639-2 codes
      // We need to find the 3-letter code from the variations
      for (final variation in variations) {
        if (variation.length == 3) {
          return variation;
        }
      }
      return null;
    } catch (e) {
      // If LanguageCodes is not initialized or fails, return null
      return null;
    }
  }

  Future<void> _initializePlayer() async {
    try {
      // Load buffer size from settings
      final settingsService = await SettingsService.getInstance();
      final bufferSizeMB = settingsService.getBufferSize();
      final bufferSizeBytes = bufferSizeMB * 1024 * 1024;
      final enableHardwareDecoding = settingsService.getEnableHardwareDecoding();
      final debugLoggingEnabled = settingsService.getEnableDebugLogging();
      final useExoPlayer = settingsService.getUseExoPlayer();

      // Create player (on Android, uses ExoPlayer by default, MPV as fallback)
      player = Player(useExoPlayer: useExoPlayer);

      await player!.setProperty('sub-ass', 'yes'); // Enable libass
      await player!.setProperty('demuxer-max-bytes', bufferSizeBytes.toString());
      await player!.setProperty('msg-level', debugLoggingEnabled ? 'all=debug' : 'all=error');
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
      await player!.setProperty('sub-pos', settingsService.getSubtitlePosition().toString());

      // Platform-specific settings
      if (AppPlatform.isIOS) {
        await player!.setProperty('audio-exclusive', 'yes');
      }

      // HDR is controlled via custom hdr-enabled property on iOS/macOS/Windows
      if (AppPlatform.isIOS || AppPlatform.isMacOS || AppPlatform.isWindows) {
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

        // Enable wakelock to prevent screen from turning off during playback
        WakelockPlus.enable();
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

      // Listen for backend switched event (ExoPlayer -> MPV fallback on Android)
      if (AppPlatform.isAndroid && useExoPlayer) {
        _backendSwitchedSubscription = player!.streams.backendSwitched.listen((_) => _onBackendSwitched());
      }

      // Listen to buffering state
      _bufferingSubscription = player!.streams.buffering.listen((isBuffering) {
        _isBuffering.value = isBuffering;
      });

      // Listen to playback restart to detect first frame ready
      _playbackRestartSubscription = player!.streams.playbackRestart.listen((_) async {
        if (!_hasFirstFrame.value) {
          _hasFirstFrame.value = true;

          // Apply frame rate matching on Android if enabled
          if (AppPlatform.isAndroid && settingsService.getMatchContentFrameRate()) {
            await _applyFrameRateMatching();
          }
        }
        if (_waitingForExternalSubsTrackSelection) {
          _waitingForExternalSubsTrackSelection = false;
          _applyTrackSelection();
        }
      });

      // Listen to position for completion detection (fallback for unreliable MPV events)
      _positionSubscription = player!.streams.position.listen((position) {
        final duration = player!.state.duration;
        if (duration.inMilliseconds > 0 &&
            position.inMilliseconds >= duration.inMilliseconds - 1000 &&
            !_showPlayNextDialog &&
            !_completionTriggered &&
            _nextEpisode != null) {
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

  /// Apply frame rate matching on Android by setting the display refresh rate
  /// to match the video content's frame rate.
  Future<void> _applyFrameRateMatching() async {
    if (player == null || !AppPlatform.isAndroid) return;

    try {
      final fpsStr = await player!.getProperty('container-fps');
      final fps = double.tryParse(fpsStr ?? '');
      if (fps == null || fps <= 0) {
        appLogger.d('Frame rate matching: No valid fps available ($fpsStr)');
        return;
      }

      final durationMs = player!.state.duration.inMilliseconds;
      await player!.setVideoFrameRate(fps, durationMs);

      // Set MPV video-sync mode for smoother playback when display is synced
      await player!.setProperty('video-sync', 'display-tempo');

      appLogger.d('Frame rate matching: Set display to ${fps}fps (duration: ${durationMs}ms)');
    } catch (e) {
      appLogger.w('Failed to apply frame rate matching', error: e);
    }
  }

  /// Clear frame rate matching and restore default display mode
  Future<void> _clearFrameRateMatching() async {
    if (player == null || !AppPlatform.isAndroid) return;

    try {
      await player!.clearVideoFrameRate();
      await player!.setProperty('video-sync', 'audio');
      appLogger.d('Frame rate matching: Cleared, restored default display mode');
    } catch (e) {
      appLogger.d('Failed to clear frame rate matching', error: e);
    }
  }

  /// Add external subtitle tracks to the player
  Future<void> _addExternalSubtitles(List<SubtitleTrack> externalSubtitles) async {
    if (player == null || externalSubtitles.isEmpty) return;

    appLogger.d('Adding ${externalSubtitles.length} external subtitle(s) to player');

    for (final subtitleTrack in externalSubtitles) {
      if (subtitleTrack.uri == null) continue;

      try {
        await player!.addSubtitleTrack(
          uri: subtitleTrack.uri!,
          title: subtitleTrack.title,
          language: subtitleTrack.language,
          select: false, // Don't auto-select
        );
        appLogger.d('Added external subtitle: ${subtitleTrack.title ?? subtitleTrack.uri}');
      } catch (e) {
        appLogger.w('Failed to add external subtitle: ${subtitleTrack.title ?? subtitleTrack.uri}', error: e);
      }
    }
  }

  /// Initialize the service layer
  Future<void> _initializeServices() async {
    if (!mounted || player == null) return;

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
      if (event is PlayEvent) {
        appLogger.d('Media control: Play event received');
        if (player != null) {
          player!.play();
          _wasPlayingBeforeInactive = false;
          appLogger.d('Cleared _wasPlayingBeforeInactive due to manual play via media controls');
          _updateMediaControlsPlaybackState();
        }
      } else if (event is PauseEvent) {
        appLogger.d('Media control: Pause event received');
        if (player != null) {
          player!.pause();
          appLogger.d('Video paused via media controls');
          _updateMediaControlsPlaybackState();
        }
      } else if (event is SeekEvent) {
        appLogger.d('Media control: Seek event received to ${event.position}');
        player?.seek(event.position);
      } else if (event is NextTrackEvent) {
        appLogger.d('Media control: Next track event received');
        if (_nextEpisode != null) {
          _playNext();
        }
      } else if (event is PreviousTrackEvent) {
        appLogger.d('Media control: Previous track event received');
        if (_previousEpisode != null) {
          _playPrevious();
        }
      }
    });

    // Update media metadata (client can be null in offline mode - artwork won't be shown)
    await _mediaControlsManager!.updateMetadata(
      metadata: widget.metadata,
      client: client,
      duration: widget.metadata.duration != null ? Duration(milliseconds: widget.metadata.duration!) : null,
    );

    if (!mounted) return;

    // Set controls enabled based on content type
    final playbackState = context.read<PlaybackStateProvider>();
    final isEpisode = widget.metadata.isEpisode;
    final isInPlaylist = playbackState.isPlaylistActive;

    await _mediaControlsManager!.setControlsEnabled(
      canGoNext: isEpisode || isInPlaylist,
      canGoPrevious: isEpisode || isInPlaylist,
    );

    // Listen to playing state and update media controls
    player!.streams.playing.listen((isPlaying) {
      _updateMediaControlsPlaybackState();
    });

    // Listen to position updates for media controls and Discord
    player!.streams.position.listen((position) {
      _mediaControlsManager?.updatePlaybackState(
        isPlaying: player!.state.playing,
        position: position,
        speed: player!.state.rate,
      );
      DiscordRPCService.instance.updatePosition(position);
    });

    // Listen to playback rate changes for Discord Rich Presence
    player!.streams.rate.listen((rate) {
      DiscordRPCService.instance.updatePlaybackSpeed(rate);
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
        await playbackState.setPlaybackFromPlayQueue(
          playQueue,
          showRatingKey,
          serverId: widget.metadata.serverId,
          serverName: widget.metadata.serverName,
        );

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
    if (!mounted) return;

    if (widget.isOffline) {
      // Offline mode: find next/previous from downloaded episodes
      _loadAdjacentEpisodesOffline();
      return;
    }

    try {
      // Use server-specific client for this metadata
      final client = _getClientForMetadata(context);

      // Load adjacent episodes using the service
      final adjacentEpisodes = await _episodeNavigation.loadAdjacentEpisodes(
        context: context,
        client: client,
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

      // Sort by season then episode number
      final sorted = List<PlexMetadata>.from(episodes)
        ..sort((a, b) {
          final seasonCmp = (a.parentIndex ?? 0).compareTo(b.parentIndex ?? 0);
          if (seasonCmp != 0) return seasonCmp;
          return (a.index ?? 0).compareTo(b.index ?? 0);
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
        );
      }

      // Open video through Player
      if (result.videoUrl != null) {
        // Reset first frame flag for new video
        _hasFirstFrame.value = false;

        // Request audio focus before starting playback (Android)
        // This causes other media apps (Spotify, podcasts, etc.) to pause
        await player!.requestAudioFocus();

        // Pass resume position if available.
        // In offline mode, prefer locally tracked progress over the cached server value
        // since the user may have watched further since downloading.
        Duration? resumePosition;
        if (widget.isOffline) {
          final globalKey = '${widget.metadata.serverId}:${widget.metadata.ratingKey}';
          final localOffset = await offlineWatchService!.getLocalViewOffset(globalKey);
          if (localOffset != null && localOffset > 0) {
            resumePosition = Duration(milliseconds: localOffset);
            appLogger.d('Resuming offline playback from local progress: ${localOffset}ms');
          }
        }
        resumePosition ??= widget.metadata.viewOffset != null
            ? Duration(milliseconds: widget.metadata.viewOffset!)
            : null;

        // If we have external subtitles, open paused to add them before playback starts.
        // This prevents a race condition on Android where adding subtitle tracks
        // during active playback can freeze the video decoder (issue #226).
        final hasExternalSubs = result.externalSubtitles.isNotEmpty;
        await player!.open(
          Media(result.videoUrl!, start: resumePosition, headers: plexHeaders),
          play: !hasExternalSubs,
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
          _hasThumbnails = false;
        });

        // Check whether any thumbnails exist by requesting the first one
        if (_currentMediaInfo?.partId != null && !widget.isOffline) {
          final partId = _currentMediaInfo!.partId!;
          final client = _getClientForMetadata(context);
          client.checkThumbnailsAvailable(partId).then((available) {
            // Guard against media having changed while the probe was in flight
            if (mounted && _currentMediaInfo?.partId == partId) {
              setState(() => _hasThumbnails = available);
            }
          });
        }

        // Initialize video PIP and filter manager with player and available versions
        if (player != null) {
          _videoFilterManager = VideoFilterManager(
            player: player!,
            availableVersions: _availableVersions,
            selectedMediaIndex: widget.selectedMediaIndex,
          );
          // Update video filter once dimensions are available
          _videoFilterManager!.updateVideoFilter();

          // PIP Manager
          _videoPIPManager = VideoPIPManager(player: player!);
          _videoPIPManager!.onBeforeEnterPip = () {
            _videoFilterManager?.enterPipMode();
          };
          _videoPIPManager!.isPipActive.addListener(_onPipStateChanged);

          // Shader Service (MPV only)
          _shaderService = ShaderService(player!);
          if (_shaderService!.isSupported) {
            await _applySavedShaderPreset();
          }
        }

        // Add external subtitles while paused, then start playback
        if (result.externalSubtitles.isNotEmpty) {
          _hasFirstFrame.value = false;
          _waitingForExternalSubsTrackSelection = true;

          try {
            await _addExternalSubtitles(result.externalSubtitles);
          } finally {
            if (player != null && mounted) {
              await player!.play();
              final pos = player!.state.position;
              try {
                await player!.seek(pos.inMilliseconds > 0 ? pos : Duration.zero);
              } catch (e) {
                appLogger.w('Non-critical seek after subtitle load failed', error: e);
              }

              // Fallback if playbackRestart doesn't fire
              Future.delayed(const Duration(seconds: 3), () {
                if (_waitingForExternalSubsTrackSelection && mounted) {
                  _waitingForExternalSubsTrackSelection = false;
                  _applyTrackSelection();
                }
              });
            }
          }
        } else {
          _trackLoadingSubscription?.cancel();
          _trackLoadingSubscription = player!.streams.tracks.listen((tracks) {
            if (tracks.audio.isEmpty && tracks.subtitle.isEmpty) return;

            _trackLoadingSubscription?.cancel();
            _trackLoadingSubscription = null;
            _applyTrackSelection();
          });
        }
      }
    } on PlaybackException catch (e) {
      if (mounted) {
        showErrorSnackBar(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
      }
    }
  }

  /// Start playback for offline/downloaded content
  Future<PlaybackInitializationResult> _startOfflinePlayback() async {
    final downloadProvider = context.read<DownloadProvider>();

    // Debug: log metadata info
    appLogger.d('Offline playback - serverId: ${widget.metadata.serverId}, ratingKey: ${widget.metadata.ratingKey}');

    final globalKey = '${widget.metadata.serverId}:${widget.metadata.ratingKey}';
    appLogger.d('Looking up video with globalKey: $globalKey');

    final videoPath = await downloadProvider.getVideoFilePath(globalKey);
    if (videoPath == null) {
      appLogger.e('Video file path not found for globalKey: $globalKey');
      throw PlaybackException(t.messages.fileInfoNotAvailable);
    }

    appLogger.d('Starting offline playback: $videoPath');

    return PlaybackInitializationResult(
      availableVersions: [],
      videoUrl: videoPath.contains('://') ? videoPath : 'file://$videoPath',
      mediaInfo: null,
      externalSubtitles: const [],
      isOffline: true,
    );
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
      _videoFilterManager!.exitPipMode();
    }
  }

  /// Apply the saved shader preset on playback start
  Future<void> _applySavedShaderPreset() async {
    if (_shaderService == null || !_shaderService!.isSupported) return;

    try {
      final shaderProvider = context.read<ShaderProvider>();
      final preset = shaderProvider.savedPreset;
      await _shaderService!.applyPreset(preset);
      shaderProvider.setCurrentPreset(preset);
    } catch (e) {
      appLogger.d('Could not apply shader preset', error: e);
    }
  }

  /// Cycle through BoxFit modes: contain → cover → fill → contain (for button)
  void _cycleBoxFitMode() {
    setState(() {
      _videoFilterManager?.cycleBoxFitMode();
    });
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
          mediaTitle: targetMetadata.title,
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
      seekWithClamping(player!, Duration(seconds: settings.getSeekTimeSmall()));
    };
    receiver.onSeekBackward = () async {
      if (player == null) return;
      final settings = await SettingsService.getInstance();
      seekWithClamping(player!, Duration(seconds: -settings.getSeekTimeSmall()));
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
      _companionRemoteProvider!.sendCommand(
        RemoteCommandType.syncState,
        data: {'playerActive': true},
      );
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
    _companionRemoteProvider?.sendCommand(
      RemoteCommandType.syncState,
      data: {'playerActive': false},
    );
    _companionRemoteProvider = null;
  }

  void _cycleSubtitleTrack() {
    if (player == null) return;
    final tracks = player!.state.tracks.subtitle.where((t) => t.id != 'auto').toList();
    if (tracks.isEmpty) return;

    final current = player!.state.track.subtitle;
    // tracks includes 'no' (off). Find current index and advance.
    final currentIndex = tracks.indexWhere((t) => t.id == current?.id);
    final nextIndex = (currentIndex + 1) % tracks.length;
    final next = tracks[nextIndex];
    player!.selectSubtitleTrack(next);
    _onSubtitleTrackChanged(next);

    if (mounted) {
      final label = next.id == 'no'
          ? 'Subtitles: Off'
          : 'Subtitles: ${tlb.TrackLabelBuilder.buildSubtitleLabel(title: next.title, language: next.language, codec: next.codec, index: nextIndex)}';
      showAppSnackBar(context, label, duration: const Duration(seconds: 1));
    }
  }

  void _cycleAudioTrack() {
    if (player == null) return;
    final tracks = player!.state.tracks.audio.where((t) => t.id != 'auto' && t.id != 'no').toList();
    if (tracks.length <= 1) return;

    final current = player!.state.track.audio;
    final currentIndex = tracks.indexWhere((t) => t.id == current?.id);
    final nextIndex = (currentIndex + 1) % tracks.length;
    final next = tracks[nextIndex];
    player!.selectAudioTrack(next);
    _onAudioTrackChanged(next);

    if (mounted) {
      final label = 'Audio: ${tlb.TrackLabelBuilder.buildAudioLabel(title: next.title, language: next.language, codec: next.codec, channelsCount: next.channelsCount, index: nextIndex)}';
      showAppSnackBar(context, label, duration: const Duration(seconds: 1));
    }
  }

  Future<void> _toggleFullscreen() async {
    if (PlatformDetector.isMobile(context)) return;
    await FullscreenStateManager().toggleFullscreen();
  }

  /// Exit fullscreen before leaving the player (Windows/Linux only).
  /// macOS is excluded because we can't distinguish native fullscreen
  /// from maximized state, so we leave the window state unchanged.
  Future<void> _exitFullscreenIfNeeded() async {
    if (AppPlatform.isWindows || AppPlatform.isLinux) {
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

    // Remove PiP state listener, clear callback, and dispose video filter manager
    _videoPIPManager?.isPipActive.removeListener(_onPipStateChanged);
    _videoPIPManager?.onBeforeEnterPip = null;
    _videoFilterManager?.dispose();

    // Cancel stream subscriptions
    _playingSubscription?.cancel();
    _completedSubscription?.cancel();
    _errorSubscription?.cancel();
    _mediaControlSubscription?.cancel();
    _bufferingSubscription?.cancel();
    _trackLoadingSubscription?.cancel();
    _positionSubscription?.cancel();
    _playbackRestartSubscription?.cancel();
    _backendSwitchedSubscription?.cancel();
    _sleepTimerSubscription?.cancel();

    // Cancel auto-play timer
    _autoPlayTimer?.cancel();

    // Dispose Play Next dialog focus nodes
    _playNextCancelFocusNode.dispose();
    _playNextConfirmFocusNode.dispose();

    // Dispose screen-level focus node
    _screenFocusNode.removeListener(_onScreenFocusChanged);
    _screenFocusNode.dispose();

    // Clear media controls and dispose manager
    _mediaControlsManager?.clear();
    _mediaControlsManager?.dispose();

    // Clear Discord Rich Presence
    DiscordRPCService.instance.stopPlayback();

    // Clear frame rate matching and abandon audio focus before disposing player (Android only)
    if (AppPlatform.isAndroid && player != null) {
      player!.clearVideoFrameRate();
      player!.abandonAudioFocus();
    }

    // Disable wakelock when leaving the video player
    WakelockPlus.disable();
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
    if (!_screenFocusNode.hasFocus && mounted && !_isExiting.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isExiting.value && !_screenFocusNode.hasFocus) {
          _screenFocusNode.requestFocus();
        }
      });
    }
  }

  void _onPlayingStateChanged(bool isPlaying) {
    // Toggle wakelock based on playback state
    if (isPlaying) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
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
  }

  void _onVideoCompleted(bool completed) async {
    if (completed && _nextEpisode != null && !_showPlayNextDialog && !_completionTriggered) {
      _completionTriggered = true;

      // Capture keyboard mode before async gap
      final isKeyboardMode = PlatformDetector.isTV() && InputModeTracker.isKeyboardMode(context);

      final settings = await SettingsService.getInstance();
      final autoPlayEnabled = settings.getAutoPlayNextEpisode();

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
    }
  }

  void _onPlayerError(String error) {
    appLogger.e('[Player ERROR] $error');
    if (!mounted) return;

    showErrorSnackBar(context, t.messages.failedPlayback(action: 'play', error: error));
  }

  /// Handle notification when native player switched from ExoPlayer to MPV
  void _onBackendSwitched() {
    appLogger.i('Player backend switched from ExoPlayer to MPV (native fallback)');

    if (mounted) {
      showAppSnackBar(context, t.messages.switchingToCompatiblePlayer);
    }
  }

  // OS Media Controls Integration

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

  /// Apply track selection using the TrackSelectionService
  Future<void> _applyTrackSelection() async {
    if (!mounted || player == null) return;

    final profileSettings = context.read<UserProfileProvider>().profileSettings;
    final settingsService = await SettingsService.getInstance();
    final trackService = TrackSelectionService(
      player: player!,
      profileSettings: profileSettings,
      metadata: widget.metadata,
      plexMediaInfo: _currentMediaInfo,
    );

    await trackService.selectAndApplyTracks(
      preferredAudioTrack: widget.preferredAudioTrack,
      preferredSubtitleTrack: widget.preferredSubtitleTrack,
      defaultPlaybackSpeed: settingsService.getDefaultPlaybackSpeed(),
      onAudioTrackChanged: _onAudioTrackChanged,
      onSubtitleTrackChanged: _onSubtitleTrackChanged,
    );
  }

  /// Handle audio track changes from the user - save both stream selection and language preference
  Future<void> _onAudioTrackChanged(AudioTrack track) async {
    final settings = await SettingsService.getInstance();

    // Only save if remember track selections is enabled
    if (!settings.getRememberTrackSelections()) {
      return;
    }
    if (_currentMediaInfo == null) {
      appLogger.w('No media info available, cannot save stream selection');
      return;
    }
    final partId = _currentMediaInfo!.getPartId();
    if (partId == null) {
      appLogger.w('No part ID available, cannot save stream selection');
      return;
    }

    final languageCode = track.language;
    int? streamID;

    // === Matching by attributes ===
    PlexAudioTrack? matched;
    final normalizedTrackLang = _iso6391ToPlex6392(track.language);

    appLogger.d('Normalized media_kit language: ${track.language} -> $normalizedTrackLang');

    for (final plexTrack in _currentMediaInfo!.audioTracks) {
      final matchLang = plexTrack.languageCode == normalizedTrackLang;
      final matchTitle = (track.title == null || track.title!.isEmpty)
          ? true
          : (plexTrack.displayTitle == track.title || plexTrack.title == track.title);

      if (matchLang && matchTitle) {
        matched = plexTrack;
        appLogger.d('Matched audio by lang/title: streamID ${matched.id}');
        break;
      }
    }

    if (matched != null) {
      streamID = matched.id;
      appLogger.d('Matched audio by lang/title: streamID $streamID');
    } else {
      // Use property-based matching from track_selection_service
      final matchedPlex = findPlexTrackForMpvAudio(track, _currentMediaInfo!.audioTracks);

      if (matchedPlex != null) {
        streamID = matchedPlex.id;
        appLogger.d('Matched audio by properties: streamID $streamID');
      } else {
        appLogger.e('Could not match audio track to any Plex track');
      }
    }

    final isEpisode = widget.metadata.isEpisode;
    final languagePrefRatingKey = isEpisode
        ? (widget.metadata.grandparentRatingKey ?? widget.metadata.ratingKey)
        : widget.metadata.ratingKey;

    try {
      if (!mounted) return;
      final client = _getClientForMetadata(context);

      final futures = <Future>[];

      // 1. Language preference (series/movie level)
      if (languageCode != null && languageCode.isNotEmpty) {
        futures.add(client.setMetadataPreferences(languagePrefRatingKey, audioLanguage: languageCode));
      }
      // 2. Exact stream selection (part level)
      if (streamID != null) {
        futures.add(client.selectStreams(partId, audioStreamID: streamID, allParts: true));
      }

      await Future.wait(futures);
      appLogger.d('Successfully saved audio preferences (language + stream)');
    } catch (e) {
      appLogger.e('Failed to save audio preferences', error: e);
    }
  }

  /// Handle subtitle track changes from the user - save both stream selection and language preference
  Future<void> _onSubtitleTrackChanged(SubtitleTrack track) async {
    final settings = await SettingsService.getInstance();

    // Only save if remember track selections is enabled
    if (!settings.getRememberTrackSelections()) {
      return;
    }

    if (_currentMediaInfo == null) {
      appLogger.w('No media info available, cannot save stream selection');
      return;
    }

    final partId = _currentMediaInfo!.getPartId();
    if (partId == null) {
      appLogger.w('No part ID available, cannot save stream selection');
      return;
    }

    String? languageCode;
    int? streamID;

    if (track.id == 'no') {
      languageCode = 'none';
      streamID = 0;
      appLogger.i('User turned subtitles off, saving preference');
    } else {
      languageCode = track.language;

      // === Matching by attributes ===
      PlexSubtitleTrack? matched;
      final normalizedTrackLang = _iso6391ToPlex6392(track.language);

      appLogger.d('Normalized media_kit language: ${track.language} -> $normalizedTrackLang');

      for (final plexTrack in _currentMediaInfo!.subtitleTracks) {
        final matchLang = plexTrack.languageCode == normalizedTrackLang;
        final matchTitle = (track.title == null || track.title!.isEmpty)
            ? true
            : (plexTrack.displayTitle == track.title || plexTrack.title == track.title);

        appLogger.d('Comparing with streamID ${plexTrack.id}:');
        appLogger.d('  matchLang: $matchLang (${plexTrack.languageCode} == $normalizedTrackLang)');
        appLogger.d('  matchTitle: $matchTitle');

        if (matchLang && matchTitle) {
          matched = plexTrack;
          appLogger.d('  ✅ MATCHED!');
          break;
        }
      }

      if (matched != null) {
        streamID = matched.id;
        appLogger.d('Matched subtitle by lang/title: streamID $streamID');
      } else {
        // Use property-based matching from track_selection_service
        final matchedPlex = findPlexTrackForMpvSubtitle(track, _currentMediaInfo!.subtitleTracks);

        if (matchedPlex != null) {
          streamID = matchedPlex.id;
          appLogger.d('Matched subtitle by properties: streamID $streamID');
        } else {
          appLogger.e('Could not match subtitle track to any Plex track');
        }
      }
    }

    // Determine ratingKeys
    final isEpisode = widget.metadata.isEpisode;
    final languagePrefRatingKey = isEpisode
        ? (widget.metadata.grandparentRatingKey ?? widget.metadata.ratingKey)
        : widget.metadata.ratingKey;

    appLogger.i(
      'Saving subtitle preference: language=$languageCode (ratingKey: $languagePrefRatingKey), streamID=$streamID (partId: $partId)',
    );

    try {
      if (!mounted) return;
      final client = _getClientForMetadata(context);

      final futures = <Future>[];

      // 1. Save language preference at series/movie level
      if (languageCode != null) {
        futures.add(client.setMetadataPreferences(languagePrefRatingKey, subtitleLanguage: languageCode));
      }
      // 2. Save exact stream selection using part ID
      if (streamID != null) {
        futures.add(client.selectStreams(partId, subtitleStreamID: streamID, allParts: true));
      }

      await Future.wait(futures);
      appLogger.d('Successfully saved subtitle preferences (language + stream)');
    } catch (e) {
      appLogger.e('Failed to save subtitle preferences', error: e);
    }
  }

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
    // - onKeyEvent: catch-all that consumes any event children didn't handle,
    //   preventing leaks to previous routes.
    return Focus(
      focusNode: _screenFocusNode,
      autofocus: isCurrentRoute,
      canRequestFocus: isCurrentRoute,
      onKeyEvent: (node, event) {
        if (!isCurrentRoute) return KeyEventResult.ignored;
        // Safety net: if this screen-level node itself has primary focus
        // (no descendant focused, e.g. after controls auto-hide), self-heal.
        // BACK is excluded: on Android TV the BACK button fires both a key event
        // and a system back gesture. Handling it here would double-pop because
        // PopScope.onPopInvokedWithResult also processes the system back gesture.
        // PopScope handles BACK navigation exclusively.
        if (node.hasPrimaryFocus && !event.logicalKey.isBackKey) {
          // Redirect focus to the first traversable descendant (video controls)
          // and show controls immediately so the first key press isn't swallowed.
          if (event.isActionable) {
            _controlsVisible.value = true;
            final descendants = node.traversalDescendants;
            if (descendants.isNotEmpty) {
              descendants.first.requestFocus();
            }
          }
        }
        return KeyEventResult.handled;
      },
      child: _isPlayerInitialized && player != null ? _buildVideoPlayer(context) : _buildLoadingSpinner(),
    );
  }

  Widget _buildVideoPlayer(BuildContext context) {
    // Cache platform detection to avoid multiple calls
    final isMobile = PlatformDetector.isMobile(context);

    return PopScope(
      canPop: false, // Disable swipe-back gesture to prevent interference with timeline scrubbing
      onPopInvokedWithResult: (didPop, result) {
        // Only process system-initiated back gestures (didPop: false).
        // Programmatic Navigator.pop() triggers didPop: true — ignore it here
        // to avoid consuming the BackKeyCoordinator flag before the system back
        // gesture arrives (which would cause a double-pop on Android TV).
        if (!didPop) {
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

                    return Video(
                      player: player!,
                      controls: (context) => plexVideoControlsBuilder(
                        player!,
                        widget.metadata,
                        onNext: (_nextEpisode != null && _canNavigateEpisodes()) ? _playNext : null,
                        onPrevious: (_previousEpisode != null && _canNavigateEpisodes()) ? _playPrevious : null,
                        availableVersions: _availableVersions,
                        selectedMediaIndex: widget.selectedMediaIndex,
                        onTogglePIPMode: _togglePIPMode,
                        boxFitMode: _videoFilterManager?.boxFitMode ?? 0,
                        onCycleBoxFitMode: _cycleBoxFitMode,
                        onAudioTrackChanged: _onAudioTrackChanged,
                        onSubtitleTrackChanged: _onSubtitleTrackChanged,
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
                        onShaderChanged: () => setState(() {}),
                        thumbnailUrlBuilder: _hasThumbnails && _currentMediaInfo?.partId != null
                            ? (Duration time) => _buildThumbnailUrl(context, time)!
                            : null,
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
                            borderRadius: BorderRadius.circular(12),
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
                                            _nextEpisode!.title,
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
                                    child: FocusableWrapper(
                                      focusNode: _playNextCancelFocusNode,
                                      onSelect: _cancelAutoPlay,
                                      useBackgroundFocus: true,
                                      autoScroll: false,
                                      borderRadius: 20,
                                      onKeyEvent: (node, event) {
                                        if (event is KeyDownEvent) {
                                          // RIGHT arrow moves focus to Play Next button
                                          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                                            _playNextConfirmFocusNode.requestFocus();
                                            return KeyEventResult.handled;
                                          }
                                          // Trap focus - consume UP/DOWN to prevent escape
                                          if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                                              event.logicalKey == LogicalKeyboardKey.arrowDown) {
                                            return KeyEventResult.handled;
                                          }
                                        }
                                        return KeyEventResult.ignored;
                                      },
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
                                    child: FocusableWrapper(
                                      focusNode: _playNextConfirmFocusNode,
                                      onSelect: _playNext,
                                      useBackgroundFocus: true,
                                      autoScroll: false,
                                      borderRadius: 20,
                                      onKeyEvent: (node, event) {
                                        if (event is KeyDownEvent) {
                                          // LEFT arrow moves focus to Cancel button
                                          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                                            _playNextCancelFocusNode.requestFocus();
                                            return KeyEventResult.handled;
                                          }
                                          // Trap focus - consume UP/DOWN to prevent escape
                                          if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                                              event.logicalKey == LogicalKeyboardKey.arrowDown) {
                                            return KeyEventResult.handled;
                                          }
                                        }
                                        return KeyEventResult.ignored;
                                      },
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
              // Watch Together: reconnecting to host overlay
              Consumer<WatchTogetherProvider>(
                builder: (context, provider, child) {
                  if (!provider.isWaitingForHostReconnect) return const SizedBox.shrink();
                  return Positioned(
                    bottom: 120,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Text(t.watchTogether.reconnectingToHost, style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Watch Together: participant join/leave notifications
              const ParticipantNotificationOverlay(),
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

  if (AppPlatform.isMacOS || AppPlatform.isIOS) {
    return 'videotoolbox';
  } else if (AppPlatform.isAndroid) {
    return 'auto-safe';
  } else {
    return 'auto'; // Windows, Linux
  }
}
