part of '../../video_player_screen.dart';

extension _VideoPlayerWatchTogetherMethods on VideoPlayerScreenState {
  /// Whether an active Watch Together session owns playback starts: media is
  /// opened paused and the sync layer coordinates the (group) start.
  bool _watchTogetherOwnsPlaybackStart() {
    if (_isOfflinePlayback || widget.isLive) return false;
    return _activeWatchTogetherSession() != null;
  }

  /// Attach player to Watch Together session for playback sync.
  ///
  /// [startupHold] delays sync readiness until platform startup gates (e.g.
  /// the Android frame-rate switch) release.
  void _attachToWatchTogetherSession({Future<void>? startupHold}) {
    try {
      final watchTogether = context.read<WatchTogetherProvider>();
      _watchTogetherProvider = watchTogether; // Store reference for use in dispose
      final serverId = _currentMetadata.serverId;
      if (watchTogether.isInSession && player != null && serverId != null) {
        watchTogether.attachPlayer(
          player!,
          ratingKey: _currentMetadata.id,
          serverId: serverId,
          mediaTitle: _currentMetadata.displayTitle,
          hasFirstFrame: _hasFirstFrame.value,
          startupHold: startupHold,
          // Sync-issued seeks ride the screen's seek path so Plex transcode
          // restarts keep working for out-of-buffer targets.
          remoteSeek: _seekPlayback,
        );
        appLogger.d('WatchTogether: Player attached for sync');

        // If guest, handle mediaSwitch internally for proper navigation context
        if (!watchTogether.isHost) {
          watchTogether.onPlayerMediaSwitched = _handlePlayerMediaSwitch;
        }
      }
    } catch (e) {
      // Watch together provider not available or not in session - non-critical
      appLogger.d('Could not attach player to watch together', error: e);
    }
  }

  /// Detach player from Watch Together session (the user is leaving the
  /// player, which ends the shared media epoch).
  void _detachFromWatchTogetherSession() {
    try {
      final watchTogether = _watchTogetherProvider ?? context.read<WatchTogetherProvider>();
      if (watchTogether.isInSession) {
        watchTogether.detachPlayer(exiting: true);
        appLogger.d('WatchTogether: Player detached');
      }
      watchTogether.onPlayerMediaSwitched = null; // Always clear player callback
    } catch (e) {
      // Non-critical
      appLogger.d('Could not detach player from watch together', error: e);
    }
  }

  /// The active Watch Together session, or null when not in one (or the
  /// provider is unavailable).
  WatchTogetherProvider? _activeWatchTogetherSession() {
    try {
      final watchTogether = _watchTogetherProvider ?? context.read<WatchTogetherProvider>();
      return watchTogether.isInSession ? watchTogether : null;
    } catch (_) {
      return null;
    }
  }

  /// Check if episode navigation controls should be enabled
  /// Returns true if not in Watch Together session, or if user is the host
  bool _canNavigateEpisodes() {
    if (_watchTogetherProvider == null) return true;
    if (!_watchTogetherProvider!.isInSession) return true;
    return _watchTogetherProvider!.isHost;
  }

  /// Notify watch together session of current media change (host only)
  /// If [metadata] is provided, uses that instead of _currentMetadata (for episode navigation)
  void _notifyWatchTogetherMediaChange({MediaItem? metadata}) {
    final targetMetadata = metadata ?? _currentMetadata;
    try {
      final watchTogether = context.read<WatchTogetherProvider>();
      if (watchTogether.isHost && watchTogether.isInSession) {
        watchTogether.setCurrentMedia(
          ratingKey: targetMetadata.id,
          serverId: ServerId(targetMetadata.serverId!),
          mediaTitle: targetMetadata.displayTitle,
        );
      }
    } catch (e) {
      // Watch together provider not available or not in session - non-critical
      appLogger.d('Could not notify watch together of media change', error: e);
    }
  }

  void _notifyWatchTogetherSeek(Duration position) {
    try {
      final watchTogether = context.read<WatchTogetherProvider>();
      if (watchTogether.isInSession) {
        // Sync manager applies canControl checks; matching play/pause avoids timing gaps.
        watchTogether.onLocalSeek(position);
      }
    } catch (e) {
      appLogger.d('Could not notify watch together of seek', error: e);
    }
  }

  /// Handle media switch from host (guest only) using the in-place reload path.
  Future<void> _handlePlayerMediaSwitch(String ratingKey, ServerId serverId, String title) async {
    if (!mounted) return;

    appLogger.d('WatchTogether: Guest handling media switch to $title');

    // Fetch metadata for the new episode. WatchTogether's sync transport is
    // backend-neutral (sync_message.dart carries `ratingKey` + `serverId`
    // over WebRTC); resolving the item is just a `fetchItem` on whichever
    // backend the guest has registered for [serverId].
    final multiServer = context.read<MultiServerProvider>();
    final client = multiServer.getClientForServer(serverId);
    if (client == null) {
      appLogger.w('WatchTogether: Server $serverId not found for media switch');
      if (mounted) showAppSnackBar(context, t.watchTogether.guestSwitchUnavailable);
      return;
    }

    final metadata = await client.fetchItem(ratingKey);
    if (!mounted) return;
    if (metadata == null) {
      appLogger.w('WatchTogether: Could not fetch metadata for $ratingKey');
      showAppSnackBar(context, t.watchTogether.guestSwitchFailed);
      return;
    }

    if (player == null || widget.isLive) {
      unawaited(_replaceScreenWithPlayer(metadata));
      return;
    }

    final handled = await _reloadMediaInPlace(
      metadata: metadata,
      selectedMediaIndex: await savedMediaVersionIndexFor(metadata) ?? 0,
      selectedMediaSourceId: null,
      qualityPreset: _selectedQualityPreset,
      preserveCurrentTrackSelection: false,
      useCurrentAudioStreamSelection: false,
      reason: 'watch together media switch',
    );
    if (!handled && mounted && player == null) {
      unawaited(_replaceScreenWithPlayer(metadata));
    }
  }
}
