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

  void _stopLiveTimelineUpdates() {
    _live.timelineGeneration++;
    _live.timelineTimer?.cancel();
    _live.timelineTimer = null;
  }

  Future<void> _sendLiveTimeline(String state) async {
    final client = _live.client;
    final playbackTime = _live.playbackStartTime != null
        ? DateTime.now().difference(_live.playbackStartTime!).inMilliseconds
        : 0;

    if (client is PlexClient) {
      final sessionId = _live.sessionIdentifier;
      final sessionPath = _live.sessionPath;
      if (sessionId == null || sessionPath == null) return;
      try {
        // Use the program ratingKey from tune metadata, not the channel key
        final ratingKey = _live.programId ?? _live.itemId;
        // For live TV, player position/duration are unreliable (often 0).
        // Use playbackTime as time, and program duration from tune metadata.
        // Plex rejects timeline pings where time > duration; grow duration to
        // match — otherwise Tunarr-style short synthetic programs 400 mid-stream.
        final time = playbackTime;
        final duration = max(_live.durationMs ?? 0, time);
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
          _setPlayerState(() {
            _live.captureBuffer = updatedBuffer;
            _live.atLiveEdge =
                (_currentPositionEpoch >=
                updatedBuffer.seekableEndEpoch - VideoPlayerScreenState._liveEdgeThresholdSeconds);
          });
        }
      } catch (e) {
        appLogger.d('Plex live timeline update failed', error: e);
      }
      return;
    }

    if (client is JellyfinClient) {
      await _live.jellyfin.report(
        client: client,
        itemId: _live.itemId,
        state: state,
        position: Duration(milliseconds: playbackTime),
        duration: Duration(milliseconds: _live.durationMs ?? 0),
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
    _liveSeek.cancel();
    final currentPlayer = player;
    if (!mounted || currentPlayer == null) return;
    final client = _live.client;
    final ds = _live.fallbackLevel < 1;
    final dsa = _live.fallbackLevel < 2;

    if (client is PlexClient) {
      final channels = widget.live?.channels;
      final channelIndex = _live.channelIndex;
      final dvrKey = _live.dvrKey;
      if (channels == null || channelIndex < 0 || channelIndex >= channels.length || dvrKey == null) {
        appLogger.w('Cannot retry live stream — missing session info');
        showGlobalErrorSnackBar(_redactPlayerError(_lastLogError ?? t.liveTv.liveStreamFailed));
        unawaited(_handleBackButton());
        return;
      }
      final channel = channels[channelIndex];
      appLogger.i('Retrying live stream (re-tune ${channel.key}): directStream=$ds directStreamAudio=$dsa');

      // Re-tune to get a fresh capture session — the previous one is dead.
      final tuneResult = await client.tuneChannel(dvrKey, channel.key);
      if (!mounted || player != currentPlayer) return;
      if (tuneResult == null) {
        showGlobalErrorSnackBar(_redactPlayerError(_lastLogError ?? t.liveTv.liveStreamFailed));
        unawaited(_handleBackButton());
        return;
      }

      _live.sessionIdentifier = tuneResult.sessionIdentifier;
      _live.sessionPath = tuneResult.sessionPath;
      _live.transcodeSessionId = generateSessionIdentifier();

      final streamPath = await client.buildLiveStreamPath(
        sessionPath: tuneResult.sessionPath,
        sessionIdentifier: tuneResult.sessionIdentifier,
        transcodeSessionId: _live.transcodeSessionId!,
        directStream: ds,
        directStreamAudio: dsa,
      );
      if (!mounted || player != currentPlayer) return;
      if (streamPath == null) {
        showGlobalErrorSnackBar(_redactPlayerError(_lastLogError ?? t.liveTv.liveStreamFailed));
        unawaited(_handleBackButton());
        return;
      }

      final streamUrl = client.buildLiveStreamUrl(streamPath);
      _live.streamUrl = streamUrl;
      _live.markStreamRestartedAtLiveEdge();

      await _setLiveStreamOptions(currentPlayer);
      await currentPlayer.open(Media(streamUrl, headers: const {'Accept-Language': 'en'}), play: true, isLive: true);
      return;
    }

    final liveStreamUrl = _live.streamUrl;
    if (client is JellyfinClient && liveStreamUrl != null) {
      appLogger.i('Retrying Jellyfin live stream by re-opening URL');
      _live.markStreamRestartedAtLiveEdge();
      await _setLiveStreamOptions(currentPlayer);
      await currentPlayer.open(
        Media(liveStreamUrl, headers: const {'Accept-Language': 'en'}),
        play: true,
        isLive: true,
      );
      return;
    }

    appLogger.w('Cannot retry live stream — no compatible client/URL available');
    showGlobalErrorSnackBar(_redactPlayerError(_lastLogError ?? t.liveTv.liveStreamFailed));
    unawaited(_handleBackButton());
  }

  /// Configure MPV options for live streaming.
  /// The official Plex Media Player does not set client-side reconnect options —
  /// reconnection is handled by the server's transcoder on the input side.
  Future<void> _setLiveStreamOptions(Player player) => player.setProperty('force-seekable', 'no');

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

  /// Seek the live TV stream to an absolute epoch second.
  /// Creates a new transcode session at the target offset.
  Future<void> _seekLivePosition(int targetEpochSeconds) async {
    final currentPlayer = player;
    if (currentPlayer == null) return;
    if (_live.captureBuffer == null ||
        _live.sessionPath == null ||
        _live.sessionIdentifier == null ||
        _live.transcodeSessionId == null) {
      return;
    }

    final clamped = targetEpochSeconds.clamp(
      _live.captureBuffer!.seekableStartEpoch,
      _live.captureBuffer!.seekableEndEpoch,
    );

    final offsetSeconds = clamped - _live.captureBuffer!.startedAt.round();

    // Live seek requires a transcode session — Plex-only by protocol. The
    // Plex path populates _live.captureBuffer; the Jellyfin path never does, so
    // the early-return above already covers Jellyfin in practice. This
    // explicit guard keeps the contract obvious.
    final client = _live.client;
    if (client is! PlexClient) return;

    final streamPath = await client.buildLiveStreamPath(
      sessionPath: _live.sessionPath!,
      sessionIdentifier: _live.sessionIdentifier!,
      transcodeSessionId: _live.transcodeSessionId!,
      offsetSeconds: offsetSeconds,
    );
    if (streamPath == null || !mounted || player != currentPlayer) return;

    final streamUrl = client.buildLiveStreamUrl(streamPath);

    _live.streamStartEpoch = _live.captureBuffer!.startedAt + offsetSeconds;
    _live.atLiveEdge =
        (clamped >= _live.captureBuffer!.seekableEndEpoch - VideoPlayerScreenState._liveEdgeThresholdSeconds);
    _live.playbackStartTime = DateTime.now();

    await _setLiveStreamOptions(currentPlayer);
    await currentPlayer.open(Media(streamUrl, headers: const {'Accept-Language': 'en'}), play: true, isLive: true);
    if (mounted) _setPlayerState(() {});
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
    if (_playbackTransition != _PlaybackTransition.idle) return; // debounce concurrent switches

    final newIndex = _live.channelIndex + delta;
    if (newIndex < 0 || newIndex >= channels.length) return;
    final currentPlayer = player;
    if (currentPlayer == null) return;

    _playbackTransition = _PlaybackTransition.switchingChannel;
    _liveSeek.cancel();

    // Stop old session heartbeats and notify server
    _stopLiveTimelineUpdates();
    await _sendLiveTimeline('stopped');

    final channel = channels[newIndex];
    appLogger.d('Switching to channel: ${channel.displayName} (${channel.key})');

    if (!mounted) return;
    _setPlayerState(() => _hasFirstFrame.value = false);

    try {
      // Look up the correct client/DVR for this channel's server
      final multiServer = context.read<MultiServerProvider>();
      final serverInfo = liveTvServerInfoForChannel(multiServer, channel);

      if (serverInfo == null) return;

      final genericClient = multiServer.getClientForServer(ServerId(serverInfo.serverId));
      final resolution = await genericClient?.liveTv.resolveStreamUrl(channel.key, dvrKey: serverInfo.dvrKey);
      if (!mounted || player != currentPlayer) return;
      if (resolution != null) {
        // Jellyfin: pre-resolved negotiated URL.
        await _setLiveStreamOptions(currentPlayer);
        await currentPlayer.open(
          Media(resolution.url, headers: const {'Accept-Language': 'en'}),
          play: true,
          isLive: true,
        );
        _live.client = genericClient;
        _live.dvrKey = serverInfo.dvrKey;
        _live.streamUrl = resolution.url;
        _live.itemId = channel.key;
        _live.sessionIdentifier = resolution.playSessionId;
        _live.jellyfin = JellyfinLiveSessionTracker(playSessionId: resolution.playSessionId);
        _live.captureBuffer = null;
        _live.programBeginsAt = null;
        _live.programId = null;
        _live.durationMs = null;
        _live.markStreamRestartedAtLiveEdge();
        if (!mounted) return;
        _setPlayerState(() {
          _live.channelIndex = newIndex;
          _live.channelName = channel.displayName;
        });
        _startLiveTimelineUpdates();
        return;
      }

      // Plex-only: DVR tune flow (Jellyfin Live TV uses pre-resolved URLs).
      final client = multiServer.getPlexClientForServer(ServerId(serverInfo.serverId));
      if (client == null) return;

      final tuneResult = await client.tuneChannel(serverInfo.dvrKey, channel.key);
      if (tuneResult == null || !mounted || player != currentPlayer) return;

      _live.transcodeSessionId = generateSessionIdentifier();
      _live.fallbackLevel = 0;

      final streamPath = await client.buildLiveStreamPath(
        sessionPath: tuneResult.sessionPath,
        sessionIdentifier: tuneResult.sessionIdentifier,
        transcodeSessionId: _live.transcodeSessionId!,
      );
      if (streamPath == null || !mounted || player != currentPlayer) return;

      final streamUrl = client.buildLiveStreamUrl(streamPath);

      await _setLiveStreamOptions(currentPlayer);
      await currentPlayer.open(Media(streamUrl, headers: const {'Accept-Language': 'en'}), play: true, isLive: true);

      _live.client = client;
      _live.dvrKey = serverInfo.dvrKey;
      _live.streamUrl = streamUrl;
      _live.itemId = channel.key;
      _live.programId = tuneResult.metadata.ratingKey;
      _live.durationMs = tuneResult.metadata.duration;

      // Reset time-shift state for new channel
      _live.captureBuffer = tuneResult.captureBuffer;
      _live.programBeginsAt = tuneResult.beginsAt;
      _live.markStreamRestartedAtLiveEdge();

      if (!mounted) return;
      _setPlayerState(() {
        _live.channelIndex = newIndex;
        _live.channelName = channel.displayName;
        _live.sessionIdentifier = tuneResult.sessionIdentifier;
        _live.sessionPath = tuneResult.sessionPath;
      });

      // Restart timeline heartbeats for the new session
      _startLiveTimelineUpdates();
    } catch (e) {
      appLogger.e('Failed to switch channel', error: e);
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      _playbackTransition = _PlaybackTransition.idle;
    }
  }

  bool get _hasNextChannel {
    final channels = widget.live?.channels;
    return channels != null && _live.channelIndex >= 0 && _live.channelIndex < channels.length - 1;
  }

  bool get _hasPreviousChannel => widget.live?.channels != null && _live.channelIndex > 0;
}
