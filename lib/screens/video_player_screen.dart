import 'dart:async';
import '../media/ids.dart';
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
import '../media/media_display_criteria.dart';
import '../media/media_server_user_profile.dart';
import '../media/media_item.dart';
import '../media/media_item_types.dart';
import '../media/media_server_client.dart';
import '../media/episode_collection.dart';
import '../media/live_tv_support.dart';
import '../models/livetv_channel.dart';
import '../services/live_seek_accumulator.dart';
import '../services/plex_client.dart';
import '../utils/session_identifier.dart';
import '../database/app_database.dart';
import '../media/media_version.dart';
import '../models/transcode_quality_preset.dart';
import '../media/media_source_info.dart';
import '../mixins/mounted_set_state_mixin.dart';
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
import '../services/apple_tv_remote_touch_service.dart';
import '../services/media_controls_manager.dart';
import '../services/playback_coordinator.dart';
import '../services/playback_initialization_service.dart';
import '../services/playback_context.dart';
import '../services/local_playback_history.dart';
import '../services/playback_session.dart';
import '../services/playback_progress_tracker.dart';
import '../services/playback_source_resolver.dart';
import '../services/offline_watch_sync_service.dart';
import '../services/display_mode_service.dart';
import '../services/settings_service.dart';
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
import '../utils/stream_buffer_sizing.dart';
import '../utils/video_player_navigation.dart';
import 'video_player/completion_latch.dart';
import 'video_player/frame_rate_matcher.dart';
import 'video_player/live_tv_session_args.dart';
import 'video_player/live_tv_session_state.dart';
import 'video_player/tv_background_suspend_policy.dart';
import 'video_player/widgets/player_prompt_overlays.dart';
import '../widgets/overlay_sheet.dart';
import '../widgets/video_controls/player_chrome_controller.dart';
import '../widgets/video_controls/video_controls.dart';
import '../widgets/video_controls/widgets/player_toast_indicator.dart';
import '../focus/focusable_button.dart';
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
part 'video_player/parts/pip.dart';
part 'video_player/parts/shader.dart';
part 'video_player/parts/playback_open.dart';
part 'video_player/parts/playback_prompts.dart';
part 'video_player/parts/playback_services.dart';
part 'video_player/parts/playback_start.dart';
part 'video_player/parts/seeking.dart';
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

/// The in-place media-source transitions a [VideoPlayerScreenState] can run.
/// They are mutually exclusive by construction — entry points bail while a
/// transition is in flight.
enum _PlaybackTransition { idle, reloadingMedia, restartingTranscode, switchingChannel }

/// Handle for one playback attempt (initial start, in-place reload,
/// transcode restart). Async continuations check [isCurrent] after every
/// await: it holds while the screen is mounted, the captured player is
/// still the active one, and no newer attempt has bumped the generation.
class _PlaybackAttempt {
  _PlaybackAttempt._(this._owner, this.generation, this.player);

  final VideoPlayerScreenState _owner;
  final int generation;
  final Player player;

  bool get isCurrent => _owner._isCurrentPlaybackGeneration(generation, player);
}

class _PlaybackOpenTiming {
  final Duration? mediaStart;
  final Duration timelineOffset;
  final Duration? timelineDuration;

  const _PlaybackOpenTiming({this.mediaStart, required this.timelineOffset, this.timelineDuration});
}

_PlaybackOpenTiming _playbackOpenTiming({
  required MediaBackend backend,
  required bool isTranscoding,
  required Duration? resumePosition,
  required int? durationMs,
}) {
  final usesSourceOffsetTranscode = isTranscoding && backend == MediaBackend.plex;
  return _PlaybackOpenTiming(
    mediaStart: usesSourceOffsetTranscode ? null : resumePosition,
    timelineOffset: usesSourceOffsetTranscode ? resumePosition ?? Duration.zero : Duration.zero,
    timelineDuration: isTranscoding && durationMs != null ? Duration(milliseconds: durationMs) : null,
  );
}

/// Builds a [TrackPreferencePersister] that writes the per-episode stream
/// selection out to a [PlexClient] resolved lazily on each call. Returns a
/// no-op-on-null persister so the [TrackManager] doesn't have to import
/// [PlexClient] itself; the resolver returning null (e.g. when the active
/// server is Jellyfin) makes the call short-circuit.
///
/// Only the current episode's part is touched — we deliberately do NOT write
/// the show-wide audio/subtitle language default (#1393): an in-player track
/// change should not silently rewrite the whole series' Plex prefs. The
/// explicit path for that lives in the metadata-edit UI.
TrackPreferencePersister _plexTrackPersister(PlexClient? Function() resolve) {
  return ({required int partId, required String trackType, int? streamID}) async {
    if (streamID == null) return;
    final client = resolve();
    if (client == null) return;
    await (trackType == 'audio'
        ? client.selectStreams(partId, audioStreamID: streamID, allParts: true)
        : client.selectStreams(partId, subtitleStreamID: streamID, allParts: true));
  };
}

class VideoPlayerScreen extends StatefulWidget {
  final MediaItem metadata;
  final AudioTrack? preferredAudioTrack;
  final SubtitleTrack? preferredSubtitleTrack;
  final SubtitleTrack? preferredSecondarySubtitleTrack;
  final int selectedMediaIndex;
  final String? selectedMediaSourceId;

  /// Version signature of a saved preference backing [selectedMediaIndex]
  /// when that index is unverified (see
  /// [PlaybackInitializationOptions.preferredVersionSignature]). Null for
  /// explicit user selections.
  final String? preferredVersionSignature;
  final bool isOffline;

  /// Quality preset override for this playback. When `null`, the screen uses
  /// the user's [SettingsService.defaultQualityPreset].
  final TranscodeQualityPreset? selectedQualityPreset;

  /// Audio stream ID to pass to the transcoder when [selectedQualityPreset]
  /// is non-original. When `null`, the playback service picks the `selected`
  /// Plex audio track (fallback: first).
  final int? selectedAudioStreamId;

  /// Present iff this screen plays live TV; carries the whole live launch
  /// state (see [LiveTvSessionArgs]).
  final LiveTvSessionArgs? live;

  bool get isLive => live != null;

  const VideoPlayerScreen({
    super.key,
    required this.metadata,
    this.preferredAudioTrack,
    this.preferredSubtitleTrack,
    this.preferredSecondarySubtitleTrack,
    this.selectedMediaIndex = 0,
    this.selectedMediaSourceId,
    this.preferredVersionSignature,
    this.isOffline = false,
    this.selectedQualityPreset,
    this.selectedAudioStreamId,
    this.live,
  });

  @override
  State<VideoPlayerScreen> createState() => VideoPlayerScreenState();
}

class VideoPlayerScreenState extends State<VideoPlayerScreen> with WidgetsBindingObserver, MountedSetStateMixin {
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

  // In-flight media-source transition. At most one can run at a time: the
  // entry guards make reload / transcode-restart / channel-switch mutually
  // exclusive instead of relying on three independent booleans.
  _PlaybackTransition _playbackTransition = _PlaybackTransition.idle;
  bool _playbackIntentShouldPlay = true;

  /// Media key of the last Watch Together switch failure the user was
  /// toasted about — the heartbeat retry loop must not re-toast every 2s.
  String? _wtSwitchToastShownForKey;

  bool _showPlayNextDialog = false;
  bool _isPhone = false;
  late int _effectiveSelectedMediaIndex;

  /// Media source id to request on the next resolve: the caller's initial
  /// selection, then re-synced to the session's post-fallback effective id
  /// by [_commitPlaybackSession]. Post-resolve consumers must read
  /// `_playbackSession.mediaSourceId`, never this field.
  String? _requestedMediaSourceId;
  bool get _offlineLibraryMode => widget.isOffline;

  // Transcode / quality state
  late TranscodeQualityPreset _selectedQualityPreset;
  int? _selectedAudioStreamId;
  AudioTrack? _preferredAudioTrack;
  SubtitleTrack? _preferredSubtitleTrack;
  SubtitleTrack? _preferredSecondarySubtitleTrack;
  bool _serverSupportsTranscoding = false;
  // Kicked off early in `_initializePlayer` for online non-live playback so
  // the metadata fetch (and transcode-decision HTTP, if non-original preset)
  // overlaps with MPV property configuration. Awaited inside `_startPlayback`
  // immediately before `player.open()` needs the video URL.
  Future<PlaybackContext>? _playbackDataFuture;

  // The item currently loaded in the player: resolver output + effective
  // selections, swapped atomically by [_commitPlaybackSession]. Null until
  // the first resolve lands and always null for live TV (which tunes
  // through its own path). The getters below denormalize it for the many
  // existing read sites.
  PlaybackSession? _playbackSession;
  int _playbackGeneration = 0;
  // Fired in parallel with MPV setup so the OS audio-focus negotiation
  // (~90ms on Android) doesn't sit on the critical path. Awaited before
  // `player.open()` so the semantics are unchanged — we just eat the cost
  // during otherwise-idle setup time.
  Future<void>? _audioFocusFuture;
  late final String _playbackSessionIdentifier;
  late String _playbackTranscodeSessionId;
  StreamSubscription<PlayerError>? _errorSubscription;
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<bool>? _completedSubscription;
  StreamSubscription<dynamic>? _mediaControlSubscription;
  StreamSubscription<AppleTvRemotePlayPauseAction>? _appleTvPlayPauseSubscription;
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
  bool _isHandlingBack = false;

  /// Set just before this screen replaces itself with another player route
  /// (the fallback pushReplacement paths). Dispose then skips the app-level
  /// player-exit side effects because the replacement continues the session.
  bool _isReplacingWithVideo = false;
  ScrubPreviewSource? _scrubPreviewSource;

  /// Live TV session state (tune identity, heartbeats, capture buffer,
  /// retry ladder) — inert for VOD screens. See [LiveTvSessionState].
  late final LiveTvSessionState _live = LiveTvSessionState(widget.live);

  /// Coalesces rapid relative live-TV skips into a single transcode re-open so
  /// mashing skip-forward can't compound into an overshoot to live (#1253).
  /// Lazily built; its closures read the current live state on each call.
  late final LiveSeekAccumulator _liveSeek = LiveSeekAccumulator(
    seek: _runLiveSeek,
    currentEpoch: () => _rawPositionEpoch,
    positionSeconds: () => player?.state.position.inSeconds ?? 0,
    bounds: _liveSeekBounds,
    onChanged: _onLiveSeekTargetChanged,
  );

  Timer? _autoPlayTimer;
  int _autoPlayCountdown = 5;

  // End-of-video Play Next latch. Completion comes from the player EOF signal;
  // position ticks only re-arm once playback is more than 2s from the end.
  final CompletionLatch _completionLatch = CompletionLatch(rearmWindowMs: 2000);

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
  bool _mediaControlsSuspendedForTvBackground = false;
  bool _resumeAfterAppleAudioSessionPause = false;
  DateTime? _lastPlaybackPauseAt;
  bool _autoPipEnabled = false;
  bool _exitFullscreenOnPlayerClose = false;
  bool _androidAutoPipTransitionInFlight = false;
  bool _pipFiltersPrepared = false;
  VoidCallback? _autoPipEnteringCallback;
  int _rewindOnResume = 0;
  Future<void> _lifecycleTransition = Future<void>.value();
  String _playerBackendLabel = 'unknown';

  /// Android TV: release the native AV pipeline once the app stays
  /// backgrounded past this grace window. A merely paused player keeps its
  /// MediaCodec decoders and (tunneled passthrough) AudioTrack alive, which
  /// on shared-pipeline TV SoCs degrades every other app until Plezy is
  /// force-stopped. The grace absorbs transient hidden/paused blips
  /// (assistant overlay, HDMI-CEC events) so quick app switches don't churn
  /// codecs.
  static const Duration _tvBackgroundPlayerSuspendGrace = Duration(seconds: 30);
  Timer? _tvBackgroundPlayerSuspendTimer;
  bool _playerSuspendedForTvBackground = false;
  Duration? _tvBackgroundSuspendPosition;
  AudioTrack? _tvBackgroundSuspendAudioTrack;
  SubtitleTrack? _tvBackgroundSuspendSubtitleTrack;
  SubtitleTrack? _tvBackgroundSuspendSecondarySubtitleTrack;

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
  Size? _lastVideoLayoutSize;
  Size? _pendingVideoLayoutSize;
  Player? _lastVideoLayoutPlayer;
  bool _videoLayoutUpdateScheduled = false;
  double? _pinchStartZoomScale;
  int _pinchZoomActivationUpdateCount = 0;
  bool _isPinchZooming = false;
  bool _pinchZoomChanged = false;
  final EpisodeNavigationService _episodeNavigation = EpisodeNavigationService();

  WatchTogetherProvider? _watchTogetherProvider;

  CompanionRemoteProvider? _companionRemoteProvider;
  VoidCallback? _savedOnHome;

  /// Backend-neutral lookup. Returns whichever client (Plex or Jellyfin)
  /// owns this item. Used by the playback-init path in [_initializePlayer].
  MediaServerClient? _getMediaServerClient(BuildContext context) {
    final id = _currentMetadata.serverId;
    if (id == null) return null;
    return context.read<MultiServerProvider>().serverManager.getClient(ServerId(id));
  }

  MediaServerClient? _getOnlineMediaServerClient(BuildContext context) {
    final id = _currentMetadata.serverId;
    if (id == null) return null;
    final manager = context.read<MultiServerProvider>().serverManager;
    if (!manager.isClientOnline(ServerId(id))) return null;
    return manager.getClient(ServerId(id));
  }

  // Denormalized views over the committed [PlaybackSession]. Read sites
  // keep their historical names; live TV (no session) gets the defaults.
  PlaybackContext? get _playbackContext => _playbackSession?.context;
  bool get _isTranscoding => _playbackSession?.isTranscoding ?? false;
  bool get _effectiveIsOffline => _playbackSession?.isOffline ?? false;
  String? get _playbackPlaySessionId => _playbackSession?.playSessionId;
  String? get _playbackPlayMethod => _playbackSession?.playMethod;
  List<MediaVersion> get _availableVersions => _playbackSession?.availableVersions ?? const [];
  MediaSourceInfo? get _currentMediaInfo => _playbackSession?.mediaInfo;

  bool get _usesLocalPlaybackSource => _effectiveIsOffline;

  bool get _isOfflinePlayback => _offlineLibraryMode || _effectiveIsOffline;

  /// Atomically publish a freshly opened [PlaybackSession] and refine the
  /// selection-intent fields from what the backend actually delivered
  /// (clamped version index, active audio stream, post-fallback preset).
  ///
  /// Reload-style flows call this from the open boundary: a failure before
  /// the commit leaves the previous session — and everything derived from
  /// it — untouched, so there is nothing to roll back.
  void _commitPlaybackSession(PlaybackSession session) {
    _playbackSession = session;
    _effectiveSelectedMediaIndex = session.mediaIndex;
    _requestedMediaSourceId = session.mediaSourceId;
    _selectedQualityPreset = session.qualityPreset;
    _selectedAudioStreamId = session.audioStreamId;
    // Every successful open passes through here (never live TV), making it
    // the chokepoint for the local last-played history. Offline plays are
    // excluded — like version prefs, the history describes online intent.
    if (!session.isOffline) {
      unawaited(LocalPlaybackHistory.recordPlayback(session.metadata));
    }
  }

  ScrubFrame? _getThumbnailData(Duration time) => _scrubPreviewSource?.getFrame(time);

  int _beginPlaybackGeneration({bool isMediaReload = false}) {
    if (!isMediaReload) _playbackTransition = _PlaybackTransition.idle;
    return ++_playbackGeneration;
  }

  /// Start a new playback attempt: bumps the generation and captures the
  /// owning player so async continuations can check [_PlaybackAttempt.isCurrent]
  /// uniformly instead of threading (generation, player) pairs around.
  _PlaybackAttempt _beginPlaybackAttempt(Player currentPlayer, {bool isMediaReload = false}) {
    return _PlaybackAttempt._(this, _beginPlaybackGeneration(isMediaReload: isMediaReload), currentPlayer);
  }

  bool _isCurrentPlaybackGeneration(int generation, Player currentPlayer) {
    return mounted && player == currentPlayer && _playbackGeneration == generation;
  }

  Future<void> _playWithPlaybackIntent(Player currentPlayer) {
    _playbackIntentShouldPlay = true;
    return currentPlayer.play();
  }

  Future<void> _pauseWithPlaybackIntent(Player currentPlayer) {
    _playbackIntentShouldPlay = false;
    return currentPlayer.pause();
  }

  Future<void> _playOrPauseWithPlaybackIntent(Player currentPlayer) {
    _playbackIntentShouldPlay = !currentPlayer.state.playing;
    return currentPlayer.playOrPause();
  }

  final ValueNotifier<bool> _isBuffering = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _hasFirstFrame = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isExiting = ValueNotifier<bool>(false);
  final PlayerChromeController _chromeController = PlayerChromeController();

  @override
  void initState() {
    super.initState();

    _currentMetadata = widget.metadata;
    _activeId = widget.metadata.id;
    _activeMediaIndex = widget.selectedMediaIndex;
    _effectiveSelectedMediaIndex = widget.selectedMediaIndex;
    _requestedMediaSourceId = widget.selectedMediaSourceId;

    // Reused across in-place quality/version/audio switches so the
    // server-side transcode session is preserved.
    _playbackSessionIdentifier = generateSessionIdentifier();
    _playbackTranscodeSessionId = generateSessionIdentifier();
    _selectedAudioStreamId = widget.selectedAudioStreamId;
    _preferredAudioTrack = widget.preferredAudioTrack;
    _preferredSubtitleTrack = widget.preferredSubtitleTrack;
    _preferredSecondarySubtitleTrack = widget.preferredSecondarySubtitleTrack;
    _selectedQualityPreset = widget.selectedQualityPreset ?? TranscodeQualityPreset.original;

    _playNextCancelFocusNode = FocusNode(debugLabel: 'PlayNextCancel');
    _playNextConfirmFocusNode = FocusNode(debugLabel: 'PlayNextConfirm');

    _stillWatchingPauseFocusNode = FocusNode(debugLabel: 'StillWatchingPause');
    _stillWatchingContinueFocusNode = FocusNode(debugLabel: 'StillWatchingContinue');

    // Screen-level focus node that wraps the entire build output.
    // Ensures a single stable focus target across loading → initialized phases.
    _screenFocusNode = FocusNode(debugLabel: 'VideoPlayerScreen');
    _screenFocusNode.addListener(_onScreenFocusChanged);

    appLogger.d('VideoPlayerScreen initialized for: ${_currentMetadata.title}');
    if (_preferredAudioTrack != null) {
      appLogger.d(
        'Preferred audio track: ${_preferredAudioTrack!.title ?? _preferredAudioTrack!.id} (${_preferredAudioTrack!.language ?? "unknown"})',
      );
    }
    if (_preferredSubtitleTrack != null) {
      final subtitleDesc = _preferredSubtitleTrack!.id == "no"
          ? "OFF"
          : "${_preferredSubtitleTrack!.title ?? _preferredSubtitleTrack!.id} (${_preferredSubtitleTrack!.language ?? "unknown"})";
      appLogger.d('Preferred subtitle track: $subtitleDesc');
    }

    try {
      final playbackState = context.read<PlaybackStateProvider>();

      // Defer both operations until after the first frame to avoid calling
      // notifyListeners() during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Keep the queue when this item belongs to it — that covers both
        // server-side queues (Plex `playQueueItemId`) and client-side
        // launcher-seeded queues (Jellyfin playlist/collection/shuffled
        // show, with synthetic ids tracked in the provider). For genuine
        // standalone playback (continue-watching, direct episode tap with no
        // queue launcher) clear any stale queue so prev/next stays consistent.
        final meta = _currentMetadata;
        if (playbackState.isItemInActiveQueue(meta)) {
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
    _setupAppleTvRemotePlaybackActions();

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
        // We don't support background playback
        if (_shouldSuspendMediaControlsForTvBackground) {
          unawaited(_suspendMediaControlsForTvBackground('paused'));
        } else {
          unawaited(_mediaControlsManager?.clear());
        }
        unawaited(_setWakelock(false));
        _recordLifecycleState('paused', action: 'backgrounded');
        break;
      case AppLifecycleState.resumed:
        // Synchronously, before the queued transition: a pending suspend must
        // not fire between this event and _handleAppResumed running.
        _cancelTvBackgroundPlayerSuspendTimer();
        _recordLifecycleState('resumed');
        _enqueueLifecycleTransition('resumed', _handleAppResumed);
        break;
      case AppLifecycleState.detached:
        _recordLifecycleState('detached');
        break;
    }
  }

  Future<void> _initializePlayer() async {
    var initPhase = 'starting';
    try {
      if (mounted) {
        setState(() => _playerInitializationError = null);
      }
      initPhase = 'loading settings';
      final settingsService = await SettingsService.getInstance();
      if (!mounted) return;
      _videoPlayerNavigationEnabled = settingsService.read(SettingsService.videoPlayerNavigationEnabled);
      _autoPipEnabled = settingsService.read(SettingsService.autoPip);
      _exitFullscreenOnPlayerClose = settingsService.read(SettingsService.exitFullscreenOnPlayerClose);
      _rewindOnResume = settingsService.read(SettingsService.rewindOnResume);
      final bufferSizeMB = settingsService.read(SettingsService.bufferSize);
      final enableHardwareDecoding = settingsService.read(SettingsService.enableHardwareDecoding);
      final debugLoggingEnabled = settingsService.read(SettingsService.enableDebugLogging);
      final useExoPlayer = settingsService.read(SettingsService.useExoPlayer);

      if (Platform.isWindows) {
        initPhase = 'syncing display mode';
        _displayModeService = DisplayModeService(settingsService, FullscreenStateManager());
        await _displayModeService!.syncWithNative();
        if (!mounted) return;
        FullscreenStateManager().addListener(_onFullscreenChanged);
      }

      // One-native-instance rule: a live music session owns the only audio
      // core — stop it and wait for its dispose before constructing the
      // video core (see PlaybackCoordinator).
      initPhase = 'claiming playback session';
      await PlaybackCoordinator.instance.claimVideo();
      if (!mounted) return;

      initPhase = 'creating player';
      final currentPlayer = Player(useExoPlayer: useExoPlayer);
      player = currentPlayer;
      _playerBackendLabel = currentPlayer.playerType;
      if (Platform.isAndroid && useExoPlayer) {
        await currentPlayer.setLogLevel(debugLoggingEnabled ? 'v' : 'warn');
        if (!mounted || player != currentPlayer) return;
      }

      // Kick off getPlaybackData() in parallel with the rest of MPV setup.
      // The network/DB work has no dependency on the player — it just needs
      // the context (providers), which is still safe to touch here because
      // no async gaps invalidate it before the calls below read it.
      // Skipped for live TV (has its own tune path) and offline (its own
      // branch in _startPlayback).
      if (!widget.isLive && !_offlineLibraryMode && mounted) {
        // Backend-neutral lookup so Jellyfin items also flow through here.
        // Plex-specific transcoder caching is gated on capabilities below;
        // Jellyfin's `streamHeaders` is empty because it embeds api_key in
        // the query string, while Plex returns the X-Plex-* identity headers.
        final genericClient = _getMediaServerClient(context);
        if (genericClient == null) {
          throw StateError('No client registered for ${_currentMetadata.serverId}');
        }
        // Single source of truth for showing quality controls and applying the
        // saved startup quality. Backends that cannot transcode always start at
        // Original even if the user picked a lower default quality.
        _serverSupportsTranscoding = genericClient.capabilities.videoTranscoding;
        if (widget.selectedQualityPreset == null) {
          _selectedQualityPreset = _serverSupportsTranscoding
              ? settingsService.read(SettingsService.defaultQualityPreset)
              : TranscodeQualityPreset.original;
        } else {
          _selectedQualityPreset = widget.selectedQualityPreset!;
        }
        final playbackResolver = PlaybackSourceResolver(
          serverManager: context.read<MultiServerProvider>().serverManager,
          database: context.read<AppDatabase>(),
        );
        _playbackDataFuture = playbackResolver.resolve(
          metadata: _currentMetadata,
          selectedMediaIndex: _effectiveSelectedMediaIndex,
          selectedMediaSourceId: _requestedMediaSourceId,
          preferredVersionSignature: widget.preferredVersionSignature,
          offlineLibraryMode: false,
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

      if (!mounted || player != currentPlayer) return;
      initPhase = 'configuring player';
      await currentPlayer.configureSubtitleFonts();
      await currentPlayer.setProperty('sub-ass', 'yes'); // Enable libass
      if (Platform.isAndroid && useExoPlayer) {
        final tunneledPlayback = settingsService.read(SettingsService.tunneledPlayback);
        await currentPlayer.setProperty('tunneled-playback', tunneledPlayback ? 'yes' : 'no');
      }
      if ((Platform.isAndroid && useExoPlayer) || Platform.isIOS || Platform.isMacOS) {
        final dvConversionMode = settingsService.read(SettingsService.dvConversionMode);
        await currentPlayer.setProperty('dv-conversion-mode', dvConversionMode.nativeValue);
      }
      if (Platform.isIOS || Platform.isMacOS) {
        await currentPlayer.setProperty('dv-conversion-log', debugLoggingEnabled ? 'yes' : 'no');
      }
      if (bufferSizeMB > 0) {
        final bufferSizeBytes = bufferSizeMB * 1024 * 1024;
        await currentPlayer.setProperty('demuxer-max-bytes', bufferSizeBytes.toString());
        final backBytes = bufferSizeBytes ~/ 4;
        await currentPlayer.setProperty('demuxer-max-back-bytes', backBytes.toString());
      }
      if (Platform.isAndroid) {
        // Cap demuxer buffers based on device heap to prevent OOM crashes.
        // Without limits, mpv defaults can consume 225MB+ just for demuxer
        // buffering, which combined with decoded frames and GPU textures
        // exhausts the process address space on memory-constrained devices.
        final heapMB = await PlayerAndroid.getHeapSize();
        if (!mounted || player != currentPlayer) return;
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
            await currentPlayer.setProperty('demuxer-max-bytes', '${autoForwardMB * 1024 * 1024}');
            await currentPlayer.setProperty('demuxer-max-back-bytes', '${autoBackMB * 1024 * 1024}');
          } else {
            // Manual mode: cap back-buffer relative to heap if 1/4 ratio is too high
            final maxBackBytes = min(bufferSizeMB * 1024 * 1024 ~/ 4, autoBackMB * 1024 * 1024);
            await currentPlayer.setProperty('demuxer-max-back-bytes', maxBackBytes.toString());
          }
        }
      }
      // requestAudioFocus initializes Android players, so start it only after
      // init-time ExoPlayer options above have been cached.
      if (Platform.isAndroid && !widget.isLive) {
        _audioFocusFuture = currentPlayer.requestAudioFocus();
        _audioFocusFuture!.ignore();
      }
      await currentPlayer.setProperty('msg-level', debugLoggingEnabled ? 'all=debug,ffmpeg/video=warn' : 'all=error');
      await currentPlayer.setLogLevel(debugLoggingEnabled ? 'v' : 'warn');
      await currentPlayer.setProperty('hwdec', _getHwdecValue(enableHardwareDecoding));

      await currentPlayer.setProperty(
        'sub-font-size',
        settingsService.read(SettingsService.subtitleFontSize).toString(),
      );
      await currentPlayer.setProperty('sub-color', settingsService.read(SettingsService.subtitleTextColor));
      await currentPlayer.setProperty(
        'sub-border-size',
        settingsService.read(SettingsService.subtitleBorderSize).toString(),
      );
      await currentPlayer.setProperty('sub-border-color', settingsService.read(SettingsService.subtitleBorderColor));
      await currentPlayer.setProperty('sub-bold', settingsService.read(SettingsService.subtitleBold) ? 'yes' : 'no');
      await currentPlayer.setProperty(
        'sub-italic',
        settingsService.read(SettingsService.subtitleItalic) ? 'yes' : 'no',
      );
      final bgOpacity = (settingsService.read(SettingsService.subtitleBackgroundOpacity) * 255 / 100).toInt();
      final bgColor = settingsService.read(SettingsService.subtitleBackgroundColor).replaceFirst('#', '');
      await currentPlayer.setProperty(
        'sub-back-color',
        '#${bgOpacity.toRadixString(16).padLeft(2, '0').toUpperCase()}$bgColor',
      );
      if (settingsService.read(SettingsService.subtitleBackgroundOpacity) > 0) {
        await currentPlayer.setProperty('sub-border-style', 'background-box');
      }
      await currentPlayer.setProperty('sub-ass-override', settingsService.read(SettingsService.subAssOverride).name);
      await currentPlayer.setProperty('sub-ass-video-aspect-override', '1');
      await currentPlayer.setProperty('sub-pos', settingsService.read(SettingsService.subtitlePosition).toString());

      if (Platform.isIOS) {
        await currentPlayer.setProperty('audio-exclusive', 'yes');

        // Rasterize subtitles at the video's resolution instead of the
        // display's; the OSD layer upscales them with the video.
        await currentPlayer.setProperty(
          'avfoundation-osd-video-res',
          settingsService.read(SettingsService.subtitleRenderResolution) == SubtitleRenderResolution.video
              ? 'yes'
              : 'no',
        );
      }

      // Audio passthrough (desktop, Android TV, and Apple TV — where the
      // fork's AVPlayer Atmos sink handles EAC3+JOC, #1300)
      if (PlatformDetector.supportsAudioPassthrough()) {
        await currentPlayer.setAudioPassthrough(settingsService.read(SettingsService.audioPassthrough));
      }

      // HDR is controlled via custom hdr-enabled property on iOS/macOS/Windows
      if (Platform.isIOS || Platform.isMacOS || Platform.isWindows) {
        final enableHDR = settingsService.read(SettingsService.enableHDR);
        await currentPlayer.setProperty('hdr-enabled', enableHDR ? 'yes' : 'no');
      }

      final audioSyncOffset = settingsService.read(SettingsService.audioSyncOffset);
      if (audioSyncOffset != 0) {
        final offsetSeconds = audioSyncOffset / 1000.0;
        await currentPlayer.setProperty('audio-delay', offsetSeconds.toString());
      }

      final subtitleSyncOffset = settingsService.read(SettingsService.subtitleSyncOffset);
      if (subtitleSyncOffset != 0) {
        final offsetSeconds = subtitleSyncOffset / 1000.0;
        await currentPlayer.setProperty('sub-delay', offsetSeconds.toString());
      }

      if (settingsService.read(SettingsService.audioNormalization)) {
        await currentPlayer.setAudioNormalization(true);
      }

      // After the passthrough apply: downmix wins on both backends (mpv
      // clears audio-spdif, ExoPlayer force-decodes encoded audio).
      if (settingsService.read(SettingsService.audioDownmix)) {
        await currentPlayer.setAudioDownmix(
          enabled: true,
          centerBoostDb: settingsService.read(SettingsService.downmixCenterBoost),
          normalize: settingsService.read(SettingsService.audioDownmixNormalize),
        );
      }

      if (PlatformDetector.isDesktopOS()) {
        await currentPlayer.setProperty('screenshot-directory', '~/Pictures');
      }

      final customMpvConfig = SettingsService.parseMpvConfigText(settingsService.read(SettingsService.mpvConfigText));
      for (final entry in customMpvConfig.entries) {
        try {
          await currentPlayer.setProperty(entry.key, entry.value);
          appLogger.d('Applied custom MPV property: ${entry.key}=${entry.value}');
        } catch (e) {
          appLogger.w('Failed to set MPV property ${entry.key}', error: e);
        }
      }

      final maxVolume = settingsService.read(SettingsService.maxVolume);
      await currentPlayer.setProperty('volume-max', maxVolume.toString());

      final savedVolume = settingsService.read(SettingsService.volume).clamp(0.0, maxVolume.toDouble());
      await currentPlayer.setVolume(savedVolume);

      if (!mounted || player != currentPlayer) return;

      initPhase = 'wiring player streams';
      await _wirePlayerStreams(
        currentPlayer: currentPlayer,
        settingsService: settingsService,
        useExoPlayer: useExoPlayer,
      );
      if (!mounted || player != currentPlayer) return;

      if (mounted) {
        setState(() {
          _isPlayerInitialized = true;
        });

        // Restart sleep timer if we're starting a new playback session
        SleepTimerService().restartIfNeeded(() => unawaited(_pauseWithPlaybackIntent(currentPlayer)));

        // Enable wakelock to prevent screen from turning off during playback
        unawaited(_setWakelock(true));
        appLogger.d('Wakelock enabled for video playback');
      }

      initPhase = 'starting playback';
      await _startPlayback();
      if (!mounted || player != currentPlayer) return;

      // Set fullscreen mode and orientation based on rotation lock setting
      initPhase = 'applying orientation';
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

      if (!mounted || player != currentPlayer) return;
      // Player streams are wired before open so broadcast first-frame events
      // cannot be dropped. Service init follows immediately after open.
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
      initPhase = 'initializing playback services';
      await _initializeServices();
    } catch (e, st) {
      appLogger.e('Failed to initialize player during $initPhase', error: e, stackTrace: st);
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

  /// Android display frame-rate matching state (retry counter, applied
  /// latch, MediaSession pause-suppression window) — see [FrameRateMatcher].
  final FrameRateMatcher _frameRate = FrameRateMatcher();

  Future<Duration?> _pauseAndHidePlayerForRouteExit() async {
    final currentPlayer = player;
    if (currentPlayer == null || !_isPlayerInitialized) return null;

    final exitPosition = currentPlayer.state.position;
    if (currentPlayer.state.isActive) {
      try {
        await _pauseWithPlaybackIntent(currentPlayer);
      } catch (e, st) {
        appLogger.w('Failed to pause player during route exit', error: e, stackTrace: st);
      }
    }

    if (!mounted || currentPlayer != player) return exitPosition;

    if (Platform.isAndroid && PlatformDetector.isTV()) {
      try {
        await currentPlayer.setVisible(false);
      } catch (e, st) {
        appLogger.w('Failed to hide Android TV player surface during route exit', error: e, stackTrace: st);
      }
    }

    return exitPosition;
  }

  /// Handle back button press
  /// For non-host participants in Watch Together, shows leave session confirmation
  Future<void> _handleBackButton() async {
    if (_showPlayNextDialog || _showStillWatchingPrompt) {
      _dismissPlaybackPromptForBack();
      return;
    }
    if (_isHandlingBack) return;
    _isHandlingBack = true;
    try {
      // For non-host participants, show leave session confirmation
      if (_watchTogetherProvider != null && _watchTogetherProvider!.isInSession && !_watchTogetherProvider!.isHost) {
        final confirmed = await showConfirmDialog(
          context,
          title: t.watchTogether.leaveSessionQuestion,
          message: t.watchTogether.leaveSessionConfirm,
          confirmText: t.watchTogether.leave,
          isDestructive: true,
        );

        if (confirmed && mounted) {
          await _watchTogetherProvider!.leaveSession();
          if (mounted) {
            final navigator = Navigator.of(context);
            if (navigator.canPop()) {
              _isExiting.value = true;
              final exitPosition = await _pauseAndHidePlayerForRouteExit();
              if (!mounted) return;
              await _sendStoppedProgressOnce(positionOverride: exitPosition);
              if (!mounted) return;
              await _restoreSystemUiAndOrientation();
              if (!mounted) return;
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
        final exitPosition = await _pauseAndHidePlayerForRouteExit();
        if (!mounted) return;
        await _sendStoppedProgressOnce(positionOverride: exitPosition);
        if (!mounted) return;
        await _restoreSystemUiAndOrientation();
        if (!mounted) return;
        navigator.pop(true);
      }
    } finally {
      _isHandlingBack = false;
    }
  }

  Future<void> _restoreSystemUiAndOrientation() async {
    if (PlatformDetector.isDesktopOS() && _exitFullscreenOnPlayerClose) {
      unawaited(FullscreenStateManager().exitFullscreen());
    }

    try {
      await OrientationHelper.restoreSystemUI();
    } catch (e) {
      appLogger.w('Failed to restore system UI', error: e);
    }

    try {
      if (_isPhone) {
        await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
      } else {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    } catch (e) {
      appLogger.w('Failed to restore orientation', error: e);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _cleanupCompanionRemoteCallbacks();

    // Notify Watch Together guests that host is exiting the player.
    // Use stored reference since context.read() may fail in dispose.
    final isReplacingWithVideo = _isReplacingWithVideo;
    if (!isReplacingWithVideo &&
        _watchTogetherProvider != null &&
        _watchTogetherProvider!.isHost &&
        _watchTogetherProvider!.isInSession) {
      _watchTogetherProvider!.notifyHostExitedPlayer();
    }

    _detachFromWatchTogetherSession();

    _isBuffering.dispose();
    _hasFirstFrame.dispose();
    _isExiting.dispose();
    _chromeController.dispose();
    _toastController.dispose();

    // Stop progress tracking and send final state. Normal back navigation
    // awaits this before popping; dispose keeps a fallback for externally
    // removed routes where dispose() cannot await.
    unawaited(_sendStoppedProgressOnce());
    _progressTracker?.stopTracking();
    _progressTracker?.dispose();
    _sendLiveTimeline('stopped');
    _stopLiveTimelineUpdates();

    _detachPipStateListener();
    _videoPIPManager?.onBeforeEnterPip = null;
    unawaited(_videoPIPManager?.disableAutoPip());
    _clearAutoPipEnteringCallback();
    _videoFilterManager?.dispose();
    _videoPIPManager = null;
    _videoFilterManager = null;

    _scrubPreviewSource?.dispose();

    if (!isReplacingWithVideo) {
      SleepTimerService().markNeedsRestart();
    }

    _playingSubscription?.cancel();
    _completedSubscription?.cancel();
    _errorSubscription?.cancel();
    _mediaControlSubscription?.cancel();
    _appleTvPlayPauseSubscription?.cancel();
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
    _tvBackgroundPlayerSuspendTimer?.cancel();

    _stillWatchingTimer?.cancel();

    _liveSeek.dispose();

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
    if (!isReplacingWithVideo &&
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
      // Native dispose deliberately leaves the display mode for Dart to clear
      // (ExoPlayerCore.releasePending) — skip it during a player→player
      // replacement, the Android analog of preserveDisplayMode below.
      if (!isReplacingWithVideo) {
        player!.clearVideoFrameRate();
      }
      player!.abandonAudioFocus();
    }

    unawaited(_setWakelock(false));
    appLogger.d('Wakelock disabled');

    if (!isReplacingWithVideo) {
      unawaited(_restoreSystemUiAndOrientation());
    }

    Sentry.addBreadcrumb(Breadcrumb(message: 'Player dispose', category: 'player'));
    final playerToDispose = player;
    player = null;
    if (playerToDispose != null) {
      // Keep the native display mode (tvOS HDMI criteria) across a
      // player→player handoff; the replacement screen primes its own.
      unawaited(playerToDispose.dispose(preserveDisplayMode: isReplacingWithVideo));
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

  void _setupAppleTvRemotePlaybackActions() {
    if (!PlatformDetector.isAppleTV()) return;

    _appleTvPlayPauseSubscription = AppleTvRemoteTouchService.instance.playPauseActions.listen((action) {
      unawaited(_handleAppleTvRemotePlayPause(action));
    });
  }

  Future<void> _handleAppleTvRemotePlayPause(AppleTvRemotePlayPauseAction action) async {
    appLogger.d(
      'Apple TV remote play/pause received source=${action.source}'
      '${action.detail == null ? '' : ' detail=${action.detail}'}',
    );
    await _toggleRemotePlayPause(source: 'Apple TV remote');
  }

  /// Toggle play/pause on behalf of a hardware remote (Apple TV bridge or a
  /// hardware media key). Mirrors the controls path: rewind-on-resume, then
  /// play/pause with playback intent.
  Future<void> _toggleRemotePlayPause({required String source}) async {
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;

    final currentPlayer = player;
    if (!_isPlayerInitialized || currentPlayer == null) {
      appLogger.d('$source play/pause ignored: player not ready');
      return;
    }

    if (!_canControlPlaybackFromRemote()) {
      appLogger.d('$source play/pause ignored: playback control unavailable');
      return;
    }

    try {
      if (!currentPlayer.state.playing) {
        await _seekBackForRewind(currentPlayer);
        if (!mounted || player != currentPlayer) return;
      }
      await _playOrPauseWithPlaybackIntent(currentPlayer);
    } catch (e, st) {
      appLogger.w('$source play/pause failed', error: e, stackTrace: st);
    }
  }

  /// Hardware media play/pause keys (Android TV remotes). Deliberately not
  /// space/configured hotkeys — text fields must still receive those.
  static bool _isHardwarePlayPauseKey(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.mediaPlayPause ||
      key == LogicalKeyboardKey.mediaPlay ||
      key == LogicalKeyboardKey.mediaPause;

  bool _canControlPlaybackFromRemote() {
    try {
      final watchTogether = _watchTogetherProvider ?? context.read<WatchTogetherProvider>();
      return !watchTogether.isInSession || watchTogether.canControl();
    } catch (e) {
      return true;
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

  void _setPlayerState(VoidCallback fn) => setStateIfMounted(fn);

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

  Future<void> _sendStoppedProgressOnce({Duration? positionOverride}) {
    final tracker = _progressTracker;
    if (tracker == null) return Future<void>.value();

    return tracker.sendStoppedProgressOnce(positionOverride: positionOverride).catchError((Object e, StackTrace st) {
      appLogger.d('Stopped progress flush failed', error: e, stackTrace: st);
    });
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
        // Hardware media play/pause must act even when focus rests on this
        // node or a sibling overlay — otherwise the key only reveals the
        // chrome and leaks to the (possibly stale/suspended) Android
        // MediaSession (#1375). Gated to TV-style nav: on desktop the global
        // HardwareKeyboard handler already acts (handlers don't stop focus
        // dispatch), and Apple TV delivers play/pause via its native bridge.
        if (_videoPlayerNavigationEnabled &&
            !PlatformDetector.isAppleTV() &&
            _isHardwarePlayPauseKey(event.logicalKey)) {
          if (event is KeyDownEvent) {
            unawaited(_toggleRemotePlayPause(source: 'Hardware media key'));
            if (node.hasPrimaryFocus) {
              _chromeController.show(focusTarget: PlayerChromeFocusTarget.playPause);
            }
          }
          return KeyEventResult.handled; // consume down, repeat, and up
        }
        // Self-heal: if this node itself has primary focus (no descendant
        // focused, e.g. after controls auto-hide), redirect to first descendant.
        if (node.hasPrimaryFocus) {
          if (event.isActionable) {
            _chromeController.show(focusTarget: PlayerChromeFocusTarget.playPause);
          }
          return event.logicalKey.isNavigationKey ? KeyEventResult.handled : KeyEventResult.ignored;
        }
        // A descendant has focus — let events pass through so
        // DirectionalFocusAction / ActivateAction can process them.
        return KeyEventResult.ignored;
      },
      child: OverlaySheetHost(
        // Host owns sheet + system back: a back with a sheet open closes it;
        // with no sheet, exit the player. canPop:false keeps swipe-back disabled
        // so it doesn't fight timeline scrubbing.
        canPop: false,
        onSystemBack: () {
          if (BackKeyCoordinator.consumeIfHandled()) return;
          BackKeyCoordinator.markHandled();
          _handleBackButton();
        },
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
