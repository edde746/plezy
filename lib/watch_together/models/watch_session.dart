import 'package:freezed_annotation/freezed_annotation.dart';

part 'watch_session.freezed.dart';

enum SessionRole { host, guest }

enum ControlMode { hostOnly, anyone }

enum SessionState { connecting, connected, error }

@freezed
sealed class Participant with _$Participant {
  const factory Participant({
    required String peerId,
    required String displayName,
    required bool isHost,
    @Default(false) bool isBuffering,
  }) = _Participant;
}

@freezed
sealed class WatchSession with _$WatchSession {
  const WatchSession._();

  const factory WatchSession({
    required String sessionId,
    required SessionRole role,
    required ControlMode controlMode,
    required SessionState state,
    String? errorMessage,
    String? mediaRatingKey,
    String? mediaServerId,
    String? mediaTitle,
    String? hostPeerId,
  }) = _WatchSession;

  bool get isHost => role == SessionRole.host;

  bool get isConnected => state == SessionState.connected;

  /// Create a new session as host
  factory WatchSession.createAsHost({
    required String sessionId,
    required String hostPeerId,
    required ControlMode controlMode,
    String? mediaRatingKey,
    String? mediaServerId,
    String? mediaTitle,
  }) => WatchSession(
    sessionId: sessionId,
    role: SessionRole.host,
    controlMode: controlMode,
    state: SessionState.connecting,
    hostPeerId: hostPeerId,
    mediaRatingKey: mediaRatingKey,
    mediaServerId: mediaServerId,
    mediaTitle: mediaTitle,
  );

  /// Create a session as guest (joining)
  factory WatchSession.joinAsGuest({required String sessionId}) => WatchSession(
    sessionId: sessionId,
    role: SessionRole.guest,
    controlMode: ControlMode.hostOnly, // Will be updated when connected
    state: SessionState.connecting,
  );
}
