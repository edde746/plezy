part of '../../video_player_screen.dart';

extension _VideoPlayerEpisodeNavigationMethods on VideoPlayerScreenState {
  void _clearEpisodeLoadingFlags() {
    if (!_isLoadingNext && !_isLoadingPrevious) return;
    _setPlayerState(() {
      _isLoadingNext = false;
      _isLoadingPrevious = false;
    });
  }

  /// Old screen-swap parity: after an in-place item change (or its failed
  /// rollback), surface the chrome and re-anchor focus on play/pause. The
  /// control that drove the swap (next button, queue item, play-next prompt)
  /// may have unmounted or unfocused by now — without a fresh route's
  /// autofocus, dpad navigation would be stranded until the chrome is hidden
  /// and re-shown. Focusing play/pause is invisible in pointer mode (focus
  /// visuals are keyboard/dpad-gated).
  void _showChromeForSwappedItem() {
    if (!mounted) return;
    _chromeController.show(focusPlayPause: true);
  }

  Future<void> _playNext() async {
    if (!_canNavigateMediaItems()) return;
    if (!mounted) return;
    if (_nextEpisode == null || _isLoadingNext) return;

    // EOF-driven advances (prompt confirm, auto-play countdown, PiP) run with
    // the completion latch set; a mid-episode Next press does not. Captured
    // before the prompt state below is cleared — a transiently failed advance
    // from EOF re-presents the Play Next prompt instead of parking on the
    // finished episode's last frame (#1867).
    final wasAtCompletion = _completionLatch.triggered;

    _autoPlayTimer?.cancel();
    _unfocusPlayNextPrompt();
    _dismissStillWatching();

    _notifyWatchTogetherMediaChange(metadata: _nextEpisode);

    _setPlayerState(() {
      _isLoadingNext = true;
      _showPlayNextDialog = false;
    });

    final outcome = await _navigateToEpisode(_nextEpisode!);
    if (outcome == _MediaReloadOutcome.failed) {
      _presentPlayNextRetryPrompt(wasAtCompletion: wasAtCompletion);
    }
  }

  Future<void> _playPrevious() async {
    if (!_canNavigateMediaItems()) return;
    if (_previousEpisode == null || _isLoadingPrevious) return;

    _notifyWatchTogetherMediaChange(metadata: _previousEpisode);

    _setPlayerState(() {
      _isLoadingPrevious = true;
    });

    await _navigateToEpisode(_previousEpisode!);
  }

  Future<void> _restartOrPlayPrevious() async {
    if (!_canNavigateMediaItems()) return;
    final currentPlayer = player;
    if (!mounted || currentPlayer == null || _isLoadingPrevious) return;

    if (!shouldRestartBeforePreviousItem(currentPlayer.state.position) && _previousEpisode != null) {
      await _playPrevious();
      return;
    }

    _autoPlayTimer?.cancel();
    _unfocusPlayNextPrompt();
    _dismissStillWatching();

    _setPlayerState(() {
      _showPlayNextDialog = false;
      _completionLatch.reset();
    });

    final target = clampSeekPosition(currentPlayer, Duration.zero);
    await _seekPlayback(target);
    if (!mounted || currentPlayer != player) return;

    _notifyWatchTogetherSeek(target);
    _mediaControls.pushPlaybackState();
  }

  /// Replace this screen with a fresh player route — the fallback for flows
  /// the in-place reload cannot serve. Marks the screen as being replaced so
  /// dispose skips the app-level player-exit side effects the replacement
  /// route takes over (WT host-exit notify, sleep timer, system UI restore,
  /// display mode).
  Future<void> _replaceScreenWithPlayer(MediaItem metadata) async {
    _isReplacingWithVideo = true; // before any await — dispose can run mid-helper
    try {
      await navigateToVideoPlayer(
        context,
        metadata: metadata,
        usePushReplacement: true,
        isOffline: _offlineLibraryMode,
      );
    } finally {
      // Still mounted ⇒ no push happened (external-player branch or a
      // throw): this screen stays, so restore normal-exit semantics.
      if (mounted) {
        _isReplacingWithVideo = false;
        _clearEpisodeLoadingFlags();
      }
    }
  }

  /// Navigates to a new episode by reusing the current player whenever possible.
  ///
  /// Returns the reload outcome so [_playNext] can distinguish a failed
  /// in-place swap (previous session still on screen) from rejected or
  /// superseded attempts. The screen-replacement fallback reports
  /// [_MediaReloadOutcome.rejected]: no in-place reload ran.
  Future<_MediaReloadOutcome> _navigateToEpisode(MediaItem episodeMetadata) async {
    _lastMediaReloadFailureReason = null;
    final currentPlayer = player;
    if (currentPlayer == null) {
      if (mounted) unawaited(_replaceScreenWithPlayer(episodeMetadata));
      return _MediaReloadOutcome.rejected;
    }

    // Callers fire this without awaiting (auto-play countdown, PiP, the prompt), so an escaping
    // throw would be an unhandled async error that also strands the loading flag set by
    // _playNext — which then silently disables item navigation for the rest of the session.
    try {
      // Carry the playing version to the next episode by signature — its Media
      // list may order versions differently, so the bare index is a guess and
      // the source id is per-episode.
      final currentVersionSignature =
          _effectiveSelectedMediaIndex >= 0 && _effectiveSelectedMediaIndex < _availableVersions.length
          ? _availableVersions[_effectiveSelectedMediaIndex].signature
          : null;
      // Users who curate per-episode selections server-side (e.g. via Plex Auto
      // Languages) opt out of carrying tracks across episodes entirely: with no
      // preferences, both audio and subtitles start at the server-selected
      // priority (#1717).
      final settingsService = await SettingsService.getInstance();
      final followServerSelections = settingsService.read(SettingsService.followServerTrackSelections);
      final committedSubtitleSelection = _playbackSession?.subtitleSelection;
      final primarySubtitlePreference = followServerSelections
          ? null
          : subtitlePreferenceForItemChange(
              hasCommittedSelection: committedSubtitleSelection != null,
              committedTrack: committedSubtitleSelection?.primaryTrack,
              nativeTrack: currentPlayer.state.track.subtitle,
              declinedPreference: committedSubtitleSelection?.declinedPreference,
              sessionPreference: _sessionSubtitlePreference,
            );
      final secondarySubtitlePreference = followServerSelections
          ? null
          : subtitlePreferenceForItemChange(
              hasCommittedSelection: committedSubtitleSelection != null,
              committedTrack: committedSubtitleSelection?.secondaryTrack,
              nativeTrack: currentPlayer.state.track.secondarySubtitle,
              sessionPreference: _sessionSecondarySubtitlePreference,
            );
      return await _reloadMediaInPlace(
        metadata: episodeMetadata,
        selectedMediaIndex: _effectiveSelectedMediaIndex,
        selectedMediaSourceId: null,
        preferredVersionSignature: currentVersionSignature,
        qualityPreset: _selectedQualityPreset,
        // Stream ids are per-part: the previous episode's audio id is
        // meaningless on the new item, so let preferences pick the track.
        useCurrentAudioStreamSelection: false,
        preserveCurrentTrackSelection: !followServerSelections,
        preservedAudioTrack: _sessionAudioPreference,
        preservedSubtitleTrack: primarySubtitlePreference,
        preservedSecondarySubtitleTrack: secondarySubtitlePreference,
        reason: 'episode navigation',
      );
    } catch (e, stackTrace) {
      appLogger.e('Failed to navigate to the next item', error: e, stackTrace: stackTrace);
      _clearEpisodeLoadingFlags();
      if (mounted) showErrorSnackBar(context, t.messages.errorLoading(error: e.toString()));
      return _MediaReloadOutcome.failed;
    }
  }
}
