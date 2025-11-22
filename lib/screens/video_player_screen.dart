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
import '../models/plex_user_profile.dart';
import '../providers/playback_state_provider.dart';
import '../services/episode_navigation_service.dart';
import '../services/media_controls_manager.dart';
import '../services/playback_progress_tracker.dart';
import '../services/settings_service.dart';
import '../utils/app_logger.dart';
import '../utils/language_codes.dart';
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
  final EpisodeNavigationService _episodeNavigation =
      EpisodeNavigationService();

  /// Get the correct PlexClient for this metadata's server
  PlexClient _getClientForMetadata(BuildContext context) {
    return context.getClientForServer(widget.metadata.serverId);
  }

  // BoxFit mode state: 0=contain (letterbox), 1=cover (fill screen), 2=fill (stretch)
  int _boxFitMode = 0;
  bool _isPinching = false; // Track if a pinch gesture is occurring
  final ValueNotifier<bool> _isBuffering = ValueNotifier<bool>(
    false,
  ); // Track if video is currently buffering

  // Video cropping state for fill screen mode
  Size? _playerSize;
  Size? _videoSize;
  Timer? _resizeDebounceTimer;

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
      _debouncedUpdateVideoFilter();
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
          if (client != null && _mediaControlsManager != null) {
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
      _startPlayback();

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
    if (client == null) return;

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
      if (client == null) return;

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
      if (client == null) return;

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
      if (client == null) {
        throw Exception('No client available');
      }

      // Get consolidated playback data (URL, media info, and versions) in a single API call
      final playbackData = await client.getVideoPlaybackData(
        widget.metadata.ratingKey,
        mediaIndex: widget.selectedMediaIndex,
      );

      if (playbackData.hasValidVideoUrl) {
        final videoUrl = playbackData.videoUrl!;
        final mediaInfo = playbackData.mediaInfo;

        // Update available versions from the playback data
        if (mounted) {
          setState(() {
            _availableVersions = playbackData.availableVersions;
          });
          // Update video filter once dimensions are available
          _updateVideoFilter();
        }

        // Build list of external subtitle tracks for media_kit
        final externalSubtitles = <SubtitleTrack>[];
        if (mediaInfo != null) {
          final externalTracks = mediaInfo.subtitleTracks
              .where((track) => track.isExternal)
              .toList();

          if (externalTracks.isNotEmpty) {
            appLogger.d(
              'Found ${externalTracks.length} external subtitle track(s)',
            );
          }

          for (final plexTrack in externalTracks) {
            try {
              // Skip if no auth token is available
              final token = client.config.token;
              if (token == null) {
                appLogger.w('No auth token available for external subtitles');
                continue;
              }

              final url = plexTrack.getSubtitleUrl(
                client.config.baseUrl,
                token,
              );

              // Skip if URL couldn't be constructed
              if (url == null) continue;

              externalSubtitles.add(
                SubtitleTrack.uri(
                  url,
                  title:
                      plexTrack.displayTitle ??
                      plexTrack.language ??
                      'Track ${plexTrack.id}',
                  language: plexTrack.languageCode,
                ),
              );
            } catch (e) {
              // Silent fallback - log error but continue with other subtitles
              appLogger.w(
                'Failed to add external subtitle track ${plexTrack.id}',
                error: e,
              );
            }
          }
        }

        // Open video (without external subtitles in Media constructor)
        await player!.open(Media(videoUrl), play: false);

        // Wait for media to be ready (duration > 0)
        int attempts = 0;
        while (player!.state.duration.inMilliseconds == 0 && attempts < 100) {
          await Future.delayed(const Duration(milliseconds: 100));
          attempts++;
        }

        // Add external subtitle tracks without auto-selecting them
        if (externalSubtitles.isNotEmpty) {
          appLogger.d(
            'Adding ${externalSubtitles.length} external subtitle(s) to player',
          );

          final nativePlayer = player!.platform as dynamic;

          for (final subtitleTrack in externalSubtitles) {
            try {
              // Use mpv's sub-add with 'auto' flag to avoid auto-selection
              await nativePlayer.command([
                'sub-add',
                subtitleTrack.id,
                'auto',
                subtitleTrack.title ?? 'external',
                subtitleTrack.language ?? 'auto',
              ]);
            } catch (e) {
              appLogger.w(
                'Failed to add external subtitle: ${subtitleTrack.title}',
                error: e,
              );
            }
          }
        }

        // Set up playback position if resuming
        if (widget.metadata.viewOffset != null &&
            widget.metadata.viewOffset! > 0) {
          final resumePosition = Duration(
            milliseconds: widget.metadata.viewOffset!,
          );
          await player!.seek(resumePosition);
        }

        // Start playback after seeking
        await player!.play();

        // Wait for tracks to be loaded, then apply preferred tracks
        _waitForTracksAndApply();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.messages.fileInfoNotAvailable)),
          );
        }
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
      _boxFitMode = (_boxFitMode + 1) % 3;
    });
    _updateVideoFilter();
  }

  /// Toggle between contain and cover modes only (for pinch gesture)
  void _toggleContainCover() {
    setState(() {
      _boxFitMode = _boxFitMode == 0 ? 1 : 0;
    });
    _updateVideoFilter();
  }

  /// Get current BoxFit based on mode
  BoxFit get _getCurrentBoxFit {
    switch (_boxFitMode) {
      case 0:
        return BoxFit.contain;
      case 1:
        return BoxFit.cover;
      case 2:
        return BoxFit.fill;
      default:
        return BoxFit.contain;
    }
  }

  /// Calculates crop parameters for "fill screen" mode (BoxFit.cover) to eliminate letterboxing.
  ///
  /// This method is only active when [_boxFitMode] == 1 (cover mode). It determines how to
  /// crop the video to completely fill the player area while maintaining aspect ratio.
  ///
  /// **How it works:**
  /// 1. Compares video aspect ratio vs player aspect ratio
  /// 2. Crops the dimension that would create letterboxing:
  ///    - Wide video (16:9) on tall player (4:3): crops left/right sides
  ///    - Tall video (4:3) on wide player (16:9): crops top/bottom
  /// 3. Centers the crop within the video
  /// 4. Calculates subtitle margin adjustments to keep subtitles visible
  ///
  /// **Subtitle positioning:**
  /// MPV uses a 720p reference coordinate system for subtitle positioning.
  /// When cropping zooms the video, subtitles need larger margins to avoid
  /// being cropped or appearing too close to edges.
  ///
  /// Returns `null` if:
  /// - Not in cover mode (_boxFitMode != 1)
  /// - Player or video size is unknown
  /// - Aspect ratios are too similar (< 0.01 difference) - no crop needed
  ///
  /// Returns a map containing:
  /// - `width`, `height`: Dimensions of the cropped area in video pixels
  /// - `x`, `y`: Crop offset from video's top-left corner in pixels
  /// - `subMarginX`, `subMarginY`: Subtitle margins in MPV coordinate space (720p reference)
  /// - `subScale`: Subtitle scaling factor (currently always 1.0)
  Map<String, dynamic>? _calculateCropParameters() {
    // Only calculate for cover mode with known dimensions
    if (_boxFitMode != 1 || _playerSize == null || _videoSize == null) {
      return null;
    }

    final playerAspect = _playerSize!.width / _playerSize!.height;
    final videoAspect = _videoSize!.width / _videoSize!.height;

    // No cropping needed if aspect ratios are very similar
    if ((playerAspect - videoAspect).abs() < 0.01) return null;

    late final int cropW, cropH, cropX, cropY;

    if (videoAspect > playerAspect) {
      // Video is wider than player - crop left/right sides
      // Example: 16:9 video in 4:3 player
      final scale = _playerSize!.height / _videoSize!.height;
      cropH = _videoSize!.height.toInt();
      cropW = (_playerSize!.width / scale).toInt();
      cropX = ((_videoSize!.width - cropW) ~/ 2); // Center horizontally
      cropY = 0;
    } else {
      // Video is taller than player - crop top/bottom
      // Example: 4:3 video in 16:9 player (most common case)
      final scale = _playerSize!.width / _videoSize!.width;
      cropW = _videoSize!.width.toInt();
      cropH = (_playerSize!.height / scale).toInt();
      cropX = 0;
      cropY = ((_videoSize!.height - cropH) ~/ 2); // Center vertically
    }

    // Subtitle positioning constants
    /// MPV's subtitle coordinate system height (720p reference)
    const double kSubCoord = 720.0;

    /// Base horizontal subtitle margin to prevent edge clipping
    const double baseX = 20.0;

    /// Base vertical subtitle margin, tuned to position subtitles
    /// comfortably above the bottom while avoiding overscan areas
    const double baseY = 45.0;

    // Calculate additional margin needed due to cropping
    // When we crop, the visible area is "zoomed in", so subtitles need
    // proportionally larger margins to maintain the same visual distance from edges
    double extraX = cropX > 0
        ? (cropX / _videoSize!.width) * kSubCoord * videoAspect
        : 0.0;
    double extraY = cropY > 0 ? (cropY / _videoSize!.height) * kSubCoord : 0.0;

    // Apply additional margin (never reduce below base)
    int marginX = (baseX + extraX).round();
    int marginY = (baseY + extraY).round();

    return {
      'width': cropW,
      'height': cropH,
      'x': cropX,
      'y': cropY,
      'subMarginX': marginX,
      'subMarginY': marginY,
      'subScale': 1.0,
    };
  }

  /// Get video dimensions from the currently selected media version
  Size? _getCurrentVideoSize() {
    if (_availableVersions.isEmpty ||
        widget.selectedMediaIndex >= _availableVersions.length) {
      return null;
    }

    final currentVersion = _availableVersions[widget.selectedMediaIndex];
    if (currentVersion.width != null && currentVersion.height != null) {
      return Size(
        currentVersion.width!.toDouble(),
        currentVersion.height!.toDouble(),
      );
    }

    return null;
  }

  /// Update the video filter based on current crop mode
  void _updateVideoFilter() async {
    if (player == null) return;

    try {
      final nativePlayer = player!.platform as dynamic;

      if (_boxFitMode == 1) {
        // Fill screen mode - apply crop filter
        _videoSize = _getCurrentVideoSize();
        final cropParams = _calculateCropParameters();

        if (cropParams != null) {
          final cropFilter =
              'crop=${cropParams['width']}:${cropParams['height']}:${cropParams['x']}:${cropParams['y']}';
          appLogger.d(
            'Applying video filter: $cropFilter (player: $_playerSize, video: $_videoSize)',
          );

          // Apply crop filter
          await nativePlayer.setProperty('vf', cropFilter);

          // Apply subtitle margins and scaling to compensate for crop zoom
          final subMarginX = cropParams['subMarginX']!;
          final subMarginY = cropParams['subMarginY']!;
          final subScale = cropParams['subScale']!;

          appLogger.d(
            'Applying subtitle properties - margins: x=$subMarginX, y=$subMarginY, scale=$subScale',
          );

          await nativePlayer.setProperty('sub-margin-x', subMarginX.toString());
          await nativePlayer.setProperty('sub-margin-y', subMarginY.toString());
          await nativePlayer.setProperty('sub-scale', subScale.toString());
        } else {
          // Clear filter but apply base margins if no cropping needed
          appLogger.d(
            'Clearing video filter - aspect ratios similar, applying base margins (player: $_playerSize, video: $_videoSize)',
          );
          await nativePlayer.setProperty('vf', '');
          await nativePlayer.setProperty('sub-margin-x', '20'); // Base margin
          await nativePlayer.setProperty('sub-margin-y', '40'); // Base margin
          await nativePlayer.setProperty('sub-scale', '1.0'); // Reset scale
        }
      } else {
        // Other modes - clear video filter but apply base margins
        appLogger.d(
          'Clearing video filter, applying base margins - BoxFit mode $_boxFitMode',
        );
        await nativePlayer.setProperty('vf', '');
        await nativePlayer.setProperty('sub-margin-x', '20'); // Base margin
        await nativePlayer.setProperty('sub-margin-y', '40'); // Base margin
        await nativePlayer.setProperty('sub-scale', '1.0'); // Reset scale
      }
    } catch (e) {
      appLogger.w('Failed to update video filter', error: e);
    }
  }

  /// Debounced version of _updateVideoFilter for resize events
  void _debouncedUpdateVideoFilter() {
    _resizeDebounceTimer?.cancel();
    _resizeDebounceTimer = Timer(const Duration(milliseconds: 50), () {
      _updateVideoFilter();
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

    // Cancel debounce timer
    _resizeDebounceTimer?.cancel();

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

  /// Generic track matching for audio and subtitle tracks
  /// Returns the best matching track based on hierarchical criteria:
  /// 1. Exact match (id + title + language)
  /// 2. Partial match (title + language)
  /// 3. Language-only match
  T? _findBestTrackMatch<T>(
    List<T> availableTracks,
    T preferred,
    String Function(T) getId,
    String? Function(T) getTitle,
    String? Function(T) getLanguage,
  ) {
    if (availableTracks.isEmpty) return null;

    // Filter out auto and no tracks
    final validTracks = availableTracks
        .where((t) => getId(t) != 'auto' && getId(t) != 'no')
        .toList();
    if (validTracks.isEmpty) return null;

    final preferredId = getId(preferred);
    final preferredTitle = getTitle(preferred);
    final preferredLanguage = getLanguage(preferred);

    // Try to match: id, title, and language
    for (var track in validTracks) {
      if (getId(track) == preferredId &&
          getTitle(track) == preferredTitle &&
          getLanguage(track) == preferredLanguage) {
        return track;
      }
    }

    // Try to match: title and language
    for (var track in validTracks) {
      if (getTitle(track) == preferredTitle &&
          getLanguage(track) == preferredLanguage) {
        return track;
      }
    }

    // Try to match: language only
    for (var track in validTracks) {
      if (getLanguage(track) == preferredLanguage) {
        return track;
      }
    }

    return null;
  }

  AudioTrack? _findBestAudioMatch(
    List<AudioTrack> availableTracks,
    AudioTrack preferred,
  ) {
    return _findBestTrackMatch<AudioTrack>(
      availableTracks,
      preferred,
      (t) => t.id,
      (t) => t.title,
      (t) => t.language,
    );
  }

  AudioTrack? _findAudioTrackByProfile(
    List<AudioTrack> availableTracks,
    PlexUserProfile profile,
  ) {
    appLogger.d('Audio track selection using user profile');
    appLogger.d(
      'Profile settings - autoSelectAudio: ${profile.autoSelectAudio}, defaultAudioLanguage: ${profile.defaultAudioLanguage}, defaultAudioLanguages: ${profile.defaultAudioLanguages}',
    );

    if (availableTracks.isEmpty || !profile.autoSelectAudio) {
      appLogger.d(
        'Cannot use profile: ${availableTracks.isEmpty ? "No tracks available" : "autoSelectAudio is false"}',
      );
      return null;
    }

    // Build list of preferred languages
    final preferredLanguages = <String>[];
    if (profile.defaultAudioLanguage != null &&
        profile.defaultAudioLanguage!.isNotEmpty) {
      preferredLanguages.add(profile.defaultAudioLanguage!);
    }
    if (profile.defaultAudioLanguages != null) {
      preferredLanguages.addAll(profile.defaultAudioLanguages!);
    }

    if (preferredLanguages.isEmpty) {
      appLogger.d('Cannot use profile: No defaultAudioLanguage(s) specified');
      return null;
    }

    appLogger.d('Preferred languages: ${preferredLanguages.join(", ")}');

    // Try to find track matching any preferred language
    for (final preferredLanguage in preferredLanguages) {
      // Get all possible language code variations (e.g., "en" → ["en", "eng"])
      final languageVariations = LanguageCodes.getVariations(preferredLanguage);
      appLogger.d(
        'Checking language variations for "$preferredLanguage": ${languageVariations.join(", ")}',
      );

      for (var track in availableTracks) {
        final trackLang = track.language?.toLowerCase();
        if (trackLang != null && languageVariations.contains(trackLang)) {
          appLogger.d(
            'Found audio track matching profile language "$preferredLanguage" (matched: "$trackLang"): ${track.title ?? "Track ${track.id}"}',
          );
          return track;
        }
      }
    }

    appLogger.d(
      'No audio track found matching profile languages or their variations',
    );
    return null;
  }

  SubtitleTrack? _findBestSubtitleMatch(
    List<SubtitleTrack> availableTracks,
    SubtitleTrack preferred,
  ) {
    // Handle special "no subtitles" case
    if (preferred.id == 'no') {
      return SubtitleTrack.no();
    }

    return _findBestTrackMatch<SubtitleTrack>(
      availableTracks,
      preferred,
      (t) => t.id,
      (t) => t.title,
      (t) => t.language,
    );
  }

  SubtitleTrack? _findSubtitleTrackByProfile(
    List<SubtitleTrack> availableTracks,
    PlexUserProfile profile, {
    AudioTrack? selectedAudioTrack,
  }) {
    appLogger.d('Subtitle track selection using user profile');
    appLogger.d(
      'Profile settings - autoSelectSubtitle: ${profile.autoSelectSubtitle}, defaultSubtitleLanguage: ${profile.defaultSubtitleLanguage}, defaultSubtitleLanguages: ${profile.defaultSubtitleLanguages}, defaultSubtitleForced: ${profile.defaultSubtitleForced}, defaultSubtitleAccessibility: ${profile.defaultSubtitleAccessibility}',
    );

    if (availableTracks.isEmpty) {
      appLogger.d('Cannot use profile: No subtitle tracks available');
      return null;
    }

    // Mode 0: Manually selected - return OFF
    if (profile.autoSelectSubtitle == 0) {
      appLogger.d(
        'Profile specifies manual mode (autoSelectSubtitle=0) - Subtitles OFF',
      );
      return SubtitleTrack.no();
    }

    // Mode 1: Shown with foreign audio
    if (profile.autoSelectSubtitle == 1) {
      appLogger.d(
        'Profile specifies foreign audio mode (autoSelectSubtitle=1)',
      );

      // Check if audio language matches user's preferred subtitle language
      if (selectedAudioTrack != null &&
          profile.defaultSubtitleLanguage != null) {
        final audioLang = selectedAudioTrack.language?.toLowerCase();
        final prefLang = profile.defaultSubtitleLanguage!.toLowerCase();
        final languageVariations = LanguageCodes.getVariations(prefLang);

        appLogger.d(
          'Checking if audio is foreign - audio: $audioLang, preferred subtitle lang: $prefLang',
        );

        // If audio matches preferred language, no subtitles needed
        if (audioLang != null && languageVariations.contains(audioLang)) {
          appLogger.d('Audio matches preferred language - Subtitles OFF');
          return SubtitleTrack.no();
        }
        appLogger.d('Foreign audio detected - enabling subtitles');
      }
      // Foreign audio detected or cannot determine, enable subtitles
    }

    // Mode 2: Always enabled (or continuing from mode 1 with foreign audio)
    appLogger.d('Selecting subtitle track based on preferences');

    // Build list of preferred languages
    final preferredLanguages = <String>[];
    if (profile.defaultSubtitleLanguage != null &&
        profile.defaultSubtitleLanguage!.isNotEmpty) {
      preferredLanguages.add(profile.defaultSubtitleLanguage!);
    }
    if (profile.defaultSubtitleLanguages != null) {
      preferredLanguages.addAll(profile.defaultSubtitleLanguages!);
    }

    if (preferredLanguages.isEmpty) {
      appLogger.d(
        'Cannot use profile: No defaultSubtitleLanguage(s) specified',
      );
      return null;
    }

    appLogger.d('Preferred languages: ${preferredLanguages.join(", ")}');

    // Apply filtering based on preferences
    var candidateTracks = availableTracks;

    // Filter by SDH (defaultSubtitleAccessibility: 0-3)
    candidateTracks = _filterSubtitlesBySDH(
      candidateTracks,
      profile.defaultSubtitleAccessibility,
    );

    // Filter by forced subtitle preference (defaultSubtitleForced: 0-3)
    candidateTracks = _filterSubtitlesByForced(
      candidateTracks,
      profile.defaultSubtitleForced,
    );

    // If no candidates after filtering, relax filters
    if (candidateTracks.isEmpty) {
      appLogger.d('No tracks match strict filters, relaxing filters');
      candidateTracks = availableTracks;
    }

    // Try to find track matching any preferred language
    for (final preferredLanguage in preferredLanguages) {
      final languageVariations = LanguageCodes.getVariations(preferredLanguage);
      appLogger.d(
        'Checking language variations for "$preferredLanguage": ${languageVariations.join(", ")}',
      );

      for (var track in candidateTracks) {
        final trackLang = track.language?.toLowerCase();
        if (trackLang != null && languageVariations.contains(trackLang)) {
          appLogger.d(
            'Found subtitle matching profile language "$preferredLanguage" (matched: "$trackLang"): ${track.title ?? "Track ${track.id}"}',
          );
          return track;
        }
      }
    }

    appLogger.d(
      'No subtitle track found matching profile languages or their variations',
    );
    return null;
  }

  /// Filters subtitle tracks based on SDH (Subtitles for Deaf or Hard-of-Hearing) preference
  ///
  /// Values:
  /// - 0: Prefer non-SDH subtitles
  /// - 1: Prefer SDH subtitles
  /// - 2: Only show SDH subtitles
  /// - 3: Only show non-SDH subtitles
  List<SubtitleTrack> _filterSubtitlesBySDH(
    List<SubtitleTrack> tracks,
    int preference,
  ) {
    if (preference == 0 || preference == 1) {
      // Prefer but don't require
      final preferSDH = preference == 1;
      final preferred = tracks.where((t) => _isSDH(t) == preferSDH).toList();
      if (preferred.isNotEmpty) {
        appLogger.d(
          'Applying SDH preference: ${preferSDH ? "prefer SDH" : "prefer non-SDH"} (${preferred.length} tracks)',
        );
        return preferred;
      }
      appLogger.d('No tracks match SDH preference, using all tracks');
      return tracks;
    } else if (preference == 2) {
      // Only SDH
      final filtered = tracks.where(_isSDH).toList();
      appLogger.d('Filtering to SDH only (${filtered.length} tracks)');
      return filtered;
    } else if (preference == 3) {
      // Only non-SDH
      final filtered = tracks.where((t) => !_isSDH(t)).toList();
      appLogger.d('Filtering to non-SDH only (${filtered.length} tracks)');
      return filtered;
    }
    return tracks;
  }

  /// Filters subtitle tracks based on forced subtitle preference
  ///
  /// Values:
  /// - 0: Prefer non-forced subtitles
  /// - 1: Prefer forced subtitles
  /// - 2: Only show forced subtitles
  /// - 3: Only show non-forced subtitles
  List<SubtitleTrack> _filterSubtitlesByForced(
    List<SubtitleTrack> tracks,
    int preference,
  ) {
    if (preference == 0 || preference == 1) {
      // Prefer but don't require
      final preferForced = preference == 1;
      final preferred = tracks
          .where((t) => _isForced(t) == preferForced)
          .toList();
      if (preferred.isNotEmpty) {
        appLogger.d(
          'Applying forced preference: ${preferForced ? "prefer forced" : "prefer non-forced"} (${preferred.length} tracks)',
        );
        return preferred;
      }
      appLogger.d('No tracks match forced preference, using all tracks');
      return tracks;
    } else if (preference == 2) {
      // Only forced
      final filtered = tracks.where(_isForced).toList();
      appLogger.d('Filtering to forced only (${filtered.length} tracks)');
      return filtered;
    } else if (preference == 3) {
      // Only non-forced
      final filtered = tracks.where((t) => !_isForced(t)).toList();
      appLogger.d('Filtering to non-forced only (${filtered.length} tracks)');
      return filtered;
    }
    return tracks;
  }

  /// Checks if a subtitle track is SDH (Subtitles for Deaf or Hard-of-Hearing)
  ///
  /// Since media_kit may not expose this directly, we infer from the title
  bool _isSDH(SubtitleTrack track) {
    final title = track.title?.toLowerCase() ?? '';

    // Look for common SDH indicators
    return title.contains('sdh') ||
        title.contains('cc') ||
        title.contains('hearing impaired') ||
        title.contains('deaf');
  }

  /// Checks if a subtitle track is forced
  bool _isForced(SubtitleTrack track) {
    final title = track.title?.toLowerCase() ?? '';
    return title.contains('forced');
  }

  /// Checks if a track language matches a preferred language
  ///
  /// Handles both 2-letter (ISO 639-1) and 3-letter (ISO 639-2) codes
  /// Also handles bibliographic variants and region codes (e.g., "en-US")
  bool _languageMatches(String? trackLanguage, String? preferredLanguage) {
    if (trackLanguage == null || preferredLanguage == null) {
      return false;
    }

    final track = trackLanguage.toLowerCase();
    final preferred = preferredLanguage.toLowerCase();

    // Direct match
    if (track == preferred) return true;

    // Extract base language codes (handle region codes like "en-US")
    final trackBase = track.split('-').first;
    final preferredBase = preferred.split('-').first;

    if (trackBase == preferredBase) return true;

    // Get all variations of the preferred language (e.g., "en" → ["en", "eng"])
    final variations = LanguageCodes.getVariations(preferredBase);

    // Check if track's base code matches any variation
    return variations.contains(trackBase);
  }

  /// Log available tracks for debugging
  void _logAvailableTracks(
    List<AudioTrack> audioTracks,
    List<SubtitleTrack> subtitleTracks,
  ) {
    appLogger.d('Available audio tracks: ${audioTracks.length}');
    for (var track in audioTracks) {
      appLogger.d(
        '  - ${track.title ?? "Track ${track.id}"} (${track.language ?? "unknown"}) ${track.isDefault == true ? "[DEFAULT]" : ""}',
      );
    }
    appLogger.d('Available subtitle tracks: ${subtitleTracks.length}');
    for (var track in subtitleTracks) {
      appLogger.d(
        '  - ${track.title ?? "Track ${track.id}"} (${track.language ?? "unknown"}) ${track.isDefault == true ? "[DEFAULT]" : ""}',
      );
    }
  }

  /// Select the best audio track based on priority:
  /// Priority 1: Preferred track from navigation
  /// Priority 2: Per-media language preference
  /// Priority 3: User profile preferences
  /// Priority 4: Default or first track
  AudioTrack? _selectAudioTrack(
    List<AudioTrack> availableTracks,
    PlexUserProfile? profileSettings,
  ) {
    if (availableTracks.isEmpty) return null;

    AudioTrack? trackToSelect;

    // Priority 1: Try to match preferred track from navigation
    if (widget.preferredAudioTrack != null) {
      appLogger.d('Priority 1: Checking preferred track from navigation');
      appLogger.d(
        '  Preferred: ${widget.preferredAudioTrack!.title ?? "Track ${widget.preferredAudioTrack!.id}"} (${widget.preferredAudioTrack!.language ?? "unknown"})',
      );
      trackToSelect = _findBestAudioMatch(
        availableTracks,
        widget.preferredAudioTrack!,
      );
      if (trackToSelect != null) {
        appLogger.d('  Matched preferred track');
        return trackToSelect;
      }
      appLogger.d('  No match found for preferred track');
    } else {
      appLogger.d('Priority 1: No preferred track from navigation');
    }

    // Priority 2: If no preferred track matched, try per-media language preference
    if (widget.metadata.audioLanguage != null) {
      appLogger.d('Priority 2: Checking per-media audio language preference');
      appLogger.d(
        '  Per-media audio language: ${widget.metadata.audioLanguage}',
      );

      final matchedTrack = availableTracks.firstWhere(
        (track) =>
            _languageMatches(track.language, widget.metadata.audioLanguage),
        orElse: () => availableTracks.first,
      );

      if (_languageMatches(
        matchedTrack.language,
        widget.metadata.audioLanguage,
      )) {
        appLogger.d('  Matched per-media audio language preference');
        return matchedTrack;
      }
      appLogger.d('  No match found for per-media audio language');
    } else {
      appLogger.d('Priority 2: No per-media audio language preference');
    }

    // Priority 3: If no preferred track matched, try user profile preferences
    if (profileSettings != null) {
      appLogger.d('Priority 3: Checking user profile preferences');
      trackToSelect = _findAudioTrackByProfile(
        availableTracks,
        profileSettings,
      );
      if (trackToSelect != null) {
        return trackToSelect;
      }
    } else {
      appLogger.d('Priority 3: No user profile available');
    }

    // Priority 4: If no match, use default or first track
    appLogger.d('Priority 4: Using default or first available track');
    trackToSelect = availableTracks.firstWhere(
      (t) => t.isDefault == true,
      orElse: () => availableTracks.first,
    );
    final isDefault = trackToSelect.isDefault == true;
    appLogger.d(
      '  Selected ${isDefault ? "default" : "first"} track: ${trackToSelect.title ?? "Track ${trackToSelect.id}"} (${trackToSelect.language ?? "unknown"})',
    );

    return trackToSelect;
  }

  /// Select the best subtitle track based on priority:
  /// Priority 1: Preferred track from navigation
  /// Priority 2: Per-media language preference
  /// Priority 3: User profile preferences
  /// Priority 4: Default track
  /// Priority 5: Off
  SubtitleTrack _selectSubtitleTrack(
    List<SubtitleTrack> availableTracks,
    PlexUserProfile? profileSettings,
    AudioTrack? selectedAudioTrack,
  ) {
    SubtitleTrack? subtitleToSelect;

    // Priority 1: Try preferred track from navigation (always wins)
    if (widget.preferredSubtitleTrack != null) {
      appLogger.d('Priority 1: Checking preferred track from navigation');
      if (widget.preferredSubtitleTrack!.id == 'no') {
        appLogger.d('  Preferred: OFF');
        return SubtitleTrack.no();
      } else if (availableTracks.isNotEmpty) {
        appLogger.d(
          '  Preferred: ${widget.preferredSubtitleTrack!.title ?? "Track ${widget.preferredSubtitleTrack!.id}"} (${widget.preferredSubtitleTrack!.language ?? "unknown"})',
        );
        subtitleToSelect = _findBestSubtitleMatch(
          availableTracks,
          widget.preferredSubtitleTrack!,
        );
        if (subtitleToSelect != null) {
          appLogger.d('  Matched preferred track');
          return subtitleToSelect;
        }
        appLogger.d('  No match found for preferred track');
      }
    } else {
      appLogger.d('Priority 1: No preferred track from navigation');
    }

    // Priority 2: If no preferred match, try per-media language preference
    if (widget.metadata.subtitleLanguage != null) {
      appLogger.d(
        'Priority 2: Checking per-media subtitle language preference',
      );
      appLogger.d(
        '  Per-media subtitle language: ${widget.metadata.subtitleLanguage}',
      );

      // Check if subtitle should be disabled
      if (widget.metadata.subtitleLanguage == 'none' ||
          widget.metadata.subtitleLanguage!.isEmpty) {
        appLogger.d('  Per-media preference: Subtitles OFF');
        return SubtitleTrack.no();
      } else if (availableTracks.isNotEmpty) {
        final matchedTrack = availableTracks.firstWhere(
          (track) => _languageMatches(
            track.language,
            widget.metadata.subtitleLanguage,
          ),
          orElse: () => availableTracks.first,
        );
        if (_languageMatches(
          matchedTrack.language,
          widget.metadata.subtitleLanguage,
        )) {
          appLogger.d('  Matched per-media subtitle language preference');
          return matchedTrack;
        }
        appLogger.d('  No match found for per-media subtitle language');
      }
    } else {
      appLogger.d('Priority 2: No per-media subtitle language preference');
    }

    // Priority 3: If no preferred match, apply user profile preferences
    if (profileSettings != null && availableTracks.isNotEmpty) {
      appLogger.d('Priority 3: Checking user profile preferences');
      subtitleToSelect = _findSubtitleTrackByProfile(
        availableTracks,
        profileSettings,
        selectedAudioTrack: selectedAudioTrack,
      );
      if (subtitleToSelect != null) {
        return subtitleToSelect;
      }
    } else if (availableTracks.isNotEmpty) {
      appLogger.d('Priority 3: No user profile available');
    }

    // Priority 4: If no profile match, check for default subtitle
    if (availableTracks.isNotEmpty) {
      appLogger.d('Priority 4: Checking for default subtitle track');
      final defaultTrack = availableTracks.firstWhere(
        (t) => t.isDefault == true,
        orElse: () => availableTracks.first,
      );
      if (defaultTrack.isDefault == true) {
        appLogger.d(
          '  Found default track: ${defaultTrack.title ?? "Track ${defaultTrack.id}"} (${defaultTrack.language ?? "unknown"})',
        );
        return defaultTrack;
      }
      appLogger.d('  No default subtitle track found');
    }

    // Priority 5: If still no subtitle selected, turn off
    appLogger.d('Priority 5: No subtitle selected - Subtitles OFF');
    return SubtitleTrack.no();
  }

  void _waitForTracksAndApply() async {
    if (!mounted) return;

    // Process tracks and apply selections
    Future<void> processTracks(Tracks tracks) async {
      if (!mounted) return;

      appLogger.d('Starting track selection process');

      // Get profile settings for track selection
      final profileSettings = context.profileSettings;

      // Get real tracks (excluding auto and no)
      final realAudioTracks = tracks.audio
          .where((t) => t.id != 'auto' && t.id != 'no')
          .toList();
      final realSubtitleTracks = tracks.subtitle
          .where((t) => t.id != 'auto' && t.id != 'no')
          .toList();

      // Log available tracks
      _logAvailableTracks(realAudioTracks, realSubtitleTracks);

      // Select and apply audio track
      appLogger.d('Audio track selection');
      final selectedAudioTrack = _selectAudioTrack(
        realAudioTracks,
        profileSettings,
      );
      if (selectedAudioTrack != null) {
        appLogger.i(
          'Final audio selection: ${selectedAudioTrack.title ?? "Track ${selectedAudioTrack.id}"} (${selectedAudioTrack.language ?? "unknown"})',
        );
        player!.setAudioTrack(selectedAudioTrack);
      } else {
        appLogger.d('No audio tracks available');
      }

      // Select and apply subtitle track
      appLogger.d('Subtitle track selection');
      final selectedSubtitleTrack = _selectSubtitleTrack(
        realSubtitleTracks,
        profileSettings,
        selectedAudioTrack,
      );
      final finalSubtitle = selectedSubtitleTrack.id == 'no'
          ? 'OFF'
          : '${selectedSubtitleTrack.title ?? "Track ${selectedSubtitleTrack.id}"} (${selectedSubtitleTrack.language ?? "unknown"})';
      appLogger.i('Final subtitle selection: $finalSubtitle');
      player!.setSubtitleTrack(selectedSubtitleTrack);

      // Set playback rate if preferred rate was provided
      if (widget.preferredPlaybackRate != null) {
        appLogger.d(
          'Setting preferred playback rate: ${widget.preferredPlaybackRate}x',
        );
        player!.setRate(widget.preferredPlaybackRate!);
      }

      appLogger.d('Track selection complete');
    }

    // Check if tracks are already available in current state
    final currentTracks = player!.state.tracks;
    if (currentTracks.audio.isNotEmpty || currentTracks.subtitle.isNotEmpty) {
      await processTracks(currentTracks);
      return;
    }

    // If not, listen to tracks stream for when they become available
    bool applied = false;
    _trackLoadingSubscription = player!.stream.tracks.listen((tracks) async {
      // Check if tracks are loaded (have at least one track) and not yet applied
      if (!applied && (tracks.audio.isNotEmpty || tracks.subtitle.isNotEmpty)) {
        applied = true;
        await processTracks(tracks);
        // Cancel subscription after successful processing
        _trackLoadingSubscription?.cancel();
        _trackLoadingSubscription = null;
      }
    });

    // Cancel subscription after timeout if still waiting
    Future.delayed(const Duration(seconds: 5), () {
      if (!applied) {
        _trackLoadingSubscription?.cancel();
        _trackLoadingSubscription = null;
      }
    });
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
      if (client == null) {
        appLogger.w('No client available to save audio language preference');
        return;
      }
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
      if (client == null) {
        appLogger.w('No client available to save subtitle language preference');
        return;
      }
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
            _isPinching = false;
          },
          onScaleUpdate: (details) {
            // Track if this is a pinch gesture (2+ fingers) on mobile
            if (!isMobile) return;
            if (details.pointerCount >= 2) {
              _isPinching = true;
            }
          },
          onScaleEnd: (details) {
            // Only toggle if we detected a pinch gesture on mobile
            if (!isMobile) return;
            if (_isPinching) {
              _toggleContainCover();
              _isPinching = false;
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

                    // Check if size actually changed to avoid unnecessary updates
                    if (_playerSize == null ||
                        (_playerSize!.width - newSize.width).abs() > 0.1 ||
                        (_playerSize!.height - newSize.height).abs() > 0.1) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _playerSize = newSize;
                          });
                          // Use debounced update for resize events
                          _debouncedUpdateVideoFilter();
                        }
                      });
                    }

                    return Video(
                      controller: controller!,
                      fit: _getCurrentBoxFit,
                      controls: (state) => plexVideoControlsBuilder(
                        player!,
                        widget.metadata,
                        onNext: _nextEpisode != null ? _playNext : null,
                        onPrevious: _previousEpisode != null
                            ? _playPrevious
                            : null,
                        availableVersions: _availableVersions,
                        selectedMediaIndex: widget.selectedMediaIndex,
                        boxFitMode: _boxFitMode,
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
