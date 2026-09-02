import 'dart:async';
import '../../media/ids.dart';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../mpv/mpv.dart';
import '../../i18n/strings.g.dart';
import '../../utils/app_logger.dart';
import '../models/playback_state.dart';
import '../models/sync_message.dart';
import '../models/watch_session.dart';
import '../services/current_playback_dispatcher.dart';
import '../services/relay_protocol.g.dart';
import '../services/watch_together_controller.dart';
import '../services/watch_together_peer_service.dart';
import '../services/watch_together_relay_endpoint.dart';

/// Callback type for when media switches (for guest navigation). Returns
/// whether the switch was handled; unhandled keys are re-dispatched on the
/// host's next state heartbeat.
typedef MediaSwitchCallback = Future<bool> Function(String ratingKey, ServerId serverId, String mediaTitle);

typedef WatchTogetherPeerServiceFactory = WatchTogetherPeerService Function({WatchTogetherRelayEndpoint? endpoint});

WatchTogetherPeerService _createWatchTogetherPeerService({WatchTogetherRelayEndpoint? endpoint}) =>
    WatchTogetherPeerService(endpoint: endpoint);

/// Provider for Watch Together functionality
///
/// This provider manages:
/// - Session creation/joining
/// - Peer connections
/// - Playback synchronization
/// - Participant list
/// - Media switching across the session
class WatchTogetherProvider with ChangeNotifier {
  WatchTogetherProvider({this._peerServiceFactory = _createWatchTogetherPeerService});

  final WatchTogetherPeerServiceFactory _peerServiceFactory;

  WatchSession? _session;
  WatchTogetherPeerService? _peerService;
  WatchTogetherController? _controller;
  PeerError? _recoverableTransportError;
  final List<Participant> _participants = [];
  bool _isSyncing = false;
  bool _isWaitingForPeers = false;
  List<String> _waitingOnPeerIds = const [];
  PlaybackPhase? _playbackPhase;
  String _displayName = t.watchTogether.defaultDisplayName;
  final CurrentPlaybackDispatcher _playbackDispatcher = CurrentPlaybackDispatcher();

  // Coalesce rapid-fire notifyListeners() calls into a single rebuild per frame.
  // During Watch Together join, 4-5 notifications fire within milliseconds;
  // this batches them into one rebuild to avoid overwhelming low-end devices.
  bool _notifyScheduled = false;
  bool _disposed = false;

  @override
  void notifyListeners() {
    if (_disposed || _notifyScheduled) return;
    _notifyScheduled = true;
    scheduleMicrotask(() {
      _notifyScheduled = false;
      if (!_disposed) super.notifyListeners();
    });
  }

  // Host reconnect grace period
  Timer? _hostReconnectTimer;
  bool _isWaitingForHostReconnect = false;
  bool _hostIntentionallyLeft = false;

  // Display name of the guest a host transfer was requested for; names the
  // failure toast if the relay rejects the request.
  String? _pendingTransferTargetName;

  // Debounce map for action events (peerId+type → last emission timestamp)
  final Map<String, int> _lastActionEventMs = {};

  /// Generate a random display name for this session
  static String _generateDisplayName() {
    const adjectives = ['Happy', 'Sleepy', 'Sunny', 'Cozy', 'Chill', 'Swift', 'Brave', 'Calm', 'Jolly', 'Lucky'];
    const nouns = ['Panda', 'Koala', 'Fox', 'Owl', 'Cat', 'Dog', 'Bear', 'Bunny', 'Duck', 'Penguin'];
    final random = Random();
    return '${adjectives[random.nextInt(adjectives.length)]} ${nouns[random.nextInt(nouns.length)]}';
  }

  /// Callback for when host switches media (guests should navigate)
  /// Used by MainScreen when VideoPlayerScreen is not active
  MediaSwitchCallback? onMediaSwitched;

  /// Callback for VideoPlayerScreen to handle media switch internally (guest only)
  /// When set, takes priority over onMediaSwitched for proper navigation context
  MediaSwitchCallback? onPlayerMediaSwitched;

  /// Callback for when host exits the video player (guests should exit too)
  VoidCallback? onHostExitedPlayer;

  // Stream subscriptions
  StreamSubscription<String>? _peerConnectedSubscription;
  StreamSubscription<String>? _peerDisconnectedSubscription;
  StreamSubscription<SyncMessage>? _messageSubscription;
  StreamSubscription<PeerError>? _errorSubscription;
  StreamSubscription<void>? _sessionEndedSubscription;
  StreamSubscription<String>? _hostChangedSubscription;

  // Getters
  bool get isInSession => _session != null;
  bool get isHost => _session?.isHost ?? false;
  bool get isConnected => _session?.isConnected ?? false;
  bool get isSyncing => _isSyncing;
  WatchSession? get session => _session;
  List<Participant> get participants => List.unmodifiable(_participants);
  int get participantCount => _participants.length;
  ControlMode get controlMode => _session?.controlMode ?? ControlMode.hostOnly;
  String? get sessionId => _session?.sessionId;
  bool get isWaitingForHostReconnect => _isWaitingForHostReconnect;

  /// Whether the room is held up waiting on peers (readiness or stalls) —
  /// drives the "Waiting for …" pill.
  bool get isWaitingForPeers => _isWaitingForPeers;

  String? _displayNameForPeer(String? peerId) {
    if (peerId == null) return null;
    return _participants
        .where((participant) => participant.peerId == peerId)
        .map((participant) => participant.displayName)
        .firstOrNull;
  }

  /// Display names of the peers the room is waiting on (excluding self).
  List<String> get waitingOnNames {
    final myPeerId = _peerService?.myPeerId;
    if (_waitingOnPeerIds.isEmpty) {
      // Guests waiting on a still-loading host have an empty digest.
      if (!isHost && _playbackPhase == PlaybackPhase.loading) {
        final hostName = _participants.where((p) => p.isHost).map((p) => p.displayName).firstOrNull;
        return [?hostName];
      }
      return const [];
    }
    return [
      for (final peerId in _waitingOnPeerIds)
        if (peerId != myPeerId) _displayNameForPeer(peerId) ?? '?',
    ];
  }

  /// Whether a player is currently attached to the sync controller.
  bool get hasAttachedPlayer => _controller?.hasPlayer ?? false;

  // Participant join/leave event stream
  final StreamController<ParticipantEvent> _participantEventController = StreamController<ParticipantEvent>.broadcast();
  Stream<ParticipantEvent> get participantEvents => _participantEventController.stream;

  // Current media getters
  String? get currentMediaRatingKey => _session?.mediaRatingKey;
  String? get currentMediaServerId => _session?.mediaServerId;
  String? get currentMediaTitle => _session?.mediaTitle;
  bool get hasCurrentPlayback =>
      currentMediaRatingKey != null && currentMediaServerId != null && currentMediaTitle != null;

  String? _buildPlaybackKey(String? ratingKey, ServerId? serverId) {
    if (ratingKey == null || serverId == null) return null;
    return '$serverId:$ratingKey';
  }

  void _updateCurrentPlaybackSnapshot({
    required String ratingKey,
    required ServerId serverId,
    required String mediaTitle,
  }) {
    _session = _session?.copyWith(mediaRatingKey: ratingKey, mediaServerId: serverId, mediaTitle: mediaTitle);
  }

  void _clearCurrentPlaybackSnapshot() {
    final session = _session;
    if (session == null) return;

    _session = WatchSession(
      sessionId: session.sessionId,
      role: session.role,
      controlMode: session.controlMode,
      state: session.state,
      errorMessage: session.errorMessage,
      hostPeerId: session.hostPeerId,
    );
    _playbackDispatcher.reset();
  }

  void _dispatchCurrentPlayback({
    required String ratingKey,
    required ServerId serverId,
    required String mediaTitle,
    required String source,
  }) {
    final callback = onPlayerMediaSwitched ?? onMediaSwitched;
    if (callback == null) {
      appLogger.d('WatchTogether: No media switch callback set, keeping snapshot from $source only');
      return;
    }

    appLogger.d('WatchTogether: Dispatching current playback from $source: $mediaTitle');
    // The key is only marked handled if the callback reports success; a
    // failed switch is retried on the host's next state heartbeat.
    unawaited(
      _playbackDispatcher.dispatch(
        _buildPlaybackKey(ratingKey, serverId)!,
        () => callback(ratingKey, serverId, mediaTitle),
      ),
    );
  }

  void markCurrentPlaybackHandled({required String ratingKey, required ServerId serverId}) {
    _playbackDispatcher.markHandled(_buildPlaybackKey(ratingKey, serverId)!);
  }

  void requestCurrentPlaybackSnapshot() {
    if (isHost) return;
    appLogger.d('WatchTogether: Requesting current playback state from host');
    _controller?.requestState();
  }

  void _requestCurrentPlaybackSnapshotIfHostConnected(WatchTogetherPeerService peerService) {
    if (!identical(_peerService, peerService)) return;
    final session = _session;
    final hostPeerId = session?.hostPeerId;
    if (session == null || session.isHost || hostPeerId == null || !peerService.connectedPeers.contains(hostPeerId)) {
      return;
    }
    _controller?.updateSession(session);
    requestCurrentPlaybackSnapshot();
  }

  /// Wire up reconnection handler to re-announce join and re-sync state
  void _wireReconnectHandler() {
    final peerService = _peerService!;
    peerService.onReconnected = () {
      if (_disposed || !identical(_peerService, peerService)) return;

      final recoverableError = _recoverableTransportError;
      final session = _session;
      if (recoverableError != null &&
          session != null &&
          session.state == SessionState.error &&
          session.errorMessage == recoverableError.message) {
        _session = session.copyWith(state: SessionState.connected, errorMessage: null);
        _recoverableTransportError = null;
        notifyListeners();
      } else {
        _recoverableTransportError = null;
      }

      _controller?.announceJoin(_displayName);
      _controller?.onReconnected();
    };
  }

  /// Wire the controller's callbacks into provider/UI state
  void _wireController() {
    final controller = _controller!;

    controller.onCorrectingChanged = (correcting) {
      _isSyncing = correcting;
      notifyListeners();
    };

    controller.onPhaseChanged = (phase) {
      _playbackPhase = phase;
      _updateWaitingState();
    };

    controller.onWaitingOnChanged = (peerIds) {
      _waitingOnPeerIds = peerIds;
      for (var i = 0; i < _participants.length; i++) {
        final isWaitedOn = peerIds.contains(_participants[i].peerId);
        if (_participants[i].isBuffering != isWaitedOn) {
          _participants[i] = _participants[i].copyWith(isBuffering: isWaitedOn);
          if (isWaitedOn) {
            _emitActionEvent(_participants[i].peerId, ParticipantEventType.buffering);
          }
        }
      }
      _updateWaitingState();
    };

    controller.onControlModeReceived = (mode) {
      if (isHost || _session == null) return;
      if (_session!.controlMode == mode) return;
      _session = _session!.copyWith(controlMode: mode);
      controller.updateSession(_session!);
      notifyListeners();
    };

    controller.onMediaStateReceived = _handleMediaStateReceived;

    controller.onHostExitedPlayer = _handleHostExitedPlayer;

    controller.onRemoteAction = (peerId, hint) {
      final type = switch (hint) {
        PlaybackActionHint.play => ParticipantEventType.resumed,
        PlaybackActionHint.pause => ParticipantEventType.paused,
        PlaybackActionHint.seek => ParticipantEventType.seeked,
        PlaybackActionHint.rate => ParticipantEventType.changedSpeed,
        PlaybackActionHint.mediaSwitch => null,
      };
      if (type != null) _emitActionEvent(peerId, type, rate: controller.roomRate);
    };

    controller.onPeerNeedsUpdate = (peerId) {
      final name = _displayNameForPeer(peerId);
      _participantEventController.add(
        ParticipantEvent(displayName: name ?? peerId, type: ParticipantEventType.needsUpdate),
      );
    };

    controller.onResumedWithout = (peerIds) {
      for (final peerId in peerIds) {
        final name = _displayNameForPeer(peerId);
        if (name != null) {
          _participantEventController.add(
            ParticipantEvent(displayName: name, type: ParticipantEventType.resumedWithout),
          );
        }
      }
    };
  }

  void _updateWaitingState() {
    final phase = _playbackPhase;
    final waiting =
        phase == PlaybackPhase.waitingForPeers ||
        // Guests waiting on a still-loading host (no digest in that phase).
        (!isHost && phase == PlaybackPhase.loading && hasCurrentPlayback);
    if (waiting != _isWaitingForPeers) {
      _isWaitingForPeers = waiting;
    }
    notifyListeners();
  }

  /// Create a new watch together session as host
  Future<String> createSession({
    required ControlMode controlMode,
    required WatchTogetherRelayEndpoint relayEndpoint,
    String? displayName,
    String? sessionId,
    String? mediaRatingKey,
    String? mediaServerId,
    String? mediaTitle,
  }) async {
    // Clean up any existing session
    await leaveSession();
    _playbackDispatcher.reset();

    appLogger.d('WatchTogether: Creating session with control mode: $controlMode');

    _peerService = _peerServiceFactory(endpoint: relayEndpoint);
    _setupPeerServiceListeners();

    try {
      final createdSessionId = await _peerService!.createSession(sessionId: sessionId);

      _session = WatchSession.createAsHost(
        sessionId: createdSessionId,
        hostPeerId: _peerService!.hostPeerId!,
        controlMode: controlMode,
        mediaRatingKey: mediaRatingKey,
        mediaServerId: mediaServerId,
        mediaTitle: mediaTitle,
      ).copyWith(state: SessionState.connected);

      _displayName = displayName ?? _generateDisplayName();
      _participants.add(Participant(peerId: _peerService!.myPeerId!, displayName: _displayName, isHost: true));

      _controller = WatchTogetherController(peerService: _peerService!, session: _session!);

      _wireController();
      _wireReconnectHandler();

      notifyListeners();
      appLogger.d('WatchTogether: Session created: $createdSessionId');

      return createdSessionId;
    } catch (e) {
      appLogger.e('WatchTogether: Failed to create session', error: e);
      _session = _session?.copyWith(state: SessionState.error, errorMessage: e.toString());
      notifyListeners();
      rethrow;
    }
  }

  /// Join an existing session as guest
  Future<void> joinSession(
    String sessionId, {
    required WatchTogetherRelayEndpoint relayEndpoint,
    String? displayName,
  }) async {
    // Clean up any existing session
    await leaveSession();
    _playbackDispatcher.reset();

    appLogger.d('WatchTogether: Joining session: $sessionId');

    final peerService = _peerServiceFactory(endpoint: relayEndpoint);
    _peerService = peerService;
    _setupPeerServiceListeners();

    final joiningSession = WatchSession.joinAsGuest(sessionId: sessionId);
    _session = joiningSession;
    notifyListeners();

    try {
      await peerService.joinSession(sessionId);
      if (!identical(_peerService, peerService)) {
        throw StateError('Watch Together join became stale');
      }

      // Host authority comes from the relay setup response rather than the
      // public room code or a client-derived routing label.
      _session = joiningSession.copyWith(state: SessionState.connected, hostPeerId: peerService.hostPeerId);

      _displayName = displayName ?? _generateDisplayName();

      _controller = WatchTogetherController(peerService: peerService, session: _session!);

      _wireController();
      _wireReconnectHandler();

      // Add self to participants
      _participants.add(Participant(peerId: peerService.myPeerId!, displayName: _displayName, isHost: false));

      // Announce join to other participants
      _controller!.announceJoin(_displayName);
      _requestCurrentPlaybackSnapshotIfHostConnected(peerService);

      notifyListeners();
      appLogger.d('WatchTogether: Joined session successfully');
    } catch (e) {
      appLogger.e('WatchTogether: Failed to join session', error: e);
      if (identical(_peerService, peerService)) {
        await leaveSession();
      }
      rethrow;
    }
  }

  /// Enter a room by code — joins a room that still has someone in it and
  /// hosts the code otherwise.
  Future<void> enterRoom(
    String sessionId, {
    required WatchTogetherRelayEndpoint relayEndpoint,
    ControlMode controlMode = ControlMode.anyone,
    String? displayName,
  }) async {
    // A successful join reserves a durable guest identity. Release that probe
    // identity before opening the provider's real connection.
    final probe = _peerServiceFactory(endpoint: relayEndpoint);
    var shouldBeHost = false;
    try {
      var probeJoined = false;
      try {
        await probe.joinSession(sessionId);
        probeJoined = true;
      } on PeerError catch (error) {
        if (error.serverCode != RelayProtocol.roomNotFoundCode) rethrow;
      }
      // A room the relay still holds but nobody is connected to is an
      // abandoned code, not a session: its declared host is gone and the
      // reservation only survives until the next cleanup sweep. Take the code
      // over instead of waiting on a host that is never coming back.
      shouldBeHost = !probeJoined || probe.connectedPeers.isEmpty;
      if (probeJoined) {
        await probe.releaseSession();
      }
    } finally {
      await probe.disconnect();
      probe.dispose();
    }

    if (shouldBeHost) {
      await createSession(
        controlMode: controlMode,
        relayEndpoint: relayEndpoint,
        displayName: displayName,
        sessionId: sessionId,
      );
    } else {
      await joinSession(sessionId, relayEndpoint: relayEndpoint, displayName: displayName);
    }
  }

  /// Leave the current session. Local callbacks and player bindings are
  /// detached synchronously; relay release remains awaitable and observable.
  Future<void> leaveSession() async {
    if (_session == null && _peerService == null) return;
    appLogger.d('WatchTogether: Leaving session');
    final peerService = _detachLocalSession(announceLeave: true);
    if (peerService != null) {
      await _finishPeerTeardown(peerService, release: true);
    }
    appLogger.d('WatchTogether: Session left');
  }

  WatchTogetherPeerService? _detachLocalSession({required bool announceLeave}) {
    _recoverableTransportError = null;
    if (announceLeave) _controller?.announceLeave();

    final peerService = _peerService;
    if (peerService != null) peerService.onReconnected = null;

    _observeSubscriptionCancellation(_peerConnectedSubscription?.cancel());
    _observeSubscriptionCancellation(_peerDisconnectedSubscription?.cancel());
    _observeSubscriptionCancellation(_messageSubscription?.cancel());
    _observeSubscriptionCancellation(_errorSubscription?.cancel());
    _observeSubscriptionCancellation(_sessionEndedSubscription?.cancel());
    _observeSubscriptionCancellation(_hostChangedSubscription?.cancel());
    _peerConnectedSubscription = null;
    _peerDisconnectedSubscription = null;
    _messageSubscription = null;
    _errorSubscription = null;
    _sessionEndedSubscription = null;
    _hostChangedSubscription = null;

    _hostReconnectTimer?.cancel();
    _hostReconnectTimer = null;
    _isWaitingForHostReconnect = false;

    _controller?.dispose();
    _controller = null;
    _peerService = null;
    _session = null;
    _participants.clear();
    _isSyncing = false;
    _isWaitingForPeers = false;
    _waitingOnPeerIds = const [];
    _playbackPhase = null;
    _playbackDispatcher.reset();
    _lastActionEventMs.clear();
    _pendingTransferTargetName = null;
    _hostIntentionallyLeft = false;

    if (!_disposed) notifyListeners();
    return peerService;
  }

  void _observeSubscriptionCancellation(Future<void>? cancellation) {
    if (cancellation == null) return;
    unawaited(
      cancellation.catchError((Object error, StackTrace stackTrace) {
        appLogger.e('WatchTogether: Failed to cancel local subscription', error: error, stackTrace: stackTrace);
      }),
    );
  }

  Future<void> _finishPeerTeardown(WatchTogetherPeerService peerService, {required bool release}) async {
    Object? failure;
    StackTrace? failureStackTrace;
    if (release) {
      try {
        await peerService.releaseSession();
      } catch (error, stackTrace) {
        failure = error;
        failureStackTrace = stackTrace;
        appLogger.e('WatchTogether: Failed to release relay ownership', error: error, stackTrace: stackTrace);
      }
    }
    try {
      await peerService.disconnect();
    } catch (error, stackTrace) {
      failure ??= error;
      failureStackTrace ??= stackTrace;
      appLogger.e('WatchTogether: Failed to disconnect relay transport', error: error, stackTrace: stackTrace);
    } finally {
      peerService.dispose();
    }
    if (failure != null) {
      Error.throwWithStackTrace(failure, failureStackTrace!);
    }
  }

  void _leaveSessionBestEffort(String reason) {
    unawaited(
      leaveSession().catchError((Object error, StackTrace stackTrace) {
        appLogger.e('WatchTogether: Best-effort $reason failed', error: error, stackTrace: stackTrace);
      }),
    );
  }

  /// Attach a player to the sync controller for the given media.
  ///
  /// [hasFirstFrame] is the screen's first-frame snapshot, [startupHold]
  /// delays sync readiness past platform startup gates (frame-rate switch),
  /// and [remoteSeek] routes sync-issued seeks through the screen's seek
  /// path (Plex transcode restarts).
  void attachPlayer(
    Player player, {
    required String ratingKey,
    required String serverId,
    String? mediaTitle,
    bool hasFirstFrame = false,
    Future<void>? startupHold,
    Future<void> Function(Duration target)? remoteSeek,
  }) {
    if (_controller == null) {
      appLogger.w('WatchTogether: Cannot attach player - no sync controller');
      return;
    }

    _controller!.attachPlayer(
      player,
      ratingKey: ratingKey,
      serverId: serverId,
      mediaTitle: mediaTitle,
      hasFirstFrame: hasFirstFrame,
      startupHold: startupHold,
      remoteSeek: remoteSeek,
    );
  }

  /// Detach the player from the sync controller. [exiting] means the user
  /// left the video player (ends the media epoch); episode switches detach
  /// without exiting.
  void detachPlayer({bool exiting = false}) {
    _controller?.detachPlayer(exiting: exiting);
  }

  /// Pause a guest's player without pausing the room — see
  /// [WatchTogetherController.pauseLocallyForSystem]. Returns false when there is no attachment, or
  /// when this peer is the host and must pause the room the ordinary way, so the caller falls back
  /// to its own pause.
  Future<bool> pauseLocallyForSystem() async {
    final controller = _controller;
    if (controller == null) return false;
    return controller.pauseLocallyForSystem();
  }

  /// Suppress sync heartbeats/corrections while the app is backgrounded.
  void setBackgrounded(bool value) {
    _controller?.setBackgrounded(value);
  }

  /// Set up listeners for peer service events
  void _setupPeerServiceListeners() {
    final peerService = _peerService!;
    _peerConnectedSubscription = peerService.onPeerConnected.listen((peerId) {
      if (_disposed || !identical(_peerService, peerService)) return;
      appLogger.d('WatchTogether: Peer connected: $peerId');

      // If host reconnected during grace period, cancel the timer
      if (!isHost && peerId == _session?.hostPeerId && _isWaitingForHostReconnect) {
        _cancelHostReconnectGracePeriod();
      }

      if (!isHost && peerId == _session?.hostPeerId) {
        _requestCurrentPlaybackSnapshotIfHostConnected(peerService);
      }

      // Peer will announce themselves with a join message
      notifyListeners();
    });

    _peerDisconnectedSubscription = peerService.onPeerDisconnected.listen((peerId) {
      if (_disposed || !identical(_peerService, peerService)) return;
      appLogger.d('WatchTogether: Peer disconnected: $peerId');

      // Capture display name before removal for notification
      final disconnectedName = _displayNameForPeer(peerId);

      // The sync controller observes peer disconnects itself.
      _participants.removeWhere((p) => p.peerId == peerId);

      // If host disconnected unexpectedly, start grace period for reconnection.
      // Skip if the host already sent a deliberate leave message.
      if (!isHost && peerId == _session?.hostPeerId && !_hostIntentionallyLeft) {
        _startHostReconnectGracePeriod();
      } else if (disconnectedName != null) {
        _participantEventController.add(
          ParticipantEvent(displayName: disconnectedName, type: ParticipantEventType.left),
        );
      }

      notifyListeners();
    });

    _messageSubscription = peerService.onMessageReceived.listen((message) {
      if (_disposed || !identical(_peerService, peerService)) return;
      _handleSyncMessage(message);
    });

    _errorSubscription = peerService.onError.listen((error) {
      if (_disposed || !identical(_peerService, peerService)) return;
      final hostPeerId = _session?.hostPeerId;
      if (error.serverCode == 'not_in_room' &&
          !isHost &&
          hostPeerId != null &&
          !peerService.connectedPeers.contains(hostPeerId)) {
        appLogger.d('WatchTogether: Declared host is not connected yet; keeping the retained-room join pending');
        return;
      }
      if (error.serverCode == RelayProtocol.notHostCode || error.serverCode == RelayProtocol.peerNotFoundCode) {
        // A rejected host transfer is not a session failure — surface a toast
        // and keep the room connected.
        appLogger.w('WatchTogether: Host transfer rejected: ${error.message}');
        final targetName = _pendingTransferTargetName;
        _pendingTransferTargetName = null;
        if (targetName != null) {
          _participantEventController.add(
            ParticipantEvent(displayName: targetName, type: ParticipantEventType.hostTransferFailed),
          );
        }
        return;
      }
      appLogger.e('WatchTogether: Peer error: ${error.message}');

      // Only established transport stream errors are recoverable. Relay and
      // terminal errors must survive any later reconnect callback.
      if (_session != null && _session!.state == SessionState.connected) {
        _recoverableTransportError = error.originalError != null && error.serverCode == null ? error : null;
        _session = _session!.copyWith(state: SessionState.error, errorMessage: error.message);
        notifyListeners();
      }
    });
    _sessionEndedSubscription = peerService.onSessionEnded.listen((_) {
      if (_disposed || !identical(_peerService, peerService) || isHost) return;
      appLogger.d('WatchTogether: Relay confirmed that the host ended the room');
      _hostIntentionallyLeft = true;
      _handleHostExitedPlayer();
      final detachedPeerService = _detachLocalSession(announceLeave: false);
      if (detachedPeerService != null) {
        unawaited(
          _finishPeerTeardown(detachedPeerService, release: false).catchError((Object error, StackTrace stackTrace) {
            appLogger.e('WatchTogether: Failed to close an ended relay session', error: error, stackTrace: stackTrace);
          }),
        );
      }
    });
    _hostChangedSubscription = peerService.onHostChanged.listen((newHostPeerId) {
      if (_disposed || !identical(_peerService, peerService)) return;
      _handleHostChanged(newHostPeerId);
    });
  }

  /// Handle incoming sync messages for participant management
  void _handleSyncMessage(SyncMessage message) {
    switch (message.type) {
      case SyncMessageType.join:
        if (message.peerId != null && message.displayName != null) {
          // Check if participant already exists
          final existingIndex = _participants.indexWhere((p) => p.peerId == message.peerId);
          if (existingIndex >= 0) {
            // Update existing participant
            _participants[existingIndex] = Participant(
              peerId: message.peerId!,
              displayName: message.displayName!,
              isHost: message.isHost ?? false,
            );
          } else {
            // Add new participant
            _participants.add(
              Participant(peerId: message.peerId!, displayName: message.displayName!, isHost: message.isHost ?? false),
            );
            _participantEventController.add(
              ParticipantEvent(displayName: message.displayName!, type: ParticipantEventType.joined),
            );

            // Send our join info back so the new peer adds us to their
            // participant list. Only reply to NEW peers to avoid an
            // infinite join ping-pong (A→join→B→join→A→...). The host's
            // reply also carries the room's control mode so lobby guests
            // learn it before any playback state exists.
            if (_peerService != null) {
              _peerService!.sendTo(
                message.peerId!,
                SyncMessage.join(
                  peerId: _peerService!.myPeerId!,
                  displayName: _displayName,
                  isHost: isHost,
                  controlMode: isHost ? _session?.controlMode : null,
                ),
              );
            }
          }

          notifyListeners();
        }
        break;

      case SyncMessageType.leave:
        if (message.peerId != null) {
          final leavingName = _displayNameForPeer(message.peerId);
          _participants.removeWhere((p) => p.peerId == message.peerId);
          if (leavingName != null) {
            _participantEventController.add(
              ParticipantEvent(displayName: leavingName, type: ParticipantEventType.left),
            );
          }

          // If the host deliberately left, end the session for everyone.
          if (!isHost && message.peerId == _session?.hostPeerId) {
            _hostIntentionallyLeft = true;
            _handleHostExitedPlayer();
            _leaveSessionBestEffort('host-leave cleanup');
          }

          notifyListeners();
        }
        break;

      // hostExitedPlayer is routed through the controller's ordered message
      // queue so it can't overtake (or be overtaken by) state messages.

      default:
        // Playback sync messages (state/status/control/...) are handled by
        // the session controller.
        break;
    }
  }

  /// Emit an action event for a remote peer (with 1s debounce per peer+type)
  void _emitActionEvent(String? peerId, ParticipantEventType type, {double? rate}) {
    if (peerId == null || peerId == _peerService?.myPeerId) return;

    final key = '$peerId:${type.name}';
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = _lastActionEventMs[key] ?? 0;
    if (now - last < 1000) return;
    _lastActionEventMs[key] = now;

    final name = _displayNameForPeer(peerId);
    if (name != null) {
      _participantEventController.add(ParticipantEvent(displayName: name, type: type, rate: rate));
    }
  }

  /// Handle current-media info carried in the host's playback state
  /// (guest only). Processed even when no player is attached so guests can
  /// navigate into (or between) playback.
  void _handleMediaStateReceived(String ratingKey, String serverId, String? mediaTitle) {
    if (isHost) return;

    final typedServerId = serverIdOrNull(serverId);
    if (typedServerId == null) {
      appLogger.w('WatchTogether: Ignoring playback state with blank serverId');
      return;
    }
    final playbackKey = _buildPlaybackKey(ratingKey, typedServerId);

    // Detached guests receive this on every heartbeat; only rebuild when the
    // snapshot actually changes.
    final session = _session;
    final snapshotChanged =
        session == null ||
        session.mediaRatingKey != ratingKey ||
        session.mediaServerId != typedServerId ||
        session.mediaTitle != (mediaTitle ?? '');
    _updateCurrentPlaybackSnapshot(ratingKey: ratingKey, serverId: typedServerId, mediaTitle: mediaTitle ?? '');
    if (snapshotChanged) notifyListeners();

    if (_playbackDispatcher.shouldDispatch(playbackKey)) {
      _dispatchCurrentPlayback(
        ratingKey: ratingKey,
        serverId: typedServerId,
        mediaTitle: mediaTitle ?? '',
        source: 'playback state',
      );
    }
  }

  @visibleForTesting
  void debugHandleMediaState(String ratingKey, String serverId, String? mediaTitle) =>
      _handleMediaStateReceived(ratingKey, serverId, mediaTitle);

  /// Called when user seeks locally (to sync with peers)
  void onLocalSeek(Duration position) {
    _controller?.onLocalSeek(position);
  }

  /// Called when the user changes the playback rate locally. The screen has
  /// already applied it to the player; this declares it to the room.
  void onLocalRate(double rate) {
    _controller?.onLocalRate(rate);
  }

  /// The room's current playback rate, or null outside a room / before the
  /// first state arrives.
  double? get roomRate => _controller?.roomRate;

  /// Whether a sync correction currently owns the player's rate. The player
  /// surface suppresses rate feedback (toast, picker) while this is true.
  bool get syncOwnsRate => _controller?.syncOwnsRate ?? false;

  /// Whether the current user can control playback
  bool canControl() {
    if (_session == null) return true; // Not in session, can control
    if (_session!.controlMode == ControlMode.anyone) return true;
    return isHost;
  }

  /// Set the current media (host only) and broadcast to guests
  ///
  /// Call this when the host starts playing new content.
  /// Guests will receive a media switch notification and should navigate.
  void setCurrentMedia({required String ratingKey, required ServerId serverId, required String mediaTitle}) {
    if (!isHost || _session == null || _peerService == null) {
      appLogger.w('WatchTogether: Cannot set media - not host or not in session');
      return;
    }

    appLogger.d('WatchTogether: Host setting current media: $mediaTitle (ratingKey: $ratingKey)');

    // Update session with new media info
    _session = _session!.copyWith(mediaRatingKey: ratingKey, mediaServerId: serverId, mediaTitle: mediaTitle);

    // The controller broadcasts the new media epoch in its playback state.
    _controller?.setCurrentMedia(ratingKey: ratingKey, serverId: serverId, mediaTitle: mediaTitle);

    notifyListeners();
  }

  /// Whether the current user (as host) may hand host authority to
  /// [participant]: connected guest speaking the current sync protocol.
  bool canTransferHostTo(Participant participant) {
    final peerService = _peerService;
    final controller = _controller;
    if (peerService == null || controller == null) return false;
    if (!isHost || !isConnected) return false;
    if (participant.isHost || participant.peerId == peerService.myPeerId) return false;
    if (!peerService.connectedPeers.contains(participant.peerId)) return false;
    return controller.isPeerCompatible(participant.peerId);
  }

  /// Ask the relay to make [participant] the host (host only). Roles flip
  /// when the relay's `hostChanged` broadcast arrives; a rejection surfaces
  /// as a [ParticipantEventType.hostTransferFailed] event.
  void transferHost(Participant participant) {
    if (!canTransferHostTo(participant)) {
      appLogger.w('WatchTogether: Ignoring host transfer to ineligible peer ${participant.peerId}');
      return;
    }
    appLogger.d('WatchTogether: Requesting host transfer to ${participant.peerId}');
    _pendingTransferTargetName = participant.displayName;
    _peerService!.transferHost(participant.peerId);
  }

  /// The relay reassigned host authority ([peerService] already flipped its
  /// own role state): rebuild session/participants and swap the controller's
  /// role engine in place.
  void _handleHostChanged(String newHostPeerId) {
    final session = _session;
    final peerService = _peerService;
    if (session == null || peerService == null) return;

    final wasHost = session.isHost;
    final amHost = newHostPeerId == peerService.myPeerId;
    _pendingTransferTargetName = null;

    // Any host-departure bookkeeping referred to the previous host.
    _cancelHostReconnectGracePeriod();
    _hostIntentionallyLeft = false;

    final updated = session.copyWith(role: amHost ? SessionRole.host : SessionRole.guest, hostPeerId: newHostPeerId);
    _session = updated;

    for (var i = 0; i < _participants.length; i++) {
      final isHostNow = _participants[i].peerId == newHostPeerId;
      if (_participants[i].isHost != isHostNow) {
        _participants[i] = _participants[i].copyWith(isHost: isHostNow);
      }
    }

    _controller?.applyHostChange(updated);

    if (amHost && !wasHost) {
      // Re-announce as host — the lobby-safe carrier that teaches guests the
      // room's control mode now comes from this peer.
      _controller?.announceJoin(_displayName);
      _participantEventController.add(
        ParticipantEvent(displayName: _displayName, type: ParticipantEventType.becameHost),
      );
    } else if (!amHost) {
      _participantEventController.add(
        ParticipantEvent(
          displayName: _displayNameForPeer(newHostPeerId) ?? '?',
          type: ParticipantEventType.hostChanged,
        ),
      );
    }

    appLogger.d('WatchTogether: Host changed to $newHostPeerId (self: $amHost)');
    notifyListeners();
  }

  /// Notify guests that host is exiting the video player
  ///
  /// Call this from video player dispose when host exits.
  void notifyHostExitedPlayer() {
    if (!isHost || _session == null || _peerService == null) {
      return;
    }

    appLogger.d('WatchTogether: Host exiting player, notifying guests');

    _peerService!.broadcast(SyncMessage.hostExitedPlayer(peerId: _peerService!.myPeerId));
  }

  /// Handle host exited player message (guest only)
  void _handleHostExitedPlayer() {
    if (isHost) return; // Host doesn't need to handle their own exit

    appLogger.d('WatchTogether: Host exited player, callback set: ${onHostExitedPlayer != null}');

    _clearCurrentPlaybackSnapshot();

    // Clear the player callback BEFORE popping so that any mediaSwitch message
    // arriving during the pop animation routes to MainScreen's handler instead
    // of the dying VideoPlayerScreen.
    onPlayerMediaSwitched = null;
    notifyListeners();

    // Trigger callback for the app to navigate guest out of player
    if (onHostExitedPlayer != null) {
      onHostExitedPlayer!.call();
    } else {
      appLogger.w('WatchTogether: onHostExitedPlayer callback not set!');
    }
  }

  /// Start a grace period for host reconnection (guest only)
  void _startHostReconnectGracePeriod() {
    _cancelHostReconnectGracePeriod();
    _isWaitingForHostReconnect = true;
    appLogger.d('WatchTogether: Host disconnected, waiting 15s for reconnection');
    notifyListeners();

    _hostReconnectTimer = Timer(const Duration(seconds: 15), () {
      if (_isWaitingForHostReconnect) {
        appLogger.d('WatchTogether: Host reconnect grace period expired');
        _isWaitingForHostReconnect = false;
        _recoverableTransportError = null;
        _session = _session?.copyWith(state: SessionState.error, errorMessage: 'Host left the session');
        onHostExitedPlayer?.call();
        notifyListeners();
      }
    });
  }

  /// Cancel host reconnect grace period
  void _cancelHostReconnectGracePeriod() {
    _hostReconnectTimer?.cancel();
    _hostReconnectTimer = null;
    if (_isWaitingForHostReconnect) {
      _isWaitingForHostReconnect = false;
      appLogger.d('WatchTogether: Host reconnected, grace period cancelled');
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    final peerService = _detachLocalSession(announceLeave: true);
    unawaited(_participantEventController.close());
    super.dispose();
    if (peerService != null) {
      unawaited(
        _finishPeerTeardown(peerService, release: true).catchError((Object error, StackTrace stackTrace) {
          appLogger.e('WatchTogether: Failed to release session during dispose', error: error, stackTrace: stackTrace);
        }),
      );
    }
  }
}

/// Type of participant event
enum ParticipantEventType {
  joined,
  left,
  paused,
  resumed,
  seeked,
  changedSpeed,
  buffering,
  needsUpdate,
  resumedWithout,
  hostChanged,
  becameHost,
  hostTransferFailed,
}

/// Event emitted when a participant joins or leaves
class ParticipantEvent {
  final String displayName;
  final ParticipantEventType type;

  /// The room rate a [ParticipantEventType.changedSpeed] event refers to.
  final double? rate;

  const ParticipantEvent({required this.displayName, required this.type, this.rate});
}
