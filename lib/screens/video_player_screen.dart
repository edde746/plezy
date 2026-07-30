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

import '../mpv/mpv.dart';
import '../mpv/player/platform/player_android.dart';
import '../mpv/player/player_native.dart';

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
import '../services/driver_distraction.dart';
import '../services/discord_rpc_service.dart';
import '../services/trackers/tracker_coordinator.dart';
import '../services/episode_navigation_service.dart';
import '../services/apple_tv_remote_touch_service.dart';
import '../services/media_controls_manager.dart';
import '../services/playback_coordinator.dart';
import '../services/playback_initialization_service.dart';
import '../services/playback_context.dart';
import '../services/local_playback_history.dart';
import '../services/playback_session.dart';
import '../services/playback_subtitle_resolver.dart';
import '../services/mpv_sidecar_open_guard.dart';
import '../services/playback_progress_tracker.dart';
import '../services/playback_source_resolver.dart';
import '../services/multi_server_manager.dart';
import '../services/offline_watch_sync_service.dart';
import '../services/display_mode_service.dart';
import '../services/media_control_router.dart';
import '../services/settings_service.dart';
import '../services/sleep_timer_service.dart';
import '../services/subtitle_preference.dart';
import '../services/track_manager.dart';
import '../services/track_selection_service.dart';
import '../services/ambient_lighting_service.dart';
import '../services/video_filter_manager.dart';
import '../services/video_volume_controller.dart';
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
import '../utils/android_exit_diagnostics.dart';
import 'video_player/completion_latch.dart';
import 'video_player/frame_rate_matcher.dart';
import 'video_player/live_stream_retry.dart';
import 'video_player/live_timeline_report.dart';
import 'video_player/wakelock_controller.dart';
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

final WakelockController _wakelockController = WakelockController();

/// Whether an in-place source reload may start the replacement media.
///
/// Reloading a paused player must not manufacture a new play intent. Watch
/// Together and explicit paused starts keep owning the eventual resume.
bool shouldAutoStartReloadedMedia({
  required bool wasPlayingBeforeReload,
  required bool watchTogetherOwnsStart,
  required bool startPaused,
}) => wasPlayingBeforeReload && !watchTogetherOwnsStart && !startPaused;

/// Builds an item-agnostic subtitle preference for an episode replacement.
///
/// Source ids and sidecar URIs belong to the current media item. Only the
/// committed semantic choice — a [SubtitleIntent] — may cross the item
/// boundary; native state is a fallback for sessions created before
/// source-backed selection was recorded.
SubtitlePreference? subtitlePreferenceForItemChange({
  required bool hasCommittedSelection,
  required SubtitleTrack? committedTrack,
  required SubtitleTrack? nativeTrack,
}) {
  SubtitlePreference? normalize(SubtitleTrack? track, {required bool preserveOff}) {
    if (track == null) return null;
    if (track.id == SubtitleTrack.off.id) return preserveOff ? const SubtitlePreference.off() : null;

    final intent = SubtitleIntent.fromTrack(track);
    return intent == null ? null : SubtitlePreference.intent(intent);
  }

  if (!hasCommittedSelection) {
    return normalize(nativeTrack, preserveOff: true);
  }

  if (committedTrack == null) return const SubtitlePreference.off();

  final committedPreference = normalize(committedTrack, preserveOff: true);
  if (committedPreference != null) return committedPreference;
  return normalize(nativeTrack, preserveOff: false);
}

/// The in-place media-source transitions a [VideoPlayerScreenState] can run.
/// They are mutually exclusive by construction — entry points bail while a
/// transition is in flight.
enum _PlaybackTransition { idle, switchingSource, reloadingMedia, switchingChannel }

enum _SubtitleSelectionSlot { primary, secondary }

/// Identity token for one owner of the in-place playback transition lock.
///
/// The enum describes what the current owner is doing; it is not itself an
/// ownership token because a superseded async flow can outlive a newer flow
/// that has since acquired the same enum value.
final class _PlaybackTransitionLease {
  _PlaybackTransitionLease();

  bool _wasSuperseded = false;

  bool get wasSuperseded => _wasSuperseded;

  void _markSuperseded() => _wasSuperseded = true;
}

/// Outcome of [VideoPlayerScreenState._reloadMediaInPlace].
enum _MediaReloadOutcome {
  /// An entry guard refused the attempt (live screen, unmounted, another
  /// transition in flight). Nothing was touched; safe to retry later.
  rejected,

  /// A newer playback attempt took ownership mid-reload; its outcome
  /// governs what is on screen now.
  superseded,

  /// The replacement media opened and its session committed. A post-open
  /// step may still have failed (tracks/services were rewired in the
  /// catch), but the network stream is fresh.
  opened,

  /// The reload failed before the replacement opened: the previous session
  /// is still committed, the eagerly-set identity was rolled back, and the
  /// old (possibly dead — #1520) stream is still loaded.
  failed,
}

/// Handle for one playback attempt (initial start or in-place reload).
/// Async continuations check [isCurrent] after every await while the screen
/// is mounted, the captured player is active, and no newer attempt exists.
class _PlaybackAttempt {
  _PlaybackAttempt._(this._owner, this.generation, this.player, this.trackMutationDrain);

  final VideoPlayerScreenState _owner;
  final int generation;
  final Player player;
  final Future<void> trackMutationDrain;

  bool get isCurrent => _owner._isCurrentPlaybackGeneration(generation, player);
}

class _PlaybackOpenTiming {
  final Duration? mediaStart;
  final Duration? timelineDuration;

  const _PlaybackOpenTiming({this.mediaStart, this.timelineDuration});
}

_PlaybackOpenTiming _playbackOpenTiming({
  required bool isTranscoding,
  required Duration? resumePosition,
  required int? durationMs,
}) {
  return _PlaybackOpenTiming(
    mediaStart: resumePosition,
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

  // Track the currently active route target to guard duplicate navigation and
  // project the server-qualified media key to housekeeping consumers.
  static final VideoPlayerActiveRouteGuard _activeRouteGuard = VideoPlayerActiveRouteGuard();

  static String? get activeGlobalKey => _activeRouteGuard.activeGlobalKey;

  static bool isNavigationActive(VideoPlayerLaunchIdentity identity) => _activeRouteGuard.blocks(identity);

  Player? player;
  Player? _bootstrapPlayer;
  VideoVolumeController? _volumeController;
  bool _isPlayerInitialized = false;
  String? _playerInitializationError;
  Future<void>? _playerInitializationOperation;
  int _playerInitializationGeneration = 0;
  late MediaItem _currentMetadata;
  MediaItem? _nextEpisode;
  MediaItem? _previousEpisode;
  // Retryable sentinel until the fire-and-forget initial adjacency load
  // commits found, boundary, or unavailable.
  QueueNavigationStatus _nextEpisodeStatus = QueueNavigationStatus.failed;
  bool _isResolvingCompletionAdjacency = false;
  bool _isLoadingNext = false;
  bool _isLoadingPrevious = false;

  // In-flight media-source transition. At most one can run at a time: reloads
  // and channel switches are mutually exclusive.
  _PlaybackTransition _playbackTransition = _PlaybackTransition.idle;
  _PlaybackTransitionLease? _playbackTransitionLease;
  Completer<void>? _playbackTransitionIdleCompleter;
  bool _playbackIntentShouldPlay = true;
  int _pendingSubtitleCycleCount = 0;
  bool _subtitleCycleDrainActive = false;

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
  SubtitlePreference? _preferredSubtitleTrack;
  SubtitlePreference? _preferredSecondarySubtitleTrack;
  bool _serverSupportsTranscoding = false;
  // Kicked off early in the player initialization attempt for online non-live playback so
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

  // Spurious-EOF recovery (#1520): a long pause can get the server-side
  // stream reaped or the idle socket killed; on resume the player drains its
  // cache and signals a clean EOF mid-file. Recovery reloads in place,
  // bounded so a persistently dying stream can't reload-loop. The budget
  // restores once playback progresses well past the last recovery point or
  // on an item change; user-initiated retries (play/seek) are always allowed
  // and never consume it.
  static const int _maxSpuriousEofRecoveryAttempts = 2;
  static const int _spuriousEofProgressResetMs = 30000;
  int _spuriousEofRecoveryAttempts = 0;
  int? _spuriousEofRecoveryBaselineMs;

  /// Playback is parked mid-file on a dead stream: automatic recovery failed
  /// or its budget is spent. Exits: user play/seek (always allowed) or the
  /// server-status monitor seeing the server come back online.
  bool _spuriousEofRecoveryParked = false;

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
  ({bool canControlPlayback, bool canNavigateMediaItems})? _lastMediaControlAuthority;
  PlaybackProgressTracker? _progressTracker;
  VideoFilterManager? _videoFilterManager;
  bool _pipInitialized = false;
  ShaderService? _shaderService;
  AmbientLightingService? _ambientLightingService;
  bool _fullscreenListenerAttached = false;
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
  /// owns this item. Used by the player initialization path.
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
    // Any freshly opened stream ends a dead-stream park (#1520).
    _spuriousEofRecoveryParked = false;
    // Every successful open passes through here (never live TV), making it
    // the chokepoint for the local last-played history. Offline plays are
    // excluded — like version prefs, the history describes online intent.
    if (!session.isOffline) {
      unawaited(LocalPlaybackHistory.recordPlayback(session.metadata));
    }
  }

  PlaybackSession _updatePlaybackSessionSubtitleSelection(
    PlaybackSession session,
    PlaybackSubtitleSelection selection,
  ) {
    final updated = session.withSubtitleSelection(selection);
    _playbackSession = updated;
    return updated;
  }

  ScrubFrame? _getThumbnailData(Duration time) => _scrubPreviewSource?.getFrame(time);

  int _beginPlaybackGeneration({bool isMediaReload = false}) {
    if (!isMediaReload) _forcePlaybackTransitionIdle();
    return ++_playbackGeneration;
  }

  _PlaybackTransitionLease? _tryAcquirePlaybackTransition(_PlaybackTransition transition) {
    assert(transition != _PlaybackTransition.idle);
    if (_playbackTransition != _PlaybackTransition.idle) return null;
    final lease = _PlaybackTransitionLease();
    _playbackTransitionLease = lease;
    _changePlaybackTransition(transition);
    return lease;
  }

  bool _ownsPlaybackTransition(_PlaybackTransitionLease lease, {_PlaybackTransition? expected}) {
    return identical(_playbackTransitionLease, lease) && (expected == null || _playbackTransition == expected);
  }

  bool _advancePlaybackTransition(
    _PlaybackTransitionLease lease,
    _PlaybackTransition transition, {
    _PlaybackTransition? expected,
  }) {
    assert(transition != _PlaybackTransition.idle);
    if (!_ownsPlaybackTransition(lease, expected: expected)) return false;
    _changePlaybackTransition(transition);
    return true;
  }

  void _releasePlaybackTransition(_PlaybackTransitionLease lease) {
    if (!identical(_playbackTransitionLease, lease)) return;
    _playbackTransitionLease = null;
    _changePlaybackTransition(_PlaybackTransition.idle);
  }

  void _forcePlaybackTransitionIdle() {
    _playbackTransitionLease?._markSuperseded();
    _playbackTransitionLease = null;
    _changePlaybackTransition(_PlaybackTransition.idle);
  }

  void _changePlaybackTransition(_PlaybackTransition transition) {
    if (_playbackTransition == transition) return;
    _playbackTransition = transition;
    if (transition == _PlaybackTransition.idle) {
      final completer = _playbackTransitionIdleCompleter;
      _playbackTransitionIdleCompleter = null;
      if (completer != null && !completer.isCompleted) completer.complete();
    } else {
      _playbackTransitionIdleCompleter ??= Completer<void>();
    }
  }

  Future<void> _waitForPlaybackTransitionIdle() async {
    while (mounted && _playbackTransition != _PlaybackTransition.idle) {
      _playbackTransitionIdleCompleter ??= Completer<void>();
      await _playbackTransitionIdleCompleter!.future;
    }
  }

  /// Start a new playback attempt: invalidates automatic track selection,
  /// bumps the generation, and captures the owning player so async
  /// continuations can check [_PlaybackAttempt.isCurrent] uniformly instead of
  /// threading (generation, player) pairs around. Reloads await the captured,
  /// bounded mutation drain at their replacement-open boundary.
  _PlaybackAttempt _beginPlaybackAttempt(Player currentPlayer, {bool isMediaReload = false}) {
    final trackMutationDrain = _trackManager?.invalidatePendingSelection() ?? Future<void>.value();
    return _PlaybackAttempt._(
      this,
      _beginPlaybackGeneration(isMediaReload: isMediaReload),
      currentPlayer,
      trackMutationDrain,
    );
  }

  bool _isCurrentPlaybackGeneration(int generation, Player currentPlayer) {
    return mounted && player == currentPlayer && _playbackGeneration == generation;
  }

  Future<void> _playWithPlaybackIntent(Player currentPlayer) {
    if (!automotivePlaybackAllowedNow()) {
      _playbackIntentShouldPlay = false;
      appLogger.d('Playback blocked while Android Automotive app is not resumed');
      return Future<void>.value();
    }
    _playbackIntentShouldPlay = true;
    if (widget.isLive && _live.retryFailed) {
      if (_live.retrying) return Future.value();
      _live.retrying = true;
      return _retryLiveStream();
    }
    if (_spuriousEofRecoveryParked && _playbackTransition == _PlaybackTransition.idle) {
      // Parked on a dead stream: play/pause on a drained cache is a no-op
      // (mpv doesn't even flip `pause` on EOF), so any press means "get my
      // video back" — rebuild the stream instead (#1520).
      return _retrySpuriousEofRecovery(reason: 'play pressed');
    }
    return currentPlayer.play();
  }

  Future<void> _pauseWithPlaybackIntent(Player currentPlayer) {
    _playbackIntentShouldPlay = false;
    return currentPlayer.pause();
  }

  Future<void> _playOrPauseWithPlaybackIntent(Player currentPlayer) {
    if (!automotivePlaybackAllowedNow()) {
      appLogger.d('Play/pause requested while Android Automotive app is not resumed; keeping playback paused');
      return _pauseWithPlaybackIntent(currentPlayer);
    }
    if (widget.isLive && _live.retryFailed) {
      return _playWithPlaybackIntent(currentPlayer);
    }
    if (_spuriousEofRecoveryParked && _playbackTransition == _PlaybackTransition.idle) {
      _playbackIntentShouldPlay = true;
      return _retrySpuriousEofRecovery(reason: 'play/pause pressed');
    }
    _playbackIntentShouldPlay = !currentPlayer.state.playing;
    return currentPlayer.playOrPause();
  }

  final ValueNotifier<bool> _isBuffering = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _hasFirstFrame = ValueNotifier<bool>(false);
  // UI readiness may be forced true to hide the loading spinner after a
  // startup failure. Reporting readiness is stricter: only a renderer event
  // (or the established non-ExoPlayer position fallback) sets this latch.
  bool _hasRenderedFirstFrame = false;
  bool _hasFatalPlaybackError = false;

  final ValueNotifier<bool> _isExiting = ValueNotifier<bool>(false);
  final PlayerChromeController _chromeController = PlayerChromeController();
  late final PlayerNavigationCoordinator _playerNavigationCoordinator;

  @override
  void initState() {
    super.initState();
    unawaited(AndroidExitDiagnostics.markUiState(AndroidUiState.player));

    _playerNavigationCoordinator = PlayerNavigationCoordinator(
      chromeController: _chromeController,
      isPromptOpen: () => _showPlayNextDialog || _showStillWatchingPrompt,
      dismissPrompt: _dismissPlaybackPromptForBack,
      isChromePresented: () =>
          _isPlayerInitialized && player != null && _hasFirstFrame.value && _chromeController.controlsPresented,
      exitFullscreenIfActive: FullscreenStateManager().exitFullscreenIfActive,
      // macOS fullscreen belongs to the app window, while HTPC-style player
      // navigation treats physical Escape as semantic Back. In both cases the
      // player must leave native fullscreen alone.
      physicalEscapeExitsFullscreen: () => shouldPhysicalEscapeExitFullscreen(
        isMacOS: Platform.isMacOS,
        videoPlayerNavigationEnabled: _videoPlayerNavigationEnabled,
      ),
      exitPlayer: () => unawaited(_handleBackButton()),
      navigateHome: _handleHomeButton,
      isActive: () => mounted,
    );

    _currentMetadata = widget.metadata;
    _activeRouteGuard.activate(
      this,
      VideoPlayerLaunchIdentity(
        metadata: widget.metadata,
        mediaIndex: widget.selectedMediaIndex,
        selectedMediaSourceId: widget.selectedMediaSourceId,
        selectedQualityPreset: widget.selectedQualityPreset,
        isOffline: widget.isOffline,
        routeKind: widget.isLive ? VideoPlayerRouteKind.liveTv : VideoPlayerRouteKind.vod,
      ),
    );
    _effectiveSelectedMediaIndex = widget.selectedMediaIndex;
    _requestedMediaSourceId = widget.selectedMediaSourceId;

    // Reused across in-place quality/version/audio switches so the
    // server-side transcode session is preserved.
    _playbackSessionIdentifier = generateSessionIdentifier();
    _playbackTranscodeSessionId = generateSessionIdentifier();
    _selectedAudioStreamId = widget.selectedAudioStreamId;
    _preferredAudioTrack = widget.preferredAudioTrack;
    _preferredSubtitleTrack = SubtitlePreference.trackOrNull(widget.preferredSubtitleTrack);
    _preferredSecondarySubtitleTrack = SubtitlePreference.trackOrNull(widget.preferredSecondarySubtitleTrack);
    _selectedQualityPreset = widget.selectedQualityPreset ?? TranscodeQualityPreset.original;

    _playNextCancelFocusNode = FocusNode(debugLabel: 'PlayNextCancel');
    _playNextConfirmFocusNode = FocusNode(debugLabel: 'PlayNextConfirm');

    _stillWatchingPauseFocusNode = FocusNode(debugLabel: 'StillWatchingPause');
    _stillWatchingContinueFocusNode = FocusNode(debugLabel: 'StillWatchingContinue');

    // Screen-level focus node that wraps the entire build output.
    // Ensures a single stable focus target across loading → initialized phases.
    _screenFocusNode = FocusNode(debugLabel: 'VideoPlayerScreen');
    _screenFocusNode.addListener(_onScreenFocusChanged);
    HardwareKeyboard.instance.addHandler(_primeInitializationNavigationFocus);

    appLogger.d('VideoPlayerScreen initialized for: ${_currentMetadata.title}');
    if (_preferredAudioTrack != null) {
      appLogger.d(
        'Preferred audio track: ${_preferredAudioTrack!.title ?? _preferredAudioTrack!.id} (${_preferredAudioTrack!.language ?? "unknown"})',
      );
    }
    if (_preferredSubtitleTrack != null) {
      appLogger.d('Preferred subtitle track: $_preferredSubtitleTrack');
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

    unawaited(_startPlayerInitialization(replaceCurrent: false));
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
        if (PlatformDetector.isAutomotive()) {
          _enqueueLifecycleTransition('inactive_automotive', _handleAppHidden);
        }
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
        unawaited(_wakelockController.setEnabled(false));
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
        if (widget.isLive) {
          unawaited(_sendStoppedProgressOnce());
        } else {
          // Last chance for VOD: dispose may never run on a terminate, and the
          // trackers that own their own watched semantics need the terminal
          // report.
          unawaited(TrackerCoordinator.instance.stopPlayback());
        }
        break;
    }
  }

  Future<void> _startPlayerInitialization({required bool replaceCurrent}) {
    final activeOperation = _playerInitializationOperation;
    if (activeOperation != null) return activeOperation;

    final generation = ++_playerInitializationGeneration;
    final operationCompleter = Completer<void>();
    final operation = operationCompleter.future;
    _playerInitializationOperation = operation;

    unawaited(() async {
      try {
        await _runPlayerInitializationAttempt(generation, replaceCurrent: replaceCurrent);
      } catch (e, st) {
        appLogger.e('Unexpected player initialization lifecycle failure', error: e, stackTrace: st);
      } finally {
        if (identical(_playerInitializationOperation, operation)) {
          _playerInitializationOperation = null;
        }
        operationCompleter.complete();
      }
    }());
    return operation;
  }

  void _retryPlayerInitialization() {
    unawaited(_startPlayerInitialization(replaceCurrent: true));
  }

  bool _isPlayerInitializationCurrent(int generation) {
    return mounted && generation == _playerInitializationGeneration;
  }

  bool _ownsPlayerInitializationAttempt(int generation, Player currentPlayer) {
    return _isPlayerInitializationCurrent(generation) && identical(player, currentPlayer);
  }

  void _disposeVolumeControllerForPlayer(Player currentPlayer) {
    final controller = _volumeController;
    if (controller == null || !controller.ownsPlayer(currentPlayer)) return;
    _volumeController = null;
    controller.dispose();
  }

  Future<void> _disposePlayerInitializationAttempt(Player attemptPlayer) async {
    _playbackGeneration++;
    _disposeVolumeControllerForPlayer(attemptPlayer);
    if (identical(player, attemptPlayer)) {
      player = null;
    }
    if (identical(_bootstrapPlayer, attemptPlayer)) {
      _bootstrapPlayer = null;
    }
    try {
      await _tearDownFailedPlayerAttempt(attemptPlayer);
    } catch (e, st) {
      appLogger.w('Failed to tear down player collaborators during initialization rollback', error: e, stackTrace: st);
    }
    try {
      await attemptPlayer.abandonAudioFocus();
    } catch (e, st) {
      appLogger.w('Failed to abandon audio focus during player rollback', error: e, stackTrace: st);
    }
    try {
      await attemptPlayer.dispose(preserveDisplayMode: false);
    } catch (e, st) {
      appLogger.w('Failed to dispose player during initialization rollback', error: e, stackTrace: st);
    }
  }

  Future<void> _runPlayerInitializationAttempt(int generation, {required bool replaceCurrent}) async {
    var initPhase = 'starting';
    Player? attemptPlayer;
    var committed = false;
    String? failureMessage;
    try {
      if (!_isPlayerInitializationCurrent(generation)) return;
      setState(() {
        _playerInitializationError = null;
        _isPlayerInitialized = false;
      });

      if (replaceCurrent) {
        final previousPlayer = player;
        if (previousPlayer != null) {
          await _disposePlayerInitializationAttempt(previousPlayer);
        }
        if (!_isPlayerInitializationCurrent(generation)) return;
      }

      initPhase = 'loading settings';
      final settingsService = await SettingsService.getInstance();
      if (!_isPlayerInitializationCurrent(generation)) return;
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
        if (!_isPlayerInitializationCurrent(generation)) return;
        if (!_fullscreenListenerAttached) {
          FullscreenStateManager().addListener(_onFullscreenChanged);
          _fullscreenListenerAttached = true;
        }
      }

      // One-native-instance rule: a live music session owns the only audio
      // core — stop it and wait for its dispose before constructing the
      // video core (see PlaybackCoordinator).
      initPhase = 'claiming playback session';
      await PlaybackCoordinator.instance.claimVideo();
      if (!mounted || generation != _playerInitializationGeneration) return;

      initPhase = 'creating player';
      final currentPlayer = Player(useExoPlayer: useExoPlayer);
      attemptPlayer = currentPlayer;
      if (!mounted || generation != _playerInitializationGeneration) return;
      if (currentPlayer is PlayerNative && currentPlayer.requiresProvisionalTextureSurface) {
        setState(() => _bootstrapPlayer = currentPlayer);
      }
      if (Platform.isAndroid && useExoPlayer) {
        await currentPlayer.setLogLevel(debugLoggingEnabled ? 'v' : 'warn');
        if (!mounted || generation != _playerInitializationGeneration) return;
      }

      // Kick off getPlaybackData() in parallel with the rest of MPV setup.
      // The network/DB work has no dependency on the player — it just needs
      // the context (providers), which is still safe to touch here because
      // no async gaps invalidate it before the calls below read it.
      // Skipped for live TV (has its own tune path) and offline (its own
      // branch in _startPlayback).
      if (!widget.isLive && !_offlineLibraryMode) {
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
          PlaybackInitializationOptions(
            metadata: _currentMetadata,
            selectedMediaIndex: _effectiveSelectedMediaIndex,
            selectedMediaSourceId: _requestedMediaSourceId,
            preferredVersionSignature: widget.preferredVersionSignature,
            qualityPreset: _selectedQualityPreset,
            selectedAudioStreamId: _selectedAudioStreamId,
            preferredSubtitleTrack: _preferredSubtitleTrack,
            sessionIdentifier: _playbackSessionIdentifier,
            transcodeSessionId: _playbackTranscodeSessionId,
          ),
          offlineLibraryMode: false,
        );
        // If MPV setup below throws before `_startPlayback` awaits this,
        // tell Dart we've "handled" the future so it's not reported as an
        // unhandled async error. The later `await` still receives the error.
        _playbackDataFuture!.ignore();
      }

      if (!_isPlayerInitializationCurrent(generation)) return;
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
        if (!_isPlayerInitializationCurrent(generation)) return;
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
      if (!Platform.isAndroid || useExoPlayer) {
        await currentPlayer.setLogLevel(debugLoggingEnabled ? 'v' : 'warn');
      }
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

      // Audio passthrough (desktop, Android TV, and Apple TV, where the native
      // sample-buffer renderer handles AC3/EAC3, including JOC metadata).
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
      if (!_isPlayerInitializationCurrent(generation)) return;
      _volumeController = VideoVolumeController(
        player: currentPlayer,
        settings: settingsService,
        initialVolume: savedVolume,
      );

      player = currentPlayer;
      _playerBackendLabel = currentPlayer.playerType;

      initPhase = 'wiring player streams';
      await _wirePlayerStreams(
        currentPlayer: currentPlayer,
        settingsService: settingsService,
        useExoPlayer: useExoPlayer,
      );
      if (!_ownsPlayerInitializationAttempt(generation, currentPlayer)) return;

      if (mounted) {
        setState(() {
          _isPlayerInitialized = true;
          _bootstrapPlayer = null;
        });

        // Restart sleep timer if we're starting a new playback session
        SleepTimerService().restartIfNeeded(() => unawaited(_pauseWithPlaybackIntent(currentPlayer)));

        // Enable wakelock to prevent screen from turning off during playback
        unawaited(_wakelockController.setEnabled(true));
        appLogger.d('Wakelock enabled for video playback');
      }

      initPhase = 'starting playback';
      await _startPlayback();
      if (!_ownsPlayerInitializationAttempt(generation, currentPlayer)) return;

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

      if (!_ownsPlayerInitializationAttempt(generation, currentPlayer)) return;
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
      if (!_ownsPlayerInitializationAttempt(generation, currentPlayer)) return;
      committed = true;
    } catch (e, st) {
      failureMessage = _safePlaybackErrorMessage(e);
      appLogger.e('Failed to initialize player during $initPhase', error: e, stackTrace: st);
    } finally {
      final failedAttempt = attemptPlayer;
      if (!committed && failedAttempt != null) {
        await _disposePlayerInitializationAttempt(failedAttempt);
      }
    }

    if (failureMessage != null && _isPlayerInitializationCurrent(generation)) {
      setState(() {
        _isPlayerInitialized = false;
        _playerInitializationError = failureMessage;
      });
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

  /// Pause/hide the player, flush stopped progress, restore system UI and
  /// orientation, then leave the player route. No-op when the route cannot pop.
  Future<void> _exitPlayerRoute({required bool navigateHome}) async {
    final navigator = Navigator.of(context);
    if (!navigator.canPop()) return;

    _isExiting.value = true;
    final exitPosition = await _pauseAndHidePlayerForRouteExit();
    if (!mounted) return;
    await _sendStoppedProgressOnce(positionOverride: exitPosition);
    if (!mounted) return;
    await _restoreSystemUiAndOrientation();
    if (!mounted) return;
    _finishPlayerNavigation(navigator, navigateHome: navigateHome);
  }

  /// Handle back button press
  /// For non-host participants in Watch Together, shows leave session confirmation
  Future<void> _handleBackButton({bool navigateHome = false}) async {
    if (!navigateHome && (_showPlayNextDialog || _showStillWatchingPrompt)) {
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
          try {
            await _watchTogetherProvider!.leaveSession();
          } catch (error, stackTrace) {
            appLogger.e('WatchTogether: Session leave failed', error: error, stackTrace: stackTrace);
          }
          if (mounted) await _exitPlayerRoute(navigateHome: navigateHome);
        }
        return;
      }

      // Default behavior for hosts or non-session users
      if (!mounted) return;
      await _exitPlayerRoute(navigateHome: navigateHome);
    } finally {
      _isHandlingBack = false;
    }
  }

  void _handleHomeButton() {
    unawaited(_handleBackButton(navigateHome: true));
  }

  void _finishPlayerNavigation(NavigatorState navigator, {required bool navigateHome}) {
    if (!navigateHome) {
      navigator.pop(true);
      return;
    }

    final onHome = _savedOnHome;
    navigator.popUntil((route) => route.isFirst);
    onHome?.call();
  }

  void _handleScreenPlayerNavigation(PlayerNavigationKey navigationKey) {
    if (navigationKey != PlayerNavigationKey.home) {
      final sheetController = OverlaySheetController.maybeOf(context);
      if (sheetController?.isOpen ?? false) {
        sheetController!.pop();
        return;
      }
    }
    _playerNavigationCoordinator.handle(navigationKey);
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

    // Cars are fixed-orientation devices, and a compact head unit can read as a
    // phone below, which would pin it to portrait on player exit.
    if (PlatformDetector.isAutomotive()) return;

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
    unawaited(AndroidExitDiagnostics.markUiState(AndroidUiState.mainScreen));
    _playerInitializationGeneration++;
    _frameRate.dispose();
    WidgetsBinding.instance.removeObserver(this);

    final transitionCompleter = _playbackTransitionIdleCompleter;
    _playbackTransitionIdleCompleter = null;
    if (transitionCompleter != null && !transitionCompleter.isCompleted) transitionCompleter.complete();

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

    // The release sequence below mirrors _tearDownFailedPlayerAttempt but is
    // deliberately separate: dispose() cannot await, and it destroys the
    // notifiers, focus nodes and player that the rollback path keeps alive
    // for a retry on a still-mounted screen.
    //
    // Stop progress tracking and send final state. Normal back navigation
    // awaits this before popping; dispose keeps a fallback for externally
    // removed routes where dispose() cannot await.
    unawaited(_sendStoppedProgressOnce());
    _progressTracker?.stopTracking();
    _progressTracker?.dispose();
    _stopLiveTimelineUpdates();

    _detachPipStateListener();
    if (_pipInitialized) unawaited(PipService.setAutoPipReady(ready: false));
    _clearAutoPipEnteringCallback();
    _videoFilterManager?.dispose();
    _pipInitialized = false;
    _videoFilterManager = null;

    _scrubPreviewSource?.dispose();

    if (!isReplacingWithVideo) {
      SleepTimerService().markNeedsRestart();
    }

    // Teardown scope: every subscription the screen ever owns, including the
    // initState-owned sleep-timer and Apple TV ones that the rollback path
    // must leave alive.
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
    HardwareKeyboard.instance.removeHandler(_primeInitializationNavigationFocus);
    _screenFocusNode.dispose();

    _mediaControlsManager?.clear();
    _mediaControlsManager?.dispose();

    DiscordRPCService.instance.stopPlayback();
    TrackerCoordinator.instance.stopPlayback();

    if (_fullscreenListenerAttached) {
      FullscreenStateManager().removeListener(_onFullscreenChanged);
      _fullscreenListenerAttached = false;
    }
    // Not _restoreWindowsDisplayMode(): that helper waits 200ms after clearing
    // the HDR hint before restoring, which dispose() cannot do. Fire the hint
    // clear at the still-live player and restore immediately.
    if (!isReplacingWithVideo &&
        Platform.isWindows &&
        _displayModeService != null &&
        _displayModeService!.anyChangeApplied) {
      if (_displayModeService!.hdrStateChanged && player != null) {
        final currentPlayer = player!;
        unawaited(() async {
          try {
            await currentPlayer.setProperty('target-colorspace-hint', 'no');
          } catch (error, stackTrace) {
            appLogger.w(
              'Failed to clear the Windows HDR colorspace hint during teardown',
              error: error,
              stackTrace: stackTrace,
            );
          }
        }());
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

    unawaited(_wakelockController.setEnabled(false));
    appLogger.d('Wakelock disabled');

    if (!isReplacingWithVideo) {
      unawaited(_restoreSystemUiAndOrientation());
    }

    Sentry.addBreadcrumb(Breadcrumb(message: 'Player dispose', category: 'player'));
    final volumeController = _volumeController;
    _volumeController = null;
    volumeController?.dispose();
    final playerToDispose = player ?? _bootstrapPlayer;
    player = null;
    _bootstrapPlayer = null;
    if (playerToDispose != null) {
      // Keep the native display mode (tvOS HDMI criteria) across a
      // player→player handoff; the replacement screen primes its own.
      unawaited(playerToDispose.dispose(preserveDisplayMode: isReplacingWithVideo));
    }
    _activeRouteGuard.clear(this);
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

  /// Loading and initialization-error phases can receive a Back key-down
  /// before their autofocus request has settled. Claim focus immediately so
  /// the matching key-up reaches the player route and exits exactly once.
  bool _primeInitializationNavigationFocus(KeyEvent event) {
    if (!mounted || _isExiting.value) return false;
    primePlayerNavigationFocusForEvent(
      event,
      focusNode: _screenFocusNode,
      playerReady: _isPlayerInitialized && player != null && _hasFirstFrame.value,
      isCurrentRoute: ModalRoute.of(context)?.isCurrent == true,
      isAppleTV: PlatformDetector.isAppleTV(),
    );
    return false;
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
    await _remoteTransport(TransportCommand.toggle, source: 'Apple TV remote');
  }

  /// Announce an *accepted user transport command* with a centred transient disc.
  ///
  /// Deliberately not driven from `player.streams.playing` or the
  /// `_*WithPlaybackIntent` helpers: those also fire for the sleep timer,
  /// lifecycle and audio-session changes, frame-rate re-opens, still-watching
  /// prompts, route exit and episode reloads — none of which are user
  /// commands. Each accepted command site opts in explicitly instead (#1676).
  void _announceTransportCommand({required bool willPlay}) {
    if (!mounted) return;
    // Visible chrome already renders the play/pause state.
    if (_chromeController.controlsVisible) return;
    _toastController.showTransport(
      willPlay ? Symbols.play_arrow_rounded : Symbols.pause_rounded,
      willPlay ? t.videoControls.playbackResumed : t.videoControls.playbackPaused,
    );
  }

  /// Apply a transport command on behalf of a hardware remote (Apple TV bridge
  /// or a hardware media key). Mirrors the controls path: rewind-on-resume,
  /// then play/pause with playback intent, then announce.
  Future<void> _remoteTransport(TransportCommand command, {required String source}) async {
    if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;

    final currentPlayer = player;
    if (!_isPlayerInitialized || currentPlayer == null) {
      appLogger.d('$source play/pause ignored: player not ready');
      return;
    }

    if (!_canControlPlayback()) {
      appLogger.d('$source play/pause ignored: playback control unavailable');
      return;
    }

    // Rewind-on-resume follows the resolved intent, never the current state: a
    // directed pause on an already-paused video must not jump backwards.
    final resumes = switch (command) {
      TransportCommand.play => !currentPlayer.state.playing,
      TransportCommand.pause => false,
      TransportCommand.toggle => !currentPlayer.state.playing,
    };

    try {
      if (resumes) {
        await _seekBackForRewind(currentPlayer);
        if (!mounted || player != currentPlayer) return;
      }
      await switch (command) {
        TransportCommand.play => _playWithPlaybackIntent(currentPlayer),
        TransportCommand.pause => _pauseWithPlaybackIntent(currentPlayer),
        TransportCommand.toggle => _playOrPauseWithPlaybackIntent(currentPlayer),
      };
      _announceTransportCommand(willPlay: _playbackIntentShouldPlay);
    } catch (e, st) {
      appLogger.w('$source play/pause failed', error: e, stackTrace: st);
    }
  }

  /// Transport requested from the player controls (keyboard hotkey, companion
  /// remote, on-screen button, click-to-toggle, D-pad Select). Authorization
  /// and rewind-on-resume already ran in the controls layer.
  Future<void> _handleControlsTransport(TransportCommand command) async {
    final currentPlayer = player;
    if (currentPlayer == null) return;
    await switch (command) {
      TransportCommand.play => _playWithPlaybackIntent(currentPlayer),
      TransportCommand.pause => _pauseWithPlaybackIntent(currentPlayer),
      TransportCommand.toggle => _playOrPauseWithPlaybackIntent(currentPlayer),
    };
    _announceTransportCommand(willPlay: _playbackIntentShouldPlay);
  }

  String? _lastLogError;
  bool _sawServer500 = false;

  static final RegExp _server500Pattern = RegExp(r'\b(?:HTTP error |Response code: )500\b');

  // OS Media Controls Integration

  /// Navigate to a specific queue item (called from QueueSheet)
  Future<void> navigateToQueueItem(MediaItem metadata) async {
    if (!_canNavigateMediaItems()) return;
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

  Future<void> _onAudioTrackChanged(AudioTrack track) async => _trackManager?.onAudioTrackSelectedByUser(track);

  Future<void> _onSubtitleTrackChanged(SubtitleTrack track, {int? sourceStreamId}) async {
    _rememberNativeSubtitleSelection(track, sourceStreamId: sourceStreamId);
    await _trackManager?.onSubtitleTrackSelectedByUser(track, sourceStreamId: sourceStreamId);
  }

  void _rememberNativeSubtitleSelection(SubtitleTrack track, {int? sourceStreamId}) {
    _rememberNativeSubtitleSelectionForSlot(
      track,
      slot: _SubtitleSelectionSlot.primary,
      sourceStreamId: sourceStreamId,
    );
  }

  void _onSecondarySubtitleTrackChanged(SubtitleTrack track) {
    _rememberNativeSubtitleSelectionForSlot(track, slot: _SubtitleSelectionSlot.secondary);
    _trackManager?.onSecondarySubtitleTrackChanged(track);
  }

  void _rememberNativeSubtitleSelectionForSlot(
    SubtitleTrack track, {
    required _SubtitleSelectionSlot slot,
    int? sourceStreamId,
  }) {
    final session = _playbackSession;
    if (session == null) return;
    final currentSelection = session.subtitleSelection;
    if (track.id == SubtitleTrack.off.id) {
      _updatePlaybackSessionSubtitleSelection(session, switch (slot) {
        _SubtitleSelectionSlot.primary => const PlaybackSubtitleSelection.off(),
        _SubtitleSelectionSlot.secondary => PlaybackSubtitleSelection(
          primaryTrack: currentSelection.primaryTrack,
          primarySourceStreamId: currentSelection.primarySourceStreamId,
          primarySidecar: currentSelection.primarySidecar,
        ),
      });
      if (mounted) _setPlayerState(() {});
      return;
    }

    final info = _currentMediaInfo;
    final currentPlayer = player;
    if (info == null || currentPlayer == null) return;

    MediaSubtitleTrack? sourceTrack;
    final currentSourceId = switch (slot) {
      _SubtitleSelectionSlot.primary => currentSelection.primarySourceStreamId,
      _SubtitleSelectionSlot.secondary => currentSelection.secondarySourceStreamId,
    };
    final currentSidecar = switch (slot) {
      _SubtitleSelectionSlot.primary => currentSelection.primarySidecar,
      _SubtitleSelectionSlot.secondary => currentSelection.secondarySidecar,
    };
    if (sourceStreamId != null) {
      for (final candidate in info.subtitleTracks) {
        if (candidate.id == sourceStreamId) {
          sourceTrack = candidate;
          break;
        }
      }
    } else if (track.isExternal && currentSourceId != null && currentSidecar?.track.uri == track.uri) {
      for (final candidate in info.subtitleTracks) {
        if (candidate.id == currentSourceId) {
          sourceTrack = candidate;
          break;
        }
      }
    }
    sourceTrack ??= findPlexTrackForMpvSubtitle(
      track,
      info.subtitleTracks,
      allMpvTracks: currentPlayer.state.tracks.subtitle,
    );
    if (sourceTrack == null) return;

    final sidecar = _sidecarForSourceStreamId(session, sourceTrack.id);
    final resolvedTrack = PlaybackSubtitleResolver.subtitleTrackForSource(sourceTrack, sidecar: sidecar);
    final selection = PlaybackSubtitleSelection(
      primaryTrack: slot == _SubtitleSelectionSlot.primary ? resolvedTrack : currentSelection.primaryTrack,
      primarySourceStreamId: slot == _SubtitleSelectionSlot.primary
          ? sourceTrack.id
          : currentSelection.primarySourceStreamId,
      primarySidecar: slot == _SubtitleSelectionSlot.primary ? sidecar : currentSelection.primarySidecar,
      secondaryTrack: slot == _SubtitleSelectionSlot.secondary ? resolvedTrack : currentSelection.secondaryTrack,
      secondarySourceStreamId: slot == _SubtitleSelectionSlot.secondary
          ? sourceTrack.id
          : currentSelection.secondarySourceStreamId,
      secondarySidecar: slot == _SubtitleSelectionSlot.secondary ? sidecar : currentSelection.secondarySidecar,
    );
    _updatePlaybackSessionSubtitleSelection(session, selection);
    if (mounted) _setPlayerState(() {});
  }

  PlaybackSubtitleSidecar? _sidecarForSourceStreamId(PlaybackSession session, int sourceStreamId) {
    for (final candidate in session.context.result.subtitleSidecars) {
      if (candidate.sourceStreamId == sourceStreamId) return candidate;
    }
    return null;
  }

  Future<void> _sendStoppedProgressOnce({Duration? positionOverride}) {
    if (widget.isLive) {
      _stopLiveTimelineUpdates();
      return _sendLiveTimeline('stopped');
    }

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
    // - onKeyEvent: owns player-level navigation after descendants have had the
    //   opportunity to handle local layers such as sheets and content strips.
    return Focus(
      focusNode: _screenFocusNode,
      autofocus: isCurrentRoute,
      canRequestFocus: isCurrentRoute,
      onKeyEvent: (node, event) {
        if (!isCurrentRoute) return KeyEventResult.ignored;
        final navigationKey = classifyPlayerNavigationKey(event, isAppleTV: PlatformDetector.isAppleTV());
        if (navigationKey != PlayerNavigationKey.none) {
          if (navigationKey != PlayerNavigationKey.home && PlatformDetector.isTV() && event is KeyDownEvent) {
            BackKeyCoordinator.markHandled();
          }
          return handlePlayerNavigationKeyAction(
            event,
            navigationKey,
            () => _handleScreenPlayerNavigation(navigationKey),
          );
        }
        // Hardware media transport must act even when focus rests on this
        // node or a sibling overlay — otherwise the key only reveals the
        // chrome and leaks to the (possibly stale/suspended) Android
        // MediaSession (#1375). Gated to TV-style nav: on desktop the global
        // HardwareKeyboard handler already acts (handlers don't stop focus
        // dispatch), and Apple TV delivers play/pause via its native bridge.
        // The chrome deliberately stays down; _remoteTransport announces the
        // accepted command with a centred transient disc instead (#1676).
        final transportCommand = classifyTransportKey(event.logicalKey);
        if (_videoPlayerNavigationEnabled && !PlatformDetector.isAppleTV() && transportCommand != null) {
          if (event is KeyDownEvent) {
            unawaited(_remoteTransport(transportCommand, source: 'Hardware media key'));
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
          _handleScreenPlayerNavigation(PlayerNavigationKey.back);
        },
        child: Builder(
          builder: (sheetContext) => _isPlayerInitialized && player != null
              ? _buildVideoPlayer(sheetContext)
              : (_playerInitializationError != null
                    ? _buildInitializationError(_playerInitializationError!)
                    : _buildPlayerInitializationSurface()),
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
