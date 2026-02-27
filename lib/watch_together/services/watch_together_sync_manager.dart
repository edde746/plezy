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
  StreamSubscription<bool>? _bufferingSubscription;
  StreamSubscription<double>? _rateSubscription;
  StreamSubscription<SyncMessage>? _messageSubscription;

  // Position sync timer (host broadcasts position periodically)
  Timer? _positionSyncTimer;

  // Drift correction constants
  static const Duration maxAllowedDrift = Duration(seconds: 2);
  static const Duration positionSyncInterval = Duration(seconds: 3);
  static const Duration excessiveDrift = Duration(seconds: 10);

  // Peer readiness state (peer ID -> hasPlayerReady)
  final Map<String, bool> _peerReady = {};

  // Whether play is deferred until all peers are ready (initial load gate)
  bool _deferredPlay = false;

  // Position to seek to when deferred play triggers
  Duration? _deferredPlayPosition;

  // Whether the first coordinated play has completed (after this, late joiners catch up via positionSync)
  bool _firstPlayCompleted = false;

  // Clock offset estimation (NTP-style)
  // Offset = how far ahead the host's clock is vs ours (in ms)
  int _clockOffset = 0;
  bool _hasClockOffset = false;
  int? _pendingPingTimestamp;
  Timer? _clockSyncTimer;
  static const Duration _clockSyncInterval = Duration(seconds: 5);

  // Track last known state to avoid duplicate broadcasts
  bool _lastKnownPlaying = false;
  double _lastKnownRate = 1.0;

  // Whether we've announced our player as ready (first buffering: false)
  bool _hasAnnouncedReady = false;

  // Callbacks
  SessionConfigCallback? onSessionConfigReceived;
  SyncStateCallback? onSyncStateChanged;

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

  /// Whether all tracked peers have their player ready
  bool get isAllReady {
    if (_peerReady.isEmpty) return true;
    return _peerReady.values.every((ready) => ready);
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

    // If guest, request current session config from host in case we missed
    // a mediaSwitch broadcast (e.g., host switched episodes while we were
    // popping out of the previous player).
    if (!_session.isHost) {
      _peerService.broadcast(SyncMessage.requestSessionConfig(peerId: _peerService.myPeerId));
      _startClockSync();
    }

    appLogger.d('WatchTogether: Player attached, isHost: ${_session.isHost}');
  }

  /// Initialize participant tracking from existing session participants
  /// Call this before attachPlayer() to ensure we know about participants who joined before
  void initializeParticipants(List<String> peerIds) {
    for (final peerId in peerIds) {
      if (peerId != _peerService.myPeerId) {
        if (_session.isHost) {
          // Host waits for each peer to load their video before allowing play.
          _peerReady[peerId] = false;
        } else {
          // Guests use optimistic defaults — the host coordinates readiness
          // and will broadcast pause/play as needed.
          _peerReady[peerId] = true;
        }
      }
    }
    final otherCount = peerIds.where((id) => id != _peerService.myPeerId).length;
    appLogger.d('WatchTogether: Initialized $otherCount existing participants (host=${_session.isHost})');
  }

  /// Detach the player and stop sync
  void detachPlayer() {
    // Announce that our player is no longer ready
    if (_peerService.myPeerId != null) {
      _peerService.broadcast(SyncMessage.playerReady(peerId: _peerService.myPeerId!, ready: false));
      _peerReady[_peerService.myPeerId!] = false;
    }
    _hasAnnouncedReady = false;
    _deferredPlay = false;
    _deferredPlayPosition = null;
    _clockSyncTimer?.cancel();
    _clockSyncTimer = null;
    _clockOffset = 0;
    _hasClockOffset = false;
    _pendingPingTimestamp = null;

    _playingSubscription?.cancel();
    _bufferingSubscription?.cancel();
    _rateSubscription?.cancel();
    _messageSubscription?.cancel();
    _positionSyncTimer?.cancel();

    _playingSubscription = null;
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
      if (_isRemoteAction) return;
      if (isPlaying == _lastKnownPlaying) return;
      _lastKnownPlaying = isPlaying;

      if (isPlaying && !isAllReady && !_firstPlayCompleted) {
        // Defer until all peers have loaded video (initial sync only)
        _deferredPlay = true;
        _deferredPlayPosition = _player?.state.position;
        _isRemoteAction = true;
        try {
          await _player!.pause();
          _lastKnownPlaying = false;
        } finally {
          _isRemoteAction = false;
        }
        _broadcastPlayPause(true);
        return;
      }

      if (!isPlaying) _deferredPlay = false;
      _broadcastPlayPause(isPlaying);
    });

    // Listen to buffering state changes
    _bufferingSubscription = _player!.streams.buffering.listen((isBuffering) async {
      if (_isRemoteAction) return;

      // Announce ready when we stop buffering for the first time (video loaded)
      if (!isBuffering && !_hasAnnouncedReady) {
        _hasAnnouncedReady = true;
        _peerReady[_peerService.myPeerId!] = true;
        _peerService.broadcast(SyncMessage.playerReady(peerId: _peerService.myPeerId!, ready: true));
        appLogger.d('WatchTogether: Video loaded, announcing player ready');

        if (_session.isHost) {
          _sendSessionConfig();
        }
      }

      // Broadcast for UI (peer buffering indicators) — no playback control
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
  /// Includes play/pause state for eventual consistency
  void _startPositionSync() {
    _positionSyncTimer?.cancel();
    _positionSyncTimer = Timer.periodic(positionSyncInterval, (_) {
      if (_player != null && _session.isHost) {
        _peerService.broadcast(
          SyncMessage.positionSync(
            _player!.state.position,
            peerId: _peerService.myPeerId,
            isPlaying: _player!.state.playing,
          ),
        );
      }
    });
  }

  /// Start NTP-style clock offset measurement (guest only)
  void _startClockSync() {
    _clockSyncTimer?.cancel();
    _hasClockOffset = false;
    _clockOffset = 0;
    _pendingPingTimestamp = null;

    // Initial burst of 3 pings for fast convergence
    int burstCount = 0;
    Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (burstCount >= 3 || _player == null) {
        timer.cancel();
        return;
      }
      _sendClockPing();
      burstCount++;
    });

    // Then continue at regular interval
    _clockSyncTimer = Timer.periodic(_clockSyncInterval, (_) {
      if (_player != null) _sendClockPing();
    });
  }

  /// Send a clock-sync ping (guest only)
  void _sendClockPing() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _pendingPingTimestamp = now;
    _peerService.broadcast(SyncMessage.ping(now, peerId: _peerService.myPeerId));
  }

  /// Process a clock-sync pong and update clock offset (guest only)
  void _processClockPong(SyncMessage message) {
    if (_pendingPingTimestamp == null || message.pingId != _pendingPingTimestamp) {
      return; // Not our ping, or stale
    }
    _pendingPingTimestamp = null;

    final t1 = message.pingId!; // Our original send timestamp
    final t2 = message.timestamp; // Host's timestamp when it created the pong
    final t3 = DateTime.now().millisecondsSinceEpoch;

    final rtt = t3 - t1;
    if (rtt < 0 || rtt > 10000) {
      appLogger.w('WatchTogether: Discarding clock sample with RTT=${rtt}ms');
      return;
    }

    // clockOffset = how far ahead host's clock is relative to ours
    final sampleOffset = t2 - t1 - (rtt ~/ 2);

    if (!_hasClockOffset) {
      _clockOffset = sampleOffset;
      _hasClockOffset = true;
      appLogger.d('WatchTogether: Initial clock offset: ${_clockOffset}ms (RTT: ${rtt}ms)');
    } else {
      // Exponential moving average
      const alpha = 0.3;
      _clockOffset = (_clockOffset + (alpha * (sampleOffset - _clockOffset)).round());
      appLogger.d('WatchTogether: Clock offset updated: ${_clockOffset}ms (sample: ${sampleOffset}ms, RTT: ${rtt}ms)');
    }
  }

  /// Check if this peer can control playback
  bool _canControl() {
    if (_session.controlMode == ControlMode.anyone) {
      return true;
    }
    return _session.isHost;
  }

  /// Check if a remote control message should be applied based on control mode
  bool _shouldApplyRemoteControl(SyncMessage message) {
    if (_session.controlMode == ControlMode.anyone) {
      return true;
    }
    // In hostOnly mode, only apply control messages from the host
    return message.peerId == _session.hostPeerId;
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
        if (!_shouldApplyRemoteControl(message)) {
          appLogger.d('WatchTogether: Ignoring play from non-host in hostOnly mode');
          break;
        }
        await _applyRemotePlay(position: message.position);
        break;

      case SyncMessageType.pause:
        if (!_shouldApplyRemoteControl(message)) {
          appLogger.d('WatchTogether: Ignoring pause from non-host in hostOnly mode');
          break;
        }
        _deferredPlay = false;
        await _applyRemotePause();
        break;

      case SyncMessageType.seek:
        if (!_shouldApplyRemoteControl(message)) {
          appLogger.d('WatchTogether: Ignoring seek from non-host in hostOnly mode');
          break;
        }
        if (message.position != null) {
          await _applyRemoteSeek(message.position!);
        }
        break;

      case SyncMessageType.buffering:
        // Buffering state used for UI only, not playback control
        break;

      case SyncMessageType.positionSync:
        if (message.position != null) {
          _checkAndCorrectDrift(message.position!, message.timestamp);
        }
        // Reconcile play/pause state if host sent it and we diverged
        // This provides eventual consistency for play/pause state
        if (message.isPlaying != null && _player != null && !_session.isHost) {
          final localPlaying = _player!.state.playing;
          if (message.isPlaying! && !localPlaying) {
            appLogger.d('WatchTogether: Play/pause state diverged, syncing to host (playing)');
            await _applyRemotePlay(position: message.position);
          } else if (!message.isPlaying! && localPlaying) {
            appLogger.d('WatchTogether: Play/pause state diverged, syncing to host (paused)');
            await _applyRemotePause();
          }
        }
        break;

      case SyncMessageType.rate:
        if (!_shouldApplyRemoteControl(message)) {
          appLogger.d('WatchTogether: Ignoring rate from non-host in hostOnly mode');
          break;
        }
        if (message.rate != null) {
          await _applyRemoteRate(message.rate!);
        }
        break;

      case SyncMessageType.join:
        _handlePeerJoin(message);
        break;

      case SyncMessageType.leave:
        if (message.peerId != null) {
          _peerReady.remove(message.peerId);
        }
        break;

      case SyncMessageType.sessionConfig:
        await _handleSessionConfig(message);
        break;

      case SyncMessageType.ping:
        if (message.pingId != null) {
          final pong = SyncMessage.pong(message.pingId!, peerId: _peerService.myPeerId);
          if (message.peerId != null) {
            _peerService.sendTo(message.peerId!, pong);
          } else {
            _peerService.broadcast(pong);
          }
        }
        break;

      case SyncMessageType.pong:
        if (message.pingId != null && !_session.isHost) {
          _processClockPong(message);
        }
        break;

      case SyncMessageType.mediaSwitch:
        // Handled at the provider level, not in sync manager
        break;

      case SyncMessageType.hostExitedPlayer:
        // Handled at the provider level, not in sync manager
        break;

      case SyncMessageType.playerReady:
        if (message.peerId != null) {
          _peerReady[message.peerId!] = message.bufferingState ?? false;
          appLogger.d('WatchTogether: Peer ${message.peerId} player ready: ${message.bufferingState}');

          if (_deferredPlay && isAllReady) {
            _deferredPlay = false;
            _firstPlayCompleted = true;
            await _applyRemotePlay(position: _deferredPlayPosition);
            _deferredPlayPosition = null;
          }
        }
        break;

      case SyncMessageType.requestSessionConfig:
        // Guest is requesting current session config (recovery after missed mediaSwitch)
        if (_session.isHost && _hasAnnouncedReady && message.peerId != null) {
          appLogger.d('WatchTogether: Guest ${message.peerId} requested session config, sending');
          _sendSessionConfig(toPeerId: message.peerId);
        }
        break;
    }
  }

  /// Apply remote play command
  Future<void> _applyRemotePlay({Duration? position}) async {
    if (_player == null) return;

    appLogger.d('WatchTogether: Applying remote PLAY${position != null ? ' at ${position.inSeconds}s' : ''}');
    _isRemoteAction = true;
    try {
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
    final now = DateTime.now().millisecondsSinceEpoch;

    // Translate host's timestamp to our local time frame using clock offset
    // _clockOffset = hostClock - localClock, so localEquivalent = remoteTimestamp - _clockOffset
    final adjustedRemoteTimestamp = remoteTimestamp - _clockOffset;
    final rawDelay = now - adjustedRemoteTimestamp;

    // Before clock offset is available, use 0 (compare positions directly)
    final networkDelay = _hasClockOffset ? rawDelay.clamp(0, 5000) : 0;

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

    if (message.peerId != null) {
      if (_session.isHost) {
        _peerReady[message.peerId!] = false;
      } else if (!_peerReady.containsKey(message.peerId!)) {
        _peerReady[message.peerId!] = true;
      }
    }

    // If we're the host, send session config AND our own join info to the new peer
    if (_session.isHost && message.peerId != null) {
      // Only send config if our video is loaded (we know the correct position)
      if (_hasAnnouncedReady) {
        _sendSessionConfig(toPeerId: message.peerId);

        _peerService.sendTo(message.peerId!, SyncMessage.playerReady(peerId: _peerService.myPeerId!, ready: true));
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

    // The host only sends sessionConfig after its player is ready, so we
    // can safely mark it as ready.
    if (message.peerId != null) {
      _peerReady[message.peerId!] = true;
    }

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
        // Host was playing — defer until our video is loaded
        _deferredPlay = true;
        _deferredPlayPosition = message.position;
        if (_hasAnnouncedReady) {
          _deferredPlay = false;
          _firstPlayCompleted = true;
          await _applyRemotePlay(position: message.position);
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
      ratingKey: _session.mediaRatingKey,
      serverId: _session.mediaServerId,
      mediaTitle: _session.mediaTitle,
    );

    if (toPeerId != null) {
      _peerService.sendTo(toPeerId, configMessage);
    } else {
      _peerService.broadcast(configMessage);
    }
  }

  /// Dispose resources
  void dispose() {
    _clockSyncTimer?.cancel();
    detachPlayer();
    _peerReady.clear();
    _hasAnnouncedReady = false;
  }
}
