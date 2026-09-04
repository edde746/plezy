part of '../../video_player_screen.dart';

extension _VideoPlayerLiveTvMethods on VideoPlayerScreenState {
  /// Start periodic timeline heartbeats for live TV transcode session.
  void _startLiveTimelineUpdates() {
    final generation = ++_live.timelineGeneration;
    _live.timelineTimer?.cancel();
    _live.timelineTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (generation != _live.timelineGeneration) return;
      final state = player?.state.playing == true ? 'playing' : 'paused';
      _sendLiveTimeline(state);
    });
    // Delay initial heartbeat to let the transcode session stabilize.
    // Sending time=0 immediately after player.open() causes the server
    // to spawn a duplicate transcode job with offset=-1 that 404s.
    Future.delayed(const Duration(seconds: 3), () {
      if (_live.timelineTimer != null && generation == _live.timelineGeneration) {
        final state = player?.state.playing == true ? 'playing' : 'paused';
        _sendLiveTimeline(state);
      }
    });
  }

  /// Advance the fallback ladder and retry — the error path's entry point.
  void _beginLiveLadderRetry() {
    _live.fallbackLevel++;
    _live.retrying = true;
    appLogger.w('Live stream failed, retrying with fallback level ${_live.fallbackLevel}');
    unawaited(_retryLiveStream());
  }

  /// Play pressed while the live stream is dead: reuse the ladder retry
  /// unless one is already in flight.
  Future<void> _retryLiveStreamForPlayIntent() {
    if (_live.retrying) return Future.value();
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
    final requestSession = _live.session;
    if (requestSession == null) return;
    final requestGeneration = _live.timelineGeneration;
    // For live TV, player position/duration are unreliable (often 0). Use
    // elapsed wall-clock as the position and the program duration from tune
    // metadata; the per-backend session owns the wire mapping.
    final playbackTime = _live.playbackStartTime != null
        ? DateTime.now().difference(_live.playbackStartTime!).inMilliseconds
        : 0;

    try {
      await runLiveTimelineReport(
        requestSession: requestSession,
        requestGeneration: requestGeneration,
        state: state,
        positionMs: playbackTime,
        currentSession: () => _live.session,
        currentGeneration: () => _live.timelineGeneration,
        isMounted: () => mounted,
        commit: (updatedBuffer) {
          _setPlayerState(() {
            _live.captureBuffer = updatedBuffer;
            _live.atLiveEdge =
                (_currentPositionEpoch >=
                updatedBuffer.seekableEndEpoch - VideoPlayerScreenState._liveEdgeThresholdSeconds);
          });
        },
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
    if (!mounted || currentPlayer == null) return;
    final generation = _transitionGate.generation;
    bool isCurrent() => _isCurrentPlaybackGeneration(generation, currentPlayer);
    final session = _live.session;
    if (session == null) {
      _live.retrying = false;
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
    final result = await runLiveStreamRetry<LiveTvPlaybackSession>(
      recover: () => session.recover(directStream: ds, directStreamAudio: dsa),
      lookupStreamUrl: (recovered) async {
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
      open: (streamUrl) => currentPlayer.open(
        Media(streamUrl, headers: const {'Accept-Language': 'en'}),
        play: automotivePlaybackAllowedNow(),
        isLive: true,
      ),
      isCurrent: isCurrent,
      adoptSession: (recovered) {
        _live.adoptSession(recovered);
        _live.selectedSubtitle = recoveredSubtitle;
        _live.markStreamRestartedAtLiveEdge();
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
        if (isCurrent()) _live.retrying = false;
      },
    );
    if (result == LiveStreamRetryResult.succeeded && isCurrent()) {
      _live.retryFailed = false;
    }
  }

  /// Configure MPV options for live streaming.
  /// The official Plex Media Player does not set client-side reconnect options —
  /// reconnection is handled by the server's transcoder on the input side.
  Future<void> _setLiveStreamOptions(Player player) => player.setProperty('force-seekable', 'no');

  /// Re-opens the current session's live stream at [streamUrl]: options, then
  /// `open(isLive: true)` honouring the automotive playback gate.
  Future<void> _openLiveStream(Player player, String streamUrl) async {
    await _setLiveStreamOptions(player);
    await player.open(
      Media(streamUrl, headers: const {'Accept-Language': 'en'}),
      play: automotivePlaybackAllowedNow(),
      isLive: true,
    );
  }

  /// The raw live playback position as an absolute epoch second
  /// (`_live.streamStartEpoch + player position`).
  int get _rawPositionEpoch => (_live.streamStartEpoch + (player?.state.position.inSeconds ?? 0)).round();

  /// The current playback position as an absolute epoch second (for live TV time-shift).
  ///
  /// While a relative skip is pending/settling, this returns the accumulator's
  /// target rather than the raw sum. During a live re-open `_live.streamStartEpoch`
  /// is advanced to the target before the new stream's position resets to ~0,
  /// so the raw sum transiently overshoots; pinning to the pending target keeps
  /// seek accumulation and the live-edge heartbeat ([_sendLiveTimeline]) correct
  /// (close #1253).
  int get _currentPositionEpoch => _liveSeek.pendingEpoch ?? _rawPositionEpoch;

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
  Future<bool> _seekLivePosition(int targetEpochSeconds) async {
    final currentPlayer = player;
    if (currentPlayer == null) return false;
    final session = _live.session;
    final buffer = _live.captureBuffer;
    if (session == null || buffer == null) return false;

    final clamped = targetEpochSeconds.clamp(buffer.seekableStartEpoch, buffer.seekableEndEpoch);
    final offsetSeconds = clamped - buffer.startedAt.round();

    final streamUrl = await session.streamUrlAt(offsetSeconds: offsetSeconds, subtitleTrack: _live.selectedSubtitle);
    if (streamUrl == null || !mounted || player != currentPlayer) return false;

    _live.streamStartEpoch = buffer.startedAt + offsetSeconds;
    _live.atLiveEdge = (clamped >= buffer.seekableEndEpoch - VideoPlayerScreenState._liveEdgeThresholdSeconds);
    _live.playbackStartTime = DateTime.now();

    await _openLiveStream(currentPlayer, streamUrl);
    if (mounted) _setPlayerState(() {});
    return true;
  }

  /// Apply a source subtitle choice to the live stream by rebuilding it with
  /// the backend's server-side delivery (Plex points the part's selection at
  /// the stream and burns it). The live counterpart of the VOD source switch:
  /// same [PlaybackSourceSubtitleChoice], but the restart is the raw
  /// `streamUrlAt → open(isLive: true)` every live URL change uses.
  Future<PlaybackSourceChangeOutcome> _switchLiveSubtitle(PlaybackSourceSubtitleChoice choice) async {
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

    // Keep the viewer's position: rebuild at the time-shift offset when
    // behind the live edge, otherwise re-open at the edge.
    if (_live.captureBuffer != null && !_live.atLiveEdge) {
      if (await _seekLivePosition(_currentPositionEpoch)) return PlaybackSourceChangeOutcome.applied;
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
    await _openLiveStream(currentPlayer, streamUrl);
    _live.markStreamRestartedAtLiveEdge();
    if (mounted) _setPlayerState(() {});
    return PlaybackSourceChangeOutcome.applied;
  }

  /// Current seekable epoch window for [_liveSeek], or null when there is no
  /// live capture buffer.
  LiveSeekBounds? _liveSeekBounds() {
    final buffer = _live.captureBuffer;
    if (buffer == null) return null;
    return (start: buffer.seekableStartEpoch, end: buffer.seekableEndEpoch);
  }

  /// Rebuild and refresh live-edge state when [_liveSeek]'s pending target
  /// changes (a skip was accumulated, or the post-seek pin was released).
  void _onLiveSeekTargetChanged() {
    if (!mounted) return;
    final pending = _liveSeek.pendingEpoch;
    final buffer = _live.captureBuffer;
    _setPlayerState(() {
      if (pending != null && buffer != null) {
        _live.atLiveEdge = pending >= buffer.seekableEndEpoch - VideoPlayerScreenState._liveEdgeThresholdSeconds;
      }
    });
  }

  /// Re-open the live stream at [targetEpochSeconds], logging (rather than
  /// throwing) on failure. A throw is rethrown so [_liveSeek] releases its
  /// pending pin; direct callers catch it.
  Future<void> _runLiveSeek(int targetEpochSeconds) async {
    try {
      await _seekLivePosition(targetEpochSeconds);
    } catch (e, st) {
      appLogger.w('Live time-shift seek failed', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Seek the live stream to an absolute epoch (scrubber / jump-to-live). Drops
  /// any pending relative-skip burst first so a queued seek can't override it.
  Future<void> _seekLiveToEpoch(int targetEpochSeconds) async {
    _liveSeek.cancel();
    try {
      await _runLiveSeek(targetEpochSeconds);
    } catch (_) {
      // Already logged; an absolute live seek is best-effort.
    }
  }

  /// Jump to the live edge of the capture buffer.
  Future<void> _jumpToLiveEdge() async {
    if (_live.captureBuffer == null) return;
    await _seekLiveToEpoch(_live.captureBuffer!.seekableEndEpoch);
  }

  Future<void> _switchLiveChannel(int delta) async {
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
        player == currentPlayer &&
        _transitionGate.owns(transitionLease, expected: PlaybackTransition.switchingChannel);
    _liveSeek.cancel();

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

      await _setLiveStreamOptions(currentPlayer);
      if (!isCurrentChannelSwitch()) {
        _abandonLiveSession(session);
        return;
      }

      _setPlayerState(() {
        _firstFrame.reset();
      });
      replacementOpenStarted = true;
      await currentPlayer.open(
        Media(streamUrl, headers: const {'Accept-Language': 'en'}),
        play: automotivePlaybackAllowedNow(),
        isLive: true,
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
      _live.markStreamRestartedAtLiveEdge();

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
