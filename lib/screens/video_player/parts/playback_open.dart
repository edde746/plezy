part of '../../video_player_screen.dart';

/// Outcome of the Android pre-open frame-rate negotiation for the initial
/// start flow: which pre-switch ran, whether playback must open paused
/// behind a startup gate, and which post-open follow-up (fallback switch
/// or mpv decoder refresh) releases it.
class _FrameRateStartupPlan {
  _FrameRateStartupPlan({required this.fps});

  final double? fps;
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
  /// while a planned follow-up is still pending.
  bool get countsAsApplied => didPreLoadSwitch || attemptedMpvPreLoad || preOpenExoHandled;

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

/// Shared building blocks for opening media on the live player.
///
/// The initial start flow ([_startPlayback]), the in-place reload flow
/// ([_reloadMediaInPlace]), and the transcode-restart seek
/// ([_restartPlexTranscodeAt]) all route through these helpers so per-open
/// behavior (display priming, frame-rate suppression windows, native
/// subtitle styling, the open sequence itself) cannot drift between paths.
/// This is also the only place that reads
/// [SettingsService.displaySwitchDelay].
extension _VideoPlayerOpenMethods on VideoPlayerScreenState {
  /// Prime native display matching (tvOS HDMI mode) from server metadata
  /// before the decoder emits stream properties. The native side resolves
  /// only after any resulting display-mode switch has settled, plus the
  /// user-configured extra delay on Apple TV.
  Future<void> _primeDisplayCriteria({
    required Player player,
    required SettingsService settingsService,
    required MediaDisplayCriteria? displayCriteria,
    required bool isTranscoding,
  }) {
    return player.setDisplayCriteria(
      !isTranscoding && displayCriteria?.canPrimeNativeDisplayCriteria == true ? displayCriteria : null,
      extraDelayMs: PlatformDetector.isAppleTV() ? settingsService.read(SettingsService.displaySwitchDelay) * 1000 : 0,
    );
  }

  /// Ask the platform to renegotiate the display refresh rate for [fps],
  /// arming the MediaSession pause-suppression window first. The native call
  /// returns only after the real display-change event (+ settle + the
  /// user-configured delay). Returns whether a switch was initiated.
  Future<bool> _switchDisplayFrameRateForOpen({
    required Player player,
    required SettingsService settingsService,
    required double fps,
    required int durationMs,
  }) {
    final delaySec = settingsService.read(SettingsService.displaySwitchDelay);
    _frameRate.beginSuppressWindow(delaySec);
    return player.setVideoFrameRate(fps, durationMs, extraDelayMs: delaySec * 1000);
  }

  /// Whether the Android pre-open frame-rate negotiation applies: the user
  /// opted into per-content refresh-rate matching and metadata already told
  /// us the target fps. Shared by the start and reload flows so the
  /// eligibility rule cannot drift between them.
  bool _shouldAutoSwitchFrameRateForOpen(SettingsService settingsService, double? fps) {
    return Platform.isAndroid && settingsService.read(SettingsService.matchContentFrameRate) && fps != null && fps > 0;
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
    required Future<void> Function() ensureAudioFocus,
  }) async {
    final plan = _FrameRateStartupPlan(fps: preKnownFps);
    final willAutoSwitch = _shouldAutoSwitchFrameRateForOpen(settingsService, preKnownFps);
    // willAutoSwitch is Android-only, so the strategy fork below is between
    // the two Android backends: mpv needs its decoder refreshed after a
    // display switch (pre-load path), ExoPlayer switches pre-open instead.
    final isAndroidMpv = currentPlayer.needsDecoderRefreshAfterDisplaySwitch;
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
        appLogger.d('Frame rate matching: pre-load MPV switch to ${preKnownFps}fps (duration: ${durationMs}ms)');
        plan.didPreLoadSwitch = await _switchDisplayFrameRateForOpen(
          player: currentPlayer,
          settingsService: settingsService,
          fps: preKnownFps!,
          durationMs: durationMs,
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
        appLogger.d('Frame rate matching: pre-open ExoPlayer switch to ${preKnownFps}fps (duration: ${durationMs}ms)');
        final didSwitch = await _switchDisplayFrameRateForOpen(
          player: currentPlayer,
          settingsService: settingsService,
          fps: preKnownFps!,
          durationMs: durationMs,
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
          fps: plan.fps!,
          durationMs: durationMs,
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
    } else if (plan.needsStartupRefresh && mounted && player == currentPlayer) {
      appLogger.d('Frame rate matching: waiting for Android MPV startup frame before decoder refresh');
      final startupFrameReady = plan._startupFrameReady;
      final startupReady = startupFrameReady == null ? false : await startupFrameReady;
      if (mounted && player == currentPlayer) {
        if (startupReady) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await _refreshAndroidMpvDecoderAfterFrameRateSwitch(reason: 'pre-load frame rate startup');
          await resumeAfterStartupGate('startup decoder refresh');
        } else {
          appLogger.w('Frame rate matching: skipping Android MPV decoder refresh because startup frame timed out');
          await resumeAfterStartupGate('startup frame timeout');
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
    if (externalSubtitlePlan.requiresPostOpenAdd) {
      await trackManager.resumeAfterSubtitleLoad();
    } else {
      await currentPlayer.play();
    }
  }

  /// Gate-release resume that yields to Watch Together when a session owns
  /// the playback start: track selection is still armed, but instead of
  /// playing, the sync readiness hold (if any) is released — the
  /// coordinated group start unpauses later. Shared by the start and reload
  /// flows.
  Future<void> _resumeAfterStartupGateOrYieldToWatchTogether({
    required Player currentPlayer,
    required _ExternalSubtitleOpenPlan externalSubtitlePlan,
    required String reason,
    required bool wtOwnsStart,
    Completer<void>? wtStartupHold,
  }) async {
    if (!wtOwnsStart) {
      return _resumeAfterFrameRateStartupGate(
        currentPlayer: currentPlayer,
        externalSubtitlePlan: externalSubtitlePlan,
        reason: reason,
      );
    }
    appLogger.d('Frame rate matching: yielding post-gate resume to Watch Together ($reason)');
    final trackManager = _trackManager;
    if (trackManager != null && externalSubtitlePlan.requiresPostOpenAdd) {
      trackManager.waitingForExternalSubsTrackSelection = false;
      trackManager.applyTrackSelectionWhenReady();
    }
    if (wtStartupHold != null && !wtStartupHold.isCompleted) {
      wtStartupHold.complete();
    }
  }

  /// Push the user's subtitle style to the native rendering layer (no-op on
  /// mpv backends, which style via `sub-*` properties). Must run after
  /// open() since that's when ExoPlayer initializes its subtitle views.
  Future<void> _applyNativeSubtitleStyle(Player player, SettingsService settingsService) {
    return player.setSubtitleStyle(
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
    SubtitleTrack? preferredSubtitleTrack,
    SubtitleTrack? preferredSecondarySubtitleTrack,
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
      showMessage: (message, {duration}) {
        if (mounted) showAppSnackBar(context, message, duration: duration);
      },
    );
  }

  /// Apply track selection for a freshly opened source: mpv backends get
  /// external subtitles via the post-open sub-add dance (opened paused to
  /// avoid the issue #226 race), others arm selection directly.
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
        if (shouldResumeAfterSubtitleLoad()) {
          await trackManager.resumeAfterSubtitleLoad();
        } else if (applySelectionWhenResumeSkipped) {
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
  /// [networkStreamRingBytes]). Both properties are always written, set or
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
      await player.setProperty(
        'stream-lavf-o',
        'reconnect=1,reconnect_on_network_error=1,reconnect_streamed=1,reconnect_delay_max=600',
      );
    } else {
      await player.setProperty('stream-lavf-o', '');
    }

    int? ringBytes;
    if (isNetworkVod && !isTranscoding) {
      // Transcode (HLS) playback only uses the mpv stream layer for the
      // playlist file; segment fetches happen inside ffmpeg's hls demuxer.
      final maxBytes = Platform.isAndroid
          ? androidStreamRingCapBytes(await PlayerAndroid.getHeapSize())
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

  /// Open [videoUrl] on [player]: stream tuning + force-seekable hint →
  /// open → native subtitle style.
  ///
  /// [shouldContinue] is re-checked between the awaits so stale generations
  /// stop without touching the player further. [onOpened] fires immediately
  /// after open() returns (before styling) so callers can flip rollback
  /// bookkeeping at the exact ownership boundary.
  ///
  /// Returns false if [shouldContinue] stopped the sequence before open;
  /// true once open() has been issued (even if styling was skipped).
  Future<bool> _openMediaOnPlayer({
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
    void Function()? onOpened,
  }) async {
    await _applyNetworkStreamTuning(
      player: player,
      isNetworkVod: !isLocalMedia && !widget.isLive,
      isTranscoding: isTranscoding,
      selectedVersion: selectedVersion,
    );
    // Transcode streams can be seekable even when MPV cannot prove it
    // from response headers. Reset non-transcodes so live/direct/offline
    // streams keep native seekability detection.
    await player.setProperty('force-seekable', isTranscoding ? 'yes' : 'no');
    if (shouldContinue != null && !shouldContinue()) return false;
    await player.open(
      Media(videoUrl, start: timing.mediaStart, headers: headers),
      play: play,
      externalSubtitles: externalSubtitlesAtOpen,
      timelineOffset: timing.timelineOffset,
      timelineDuration: timing.timelineDuration,
    );
    onOpened?.call();
    if (shouldContinue != null && !shouldContinue()) return true;
    await _applyNativeSubtitleStyle(player, settingsService);
    return true;
  }
}
