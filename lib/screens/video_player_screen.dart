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
import '../widgets/overlay_sheet.dart';
import '../widgets/video_controls/video_controls.dart';
import '../widgets/video_controls/widgets/player_toast_indicator.dart';
import '../focus/focusable_button.dart';
import '../focus/input_mode_tracker.dart';
import '../focus/dpad_navigator.dart';
import '../focus/key_event_utils.dart';
import '../i18n/strings.g.dart';
import '../watch_together/providers/watch_together_provider.dart';
import '../watch_together/widgets/watch_together_overlay.dart';

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
  bool _isReplacingWithVideo = false; // Flag to skip orientation restoration during video-to-video navigation
  bool _isDisposingForNavigation = false;
  bool _isHandlingBack = false;
  ScrubPreviewSource? _scrubPreviewSource;

  // Live TV channel navigation
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

  // Live TV time-shift
  CaptureBuffer? _captureBuffer;
  int? _programBeginsAt;
  double _streamStartEpoch = 0;
  bool _isAtLiveEdge = true;
  String? _transcodeSessionId;

  /// Fallback level for live TV stream errors (mirrors Plex web client behavior).
  /// 0 = directStream+directStreamAudio, 1 = no directStream, 2 = no DS + no DS audio.
  int _liveStreamFallbackLevel = 0;
  bool _isRetryingLiveStream = false;

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

  /// Backend-neutral lookup. Returns whichever client (Plex or Jellyfin)
  /// owns this item. Used by the playback-init path in [_initializePlayer].
  MediaServerClient? _getMediaServerClient(BuildContext context) {
    final id = _currentMetadata.serverId;
    if (id == null) return null;
    return context.read<MultiServerProvider>().serverManager.getClient(id);
  }

  bool get _isOfflinePlayback => widget.isOffline || _effectiveIsOffline;

  ScrubFrame? _getThumbnailData(Duration time) => _scrubPreviewSource?.getFrame(time);

  final ValueNotifier<bool> _isBuffering = ValueNotifier<bool>(false); // Track if video is currently buffering
  final ValueNotifier<bool> _hasFirstFrame = ValueNotifier<bool>(false); // Track if first video frame has rendered
  final ValueNotifier<bool> _isExiting = ValueNotifier<bool>(false); // Track if navigating away (for black overlay)
  final ValueNotifier<bool> _controlsVisible = ValueNotifier<bool>(
    true,
  ); // Track if video controls are visible (for popup positioning)

  @override
  void initState() {
    super.initState();

    _currentMetadata = widget.metadata;
    _activeId = widget.metadata.id;
    _activeMediaIndex = widget.selectedMediaIndex;

    // Transcode session identifiers — reused across quality/version/audio
    // switches so the server-side transcode session is preserved.
    _playbackSessionIdentifier = widget.reusedSessionIdentifier ?? generateSessionIdentifier();
    _playbackTranscodeSessionId = widget.reusedTranscodeSessionId ?? generateSessionIdentifier();
    _selectedAudioStreamId = widget.selectedAudioStreamId;
    _effectiveIsOffline = widget.isOffline;
    // Quality preset is resolved later when the SettingsProvider is available;
    // see _resolveQualityPreset() called from _initializePlayer.
    _selectedQualityPreset = widget.selectedQualityPreset ?? TranscodeQualityPreset.original;

    // Initialize live TV channel tracking
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

  void _recordLifecycleState(String state, {String? action}) {
    final isTv = PlatformDetector.isTV();
    final pipActive = PipService().isPipActive.value;
    final breadcrumbData = <String, dynamic>{
      'state': state,
      'isTv': isTv,
      'autoPipEnabled': _autoPipEnabled,
      'pipActive': pipActive,
      'pipTransitionInFlight': _androidAutoPipTransitionInFlight,
      'hiddenForBackground': _hiddenForBackground,
      'backend': _playerBackendLabel,
    };
    if (action != null) {
      breadcrumbData['action'] = action;
    }

    Sentry.addBreadcrumb(
      Breadcrumb(message: 'Player lifecycle $state', category: 'player.lifecycle', data: breadcrumbData),
    );

    appLogger.d(
      'Player lifecycle: state=$state'
      '${action != null ? ' action=$action' : ''}'
      ' isTv=$isTv'
      ' autoPipEnabled=$_autoPipEnabled'
      ' pipActive=$pipActive'
      ' pipTransitionInFlight=$_androidAutoPipTransitionInFlight'
      ' hiddenForBackground=$_hiddenForBackground'
      ' backend=$_playerBackendLabel',
    );
  }

  void _setAndroidAutoPipTransitionInFlight(bool value, {required String reason}) {
    if (!Platform.isAndroid || _androidAutoPipTransitionInFlight == value) return;
    _androidAutoPipTransitionInFlight = value;
    _recordLifecycleState('pip_transition', action: '${value ? 'started' : 'cleared'}:$reason');
  }

  void _suspendLiveTimelineForBackground() {
    _resumeLiveTimelineOnResume = _liveTimelineTimer != null;
    _stopLiveTimelineUpdates();
  }

  void _resumeLiveTimelineAfterBackgroundIfNeeded() {
    final shouldResume = _resumeLiveTimelineOnResume;
    _resumeLiveTimelineOnResume = false;
    if (shouldResume && _liveSessionIdentifier != null) {
      _startLiveTimelineUpdates();
    }
  }

  Future<void> _handleAppHidden() async {
    if (_shouldSkipForPip) {
      _recordLifecycleState('hidden', action: 'skipped_for_pip');
      return;
    }

    // Suppress Watch Together heartbeats while backgrounded so App Nap
    // doesn't cause stale position broadcasts that make guests loop.
    _watchTogetherProvider?.setBackgrounded(true);

    final currentPlayer = player;
    if (currentPlayer == null || !_isPlayerInitialized) {
      _recordLifecycleState('hidden', action: 'skipped_no_player');
      return;
    }

    final isTv = PlatformDetector.isTV();
    final shouldPauseForBackground = PlatformDetector.isHandheld(context) || isTv;

    // Pause first so Android MPV does not keep decoding against a transient
    // background surface while the app is locking or hiding.
    if (shouldPauseForBackground) {
      _wasPlayingBeforeInactive = currentPlayer.state.isActive;
      if (_wasPlayingBeforeInactive) {
        try {
          await currentPlayer.pause();
          appLogger.d('Video paused due to app being hidden (${isTv ? 'tv' : 'handheld'})');
        } catch (e) {
          appLogger.w('Failed to pause video before background transition', error: e);
        }
      }
    }

    if (!mounted || currentPlayer != player) return;

    _suspendLiveTimelineForBackground();

    if (isTv) {
      _recordLifecycleState('hidden', action: 'tv_background_pause_only');
      return;
    }

    _hiddenForBackground = true;
    await currentPlayer.setVisible(false);
    _recordLifecycleState('hidden', action: 'render_hidden');
  }

  Future<void> _handleAppResumed() async {
    _recordLifecycleState('resumed', action: 'begin');
    _watchTogetherProvider?.setBackgrounded(false);

    if (Platform.isAndroid && _androidAutoPipTransitionInFlight && !PipService().isPipActive.value) {
      _setAndroidAutoPipTransitionInFlight(false, reason: 'resume_without_pip');
    }

    final currentPlayer = player;

    // Restore render layer if it was hidden for background, then force a
    // video-output refresh before any auto-resume logic runs.
    if (_hiddenForBackground && currentPlayer != null && _isPlayerInitialized) {
      await currentPlayer.setVisible(true);
      await currentPlayer.updateFrame();

      if (!mounted || currentPlayer != player) return;

      _hiddenForBackground = false;
      _recordLifecycleState('resumed', action: 'render_restored');
    }

    // Restore media controls and wakelock when app is resumed.
    if (_isPlayerInitialized && mounted) {
      await _restoreMediaControlsAfterResume();
    }

    _resumeLiveTimelineAfterBackgroundIfNeeded();
    _recordLifecycleState('resumed', action: 'complete');
  }

  Future<void> _initializePlayer() async {
    try {
      if (mounted) {
        setState(() => _playerInitializationError = null);
      }
      // Load buffer size from settings
      final settingsService = await SettingsService.getInstance();
      _videoPlayerNavigationEnabled = settingsService.read(SettingsService.videoPlayerNavigationEnabled);
      _autoPipEnabled = settingsService.read(SettingsService.autoPip);
      _rewindOnResume = settingsService.read(SettingsService.rewindOnResume);
      final bufferSizeMB = settingsService.read(SettingsService.bufferSize);
      final enableHardwareDecoding = settingsService.read(SettingsService.enableHardwareDecoding);
      final debugLoggingEnabled = settingsService.read(SettingsService.enableDebugLogging);
      final useExoPlayer = settingsService.read(SettingsService.useExoPlayer);

      // Initialize Windows display mode service.
      if (Platform.isWindows) {
        _displayModeService = DisplayModeService(settingsService, FullscreenStateManager());
        await _displayModeService!.syncWithNative();
        FullscreenStateManager().addListener(_onFullscreenChanged);
      }

      // Create player (on Android, uses ExoPlayer by default, MPV as fallback)
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

      // Platform-specific settings
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

      // Apply audio sync offset
      final audioSyncOffset = settingsService.read(SettingsService.audioSyncOffset);
      if (audioSyncOffset != 0) {
        final offsetSeconds = audioSyncOffset / 1000.0;
        await player!.setProperty('audio-delay', offsetSeconds.toString());
      }

      // Apply subtitle sync offset
      final subtitleSyncOffset = settingsService.read(SettingsService.subtitleSyncOffset);
      if (subtitleSyncOffset != 0) {
        final offsetSeconds = subtitleSyncOffset / 1000.0;
        await player!.setProperty('sub-delay', offsetSeconds.toString());
      }

      // Apply audio normalization (loudnorm filter)
      if (settingsService.read(SettingsService.audioNormalization)) {
        await player!.setProperty('af', 'loudnorm=I=-14:TP=-3:LRA=4');
      }

      // Apply custom MPV config entries
      final customMpvConfig = SettingsService.parseMpvConfigText(settingsService.read(SettingsService.mpvConfigText));
      for (final entry in customMpvConfig.entries) {
        try {
          await player!.setProperty(entry.key, entry.value);
          appLogger.d('Applied custom MPV property: ${entry.key}=${entry.value}');
        } catch (e) {
          appLogger.w('Failed to set MPV property ${entry.key}', error: e);
        }
      }

      // Set max volume limit for volume boost
      final maxVolume = settingsService.read(SettingsService.maxVolume);
      await player!.setProperty('volume-max', maxVolume.toString());

      // Apply saved volume (clamped to max volume)
      final savedVolume = settingsService.read(SettingsService.volume).clamp(0.0, maxVolume.toDouble());
      unawaited(player!.setVolume(savedVolume));

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
        unawaited(_setWakelock(true));
        appLogger.d('Wakelock enabled for video playback');
      }

      // Get the video URL and start playback
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

      // Listen to playback state changes
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

      // Listen to MPV errors
      _errorSubscription = player!.streams.error.listen(_onPlayerError);

      // warn is included so we can catch ffmpeg's "HTTP error 500" line in
      // _onPlayerLog — the error-level log that follows omits the status code.
      _logSubscription = player!.streams.log
          .where((log) => const {PlayerLogLevel.fatal, PlayerLogLevel.error, PlayerLogLevel.warn}.contains(log.level))
          .listen(_onPlayerLog);

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

      // Listen to playback restart to detect first frame ready
      _playbackRestartSubscription = player!.streams.playbackRestart.listen((_) async {
        _lastLogError = null;
        _sawServer500 = false;
        _liveStreamFallbackLevel = 0;
        if (!_hasFirstFrame.value) {
          _hasFirstFrame.value = true;
          unawaited(Sentry.addBreadcrumb(Breadcrumb(message: 'First frame ready', category: 'player')));

          // Apply frame rate matching on Android if enabled
          if (Platform.isAndroid && settingsService.read(SettingsService.matchContentFrameRate)) {
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

  String _safePlaybackErrorMessage(Object error) {
    final raw = error.toString();
    final redacted = LogRedactionManager.redact(raw);
    if (raw.contains('No client registered')) {
      return t.messages.errorLoading(error: 'Server is unavailable for the active profile');
    }
    return t.messages.errorLoading(error: redacted);
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
  Future<void> _applyFrameRateMatching() async {
    if (player == null || !Platform.isAndroid) return;
    if (_frameRateMatchingApplied) return;

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
      _frameRateMatchingApplied = true;
      final durationMs = player!.state.duration.inMilliseconds;
      final settingsService = await SettingsService.getInstance();
      final delaySec = settingsService.read(SettingsService.displaySwitchDelay);

      // Suppress spurious PauseEvent from MediaSession during HDMI renegotiation.
      // Fire Stick (and similar Android TV devices) send onPause() through the
      // MediaSession callback when the display mode changes for frame rate matching.
      _suppressMediaPauseDuringFrameRateSwitch = true;
      Future.delayed(Duration(seconds: 2 + delaySec + 1), () {
        _suppressMediaPauseDuringFrameRateSwitch = false;
      });

      // Pause so the playback clock doesn't advance while the TV renegotiates
      // HDMI. The native setVideoFrameRate call below awaits the real display
      // change event (+ settle + user delay) before returning, and then we
      // resume — same shape as the primary pre-playback path, just later.
      try {
        await player!.pause();
      } catch (e) {
        appLogger.w('Failed to pause before frame rate switch', error: e);
      }

      final didSwitch = await player!.setVideoFrameRate(fps, durationMs, extraDelayMs: delaySec * 1000);

      // Set MPV video-sync mode for smoother playback when display is synced
      try {
        await player!.setProperty('video-sync', 'display-tempo');
      } catch (e) {
        appLogger.d('video-sync property unsupported', error: e);
      }

      if (mounted && player != null) {
        await player!.play();
      }

      unawaited(
        Sentry.addBreadcrumb(
          Breadcrumb(
            message: 'Frame rate matching: ${fps}fps, switched=$didSwitch, delay=${delaySec}s',
            category: 'player',
          ),
        ),
      );
      appLogger.d('Frame rate matching: Set display to ${fps}fps (duration: ${durationMs}ms, switched=$didSwitch)');
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
      unawaited(Sentry.addBreadcrumb(Breadcrumb(message: 'Frame rate matching cleared', category: 'player')));
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

      final delay = await _displayModeService!.applyDisplayMatching(fps: fps, sigPeak: sigPeak);

      if (delay > Duration.zero) {
        await Future.delayed(delay);
      }
    } catch (e) {
      appLogger.w('Failed to apply display mode matching', error: e);
    }
  }

  /// Called when fullscreen state changes — apply or restore Windows display
  /// matching. On Windows the player opens windowed by default, so the initial
  /// attempt during `playbackRestart` is skipped by DisplayModeService's
  /// fullscreen gate. Catching the enter-fullscreen transition here lets the
  /// switch happen at the natural moment the user starts watching.
  void _onFullscreenChanged() {
    if (_displayModeService == null) return;
    if (FullscreenStateManager().isFullscreen) {
      if (_hasFirstFrame.value && !_displayModeService!.anyChangeApplied) {
        _applyWindowsDisplayMatching();
      }
    } else if (_displayModeService!.anyChangeApplied) {
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

  /// Wire the per-item playback services that need to (re)bind whenever
  /// the active media item changes: [PlaybackProgressTracker],
  /// [MediaControlsManager.updateMetadata], and the
  /// Discord/Trakt/Tracker scrobblers. Both [_initializeServices] and
  /// [_swapEpisodeInPip] call this so the two flows can't drift.
  ///
  /// The caller is responsible for ensuring `player != null` and (if the
  /// media-controls metadata refresh should run) for having created
  /// [_mediaControlsManager] before the first call.
  void _wirePerItemPlaybackServices({
    required MediaItem metadata,
    required MediaServerClient? mediaClient,
    required OfflineWatchSyncService? offlineWatchService,
    String? playSessionId,
    String? playMethod,
    MediaSourceInfo? mediaInfo,
  }) {
    if (player == null) return;

    // Progress tracker — offline mode queues for later sync; online mode
    // dispatches to the right backend through the neutral client.
    if (_isOfflinePlayback) {
      _progressTracker = PlaybackProgressTracker(
        client: null,
        metadata: metadata,
        player: player!,
        isOffline: true,
        offlineWatchService: offlineWatchService,
      );
      _progressTracker!.startTracking();
    } else if (mediaClient != null) {
      _progressTracker = PlaybackProgressTracker(
        client: mediaClient,
        metadata: metadata,
        player: player!,
        playMethod: playMethod ?? (_isTranscoding ? 'Transcode' : 'DirectPlay'),
        playSessionId: playSessionId,
        mediaInfo: mediaInfo,
      );
      _progressTracker!.startTracking();
    }

    // Media controls metadata. Fire-and-forget — the OS plugin downloads
    // the poster synchronously inside `setMetadata` (~270 ms); the
    // controls populate a beat after first frame which is fine.
    if (_mediaControlsManager != null) {
      unawaited(
        _mediaControlsManager!.updateMetadata(
          metadata: metadata,
          client: mediaClient,
          duration: metadata.durationMs != null ? Duration(milliseconds: metadata.durationMs!) : null,
        ),
      );
    }

    // Scrobblers — Discord RPC, Trakt, unified tracker. All accept the
    // neutral [MediaServerClient]; null short-circuits cleanly.
    if (mediaClient != null) {
      unawaited(DiscordRPCService.instance.startPlayback(metadata, mediaClient));
      unawaited(TraktScrobbleService.instance.startPlayback(metadata, mediaClient, isLive: widget.isLive));
      unawaited(TrackerCoordinator.instance.startPlayback(metadata, mediaClient, isLive: widget.isLive));
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

    // Get client (null in offline mode). Backend-neutral lookup so Jellyfin
    // items also wire a [PlaybackProgressTracker]; the tracker dispatches
    // to the right backend's reporting endpoints internally.
    final mediaClient = _isOfflinePlayback ? null : _getMediaServerClient(context);
    final offlineWatchService = context.read<OfflineWatchSyncService>();

    // Initialize media controls manager (must exist before the per-item
    // helper wires its metadata update).
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
        if (_suppressMediaPauseDuringFrameRateSwitch) {
          appLogger.d('Media control: Pause event suppressed (frame rate switch in progress)');
          return;
        }
        appLogger.d('Media control: Pause event received');
        currentPlayer!.pause();
        _updateMediaControlsPlaybackState();
      } else if (event is TogglePlayPauseEvent) {
        appLogger.d('Media control: Toggle play/pause event received');
        if (currentPlayer!.state.isActive) {
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

    // Wire progress tracker, media-controls metadata, and the
    // Discord/Trakt/Tracker scrobblers. Shared with [_swapEpisodeInPip]
    // so the two flows can't drift.
    _wirePerItemPlaybackServices(
      metadata: _currentMetadata,
      mediaClient: mediaClient,
      offlineWatchService: offlineWatchService,
      playSessionId: _playbackPlaySessionId,
      playMethod: _playbackPlayMethod,
      mediaInfo: _currentMediaInfo,
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
        isPlaying: player!.state.isActive,
        position: position,
        speed: player!.state.rate,
      );
      DiscordRPCService.instance.updatePosition(position);
      TraktScrobbleService.instance.updatePosition(position);
      TrackerCoordinator.instance.updatePosition(position);
      // Keep Trakt's known duration current — mpv only emits on the duration
      // stream once per load, but this is cheap and avoids an extra listener.
      TraktScrobbleService.instance.updateDuration(player!.state.duration);
      TrackerCoordinator.instance.updateDuration(player!.state.duration);
    });

    // Listen to playback rate changes for Discord Rich Presence
    _mediaControlsRateSubscription = player!.streams.rate.listen((rate) {
      DiscordRPCService.instance.updatePlaybackSpeed(rate);
    });

    _mediaControlsSeekableSubscription = player!.streams.seekable.listen((_) {
      unawaited(_syncMediaControlsAvailability());
    });
  }

  /// Ensure a play queue exists for sequential episode playback
  Future<void> _ensurePlayQueue() async {
    if (!mounted) return;

    // Skip play queue in offline mode (requires server connection)
    if (_isOfflinePlayback) return;

    // Skip play queue for live TV (would interfere with tuner session)
    if (widget.isLive) return;

    // Only create play queues for episodes
    if (!_currentMetadata.isEpisode) {
      return;
    }

    // Plex-only — Jellyfin's local queue is published by
    // EpisodeNavigationService._ensureLocalEpisodeQueue from
    // _loadAdjacentEpisodes, so this method is a no-op for it.
    if (_currentMetadata.backend != MediaBackend.plex) return;

    try {
      final client = context.getPlexClientForServer(_currentMetadata.serverId!);

      final playbackState = context.read<PlaybackStateProvider>();

      // Determine the show's rating key
      // For episodes, grandparentId points to the show
      final showRatingKey = _currentMetadata.grandparentId;
      if (showRatingKey == null) {
        appLogger.d('Episode missing grandparentId, skipping play queue creation');
        return;
      }

      // Check if there's already an active queue for THIS show.
      // A leftover queue from a different show or — more importantly —
      // from a different backend (Jellyfin's local queue is published
      // here too) would otherwise mask the new show's navigation.
      final existingContextKey = playbackState.shuffleContextKey;
      final isQueueActive = playbackState.isQueueActive;

      if (isQueueActive && existingContextKey == showRatingKey) {
        playbackState.setCurrentItem(_currentMetadata);
        appLogger.d('Using existing play queue (context: $existingContextKey)');
        return;
      }
      if (isQueueActive) {
        appLogger.d('Resetting stale play queue (was: $existingContextKey, now: $showRatingKey)');
        playbackState.clearShuffle();
      }

      // Create a new sequential play queue for the show
      appLogger.d('Creating sequential play queue for show $showRatingKey');
      final playQueue = await client.createShowPlayQueue(
        showRatingKey: showRatingKey,
        shuffle: 0, // Sequential order
        startingEpisodeKey: _currentMetadata.id,
      );

      if (playQueue != null && playQueue.items != null && playQueue.items!.isNotEmpty) {
        // Initialize playback state with the play queue
        await playbackState.setPlaybackFromPlayQueue(playQueue, showRatingKey);

        // Set the client for loading more items
        playbackState.setPlayQueueWindowFetcher(client.getPlayQueue);

        appLogger.d('Sequential play queue created with ${playQueue.items!.length} items');
      }
    } catch (e) {
      // Non-critical: Sequential playback will fall back to non-queue navigation
      appLogger.d('Could not create play queue for sequential playback', error: e);
    }
  }

  Future<void> _loadAdjacentEpisodes() async {
    if (!mounted || widget.isLive) return;

    if (_isOfflinePlayback) {
      // Offline mode: find next/previous from downloaded episodes
      _loadAdjacentEpisodesOffline();
      return;
    }

    try {
      // Load adjacent episodes using the service
      final adjacentEpisodes = await _episodeNavigation.loadAdjacentEpisodes(
        context: context,
        metadata: _currentMetadata,
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
    if (!_currentMetadata.isEpisode) return;

    final showKey = _currentMetadata.grandparentId;
    if (showKey == null) return;

    try {
      final downloadProvider = context.read<DownloadProvider>();
      final episodes = downloadProvider.getDownloadedEpisodesForShow(showKey);

      if (episodes.isEmpty) return;

      // Sort by aired date, falling back to season/episode number
      final sorted = List<MediaItem>.from(episodes)
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
      final currentIdx = sorted.indexWhere((ep) => ep.id == _currentMetadata.id);

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
        if (_liveStreamUrl != null) {
          streamUrl = _liveStreamUrl!;
          _streamStartEpoch = DateTime.now().millisecondsSinceEpoch / 1000.0;
          _isAtLiveEdge = true;
        } else {
          // Tune channel inside the player (shows loading spinner while tuning)
          final channels = widget.liveChannels;
          final channelIndex = _liveChannelIndex;
          if (channels == null || channelIndex < 0 || channelIndex >= channels.length) {
            throw Exception('No channel to tune');
          }
          final channel = channels[channelIndex];
          appLogger.d('Tune: dvrKey=$_liveDvrKey channelKey=${channel.key}');
          final client = _liveClient;
          if (client is! PlexClient) {
            throw StateError(
              'In-player live tuning is Plex-only; got ${client?.runtimeType ?? 'null'}. '
              'Jellyfin live TV must pass a pre-resolved liveStreamUrl via LiveTvSupport.resolveStreamUrl.',
            );
          }
          final dvrKey = _liveDvrKey;
          if (dvrKey == null) throw Exception('No DVR to tune');
          final tuneResult = await client.tuneChannel(dvrKey, channel.key);
          if (tuneResult == null) throw Exception('Failed to tune channel');

          _liveSessionIdentifier = tuneResult.sessionIdentifier;
          _liveSessionPath = tuneResult.sessionPath;
          _liveProgramId = tuneResult.metadata.ratingKey;
          _liveDurationMs = tuneResult.metadata.duration;
          _captureBuffer = tuneResult.captureBuffer;
          _programBeginsAt = tuneResult.beginsAt;
          _transcodeSessionId = generateSessionIdentifier();

          // Show "Watch from Start" dialog when an existing capture session has >60s of history.
          // On a fresh tune (no active recording), the buffer is empty so this won't trigger.
          int? offsetSeconds;
          if (_captureBuffer != null && _programBeginsAt != null) {
            final nowEpoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            final offsetProgramStart = _programBeginsAt! - _captureBuffer!.startedAt.round();
            // If a session recording started after current program start, offset of program start at will be negative.
            // If a session recording started before current program start, offset of program start will be positive.
            // If guide data is not available, program start will be equal to current time.
            final useProgramStart = offsetProgramStart > 0 && nowEpoch - _programBeginsAt! > 60;
            final effectiveStart = useProgramStart ? _programBeginsAt! : _captureBuffer!.seekableStartEpoch;
            final elapsed = nowEpoch - effectiveStart;
            appLogger.d(
              'Time-shift: buffer=${_captureBuffer!.seekableDurationSeconds}s, '
              'beginsAt=$_programBeginsAt, elapsed=${elapsed}s (need >60 for dialog)',
            );
            if (elapsed > 60) {
              final watchFromStart = await _showWatchFromStartDialog(effectiveStart, nowEpoch);
              if (!mounted) return;
              if (watchFromStart == true) {
                offsetSeconds = useProgramStart ? offsetProgramStart : _captureBuffer!.seekStartSeconds.round();
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

          streamUrl = client.buildLiveStreamUrl(streamPath);
          _liveStreamUrl = streamUrl;

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
        unawaited(_sendLiveTimeline('stopped'));
        if (mounted) {
          showErrorSnackBar(context, e.toString());
          unawaited(_handleBackButton());
        }
      }
      return;
    }

    // Capture providers before async gaps
    final offlineWatchService = context.read<OfflineWatchSyncService>();

    try {
      PlaybackInitializationResult result;
      Map<String, String>? streamHeaders;

      if (widget.isOffline) {
        // Offline mode: route through PlaybackInitializationService with a
        // (possibly null) cached client. The service reads cached media
        // info via the client when available, falls back to local file +
        // sidecar subtitles otherwise.
        final cachedSourceClient = _getMediaServerClient(context);
        final offlineService = PlaybackInitializationService(
          client: cachedSourceClient,
          database: context.read<AppDatabase>(),
        );
        result = await offlineService.getPlaybackData(
          metadata: _currentMetadata,
          selectedMediaIndex: widget.selectedMediaIndex,
          preferOffline: true,
        );
        if (result.videoUrl == null) {
          throw PlaybackException(t.messages.fileInfoNotAvailable);
        }
      } else {
        // Online path: `_playbackDataFuture` was kicked off in `_initializePlayer`
        // in parallel with MPV setup. Quality preset + server capabilities +
        // headers were resolved there too. Just await the result.
        streamHeaders = _streamHeaders;
        result = await _playbackDataFuture!;

        _isTranscoding = result.isTranscoding;
        _effectiveIsOffline = result.isOffline;
        _playbackPlaySessionId = result.playSessionId;
        _playbackPlayMethod = result.playMethod;
        if (result.activeAudioStreamId != null) {
          _selectedAudioStreamId = result.activeAudioStreamId;
        }

        if (result.fallbackReason != null && !_selectedQualityPreset.isOriginal) {
          if (mounted) {
            showErrorSnackBar(context, t.videoControls.transcodeUnavailableFallback);
          }
          // Reset the preset so the UI reflects what's actually playing.
          _selectedQualityPreset = TranscodeQualityPreset.original;
        }
      }

      // Primary refresh-rate path: when Plex metadata provides an fps and the
      // user has frame-rate matching on, open the player paused so the HDMI
      // refresh-rate switch can complete before any frame renders.
      final settingsService = await SettingsService.getInstance();
      final preKnownFps = result.mediaInfo?.frameRate;
      final willAutoSwitch =
          Platform.isAndroid &&
          settingsService.read(SettingsService.matchContentFrameRate) &&
          preKnownFps != null &&
          preKnownFps > 0;

      // Open video through Player
      if (result.videoUrl != null) {
        // Reset first frame flag and frame rate retry counter for new video
        _hasFirstFrame.value = false;
        _frameRateRetries = 0;
        _frameRateMatchingApplied = false;

        // Request audio focus before starting playback (Android)
        // This causes other media apps (Spotify, podcasts, etc.) to pause.
        // Fired in parallel with MPV setup in `_initializePlayer`; we await
        // the in-flight future here (usually already resolved).
        if (_audioFocusFuture != null) {
          await _audioFocusFuture;
          _audioFocusFuture = null;
        } else {
          await player!.requestAudioFocus();
        }

        // Pass resume position if available.
        // In offline mode, prefer locally tracked progress over the cached server value
        // since the user may have watched further since downloading.
        Duration? resumePosition;
        if (_isOfflinePlayback) {
          final globalKey = _currentMetadata.globalKey;
          final localOffset = await offlineWatchService.getLocalViewOffset(globalKey);
          if (localOffset != null && localOffset > 0) {
            resumePosition = Duration(milliseconds: localOffset);
            appLogger.d('Resuming offline playback from local progress: ${localOffset}ms');
          }
        }
        resumePosition ??= _currentMetadata.viewOffsetMs != null
            ? Duration(milliseconds: _currentMetadata.viewOffsetMs!)
            : null;

        // Enable FFmpeg auto-reconnect for VOD streams (covers network drops
        // up to 10 min). Forwarded to the Kotlin layer on Android so MPV
        // inherits it on the ExoPlayer→MPV fallback path (see
        // _onBackendSwitched), so keep it unconditional.
        if (!_isOfflinePlayback && !widget.isLive) {
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
          Media(result.videoUrl!, start: resumePosition, headers: streamHeaders),
          play: !willAutoSwitch && (isExoPlayer || !hasExternalSubs),
          externalSubtitles: isExoPlayer && hasExternalSubs ? result.externalSubtitles : null,
        );

        // Apply subtitle styling to ExoPlayer native layer (CaptionStyleCompat + libass font scale)
        // Must be called after open() since that's when ExoPlayer initializes
        if (player is PlayerAndroid) {
          await (player as PlayerAndroid).setSubtitleStyle(
            fontSize: settingsService.read(SettingsService.subtitleFontSize).toDouble(),
            textColor: settingsService.read(SettingsService.subtitleTextColor),
            borderSize: settingsService.read(SettingsService.subtitleBorderSize).toDouble(),
            borderColor: settingsService.read(SettingsService.subtitleBorderColor),
            bgColor: settingsService.read(SettingsService.subtitleBackgroundColor),
            bgOpacity: settingsService.read(SettingsService.subtitleBackgroundOpacity),
            subtitlePosition: settingsService.read(SettingsService.subtitlePosition),
            bold: settingsService.read(SettingsService.subtitleBold),
            italic: settingsService.read(SettingsService.subtitleItalic),
          );
        }

        // Attach player to Watch Together session for sync (if in session)
        if (mounted && !_isOfflinePlayback) {
          _attachToWatchTogetherSession();
          _notifyWatchTogetherMediaChange();
        }
      }

      // Update available versions from the playback data
      if (mounted) {
        setState(() {
          _availableVersions = result.availableVersions;
          _currentMediaInfo = result.mediaInfo;
          _scrubPreviewSource?.dispose();
          _scrubPreviewSource = null;
        });

        // Backend-neutral scrub-thumbnail load. The factory dispatches to
        // BIF (Plex) or trickplay sprite sheets (Jellyfin) and returns null
        // when the inputs aren't sufficient. Guard against media-change
        // races during the async load.
        final mediaClient = context.tryGetMediaClientForServer(_currentMetadata.serverId);
        final mediaInfoAtStart = _currentMediaInfo;
        if (mediaInfoAtStart != null && !_isOfflinePlayback && mediaClient != null) {
          unawaited(
            mediaClient
                .createScrubPreviewSource(item: _currentMetadata, mediaSource: mediaInfoAtStart)
                .then((service) {
                  if (service == null) return;
                  if (mounted && identical(_currentMediaInfo, mediaInfoAtStart)) {
                    setState(() => _scrubPreviewSource = service);
                  } else {
                    service.dispose();
                  }
                })
                .catchError((e, st) {
                  appLogger.w('Scrub preview load failed', error: e, stackTrace: st);
                }),
          );
        }

        await _initVideoFilterAndPip();

        if (player != null) {
          // Auto-PiP: set up callback for API 26-30 path and initial state
          if (_autoPipEnabled) {
            PipService.onAutoPipEntering = () {
              _setAndroidAutoPipTransitionInFlight(true, reason: 'native_auto_pip_entering');
              _videoFilterManager?.enterPipMode();
            };
            if (player!.state.playing) {
              unawaited(_videoPIPManager!.updateAutoPipState(isPlaying: true));
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

        // Track manager: owns track selection, external subtitle loading, and Plex
        // immediate stream writes. Jellyfin persists selected stream indexes through
        // playback progress reports instead.
        final plexTrackClient = mediaClient is PlexClient ? mediaClient : null;
        _trackManager = TrackManager(
          player: player!,
          isActive: () => mounted && player != null,
          persistTrackPreference: plexTrackClient != null ? _plexTrackPersister(() => plexTrackClient) : null,
          getProfileSettings: () => context.read<UserProfileProvider>().profileSettings,
          waitForProfileSettings: _waitForProfileSettingsIfNeeded,
          metadata: _currentMetadata,
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
            // When willAutoSwitch the pre-playback refresh-rate block below
            // owns the resume, so skip this one to avoid a double-play.
            if (!willAutoSwitch) {
              await _trackManager!.resumeAfterSubtitleLoad();
            }
          }
        } else {
          // Android (subs attached at open time) or no external subs:
          // apply once tracks are available
          _trackManager!.applyTrackSelectionWhenReady();
        }

        // Initiate the HDMI refresh-rate switch BEFORE any frame renders.
        // The player was opened paused; setVideoFrameRate awaits the real
        // display-change event (+ settle + user delay) before returning, and
        // then we start playback — so the first frame the user sees is after
        // the switch has settled.
        if (willAutoSwitch && mounted && player != null) {
          _frameRateMatchingApplied = true;
          final delaySec = settingsService.read(SettingsService.displaySwitchDelay);
          final durationMs = _currentMetadata.durationMs ?? player!.state.duration.inMilliseconds;
          _suppressMediaPauseDuringFrameRateSwitch = true;
          Future.delayed(Duration(seconds: 2 + delaySec + 1), () {
            _suppressMediaPauseDuringFrameRateSwitch = false;
          });
          bool didSwitch = false;
          try {
            didSwitch = await player!.setVideoFrameRate(preKnownFps, durationMs, extraDelayMs: delaySec * 1000);
            // MPV video-sync tuning (no-op on ExoPlayer).
            try {
              await player!.setProperty('video-sync', 'display-tempo');
            } catch (e) {
              appLogger.d('video-sync property unsupported on this player', error: e);
            }
          } catch (e) {
            appLogger.w('Failed to apply pre-playback frame rate matching', error: e);
          }

          // Always resume — either the switch completed and we want to play,
          // or no switch was needed and we need to start playback now that the
          // preparation gate has been cleared.
          if (mounted && player != null) {
            if (player is! PlayerAndroid && result.externalSubtitles.isNotEmpty) {
              await _trackManager!.resumeAfterSubtitleLoad();
            } else {
              await player!.play();
            }
          }

          unawaited(
            Sentry.addBreadcrumb(
              Breadcrumb(
                message: 'Pre-playback frame rate: ${preKnownFps}fps, switched=$didSwitch, delay=${delaySec}s',
                category: 'player',
              ),
            ),
          );
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

  /// Initialize VideoFilterManager and VideoPIPManager if not already set up.
  /// Called from both live TV and VOD playback paths.
  Future<void> _initVideoFilterAndPip() async {
    if (player == null || _videoFilterManager != null) return;
    final settings = await SettingsService.getInstance();
    _videoFilterManager = VideoFilterManager(
      player: player!,
      availableVersions: _availableVersions,
      selectedMediaIndex: widget.selectedMediaIndex,
      initialBoxFitMode: settings.read(SettingsService.defaultBoxFitMode),
      onBoxFitModeChanged: (mode) => settings.write(SettingsService.defaultBoxFitMode, mode),
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
    final isInPip = _videoPIPManager?.isPipActive.value ?? PipService().isPipActive.value;
    _setAndroidAutoPipTransitionInFlight(false, reason: 'pip_state_changed');
    _recordLifecycleState('pip_state_changed', action: isInPip ? 'entered' : 'exited');

    if (_videoPIPManager == null || _videoFilterManager == null) return;

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
      final presetId = settings.read(SettingsService.globalShaderPreset);
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
    if (!settings.read(SettingsService.ambientLighting)) return;

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
    unawaited(settings.write(SettingsService.ambientLighting, ambientLighting.isEnabled));

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
  /// If [metadata] is provided, uses that instead of _currentMetadata (for episode navigation)
  void _notifyWatchTogetherMediaChange({MediaItem? metadata}) {
    final targetMetadata = metadata ?? _currentMetadata;
    try {
      final watchTogether = context.read<WatchTogetherProvider>();
      if (watchTogether.isHost && watchTogether.isInSession) {
        watchTogether.setCurrentMedia(
          ratingKey: targetMetadata.id,
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

    // Fetch metadata for the new episode. WatchTogether's sync transport is
    // backend-neutral (sync_message.dart carries `ratingKey` + `serverId`
    // over WebRTC); resolving the item is just a `fetchItem` on whichever
    // backend the guest has registered for [serverId].
    final multiServer = context.read<MultiServerProvider>();
    final client = multiServer.getClientForServer(serverId);
    if (client == null) {
      appLogger.w('WatchTogether: Server $serverId not found for media switch');
      if (mounted) showAppSnackBar(context, t.watchTogether.guestSwitchUnavailable);
      return;
    }

    final metadata = await client.fetchItem(ratingKey);
    if (!mounted) return;
    if (metadata == null) {
      appLogger.w('WatchTogether: Could not fetch metadata for $ratingKey');
      showAppSnackBar(context, t.watchTogether.guestSwitchFailed);
      return;
    }

    // Detach and dispose current player before switching to avoid sync calls on a disposed instance
    _isReplacingWithVideo = true;
    await disposePlayerForNavigation();
    if (!mounted) return;

    // Use same navigation as local episode change (pushReplacement from player context)
    unawaited(navigateToVideoPlayer(context, metadata: metadata, usePushReplacement: true));
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
      final seekSeconds = settings.read(SettingsService.seekTimeSmall);
      if (widget.isLive && _captureBuffer != null) {
        await _seekLivePosition(_currentPositionEpoch + seekSeconds);
        return;
      }
      final target = clampSeekPosition(player!, player!.state.position + Duration(seconds: seekSeconds));
      await player!.seek(target);
    };
    receiver.onSeekBackward = () async {
      if (player == null) return;
      final settings = await SettingsService.getInstance();
      final seekSeconds = settings.read(SettingsService.seekTimeSmall);
      if (widget.isLive && _captureBuffer != null) {
        await _seekLivePosition(_currentPositionEpoch - seekSeconds);
        return;
      }
      final target = clampSeekPosition(player!, player!.state.position - Duration(seconds: seekSeconds));
      await player!.seek(target);
    };
    receiver.onVolumeUp = () async {
      if (player == null) return;
      final settings = await SettingsService.getInstance();
      final maxVol = settings.read(SettingsService.maxVolume).toDouble();
      final newVolume = (player!.state.volume + 10).clamp(0.0, maxVol);
      unawaited(player!.setVolume(newVolume));
      unawaited(settings.write(SettingsService.volume, newVolume));
    };
    receiver.onVolumeDown = () async {
      if (player == null) return;
      final settings = await SettingsService.getInstance();
      final maxVol = settings.read(SettingsService.maxVolume).toDouble();
      final newVolume = (player!.state.volume - 10).clamp(0.0, maxVol);
      unawaited(player!.setVolume(newVolume));
      unawaited(settings.write(SettingsService.volume, newVolume));
    };
    receiver.onVolumeMute = () async {
      if (player == null) return;
      final settings = await SettingsService.getInstance();
      final newVolume = player!.state.volume > 0 ? 0.0 : 100.0;
      unawaited(player!.setVolume(newVolume));
      unawaited(settings.write(SettingsService.volume, newVolume));
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
    } catch (e) {
      appLogger.d('CompanionRemote provider unavailable', error: e);
    }
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
    _toastController.dispose();

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

    // Release cached scrub-thumbnail data (BIF or trickplay)
    _scrubPreviewSource?.dispose();

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

    // Clear Discord Rich Presence + send Trakt stop scrobble
    DiscordRPCService.instance.stopPlayback();
    TraktScrobbleService.instance.stopPlayback();
    TrackerCoordinator.instance.stopPlayback();

    // Clean up Windows display mode service
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

    // Update Discord Rich Presence + Trakt scrobble
    if (isPlaying) {
      DiscordRPCService.instance.resumePlayback();
      TraktScrobbleService.instance.resumePlayback();
    } else {
      DiscordRPCService.instance.pausePlayback();
      TraktScrobbleService.instance.pausePlayback();
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
    if (!completed) return;
    // Ignore spurious EOF from the old file during in-place episode swap
    if (_isSwappingEpisode) return;

    // mpv does not flip the `pause` property on EOF, so _onPlayingStateChanged
    // never fires false.  Normalize all playback-dependent state.
    unawaited(_setWakelock(false));
    unawaited(_progressTracker?.sendProgress('paused'));
    _updateMediaControlsPlaybackState();
    unawaited(DiscordRPCService.instance.pausePlayback());
    unawaited(TraktScrobbleService.instance.pausePlayback());
    if (_autoPipEnabled) {
      unawaited(_videoPIPManager?.updateAutoPipState(isPlaying: false));
    }

    if (_nextEpisode != null && !_showPlayNextDialog && !_showStillWatchingPrompt && !_completionTriggered) {
      _completionTriggered = true;

      // PiP: skip dialog (user can't interact), auto-play immediately
      if (PipService().isPipActive.value) {
        unawaited(_playNext());
        return;
      }

      // Capture keyboard mode before async gap
      final isKeyboardMode = PlatformDetector.isTV() && InputModeTracker.isKeyboardMode(context);

      final settings = await SettingsService.getInstance();
      final autoPlayEnabled = settings.read(SettingsService.autoPlayNextEpisode);

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
    } else if (_nextEpisode == null && !_completionTriggered) {
      _completionTriggered = true;
      unawaited(_handleBackButton());
    }
  }

  void _onPlayerError(PlayerError err) {
    appLogger.e('[Player ERROR] ${err.message}');
    if (!mounted || _isExiting.value) return;

    // Fatal, unrecoverable until server-side fix — show modal instead of a snackbar.
    if (err.cause == PlayerError.serverHttp500 || _sawServer500) {
      _showServerLimitDialog();
      return;
    }

    // Live TV: retry with progressively degraded stream settings
    // (mirrors Plex web client fallback chain).
    if (widget.isLive && _liveStreamFallbackLevel < 2 && !_isRetryingLiveStream) {
      _liveStreamFallbackLevel++;
      _isRetryingLiveStream = true;
      appLogger.w('Live stream failed, retrying with fallback level $_liveStreamFallbackLevel');
      _retryLiveStream().whenComplete(() => _isRetryingLiveStream = false);
      return;
    }

    showGlobalErrorSnackBar(_redactPlayerError(_lastLogError ?? err.message));
    _handleBackButton();
  }

  String? _lastLogError;
  bool _sawServer500 = false;

  static final RegExp _server500Pattern = RegExp(r'\b(?:HTTP error |Response code: )500\b');

  void _onPlayerLog(PlayerLog log) {
    if (!_sawServer500 && _server500Pattern.hasMatch(log.text)) {
      _sawServer500 = true;
    }
    if (log.level == PlayerLogLevel.error || log.level == PlayerLogLevel.fatal) {
      appLogger.e('[Player LOG ERROR] [${log.prefix}] ${log.text}');
      _lastLogError = _redactPlayerError(log.text.trim());
    }
  }

  String _redactPlayerError(String message) => LogRedactionManager.redact(message);

  Future<void> _showServerLimitDialog() async {
    if (!mounted) return;
    await showServerLimitDialog(context);
    if (mounted) unawaited(_handleBackButton());
  }

  /// Handle notification when native player switched from ExoPlayer to MPV
  Future<void> _onBackendSwitched() async {
    _playerBackendLabel = 'mpv';
    _recordLifecycleState('backend_switched', action: 'mpv_fallback');

    _toastController.show(
      Symbols.swap_horiz_rounded,
      t.messages.switchingToCompatiblePlayer,
      duration: const Duration(seconds: 2),
    );

    await _trackManager?.onBackendSwitched();
  }

  // OS Media Controls Integration

  Future<void> _syncMediaControlsAvailability() async {
    final manager = _mediaControlsManager;
    final currentPlayer = player;
    if (!mounted || manager == null || currentPlayer == null) return;

    final playbackState = context.read<PlaybackStateProvider>();
    final canNavigateEpisodes = _currentMetadata.isEpisode || playbackState.isPlaylistActive;
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

    unawaited(_setWakelock(player?.state.isActive ?? false));

    final manager = _mediaControlsManager;
    final currentPlayer = player;
    if (manager != null && currentPlayer != null) {
      final client = _isOfflinePlayback ? null : _getMediaServerClient(context);
      await manager.updateMetadata(
        metadata: _currentMetadata,
        client: client,
        duration: _currentMetadata.durationMs != null ? Duration(milliseconds: _currentMetadata.durationMs!) : null,
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
    appLogger.d('Media controls restored on app resume');
  }

  /// Wrapper method to update media controls playback state
  void _updateMediaControlsPlaybackState() {
    if (player == null) return;

    _mediaControlsManager?.updatePlaybackState(
      isPlaying: player!.state.isActive,
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
    if (_previousEpisode == null || _isLoadingPrevious) return;

    _notifyWatchTogetherMediaChange(metadata: _previousEpisode);

    setState(() {
      _isLoadingPrevious = true;
    });

    await _navigateToEpisode(_previousEpisode!);
  }

  /// Navigate to a specific queue item (called from QueueSheet)
  Future<void> navigateToQueueItem(MediaItem metadata) async {
    _notifyWatchTogetherMediaChange(metadata: metadata);
    await _navigateToEpisode(metadata);
  }

  bool _isSwitchingChannel = false;

  /// Switch to an adjacent live TV channel (delta: +1 for next, -1 for previous)
  /// Start periodic timeline heartbeats for live TV transcode session.
  void _startLiveTimelineUpdates() {
    final generation = ++_liveTimelineGeneration;
    _liveTimelineTimer?.cancel();
    _liveTimelineTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (generation != _liveTimelineGeneration) return;
      final state = player?.state.playing == true ? 'playing' : 'paused';
      _sendLiveTimeline(state);
    });
    // Delay initial heartbeat to let the transcode session stabilize.
    // Sending time=0 immediately after player.open() causes the server
    // to spawn a duplicate transcode job with offset=-1 that 404s.
    Future.delayed(const Duration(seconds: 3), () {
      if (_liveTimelineTimer != null && generation == _liveTimelineGeneration) {
        final state = player?.state.playing == true ? 'playing' : 'paused';
        _sendLiveTimeline(state);
      }
    });
  }

  void _stopLiveTimelineUpdates() {
    _liveTimelineGeneration++;
    _liveTimelineTimer?.cancel();
    _liveTimelineTimer = null;
  }

  Future<void> _sendLiveTimeline(String state) async {
    final client = _liveClient;
    final playbackTime = _livePlaybackStartTime != null
        ? DateTime.now().difference(_livePlaybackStartTime!).inMilliseconds
        : 0;

    if (client is PlexClient) {
      final sessionId = _liveSessionIdentifier;
      final sessionPath = _liveSessionPath;
      if (sessionId == null || sessionPath == null) return;
      try {
        // Use the program ratingKey from tune metadata, not the channel key
        final ratingKey = _liveProgramId ?? _liveItemId ?? widget.metadata.id;
        // For live TV, player position/duration are unreliable (often 0).
        // Use playbackTime as time, and program duration from tune metadata.
        // Plex rejects timeline pings where time > duration; grow duration to
        // match — otherwise Tunarr-style short synthetic programs 400 mid-stream.
        final time = playbackTime;
        final duration = max(_liveDurationMs ?? 0, time);
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
        appLogger.d('Plex live timeline update failed', error: e);
      }
      return;
    }

    if (client is JellyfinClient) {
      await _jellyfinLiveSession.report(
        client: client,
        itemId: _liveItemId ?? widget.metadata.id,
        state: state,
        position: Duration(milliseconds: playbackTime),
        duration: Duration(milliseconds: _liveDurationMs ?? 0),
      );
      return;
    }
  }

  /// Retry the live stream with degraded direct-stream settings.
  ///
  /// Plex re-tunes the channel for a fresh capture session (the previous one
  /// expires while MPV exhausts its reconnect attempts). Jellyfin streams the
  /// channel directly with a session-less URL, so retry is just re-opening
  /// that URL — degradation knobs apply only to the Plex transcoder branch.
  Future<void> _retryLiveStream() async {
    final client = _liveClient;
    final ds = _liveStreamFallbackLevel < 1;
    final dsa = _liveStreamFallbackLevel < 2;

    if (client is PlexClient) {
      final channels = widget.liveChannels;
      final channelIndex = _liveChannelIndex;
      final dvrKey = _liveDvrKey;
      if (channels == null || channelIndex < 0 || channelIndex >= channels.length || dvrKey == null) {
        appLogger.w('Cannot retry live stream — missing session info');
        showGlobalErrorSnackBar(_redactPlayerError(_lastLogError ?? 'Live stream failed'));
        unawaited(_handleBackButton());
        return;
      }
      final channel = channels[channelIndex];
      appLogger.i('Retrying live stream (re-tune ${channel.key}): directStream=$ds directStreamAudio=$dsa');

      // Re-tune to get a fresh capture session — the previous one is dead.
      final tuneResult = await client.tuneChannel(dvrKey, channel.key);
      if (tuneResult == null || !mounted) {
        showGlobalErrorSnackBar(_redactPlayerError(_lastLogError ?? 'Live stream failed'));
        unawaited(_handleBackButton());
        return;
      }

      _liveSessionIdentifier = tuneResult.sessionIdentifier;
      _liveSessionPath = tuneResult.sessionPath;
      _transcodeSessionId = generateSessionIdentifier();

      final streamPath = await client.buildLiveStreamPath(
        sessionPath: tuneResult.sessionPath,
        sessionIdentifier: tuneResult.sessionIdentifier,
        transcodeSessionId: _transcodeSessionId!,
        directStream: ds,
        directStreamAudio: dsa,
      );
      if (streamPath == null || !mounted) {
        showGlobalErrorSnackBar(_redactPlayerError(_lastLogError ?? 'Live stream failed'));
        unawaited(_handleBackButton());
        return;
      }

      final streamUrl = client.buildLiveStreamUrl(streamPath);
      _liveStreamUrl = streamUrl;
      _livePlaybackStartTime = DateTime.now();
      _streamStartEpoch = DateTime.now().millisecondsSinceEpoch / 1000.0;
      _isAtLiveEdge = true;

      await _setLiveStreamOptions();
      await player!.open(Media(streamUrl, headers: const {'Accept-Language': 'en'}), play: true, isLive: true);
      return;
    }

    final liveStreamUrl = _liveStreamUrl;
    if (client is JellyfinClient && liveStreamUrl != null) {
      appLogger.i('Retrying Jellyfin live stream by re-opening URL');
      _livePlaybackStartTime = DateTime.now();
      _streamStartEpoch = DateTime.now().millisecondsSinceEpoch / 1000.0;
      _isAtLiveEdge = true;
      await _setLiveStreamOptions();
      await player!.open(Media(liveStreamUrl, headers: const {'Accept-Language': 'en'}), play: true, isLive: true);
      return;
    }

    appLogger.w('Cannot retry live stream — no compatible client/URL available');
    showGlobalErrorSnackBar(_redactPlayerError(_lastLogError ?? 'Live stream failed'));
    unawaited(_handleBackButton());
  }

  /// Force mpv to reconnect its HTTP stream by seeking to the current position.
  /// This bypasses ffmpeg's exponential reconnect backoff when the app detects
  /// that network connectivity has been restored.
  void _forceStreamReconnect() {
    final p = player;
    if (p == null || !_isPlayerInitialized) return;
    final pos = p.state.position;
    appLogger.i('Network restored while buffering, forcing stream reconnect at ${pos.inSeconds}s');
    // Clear any stale completion latch caused by a spurious EOF during the drop,
    // so the real end-of-file can trigger Play Next after we recover.
    if (_completionTriggered && !_showPlayNextDialog && _autoPlayTimer?.isActive != true) {
      _completionTriggered = false;
    }
    p.seek(pos);
  }

  /// Configure MPV options for live streaming.
  /// The official Plex Media Player does not set client-side reconnect options —
  /// reconnection is handled by the server's transcoder on the input side.
  Future<void> _setLiveStreamOptions() async {
    await player!.setProperty('force-seekable', 'no');
  }

  /// The current playback position as an absolute epoch second (for live TV time-shift).
  int get _currentPositionEpoch => (_streamStartEpoch + (player?.state.position.inSeconds ?? 0)).round();

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
    if (_captureBuffer == null ||
        _liveSessionPath == null ||
        _liveSessionIdentifier == null ||
        _transcodeSessionId == null) {
      return;
    }

    final clamped = targetEpochSeconds.clamp(_captureBuffer!.seekableStartEpoch, _captureBuffer!.seekableEndEpoch);

    final offsetSeconds = clamped - _captureBuffer!.startedAt.round();

    // Live seek requires a transcode session — Plex-only by protocol. The
    // Plex path populates _captureBuffer; the Jellyfin path never does, so
    // the early-return above already covers Jellyfin in practice. This
    // explicit guard keeps the contract obvious.
    final client = _liveClient;
    if (client is! PlexClient) return;

    final streamPath = await client.buildLiveStreamPath(
      sessionPath: _liveSessionPath!,
      sessionIdentifier: _liveSessionIdentifier!,
      transcodeSessionId: _transcodeSessionId!,
      offsetSeconds: offsetSeconds,
    );
    if (streamPath == null || !mounted) return;

    final streamUrl = client.buildLiveStreamUrl(streamPath);

    _streamStartEpoch = _captureBuffer!.startedAt + offsetSeconds;
    _isAtLiveEdge = (clamped >= _captureBuffer!.seekableEndEpoch - _liveEdgeThresholdSeconds);
    _livePlaybackStartTime = DateTime.now();

    await _setLiveStreamOptions();
    await player!.open(Media(streamUrl, headers: const {'Accept-Language': 'en'}), play: true, isLive: true);
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
      final serverInfo = liveTvServerInfoForChannel(multiServer, channel);

      if (serverInfo == null) return;

      final genericClient = multiServer.getClientForServer(serverInfo.serverId);
      final resolution = await genericClient?.liveTv.resolveStreamUrl(channel.key, dvrKey: serverInfo.dvrKey);
      if (resolution != null) {
        // Jellyfin: pre-resolved negotiated URL.
        await _setLiveStreamOptions();
        await player!.open(Media(resolution.url, headers: const {'Accept-Language': 'en'}), play: true, isLive: true);
        _liveClient = genericClient;
        _liveDvrKey = serverInfo.dvrKey;
        _liveStreamUrl = resolution.url;
        _liveItemId = channel.key;
        _liveSessionIdentifier = resolution.playSessionId;
        _jellyfinLiveSession = JellyfinLiveSessionTracker(playSessionId: resolution.playSessionId);
        _livePlaybackStartTime = DateTime.now();
        _captureBuffer = null;
        _programBeginsAt = null;
        _liveProgramId = null;
        _liveDurationMs = null;
        _streamStartEpoch = DateTime.now().millisecondsSinceEpoch / 1000.0;
        _isAtLiveEdge = true;
        if (!mounted) return;
        setState(() {
          _liveChannelIndex = newIndex;
          _liveChannelName = channel.displayName;
        });
        _startLiveTimelineUpdates();
        return;
      }

      // Plex-only: DVR tune flow (Jellyfin Live TV uses pre-resolved URLs).
      final client = multiServer.getPlexClientForServer(serverInfo.serverId);
      if (client == null) return;

      final tuneResult = await client.tuneChannel(serverInfo.dvrKey, channel.key);
      if (tuneResult == null || !mounted) return;

      _transcodeSessionId = generateSessionIdentifier();
      _liveStreamFallbackLevel = 0;

      final streamPath = await client.buildLiveStreamPath(
        sessionPath: tuneResult.sessionPath,
        sessionIdentifier: tuneResult.sessionIdentifier,
        transcodeSessionId: _transcodeSessionId!,
      );
      if (streamPath == null || !mounted) return;

      final streamUrl = client.buildLiveStreamUrl(streamPath);

      await _setLiveStreamOptions();
      await player!.open(Media(streamUrl, headers: const {'Accept-Language': 'en'}), play: true, isLive: true);

      _liveClient = client;
      _liveDvrKey = serverInfo.dvrKey;
      _liveStreamUrl = streamUrl;
      _liveItemId = channel.key;
      _livePlaybackStartTime = DateTime.now();
      _liveProgramId = tuneResult.metadata.ratingKey;
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

  /// Navigates to a new episode, preserving playback state and track selections.
  /// When PiP is active, swaps the media source in-place to keep the PiP window alive.
  Future<void> _navigateToEpisode(MediaItem episodeMetadata) async {
    // PiP active: swap media in-place to keep the PiP window alive. The
    // swap path threads the neutral [MediaServerClient] through
    // [PlaybackInitializationService] and the lifecycle services, so it
    // works for both Plex and Jellyfin sessions.
    if (PipService().isPipActive.value && player != null) {
      await _swapEpisodeInPip(episodeMetadata);
      return;
    }

    // Set flag to skip orientation restoration in dispose()
    _isReplacingWithVideo = true;

    // Clear Discord Rich Presence + Trakt scrobble before switching episodes
    unawaited(DiscordRPCService.instance.stopPlayback());
    unawaited(TraktScrobbleService.instance.stopPlayback());
    unawaited(TrackerCoordinator.instance.stopPlayback());

    // If player isn't available, navigate without preserving settings
    if (player == null) {
      if (mounted) {
        unawaited(
          navigateToVideoPlayer(
            context,
            metadata: episodeMetadata,
            usePushReplacement: true,
            isOffline: _isOfflinePlayback,
          ),
        );
      }
      return;
    }

    // Capture current state atomically to avoid race conditions
    final currentPlayer = player;
    if (currentPlayer == null) {
      // Player already disposed, navigate without preserving settings
      if (mounted) {
        unawaited(
          navigateToVideoPlayer(
            context,
            metadata: episodeMetadata,
            usePushReplacement: true,
            isOffline: _isOfflinePlayback,
          ),
        );
      }
      return;
    }

    final currentAudioTrack = currentPlayer.state.track.audio;
    final currentSubtitleTrack = currentPlayer.state.track.subtitle;
    final currentSecondarySubtitleTrack = currentPlayer.state.track.secondarySubtitle;

    // Pause and stop current playback
    unawaited(currentPlayer.pause());
    await _progressTracker?.sendProgress('stopped');
    _progressTracker?.stopTracking();

    // Ensure the native player is fully disposed before creating the next one
    await disposePlayerForNavigation();

    // Navigate to the episode using pushReplacement to destroy current player
    if (mounted) {
      unawaited(
        navigateToVideoPlayer(
          context,
          metadata: episodeMetadata,
          preferredAudioTrack: currentAudioTrack,
          preferredSubtitleTrack: currentSubtitleTrack,
          preferredSecondarySubtitleTrack: currentSecondarySubtitleTrack,
          usePushReplacement: true,
          isOffline: _isOfflinePlayback,
        ),
      );
    }
  }

  /// Swap to a new episode while keeping the player alive for PiP continuity.
  /// Reuses the existing mpv instance (and its Metal layer in PiP) and only
  /// reloads the media source + resets Dart-side services.
  Future<void> _swapEpisodeInPip(MediaItem episodeMetadata) async {
    _isSwappingEpisode = true;
    final currentPlayer = player!;
    final previousMetadata = _currentMetadata;

    final currentAudioTrack = currentPlayer.state.track.audio;
    final currentSubtitleTrack = currentPlayer.state.track.subtitle;
    final currentSecondarySubtitleTrack = currentPlayer.state.track.secondarySubtitle;

    // Capture context-dependent values before async gaps. The neutral
    // [PlaybackInitializationService] consumes [mediaClient] regardless of
    // backend. We still narrow to [plexClient] for [TrackManager]'s
    // server-side track persistence, which is Plex-only — Jellyfin
    // sessions get a null `getPlexClient` and skip that path.
    final mediaClient = _isOfflinePlayback ? null : _getMediaServerClient(context);
    final plexClient = mediaClient is PlexClient ? mediaClient : null;
    final streamHeaders = mediaClient?.streamHeaders ?? const <String, String>{};
    final offlineWatchService = context.read<OfflineWatchSyncService>();
    final userProfileProvider = context.read<UserProfileProvider>();
    final playbackState = context.read<PlaybackStateProvider>();
    final database = context.read<AppDatabase>();

    await _progressTracker?.sendProgress('stopped');
    _progressTracker?.stopTracking();
    _progressTracker?.dispose();
    _progressTracker = null;
    unawaited(DiscordRPCService.instance.stopPlayback());
    unawaited(TraktScrobbleService.instance.stopPlayback());
    unawaited(TrackerCoordinator.instance.stopPlayback());

    _currentMetadata = episodeMetadata;
    _activeId = episodeMetadata.id;
    _showPlayNextDialog = false;
    _autoPlayTimer?.cancel();
    _hasFirstFrame.value = false;

    try {
      // Same service shape works for both online (mediaClient non-null,
      // bundled video URL + media info) and pure-offline (mediaClient null,
      // local file + cached media info if available).
      final playbackService = PlaybackInitializationService(client: mediaClient, database: database);
      final result = await playbackService.getPlaybackData(
        metadata: episodeMetadata,
        selectedMediaIndex: widget.selectedMediaIndex,
        preferOffline: _isOfflinePlayback || _selectedQualityPreset.isOriginal,
        qualityPreset: _selectedQualityPreset,
        selectedAudioStreamId: _selectedAudioStreamId,
        sessionIdentifier: _playbackSessionIdentifier,
        transcodeSessionId: _playbackTranscodeSessionId,
      );

      if (result.videoUrl == null) {
        throw PlaybackException('No video URL available');
      }

      Duration? resumePosition;
      _isTranscoding = result.isTranscoding;
      _effectiveIsOffline = result.isOffline;
      _playbackPlaySessionId = result.playSessionId;
      _playbackPlayMethod = result.playMethod;
      if (result.activeAudioStreamId != null) {
        _selectedAudioStreamId = result.activeAudioStreamId;
      }
      if (result.fallbackReason != null && !_selectedQualityPreset.isOriginal) {
        if (mounted) {
          showErrorSnackBar(context, t.videoControls.transcodeUnavailableFallback);
        }
        _selectedQualityPreset = TranscodeQualityPreset.original;
      }

      if (_isOfflinePlayback) {
        final localOffset = await offlineWatchService.getLocalViewOffset(episodeMetadata.globalKey);
        if (localOffset != null && localOffset > 0) {
          resumePosition = Duration(milliseconds: localOffset);
        }
      }
      resumePosition ??= episodeMetadata.viewOffsetMs != null
          ? Duration(milliseconds: episodeMetadata.viewOffsetMs!)
          : null;

      final hasExternalSubs = result.externalSubtitles.isNotEmpty;
      final isExoPlayer = player is PlayerAndroid;
      await currentPlayer.open(
        Media(result.videoUrl!, start: resumePosition, headers: streamHeaders),
        play: isExoPlayer || !hasExternalSubs,
        externalSubtitles: isExoPlayer && hasExternalSubs ? result.externalSubtitles : null,
      );

      _completionTriggered = false;
      _isSwappingEpisode = false;

      if (!mounted) return;

      _scrubPreviewSource?.dispose();
      setState(() {
        _availableVersions = result.availableVersions;
        _currentMediaInfo = result.mediaInfo;
        _scrubPreviewSource = null;
        _isLoadingNext = false;
      });

      _trackManager?.dispose();
      _trackManager = TrackManager(
        player: currentPlayer,
        isActive: () => mounted && player != null,
        // Plex writes track changes immediately. Jellyfin persists selected
        // indexes through playback progress reports.
        persistTrackPreference: plexClient != null ? _plexTrackPersister(() => plexClient) : null,
        getProfileSettings: () => userProfileProvider.profileSettings,
        waitForProfileSettings: _waitForProfileSettingsIfNeeded,
        metadata: episodeMetadata,
        mediaInfo: _currentMediaInfo,
        preferredAudioTrack: currentAudioTrack,
        preferredSubtitleTrack: currentSubtitleTrack,
        preferredSecondarySubtitleTrack: currentSecondarySubtitleTrack,
        showMessage: (message, {duration}) {
          if (mounted) showAppSnackBar(context, message, duration: duration);
        },
      );
      _trackManager!.cacheExternalSubtitles(result.externalSubtitles);

      if (player is! PlayerAndroid && hasExternalSubs) {
        _trackManager!.waitingForExternalSubsTrackSelection = true;
        try {
          await _trackManager!.addExternalSubtitles(result.externalSubtitles);
        } finally {
          await _trackManager!.resumeAfterSubtitleLoad();
        }
      } else {
        _trackManager!.applyTrackSelectionWhenReady();
      }

      // Wire progress tracker, media-controls metadata, and the
      // Discord/Trakt/Tracker scrobblers — same helper as the initial
      // start flow, so any future change lands in both paths together.
      _wirePerItemPlaybackServices(
        metadata: episodeMetadata,
        mediaClient: mediaClient,
        offlineWatchService: offlineWatchService,
        playSessionId: _playbackPlaySessionId,
        playMethod: _playbackPlayMethod,
        mediaInfo: _currentMediaInfo,
      );

      try {
        playbackState.setCurrentItem(episodeMetadata);
      } catch (e) {
        appLogger.d('playbackState.setCurrentItem failed', error: e);
      }

      await _loadAdjacentEpisodes();

      if (_autoPipEnabled) {
        unawaited(_videoPIPManager?.updateAutoPipState(isPlaying: currentPlayer.state.playing));
      }
    } catch (e) {
      _isSwappingEpisode = false;
      _completionTriggered = false;
      _currentMetadata = previousMetadata;
      _activeId = previousMetadata.id;
      appLogger.e('Failed to swap episode in PiP', error: e);
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

  Widget _buildLoadingSpinner() {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }

  Widget _buildInitializationError(String message) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppIcon(Symbols.error_rounded, color: Colors.white70, size: 44, fill: 1),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton(
                      autofocus: true,
                      onPressed: () {
                        final playerToDispose = player;
                        player = null;
                        if (playerToDispose != null) unawaited(playerToDispose.dispose());
                        setState(() {
                          _playerInitializationError = null;
                          _isPlayerInitialized = false;
                        });
                        unawaited(_initializePlayer());
                      },
                      child: Text(t.common.retry),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(onPressed: () => unawaited(_handleBackButton()), child: Text(t.common.back)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
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
          builder: (sheetContext) => _isPlayerInitialized && player != null
              ? _buildVideoPlayer(sheetContext)
              : (_playerInitializationError != null
                    ? _buildInitializationError(_playerInitializationError!)
                    : _buildLoadingSpinner()),
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
                        _currentMetadata,
                        onNext: onNext,
                        onPrevious: onPrevious,
                        availableVersions: _availableVersions,
                        selectedMediaIndex: widget.selectedMediaIndex,
                        selectedQualityPreset: _selectedQualityPreset,
                        serverSupportsTranscoding: _serverSupportsTranscoding,
                        isTranscoding: _isTranscoding,
                        isOfflinePlayback: _isOfflinePlayback,
                        sourceAudioTracks: _currentMediaInfo?.audioTracks ?? const [],
                        selectedAudioStreamId: _selectedAudioStreamId,
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
                        onReachedEnd: () => _onVideoCompleted(true),
                        canControl: canControl,
                        hasFirstFrame: _hasFirstFrame,
                        playNextFocusNode: _showPlayNextDialog ? _playNextConfirmFocusNode : null,
                        controlsVisible: _controlsVisible,
                        shaderService: _shaderService,
                        // ignore: no-empty-block - setState triggers rebuild to reflect shader change
                        onShaderChanged: () => setState(() {}),
                        thumbnailDataBuilder: _scrubPreviewSource?.isAvailable == true ? _getThumbnailData : null,
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
                        toastController: _toastController,
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
                  fit: StackFit.expand,
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
                    // Watch Together: participant join/leave/buffering notifications
                    const ParticipantNotificationOverlay(),
                    // Watch Together: waiting for participants to load
                    const WaitingForParticipantsIndicator(),
                    // Watch Together: syncing indicator during drift correction
                    const SyncingIndicator(),
                  ],
                ),
              ),
              // Black overlay during exit (no spinner - just covers transparency)
              ValueListenableBuilder<bool>(
                valueListenable: _isExiting,
                builder: (context, isExiting, child) {
                  if (!isExiting) return const SizedBox.shrink();
                  return const Positioned.fill(child: ColoredBox(color: Colors.black));
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
