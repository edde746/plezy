/// Session role - whether this device is the host or a guest
enum SessionRole { host, guest }

/// Control mode - who can control playback
enum ControlMode {
  /// Only the host can control playback
  hostOnly,

  /// Anyone in the session can control playback
  anyone,
}

/// Current state of the watch together session
enum SessionState {
  /// Not connected to any session
  disconnected,

  /// Attempting to connect/create session
  connecting,

  /// Successfully connected to session
  connected,

  /// Connection error occurred
  error,
}

/// Represents a participant in a watch together session
class Participant {
  final String peerId;
  final String displayName;
  final bool isHost;
  Duration lastKnownPosition;
  bool isBuffering;

  Participant({
    required this.peerId,
    required this.displayName,
    required this.isHost,
    this.lastKnownPosition = Duration.zero,
    this.isBuffering = false,
  });

  Participant copyWith({
    String? peerId,
    String? displayName,
    bool? isHost,
    Duration? lastKnownPosition,
    bool? isBuffering,
  }) {
    return Participant(
      peerId: peerId ?? this.peerId,
      displayName: displayName ?? this.displayName,
      isHost: isHost ?? this.isHost,
      lastKnownPosition: lastKnownPosition ?? this.lastKnownPosition,
      isBuffering: isBuffering ?? this.isBuffering,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Participant && runtimeType == other.runtimeType && peerId == other.peerId;

  @override
  int get hashCode => peerId.hashCode;
}

/// Represents a watch together session
class WatchSession {
  /// Unique identifier for this session (used for joining)
  final String sessionId;

  /// This device's role in the session
  final SessionRole role;

  /// Who can control playback
  final ControlMode controlMode;

  /// Current connection state
  final SessionState state;

  /// List of participants in the session
  final List<Participant> participants;

  /// Error message if state is error
  final String? errorMessage;

  /// Rating key of the media being watched (for validation)
  final String? mediaRatingKey;

  /// Server ID of the media being watched (same-server requirement)
  final String? mediaServerId;

  /// Title of the media being watched
  final String? mediaTitle;

  /// The host's peer ID (used to identify host messages)
  final String? hostPeerId;

  const WatchSession({
    required this.sessionId,
    required this.role,
    required this.controlMode,
    required this.state,
    this.participants = const [],
    this.errorMessage,
    this.mediaRatingKey,
    this.mediaServerId,
    this.mediaTitle,
    this.hostPeerId,
  });

  /// Whether this device is the host
  bool get isHost => role == SessionRole.host;

  /// Whether the session is currently connected
  bool get isConnected => state == SessionState.connected;

  /// Number of participants (including self)
  int get participantCount => participants.length;

  WatchSession copyWith({
    String? sessionId,
    SessionRole? role,
    ControlMode? controlMode,
    SessionState? state,
    List<Participant>? participants,
    String? errorMessage,
    String? mediaRatingKey,
    String? mediaServerId,
    String? mediaTitle,
    String? hostPeerId,
  }) {
    return WatchSession(
      sessionId: sessionId ?? this.sessionId,
      role: role ?? this.role,
      controlMode: controlMode ?? this.controlMode,
      state: state ?? this.state,
      participants: participants ?? this.participants,
      errorMessage: errorMessage ?? this.errorMessage,
      mediaRatingKey: mediaRatingKey ?? this.mediaRatingKey,
      mediaServerId: mediaServerId ?? this.mediaServerId,
      mediaTitle: mediaTitle ?? this.mediaTitle,
      hostPeerId: hostPeerId ?? this.hostPeerId,
    );
  }

  /// Create a new session as host
  factory WatchSession.createAsHost({
    required String sessionId,
    required String hostPeerId,
    required ControlMode controlMode,
    String? mediaRatingKey,
    String? mediaServerId,
    String? mediaTitle,
  }) {
    return WatchSession(
      sessionId: sessionId,
      role: SessionRole.host,
      controlMode: controlMode,
      state: SessionState.connecting,
      hostPeerId: hostPeerId,
      mediaRatingKey: mediaRatingKey,
      mediaServerId: mediaServerId,
      mediaTitle: mediaTitle,
      participants: [],
    );
  }

  /// Create a session as guest (joining)
  factory WatchSession.joinAsGuest({required String sessionId}) {
    return WatchSession(
      sessionId: sessionId,
      role: SessionRole.guest,
      controlMode: ControlMode.hostOnly, // Will be updated when connected
      state: SessionState.connecting,
      participants: [],
    );
  }
}
