part of '../../video_player_screen.dart';

extension _VideoPlayerLiveTvMethods on VideoPlayerScreenState {
  /// Start periodic timeline heartbeats for live TV transcode session.
  void _startLiveTimelineUpdates() {
    final generation = ++_liveTimelineGeneration;
    _liveTimelineTimer?.cancel();
    _liveTimelineTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (generation != _liveTimelineGeneration) return;
      final state = player?.state.playing == true ? 'playing' : 'paused';
      _sendLiveTimeline(state);
    });
    // Delay initial heartbeat to let the transcode session stabilize.
    // Sending time=0 immediately after player.open() causes the server
    // to spawn a duplicate transcode job with offset=-1 that 404s.
    Future.delayed(const Duration(seconds: 3), () {
      if (_liveTimelineTimer != null && generation == _liveTimelineGeneration) {
        final state = player?.state.playing == true ? 'playing' : 'paused';
        _sendLiveTimeline(state);
      }
    });
  }

  void _stopLiveTimelineUpdates() {
    _liveTimelineGeneration++;
    _liveTimelineTimer?.cancel();
    _liveTimelineTimer = null;
  }

  Future<void> _sendLiveTimeline(String state) async {
    final client = _liveClient;
    final playbackTime = _livePlaybackStartTime != null
        ? DateTime.now().difference(_livePlaybackStartTime!).inMilliseconds
        : 0;

    if (client is PlexClient) {
      final sessionId = _liveSessionIdentifier;
      final sessionPath = _liveSessionPath;
      if (sessionId == null || sessionPath == null) return;
      try {
        // Use the program ratingKey from tune metadata, not the channel key
        final ratingKey = _liveProgramId ?? _liveItemId ?? widget.metadata.id;
        // For live TV, player position/duration are unreliable (often 0).
        // Use playbackTime as time, and program duration from tune metadata.
        // Plex rejects timeline pings where time > duration; grow duration to
        // match — otherwise Tunarr-style short synthetic programs 400 mid-stream.
        final time = playbackTime;
        final duration = max(_liveDurationMs ?? 0, time);
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
            _captureBuffer = updatedBuffer;
            _isAtLiveEdge =
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
      await _jellyfinLiveSession.report(
        client: client,
        itemId: _liveItemId ?? widget.metadata.id,
        state: state,
        position: Duration(milliseconds: playbackTime),
        duration: Duration(milliseconds: _liveDurationMs ?? 0),
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
    final client = _liveClient;
    final ds = _liveStreamFallbackLevel < 1;
    final dsa = _liveStreamFallbackLevel < 2;

    if (client is PlexClient) {
      final channels = widget.liveChannels;
      final channelIndex = _liveChannelIndex;
      final dvrKey = _liveDvrKey;
      if (channels == null || channelIndex < 0 || channelIndex >= channels.length || dvrKey == null) {
        appLogger.w('Cannot retry live stream — missing session info');
        showGlobalErrorSnackBar(_redactPlayerError(_lastLogError ?? 'Live stream failed'));
        unawaited(_handleBackButton());
        return;
      }
      final channel = channels[channelIndex];
      appLogger.i('Retrying live stream (re-tune ${channel.key}): directStream=$ds directStreamAudio=$dsa');

      // Re-tune to get a fresh capture session — the previous one is dead.
      final tuneResult = await client.tuneChannel(dvrKey, channel.key);
      if (tuneResult == null || !mounted) {
        showGlobalErrorSnackBar(_redactPlayerError(_lastLogError ?? 'Live stream failed'));
        unawaited(_handleBackButton());
        return;
      }

      _liveSessionIdentifier = tuneResult.sessionIdentifier;
      _liveSessionPath = tuneResult.sessionPath;
      _transcodeSessionId = generateSessionIdentifier();

      final streamPath = await client.buildLiveStreamPath(
        sessionPath: tuneResult.sessionPath,
        sessionIdentifier: tuneResult.sessionIdentifier,
        transcodeSessionId: _transcodeSessionId!,
        directStream: ds,
        directStreamAudio: dsa,
      );
      if (streamPath == null || !mounted) {
        showGlobalErrorSnackBar(_redactPlayerError(_lastLogError ?? 'Live stream failed'));
        unawaited(_handleBackButton());
        return;
      }

      final streamUrl = client.buildLiveStreamUrl(streamPath);
      _liveStreamUrl = streamUrl;
      _livePlaybackStartTime = DateTime.now();
      _streamStartEpoch = DateTime.now().millisecondsSinceEpoch / 1000.0;
      _isAtLiveEdge = true;

      await _setLiveStreamOptions();
      await player!.open(Media(streamUrl, headers: const {'Accept-Language': 'en'}), play: true, isLive: true);
      return;
    }

    final liveStreamUrl = _liveStreamUrl;
    if (client is JellyfinClient && liveStreamUrl != null) {
      appLogger.i('Retrying Jellyfin live stream by re-opening URL');
      _livePlaybackStartTime = DateTime.now();
      _streamStartEpoch = DateTime.now().millisecondsSinceEpoch / 1000.0;
      _isAtLiveEdge = true;
      await _setLiveStreamOptions();
      await player!.open(Media(liveStreamUrl, headers: const {'Accept-Language': 'en'}), play: true, isLive: true);
      return;
    }

    appLogger.w('Cannot retry live stream — no compatible client/URL available');
    showGlobalErrorSnackBar(_redactPlayerError(_lastLogError ?? 'Live stream failed'));
    unawaited(_handleBackButton());
  }

  /// Configure MPV options for live streaming.
  /// The official Plex Media Player does not set client-side reconnect options —
  /// reconnection is handled by the server's transcoder on the input side.
  Future<void> _setLiveStreamOptions() async {
    await player!.setProperty('force-seekable', 'no');
  }

  /// The current playback position as an absolute epoch second (for live TV time-shift).
  int get _currentPositionEpoch => (_streamStartEpoch + (player?.state.position.inSeconds ?? 0)).round();

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
    if (_captureBuffer == null ||
        _liveSessionPath == null ||
        _liveSessionIdentifier == null ||
        _transcodeSessionId == null) {
      return;
    }

    final clamped = targetEpochSeconds.clamp(_captureBuffer!.seekableStartEpoch, _captureBuffer!.seekableEndEpoch);

    final offsetSeconds = clamped - _captureBuffer!.startedAt.round();

    // Live seek requires a transcode session — Plex-only by protocol. The
    // Plex path populates _captureBuffer; the Jellyfin path never does, so
    // the early-return above already covers Jellyfin in practice. This
    // explicit guard keeps the contract obvious.
    final client = _liveClient;
    if (client is! PlexClient) return;

    final streamPath = await client.buildLiveStreamPath(
      sessionPath: _liveSessionPath!,
      sessionIdentifier: _liveSessionIdentifier!,
      transcodeSessionId: _transcodeSessionId!,
      offsetSeconds: offsetSeconds,
    );
    if (streamPath == null || !mounted) return;

    final streamUrl = client.buildLiveStreamUrl(streamPath);

    _streamStartEpoch = _captureBuffer!.startedAt + offsetSeconds;
    _isAtLiveEdge = (clamped >= _captureBuffer!.seekableEndEpoch - VideoPlayerScreenState._liveEdgeThresholdSeconds);
    _livePlaybackStartTime = DateTime.now();

    await _setLiveStreamOptions();
    await player!.open(Media(streamUrl, headers: const {'Accept-Language': 'en'}), play: true, isLive: true);
    if (mounted) _setPlayerState(() {});
  }

  /// Jump to the live edge of the capture buffer.
  Future<void> _jumpToLiveEdge() async {
    if (_captureBuffer == null) return;
    await _seekLivePosition(_captureBuffer!.seekableEndEpoch);
  }

  Future<void> _switchLiveChannel(int delta) async {
    final channels = widget.liveChannels;
    if (channels == null || channels.isEmpty) return;
    if (_isSwitchingChannel) return; // debounce concurrent switches

    final newIndex = _liveChannelIndex + delta;
    if (newIndex < 0 || newIndex >= channels.length) return;

    _isSwitchingChannel = true;

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

      final genericClient = multiServer.getClientForServer(serverInfo.serverId);
      final resolution = await genericClient?.liveTv.resolveStreamUrl(channel.key, dvrKey: serverInfo.dvrKey);
      if (resolution != null) {
        // Jellyfin: pre-resolved negotiated URL.
        await _setLiveStreamOptions();
        await player!.open(Media(resolution.url, headers: const {'Accept-Language': 'en'}), play: true, isLive: true);
        _liveClient = genericClient;
        _liveDvrKey = serverInfo.dvrKey;
        _liveStreamUrl = resolution.url;
        _liveItemId = channel.key;
        _liveSessionIdentifier = resolution.playSessionId;
        _jellyfinLiveSession = JellyfinLiveSessionTracker(playSessionId: resolution.playSessionId);
        _livePlaybackStartTime = DateTime.now();
        _captureBuffer = null;
        _programBeginsAt = null;
        _liveProgramId = null;
        _liveDurationMs = null;
        _streamStartEpoch = DateTime.now().millisecondsSinceEpoch / 1000.0;
        _isAtLiveEdge = true;
        if (!mounted) return;
        _setPlayerState(() {
          _liveChannelIndex = newIndex;
          _liveChannelName = channel.displayName;
        });
        _startLiveTimelineUpdates();
        return;
      }

      // Plex-only: DVR tune flow (Jellyfin Live TV uses pre-resolved URLs).
      final client = multiServer.getPlexClientForServer(serverInfo.serverId);
      if (client == null) return;

      final tuneResult = await client.tuneChannel(serverInfo.dvrKey, channel.key);
      if (tuneResult == null || !mounted) return;

      _transcodeSessionId = generateSessionIdentifier();
      _liveStreamFallbackLevel = 0;

      final streamPath = await client.buildLiveStreamPath(
        sessionPath: tuneResult.sessionPath,
        sessionIdentifier: tuneResult.sessionIdentifier,
        transcodeSessionId: _transcodeSessionId!,
      );
      if (streamPath == null || !mounted) return;

      final streamUrl = client.buildLiveStreamUrl(streamPath);

      await _setLiveStreamOptions();
      await player!.open(Media(streamUrl, headers: const {'Accept-Language': 'en'}), play: true, isLive: true);

      _liveClient = client;
      _liveDvrKey = serverInfo.dvrKey;
      _liveStreamUrl = streamUrl;
      _liveItemId = channel.key;
      _livePlaybackStartTime = DateTime.now();
      _liveProgramId = tuneResult.metadata.ratingKey;
      _liveDurationMs = tuneResult.metadata.duration;

      // Reset time-shift state for new channel
      _captureBuffer = tuneResult.captureBuffer;
      _programBeginsAt = tuneResult.beginsAt;
      _streamStartEpoch = DateTime.now().millisecondsSinceEpoch / 1000.0;
      _isAtLiveEdge = true;

      if (!mounted) return;
      _setPlayerState(() {
        _liveChannelIndex = newIndex;
        _liveChannelName = channel.displayName;
        _liveSessionIdentifier = tuneResult.sessionIdentifier;
        _liveSessionPath = tuneResult.sessionPath;
      });

      // Restart timeline heartbeats for the new session
      _startLiveTimelineUpdates();
    } catch (e) {
      appLogger.e('Failed to switch channel', error: e);
      if (mounted) showErrorSnackBar(context, e.toString());
    } finally {
      _isSwitchingChannel = false;
    }
  }

  bool get _hasNextChannel =>
      widget.isLive &&
      widget.liveChannels != null &&
      _liveChannelIndex >= 0 &&
      _liveChannelIndex < (widget.liveChannels!.length - 1);

  bool get _hasPreviousChannel => widget.isLive && widget.liveChannels != null && _liveChannelIndex > 0;
}
