import 'dart:async';

import '../../mpv/mpv.dart';
import '../../utils/app_logger.dart';
import '../models/sync_message.dart';
import '../models/watch_session.dart';
import 'watch_together_peer_service.dart';

/// Callback type for when session configuration is received
typedef SessionConfigCallback = void Function(ControlMode controlMode);

/// Callback type for when sync state changes
typedef SyncStateCallback = void Function(bool isSyncing);

/// Manages playback synchronization between peers
///
/// This class:
/// - Subscribes to player stream events
/// - Broadcasts local playback actions to peers
/// - Applies remote playback actions to the local player
/// - Handles drift correction
class WatchTogetherSyncManager {
  final WatchTogetherPeerService _peerService;
  final String displayName;
  WatchSession _session;

  Player? _player;
  bool _isRemoteAction = false; // Flag to prevent echo
  bool _isSyncing = false; // Flag for UI indicator during sync

  // Stream subscriptions
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<bool>? _bufferingSubscription;
  StreamSubscription<double>? _rateSubscription;
  StreamSubscription<SyncMessage>? _messageSubscription;

  // Position sync timer (host broadcasts position periodically)
  Timer? _positionSyncTimer;

  // Drift correction constants
  static const Duration maxAllowedDrift = Duration(seconds: 2);
  static const Duration positionSyncInterval = Duration(seconds: 5);
  static const Duration excessiveDrift = Duration(seconds: 10);

  // Track last known state to avoid duplicate broadcasts
  bool _lastKnownPlaying = false;
  double _lastKnownRate = 1.0;

  // Track if we were playing before a peer started buffering (for auto-resume)
  bool _wasPlayingBeforeBuffering = false;

  // Position to seek to when auto-resuming deferred playback
  Duration? _pendingPlayPosition;

  // Whether we've announced our player as ready (first buffering: false)
  bool _hasAnnouncedReady = false;

  // Callbacks
  SessionConfigCallback? onSessionConfigReceived;
  SyncStateCallback? onSyncStateChanged;

  /// Participants' buffering states (peer ID -> isBuffering)
  final Map<String, bool> _participantBuffering = {};

  /// Participants' ready states (peer ID -> hasPlayerReady)
  final Map<String, bool> _participantReady = {};

  WatchTogetherSyncManager({
    required WatchTogetherPeerService peerService,
    required WatchSession session,
    required this.displayName,
  }) : _peerService = peerService,
       _session = session;

  /// Update the session (e.g., when control mode changes)
  void updateSession(WatchSession session) {
    _session = session;
    appLogger.d('WatchTogether: Sync manager session updated, controlMode: ${session.controlMode}');
  }

  /// Whether this manager has a player attached
  bool get hasPlayer => _player != null;

  /// Whether any participant (including local player) is currently buffering
  bool get isAnyBuffering => _participantBuffering.values.any((b) => b) || (_player?.state.buffering ?? false);

  /// Whether all participants have their player attached and ready
  /// Returns true if:
  /// - We're alone (no other peers tracked)
  /// - All tracked participants have sent playerReady(true)
  bool get isAllReady {
    // If no other peers are tracked, we're ready (solo viewing)
    if (_participantBuffering.isEmpty) {
      return true;
    }
    // All peers in _participantBuffering must also be in _participantReady with value true
    for (final peerId in _participantBuffering.keys) {
      final ready = _participantReady[peerId];
      if (ready != true) {
        return false; // Peer hasn't sent ready yet or sent ready(false)
      }
    }
    return true;
  }

  /// Whether sync is in progress (for UI indicator)
  bool get isSyncing => _isSyncing;

  /// Attach a player to sync
  void attachPlayer(Player player) {
    if (_player != null) {
      detachPlayer();
    }

    _player = player;
    _lastKnownPlaying = player.state.playing;
    _lastKnownRate = player.state.rate;

    _setupPlayerSubscriptions();
    _setupMessageSubscription();

    // If host, start broadcasting position periodically
    if (_session.isHost) {
      _startPositionSync();
      // Note: sessionConfig is sent after video loads (with correct position) in buffering handler
    }

    // Note: playerReady will be announced when video loads (first buffering: false)

    appLogger.d('WatchTogether: Player attached, isHost: ${_session.isHost}');
  }

  /// Initialize participant tracking from existing session participants
  /// Call this before attachPlayer() to ensure we know about participants who joined before
  void initializeParticipants(List<String> peerIds) {
    for (final peerId in peerIds) {
      if (peerId != _peerService.myPeerId) {
        // Assume they're buffering until they tell us otherwise
        _participantBuffering[peerId] = true;
        // They're not ready until they send playerReady
        _participantReady[peerId] = false;
      }
    }
    final otherCount = peerIds.where((id) => id != _peerService.myPeerId).length;
    appLogger.d('WatchTogether: Initialized $otherCount existing participants');
  }

  /// Detach the player and stop sync
  void detachPlayer() {
    // Announce that our player is no longer ready
    if (_peerService.myPeerId != null) {
      _peerService.broadcast(SyncMessage.playerReady(peerId: _peerService.myPeerId!, ready: false));
      _participantReady[_peerService.myPeerId!] = false;
    }
    _hasAnnouncedReady = false;

    _playingSubscription?.cancel();
    _positionSubscription?.cancel();
    _bufferingSubscription?.cancel();
    _rateSubscription?.cancel();
    _messageSubscription?.cancel();
    _positionSyncTimer?.cancel();

    _playingSubscription = null;
    _positionSubscription = null;
    _bufferingSubscription = null;
    _rateSubscription = null;
    _messageSubscription = null;
    _positionSyncTimer = null;

    _player = null;
    appLogger.d('WatchTogether: Player detached');
  }

  /// Set up subscriptions to player streams
  void _setupPlayerSubscriptions() {
    // Listen to playing state changes
    _playingSubscription = _player!.streams.playing.listen((isPlaying) async {
      if (_isRemoteAction) return; // Skip if this change was caused by a remote action

      if (isPlaying != _lastKnownPlaying) {
        _lastKnownPlaying = isPlaying;

        // If trying to play, check if all peers are ready first
        if (isPlaying && (!isAllReady || isAnyBuffering)) {
          appLogger.d('WatchTogether: Deferring local play - waiting for all peers to be ready');
          _wasPlayingBeforeBuffering = true;
          _pendingPlayPosition = _player?.state.position;
          _isRemoteAction = true;
          try {
            await _player!.pause();
            _lastKnownPlaying = false;
          } finally {
            _isRemoteAction = false;
          }
          // Still broadcast so peers know we want to play
          _broadcastPlayPause(true);
          return;
        }

        _broadcastPlayPause(isPlaying);
      }
    });

    // Listen to buffering state changes
    _bufferingSubscription = _player!.streams.buffering.listen((isBuffering) {
      if (_isRemoteAction) return;

      // Announce ready when we stop buffering for the first time (video loaded)
      if (!isBuffering && !_hasAnnouncedReady) {
        _hasAnnouncedReady = true;
        _participantReady[_peerService.myPeerId!] = true;
        _peerService.broadcast(SyncMessage.playerReady(peerId: _peerService.myPeerId!, ready: true));
        appLogger.d('WatchTogether: Video loaded, announcing player ready');

        // If host, send session config now that video is loaded with correct position
        if (_session.isHost) {
          _sendSessionConfig();
        }
      }

      _peerService.broadcast(SyncMessage.buffering(isBuffering, peerId: _peerService.myPeerId));
    });

    // Listen to rate changes
    _rateSubscription = _player!.streams.rate.listen((rate) {
      if (_isRemoteAction) return;

      if (rate != _lastKnownRate) {
        _lastKnownRate = rate;
        if (_canControl()) {
          _peerService.broadcast(SyncMessage.rate(rate, peerId: _peerService.myPeerId));
        }
      }
    });
  }

  /// Set up subscription to incoming sync messages
  void _setupMessageSubscription() {
    _messageSubscription = _peerService.onMessageReceived.listen(_handleMessage);
  }

  /// Start periodic position sync (host only)
  void _startPositionSync() {
    _positionSyncTimer?.cancel();
    _positionSyncTimer = Timer.periodic(positionSyncInterval, (_) {
      if (_player != null && _session.isHost) {
        _peerService.broadcast(SyncMessage.positionSync(_player!.state.position, peerId: _peerService.myPeerId));
      }
    });
  }

  /// Check if this peer can control playback
  bool _canControl() {
    if (_session.controlMode == ControlMode.anyone) {
      return true;
    }
    return _session.isHost;
  }

  /// Broadcast play/pause state
  void _broadcastPlayPause(bool isPlaying) {
    if (!_canControl()) {
      appLogger.d('WatchTogether: Cannot control playback in hostOnly mode');
      return;
    }

    if (isPlaying) {
      final position = _player?.state.position ?? Duration.zero;
      _peerService.broadcast(SyncMessage.play(peerId: _peerService.myPeerId, position: position));
    } else {
      _peerService.broadcast(SyncMessage.pause(peerId: _peerService.myPeerId));
    }
  }

  /// Called when user seeks locally
  void onLocalSeek(Duration position) {
    if (!_canControl()) {
      appLogger.d('WatchTogether: Cannot control playback in hostOnly mode');
      return;
    }

    _peerService.broadcast(SyncMessage.seek(position, peerId: _peerService.myPeerId));
  }

  /// Handle incoming sync messages
  void _handleMessage(SyncMessage message) async {
    // Ignore our own messages
    if (message.peerId == _peerService.myPeerId) {
      return;
    }

    // HOST RELAY: In "anyone" mode, host rebroadcasts control commands from guests
    // This is needed because guests only connect to host (star topology), not to each other
    if (_session.isHost && _session.controlMode == ControlMode.anyone) {
      final isControlMessage =
          message.type == SyncMessageType.play ||
          message.type == SyncMessageType.pause ||
          message.type == SyncMessageType.seek ||
          message.type == SyncMessageType.rate;

      if (isControlMessage) {
        appLogger.d('WatchTogether: Host relaying ${message.type} from ${message.peerId}');
        _peerService.broadcast(message);
      }
    }

    // In hostOnly mode, only process messages from host (unless it's join/leave/sessionConfig)
    if (_session.controlMode == ControlMode.hostOnly && !_session.isHost) {
      final isHostMessage = message.peerId == _session.hostPeerId;
      final isMetaMessage =
          message.type == SyncMessageType.join ||
          message.type == SyncMessageType.leave ||
          message.type == SyncMessageType.sessionConfig ||
          message.type == SyncMessageType.buffering ||
          message.type == SyncMessageType.ping ||
          message.type == SyncMessageType.pong ||
          message.type == SyncMessageType.mediaSwitch;

      if (!isHostMessage && !isMetaMessage) {
        appLogger.d('WatchTogether: Ignoring non-host message in hostOnly mode');
        return;
      }
    }

    switch (message.type) {
      case SyncMessageType.play:
        await _applyRemotePlay(position: message.position);
        break;

      case SyncMessageType.pause:
        _wasPlayingBeforeBuffering = false; // User intentionally paused, don't auto-resume
        await _applyRemotePause();
        break;

      case SyncMessageType.seek:
        if (message.position != null) {
          await _applyRemoteSeek(message.position!);
        }
        break;

      case SyncMessageType.buffering:
        if (message.peerId != null && message.bufferingState != null) {
          _participantBuffering[message.peerId!] = message.bufferingState!;

          // Auto-pause when any peer starts buffering
          if (isAnyBuffering && _player!.state.playing) {
            _wasPlayingBeforeBuffering = true;
            appLogger.d('WatchTogether: Peer buffering, pausing playback');
            await _applyRemotePause();
          }
          // Auto-resume when all peers stop buffering AND all ready (if we were playing before)
          else if (isAllReady && !isAnyBuffering && !_player!.state.playing && _wasPlayingBeforeBuffering) {
            _wasPlayingBeforeBuffering = false;
            appLogger.d('WatchTogether: All peers done buffering, resuming playback');
            await _applyRemotePlay(position: _pendingPlayPosition);
            _pendingPlayPosition = null;
          }
        }
        break;

      case SyncMessageType.positionSync:
        if (message.position != null) {
          _checkAndCorrectDrift(message.position!, message.timestamp);
        }
        break;

      case SyncMessageType.rate:
        if (message.rate != null) {
          await _applyRemoteRate(message.rate!);
        }
        break;

      case SyncMessageType.join:
        _handlePeerJoin(message);
        break;

      case SyncMessageType.leave:
        if (message.peerId != null) {
          _participantBuffering.remove(message.peerId);
          _participantReady.remove(message.peerId);
        }
        break;

      case SyncMessageType.sessionConfig:
        await _handleSessionConfig(message);
        break;

      case SyncMessageType.ping:
        if (message.pingId != null) {
          _peerService.broadcast(SyncMessage.pong(message.pingId!, peerId: _peerService.myPeerId));
        }
        break;

      case SyncMessageType.pong:
        // Could be used for latency measurement
        break;

      case SyncMessageType.mediaSwitch:
        // Handled at the provider level, not in sync manager
        break;

      case SyncMessageType.hostExitedPlayer:
        // Handled at the provider level, not in sync manager
        break;

      case SyncMessageType.playerReady:
        if (message.peerId != null) {
          _participantReady[message.peerId!] = message.bufferingState ?? false;
          appLogger.d('WatchTogether: Peer ${message.peerId} player ready: ${message.bufferingState}');

          // If we were waiting to play and all are now ready, start playback
          if (isAllReady && !isAnyBuffering && _wasPlayingBeforeBuffering) {
            _wasPlayingBeforeBuffering = false;
            appLogger.d('WatchTogether: All players ready, starting playback');
            await _applyRemotePlay(position: _pendingPlayPosition);
            _pendingPlayPosition = null;
          }
        }
        break;
    }
  }

  /// Apply remote play command
  Future<void> _applyRemotePlay({Duration? position}) async {
    if (_player == null) return;

    // If not all participants have their player ready, defer play
    if (!isAllReady) {
      appLogger.d('WatchTogether: Deferring play - waiting for all players to be ready');
      _wasPlayingBeforeBuffering = true;
      if (position != null) _pendingPlayPosition = position;
      return; // Will trigger when all players send playerReady
    }

    // If anyone is buffering, defer play until all ready
    if (isAnyBuffering) {
      appLogger.d('WatchTogether: Deferring play - waiting for all peers to stop buffering');
      _wasPlayingBeforeBuffering = true;
      if (position != null) _pendingPlayPosition = position;
      return; // Auto-resume will trigger when buffering clears
    }

    appLogger.d('WatchTogether: Applying remote PLAY${position != null ? ' at ${position.inSeconds}s' : ''}');
    _isRemoteAction = true;
    try {
      // Seek to position first if provided
      if (position != null) {
        await _player!.seek(position);
      }
      await _player!.play();
      _lastKnownPlaying = true;
    } on StateError catch (e) {
      appLogger.w('WatchTogether: Player disposed during remote PLAY', error: e);
      detachPlayer();
    } finally {
      _isRemoteAction = false;
    }
  }

  /// Apply remote pause command
  Future<void> _applyRemotePause() async {
    if (_player == null) return;

    appLogger.d('WatchTogether: Applying remote PAUSE');
    _isRemoteAction = true;
    try {
      await _player!.pause();
      _lastKnownPlaying = false;
    } on StateError catch (e) {
      appLogger.w('WatchTogether: Player disposed during remote PAUSE', error: e);
      detachPlayer();
    } finally {
      _isRemoteAction = false;
    }
  }

  /// Apply remote seek command
  Future<void> _applyRemoteSeek(Duration position) async {
    if (_player == null) return;

    appLogger.d('WatchTogether: Applying remote SEEK to ${position.inSeconds}s');
    _isRemoteAction = true;
    try {
      await _player!.seek(position);
    } on StateError catch (e) {
      appLogger.w('WatchTogether: Player disposed during remote SEEK', error: e);
      detachPlayer();
    } finally {
      _isRemoteAction = false;
    }
  }

  /// Apply remote rate change
  Future<void> _applyRemoteRate(double rate) async {
    if (_player == null) return;

    appLogger.d('WatchTogether: Applying remote RATE: $rate');
    _isRemoteAction = true;
    try {
      await _player!.setRate(rate);
      _lastKnownRate = rate;
    } on StateError catch (e) {
      appLogger.w('WatchTogether: Player disposed during remote RATE', error: e);
      detachPlayer();
    } finally {
      _isRemoteAction = false;
    }
  }

  /// Check and correct position drift
  void _checkAndCorrectDrift(Duration remotePosition, int remoteTimestamp) {
    if (_player == null || _session.isHost) return;

    final localPosition = _player!.state.position;
    final networkDelay = DateTime.now().millisecondsSinceEpoch - remoteTimestamp;

    // Estimate where remote should be now, accounting for playback time elapsed
    Duration estimatedRemoteNow = remotePosition;
    if (_player!.state.playing && networkDelay > 0) {
      // If playing, account for time elapsed during network transit
      // Multiply by rate in case playback speed is different
      estimatedRemoteNow = remotePosition + Duration(milliseconds: (networkDelay * _player!.state.rate).round());
    }

    final drift = (localPosition - estimatedRemoteNow).abs();

    if (drift > excessiveDrift) {
      // Excessive drift - force sync with indicator
      appLogger.w('WatchTogether: Excessive drift (${drift.inSeconds}s), force syncing');
      _setSyncing(true);
      _applyRemoteSeek(estimatedRemoteNow);
      Future.delayed(const Duration(milliseconds: 500), () => _setSyncing(false));
    } else if (drift > maxAllowedDrift) {
      // Normal drift correction
      appLogger.d('WatchTogether: Drift correction (${drift.inMilliseconds}ms)');
      _setSyncing(true);
      _applyRemoteSeek(estimatedRemoteNow);
      Future.delayed(const Duration(milliseconds: 300), () => _setSyncing(false));
    }
  }

  /// Handle peer join message
  void _handlePeerJoin(SyncMessage message) {
    appLogger.d('WatchTogether: Peer joined: ${message.displayName}');

    // Assume new peer is buffering and not ready until they explicitly signal
    if (message.peerId != null) {
      _participantBuffering[message.peerId!] = true;
      _participantReady[message.peerId!] = false;
    }

    // If we're the host, send session config AND our own join info to the new peer
    if (_session.isHost && message.peerId != null) {
      // Only send config if our video is loaded (we know the correct position)
      if (_hasAnnouncedReady) {
        _sendSessionConfig(toPeerId: message.peerId);
      }
      // Send host's join info so guest adds host to their participants list
      _peerService.sendTo(
        message.peerId!,
        SyncMessage.join(peerId: _peerService.myPeerId!, displayName: displayName, isHost: true),
      );
    }
  }

  /// Handle session config from host
  Future<void> _handleSessionConfig(SyncMessage message) async {
    if (_session.isHost) return; // Host doesn't need to process config

    appLogger.d('WatchTogether: Received session config');

    // Update control mode
    if (message.controlMode != null) {
      onSessionConfigReceived?.call(message.controlMode!);
    }

    // Sync to host's current state
    if (_player == null) return;

    _isRemoteAction = true;
    try {
      // Always seek to host's position first
      if (message.position != null) {
        await _player!.seek(message.position!);
      }

      // Match playback rate
      if (message.rate != null) {
        await _player!.setRate(message.rate!);
        _lastKnownRate = message.rate!;
      }

      // Match play/pause state (bufferingState is reused: false = playing)
      if (message.bufferingState == false) {
        // Host was playing - defer play until all ready
        _wasPlayingBeforeBuffering = true;
        _pendingPlayPosition = message.position;
        // Check if we can play now
        if (isAllReady && !isAnyBuffering) {
          await _applyRemotePlay(position: message.position);
        } else {
          appLogger.d('WatchTogether: Host was playing but deferring until all ready');
        }
      } else {
        await _player!.pause();
        _lastKnownPlaying = false;
      }
    } on StateError catch (e) {
      appLogger.w('WatchTogether: Player disposed during session config apply', error: e);
      detachPlayer();
    } finally {
      _isRemoteAction = false;
    }
  }

  /// Set syncing state and notify listeners
  void _setSyncing(bool isSyncing) {
    if (_isSyncing != isSyncing) {
      _isSyncing = isSyncing;
      onSyncStateChanged?.call(isSyncing);
    }
  }

  /// Send join announcement to all peers
  void announceJoin(String displayName) {
    _peerService.broadcast(
      SyncMessage.join(peerId: _peerService.myPeerId!, displayName: displayName, isHost: _session.isHost),
    );
  }

  /// Send leave announcement to all peers
  void announceLeave() {
    if (_peerService.myPeerId != null) {
      _peerService.broadcast(SyncMessage.leave(peerId: _peerService.myPeerId!));
    }
  }

  /// Send current session configuration to peers
  void _sendSessionConfig({String? toPeerId}) {
    if (!_session.isHost || _peerService.myPeerId == null) return;

    final position = _player?.state.position ?? Duration.zero;
    final isPlaying = _player?.state.playing ?? false;
    final rate = _player?.state.rate ?? 1.0;

    final configMessage = SyncMessage.sessionConfig(
      controlMode: _session.controlMode,
      currentPosition: position,
      isPlaying: isPlaying,
      playbackRate: rate,
      peerId: _peerService.myPeerId,
    );

    if (toPeerId != null) {
      _peerService.sendTo(toPeerId, configMessage);
    } else {
      _peerService.broadcast(configMessage);
    }
  }

  /// Dispose resources
  void dispose() {
    detachPlayer();
    _participantBuffering.clear();
    _participantReady.clear();
    _hasAnnouncedReady = false;
  }
}
