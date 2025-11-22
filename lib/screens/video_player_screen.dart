import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:os_media_controls/os_media_controls.dart';
import 'package:provider/provider.dart';

import '../client/plex_client.dart';
import '../models/plex_media_version.dart';
import '../models/plex_metadata.dart';
import '../providers/playback_state_provider.dart';
import '../services/episode_navigation_service.dart';
import '../services/media_controls_manager.dart';
import '../services/playback_initialization_service.dart';
import '../services/playback_progress_tracker.dart';
import '../services/settings_service.dart';
import '../services/track_selection_service.dart';
import '../services/video_filter_manager.dart';
import '../utils/app_logger.dart';
import '../utils/orientation_helper.dart';
import '../utils/platform_detector.dart';
import '../utils/provider_extensions.dart';
import '../utils/video_player_navigation.dart';
import '../widgets/video_controls/video_controls.dart';
import '../i18n/strings.g.dart';

class VideoPlayerScreen extends StatefulWidget {
  final PlexMetadata metadata;
  final AudioTrack? preferredAudioTrack;
  final SubtitleTrack? preferredSubtitleTrack;
  final double? preferredPlaybackRate;
  final int selectedMediaIndex;

  const VideoPlayerScreen({
    super.key,
    required this.metadata,
    this.preferredAudioTrack,
    this.preferredSubtitleTrack,
    this.preferredPlaybackRate,
    this.selectedMediaIndex = 0,
  });

  @override
  State<VideoPlayerScreen> createState() => VideoPlayerScreenState();
}

class VideoPlayerScreenState extends State<VideoPlayerScreen>
    with WidgetsBindingObserver {
  Player? player;
  VideoController? controller;
  bool _isPlayerInitialized = false;
  PlexMetadata? _nextEpisode;
  PlexMetadata? _previousEpisode;
  bool _isLoadingNext = false;
  bool _showPlayNextDialog = false;
  bool _isPhone = false;
  List<PlexMediaVersion> _availableVersions = [];
  StreamSubscription<PlayerLog>? _logSubscription;
  StreamSubscription<String>? _errorSubscription;
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<bool>? _completedSubscription;
  StreamSubscription<dynamic>? _mediaControlSubscription;
  StreamSubscription<bool>? _bufferingSubscription;
  StreamSubscription<Tracks>? _trackLoadingSubscription;
  bool _isReplacingWithVideo =
      false; // Flag to skip orientation restoration during video-to-video navigation

  // App lifecycle state tracking
  bool _wasPlayingBeforeInactive = false;

  // Services
  MediaControlsManager? _mediaControlsManager;
  PlaybackProgressTracker? _progressTracker;
  VideoFilterManager? _videoFilterManager;
  TrackSelectionService? _trackSelectionService;
  final EpisodeNavigationService _episodeNavigation =
      EpisodeNavigationService();

  /// Get the correct PlexClient for this metadata's server
  PlexClient _getClientForMetadata(BuildContext context) {
    return context.getClientForServer(widget.metadata.serverId);
  }

  final ValueNotifier<bool> _isBuffering = ValueNotifier<bool>(
    false,
  ); // Track if video is currently buffering

  @override
  void initState() {
    super.initState();

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
      appLogger.d(
        'Deferred playback state update (provider not ready)',
        error: e,
      );
    }

    // Register app lifecycle observer
    WidgetsBinding.instance.addObserver(this);

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
        // App is inactive (Control Center, Notification Screen, etc.)
        // Pause video but keep media controls for quick resume (mobile only)
        if (PlatformDetector.isMobile(context)) {
          if (player != null && _isPlayerInitialized) {
            _wasPlayingBeforeInactive = player!.state.playing;
            if (_wasPlayingBeforeInactive) {
              player!.pause();
              appLogger.d('Video paused due to app becoming inactive (mobile)');
            }
            // Keep media controls active on mobile for quick resume
            _updateMediaControlsPlaybackState();
          }
        }
        break;
      case AppLifecycleState.paused:
        // Clear media controls when app truly goes to background
        // (we don't support background playback)
        OsMediaControls.clear();
        appLogger.d(
          'Media controls cleared due to app being paused/backgrounded',
        );
        break;
      case AppLifecycleState.resumed:
        // Restore media controls when app is resumed
        if (_isPlayerInitialized && mounted) {
          // Restore media metadata
          final client = _getClientForMetadata(context);
          if (_mediaControlsManager != null) {
            _mediaControlsManager!.updateMetadata(
              metadata: widget.metadata,
              client: client,
              duration: widget.metadata.duration != null
                  ? Duration(milliseconds: widget.metadata.duration!)
                  : null,
            );
          }

          // Resume playback if it was playing before going inactive
          if (_wasPlayingBeforeInactive && player != null) {
            player!.play();
            _wasPlayingBeforeInactive = false;
            appLogger.d('Video resumed after returning from inactive state');
          }

          _updateMediaControlsPlaybackState();
          appLogger.d('Media controls restored on app resume');
        }
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // No action needed for these states
        break;
    }
  }

  Future<void> _initializePlayer() async {
    try {
      // Load buffer size from settings
      final settingsService = await SettingsService.getInstance();
      final bufferSizeMB = settingsService.getBufferSize();
      final bufferSizeBytes = bufferSizeMB * 1024 * 1024;
      final enableHardwareDecoding = settingsService
          .getEnableHardwareDecoding();
      final debugLoggingEnabled = settingsService.getEnableDebugLogging();

      // Build MPV configuration
      final config = <String, String>{
        'sub-font-size': settingsService.getSubtitleFontSize().toString(),
        'sub-color': settingsService.getSubtitleTextColor(),
        'sub-border-size': settingsService.getSubtitleBorderSize().toString(),
        'sub-border-color': settingsService.getSubtitleBorderColor(),
        'sub-back-color':
            '#${(settingsService.getSubtitleBackgroundOpacity() * 255 / 100).toInt().toRadixString(16).padLeft(2, '0').toUpperCase()}${settingsService.getSubtitleBackgroundColor().replaceFirst('#', '')}',
        'sub-ass-override': 'no',
      };

      if (Platform.isIOS) {
        config['audio-exclusive'] = 'yes';
      }

      // Create player with configuration
      player = Player(
        configuration: PlayerConfiguration(
          libass: true,
          libassAndroidFont: 'assets/droid-sans.ttf',
          libassAndroidFontName: 'Droid Sans Fallback',
          bufferSize: bufferSizeBytes,
          logLevel: debugLoggingEnabled ? MPVLogLevel.debug : MPVLogLevel.error,
          mpvConfiguration: config,
        ),
      );
      controller = VideoController(
        player!,
        configuration: VideoControllerConfiguration(
          enableHardwareAcceleration: enableHardwareDecoding,
        ),
      );

      // Apply audio sync offset
      final audioSyncOffset = settingsService.getAudioSyncOffset();
      if (audioSyncOffset != 0) {
        final offsetSeconds = audioSyncOffset / 1000.0;
        await (player!.platform as dynamic).setProperty(
          'audio-delay',
          offsetSeconds.toString(),
        );
      }

      // Apply subtitle sync offset
      final subtitleSyncOffset = settingsService.getSubtitleSyncOffset();
      if (subtitleSyncOffset != 0) {
        final offsetSeconds = subtitleSyncOffset / 1000.0;
        await (player!.platform as dynamic).setProperty(
          'sub-delay',
          offsetSeconds.toString(),
        );
      }

      // Apply saved volume
      final savedVolume = settingsService.getVolume();
      player!.setVolume(savedVolume);

      // Notify that player is ready
      if (mounted) {
        setState(() {
          _isPlayerInitialized = true;
        });
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
      _playingSubscription = player!.stream.playing.listen(
        _onPlayingStateChanged,
      );

      // Listen to completion
      _completedSubscription = player!.stream.completed.listen(
        _onVideoCompleted,
      );

      // Listen to MPV logs
      _logSubscription = player!.stream.log.listen(_onPlayerLog);

      // Listen to MPV errors
      _errorSubscription = player!.stream.error.listen(_onPlayerError);

      // Listen to buffering state
      _bufferingSubscription = player!.stream.buffering.listen((isBuffering) {
        _isBuffering.value = isBuffering;
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

  /// Initialize the service layer
  Future<void> _initializeServices() async {
    if (!mounted || player == null) return;

    final client = _getClientForMetadata(context);

    // Initialize progress tracker
    _progressTracker = PlaybackProgressTracker(
      client: client,
      metadata: widget.metadata,
      player: player!,
    );
    _progressTracker!.startTracking();

    // Initialize media controls manager
    _mediaControlsManager = MediaControlsManager();

    // Set up media control event handling
    _mediaControlSubscription = _mediaControlsManager!.controlEvents.listen((
      event,
    ) {
      if (event is PlayEvent) {
        appLogger.d('Media control: Play event received');
        if (player != null) {
          player!.play();
          _wasPlayingBeforeInactive = false;
          appLogger.d(
            'Cleared _wasPlayingBeforeInactive due to manual play via media controls',
          );
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

    // Update media metadata
    await _mediaControlsManager!.updateMetadata(
      metadata: widget.metadata,
      client: client,
      duration: widget.metadata.duration != null
          ? Duration(milliseconds: widget.metadata.duration!)
          : null,
    );

    if (!mounted) return;

    // Set controls enabled based on content type
    final playbackState = context.read<PlaybackStateProvider>();
    final isEpisode = widget.metadata.type.toLowerCase() == 'episode';
    final isInPlaylist = playbackState.isPlaylistActive;

    await _mediaControlsManager!.setControlsEnabled(
      canGoNext: isEpisode || isInPlaylist,
      canGoPrevious: isEpisode || isInPlaylist,
    );

    // Listen to playing state and update media controls
    player!.stream.playing.listen((isPlaying) {
      _updateMediaControlsPlaybackState();
    });

    // Listen to position updates for media controls
    player!.stream.position.listen((position) {
      _mediaControlsManager?.updatePlaybackState(
        isPlaying: player!.state.playing,
        position: position,
        speed: player!.state.rate,
      );
    });
  }

  /// Ensure a play queue exists for sequential episode playback
  Future<void> _ensurePlayQueue() async {
    if (!mounted) return;

    // Only create play queues for episodes
    if (widget.metadata.type.toLowerCase() != 'episode') {
      return;
    }

    try {
      final client = _getClientForMetadata(context);

      final playbackState = context.read<PlaybackStateProvider>();

      // Determine the show's rating key
      // For episodes, grandparentRatingKey points to the show
      final showRatingKey = widget.metadata.grandparentRatingKey;
      if (showRatingKey == null) {
        appLogger.d(
          'Episode missing grandparentRatingKey, skipping play queue creation',
        );
        return;
      }

      // Check if there's already an active queue for this show
      final existingContextKey = playbackState.shuffleContextKey;
      final isQueueActive = playbackState.isQueueActive;

      if (isQueueActive && existingContextKey == showRatingKey) {
        // Queue already exists for this show, just update the current item
        playbackState.setCurrentItem(widget.metadata);
        appLogger.d('Using existing play queue for show $showRatingKey');
        return;
      }

      // Create a new sequential play queue for the show
      appLogger.d('Creating sequential play queue for show $showRatingKey');
      final playQueue = await client.createShowPlayQueue(
        showRatingKey: showRatingKey,
        shuffle: 0, // Sequential order
        startingEpisodeKey: widget.metadata.ratingKey,
      );

      if (playQueue != null &&
          playQueue.items != null &&
          playQueue.items!.isNotEmpty) {
        // Initialize playback state with the play queue
        await playbackState.setPlaybackFromPlayQueue(
          playQueue,
          showRatingKey,
          serverId: widget.metadata.serverId,
          serverName: widget.metadata.serverName,
        );

        // Set the client for loading more items
        playbackState.setClient(client);

        appLogger.d(
          'Sequential play queue created with ${playQueue.items!.length} items',
        );
      }
    } catch (e) {
      // Non-critical: Sequential playback will fall back to non-queue navigation
      appLogger.d(
        'Could not create play queue for sequential playback',
        error: e,
      );
    }
  }

  Future<void> _loadAdjacentEpisodes() async {
    if (!mounted) return;

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

  Future<void> _startPlayback() async {
    if (!mounted) return;

    try {
      // Use server-specific client for this metadata
      final client = _getClientForMetadata(context);

      // Capture profile settings before async gap
      final profileSettings = context.profileSettings;

      // Initialize playback service
      final playbackService = PlaybackInitializationService(
        player: player!,
        client: client,
        context: context,
      );

      // Start playback and get available versions
      final result = await playbackService.startPlayback(
        metadata: widget.metadata,
        selectedMediaIndex: widget.selectedMediaIndex,
      );

      // Update available versions from the playback data
      if (mounted) {
        setState(() {
          _availableVersions = result.availableVersions.cast();
        });

        // Initialize video filter manager with player and available versions
        if (player != null && _availableVersions.isNotEmpty) {
          _videoFilterManager = VideoFilterManager(
            player: player!,
            availableVersions: _availableVersions,
            selectedMediaIndex: widget.selectedMediaIndex,
          );
          // Update video filter once dimensions are available
          _videoFilterManager!.updateVideoFilter();
        }
      }

      // Initialize track selection service and apply tracks
      _trackSelectionService = TrackSelectionService(
        player: player!,
        profileSettings: profileSettings,
        metadata: widget.metadata,
      );

      await _trackSelectionService!.selectAndApplyTracks(
        preferredAudioTrack: widget.preferredAudioTrack,
        preferredSubtitleTrack: widget.preferredSubtitleTrack,
        preferredPlaybackRate: widget.preferredPlaybackRate,
      );
    } on PlaybackException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.messages.errorLoading(error: e.toString()))),
        );
      }
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

  @override
  void dispose() {
    // Unregister app lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    // Dispose value notifiers
    _isBuffering.dispose();

    // Stop progress tracking and send final state
    _progressTracker?.sendProgress('stopped');
    _progressTracker?.stopTracking();
    _progressTracker?.dispose();

    // Dispose video filter manager
    _videoFilterManager?.dispose();

    // Cancel stream subscriptions
    _playingSubscription?.cancel();
    _completedSubscription?.cancel();
    _logSubscription?.cancel();
    _errorSubscription?.cancel();
    _mediaControlSubscription?.cancel();
    _bufferingSubscription?.cancel();
    _trackLoadingSubscription?.cancel();

    // Clear media controls and dispose manager
    _mediaControlsManager?.clear();
    _mediaControlsManager?.dispose();

    // Clear video filter and reset subtitle margins before disposing player
    try {
      if (player != null) {
        final nativePlayer = player!.platform as dynamic;
        nativePlayer.setProperty('vf', '');
        nativePlayer.setProperty('sub-margin-x', '0');
        nativePlayer.setProperty('sub-margin-y', '0');
        nativePlayer.setProperty('sub-scale', '1.0');
      }
    } catch (e) {
      // Non-critical: Cleanup operations during disposal
      appLogger.d('Error during player cleanup in dispose', error: e);
    }

    // Restore system UI and orientation preferences (skip if navigating to another video)
    if (!_isReplacingWithVideo) {
      OrientationHelper.restoreSystemUI();

      // Restore orientation based on cached device type (no context needed)
      try {
        if (_isPhone) {
          // Phone: portrait only
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]);
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
    super.dispose();
  }

  void _onPlayingStateChanged(bool isPlaying) {
    // Send timeline update when playback state changes
    _progressTracker?.sendProgress(isPlaying ? 'playing' : 'paused');

    // Update OS media controls playback state
    _updateMediaControlsPlaybackState();
  }

  void _onVideoCompleted(bool completed) {
    if (completed && _nextEpisode != null && !_showPlayNextDialog) {
      setState(() {
        _showPlayNextDialog = true;
      });
    }
  }

  void _onPlayerLog(PlayerLog log) {
    // Map MPV log levels to app logger levels
    switch (log.level.toLowerCase()) {
      case 'fatal':
      case 'error':
        appLogger.e('[MPV:${log.prefix}] ${log.text}');
        break;
      case 'warn':
        appLogger.w('[MPV:${log.prefix}] ${log.text}');
        break;
      case 'info':
        appLogger.i('[MPV:${log.prefix}] ${log.text}');
        break;
      case 'debug':
      case 'trace':
      case 'v':
        appLogger.d('[MPV:${log.prefix}] ${log.text}');
        break;
      default:
        appLogger.d('[MPV:${log.prefix}:${log.level}] ${log.text}');
    }
  }

  void _onPlayerError(String error) {
    appLogger.e('[MPV ERROR] $error');
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

    setState(() {
      _isLoadingNext = true;
      _showPlayNextDialog = false;
    });

    await _navigateToEpisode(_nextEpisode!);
  }

  Future<void> _playPrevious() async {
    if (_previousEpisode == null) return;
    await _navigateToEpisode(_previousEpisode!);
  }

  /// Handle audio track changes from the user - save as per-media preference if enabled
  Future<void> _onAudioTrackChanged(AudioTrack track) async {
    final settings = await SettingsService.getInstance();

    // Only save if remember track selections is enabled
    if (!settings.getRememberTrackSelections()) {
      return;
    }

    // Extract language code from the track
    final languageCode = track.language;
    if (languageCode == null || languageCode.isEmpty) {
      appLogger.d('Audio track has no language code, not saving preference');
      return;
    }

    // Determine which ratingKey to use
    // For TV shows: use grandparentRatingKey (series level)
    // For movies: use ratingKey (movie level)
    final isEpisode = widget.metadata.type.toLowerCase() == 'episode';
    final targetRatingKey = isEpisode
        ? (widget.metadata.grandparentRatingKey ?? widget.metadata.ratingKey)
        : widget.metadata.ratingKey;

    appLogger.i(
      'Saving audio language preference: $languageCode for ${isEpisode ? "series" : "movie"} (ratingKey: $targetRatingKey)',
    );

    try {
      if (!mounted) return;
      // Use server-specific client for this metadata
      final client = _getClientForMetadata(context);
      await client.setMetadataPreferences(
        targetRatingKey,
        audioLanguage: languageCode,
      );
      appLogger.d('Successfully saved audio language preference');
    } catch (e) {
      appLogger.e('Failed to save audio language preference', error: e);
    }
  }

  /// Handle subtitle track changes from the user - save as per-media preference if enabled
  Future<void> _onSubtitleTrackChanged(SubtitleTrack track) async {
    final settings = await SettingsService.getInstance();

    // Only save if remember track selections is enabled
    if (!settings.getRememberTrackSelections()) {
      return;
    }

    // Handle "Off" selection
    String? languageCode;
    if (track.id == 'no') {
      languageCode = 'none';
      appLogger.i('User turned subtitles off, saving preference');
    } else {
      languageCode = track.language;
      if (languageCode == null || languageCode.isEmpty) {
        appLogger.d(
          'Subtitle track has no language code, not saving preference',
        );
        return;
      }
    }

    // Determine which ratingKey to use
    final isEpisode = widget.metadata.type.toLowerCase() == 'episode';
    final targetRatingKey = isEpisode
        ? (widget.metadata.grandparentRatingKey ?? widget.metadata.ratingKey)
        : widget.metadata.ratingKey;

    appLogger.i(
      'Saving subtitle language preference: $languageCode for ${isEpisode ? "series" : "movie"} (ratingKey: $targetRatingKey)',
    );

    try {
      if (!mounted) return;
      // Use server-specific client for this metadata
      final client = _getClientForMetadata(context);
      await client.setMetadataPreferences(
        targetRatingKey,
        subtitleLanguage: languageCode,
      );
      appLogger.d('Successfully saved subtitle language preference');
    } catch (e) {
      appLogger.e('Failed to save subtitle language preference', error: e);
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

    // If player isn't available, navigate without preserving settings
    if (player == null) {
      if (mounted) {
        navigateToVideoPlayer(
          context,
          metadata: episodeMetadata,
          usePushReplacement: true,
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
        );
      }
      return;
    }

    final currentAudioTrack = currentPlayer.state.track.audio;
    final currentSubtitleTrack = currentPlayer.state.track.subtitle;
    final currentRate = currentPlayer.state.rate;

    // Pause and stop current playback
    currentPlayer.pause();
    _progressTracker?.sendProgress('stopped');
    _progressTracker?.stopTracking();

    // Navigate to the episode using pushReplacement to destroy current player
    if (mounted) {
      navigateToVideoPlayer(
        context,
        metadata: episodeMetadata,
        preferredAudioTrack: currentAudioTrack,
        preferredSubtitleTrack: currentSubtitleTrack,
        preferredPlaybackRate: currentRate,
        usePushReplacement: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while player initializes
    if (!_isPlayerInitialized || controller == null || player == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    // Cache platform detection to avoid multiple calls
    final isMobile = PlatformDetector.isMobile(context);

    return PopScope(
      canPop:
          false, // Disable swipe-back gesture to prevent interference with timeline scrubbing
      onPopInvokedWithResult: (didPop, result) {
        // Allow programmatic back navigation from UI controls
        if (!didPop) {
          Navigator.of(context).pop(true);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior
              .translucent, // Allow taps to pass through to controls
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
            if (_videoFilterManager != null &&
                _videoFilterManager!.isPinching) {
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
                    final newSize = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );

                    // Update player size in video filter manager
                    if (_videoFilterManager != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          _videoFilterManager!.updatePlayerSize(newSize);
                        }
                      });
                    }

                    return Video(
                      controller: controller!,
                      fit: _videoFilterManager?.currentBoxFit ?? BoxFit.contain,
                      controls: (state) => plexVideoControlsBuilder(
                        player!,
                        widget.metadata,
                        onNext: _nextEpisode != null ? _playNext : null,
                        onPrevious: _previousEpisode != null
                            ? _playPrevious
                            : null,
                        availableVersions: _availableVersions,
                        selectedMediaIndex: widget.selectedMediaIndex,
                        boxFitMode: _videoFilterManager?.boxFitMode ?? 0,
                        onCycleBoxFitMode: _cycleBoxFitMode,
                        onAudioTrackChanged: _onAudioTrackChanged,
                        onSubtitleTrackChanged: _onSubtitleTrackChanged,
                      ),
                    );
                  },
                ),
              ),
              // Play Next Dialog
              if (_showPlayNextDialog && _nextEpisode != null)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.8),
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.play_circle_outline,
                              size: 64,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 24),
                            Consumer<PlaybackStateProvider>(
                              builder: (context, playbackState, child) {
                                final isShuffleActive =
                                    playbackState.isShuffleActive;
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Up Next',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (isShuffleActive) ...[
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.shuffle,
                                        size: 20,
                                        color: Colors.white70,
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _nextEpisode!.grandparentTitle ??
                                  _nextEpisode!.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            if (_nextEpisode!.parentIndex != null &&
                                _nextEpisode!.index != null)
                              Text(
                                'S${_nextEpisode!.parentIndex} · E${_nextEpisode!.index} · ${_nextEpisode!.title}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _showPlayNextDialog = false;
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: const BorderSide(color: Colors.white),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                  ),
                                  child: Text(t.dialog.cancel),
                                ),
                                const SizedBox(width: 16),
                                FilledButton(
                                  onPressed: _playNext,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                  ),
                                  child: Text(t.dialog.playNow),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              // Buffering indicator
              ValueListenableBuilder<bool>(
                valueListenable: _isBuffering,
                builder: (context, isBuffering, child) {
                  if (!isBuffering) return const SizedBox.shrink();
                  return Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
