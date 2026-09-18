part of '../../video_player_screen.dart';

/// Outcome of the pre-open display negotiation for one open: which
/// pre-switch ran (ExoPlayer only), whether playback must open paused behind
/// a startup gate, and which post-open follow-up releases it.
///
/// mpv never switches before open: its target is read from the decoded
/// stream itself (see [PlayerOutputFormat]), so it opens paused, negotiates
/// the display once the first frame proves what is being presented, and
/// resumes. ExoPlayer keeps its metadata-driven pre-open switch.
class _FrameRateStartupPlan {
  _FrameRateStartupPlan({required this.fps, this.width = 0, this.height = 0});

  /// The ExoPlayer fps to rate-match; null when refresh-rate matching is off
  /// or the rate is unknown (a resolution-only switch passes 0 natively,
  /// which keeps the current refresh rate). Always null for mpv.
  final double? fps;

  /// Native video dimensions for the ExoPlayer switch: the
  /// resolution-matching target when that setting is on, and otherwise the
  /// floor a display-mode fallback must not downscale below just to match
  /// cadence (0 = unknown).
  final int width;
  final int height;
  bool preOpenExoHandled = false;
  bool needsPostOpenSwitch = false;

  /// Open paused; once the first frame is shown, negotiate the display from
  /// the player's own output (Android mpv) or wait out the AVDisplayManager
  /// switch the decoded stream triggered (Apple TV), then resume.
  bool needsFirstFrameSwitch = false;

  /// The first-frame signal, taken from the attempt's open outcome *before*
  /// open() so the gate can't miss a synchronously-fast restart event.
  /// Non-null exactly while [needsFirstFrameSwitch] is set, which is final
  /// before [armFirstFrameGate] runs. Resolves false — never throws — when
  /// the open fails, is aborted, or hits the outcome's deadline.
  Future<bool> _startupFrameReady = Future<bool>.value(false);

  /// The [FrameRateMatcher.beginDisplayNegotiation] token holding the first
  /// frame behind the loading UI for this open; null when no gate is armed.
  Object? displayNegotiation;

  /// Whether playback must open paused behind a startup gate that
  /// [_releaseFrameRateStartupGate] resumes.
  bool get holdPlaybackStart => needsPostOpenSwitch || needsFirstFrameSwitch;

  /// Whether the plan already owns the per-item switch — keeps the
  /// post-first-frame fallback from double-switching while a planned
  /// follow-up is still pending.
  bool get countsAsApplied => needsFirstFrameSwitch || preOpenExoHandled;

  /// See [_startupFrameReady]. Also begins the first-frame UI hold on
  /// [frameRate], which the gate release ends with this plan's token.
  void armFirstFrameGate(PlaybackOpenOutcome outcome, FrameRateMatcher frameRate) {
    if (!needsFirstFrameSwitch) return;
    appLogger.d('Display matching: opening paused until the first frame reveals the presented format');
    _startupFrameReady = outcome.firstFrame;
    displayNegotiation = frameRate.beginDisplayNegotiation();
  }
}

class _MediaOpenResult {
  const _MediaOpenResult({required this.didOpen, this.sidecarFallbackUsed = false});

  final bool didOpen;
  final bool sidecarFallbackUsed;
}

/// Start position for a fresh open, in precedence order: an explicit
/// caller request (version switch, stream recovery, Watch Together), the
/// shuffle-starts-from-beginning override (#2303), locally tracked offline
/// progress, then the server-side view offset.
Duration? resolveOpenResumePosition({
  Duration? requested,
  bool shuffleFromBeginning = false,
  int? offlineOffsetMs,
  int? viewOffsetMs,
}) {
  if (requested != null) return requested;
  if (shuffleFromBeginning) return Duration.zero;
  if (offlineOffsetMs != null && offlineOffsetMs > 0) {
    return Duration(milliseconds: offlineOffsetMs);
  }
  return viewOffsetMs != null ? Duration(milliseconds: viewOffsetMs) : null;
}

/// Shared building blocks for opening media on the live player.
///
/// The initial start flow ([_startPlayback]) and in-place reload flow
/// ([_reloadMediaInPlace]) both route through these helpers — and through
/// the shared [_openResolvedMedia] orchestration — so per-open behavior
/// (the GL color-transfer hint, frame-rate suppression windows, native
/// subtitle styling, and the open sequence) cannot drift between paths.
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

  /// On Android mpv, announce the stream's transfer (`content-color-transfer`)
  /// from server metadata so an HDR session can get a BT.2020 PQ GL surface
  /// if it ever renders through GL (software fallback, hardware decoding
  /// off). Transcoded streams stay unannounced: the server may tone-map, so
  /// the default SDR surface is the safe target. This is a surface-format
  /// hint set before the decoder exists, not display matching — the display
  /// mode itself is negotiated from mpv's decoded stream on every platform.
  Future<void> _announceContentColorTransfer({
    required Player player,
    required MediaDisplayCriteria? displayCriteria,
    required bool isTranscoding,
  }) async {
    // needsDecoderRefreshAfterDisplaySwitch is how this file distinguishes
    // the two Android backends (true = the mpv core).
    if (!Platform.isAndroid || !player.needsDecoderRefreshAfterDisplaySwitch) return;
    final transfer = isTranscoding ? null : displayCriteria?.transfer;
    await player.setProperty('content-color-transfer', transfer ?? 'unknown');
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

  /// Whether the ExoPlayer pre-open display-mode negotiation applies: the
  /// user opted into per-content refresh-rate matching and metadata already
  /// told us the target fps, and/or opted into resolution matching and
  /// metadata carries the video dimensions. Shared by the start and reload
  /// flows so the eligibility rule cannot drift between them.
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

  /// Resolve where a fresh open should start: explicit request → shuffle
  /// override → locally tracked offline progress → server view offset.
  Future<Duration?> _resolveOpenResumePosition({
    required MediaItem metadata,
    required bool isOffline,
    required OfflineWatchSyncService offlineWatchService,
    Duration? requested,
  }) async {
    // A shuffled queue opts out of resume when the user asked for it (#2303):
    // every item opens at 0:00, including episodes reached through
    // auto-advance and Plex server-side window refetches. Explicit requests
    // still win, so the flag is only read when no request is in play.
    final shuffleFromBeginning =
        requested == null &&
        mounted &&
        context.read<PlaybackStateProvider>().isShuffleActive &&
        (await SettingsService.getInstance()).read(SettingsService.shuffleStartsFromBeginning);
    int? offlineOffsetMs;
    // In offline mode, prefer locally tracked progress over the cached server
    // value since the user may have watched further since downloading.
    if (requested == null && !shuffleFromBeginning && isOffline) {
      offlineOffsetMs = await offlineWatchService.getLocalViewOffset(metadata.globalKey);
      if (offlineOffsetMs != null && offlineOffsetMs > 0) {
        appLogger.d('Resuming offline playback from local progress: ${offlineOffsetMs}ms');
      }
    }
    return resolveOpenResumePosition(
      requested: requested,
      shuffleFromBeginning: shuffleFromBeginning,
      offlineOffsetMs: offlineOffsetMs,
      viewOffsetMs: metadata.viewOffsetMs,
    );
  }

  /// Decide the display strategy for an open. mpv (Android) and Apple TV
  /// open paused and negotiate from the decoded stream at the first frame;
  /// ExoPlayer switches before open from metadata (after audio focus, so
  /// AudioTrack passthrough survives the renegotiation) and falls back to a
  /// post-open switch that holds playback start when it could not. Returns
  /// null when the screen/player went stale mid-switch and the caller must
  /// bail.
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
    // needsDecoderRefreshAfterDisplaySwitch is how this file distinguishes
    // the two Android backends (true = the mpv core).
    final isAndroidMpv = currentPlayer.needsDecoderRefreshAfterDisplaySwitch;
    if (isAndroidMpv || PlatformDetector.isAppleTV()) {
      final plan = _FrameRateStartupPlan(fps: null);
      final matchingEnabled =
          settingsService.read(SettingsService.matchContentFrameRate) ||
          settingsService.read(SettingsService.matchContentResolution);
      // Apple TV matching is a system setting (AVDisplayManager); the gate
      // only exists to keep playback from running through the HDMI blank.
      plan.needsFirstFrameSwitch = hasVideoUrl && (!isAndroidMpv || matchingEnabled);
      return plan;
    }

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

    // Independent of matchContentFrameRate: ExoPlayer needs the rate even when the
    // display never switches, because it also decides whether video tunneling is
    // safe for this item. Neither the Matroska nor the MP4 extractor populates
    // Format.frameRate, and a tunneled session renders no frames back for the
    // native FPS detector, so metadata is the only source.
    //
    // Source-side only: a transcode's metadata rate describes the original
    // file, not what the server is about to send. "0" clears a stale rate
    // carried over from the previous item.
    if (Platform.isAndroid) {
      final directPlayFps = isTranscoding ? null : preKnownFps;
      await currentPlayer.setProperty('content-frame-rate', (directPlayFps ?? 0).toString());
    }
    final needsExoPreOpen = willAutoSwitch && hasVideoUrl;
    plan.needsPostOpenSwitch = willAutoSwitch && !needsExoPreOpen;

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
  /// behind: run the ExoPlayer post-open fallback switch, or wait for the
  /// first rendered frame and negotiate the display from what the player
  /// presents, then resume via [resumeAfterStartupGate]. A gate that settles
  /// without a frame resumes only while [isCurrent] still holds — a failed,
  /// aborted, or superseded open has nothing to resume.
  Future<void> _releaseFrameRateStartupGate({
    required Player currentPlayer,
    required SettingsService settingsService,
    required _FrameRateStartupPlan plan,
    required bool Function() isCurrent,
    required Future<void> Function(String reason) resumeAfterStartupGate,
    Future<void>? watchTogetherStartupHold,
  }) async {
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
      await resumeAfterStartupGate('post-open frame rate switch');

      unawaited(
        Sentry.addBreadcrumb(
          Breadcrumb(message: 'Pre-playback frame rate: ${plan.fps}fps, switched=$didSwitch', category: 'player'),
        ),
      );
    } else if (plan.needsFirstFrameSwitch && mounted && player == currentPlayer) {
      try {
        await _negotiateDisplayAtFirstFrame(
          currentPlayer: currentPlayer,
          settingsService: settingsService,
          plan: plan,
          isCurrent: isCurrent,
          resumeAfterRefresh: resumeAfterStartupGate,
          watchTogetherStartupHold: watchTogetherStartupHold,
        );
      } finally {
        _frameRate.endDisplayNegotiation(plan.displayNegotiation);
      }
    }
  }

  /// The first-frame branch of [_releaseFrameRateStartupGate].
  Future<void> _negotiateDisplayAtFirstFrame({
    required Player currentPlayer,
    required SettingsService settingsService,
    required _FrameRateStartupPlan plan,
    required bool Function() isCurrent,
    required Future<void> Function(String reason) resumeAfterRefresh,
    required Future<void>? watchTogetherStartupHold,
  }) async {
    appLogger.d('Display matching: waiting for the first frame before negotiating the display');
    final startupReady = await plan._startupFrameReady;
    if (!isCurrent()) {
      appLogger.d('Display matching: startup gate released for a superseded or failed open; not resuming');
      return;
    }
    if (!startupReady) {
      appLogger.w('Display matching: startup frame timed out; resuming without negotiating the display');
      await resumeAfterRefresh('startup frame timeout');
      return;
    }

    // Hold the clock while the display is measured and the TV renegotiates
    // HDMI.
    Future<void> holdResumedClock() async {
      if (!currentPlayer.state.playing) return;
      try {
        await currentPlayer.pause();
      } catch (e) {
        appLogger.w('Failed to pause before display mode switch', error: e);
      }
    }

    // Everything below drives pause/play transitions the viewer did not ask
    // for (the measurement window, the hold around the switch); a bound
    // Watch Together room would broadcast them as intents and service remote
    // requests against the player mid-measurement.
    await _withWatchTogetherDetached(startupHold: watchTogetherStartupHold, () async {
      try {
        if (PlatformDetector.isAppleTV()) {
          // The decoded stream's criteria already went to AVDisplayManager
          // natively; only the mode switch it may have started is waited out.
          await currentPlayer.awaitDisplayModeSwitch(
            extraDelayMs: settingsService.read(SettingsService.displaySwitchDelay) * 1000,
          );
        } else {
          await holdResumedClock();
          final measurement = await _measurePresentedFormat(currentPlayer);
          if (!isCurrent()) return;
          final target = _displayTargetFor(settingsService, measurement.output);
          var switched = false;
          if (target != null) {
            switched = await _switchDisplayToTarget(
              currentPlayer: currentPlayer,
              settingsService: settingsService,
              target: target,
              reason: 'first-frame display switch',
              refreshPosition: measurement.windowStart,
            );
          }
          // The switch's decoder refresh seeks back to the window start; with
          // no switch, playback would otherwise begin the stepped frames in.
          if (!switched && measurement.windowStart != null && !widget.isLive && isCurrent()) {
            await _refreshAndroidMpvDecoderAfterFrameRateSwitch(
              reason: 'measurement window rewind',
              targetPosition: measurement.windowStart,
            );
          }
        }
      } catch (e) {
        appLogger.w('Failed to negotiate the display at the first frame', error: e);
      }
    });
    if (!isCurrent()) return;
    await resumeAfterRefresh('first-frame display negotiation');
  }

  /// What the player presents, measured rather than guessed. A decoder that
  /// deinterlaces by itself (MediaCodec on Tegra, MediaTek, Amlogic) emits
  /// one frame per field with no mpv filter to report it, and a paused first
  /// frame carries no cadence: Tegra has no output interval yet and
  /// MediaTek's first field pair shares a timestamp. So, still behind the
  /// loading UI, mpv steps ten frames with the audio gain at zero
  /// (`frame-step … mute`) and re-pauses. The presented rate is then read
  /// two ways: mpv's `estimated-vf-fps`, and the media time those ten frames
  /// advanced `time-pos` by — the decoder's own output timestamps, which on
  /// the video plane are honest long before mpv's average converges. Ten
  /// frames cost ~170 ms at field rate, ~420 ms at 24p; [windowStart] is
  /// where the window began, for the seek that follows.
  Future<({PlayerOutputFormat output, Duration? windowStart})> _measurePresentedFormat(Player currentPlayer) async {
    // The ExoPlayer plugin (and its mpv fallback core) exposes no chain
    // state and cannot step; take what its stats report.
    if (currentPlayer is PlayerAndroid) {
      return (output: await PlayerOutputFormat.read(currentPlayer), windowStart: null);
    }

    await _awaitDecodedFrame(currentPlayer);
    // A vehicle that forbids playback also forbids stepping frames.
    if (!automotivePlaybackAllowedNow()) {
      return (output: await PlayerOutputFormat.read(currentPlayer), windowStart: null);
    }
    final step = await _stepFramesForCadence(currentPlayer);
    final steppedFps = step == null
        ? null
        : PlayerOutputFormat.steppedRate(frames: _cadenceStepFrames, advanced: step.end - step.start);
    if (steppedFps != null) {
      appLogger.d(
        'Display matching: $_cadenceStepFrames stepped frames presented at ${steppedFps.toStringAsFixed(2)}fps',
      );
    }
    return (output: await PlayerOutputFormat.read(currentPlayer, steppedFps: steppedFps), windowStart: step?.start);
  }

  /// The open outcome's first-frame signal is mpv's playback-restart, which
  /// a video chain that failed to initialize also emits — audio playing,
  /// video at EOF — before the Android core moves the session to a GL vo and
  /// re-selects the track; that re-selection is not a restart, so no second
  /// event follows. Readiness is `video-dec-params`, which mpv fills only
  /// once *this* chain's decoder emitted a frame: `video-out-params` and
  /// `vo-configured` belong to the VO and survive a reload of the previous
  /// item, `width`/`height` fall back to the container's declared size, and
  /// `container-fps` is carried from the chain's creation. Polled, since
  /// nothing announces it; the cap covers a GL vo init plus a software
  /// decoder on a low-end box.
  Future<void> _awaitDecodedFrame(Player currentPlayer) async {
    const interval = Duration(milliseconds: 100);
    for (var waited = Duration.zero; waited < const Duration(seconds: 3); waited += interval) {
      final decodedWidth = int.tryParse(await currentPlayer.getProperty('video-dec-params/w') ?? '') ?? 0;
      if (decodedWidth > 0) {
        if (waited > Duration.zero) {
          appLogger.d('Display matching: decoded frame arrived after ${waited.inMilliseconds}ms');
        }
        return;
      }
      await Future<void>.delayed(interval);
    }
    appLogger.w('Display matching: no decoded frame within 3s; negotiating from what mpv reports');
  }

  static const _cadenceStepFrames = 10;

  /// See [_measurePresentedFormat]. Returns the video timestamps before and
  /// after a step that showed all its frames, or null when no such window
  /// could be had. A cache stall that begins inside the window cancels the
  /// step in mpv (an internal pause zeroes `step_frames`) and leaves
  /// playback free-running once the cache refills, so a stalled or
  /// overrunning window is paused explicitly, its frame count discarded,
  /// and — since a startup stall is what the viewer would wait through
  /// anyway — retried once after the refill.
  Future<({Duration start, Duration end})?> _stepFramesForCadence(Player currentPlayer) async {
    for (var attempt = 1; attempt <= 2; attempt++) {
      final window = await _runFrameStepWindow(currentPlayer);
      if (window.frames != null) return window.frames;
      if (!window.stalled) return null;
      appLogger.d('Display matching: measurement window $attempt stalled on the cache; waiting for the refill');
      if (!await _awaitCacheRefill(currentPlayer)) return null;
    }
    appLogger.w('Display matching: measurement window stalled twice; negotiating from the paused frame');
    return null;
  }

  Future<({({Duration start, Duration end})? frames, bool stalled})> _runFrameStepWindow(Player currentPlayer) async {
    Future<Duration?> videoTime() async {
      final seconds = double.tryParse(await currentPlayer.getProperty('time-pos') ?? '');
      return seconds == null ? null : Duration(microseconds: (seconds * Duration.microsecondsPerSecond).round());
    }

    var unpaused = false;
    final settled = Completer<bool>();
    void settle(bool completed) {
      if (!settled.isCompleted) settled.complete(completed);
    }

    final subscriptions = [
      currentPlayer.streams.playing.listen((playing) {
        if (playing) {
          unpaused = true;
        } else if (unpaused) {
          settle(true);
        }
      }),
      currentPlayer.streams.buffering.listen((buffering) {
        if (buffering) settle(false);
      }),
    ];
    var stalled = false;
    try {
      final start = await videoTime();
      if (start == null) return (frames: null, stalled: false);
      await currentPlayer.command(['frame-step', '$_cadenceStepFrames', 'mute']);
      var completed = await settled.future.timeout(const Duration(milliseconds: 1500), onTimeout: () => false);
      if (!completed) {
        // A fast step can flip pause false→true between two observer
        // deliveries, which mpv then coalesces into no event at all.
        completed = !currentPlayer.state.buffering && await currentPlayer.getProperty('pause') == 'yes';
      }
      if (!completed) {
        stalled = currentPlayer.state.buffering;
        if (!stalled) appLogger.w('Display matching: frame step did not re-pause within 1.5s');
        await currentPlayer.pause();
        return (frames: null, stalled: stalled);
      }
      final end = await videoTime();
      return (frames: (start: start, end: end ?? start), stalled: false);
    } catch (e) {
      appLogger.w('Display matching: frame step failed; negotiating from the paused frame', error: e);
      return (frames: null, stalled: false);
    } finally {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
      await _restoreAudioGainAfterFrameStep(currentPlayer);
    }
  }

  /// `frame-step … mute` zeroes the AO gain and restores it only when the
  /// step's last frame is written. A step cut short — by a cache stall, an
  /// explicit pause, or end of file inside the window — leaves the gain at
  /// zero for the rest of the item. mpv reapplies the gain on a mute
  /// change, so a round trip through `mute` restores it whatever the step
  /// did; a viewer's own mute is put back as it was.
  Future<void> _restoreAudioGainAfterFrameStep(Player currentPlayer) async {
    try {
      final mute = await currentPlayer.getProperty('mute') ?? 'no';
      await currentPlayer.setProperty('mute', 'yes');
      await currentPlayer.setProperty('mute', mute);
    } catch (e) {
      appLogger.w('Display matching: could not restore the audio gain after the frame step', error: e);
    }
  }

  /// Waits for `paused-for-cache` to clear; false when it does not within
  /// the cap or the player is gone.
  Future<bool> _awaitCacheRefill(Player currentPlayer) async {
    const interval = Duration(milliseconds: 200);
    for (var waited = Duration.zero; waited < const Duration(seconds: 10); waited += interval) {
      if (currentPlayer.disposed) return false;
      if (!currentPlayer.state.buffering) return true;
      await Future<void>.delayed(interval);
    }
    appLogger.w('Display matching: cache did not refill within 10s');
    return false;
  }

  /// Resume playback once a frame-rate startup gate releases. Shared by the
  /// start and reload flows.
  Future<void> _resumeAfterFrameRateStartupGate({required Player currentPlayer, required String reason}) async {
    if (!mounted || player != currentPlayer) return;
    appLogger.d('Frame rate matching: resuming playback after $reason');
    if (!automotivePlaybackAllowedNow()) {
      // The vehicle outranks the startup gate: releasing the frame-rate gate is not permission to
      // play.
      _playbackIntentShouldPlay = false;
      return;
    }
    _playbackIntentShouldPlay = true;
    await _playWithPlaybackIntent(currentPlayer);
  }

  /// Resolves the post-gate playback decision without inventing a play
  /// intent. A Watch Together owner also receives its readiness release.
  Future<void> _finishPlaybackAfterStartupGate({
    required Player currentPlayer,
    required String reason,
    required bool shouldResume,
    required bool watchTogetherOwnsStart,
    Completer<void>? wtStartupHold,
  }) async {
    if (shouldResume) {
      return _resumeAfterFrameRateStartupGate(currentPlayer: currentPlayer, reason: reason);
    }
    appLogger.d(
      watchTogetherOwnsStart
          ? 'Frame rate matching: yielding post-gate resume to Watch Together ($reason)'
          : 'Frame rate matching: preserving paused playback after $reason',
    );
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

  /// Build the per-item [TrackManager] for a freshly opened source. The
  /// start and reload flows construct it identically apart from where the
  /// preferred tracks and profile settings come from.
  TrackManager _buildTrackManager({
    required Player forPlayer,
    required MediaItem metadata,
    required MediaServerClient? mediaClient,
    required MediaServerUserProfile? Function() getProfileSettings,
    AudioTrack? preferredAudioTrack,
    SubtitlePreference? preferredSubtitleTrack,
    SubtitlePreference? preferredSecondarySubtitleTrack,
    bool primarySubtitleIsServerRendered = false,
    bool persistAutomaticSubtitleSelection = true,
  }) {
    return TrackManager(
      player: forPlayer,
      isActive: () => mounted && player == forPlayer,
      // Plex writes track changes immediately. MediaBrowser persists selected
      // indexes through playback progress reports and only needs the account
      // told to keep them.
      persistTrackPreference: mediaClient is PlexClient ? _plexTrackPersister(mediaClient) : null,
      enableTrackSelectionMemory: mediaClient is JellyfinClient
          ? _mediaBrowserTrackMemoryEnabler(mediaClient, context.read<AccountPreferencesController>())
          : null,
      getProfileSettings: getProfileSettings,
      waitForProfileSettings: _waitForProfileSettingsIfNeeded,
      metadata: metadata,
      mediaInfo: _currentMediaInfo,
      preferredAudioTrack: preferredAudioTrack,
      preferredSubtitleTrack: preferredSubtitleTrack,
      preferredSecondarySubtitleTrack: preferredSecondarySubtitleTrack,
      primarySubtitleIsServerRendered: primarySubtitleIsServerRendered,
      persistAutomaticSubtitleSelection: persistAutomaticSubtitleSelection,
      showMessage: (message, {duration}) {
        if (mounted) showAppSnackBar(context, message, duration: duration);
      },
      playbackRateOwnedExternally: _watchTogetherOwnsPlaybackRate,
    );
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
  /// bookkeeping at the exact ownership boundary. [outcome] is the attempt's
  /// armed open outcome: the sidecar guard reads its signals, and an open
  /// that throws aborts it so no waiter is left holding.
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
    required PlaybackOpenOutcome outcome,
    Map<String, String>? headers,
    required bool play,
    List<SubtitleTrack>? externalSubtitlesAtOpen,
    required bool Function() shouldContinue,
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
    if (!shouldContinue()) return const _MediaOpenResult(didOpen: false);

    final media = Media(videoUrl, start: timing.mediaStart, headers: headers);
    final sidecarOpenGuard = MpvSidecarOpenGuard.armIfNeeded(outcome: outcome, subtitles: externalSubtitlesAtOpen);
    // Both call sites check [shouldContinue] on the statement before, with no
    // await in between, so this closure does not re-check: a staleness signal
    // encoded as a throw would only skip the cleanup below.
    Future<void> openMedia({required bool shouldPlay, List<SubtitleTrack>? externalSubtitles}) {
      // Errors logged from here on belong to this file; a previous file's
      // last error must not be named by this open's failure view.
      _lastLogError = null;
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
      outcome.abort('open threw before the backend took the file');
      rethrow;
    }

    var sidecarFallbackUsed = false;
    final sidecarOutcome = await sidecarOpenGuard?.wait();
    if (sidecarOutcome == MpvSidecarOpenOutcome.aborted) {
      return const _MediaOpenResult(didOpen: true);
    }
    if (sidecarOutcome == MpvSidecarOpenOutcome.stalled) {
      appLogger.w('Selected subtitle sidecar stalled after primary media discovery; reopening without subtitles');
      if (!shouldContinue()) {
        return const _MediaOpenResult(didOpen: true);
      }
      await player.stop();
      onMediaAvailabilityChanged?.call(false);
      if (!shouldContinue()) return const _MediaOpenResult(didOpen: true);
      // Respect a pause requested while mpv was waiting on the sidecar. A
      // startup gate encoded by [play] remains authoritative when it is false.
      await openMedia(shouldPlay: play && _playbackIntentShouldPlay);
      onMediaAvailabilityChanged?.call(true);
      sidecarFallbackUsed = true;
      if (mounted && shouldContinue()) {
        showErrorSnackBar(context, t.videoControls.subtitleUnavailableFallback);
      }
    }

    if (!shouldContinue()) {
      return _MediaOpenResult(didOpen: true, sidecarFallbackUsed: sidecarFallbackUsed);
    }
    await _applyNativeSubtitleStyle(player, settingsService);
    return _MediaOpenResult(didOpen: true, sidecarFallbackUsed: sidecarFallbackUsed);
  }

  /// Shared orchestration for opening a resolved source on the live player:
  /// pre-open frame-rate negotiation → per-item frame-rate reset → GL
  /// color-transfer hint → startup-gate arming → external-subtitle planning →
  /// open → sidecar-fallback session recompute → track-manager build →
  /// post-open track application → frame-rate startup-gate release.
  ///
  /// The initial start flow ([_startPlayback]) and the in-place reload flow
  /// ([_reloadMediaInPlace]) both run this sequence; caller-specific
  /// choreography (session commit boundary, Watch Together attach/detach,
  /// progress-tracker teardown, per-screen service setup) stays in the
  /// callers and runs through the hooks below at its original position in
  /// the sequence. Deliberate per-flow differences are explicit parameters —
  /// nothing here may silently unify them.
  ///
  /// Returns false when a staleness guard or hook aborted the flow (the start
  /// flow returns silently, the reload flow maps it to superseded); open
  /// failures still throw to the caller. Everything the sequence produces is
  /// committed to screen state before it returns, so there is nothing else to
  /// hand back.
  Future<bool> _openResolvedMedia({
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
    // [_openMediaOnPlayer]'s shouldContinue. start: attempt.isCurrent +
    // Watch Together lease; reload: attempt.isCurrent + room lease.
    required bool Function() isCurrent,
    // The attempt's armed open outcome: every startup waiter below (frame-rate
    // startup gate, sidecar guard) derives from it, so a failed or aborted
    // open settles them all at once.
    required PlaybackOpenOutcome outcome,
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
    // start resolves it in [beforeColorHint] (after audio focus, its original
    // position) and exposes the value here.
    required Duration? Function() resumePosition,
    // Media client for TrackManager's server-side track persistence. reload
    // passes the resolver's reporting client; start reads the screen's media
    // client inside [beforeTrackSetup].
    required MediaServerClient? Function() mediaClient,
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
    // frame-rate reset and the GL color-transfer hint. Return false to abort.
    Future<bool> Function()? beforeColorHint,
    // reload-only: progress-tracker teardown and the captured track-mutation
    // drain between the GL color-transfer hint and startup-gate arming.
    // Return false to abort.
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
    if (frameRatePlan == null || (staleGuard != null && !staleGuard())) return false;

    final wtOwnsStart = watchTogetherOwnsStart();
    final shouldAutoStart = resolveShouldAutoStart(wtOwnsStart);
    var openSession = session;
    var openSubtitleSelection = subtitleSelection;

    // Open video through Player
    if (result.videoUrl != null) {
      // Reset first frame flag and frame rate retry counter for new video
      if (clearFirstFrameForOpen) _firstFrame.resetUiForOpen();
      _frameRate.resetForNewItem();
      if (frameRatePlan.countsAsApplied) {
        _frameRate.applied = true;
      }

      if (beforeColorHint != null && !await beforeColorHint()) return false;

      await _announceContentColorTransfer(
        player: currentPlayer,
        displayCriteria: displayCriteria,
        isTranscoding: result.isTranscoding,
      );

      if (beforeArm != null && !await beforeArm()) return false;

      frameRatePlan.armFirstFrameGate(outcome, _frameRate);
      final shouldAutoPlay = shouldAutoStart && !frameRatePlan.holdPlaybackStart;

      // Sidecars ride along with open() so tracks are discovered in a single
      // prepare/loadfile cycle.
      final openTiming = _playbackOpenTiming(
        isTranscoding: result.isTranscoding,
        resumePosition: resumePosition(),
        durationMs: metadata.durationMs,
      );
      if (!isCurrent()) return false;
      final openResult = await _openMediaOnPlayer(
        player: currentPlayer,
        settingsService: settingsService,
        videoUrl: result.videoUrl!,
        isTranscoding: result.isTranscoding,
        isLocalMedia: isLocalMedia,
        selectedVersion: result.selectedVersion,
        timing: openTiming,
        outcome: outcome,
        headers: headers,
        play: deferAutomotiveStart ? shouldAutoPlay && !PlatformDetector.isAutomotive() : shouldAutoPlay,
        externalSubtitlesAtOpen: openSubtitleSelection.sidecarsAtOpen,
        shouldContinue: isCurrent,
        onOpening: onOpening,
        onOpened: onOpened,
        onMediaAvailabilityChanged: onMediaAvailabilityChanged,
      );
      // A false didOpen means shouldContinue stopped the sequence pre-open;
      // open failures throw to the caller instead.
      if (!openResult.didOpen || !isCurrent()) return false;
      if (openResult.sidecarFallbackUsed) {
        openSession = _commitSidecarFallbackSession(openSession);
        openSubtitleSelection = openSession.subtitleSelection;
      }

      if (!await afterMediaOpened(shouldAutoPlay, frameRatePlan.holdPlaybackStart, wtOwnsStart)) return false;
    }

    if (beforeTrackSetup != null && !await beforeTrackSetup()) return false;

    // Track manager: owns track selection and Plex immediate stream writes.
    // Jellyfin persists selected stream indexes through playback progress
    // reports instead.
    final trackManager = _buildTrackManager(
      forPlayer: currentPlayer,
      metadata: metadata,
      mediaClient: mediaClient(),
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
      // A declined carry is still the viewer's choice: a late native pass may
      // yet serve it, and that pick belongs on the server (#2323).
      persistAutomaticSubtitleSelection:
          openSubtitleSelection.primaryHonorsPreference || openSubtitleSelection.declinedPreference != null,
    );
    _trackManager = trackManager;

    trackManager.applyTrackSelectionWhenReady();
    if (staleGuard != null && !staleGuard()) return false;

    await _releaseFrameRateStartupGate(
      currentPlayer: currentPlayer,
      settingsService: settingsService,
      plan: frameRatePlan,
      isCurrent: isCurrent,
      // Paused opens use the same no-resume branch as an externally
      // coordinated start: no new play intent is manufactured, and a Watch
      // Together owner also gets its readiness hold released.
      resumeAfterStartupGate: (reason) => _finishPlaybackAfterStartupGate(
        currentPlayer: currentPlayer,
        reason: reason,
        shouldResume: shouldAutoStart,
        watchTogetherOwnsStart: wtOwnsStart,
        wtStartupHold: wtStartupHold?.call(),
      ),
      watchTogetherStartupHold: wtStartupHold?.call()?.future,
    );

    return true;
  }
}
