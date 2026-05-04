enum SessionRole { host, guest }

enum ControlMode { hostOnly, anyone }

enum SessionState { disconnected, connecting, connected, error }

class Participant {
  final String peerId;
  final String displayName;
  final bool isHost;
  final Duration lastKnownPosition;
  final bool isBuffering;

  const Participant({
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

class WatchSession {
  final String sessionId;
  final SessionRole role;
  final ControlMode controlMode;
  final SessionState state;
  final String? errorMessage;
  final String? mediaRatingKey;
  final String? mediaServerId;
  final String? mediaTitle;
  final String? hostPeerId;

  const WatchSession({
    required this.sessionId,
    required this.role,
    required this.controlMode,
    required this.state,
    this.errorMessage,
    this.mediaRatingKey,
    this.mediaServerId,
    this.mediaTitle,
    this.hostPeerId,
  });

  bool get isHost => role == SessionRole.host;

  bool get isConnected => state == SessionState.connected;

  WatchSession copyWith({
    String? sessionId,
    SessionRole? role,
    ControlMode? controlMode,
    SessionState? state,
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
    );
  }

  /// Create a session as guest (joining)
  factory WatchSession.joinAsGuest({required String sessionId}) {
    return WatchSession(
      sessionId: sessionId,
      role: SessionRole.guest,
      controlMode: ControlMode.hostOnly, // Will be updated when connected
      state: SessionState.connecting,
    );
  }
}
