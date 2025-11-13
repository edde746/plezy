import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:os_media_controls/os_media_controls.dart';
import 'package:provider/provider.dart';

import '../models/plex_media_version.dart';
import '../models/plex_metadata.dart';
import '../models/plex_user_profile.dart';
import '../providers/playback_state_provider.dart';
import '../providers/plex_client_provider.dart';
import '../providers/settings_provider.dart';
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

class VideoPlayerScreenState extends State<VideoPlayerScreen> {
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
  StreamSubscription<PlayerLog>? _logSubscription;
  StreamSubscription<String>? _errorSubscription;
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<bool>? _completedSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<dynamic>? _mediaControlSubscription;
  StreamSubscription<bool>? _bufferingSubscription;
  bool _isReplacingWithVideo =
      false; // Flag to skip orientation restoration during video-to-video navigation

  // BoxFit mode state: 0=contain (letterbox), 1=cover (fill screen), 2=fill (stretch)
  int _boxFitMode = 0;
  bool _isPinching = false; // Track if a pinch gesture is occurring
  bool _isBuffering = false; // Track if video is currently buffering

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

  Future<void> _initializePlayer() async {
    try {
      // Load buffer size from settings
      final settingsService = await SettingsService.getInstance();
      final bufferSizeMB = settingsService.getBufferSize();
      final bufferSizeBytes = bufferSizeMB * 1024 * 1024;
      final enableHardwareDecoding = settingsService
          .getEnableHardwareDecoding();
      final debugLoggingEnabled = settingsService.getEnableDebugLogging();

      // Create player with configuration
      player = Player(
        configuration: PlayerConfiguration(
          libass: true,
          libassAndroidFont: 'assets/droid-sans.ttf',
          libassAndroidFontName: 'Droid Sans Fallback',
          bufferSize: bufferSizeBytes,
          logLevel: debugLoggingEnabled ? MPVLogLevel.debug : MPVLogLevel.error,
          mpvConfiguration: {
            'sub-font-size': settingsService.getSubtitleFontSize().toString(),
            'sub-color': settingsService.getSubtitleTextColor(),
            'sub-border-size': settingsService
                .getSubtitleBorderSize()
                .toString(),
            'sub-border-color': settingsService.getSubtitleBorderColor(),
            'sub-back-color':
                '#${(settingsService.getSubtitleBackgroundOpacity() * 255 / 100).toInt().toRadixString(16).padLeft(2, '0').toUpperCase()}${settingsService.getSubtitleBackgroundColor().replaceFirst('#', '')}',
          },
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

      // Listen to position updates for media controls
      _positionSubscription = player!.stream.position.listen((_) {
        _updateMediaControlsPosition();
      });

      // Listen to buffering state
      _bufferingSubscription = player!.stream.buffering.listen((isBuffering) {
        if (mounted) {
          setState(() {
            _isBuffering = isBuffering;
          });
        }
      });

      // Initialize OS media controls
      _initializeMediaControls();

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

      final playbackState = context.read<PlaybackStateProvider>();
      final settingsProvider = context.read<SettingsProvider>();

      PlexMetadata? next;
      PlexMetadata? previous;

      // Check if shuffle mode is active
      if (playbackState.isShuffleActive) {
        // Get settings
        final shuffleOrderNavigation = settingsProvider.shuffleOrderNavigation;
        final loopQueue = settingsProvider.shuffleLoopQueue;

        if (shuffleOrderNavigation) {
          // Use shuffled order for next/previous
          next = playbackState.getNextEpisode(
            widget.metadata.ratingKey,
            loopQueue: loopQueue,
          );
          previous = playbackState.getPreviousEpisode(
            widget.metadata.ratingKey,
          );
        } else {
          // Use chronological order even in shuffle mode
          next = await client.findAdjacentEpisode(widget.metadata, 1);
          previous = await client.findAdjacentEpisode(widget.metadata, -1);
        }
      } else {
        // Use normal sequential episode loading
        next = await client.findAdjacentEpisode(widget.metadata, 1);
        previous = await client.findAdjacentEpisode(widget.metadata, -1);
      }

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
  }

  /// Toggle between contain and cover modes only (for pinch gesture)
  void _toggleContainCover() {
    setState(() {
      _boxFitMode = _boxFitMode == 0 ? 1 : 0;
    });
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

  @override
  void dispose() {
    // Stop progress tracking
    _progressTimer?.cancel();

    // Cancel stream subscriptions
    _playingSubscription?.cancel();
    _completedSubscription?.cancel();
    _logSubscription?.cancel();
    _errorSubscription?.cancel();
    _positionSubscription?.cancel();
    _mediaControlSubscription?.cancel();
    _bufferingSubscription?.cancel();

    // Clear OS media controls completely
    OsMediaControls.clear();

    // Send final stopped state
    _sendProgress('stopped');

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
        // Get the currently selected audio track
        final currentAudioTrack = realAudioTracks.firstWhere(
          (t) => t.id == player!.state.track.audio.id,
          orElse: () => realAudioTracks.first,
        );
        subtitleToSelect = _findSubtitleTrackByProfile(
          realSubtitleTracks,
          profileSettings,
          selectedAudioTrack: currentAudioTrack,
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

    // Update OS media controls playback state
    _updateMediaControlsPlaybackState();
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

  void _initializeMediaControls() async {
    // Listen to media control events
    _mediaControlSubscription = OsMediaControls.controlEvents.listen((event) {
      if (event is PlayEvent) {
        player?.play();
      } else if (event is PauseEvent) {
        player?.pause();
      } else if (event is SeekEvent) {
        player?.seek(event.position);
      } else if (event is NextTrackEvent) {
        if (_nextEpisode != null) {
          _playNext();
        }
      } else if (event is PreviousTrackEvent) {
        if (_previousEpisode != null) {
          _playPrevious();
        }
      }
    });

    // Enable/disable next/previous track controls based on content type
    final isEpisode = widget.metadata.type.toLowerCase() == 'episode';
    if (isEpisode) {
      // Enable next/previous track controls for episodes
      await OsMediaControls.enableControls([
        MediaControl.next,
        MediaControl.previous,
      ]);
    } else {
      // Disable next/previous track controls for movies
      await OsMediaControls.disableControls([
        MediaControl.next,
        MediaControl.previous,
      ]);
    }

    // Set initial metadata
    await _updateMediaMetadata();
  }

  Future<void> _updateMediaMetadata() async {
    if (!mounted) {
      appLogger.w('Cannot update media metadata: widget not mounted');
      return;
    }

    final metadata = widget.metadata;
    final clientProvider = context.plexClient;
    final client = clientProvider.client;

    // Get artwork URL
    String? artworkUrl;
    if (client == null) {
      appLogger.w(
        'Cannot get artwork URL for media controls: Plex client is null',
      );
    } else {
      final thumbUrl = metadata.type.toLowerCase() == 'episode'
          ? metadata.grandparentThumb ?? metadata.thumb
          : metadata.thumb;

      if (thumbUrl != null) {
        try {
          artworkUrl = client.getThumbnailUrl(thumbUrl);
          appLogger.d('Artwork URL for media controls: $artworkUrl');
        } catch (e) {
          appLogger.w('Failed to get artwork URL for media controls', error: e);
        }
      } else {
        appLogger.d('No thumbnail URL available for media controls');
      }
    }

    // Build title/artist based on content type
    String title = metadata.title;
    String? artist;
    String? album;

    if (metadata.type.toLowerCase() == 'episode') {
      title = metadata.title;
      artist = metadata.grandparentTitle; // Show name
      if (metadata.parentIndex != null) {
        album = 'Season ${metadata.parentIndex}';
      }
    }

    await OsMediaControls.setMetadata(
      MediaMetadata(
        title: title,
        artist: artist,
        album: album,
        duration: metadata.duration != null
            ? Duration(milliseconds: metadata.duration!)
            : null,
        artworkUrl: artworkUrl,
      ),
    );

    // Set initial playback state
    _updateMediaControlsPlaybackState();
  }

  void _updateMediaControlsPlaybackState() {
    if (player == null) return;

    OsMediaControls.setPlaybackState(
      MediaPlaybackState(
        state: player!.state.playing
            ? PlaybackState.playing
            : PlaybackState.paused,
        position: player!.state.position,
        speed: player!.state.rate,
      ),
    );
  }

  void _updateMediaControlsPosition() {
    if (player == null) return;

    // Only update if playing to avoid excessive updates
    if (player!.state.playing) {
      OsMediaControls.setPlaybackState(
        MediaPlaybackState(
          state: PlaybackState.playing,
          position: player!.state.position,
          speed: player!.state.rate,
        ),
      );
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
        body: GestureDetector(
          behavior: HitTestBehavior
              .translucent, // Allow taps to pass through to controls
          onScaleStart: (details) {
            // Initialize pinch gesture tracking (mobile only)
            if (!PlatformDetector.isMobile(context)) return;
            _isPinching = false;
          },
          onScaleUpdate: (details) {
            // Track if this is a pinch gesture (2+ fingers) on mobile
            if (!PlatformDetector.isMobile(context)) return;
            if (details.pointerCount >= 2) {
              _isPinching = true;
            }
          },
          onScaleEnd: (details) {
            // Only toggle if we detected a pinch gesture on mobile
            if (!PlatformDetector.isMobile(context)) return;
            if (_isPinching) {
              _toggleContainCover();
              _isPinching = false;
            }
          },
          child: Stack(
            children: [
              // Video player
              Center(
                child: Video(
                  controller: controller!,
                  fit: _getCurrentBoxFit,
                  controls: (state) => plexVideoControlsBuilder(
                    player!,
                    widget.metadata,
                    onNext: _nextEpisode != null ? _playNext : null,
                    onPrevious: _previousEpisode != null ? _playPrevious : null,
                    availableVersions: _availableVersions,
                    selectedMediaIndex: widget.selectedMediaIndex,
                    boxFitMode: _boxFitMode,
                    onCycleBoxFitMode: _cycleBoxFitMode,
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
              if (_isBuffering)
                Positioned.fill(
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
                ),
            ],
          ),
        ),
      ),
    );
  }
}
