import 'dart:convert';

import 'playback_state.dart';

/// Types of sync messages sent over the relay data channel (protocol v2).
enum SyncMessageType {
  /// Authoritative playback state broadcast by the host
  state,

  /// A peer's player status report to the host
  status,

  /// A guest's playback control request to the host
  control,

  /// Request the current playback state from the host
  requestState,

  /// Participant joined the session
  join,

  /// Participant left the session
  leave,

  /// Ping for clock-offset measurement
  ping,

  /// Pong response
  pong,

  /// Host exited the video player
  hostExitedPlayer,
}

/// A message sent over the relay data channel for synchronization
class SyncMessage {
  /// Current sync protocol version, carried on join messages. Peers with a
  /// different version are excluded from readiness gating and surfaced as
  /// needing an update.
  static const int protocolVersion = 2;

  /// Type of this message
  final SyncMessageType type;

  /// Timestamp when this message was created (Unix ms). For pong messages
  /// this is the responder's "clock now" used for offset estimation.
  final int timestamp;

  /// Peer ID of the sender
  final String? peerId;

  /// Display name of the sender (for join message)
  final String? displayName;

  /// Whether the sender is the host (for join message)
  final bool? isHost;

  /// Ping ID for matching pong responses
  final int? pingId;

  /// Authoritative playback state (for state message)
  final PlaybackState? state;

  /// Peer player status report (for status message)
  final PeerStatus? status;

  /// Playback control request (for control message)
  final ControlRequest? control;

  /// Sync protocol version (for join message)
  final int? version;

  const SyncMessage({
    required this.type,
    required this.timestamp,
    this.peerId,
    this.displayName,
    this.isHost,
    this.pingId,
    this.state,
    this.status,
    this.control,
    this.version,
  });

  /// Create a STATE message carrying the host's authoritative playback state
  factory SyncMessage.state(PlaybackState state, {String? peerId}) {
    return SyncMessage(
      type: SyncMessageType.state,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      peerId: peerId,
      state: state,
    );
  }

  /// Create a STATUS message reporting this peer's player state to the host
  factory SyncMessage.status(PeerStatus status, {String? peerId}) {
    return SyncMessage(
      type: SyncMessageType.status,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      peerId: peerId,
      status: status,
    );
  }

  /// Create a CONTROL message requesting a playback action from the host
  factory SyncMessage.control(ControlRequest control, {String? peerId}) {
    return SyncMessage(
      type: SyncMessageType.control,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      peerId: peerId,
      control: control,
    );
  }

  /// Create a REQUEST_STATE message asking the host to re-send its state
  factory SyncMessage.requestState({String? peerId}) {
    return SyncMessage(
      type: SyncMessageType.requestState,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      peerId: peerId,
    );
  }

  /// Create a JOIN message (carries the sender's protocol version)
  factory SyncMessage.join({required String peerId, required String displayName, required bool isHost}) {
    return SyncMessage(
      type: SyncMessageType.join,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      peerId: peerId,
      displayName: displayName,
      isHost: isHost,
      version: protocolVersion,
    );
  }

  /// Create a LEAVE message
  factory SyncMessage.leave({required String peerId}) {
    return SyncMessage(type: SyncMessageType.leave, timestamp: DateTime.now().millisecondsSinceEpoch, peerId: peerId);
  }

  /// Create a PING message
  factory SyncMessage.ping(int pingId, {String? peerId}) {
    return SyncMessage(
      type: SyncMessageType.ping,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      pingId: pingId,
      peerId: peerId,
    );
  }

  /// Create a PONG message
  factory SyncMessage.pong(int pingId, {String? peerId}) {
    return SyncMessage(
      type: SyncMessageType.pong,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      pingId: pingId,
      peerId: peerId,
    );
  }

  /// Create a HOST_EXITED_PLAYER message (sent by host when exiting video player)
  factory SyncMessage.hostExitedPlayer({String? peerId}) {
    return SyncMessage(
      type: SyncMessageType.hostExitedPlayer,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      peerId: peerId,
    );
  }

  SyncMessage copyWith({String? peerId}) {
    return SyncMessage(
      type: type,
      timestamp: timestamp,
      peerId: peerId ?? this.peerId,
      displayName: displayName,
      isHost: isHost,
      pingId: pingId,
      state: state,
      status: status,
      control: control,
      version: version,
    );
  }

  /// Serialize to JSON string for sending over the data channel
  String toJson() {
    final map = <String, dynamic>{'t': type.name, 'ts': timestamp};

    if (peerId != null) map['pid'] = peerId;
    if (displayName != null) map['name'] = displayName;
    if (isHost != null) map['host'] = isHost;
    if (pingId != null) map['ping'] = pingId;
    if (state != null) map['st'] = state!.toMap();
    if (status != null) map['su'] = status!.toMap();
    if (control != null) map['co'] = control!.toMap();
    if (version != null) map['v'] = version;

    return jsonEncode(map);
  }

  /// Parse from JSON string received from the data channel
  factory SyncMessage.fromJson(String jsonString) {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;

    final typeString = map['t'] as String;
    final type =
        SyncMessageType.values.asNameMap()[typeString] ?? (throw FormatException('Unknown message type: $typeString'));

    return SyncMessage(
      type: type,
      timestamp: map['ts'] as int,
      peerId: map['pid'] as String?,
      displayName: map['name'] as String?,
      isHost: map['host'] as bool?,
      pingId: map['ping'] as int?,
      state: map['st'] != null ? PlaybackState.fromMap((map['st'] as Map).cast<String, dynamic>()) : null,
      status: map['su'] != null ? PeerStatus.fromMap((map['su'] as Map).cast<String, dynamic>()) : null,
      control: map['co'] != null ? ControlRequest.fromMap((map['co'] as Map).cast<String, dynamic>()) : null,
      version: map['v'] as int?,
    );
  }

  @override
  String toString() {
    return 'SyncMessage(type: $type, timestamp: $timestamp, peerId: $peerId, '
        'state: $state, status: $status, control: $control)';
  }
}
