part of '../../video_player_screen.dart';

/// The player's side of Watch Together: one [PlezyPlayerAdapter] per file the
/// player opened, handed to the room, and the user's presses routed to the
/// room while it drives this player.
extension _VideoPlayerWatchTogetherMethods on VideoPlayerScreenState {
  /// The room, when this user is in one and this screen can take part: Live
  /// TV never does.
  WatchTogetherProvider? _watchTogetherRoom() {
    final watchTogether = _watchTogetherProvider;
    if (widget.isLive || watchTogether == null || !watchTogether.isInSession) return null;
    return watchTogether;
  }

  /// The room, while it drives this screen's player.
  WatchTogetherProvider? _followedRoom() {
    final watchTogether = _watchTogetherProvider;
    final adapter = _wtAdapter;
    if (watchTogether == null || adapter == null || !watchTogether.follows(adapter)) return null;
    return watchTogether;
  }

  /// The room starts this open, so it opens paused: a host's file waits for
  /// everyone once shared, and a guest's for the room.
  bool _watchTogetherOwnsPlaybackStart() {
    final room = _watchTogetherRoom();
    if (room == null || !room.isConnected) return false;
    if (room.isHost) return _roomCanGetOpenedFile();
    return _wtRoomOpen || _followedRoom() != null;
  }

  /// Whether the room can get the file the player has open: a stream, or a
  /// download of a server that is online now. A download is the server's
  /// file, so the room shares the server's copy of it.
  bool _roomCanGetOpenedFile() => !_isOfflinePlayback || _getOnlineMediaServerClient(context) != null;

  /// The room sets the rate, not the item's remembered speed.
  bool _watchTogetherOwnsPlaybackRate() => _watchTogetherOwnsPlaybackStart();

  /// Without control of a room that drives this player, presses do nothing.
  bool _canControlPlayback() => !_shuttingDown && (_followedRoom()?.canControl ?? true);

  /// Another item replaces the room's media for everyone: host only.
  bool _canNavigateMediaItems() => !_shuttingDown && (_followedRoom()?.isHost ?? true);

  /// Registers this screen as the player the room switches and closes.
  void _registerWithWatchTogether() {
    final watchTogether = _watchTogetherProvider;
    if (watchTogether == null) return;
    watchTogether.registerPlayer(
      this,
      WatchPlayerHooks(openInPlace: _openRoomCopyInPlace, exitPlayer: _exitPlayerForRoom),
    );
  }

  /// The file the player has open, as the room knows it. A room's copy that
  /// names this item without a version (the server listed none when it was
  /// found) stands for whichever version opened. A download's session lists
  /// no versions; the item's own list names the one on disk.
  WatchCopy? _openedWatchCopy() {
    if (widget.isLive) return null;
    final session = _playbackSession;
    final metadata = session?.metadata ?? _currentMetadata;
    if (metadata.serverId == null) return null;
    final sessionVersions = session?.availableVersions ?? const <MediaVersion>[];
    final versions = sessionVersions.isNotEmpty ? sessionVersions : metadata.mediaVersions ?? const <MediaVersion>[];
    final index = session?.mediaIndex ?? -1;
    final sourceId = session?.mediaSourceId;
    final version = index >= 0 && index < versions.length
        ? versions[index]
        : versions.where((v) => sourceId != null && v.id == sourceId).firstOrNull;
    final opened = WatchCopy.of(metadata, version);
    final roomRef = _watchTogetherProvider?.roomCopy?.ref;
    if (roomRef != null &&
        roomRef.serverId == opened.serverId &&
        roomRef.itemId == opened.itemId &&
        (roomRef.versionId.isEmpty || opened.versionId.isEmpty)) {
      return roomRef;
    }
    return opened;
  }

  /// The room's commands act on the player directly; none of them may come
  /// back to the room as the user's press.
  PlayerCommands _watchTogetherCommands(Player currentPlayer) => PlayerCommands(
    play: () async {
      if (!automotivePlaybackAllowedNow()) throw StateError('playback is restricted while driving');
      await _playWithPlaybackIntent(currentPlayer);
    },
    pause: () => _pauseWithPlaybackIntent(currentPlayer),
    seek: (position) => _performSeekPlayback(position),
    setRate: (rate) => currentPlayer.setRate(rate),
  );

  /// Hands the file the player just committed to the room. The adapter of an
  /// earlier open of the same file in the same player stays (a quality or
  /// track reload); any other open gets a new one. [startupHold] keeps the
  /// room waiting while the screen still prepares the file.
  void _bindWatchTogether({Future<void>? startupHold}) {
    final watchTogether = _watchTogetherProvider;
    final currentPlayer = player;
    final roomOpen = _wtRoomOpen;
    _wtRoomOpen = false;
    if (watchTogether == null || currentPlayer == null || _shuttingDown) return;
    final copy = _openedWatchCopy();
    final previous = _wtAdapter;
    if (copy == null) {
      if (previous != null) {
        _wtAdapter = null;
        unawaited(watchTogether.playerClosed(previous, continuing: true));
      }
      return;
    }
    if (previous != null && identical(previous.player, currentPlayer) && previous.copy == copy) {
      if (startupHold != null) previous.hold(startupHold);
      watchTogether.playerChanged(previous);
      return;
    }
    final adapter = PlezyPlayerAdapter(
      player: currentPlayer,
      copy: copy,
      commands: _watchTogetherCommands(currentPlayer),
    );
    if (startupHold != null) adapter.hold(startupHold);
    _wtAdapter = adapter;
    watchTogether.playerOpened(adapter, shareable: _roomCanGetOpenedFile(), roomLaunch: roomOpen);
  }

  /// Keeps the room waiting until [until] completes: the player is busy with
  /// the file (a reload, a display-mode switch), and the room's commands wait
  /// for it.
  void _holdWatchTogether(Future<void> until) => _wtAdapter?.hold(until);

  /// Runs [body], which drives the player itself (the display measurement,
  /// the hold around a display switch), with the room held off so it neither
  /// counts the player ready nor commands it meanwhile.
  Future<void> _withWatchTogetherHeld(Future<void> Function() body) {
    final done = Completer<void>();
    _holdWatchTogether(done.future);
    return Future<void>.sync(body).whenComplete(done.complete);
  }

  /// The player is going away; a host's media stops for everyone unless
  /// [continuing]. Completes once the room no longer commands the player.
  Future<void> _releaseWatchTogether({required bool continuing}) {
    final watchTogether = _watchTogetherProvider;
    final adapter = _wtAdapter;
    _wtAdapter = null;
    _wtRoomOpen = false;
    if (watchTogether == null) return Future<void>.value();
    watchTogether.unregisterPlayer(this);
    if (adapter != null) _wtReleased = watchTogether.playerClosed(adapter, continuing: continuing);
    // A car's restriction and the background belonged to this player (its
    // resume never comes once it closed); the next one starts fresh.
    watchTogether.setVehicleRestricted(false);
    watchTogether.setBackgrounded(false);
    return _wtReleased ?? Future<void>.value();
  }

  /// The file failed to play for good. The room stops commanding this
  /// player and counting on it: it would seek the dead file every couple of
  /// seconds and hold everyone for it. The room keeps its media, so the user
  /// can join again from the Watch Together screen; a retry binds anew.
  void _detachWatchTogetherAfterFailure() {
    final watchTogether = _watchTogetherProvider;
    final adapter = _wtAdapter;
    _wtAdapter = null;
    _wtRoomOpen = false;
    if (watchTogether == null || adapter == null) return;
    _wtReleased = watchTogether.playerClosed(adapter, continuing: true);
  }

  /// A user's play, pause or toggle. While the room drives this player, the
  /// press goes to the room, which then commands the player.
  Future<void> _transportIntent(Player currentPlayer, TransportCommand command) {
    final room = _followedRoom();
    if (room != null) {
      final play = switch (command) {
        TransportCommand.play => true,
        TransportCommand.pause => false,
        TransportCommand.toggle => !currentPlayer.state.playing,
      };
      if (play ? room.play() : room.pause()) {
        _playbackIntentShouldPlay = play;
        return Future<void>.value();
      }
    }
    return switch (command) {
      TransportCommand.play => _playWithPlaybackIntent(currentPlayer),
      TransportCommand.pause => _pauseWithPlaybackIntent(currentPlayer),
      TransportCommand.toggle => _playOrPauseWithPlaybackIntent(currentPlayer),
    };
  }

  /// Applies a user-chosen rate. While the room drives this player the room
  /// takes it, and everyone plays at it. Every deliberate rate change (speed
  /// sheet, keyboard, long-press 2x, media controls) goes through here.
  Future<void> _setPlaybackRate(double rate) {
    final currentPlayer = player;
    if (!mounted || currentPlayer == null) return Future<void>.value();
    if (_followedRoom()?.setRate(rate) == true) return Future<void>.value();
    final generation = _transitionGate.generation;
    final operation = ++_userRateOperation;
    final previous = _userRateMutation;
    final mutation = () async {
      await previous.catchError((Object error) {
        appLogger.w('Previous playback rate change failed', error: error);
      });
      if (!_isCurrentPlaybackGeneration(generation, currentPlayer) || operation != _userRateOperation) return;
      await currentPlayer.setRate(rate);
    }();
    _userRateMutation = mutation;
    return mutation;
  }

  /// The room switches this player to [copy]: in place, or by replacing the
  /// screen when it can't reload (Live TV, no player yet) or plays from the
  /// offline library, which opens downloads only. Returns whether the file
  /// is opening; the room binds it once it opened.
  Future<bool> _openRoomCopyInPlace(WatchCopy copy) async {
    if (!mounted || _shuttingDown) return false;
    if (_wtAdapter?.copy == copy) return true;
    final metadata = copy.item ?? await _fetchRoomItem(copy);
    if (metadata == null || !mounted || _shuttingDown) return false;
    if (_watchTogetherProvider?.roomCopy?.ref != copy) return false;
    appLogger.d('WatchTogether: opening the room\'s file ${metadata.displayTitle}');
    if (player == null || widget.isLive || _offlineLibraryMode) {
      unawaited(_replaceScreenWithPlayer(metadata, watchTogetherCopy: copy));
      return true;
    }
    // An auto-advance or another reload may still hold the player.
    await _transitionGate.waitForIdle(() => mounted && !_shuttingDown);
    if (!mounted || _shuttingDown || _watchTogetherProvider?.roomCopy?.ref != copy) return false;
    final version = _versionOf(metadata, copy);
    _wtRoomOpen = true;
    final outcome = await _reloadMediaInPlace(
      metadata: metadata,
      selectedMediaIndex: version?.index ?? 0,
      selectedMediaSourceId: version?.sourceId,
      qualityPreset: _selectedQualityPreset,
      preserveCurrentTrackSelection: false,
      useCurrentAudioStreamSelection: false,
      showErrorUi: false,
      reason: 'watch together media switch',
    );
    if (!mounted) return false;
    if (outcome == MediaReloadOutcome.rejected && player == null) {
      _wtRoomOpen = false;
      unawaited(_replaceScreenWithPlayer(metadata, watchTogetherCopy: copy));
      return true;
    }
    if (outcome != MediaReloadOutcome.opened) _wtRoomOpen = false;
    return outcome == MediaReloadOutcome.opened;
  }

  Future<MediaItem?> _fetchRoomItem(WatchCopy copy) async {
    final client = context.read<MultiServerProvider>().getClientForServer(ServerId(copy.serverId));
    if (client == null) return null;
    try {
      return await client.fetchItem(copy.itemId);
    } catch (e, stackTrace) {
      appLogger.w('WatchTogether: could not fetch ${copy.itemId}', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// The index and source id of [copy]'s version among [metadata]'s.
  ({int index, String? sourceId})? _versionOf(MediaItem metadata, WatchCopy copy) =>
      watchTogetherVersionOf(metadata, copy);

  /// The room stopped the media this guest followed: close the player.
  void _exitPlayerForRoom() {
    if (!mounted || _shuttingDown) return;
    appLogger.d('WatchTogether: the room stopped its media; leaving the player');
    unawaited(_exitPlayerRoute(navigateHome: false));
  }

  /// Pauses for something the environment forced on this user alone (a car
  /// that forbids video). While the room drives this player, the room stops
  /// waiting for this user instead of pausing for everyone, and catches the
  /// player up once [VideoPlayerScreenState._handleCarRestrictionsChanged]
  /// or the app's return lifts it. Returns whether the room owns the resume.
  Future<bool> _pauseWithoutDisturbingTheRoom(Player currentPlayer) async {
    final room = _followedRoom();
    room?.setVehicleRestricted(true);
    await _pauseWithPlaybackIntent(currentPlayer);
    return room != null;
  }
}
