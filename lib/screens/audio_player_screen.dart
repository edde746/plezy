import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../mpv/mpv.dart';
import 'package:os_media_controls/os_media_controls.dart';

import 'package:provider/provider.dart';
import '../services/plex_client.dart';
import '../models/plex_metadata.dart';
import '../models/plex_media_info.dart';
import '../models/plex_library.dart';
import '../providers/multi_server_provider.dart';
import '../services/audio_playback_initialization_service.dart';
import '../services/media_controls_manager.dart';
import '../services/playback_progress_tracker.dart';
import '../services/settings_service.dart';
import '../utils/app_logger.dart';
import '../utils/provider_extensions.dart';
import '../utils/formatters.dart' show formatDurationTimestamp;
import '../widgets/desktop_app_bar.dart';
import '../focus/key_event_utils.dart';
import '../widgets/video_controls/icons.dart';

class AudioPlayerScreen extends StatefulWidget {
  final PlexMetadata metadata;
  final List<PlexMetadata>? queue;
  final int startIndex;

  const AudioPlayerScreen({
    super.key,
    required this.metadata,
    this.queue,
    this.startIndex = 0,
  });

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen>
    with WidgetsBindingObserver {
  Player? player;
  bool _isPlayerInitialized = false;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 100.0;
  PlexMetadata? _fullMetadata;
  bool _isLoadingMetadata = true;
  List<PlexChapter> _chapters = [];
  bool _chaptersLoaded = false;
  PlexMediaInfo? _mediaInfo;
  PlexLibrary? _sourceLibrary; // Cache the library this track belongs to

  // Queue support
  late List<PlexMetadata> _queue;
  late int _currentIndex;

  PlexMetadata get _currentMetadata => _queue[_currentIndex];
  bool get _hasNext => _currentIndex < _queue.length - 1;
  bool get _hasPrevious => _currentIndex > 0;

  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<dynamic>? _mediaControlSubscription;
  StreamSubscription<bool>? _bufferingSubscription;

  MediaControlsManager? _mediaControlsManager;
  PlaybackProgressTracker? _progressTracker;
  Timer? _progressTimer;

  /// Get the correct PlexClient for this metadata's server
  PlexClient _getClientForMetadata(BuildContext context) {
    return context.getClientForServer(_currentMetadata.serverId!);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _queue = widget.queue ?? [widget.metadata];
    _currentIndex = widget.startIndex.clamp(0, _queue.length - 1);
    _loadFullMetadata();
    _initializePlayer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _playingSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _mediaControlSubscription?.cancel();
    _bufferingSubscription?.cancel();
    _progressTracker?.stopTracking();
    _progressTimer?.cancel();
    _mediaControlsManager?.dispose();
    player?.dispose();
    super.dispose();
  }

  Future<void> _loadFullMetadata() async {
    setState(() {
      _isLoadingMetadata = true;
    });

    try {
      final client = _getClientForMetadata(context);
      final metadata = await client.getMetadataWithImages(
        _currentMetadata.ratingKey,
      );

      if (metadata != null) {
        final metadataWithServerId = metadata.copyWith(
          serverId: _currentMetadata.serverId,
          serverName: _currentMetadata.serverName,
        );

        setState(() {
          _fullMetadata = metadataWithServerId;
          _isLoadingMetadata = false;
        });
      } else {
        setState(() {
          _fullMetadata = _currentMetadata;
          _isLoadingMetadata = false;
        });
      }
    } catch (e) {
      setState(() {
        _fullMetadata = _currentMetadata;
        _isLoadingMetadata = false;
      });
    }
  }

  Future<void> _initializePlayer() async {
    try {
      final settingsService = await SettingsService.getInstance();
      final bufferSizeMB = settingsService.getBufferSize();
      final bufferSizeBytes = bufferSizeMB * 1024 * 1024;
      final debugLoggingEnabled = settingsService.getEnableDebugLogging();

      // Create player for audio-only playback
      player = Player();

      // Configure for audio-only: disable video, playlist scripts
      await player!.setProperty('vo', 'null');
      await player!.setProperty('ytdl', 'no');
      await player!.setProperty('prefetch-playlist', 'no');
      await player!.setProperty('load-scripts', 'no');
      if (bufferSizeMB > 0) {
        await player!.setProperty('demuxer-max-bytes', '${bufferSizeMB * 1024 * 1024}');
      }

      // Apply saved volume
      final savedVolume = settingsService.getVolume();
      player!.setVolume(savedVolume);
      _volume = savedVolume;

      // Notify that player is ready
      if (mounted) {
        setState(() {
          _isPlayerInitialized = true;
        });
      }

      // Listen to playback state changes (before starting playback to catch all events)
      _playingSubscription = player!.streams.playing.listen((playing) {
        if (mounted) {
          setState(() {
            _isPlaying = playing;
          });
        }
        _updateMediaControlsPlaybackState();
      });

      // Listen to position updates
      _positionSubscription = player!.streams.position.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
        _updateMediaControlsPlaybackState();
      });

      // Listen to duration updates
      _durationSubscription = player!.streams.duration.listen((duration) {
        if (mounted) {
          setState(() {
            _duration = duration;
          });
        }
      });

      // Listen to completion
      player!.streams.completed.listen((completed) {
        if (completed && mounted) {
          _onTrackCompleted();
        }
      });

      // Start playback
      await _startPlayback();

      // Sync initial state from player (in case events were missed)
      if (mounted) {
        setState(() {
          _isPlaying = player!.state.playing;
          _position = player!.state.position;
          _duration = player!.state.duration;
        });
      }

      // Load source library for audiobook detection
      _loadSourceLibrary();

      // Load chapters
      _loadChapters();

      // Set up media controls
      await _setupMediaControls();

      // Start progress tracking
      final client = _getClientForMetadata(context);
      _progressTracker = PlaybackProgressTracker(
        client: client,
        metadata: _fullMetadata ?? _currentMetadata,
        player: player!,
      );
      _progressTracker!.startTracking();
    } catch (e) {
      appLogger.e('Failed to initialize audio player', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start playback: $e')),
        );
      }
    }
  }

  Future<void> _startPlayback() async {
    try {
      final client = _getClientForMetadata(context);
      final initializationService = AudioPlaybackInitializationService(
        player: player!,
        client: client,
        context: context,
      );

      final result = await initializationService.startPlayback(
        metadata: _fullMetadata ?? _currentMetadata,
      );

      // Store media info for chapters
      if (mounted) {
        setState(() {
          _mediaInfo = result.mediaInfo;
        });
      }
    } catch (e) {
      appLogger.e('Failed to start playback', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start playback: $e')),
        );
      }
    }
  }

  Future<void> _loadChapters() async {
    try {
      final client = _getClientForMetadata(context);
      final chapters = await client.getChapters(
        (_fullMetadata ?? _currentMetadata).ratingKey,
      );
      if (mounted) {
        setState(() {
          _chapters = chapters;
          _chaptersLoaded = true;
        });
      }
    } catch (e) {
      appLogger.w('Failed to load chapters', error: e);
      if (mounted) {
        setState(() {
          _chaptersLoaded = true;
        });
      }
    }
  }

  /// Check if this track is from an audiobook library.
  /// 
  /// Uses library-based detection (most reliable) with duration fallback
  /// for cases where library info isn't available.
  bool get _isAudiobook {
    // First check if we know the source library (most reliable)
    if (_sourceLibrary != null) {
      return _sourceLibrary!.isAudiobookLibrary;
    }

    // Fallback: use duration heuristic (long tracks > 30 minutes)
    // This is less reliable but better than nothing when library info isn't available
    final metadata = _fullMetadata ?? _currentMetadata;
    final duration = metadata.duration;
    return duration != null && duration > 30 * 60 * 1000; // 30 minutes
  }

  /// Load the source library for this track if available.
  /// This enables accurate audiobook detection based on library metadata.
  Future<void> _loadSourceLibrary() async {
    final metadata = _fullMetadata ?? _currentMetadata;
    if (metadata.librarySectionID == null) return;

    try {
      // Get libraries from the same server as this metadata
      final client = _getClientForMetadata(context);
      final libraries = await client.getLibraries();
      
      // Find library matching the section ID (key matches librarySectionID)
      final library = libraries.firstWhere(
        (lib) => lib.key == metadata.librarySectionID.toString(),
        orElse: () => libraries.first, // Fallback to first library if not found
      );

      if (mounted) {
        setState(() {
          _sourceLibrary = library;
        });
      }
    } catch (e) {
      // Library lookup failed, will fall back to duration-based detection
      appLogger.d('Could not load source library for audiobook detection: $e');
    }
  }

  /// Get current chapter based on position
  PlexChapter? _getCurrentChapter(Duration position) {
    final posMs = position.inMilliseconds;
    for (final chapter in _chapters) {
      final startMs = chapter.startTimeOffset ?? 0;
      final endMs = chapter.endTimeOffset ?? double.maxFinite.toInt();
      if (posMs >= startMs && posMs < endMs) {
        return chapter;
      }
    }
    return null;
  }

  /// Seek to previous chapter
  void _seekToPreviousChapter() {
    if (_chapters.isEmpty || player == null) return;

    final currentPos = player!.state.position;
    final currentPosMs = currentPos.inMilliseconds;

    // Find the previous chapter
    PlexChapter? previousChapter;
    for (int i = _chapters.length - 1; i >= 0; i--) {
      final chapter = _chapters[i];
      final startMs = chapter.startTimeOffset ?? 0;
      if (startMs < currentPosMs) {
        previousChapter = chapter;
        break;
      }
    }

    if (previousChapter != null) {
      final seekPos = Duration(milliseconds: previousChapter.startTimeOffset ?? 0);
      player!.seek(seekPos);
    } else {
      // Go to beginning
      player!.seek(Duration.zero);
    }
  }

  /// Seek to next chapter
  void _seekToNextChapter() {
    if (_chapters.isEmpty || player == null) return;

    final currentPos = player!.state.position;
    final currentPosMs = currentPos.inMilliseconds;

    // Find the next chapter
    for (final chapter in _chapters) {
      final startMs = chapter.startTimeOffset ?? 0;
      if (startMs > currentPosMs) {
        final seekPos = Duration(milliseconds: startMs);
        player!.seek(seekPos);
        return;
      }
    }
  }

  /// Skip backward by 15 seconds
  void _skipBackward() {
    if (player == null) return;
    final currentPos = player!.state.position;
    final duration = player!.state.duration;
    final skipDuration = const Duration(seconds: 15);
    final newPosMs = (currentPos.inMilliseconds - skipDuration.inMilliseconds)
        .clamp(0, duration.inMilliseconds);
    player!.seek(Duration(milliseconds: newPosMs));
  }

  /// Skip forward by 30 seconds
  void _skipForward() {
    if (player == null) return;
    final currentPos = player!.state.position;
    final duration = player!.state.duration;
    final skipDuration = const Duration(seconds: 30);
    final newPosMs = (currentPos.inMilliseconds + skipDuration.inMilliseconds)
        .clamp(0, duration.inMilliseconds);
    player!.seek(Duration(milliseconds: newPosMs));
  }

  /// Format playback speed for display
  String _formatSpeed(double rate) {
    if ((rate - 1.0).abs() < 0.01) {
      return 'Normal';
    }
    return '${rate.toStringAsFixed(2)}x';
  }

  /// Show playback speed selector
  void _showSpeedSelector() {
    if (player == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StreamBuilder<double>(
          stream: player!.streams.rate,
          initialData: player!.state.rate,
          builder: (context, snapshot) {
            final currentRate = snapshot.data ?? 1.0;
            final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0];

            return ListView.builder(
              shrinkWrap: true,
              itemCount: speeds.length,
              itemBuilder: (context, index) {
                final speed = speeds[index];
                final isSelected = (currentRate - speed).abs() < 0.01;

                return ListTile(
                  title: Text(
                    _formatSpeed(speed),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check, color: Colors.blue)
                      : null,
                  onTap: () {
                    player!.setRate(speed);
                    Navigator.pop(context);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _setupMediaControls() async {
    final client = _getClientForMetadata(context);
    _mediaControlsManager = MediaControlsManager();

    // Listen to media control events
    _mediaControlSubscription = _mediaControlsManager!.controlEvents.listen((event) {
      if (event is PlayEvent) {
        player?.play();
      } else if (event is PauseEvent) {
        player?.pause();
      } else if (event is SeekEvent) {
        player?.seek(event.position);
      }
    });

    // Update media metadata
    await _mediaControlsManager!.updateMetadata(
      metadata: _fullMetadata ?? _currentMetadata,
      client: client,
      duration: _currentMetadata.duration != null
          ? Duration(milliseconds: _currentMetadata.duration!)
          : null,
    );

    if (!mounted) return;

    await _mediaControlsManager!.setControlsEnabled(
      canGoNext: _hasNext,
      canGoPrevious: _hasPrevious,
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

  void _updateMediaControlsPlaybackState() {
    _mediaControlsManager?.updatePlaybackState(
      isPlaying: _isPlaying,
      position: _position,
      speed: player?.state.rate ?? 1.0,
    );
  }

  void _onTrackCompleted() {
    // Mark as played and send final progress
    _progressTracker?.sendProgress('stopped');
    _progressTracker?.stopTracking();

    if (_hasNext) {
      _playTrack(_currentIndex + 1);
    } else {
      // End of queue — navigate back
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _playTrack(int index) async {
    if (index < 0 || index >= _queue.length) return;

    _progressTracker?.sendProgress('stopped');
    _progressTracker?.stopTracking();

    setState(() {
      _currentIndex = index;
      _fullMetadata = null;
      _isLoadingMetadata = true;
      _chapters = [];
      _chaptersLoaded = false;
      _mediaInfo = null;
      _position = Duration.zero;
      _duration = Duration.zero;
    });

    await _loadFullMetadata();
    await _startPlayback();

    // Sync state after playback starts
    if (mounted) {
      setState(() {
        _isPlaying = player!.state.playing;
        _position = player!.state.position;
        _duration = player!.state.duration;
      });
    }

    _loadSourceLibrary();
    _loadChapters();
    await _setupMediaControls();

    // Update progress tracker for new track
    final client = _getClientForMetadata(context);
    _progressTracker = PlaybackProgressTracker(
      client: client,
      metadata: _fullMetadata ?? _currentMetadata,
      player: player!,
    );
    _progressTracker!.startTracking();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 600;
    final client = _getClientForMetadata(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          return handleBackKeyNavigation(context, event);
        },
        child: CustomScrollView(
          slivers: [
            CustomAppBar(
              title: Text(_fullMetadata?.title ?? _currentMetadata.title),
              pinned: true,
              onBackPressed: () => Navigator.pop(context),
            ),
            if (_isPlayerInitialized && !_isLoadingMetadata)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Album art
                        if (_fullMetadata?.thumb != null ||
                            _fullMetadata?.art != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: client.getThumbnailUrl(
                                _fullMetadata!.thumb ?? _fullMetadata!.art!,
                              ),
                              width: isDesktop ? 400 : 300,
                              height: isDesktop ? 400 : 300,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: isDesktop ? 400 : 300,
                                height: isDesktop ? 400 : 300,
                                color: theme.cardColor,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: isDesktop ? 400 : 300,
                                height: isDesktop ? 400 : 300,
                                color: theme.cardColor,
                                child: Icon(
                                  Icons.music_note,
                                  size: 100,
                                  color: theme.disabledColor,
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: isDesktop ? 400 : 300,
                            height: isDesktop ? 400 : 300,
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.music_note,
                              size: 100,
                              color: theme.disabledColor,
                            ),
                          ),
                        const SizedBox(height: 32),
                        // Track info
                        Text(
                          _fullMetadata?.title ?? _currentMetadata.title,
                          style: theme.textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        if (_fullMetadata?.parentTitle != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _fullMetadata!.parentTitle!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.disabledColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        if (_queue.length > 1) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${_currentIndex + 1} of ${_queue.length}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.disabledColor,
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        // Progress bar with StreamBuilder for real-time updates
                        if (player != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: StreamBuilder<Duration>(
                              stream: player!.streams.position,
                              initialData: player!.state.position,
                              builder: (context, positionSnapshot) {
                                return StreamBuilder<Duration>(
                                  stream: player!.streams.duration,
                                  initialData: player!.state.duration,
                                  builder: (context, durationSnapshot) {
                                    final position =
                                        positionSnapshot.data ?? Duration.zero;
                                    final duration =
                                        durationSnapshot.data ?? Duration.zero;
                                    final remaining = duration - position;
                                    final currentChapter = _getCurrentChapter(position);

                                    return Column(
                                      children: [
                                        // Current chapter indicator (for audiobooks)
                                        if (_isAudiobook && currentChapter != null) ...[
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 8.0),
                                            child: Text(
                                              currentChapter.label,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.primary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                        Slider(
                                          value: duration.inMilliseconds > 0
                                              ? position.inMilliseconds /
                                                  duration.inMilliseconds
                                              : 0.0,
                                          onChanged: (value) {
                                            final newPosition = Duration(
                                              milliseconds: (value *
                                                      duration.inMilliseconds)
                                                  .round(),
                                            );
                                            player?.seek(newPosition);
                                          },
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  formatDurationTimestamp(position),
                                                  style: theme.textTheme.bodySmall,
                                                ),
                                                if (_isAudiobook && remaining.inSeconds > 0)
                                                  Text(
                                                    '-${formatDurationTimestamp(remaining)}',
                                                    style: theme.textTheme.bodySmall?.copyWith(
                                                      color: theme.disabledColor,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            Text(
                                              formatDurationTimestamp(duration),
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        const SizedBox(height: 24),
                        // Skip controls (for audiobooks)
                        if (_isAudiobook && player != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Skip backward 15s
                                IconButton(
                                  icon: Icon(getReplayIcon(15)),
                                  tooltip: 'Skip back 15 seconds',
                                  onPressed: _skipBackward,
                                  iconSize: 32,
                                ),
                                const SizedBox(width: 8),
                                // Chapter previous (if chapters available)
                                if (_chapters.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.skip_previous),
                                    tooltip: 'Previous chapter',
                                    onPressed: _seekToPreviousChapter,
                                    iconSize: 32,
                                  ),
                                if (_chapters.isNotEmpty) const SizedBox(width: 8),
                                // Playback speed
                                StreamBuilder<double>(
                                  stream: player!.streams.rate,
                                  initialData: player!.state.rate,
                                  builder: (context, snapshot) {
                                    final rate = snapshot.data ?? 1.0;
                                    return TextButton.icon(
                                      icon: const Icon(Icons.speed, size: 20),
                                      label: Text(_formatSpeed(rate)),
                                      onPressed: _showSpeedSelector,
                                    );
                                  },
                                ),
                                if (_chapters.isNotEmpty) const SizedBox(width: 8),
                                // Chapter next (if chapters available)
                                if (_chapters.isNotEmpty)
                                  IconButton(
                                    icon: const Icon(Icons.skip_next),
                                    tooltip: 'Next chapter',
                                    onPressed: _seekToNextChapter,
                                    iconSize: 32,
                                  ),
                                const SizedBox(width: 8),
                                // Skip forward 30s
                                IconButton(
                                  icon: Icon(getForwardIcon(30)),
                                  tooltip: 'Skip forward 30 seconds',
                                  onPressed: _skipForward,
                                  iconSize: 32,
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),
                        // Main controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Volume down
                            IconButton(
                              icon: const Icon(Icons.volume_down),
                              onPressed: () {
                                final newVolume =
                                    (_volume - 10).clamp(0.0, 100.0);
                                player?.setVolume(newVolume);
                                setState(() {
                                  _volume = newVolume;
                                });
                              },
                              iconSize: 32,
                            ),
                            const SizedBox(width: 16),
                            // Previous track
                            if (_queue.length > 1)
                              IconButton(
                                icon: const Icon(Icons.skip_previous),
                                onPressed: _hasPrevious
                                    ? () => _playTrack(_currentIndex - 1)
                                    : null,
                                iconSize: 40,
                              ),
                            // Play/Pause
                            StreamBuilder<bool>(
                              stream: player?.streams.playing,
                              initialData: player?.state.playing ?? false,
                              builder: (context, snapshot) {
                                final isPlaying = snapshot.data ?? false;
                                return IconButton(
                                  icon: Icon(
                                      isPlaying ? Icons.pause : Icons.play_arrow),
                                  onPressed: () {
                                    if (isPlaying) {
                                      player?.pause();
                                    } else {
                                      player?.play();
                                    }
                                  },
                                  iconSize: 64,
                                );
                              },
                            ),
                            // Next track
                            if (_queue.length > 1)
                              IconButton(
                                icon: const Icon(Icons.skip_next),
                                onPressed: _hasNext
                                    ? () => _playTrack(_currentIndex + 1)
                                    : null,
                                iconSize: 40,
                              ),
                            const SizedBox(width: 16),
                            // Volume up
                            IconButton(
                              icon: const Icon(Icons.volume_up),
                              onPressed: () {
                                final newVolume =
                                    (_volume + 10).clamp(0.0, 100.0);
                                player?.setVolume(newVolume);
                                setState(() {
                                  _volume = newVolume;
                                });
                              },
                              iconSize: 32,
                            ),
                          ],
                        ),
                        // Playback speed control (for non-audiobooks or as secondary control)
                        if (!_isAudiobook && player != null) ...[
                          const SizedBox(height: 16),
                          StreamBuilder<double>(
                            stream: player!.streams.rate,
                            initialData: player!.state.rate,
                            builder: (context, snapshot) {
                              final rate = snapshot.data ?? 1.0;
                              if ((rate - 1.0).abs() < 0.01) {
                                return const SizedBox.shrink();
                              }
                              return TextButton.icon(
                                icon: const Icon(Icons.speed, size: 18),
                                label: Text(_formatSpeed(rate)),
                                onPressed: _showSpeedSelector,
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              )
            else
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

