part of '../../video_player_screen.dart';

/// Subtitle/audio cycling for companion-remote and keyboard shortcuts.
/// Stays on the State: the drain loop coalesces queued presses into
/// [_switchPlaybackSource] reopens and is bound to the transition lease.
extension _VideoPlayerCompanionRemoteMethods on VideoPlayerScreenState {
  void _cycleSubtitleTrack() {
    final sourceTracks = _sourceSubtitleTracksForControls();
    if (!_isOfflinePlayback && sourceTracks.isNotEmpty) {
      _pendingSubtitleCycleCount++;
      if (!_subtitleCycleDrainActive) unawaited(_drainSubtitleCycles());
      return;
    }
    _cycleSubtitleTrackNatively();
  }

  /// Cycle through the native track list, for playback with no source
  /// catalog to advance through (downloads, and items whose server exposes no
  /// subtitle rows).
  ///
  /// The manager owns the selection and the server write-back; the committed
  /// choice is this screen's, and the episode carry-over reads it, so a cycle
  /// that lands on Off has to be recorded here or the next episode inherits
  /// the choice this one started with.
  void _cycleSubtitleTrackNatively() {
    final cycled = _trackManager?.cycleSubtitleTrack();
    if (cycled != null) _rememberNativeSubtitleSelection(cycled);
  }

  Future<void> _drainSubtitleCycles() async {
    if (_subtitleCycleDrainActive) return;
    _subtitleCycleDrainActive = true;
    try {
      while (mounted && (_pendingSubtitleCycleCount > 0 || _pendingSubtitleTargetChoice != null)) {
        await _transitionGate.waitForIdle(() => mounted);
        if (!mounted) break;
        final requestedChoice = _pendingSubtitleTargetChoice;
        if (requestedChoice == null && _pendingSubtitleCycleCount == 0) break;

        // Collapse every press queued before this dispatch into one target.
        // Presses arriving during the reopen remain queued for the next pass.
        final advances = _pendingSubtitleCycleCount;
        final sourceTracks = _sourceSubtitleTracksForControls();
        if (_isOfflinePlayback || sourceTracks.isEmpty) {
          // No source catalog to switch within: an explicit request has
          // nothing to resolve against, and presses fall back to the player.
          _pendingSubtitleTargetChoice = null;
          _pendingSubtitleCycleCount -= advances;
          for (var i = 0; i < advances; i++) {
            _cycleSubtitleTrackNatively();
          }
          continue;
        }
        // An explicit track request supersedes queued cycling: the controller
        // named a destination, so advancing past it would undo the request.
        final currentChoice =
            _selectedSourceSubtitleChoiceForControls(sourceTracks) ?? const PlaybackSourceSubtitleChoice.off();
        final targetChoice =
            requestedChoice ?? PlaybackSubtitleResolver.advanceSourceChoice(sourceTracks, currentChoice, advances);
        final outcome = await _switchPlaybackSource(newSubtitleChoice: targetChoice);
        if (outcome == PlaybackSourceChangeOutcome.busy) {
          await _transitionGate.waitForIdle(() => mounted);
          continue;
        }
        // A newer request may have replaced ours while the switch was in
        // flight; only retire the one this pass actually applied.
        if (identical(_pendingSubtitleTargetChoice, requestedChoice)) _pendingSubtitleTargetChoice = null;
        if (requestedChoice == null) _pendingSubtitleCycleCount -= advances;
      }
    } finally {
      _subtitleCycleDrainActive = false;
    }
  }

  void _cycleAudioTrack() => _trackManager?.cycleAudioTrack();
}

/// Companion remote commands beyond the base [CompanionRemoteBinding] slots.
/// They live on the State because each reaches into player, track and screen
/// internals.
extension _VideoPlayerCompanionCommandMethods on VideoPlayerScreenState {
  /// Call right after `_companionRemote.bind()`.
  void _installCompanionCommandSlots() {
    final receiver = CompanionRemoteReceiver.instance;
    receiver.onPlay = () => unawaited(_remoteTransport(TransportCommand.play, source: 'Companion remote'));
    receiver.onPause = () => unawaited(_remoteTransport(TransportCommand.pause, source: 'Companion remote'));
    receiver.onPlayPause = () => unawaited(_remoteTransport(TransportCommand.toggle, source: 'Companion remote'));
    receiver.onSkipIntro = () => unawaited(_skipToMarker(credits: false));
    receiver.onSkipCredits = () => unawaited(_skipToMarker(credits: true));
    receiver.onSeekTo = (positionMs) {
      if (player == null) return;
      unawaited(player!.seek(Duration(milliseconds: positionMs)));
    };
    receiver.onVolumeSet = (volume) {
      final p = player;
      final controller = _volumeController;
      if (p == null || controller == null || !controller.ownsPlayer(p)) return;
      controller.commit(volume);
    };
    receiver.onSetSubtitleTrack = _selectSubtitleFromCriteria;
    receiver.onSetAudioTrack = _selectAudioFromCriteria;
    receiver.onSetQuality = _selectQualityFromCriteria;
    receiver.onSetAudioDevice = _selectAudioDeviceFromCriteria;
    receiver.onSetSubtitleSync = (criteria) => unawaited(_applySyncOffset('sub-delay', criteria));
    receiver.onSetAudioSync = (criteria) => unawaited(_applySyncOffset('audio-delay', criteria));
    receiver.onSetSpeed = _setSpeedFromCriteria;
    receiver.onSetSecondarySubtitleTrack = _selectSecondarySubtitleFromCriteria;
    receiver.onSetZoom = _applyZoomFromCriteria;
    receiver.onCommandHandled = _notifyCompanionRemoteStateChanged;

    // The base binding sends the bare playerActive frame; this adds the
    // now-playing frame on a heartbeat.
    try {
      _companionRemoteProvider = context.read<CompanionRemoteProvider>();
      _companionNowPlayingTimer?.cancel();
      _companionNowPlayingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!mounted) return;
        unawaited(_refreshRemoteStateCache());
        _sendNowPlaying(active: true);
      });
    } catch (e) {
      appLogger.d('CompanionRemote provider unavailable', error: e);
    }
  }

  /// Mirrors [CompanionRemoteBinding.unbind]'s owner guard, so a replacement
  /// screen that already installed keeps its slots. Call right before
  /// `_companionRemote.unbind()`.
  void _removeCompanionCommandSlots() {
    _companionNowPlayingTimer?.cancel();
    _companionNowPlayingTimer = null;
    final receiver = CompanionRemoteReceiver.instance;
    if (!identical(receiver.playerOwner, _companionRemote)) {
      _companionRemoteProvider = null;
      return;
    }
    receiver.onPlay = null;
    receiver.onPause = null;
    receiver.onPlayPause = null;
    receiver.onSkipIntro = null;
    receiver.onSkipCredits = null;
    receiver.onSeekTo = null;
    receiver.onVolumeSet = null;
    receiver.onSetSubtitleTrack = null;
    receiver.onSetAudioTrack = null;
    receiver.onSetQuality = null;
    receiver.onSetAudioDevice = null;
    receiver.onSetSubtitleSync = null;
    receiver.onSetAudioSync = null;
    receiver.onSetSpeed = null;
    receiver.onSetSecondarySubtitleTrack = null;
    receiver.onSetZoom = null;
    receiver.onCommandHandled = null;
    _sendNowPlaying(active: false);
    _companionRemoteProvider = null;
  }

  void _selectSubtitleFromCriteria(Map<String, dynamic> criteria) {
    // Wait out any in-flight source switch, as _drainSubtitleCycles does: mid-
    // rebuild the loaded list is transient (often empty), so the request would
    // fall through to the source catalog and could land on the wrong sidecar.
    unawaited(_applySubtitleCriteria(criteria));
  }

  Future<void> _applySubtitleCriteria(Map<String, dynamic> criteria) async {
    await _transitionGate.waitForIdle(() => mounted);
    if (!mounted) return;
    final p = player;
    if (p == null) return;
    if (criteria['off'] == true) {
      unawaited(_applyPlayerSubtitleTrack(p, SubtitleTrack.off));
      return;
    }
    // Positional selection mirrors setAudioTrack, and is the only way to pick an
    // external track: its id embeds a credentialed URL, so syncState withholds it.
    final index = (criteria['index'] as num?)?.toInt();
    if (index != null) {
      final tracks = p.state.tracks.subtitle;
      if (index >= 0 && index < tracks.length) unawaited(_applyPlayerSubtitleTrack(p, tracks[index]));
      return;
    }
    final id = criteria['id'] as String?;
    final language = (criteria['language'] as String?)?.toLowerCase();
    final codec = (criteria['codec'] as String?)?.toLowerCase();
    final external = criteria['external'] as bool?;
    SubtitleTrack? match;
    for (final t in p.state.tracks.subtitle) {
      if (id != null) {
        if (t.id == id) {
          match = t;
          break;
        }
        continue;
      }
      if (language != null && !trackLanguageMatches(query: language, language: t.language, title: t.title)) {
        continue;
      }
      if (codec != null && !'${t.codec ?? ''} ${t.title ?? ''}'.toLowerCase().contains(codec)) continue;
      if (external != null && t.isExternal != external) continue;
      match = t;
      break;
    }
    if (match != null) {
      unawaited(_applyPlayerSubtitleTrack(p, match));
      return;
    }
    if (id == null) _selectSourceSubtitleFromCriteria(language: language, codec: codec, external: external);
  }

  Future<void> _applyPlayerSubtitleTrack(Player p, SubtitleTrack track) async {
    await p.selectSubtitleTrack(track);
    if (!mounted) return;
    await _onSubtitleTrackChanged(track);
  }

  void _selectSourceSubtitleFromCriteria({String? language, String? codec, bool? external}) {
    if (_isOfflinePlayback) return;
    final sourceTracks = _sourceSubtitleTracksForControls();
    if (sourceTracks.isEmpty) return;
    final choice = PlaybackSubtitleResolver.matchSourceChoice(
      sourceTracks,
      language: language,
      codec: codec,
      external: external,
    );
    if (choice == null) {
      appLogger.d('Companion remote: no subtitle track matches the requested criteria');
      return;
    }
    _pendingSubtitleTargetChoice = choice;
    if (!_subtitleCycleDrainActive) unawaited(_drainSubtitleCycles());
  }

  void _selectAudioFromCriteria(Map<String, dynamic> criteria) {
    final p = player;
    if (p == null) return;
    final tracks = p.state.tracks.audio;
    final id = criteria['id'] as String?;
    final language = (criteria['language'] as String?)?.toLowerCase();
    final index = (criteria['index'] as num?)?.toInt();
    AudioTrack? match;
    if (index != null && index >= 0 && index < tracks.length) {
      match = tracks[index];
    } else {
      for (final t in tracks) {
        if (id != null) {
          if (t.id == id) {
            match = t;
            break;
          }
          continue;
        }
        if (language != null && !trackLanguageMatches(query: language, language: t.language, title: t.title)) {
          continue;
        }
        match = t;
        break;
      }
    }
    final selected = match;
    if (selected == null) return;
    // Record it the way the on-screen picker does; selecting on the player
    // alone leaves the track manager's state behind.
    unawaited(() async {
      await p.selectAudioTrack(selected);
      if (mounted) await _onAudioTrackChanged(selected);
    }());
  }

  void _selectQualityFromCriteria(Map<String, dynamic> criteria) {
    if (player == null || _isOfflinePlayback) return;
    if (!_serverSupportsTranscoding) {
      appLogger.d('Companion remote: server does not support transcoding, ignoring setQuality');
      return;
    }
    final index = (criteria['index'] as num?)?.toInt();
    final order = TranscodeQualityPreset.displayOrder;
    TranscodeQualityPreset? preset;
    if (index != null) {
      if (index < 0 || index >= order.length) return;
      preset = order[index];
    } else {
      final query = criteria['quality'] as String?;
      if (query == null) return;
      preset = TranscodeQualityPreset.matchByName(query);
    }
    if (preset == null) {
      appLogger.d('Companion remote: no quality preset matches the requested criteria');
      return;
    }
    if (preset == _selectedQualityPreset) return;
    unawaited(_switchPlaybackSource(newPreset: preset));
  }

  void _selectAudioDeviceFromCriteria(Map<String, dynamic> criteria) {
    final p = player;
    if (p == null) return;
    if (criteria['auto'] == true) {
      unawaited(p.setAudioDevice(AudioDevice.auto));
      return;
    }
    final devices = p.state.audioDevices;
    final index = (criteria['index'] as num?)?.toInt();
    if (index != null) {
      if (index >= 0 && index < devices.length) unawaited(p.setAudioDevice(devices[index]));
      return;
    }
    final name = criteria['name'] as String?;
    if (name == null) return;
    final device = matchAudioDevice(name, devices);
    if (device == null) {
      appLogger.d('Companion remote: no audio device matches the requested name');
      return;
    }
    unawaited(p.setAudioDevice(device));
  }

  Future<void> _applySyncOffset(String property, Map<String, dynamic> criteria) async {
    final p = player;
    if (p == null) return;
    int? targetMs;
    if (criteria['reset'] == true) {
      targetMs = 0;
    } else if (criteria['offsetMs'] != null) {
      targetMs = (criteria['offsetMs'] as num).toInt();
    } else if (criteria['deltaMs'] != null) {
      final currentSeconds = double.tryParse(await p.getProperty(property) ?? '') ?? 0;
      targetMs = (currentSeconds * 1000).round() + (criteria['deltaMs'] as num).toInt();
    }
    if (targetMs == null) return;
    // Matches the settings sheet's own absolute limit.
    targetMs = targetMs.clamp(-VideoPlayerScreenState._syncOffsetLimitMs, VideoPlayerScreenState._syncOffsetLimitMs);
    await p.setProperty(property, (targetMs / 1000.0).toString());
  }

  void _setSpeedFromCriteria(Map<String, dynamic> criteria) {
    final p = player;
    if (p == null) return;
    double? target;
    if (criteria['reset'] == true) {
      target = 1.0;
    } else if (criteria['speed'] != null) {
      target = (criteria['speed'] as num).toDouble();
    } else if (criteria['delta'] != null) {
      // Read the live rate rather than caching one: the settings sheet and the
      // long-press-to-2x gesture both move it.
      target = p.state.rate + (criteria['delta'] as num).toDouble();
    }
    if (target == null) return;
    // Matches the settings sheet's own speed list bounds.
    unawaited(
      p.setRate(target.clamp(VideoPlayerScreenState._minPlaybackSpeed, VideoPlayerScreenState._maxPlaybackSpeed)),
    );
  }

  void _selectSecondarySubtitleFromCriteria(Map<String, dynamic> criteria) {
    final p = player;
    if (p == null) return;
    if (!p.supportsSecondarySubtitles) {
      appLogger.d('Companion remote: backend has no secondary subtitle support');
      return;
    }
    if (criteria['off'] == true) {
      unawaited(_applyPlayerSecondarySubtitleTrack(p, SubtitleTrack.off));
      return;
    }
    final tracks = p.state.tracks.subtitle;
    final index = (criteria['index'] as num?)?.toInt();
    if (index != null) {
      if (index >= 0 && index < tracks.length) {
        unawaited(_applyPlayerSecondarySubtitleTrack(p, tracks[index]));
      }
      return;
    }
    final language = (criteria['language'] as String?)?.toLowerCase();
    if (language == null) return;
    for (final t in tracks) {
      if (trackLanguageMatches(query: language, language: t.language, title: t.title)) {
        unawaited(_applyPlayerSecondarySubtitleTrack(p, t));
        return;
      }
    }
    appLogger.d('Companion remote: no loaded subtitle track matches the requested secondary criteria');
  }

  Future<void> _applyPlayerSecondarySubtitleTrack(Player p, SubtitleTrack track) async {
    await p.selectSecondarySubtitleTrack(track);
    if (!mounted) return;
    _onSecondarySubtitleTrackChanged(track);
  }

  void _applyZoomFromCriteria(Map<String, dynamic> criteria) {
    final filter = _videoFilterManager;
    if (filter == null) return;
    final fit = (criteria['fit'] as String?)?.toLowerCase();
    if (fit != null) {
      final mode = switch (fit) {
        'contain' => 0,
        'cover' => 1,
        'fill' => 2,
        _ => null,
      };
      if (mode == null) {
        appLogger.d('Companion remote: unknown fit mode requested');
        return;
      }
      filter.setBoxFitMode(mode);
      return;
    }
    if (criteria['reset'] == true) {
      filter.resetToContain();
      return;
    }
    // setZoomScale runs normalizeZoomScale, which already clamps to
    // [minZoomScale, maxZoomScale]; a second clamp here could only disagree.
    if (criteria['scale'] != null) {
      filter.setZoomScale((criteria['scale'] as num).toDouble());
    } else if (criteria['delta'] != null) {
      filter.setZoomScale(filter.zoomScale + (criteria['delta'] as num).toDouble());
    }
  }

  Future<void> _refreshRemoteStateCache() async {
    final p = player;
    if (p == null) return;
    final subtitle = double.tryParse(await p.getProperty('sub-delay') ?? '');
    final audio = double.tryParse(await p.getProperty('audio-delay') ?? '');
    if (!mounted) return;
    _subtitleSyncOffsetMs = subtitle == null ? null : (subtitle * 1000).round();
    _audioSyncOffsetMs = audio == null ? null : (audio * 1000).round();
    try {
      _maxVolumeForRemote = SettingsService.instance.read(SettingsService.maxVolume).toDouble();
    } catch (_) {
      // Settings not up yet; the next tick will carry it.
    }
  }

  Future<void> _skipToMarker({required bool credits}) async {
    final p = player;
    if (p == null || !mounted) return;
    final metadata = _currentMetadata;
    final serverId = metadata.serverId;
    final client = serverId != null ? context.tryGetMediaClientForServer(ServerId(serverId)) : null;
    final database = context.read<AppDatabase>();
    final extras = await VideoControlsPlaybackExtrasLoader(
      metadata: metadata,
      database: database,
      client: client,
    ).load();
    if (extras == null || !mounted) return;
    MediaMarker? target;
    for (final marker in extras.markers) {
      if (credits ? marker.isCredits : marker.type == 'intro') {
        target = marker;
        break;
      }
    }
    if (target == null) return;
    if (p.state.position < target.endTime) {
      unawaited(p.seek(target.endTime));
    }
  }

  void _notifyCompanionRemoteStateChanged() {
    if (_companionRemoteProvider == null) return;
    _companionStateDebounce?.cancel();
    // Long enough to collapse a pause/seek/resume flurry into one frame, short
    // enough that a controller sees the result as part of its round-trip.
    _companionStateDebounce = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;
      _sendNowPlaying(active: true);
    });
  }

  void _sendNowPlaying({required bool active}) {
    final provider = _companionRemoteProvider;
    // A host session reads as connected from server start, so only a present
    // controller means someone can receive this.
    if (provider == null || !provider.isHost || !provider.isConnected || provider.connectedDevice == null) return;
    // Commands are dropped until the player exists; naming the item earlier
    // invites a controller to send them into that gap.
    if (active && !_isPlayerInitialized) return;
    final p = player;
    final m = _currentMetadata;
    final audio = p?.state.tracks.audio ?? const <AudioTrack>[];
    final subtitle = p?.state.tracks.subtitle ?? const <SubtitleTrack>[];
    final audioId = p?.state.track.audio?.id;
    final subtitleId = p?.state.track.subtitle?.id;
    final secondarySubtitleId = p?.state.track.secondarySubtitle?.id;
    provider.sendCommand(
      RemoteCommandType.syncState,
      data: {
        'playerActive': active,
        // A source reopen rebuilds the track set, so the selected-track fields
        // below are transient until this clears.
        if (_transitionGate.transition != PlaybackTransition.idle) 'transitional': true,
        'serverId': m.serverId,
        'ratingKey': m.id,
        'title': m.title,
        'positionMs': p?.state.position.inMilliseconds ?? 0,
        'durationMs': p?.state.duration.inMilliseconds ?? 0,
        'paused': p == null ? true : !p.state.playing,
        // Absent for a movie.
        'showTitle': m.grandparentTitle,
        'seasonNumber': m.parentIndex,
        'episodeNumber': m.index,
        'year': m.year,
        'volume': p?.state.volume,
        'maxVolume': _maxVolumeForRemote,
        'muted': p == null ? null : p.state.volume <= 0,
        'speed': p?.state.rate,
        'buffering': p?.state.buffering,
        // setQuality only takes effect while the server transcodes.
        'transcoding': _isTranscoding,
        // Always false on mobile, which has no desktop window.
        'fullscreen': FullscreenStateManager().isFullscreen,
        // Ids that embed a credentialed URL are withheld; see track_payload.dart.
        'audioTracks': audioTracksPayload(audio),
        'subtitleTracks': subtitleTracksPayload(subtitle),
        'selectedAudioId': safeTrackId(audioId),
        'selectedSubtitleId': safeTrackId(subtitleId),
        'selectedAudioIndex': indexOfTrackId(audio.map((t) => t.id), audioId),
        'selectedSubtitleIndex': indexOfTrackId(subtitle.map((t) => t.id), subtitleId),
        'selectedSecondarySubtitleId': safeTrackId(secondarySubtitleId),
        'selectedSecondarySubtitleIndex': indexOfTrackId(subtitle.map((t) => t.id), secondarySubtitleId),
        // The track list is empty when the server burns an image subtitle into
        // a transcode; these still confirm a subtitle change then.
        'subtitleSourceId': _playbackSession?.subtitleSelection.primarySourceStreamId,
        'subtitleBurnedIn': _subtitleBurnedIn,
        'qualityPreset': _selectedQualityPreset.name,
        'audioDevice': p?.state.audioDevice.name,
        'audioDevices': [
          for (final d in p?.state.audioDevices ?? const <AudioDevice>[])
            {'name': d.name, if (d.description.isNotEmpty) 'description': d.description},
        ],
        'subtitleSyncMs': _subtitleSyncOffsetMs,
        'audioSyncMs': _audioSyncOffsetMs,
        'zoomScale': _videoFilterManager?.zoomScale,
        'boxFit': switch (_videoFilterManager?.boxFitMode) {
          0 => 'contain',
          1 => 'cover',
          2 => 'fill',
          _ => null,
        },
        // Absent when there is none — which is exactly how a controller knows
        // it has reached the end of a series.
        'nextEpisode': _episodeSummary(_episode.next),
        'previousEpisode': _episodeSummary(_episode.previous),
      },
    );
  }

  Map<String, dynamic>? _episodeSummary(MediaItem? episode) {
    if (episode == null) return null;
    return {
      'ratingKey': episode.id,
      'title': episode.title,
      'seasonNumber': episode.parentIndex,
      'episodeNumber': episode.index,
    };
  }
}
