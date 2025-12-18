import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../mpv/mpv.dart';
import '../../utils/app_logger.dart';
import '../models/sync_message.dart';
import '../models/watch_session.dart';
import '../services/watch_together_peer_service.dart';
import '../services/watch_together_sync_manager.dart';

/// Callback type for when media switches (for guest navigation)
typedef MediaSwitchCallback = void Function(String ratingKey, String serverId, String mediaTitle);

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
  WatchTogetherSyncManager? _syncManager;
  final List<Participant> _participants = [];
  bool _isSyncing = false;
  String _displayName = 'User';

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
  WatchTogetherSyncManager? get syncManager => _syncManager;

  // Current media getters
  String? get currentMediaRatingKey => _session?.mediaRatingKey;
  String? get currentMediaServerId => _session?.mediaServerId;
  String? get currentMediaTitle => _session?.mediaTitle;

  /// Set the display name for this user
  void setDisplayName(String name) {
    _displayName = name;
  }

  /// Create a new watch together session as host
  Future<String> createSession({
    required ControlMode controlMode,
    String? mediaRatingKey,
    String? mediaServerId,
    String? mediaTitle,
  }) async {
    // Clean up any existing session
    await leaveSession();

    appLogger.d('WatchTogether: Creating session with control mode: $controlMode');

    _peerService = WatchTogetherPeerService();
    _setupPeerServiceListeners();

    try {
      final sessionId = await _peerService!.createSession();

      _session = WatchSession.createAsHost(
        sessionId: sessionId,
        hostPeerId: _peerService!.myPeerId!,
        controlMode: controlMode,
        mediaRatingKey: mediaRatingKey,
        mediaServerId: mediaServerId,
        mediaTitle: mediaTitle,
      ).copyWith(state: SessionState.connected);

      // Generate a random display name and add self to participants
      _displayName = _generateDisplayName();
      _participants.add(Participant(peerId: _peerService!.myPeerId!, displayName: _displayName, isHost: true));

      _syncManager = WatchTogetherSyncManager(
        peerService: _peerService!,
        session: _session!,
        displayName: _displayName,
      );

      _syncManager!.onSyncStateChanged = (isSyncing) {
        _isSyncing = isSyncing;
        notifyListeners();
      };

      notifyListeners();
      appLogger.d('WatchTogether: Session created: $sessionId');

      return sessionId;
    } catch (e) {
      appLogger.e('WatchTogether: Failed to create session', error: e);
      _session = _session?.copyWith(state: SessionState.error, errorMessage: e.toString());
      notifyListeners();
      rethrow;
    }
  }

  /// Join an existing session as guest
  Future<void> joinSession(String sessionId) async {
    // Clean up any existing session
    await leaveSession();

    appLogger.d('WatchTogether: Joining session: $sessionId');

    _peerService = WatchTogetherPeerService();
    _setupPeerServiceListeners();

    _session = WatchSession.joinAsGuest(sessionId: sessionId);
    notifyListeners();

    try {
      await _peerService!.joinSession(sessionId);

      // Session will be fully configured when we receive sessionConfig from host
      _session = _session!.copyWith(state: SessionState.connected, hostPeerId: 'wt-${sessionId.toUpperCase()}');

      // Generate a random display name for this session
      _displayName = _generateDisplayName();

      _syncManager = WatchTogetherSyncManager(
        peerService: _peerService!,
        session: _session!,
        displayName: _displayName,
      );

      _syncManager!.onSessionConfigReceived = (controlMode) {
        _session = _session!.copyWith(controlMode: controlMode);
        _syncManager!.updateSession(_session!);
        notifyListeners();
      };

      _syncManager!.onSyncStateChanged = (isSyncing) {
        _isSyncing = isSyncing;
        notifyListeners();
      };

      // Add self to participants
      _participants.add(Participant(peerId: _peerService!.myPeerId!, displayName: _displayName, isHost: false));

      // Announce join to other participants
      _syncManager!.announceJoin(_displayName);

      notifyListeners();
      appLogger.d('WatchTogether: Joined session successfully');
    } catch (e) {
      appLogger.e('WatchTogether: Failed to join session', error: e);
      _session = _session?.copyWith(state: SessionState.error, errorMessage: e.toString());
      notifyListeners();
      rethrow;
    }
  }

  /// Leave the current session
  Future<void> leaveSession() async {
    if (_session == null) return;

    appLogger.d('WatchTogether: Leaving session');

    // Announce leave if connected
    _syncManager?.announceLeave();

    // Clean up subscriptions
    _peerConnectedSubscription?.cancel();
    _peerDisconnectedSubscription?.cancel();
    _messageSubscription?.cancel();
    _errorSubscription?.cancel();

    _peerConnectedSubscription = null;
    _peerDisconnectedSubscription = null;
    _messageSubscription = null;
    _errorSubscription = null;

    // Clean up services
    _syncManager?.dispose();
    _syncManager = null;

    await _peerService?.disconnect();
    _peerService?.dispose();
    _peerService = null;

    _session = null;
    _participants.clear();
    _isSyncing = false;

    notifyListeners();
    appLogger.d('WatchTogether: Session left');
  }

  /// Attach a player to the sync manager
  void attachPlayer(Player player) {
    if (_syncManager == null) {
      appLogger.w('WatchTogether: Cannot attach player - no sync manager');
      return;
    }

    // Initialize sync manager with existing participants (may have joined before player attached)
    final peerIds = _participants.map((p) => p.peerId).toList();
    _syncManager!.initializeParticipants(peerIds);

    _syncManager!.attachPlayer(player);
    appLogger.d('WatchTogether: Player attached to sync manager');
  }

  /// Detach the player from the sync manager
  void detachPlayer() {
    _syncManager?.detachPlayer();
    appLogger.d('WatchTogether: Player detached from sync manager');
  }

  /// Set up listeners for peer service events
  void _setupPeerServiceListeners() {
    _peerConnectedSubscription = _peerService!.onPeerConnected.listen((peerId) {
      appLogger.d('WatchTogether: Peer connected: $peerId');
      // Peer will announce themselves with a join message
      notifyListeners();
    });

    _peerDisconnectedSubscription = _peerService!.onPeerDisconnected.listen((peerId) {
      appLogger.d('WatchTogether: Peer disconnected: $peerId');
      _participants.removeWhere((p) => p.peerId == peerId);

      // If host disconnected, end session for guests
      if (!isHost && peerId == _session?.hostPeerId) {
        _session = _session?.copyWith(state: SessionState.error, errorMessage: 'Host left the session');
        // Ensure guests exit the player if host disappears
        onHostExitedPlayer?.call();
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
          }

          notifyListeners();
        }
        break;

      case SyncMessageType.leave:
        if (message.peerId != null) {
          _participants.removeWhere((p) => p.peerId == message.peerId);
          notifyListeners();
        }
        break;

      case SyncMessageType.buffering:
        if (message.peerId != null) {
          final index = _participants.indexWhere((p) => p.peerId == message.peerId);
          if (index >= 0) {
            _participants[index] = _participants[index].copyWith(isBuffering: message.bufferingState ?? false);
            notifyListeners();
          }
        }
        break;

      case SyncMessageType.positionSync:
        if (message.peerId != null && message.position != null) {
          final index = _participants.indexWhere((p) => p.peerId == message.peerId);
          if (index >= 0) {
            _participants[index] = _participants[index].copyWith(lastKnownPosition: message.position);
            // Don't notify for position updates - too frequent
          }
        }
        break;

      case SyncMessageType.mediaSwitch:
        _handleMediaSwitch(message);
        break;

      case SyncMessageType.hostExitedPlayer:
        _handleHostExitedPlayer(message);
        break;

      case SyncMessageType.sessionConfig:
        _handleSessionConfig(message);
        break;

      default:
        break;
    }
  }

  /// Handle session config from host (guest only)
  /// This is handled at provider level so it's processed even before player is attached
  void _handleSessionConfig(SyncMessage message) {
    if (isHost) return; // Host doesn't need to process config

    if (message.controlMode != null) {
      appLogger.d('WatchTogether: Received session config, controlMode: ${message.controlMode}');
      _session = _session!.copyWith(controlMode: message.controlMode);
      _syncManager?.updateSession(_session!); // Update sync manager if it exists
      notifyListeners();
    }
  }

  /// Called when user seeks locally (to broadcast to peers)
  void onLocalSeek(Duration position) {
    _syncManager?.onLocalSeek(position);
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
  void setCurrentMedia({required String ratingKey, required String serverId, required String mediaTitle}) {
    if (!isHost || _session == null || _peerService == null) {
      appLogger.w('WatchTogether: Cannot set media - not host or not in session');
      return;
    }

    appLogger.d('WatchTogether: Host setting current media: $mediaTitle (ratingKey: $ratingKey)');

    // Update session with new media info
    _session = _session!.copyWith(mediaRatingKey: ratingKey, mediaServerId: serverId, mediaTitle: mediaTitle);

    // Broadcast media switch to all guests
    _peerService!.broadcast(
      SyncMessage.mediaSwitch(
        ratingKey: ratingKey,
        serverId: serverId,
        mediaTitle: mediaTitle,
        peerId: _peerService!.myPeerId,
      ),
    );

    notifyListeners();
  }

  /// Handle media switch message from host (guest only)
  void _handleMediaSwitch(SyncMessage message) {
    if (isHost) return; // Host doesn't need to handle their own switch

    // Skip if already playing this media (prevents duplicate navigation from duplicate messages)
    if (_session?.mediaRatingKey == message.ratingKey) {
      appLogger.d('WatchTogether: Ignoring duplicate media switch for ${message.ratingKey}');
      return;
    }

    if (message.ratingKey == null || message.serverId == null || message.mediaTitle == null) {
      appLogger.w('WatchTogether: Received incomplete media switch message');
      return;
    }

    appLogger.d('WatchTogether: Received media switch: ${message.mediaTitle}');

    // Update local session state
    _session = _session?.copyWith(
      mediaRatingKey: message.ratingKey,
      mediaServerId: message.serverId,
      mediaTitle: message.mediaTitle,
    );

    notifyListeners();

    // If player handler is set (VideoPlayerScreen is active), use that for proper navigation context
    if (onPlayerMediaSwitched != null) {
      onPlayerMediaSwitched!(message.ratingKey!, message.serverId!, message.mediaTitle!);
      return;
    }

    // Otherwise, trigger app-level navigation callback (MainScreen handles it)
    onMediaSwitched?.call(message.ratingKey!, message.serverId!, message.mediaTitle!);
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
  void _handleHostExitedPlayer(SyncMessage message) {
    if (isHost) return; // Host doesn't need to handle their own exit

    appLogger.d('WatchTogether: Host exited player, callback set: ${onHostExitedPlayer != null}');

    // Trigger callback for the app to navigate guest out of player
    if (onHostExitedPlayer != null) {
      onHostExitedPlayer!.call();
    } else {
      appLogger.w('WatchTogether: onHostExitedPlayer callback not set!');
    }
  }

  @override
  void dispose() {
    leaveSession();
    super.dispose();
  }
}
