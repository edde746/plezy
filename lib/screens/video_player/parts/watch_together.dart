part of '../../video_player_screen.dart';

extension _VideoPlayerWatchTogetherMethods on VideoPlayerScreenState {
  /// Whether an active Watch Together session owns playback starts: media is
  /// opened paused and the sync layer coordinates the (group) start.
  bool _watchTogetherOwnsPlaybackStart() {
    if (_isOfflinePlayback || widget.isLive) return false;
    return _activeWatchTogetherSession() != null;
  }

  /// Active room rate wins over saved item preferences after explicit selection.
  bool _watchTogetherOwnsPlaybackRate() => !_isOfflinePlayback && _activeWatchTogetherSession() != null;

  /// Bind only a committed open and retain its session/output ownership for disposal.
  void _attachToWatchTogetherSession({required WatchPlaybackLease lease, Future<void>? startupHold}) {
    final watchTogether = _activeWatchTogetherSession();
    final currentPlayer = player;
    final metadata = _playbackSession?.metadata ?? _currentMetadata;
    final serverId = metadata.serverId;
    if (watchTogether == null ||
        currentPlayer == null ||
        serverId == null ||
        !watchTogether.isPlaybackLeaseCurrent(lease)) {
      return;
    }
    _watchTogetherProvider = watchTogether;
    final generation = _transitionGate.generation;
    final bindingLease = watchTogether.capturePlaybackLease()!;
    _watchTogetherLease = bindingLease;
    watchTogether.onPlayerMediaSwitched = _handlePlayerMediaSwitch;
    _watchTogetherBinding = watchTogether.bindPlayer(
      currentPlayer,
      ratingKey: metadata.id,
      serverId: serverId,
      mediaTitle: metadata.displayTitle,
      hasFirstFrame: _firstFrame.uiReady.value,
      startupHold: startupHold,
      lease: bindingLease,
      remoteSeek: (target) async {
        if (!_isCurrentPlaybackGeneration(generation, currentPlayer) ||
            !watchTogether.isPlaybackLeaseCurrent(bindingLease)) {
          throw StateError('Watch Together seek source was superseded');
        }
        final commandLease = watchTogether.capturePlaybackLease(selection: true)!;
        await _performSeekPlayback(target, isCurrent: () => watchTogether.isPlaybackLeaseCurrent(commandLease));
      },
    );
  }

  void _detachFromWatchTogetherSession({required bool exiting}) {
    final watchTogether = _watchTogetherProvider;
    final binding = _watchTogetherBinding;
    if (watchTogether == null) return;
    if (binding != null) {
      if (!watchTogether.ownsBinding(binding)) return;
      if (exiting) {
        watchTogether.endMedia(expectedBinding: binding);
      } else {
        watchTogether.unbindPlayer(expectedBinding: binding);
      }
    } else if (exiting &&
        !watchTogether.hasAttachedPlayer &&
        watchTogether.isPlaybackLeaseCurrent(_watchTogetherLease)) {
      // The room can adopt media before this route has opened any output.
      watchTogether.endMedia();
    }
    if (watchTogether.onPlayerMediaSwitched == _handlePlayerMediaSwitch) {
      watchTogether.onPlayerMediaSwitched = null;
    }
  }

  /// The active Watch Together session, or null when not in one (or the
  /// provider is unavailable).
  WatchTogetherProvider? _activeWatchTogetherSession() {
    try {
      final watchTogether = _watchTogetherProvider ?? context.read<WatchTogetherProvider>();
      final lease = _watchTogetherLease ?? widget.watchTogetherLease;
      if (lease != null && !watchTogether.isSamePlaybackSession(lease)) return null;
      return watchTogether.isInSession ? watchTogether : null;
    } catch (_) {
      return null;
    }
  }

  /// Playback intent is guest-controllable only when the active room permits
  /// it. Outside a room, the local screen remains authoritative.
  bool _canControlPlayback() => _activeWatchTogetherSession()?.canControl() ?? true;

  /// Choosing another queue item or episode is host-only in every room mode.
  bool _canNavigateMediaItems() => _activeWatchTogetherSession()?.isHost ?? true;

  void _commitWatchTogetherSelection(
    WatchTogetherProvider? watchTogether,
    WatchPlaybackLease? lease,
    MediaItem metadata,
    Duration position,
  ) {
    if (watchTogether == null || lease == null || !lease.canSelect || metadata.serverId == null) return;
    watchTogether.selectMedia(
      ratingKey: metadata.id,
      serverId: ServerId(metadata.serverId!),
      mediaTitle: metadata.displayTitle,
      position: position,
      rate: ScopedPlayerPrefs.resolve(ScopedPlayerPrefs.playbackSpeed, metadata),
      lease: lease,
    );
  }

  /// Apply a user-chosen playback rate and declare it to an active Watch
  /// Together room. Every deliberate rate change (speed sheet, keyboard,
  /// long-press 2x, media controls) goes through here; the sync layer never
  /// infers rate intent from the player's own rate stream.
  Future<void> _setPlaybackRate(double rate) {
    final currentPlayer = player;
    if (!mounted || currentPlayer == null) return Future<void>.value();
    final generation = _transitionGate.generation;
    final operation = ++_userRateOperation;
    final watchTogether = _activeWatchTogetherSession();
    final lease = watchTogether?.capturePlaybackLease(selection: watchTogether.isHost);
    watchTogether?.onLocalRate(rate);
    final previous = _userRateMutation;
    final mutation = () async {
      await previous.catchError((Object error) {
        appLogger.w('Previous playback rate change failed', error: error);
      });
      if (!_isCurrentPlaybackGeneration(generation, currentPlayer) ||
          operation != _userRateOperation ||
          (lease != null && !lease.isCurrent)) {
        return;
      }
      await currentPlayer.setRate(rate);
    }();
    _userRateMutation = mutation;
    return mutation;
  }

  /// Handle media switch from host (guest only) using the in-place reload
  /// path. Returns whether the switch was handled; unhandled switches are
  /// re-dispatched on the host's next state heartbeat.
  Future<bool> _handlePlayerMediaSwitch(String ratingKey, ServerId serverId, String title) async {
    if (!mounted) return false;
    final watchTogether = _activeWatchTogetherSession();
    final lease = watchTogether?.capturePlaybackLease();
    if (watchTogether == null || lease == null) return false;
    final switchKey = '$serverId:$ratingKey';

    // Idempotent retry: already on the target with a settled player. Don't
    // test identity mid-transition — _currentMetadata is set eagerly at
    // reload start and can roll back on failure.
    if (_transitionGate.transition == PlaybackTransition.idle &&
        player != null &&
        watchTogether.hasAttachedPlayer &&
        _watchTogetherBinding != null &&
        watchTogether.ownsBinding(_watchTogetherBinding!) &&
        (_playbackSession?.metadata ?? _currentMetadata).id == ratingKey &&
        (_playbackSession?.metadata ?? _currentMetadata).serverId == serverId) {
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
    if (!mounted || !watchTogether.isPlaybackLeaseCurrent(lease)) return false;
    if (metadata == null) {
      appLogger.w('WatchTogether: Could not fetch metadata for $ratingKey');
      _showSwitchFailureToastOnce(switchKey, t.watchTogether.guestSwitchFailed);
      return false;
    }

    // The fetch can outlive the dispatch that requested it (slow server,
    // host switching again, dispatcher timeout); reloading then would swap
    // the live screen to stale media. Unhandled: the current key rides the
    // next heartbeat.
    if (watchTogether.currentMediaRatingKey != ratingKey || watchTogether.currentMediaServerId != serverId) {
      appLogger.d('WatchTogether: Skipping stale media switch to $ratingKey');
      return false;
    }

    if (player == null || widget.isLive) {
      // Route replacement: report handled at initiation — the navigation
      // future only completes when the pushed route pops.
      unawaited(_replaceScreenWithPlayer(metadata, watchTogetherLease: lease));
      return true;
    }

    // fetchItem populates mediaVersions, so the saved preference resolves to
    // a verified index/id here rather than a raw stored index.
    final savedVersion = await resolveSavedMediaVersionFor(metadata);
    if (!mounted || !watchTogether.isPlaybackLeaseCurrent(lease)) return false;
    final outcome = await _reloadMediaInPlace(
      metadata: metadata,
      selectedMediaIndex: savedVersion?.index ?? 0,
      selectedMediaSourceId: savedVersion?.sourceId,
      preferredVersionSignature: savedVersion?.signature,
      qualityPreset: _selectedQualityPreset,
      preserveCurrentTrackSelection: false,
      useCurrentAudioStreamSelection: false,
      showErrorUi: false, // the retry loop owns user feedback (once per key)
      watchTogetherLease: lease,
      reason: 'watch together media switch',
    );
    if (!mounted || !watchTogether.isPlaybackLeaseCurrent(lease)) return false;
    if (outcome == MediaReloadOutcome.rejected) {
      if (player == null) {
        unawaited(_replaceScreenWithPlayer(metadata, watchTogetherLease: lease));
        return true;
      }
      // Busy transition (e.g. auto-advance racing the host switch) — not an
      // error; the next heartbeat re-dispatches and converges once idle.
      return false;
    }
    // failed (after rollback) and superseded land here too — trust only the
    // committed identity.
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
