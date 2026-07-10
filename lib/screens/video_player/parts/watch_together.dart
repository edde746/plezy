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

  /// Handle media switch from host (guest only) using the in-place reload
  /// path. Returns whether the switch was handled; unhandled switches are
  /// re-dispatched on the host's next state heartbeat.
  Future<bool> _handlePlayerMediaSwitch(String ratingKey, ServerId serverId, String title) async {
    if (!mounted) return false;
    final switchKey = '$serverId:$ratingKey';

    // Idempotent retry: already on the target with a settled player. Don't
    // test identity mid-transition — _currentMetadata is set eagerly at
    // reload start and can roll back on failure.
    if (_playbackTransition == _PlaybackTransition.idle &&
        player != null &&
        _currentMetadata.id == ratingKey &&
        _currentMetadata.serverId == serverId) {
      _wtSwitchToastShownForKey = null;
      return true;
    }

    appLogger.d('WatchTogether: Guest handling media switch to $title');

    // Fetch metadata for the new episode. WatchTogether's sync transport is
    // backend-neutral (sync_message.dart carries `ratingKey` + `serverId`
    // over WebRTC); resolving the item is just a `fetchItem` on whichever
    // backend the guest has registered for [serverId].
    final multiServer = context.read<MultiServerProvider>();
    final client = multiServer.getClientForServer(serverId);
    if (client == null) {
      appLogger.w('WatchTogether: Server $serverId not found for media switch');
      _showSwitchFailureToastOnce(switchKey, t.watchTogether.guestSwitchUnavailable);
      return false;
    }

    MediaItem? metadata;
    try {
      metadata = await client.fetchItem(ratingKey);
    } catch (e, stackTrace) {
      appLogger.w('WatchTogether: Could not fetch metadata for $ratingKey', error: e, stackTrace: stackTrace);
    }
    if (!mounted) return false;
    if (metadata == null) {
      appLogger.w('WatchTogether: Could not fetch metadata for $ratingKey');
      _showSwitchFailureToastOnce(switchKey, t.watchTogether.guestSwitchFailed);
      return false;
    }

    // The fetch can outlive the dispatch that requested it (slow server,
    // host switching again, dispatcher timeout); reloading then would swap
    // the live screen to stale media. Unhandled: the current key rides the
    // next heartbeat.
    final watchTogether = _activeWatchTogetherSession();
    if (watchTogether == null ||
        watchTogether.currentMediaRatingKey != ratingKey ||
        watchTogether.currentMediaServerId != serverId) {
      appLogger.d('WatchTogether: Skipping stale media switch to $ratingKey');
      return false;
    }

    if (player == null || widget.isLive) {
      // Route replacement: report handled at initiation — the navigation
      // future only completes when the pushed route pops.
      unawaited(_replaceScreenWithPlayer(metadata));
      return true;
    }

    // fetchItem populates mediaVersions, so the saved preference resolves to
    // a verified index/id here rather than a raw stored index.
    final savedVersion = await resolveSavedMediaVersionFor(metadata);
    final handled = await _reloadMediaInPlace(
      metadata: metadata,
      selectedMediaIndex: savedVersion?.index ?? 0,
      selectedMediaSourceId: savedVersion?.sourceId,
      preferredVersionSignature: savedVersion?.signature,
      qualityPreset: _selectedQualityPreset,
      preserveCurrentTrackSelection: false,
      useCurrentAudioStreamSelection: false,
      showErrorUi: false, // the retry loop owns user feedback (once per key)
      reason: 'watch together media switch',
    );
    if (!mounted) return false;
    if (!handled) {
      if (player == null) {
        unawaited(_replaceScreenWithPlayer(metadata));
        return true;
      }
      // Busy transition (e.g. auto-advance racing the host switch) — not an
      // error; the next heartbeat re-dispatches and converges once idle.
      return false;
    }
    // handled==true also covers "reload failed after rollback" and
    // "superseded by a newer attempt" — trust only the committed identity.
    final onTarget = _currentMetadata.id == ratingKey && _currentMetadata.serverId == serverId;
    if (onTarget) {
      // A success ends the failure episode for this key; a later failure to
      // switch back here must toast again.
      _wtSwitchToastShownForKey = null;
    } else {
      _showSwitchFailureToastOnce(switchKey, t.watchTogether.guestSwitchFailed);
    }
    return onTarget;
  }

  /// Toast a Watch Together switch failure at most once per media key (the
  /// heartbeat retry loop calls the handler every few seconds).
  void _showSwitchFailureToastOnce(String switchKey, String message) {
    if (_wtSwitchToastShownForKey == switchKey) return;
    _wtSwitchToastShownForKey = switchKey;
    if (mounted) showAppSnackBar(context, message);
  }
}
