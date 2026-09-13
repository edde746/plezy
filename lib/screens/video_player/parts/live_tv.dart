part of '../../video_player_screen.dart';

const _liveClockReadyTimeout = Duration(seconds: 15);

extension _VideoPlayerLiveTvMethods on VideoPlayerScreenState {
  /// Start periodic timeline heartbeats for live TV transcode session.
  void _startLiveTimelineUpdates() {
    if (_shuttingDown) return;
    final generation = ++_live.timelineGeneration;
    _live.timelineTimer?.cancel();
    unawaited(_refreshLiveGuide());
    _live.timelineTimer = startLiveTimelinePolling(
      // Plex supplies seekable bounds in heartbeat responses. Refresh those
      // alongside playback rather than holding a ten-second-old buffer edge.
      interval: Duration(seconds: _live.session is LiveTvTimeshiftSession ? 2 : 10),
      isCurrent: () => mounted && generation == _live.timelineGeneration,
      onTick: () {
        _setPlayerState(() {}); // Refresh age-based availability, including paused playback.
        unawaited(_refreshLiveGuide());
      },
      report: () {
        final state = player?.state.playing == true ? 'playing' : 'paused';
        return _sendLiveTimeline(state);
      },
    );
  }

  /// Advance the fallback ladder and retry — the error path's entry point.
  void _beginLiveLadderRetry() {
    if (_shuttingDown) return;
    _live.fallbackLevel++;
    _live.retrying = true;
    appLogger.w('Live stream failed, retrying with fallback level ${_live.fallbackLevel}');
    unawaited(_retryLiveStream());
  }

  /// Play pressed while the live stream is dead: reuse the ladder retry
  /// unless one is already in flight.
  Future<void> _retryLiveStreamForPlayIntent() {
    if (_shuttingDown || _live.retrying) return Future.value();
    _live.retrying = true;
    return _retryLiveStream();
  }

  /// A playback restart proves the current ladder level works; refill it.
  void _resetLiveLadderOnPlaybackRestart() {
    _live.fallbackLevel = 0;
    _live.retryFailed = false;
  }

  void _suspendLiveTimelineForBackground() {
    _live.resumeTimelineOnResume = _live.timelineTimer != null;
    _stopLiveTimelineUpdates();
  }

  void _resumeLiveTimelineAfterBackgroundIfNeeded() {
    final shouldResume = _live.resumeTimelineOnResume;
    _live.resumeTimelineOnResume = false;
    if (shouldResume && _live.session != null) {
      _startLiveTimelineUpdates();
    }
  }

  /// The TV background policy stopped the tuned session: exit the screen on
  /// the next resume instead of showing a dead stream.
  void _stopLiveSessionForTvBackground() {
    _live.exitOnResume = true;
    _live.resumeTimelineOnResume = false;
    _stopLiveTimelineUpdates();
  }

  /// Whether the background stop asked for an exit-on-resume; consuming the
  /// flag so the exit runs once.
  bool _consumeLiveExitOnResume() {
    if (!_live.exitOnResume) return false;
    _live.exitOnResume = false;
    return true;
  }

  void _stopLiveTimelineUpdates() {
    _live.timelineGeneration++;
    _live.timelineTimer?.cancel();
    _live.timelineTimer = null;
  }

  Future<void> _sendLiveTimeline(String state) async {
    if (_shuttingDown && state != 'stopped') return;
    final requestSession = _live.session;
    if (requestSession == null) return;
    final requestGeneration = _live.timelineGeneration;
    final requestStreamGeneration = _live.streamGeneration;
    // For live TV, player position/duration are unreliable (often 0). Use
    // elapsed wall-clock as the position and the program duration from tune
    // metadata; the per-backend session owns the wire mapping.
    final playbackTime = _live.playbackElapsed.elapsedMilliseconds;

    try {
      await _live.timelineReports.send(
        stopped: state == 'stopped',
        report: () => runLiveTimelineReport(
          requestSession: requestSession,
          requestGeneration: requestGeneration,
          state: state,
          positionMs: playbackTime,
          currentSession: () => _live.session,
          currentGeneration: () => _live.timelineGeneration,
          isMounted: () => mounted,
          commit: (update) {
            if (requestStreamGeneration != _live.streamGeneration) return;
            _setPlayerState(() {
              final playbackStream = update.playbackStream;
              if (playbackStream != null &&
                  _live.adoptPlaybackStreamOrigin(playbackStream, generation: requestStreamGeneration)) {
                appLogger.d('Live clock re-anchored on playback transcode origin ${playbackStream.startedAt}');
              }
              final buffer = update.captureBuffer;
              if (buffer != null) {
                _live.captureBuffer = buffer;
                _liveBufferAge
                  ..reset()
                  ..start();
              }
            });
          },
        ),
      );
    } catch (e) {
      appLogger.d('Live timeline update failed', error: e);
    }
  }

  /// Fire-and-forget a stopped heartbeat for a session that started but was
  /// never adopted (unmount or superseded mid-start) so the backend tears
  /// down its tuner/transcode resources instead of waiting for a timeout.
  void _abandonLiveSession(LiveTvPlaybackSession session) {
    unawaited(() async {
      try {
        await session.reportTimeline(state: 'stopped', positionMs: 0, durationMs: session.program.durationMs ?? 0);
      } catch (e) {
        appLogger.d('Failed to stop abandoned live session', error: e);
      }
    }());
  }

  /// Resolve the owning live-TV server for [channel] and start a playback
  /// session on it — the shared resolution path for initial launch and
  /// channel zapping (Plex tunes a DVR, Jellyfin negotiates a direct URL).
  Future<LiveTvPlaybackSession?> _startLiveSession(LiveTvChannel channel) async {
    final multiServer = context.read<MultiServerProvider>();
    final serverInfo = liveTvServerInfoForChannel(multiServer, channel);
    if (serverInfo == null) {
      appLogger.w('No live TV server available for ${channel.displayName}');
      return null;
    }
    final client = multiServer.getClientForServer(ServerId(serverInfo.serverId));
    if (client == null) {
      appLogger.w('Live TV server ${serverInfo.serverId} is not connected');
      return null;
    }
    return client.liveTv.startPlayback(channel.key, dvrKey: serverInfo.dvrKey, quality: _selectedQualityPreset);
  }

  /// Retry the live stream with degraded direct-stream settings.
  ///
  /// The session owns the per-backend recovery: Plex re-tunes the channel
  /// for a fresh capture session (the previous one expires while MPV
  /// exhausts its reconnect attempts) applying the degradation flags;
  /// Jellyfin re-opens its session-less URL.
  Future<void> _retryLiveStream() async {
    _liveSeek.cancel();
    final currentPlayer = player;
    if (!mounted || _shuttingDown || currentPlayer == null) return;
    final generation = _transitionGate.generation;
    final intent = _liveSeek.intentGeneration;
    final retryOwner = _live.beginRetry();
    final session = _live.session;
    bool isCurrent() =>
        _isCurrentPlaybackGeneration(generation, currentPlayer) &&
        identical(_live.session, session) &&
        intent == _liveSeek.intentGeneration &&
        _live.ownsRetry(retryOwner);
    _live.playbackPosition(currentPlayer.currentPosition);
    _live.invalidatePlayback();
    if (session == null) {
      _live.finishRetry(retryOwner);
      appLogger.w('Cannot retry live stream — no session');
      showGlobalErrorSnackBar(_redactPlayerError(_lastLogError ?? t.liveTv.liveStreamFailed));
      unawaited(_handleBackButton());
      return;
    }

    final ds = _live.fallbackLevel < 1;
    final dsa = _live.fallbackLevel < 2;
    appLogger.i('Retrying live stream: directStream=$ds directStreamAudio=$dsa');

    // Carried across the re-tune: stream ids are tune-scoped, so the choice
    // is re-mapped onto the recovered session's track list. Recovering the
    // video outranks keeping subtitles — a failed burn re-apply drops them.
    MediaSubtitleTrack? recoveredSubtitle;
    CaptureBuffer? recoveredCaptureBuffer;
    await runLiveStreamRetry<LiveTvPlaybackSession>(
      recover: () => session.recover(directStream: ds, directStreamAudio: dsa),
      lookupStreamUrl: (recovered) async {
        recoveredCaptureBuffer = recovered.captureBuffer;
        recoveredSubtitle = LiveTvSessionState.remapSubtitleSelection(recovered.subtitleTracks, _live.selectedSubtitle);
        if (recoveredSubtitle != null) {
          final url = await recovered.streamUrlAt(subtitleTrack: recoveredSubtitle);
          if (url != null) return url;
          appLogger.w('Live recovery could not re-apply the subtitle burn; retrying without subtitles');
          recoveredSubtitle = null;
        }
        return recovered.streamUrlAt();
      },
      applyPlayerOptions: () => _setLiveStreamOptions(currentPlayer),
      open: (streamUrl) async {
        _live.markStreamRestartedAtLiveEdge(recoveredCaptureBuffer);
        final targetEpoch = recoveredCaptureBuffer == null ? null : _live.streamStartEpoch;
        await _openLiveStream(currentPlayer, streamUrl, targetEpoch: targetEpoch, applyOptions: false);
      },
      isCurrent: isCurrent,
      adoptSession: (recovered) {
        _live.adoptSession(recovered);
        _live.selectedSubtitle = recoveredSubtitle;
        _live.retryFailed = false;
      },
      // Jellyfin's recover() returns the receiver, so the recovered object can
      // be the still-current session; the retry helper skips the discard by
      // identity so a failed retry cannot terminally stop-report it.
      currentSession: () => _live.session,
      discardSession: _abandonLiveSession,
      reportFailure: (error, stackTrace) {
        appLogger.e('Failed to recover live stream', error: error, stackTrace: stackTrace);
        _live.retryFailed = true;
        showGlobalErrorSnackBar(t.messages.liveStreamInterrupted);
      },
      onFinished: () {
        // Intent/session supersession may invalidate adoption, but the retry
        // still releases its own flag. It cannot release a newer retry.
        _live.finishRetry(retryOwner);
      },
    );
  }

  /// Configure MPV options for live streaming.
  /// The official Plex Media Player does not set client-side reconnect options —
  /// reconnection is handled by the server's transcoder on the input side.
  Future<void> _setLiveStreamOptions(Player player) => player.setProperty('force-seekable', 'no');

  /// Re-opens the current session's live stream at [streamUrl].
  ///
  /// Offset-based MPV opens register their requested absolute [targetEpoch]
  /// before `loadfile` and bind that registration to the source id the load
  /// reports, so only that source's events can calibrate it. When [awaitClock]
  /// is true, success means the new source's first rendered player position
  /// has been mapped to that epoch.
  Future<bool> _openLiveStream(
    Player player,
    String streamUrl, {
    double? targetEpoch,
    bool awaitClock = false,
    bool? play,
    bool applyOptions = true,
    bool Function()? isCurrent,
    bool timeShifted = false,
    void Function()? onOpenStarted,
  }) async {
    bool ownsOpen() =>
        mounted && !_shuttingDown && _launchCurrent && this.player == player && (isCurrent?.call() ?? true);
    if (!ownsOpen()) return false;
    _live.playbackPosition(player.currentPosition);
    _live.invalidatePlayback();
    _live.streamGeneration++;
    final streamGeneration = _live.streamGeneration;
    bool ownsStream() => ownsOpen() && streamGeneration == _live.streamGeneration;
    final media = Media(streamUrl, headers: const {'Accept-Language': 'en'});
    final playNow = play ?? automotivePlaybackAllowedNow();
    if (targetEpoch == null || player is! PlayerNative) {
      if (applyOptions) await _setLiveStreamOptions(player);
      if (!ownsStream()) return false;
      onOpenStarted?.call();
      await player.open(media, play: playNow, isLive: true);
      if (ownsStream() && targetEpoch != null) {
        _live.estimateUnidentifiedStream(targetEpoch, player.currentPosition);
      }
      return ownsStream();
    }

    final clockGeneration = _live.beginClockOpen(targetEpoch);
    final clockResult = _live.clockOpenResult(clockGeneration);
    final int? sourceId;
    try {
      if (applyOptions) await _setLiveStreamOptions(player);
      if (!ownsStream()) {
        _live.failClockOpen(clockGeneration);
        return false;
      }
      onOpenStarted?.call();
      sourceId = await player.open(media, play: playNow, isLive: true, startLivePlaylistFromBeginning: timeShifted);
    } catch (_) {
      _live.failClockOpen(clockGeneration);
      rethrow;
    }
    if (!ownsStream()) {
      _live.failClockOpen(clockGeneration);
      return false;
    }
    if (sourceId == null) {
      // The load never reached mpv (core unavailable), so no source will ever
      // report for this open.
      _live.failClockOpen(clockGeneration);
      return false;
    }
    _live.bindClockOpen(clockGeneration, sourceId);

    if (!awaitClock) {
      unawaited(clockResult);
      return true;
    }
    return clockResult.timeout(
      _liveClockReadyTimeout,
      onTimeout: () {
        _live.timeoutClockOpen(clockGeneration);
        appLogger.w('Live time-shift source did not report a rendered clock position');
        return false;
      },
    );
  }

  double? get _currentPositionEpoch =>
      _liveSeek.pendingEpoch ?? _live.playbackPosition(player?.currentPosition ?? Duration.zero).epoch;

  LiveTvTimeline _liveTimelineForPosition(Duration position) {
    final session = _live.session;
    final buffer = _live.captureBuffer;
    final staleBuffer = _liveBufferAge.isRunning && _liveBufferAge.elapsed > const Duration(seconds: 30);
    final seekable = session is LiveTvTimeshiftSession && buffer != null && !staleBuffer
        ? (session as LiveTvTimeshiftSession).seekWindow(buffer)
        : null;
    return LiveTvTimeline.resolve(
      playback: _live.playbackPosition(position),
      seekable: seekable,
      liveEdgeEpoch: buffer == null ? null : buffer.startedAt + buffer.seekEndSeconds,
      liveEdgeAccuracy: buffer == null
          ? LiveTvTimeAccuracy.unknown
          : staleBuffer
          ? LiveTvTimeAccuracy.stale
          : LiveTvTimeAccuracy.estimated,
      pendingSeekEpoch: _liveSeek.pendingEpoch ?? _live.pendingTargetEpoch,
      programPreviewEpoch: _liveSeek.programPreviewEpoch,
      seekStatus: _liveSeek.pendingEpoch != null ? LiveTvSeekStatus.pending : _live.seekStatus,
      programs: identical(_liveGuideSession, session) ? _liveGuide.programs : const [],
      metadataNowEpoch: DateTime.now().millisecondsSinceEpoch / 1000.0,
      programDataStale: _liveGuide.stale || _liveGuideAge.elapsed > const Duration(minutes: 2),
    );
  }

  Future<void> _refreshLiveGuide() async {
    final session = _live.session;
    if (session == null || session is! LiveTvTimeshiftSession || !mounted) return;
    if (!identical(_liveGuideSession, session)) {
      _liveGuideSession = session;
      _liveGuide.reset(session);
      _liveGuideLoading = false;
      _liveGuideAge.reset();
      _liveBufferAge
        ..reset()
        ..start();
    } else if (_liveGuideLoading || (_liveGuideAge.isRunning && _liveGuideAge.elapsed < const Duration(minutes: 1))) {
      return;
    }
    final args = widget.live!;
    final channels = args.channels;
    final channel = channels != null && _live.channelIndex >= 0 && _live.channelIndex < channels.length
        ? channels[_live.channelIndex]
        : args.channel;
    final multiServer = context.read<MultiServerProvider>();
    final serverInfo = liveTvServerInfoForChannel(multiServer, channel);
    if (serverInfo == null) return;
    final client = multiServer.getClientForServer(ServerId(serverInfo.serverId));
    if (client == null) return;
    _liveGuideLoading = true;
    final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final buffer = _live.captureBuffer;
    final playback = _live.playbackPosition(player?.currentPosition ?? Duration.zero).epoch;
    var from = buffer == null ? now - 3600 : buffer.startedAt + buffer.seekStartSeconds;
    if (playback != null && playback < from) from = playback;
    final changed = await _liveGuide.refresh(
      owner: session,
      channel: channel,
      fromEpoch: from,
      toEpoch: now + 6 * 3600,
      fetch: (from, to) => client.liveTv.fetchSchedule(from: from, to: to),
    );
    if (!mounted || !identical(_live.session, session) || !identical(_liveGuideSession, session)) return;
    _liveGuideLoading = false;
    _liveGuideAge
      ..reset()
      ..start();
    if (changed) _setPlayerState(() {});
  }

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

  /// Seek the live TV stream to an absolute epoch second by rebuilding the
  /// stream at the target offset. The session returns null when the backend
  /// can't time-shift (Jellyfin), and its capture buffer is null there too,
  /// so both guards cover it. Returns whether the rebuilt stream was opened.
  Future<bool> _seekLivePosition(double? targetEpochSeconds, {PlaybackTransitionLease? sourceLease}) async {
    final currentPlayer = player;
    final session = _live.session;
    bool ownsTransition() => sourceLease == null
        ? _transitionGate.transition == PlaybackTransition.idle
        : _transitionGate.owns(sourceLease, expected: PlaybackTransition.switchingSource);
    if (currentPlayer == null ||
        session == null ||
        session is! LiveTvTimeshiftSession ||
        !ownsTransition() ||
        _live.retrying) {
      return false;
    }
    final generation = _transitionGate.generation;
    final intent = _liveSeek.intentGeneration;
    bool isCurrent() =>
        _isCurrentPlaybackGeneration(generation, currentPlayer) &&
        identical(_live.session, session) &&
        intent == _liveSeek.intentGeneration &&
        ownsTransition() &&
        !_live.retrying;
    _live.seekStatus = LiveTvSeekStatus.pending;
    final result = await runLiveTvSeek(
      session: session as LiveTvTimeshiftSession,
      targetEpoch: targetEpochSeconds,
      currentBuffer: () => targetEpochSeconds == null ? _live.captureBuffer : _freshLiveBuffer,
      isCurrent: isCurrent,
      subtitleTrack: _live.selectedSubtitle,
      open: (request) async {
        if (!isCurrent()) return false;
        _live.playbackElapsed
          ..reset()
          ..start();
        return _openLiveStream(
          currentPlayer,
          request.url,
          targetEpoch: request.effectiveTargetEpoch,
          awaitClock: currentPlayer is PlayerNative,
          isCurrent: isCurrent,
          timeShifted: targetEpochSeconds != null,
        );
      },
    );
    if (result == LiveTvSeekOutcome.superseded || !isCurrent()) return false;
    if (result == LiveTvSeekOutcome.failed) {
      _live.seekStatus = LiveTvSeekStatus.failed;
      showGlobalErrorSnackBar(t.liveTv.liveStreamFailed);
    }
    _setPlayerState(() {});
    return result == LiveTvSeekOutcome.opened;
  }

  /// Apply a source subtitle choice to the live stream by rebuilding it with
  /// the backend's server-side delivery (Plex points the part's selection at
  /// the stream and burns it). The live counterpart of the VOD source switch:
  /// same [PlaybackSourceSubtitleChoice], but the restart is the raw
  /// `streamUrlAt → open(isLive: true)` every live URL change uses.
  Future<PlaybackSourceChangeOutcome> _switchLiveSubtitle(
    PlaybackSourceSubtitleChoice choice,
    PlaybackTransitionLease lease,
  ) async {
    if (_live.retrying) return PlaybackSourceChangeOutcome.busy;
    _liveSeek.cancel();
    final currentPlayer = player;
    final session = _live.session;
    if (currentPlayer == null || session == null) return PlaybackSourceChangeOutcome.unavailable;

    MediaSubtitleTrack? target;
    if (!choice.isOff) {
      for (final track in session.subtitleTracks) {
        if (track.id == choice.sourceStreamId) {
          target = track;
          break;
        }
      }
      if (target == null) return PlaybackSourceChangeOutcome.unavailable;
    }
    final previous = _live.selectedSubtitle;
    if (target?.id == previous?.id) return PlaybackSourceChangeOutcome.unchanged;

    _live.selectedSubtitle = target;

    // Preserve the active position estimate even after a long live pause.
    // Last-open mode cannot establish where playback is now.
    if (_live.captureBuffer != null && _currentPositionEpoch != null) {
      if (_currentPositionEpoch != null && await _seekLivePosition(_currentPositionEpoch, sourceLease: lease)) {
        return PlaybackSourceChangeOutcome.applied;
      }
      if (!_transitionGate.owns(lease) || !identical(_live.session, session)) {
        return PlaybackSourceChangeOutcome.superseded;
      }
      _live.selectedSubtitle = previous;
      return PlaybackSourceChangeOutcome.failed;
    }

    final streamUrl = await session.streamUrlAt(subtitleTrack: target);
    if (!mounted || player != currentPlayer || _live.session != session) {
      return PlaybackSourceChangeOutcome.superseded;
    }
    if (streamUrl == null) {
      _live.selectedSubtitle = previous;
      return PlaybackSourceChangeOutcome.failed;
    }
    _live.markStreamRestartedAtLiveEdge(_live.captureBuffer);
    await _openLiveStream(
      currentPlayer,
      streamUrl,
      targetEpoch: _live.captureBuffer == null ? null : _live.streamStartEpoch,
      isCurrent: () => _transitionGate.owns(lease) && identical(_live.session, session),
    );
    if (mounted) _setPlayerState(() {});
    return PlaybackSourceChangeOutcome.applied;
  }

  /// Current seekable epoch window for [_liveSeek], or null when there is no
  /// live capture buffer.
  CaptureBuffer? get _freshLiveBuffer =>
      _liveBufferAge.isRunning && _liveBufferAge.elapsed > const Duration(seconds: 30) ? null : _live.captureBuffer;

  LiveSeekBounds? _liveSeekBounds() {
    if (_live.retrying) return null;
    final session = _live.session;
    final buffer = _freshLiveBuffer;
    if (session is! LiveTvTimeshiftSession || buffer == null) return null;
    final window = (session as LiveTvTimeshiftSession).seekWindow(buffer);
    return window;
  }

  void _onLiveSeekTargetChanged() {
    if (!mounted) return;
    if (_lastLiveIntent != _liveSeek.intentGeneration) {
      _lastLiveIntent = _liveSeek.intentGeneration;
      _live.cancelClockOpens();
    }
    _setPlayerState(() {});
  }

  /// Re-open the live stream at [targetEpochSeconds], logging failures.
  Future<bool> _runLiveSeek(double? targetEpochSeconds) async {
    final session = _live.session;
    final intent = _liveSeek.intentGeneration;
    try {
      final opened = await _seekLivePosition(targetEpochSeconds);
      if (!opened) {
        appLogger.w('Live time-shift seek did not reach a ready source');
      }
      return opened;
    } catch (e, st) {
      appLogger.w('Live time-shift seek failed', error: e, stackTrace: st);
      if (mounted && identical(_live.session, session) && intent == _liveSeek.intentGeneration) {
        _live.seekStatus = LiveTvSeekStatus.failed;
        _setPlayerState(() {});
        showGlobalErrorSnackBar(t.liveTv.liveStreamFailed);
      }
      return false;
    }
  }

  /// Seek the live stream to an absolute epoch (scrubber / jump-to-live). Drops
  /// any pending relative-skip burst first so a queued seek can't override it.
  void _seekLiveToEpoch(double targetEpochSeconds) => _liveSeek.seekTo(targetEpochSeconds);

  /// Jump to the live edge of the capture buffer.
  void _jumpToLiveEdge() {
    if (_live.retrying) return;
    final buffer = _live.captureBuffer;
    if (buffer != null) _liveSeek.jumpToLive(previewEpoch: buffer.startedAt + buffer.seekEndSeconds);
  }

  Future<void> _switchLiveChannel(int delta) async {
    if (_shuttingDown) return;
    final channels = widget.live?.channels;
    if (channels == null || channels.isEmpty) return;
    final newIndex = _live.channelIndex + delta;
    if (newIndex < 0 || newIndex >= channels.length) return;
    final currentPlayer = player;
    if (currentPlayer == null) return;

    final transitionLease = _transitionGate.tryAcquire(PlaybackTransition.switchingChannel);
    if (transitionLease == null) return; // debounce concurrent switches
    bool isCurrentChannelSwitch() =>
        mounted &&
        !_shuttingDown &&
        player == currentPlayer &&
        _transitionGate.owns(transitionLease, expected: PlaybackTransition.switchingChannel);
    _liveSeek.cancel();
    _live.cancelRetry();

    final previousSession = _live.session;
    final previousFirstFrame = _firstFrame.snapshot();
    final channel = channels[newIndex];
    appLogger.d('Switching to channel: ${channel.displayName} (${channel.key})');

    LiveTvPlaybackSession? session;
    var replacementOpenStarted = false;
    try {
      // Channel switch IS a fresh start: same resolution path as launch. Keep
      // the old session alive until the replacement stream is actually open so
      // a failed zap does not tell the server to reclaim the still-playing
      // tuner/transcode session.
      session = await _startLiveSession(channel);
      if (session == null) {
        // Jellyfin's negotiation returns null instead of throwing, so this
        // is not covered by the catch below; without feedback a failed zap
        // looks like a dead remote (#2198).
        if (mounted) showErrorSnackBar(context, t.liveTv.failedToStartChannel);
        return;
      }
      if (!isCurrentChannelSwitch()) {
        _abandonLiveSession(session);
        return;
      }

      final streamUrl = await session.streamUrlAt();
      if (streamUrl == null || !isCurrentChannelSwitch()) {
        _abandonLiveSession(session);
        return;
      }

      _setPlayerState(() {
        _firstFrame.reset();
      });
      _live.markStreamRestartedAtLiveEdge(session.captureBuffer);
      final targetEpoch = session.captureBuffer == null ? null : _live.streamStartEpoch;
      await _openLiveStream(
        currentPlayer,
        streamUrl,
        targetEpoch: targetEpoch,
        onOpenStarted: () {
          replacementOpenStarted = true;
          // The native state belongs to the replacement from this point,
          // before its session/channel is adopted after timeline reporting.
          // Detach the receipt, not the screen's launch lifetime fence.
          widget.launchObserver?.detach();
        },
      );
      if (!isCurrentChannelSwitch()) {
        _abandonLiveSession(session);
        return;
      }

      // The new stream is now the active local playback. Stop the old heartbeat
      // and send its terminal timeline before adopting the replacement session.
      _stopLiveTimelineUpdates();
      if (previousSession != null) {
        await _sendLiveTimeline('stopped');
      }
      if (!isCurrentChannelSwitch()) {
        _abandonLiveSession(session);
        return;
      }

      _live.adoptSession(session);
      _live.fallbackLevel = 0;
      _live.cancelRetry();
      _live.retryFailed = false;

      if (!mounted) return;
      _setPlayerState(() {
        _live.channelIndex = newIndex;
        _live.channelName = channel.displayName;
      });

      // Restart timeline heartbeats for the new session
      _startLiveTimelineUpdates();
    } catch (e) {
      // A session that tuned but was never adopted (streamUrlAt/open threw)
      // would otherwise hold its server-side tuner until the backend times out.
      final orphan = session;
      if (orphan != null && _live.session != orphan) _abandonLiveSession(orphan);
      if (!isCurrentChannelSwitch()) return;
      if (replacementOpenStarted && mounted && _live.session == previousSession) {
        _setPlayerState(() {
          _firstFrame.restore(previousFirstFrame);
        });
      }
      appLogger.e('Failed to switch channel', error: e);
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      _transitionGate.release(transitionLease);
    }
  }

  bool get _hasNextChannel {
    final channels = widget.live?.channels;
    return channels != null && _live.channelIndex >= 0 && _live.channelIndex < channels.length - 1;
  }

  bool get _hasPreviousChannel => widget.live?.channels != null && _live.channelIndex > 0;
}
