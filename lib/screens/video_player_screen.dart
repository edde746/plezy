import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:os_media_controls/os_media_controls.dart';
import 'package:provider/provider.dart';

import '../mpv/mpv.dart';

import '../../services/plex_client.dart';
import '../models/plex_media_version.dart';
import '../models/plex_metadata.dart';
import '../models/plex_media_info.dart';
import '../providers/playback_state_provider.dart';
import '../services/episode_navigation_service.dart';
import '../services/media_controls_manager.dart';
import '../services/playback_initialization_service.dart';
import '../services/playback_progress_tracker.dart';
import '../services/settings_service.dart';
import '../services/track_selection_service.dart';
import '../services/video_filter_manager.dart';
import '../providers/user_profile_provider.dart';
import '../utils/app_logger.dart';
import '../utils/orientation_helper.dart';
import '../utils/platform_detector.dart';
import '../utils/provider_extensions.dart';
import '../utils/language_codes.dart';
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
  bool _isPlayerInitialized = false;
  PlexMetadata? _nextEpisode;
  PlexMetadata? _previousEpisode;
  bool _isLoadingNext = false;
  bool _showPlayNextDialog = false;
  bool _isPhone = false;
  List<PlexMediaVersion> _availableVersions = [];
  PlexMediaInfo? _currentMediaInfo;
  StreamSubscription<PlayerLog>? _logSubscription;
  StreamSubscription<String>? _errorSubscription;
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<bool>? _completedSubscription;
  StreamSubscription<dynamic>? _mediaControlSubscription;
  StreamSubscription<bool>? _bufferingSubscription;
  StreamSubscription<Tracks>? _trackLoadingSubscription;
  bool _isReplacingWithVideo =
      false; // Flag to skip orientation restoration during video-to-video navigation
  bool _isDisposingForNavigation = false;

  // App lifecycle state tracking
  bool _wasPlayingBeforeInactive = false;

  // Services
  MediaControlsManager? _mediaControlsManager;
  PlaybackProgressTracker? _progressTracker;
  VideoFilterManager? _videoFilterManager;
  final EpisodeNavigationService _episodeNavigation =
      EpisodeNavigationService();

  /// Get the correct PlexClient for this metadata's server
  PlexClient _getClientForMetadata(BuildContext context) {
    return context.getClientForServer(widget.metadata.serverId!);
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
      final enableHardwareDecoding = settingsService
          .getEnableHardwareDecoding();
      final debugLoggingEnabled = settingsService.getEnableDebugLogging();

      // Create player
      player = Player();

      await player!.setProperty('sub-ass', 'yes'); // Enable libass
      await player!.setProperty(
        'demuxer-max-bytes',
        bufferSizeBytes.toString(),
      );
      await player!.setProperty(
        'msg-level',
        debugLoggingEnabled ? 'all=debug' : 'all=error',
      );
      await player!.setProperty(
        'hwdec',
        _getHwdecValue(enableHardwareDecoding),
      );

      // Subtitle styling
      await player!.setProperty(
        'sub-font-size',
        settingsService.getSubtitleFontSize().toString(),
      );
      await player!.setProperty(
        'sub-color',
        settingsService.getSubtitleTextColor(),
      );
      await player!.setProperty(
        'sub-border-size',
        settingsService.getSubtitleBorderSize().toString(),
      );
      await player!.setProperty(
        'sub-border-color',
        settingsService.getSubtitleBorderColor(),
      );
      final bgOpacity =
          (settingsService.getSubtitleBackgroundOpacity() * 255 / 100).toInt();
      final bgColor = settingsService.getSubtitleBackgroundColor().replaceFirst(
        '#',
        '',
      );
      await player!.setProperty(
        'sub-back-color',
        '#${bgOpacity.toRadixString(16).padLeft(2, '0').toUpperCase()}$bgColor',
      );
      await player!.setProperty('sub-ass-override', 'no');

      // Platform-specific settings
      if (Platform.isIOS) {
        await player!.setProperty('audio-exclusive', 'yes');
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
      _playingSubscription = player!.streams.playing.listen(
        _onPlayingStateChanged,
      );

      // Listen to completion
      _completedSubscription = player!.streams.completed.listen(
        _onVideoCompleted,
      );

      // Listen to MPV logs
      _logSubscription = player!.streams.log.listen(_onPlayerLog);

      // Listen to MPV errors
      _errorSubscription = player!.streams.error.listen(_onPlayerError);

      // Listen to buffering state
      _bufferingSubscription = player!.streams.buffering.listen((isBuffering) {
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

  /// Add external subtitle tracks to the player
  Future<void> _addExternalSubtitles(
    List<SubtitleTrack> externalSubtitles,
  ) async {
    if (player == null || externalSubtitles.isEmpty) return;

    appLogger.d(
      'Adding ${externalSubtitles.length} external subtitle(s) to player',
    );

    // Wait for media to be ready
    await _waitForMediaReady();

    for (final subtitleTrack in externalSubtitles) {
      if (subtitleTrack.uri == null) continue;

      try {
        await player!.addSubtitleTrack(
          uri: subtitleTrack.uri!,
          title: subtitleTrack.title,
          language: subtitleTrack.language,
          select: false, // Don't auto-select
        );
        appLogger.d(
          'Added external subtitle: ${subtitleTrack.title ?? subtitleTrack.uri}',
        );
      } catch (e) {
        appLogger.w(
          'Failed to add external subtitle: ${subtitleTrack.title ?? subtitleTrack.uri}',
          error: e,
        );
      }
    }
  }

  /// Wait for media to be ready (duration > 0)
  Future<void> _waitForMediaReady() async {
    if (player == null) return;

    int attempts = 0;
    while (player!.state.duration.inMilliseconds == 0 && attempts < 100) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }

    if (attempts >= 100) {
      appLogger.w('Media ready timeout - proceeding anyway');
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
    player!.streams.playing.listen((isPlaying) {
      _updateMediaControlsPlaybackState();
    });

    // Listen to position updates for media controls
    player!.streams.position.listen((position) {
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

      // Initialize playback service
      final playbackService = PlaybackInitializationService(client: client);

      // Get playback data (video URL and available versions)
      final result = await playbackService.getPlaybackData(
        metadata: widget.metadata,
        selectedMediaIndex: widget.selectedMediaIndex,
      );

      // Open video through Player
      if (result.videoUrl != null) {
        // Pass resume position if available
        final resumePosition = widget.metadata.viewOffset != null
            ? Duration(milliseconds: widget.metadata.viewOffset!)
            : null;
        await player!.open(Media(result.videoUrl!, start: resumePosition));
      }

      // Update available versions from the playback data
      if (mounted) {
        setState(() {
          _availableVersions = result.availableVersions.cast();
          _currentMediaInfo = result.mediaInfo;
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

        // Add external subtitles to the player
        if (result.externalSubtitles.isNotEmpty) {
          await _addExternalSubtitles(result.externalSubtitles);
        }
      }

      // Set up track loading subscription to apply track selection when tracks are loaded
      _trackLoadingSubscription?.cancel();
      _trackLoadingSubscription = player!.streams.tracks.listen((tracks) {
        // Only process when we have actual tracks loaded
        if (tracks.audio.isEmpty && tracks.subtitle.isEmpty) return;

        // Cancel subscription after first load to avoid re-applying on every track change
        _trackLoadingSubscription?.cancel();
        _trackLoadingSubscription = null;

        // Apply track selection using the service
        _applyTrackSelection();
      });
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
    switch (log.level) {
      case PlayerLogLevel.fatal:
      case PlayerLogLevel.error:
        appLogger.e('[MPV:${log.prefix}] ${log.text}');
        break;
      case PlayerLogLevel.warn:
        appLogger.w('[MPV:${log.prefix}] ${log.text}');
        break;
      case PlayerLogLevel.info:
        appLogger.i('[MPV:${log.prefix}] ${log.text}');
        break;
      case PlayerLogLevel.debug:
      case PlayerLogLevel.trace:
      case PlayerLogLevel.verbose:
        appLogger.d('[MPV:${log.prefix}] ${log.text}');
        break;
      default:
        appLogger.d('[MPV:${log.prefix}:${log.level.name}] ${log.text}');
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

  /// Apply track selection using the TrackSelectionService
  Future<void> _applyTrackSelection() async {
    if (!mounted || player == null) return;

    final profileSettings = context.read<UserProfileProvider>().profileSettings;

    final trackService = TrackSelectionService(
      player: player!,
      profileSettings: profileSettings,
      metadata: widget.metadata,
    );

    await trackService.selectAndApplyTracks(
      preferredAudioTrack: widget.preferredAudioTrack,
      preferredSubtitleTrack: widget.preferredSubtitleTrack,
      preferredPlaybackRate: widget.preferredPlaybackRate,
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

    appLogger.d(
      'Normalized media_kit language: ${track.language} -> $normalizedTrackLang',
    );

    for (final plexTrack in _currentMediaInfo!.audioTracks) {
      final matchLang = plexTrack.languageCode == normalizedTrackLang;
      final matchTitle = (track.title == null || track.title!.isEmpty)
          ? true
          : (plexTrack.displayTitle == track.title ||
                plexTrack.title == track.title);

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
      appLogger.w('Could not match audio track, using fallback index');
      // Fallback - normally no offset for audio
      try {
        final trackIndex = int.parse(track.id);

        if (trackIndex >= 0 &&
            trackIndex < _currentMediaInfo!.audioTracks.length) {
          streamID = _currentMediaInfo!.audioTracks[trackIndex].id;
          appLogger.d(
            'Using fallback: audio index $trackIndex -> streamID $streamID',
          );
        } else {
          appLogger.e(
            'Fallback index $trackIndex out of bounds (total: ${_currentMediaInfo!.audioTracks.length})',
          );
        }
      } catch (e) {
        appLogger.e('Failed to parse track index', error: e);
      }
    }

    final isEpisode = widget.metadata.type.toLowerCase() == 'episode';
    final languagePrefRatingKey = isEpisode
        ? (widget.metadata.grandparentRatingKey ?? widget.metadata.ratingKey)
        : widget.metadata.ratingKey;

    try {
      if (!mounted) return;
      final client = _getClientForMetadata(context);

      final futures = <Future>[];

      // 1. Language preference (series/movie level)
      if (languageCode != null && languageCode.isNotEmpty) {
        futures.add(
          client.setMetadataPreferences(
            languagePrefRatingKey,
            audioLanguage: languageCode,
          ),
        );
      }
      // 2. Exact stream selection (part level)
      if (streamID != null) {
        futures.add(
          client.selectStreams(partId, audioStreamID: streamID, allParts: true),
        );
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

      appLogger.d(
        'Normalized media_kit language: ${track.language} -> $normalizedTrackLang',
      );

      for (final plexTrack in _currentMediaInfo!.subtitleTracks) {
        final matchLang = plexTrack.languageCode == normalizedTrackLang;
        final matchTitle = (track.title == null || track.title!.isEmpty)
            ? true
            : (plexTrack.displayTitle == track.title ||
                  plexTrack.title == track.title);

        appLogger.d('Comparing with streamID ${plexTrack.id}:');
        appLogger.d(
          '  matchLang: $matchLang (${plexTrack.languageCode} == $normalizedTrackLang)',
        );
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
        appLogger.w('Could not match subtitle track, using fallback index');
        // Fallback with offset correction
        try {
          final trackIndex = int.parse(track.id);

          // media kit has a "no" (off) at index 0, so real subtitles start at 1
          // We need to subtract 1 to get the actual index in PlexMediaInfo
          final plexIndex = trackIndex > 0 ? trackIndex - 1 : 0;

          if (plexIndex >= 0 &&
              plexIndex < _currentMediaInfo!.subtitleTracks.length) {
            streamID = _currentMediaInfo!.subtitleTracks[plexIndex].id;
            appLogger.d(
              'Using fallback: media_kit index $trackIndex -> Plex index $plexIndex -> streamID $streamID',
            );
          } else {
            appLogger.e(
              'Fallback index $plexIndex out of bounds (total: ${_currentMediaInfo!.subtitleTracks.length})',
            );
          }
        } catch (e) {
          appLogger.e('Failed to parse track index', error: e);
        }
      }
    }

    // Determine ratingKeys
    final isEpisode = widget.metadata.type.toLowerCase() == 'episode';
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
        futures.add(
          client.setMetadataPreferences(
            languagePrefRatingKey,
            subtitleLanguage: languageCode,
          ),
        );
      }
      // 2. Save exact stream selection using part ID
      if (streamID != null) {
        futures.add(
          client.selectStreams(
            partId,
            subtitleStreamID: streamID,
            allParts: true,
          ),
        );
      }

      await Future.wait(futures);
      appLogger.d(
        'Successfully saved subtitle preferences (language + stream)',
      );
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

    // Ensure the native player is fully disposed before creating the next one
    await disposePlayerForNavigation();

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

  /// Dispose the player before replacing the video to avoid race conditions
  Future<void> disposePlayerForNavigation() async {
    if (_isDisposingForNavigation) return;
    _isDisposingForNavigation = true;

    try {
      _progressTracker?.sendProgress('stopped');
      _progressTracker?.stopTracking();
      await player?.dispose();
    } catch (e) {
      appLogger.d('Error disposing player before navigation', error: e);
    } finally {
      player = null;
      _isPlayerInitialized = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while player initializes
    if (!_isPlayerInitialized || player == null) {
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
        // Use transparent background on macOS when native video layer is active
        backgroundColor: Colors.transparent,
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

                    // Update player size in video filter manager and native layer
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && player != null) {
                        _videoFilterManager?.updatePlayerSize(newSize);
                        // Update Metal layer frame on iOS/macOS for rotation
                        player!.updateFrame();
                      }
                    });

                    return Video(
                      player: player!,
                      controls: (context) => plexVideoControlsBuilder(
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

/// Returns the appropriate hwdec value based on platform and user preference.
String _getHwdecValue(bool enabled) {
  if (!enabled) return 'no';

  if (Platform.isMacOS || Platform.isIOS) {
    return 'videotoolbox';
  } else if (Platform.isAndroid) {
    return 'mediacodec-copy';
  } else {
    return 'auto'; // Windows, Linux
  }
}
