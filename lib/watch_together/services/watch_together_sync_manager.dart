import 'dart:async';

import 'package:flutter/services.dart';

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

  // Stream subscriptions (cancelled together in detachPlayer)
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Future<void> _messageQueue = Future.value();
  int _playerAttachmentGeneration = 0;

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

  // Timer for clearing sync indicator (prevents flicker from overlapping corrections)
  Timer? _syncingTimer;

  // Debounce timer for buffering broadcasts
  Timer? _bufferingDebounceTimer;

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

    _playerAttachmentGeneration++;
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
    _playerAttachmentGeneration++;
    _player = null;
    _isRemoteAction = false;
    _setSyncing(false);

    // Announce that our player is no longer ready
    if (_peerService.myPeerId != null) {
      _peerService.broadcast(SyncMessage.playerReady(peerId: _peerService.myPeerId!, ready: false));
      _peerReady[_peerService.myPeerId!] = false;
    }
    _hasAnnouncedReady = false;
    _deferredPlay = false;
    _deferredPlayPosition = null;
    _firstPlayCompleted = false;
    _syncingTimer?.cancel();
    _syncingTimer = null;
    _bufferingDebounceTimer?.cancel();
    _bufferingDebounceTimer = null;
    _clockSyncTimer?.cancel();
    _clockSyncTimer = null;
    _clockOffset = 0;
    _hasClockOffset = false;
    _pendingPingTimestamp = null;

    final subscriptions = List<StreamSubscription<dynamic>>.of(_subscriptions);
    _subscriptions.clear();
    for (final subscription in subscriptions) {
      unawaited(subscription.cancel());
    }
    _positionSyncTimer?.cancel();
    _positionSyncTimer = null;

    appLogger.d('WatchTogether: Player detached');
  }

  /// Set up subscriptions to player streams
  void _setupPlayerSubscriptions() {
    // Listen to playing state changes
    _subscriptions.add(
      _player!.streams.playing.listen((isPlaying) async {
        if (_isRemoteAction) return;
        if (isPlaying == _lastKnownPlaying) return;
        final player = _player;
        final attachmentGeneration = _playerAttachmentGeneration;
        if (player == null || !_isPlayerAttachmentCurrent(player, attachmentGeneration)) return;

        _lastKnownPlaying = isPlaying;

        if (isPlaying && !isAllReady && !_firstPlayCompleted) {
          // Defer until all peers have loaded video (initial sync only)
          _deferredPlay = true;
          _deferredPlayPosition = player.state.position;
          _isRemoteAction = true;
          try {
            final didPause = await _runGuardedPlayerCommand(
              actionName: 'deferred play pause',
              player: player,
              attachmentGeneration: attachmentGeneration,
              command: (player) => player.pause(),
            );
            if (!didPause) return;

            _lastKnownPlaying = false;
          } finally {
            _isRemoteAction = false;
          }
          _broadcastPlayPause(true);
          return;
        }

        if (!isPlaying) _deferredPlay = false;
        _broadcastPlayPause(isPlaying);
      }),
    );

    // Listen to buffering state changes
    _subscriptions.add(
      _player!.streams.buffering.listen((isBuffering) async {
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

        // Broadcast for UI (peer buffering indicators) — debounced to avoid churn
        _bufferingDebounceTimer?.cancel();
        _bufferingDebounceTimer = Timer(const Duration(milliseconds: 300), () {
          _peerService.broadcast(SyncMessage.buffering(isBuffering, peerId: _peerService.myPeerId));
        });
      }),
    );

    // Listen to rate changes
    _subscriptions.add(
      _player!.streams.rate.listen((rate) {
        if (_isRemoteAction) return;

        if (rate != _lastKnownRate) {
          _lastKnownRate = rate;
          if (_canControl()) {
            _peerService.broadcast(SyncMessage.rate(rate, peerId: _peerService.myPeerId));
          }
        }
      }),
    );
  }

  /// Set up subscription to incoming sync messages
  void _setupMessageSubscription() {
    _subscriptions.add(
      _peerService.onMessageReceived.listen((message) {
        final queuedAttachmentGeneration = _playerAttachmentGeneration;
        _messageQueue = _messageQueue.then((_) => _handleMessage(message, queuedAttachmentGeneration)).catchError((
          Object error,
          StackTrace stackTrace,
        ) {
          appLogger.e(
            'WatchTogether: Failed to handle ${message.type.name} message',
            error: error,
            stackTrace: stackTrace,
          );
        });
      }),
    );
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

  bool _isRecoverablePlayerException(PlatformException error) {
    return error.code == 'COMMAND_FAILED' || error.code == 'NOT_INITIALIZED';
  }

  bool _isPlayerAttachmentCurrent(Player player, int attachmentGeneration) {
    return identical(_player, player) && _playerAttachmentGeneration == attachmentGeneration;
  }

  bool _isPlayerAttachmentUsable(Player player, int attachmentGeneration) {
    return _isPlayerAttachmentCurrent(player, attachmentGeneration) && !player.disposed;
  }

  void _handleRecoverableRemoteActionFailure(
    String actionName,
    Object error, {
    required Player player,
    required int attachmentGeneration,
  }) {
    appLogger.w('WatchTogether: Remote $actionName skipped because player became unavailable', error: error);
    if (_isPlayerAttachmentCurrent(player, attachmentGeneration)) {
      detachPlayer();
    }
  }

  Future<bool> _runGuardedPlayerCommand({
    required String actionName,
    required Player player,
    required int attachmentGeneration,
    required Future<void> Function(Player player) command,
  }) async {
    if (!_isPlayerAttachmentUsable(player, attachmentGeneration)) {
      if (_isPlayerAttachmentCurrent(player, attachmentGeneration)) {
        _handleRecoverableRemoteActionFailure(
          actionName,
          StateError('Player became unavailable'),
          player: player,
          attachmentGeneration: attachmentGeneration,
        );
      }
      return false;
    }

    try {
      await command(player);
    } on StateError catch (e) {
      _handleRecoverableRemoteActionFailure(actionName, e, player: player, attachmentGeneration: attachmentGeneration);
      return false;
    } on PlatformException catch (e) {
      if (_isRecoverablePlayerException(e)) {
        _handleRecoverableRemoteActionFailure(
          actionName,
          e,
          player: player,
          attachmentGeneration: attachmentGeneration,
        );
        return false;
      }
      rethrow;
    }

    if (!_isPlayerAttachmentUsable(player, attachmentGeneration)) {
      if (_isPlayerAttachmentCurrent(player, attachmentGeneration)) {
        _handleRecoverableRemoteActionFailure(
          actionName,
          StateError('Player became unavailable'),
          player: player,
          attachmentGeneration: attachmentGeneration,
        );
      }
      return false;
    }

    return true;
  }

  Future<bool> _runGuardedRemoteAction({
    required String actionName,
    required Future<bool> Function(Player player, int attachmentGeneration) action,
    int? expectedAttachmentGeneration,
  }) async {
    final player = _player;
    if (player == null) return false;

    final attachmentGeneration = _playerAttachmentGeneration;
    if (expectedAttachmentGeneration != null && expectedAttachmentGeneration != attachmentGeneration) {
      return false;
    }

    if (!_isPlayerAttachmentUsable(player, attachmentGeneration)) {
      _handleRecoverableRemoteActionFailure(
        actionName,
        StateError('Player became unavailable'),
        player: player,
        attachmentGeneration: attachmentGeneration,
      );
      return false;
    }

    _isRemoteAction = true;
    try {
      return await action(player, attachmentGeneration);
    } on StateError catch (e) {
      _handleRecoverableRemoteActionFailure(actionName, e, player: player, attachmentGeneration: attachmentGeneration);
      return false;
    } on PlatformException catch (e) {
      if (_isRecoverablePlayerException(e)) {
        _handleRecoverableRemoteActionFailure(
          actionName,
          e,
          player: player,
          attachmentGeneration: attachmentGeneration,
        );
        return false;
      }
      rethrow;
    } finally {
      _isRemoteAction = false;
    }
  }

  /// Broadcast play/pause state
  void _broadcastPlayPause(bool isPlaying) {
    if (!_canControl()) return;

    if (isPlaying) {
      final position = _player?.state.position ?? Duration.zero;
      _peerService.broadcast(SyncMessage.play(peerId: _peerService.myPeerId, position: position));
    } else {
      _peerService.broadcast(SyncMessage.pause(peerId: _peerService.myPeerId));
    }
  }

  /// Called when user seeks locally
  void onLocalSeek(Duration position) {
    if (!_canControl()) return;

    _peerService.broadcast(SyncMessage.seek(position, peerId: _peerService.myPeerId));
  }

  /// Handle incoming sync messages
  Future<void> _handleMessage(SyncMessage message, int queuedAttachmentGeneration) async {
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

      if (!isHostMessage && !isMetaMessage) return;
    }

    switch (message.type) {
      case SyncMessageType.play:
        if (!_shouldApplyRemoteControl(message)) break;
        await _applyRemotePlay(position: message.position, expectedAttachmentGeneration: queuedAttachmentGeneration);
        break;

      case SyncMessageType.pause:
        if (!_shouldApplyRemoteControl(message)) break;
        _deferredPlay = false;
        await _applyRemotePause(expectedAttachmentGeneration: queuedAttachmentGeneration);
        break;

      case SyncMessageType.seek:
        if (!_shouldApplyRemoteControl(message)) break;
        if (message.position != null) {
          await _applyRemoteSeek(message.position!, expectedAttachmentGeneration: queuedAttachmentGeneration);
        }
        break;

      case SyncMessageType.buffering:
        // Buffering state used for UI only, not playback control
        break;

      case SyncMessageType.positionSync:
        if (message.position != null) {
          await _checkAndCorrectDrift(message.position!, message.timestamp, queuedAttachmentGeneration);
        }
        // Reconcile play/pause state if host sent it and we diverged
        // This provides eventual consistency for play/pause state
        final player = _player;
        if (message.isPlaying != null && player != null && !_session.isHost) {
          if (!_isPlayerAttachmentCurrent(player, queuedAttachmentGeneration)) {
            break;
          }

          final localPlaying = player.state.playing;
          if (message.isPlaying! && !localPlaying) {
            await _applyRemotePlay(
              position: message.position,
              expectedAttachmentGeneration: queuedAttachmentGeneration,
            );
          } else if (!message.isPlaying! && localPlaying) {
            await _applyRemotePause(expectedAttachmentGeneration: queuedAttachmentGeneration);
          }
        }
        break;

      case SyncMessageType.rate:
        if (!_shouldApplyRemoteControl(message)) break;
        if (message.rate != null) {
          await _applyRemoteRate(message.rate!, expectedAttachmentGeneration: queuedAttachmentGeneration);
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
        await _handleSessionConfig(message, queuedAttachmentGeneration);
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
            await _applyRemotePlay(
              position: _deferredPlayPosition,
              expectedAttachmentGeneration: queuedAttachmentGeneration,
            );
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
  Future<bool> _applyRemotePlay({Duration? position, int? expectedAttachmentGeneration}) async {
    return _runGuardedRemoteAction(
      actionName: 'play',
      expectedAttachmentGeneration: expectedAttachmentGeneration,
      action: (player, attachmentGeneration) async {
        if (position != null) {
          final didSeek = await _runGuardedPlayerCommand(
            actionName: 'play seek',
            player: player,
            attachmentGeneration: attachmentGeneration,
            command: (player) => player.seek(position),
          );
          if (!didSeek) return false;
        }

        final didPlay = await _runGuardedPlayerCommand(
          actionName: 'play',
          player: player,
          attachmentGeneration: attachmentGeneration,
          command: (player) => player.play(),
        );
        if (!didPlay) return false;

        _lastKnownPlaying = true;
        return true;
      },
    );
  }

  /// Apply remote pause command
  Future<bool> _applyRemotePause({int? expectedAttachmentGeneration}) async {
    return _runGuardedRemoteAction(
      actionName: 'pause',
      expectedAttachmentGeneration: expectedAttachmentGeneration,
      action: (player, attachmentGeneration) async {
        final didPause = await _runGuardedPlayerCommand(
          actionName: 'pause',
          player: player,
          attachmentGeneration: attachmentGeneration,
          command: (player) => player.pause(),
        );
        if (!didPause) return false;

        _lastKnownPlaying = false;
        return true;
      },
    );
  }

  /// Apply remote seek command
  Future<bool> _applyRemoteSeek(Duration position, {int? expectedAttachmentGeneration}) async {
    return _runGuardedRemoteAction(
      actionName: 'seek',
      expectedAttachmentGeneration: expectedAttachmentGeneration,
      action: (player, attachmentGeneration) {
        return _runGuardedPlayerCommand(
          actionName: 'seek',
          player: player,
          attachmentGeneration: attachmentGeneration,
          command: (player) => player.seek(position),
        );
      },
    );
  }

  /// Apply remote rate change
  Future<bool> _applyRemoteRate(double rate, {int? expectedAttachmentGeneration}) async {
    return _runGuardedRemoteAction(
      actionName: 'rate',
      expectedAttachmentGeneration: expectedAttachmentGeneration,
      action: (player, attachmentGeneration) async {
        final didSetRate = await _runGuardedPlayerCommand(
          actionName: 'rate',
          player: player,
          attachmentGeneration: attachmentGeneration,
          command: (player) => player.setRate(rate),
        );
        if (!didSetRate) return false;

        _lastKnownRate = rate;
        return true;
      },
    );
  }

  /// Check and correct position drift
  Future<void> _checkAndCorrectDrift(
    Duration remotePosition,
    int remoteTimestamp,
    int expectedAttachmentGeneration,
  ) async {
    if (_session.isHost) return;

    final player = _player;
    if (player == null || !_isPlayerAttachmentCurrent(player, expectedAttachmentGeneration)) return;

    final localPosition = player.state.position;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Translate host's timestamp to our local time frame using clock offset
    // _clockOffset = hostClock - localClock, so localEquivalent = remoteTimestamp - _clockOffset
    final adjustedRemoteTimestamp = remoteTimestamp - _clockOffset;
    final rawDelay = now - adjustedRemoteTimestamp;

    // Before clock offset is available, use 0 (compare positions directly)
    final networkDelay = _hasClockOffset ? rawDelay.clamp(0, 5000) : 0;

    // Estimate where remote should be now, accounting for playback time elapsed
    var estimatedRemoteNow = remotePosition;
    if (player.state.playing && networkDelay > 0) {
      // If playing, account for time elapsed during network transit
      // Multiply by rate in case playback speed is different
      estimatedRemoteNow = remotePosition + Duration(milliseconds: (networkDelay * player.state.rate).round());
    }

    final drift = (localPosition - estimatedRemoteNow).abs();

    if (drift > excessiveDrift) {
      // Excessive drift - force sync with indicator
      appLogger.w('WatchTogether: Excessive drift (${drift.inSeconds}s), force syncing');
      _setSyncing(true);
      final didSeek = await _applyRemoteSeek(
        estimatedRemoteNow,
        expectedAttachmentGeneration: expectedAttachmentGeneration,
      );
      if (!didSeek) {
        _setSyncing(false);
        return;
      }
      _syncingTimer?.cancel();
      _syncingTimer = Timer(const Duration(milliseconds: 500), () => _setSyncing(false));
    } else if (drift > maxAllowedDrift) {
      _setSyncing(true);
      final didSeek = await _applyRemoteSeek(
        estimatedRemoteNow,
        expectedAttachmentGeneration: expectedAttachmentGeneration,
      );
      if (!didSeek) {
        _setSyncing(false);
        return;
      }
      _syncingTimer?.cancel();
      _syncingTimer = Timer(const Duration(milliseconds: 300), () => _setSyncing(false));
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
    }
  }

  /// Handle session config from host
  Future<void> _handleSessionConfig(SyncMessage message, int expectedAttachmentGeneration) async {
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

    await _runGuardedRemoteAction(
      actionName: 'session config',
      expectedAttachmentGeneration: expectedAttachmentGeneration,
      action: (player, attachmentGeneration) async {
        // Always seek to host's position first
        if (message.position != null) {
          final didSeek = await _runGuardedPlayerCommand(
            actionName: 'session config seek',
            player: player,
            attachmentGeneration: attachmentGeneration,
            command: (player) => player.seek(message.position!),
          );
          if (!didSeek) return false;
        }

        // Match playback rate
        if (message.rate != null) {
          final didSetRate = await _runGuardedPlayerCommand(
            actionName: 'session config rate',
            player: player,
            attachmentGeneration: attachmentGeneration,
            command: (player) => player.setRate(message.rate!),
          );
          if (!didSetRate) return false;

          _lastKnownRate = message.rate!;
        }

        // Match play/pause state (prefer isPlaying, fall back to legacy bufferingState encoding)
        final hostIsPlaying = message.isPlaying ?? (message.bufferingState == false);
        if (hostIsPlaying) {
          // Host was playing — defer until our video is loaded
          _deferredPlay = true;
          _deferredPlayPosition = message.position;
          if (_hasAnnouncedReady) {
            _deferredPlay = false;
            _firstPlayCompleted = true;
            final didPlay = await _runGuardedPlayerCommand(
              actionName: 'session config play',
              player: player,
              attachmentGeneration: attachmentGeneration,
              command: (player) => player.play(),
            );
            if (!didPlay) return false;

            _lastKnownPlaying = true;
          }
        } else {
          final didPause = await _runGuardedPlayerCommand(
            actionName: 'session config pause',
            player: player,
            attachmentGeneration: attachmentGeneration,
            command: (player) => player.pause(),
          );
          if (!didPause) return false;

          _lastKnownPlaying = false;
        }

        return true;
      },
    );
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
    _syncingTimer?.cancel();
    detachPlayer();
    _peerReady.clear();
    _hasAnnouncedReady = false;
  }
}
