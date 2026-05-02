part of '../../video_player_screen.dart';

extension _VideoPlayerWatchTogetherMethods on VideoPlayerScreenState {
  /// Attach player to Watch Together session for playback sync
  void _attachToWatchTogetherSession() {
    try {
      final watchTogether = context.read<WatchTogetherProvider>();
      _watchTogetherProvider = watchTogether; // Store reference for use in dispose
      if (watchTogether.isInSession && player != null) {
        watchTogether.attachPlayer(player!);
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

  /// Detach player from Watch Together session
  void _detachFromWatchTogetherSession() {
    try {
      final watchTogether = _watchTogetherProvider ?? context.read<WatchTogetherProvider>();
      if (watchTogether.isInSession) {
        watchTogether.detachPlayer();
        appLogger.d('WatchTogether: Player detached');
      }
      watchTogether.onPlayerMediaSwitched = null; // Always clear player callback
    } catch (e) {
      // Non-critical
      appLogger.d('Could not detach player from watch together', error: e);
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
          serverId: targetMetadata.serverId!,
          mediaTitle: targetMetadata.displayTitle,
        );
      }
    } catch (e) {
      // Watch together provider not available or not in session - non-critical
      appLogger.d('Could not notify watch together of media change', error: e);
    }
  }

  /// Handle media switch from host (guest only)
  /// Uses VideoPlayerScreen's context for proper navigation (pushReplacement)
  Future<void> _handlePlayerMediaSwitch(String ratingKey, String serverId, String title) async {
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

    // Detach and dispose current player before switching to avoid sync calls on a disposed instance
    _isReplacingWithVideo = true;
    await disposePlayerForNavigation();
    if (!mounted) return;

    // Use same navigation as local episode change (pushReplacement from player context)
    unawaited(navigateToVideoPlayer(context, metadata: metadata, usePushReplacement: true));
  }
}
