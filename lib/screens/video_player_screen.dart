import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/services.dart';
import 'package:os_media_controls/os_media_controls.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../mpv/mpv.dart';

import '../../services/plex_client.dart';
import '../services/plex_api_cache.dart';
import '../models/plex_media_version.dart';
import '../models/plex_metadata.dart';
import '../utils/content_utils.dart';
import '../models/plex_media_info.dart';
import '../providers/download_provider.dart';
import '../providers/multi_server_provider.dart';
import '../providers/playback_state_provider.dart';
import '../services/episode_navigation_service.dart';
import '../services/media_controls_manager.dart';
import '../services/playback_initialization_service.dart';
import '../services/playback_progress_tracker.dart';
import '../services/offline_watch_sync_service.dart';
import '../services/settings_service.dart';
import '../services/track_selection_service.dart';
import '../services/video_filter_manager.dart';
import '../providers/user_profile_provider.dart';
import '../utils/app_logger.dart';
import '../utils/orientation_helper.dart';
import '../utils/platform_detector.dart';
import '../utils/provider_extensions.dart';
import '../utils/language_codes.dart';
import '../utils/snackbar_helper.dart';
import '../utils/video_player_navigation.dart';
import '../widgets/video_controls/video_controls.dart';
import '../i18n/strings.g.dart';
import '../watch_together/providers/watch_together_provider.dart';

class VideoPlayerScreen extends StatefulWidget {
  final PlexMetadata metadata;
  final AudioTrack? preferredAudioTrack;
  final SubtitleTrack? preferredSubtitleTrack;
  final double? preferredPlaybackRate;
  final int selectedMediaIndex;
  final bool isOffline;

  const VideoPlayerScreen({
    super.key,
    required this.metadata,
    this.preferredAudioTrack,
    this.preferredSubtitleTrack,
    this.preferredPlaybackRate,
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
  StreamSubscription<PlayerLog>? _logSubscription;
  StreamSubscription<String>? _errorSubscription;
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<bool>? _completedSubscription;
  StreamSubscription<dynamic>? _mediaControlSubscription;
  StreamSubscription<bool>? _bufferingSubscription;
  StreamSubscription<Tracks>? _trackLoadingSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<void>? _playbackRestartSubscription;
  bool _isReplacingWithVideo = false; // Flag to skip orientation restoration during video-to-video navigation
  bool _isDisposingForNavigation = false;

  // Auto-play next episode
  Timer? _autoPlayTimer;
  int _autoPlayCountdown = 5;
  bool _completionTriggered = false;

  // App lifecycle state tracking
  bool _wasPlayingBeforeInactive = false;

  // Services
  MediaControlsManager? _mediaControlsManager;
  PlaybackProgressTracker? _progressTracker;
  VideoFilterManager? _videoFilterManager;
  final EpisodeNavigationService _episodeNavigation = EpisodeNavigationService();

  // Watch Together provider reference (stored early to use in dispose)
  WatchTogetherProvider? _watchTogetherProvider;

  /// Get the correct PlexClient for this metadata's server
  PlexClient _getClientForMetadata(BuildContext context) {
    return context.getClientForServer(widget.metadata.serverId!);
  }

  final ValueNotifier<bool> _isBuffering = ValueNotifier<bool>(false); // Track if video is currently buffering
  final ValueNotifier<bool> _hasFirstFrame = ValueNotifier<bool>(false); // Track if first video frame has rendered
  final ValueNotifier<bool> _isExiting = ValueNotifier<bool>(false); // Track if navigating away (for black overlay)

  @override
  void initState() {
    super.initState();

    _activeRatingKey = widget.metadata.ratingKey;
    _activeMediaIndex = widget.selectedMediaIndex;

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

      // Create player
      player = Player();

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

      // Listen to MPV logs
      _logSubscription = player!.streams.log.listen(_onPlayerLog);

      // Listen to MPV errors
      _errorSubscription = player!.streams.error.listen(_onPlayerError);

      // Listen to buffering state
      _bufferingSubscription = player!.streams.buffering.listen((isBuffering) {
        _isBuffering.value = isBuffering;
      });

      // Listen to playback restart to detect first frame ready
      _playbackRestartSubscription = player!.streams.playbackRestart.listen((_) {
        if (!_hasFirstFrame.value) {
          _hasFirstFrame.value = true;
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

  /// Add external subtitle tracks to the player
  Future<void> _addExternalSubtitles(List<SubtitleTrack> externalSubtitles) async {
    if (player == null || externalSubtitles.isEmpty) return;

    appLogger.d('Adding ${externalSubtitles.length} external subtitle(s) to player');

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
        appLogger.d('Added external subtitle: ${subtitleTrack.title ?? subtitleTrack.uri}');
      } catch (e) {
        appLogger.w('Failed to add external subtitle: ${subtitleTrack.title ?? subtitleTrack.uri}', error: e);
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

    // Skip loading adjacent episodes in offline mode (requires server connection)
    if (widget.isOffline) return;

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
      PlaybackInitializationResult result;

      if (widget.isOffline) {
        // Offline mode: get video path from downloads without requiring server
        result = await _startOfflinePlayback();
      } else {
        // Online mode: use server-specific client
        final client = _getClientForMetadata(context);
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

        // Pass resume position if available
        final resumePosition = widget.metadata.viewOffset != null
            ? Duration(milliseconds: widget.metadata.viewOffset!)
            : null;
        await player!.open(Media(result.videoUrl!, start: resumePosition));

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
        });

        // Initialize video filter manager with player and available versions
        if (player != null) {
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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
      videoUrl: 'file://$videoPath',
      mediaInfo: null,
      externalSubtitles: const [],
      isOffline: true,
    );
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

  /// Handle back button press
  /// For non-host participants in Watch Together, shows leave session confirmation
  Future<void> _handleBackButton() async {
    // For non-host participants, show leave session confirmation
    if (_watchTogetherProvider != null && _watchTogetherProvider!.isInSession && !_watchTogetherProvider!.isHost) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Leave Session?'),
          content: const Text('You will be removed from the session.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: Theme.of(dialogContext).colorScheme.error),
              child: const Text('Leave'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        await _watchTogetherProvider!.leaveSession();
        if (mounted) {
          _isExiting.value = true;
          Navigator.of(context).pop(true);
        }
      }
      return;
    }

    // Default behavior for hosts or non-session users
    _isExiting.value = true;
    Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    // Unregister app lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

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
    _positionSubscription?.cancel();
    _playbackRestartSubscription?.cancel();

    // Cancel auto-play timer
    _autoPlayTimer?.cancel();

    // Clear media controls and dispose manager
    _mediaControlsManager?.clear();
    _mediaControlsManager?.dispose();

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
  }

  void _onVideoCompleted(bool completed) {
    if (completed && _nextEpisode != null && !_showPlayNextDialog && !_completionTriggered) {
      _completionTriggered = true;

      // On Linux, show the Flutter layer so the overlay is visible
      if (Platform.isLinux) {
        player?.setControlsVisible(true);
      }

      setState(() {
        _showPlayNextDialog = true;
        _autoPlayCountdown = 5;
      });
      _startAutoPlayTimer();
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
    final trackService = TrackSelectionService(
      player: player!,
      profileSettings: profileSettings,
      metadata: widget.metadata,
      plexMediaInfo: _currentMediaInfo,
    );

    await trackService.selectAndApplyTracks(
      preferredAudioTrack: widget.preferredAudioTrack,
      preferredSubtitleTrack: widget.preferredSubtitleTrack,
      preferredPlaybackRate: widget.preferredPlaybackRate,
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
      appLogger.w('Could not match audio track, using fallback index');
      // Fallback - normally no offset for audio
      try {
        final trackIndex = int.parse(track.id);

        if (trackIndex >= 0 && trackIndex < _currentMediaInfo!.audioTracks.length) {
          streamID = _currentMediaInfo!.audioTracks[trackIndex].id;
          appLogger.d('Using fallback: audio index $trackIndex -> streamID $streamID');
        } else {
          appLogger.e('Fallback index $trackIndex out of bounds (total: ${_currentMediaInfo!.audioTracks.length})');
        }
      } catch (e) {
        appLogger.e('Failed to parse track index', error: e);
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
        appLogger.w('Could not match subtitle track, using fallback index');
        // Fallback with offset correction
        try {
          final trackIndex = int.parse(track.id);

          // media kit has a "no" (off) at index 0, so real subtitles start at 1
          // We need to subtract 1 to get the actual index in PlexMediaInfo
          final plexIndex = trackIndex > 0 ? trackIndex - 1 : 0;

          if (plexIndex >= 0 && plexIndex < _currentMediaInfo!.subtitleTracks.length) {
            streamID = _currentMediaInfo!.subtitleTracks[plexIndex].id;
            appLogger.d('Using fallback: media_kit index $trackIndex -> Plex index $plexIndex -> streamID $streamID');
          } else {
            appLogger.e('Fallback index $plexIndex out of bounds (total: ${_currentMediaInfo!.subtitleTracks.length})');
          }
        } catch (e) {
          appLogger.e('Failed to parse track index', error: e);
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

    // If player isn't available, navigate without preserving settings
    if (player == null) {
      if (mounted) {
        navigateToVideoPlayer(context, metadata: episodeMetadata, usePushReplacement: true);
      }
      return;
    }

    // Capture current state atomically to avoid race conditions
    final currentPlayer = player;
    if (currentPlayer == null) {
      // Player already disposed, navigate without preserving settings
      if (mounted) {
        navigateToVideoPlayer(context, metadata: episodeMetadata, usePushReplacement: true);
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
    _isExiting.value = true; // Show black overlay during transition

    try {
      _detachFromWatchTogetherSession();
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
      canPop: false, // Disable swipe-back gesture to prevent interference with timeline scrubbing
      onPopInvokedWithResult: (didPop, result) {
        // Allow programmatic back navigation from UI controls
        if (!didPop) _handleBackButton();
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

                    // Update player size in video filter manager and native layer
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && player != null) {
                        _videoFilterManager?.updatePlayerSize(newSize);
                        // Update Metal layer frame on iOS/macOS for rotation
                        player!.updateFrame();
                      }
                    });

                    // Compute canControl from Watch Together provider
                    bool canControl = true;
                    try {
                      final watchTogether = this.context.read<WatchTogetherProvider>();
                      if (watchTogether.isInSession) {
                        canControl = watchTogether.canControl();
                      }
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
                      ),
                    );
                  },
                ),
              ),
              // Netflix-style auto-play overlay
              if (_showPlayNextDialog && _nextEpisode != null)
                Positioned(
                  right: 24,
                  bottom: 100,
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
                              child: OutlinedButton(
                                onPressed: _cancelAutoPlay,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: Text(t.dialog.cancel),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
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
                                    Text('$_autoPlayCountdown'),
                                    const SizedBox(width: 4),
                                    const AppIcon(Symbols.play_arrow_rounded, fill: 1, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              // Buffering indicator (also shows during initial load, but not when exiting)
              ValueListenableBuilder<bool>(
                valueListenable: _isBuffering,
                builder: (context, isBuffering, child) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: _hasFirstFrame,
                    builder: (context, hasFrame, child) {
                      // Don't show spinner when exiting (just black overlay)
                      // Show spinner when (buffering OR loading) AND NOT exiting
                      if ((!isBuffering && hasFrame) || _isExiting.value) return const SizedBox.shrink();
                      return Positioned.fill(
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
                      );
                    },
                  );
                },
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
    return 'auto-safe';
  } else {
    return 'auto'; // Windows, Linux
  }
}
