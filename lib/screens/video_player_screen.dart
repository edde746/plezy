import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:plezy/widgets/app_icon.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter/services.dart';
import 'package:os_media_controls/os_media_controls.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../mpv/mpv.dart';
import '../mpv/player/platform/player_android.dart';

import '../services/scrub_preview_source.dart';
import '../media/media_backend.dart';
import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../media/media_server_client.dart';
import '../services/jellyfin_client.dart';
import '../services/live_session_tracker.dart';
import '../services/plex_client.dart';
import '../utils/session_identifier.dart';
import '../database/app_database.dart';
import '../media/media_version.dart';
import '../models/livetv_capture_buffer.dart';
import '../models/livetv_channel.dart';
import '../models/transcode_quality_preset.dart';
import '../media/media_source_info.dart';
import '../providers/download_provider.dart';
import '../providers/multi_server_provider.dart';
import '../providers/playback_state_provider.dart';
import '../models/companion_remote/remote_command.dart';
import '../providers/companion_remote_provider.dart';
import '../services/companion_remote/companion_remote_receiver.dart';
import '../services/fullscreen_state_manager.dart';
import '../services/discord_rpc_service.dart';
import '../services/trackers/tracker_coordinator.dart';
import '../services/trakt/trakt_scrobble_service.dart';
import '../services/episode_navigation_service.dart';
import '../services/media_controls_manager.dart';
import '../services/playback_initialization_service.dart';
import '../services/playback_progress_tracker.dart';
import '../services/offline_watch_sync_service.dart';
import '../services/display_mode_service.dart';
import '../services/settings_service.dart';
import '../providers/settings_provider.dart';
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
import '../utils/log_redaction_manager.dart';
import '../utils/live_tv_player_navigation.dart';
import '../utils/player_utils.dart';
import '../utils/orientation_helper.dart';
import '../utils/platform_detector.dart';
import '../utils/provider_extensions.dart';
import '../utils/snackbar_helper.dart';
import '../utils/video_player_navigation.dart';
import 'video_player/widgets/player_prompt_overlays.dart';
import '../widgets/overlay_sheet.dart';
import '../widgets/video_controls/video_controls.dart';
import '../widgets/video_controls/widgets/player_toast_indicator.dart';
import '../focus/input_mode_tracker.dart';
import '../focus/dpad_navigator.dart';
import '../focus/key_event_utils.dart';
import '../i18n/strings.g.dart';
import '../watch_together/providers/watch_together_provider.dart';

part 'video_player/parts/companion_remote.dart';
part 'video_player/parts/display_matching.dart';
part 'video_player/parts/episode_navigation.dart';
part 'video_player/parts/episode_queue.dart';
part 'video_player/parts/errors.dart';
part 'video_player/parts/lifecycle.dart';
part 'video_player/parts/live_tv.dart';
part 'video_player/parts/media_controls.dart';
part 'video_player/parts/pip_shader.dart';
part 'video_player/parts/playback_prompts.dart';
part 'video_player/parts/playback_services.dart';
part 'video_player/parts/playback_start.dart';
part 'video_player/parts/build.dart';
part 'video_player/parts/watch_together.dart';

bool? _wakelockEnabled;

Future<void> _setWakelock(bool enabled) async {
  if (_wakelockEnabled == enabled) return;
  _wakelockEnabled = enabled;
  try {
    if (enabled) {
      await WakelockPlus.enable();
    } else {
      await WakelockPlus.disable();
    }
  } catch (e) {
    _wakelockEnabled = null;
    appLogger.w('Wakelock ${enabled ? 'enable' : 'disable'} failed: $e');
  }
}

/// Builds a [TrackPreferencePersister] that fans the language-preference +
/// stream-selection writes out to a [PlexClient] resolved lazily on each
/// call. Returns a no-op-on-null persister so the [TrackManager] doesn't
/// have to import [PlexClient] itself; the resolver returning null (e.g.
/// when the active server is Jellyfin) makes the call short-circuit.
TrackPreferencePersister _plexTrackPersister(PlexClient? Function() resolve) {
  return ({
    required String id,
    required int partId,
    required String trackType,
    String? languageCode,
    int? streamID,
  }) async {
    final client = resolve();
    if (client == null) return;
    final futures = <Future>[];
    if (languageCode != null && (trackType == 'subtitle' || languageCode.isNotEmpty)) {
      futures.add(
        trackType == 'audio'
            ? client.setMetadataPreferences(id, audioLanguage: languageCode)
            : client.setMetadataPreferences(id, subtitleLanguage: languageCode),
      );
    }
    if (streamID != null) {
      futures.add(
        trackType == 'audio'
            ? client.selectStreams(partId, audioStreamID: streamID, allParts: true)
            : client.selectStreams(partId, subtitleStreamID: streamID, allParts: true),
      );
    }
    await Future.wait(futures);
  };
}

class VideoPlayerScreen extends StatefulWidget {
  final MediaItem metadata;
  final AudioTrack? preferredAudioTrack;
  final SubtitleTrack? preferredSubtitleTrack;
  final SubtitleTrack? preferredSecondarySubtitleTrack;
  final int selectedMediaIndex;
  final bool isOffline;

  /// Quality preset override for this playback. When `null`, the screen uses
  /// the user's default from [SettingsProvider].
  final TranscodeQualityPreset? selectedQualityPreset;

  /// Audio stream ID to pass to the transcoder when [selectedQualityPreset]
  /// is non-original. When `null`, the playback service picks the `selected`
  /// Plex audio track (fallback: first).
  final int? selectedAudioStreamId;

  /// Session identifiers forwarded across quality/version/audio switches so
  /// the server-side transcode session is preserved.
  final String? reusedSessionIdentifier;
  final String? reusedTranscodeSessionId;

  // Live TV fields
  final bool isLive;
  final String? liveChannelName;
  final String? liveStreamUrl;
  final List<LiveTvChannel>? liveChannels;
  final int? liveCurrentChannelIndex;
  final String? liveDvrKey;

  /// Backend-neutral client typing. The four in-player live ops branch on
  /// `client is PlexClient` / `client is JellyfinClient` at their use sites:
  /// Plex tunes a transcode session and gets capture-buffer updates;
  /// Jellyfin uses its `/Sessions/Playing*` endpoints for progress reporting
  /// and re-opens [liveStreamUrl] for retry. Tune (Plex-only by protocol)
  /// and seek (Plex-only — Jellyfin live channels aren't seekable) gate
  /// explicitly on `client is PlexClient`.
  final MediaServerClient? liveClient;
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
    this.selectedQualityPreset,
    this.selectedAudioStreamId,
    this.reusedSessionIdentifier,
    this.reusedTranscodeSessionId,
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
  static String? _activeId;
  static int? _activeMediaIndex;

  static String? get activeId => _activeId;
  static int? get activeMediaIndex => _activeMediaIndex;

  Player? player;
  bool _isPlayerInitialized = false;
  String? _playerInitializationError;
  late MediaItem _currentMetadata;
  MediaItem? _nextEpisode;
  MediaItem? _previousEpisode;
  bool _isLoadingNext = false;
  bool _isLoadingPrevious = false;
  bool _isSwappingEpisode = false;
  bool _showPlayNextDialog = false;
  bool _isPhone = false;
  List<MediaVersion> _availableVersions = [];
  MediaSourceInfo? _currentMediaInfo;

  // Transcode / quality state
  late TranscodeQualityPreset _selectedQualityPreset;
  int? _selectedAudioStreamId;
  bool _isTranscoding = false;
  bool _effectiveIsOffline = false;
  bool _serverSupportsTranscoding = false;
  // Kicked off early in `_initializePlayer` for online non-live playback so
  // the metadata fetch (and transcode-decision HTTP, if non-original preset)
  // overlaps with MPV property configuration. Awaited inside `_startPlayback`
  // immediately before `player.open()` needs the video URL.
  Future<PlaybackInitializationResult>? _playbackDataFuture;
  // HTTP headers attached to the player's `Media` request — `X-Plex-Token`
  // for Plex, empty for Jellyfin (token rides in the URL there). Sourced
  // from `MediaServerClient.streamHeaders` so the player code path stays
  // backend-neutral.
  Map<String, String>? _streamHeaders;
  // Fired in parallel with MPV setup so the OS audio-focus negotiation
  // (~90ms on Android) doesn't sit on the critical path. Awaited before
  // `player.open()` so the semantics are unchanged — we just eat the cost
  // during otherwise-idle setup time.
  Future<void>? _audioFocusFuture;
  late final String _playbackSessionIdentifier;
  late final String _playbackTranscodeSessionId;
  String? _playbackPlaySessionId;
  String? _playbackPlayMethod;
  StreamSubscription<PlayerError>? _errorSubscription;
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
  bool _isReplacingWithVideo = false;
  bool _isDisposingForNavigation = false;
  bool _isHandlingBack = false;
  ScrubPreviewSource? _scrubPreviewSource;

  int _liveChannelIndex = -1;
  String? _liveChannelName;
  MediaServerClient? _liveClient;
  String? _liveDvrKey;
  String? _liveStreamUrl;
  String? _liveItemId;
  String? _liveSessionIdentifier;
  String? _liveSessionPath;
  Timer? _liveTimelineTimer;
  int _liveTimelineGeneration = 0;
  DateTime? _livePlaybackStartTime;
  String? _liveProgramId;
  int? _liveDurationMs;

  // Jellyfin live TV heartbeat state machine. The Plex live branch keeps
  // its bespoke capture-buffer flow inline; this tracker only collapses
  // the Jellyfin started/progress/stopped transition.
  JellyfinLiveSessionTracker _jellyfinLiveSession = JellyfinLiveSessionTracker();

  CaptureBuffer? _captureBuffer;
  int? _programBeginsAt;
  double _streamStartEpoch = 0;
  bool _isAtLiveEdge = true;
  String? _transcodeSessionId;

  /// Fallback level for live TV stream errors (mirrors Plex web client behavior).
  /// 0 = directStream+directStreamAudio, 1 = no directStream, 2 = no DS + no DS audio.
  int _liveStreamFallbackLevel = 0;
  bool _isRetryingLiveStream = false;

  Timer? _autoPlayTimer;
  int _autoPlayCountdown = 5;
  bool _completionTriggered = false;

  late final FocusNode _playNextCancelFocusNode;
  late final FocusNode _playNextConfirmFocusNode;

  bool _showStillWatchingPrompt = false;
  int _stillWatchingCountdown = 30;
  Timer? _stillWatchingTimer;
  late final FocusNode _stillWatchingPauseFocusNode;
  late final FocusNode _stillWatchingContinueFocusNode;

  // Screen-level focus node: persists across loading/initialized phases so
  // key events never escape the video player route.
  late final FocusNode _screenFocusNode;

  // VLC-style in-player toast controller (rate changes, backend switch, etc.).
  final PlayerToastController _toastController = PlayerToastController();
  bool _reclaimingFocus = false;

  // Cached setting: when false on Windows/Linux, ESC should not exit the player
  bool _videoPlayerNavigationEnabled = false;

  // App lifecycle state tracking
  bool _wasPlayingBeforeInactive = false;
  bool _hiddenForBackground = false;
  bool _autoPipEnabled = false;
  bool _androidAutoPipTransitionInFlight = false;
  bool _resumeLiveTimelineOnResume = false;
  int _rewindOnResume = 0;
  Future<void> _lifecycleTransition = Future<void>.value();
  String _playerBackendLabel = 'unknown';

  /// Whether to skip lifecycle actions because PiP is active or about to start.
  /// Apple auto-PiP is system-initiated during the background transition, and
  /// Android auto-PiP on API 26-30 has a brief native transition window before
  /// onPipChanged fires.
  bool get _shouldSkipForPip =>
      PipService().isPipActive.value ||
      ((Platform.isIOS || Platform.isMacOS) && _autoPipEnabled) ||
      (Platform.isAndroid && _androidAutoPipTransitionInFlight);

  MediaControlsManager? _mediaControlsManager;
  PlaybackProgressTracker? _progressTracker;
  VideoFilterManager? _videoFilterManager;
  VideoPIPManager? _videoPIPManager;
  ShaderService? _shaderService;
  AmbientLightingService? _ambientLightingService;
  final EpisodeNavigationService _episodeNavigation = EpisodeNavigationService();

  WatchTogetherProvider? _watchTogetherProvider;

  CompanionRemoteProvider? _companionRemoteProvider;
  VoidCallback? _savedOnHome;

  /// Backend-neutral lookup. Returns whichever client (Plex or Jellyfin)
  /// owns this item. Used by the playback-init path in [_initializePlayer].
  MediaServerClient? _getMediaServerClient(BuildContext context) {
    final id = _currentMetadata.serverId;
    if (id == null) return null;
    return context.read<MultiServerProvider>().serverManager.getClient(id);
  }

  bool get _isOfflinePlayback => widget.isOffline || _effectiveIsOffline;

  ScrubFrame? _getThumbnailData(Duration time) => _scrubPreviewSource?.getFrame(time);

  final ValueNotifier<bool> _isBuffering = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _hasFirstFrame = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isExiting = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _controlsVisible = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();

    _currentMetadata = widget.metadata;
    _activeId = widget.metadata.id;
    _activeMediaIndex = widget.selectedMediaIndex;

    // Reused across quality/version/audio switches so the server-side
    // transcode session is preserved.
    _playbackSessionIdentifier = widget.reusedSessionIdentifier ?? generateSessionIdentifier();
    _playbackTranscodeSessionId = widget.reusedTranscodeSessionId ?? generateSessionIdentifier();
    _selectedAudioStreamId = widget.selectedAudioStreamId;
    _effectiveIsOffline = widget.isOffline;
    _selectedQualityPreset = widget.selectedQualityPreset ?? TranscodeQualityPreset.original;

    _liveChannelIndex = widget.liveCurrentChannelIndex ?? -1;
    _liveChannelName = widget.liveChannelName;
    _liveClient = widget.liveClient;
    _liveDvrKey = widget.liveDvrKey;
    _liveStreamUrl = widget.liveStreamUrl;
    _liveItemId = widget.metadata.id;
    _liveSessionIdentifier = widget.liveSessionIdentifier;
    _liveSessionPath = widget.liveSessionPath;
    if (widget.liveClient is JellyfinClient && widget.liveSessionIdentifier != null) {
      _jellyfinLiveSession = JellyfinLiveSessionTracker(playSessionId: widget.liveSessionIdentifier);
    }

    _playNextCancelFocusNode = FocusNode(debugLabel: 'PlayNextCancel');
    _playNextConfirmFocusNode = FocusNode(debugLabel: 'PlayNextConfirm');

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

    try {
      final playbackState = context.read<PlaybackStateProvider>();

      // Defer both operations until after the first frame to avoid calling
      // notifyListeners() during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Keep the queue when this item belongs to it — that covers both
        // server-side queues (Plex `playQueueItemId`) and client-side
        // launcher-seeded queues (Jellyfin playlist/collection, with
        // synthetic ids tracked in the provider). For genuine standalone
        // playback (continue-watching, direct episode tap with no queue
        // launcher) clear any stale queue so prev/next stays consistent.
        final meta = widget.metadata;
        final inActiveQueue = playbackState.isQueueActive && playbackState.playQueueItemIdFor(meta) != null;
        if (inActiveQueue) {
          playbackState.setCurrentItem(meta);
        } else {
          playbackState.clearShuffle();
        }
      });
    } catch (e) {
      appLogger.d('Deferred playback state update (provider not ready)', error: e);
    }

    WidgetsBinding.instance.addObserver(this);

    _setupCompanionRemoteCallbacks();

    _sleepTimerSubscription = SleepTimerService().onPrompt.listen((_) {
      if (mounted) _showStillWatchingDialog();
    });

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
        _recordLifecycleState('inactive');
        // App is inactive (notification shade, split-screen, etc.)
        // Don't pause - user may still be watching
        break;
      case AppLifecycleState.hidden:
        _recordLifecycleState('hidden');
        _enqueueLifecycleTransition('hidden', _handleAppHidden);
        break;
      case AppLifecycleState.paused:
        if (_shouldSkipForPip) {
          _recordLifecycleState('paused', action: 'skipped_for_pip');
          break;
        }
        // Clear media controls when app truly goes to background
        // (we don't support background playback)
        _mediaControlsManager?.clear();
        // Disable wakelock when app goes to background
        _setWakelock(false);
        _recordLifecycleState('paused', action: 'backgrounded');
        break;
      case AppLifecycleState.resumed:
        _recordLifecycleState('resumed');
        _enqueueLifecycleTransition('resumed', _handleAppResumed);
        break;
      case AppLifecycleState.detached:
        _recordLifecycleState('detached');
        // No action needed for this state
        break;
    }
  }

  Future<void> _initializePlayer() async {
    try {
      if (mounted) {
        setState(() => _playerInitializationError = null);
      }
      final settingsService = await SettingsService.getInstance();
      _videoPlayerNavigationEnabled = settingsService.read(SettingsService.videoPlayerNavigationEnabled);
      _autoPipEnabled = settingsService.read(SettingsService.autoPip);
      _rewindOnResume = settingsService.read(SettingsService.rewindOnResume);
      final bufferSizeMB = settingsService.read(SettingsService.bufferSize);
      final enableHardwareDecoding = settingsService.read(SettingsService.enableHardwareDecoding);
      final debugLoggingEnabled = settingsService.read(SettingsService.enableDebugLogging);
      final useExoPlayer = settingsService.read(SettingsService.useExoPlayer);

      if (Platform.isWindows) {
        _displayModeService = DisplayModeService(settingsService, FullscreenStateManager());
        await _displayModeService!.syncWithNative();
        FullscreenStateManager().addListener(_onFullscreenChanged);
      }

      player = Player(useExoPlayer: useExoPlayer);
      _playerBackendLabel = player!.playerType;

      // Kick off audio-focus negotiation in parallel with MPV config + prefetch.
      // On Android this is a round-trip to AudioManager (~90ms cold).
      if (Platform.isAndroid && !widget.isLive) {
        _audioFocusFuture = player!.requestAudioFocus();
        _audioFocusFuture!.ignore();
      }

      // Kick off getPlaybackData() in parallel with the rest of MPV setup.
      // The network/DB work has no dependency on the player — it just needs
      // the context (providers), which is still safe to touch here because
      // no async gaps invalidate it before the calls below read it.
      // Skipped for live TV (has its own tune path) and offline (its own
      // branch in _startPlayback).
      if (!widget.isLive && !widget.isOffline && mounted) {
        // Backend-neutral lookup so Jellyfin items also flow through here.
        // Plex-specific transcoder caching is gated on capabilities below;
        // Jellyfin's `streamHeaders` is empty because it embeds api_key in
        // the query string, while Plex returns the X-Plex-* identity headers.
        final genericClient = _getMediaServerClient(context);
        if (genericClient == null) {
          throw StateError('No client registered for ${_currentMetadata.serverId}');
        }
        _streamHeaders = genericClient.streamHeaders;
        // Single source of truth — `capabilities.videoTranscoding` reflects
        // the per-Plex-server probe (false on Plex installs without a working
        // transcoder) and is hard-false on Jellyfin. The long-press context
        // menu's quality picker reads the same flag. Alternate-version
        // selection still works regardless because it's gated on
        // `availableVersions.length`, not transcoding capability.
        _serverSupportsTranscoding = genericClient.capabilities.videoTranscoding;
        if (widget.selectedQualityPreset == null) {
          try {
            final settingsProvider = context.read<SettingsProvider>();
            _selectedQualityPreset = settingsProvider.defaultQualityPreset;
          } catch (_) {
            _selectedQualityPreset = TranscodeQualityPreset.original;
          }
        } else {
          _selectedQualityPreset = widget.selectedQualityPreset!;
        }
        final playbackService = PlaybackInitializationService(
          client: genericClient,
          database: context.read<AppDatabase>(),
        );
        _playbackDataFuture = playbackService.getPlaybackData(
          metadata: _currentMetadata,
          selectedMediaIndex: widget.selectedMediaIndex,
          preferOffline: _selectedQualityPreset.isOriginal,
          qualityPreset: _selectedQualityPreset,
          selectedAudioStreamId: _selectedAudioStreamId,
          sessionIdentifier: _playbackSessionIdentifier,
          transcodeSessionId: _playbackTranscodeSessionId,
        );
        // If MPV setup below throws before `_startPlayback` awaits this,
        // tell Dart we've "handled" the future so it's not reported as an
        // unhandled async error. The later `await` still receives the error.
        _playbackDataFuture!.ignore();
      }

      await player!.configureSubtitleFonts();
      await player!.setProperty('sub-ass', 'yes'); // Enable libass
      if (Platform.isAndroid && useExoPlayer) {
        final tunneledPlayback = settingsService.read(SettingsService.tunneledPlayback);
        await player!.setProperty('tunneled-playback', tunneledPlayback ? 'yes' : 'no');
      }
      if (bufferSizeMB > 0) {
        final bufferSizeBytes = bufferSizeMB * 1024 * 1024;
        await player!.setProperty('demuxer-max-bytes', bufferSizeBytes.toString());
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

      await player!.setProperty('sub-font-size', settingsService.read(SettingsService.subtitleFontSize).toString());
      await player!.setProperty('sub-color', settingsService.read(SettingsService.subtitleTextColor));
      await player!.setProperty('sub-border-size', settingsService.read(SettingsService.subtitleBorderSize).toString());
      await player!.setProperty('sub-border-color', settingsService.read(SettingsService.subtitleBorderColor));
      await player!.setProperty('sub-bold', settingsService.read(SettingsService.subtitleBold) ? 'yes' : 'no');
      await player!.setProperty('sub-italic', settingsService.read(SettingsService.subtitleItalic) ? 'yes' : 'no');
      final bgOpacity = (settingsService.read(SettingsService.subtitleBackgroundOpacity) * 255 / 100).toInt();
      final bgColor = settingsService.read(SettingsService.subtitleBackgroundColor).replaceFirst('#', '');
      await player!.setProperty(
        'sub-back-color',
        '#${bgOpacity.toRadixString(16).padLeft(2, '0').toUpperCase()}$bgColor',
      );
      if (settingsService.read(SettingsService.subtitleBackgroundOpacity) > 0) {
        await player!.setProperty('sub-border-style', 'background-box');
      }
      await player!.setProperty('sub-ass-override', settingsService.read(SettingsService.subAssOverride).name);
      await player!.setProperty('sub-ass-video-aspect-override', '1');
      await player!.setProperty('sub-pos', settingsService.read(SettingsService.subtitlePosition).toString());

      if (Platform.isIOS) {
        await player!.setProperty('audio-exclusive', 'yes');
      }

      // Audio passthrough (desktop only - sends bitstream to receiver)
      if (PlatformDetector.isDesktopOS()) {
        if (settingsService.read(SettingsService.audioPassthrough)) {
          await player!.setAudioPassthrough(true);
        }
      }

      // HDR is controlled via custom hdr-enabled property on iOS/macOS/Windows
      if (Platform.isIOS || Platform.isMacOS || Platform.isWindows) {
        final enableHDR = settingsService.read(SettingsService.enableHDR);
        await player!.setProperty('hdr-enabled', enableHDR ? 'yes' : 'no');
      }

      final audioSyncOffset = settingsService.read(SettingsService.audioSyncOffset);
      if (audioSyncOffset != 0) {
        final offsetSeconds = audioSyncOffset / 1000.0;
        await player!.setProperty('audio-delay', offsetSeconds.toString());
      }

      final subtitleSyncOffset = settingsService.read(SettingsService.subtitleSyncOffset);
      if (subtitleSyncOffset != 0) {
        final offsetSeconds = subtitleSyncOffset / 1000.0;
        await player!.setProperty('sub-delay', offsetSeconds.toString());
      }

      if (settingsService.read(SettingsService.audioNormalization)) {
        await player!.setProperty('af', 'loudnorm=I=-14:TP=-3:LRA=4');
      }

      final customMpvConfig = SettingsService.parseMpvConfigText(settingsService.read(SettingsService.mpvConfigText));
      for (final entry in customMpvConfig.entries) {
        try {
          await player!.setProperty(entry.key, entry.value);
          appLogger.d('Applied custom MPV property: ${entry.key}=${entry.value}');
        } catch (e) {
          appLogger.w('Failed to set MPV property ${entry.key}', error: e);
        }
      }

      final maxVolume = settingsService.read(SettingsService.maxVolume);
      await player!.setProperty('volume-max', maxVolume.toString());

      final savedVolume = settingsService.read(SettingsService.volume).clamp(0.0, maxVolume.toDouble());
      unawaited(player!.setVolume(savedVolume));

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
        unawaited(_setWakelock(true));
        appLogger.d('Wakelock enabled for video playback');
      }

      await _startPlayback();

      // Set fullscreen mode and orientation based on rotation lock setting
      if (mounted) {
        try {
          // Check rotation lock setting before applying orientation
          final isRotationLocked = settingsService.read(SettingsService.rotationLocked);

          if (isRotationLocked) {
            // Locked: Apply landscape orientation only
            OrientationHelper.setLandscapeOrientation();
          } else {
            // Unlocked: Allow all orientations immediately
            unawaited(SystemChrome.setPreferredOrientations(DeviceOrientation.values));
            unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky));
          }
        } catch (e) {
          appLogger.w('Failed to set orientation', error: e);
          // Don't crash if orientation fails - video can still play
        }
      }

      await Future.wait<void>([
        if (_playingSubscription != null) _playingSubscription!.cancel(),
        if (_completedSubscription != null) _completedSubscription!.cancel(),
        if (_errorSubscription != null) _errorSubscription!.cancel(),
        if (_logSubscription != null) _logSubscription!.cancel(),
        if (_backendSwitchedSubscription != null) _backendSwitchedSubscription!.cancel(),
        if (_bufferingSubscription != null) _bufferingSubscription!.cancel(),
        if (_serverStatusSubscription != null) _serverStatusSubscription!.cancel(),
        if (_playbackRestartSubscription != null) _playbackRestartSubscription!.cancel(),
        if (_positionSubscription != null) _positionSubscription!.cancel(),
      ]);

      _playingSubscription = player!.streams.playing.listen(_onPlayingStateChanged);

      // Listen to completion. When mpv emits completed=false (file-loaded after a
      // reconnect-seek or fresh open), clear a stale _completionTriggered so the
      // real end-of-file can still show Play Next. Guarded against clobbering an
      // active dialog or running auto-play countdown.
      _completedSubscription = player!.streams.completed.listen((done) {
        if (!done && _completionTriggered && !_showPlayNextDialog && _autoPlayTimer?.isActive != true) {
          _completionTriggered = false;
        }
        _onVideoCompleted(done);
      });

      _errorSubscription = player!.streams.error.listen(_onPlayerError);

      // warn is included so we can catch ffmpeg's "HTTP error 500" line in
      // _onPlayerLog — the error-level log that follows omits the status code.
      _logSubscription = player!.streams.log
          .where((log) => const {PlayerLogLevel.fatal, PlayerLogLevel.error, PlayerLogLevel.warn}.contains(log.level))
          .listen(_onPlayerLog);

      if (Platform.isAndroid && useExoPlayer) {
        _backendSwitchedSubscription = player!.streams.backendSwitched.listen((_) => _onBackendSwitched());
      }

      _bufferingSubscription = player!.streams.buffering.listen((isBuffering) {
        _isBuffering.value = isBuffering;
      });

      // When server comes back online while buffering, force mpv to reconnect
      // immediately instead of waiting for ffmpeg's exponential backoff
      if (!_isOfflinePlayback && !widget.isLive) {
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

      _playbackRestartSubscription = player!.streams.playbackRestart.listen((_) async {
        _lastLogError = null;
        _sawServer500 = false;
        _liveStreamFallbackLevel = 0;
        if (!_hasFirstFrame.value) {
          _hasFirstFrame.value = true;
          unawaited(Sentry.addBreadcrumb(Breadcrumb(message: 'First frame ready', category: 'player')));

          if (Platform.isAndroid && settingsService.read(SettingsService.matchContentFrameRate)) {
            await _applyFrameRateMatching();
          }

          if (Platform.isWindows && _displayModeService != null) {
            await _applyWindowsDisplayMatching();
          }
        }
        _trackManager?.onPlaybackRestart();
      });

      int? lastObservedPositionMs;
      _positionSubscription = player!.streams.position.listen((position) {
        // Fallback for cases where playbackRestart doesn't fire (observed on
        // some offline Android playback flows). Prevents a permanent loading
        // spinner. Checking `position > 0` was broken for resume playback —
        // the native layer sets position to the resume offset before the first
        // frame renders, so the fallback tripped immediately. Requiring a
        // position *change* ensures we only fire when playback is advancing.
        if (!_hasFirstFrame.value) {
          if (lastObservedPositionMs != null && position.inMilliseconds != lastObservedPositionMs) {
            _hasFirstFrame.value = true;

            // Apply frame rate matching here too, since this fallback may fire
            // before playbackRestart (race condition with resume positions > 0)
            if (Platform.isAndroid && settingsService.read(SettingsService.matchContentFrameRate)) {
              _applyFrameRateMatching();
            }
          }
          lastObservedPositionMs = position.inMilliseconds;
        }

        final duration = player!.state.duration;
        if (duration.inMilliseconds > 0 &&
            position.inMilliseconds >= duration.inMilliseconds - 1000 &&
            !_showPlayNextDialog &&
            !_completionTriggered) {
          _onVideoCompleted(true);
        }
      });

      // Services init must finish before first frame so Discord / Trakt /
      // Tracker start-playback calls are dispatched pre-first-frame.
      // `_loadAdjacentEpisodes` depends on the play queue being in state
      // (EpisodeNavigationService bails when !isQueueActive), so chain it
      // after `_ensurePlayQueue`. Both stay fire-and-forget so HTTP latency
      // is off the critical path; the user can't hit next/previous buttons
      // until after first frame anyway.
      unawaited(
        _ensurePlayQueue().whenComplete(() {
          if (mounted) _loadAdjacentEpisodes();
        }),
      );
      await _initializeServices();
    } catch (e) {
      appLogger.e('Failed to initialize player', error: e);
      if (mounted) {
        setState(() {
          _isPlayerInitialized = false;
          _playerInitializationError = _safePlaybackErrorMessage(e);
        });
      }
    }
  }

  /// Windows display mode matching service.
  DisplayModeService? _displayModeService;

  /// Apply frame rate matching on Android by setting the display refresh rate
  /// to match the video content's frame rate.
  int _frameRateRetries = 0;
  bool _suppressMediaPauseDuringFrameRateSwitch = false;
  // True once a frame-rate switch has been requested for the current playback
  // session — either via the pre-playback primary path (Plex metadata fps) or
  // via the post-`playbackRestart` fallback. Prevents double-switching.
  bool _frameRateMatchingApplied = false;

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
            final navigator = Navigator.of(context);
            if (navigator.canPop()) {
              _isExiting.value = true;
              navigator.pop(true);
            }
          }
        }
        return;
      }

      // Default behavior for hosts or non-session users
      if (!mounted) return;
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        _isExiting.value = true;
        navigator.pop(true);
      }
    } finally {
      _isHandlingBack = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

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

    _detachFromWatchTogetherSession();

    _isBuffering.dispose();
    _hasFirstFrame.dispose();
    _isExiting.dispose();
    _controlsVisible.dispose();
    _toastController.dispose();

    // Stop progress tracking and send final state.
    // Fire-and-forget: dispose() is synchronous so we can't await, but the
    // database write is app-level and will typically complete before teardown.
    _progressTracker?.sendProgress('stopped');
    _progressTracker?.stopTracking();
    _progressTracker?.dispose();
    _sendLiveTimeline('stopped');
    _stopLiveTimelineUpdates();

    _videoPIPManager?.isPipActive.removeListener(_onPipStateChanged);
    _videoPIPManager?.onBeforeEnterPip = null;
    _videoPIPManager?.disableAutoPip();
    PipService.onAutoPipEntering = null;
    _videoFilterManager?.dispose();

    _scrubPreviewSource?.dispose();

    // Mark sleep timer for restart if truly exiting (not episode transition)
    if (!_isReplacingWithVideo) {
      SleepTimerService().markNeedsRestart();
    }

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

    _autoPlayTimer?.cancel();

    _stillWatchingTimer?.cancel();

    _playNextCancelFocusNode.dispose();
    _playNextConfirmFocusNode.dispose();

    _stillWatchingPauseFocusNode.dispose();
    _stillWatchingContinueFocusNode.dispose();

    _screenFocusNode.removeListener(_onScreenFocusChanged);
    _screenFocusNode.dispose();

    _mediaControlsManager?.clear();
    _mediaControlsManager?.dispose();

    DiscordRPCService.instance.stopPlayback();
    TraktScrobbleService.instance.stopPlayback();
    TrackerCoordinator.instance.stopPlayback();

    if (Platform.isWindows && _displayModeService != null) {
      FullscreenStateManager().removeListener(_onFullscreenChanged);
    }
    if (!_isReplacingWithVideo &&
        Platform.isWindows &&
        _displayModeService != null &&
        _displayModeService!.anyChangeApplied) {
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

    _setWakelock(false);
    appLogger.d('Wakelock disabled');

    // Restore system UI and orientation preferences (skip if navigating to another video)
    if (!_isReplacingWithVideo) {
      OrientationHelper.restoreSystemUI();

      // Restore orientation based on cached device type (no context needed)
      try {
        if (_isPhone) {
          SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
        } else {
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
    final playerToDispose = player;
    player = null;
    if (playerToDispose != null) {
      unawaited(playerToDispose.dispose());
    }
    if (_activeId == _currentMetadata.id) {
      _activeId = null;
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

  String? _lastLogError;
  bool _sawServer500 = false;

  static final RegExp _server500Pattern = RegExp(r'\b(?:HTTP error |Response code: )500\b');

  // OS Media Controls Integration

  /// Navigate to a specific queue item (called from QueueSheet)
  Future<void> navigateToQueueItem(MediaItem metadata) async {
    _notifyWatchTogetherMediaChange(metadata: metadata);
    await _navigateToEpisode(metadata);
  }

  void _setPlayerState(VoidCallback fn) => setState(fn);

  bool _isSwitchingChannel = false;

  /// Wait briefly for profile settings to load in offline mode.
  /// This prevents default-track fallback when playback starts before
  /// UserProfileProvider finishes initialization.
  Future<void> _waitForProfileSettingsIfNeeded() async {
    if (!_isOfflinePlayback || !mounted) return;

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

  /// Session identifiers owned by this screen, forwarded to a replacement
  /// [VideoPlayerScreen] during quality/version/audio switches so the Plex
  /// transcode session is continued rather than restarted.
  String get playbackSessionIdentifier => _playbackSessionIdentifier;
  String get playbackTranscodeSessionId => _playbackTranscodeSessionId;

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
      if (!_isReplacingWithVideo) {
        await _restoreWindowsDisplayMode();
      }
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
          builder: (sheetContext) => _isPlayerInitialized && player != null
              ? _buildVideoPlayer(sheetContext)
              : (_playerInitializationError != null
                    ? _buildInitializationError(_playerInitializationError!)
                    : _buildLoadingSpinner()),
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
