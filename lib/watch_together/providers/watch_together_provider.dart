import 'dart:async';
import '../../media/ids.dart';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../mpv/mpv.dart';
import '../../services/settings_service.dart';
import '../../utils/app_logger.dart';
import '../models/playback_state.dart';
import '../models/sync_message.dart';
import '../models/watch_session.dart';
import '../services/watch_together_controller.dart';
import '../services/watch_together_peer_service.dart';

/// Callback type for when media switches (for guest navigation)
typedef MediaSwitchCallback = void Function(String ratingKey, ServerId serverId, String mediaTitle);

/// Provider for Watch Together functionality
///
/// This provider manages:
/// - Session creation/joining
/// - Peer connections
/// - Playback synchronization
/// - Participant list
/// - Media switching across the session
class WatchTogetherProvider with ChangeNotifier {
  WatchSession? _session;
  WatchTogetherPeerService? _peerService;
  WatchTogetherController? _controller;
  final List<Participant> _participants = [];
  bool _isSyncing = false;
  bool _isWaitingForPeers = false;
  List<String> _waitingOnPeerIds = const [];
  PlaybackPhase? _playbackPhase;
  String _displayName = 'User';
  String? _lastHandledCurrentPlaybackKey;

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

  // Getters
  bool get isInSession => _session != null && _session!.state != SessionState.disconnected;
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
        if (peerId != myPeerId)
          _participants.where((p) => p.peerId == peerId).map((p) => p.displayName).firstOrNull ?? '?',
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

  /// Set the display name for this user
  void setDisplayName(String name) {
    _displayName = name;
  }

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
    _lastHandledCurrentPlaybackKey = null;
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

    _lastHandledCurrentPlaybackKey = _buildPlaybackKey(ratingKey, ServerId(serverId));
    appLogger.d('WatchTogether: Dispatching current playback from $source: $mediaTitle');
    callback(ratingKey, ServerId(serverId), mediaTitle);
  }

  void markCurrentPlaybackHandled({required String ratingKey, required ServerId serverId}) {
    _lastHandledCurrentPlaybackKey = _buildPlaybackKey(ratingKey, serverId);
  }

  void requestCurrentPlaybackSnapshot() {
    if (isHost) return;
    appLogger.d('WatchTogether: Requesting current playback state from host');
    _controller?.requestState();
  }

  /// Wire up reconnection handler to re-announce join and re-sync state
  void _wireReconnectHandler() {
    _peerService!.onReconnected = () {
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

    controller.onRemoteAction = (peerId, hint) {
      final type = switch (hint) {
        PlaybackActionHint.play => ParticipantEventType.resumed,
        PlaybackActionHint.pause => ParticipantEventType.paused,
        PlaybackActionHint.seek => ParticipantEventType.seeked,
        PlaybackActionHint.rate || PlaybackActionHint.mediaSwitch => null,
      };
      if (type != null) _emitActionEvent(peerId, type);
    };

    controller.onPeerNeedsUpdate = (peerId) {
      final name = _participants.where((p) => p.peerId == peerId).map((p) => p.displayName).firstOrNull;
      _participantEventController.add(
        ParticipantEvent(displayName: name ?? peerId, type: ParticipantEventType.needsUpdate),
      );
    };

    controller.onResumedWithout = (peerIds) {
      for (final peerId in peerIds) {
        final name = _participants.where((p) => p.peerId == peerId).map((p) => p.displayName).firstOrNull;
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
    String? displayName,
    String? sessionId,
    String? mediaRatingKey,
    String? mediaServerId,
    String? mediaTitle,
  }) async {
    // Clean up any existing session
    await leaveSession();
    _lastHandledCurrentPlaybackKey = null;

    appLogger.d('WatchTogether: Creating session with control mode: $controlMode');

    final customRelayUrl = SettingsService.instanceOrNull?.read(SettingsService.customRelayUrl);
    _peerService = WatchTogetherPeerService(customBaseUrl: customRelayUrl);
    _setupPeerServiceListeners();

    try {
      final createdSessionId = await _peerService!.createSession(sessionId: sessionId);

      _session = WatchSession.createAsHost(
        sessionId: createdSessionId,
        hostPeerId: _peerService!.myPeerId!,
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
  Future<void> joinSession(String sessionId, {String? displayName}) async {
    // Clean up any existing session
    await leaveSession();
    _lastHandledCurrentPlaybackKey = null;

    appLogger.d('WatchTogether: Joining session: $sessionId');

    final customRelayUrl = SettingsService.instanceOrNull?.read(SettingsService.customRelayUrl);
    _peerService = WatchTogetherPeerService(customBaseUrl: customRelayUrl);
    _setupPeerServiceListeners();

    _session = WatchSession.joinAsGuest(sessionId: sessionId);
    notifyListeners();

    try {
      await _peerService!.joinSession(sessionId);

      // Session will be fully configured when we receive sessionConfig from host
      _session = _session!.copyWith(state: SessionState.connected, hostPeerId: 'wt-${sessionId.toUpperCase()}');

      _displayName = displayName ?? _generateDisplayName();

      _controller = WatchTogetherController(peerService: _peerService!, session: _session!);

      _wireController();
      _wireReconnectHandler();

      // Add self to participants
      _participants.add(Participant(peerId: _peerService!.myPeerId!, displayName: _displayName, isHost: false));

      // Announce join to other participants
      _controller!.announceJoin(_displayName);
      requestCurrentPlaybackSnapshot();

      notifyListeners();
      appLogger.d('WatchTogether: Joined session successfully');
    } catch (e) {
      appLogger.e('WatchTogether: Failed to join session', error: e);
      _session = _session?.copyWith(state: SessionState.error, errorMessage: e.toString());
      notifyListeners();
      rethrow;
    }
  }

  /// Enter a room by code — joins if it exists, creates if empty.
  ///
  /// Returns `true` if the user became the host.
  Future<bool> enterRoom(String sessionId, {ControlMode controlMode = ControlMode.anyone, String? displayName}) async {
    // Probe the relay with a lightweight peer service to check room occupancy,
    // then do a single createSession or joinSession. This avoids the crash-prone
    // join→teardown→create cycle on the provider.
    final customRelayUrl = SettingsService.instanceOrNull?.read(SettingsService.customRelayUrl);
    final probe = WatchTogetherPeerService(customBaseUrl: customRelayUrl);
    bool shouldBeHost;
    try {
      await probe.joinSession(sessionId);
      shouldBeHost = probe.connectedPeers.isEmpty;
    } on PeerError catch (e) {
      if (e.serverCode == 'room_not_found') {
        shouldBeHost = true;
      } else {
        await probe.disconnect();
        probe.dispose();
        rethrow;
      }
    }
    await probe.disconnect();
    probe.dispose();

    if (shouldBeHost) {
      await createSession(controlMode: controlMode, displayName: displayName, sessionId: sessionId);
    } else {
      await joinSession(sessionId, displayName: displayName);
    }
    return shouldBeHost;
  }

  /// Leave the current session
  Future<void> leaveSession() async {
    if (_session == null) return;

    appLogger.d('WatchTogether: Leaving session');

    // Announce leave if connected
    _controller?.announceLeave();

    // Clean up subscriptions
    unawaited(_peerConnectedSubscription?.cancel());
    unawaited(_peerDisconnectedSubscription?.cancel());
    unawaited(_messageSubscription?.cancel());
    unawaited(_errorSubscription?.cancel());

    _peerConnectedSubscription = null;
    _peerDisconnectedSubscription = null;
    _messageSubscription = null;
    _errorSubscription = null;

    // Cancel host reconnect grace period
    _cancelHostReconnectGracePeriod();

    // Clean up services
    _controller?.dispose();
    _controller = null;

    await _peerService?.disconnect();
    _peerService?.dispose();
    _peerService = null;

    _session = null;
    _participants.clear();
    _isSyncing = false;
    _isWaitingForPeers = false;
    _waitingOnPeerIds = const [];
    _playbackPhase = null;
    _lastHandledCurrentPlaybackKey = null;
    _lastActionEventMs.clear();
    _hostIntentionallyLeft = false;

    notifyListeners();
    appLogger.d('WatchTogether: Session left');
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

  /// Suppress sync heartbeats/corrections while the app is backgrounded.
  void setBackgrounded(bool value) {
    _controller?.setBackgrounded(value);
  }

  /// Set up listeners for peer service events
  void _setupPeerServiceListeners() {
    _peerConnectedSubscription = _peerService!.onPeerConnected.listen((peerId) {
      appLogger.d('WatchTogether: Peer connected: $peerId');

      // If host reconnected during grace period, cancel the timer
      if (!isHost && peerId == _session?.hostPeerId && _isWaitingForHostReconnect) {
        _cancelHostReconnectGracePeriod();
      }

      if (!isHost && peerId == _session?.hostPeerId) {
        requestCurrentPlaybackSnapshot();
      }

      // Peer will announce themselves with a join message
      notifyListeners();
    });

    _peerDisconnectedSubscription = _peerService!.onPeerDisconnected.listen((peerId) {
      appLogger.d('WatchTogether: Peer disconnected: $peerId');

      // Capture display name before removal for notification
      final disconnectedName = _participants.where((p) => p.peerId == peerId).map((p) => p.displayName).firstOrNull;

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

    _messageSubscription = _peerService!.onMessageReceived.listen((message) {
      _handleSyncMessage(message);
    });

    _errorSubscription = _peerService!.onError.listen((error) {
      appLogger.e('WatchTogether: Peer error: ${error.message}');

      // Update session state on error
      if (_session != null && _session!.state == SessionState.connected) {
        _session = _session!.copyWith(state: SessionState.error, errorMessage: error.message);
        notifyListeners();
      }
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
            // infinite join ping-pong (A→join→B→join→A→...).
            if (_peerService != null) {
              _peerService!.sendTo(
                message.peerId!,
                SyncMessage.join(peerId: _peerService!.myPeerId!, displayName: _displayName, isHost: isHost),
              );
            }
          }

          notifyListeners();
        }
        break;

      case SyncMessageType.leave:
        if (message.peerId != null) {
          final leavingName = _participants
              .where((p) => p.peerId == message.peerId)
              .map((p) => p.displayName)
              .firstOrNull;
          _participants.removeWhere((p) => p.peerId == message.peerId);
          if (leavingName != null) {
            _participantEventController.add(
              ParticipantEvent(displayName: leavingName, type: ParticipantEventType.left),
            );
          }

          // If the host deliberately left, end the session for everyone.
          if (!isHost && message.peerId == _session?.hostPeerId) {
            _hostIntentionallyLeft = true;
            _handleHostExitedPlayer(message);
            leaveSession();
          }

          notifyListeners();
        }
        break;

      case SyncMessageType.hostExitedPlayer:
        _handleHostExitedPlayer(message);
        break;

      default:
        // Playback sync messages (state/status/control/...) are handled by
        // the session controller.
        break;
    }
  }

  /// Emit an action event for a remote peer (with 1s debounce per peer+type)
  void _emitActionEvent(String? peerId, ParticipantEventType type) {
    if (peerId == null || peerId == _peerService?.myPeerId) return;

    final key = '$peerId:${type.name}';
    final now = DateTime.now().millisecondsSinceEpoch;
    final last = _lastActionEventMs[key] ?? 0;
    if (now - last < 1000) return;
    _lastActionEventMs[key] = now;

    final name = _participants.where((p) => p.peerId == peerId).map((p) => p.displayName).firstOrNull;
    if (name != null) {
      _participantEventController.add(ParticipantEvent(displayName: name, type: type));
    }
  }

  /// Handle current-media info carried in the host's playback state
  /// (guest only). Processed even when no player is attached so guests can
  /// navigate into (or between) playback.
  void _handleMediaStateReceived(String ratingKey, String serverId, String? mediaTitle) {
    if (isHost) return;

    final playbackKey = _buildPlaybackKey(ratingKey, serverIdOrNull(serverId));
    final shouldDispatch = playbackKey != _lastHandledCurrentPlaybackKey;

    _updateCurrentPlaybackSnapshot(ratingKey: ratingKey, serverId: ServerId(serverId), mediaTitle: mediaTitle ?? '');
    notifyListeners();

    if (shouldDispatch) {
      _dispatchCurrentPlayback(
        ratingKey: ratingKey,
        serverId: ServerId(serverId),
        mediaTitle: mediaTitle ?? '',
        source: 'playback state',
      );
    }
  }

  /// Called when user seeks locally (to sync with peers)
  void onLocalSeek(Duration position) {
    _controller?.onLocalSeek(position);
  }

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
  void _handleHostExitedPlayer(SyncMessage _) {
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
    _disposed = true;
    _cancelHostReconnectGracePeriod();
    _participantEventController.close();
    leaveSession();
    super.dispose();
  }
}

/// Type of participant event
enum ParticipantEventType { joined, left, paused, resumed, seeked, buffering, needsUpdate, resumedWithout }

/// Event emitted when a participant joins or leaves
class ParticipantEvent {
  final String displayName;
  final ParticipantEventType type;

  const ParticipantEvent({required this.displayName, required this.type});
}
