import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models/plex_metadata.dart';
import '../models/plex_user_profile.dart';
import '../providers/plex_client_provider.dart';
import '../utils/provider_extensions.dart';
import '../widgets/plex_video_controls.dart';
import '../utils/language_codes.dart';
import '../utils/app_logger.dart';
import '../services/settings_service.dart';
import '../utils/orientation_helper.dart';
import '../utils/video_player_navigation.dart';
import '../utils/platform_detector.dart';
import '../models/plex_media_version.dart';

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
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  Player? player;
  VideoController? controller;
  bool _isPlayerInitialized = false;
  Timer? _progressTimer;
  PlexMetadata? _nextEpisode;
  PlexMetadata? _previousEpisode;
  bool _isLoadingNext = false;
  bool _showPlayNextDialog = false;
  PlexClientProvider? _cachedClientProvider;
  bool _isPhone = false;
  List<PlexMediaVersion> _availableVersions = [];

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

    // Initialize player asynchronously with buffer size from settings
    _initializePlayer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Cache provider reference for safe access in dispose()
    try {
      _cachedClientProvider = context.plexClient;
    } catch (e) {
      appLogger.w('Failed to cache PlexClientProvider', error: e);
      _cachedClientProvider = null;
    }

    // Cache device type for safe access in dispose()
    try {
      _isPhone = PlatformDetector.isPhone(context);
    } catch (e) {
      appLogger.w('Failed to determine device type', error: e);
      _isPhone = false; // Default to tablet/desktop (all orientations)
    }
  }

  void _setLandscapeOrientation() {
    OrientationHelper.setLandscapeOrientation();
  }

  Future<void> _initializePlayer() async {
    try {
      // Load buffer size from settings
      final settingsService = await SettingsService.getInstance();
      final bufferSizeMB = settingsService.getBufferSize();
      final bufferSizeBytes = bufferSizeMB * 1024 * 1024;

      // Create player with configuration
      player = Player(
        configuration: PlayerConfiguration(
          libass: true,
          libassAndroidFont: 'assets/droid-sans.ttf',
          libassAndroidFontName: 'Droid Sans Fallback',
          bufferSize: bufferSizeBytes,
        ),
      );
      controller = VideoController(player!);

      // Notify that player is ready
      if (mounted) {
        setState(() {
          _isPlayerInitialized = true;
        });
      }

      // Get the video URL and start playback
      _startPlayback();

      // Load available media versions
      _loadMediaVersions();

      // Set fullscreen mode and landscape orientation
      if (mounted) {
        try {
          _setLandscapeOrientation();
        } catch (e) {
          appLogger.w('Failed to set landscape orientation', error: e);
          // Don't crash if orientation fails - video can still play
        }
      }

      // Listen to playback state changes
      player!.stream.playing.listen(_onPlayingStateChanged);

      // Listen to completion
      player!.stream.completed.listen(_onVideoCompleted);

      // Start periodic progress updates
      _startProgressTracking();

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

  Future<void> _loadAdjacentEpisodes() async {
    if (widget.metadata.type.toLowerCase() != 'episode') {
      return;
    }

    try {
      final clientProvider = context.plexClient;
      final client = clientProvider.client;
      if (client == null) return;

      final next = await client.findAdjacentEpisode(widget.metadata, 1);
      final previous = await client.findAdjacentEpisode(widget.metadata, -1);

      if (mounted) {
        setState(() {
          _nextEpisode = next;
          _previousEpisode = previous;
        });
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  Future<void> _startPlayback() async {
    try {
      final clientProvider = context.plexClient;
      final client = clientProvider.client;
      if (client == null) {
        throw Exception('No client available');
      }

      // Get the direct file URL from the server using the selected media index
      final videoUrl = await client.getVideoUrl(
        widget.metadata.ratingKey,
        mediaIndex: widget.selectedMediaIndex,
      );

      if (videoUrl != null) {
        // Open video without auto-playing
        await player!.open(Media(videoUrl), play: false);

        // Wait for media to be ready (duration > 0)
        int attempts = 0;
        while (player!.state.duration.inMilliseconds == 0 && attempts < 100) {
          await Future.delayed(const Duration(milliseconds: 100));
          attempts++;
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
            const SnackBar(content: Text('Could not find video file')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  /// Load available media versions for this item
  Future<void> _loadMediaVersions() async {
    try {
      final clientProvider = context.plexClient;
      final client = clientProvider.client;
      if (client == null) return;

      final versions = await client.getMediaVersions(widget.metadata.ratingKey);
      if (mounted) {
        setState(() {
          _availableVersions = versions;
        });
      }
    } catch (e) {
      appLogger.e('Error loading media versions: $e');
    }
  }

  @override
  void dispose() {
    // Stop progress tracking
    _progressTimer?.cancel();

    // Send final stopped state
    _sendProgress('stopped');

    // Restore system UI and orientation preferences
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

    player?.dispose();
    super.dispose();
  }

  void _startProgressTracking() {
    // Send progress update every 10 seconds
    _progressTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (player?.state.playing ?? false) {
        _sendProgress('playing');
      }
    });
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
      'Profile settings - autoSelectAudio: ${profile.autoSelectAudio}, defaultAudioLanguage: ${profile.defaultAudioLanguage}',
    );

    if (availableTracks.isEmpty || !profile.autoSelectAudio) {
      appLogger.d(
        'Cannot use profile: ${availableTracks.isEmpty ? "No tracks available" : "autoSelectAudio is false"}',
      );
      return null;
    }

    final preferredLanguage = profile.defaultAudioLanguage;
    if (preferredLanguage == null || preferredLanguage.isEmpty) {
      appLogger.d('Cannot use profile: No defaultAudioLanguage specified');
      return null;
    }

    // Get all possible language code variations (e.g., "en" → ["en", "eng"])
    final languageVariations = LanguageCodes.getVariations(preferredLanguage);
    appLogger.d(
      'Checking language variations: ${languageVariations.join(", ")}',
    );

    // Try to find track matching any language variation
    for (var track in availableTracks) {
      final trackLang = track.language?.toLowerCase();
      if (trackLang != null && languageVariations.contains(trackLang)) {
        appLogger.d(
          'Found audio track matching profile language "$preferredLanguage" (matched: "$trackLang"): ${track.title ?? "Track ${track.id}"}',
        );
        return track;
      }
    }

    appLogger.d(
      'No audio track found matching profile language "$preferredLanguage" or its variations',
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
    PlexUserProfile profile,
  ) {
    appLogger.d('Subtitle track selection using user profile');
    appLogger.d(
      'Profile settings - autoSelectSubtitle: ${profile.autoSelectSubtitle}, defaultSubtitleLanguage: ${profile.defaultSubtitleLanguage}, defaultSubtitleForced: ${profile.defaultSubtitleForced}',
    );

    if (availableTracks.isEmpty) {
      appLogger.d('Cannot use profile: No subtitle tracks available');
      return null;
    }

    // If autoSelectSubtitle is 0, don't select any subtitle
    if (!profile.shouldAutoSelectSubtitle) {
      appLogger.d(
        'Profile specifies no auto-select (autoSelectSubtitle=0) - Subtitles OFF',
      );
      return SubtitleTrack.no();
    }

    final preferredLanguage = profile.defaultSubtitleLanguage;
    if (preferredLanguage == null || preferredLanguage.isEmpty) {
      appLogger.d('Cannot use profile: No defaultSubtitleLanguage specified');
      return null;
    }

    // Get all possible language code variations (e.g., "en" → ["en", "eng"])
    final languageVariations = LanguageCodes.getVariations(preferredLanguage);
    appLogger.d(
      'Checking language variations: ${languageVariations.join(", ")}',
    );

    // If defaultSubtitleForced is 1, prefer forced subtitles
    if (profile.preferForcedSubtitles) {
      appLogger.d('Profile prefers forced subtitles (defaultSubtitleForced=1)');
      // Try to find forced subtitle in preferred language
      for (var track in availableTracks) {
        final trackLang = track.language?.toLowerCase();
        if (trackLang != null &&
            languageVariations.contains(trackLang) &&
            track.title?.toLowerCase().contains('forced') == true) {
          appLogger.d(
            'Found forced subtitle matching profile language "$preferredLanguage" (matched: "$trackLang"): ${track.title ?? "Track ${track.id}"}',
          );
          return track;
        }
      }
      appLogger.d(
        'No forced subtitle found in "$preferredLanguage" or its variations, trying regular subtitles',
      );
    }

    // Try to find regular subtitle in preferred language
    for (var track in availableTracks) {
      final trackLang = track.language?.toLowerCase();
      if (trackLang != null && languageVariations.contains(trackLang)) {
        appLogger.d(
          'Found subtitle matching profile language "$preferredLanguage" (matched: "$trackLang"): ${track.title ?? "Track ${track.id}"}',
        );
        return track;
      }
    }

    appLogger.d(
      'No subtitle track found matching profile language "$preferredLanguage" or its variations',
    );
    return null;
  }

  void _waitForTracksAndApply() async {
    // Helper function to process tracks
    Future<void> processTracks(Tracks tracks) async {
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

      appLogger.d('Available audio tracks: ${realAudioTracks.length}');
      for (var track in realAudioTracks) {
        appLogger.d(
          '  - ${track.title ?? "Track ${track.id}"} (${track.language ?? "unknown"}) ${track.isDefault == true ? "[DEFAULT]" : ""}',
        );
      }
      appLogger.d('Available subtitle tracks: ${realSubtitleTracks.length}');
      for (var track in realSubtitleTracks) {
        appLogger.d(
          '  - ${track.title ?? "Track ${track.id}"} (${track.language ?? "unknown"}) ${track.isDefault == true ? "[DEFAULT]" : ""}',
        );
      }

      // Select audio track with priority: preferred > user profile > default > first
      appLogger.d('Audio track selection');
      if (realAudioTracks.isNotEmpty) {
        AudioTrack? trackToSelect;

        // Priority 1: Try to match preferred track from navigation
        if (widget.preferredAudioTrack != null) {
          appLogger.d('Priority 1: Checking preferred track from navigation');
          appLogger.d(
            '  Preferred: ${widget.preferredAudioTrack!.title ?? "Track ${widget.preferredAudioTrack!.id}"} (${widget.preferredAudioTrack!.language ?? "unknown"})',
          );
          trackToSelect = _findBestAudioMatch(
            realAudioTracks,
            widget.preferredAudioTrack!,
          );
          if (trackToSelect != null) {
            appLogger.d('  Matched preferred track');
          } else {
            appLogger.d('  No match found for preferred track');
          }
        } else {
          appLogger.d('Priority 1: No preferred track from navigation');
        }

        // Priority 2: If no preferred track matched, try user profile preferences
        if (trackToSelect == null && profileSettings != null) {
          appLogger.d('Priority 2: Checking user profile preferences');
          trackToSelect = _findAudioTrackByProfile(
            realAudioTracks,
            profileSettings,
          );
        } else if (trackToSelect == null) {
          appLogger.d('Priority 2: No user profile available');
        }

        // Priority 3: If no match, use default or first track
        if (trackToSelect == null) {
          appLogger.d('Priority 3: Using default or first available track');
          trackToSelect = realAudioTracks.firstWhere(
            (t) => t.isDefault == true,
            orElse: () => realAudioTracks.first,
          );
          final isDefault = trackToSelect.isDefault == true;
          appLogger.d(
            '  Selected ${isDefault ? "default" : "first"} track: ${trackToSelect.title ?? "Track ${trackToSelect.id}"} (${trackToSelect.language ?? "unknown"})',
          );
        }

        appLogger.i(
          'Final audio selection: ${trackToSelect.title ?? "Track ${trackToSelect.id}"} (${trackToSelect.language ?? "unknown"})',
        );
        player!.setAudioTrack(trackToSelect);
      } else {
        appLogger.d('No audio tracks available');
      }

      // Select subtitle track with priority: preferred > user profile > default > off
      appLogger.d('Subtitle track selection');
      SubtitleTrack? subtitleToSelect;

      // Priority 1: Try preferred track from navigation (always wins)
      if (widget.preferredSubtitleTrack != null) {
        appLogger.d('Priority 1: Checking preferred track from navigation');
        if (widget.preferredSubtitleTrack!.id == 'no') {
          appLogger.d('  Preferred: OFF');
          subtitleToSelect = SubtitleTrack.no();
          appLogger.d('  Using preferred setting: Subtitles OFF');
        } else if (realSubtitleTracks.isNotEmpty) {
          appLogger.d(
            '  Preferred: ${widget.preferredSubtitleTrack!.title ?? "Track ${widget.preferredSubtitleTrack!.id}"} (${widget.preferredSubtitleTrack!.language ?? "unknown"})',
          );
          subtitleToSelect = _findBestSubtitleMatch(
            realSubtitleTracks,
            widget.preferredSubtitleTrack!,
          );
          if (subtitleToSelect != null) {
            appLogger.d('  Matched preferred track');
          } else {
            appLogger.d('  No match found for preferred track');
          }
        }
      } else {
        appLogger.d('Priority 1: No preferred track from navigation');
      }

      // Priority 2: If no preferred match, apply user profile preferences
      if (subtitleToSelect == null &&
          profileSettings != null &&
          realSubtitleTracks.isNotEmpty) {
        appLogger.d('Priority 2: Checking user profile preferences');
        subtitleToSelect = _findSubtitleTrackByProfile(
          realSubtitleTracks,
          profileSettings,
        );
      } else if (subtitleToSelect == null && realSubtitleTracks.isNotEmpty) {
        appLogger.d('Priority 2: No user profile available');
      }

      // Priority 3: If no profile match, check for default subtitle
      if (subtitleToSelect == null && realSubtitleTracks.isNotEmpty) {
        appLogger.d('Priority 3: Checking for default subtitle track');
        final defaultTrackIndex = realSubtitleTracks.indexWhere(
          (t) => t.isDefault == true,
        );
        if (defaultTrackIndex != -1) {
          subtitleToSelect = realSubtitleTracks[defaultTrackIndex];
          appLogger.d(
            '  Found default track: ${subtitleToSelect.title ?? "Track ${subtitleToSelect.id}"} (${subtitleToSelect.language ?? "unknown"})',
          );
        } else {
          appLogger.d('  No default subtitle track found');
        }
      }

      // If still no subtitle selected, turn off
      if (subtitleToSelect == null) {
        appLogger.d('Priority 4: No subtitle selected - Subtitles OFF');
        subtitleToSelect = SubtitleTrack.no();
      }

      final finalSubtitle = subtitleToSelect.id == 'no'
          ? 'OFF'
          : '${subtitleToSelect.title ?? "Track ${subtitleToSelect.id}"} (${subtitleToSelect.language ?? "unknown"})';
      appLogger.i('Final subtitle selection: $finalSubtitle');
      player!.setSubtitleTrack(subtitleToSelect);

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
    final subscription = player!.stream.tracks.listen((tracks) async {
      // Check if tracks are loaded (have at least one track) and not yet applied
      if (!applied && (tracks.audio.isNotEmpty || tracks.subtitle.isNotEmpty)) {
        applied = true;
        await processTracks(tracks);
      }
    });

    // Cancel subscription after timeout
    Future.delayed(const Duration(seconds: 5), () {
      subscription.cancel();
    });
  }

  void _onPlayingStateChanged(bool isPlaying) {
    // Send timeline update when playback state changes
    _sendProgress(isPlaying ? 'playing' : 'paused');
  }

  void _sendProgress(String state) {
    // Don't send misleading data if player isn't available
    if (player == null) return;

    final position = player!.state.position.inMilliseconds;
    final duration = player!.state.duration.inMilliseconds;

    if (duration > 0) {
      final clientProvider = _cachedClientProvider;
      final client = clientProvider?.client;
      if (client == null) return;

      client
          .updateProgress(
            widget.metadata.ratingKey,
            time: position,
            state: state,
            duration: duration,
          )
          .catchError((error) {
            // Silently handle errors - don't interrupt playback
          });
    }
  }

  void _onVideoCompleted(bool completed) {
    if (completed && _nextEpisode != null && !_showPlayNextDialog) {
      setState(() {
        _showPlayNextDialog = true;
      });
    }
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

  /// Navigates to a new episode, preserving playback state and track selections
  Future<void> _navigateToEpisode(PlexMetadata episodeMetadata) async {
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

    // Capture current track selection BEFORE pausing
    final currentAudioTrack = player!.state.track.audio;
    final currentSubtitleTrack = player!.state.track.subtitle;

    // Pause and stop current playback
    player!.pause();
    _progressTimer?.cancel();
    _sendProgress('stopped');

    // Navigate to the episode using pushReplacement to destroy current player
    if (mounted) {
      final currentRate = player!.state.rate;
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
        body: Stack(
          children: [
            // Video player
            Center(
              child: Video(
                controller: controller!,
                controls: (state) => plexVideoControlsBuilder(
                  player!,
                  widget.metadata,
                  onNext: _nextEpisode != null ? _playNext : null,
                  onPrevious: _previousEpisode != null ? _playPrevious : null,
                  availableVersions: _availableVersions,
                  selectedMediaIndex: widget.selectedMediaIndex,
                ),
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
                          const Text(
                            'Up Next',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
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
                                child: const Text('Cancel'),
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
                                child: const Text('Play Now'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
