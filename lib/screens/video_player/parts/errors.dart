part of '../../video_player_screen.dart';

extension _VideoPlayerErrorMethods on VideoPlayerScreenState {
  String _safePlaybackErrorMessage(Object error) {
    // The native core failed to start; the sentinel carries no prose because
    // the UI owns the wording — show the localized copy directly.
    if (error is PlayerInitializationException) {
      return t.messages.playbackFailed;
    }
    final raw = error.toString();
    final redacted = LogRedactionManager.redact(raw);
    if (raw.contains('No client registered')) {
      return t.messages.errorLoading(error: t.messages.serverUnavailableForProfile);
    }
    return t.messages.errorLoading(error: redacted);
  }

  void _onPlayerError(PlayerError err) {
    appLogger.e('[Player ERROR] ${err.message}');
    if (!mounted || _isExiting.value) return;
    // The open already failed and its verdict is on screen: every further
    // error is the same dead load (a playlist walk, a retrying reconnect)
    // reporting again, and re-running the policy per event is what turned a
    // failed HLS open into an ANR. A new open resets the latch.
    if (_hasFatalPlaybackError) return;

    // A sidecar subtitle fetch can also log a status, but it never raises the
    // end-file error this handler is wired to, so a latched status belongs to
    // the primary media open.
    final action = resolvePlaybackFailureAction(
      cause: err.cause,
      fatalHttpStatuses: _fatalHttpStatuses,
      isLive: widget.isLive,
      liveRetrying: _live.retrying,
      liveFallbackLevel: _live.fallbackLevel,
      liveRetryFailed: _live.retryFailed,
    );

    switch (action) {
      // Every dialog is unrecoverable until the server side changes, so each
      // replaces the snackbar rather than joining it.
      case PlaybackFailureAction.playbackNotAllowedDialog:
        _latchFatalPlaybackError(action);
        unawaited(_showPlaybackNotAllowedDialog());
      case PlaybackFailureAction.serverLimitDialog:
        _latchFatalPlaybackError(action);
        unawaited(_showServerLimitDialog());
      case PlaybackFailureAction.mediaUnreadableDialog:
        _latchFatalPlaybackError(action);
        unawaited(_showMediaUnreadableDialog());
      case PlaybackFailureAction.serverBusyDialog:
        _latchFatalPlaybackError(action);
        unawaited(_showServerBusyDialog());
      // The bounded retry operation owns errors raised while applying/opening
      // its replacement stream. Do not let the same error close the route.
      case PlaybackFailureAction.ignore:
        return;
      case PlaybackFailureAction.liveRetry:
        _beginLiveLadderRetry();
      case PlaybackFailureAction.liveInterrupted:
        showGlobalErrorSnackBar(t.messages.liveStreamInterrupted);
      case PlaybackFailureAction.fatal:
        _latchFatalPlaybackError(action, cause: err.cause);
        // A failed core start carries only diagnostic text; _lastLogError is
        // raw mpv/ffmpeg output, so neither is fit to show bare — use the
        // localized copy, with the redacted diagnostic as its detail. A timed
        // out open raised nothing itself, but the last error line mpv logged
        // on the way to the stall (a chain that failed, a stream that never
        // produced) is the only diagnosis there is, so it rides along too.
        final lastLogError = _lastLogError;
        final message = switch (err.cause) {
          PlayerError.playerInitFailed => t.messages.playbackFailed,
          PlayerError.openTimedOut =>
            lastLogError == null ? t.messages.playbackFailed : t.messages.playbackFailedDetail(error: lastLogError),
          PlayerError.audioOutputFailed => t.messages.audioOutputFailed,
          _ => t.messages.playbackFailedDetail(error: _redactPlayerError(lastLogError ?? err.message)),
        };
        // Live TV has no in-place reload to retry through: its own start
        // flow leaves the route on failure, so a dead live session does too.
        if (widget.isLive) {
          showGlobalErrorSnackBar(message);
          unawaited(_handleBackButton());
          return;
        }
        _presentPlaybackFailure(message);
    }
  }

  /// A terminal player error: the attempt is no longer current, progress
  /// reporting stops, every waiter armed for its open collapses, and the
  /// backend is told to stop — the error UI is the only thing left running
  /// for it. The stop is not optional: on a failed HLS open mpv falls back to
  /// its playlist parser and walks the manifest's entries, each failing in
  /// turn (46 end-file errors in 4 s on a Fire TV), and with the route no
  /// longer popping nothing else halts that walk; a stalled load is likewise
  /// still retrying and a late success must not play behind the failure
  /// view. Further errors from the same dead open are ignored by
  /// [_onPlayerError] until a new open resets the latch. The launch receipt
  /// goes terminal here, not on exit: the route may never close (an
  /// agent-launched player has nothing to pop to), and a caller polling the
  /// receipt must not read a failed open as `opening` or, after Back, as a
  /// user stop.
  void _latchFatalPlaybackError(PlaybackFailureAction action, {String? cause}) {
    _hasFatalPlaybackError = true;
    // Every dialog is a server verdict and a device fault repeats, so only a
    // plain open failure may be retried (see [_tryOpenAutoRetry]).
    _latchedFailureAllowsRetry = action == PlaybackFailureAction.fatal && causeAllowsOpenAutoRetry(cause);
    _progressTracker?.stopTracking();
    _abortCurrentOpen('player error: ${action.name}');
    final currentPlayer = player;
    if (currentPlayer != null) {
      unawaited(
        currentPlayer.stop().catchError((Object e, StackTrace st) {
          appLogger.w('Failed to stop the failed load', error: e, stackTrace: st);
        }),
      );
    }
    if (_ownsLaunchPlayback() && widget.launchObserver?.failure == null) {
      widget.launchObserver?.mark(
        'failed',
        failure: switch (action) {
          PlaybackFailureAction.playbackNotAllowedDialog => 'playbackNotAllowed',
          PlaybackFailureAction.serverLimitDialog => 'serverLimit',
          PlaybackFailureAction.mediaUnreadableDialog => 'mediaUnreadable',
          PlaybackFailureAction.serverBusyDialog => 'serverBusy',
          _ => cause == PlayerError.audioOutputFailed ? 'audioOutputFailed' : 'playbackFailed',
        },
      );
    }
  }

  /// Raise the persistent failure surface over the player. It stays until
  /// Retry re-runs the open or Back leaves; a snackbar is neither focusable
  /// nor on a remote's path, and it is gone in seconds. The spinner is
  /// forced down so it cannot sit over the view, and Retry takes focus once
  /// the view has built (see [_initializationErrorFocusNode]). The backend's
  /// end-file verdict always lands; a thrown open only fills an empty view,
  /// since the verdict that preceded it is the more specific of the two.
  ///
  /// An open that never showed a frame is first re-run up to
  /// [maxOpenAutoRetries] times (see [_tryOpenAutoRetry]); the view only goes
  /// up once those are spent.
  void _presentPlaybackFailure(String message) {
    if (!mounted || _shuttingDown) return;
    if (_tryOpenAutoRetry(message)) return;
    _firstFrame.forceUiReadyOnFailure();
    // Nothing plays behind the view, so it must not hold the screen awake
    // while it waits; the playing-state handler takes the wakelock again once
    // a retried open plays.
    unawaited(_wakelockController.setEnabled(false));
    _setPlayerState(() {
      _playbackFailureMessage = message;
      _playbackFailureRetry = _retryFailedPlayback;
      // Retries spent on this open, so the view can say it was tried more
      // than once.
      _playbackFailureAttempts = _openAutoRetries + 1;
    });
    _focusFailureActionAfterBuild();
  }

  void _dismissPlaybackFailure() {
    if (_playbackFailureMessage == null) return;
    _setPlayerState(() {
      _playbackFailureMessage = null;
      _playbackFailureRetry = null;
      _playbackFailureAttempts = 1;
      _switchVersionChecking = false;
      _switchVersionUnreachable = false;
    });
  }

  /// The button only exists after the next frame builds, so the request waits
  /// for it; see [_initializationErrorFocusNode] for why autofocus alone
  /// leaves the view with nothing focused.
  void _focusFailureActionAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _shuttingDown || (_playerInitializationError == null && _playbackFailureMessage == null)) {
        return;
      }
      if (_initializationErrorFocusNode.canRequestFocus) _initializationErrorFocusNode.requestFocus();
    });
  }

  /// The open Retry re-runs for the failure on screen. A failed in-place
  /// source switch restores the request that was playing before it — one
  /// attempt, prompted; a restore that fails too leaves the failure view up.
  /// Anything else re-runs the failed open itself, from the playhead when
  /// that open had already rendered.
  _PlaybackOpenRequest? _retryRequestForFailure() {
    final current = _currentOpenRequest;
    if (current == null) return null;
    final working = _workingOpenRequest;
    if (working != null && working.metadata.globalKey == current.metadata.globalKey && !working.sameSourceAs(current)) {
      return working.resumingAt(current.resumePosition ?? working.resumePosition);
    }
    if (_firstFrame.rendered) return current.resumingAt(player?.state.position);
    return current;
  }

  void _retryFailedPlayback() {
    // A deliberate retry gets a fresh set of automatic retries.
    _openAutoRetries = 0;
    final request = _retryRequestForFailure();
    if (request == null || player == null) {
      // Nothing was ever dispatched (or the core is gone): start over.
      _retryPlayerInitialization();
      return;
    }
    unawaited(_reopenAfterFailure(request));
  }

  Future<void> _reopenAfterFailure(_PlaybackOpenRequest request) async {
    final outcome = await _reloadMediaInPlace(
      metadata: request.metadata,
      selectedMediaIndex: request.mediaIndex,
      selectedMediaSourceId: request.mediaSourceId,
      qualityPreset: request.qualityPreset,
      selectedAudioStreamId: request.audioStreamId,
      useCurrentAudioStreamSelection: false,
      resumePosition: request.resumePosition,
      preferredSubtitleTrackOverride: SubtitlePreference.trackOrNull(_playbackSession?.subtitleSelection.primaryTrack),
      // A failure before the open rolls the view back to the message it
      // retried from; one after it raises its own through _onPlayerError.
      showErrorUi: false,
      reason: 'retry after playback failure',
    );
    if (outcome == MediaReloadOutcome.failed && mounted && _playbackFailureMessage == null) {
      _presentPlaybackFailure(t.messages.playbackFailed);
    }
  }

  /// The open on screen failed before its first frame. A slow backing store
  /// (a cloud-mounted library whose first read of an uncached file stalls or
  /// times out) often opens on a second try, so re-run the same request in
  /// place, with a toast, before the failure view goes up. Same version, same
  /// position, and the viewer's track picks. Bounded per source: a first frame,
  /// a user Retry or another source starts a fresh count. Returns false when
  /// the failure should be shown instead.
  bool _tryOpenAutoRetry(String message) {
    if (widget.isLive || _isOfflinePlayback || _firstFrame.rendered || player == null) return false;
    // The open ended on a verdict a retry would only meet again.
    if (_hasFatalPlaybackError && !_latchedFailureAllowsRetry) return false;
    final request = _currentOpenRequest;
    if (request == null) return false;
    // A switch away from a stream that was playing (another version, quality
    // or audio track) goes straight to the view: Retry there restores the
    // stream that worked, rather than holding the viewer on the new pick.
    final working = _workingOpenRequest;
    if (working != null && working.metadata.globalKey == request.metadata.globalKey && !working.sameSourceAs(request)) {
      return false;
    }
    final retried = _openAutoRetrySource;
    if (retried == null || !retried.sameSourceAs(request)) {
      _openAutoRetrySource = request;
      _openAutoRetries = 0;
    }
    if (_openAutoRetries >= maxOpenAutoRetries) return false;
    final attempt = ++_openAutoRetries;
    // The open is not over yet: an agent polling the launch receipt must not
    // read the failure this retry may still recover from.
    _openAutoRetryPending = true;
    final observer = widget.launchObserver;
    if (observer != null && observer.isTerminal && _ownsLaunchPlayback()) observer.mark('opening');
    appLogger.w('Playback open failed ($message); automatic retry $attempt of $maxOpenAutoRetries');
    unawaited(_runOpenAutoRetry(request, message, attempt));
    return true;
  }

  Future<void> _runOpenAutoRetry(_PlaybackOpenRequest request, String message, int attempt) async {
    // Let the failed open finish unwinding first: a start that is still
    // setting up (filters, PiP, shaders) would see the retry's new generation
    // and skip that setup, and a reload still holding the transition gate
    // would reject the retry.
    try {
      await _startPlaybackRun;
    } catch (_) {}
    await _transitionGate.waitForIdle(() => mounted && !_shuttingDown);
    _openAutoRetryPending = false;
    // Back, another item or a version pick took over meanwhile.
    if (!mounted || _shuttingDown || !identical(_currentOpenRequest, request)) return;
    _toastController.show(
      Symbols.refresh_rounded,
      t.videoControls.openRetrying(attempt: attempt, max: maxOpenAutoRetries),
      duration: const Duration(seconds: 3),
    );
    final outcome = await _reopenWithViewerTracks(request, reason: 'automatic retry $attempt after open failure');
    if (!mounted || _playbackFailureMessage != null) return;
    switch (outcome) {
      case MediaReloadOutcome.failed:
        _presentPlaybackFailure(message);
      case MediaReloadOutcome.rejected:
        // Nothing replaced the failed open, so it still needs its verdict.
        if (identical(_currentOpenRequest, request)) _presentPlaybackFailure(message);
      case MediaReloadOutcome.opened:
      case MediaReloadOutcome.superseded:
        // An open that fails after dispatch reports through _onPlayerError.
        return;
    }
  }

  /// Re-open [request] in place, on its own source unless [mediaIndex] picks
  /// another, keeping the viewer's explicit track picks: this screen's choices
  /// first, then the launch's. Stream ids are per version, so [request]'s
  /// audio id only rides along on its own source.
  Future<MediaReloadOutcome> _reopenWithViewerTracks(
    _PlaybackOpenRequest request, {
    int? mediaIndex,
    String? mediaSourceId,
    required String reason,
  }) {
    final sameSource = mediaIndex == null;
    return _reloadMediaInPlace(
      metadata: request.metadata,
      selectedMediaIndex: sameSource ? request.mediaIndex : mediaIndex,
      selectedMediaSourceId: sameSource ? request.mediaSourceId : mediaSourceId,
      qualityPreset: request.qualityPreset,
      selectedAudioStreamId: sameSource ? request.audioStreamId : null,
      useCurrentAudioStreamSelection: false,
      resumePosition: request.resumePosition,
      preserveCurrentTrackSelection: true,
      preservedAudioTrack: _sessionAudioPreference ?? _preferredAudioTrack,
      preservedSubtitleTrack: _sessionSubtitlePreference ?? _preferredSubtitleTrack,
      preservedSecondarySubtitleTrack: _sessionSecondarySubtitlePreference ?? _preferredSecondarySubtitleTrack,
      showErrorUi: false,
      reason: reason,
    );
  }

  /// Whether the failure view offers another version: an on-demand item with
  /// more than one, outside a launch that asked for exactly one. Every
  /// version is on the same server, so none is offered while that server is
  /// known to be unreachable.
  bool get _canSwitchVersionAfterFailure =>
      !widget.isLive &&
      !_isOfflinePlayback &&
      !widget.strictMediaSelection &&
      !_switchVersionUnreachable &&
      _currentOpenRequest != null &&
      _availableVersions.length > 1 &&
      _isServerKnownOnline(_currentMetadata.serverId);

  bool _isServerKnownOnline(String? serverId) {
    if (serverId == null) return false;
    try {
      return context.read<MultiServerProvider>().serverManager.isServerOnline(ServerId(serverId));
    } catch (_) {
      // No server registry in this context: let the reachability check decide.
      return true;
    }
  }

  /// The failure view's Switch Version: pick another version of the item and
  /// open it from where the failed open would have started. A deliberate pick,
  /// so it is saved like one made in the player's version picker.
  ///
  /// The server's health status can lag, so the server is asked for the item
  /// first: when it does not answer, the button goes away instead of offering
  /// versions that cannot open either.
  Future<void> _switchVersionAfterFailure() async {
    final request = _currentOpenRequest;
    final versions = _availableVersions;
    if (request == null || versions.length < 2 || _switchVersionChecking) return;
    _setPlayerState(() => _switchVersionChecking = true);
    final reachable = await _isServerReachableFor(request.metadata);
    if (!mounted || _shuttingDown || !identical(_currentOpenRequest, request)) return;
    _setPlayerState(() {
      _switchVersionChecking = false;
      _switchVersionUnreachable = !reachable;
    });
    if (!reachable) {
      showErrorSnackBar(context, t.videoControls.switchVersionUnreachable);
      _focusFailureActionAfterBuild();
      return;
    }
    final current = _effectiveSelectedMediaIndex;
    final index = await showOptionPickerDialog<int>(
      context,
      title: t.videoControls.switchVersion,
      options: [
        for (var i = 0; i < versions.length; i++)
          (
            icon: i == current ? Symbols.error_rounded : Symbols.video_file_rounded,
            label: versions[i].displayLabel,
            value: i,
          ),
      ],
    );
    if (index == null || !mounted || _shuttingDown || !identical(_currentOpenRequest, request)) return;
    await saveMediaVersionPreferenceFor(request.metadata, index: index, versions: versions);
    if (!mounted || _shuttingDown || !identical(_currentOpenRequest, request)) return;
    _openAutoRetries = 0;
    final outcome = await _reopenWithViewerTracks(
      request,
      mediaIndex: index,
      mediaSourceId: PlaybackSession.mediaSourceIdForIndex(versions, index),
      reason: 'version switch after playback failure',
    );
    if (outcome == MediaReloadOutcome.failed && mounted && _playbackFailureMessage == null) {
      _presentPlaybackFailure(t.messages.playbackFailed);
    }
  }

  /// Whether [metadata]'s server answers a request for it now.
  Future<bool> _isServerReachableFor(MediaItem metadata) async {
    final client = context.tryGetMediaClientForServer(serverIdOrNull(metadata.serverId));
    if (client == null) return false;
    try {
      await client.fetchItem(metadata.id).timeout(VideoPlayerScreenState._switchVersionReachabilityTimeout);
      return true;
    } catch (e) {
      appLogger.w('Server did not answer before switching versions', error: e);
      return false;
    }
  }

  void _onPlayerLog(PlayerLog log) {
    final status = PlayerError.httpStatusFromLog(log.text);
    if (status != null && fatalPlaybackHttpStatuses.contains(status)) _fatalHttpStatuses.add(status);
    // An open the server answers with 503 never fails on its own: ffmpeg's
    // reconnect loop retries 503 forever and mpv just reports buffering
    // (#1830). Bound it. Live TV stays out — its ladder owns retries there.
    // A sidecar subtitle fetch shares this log stream and could arm the
    // watchdog too, but a first frame disarms it, so that only matters when
    // the primary media is itself stuck.
    if (status == 503 && !widget.isLive && !_firstFrame.rendered && !_hasFatalPlaybackError) {
      _http503Watchdog.onOpenPhase503();
    }
    if (log.level == PlayerLogLevel.error || log.level == PlayerLogLevel.fatal) {
      appLogger.e('[Player LOG ERROR] [${log.prefix}] ${log.text}');
      _lastLogError = _redactPlayerError(log.text.trim());
    }
    if (SpuriousEofRecovery.isTransportFaultLog(log)) _transportFaultSeen = true;
    // A stream mpv gives up on at open (`error_on_track`) ends the file only
    // when the other stream is gone too; otherwise the load lives on with no
    // end-file and the viewer waits out the open deadline for an error mpv
    // logged seconds earlier. Fail the open on that line instead. Same guard
    // as the deadline: a first frame or a latched error already settled this
    // open, and a superseded attempt's lines are not this open's business.
    if (_firstFrame.rendered || _hasFatalPlaybackError || !(_playbackAttempt?.isCurrent ?? false)) return;
    final cause = openFailureCauseFromLog(
      level: log.level,
      prefix: log.prefix,
      text: log.text,
      isAndroid: Platform.isAndroid,
    );
    if (cause == null) return;
    appLogger.w('mpv gave up on a stream while opening — giving up on this open');
    _onPlayerError(PlayerError(log.text.trim(), cause: cause));
  }

  /// The open-phase 503 watchdog's deadline passed with no first frame: the
  /// server is still refusing the stream. Synthesize the error the reconnect
  /// loop will never raise on its own so the normal failure policy runs.
  void _onOpenHttp503Persistent() {
    if (!mounted || _isExiting.value || _firstFrame.rendered || _hasFatalPlaybackError) return;
    appLogger.w(
      'Server kept answering the stream with HTTP 503 for '
      '${openHttp503Patience.inSeconds}s without a first frame — giving up on this open',
    );
    _onPlayerError(PlayerError(t.messages.serverBusyTitle, cause: PlayerError.serverHttp503));
  }

  /// The attempt's open deadline passed: the backend started the load and
  /// then neither loaded, failed, nor died. Its waiters are already aborted;
  /// synthesize the error the backend never raised so the failure policy
  /// runs (which stops the still-retrying load) and the viewer is not left
  /// on a spinner. Same guard as the 503 watchdog: a first frame or a
  /// latched error already settled this open.
  void _onOpenDeadlineExpired(Player currentPlayer, int generation) {
    if (!_isCurrentPlaybackGeneration(generation, currentPlayer) || _firstFrame.rendered || _hasFatalPlaybackError) {
      return;
    }
    appLogger.w(
      'No first frame within ${VideoPlayerScreenState._openDeadline.inSeconds}s of load start — giving up on this open',
    );
    _onPlayerError(PlayerError(t.messages.playbackFailed, cause: PlayerError.openTimedOut));
  }

  String _redactPlayerError(String message) => LogRedactionManager.redact(message);

  Future<void> _showPlaybackNotAllowedDialog() async {
    if (!mounted) return;
    await showPlaybackNotAllowedDialog(context);
    if (mounted) unawaited(_handleBackButton());
  }

  Future<void> _showServerLimitDialog() async {
    if (!mounted) return;
    await showServerLimitDialog(context);
    if (mounted) unawaited(_handleBackButton());
  }

  Future<void> _showMediaUnreadableDialog() async {
    if (!mounted) return;
    // One version's file being gone says nothing about the others'.
    final switchVersion = await showMediaUnreadableDialog(context, offerSwitchVersion: _canSwitchVersionAfterFailure);
    if (!mounted) return;
    if (switchVersion) {
      // Stay on the item: the failure view keeps Retry and Back in reach if
      // the pick is cancelled. A missing file is not retried automatically.
      _presentPlaybackFailure(t.messages.mediaUnreadableTitle);
      unawaited(_switchVersionAfterFailure());
      return;
    }
    unawaited(_handleBackButton());
  }

  Future<void> _showServerBusyDialog() async {
    if (!mounted) return;
    // The reconnect loop is still running behind the modal; pause so a server
    // that recovers mid-dialog cannot start playing under it. Best-effort —
    // the route is left on dialog close either way.
    unawaited(player?.pause().catchError((_) {}));
    await showServerBusyDialog(context);
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
}
