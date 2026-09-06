part of '../../video_player_screen.dart';

/// Outcome of the Android pre-open frame-rate negotiation for the initial
/// start flow: which pre-switch ran, whether playback must open paused
/// behind a startup gate, and which post-open follow-up (fallback switch
/// or mpv decoder refresh) releases it.
class _FrameRateStartupPlan {
  _FrameRateStartupPlan({required this.fps, this.width = 0, this.height = 0});

  /// The fps to rate-match; null when refresh-rate matching is off or the
  /// rate is unknown (a resolution-only switch passes 0 natively, which
  /// keeps the current refresh rate).
  final double? fps;

  /// Native video dimensions: the resolution-matching target when that
  /// setting is on, and otherwise the floor a display-mode fallback must not
  /// downscale below just to match cadence (0 = unknown).
  final int width;
  final int height;
  bool attemptedMpvPreLoad = false;
  bool didPreLoadSwitch = false;
  bool preOpenExoHandled = false;
  bool needsPostOpenSwitch = false;
  bool needsStartupRefresh = false;
  Future<bool>? _startupFrameReady;

  /// Whether playback must open paused behind a startup gate that
  /// [_releaseFrameRateStartupGate] resumes.
  bool get holdPlaybackStart => needsPostOpenSwitch || needsStartupRefresh;

  /// Whether the pre-open negotiation already counts as the per-item
  /// switch — keeps the post-first-frame fallback from double-switching
  /// while a planned follow-up is still pending. A successful mpv pre-load
  /// switch always implies [attemptedMpvPreLoad].
  bool get countsAsApplied => attemptedMpvPreLoad || preOpenExoHandled;

  /// Subscribe to the first rendered frame *before* open() so the startup
  /// decoder refresh can't miss a synchronously-fast restart event.
  void armStartupRefreshGate(Player player) {
    if (!needsStartupRefresh) return;
    appLogger.d('Frame rate matching: opening Android MPV paused for startup decoder refresh');
    _startupFrameReady = player.streams.playbackRestart.first
        .then((_) => true)
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            appLogger.w('Timed out waiting for Android MPV startup frame before decoder refresh');
            return false;
          },
        );
  }
}

class _ExternalSubtitleOpenPlan {
  const _ExternalSubtitleOpenPlan({required this.externalSubtitles, required this.attachesAtOpen, this.readyAfterOpen});

  final List<SubtitleTrack> externalSubtitles;
  final bool attachesAtOpen;
  final Future<void>? readyAfterOpen;

  bool get hasExternalSubtitles => externalSubtitles.isNotEmpty;
  bool get requiresPostOpenAdd => !attachesAtOpen && hasExternalSubtitles;
  bool get canStartBeforeTrackSetup => attachesAtOpen || !hasExternalSubtitles;
  List<SubtitleTrack>? get subtitlesAtOpen => attachesAtOpen && hasExternalSubtitles ? externalSubtitles : null;
}

class _MediaOpenResult {
  const _MediaOpenResult({required this.didOpen, this.sidecarFallbackUsed = false});

  final bool didOpen;
  final bool sidecarFallbackUsed;
}

/// Everything the shared open orchestration ([_openResolvedMedia]) produced
/// that outlives it: the (possibly sidecar-fallback-recomputed) session and
/// subtitle selection, the freshly built per-item track manager, and the
/// plans the open ran under.
class _ResolvedMediaOpenResult {
  const _ResolvedMediaOpenResult({
    required this.session,
    required this.subtitleSelection,
    required this.trackManager,
    required this.externalSubtitlePlan,
    required this.frameRatePlan,
  });

  final PlaybackSession session;
  final PlaybackSubtitleSelection subtitleSelection;
  final TrackManager trackManager;
  final _ExternalSubtitleOpenPlan externalSubtitlePlan;
  final _FrameRateStartupPlan frameRatePlan;
}

/// Shared building blocks for opening media on the live player.
///
/// The initial start flow ([_startPlayback]) and in-place reload flow
/// ([_reloadMediaInPlace]) both route through these helpers — and through
/// the shared [_openResolvedMedia] orchestration — so per-open behavior
/// (display priming, frame-rate suppression windows, native subtitle
/// styling, and the open sequence) cannot drift between paths.
/// This is also the only place that reads
/// [SettingsService.displaySwitchDelay].
extension _VideoPlayerOpenMethods on VideoPlayerScreenState {
  PlaybackSession _commitSidecarFallbackSession(PlaybackSession session) {
    return _updatePlaybackSessionSubtitleSelection(session, const PlaybackSubtitleSelection.off());
  }

  Future<PlaybackSubtitleSelection> _resolveSubtitleSelectionForOpen({
    required MediaItem metadata,
    required PlaybackInitializationResult result,
    AudioTrack? preferredAudioTrack,
    SubtitlePreference? preferredSubtitleTrack,
    SubtitlePreference? preferredSecondarySubtitleTrack,
    bool preserveSubtitleSourceIdentity = true,
  }) async {
    await _waitForProfileSettingsIfNeeded();
    if (!mounted) return const PlaybackSubtitleSelection.off();

    return PlaybackSubtitleResolver.resolve(
      metadata: metadata,
      mediaInfo: result.mediaInfo,
      sidecars: result.subtitleSidecars,
      profileSettings: context.read<AccountPreferencesController>().activePreferences,
      preferredAudioTrack: preferredAudioTrack,
      preferredSubtitleTrack: preferredSubtitleTrack,
      preferredSecondarySubtitleTrack: preferredSecondarySubtitleTrack,
      preserveSourceIdentity: preserveSubtitleSourceIdentity,
      isTranscoding: result.isTranscoding,
    );
  }

  /// Prime native display matching (tvOS HDMI mode) from server metadata
  /// before the decoder emits stream properties. The native side resolves
  /// only after any resulting display-mode switch has settled, plus the
  /// user-configured extra delay on Apple TV.
  ///
  /// On Android mpv the same server metadata announces the stream's transfer
  /// (`content-color-transfer`) so an HDR session can get a BT.2020 PQ GL
  /// surface if it ever renders through GL (software fallback, hardware
  /// decoding off). Transcoded streams stay unannounced: the server may
  /// tone-map, so the default SDR surface is the safe target.
  Future<void> _primeDisplayCriteria({
    required Player player,
    required SettingsService settingsService,
    required MediaDisplayCriteria? displayCriteria,
    required bool isTranscoding,
  }) async {
    // needsDecoderRefreshAfterDisplaySwitch is how this file distinguishes
    // the two Android backends (true = the mpv core).
    if (Platform.isAndroid && player.needsDecoderRefreshAfterDisplaySwitch) {
      final transfer = isTranscoding ? null : displayCriteria?.transfer;
      await player.setProperty('content-color-transfer', transfer ?? 'unknown');
    }
    return player.setDisplayCriteria(
      !isTranscoding && displayCriteria?.canPrimeNativeDisplayCriteria == true ? displayCriteria : null,
      extraDelayMs: PlatformDetector.isAppleTV() ? settingsService.read(SettingsService.displaySwitchDelay) * 1000 : 0,
    );
  }

  /// Ask the platform to renegotiate the display mode for [fps] and/or the
  /// video resolution, arming the MediaSession pause-suppression window
  /// first. The native call returns only after the real display-change event
  /// (+ settle + the user-configured delay). Returns whether a switch was
  /// initiated.
  Future<bool> _switchDisplayFrameRateForOpen({
    required Player player,
    required SettingsService settingsService,
    required double fps,
    required int durationMs,
    int videoWidth = 0,
    int videoHeight = 0,
  }) {
    final delaySec = settingsService.read(SettingsService.displaySwitchDelay);
    _frameRate.beginSuppressWindow(delaySec);
    return player.setVideoFrameRate(
      fps,
      durationMs,
      extraDelayMs: delaySec * 1000,
      videoWidth: videoWidth,
      videoHeight: videoHeight,
      matchResolution: settingsService.read(SettingsService.matchContentResolution),
    );
  }

  /// Whether the Android pre-open display-mode negotiation applies: the user
  /// opted into per-content refresh-rate matching and metadata already told
  /// us the target fps, and/or opted into resolution matching and metadata
  /// carries the video dimensions. Shared by the start and reload flows so
  /// the eligibility rule cannot drift between them.
  bool _shouldAutoSwitchDisplayModeForOpen(
    SettingsService settingsService, {
    double? fps,
    int width = 0,
    int height = 0,
  }) {
    if (!Platform.isAndroid) return false;
    final rateEligible = settingsService.read(SettingsService.matchContentFrameRate) && fps != null && fps > 0;
    final resolutionEligible = settingsService.read(SettingsService.matchContentResolution) && width > 0 && height > 0;
    return rateEligible || resolutionEligible;
  }

  /// Resolve where a fresh open should start: explicit request → locally
  /// tracked offline progress → server view offset.
  Future<Duration?> _resolveOpenResumePosition({
    required MediaItem metadata,
    required bool isOffline,
    required OfflineWatchSyncService offlineWatchService,
    Duration? requested,
  }) async {
    if (requested != null) return requested;
    // In offline mode, prefer locally tracked progress over the cached server
    // value since the user may have watched further since downloading.
    if (isOffline) {
      final localOffset = await offlineWatchService.getLocalViewOffset(metadata.globalKey);
      if (localOffset != null && localOffset > 0) {
        appLogger.d('Resuming offline playback from local progress: ${localOffset}ms');
        return Duration(milliseconds: localOffset);
      }
    }
    return metadata.viewOffsetMs != null ? Duration(milliseconds: metadata.viewOffsetMs!) : null;
  }

  /// Run the Android pre-open frame-rate strategy for the initial start:
  /// mpv switches before load (its decoder must start after the mode change,
  /// then gets a startup refresh); ExoPlayer switches before open (after
  /// audio focus, so AudioTrack passthrough survives the renegotiation);
  /// anything that could not switch up front falls back to a post-open
  /// switch that holds playback start. Returns null when the screen/player
  /// went stale mid-switch and the caller must bail.
  Future<_FrameRateStartupPlan?> _prepareFrameRateForOpen({
    required Player currentPlayer,
    required SettingsService settingsService,
    required double? preKnownFps,
    required bool hasVideoUrl,
    required bool isTranscoding,
    required Future<void> Function() ensureAudioFocus,
    int preKnownWidth = 0,
    int preKnownHeight = 0,
  }) async {
    // Rate-match only when the user opted in; the plan's fps drives the
    // switch calls, so a resolution-only open passes 0 to the native side.
    final rateMatchFps = settingsService.read(SettingsService.matchContentFrameRate) ? preKnownFps : null;
    final plan = _FrameRateStartupPlan(fps: rateMatchFps, width: preKnownWidth, height: preKnownHeight);
    final willAutoSwitch = _shouldAutoSwitchDisplayModeForOpen(
      settingsService,
      fps: preKnownFps,
      width: preKnownWidth,
      height: preKnownHeight,
    );
    // willAutoSwitch is Android-only, so the strategy fork below is between
    // the two Android backends: mpv needs its decoder refreshed after a
    // display switch (pre-load path), ExoPlayer switches pre-open instead.
    final isAndroidMpv = currentPlayer.needsDecoderRefreshAfterDisplaySwitch;

    // Independent of matchContentFrameRate: ExoPlayer needs the rate even when the
    // display never switches, because it also decides whether video tunneling is
    // safe for this item. Neither the Matroska nor the MP4 extractor populates
    // Format.frameRate, and a tunneled session renders no frames back for the
    // native FPS detector, so metadata is the only source.
    //
    // Source-side only, like _primeDisplayCriteria: a transcode's metadata rate
    // describes the original file, not what the server is about to send. "0" clears
    // a stale rate carried over from the previous item.
    if (Platform.isAndroid && !isAndroidMpv) {
      final directPlayFps = isTranscoding ? null : preKnownFps;
      await currentPlayer.setProperty('content-frame-rate', (directPlayFps ?? 0).toString());
    }
    final needsMpvPreLoad = willAutoSwitch && isAndroidMpv && hasVideoUrl;
    final needsExoPreOpen = willAutoSwitch && !isAndroidMpv && hasVideoUrl;
    plan.needsPostOpenSwitch = willAutoSwitch && !needsMpvPreLoad && !needsExoPreOpen;
    plan.attemptedMpvPreLoad = needsMpvPreLoad;

    // MPV on Android can decode and present its first paused frame before a
    // post-open display switch settles. Switch first when metadata already
    // gives us the FPS so MediaCodec starts after the display mode change.
    if (needsMpvPreLoad) {
      final durationMs = _currentMetadata.durationMs ?? currentPlayer.state.duration.inMilliseconds;
      try {
        appLogger.d('Display matching: pre-load MPV switch to ${plan.fps}fps (duration: ${durationMs}ms)');
        plan.didPreLoadSwitch = await _switchDisplayFrameRateForOpen(
          player: currentPlayer,
          settingsService: settingsService,
          fps: plan.fps ?? 0,
          durationMs: durationMs,
          videoWidth: plan.width,
          videoHeight: plan.height,
        );
        if (!mounted || player != currentPlayer) return null;
        if (plan.didPreLoadSwitch) {
          _frameRate.applied = true;
          plan.needsStartupRefresh = true;
        }
        appLogger.d(
          'Frame rate matching: pre-load MPV switch complete '
          '(switched=${plan.didPreLoadSwitch}, startupRefresh=${plan.needsStartupRefresh})',
        );
      } catch (e) {
        appLogger.w('Failed to apply pre-load MPV frame rate matching', error: e);
        plan.needsPostOpenSwitch = true;
        plan.needsStartupRefresh = false;
      }
    }

    // ExoPlayer prepares AudioTrack during open() even when opened paused.
    // On Shield/AVR chains, switching HDMI refresh rate after that can break
    // direct passthrough, so switch before ExoPlayer creates renderers.
    if (needsExoPreOpen) {
      final durationMs = _currentMetadata.durationMs ?? currentPlayer.state.duration.inMilliseconds;
      try {
        await ensureAudioFocus();
        if (!mounted || player != currentPlayer) return null;
        appLogger.d('Display matching: pre-open ExoPlayer switch to ${plan.fps}fps (duration: ${durationMs}ms)');
        final didSwitch = await _switchDisplayFrameRateForOpen(
          player: currentPlayer,
          settingsService: settingsService,
          fps: plan.fps ?? 0,
          durationMs: durationMs,
          videoWidth: plan.width,
          videoHeight: plan.height,
        );
        if (!mounted || player != currentPlayer) return null;
        plan.preOpenExoHandled = true;
        appLogger.d('Frame rate matching: pre-open ExoPlayer switch complete (switched=$didSwitch)');
      } catch (e) {
        appLogger.w('Failed to apply pre-open ExoPlayer frame rate matching', error: e);
        plan.needsPostOpenSwitch = true;
        plan.preOpenExoHandled = false;
      }
    }

    return plan;
  }

  /// Release the startup gate a [_FrameRateStartupPlan] held playback
  /// behind: run the post-open fallback switch, or wait for the first
  /// rendered frame and refresh the mpv decoder, then resume via
  /// [resumeAfterStartupGate].
  Future<void> _releaseFrameRateStartupGate({
    required Player currentPlayer,
    required SettingsService settingsService,
    required _FrameRateStartupPlan plan,
    required Future<void> Function(String reason) resumeAfterStartupGate,
    bool playbackResumedForStartupFrame = false,
  }) async {
    Future<void> resumeAfterRefresh(String reason) async {
      if (playbackResumedForStartupFrame) {
        appLogger.d('Frame rate matching: continuing already-resumed playback after $reason');
        await _playWithPlaybackIntent(currentPlayer);
      } else {
        await resumeAfterStartupGate(reason);
      }
    }

    // Fallback refresh-rate path. The player was opened paused;
    // setVideoFrameRate awaits the real display-change event (+ settle +
    // user delay) before returning, then we start playback.
    if (plan.needsPostOpenSwitch && mounted && player == currentPlayer) {
      _frameRate.applied = true;
      final durationMs = _currentMetadata.durationMs ?? currentPlayer.state.duration.inMilliseconds;
      bool didSwitch = false;
      try {
        didSwitch = await _switchDisplayFrameRateForOpen(
          player: currentPlayer,
          settingsService: settingsService,
          fps: plan.fps ?? 0,
          durationMs: durationMs,
          videoWidth: plan.width,
          videoHeight: plan.height,
        );
        if (!mounted || player != currentPlayer) return;
        if (didSwitch) {
          await _refreshAndroidMpvDecoderAfterFrameRateSwitch(reason: 'post-open frame rate switch');
        }
      } catch (e) {
        appLogger.w('Failed to apply pre-playback frame rate matching', error: e);
      }

      // Always resume — either the switch completed and we want to play,
      // or no switch was needed and we need to start playback now that the
      // preparation gate has been cleared.
      await resumeAfterRefresh('post-open frame rate switch');

      unawaited(
        Sentry.addBreadcrumb(
          Breadcrumb(message: 'Pre-playback frame rate: ${plan.fps}fps, switched=$didSwitch', category: 'player'),
        ),
      );
    } else if (plan.needsStartupRefresh && mounted && player == currentPlayer) {
      appLogger.d('Frame rate matching: waiting for Android MPV startup frame before decoder refresh');
      final startupFrameReady = plan._startupFrameReady;
      final startupReady = startupFrameReady == null ? false : await startupFrameReady;
      if (mounted && player == currentPlayer) {
        if (startupReady) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await _refreshAndroidMpvDecoderAfterFrameRateSwitch(reason: 'pre-load frame rate startup');
          await resumeAfterRefresh('startup decoder refresh');
        } else {
          appLogger.w('Frame rate matching: skipping Android MPV decoder refresh because startup frame timed out');
          await resumeAfterRefresh('startup frame timeout');
        }
      }

      unawaited(
        Sentry.addBreadcrumb(
          Breadcrumb(
            message: 'Android MPV startup decoder refresh after pre-load frame-rate switch',
            category: 'player',
          ),
        ),
      );
    }
  }

  /// Resume playback once a frame-rate startup gate releases: a pending
  /// post-open external-subtitle load resumes through the track manager
  /// (which also arms selection), everything else plays directly. Shared by
  /// the start and reload flows.
  Future<void> _resumeAfterFrameRateStartupGate({
    required Player currentPlayer,
    required _ExternalSubtitleOpenPlan externalSubtitlePlan,
    required String reason,
  }) async {
    if (!mounted || player != currentPlayer) return;
    final trackManager = _trackManager;
    if (trackManager == null) return;
    appLogger.d('Frame rate matching: resuming playback after $reason');
    if (!automotivePlaybackAllowedNow()) {
      // The vehicle outranks the startup gate: releasing the frame-rate gate is not permission to
      // play. Subtitle selection still has to land, or the track stays stuck waiting for it.
      _playbackIntentShouldPlay = false;
      if (externalSubtitlePlan.requiresPostOpenAdd) {
        trackManager.waitingForExternalSubsTrackSelection = false;
        trackManager.applyTrackSelectionWhenReady();
      }
      return;
    }
    _playbackIntentShouldPlay = true;
    if (externalSubtitlePlan.requiresPostOpenAdd) {
      await trackManager.resumeAfterSubtitleLoad();
    } else {
      await _playWithPlaybackIntent(currentPlayer);
    }
  }

  /// Resolves the post-gate playback decision without inventing a play
  /// intent. Track selection is still armed when playback must remain paused;
  /// a Watch Together owner also receives its readiness release.
  Future<void> _finishPlaybackAfterStartupGate({
    required Player currentPlayer,
    required _ExternalSubtitleOpenPlan externalSubtitlePlan,
    required String reason,
    required bool shouldResume,
    required bool watchTogetherOwnsStart,
    Completer<void>? wtStartupHold,
  }) async {
    if (shouldResume) {
      return _resumeAfterFrameRateStartupGate(
        currentPlayer: currentPlayer,
        externalSubtitlePlan: externalSubtitlePlan,
        reason: reason,
      );
    }
    appLogger.d(
      watchTogetherOwnsStart
          ? 'Frame rate matching: yielding post-gate resume to Watch Together ($reason)'
          : 'Frame rate matching: preserving paused playback after $reason',
    );
    final trackManager = _trackManager;
    if (trackManager != null && externalSubtitlePlan.requiresPostOpenAdd) {
      trackManager.waitingForExternalSubsTrackSelection = false;
      trackManager.applyTrackSelectionWhenReady();
    }
    if (watchTogetherOwnsStart && wtStartupHold != null && !wtStartupHold.isCompleted) {
      wtStartupHold.complete();
    }
  }

  /// Push the user's subtitle style to the native rendering layer. Must run
  /// after open() since that's when ExoPlayer initializes its subtitle views.
  /// Only the ExoPlayer backend consumes it — [Player.setSubtitleStyle] is a
  /// no-op on every mpv backend, which styles via `sub-*` properties — so the
  /// style settings reads are skipped there. Gated on the same
  /// configured-backend signal as track_controls/video_settings_sheet; the
  /// Android mpv fallback keeps playerType 'exoplayer' and still receives the
  /// call, exactly as before.
  Future<void> _applyNativeSubtitleStyle(Player player, SettingsService settingsService) async {
    if (player.playerType != 'exoplayer') return;
    await player.setSubtitleStyle(
      fontSize: settingsService.read(SettingsService.subtitleFontSize).toDouble(),
      textColor: settingsService.read(SettingsService.subtitleTextColor),
      borderSize: settingsService.read(SettingsService.subtitleBorderSize).toDouble(),
      borderColor: settingsService.read(SettingsService.subtitleBorderColor),
      bgColor: settingsService.read(SettingsService.subtitleBackgroundColor),
      bgOpacity: settingsService.read(SettingsService.subtitleBackgroundOpacity),
      subtitlePosition: settingsService.read(SettingsService.subtitlePosition),
      bold: settingsService.read(SettingsService.subtitleBold),
      italic: settingsService.read(SettingsService.subtitleItalic),
      anchorToScreen: settingsService.read(SettingsService.subtitleAnchorToScreen),
    );
  }

  _ExternalSubtitleOpenPlan _prepareExternalSubtitleOpenPlan({
    required Player player,
    required List<SubtitleTrack> externalSubtitles,
    bool waitForFileLoaded = true,
  }) {
    final attachesAtOpen = player.attachesExternalSubtitlesAtOpen;
    final hasExternalSubtitles = externalSubtitles.isNotEmpty;

    return _ExternalSubtitleOpenPlan(
      externalSubtitles: externalSubtitles,
      attachesAtOpen: attachesAtOpen,
      readyAfterOpen: waitForFileLoaded && !attachesAtOpen && hasExternalSubtitles
          ? player.streams.fileLoaded.first.timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                appLogger.w('Timed out waiting for file-loaded before adding external subtitles');
              },
            )
          : null,
    );
  }

  /// Build the per-item [TrackManager] for a freshly opened source. The
  /// start and reload flows construct it identically apart from where the
  /// preferred tracks and profile settings come from.
  TrackManager _buildTrackManager({
    required Player forPlayer,
    required MediaItem metadata,
    required PlexClient? plexClient,
    required MediaServerUserProfile? Function() getProfileSettings,
    AudioTrack? preferredAudioTrack,
    SubtitlePreference? preferredSubtitleTrack,
    SubtitlePreference? preferredSecondarySubtitleTrack,
    bool primarySubtitleIsServerRendered = false,
  }) {
    return TrackManager(
      player: forPlayer,
      isActive: () => mounted && player == forPlayer,
      // Plex writes track changes immediately. Jellyfin persists selected
      // indexes through playback progress reports.
      persistTrackPreference: plexClient != null ? _plexTrackPersister(() => plexClient) : null,
      getProfileSettings: getProfileSettings,
      waitForProfileSettings: _waitForProfileSettingsIfNeeded,
      metadata: metadata,
      mediaInfo: _currentMediaInfo,
      preferredAudioTrack: preferredAudioTrack,
      preferredSubtitleTrack: preferredSubtitleTrack,
      preferredSecondarySubtitleTrack: preferredSecondarySubtitleTrack,
      primarySubtitleIsServerRendered: primarySubtitleIsServerRendered,
      showMessage: (message, {duration}) {
        if (mounted) showAppSnackBar(context, message, duration: duration);
      },
      playbackRateOwnedExternally: _watchTogetherOwnsPlaybackRate,
    );
  }

  /// Apply track selection for a freshly opened source: backends that cannot
  /// attach external subtitles during open use the post-open sub-add dance
  /// (opened paused to avoid the issue #226 race), others arm selection
  /// directly.
  /// [shouldResumeAfterSubtitleLoad] lets a startup gate own the resume.
  /// [applySelectionWhenResumeSkipped] is for flows that legitimately stay
  /// paused (e.g. a transcode restart while paused): selection is still
  /// armed and the waiting flag cleared instead of leaving both dangling.
  Future<void> _applyTracksAfterOpen({
    required TrackManager trackManager,
    required _ExternalSubtitleOpenPlan externalSubtitlePlan,
    required bool Function() shouldResumeAfterSubtitleLoad,
    bool applySelectionWhenResumeSkipped = false,
  }) async {
    if (externalSubtitlePlan.requiresPostOpenAdd) {
      trackManager.waitingForExternalSubsTrackSelection = true;
      try {
        await trackManager.addExternalSubtitles(
          externalSubtitlePlan.externalSubtitles,
          waitUntilReady: externalSubtitlePlan.readyAfterOpen,
        );
      } finally {
        // A car must not start playing just because subtitles finished loading: the vehicle's
        // verdict outranks the caller's startup gate, and a skipped resume still has to release the
        // subtitle-selection wait.
        final resumeWanted = shouldResumeAfterSubtitleLoad();
        if (resumeWanted && automotivePlaybackAllowedNow()) {
          _playbackIntentShouldPlay = true;
          await trackManager.resumeAfterSubtitleLoad();
        } else if (applySelectionWhenResumeSkipped || resumeWanted) {
          trackManager.waitingForExternalSubsTrackSelection = false;
          trackManager.applyTrackSelectionWhenReady();
        }
      }
    } else {
      // Subs attached at open time (ExoPlayer) or none: apply once tracks
      // are available.
      trackManager.applyTrackSelectionWhenReady();
    }
  }

  /// Drop the previous item's scrub-preview source and kick off the async
  /// thumbnail load for the new one.
  void _resetScrubPreviewForNewItem({
    required MediaItem metadata,
    required MediaSourceInfo? mediaInfo,
    required MediaServerClient? mediaClient,
  }) {
    _scrubPreviewSource?.dispose();
    _setPlayerState(() => _scrubPreviewSource = null);
    _queueScrubPreviewLoad(metadata: metadata, mediaInfo: mediaInfo, mediaClient: mediaClient);
  }

  /// Per-open network stream tunings: ffmpeg auto-reconnect plus an enlarged
  /// mpv stream ring buffer for poorly interleaved MP4/MOV direct play (the
  /// ring absorbs the demuxer's audio↔video byte ping-pong so HTTP reads stay
  /// linear instead of dropping the connection on every byte seek — see
  /// [networkStreamRingBytes]). Every property is always written, set or
  /// reset, so a reused player never carries one item's tuning into the next
  /// open. On Android with ExoPlayer active they are stashed natively and
  /// replayed on the exo→mpv fallback, so keep them unconditional.
  Future<void> _applyNetworkStreamTuning({
    required Player player,
    required bool isNetworkVod,
    required bool isTranscoding,
    required MediaVersion? selectedVersion,
  }) async {
    if (isNetworkVod) {
      // Covers network drops up to 10 min; applies to transcode streams too.
      //
      // reconnect_on_http_error=503: without it, ffmpeg abandons a reconnect
      // that gets an HTTP error and the truncated body surfaces as a clean
      // mid-file EOF (#1520 — PMS answers 503 while restarting/maintenance).
      // Deliberately 503 only: a persistent 500 must keep failing fast so the
      // server-limit dialog (_httpStatusPattern) appears promptly, and a
      // multi-code list would need mpv's %len% quoting to survive the
      // comma-separated option string. While ffmpeg retries, mpv reports
      // buffering, which also makes the server-online reconnect hook in
      // _wirePlayerStreams reachable.
      await player.setProperty(
        'stream-lavf-o',
        'reconnect=1,reconnect_on_network_error=1,reconnect_on_http_error=503,'
            'reconnect_streamed=1,reconnect_delay_max=600',
      );
    } else {
      await player.setProperty('stream-lavf-o', '');
    }

    // Transcode (HLS) segment fetches happen inside ffmpeg's hls demuxer, not
    // mpv's stream layer, so the reconnect options above never reach them and
    // mpv's default network-timeout is inert there: a segment response PMS
    // leaves open without data or error — observed when the request races a
    // transcoder seek/restart — buffers forever (#1859). An explicit
    // network-timeout bounds each stalled read and the demuxer-level
    // reconnect options re-request the same segment instead of skipping its
    // content. 20s sits above the segment-serve latency of a struggling
    // transcode (reads that deliver any bytes reset the clock) and a false
    // trip is a Range-resumed reconnect, not an error.
    if (isNetworkVod && isTranscoding) {
      await player.setProperty('network-timeout', '20');
      await player.setProperty('demuxer-lavf-o', 'reconnect=1,reconnect_streamed=1,reconnect_on_network_error=1');
    } else {
      // mpv's documented default network-timeout.
      await player.setProperty('network-timeout', '60');
      await player.setProperty('demuxer-lavf-o', '');
    }

    int? ringBytes;
    if (isNetworkVod && !isTranscoding) {
      // Transcode (HLS) playback only uses the mpv stream layer for the
      // playlist file; segment fetches happen inside ffmpeg's hls demuxer.
      final maxBytes = Platform.isAndroid
          ? androidStreamRingCapBytes(await PlayerNative.getHeapSize())
          : maxStreamRingBytes;
      ringBytes = networkStreamRingBytes(
        container: selectedVersion?.container,
        bitrateKbps: selectedVersion?.bitrate,
        maxBytes: maxBytes,
      );
    }
    if (ringBytes != null) {
      appLogger.i(
        'Stream ring buffer: ${ringBytes ~/ (1024 * 1024)}MiB '
        '(container=${selectedVersion?.container}, bitrate=${selectedVersion?.bitrate}kbps)',
      );
    } else {
      appLogger.d(
        'Stream ring buffer: default '
        '(networkVod=$isNetworkVod, transcoding=$isTranscoding, container=${selectedVersion?.container})',
      );
    }
    await player.setProperty('stream-buffer-size', '${ringBytes ?? mpvDefaultStreamBufferBytes}');
  }

  /// Open [videoUrl] on [player]: stream tuning → open → native subtitle style.
  ///
  /// [shouldContinue] is re-checked between the awaits so stale generations
  /// stop without touching the player further. [onOpened] fires immediately
  /// after open() returns (before styling) so callers can flip rollback
  /// bookkeeping at the exact ownership boundary.
  ///
  /// Returns whether open was issued and whether a selected remote sidecar
  /// stalled after the primary media was ready, requiring an automatic reopen
  /// without subtitles.
  Future<_MediaOpenResult> _openMediaOnPlayer({
    required Player player,
    required SettingsService settingsService,
    required String videoUrl,
    required bool isTranscoding,
    required bool isLocalMedia,
    required MediaVersion? selectedVersion,
    required _PlaybackOpenTiming timing,
    Map<String, String>? headers,
    required bool play,
    List<SubtitleTrack>? externalSubtitlesAtOpen,
    bool Function()? shouldContinue,
    void Function()? onOpening,
    void Function()? onOpened,
    void Function(bool available)? onMediaAvailabilityChanged,
  }) async {
    await _applyNetworkStreamTuning(
      player: player,
      isNetworkVod: !isLocalMedia && !widget.isLive,
      isTranscoding: isTranscoding,
      selectedVersion: selectedVersion,
    );
    if (shouldContinue != null && !shouldContinue()) return const _MediaOpenResult(didOpen: false);

    final media = Media(videoUrl, start: timing.mediaStart, headers: headers);
    final sidecarOpenGuard = MpvSidecarOpenGuard.armIfNeeded(player: player, subtitles: externalSubtitlesAtOpen);
    Future<void> openMedia({required bool shouldPlay, List<SubtitleTrack>? externalSubtitles}) {
      onOpening?.call();
      return player.open(
        media,
        // The last word on the vehicle, taken here because this is the only place media actually
        // starts: callers decide `play` before awaiting resolve, tuning and track work, and a car
        // that starts driving in between has already spent its restriction pausing the outgoing
        // item. `DD-3` allows video no exemption, and the gated resume paths start it once parked.
        play: shouldPlay && automotivePlaybackAllowedNow(),
        externalSubtitles: externalSubtitles,
        timelineDuration: timing.timelineDuration,
      );
    }

    try {
      await openMedia(shouldPlay: play, externalSubtitles: externalSubtitlesAtOpen);
      onOpened?.call();
      onMediaAvailabilityChanged?.call(true);
    } catch (_) {
      await sidecarOpenGuard?.dispose();
      rethrow;
    }

    var sidecarFallbackUsed = false;
    final sidecarOutcome = await sidecarOpenGuard?.wait();
    if (sidecarOutcome == MpvSidecarOpenOutcome.aborted) {
      return const _MediaOpenResult(didOpen: true);
    }
    if (sidecarOutcome == MpvSidecarOpenOutcome.stalled) {
      appLogger.w('Selected subtitle sidecar stalled after primary media discovery; reopening without subtitles');
      if (shouldContinue != null && !shouldContinue()) {
        return const _MediaOpenResult(didOpen: true);
      }
      await player.stop();
      onMediaAvailabilityChanged?.call(false);
      if (shouldContinue != null && !shouldContinue()) return const _MediaOpenResult(didOpen: true);
      // Respect a pause requested while mpv was waiting on the sidecar. A
      // startup gate encoded by [play] remains authoritative when it is false.
      await openMedia(shouldPlay: play && _playbackIntentShouldPlay);
      onMediaAvailabilityChanged?.call(true);
      sidecarFallbackUsed = true;
      if (mounted && (shouldContinue == null || shouldContinue())) {
        showErrorSnackBar(context, t.videoControls.subtitleUnavailableFallback);
      }
    }

    if (shouldContinue != null && !shouldContinue()) {
      return _MediaOpenResult(didOpen: true, sidecarFallbackUsed: sidecarFallbackUsed);
    }
    await _applyNativeSubtitleStyle(player, settingsService);
    return _MediaOpenResult(didOpen: true, sidecarFallbackUsed: sidecarFallbackUsed);
  }

  /// Shared orchestration for opening a resolved source on the live player:
  /// pre-open frame-rate negotiation → per-item frame-rate reset → display
  /// priming → startup-gate arming → external-subtitle planning → open →
  /// sidecar-fallback session recompute → track-manager build → post-open
  /// track application → frame-rate startup-gate release.
  ///
  /// The initial start flow ([_startPlayback]) and the in-place reload flow
  /// ([_reloadMediaInPlace]) both run this sequence; caller-specific
  /// choreography (session commit boundary, Watch Together attach/detach,
  /// progress-tracker teardown, per-screen service setup) stays in the
  /// callers and runs through the hooks below at its original position in
  /// the sequence. Deliberate per-flow differences are explicit parameters —
  /// nothing here may silently unify them.
  ///
  /// Returns null when a staleness guard or hook aborted the flow (the start
  /// flow returns silently, the reload flow maps it to superseded); open
  /// failures still throw to the caller.
  Future<_ResolvedMediaOpenResult?> _openResolvedMedia({
    required Player currentPlayer,
    required SettingsService settingsService,
    // start: _currentMetadata; reload: the replacement item's metadata.
    required MediaItem metadata,
    required PlaybackInitializationResult result,
    required PlaybackSession session,
    required PlaybackSubtitleSelection subtitleSelection,
    // start: the resolved stream headers; reload drops them for local media.
    required Map<String, String>? headers,
    // start: _isOfflinePlayback (its session is already committed); reload:
    // _offlineLibraryMode || result.usesLocalMedia because its replacement
    // session commits later, in [onOpened], so the getter still describes
    // the previous item at open time.
    required bool isLocalMedia,
    // Staleness check used at the shared guard points and as
    // [_openMediaOnPlayer]'s shouldContinue. start: attempt.isCurrent;
    // reload: isCurrentReload (attempt + fatal-error + exiting).
    required bool Function() isCurrent,
    // Whether an active Watch Together session owns the (group) start. The
    // start flow reads it live right after the frame-rate negotiation (its
    // original position); the reload flow captured it before detaching the
    // player from the session and replays that value.
    required bool Function() watchTogetherOwnsStart,
    // Whether this open should end in playing. start: !wtOwnsStart (an
    // initial start always intends to play unless the sync layer owns the
    // group start); reload: shouldAutoStartReloadedMedia (was-playing /
    // startPaused / Watch Together).
    required bool Function(bool wtOwnsStart) resolveShouldAutoStart,
    // Where playback starts. reload resolves it before the old stop report;
    // start resolves it in [beforePrime] (after audio focus, its original
    // position) and exposes the value here.
    required Duration? Function() resumePosition,
    // Plex client for TrackManager's server-side track persistence. reload
    // narrows the resolver's reporting client; start derives it from the
    // screen's media client inside [beforeTrackSetup].
    required PlexClient? Function() plexClient,
    required MediaServerUserProfile? Function() getProfileSettings,
    // start: the launch-time preference; reload: the carried-over selection.
    required AudioTrack? preferredAudioTrack,
    // Transcode signal for the server-rendered-primary-subtitle rule. Known
    // per-flow drift, kept deliberately: start reads the live session-backed
    // _isTranscoding getter (its session committed before this call); reload
    // reads result.isTranscoding because its session commits at the open
    // boundary.
    required bool Function() primarySubtitleTranscoding,
    // Audio-focus hook for the pre-open ExoPlayer switch. start memoizes the
    // in-flight _audioFocusFuture; reload requests focus directly.
    required Future<void> Function() ensureAudioFocus,
    // start: true — the flag is dropped here, right before the frame-rate
    // reset; reload dropped it earlier, at its eager-identity boundary.
    required bool clearFirstFrameForOpen,
    // start: true — open never auto-plays on automotive and [afterMediaOpened]
    // re-issues the play intent instead; reload: false — the vehicle verdict
    // is read inside [_openMediaOnPlayer] at the player.open itself, which is
    // after this call and its own awaited tuning work.
    required bool deferAutomotiveStart,
    // reload-only extra staleness re-checks (right after the frame-rate plan
    // and right after track application); the start flow has none there.
    bool Function()? staleGuard,
    // start-only: audio focus + resume-position resolution between the
    // frame-rate reset and display priming. Return false to abort.
    Future<bool> Function()? beforePrime,
    // reload-only: progress-tracker teardown and the captured track-mutation
    // drain between display priming and startup-gate arming. Return false to
    // abort.
    Future<bool> Function()? beforeArm,
    // Runs right after the open boundary (incl. the sidecar-fallback session
    // recompute), only when a video URL was opened. start: Watch Together
    // attach + deferred automotive start; reload: completion-latch/scrub/
    // loading-flag upkeep and disposing the previous track manager. Return
    // false to abort.
    required Future<bool> Function(bool shouldAutoPlay, bool holdPlaybackStart, bool wtOwnsStart) afterMediaOpened,
    // start-only: mounted gate + per-screen service setup (scrub preview,
    // video filter/PiP, shaders) between the open branch and the track
    // manager build. Return false to abort.
    Future<bool> Function()? beforeTrackSetup,
    // start-only: reads the Watch Together startup hold its
    // [afterMediaOpened] may have created, consumed when the startup gate
    // resolves the post-gate playback decision.
    Completer<void>? Function()? wtStartupHold,
    // Open-boundary callbacks passed through to [_openMediaOnPlayer]: reload
    // disarms the 503 watchdog in [onOpening] and commits its session in
    // [onOpened]; start tracks primary-media availability for its error
    // classification.
    void Function()? onOpening,
    void Function()? onOpened,
    void Function(bool available)? onMediaAvailabilityChanged,
  }) async {
    final displayCriteria = result.mediaInfo?.displayCriteria;

    final frameRatePlan = await _prepareFrameRateForOpen(
      currentPlayer: currentPlayer,
      settingsService: settingsService,
      preKnownFps: displayCriteria?.fps,
      preKnownWidth: displayCriteria?.width ?? 0,
      preKnownHeight: displayCriteria?.height ?? 0,
      hasVideoUrl: result.videoUrl != null,
      isTranscoding: result.isTranscoding,
      ensureAudioFocus: ensureAudioFocus,
    );
    if (frameRatePlan == null || (staleGuard != null && !staleGuard())) return null;

    final wtOwnsStart = watchTogetherOwnsStart();
    final shouldAutoStart = resolveShouldAutoStart(wtOwnsStart);
    var openSession = session;
    var openSubtitleSelection = subtitleSelection;
    late _ExternalSubtitleOpenPlan externalSubtitlePlan;

    // Open video through Player
    if (result.videoUrl != null) {
      // Reset first frame flag and frame rate retry counter for new video
      if (clearFirstFrameForOpen) _firstFrame.resetUiForOpen();
      _frameRate.resetForNewItem();
      if (frameRatePlan.countsAsApplied) {
        _frameRate.applied = true;
      }

      if (beforePrime != null && !await beforePrime()) return null;

      await _primeDisplayCriteria(
        player: currentPlayer,
        settingsService: settingsService,
        displayCriteria: displayCriteria,
        isTranscoding: result.isTranscoding,
      );

      if (beforeArm != null && !await beforeArm()) return null;

      frameRatePlan.armStartupRefreshGate(currentPlayer);
      externalSubtitlePlan = _prepareExternalSubtitleOpenPlan(
        player: currentPlayer,
        externalSubtitles: openSubtitleSelection.sidecarsAtOpen,
      );
      final shouldAutoPlay =
          shouldAutoStart && !frameRatePlan.holdPlaybackStart && externalSubtitlePlan.canStartBeforeTrackSetup;

      // Backends that support at-open sidecars receive them with open()
      // so tracks are discovered in a single prepare/loadfile cycle. Any
      // backend that cannot do that still uses the post-open sub-add path.
      final openTiming = _playbackOpenTiming(
        isTranscoding: result.isTranscoding,
        resumePosition: resumePosition(),
        durationMs: metadata.durationMs,
      );
      if (!isCurrent()) return null;
      final openResult = await _openMediaOnPlayer(
        player: currentPlayer,
        settingsService: settingsService,
        videoUrl: result.videoUrl!,
        isTranscoding: result.isTranscoding,
        isLocalMedia: isLocalMedia,
        selectedVersion: result.selectedVersion,
        timing: openTiming,
        headers: headers,
        play: deferAutomotiveStart ? shouldAutoPlay && !PlatformDetector.isAutomotive() : shouldAutoPlay,
        externalSubtitlesAtOpen: externalSubtitlePlan.subtitlesAtOpen,
        shouldContinue: isCurrent,
        onOpening: onOpening,
        onOpened: onOpened,
        onMediaAvailabilityChanged: onMediaAvailabilityChanged,
      );
      // A false didOpen means shouldContinue stopped the sequence pre-open;
      // open failures throw to the caller instead.
      if (!openResult.didOpen || !isCurrent()) return null;
      if (openResult.sidecarFallbackUsed) {
        openSession = _commitSidecarFallbackSession(openSession);
        openSubtitleSelection = openSession.subtitleSelection;
        externalSubtitlePlan = _prepareExternalSubtitleOpenPlan(player: currentPlayer, externalSubtitles: const []);
      }

      if (!await afterMediaOpened(shouldAutoPlay, frameRatePlan.holdPlaybackStart, wtOwnsStart)) return null;
    } else {
      externalSubtitlePlan = _prepareExternalSubtitleOpenPlan(
        player: currentPlayer,
        externalSubtitles: openSubtitleSelection.sidecarsAtOpen,
        waitForFileLoaded: false,
      );
    }

    if (beforeTrackSetup != null && !await beforeTrackSetup()) return null;

    // Track manager: owns track selection, external subtitle loading, and Plex
    // immediate stream writes. Jellyfin persists selected stream indexes through
    // playback progress reports instead.
    final trackManager = _buildTrackManager(
      forPlayer: currentPlayer,
      metadata: metadata,
      plexClient: plexClient(),
      getProfileSettings: getProfileSettings,
      preferredAudioTrack: preferredAudioTrack,
      // A declined preference stays alive for the native passes instead of
      // being frozen into off: the resolver's off verdict would turn a
      // metadata mismatch into a navigation-priority off that no late track
      // can undo (#1785).
      preferredSubtitleTrack:
          openSubtitleSelection.declinedPreference ??
          SubtitlePreference.trackOrNull(openSubtitleSelection.primaryTrack),
      preferredSecondarySubtitleTrack: SubtitlePreference.trackOrNull(openSubtitleSelection.secondaryTrack),
      // A source-backed primary with no sidecar on a transcode is one the
      // server burned into the picture: it is already visible, and no native
      // track will ever arrive to match it.
      primarySubtitleIsServerRendered:
          primarySubtitleTranscoding() &&
          openSubtitleSelection.primarySourceStreamId != null &&
          openSubtitleSelection.primarySidecar == null,
    );
    _trackManager = trackManager;

    // Store only the active sidecars for re-use after backend fallback.
    trackManager.cacheExternalSubtitles(openSubtitleSelection.sidecarsAtOpen);

    final resumeForStartupFrame =
        shouldAutoStart && frameRatePlan.needsStartupRefresh && externalSubtitlePlan.requiresPostOpenAdd;
    await _applyTracksAfterOpen(
      trackManager: trackManager,
      externalSubtitlePlan: externalSubtitlePlan,
      // When the startup gate below owns the resume, skip this one to avoid
      // a double-play, and never resume a player a newer flow owns. Paused
      // and Watch Together-owned starts arm selection through the
      // resume-skipped branch instead. Post-open external-subtitle paths are
      // the exception: after they attach we must resume once so mpv can
      // produce the startup frame the decoder-refresh gate is waiting for.
      shouldResumeAfterSubtitleLoad: () =>
          shouldAutoStart &&
          (!frameRatePlan.holdPlaybackStart || resumeForStartupFrame) &&
          mounted &&
          player == currentPlayer,
      applySelectionWhenResumeSkipped: !shouldAutoStart && !frameRatePlan.holdPlaybackStart,
    );
    if (staleGuard != null && !staleGuard()) return null;

    await _releaseFrameRateStartupGate(
      currentPlayer: currentPlayer,
      settingsService: settingsService,
      plan: frameRatePlan,
      // Paused opens use the same no-resume branch as an externally
      // coordinated start: track selection is armed without manufacturing a
      // new play intent, and a Watch Together owner also gets its readiness
      // hold released.
      resumeAfterStartupGate: (reason) => _finishPlaybackAfterStartupGate(
        currentPlayer: currentPlayer,
        externalSubtitlePlan: externalSubtitlePlan,
        reason: reason,
        shouldResume: shouldAutoStart,
        watchTogetherOwnsStart: wtOwnsStart,
        wtStartupHold: wtStartupHold?.call(),
      ),
      playbackResumedForStartupFrame: resumeForStartupFrame,
    );

    return _ResolvedMediaOpenResult(
      session: openSession,
      subtitleSelection: openSubtitleSelection,
      trackManager: trackManager,
      externalSubtitlePlan: externalSubtitlePlan,
      frameRatePlan: frameRatePlan,
    );
  }
}
