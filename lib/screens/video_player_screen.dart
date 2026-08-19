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
import '../services/car_ux_restrictions_service.dart';
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
import '../services/scoped_player_prefs.dart';
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
import '../utils/route_visibility.dart';
import '../utils/video_player_navigation.dart';
import '../utils/android_exit_diagnostics.dart';
import 'video_player/completion_latch.dart';
import 'video_player/frame_rate_matcher.dart';
import 'video_player/live_stream_retry.dart';
import 'video_player/live_timeline_report.dart';
import 'video_player/wakelock_controller.dart';
import 'video_player/playback_failure_action.dart';
import 'video_player/open_http_503_watchdog.dart';
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
import '../focus/focus_navigation_intent.dart';
import '../focus/key_event_utils.dart';
import '../focus/transport_keys.dart';
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

/// Property names the free-form mpv config is not allowed to write.
///
/// Neither is an mpv property. The Linux plugin intercepts both by name and
/// moves its own persistent HDR state instead (linux/runner/mpv/mpv_plugin.cc),
/// and the custom config is applied *after* startup has pushed the stored
/// preferences, so a `hdr-enabled=yes` or `hdr-tone-mapping=player` line would
/// change the live plane without anything writing it back to [SettingsService].
/// The settings sheet renders its HDR switch and tone-mapping row straight off
/// those preferences with no native readback, so the UI would report one state
/// while the plane held another - for the whole session, and again after a
/// restart, since the next startup replays the same order rather than
/// reconciling.
///
/// Filtered rather than reordered: reordering would still leave the config as a
/// second writer of state the app owns, silently discarded on every startup
/// instead of silently winning. Nothing legitimate is lost - both names are
/// settings the player's own HDR controls already expose, and mean nothing to
/// mpv itself, so no platform is losing a real mpv property here.
const _appInterceptedMpvProperties = {'hdr-enabled', 'hdr-tone-mapping'};

/// The above, plus the four real mpv properties the Linux video plane owns.
///
/// It writes all four as one unit and caches what it last applied so it can skip
/// a transaction that would change nothing. A config line writing one of them
/// moves mpv without moving that cache, and the next transaction then compares
/// against a value mpv no longer holds and skips the write it needed to make -
/// leaving mpv encoding one colour space while the surface is described as
/// another, the single state the two-phase apply exists to prevent.
///
/// Scoped to the plane deliberately. These are ordinary mpv properties
/// everywhere else, nothing caches them there, and no other platform exposes a
/// UI control for them - so withholding them off Linux would remove the user's
/// only way to set them and point the log at a control they do not have.
/// The windowed-VO family. Embedded video is pinned to vo=libmpv (the render
/// API the plane and every other embedded surface are created against); a
/// config line switching `vo` — or the `gpu-context`/`gpu-api` it rides on —
/// makes mpv re-create its output as a separate, uncontrollable window and
/// orphans the embedded render context. vo=gpu-next is windowed by
/// construction and compute shaders (ArtCNN) need it, so no embedded vo is
/// worth accepting; the skip log for these names says that instead of pointing
/// at the HDR settings.
const _appEmbeddedOwnedMpvProperties = {'vo', 'gpu-context', 'gpu-api'};

const _appOwnedMpvProperties = {
  ..._appInterceptedMpvProperties,
  ..._appEmbeddedOwnedMpvProperties,
  'target-trc',
  'target-prim',
  'target-peak',
  'tone-mapping',
};

/// Whether an in-place source reload may start the replacement media.
///
/// Reloading a paused player must not manufacture a new play intent. Watch
/// Together and explicit paused starts keep owning the eventual resume.
bool shouldAutoStartReloadedMedia({
  required bool wasPlayingBeforeReload,
  required bool watchTogetherOwnsStart,
  required bool startPaused,
}) => wasPlayingBeforeReload && !watchTogetherOwnsStart && !startPaused;

/// Whether a freshly opened player route starts with its chrome up.
///
/// A television starts with the controls down. Auto-hide cannot even arm until
/// the first frame lands, so chrome raised by the route opening would park the
/// whole OSD and timebar over the first seconds of picture (#1765). The route
/// keeps its own loading surface and buffering overlay, the screen focus node
/// owns back, and the first D-pad press raises the chrome, so a remote loses
/// nothing. Pointer and touch platforms keep it: the viewer's hand is already
/// on the surface, and the title and back affordance belong over the spinner.
bool playerChromeStartsVisible({required bool isTv}) => !isTv;

/// Builds an item-agnostic subtitle preference for an episode replacement.
///
/// Source ids and sidecar URIs belong to the current media item. Only the
/// committed semantic choice — a [SubtitleIntent] — may cross the item
/// boundary; native state is a fallback for sessions created before
/// source-backed selection was recorded.
///
/// [sessionPreference] is the screen's last explicit viewer choice and wins
/// outright: automatic outcomes never overwrite it, so a catalog-gap episode
/// cannot reset the choice for the rest of the session.
///
/// [declinedPreference] is the committed selection's unserved carry: its off
/// is fallout from a metadata mismatch, not a viewer choice, so it must not
/// harden into an explicit off on the next item (#1785).
SubtitlePreference? subtitlePreferenceForItemChange({
  required bool hasCommittedSelection,
  required SubtitleTrack? committedTrack,
  required SubtitleTrack? nativeTrack,
  SubtitlePreference? declinedPreference,
  SubtitlePreference? sessionPreference,
}) {
  final sessionIntent = SubtitlePreference.demoteToIntent(sessionPreference);
  if (sessionIntent != null) return sessionIntent;
  SubtitlePreference? normalize(SubtitleTrack? track, {required bool preserveOff}) {
    if (track == null) return null;
    if (track.id == SubtitleTrack.off.id) return preserveOff ? const SubtitlePreference.off() : null;

    final intent = SubtitleIntent.fromTrack(track);
    return intent == null ? null : SubtitlePreference.intent(intent);
  }

  if (!hasCommittedSelection) {
    return normalize(nativeTrack, preserveOff: true);
  }

  final committedIsOff = committedTrack == null || committedTrack.id == SubtitleTrack.off.id;
  if (declinedPreference != null && committedIsOff) {
    // Live native state wins — a late native pass may have served the
    // declined carry — otherwise the declined preference itself keeps
    // crossing item boundaries until the viewer or a richer catalog
    // settles it.
    return normalize(nativeTrack, preserveOff: false) ?? SubtitlePreference.demoteToIntent(declinedPreference);
  }

  if (committedTrack == null) return const SubtitlePreference.off();

  final committedPreference = normalize(committedTrack, preserveOff: true);
  if (committedPreference != null) return committedPreference;
  return normalize(nativeTrack, preserveOff: false);
}

/// Builds the committed [PlaybackSubtitleSelection] for a user's subtitle
/// pick in one slot, leaving the other slot untouched.
///
/// [sourceTrack] and [sidecar] are null when the pick has no source-catalog
/// identity — items without subtitle rows, or a native track the identity
/// matcher cannot map. The raw native [track] is committed then (without
/// source ids), so the session still reflects what is on screen and the next
/// item boundary demotes it to a semantic intent instead of hardening the
/// stale previous selection into an explicit off (#1785).
PlaybackSubtitleSelection subtitleSelectionForUserPick({
  required PlaybackSubtitleSelection currentSelection,
  required bool isPrimarySlot,
  required SubtitleTrack track,
  MediaSubtitleTrack? sourceTrack,
  PlaybackSubtitleSidecar? sidecar,
}) {
  final resolvedTrack = sourceTrack == null
      ? track
      : PlaybackSubtitleResolver.subtitleTrackForSource(sourceTrack, sidecar: sidecar);
  return PlaybackSubtitleSelection(
    primaryTrack: isPrimarySlot ? resolvedTrack : currentSelection.primaryTrack,
    primarySourceStreamId: isPrimarySlot ? sourceTrack?.id : currentSelection.primarySourceStreamId,
    primarySidecar: isPrimarySlot ? sidecar : currentSelection.primarySidecar,
    secondaryTrack: isPrimarySlot ? currentSelection.secondaryTrack : resolvedTrack,
    secondarySourceStreamId: isPrimarySlot ? currentSelection.secondarySourceStreamId : sourceTrack?.id,
    secondarySidecar: isPrimarySlot ? currentSelection.secondarySidecar : sidecar,
    // A primary pick is a decision that retires any unresolved carry; a
    // secondary-only change must not relabel the primary's declined off as
    // deliberate (that would persist -1 and harden the next boundary).
    declinedPreference: isPrimarySlot ? null : currentSelection.declinedPreference,
  );
}

/// Session-preference form of a source-catalog subtitle choice that had to
/// go through a reload instead of a local track switch.
///
/// The authoritative row — not the reload's outcome — becomes the session
/// preference: a failed resolution must not turn the viewer's pick into a
/// carried off. Returns null when the row is absent from [rows] so a stale
/// id never overwrites the existing session preference.
SubtitlePreference? sessionPreferenceForSourceSubtitleChoice(
  PlaybackSourceSubtitleChoice choice,
  List<MediaSubtitleTrack> rows,
) {
  if (choice.isOff) return const SubtitlePreference.off();
  for (final row in rows) {
    if (row.id == choice.sourceStreamId) {
      return SubtitlePreference.track(PlaybackSubtitleResolver.subtitleTrackForSource(row));
    }
  }
  return null;
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
  return ({required int partId, required String trackType, required int streamID}) async {
    final client = resolve();
    if (client == null) return;
    await (trackType == 'audio'
        ? client.selectStreams(partId, audioStreamID: streamID)
        : client.selectStreams(partId, subtitleStreamID: streamID));
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
  // globalKey of the adjacent episode whose playback metadata row was last
  // prefetched into the API cache — see _primeNextEpisodePlaybackMetadata.
  String? _primedNextEpisodeGlobalKey;
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

  /// Last explicit track choices made on this screen. They survive in-place
  /// reloads but not route replacement. Automatic selections never overwrite
  /// them, so an episode with a catalog gap cannot reset the viewer's choice
  /// for the rest of the session (#1785).
  AudioTrack? _sessionAudioPreference;
  SubtitlePreference? _sessionSubtitlePreference;
  SubtitlePreference? _sessionSecondarySubtitlePreference;
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

  /// Cancel-and-null scope for the screen's player-driven stream
  /// subscriptions — the single authority consumed by [_wirePlayerStreams]
  /// (re-wire: the nine player streams), [_tearDownFailedPlayerAttempt]
  /// (rollback: player streams plus the five media-controls listeners created
  /// in [_initializeServices]), and the screen's `dispose`. The
  /// initState-owned `_sleepTimerSubscription` and
  /// `_appleTvPlayPauseSubscription` are deliberately excluded: cancelling
  /// them on a re-wire or rollback would kill the sleep-timer prompt and the
  /// Apple TV remote for the rest of the screen's life.
  List<Future<void>> _cancelPlayerStreamSubscriptions({required bool includeMediaControls}) {
    final cancellations = <Future<void>>[
      ?_playingSubscription?.cancel(),
      ?_completedSubscription?.cancel(),
      ?_errorSubscription?.cancel(),
      ?_logSubscription?.cancel(),
      ?_backendSwitchedSubscription?.cancel(),
      ?_bufferingSubscription?.cancel(),
      ?_serverStatusSubscription?.cancel(),
      ?_playbackRestartSubscription?.cancel(),
      ?_positionSubscription?.cancel(),
      if (includeMediaControls) ...[
        ?_mediaControlSubscription?.cancel(),
        ?_mediaControlsPlayingSubscription?.cancel(),
        ?_mediaControlsPositionSubscription?.cancel(),
        ?_mediaControlsRateSubscription?.cancel(),
        ?_mediaControlsSeekableSubscription?.cancel(),
      ],
    ];
    _playingSubscription = null;
    _completedSubscription = null;
    _errorSubscription = null;
    _logSubscription = null;
    _backendSwitchedSubscription = null;
    _bufferingSubscription = null;
    _serverStatusSubscription = null;
    _playbackRestartSubscription = null;
    _positionSubscription = null;
    if (includeMediaControls) {
      _mediaControlSubscription = null;
      _mediaControlsPlayingSubscription = null;
      _mediaControlsPositionSubscription = null;
      _mediaControlsRateSubscription = null;
      _mediaControlsSeekableSubscription = null;
    }
    return cancellations;
  }

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

  // Transient episode-transition failure retry (#1867). A failed in-place
  // reload records the classified reason here so _playNext can distinguish
  // "server momentarily unreachable" (re-present the Play Next prompt,
  // optionally with an auto-retry countdown) from terminal failures.
  // _navigateToEpisode clears the field before each attempt; the counter
  // resets when a reload succeeds.
  PlaybackFailureReason? _lastMediaReloadFailureReason;
  int _playNextTransientRetryCount = 0;

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

  /// Key for a context below this screen's own [OverlaySheetHost]. The State's
  /// context sits ABOVE the host, so resolving the controller with `context`
  /// always misses it and the screen would walk its back pipeline (hide chrome,
  /// then exit the player) while a sheet is still open (#1741).
  final GlobalKey _overlayChildKey = GlobalKey();

  BuildContext get _sheetContext => _overlayChildKey.currentContext ?? context;

  // VLC-style in-player toast controller (rate changes, backend switch, etc.).
  final PlayerToastController _toastController = PlayerToastController();
  bool _reclaimingFocus = false;

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

  /// Redelivery schedule for the suspend-time stopped report. Standby entry
  /// can drop Wi-Fi into power-save and stall exactly that connect, and
  /// mutations deliberately never fail over ([FailoverHttpClient]), so the
  /// one report the suspend exists for gets a bounded retry window instead
  /// of a single fail-fast attempt.
  static const Duration _tvBackgroundStopReportRetryDelay = Duration(seconds: 10);
  static const int _tvBackgroundStopReportMaxRetries = 5;
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
  final PlayerChromeController _chromeController = PlayerChromeController(
    initiallyVisible: playerChromeStartsVisible(isTv: PlatformDetector.isTV()),
  );

  /// Lets startup-policy coverage assert the chrome this route actually opened
  /// with, rather than a controller the test seeded itself.
  @visibleForTesting
  PlayerChromeController get chromeController => _chromeController;

  late final PlayerNavigationCoordinator _playerNavigationCoordinator;

  @override
  void initState() {
    super.initState();
    unawaited(AndroidExitDiagnostics.markUiState(AndroidUiState.player));

    // Fullscreen entered from here on is the player's to drop; whatever was
    // already fullscreen belongs to the app window (#1624).
    FullscreenStateManager().beginScope();

    _playerNavigationCoordinator = PlayerNavigationCoordinator(
      chromeController: _chromeController,
      isPromptOpen: () => _showPlayNextDialog || _showStillWatchingPrompt,
      dismissPrompt: _dismissPlaybackPromptForBack,
      isChromePresented: () =>
          _isPlayerInitialized && player != null && _hasFirstFrame.value && _chromeController.controlsPresented,
      // On phones a Back must exit the player even with the controls up
      // (#1938); the staged chrome handling is TV/desktop behavior (#4443b761
      // applied it to the phone system-back path too, so back stopped
      // closing the player).
      exitPlayerBeforeChrome: () => PlatformDetector.isMobile(context),
      exitFullscreenIfActive: FullscreenStateManager().exitFullscreenIfActive,
      // macOS fullscreen belongs to the app window, while HTPC-style player
      // navigation treats physical Escape as semantic Back. In both cases the
      // player must leave native fullscreen alone. So must it when the window
      // was already fullscreen before the player opened — that fullscreen is
      // the app's (start-in-fullscreen, or a toggle from the browse UI) and
      // Escape is plain Back (#1624).
      physicalEscapeExitsFullscreen: () => shouldPhysicalEscapeExitFullscreen(
        isMacOS: Platform.isMacOS,
        videoPlayerNavigationEnabled: videoPlayerNavigationPreference(),
        playerEnteredFullscreen: FullscreenStateManager().scopeOwnsFullscreen,
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
    _screenFocusNode = playerSurfaceFocusNode('VideoPlayerScreen');
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
    if (PlatformDetector.isAutomotive()) {
      // Driving normally reaches this screen as a lifecycle event, because the
      // system puts its blocking activity over a non-distraction-optimized app.
      // Not always: restrictions are per display, so a session the driver is not
      // looking at can be restricted while this activity stays resumed. `DD-3`
      // gives video no exemption, so take the vehicle's word directly too.
      CarUxRestrictionsService.instance.ensureStarted();
      CarUxRestrictionsService.instance.listenable.addListener(_handleCarRestrictionsChanged);
    }

    _setupCompanionRemoteCallbacks();
    _setupAppleTvRemotePlaybackActions();

    _sleepTimerSubscription = SleepTimerService().onPrompt.listen((_) {
      if (mounted) _showStillWatchingDialog();
    });

    if (PlatformDetector.isAutomotive()) {
      unawaited(_startPlayerInitializationOnceVehicleAnswers());
    } else {
      unawaited(_startPlayerInitialization(replaceCurrent: false));
    }
  }

  /// A car must not start video before the vehicle has spoken: `DD-3` gives video
  /// no exemption while driving, so a cold start would otherwise play until the
  /// verdict lands. The wait is bounded by the service, so a car that cannot
  /// answer only delays this by that budget and then falls back to lifecycle
  /// gating — which, for a screen the user just opened, permits playback.
  Future<void> _startPlayerInitializationOnceVehicleAnswers() async {
    await CarUxRestrictionsService.instance.ensureResolved();
    if (!mounted) return;
    await _startPlayerInitialization(replaceCurrent: false);
  }

  /// The vehicle started requiring distraction optimization (`DD-3`).
  ///
  /// Pauses only. The backgrounding path is deliberately not reused: it hides the
  /// render surface, suspends the live timeline and marks Watch Together
  /// backgrounded, all of which `_handleAppResumed` undoes — and no resume event
  /// is coming, because the activity never left the foreground. The playback gate
  /// keeps this paused until the vehicle releases it.
  void _handleCarRestrictionsChanged() {
    if (!mounted || automotivePlaybackAllowedNow()) return;
    _enqueueLifecycleTransition('restricted_automotive', _pauseForVehicleRestriction);
  }

  /// Pauses for something the environment forced on this peer alone.
  ///
  /// A guest's pause goes to the Watch Together attachment, which records it as its own command so
  /// the resulting event is consumed as an acknowledgement rather than a user intent that would
  /// pause the whole room. A host is refused there and pauses the ordinary way: it is the room's
  /// clock, and a room whose host cannot play has to pause with it.
  ///
  /// Returns whether the sync layer took ownership. When it did, it also owns the resume — through
  /// the attachment, following the room — so the caller must not restore playback itself: doing so
  /// would publish a play request and, in a room anyone can control, restart everybody.
  Future<bool> _pauseWithoutDisturbingTheRoom(Player currentPlayer) async {
    final syncOwnsIt = await (_watchTogetherProvider?.pauseLocallyForSystem() ?? Future.value(false));
    if (syncOwnsIt) return true;
    await _pauseWithPlaybackIntent(currentPlayer);
    return false;
  }

  Future<void> _pauseForVehicleRestriction() async {
    final currentPlayer = player;
    // Deliberately not gated on `state.isActive`: that is `playing && !completed`, which is false
    // for the whole of a rebuffer while the native side still intends to play. Skipping here would
    // leave the play intent standing, and playback would start the moment the buffer fills.
    if (currentPlayer == null || !_isPlayerInitialized) return;
    try {
      await _pauseWithoutDisturbingTheRoom(currentPlayer);
    } catch (e, stackTrace) {
      appLogger.w('Failed to pause video for vehicle restrictions', error: e, stackTrace: stackTrace);
      // Fail closed: `DD-3` is not satisfied by having tried, and the restriction has already
      // fired, so nothing else is coming to stop this session.
      try {
        await currentPlayer.stop();
      } catch (e, stackTrace) {
        appLogger.w('Failed to stop restricted video', error: e, stackTrace: stackTrace);
      }
    }
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
      // Literal `mounted` check: the kickoff block below reads `context`, and
      // the lint cannot see the mounted check inside the helper.
      if (!mounted || !_isPlayerInitializationCurrent(generation)) return;
      _autoPipEnabled = settingsService.read(SettingsService.autoPip);
      _exitFullscreenOnPlayerClose = settingsService.read(SettingsService.exitFullscreenOnPlayerClose);
      _rewindOnResume = settingsService.read(SettingsService.rewindOnResume);
      final bufferSizeMB = settingsService.read(SettingsService.bufferSize);
      final playbackBufferTier = settingsService.read(SettingsService.playbackBufferTier);
      final enableHardwareDecoding = settingsService.read(SettingsService.enableHardwareDecoding);
      final debugLoggingEnabled = settingsService.read(SettingsService.enableDebugLogging);
      final useExoPlayer = settingsService.read(SettingsService.useExoPlayer);

      // Kick off getPlaybackData() before the Windows display-mode sync, the
      // music-session teardown in claimVideo(), player construction, and the
      // whole mpv property chain below: the resolve depends only on settings +
      // provider lookups, so starting it first hides all of that setup behind
      // the network round trip(s).
      // The network/DB work has no dependency on the player — it just needs
      // the context (providers), which is still safe to touch here because no
      // async gaps invalidate it between the guard after the settings await
      // and the reads below.
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
            preferredAudioTrack: _preferredAudioTrack,
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
      final currentPlayer = Player(useExoPlayer: useExoPlayer, hardwareDecoding: enableHardwareDecoding);
      attemptPlayer = currentPlayer;
      if (!mounted || generation != _playerInitializationGeneration) return;
      if (Platform.isAndroid && useExoPlayer) {
        await currentPlayer.setLogLevel(debugLoggingEnabled ? 'v' : 'warn');
        if (!mounted || generation != _playerInitializationGeneration) return;
      }

      if (!_isPlayerInitializationCurrent(generation)) return;
      initPhase = 'configuring player';
      await currentPlayer.configureSubtitleFonts();
      await currentPlayer.setProperty('sub-ass', 'yes'); // Enable libass
      if (Platform.isAndroid && useExoPlayer) {
        final tunneledPlayback = settingsService.read(SettingsService.tunneledPlayback);
        await currentPlayer.setProperty('tunneled-playback', tunneledPlayback ? 'yes' : 'no');
        await currentPlayer.setProperty('exo-buffer-tier', playbackBufferTier.nativeValue);
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
            // These tiers size mpv's demuxer. ExoPlayer's LoadControl allocator is a
            // different consumer — a flat byte cap there collapses to a few seconds of
            // read-ahead on a 100 Mbps remux — so let the native side derive its own
            // target on Auto (#1618).
            await currentPlayer.setProperty('demuxer-max-bytes-auto', 'yes');
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

      // Subtitle styling is a preference, never a reason to fail playback.
      // mpv 0.40's OPT_COLOR parser accepts only #RRGGBB/#AARRGGBB (or
      // r/g/b/a floats), so a stored colour that does not parse would make
      // mpv refuse the write - and, unwrapped, that refusal aborts player
      // initialization on every open. Values are sanitized first, and
      // whatever is left is a logged warning with mpv keeping its own
      // default styling.
      try {
        await currentPlayer.setProperty(
          'sub-font-size',
          settingsService.read(SettingsService.subtitleFontSize).toString(),
        );
        await currentPlayer.setProperty(
          'sub-color',
          _sanitizedSubtitleColor(
            settingsService.read(SettingsService.subtitleTextColor),
            SettingsService.subtitleTextColor.defaultValue,
          ),
        );
        await currentPlayer.setProperty(
          'sub-border-size',
          settingsService.read(SettingsService.subtitleBorderSize).toString(),
        );
        await currentPlayer.setProperty(
          'sub-border-color',
          _sanitizedSubtitleColor(
            settingsService.read(SettingsService.subtitleBorderColor),
            SettingsService.subtitleBorderColor.defaultValue,
          ),
        );
        await currentPlayer.setProperty('sub-bold', settingsService.read(SettingsService.subtitleBold) ? 'yes' : 'no');
        await currentPlayer.setProperty(
          'sub-italic',
          settingsService.read(SettingsService.subtitleItalic) ? 'yes' : 'no',
        );
        final bgOpacity = (settingsService.read(SettingsService.subtitleBackgroundOpacity) * 255 / 100).toInt();
        final bgColor = _sanitizedSubtitleColor(
          settingsService.read(SettingsService.subtitleBackgroundColor),
          SettingsService.subtitleBackgroundColor.defaultValue,
        ).replaceFirst('#', '');
        await currentPlayer.setProperty(
          'sub-back-color',
          '#${bgOpacity.toRadixString(16).padLeft(2, '0').toUpperCase()}$bgColor',
        );
        if (settingsService.read(SettingsService.subtitleBackgroundOpacity) > 0) {
          await currentPlayer.setProperty('sub-border-style', 'background-box');
        }
      } catch (e) {
        appLogger.w('VideoPlayerScreen: subtitle styling not applied', error: e);
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

      // Audio passthrough (Windows/Linux, Android TV, and Apple TV, where the
      // native sample-buffer renderer handles AC3/EAC3, including JOC metadata;
      // never macOS — see PlatformDetector.supportsAudioPassthrough).
      if (PlatformDetector.supportsAudioPassthrough()) {
        await currentPlayer.setAudioPassthrough(settingsService.read(SettingsService.audioPassthrough));
      }

      // Set before hdr-enabled so the first image description is already built
      // for the chosen mode. Unlike hdr-enabled below, every failure here is
      // swallowed: an older libmpv rejects it as an unknown property, with no
      // code to tell that apart, and a tone-mapping preference is never a reason
      // to fail playback.
      if (PlayerNative.usesLinuxVideoPlane) {
        final toneMapping = settingsService.read(SettingsService.hdrToneMapping);
        try {
          await currentPlayer.setProperty('hdr-tone-mapping', toneMapping.name);
        } catch (e) {
          appLogger.d('VideoPlayerScreen: HDR tone-mapping mode not applied', error: e);
          // A refused transaction leaves the plugin on the mode it last accepted,
          // and nothing has moved it off the compositor default this session -
          // the only writer is this push, plus the sheet, which persists solely
          // on success. Storing that back keeps the sheet from offering "Player"
          // as the current mode while the plane tone-maps in the compositor,
          // a disagreement no later write would correct on its own.
          // Contained on its own, for the same reason as the hdr-enabled block
          // below: the refusal is deliberately tolerated, so a preference store
          // that then throws must not turn "carry on with compositor tone
          // mapping" into a failed player initialization.
          if (toneMapping != HdrToneMapping.compositor) {
            try {
              await settingsService.write(SettingsService.hdrToneMapping, HdrToneMapping.compositor);
            } catch (writeError) {
              appLogger.w('VideoPlayerScreen: could not reconcile the stored tone-mapping mode', error: writeError);
            }
          }
        }
      }

      // HDR is controlled via the custom hdr-enabled property. On Linux it means
      // "allow passthrough": the native side only describes the plane as HDR
      // when the compositor, the output and the source all agree, so pushing the
      // preference here is safe even when it cannot be honoured.
      //
      // Linux swallows every refusal, because on Linux a refusal is a statement
      // about the *plane*, not about the media: HDR_UNSUPPORTED means this
      // session's plane can never carry HDR - an 8-bit EGL config, or a
      // compositor without the colour-management pieces - and a failed colour
      // transaction means mpv would not take the output properties. Neither is a
      // reason not to play the video in SDR, so rethrowing would turn "this
      // session cannot do HDR" into "this session cannot play video": the
      // initialization error screen, with a Retry that fails the same way.
      //
      // Two earlier reasons given here no longer hold and are recorded as gone
      // so they are not reinstated: the packages no longer link a distro libmpv
      // (each ships the pinned build), and the plugin intercepts hdr-enabled
      // whenever a video surface exists, so the old fall-through to mpv's
      // target-colorspace-hint - and its mpv 0.40 version floor - is unreachable.
      //
      // The tolerance is Linux-only rather than "every platform, for this one
      // error code". HDR_UNSUPPORTED is produced by the Linux plugin and nothing
      // else, so tolerating it elsewhere would be an inert branch no test on any
      // runner can reach, and a silent change to what the other platforms did
      // before this feature existed.
      if (Platform.isIOS || Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        final enableHDR = settingsService.read(SettingsService.enableHDR);
        try {
          await currentPlayer.setProperty('hdr-enabled', enableHDR ? 'yes' : 'no');
        } catch (e) {
          if (!PlayerNative.usesLinuxVideoPlane) rethrow;
          appLogger.d('VideoPlayerScreen: HDR passthrough not applied', error: e);
          // Same hazard as the tone-mapping block above. A refused transaction
          // hands hdr_wanted back to whatever it held before this write, and
          // nothing has moved it this session: the plugin is freshly created and
          // zero-initialised, so it is off. Storing that back keeps the settings
          // switch - which renders straight off this preference - from reading
          // on while the plane is SDR, a disagreement no later write corrects
          // because every internal re-apply reads the native side instead.
          // Contained on its own. The refusal above is deliberately tolerated -
          // this session simply plays SDR - so a preference store that then
          // throws must not escalate that into the initialization error screen,
          // which is where an escape from this catch lands. Worst case the
          // preference stays out of step, which is the situation before this
          // reconciliation existed.
          if (enableHDR) {
            try {
              await settingsService.write(SettingsService.enableHDR, false);
            } catch (writeError) {
              appLogger.w('VideoPlayerScreen: could not reconcile the stored HDR preference', error: writeError);
            }
          }
        }
      }

      final audioSyncOffset = ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.audioSyncOffset, _currentMetadata);
      if (audioSyncOffset != 0) {
        final offsetSeconds = audioSyncOffset / 1000.0;
        await currentPlayer.setProperty('audio-delay', offsetSeconds.toString());
      }

      final subtitleSyncOffset = ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.subtitleSyncOffset, _currentMetadata);
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
      // Only the Linux video plane owns the four real mpv properties, so only
      // there are they withheld. Elsewhere nothing caches them and a config line
      // is the user's single way to reach them - dropping it would take away
      // something that worked, and point at a control that platform does not
      // show. The two intercepted names are not mpv properties anywhere, so
      // those stay withheld everywhere.
      final ownedHere = PlayerNative.usesLinuxVideoPlane ? _appOwnedMpvProperties : _appInterceptedMpvProperties;
      for (final entry in customMpvConfig.entries) {
        // Not silently dropped: the user typed this line, so say which one went
        // unapplied and where to set it instead, at the same level as the other
        // skipped or failed startup writes below.
        if (ownedHere.contains(entry.key)) {
          if (_appEmbeddedOwnedMpvProperties.contains(entry.key)) {
            appLogger.w(
              'Skipped custom MPV property ${entry.key}=${entry.value}: the app owns the video '
              'output on this platform (embedded rendering is vo=libmpv); a windowed VO such as '
              'gpu-next cannot be used inside the app, so compute shaders like ArtCNN cannot run '
              'embedded either',
            );
          } else {
            appLogger.w(
              'Skipped custom MPV property ${entry.key}=${entry.value}: the app owns it, '
              'set it in the player HDR settings instead',
            );
          }
          continue;
        }
        try {
          await currentPlayer.setProperty(entry.key, entry.value);
          appLogger.d('Applied custom MPV property: ${entry.key}=${entry.value}');
        } catch (e) {
          appLogger.w('Failed to set MPV property ${entry.key}', error: e);
        }
      }

      final maxVolume = settingsService.read(SettingsService.maxVolume);
      try {
        await currentPlayer.setProperty('volume-max', maxVolume.toString());
      } catch (e) {
        appLogger.w('VideoPlayerScreen: volume-max not applied', error: e);
      }

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
        setState(() => _isPlayerInitialized = true);

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
      final sheetController = OverlaySheetController.maybeOf(_sheetContext);
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
    CarUxRestrictionsService.instance.listenable.removeListener(_handleCarRestrictionsChanged);

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
    _cancelPlayerStreamSubscriptions(includeMediaControls: true);
    _appleTvPlayPauseSubscription?.cancel();
    _sleepTimerSubscription?.cancel();
    _trackManager?.dispose();

    _autoPlayTimer?.cancel();
    _tvBackgroundPlayerSuspendTimer?.cancel();
    _http503Watchdog.disarm();

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
    FullscreenStateManager().endScope();
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
    final playerToDispose = player;
    player = null;
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
  ///
  /// Reclaim only while this screen is the app's top visible route. The
  /// build's `canRequestFocus` already tracks routes pushed above the player
  /// on its own (profile-session) navigator, but a route on an ancestor
  /// navigator — the root-navigator profile picker on resume — leaves it
  /// true, and reclaiming then yanks the remote off the visible route,
  /// wedging D-pad devices (#2034).
  void _onScreenFocusChanged() {
    if (_reclaimingFocus) return;
    if (!_screenFocusNode.hasFocus && mounted && !_isExiting.value) {
      _reclaimingFocus = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _reclaimingFocus = false;
        if (mounted && !_isExiting.value && !_screenFocusNode.hasFocus && isRouteChainCurrent(context)) {
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
      isCurrentRoute: isRouteChainCurrent(context),
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

  /// Statuses in [fatalPlaybackHttpStatuses] the player's own log stream
  /// reported for this open. Each latches independently: the reconnect path
  /// deliberately retries a 503 (see `_applyNetworkStreamTuning`), and a
  /// transient status must never mask the fatal one that follows.
  final Set<int> _fatalHttpStatuses = <int>{};

  /// Bounds an open the server keeps answering with HTTP 503 — that loop
  /// otherwise never raises an error (#1830). Armed from [_onPlayerLog],
  /// disarmed on first frame, on every new-open reset, and in [dispose].
  late final OpenHttp503Watchdog _http503Watchdog = OpenHttp503Watchdog(onPersistent: _onOpenHttp503Persistent);

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

  Future<void> _onAudioTrackChanged(AudioTrack track) async {
    if (track.id != AudioTrack.auto.id && track.id != AudioTrack.off.id) {
      _sessionAudioPreference = track;
    }
    await _trackManager?.onAudioTrackSelectedByUser(track);
  }

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
    if (track.id == SubtitleTrack.off.id) {
      switch (slot) {
        case _SubtitleSelectionSlot.primary:
          _sessionSubtitlePreference = const SubtitlePreference.off();
        case _SubtitleSelectionSlot.secondary:
          _sessionSecondarySubtitlePreference = const SubtitlePreference.off();
      }
      final session = _playbackSession;
      if (session == null) return;
      final currentSelection = session.subtitleSelection;
      _updatePlaybackSessionSubtitleSelection(session, switch (slot) {
        _SubtitleSelectionSlot.primary => const PlaybackSubtitleSelection.off(),
        // Dropping only the secondary must not relabel the primary's
        // declined off as deliberate.
        _SubtitleSelectionSlot.secondary => PlaybackSubtitleSelection(
          primaryTrack: currentSelection.primaryTrack,
          primarySourceStreamId: currentSelection.primarySourceStreamId,
          primarySidecar: currentSelection.primarySidecar,
          declinedPreference: currentSelection.declinedPreference,
        ),
      });
      if (mounted) _setPlayerState(() {});
      return;
    }

    final session = _playbackSession;
    if (session == null) return;
    final currentSelection = session.subtitleSelection;

    final info = _currentMediaInfo;
    final currentPlayer = player;

    MediaSubtitleTrack? sourceTrack;
    final currentSourceId = switch (slot) {
      _SubtitleSelectionSlot.primary => currentSelection.primarySourceStreamId,
      _SubtitleSelectionSlot.secondary => currentSelection.secondarySourceStreamId,
    };
    final currentSidecar = switch (slot) {
      _SubtitleSelectionSlot.primary => currentSelection.primarySidecar,
      _SubtitleSelectionSlot.secondary => currentSelection.secondarySidecar,
    };
    if (info != null) {
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
      if (sourceTrack == null && currentPlayer != null) {
        sourceTrack = findPlexTrackForMpvSubtitle(
          track,
          info.subtitleTracks,
          allMpvTracks: currentPlayer.state.tracks.subtitle,
        );
      }
    }

    // No source identity (no catalog, or a native track the identity matcher
    // cannot map) still commits the raw pick: an uncommitted selection reads
    // as the session's previous choice — usually the initial off — and the
    // next episode boundary would harden that into an explicit off while the
    // viewer visibly watches with subtitles on (#1785). The raw track carries
    // no source ids, so it demotes to a semantic intent at the boundary.
    final sidecar = sourceTrack == null ? null : _sidecarForSourceStreamId(session, sourceTrack.id);
    final selection = subtitleSelectionForUserPick(
      currentSelection: currentSelection,
      isPrimarySlot: slot == _SubtitleSelectionSlot.primary,
      track: track,
      sourceTrack: sourceTrack,
      sidecar: sidecar,
    );
    final resolvedTrack = switch (slot) {
      _SubtitleSelectionSlot.primary => selection.primaryTrack,
      _SubtitleSelectionSlot.secondary => selection.secondaryTrack,
    };
    if (resolvedTrack != null) {
      switch (slot) {
        case _SubtitleSelectionSlot.primary:
          _sessionSubtitlePreference = SubtitlePreference.track(resolvedTrack);
        case _SubtitleSelectionSlot.secondary:
          _sessionSecondarySubtitlePreference = SubtitlePreference.track(resolvedTrack);
      }
    }
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
        if (videoPlayerNavigationPreference() && !PlatformDetector.isAppleTV() && transportCommand != null) {
          if (event is KeyDownEvent) {
            unawaited(_remoteTransport(transportCommand, source: 'Hardware media key'));
          }
          return KeyEventResult.handled; // consume down, repeat, and up
        }
        // Self-heal: if this node itself has primary focus (no descendant
        // focused, e.g. during loading or after a window re-activation),
        // redirect to the first descendant. Arrows stay playback shortcuts on
        // desktop unless the viewer opted into player navigation; only Tab and
        // a remote's OK deliberately pull focus into the OSD (#1797). Consuming
        // reserved control keys either way keeps them from leaking to the route
        // below.
        if (node.hasPrimaryFocus) {
          if (event.isActionable) {
            // One decision drives both halves: the key that hands the chrome
            // focus is the same key that switches the app into keyboard mode,
            // so focus can never land on a control while focus chrome is still
            // suppressed. For an arrow this already answers "did the viewer opt
            // into player navigation", because the screen node owns arrows
            // exactly while that setting is off.
            final navigating = eventRequestsFocusNavigation(event, focused: node);
            if (!event.logicalKey.isDpadDirection || navigating) {
              _chromeController.show(focusPlayPause: navigating);
            }
          }
          return event.logicalKey.isReservedControlKey ? KeyEventResult.handled : KeyEventResult.ignored;
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
          key: _overlayChildKey,
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

/// mpv's OPT_COLOR parser accepts only #RRGGBB / #AARRGGBB (plus r/g/b/a
/// floats). The stored subtitle colours are free-form strings, so a legacy,
/// tampered or foreign value (named colour, 3-digit hex, ARGB-int text) makes
/// mpv refuse the write with MPV_ERROR_PROPERTY_FORMAT. Sanitized here so a
/// bad preference degrades to the default colour instead of failing playback.
String _sanitizedSubtitleColor(String value, String fallback) {
  final cleaned = value.replaceFirst('#', '').toUpperCase();
  if (RegExp(r'^[0-9A-F]{6}([0-9A-F]{2})?$').hasMatch(cleaned)) {
    return '#$cleaned';
  }
  return fallback;
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
