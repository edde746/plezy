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
    final session = _live.session;
    if (session == null) return;
    // For live TV, player position/duration are unreliable (often 0). Use
    // elapsed wall-clock as the position and the program duration from tune
    // metadata; the per-backend session owns the wire mapping.
    final playbackTime = _live.playbackStartTime != null
        ? DateTime.now().difference(_live.playbackStartTime!).inMilliseconds
        : 0;

    try {
      final updatedBuffer = await session.reportTimeline(
        state: state,
        positionMs: playbackTime,
        durationMs: session.program.durationMs ?? 0,
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
    return client.liveTv.startPlayback(channel.key, dvrKey: serverInfo.dvrKey);
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
    final session = _live.session;
    if (session == null) {
      appLogger.w('Cannot retry live stream — no session');
      showGlobalErrorSnackBar(_redactPlayerError(_lastLogError ?? t.liveTv.liveStreamFailed));
      unawaited(_handleBackButton());
      return;
    }

    final ds = _live.fallbackLevel < 1;
    final dsa = _live.fallbackLevel < 2;
    appLogger.i('Retrying live stream: directStream=$ds directStreamAudio=$dsa');

    final recovered = await session.recover(directStream: ds, directStreamAudio: dsa);
    if (!mounted || player != currentPlayer) return;
    final streamUrl = recovered == null ? null : await recovered.streamUrlAt();
    if (!mounted || player != currentPlayer) return;
    if (recovered == null || streamUrl == null) {
      showGlobalErrorSnackBar(_redactPlayerError(_lastLogError ?? t.liveTv.liveStreamFailed));
      unawaited(_handleBackButton());
      return;
    }

    _live.adoptSession(recovered);
    _live.markStreamRestartedAtLiveEdge();

    await _setLiveStreamOptions(currentPlayer);
    await currentPlayer.open(Media(streamUrl, headers: const {'Accept-Language': 'en'}), play: true, isLive: true);
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

  /// Seek the live TV stream to an absolute epoch second by rebuilding the
  /// stream at the target offset. The session returns null when the backend
  /// can't time-shift (Jellyfin), and its capture buffer is null there too,
  /// so both guards cover it.
  Future<void> _seekLivePosition(int targetEpochSeconds) async {
    final currentPlayer = player;
    if (currentPlayer == null) return;
    final session = _live.session;
    final buffer = _live.captureBuffer;
    if (session == null || buffer == null) return;

    final clamped = targetEpochSeconds.clamp(buffer.seekableStartEpoch, buffer.seekableEndEpoch);
    final offsetSeconds = clamped - buffer.startedAt.round();

    final streamUrl = await session.streamUrlAt(offsetSeconds: offsetSeconds);
    if (streamUrl == null || !mounted || player != currentPlayer) return;

    _live.streamStartEpoch = buffer.startedAt + offsetSeconds;
    _live.atLiveEdge = (clamped >= buffer.seekableEndEpoch - VideoPlayerScreenState._liveEdgeThresholdSeconds);
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

    LiveTvPlaybackSession? session;
    try {
      // Channel switch IS a fresh start: same resolution path as launch.
      session = await _startLiveSession(channel);
      if (session == null) return;
      if (!mounted || player != currentPlayer) {
        _abandonLiveSession(session);
        return;
      }

      final streamUrl = await session.streamUrlAt();
      if (streamUrl == null || !mounted || player != currentPlayer) {
        _abandonLiveSession(session);
        return;
      }

      await _setLiveStreamOptions(currentPlayer);
      await currentPlayer.open(Media(streamUrl, headers: const {'Accept-Language': 'en'}), play: true, isLive: true);

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
